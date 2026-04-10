#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


def load_matrix(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise SystemExit(f"Mini-game API validation: missing matrix file: {path}") from exc
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Mini-game API validation: invalid matrix JSON {path}: {exc}") from exc


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="ignore")


def validate_profile(profile_name: str, root: Path, matrix: dict[str, Any]) -> int:
    profiles = matrix.get("profiles", {})
    if not isinstance(profiles, dict) or profile_name not in profiles:
        known = ", ".join(sorted(profiles.keys())) if isinstance(profiles, dict) else ""
        raise SystemExit(
            "Mini-game API validation: unknown profile %r. Known profiles: %s"
            % (profile_name, known or "<none>")
        )

    profile = profiles[profile_name]
    checks = profile.get("checks", [])
    if not isinstance(checks, list) or not checks:
        raise SystemExit(f"Mini-game API validation: profile {profile_name} has no checks")
    if not root.is_dir():
        raise SystemExit(f"Mini-game API validation: artifact root does not exist: {root}")

    failures: list[str] = []
    passed = 0
    validated_apis: set[str] = set()

    print(f"Mini-game API validation: profile={profile_name} root={root}")
    for check in checks:
        if not isinstance(check, dict):
            failures.append(f"invalid check entry: {check!r}")
            continue
        rel_path = check.get("path")
        contains = check.get("contains", [])
        label = str(check.get("label", check.get("id", "<unknown>")))
        apis = check.get("apis", [])
        if not isinstance(rel_path, str) or not rel_path:
            failures.append(f"{label}: missing path")
            continue
        if not isinstance(contains, list) or not all(isinstance(item, str) for item in contains):
            failures.append(f"{label}: invalid contains list")
            continue

        file_path = root / rel_path
        if not file_path.is_file():
            failures.append(f"{label}: missing file {file_path}")
            continue

        text = read_text(file_path)
        missing_tokens = [token for token in contains if token not in text]
        if missing_tokens:
            failures.append(
                f"{label}: missing markers in {file_path}: {', '.join(missing_tokens)}"
            )
            continue

        passed += 1
        if isinstance(apis, list):
            validated_apis.update(str(api) for api in apis)
        print(f"  OK {label} [{rel_path}]")

    if failures:
        print("Mini-game API validation: FAILED", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print(
        "Mini-game API validation: OK (%d checks, %d API markers)"
        % (passed, len(validated_apis))
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate mini-game platform API coverage for shared export artifacts."
    )
    parser.add_argument("--profile", required=True, help="Platform profile name from the matrix")
    parser.add_argument(
        "--artifact-root",
        required=True,
        help="Artifact root directory to validate, such as build/tt-minigame or build/wechat-minigame/minigame",
    )
    parser.add_argument(
        "--matrix",
        help="Optional override for the platform API matrix JSON",
    )
    args = parser.parse_args()

    script_dir = Path(__file__).resolve().parent
    matrix_path = Path(args.matrix).resolve() if args.matrix else script_dir / "platform_api_matrix.json"
    artifact_root = Path(args.artifact_root).resolve()
    matrix = load_matrix(matrix_path)
    return validate_profile(args.profile, artifact_root, matrix)


if __name__ == "__main__":
    raise SystemExit(main())
