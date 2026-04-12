#!/usr/bin/env python3
from __future__ import annotations

import argparse
import configparser
import json
import shutil
from pathlib import Path


def read_plugin_metadata(path: Path) -> tuple[str, str]:
    parser = configparser.ConfigParser()
    parser.read(path, encoding="utf-8")
    if "plugin" not in parser:
        raise SystemExit(f"Douyin overlay: missing [plugin] section in {path}")
    section = parser["plugin"]
    name = section.get("name", "").strip().strip('"')
    version = section.get("version", "").strip().strip('"')
    return name, version


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", required=True)
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    douyin_root = Path(__file__).resolve().parents[1]
    manifest = json.loads((douyin_root / "overlay" / "manifest.json").read_text(encoding="utf-8"))

    vendor_config = manifest["vendor_plugin"]
    plugin_cfg = project_root / vendor_config["path"]
    if not plugin_cfg.exists():
        raise SystemExit(f"Douyin overlay: missing vendor plugin cfg {plugin_cfg}")

    name, version = read_plugin_metadata(plugin_cfg)
    if name != vendor_config["name"] or version != vendor_config["version"]:
        raise SystemExit(
            "Douyin overlay: unexpected vendor baseline "
            f"name={name!r} version={version!r}, expected "
            f"name={vendor_config['name']!r} version={vendor_config['version']!r}"
        )

    updated = 0
    for entry in manifest["overlay_files"]:
        source = douyin_root / entry["source"]
        target = project_root / entry["target"]
        if not source.exists():
            raise SystemExit(f"Douyin overlay: missing overlay source {source}")
        if not target.exists():
            raise SystemExit(f"Douyin overlay: missing overlay target {target}")
        source_text = source.read_text(encoding="utf-8")
        target_text = target.read_text(encoding="utf-8")
        if source_text != target_text:
            shutil.copy2(source, target)
            updated += 1

    print(
        "Douyin overlay: baseline verified",
        f"({name} {version}), synced {updated} overlay file(s).",
    )


if __name__ == "__main__":
    main()
