#!/usr/bin/env python3
"""Render reusable platform API probe templates as query strings or JSON."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any
from urllib.parse import urlencode


ROOT = Path(__file__).resolve().parent
TEMPLATE_PATH = ROOT / "platform_api_probe_templates.json"


QUERY_KEY_MAP = {
    "allow_ui": "api_probe_ui",
    "request_url": "api_probe_request_url",
    "socket_url": "api_probe_socket_url",
    "subpackage_name": "api_probe_subpackage",
    "report_scene_id": "api_probe_scene_id",
    "rewarded_placement": "api_probe_rewarded_placement",
    "share_query": "api_probe_share_query",
    "share_path": "api_probe_share_path",
    "temp_path": "api_probe_temp_path",
    "timeout_ms": "api_probe_timeout_ms",
}


def load_templates() -> dict[str, Any]:
    return json.loads(TEMPLATE_PATH.read_text(encoding="utf-8"))


def resolve_platform(payload: dict[str, Any], requested: str) -> tuple[str, dict[str, Any]]:
    normalized = requested.strip().lower()
    platforms = payload.get("platforms", {})
    for name, config in platforms.items():
        aliases = [name] + list(config.get("aliases", []))
        if normalized in [alias.strip().lower() for alias in aliases]:
            return name, config
    raise KeyError(f"unknown platform template set: {requested}")


def render_query(options: dict[str, Any]) -> str:
    params: list[tuple[str, str]] = [("api_probe", "1")]
    calls = options.get("calls", [])
    if isinstance(calls, list) and calls:
        params.append(("api_probe_calls", ",".join(str(call) for call in calls)))
    for key, query_key in QUERY_KEY_MAP.items():
        if key not in options:
            continue
        value = options[key]
        if key == "allow_ui":
            if bool(value):
                params.append((query_key, "1"))
            continue
        if value is None:
            continue
        params.append((query_key, str(value)))
    return urlencode(params, safe=",:/_")


def _gdscript_scalar(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return "null"
    if isinstance(value, (int, float)):
        return str(value)
    return json.dumps(str(value), ensure_ascii=True)


def _gdscript_value(value: Any, indent: int = 0) -> str:
    padding = " " * indent
    if isinstance(value, dict):
        if not value:
            return "{}"
        lines = ["{"]
        items = list(value.items())
        for index, (key, nested) in enumerate(items):
            suffix = "," if index < len(items) - 1 else ""
            lines.append(f'{padding}    "{key}": {_gdscript_value(nested, indent + 4)}{suffix}')
        lines.append(f"{padding}}}")
        return "\n".join(lines)
    if isinstance(value, list):
        if not value:
            return "[]"
        lines = ["["]
        for index, nested in enumerate(value):
            suffix = "," if index < len(value) - 1 else ""
            lines.append(f"{padding}    {_gdscript_value(nested, indent + 4)}{suffix}")
        lines.append(f"{padding}]")
        return "\n".join(lines)
    return _gdscript_scalar(value)


def render_gdscript_call(options: dict[str, Any]) -> str:
    return "await PlatformServices.run_platform_api_probe(%s)" % _gdscript_value(options)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--platform", required=True, help="Platform name or alias, e.g. wechat, wx, douyin, tt.")
    parser.add_argument("--template", help="Template name to render. Omit with --list.")
    parser.add_argument("--format", choices=("query", "json", "gdscript"), default="query", help="Output format.")
    parser.add_argument("--list", action="store_true", help="List available templates for the platform.")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    payload = load_templates()
    platform_name, config = resolve_platform(payload, args.platform)
    templates = config.get("templates", {})

    if args.list:
        for template_name, template in templates.items():
            description = str(template.get("description", "")).strip()
            print(f"{platform_name}:{template_name} - {description}")
        return 0

    if not args.template:
        parser.error("--template is required unless --list is used")

    template = templates.get(args.template)
    if template is None:
        available = ", ".join(sorted(templates.keys()))
        raise KeyError(f"unknown template '{args.template}' for platform '{platform_name}', available: {available}")

    options = template.get("options", {})
    if args.format == "json":
        print(json.dumps(options, ensure_ascii=True, indent=2, sort_keys=True))
    elif args.format == "gdscript":
        print(render_gdscript_call(options))
    else:
        print(render_query(options))
    notes = template.get("notes", [])
    if notes:
        print("")
        print("Notes:")
        for note in notes:
            print(f"- {note}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
