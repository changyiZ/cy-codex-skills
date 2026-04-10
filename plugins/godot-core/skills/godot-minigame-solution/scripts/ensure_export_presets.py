#!/usr/bin/env python3
from __future__ import annotations

import argparse
import ast
import json
import re
from pathlib import Path
import configparser


WEB_PRESET = "Web"
WECHAT_PRESET = "WeChat Web Base"
DOUYIN_PRESET = "Douyin"


def strip_quotes(raw: str) -> str:
    value = raw.strip()
    if len(value) >= 2 and value[0] == '"' and value[-1] == '"':
        return value[1:-1]
    return value


def quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def parse_packed_string_array(raw: str) -> list[str]:
    match = re.fullmatch(r"PackedStringArray\((.*)\)", raw.strip(), re.DOTALL)
    if not match:
        return []
    inner = match.group(1).strip()
    if not inner:
        return []
    return list(ast.literal_eval("[" + inner + "]"))


def format_packed_string_array(values: list[str]) -> str:
    encoded = ", ".join(quote(value) for value in values)
    return f"PackedStringArray({encoded})"


def load_config(path: Path) -> configparser.RawConfigParser:
    config = configparser.RawConfigParser()
    config.optionxform = str
    if path.exists():
        config.read(path, encoding="utf-8")
    return config


def preset_indices(config: configparser.RawConfigParser) -> list[int]:
    indices: list[int] = []
    for section in config.sections():
        match = re.fullmatch(r"preset\.(\d+)(?:\.options)?", section)
        if match:
            indices.append(int(match.group(1)))
    return sorted(set(indices))


def preset_name_to_index(config: configparser.RawConfigParser) -> dict[str, int]:
    mapping: dict[str, int] = {}
    for index in preset_indices(config):
        section = f"preset.{index}"
        name = strip_quotes(config.get(section, "name", fallback=""))
        if name:
            mapping[name] = index
    return mapping


def ensure_preset_sections(config: configparser.RawConfigParser, name: str) -> tuple[str, str]:
    mapping = preset_name_to_index(config)
    if name in mapping:
        index = mapping[name]
    else:
        indices = preset_indices(config)
        index = 0 if not indices else max(indices) + 1
    section = f"preset.{index}"
    options_section = f"{section}.options"
    if not config.has_section(section):
        config.add_section(section)
    if not config.has_section(options_section):
        config.add_section(options_section)
    return section, options_section


def find_section_value(raw: str, section_name: str, key: str) -> str:
    section_match = re.search(
        rf"^\[{re.escape(section_name)}\]\s*$([\s\S]*?)(?=^\[|\Z)",
        raw,
        re.MULTILINE,
    )
    if not section_match:
        return ""
    section_body = section_match.group(1)
    key_match = re.search(rf'^\s*{re.escape(key)}=(.+?)\s*$', section_body, re.MULTILINE)
    if not key_match:
        return ""
    return strip_quotes(key_match.group(1))


def load_project_settings(project_root: Path) -> dict[str, str]:
    project_path = project_root / "project.godot"
    if not project_path.exists():
        raise SystemExit(f"missing project.godot: {project_path}")
    raw = project_path.read_text(encoding="utf-8")
    return {
        "douyin_app_id": find_section_value(raw, "douyin", "app_id"),
    }


def discover_web_shell(project_root: Path) -> str:
    shell_path = project_root / "web" / "index.html"
    return "res://web/index.html" if shell_path.exists() else ""


def discover_douyin_templates(project_root: Path) -> tuple[str, str]:
    debug_path = (project_root / "addons" / "ttsdk.editor" / "templates" / "web_debug.zip").resolve()
    release_path = (project_root / "addons" / "ttsdk.editor" / "templates" / "web_release.zip").resolve()
    debug_value = str(debug_path) if debug_path.exists() else ""
    release_value = str(release_path) if release_path.exists() else ""
    return debug_value, release_value


def collect_subpackage_entries(project_root: Path) -> list[dict[str, object]]:
    manifest_path = project_root / "data" / "minigame_subpackages.json"
    if not manifest_path.exists():
        return []
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    platforms = data.get("platforms", {})
    if not isinstance(platforms, dict):
        return []
    douyin = platforms.get("douyin", {})
    if not isinstance(douyin, dict):
        return []
    entries = douyin.get("subpackages", [])
    if not isinstance(entries, list):
        return []
    result: list[dict[str, object]] = []
    for entry in entries:
        if isinstance(entry, dict):
            result.append(entry)
    return result


def collect_subpackage_export_files(project_root: Path, root_value: str) -> list[str]:
    root_dir = (project_root / root_value).resolve()
    if not root_dir.exists():
        return []
    files = [
        "res://" + path.relative_to(project_root).as_posix()
        for path in sorted(root_dir.rglob("*"))
        if path.is_file()
    ]
    return files


def configure_web_preset(
    config: configparser.RawConfigParser,
    *,
    project_root: Path,
    preset_name: str,
    custom_features: str,
    export_path: str,
    runnable: bool,
) -> None:
    section, options_section = ensure_preset_sections(config, preset_name)
    shell_path = discover_web_shell(project_root)
    config.set(section, "name", quote(preset_name))
    config.set(section, "platform", quote("Web"))
    config.set(section, "runnable", "true" if runnable else "false")
    config.set(section, "dedicated_server", "false")
    config.set(section, "custom_features", quote(custom_features))
    config.set(section, "export_filter", quote("all_resources"))
    config.set(section, "export_files", format_packed_string_array([]))
    config.set(section, "include_filter", quote(""))
    config.set(section, "exclude_filter", quote(""))
    config.set(section, "export_path", quote(export_path))
    config.set(section, "patches", format_packed_string_array([]))
    config.set(section, "patch_delta_encoding", "false")
    config.set(section, "patch_delta_compression_level_zstd", "19")
    config.set(section, "patch_delta_min_reduction", "0.1")
    config.set(section, "patch_delta_include_filters", quote("*"))
    config.set(section, "patch_delta_exclude_filters", quote(""))
    config.set(section, "encryption_include_filters", quote(""))
    config.set(section, "encryption_exclude_filters", quote(""))
    config.set(section, "seed", "0")
    config.set(section, "encrypt_pck", "false")
    config.set(section, "encrypt_directory", "false")
    config.set(section, "script_export_mode", "1")

    config.set(options_section, "custom_template/debug", quote(""))
    config.set(options_section, "custom_template/release", quote(""))
    config.set(options_section, "variant/extensions_support", "false")
    config.set(options_section, "variant/thread_support", "false")
    config.set(options_section, "vram_texture_compression/for_desktop", "false")
    config.set(options_section, "vram_texture_compression/for_mobile", "true")
    config.set(options_section, "html/export_icon", "false")
    config.set(options_section, "html/custom_html_shell", quote(shell_path))
    config.set(options_section, "html/head_include", quote(""))
    config.set(options_section, "html/canvas_resize_policy", "2")
    config.set(options_section, "html/focus_canvas_on_start", "true")
    config.set(options_section, "html/experimental_virtual_keyboard", "true")
    config.set(options_section, "progressive_web_app/enabled", "false")
    config.set(options_section, "progressive_web_app/ensure_cross_origin_isolation_headers", "true")
    config.set(options_section, "progressive_web_app/offline_page", quote(""))
    config.set(options_section, "progressive_web_app/display", "1")
    config.set(options_section, "progressive_web_app/orientation", "0")
    config.set(options_section, "progressive_web_app/icon_144x144", quote(""))
    config.set(options_section, "progressive_web_app/icon_180x180", quote(""))
    config.set(options_section, "progressive_web_app/icon_512x512", quote(""))
    config.set(options_section, "progressive_web_app/background_color", "Color(0, 0, 0, 1)")
    config.set(options_section, "threads/emscripten_pool_size", "8")
    config.set(options_section, "threads/godot_pool_size", "4")


def configure_douyin_preset(
    config: configparser.RawConfigParser,
    *,
    project_root: Path,
    app_id: str,
    has_subpackages: bool,
) -> None:
    section, options_section = ensure_preset_sections(config, DOUYIN_PRESET)
    debug_template, release_template = discover_douyin_templates(project_root)

    config.set(section, "name", quote(DOUYIN_PRESET))
    config.set(section, "platform", quote("tt-minigame"))
    config.set(section, "runnable", "false")
    config.set(section, "advanced_options", "false")
    config.set(section, "dedicated_server", "false")
    config.set(section, "custom_features", quote("douyin_minigame"))
    config.set(section, "export_filter", quote("all_resources"))
    config.set(section, "export_files", format_packed_string_array([]))
    config.set(section, "include_filter", quote(""))
    config.set(section, "exclude_filter", quote(""))
    config.set(section, "export_path", quote("build/tt-minigame/project.config.json"))
    config.set(section, "patches", format_packed_string_array([]))
    config.set(section, "encryption_include_filters", quote(""))
    config.set(section, "encryption_exclude_filters", quote(""))
    config.set(section, "seed", "0")
    config.set(section, "encrypt_pck", "false")
    config.set(section, "encrypt_directory", "false")
    config.set(section, "script_export_mode", "1")

    config.set(options_section, "douyin/app_id", quote(app_id))
    config.set(options_section, "douyin/canvas_resize_policy", "0")
    config.set(options_section, "douyin/device_device_orientation", "0")
    config.set(options_section, "douyin/subpackage_on", "true" if has_subpackages else "false")
    config.set(options_section, "douyin/custom_game_js", "false")
    config.set(options_section, "douyin/douyin_developer_tool", quote(""))
    config.set(options_section, "douyin/extensions_support", "false")
    config.set(options_section, "douyin_debug/remote_debugger_on", "false")
    config.set(options_section, "douyin_debug/remote_debugger_url", quote("ws://127.0.0.1:6007"))
    config.set(options_section, "douyin_debug/settings_debug_id", quote(""))
    config.set(options_section, "douyin_optimize/brotli_on", "true")
    config.set(options_section, "douyin_optimize/brotli_policy", "2")
    config.set(options_section, "douyin_custom_template/debug", quote(debug_template))
    config.set(options_section, "douyin_custom_template/release", quote(release_template))
    config.set(options_section, "douyin_exeprimental/audio_context", "false")


def configure_subpackage_preset(
    config: configparser.RawConfigParser,
    *,
    project_root: Path,
    entry: dict[str, object],
) -> None:
    name = str(entry.get("name", "")).strip()
    if not name:
        return
    preset_name = str(entry.get("export_preset", "")).strip() or f"Douyin Subpackage {name}"
    export_files = collect_subpackage_export_files(project_root, str(entry.get("root", "")).strip())
    export_path = str(entry.get("pack_path", "")).strip() or f"build/tt-minigame/subpackages/{name}/data.pck"

    section, options_section = ensure_preset_sections(config, preset_name)
    config.set(section, "name", quote(preset_name))
    config.set(section, "platform", quote("tt-minigame-subpackage"))
    config.set(section, "runnable", "false")
    config.set(section, "dedicated_server", "false")
    config.set(section, "custom_features", quote(""))
    config.set(section, "export_filter", quote("resources"))
    config.set(section, "export_files", format_packed_string_array(export_files))
    config.set(section, "include_filter", quote(""))
    config.set(section, "exclude_filter", quote(""))
    config.set(section, "export_path", quote(export_path))
    config.set(section, "patches", format_packed_string_array([]))
    config.set(section, "patch_delta_encoding", "false")
    config.set(section, "patch_delta_compression_level_zstd", "19")
    config.set(section, "patch_delta_min_reduction", "0.1")
    config.set(section, "patch_delta_include_filters", quote("*"))
    config.set(section, "patch_delta_exclude_filters", quote(""))
    config.set(section, "encryption_include_filters", quote(""))
    config.set(section, "encryption_exclude_filters", quote(""))
    config.set(section, "seed", "0")
    config.set(section, "encrypt_pck", "false")
    config.set(section, "encrypt_directory", "false")
    config.set(section, "script_export_mode", "1")

    config.set(options_section, "douyin/project_config_file", quote("build/tt-minigame/project.config.json"))
    config.set(options_section, "douyin/subpackage_name", quote(name))
    config.set(options_section, "douyin_optimize/brotli_on", "true")
    config.set(options_section, "douyin_optimize/brotli_policy", "2")


def write_config(path: Path, config: configparser.RawConfigParser) -> None:
    with path.open("w", encoding="utf-8") as handle:
        config.write(handle, space_around_delimiters=False)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", required=True)
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    project_settings = load_project_settings(project_root)
    export_path = project_root / "export_presets.cfg"
    config = load_config(export_path)

    configure_web_preset(
        config,
        project_root=project_root,
        preset_name=WEB_PRESET,
        custom_features="web_mock",
        export_path="build/web/index.html",
        runnable=True,
    )
    configure_web_preset(
        config,
        project_root=project_root,
        preset_name=WECHAT_PRESET,
        custom_features="wechat_minigame",
        export_path="build/web-wechat/index.html",
        runnable=False,
    )

    subpackage_entries = collect_subpackage_entries(project_root)
    configure_douyin_preset(
        config,
        project_root=project_root,
        app_id=project_settings.get("douyin_app_id", ""),
        has_subpackages=bool(subpackage_entries),
    )
    for entry in subpackage_entries:
        configure_subpackage_preset(config, project_root=project_root, entry=entry)

    write_config(export_path, config)
    print(f"Ensured export presets at {export_path}")


if __name__ == "__main__":
    main()
