#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

import yaml


ACTIVE_SKILLS = {
    "godot-bug-triage",
    "godot-core",
    "godot-export-release",
    "godot-feature-impl",
    "godot-scene-refactor",
    "godot-web-cjk-font-fix",
    "godot-web-export",
}
REQUIRED_FIELDS = {
    "id",
    "skill",
    "summary",
    "prompt",
    "workspace",
    "validation_commands",
}


def main() -> int:
    plugin_root = Path(sys.argv[1]).resolve()
    tasks_dir = plugin_root / "evals" / "tasks" / "game0226"
    if not tasks_dir.exists():
        raise SystemExit(f"Missing task catalog directory: {tasks_dir}")

    manifests = sorted(tasks_dir.glob("*.yaml"))
    if not manifests:
        raise SystemExit(f"No task manifests found in: {tasks_dir}")

    seen_skills: set[str] = set()
    for path in manifests:
        data = yaml.safe_load(path.read_text())
        if not isinstance(data, dict):
            raise SystemExit(f"Task manifest is not a mapping: {path}")
        missing = REQUIRED_FIELDS - set(data)
        if missing:
            raise SystemExit(f"Task manifest missing fields {sorted(missing)}: {path}")

        skill = str(data["skill"])
        if skill not in ACTIVE_SKILLS:
            raise SystemExit(f"Unknown skill {skill!r} in {path}")
        seen_skills.add(skill)

        workspace = Path(str(data["workspace"]))
        if not workspace.is_absolute():
            raise SystemExit(f"Workspace must be absolute in {path}")
        if not workspace.exists():
            raise SystemExit(f"Workspace does not exist for {path}: {workspace}")

        validation_commands = data["validation_commands"]
        if not isinstance(validation_commands, list) or not validation_commands:
            raise SystemExit(f"validation_commands must be a non-empty list in {path}")
        if not all(isinstance(item, str) and item.strip() for item in validation_commands):
            raise SystemExit(f"validation_commands must contain non-empty strings in {path}")

    missing_skills = ACTIVE_SKILLS - seen_skills
    if missing_skills:
        raise SystemExit(f"Missing task manifests for skills: {sorted(missing_skills)}")

    print(f"Validated {len(manifests)} task manifests in {tasks_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
