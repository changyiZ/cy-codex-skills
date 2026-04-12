#!/usr/bin/env python3
from __future__ import annotations

import argparse
import contextlib
import subprocess
import sys
from pathlib import Path


def path_arg(path: Path, cwd: Path) -> str:
    try:
        return str(path.relative_to(cwd))
    except ValueError:
        return str(path)


def sanitize_project_text(text: str) -> str:
    lines = text.splitlines()
    result: list[str] = []
    in_editor_plugins = False
    wrote_enabled = False

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            if in_editor_plugins and not wrote_enabled:
                result.append('enabled=PackedStringArray()')
            in_editor_plugins = stripped == "[editor_plugins]"
            wrote_enabled = False
            result.append(line)
            continue
        if in_editor_plugins and line.startswith("enabled="):
            result.append('enabled=PackedStringArray()')
            wrote_enabled = True
            continue
        result.append(line)

    if in_editor_plugins and not wrote_enabled:
        result.append('enabled=PackedStringArray()')

    sanitized = "\n".join(result)
    if text.endswith("\n"):
        sanitized += "\n"
    return sanitized


@contextlib.contextmanager
def sanitized_export_state(project_root: Path):
    project_file = project_root / "project.godot"
    extension_list = project_root / ".godot" / "extension_list.cfg"
    hidden_editor_dirs = [
        project_root / "addons" / "ttsdk.editor",
        project_root / "addons" / "minigame_solution" / "douyin" / "overlay" / "ttsdk.editor",
    ]

    original_project = project_file.read_text(encoding="utf-8")
    project_changed = False
    extension_existed = extension_list.exists()
    original_extension_list = ""
    if extension_existed:
        original_extension_list = extension_list.read_text(encoding="utf-8")
    moved_dirs: list[tuple[Path, Path]] = []

    try:
        sanitized_project = sanitize_project_text(original_project)
        if sanitized_project != original_project:
            project_file.write_text(sanitized_project, encoding="utf-8")
            project_changed = True

        extension_list.parent.mkdir(parents=True, exist_ok=True)
        extension_list.write_text("", encoding="utf-8")
        for editor_dir in hidden_editor_dirs:
            if not editor_dir.exists():
                continue
            hidden_name = (
                "."
                + project_root.name
                + "-"
                + str(editor_dir.relative_to(project_root)).replace("/", "__")
                + ".export-hidden"
            )
            hidden_dir = project_root.parent / hidden_name
            if hidden_dir.exists():
                raise RuntimeError(f"wechat export: hidden editor dir already exists: {hidden_dir}")
            editor_dir.rename(hidden_dir)
            moved_dirs.append((editor_dir, hidden_dir))
        yield
    finally:
        for editor_dir, hidden_dir in reversed(moved_dirs):
            if hidden_dir.exists():
                hidden_dir.rename(editor_dir)
        if project_changed:
            project_file.write_text(original_project, encoding="utf-8")
        if extension_existed:
            extension_list.write_text(original_extension_list, encoding="utf-8")
        else:
            extension_list.unlink(missing_ok=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", required=True)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--preset", default="WeChat Web Base")
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--web-dir", default="build/web")
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    web_dir = Path(args.web_dir)
    if not web_dir.is_absolute():
        web_dir = project_root / web_dir
    output_dir = Path(args.output_dir)
    if not output_dir.is_absolute():
        output_dir = project_root / output_dir

    assemble_script = Path(__file__).resolve().with_name("assemble_wechat.py")
    if not assemble_script.exists():
        raise SystemExit(f"wechat export: missing assembler: {assemble_script}")

    web_dir.mkdir(parents=True, exist_ok=True)

    export_cmd = [
        args.godot,
        "--headless",
        "--path",
        ".",
        "--export-debug",
        args.preset,
        path_arg(web_dir / "index.html", project_root),
    ]
    with sanitized_export_state(project_root):
        subprocess.run(export_cmd, check=True, cwd=project_root)

    assemble_cmd = [
        sys.executable,
        str(assemble_script),
        "--project-root",
        str(project_root),
        "--web-dir",
        str(web_dir),
        "--output-dir",
        str(output_dir),
    ]
    subprocess.run(assemble_cmd, check=True, cwd=project_root)


if __name__ == "__main__":
    main()
