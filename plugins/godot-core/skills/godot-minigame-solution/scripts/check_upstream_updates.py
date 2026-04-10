#!/usr/bin/env python3
from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime, timezone
from html.parser import HTMLParser
import hashlib
import json
import os
from pathlib import Path
import re
import sys
from typing import Any
from urllib import error, request


USER_AGENT = "godot-minigame-solution-upgrade-monitor/1.0"
ATTENTION_STATUSES = {"changed", "behind", "drift", "error"}


class TextExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.parts: list[str] = []
        self._skip_depth = 0

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag in {"script", "style", "noscript"}:
            self._skip_depth += 1

    def handle_endtag(self, tag: str) -> None:
        if tag in {"script", "style", "noscript"} and self._skip_depth > 0:
            self._skip_depth -= 1

    def handle_data(self, data: str) -> None:
        if self._skip_depth == 0:
            self.parts.append(data)


@dataclass
class CheckResult:
    item_id: str
    category: str
    title: str
    status: str
    summary: str
    details: dict[str, Any]


def now_iso() -> str:
    return datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def http_get(url: str) -> tuple[bytes, dict[str, str]]:
    req = request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "*/*"})
    with request.urlopen(req, timeout=30) as response:
        data = response.read()
        headers = {key.lower(): value for key, value in response.headers.items()}
    return data, headers


def fetch_json(url: str) -> Any:
    data, _headers = http_get(url)
    return json.loads(data.decode("utf-8"))


def normalize_text(raw: str) -> str:
    text = raw.replace("\u00a0", " ")
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def html_to_text(raw_html: str) -> str:
    parser = TextExtractor()
    parser.feed(raw_html)
    parser.close()
    return normalize_text(" ".join(parser.parts))


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while True:
            chunk = handle.read(1024 * 1024)
            if not chunk:
                break
            digest.update(chunk)
    return digest.hexdigest()


def sha256_tree(path: Path, *, ignore_relpaths: set[str] | None = None) -> str:
    digest = hashlib.sha256()
    ignored = ignore_relpaths or set()
    for entry in sorted(path.rglob("*")):
        if entry.is_dir():
            continue
        relative_text = entry.relative_to(path).as_posix()
        if relative_text in ignored:
            continue
        relative = relative_text.encode("utf-8")
        digest.update(relative)
        digest.update(b"\0")
        digest.update(sha256_file(entry).encode("utf-8"))
        digest.update(b"\0")
    return digest.hexdigest()


def resolve_path(template: str, *, skill_root: Path, source_repo: Path | None) -> Path | None:
    if "{source_repo}" in template:
        if source_repo is None:
            return None
        resolved = template.replace("{source_repo}", str(source_repo))
        return Path(resolved).resolve()
    candidate = Path(template)
    if candidate.is_absolute():
        return candidate
    return (skill_root / template).resolve()


def get_json_path_value(payload: Any, path_parts: list[str]) -> Any:
    value = payload
    for part in path_parts:
        if not isinstance(value, dict) or part not in value:
            return None
        value = value[part]
    return value


def parse_version_parts(value: str) -> tuple[int, ...]:
    parts = [int(piece) for piece in re.findall(r"\d+", value)]
    return tuple(parts)


def compare_versions(current: str, latest: str) -> int:
    current_parts = parse_version_parts(current)
    latest_parts = parse_version_parts(latest)
    if current_parts == latest_parts:
        return 0
    if current_parts < latest_parts:
        return -1
    return 1


def run_web_page_check(item: dict[str, Any], previous_state: dict[str, Any]) -> CheckResult:
    data, headers = http_get(item["url"])
    raw = data.decode("utf-8", errors="replace")
    content_type = headers.get("content-type", "")
    normalized = html_to_text(raw) if "html" in content_type else normalize_text(raw)
    current_hash = sha256_text(normalized)
    previous_hash = previous_state.get("content_hash", "")
    last_modified = headers.get("last-modified", "")
    if not previous_hash:
        status = "baseline"
        summary = "Recorded the first content baseline."
    elif previous_hash != current_hash:
        status = "changed"
        summary = "Remote page content changed since the last recorded check."
    else:
        status = "no_change"
        summary = "No content change detected since the last recorded check."
    return CheckResult(
        item_id=item["id"],
        category=item["category"],
        title=item["title"],
        status=status,
        summary=summary,
        details={
            "url": item["url"],
            "content_hash": current_hash,
            "last_modified": last_modified,
        },
    )


def read_pinned_commit(skill_root: Path, item: dict[str, Any]) -> str:
    metadata = load_json((skill_root / item["pinned_commit_file"]).resolve())
    raw = metadata
    field = item.get("pinned_commit_field", "")
    if field:
        raw = metadata.get(field, "")
    return str(raw)


def run_github_repo_check(skill_root: Path, item: dict[str, Any], previous_state: dict[str, Any]) -> CheckResult:
    repo = item["repo"]
    commits_url = f"https://github.com/{repo}/commits"
    req = request.Request(commits_url, headers={"User-Agent": USER_AGENT, "Accept": "text/html"})
    with request.urlopen(req, timeout=30) as response:
        final_url = response.geturl()
        html = response.read().decode("utf-8", errors="replace")
    branch_name = final_url.rstrip("/").split("/")[-1]
    match = re.search(r"/commit/([0-9a-f]{40})", html)
    if not match:
        raise RuntimeError(f"Could not parse latest commit SHA from {final_url}")
    latest_sha = match.group(1)
    previous_sha = previous_state.get("latest_sha", "")
    pinned_commit = read_pinned_commit(skill_root, item)
    status = "changed" if previous_sha and latest_sha != previous_sha else "no_change"
    if not previous_sha:
        status = "baseline"
    if pinned_commit and pinned_commit != latest_sha:
        status = "behind"
    summary = "Repository head unchanged."
    if status == "baseline":
        summary = "Recorded the first upstream repository baseline."
    elif status == "changed":
        summary = "Repository head changed since the last recorded check."
    elif status == "behind":
        summary = "Pinned commit is behind the current upstream default-branch head."
    return CheckResult(
        item_id=item["id"],
        category=item["category"],
        title=item["title"],
        status=status,
        summary=summary,
        details={
            "repo": repo,
            "default_branch": branch_name,
            "latest_sha": latest_sha,
            "pinned_commit": pinned_commit,
            "html_url": final_url,
        },
    )


def run_github_release_check(item: dict[str, Any], previous_state: dict[str, Any]) -> CheckResult:
    repo = item["repo"]
    latest_url = f"https://github.com/{repo}/releases/latest"
    req = request.Request(latest_url, headers={"User-Agent": USER_AGENT, "Accept": "text/html"})
    with request.urlopen(req, timeout=30) as response:
        final_url = response.geturl()
    latest_version = final_url.rstrip("/").split("/")[-1]
    current_version = str(item.get("current_version", ""))
    previous_version = previous_state.get("latest_version", "")
    status = "baseline" if not previous_version else "no_change"
    if previous_version and previous_version != latest_version:
        status = "changed"
    if current_version and latest_version and compare_versions(current_version, latest_version) < 0:
        status = "behind"
    summary = "Latest release unchanged."
    if status == "baseline":
        summary = "Recorded the first upstream release baseline."
    elif status == "changed":
        summary = "Latest release tag changed since the last recorded check."
    elif status == "behind":
        summary = "Current compatibility baseline is behind the latest upstream release."
    return CheckResult(
        item_id=item["id"],
        category=item["category"],
        title=item["title"],
        status=status,
        summary=summary,
        details={
            "repo": repo,
            "current_version": current_version,
            "latest_version": latest_version,
            "html_url": final_url,
        },
    )


def read_current_version(skill_root: Path, item: dict[str, Any]) -> str:
    if "current_version" in item:
        return str(item["current_version"])
    payload = load_json((skill_root / item["current_version_file"]).resolve())
    current = get_json_path_value(payload, list(item["current_version_path"]))
    return "" if current is None else str(current)


def run_npm_package_check(skill_root: Path, item: dict[str, Any], previous_state: dict[str, Any]) -> CheckResult:
    package_name = item["package"]
    registry = fetch_json(f"https://registry.npmjs.org/{package_name}")
    latest_version = str(registry.get("dist-tags", {}).get("latest", ""))
    current_version = read_current_version(skill_root, item)
    previous_version = previous_state.get("latest_version", "")
    status = "baseline" if not previous_version else "no_change"
    if previous_version and previous_version != latest_version:
        status = "changed"
    if current_version and latest_version and compare_versions(current_version, latest_version) < 0:
        status = "behind"
    summary = "npm package latest tag unchanged."
    if status == "baseline":
        summary = "Recorded the first npm latest-version baseline."
    elif status == "changed":
        summary = "npm latest tag changed since the last recorded check."
    elif status == "behind":
        summary = "Pinned dependency version is behind the latest npm release."
    return CheckResult(
        item_id=item["id"],
        category=item["category"],
        title=item["title"],
        status=status,
        summary=summary,
        details={
            "package": package_name,
            "current_version": current_version,
            "latest_version": latest_version,
            "url": f"https://www.npmjs.com/package/{package_name}",
        },
    )


def run_local_tree_compare(skill_root: Path, source_repo: Path | None, item: dict[str, Any]) -> CheckResult:
    left = resolve_path(item["left"], skill_root=skill_root, source_repo=source_repo)
    right = resolve_path(item["right"], skill_root=skill_root, source_repo=source_repo)
    if left is None or right is None:
        return CheckResult(
            item_id=item["id"],
            category=item["category"],
            title=item["title"],
            status="skipped",
            summary="Source repo path was not provided for this local resource comparison.",
            details={},
        )
    if not left.exists() or not right.exists():
        missing = []
        if not left.exists():
            missing.append(str(left))
        if not right.exists():
            missing.append(str(right))
        return CheckResult(
            item_id=item["id"],
            category=item["category"],
            title=item["title"],
            status="error",
            summary="One or more local comparison paths are missing.",
            details={"missing_paths": missing},
        )
    ignored = set(item.get("ignore_relpaths", []))
    left_digest = sha256_tree(left, ignore_relpaths=ignored)
    right_digest = sha256_tree(right, ignore_relpaths=ignored)
    status = "in_sync" if left_digest == right_digest else "drift"
    summary = "Bundled resource tree matches the implementation repo." if status == "in_sync" else "Bundled resource tree differs from the implementation repo."
    return CheckResult(
        item_id=item["id"],
        category=item["category"],
        title=item["title"],
        status=status,
        summary=summary,
        details={
            "left": str(left),
            "right": str(right),
            "left_digest": left_digest,
            "right_digest": right_digest,
        },
    )


def run_local_file_group_compare(skill_root: Path, source_repo: Path | None, item: dict[str, Any]) -> CheckResult:
    if source_repo is None:
        return CheckResult(
            item_id=item["id"],
            category=item["category"],
            title=item["title"],
            status="skipped",
            summary="Source repo path was not provided for this local file-group comparison.",
            details={},
        )
    mismatches: list[dict[str, str]] = []
    missing: list[str] = []
    checked_pairs = 0
    for pair in item["pairs"]:
        left = resolve_path(pair["left"], skill_root=skill_root, source_repo=source_repo)
        right = resolve_path(pair["right"], skill_root=skill_root, source_repo=source_repo)
        if left is None or right is None:
            continue
        checked_pairs += 1
        if not left.exists() or not right.exists():
            if not left.exists():
                missing.append(str(left))
            if not right.exists():
                missing.append(str(right))
            continue
        left_digest = sha256_file(left)
        right_digest = sha256_file(right)
        if left_digest != right_digest:
            mismatches.append(
                {
                    "left": str(left),
                    "right": str(right),
                }
            )
    if missing:
        return CheckResult(
            item_id=item["id"],
            category=item["category"],
            title=item["title"],
            status="error",
            summary="One or more file-group comparison paths are missing.",
            details={"missing_paths": missing},
        )
    status = "in_sync" if not mismatches else "drift"
    summary = "Bundled template file set matches the implementation repo." if status == "in_sync" else "Bundled template file set differs from the implementation repo."
    return CheckResult(
        item_id=item["id"],
        category=item["category"],
        title=item["title"],
        status=status,
        summary=summary,
        details={
            "checked_pairs": checked_pairs,
            "mismatches": mismatches,
        },
    )


def run_check(skill_root: Path, source_repo: Path | None, item: dict[str, Any], previous_state: dict[str, Any]) -> CheckResult:
    kind = item["kind"]
    if kind == "web_page":
        return run_web_page_check(item, previous_state)
    if kind == "github_repo":
        return run_github_repo_check(skill_root, item, previous_state)
    if kind == "github_release":
        return run_github_release_check(item, previous_state)
    if kind == "npm_package":
        return run_npm_package_check(skill_root, item, previous_state)
    if kind == "local_tree_compare":
        return run_local_tree_compare(skill_root, source_repo, item)
    if kind == "local_file_group_compare":
        return run_local_file_group_compare(skill_root, source_repo, item)
    raise ValueError(f"Unsupported check kind: {kind}")


def default_state_path(skill_root: Path) -> Path:
    skill_name = skill_root.name
    codex_home = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
    return codex_home / "skills" / skill_name / "state" / "upgrade_monitor_state.json"


def load_state(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"checks": {}}
    return load_json(path)


def render_markdown(results: list[CheckResult], *, checked_at: str, state_file: Path, source_repo: Path | None) -> str:
    attention = [result for result in results if result.status in ATTENTION_STATUSES]
    categories = ["official", "external", "dependency", "resource"]
    lines = [
        "# Godot Mini-game Upgrade Monitor",
        "",
        f"- Checked at: `{checked_at}`",
        f"- State file: `{state_file}`",
        f"- Source repo: `{source_repo}`" if source_repo is not None else "- Source repo: `not provided`",
        f"- Attention items: `{len(attention)}` / `{len(results)}`",
        "",
    ]
    for category in categories:
        category_results = [result for result in results if result.category == category]
        if not category_results:
            continue
        lines.append(f"## {category.title()}")
        for result in category_results:
            lines.append(f"- `{result.status}` {result.title}: {result.summary}")
            if result.status == "behind":
                if "current_version" in result.details and "latest_version" in result.details:
                    lines.append(
                        f"  current `{result.details['current_version']}` -> latest `{result.details['latest_version']}`"
                    )
                elif "pinned_commit" in result.details and "latest_sha" in result.details:
                    lines.append(
                        f"  pinned `{str(result.details['pinned_commit'])[:12]}` -> latest `{str(result.details['latest_sha'])[:12]}`"
                    )
            if result.status == "changed" and "url" in result.details:
                lines.append(f"  source: {result.details['url']}")
            if result.status == "drift":
                mismatches = result.details.get("mismatches", [])
                if mismatches:
                    preview = mismatches[:5]
                    for mismatch in preview:
                        lines.append(f"  drift: `{mismatch['left']}` != `{mismatch['right']}`")
                    if len(mismatches) > len(preview):
                        lines.append(f"  ... and {len(mismatches) - len(preview)} more")
        lines.append("")
    lines.append("## Recommended Actions")
    if not attention:
        lines.append("- No upgrade action is currently indicated by the configured checks.")
    else:
        for result in attention:
            if result.category == "official":
                lines.append(f"- Review the official document drift for `{result.title}` and decide whether the skills or bundled assets need updates.")
            elif result.category == "external":
                lines.append(f"- Review the external upstream change for `{result.title}` and decide whether the pinned baseline should move.")
            elif result.category == "dependency":
                lines.append(f"- Review the dependency upgrade signal for `{result.title}` and decide whether the pinned version should be refreshed.")
            elif result.category == "resource":
                lines.append(f"- Refresh the bundled skill resources for `{result.title}` so the installed bundle matches the implementation source.")
    lines.append("")
    return "\n".join(lines)


def render_json(results: list[CheckResult], *, checked_at: str, state_file: Path, source_repo: Path | None) -> str:
    payload = {
        "checked_at": checked_at,
        "state_file": str(state_file),
        "source_repo": "" if source_repo is None else str(source_repo),
        "results": [
            {
                "id": result.item_id,
                "category": result.category,
                "title": result.title,
                "status": result.status,
                "summary": result.summary,
                "details": result.details,
            }
            for result in results
        ],
    }
    return json.dumps(payload, ensure_ascii=False, indent=2)


def exit_code(results: list[CheckResult]) -> int:
    has_error = any(result.status == "error" for result in results)
    has_attention = any(result.status in {"changed", "behind", "drift"} for result in results)
    if has_error and has_attention:
        return 3
    if has_error:
        return 1
    if has_attention:
        return 2
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-repo", help="Optional implementation repo used for bundled-resource drift checks.")
    parser.add_argument("--state-file", help="Optional state-file override.")
    parser.add_argument("--report-file", help="Optional report output path.")
    parser.add_argument("--output-format", choices=["markdown", "json"], default="markdown")
    parser.add_argument("--no-update-state", action="store_true")
    args = parser.parse_args()

    skill_root = Path(__file__).resolve().parents[1]
    source_repo = Path(args.source_repo).resolve() if args.source_repo else None
    watchlist = load_json(skill_root / "monitoring" / "watchlist.json")
    checked_at = now_iso()
    state_file = Path(args.state_file).resolve() if args.state_file else default_state_path(skill_root)
    state = load_state(state_file)

    results: list[CheckResult] = []
    next_state: dict[str, Any] = {"checked_at": checked_at, "checks": {}}
    for item in watchlist["checks"]:
        previous = state.get("checks", {}).get(item["id"], {})
        try:
            result = run_check(skill_root, source_repo, item, previous)
        except error.HTTPError as exc:
            result = CheckResult(
                item_id=item["id"],
                category=item["category"],
                title=item["title"],
                status="error",
                summary=f"HTTP error while checking upstream source: {exc.code}",
                details={"url": item.get("url", ""), "repo": item.get("repo", "")},
            )
        except Exception as exc:  # noqa: BLE001
            result = CheckResult(
                item_id=item["id"],
                category=item["category"],
                title=item["title"],
                status="error",
                summary=f"Check failed: {exc}",
                details={},
            )
        results.append(result)
        next_state["checks"][item["id"]] = result.details

    output = render_markdown(results, checked_at=checked_at, state_file=state_file, source_repo=source_repo)
    if args.output_format == "json":
        output = render_json(results, checked_at=checked_at, state_file=state_file, source_repo=source_repo)

    if args.report_file:
        report_path = Path(args.report_file).resolve()
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(output + ("" if output.endswith("\n") else "\n"), encoding="utf-8")

    if not args.no_update_state:
        write_json(state_file, next_state)

    print(output)
    return exit_code(results)


if __name__ == "__main__":
    raise SystemExit(main())
