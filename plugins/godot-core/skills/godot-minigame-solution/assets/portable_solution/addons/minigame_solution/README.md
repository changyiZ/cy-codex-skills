# Minigame Solution Package

This addon directory is the repo-local source of truth for the reusable Godot mini-game adaptation stack.

Structure:
- `godot_contract/`: shared GDScript platform contract and project manifest helpers
- `wechat/`: repo-owned WeChat shell, Web-export assembly, and WeChat smoke checks
- `douyin/`: Douyin export overlay, vendor verification, and export/smoke helpers
- `validation/`: shared platform API capability matrix plus artifact validator used by WeChat and Douyin smoke checks

Project-local wrappers stay under `platform/`, `tools/`, and `Makefile`.

The reusable runtime probe contract is split across:
- `autoload/PlatformServices.gd`: shared gameplay-facing entrypoint via `run_platform_api_probe()`
- `addons/minigame_solution/wechat/template/js/platform-api-probe.js`: WeChat shell-local probe bridge exposed as `globalThis.godotMinigameProbe`
- `addons/minigame_solution/douyin/runtime/platform-api-probe.js`: Douyin runtime probe bridge exposed as `globalThis.godotMinigameProbe`

Probe execution can be triggered from code or from launch query flags such as `api_probe=1` and `api_probe_calls=...`, so validation stays reusable and does not depend on project-specific debug UI.

Reusable template assets live under:
- `addons/minigame_solution/validation/platform_api_probe_templates.json`
- `addons/minigame_solution/validation/render_platform_api_probe_template.py`
- `addons/minigame_solution/validation/manual_acceptance_checklist.md`
- `addons/minigame_solution/validation/platform_api_probe_playbook.md`

This repo also keeps a thin project wrapper at `tools/minigame_probe_template.py` plus `make probe-template` so current-project values can be filled without changing the shared template contract.
