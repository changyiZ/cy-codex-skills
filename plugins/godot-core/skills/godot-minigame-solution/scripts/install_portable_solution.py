#!/usr/bin/env python3
from __future__ import annotations

import argparse
import ast
import re
import shutil
import subprocess
import sys
from pathlib import Path


AUTLOAD_SECTION = "autoload"
EDITOR_PLUGINS_SECTION = "editor_plugins"
WECHAT_SECTION = "wechat"
DOUYIN_SECTION = "douyin"


def parse_packed_string_array(raw: str) -> list[str]:
    match = re.fullmatch(r"PackedStringArray\((.*)\)", raw.strip(), re.DOTALL)
    if not match:
        return []
    inner = match.group(1).strip()
    if not inner:
        return []
    return list(ast.literal_eval("[" + inner + "]"))


def format_packed_string_array(values: list[str]) -> str:
    encoded = ", ".join(f'"{value}"' for value in values)
    return f"PackedStringArray({encoded})"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def derive_app_name(project_root: Path) -> str:
    project_file = project_root / "project.godot"
    if not project_file.exists():
        return "Godot Mini-game"
    content = read_text(project_file)
    match = re.search(r'^\s*config/name="([^"]+)"\s*$', content, re.MULTILINE)
    return match.group(1) if match else "Godot Mini-game"


def find_section_bounds(lines: list[str], section_name: str) -> tuple[int | None, int | None]:
    header = f"[{section_name}]"
    start: int | None = None
    for index, line in enumerate(lines):
        if line.strip() == header:
            start = index
            break
    if start is None:
        return None, None
    end = len(lines)
    for index in range(start + 1, len(lines)):
        stripped = lines[index].strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            end = index
            break
    return start, end


def ensure_section(lines: list[str], section_name: str) -> tuple[int, int]:
    start, end = find_section_bounds(lines, section_name)
    if start is not None and end is not None:
        return start, end
    if lines and lines[-1] != "\n":
        if not lines[-1].endswith("\n"):
            lines[-1] = lines[-1] + "\n"
        lines.append("\n")
    lines.extend([f"[{section_name}]\n", "\n"])
    return find_section_bounds(lines, section_name)


def ensure_key(
    lines: list[str],
    *,
    section_name: str,
    key: str,
    value: str,
    replace_existing: bool,
    warnings: list[str],
) -> None:
    start, end = ensure_section(lines, section_name)
    prefix = f"{key}="
    for index in range(start + 1, end):
        stripped = lines[index].strip()
        if not stripped or stripped.startswith(";") or stripped.startswith("#"):
            continue
        if stripped.startswith(prefix):
            if replace_existing:
                lines[index] = f"{key}={value}\n"
            elif stripped != f"{key}={value}":
                warnings.append(f"Kept existing {section_name}.{key}")
            return
    insert_at = end
    if insert_at > start + 1 and lines[insert_at - 1].strip():
        lines.insert(insert_at, "\n")
        insert_at += 1
    lines.insert(insert_at, f"{key}={value}\n")


def ensure_packed_array_item(
    lines: list[str],
    *,
    section_name: str,
    key: str,
    item: str,
) -> None:
    start, end = ensure_section(lines, section_name)
    prefix = f"{key}="
    for index in range(start + 1, end):
        stripped = lines[index].strip()
        if stripped.startswith(prefix):
            values = parse_packed_string_array(stripped[len(prefix):])
            if item not in values:
                values.append(item)
                lines[index] = f"{key}={format_packed_string_array(values)}\n"
            return
    lines.insert(end, f'{key}={format_packed_string_array([item])}\n')


def update_project_settings(project_root: Path, app_name: str) -> list[str]:
    project_path = project_root / "project.godot"
    if not project_path.exists():
        raise SystemExit(f"missing project.godot: {project_path}")

    warnings: list[str] = []
    lines = project_path.read_text(encoding="utf-8").splitlines(keepends=True)

    ensure_key(
        lines,
        section_name=AUTLOAD_SECTION,
        key="PlatformServices",
        value='"*res://autoload/PlatformServices.gd"',
        replace_existing=False,
        warnings=warnings,
    )
    ensure_key(
        lines,
        section_name=AUTLOAD_SECTION,
        key="tt",
        value='"*res://autoload/TTBridge.gd"',
        replace_existing=False,
        warnings=warnings,
    )
    ensure_packed_array_item(
        lines,
        section_name=EDITOR_PLUGINS_SECTION,
        key="enabled",
        item="res://addons/ttsdk.editor/plugin.cfg",
    )
    ensure_packed_array_item(
        lines,
        section_name=EDITOR_PLUGINS_SECTION,
        key="enabled",
        item="res://addons/godot-minigame/plugin.cfg",
    )
    ensure_key(
        lines,
        section_name=WECHAT_SECTION,
        key="app_id",
        value='""',
        replace_existing=False,
        warnings=warnings,
    )
    ensure_key(
        lines,
        section_name=WECHAT_SECTION,
        key="rewarded_revive_ad_unit_id",
        value='""',
        replace_existing=False,
        warnings=warnings,
    )
    ensure_key(
        lines,
        section_name=WECHAT_SECTION,
        key="share_title",
        value=f'"{app_name}"',
        replace_existing=False,
        warnings=warnings,
    )
    ensure_key(
        lines,
        section_name=WECHAT_SECTION,
        key="share_image_url",
        value='""',
        replace_existing=False,
        warnings=warnings,
    )
    ensure_key(
        lines,
        section_name=DOUYIN_SECTION,
        key="app_id",
        value='""',
        replace_existing=False,
        warnings=warnings,
    )
    ensure_key(
        lines,
        section_name=DOUYIN_SECTION,
        key="rewarded_revive_ad_unit_id",
        value='""',
        replace_existing=False,
        warnings=warnings,
    )
    ensure_key(
        lines,
        section_name=DOUYIN_SECTION,
        key="interstitial_level_end_ad_unit_id",
        value='""',
        replace_existing=False,
        warnings=warnings,
    )

    project_path.write_text("".join(lines), encoding="utf-8")
    return warnings


def copy_tree(
    source_root: Path,
    destination_root: Path,
    *,
    overwrite_existing: bool,
    exclude_top_level: set[str] | None = None,
) -> tuple[list[str], list[str]]:
    installed: list[str] = []
    skipped: list[str] = []
    excluded = exclude_top_level or set()
    for source_path in sorted(source_root.rglob("*")):
        relative_path = source_path.relative_to(source_root)
        if relative_path.parts and relative_path.parts[0] in excluded:
            continue
        destination_path = destination_root / relative_path
        if source_path.is_dir():
            destination_path.mkdir(parents=True, exist_ok=True)
            continue
        destination_path.parent.mkdir(parents=True, exist_ok=True)
        if destination_path.exists() and not overwrite_existing:
            skipped.append(relative_path.as_posix())
            continue
        shutil.copy2(source_path, destination_path)
        installed.append(relative_path.as_posix())
    return installed, skipped


def install_makefile_fragment(project_root: Path, template_root: Path, overwrite_existing: bool) -> str | None:
    source_path = template_root / "templates" / "Makefile.minigame.mk"
    destination_path = project_root / "Makefile.minigame.mk"
    if destination_path.exists() and not overwrite_existing:
        return None
    shutil.copy2(source_path, destination_path)
    return str(destination_path.relative_to(project_root))


def run_export_preset_setup(script_root: Path, project_root: Path) -> None:
    subprocess.run(
        [sys.executable, str(script_root / "ensure_export_presets.py"), "--project-root", str(project_root)],
        check=True,
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", required=True)
    parser.add_argument("--app-name")
    parser.add_argument("--overwrite-existing", action="store_true")
    parser.add_argument("--skip-export-presets", action="store_true")
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    if not (project_root / "project.godot").exists():
        raise SystemExit(f"target does not look like a Godot project: {project_root}")

    skill_root = Path(__file__).resolve().parents[1]
    assets_root = skill_root / "assets"
    addon_root = assets_root / "portable_solution" / "addons"
    template_root = assets_root / "project_template"

    installed_addons, skipped_addons = copy_tree(
        addon_root,
        project_root / "addons",
        overwrite_existing=args.overwrite_existing,
    )
    installed_template, skipped_template = copy_tree(
        template_root,
        project_root,
        overwrite_existing=args.overwrite_existing,
        exclude_top_level={"templates"},
    )
    makefile_fragment = install_makefile_fragment(
        project_root,
        template_root,
        overwrite_existing=args.overwrite_existing,
    )

    app_name = args.app_name or derive_app_name(project_root)
    project_warnings = update_project_settings(project_root, app_name)
    if not args.skip_export_presets:
        run_export_preset_setup(skill_root / "scripts", project_root)

    print(f"Installed portable mini-game solution into {project_root}")
    print(f"App name baseline: {app_name}")
    print(f"Addon files copied: {len(installed_addons)}")
    print(f"Template files copied: {len(installed_template)}")
    if skipped_addons:
        print("Skipped existing addon files:")
        for path in skipped_addons[:20]:
            print(f"  - {path}")
        if len(skipped_addons) > 20:
            print(f"  - ... {len(skipped_addons) - 20} more")
    if skipped_template:
        print("Skipped existing template files:")
        for path in skipped_template:
            print(f"  - {path}")
    if makefile_fragment is not None:
        print(f"Installed Makefile fragment: {makefile_fragment}")
    else:
        print("Kept existing Makefile.minigame.mk")
    if project_warnings:
        print("Project setting warnings:")
        for warning in project_warnings:
            print(f"  - {warning}")
    if args.skip_export_presets:
        print("Export preset generation skipped.")
    else:
        print("Export presets ensured.")


if __name__ == "__main__":
    main()
