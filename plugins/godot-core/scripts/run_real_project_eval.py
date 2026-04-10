#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import re
import selectors
import shlex
import subprocess
import sys
import time
from collections import Counter
from pathlib import Path


PLUGIN_ROOT = Path(__file__).resolve().parents[1]
PROMPTS_DIR = PLUGIN_ROOT / "evals" / "prompts"
ARTIFACTS_ROOT = PLUGIN_ROOT / "evals" / "artifacts"
ACTIVE_SKILLS = [
    "godot-bug-triage",
    "godot-core",
    "godot-export-release",
    "godot-feature-impl",
    "godot-scene-refactor",
    "godot-web-cjk-font-fix",
    "godot-web-export",
]
SKILL_REGEX = re.compile(r"\b(" + "|".join(re.escape(skill) for skill in ACTIVE_SKILLS) + r")\b")
COMMAND_SPECS = [
    ("smoke", ["make", "smoke"]),
    ("export-web-check", ["make", "export-web-check"]),
    ("export-web", ["make", "export-web"]),
    ("web-smoke", ["make", "web-smoke"]),
    ("browser-smoke", ["make", "browser-smoke"]),
    ("subset-font-verify", ["make", "subset-font-verify"]),
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", required=True)
    parser.add_argument("--label", required=True)
    parser.add_argument("--command-timeout-seconds", type=int, default=180)
    parser.add_argument("--route-timeout-seconds", type=int, default=45)
    return parser.parse_args()


def normalize_text(value: object) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return str(value)


def run_command(
    cmd: list[str], cwd: Path, timeout_seconds: int
) -> tuple[int | None, str, str, bool]:
    try:
        completed = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout_seconds,
        )
        return (
            completed.returncode,
            normalize_text(completed.stdout),
            normalize_text(completed.stderr),
            False,
        )
    except subprocess.TimeoutExpired as exc:
        stdout = normalize_text(exc.stdout)
        stderr = normalize_text(exc.stderr)
        return None, stdout, stderr, True


def extract_agent_message_from_event(event: dict[str, object]) -> str | None:
    if event.get("type") != "item.completed":
        return None
    item = event.get("item")
    if not isinstance(item, dict):
        return None
    if item.get("type") != "agent_message":
        return None
    text = item.get("text")
    return text if isinstance(text, str) else None


def should_stop_early(case: dict[str, object], agent_messages: list[str]) -> tuple[bool, str | None]:
    if not agent_messages:
        return False, None

    expected_skill = str(case["expected_skill"])
    mentioned_skills = sorted(set(SKILL_REGEX.findall("\n".join(agent_messages))))

    if bool(case["should_trigger"]) and expected_skill in mentioned_skills:
        return True, "positive-skill-confirmed"

    if not bool(case["should_trigger"]):
        if mentioned_skills and expected_skill not in mentioned_skills:
            return True, "negative-other-skill-confirmed"
        if len(agent_messages) >= 2 and expected_skill not in mentioned_skills:
            return True, "negative-no-expected-skill-after-two-messages"

    return False, None


def terminate_process(process: subprocess.Popen[str]) -> int | None:
    if process.poll() is not None:
        return process.returncode

    process.terminate()
    try:
        return process.wait(timeout=3)
    except subprocess.TimeoutExpired:
        process.kill()
        try:
            return process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            return None


def run_route_command(
    cmd: list[str], cwd: Path, timeout_seconds: int, case: dict[str, object]
) -> dict[str, object]:
    process = subprocess.Popen(
        cmd,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1,
    )
    selector = selectors.DefaultSelector()
    assert process.stdout is not None
    assert process.stderr is not None
    selector.register(process.stdout, selectors.EVENT_READ, data="stdout")
    selector.register(process.stderr, selectors.EVENT_READ, data="stderr")

    stdout_lines: list[str] = []
    stderr_lines: list[str] = []
    agent_messages: list[str] = []
    early_stopped = False
    early_stop_reason: str | None = None
    timed_out = False
    start = time.monotonic()
    deadline = start + timeout_seconds

    try:
        while selector.get_map():
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                timed_out = True
                break

            ready = selector.select(timeout=min(0.5, remaining))
            if not ready:
                if process.poll() is not None:
                    for fileobj in list(selector.get_map().values()):
                        selector.unregister(fileobj.fileobj)
                    break
                continue

            for key, _ in ready:
                line = key.fileobj.readline()
                if line == "":
                    selector.unregister(key.fileobj)
                    continue

                if key.data == "stdout":
                    stdout_lines.append(line)
                    stripped = line.strip()
                    if stripped:
                        try:
                            event = json.loads(stripped)
                        except json.JSONDecodeError:
                            event = None
                        if isinstance(event, dict):
                            agent_message = extract_agent_message_from_event(event)
                            if agent_message:
                                agent_messages.append(agent_message)
                                stop, reason = should_stop_early(case, agent_messages)
                                if stop:
                                    early_stopped = True
                                    early_stop_reason = reason
                else:
                    stderr_lines.append(line)

            if early_stopped:
                break
    finally:
        selector.close()

    if early_stopped or timed_out:
        returncode = terminate_process(process)
    else:
        returncode = process.wait()

    return {
        "elapsed_seconds": round(time.monotonic() - start, 3),
        "early_stop_reason": early_stop_reason,
        "early_stopped": early_stopped,
        "returncode": returncode,
        "stderr": "".join(stderr_lines),
        "stdout": "".join(stdout_lines),
        "timed_out": timed_out,
    }


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def write_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=True, indent=2, sort_keys=True) + "\n")


def load_prompt_cases() -> list[dict[str, object]]:
    cases: list[dict[str, object]] = []
    for csv_path in sorted(PROMPTS_DIR.glob("*.csv")):
        skill_name = csv_path.stem
        if skill_name not in ACTIVE_SKILLS:
            continue

        positive = None
        negative = None
        with csv_path.open(newline="") as handle:
            reader = csv.DictReader(handle)
            for row in reader:
                should_trigger = row["should_trigger"].strip().lower() == "true"
                if should_trigger and positive is None:
                    positive = row
                if not should_trigger and negative is None:
                    negative = row
        if positive is not None:
            cases.append(
                {
                    "skill": skill_name,
                    "case_type": "positive",
                    "expected_skill": skill_name,
                    "should_trigger": True,
                    "id": positive["id"],
                    "prompt": positive["prompt"],
                    "notes": positive["notes"],
                }
            )
        if negative is not None:
            cases.append(
                {
                    "skill": skill_name,
                    "case_type": "negative",
                    "expected_skill": skill_name,
                    "should_trigger": False,
                    "id": negative["id"],
                    "prompt": negative["prompt"],
                    "notes": negative["notes"],
                }
            )
    return cases


def make_targets(project_root: Path) -> list[str]:
    makefile = project_root / "Makefile"
    if not makefile.exists():
        return []
    targets: list[str] = []
    pattern = re.compile(r"^([A-Za-z0-9_.-]+):")
    for line in makefile.read_text().splitlines():
        match = pattern.match(line)
        if match:
            targets.append(match.group(1))
    return targets


def parse_export_presets(project_root: Path) -> list[dict[str, object]]:
    path = project_root / "export_presets.cfg"
    if not path.exists():
        return []

    presets: list[dict[str, object]] = []
    current: dict[str, object] | None = None
    in_options = False
    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("[preset.") and line.endswith("]"):
            in_options = line.endswith(".options]")
            if not in_options:
                current = {"section": line}
                presets.append(current)
            continue
        if current is None or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"')
        if in_options:
            current.setdefault("options", {})[key] = value
        else:
            current[key] = value
    return presets


def collect_file_sizes(project_root: Path, relative_paths: list[str]) -> dict[str, int]:
    sizes: dict[str, int] = {}
    for relative_path in relative_paths:
        path = project_root / relative_path
        if path.exists() and path.is_file():
            sizes[relative_path] = path.stat().st_size
    return sizes


def collect_font_sizes(project_root: Path) -> dict[str, int]:
    fonts_dir = project_root / "assets" / "fonts"
    sizes: dict[str, int] = {}
    if not fonts_dir.exists():
        return sizes
    for path in sorted(fonts_dir.iterdir()):
        if path.suffix.lower() in {".woff", ".woff2", ".ttf", ".otf", ".ttc"}:
            sizes[str(path.relative_to(project_root))] = path.stat().st_size
    return sizes


def parse_jsonl(stdout: str) -> tuple[list[dict[str, object]], list[str]]:
    events: list[dict[str, object]] = []
    invalid_lines: list[str] = []
    for raw_line in stdout.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            invalid_lines.append(raw_line)
    return events, invalid_lines


def extract_agent_messages(events: list[dict[str, object]]) -> list[str]:
    messages: list[str] = []
    for event in events:
        message = extract_agent_message_from_event(event)
        if message:
            messages.append(message)
    return messages


def summarize_route_case(
    case: dict[str, object],
    stdout: str,
    stderr: str,
    returncode: int | None,
    timed_out: bool,
    early_stopped: bool,
    early_stop_reason: str | None,
    elapsed_seconds: float,
) -> dict[str, object]:
    events, invalid_lines = parse_jsonl(stdout)
    agent_messages = extract_agent_messages(events)
    joined_messages = "\n".join(agent_messages)
    mentioned_skills = sorted(set(SKILL_REGEX.findall(joined_messages)))
    expected_skill = str(case["expected_skill"])
    should_trigger = bool(case["should_trigger"])

    if early_stopped:
        if should_trigger and expected_skill in mentioned_skills:
            status = "pass-early"
        elif not should_trigger and expected_skill not in mentioned_skills:
            status = "pass-early"
        else:
            status = "early-stop-ambiguous"
    elif timed_out:
        if should_trigger and expected_skill in mentioned_skills:
            status = "pass-timeout"
        elif not should_trigger and expected_skill not in mentioned_skills and agent_messages:
            status = "pass-timeout"
        else:
            status = "timeout"
    elif returncode not in (0, None):
        status = "command-error"
    elif should_trigger:
        status = "pass" if expected_skill in mentioned_skills else "missed"
    else:
        status = "pass" if expected_skill not in mentioned_skills else "false-positive"

    return {
        "agent_messages": agent_messages,
        "early_stop_reason": early_stop_reason,
        "early_stopped": early_stopped,
        "elapsed_seconds": elapsed_seconds,
        "expected_skill": expected_skill,
        "id": case["id"],
        "invalid_json_lines": invalid_lines,
        "mentioned_skills": mentioned_skills,
        "notes": case["notes"],
        "prompt": case["prompt"],
        "returncode": returncode,
        "should_trigger": should_trigger,
        "status": status,
        "stderr_present": bool(stderr.strip()),
        "timed_out": timed_out,
    }


def render_markdown_summary(
    project_root: Path,
    label: str,
    artifact_dir: Path,
    commands_summary: list[dict[str, object]],
    routes_summary: list[dict[str, object]],
    snapshot: dict[str, object],
    overall_status: str,
) -> str:
    command_counts = Counter(item["status"] for item in commands_summary)
    route_counts = Counter(item["status"] for item in routes_summary)
    lines = [
        "# Real Project Eval",
        "",
        f"- Generated at: {dt.datetime.now().astimezone().isoformat()}",
        f"- Project label: `{label}`",
        f"- Project root: `{project_root}`",
        f"- Artifact dir: `{artifact_dir}`",
        f"- Overall status: `{overall_status}`",
        "",
        "## Project snapshot",
        "",
        f"- Make targets: `{', '.join(snapshot['make_targets'])}`",
        f"- Export presets: `{json.dumps(snapshot['export_presets'], ensure_ascii=True)}`",
        f"- Build files: `{json.dumps(snapshot['build_files'], ensure_ascii=True)}`",
        f"- Font files: `{json.dumps(snapshot['font_files'], ensure_ascii=True)}`",
        f"- Command status counts: `{json.dumps(dict(command_counts), ensure_ascii=True)}`",
        f"- Route status counts: `{json.dumps(dict(route_counts), ensure_ascii=True)}`",
        "",
        "## Project commands",
        "",
        "| Command | Status | Return code |",
        "| --- | --- | --- |",
    ]

    for item in commands_summary:
        returncode = item["returncode"]
        returncode_text = "timeout" if returncode is None else str(returncode)
        lines.append(
            f"| `{item['name']}` | `{item['status']}` | `{returncode_text}` |"
        )

    lines.extend(
        [
            "",
            "## Route replay summary",
            "",
            "| Case | Expected skill | Should trigger | Observed mentions | Status |",
            "| --- | --- | --- | --- | --- |",
        ]
    )

    for item in routes_summary:
        observed = ", ".join(item["mentioned_skills"]) or "-"
        lines.append(
            f"| `{item['id']}` | `{item['expected_skill']}` | `{str(item['should_trigger']).lower()}` | `{observed}` | `{item['status']}` |"
        )

    lines.extend(
        [
            "",
            "## Notes",
            "",
            "- `stderr` for each route replay is stored separately so global Codex warnings do not corrupt the JSONL artifacts.",
            "- This run uses one positive and one negative prompt per active skill, sourced from the plugin prompt CSVs.",
        ]
    )

    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    project_root = Path(args.project_root).expanduser().resolve()
    if not (project_root / "project.godot").exists():
        print(f"Expected Godot project at {project_root}", file=sys.stderr)
        return 1

    timestamp = dt.datetime.now().astimezone().strftime("%Y%m%dT%H%M%S")
    artifact_dir = ARTIFACTS_ROOT / f"{args.label}-{timestamp}"
    commands_dir = artifact_dir / "commands"
    routes_dir = artifact_dir / "routes"
    artifact_dir.mkdir(parents=True, exist_ok=True)

    snapshot = {
        "build_files": collect_file_sizes(
            project_root,
            [
                "build/web/index.html",
                "build/web/index.js",
                "build/web/index.pck",
                "build/web/index.wasm",
            ],
        ),
        "export_presets": parse_export_presets(project_root),
        "font_files": collect_font_sizes(project_root),
        "make_targets": make_targets(project_root),
        "project_root": str(project_root),
    }
    write_json(artifact_dir / "project_snapshot.json", snapshot)

    commands_summary: list[dict[str, object]] = []
    available_targets = set(snapshot["make_targets"])
    for name, cmd in COMMAND_SPECS:
        path_base = commands_dir / name
        if name not in available_targets:
            meta = {
                "command": shlex.join(cmd),
                "name": name,
                "returncode": None,
                "status": "skipped",
            }
            write_json(path_base.with_suffix(".meta.json"), meta)
            commands_summary.append(meta)
            continue

        returncode, stdout, stderr, timed_out = run_command(cmd, project_root, args.command_timeout_seconds)
        write_text(path_base.with_suffix(".stdout.log"), stdout)
        write_text(path_base.with_suffix(".stderr.log"), stderr)
        status = "timeout" if timed_out else ("pass" if returncode == 0 else "fail")
        meta = {
            "command": shlex.join(cmd),
            "name": name,
            "returncode": returncode,
            "status": status,
            "timed_out": timed_out,
        }
        write_json(path_base.with_suffix(".meta.json"), meta)
        commands_summary.append(meta)

    snapshot["build_files"] = collect_file_sizes(
        project_root,
        [
            "build/web/index.html",
            "build/web/index.js",
            "build/web/index.pck",
            "build/web/index.wasm",
        ],
    )
    write_json(artifact_dir / "project_snapshot.json", snapshot)

    routes_summary: list[dict[str, object]] = []
    for case in load_prompt_cases():
        route_dir = routes_dir / str(case["skill"])
        path_base = route_dir / str(case["id"])
        cmd = [
            "codex",
            "exec",
            "--skip-git-repo-check",
            "--json",
            str(case["prompt"]),
        ]
        route_result = run_route_command(cmd, project_root, args.route_timeout_seconds, case)
        stdout = str(route_result["stdout"])
        stderr = str(route_result["stderr"])
        write_text(path_base.with_suffix(".jsonl"), stdout)
        write_text(path_base.with_suffix(".stderr.log"), stderr)
        meta = summarize_route_case(
            case,
            stdout,
            stderr,
            route_result["returncode"] if isinstance(route_result["returncode"], int) or route_result["returncode"] is None else None,
            bool(route_result["timed_out"]),
            bool(route_result["early_stopped"]),
            str(route_result["early_stop_reason"]) if route_result["early_stop_reason"] is not None else None,
            float(route_result["elapsed_seconds"]),
        )
        write_json(path_base.with_suffix(".meta.json"), meta)
        routes_summary.append(meta)

    command_failures = [item for item in commands_summary if item["status"] != "pass"]
    route_failures = [
        item for item in routes_summary
        if item["status"] not in {"pass", "pass-early", "pass-timeout"}
    ]
    overall_status = "pass" if not command_failures and not route_failures else "fail"
    summary = {
        "commands": commands_summary,
        "command_failures": command_failures,
        "generated_at": dt.datetime.now().astimezone().isoformat(),
        "has_failures": bool(command_failures or route_failures),
        "label": args.label,
        "overall_status": overall_status,
        "project_root": str(project_root),
        "routes": routes_summary,
        "route_failures": route_failures,
        "snapshot": snapshot,
    }
    write_json(artifact_dir / "summary.json", summary)
    write_text(
        artifact_dir / "README.md",
        render_markdown_summary(project_root, args.label, artifact_dir, commands_summary, routes_summary, snapshot, overall_status),
    )

    print(f"Wrote real-project eval artifacts to {artifact_dir}")
    return 0 if overall_status == "pass" else 2


if __name__ == "__main__":
    raise SystemExit(main())
