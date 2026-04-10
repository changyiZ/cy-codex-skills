# Godot Core

Last verified: 2026-04-10

Primary sources:
- https://developers.openai.com/codex/plugins/build
- https://developers.openai.com/codex/concepts/customization/#skills
- https://developers.openai.com/codex/skills/#best-practices
- https://docs.godotengine.org/en/stable/
- https://godotengine.org/download/archive/
- https://github.com/godotengine/godot-demo-projects
- https://pixijs.com/llms

`godot-core` is a Codex plugin package for repeatable Godot workflows. It combines the core Godot implementation and Web specialist skills with a bundled WeChat/Douyin mini-game adaptation suite so the plugin becomes the single distribution surface for reusable Godot guidance.

This plugin is intentionally local-only for now. Cloud publication, public branding, and broader distribution stay deferred until routing and validation are stable enough.

## Package and install

This repository stores the packaged plugin at `plugins/godot-core`.

To use it as a local Codex plugin, copy or symlink that directory to `~/.codex/plugins/godot-core`, then register it in `~/.agents/plugins/marketplace.json` or reuse this repo's `.agents/plugins/marketplace.json` as the source template.

After editing the plugin, restart Codex so the marketplace and local plugin copy are reloaded.

For repeatable local maintenance, use:

- `bash scripts/local_plugin_maintenance.sh sync`
- `bash scripts/local_plugin_maintenance.sh validate`
- `bash scripts/local_plugin_maintenance.sh smoke /Users/cY/dev/godot/game0226 game0226`

## Included skills

Core workflow skills:

- `godot-bug-triage`: isolate runtime, scene-loading, editor, and export failures and push toward the smallest defensible fix.
- `godot-feature-impl`: implement ordinary gameplay, UI, and systems work with project-aware validation.
- `godot-scene-refactor`: explicit-only scene tree, node path, signal, and scene-path refactors.
- `godot-export-release`: explicit-only export and release workflow for preset-driven builds.

Specialized and compatibility skills:

- `godot-core`: umbrella Godot workflow with plan-first validation gates and routing to more specific specialist skills when needed.
- `godot-web-export`: Godot Web export and deployment workflow with thread, hosting, and browser runtime checks.
- `godot-web-cjk-font-fix`: targeted workflow for Godot Web Chinese, Japanese, and Korean font rendering failures.
- `godot-minigame-solution`: router skill for shared WeChat/Douyin mini-game adoption, refresh, validation, and upstream monitoring.
- `godot-wechat-minigame`: WeChat-specific export, validation, and runtime-triage workflow.
- `godot-douyin-minigame`: Douyin-specific exporter, validation, and runtime-triage workflow.

## Consolidation status

- Useful standalone Godot skills from the local skills workspace were merged into this plugin and now live under `plugins/godot-core/skills`.
- The mini-game suite now also lives under the plugin: `godot-minigame-solution`, `godot-wechat-minigame`, and `godot-douyin-minigame`.
- Legacy standalone locations in the local Codex setup were cleaned up into symlinks that point back to the plugin copies.
- `godot-ai-coding-accelerator` was removed because it only served as a legacy compatibility router and is now superseded by the plugin plus the remaining focused skills.
- `godot-mini-game-wechat` remains separate because it is a project/framework workspace, not a Codex skill.

## Source of truth

This plugin follows a strict source order:

1. OpenAI official Codex plugin, skills, MCP, and best-practices documentation for packaging, skill design, and evaluation shape.
2. Godot official stable documentation and class reference for engine behavior and export facts.
3. Godot official tutorials and `godot-demo-projects` for runnable patterns.
4. Pixi `llms` pages for document structure only, not for Godot technical facts.
5. Local `godot-*` skills only as reusable experience until they are merged into the plugin-managed copies.

See [docs/reference-policy.md](docs/reference-policy.md).

## LLM docs

The plugin root exposes three machine-friendly entrypoints plus a human landing page:

- [llms.txt](llms.txt): quick routing index.
- [llms-medium.txt](llms-medium.txt): workflow defaults and boundaries.
- [llms-full.txt](llms-full.txt): fuller plugin context pack.
- [docs/llms.md](docs/llms.md): how the files are intended to be used.

## Project adaptation expectations

This plugin is not a substitute for per-project context. The Godot project should still provide:

- `AGENTS.md` with commands, constraints, and done criteria.
- project docs such as architecture, scene catalog, autoloads, input map, and export matrix.
- reproducible verification commands such as import, smoke, test, or export scripts.

## Validation and evals

`evals/` currently covers the pre-existing seven plugin skills. The first goal remains routing stability, not benchmark scale. Rubric checklists currently exist for the higher-risk skills: `godot-scene-refactor`, `godot-export-release`, `godot-web-export`, and `godot-web-cjk-font-fix`. The newly merged mini-game skills are carried into the plugin based on project-backed validation and durable repo evidence, but they do not yet have matching plugin-local eval CSVs or rubric files.

The maintained general Godot validation workspace is `/Users/cY/dev/godot/game0226`. The mini-game specialization is backed separately by `/Users/cY/dev/godot/game0330` and `/Users/cY/dev/godot/game0213`, which now also feed the plugin-managed mini-game skills.

See [evals/README.md](evals/README.md).

## Non-goals in v0.2

- No `.mcp.json` is shipped yet.
- No app integrations are bundled.
- No cloud publication target is maintained in v0.1. This remains a local-only plugin until validation passes.
- `godot-mini-game-wechat` is not bundled because it is not a skill package.
