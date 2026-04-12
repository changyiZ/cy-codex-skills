# Godot MCP v1 Candidate Surface

Last verified: 2026-03-30

Primary sources:
- https://developers.openai.com/codex/concepts/customization/#mcp
- https://developers.openai.com/codex/plugins/build
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html
- https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_web.html

This plugin does not package `.mcp.json` or a server in v0.1. The goal here is to document a stable future boundary before any MCP is distributed.

## Candidate resources

- `godot://scene_catalog`
- `godot://autoloads`
- `godot://input_map`
- `godot://export_presets`
- `godot://latest_build_log`
- `godot://latest_test_report`

## Candidate tools

- `godot_import_project`
- `godot_run_smoke`
- `godot_export_build`
- `godot_inspect_scene_refs`

## Non-goals for v1 MCP

- no direct live editor manipulation
- no generic `run_any_command`
- no destructive project mutation without explicit approval layers
- no duplication of local file reads that the skill can already perform

## Packaging rule

Keep MCP out of the plugin until the server boundary is stable and clearly more useful than local repo inspection.
