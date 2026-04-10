#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


REQUIRED_FILES = (
    "addons/minigame_solution/wechat/scripts/export.py",
    "addons/minigame_solution/douyin/scripts/export.py",
    "addons/godot-minigame/plugin.cfg",
    "addons/ttsdk/plugin.cfg",
    "addons/ttsdk.editor/plugin.cfg",
    "autoload/PlatformServices.gd",
    "autoload/TTBridge.gd",
    "platform/PlatformBackend.gd",
    "platform/wechat/WeChatPlatformBackend.gd",
    "platform/douyin/DouyinPlatformBackend.gd",
    "platform/web_mock/WebPlatformBackend.gd",
    "tools/wechat/export_wechat.sh",
    "tools/wechat/smoke_test.sh",
    "tools/douyin/export.sh",
    "tools/douyin_smoke_test.sh",
    "data/minigame_subpackages.json",
)

REQUIRED_PROJECT_SECTIONS = ("autoload", "editor_plugins", "wechat", "douyin")
REQUIRED_EXPORT_PRESETS = ("Web", "WeChat Web Base", "Douyin")


def load_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def has_section(raw: str, name: str) -> bool:
    return re.search(rf"^\[{re.escape(name)}\]\s*$", raw, re.MULTILINE) is not None


def has_autoload(raw: str, name: str, target: str) -> bool:
    pattern = rf'^\s*{re.escape(name)}="\*?{re.escape(target)}"\s*$'
    return re.search(pattern, raw, re.MULTILINE) is not None


def has_preset(raw: str, name: str) -> bool:
    pattern = rf'^\s*name="{re.escape(name)}"\s*$'
    return re.search(pattern, raw, re.MULTILINE) is not None


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    errors: list[str] = []

    for relative_path in REQUIRED_FILES:
        if not (root / relative_path).exists():
            errors.append(f"missing file: {relative_path}")

    project_raw = load_text(root / "project.godot")
    if not project_raw:
        errors.append("missing file: project.godot")
    else:
        for section in REQUIRED_PROJECT_SECTIONS:
            if not has_section(project_raw, section):
                errors.append(f"missing project section: [{section}]")
        if not has_autoload(project_raw, "PlatformServices", "res://autoload/PlatformServices.gd"):
            errors.append("missing autoload: PlatformServices")
        if not has_autoload(project_raw, "tt", "res://autoload/TTBridge.gd"):
            errors.append("missing autoload: tt")

    export_raw = load_text(root / "export_presets.cfg")
    if not export_raw:
        errors.append("missing file: export_presets.cfg")
    else:
        for preset in REQUIRED_EXPORT_PRESETS:
            if not has_preset(export_raw, preset):
                errors.append(f"missing export preset: {preset}")

    manifest_path = root / "data" / "minigame_subpackages.json"
    if manifest_path.exists():
        try:
            json.loads(manifest_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            errors.append(f"invalid data/minigame_subpackages.json: {error}")

    if errors:
        print("Mini-game preflight failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print("Mini-game preflight: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
