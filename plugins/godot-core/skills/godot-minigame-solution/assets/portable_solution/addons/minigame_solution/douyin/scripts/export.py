#!/usr/bin/env python3
from __future__ import annotations

import argparse
from datetime import datetime
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


def run(command: list[str], *, cwd: Path) -> None:
    subprocess.run(command, check=True, cwd=cwd)


def load_douyin_subpackages(manifest_path: Path) -> list[dict[str, object]]:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    platforms = manifest.get("platforms", {})
    if not isinstance(platforms, dict):
        return []
    douyin = platforms.get("douyin", {})
    if not isinstance(douyin, dict):
        return []
    subpackages = douyin.get("subpackages", [])
    return [entry for entry in subpackages if isinstance(entry, dict)]


def clean_output_dir(output_dir: Path) -> None:
    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.parent.mkdir(parents=True, exist_ok=True)


def install_runtime_probe(output_dir: Path, douyin_root: Path) -> None:
    probe_source = douyin_root / "runtime" / "platform-api-probe.js"
    if not probe_source.exists():
        raise SystemExit(f"Douyin export: missing runtime probe {probe_source}")
    shutil.copy2(probe_source, output_dir / "platform-api-probe.js")

    game_js_path = output_dir / "game.js"
    source = game_js_path.read_text(encoding="utf-8")
    if "platform-api-probe" in source:
        return
    game_js_path.write_text("require('./platform-api-probe.js')\n" + source, encoding="utf-8")


def inject_build_stamp(game_js_path: Path, build_stamp: str) -> None:
    source = game_js_path.read_text(encoding="utf-8")
    marker = "[godot-tt] build stamp "
    if marker in source:
        return
    stamp_block = "\n".join(
        [
            "// Repo-owned Douyin build stamp.",
            "(function () {",
            f"  const buildStamp = {json.dumps(build_stamp, ensure_ascii=False)};",
            "  try {",
            "    console.log('[godot-tt] build stamp ' + buildStamp);",
            "    globalThis.__godotDouyinBuildStamp = buildStamp;",
            "    globalThis.godotMinigameRuntime = {",
            "      getPlatformName: function () {",
            "        return 'douyin_minigame';",
            "      },",
            "      getBuildStamp: function () {",
            "        return buildStamp;",
            "      },",
            "      getRuntimeJson: function () {",
            "        return '';",
            "      },",
            "    };",
            "  } catch (_error) {}",
            "})();",
            "",
        ]
    )
    game_js_path.write_text(stamp_block + source, encoding="utf-8")


def write_export_manifest(
    *,
    output_dir: Path,
    build_stamp: str,
    project_root: Path,
    douyin_root: Path,
    manifest_path: Path,
) -> None:
    overlay_manifest_path = douyin_root / "overlay" / "manifest.json"
    overlay_manifest = json.loads(overlay_manifest_path.read_text(encoding="utf-8"))
    root_files = sorted(str(path.relative_to(output_dir)) for path in output_dir.iterdir() if path.is_file())
    if "douyin-manifest.json" not in root_files:
        root_files.append("douyin-manifest.json")
        root_files.sort()
    godot_dir = output_dir / "godot"
    subpackages_dir = output_dir / "subpackages"
    export_manifest = {
        "route": "douyin",
        "build_stamp": build_stamp,
        "output_dir": str(output_dir.relative_to(project_root)),
        "overlay_source": str((douyin_root / "overlay" / "ttsdk.editor").relative_to(project_root)),
        "vendor_plugin": overlay_manifest.get("vendor_plugin", {}),
        "subpackage_manifest": str(manifest_path.relative_to(project_root)),
        "root_files": root_files,
        "godot_files": sorted(
            str(path.relative_to(output_dir)) for path in godot_dir.rglob("*") if path.is_file()
        )
        if godot_dir.is_dir()
        else [],
        "subpackage_files": sorted(
            str(path.relative_to(output_dir)) for path in subpackages_dir.rglob("*") if path.is_file()
        )
        if subpackages_dir.is_dir()
        else [],
    }
    (output_dir / "douyin-manifest.json").write_text(
        json.dumps(export_manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", required=True)
    parser.add_argument("--output-dir", default="build/tt-minigame")
    parser.add_argument("--godot-bin", default=os.environ.get("GODOT", "godot"))
    parser.add_argument("--manifest-path", default="data/minigame_subpackages.json")
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    output_dir = (project_root / args.output_dir).resolve()
    relative_output_dir = output_dir.relative_to(project_root)
    if relative_output_dir.as_posix() != "build/tt-minigame":
        raise SystemExit(
            "Douyin export currently expects output_dir=build/tt-minigame "
            "because the vendored exporter preset still points its subpackage project_config_file there."
        )
    build_stamp = datetime.now().astimezone().isoformat(timespec="seconds")

    manifest_path = (project_root / args.manifest_path).resolve()
    if not manifest_path.exists():
        raise SystemExit(f"Douyin export: missing manifest {manifest_path}")

    douyin_root = Path(__file__).resolve().parents[1]
    clean_output_dir(output_dir)
    run(
        [sys.executable, str(douyin_root / "scripts" / "sync_ttsdk_overlay.py"), "--project-root", str(project_root)],
        cwd=project_root,
    )

    run(
        [
            args.godot_bin,
            "--headless",
            "--export-release",
            "Douyin",
            str(relative_output_dir / "project.config.json"),
            "--path",
            ".",
        ],
        cwd=project_root,
    )

    for entry in load_douyin_subpackages(manifest_path):
        preset = str(entry.get("export_preset", "")).strip()
        pack_path = str(entry.get("pack_path", "")).strip()
        if not preset or not pack_path:
            raise SystemExit(f"Douyin export: invalid subpackage entry {entry}")
        run(
            [
                args.godot_bin,
                "--headless",
                "--export-pack",
                preset,
                str(relative_output_dir / pack_path),
                "--path",
                ".",
            ],
            cwd=project_root,
        )

    install_runtime_probe(output_dir, douyin_root)
    inject_build_stamp(output_dir / "game.js", build_stamp)
    write_export_manifest(
        output_dir=output_dir,
        build_stamp=build_stamp,
        project_root=project_root,
        douyin_root=douyin_root,
        manifest_path=manifest_path,
    )

    run(
        ["bash", str(douyin_root / "scripts" / "smoke_test.sh"), str(relative_output_dir), str(manifest_path)],
        cwd=project_root,
    )


if __name__ == "__main__":
    main()
