# Changelog

Last verified: 2026-04-10

## 0.2.0

- Merged the validated mini-game suite into the plugin: `godot-minigame-solution`, `godot-wechat-minigame`, and `godot-douyin-minigame`.
- Made `/Users/cY/.codex/skills/godot-minigame-solution`, `/Users/cY/.codex/skills/godot-wechat-minigame`, `/Users/cY/.codex/skills/godot-douyin-minigame`, and the matching `/Users/cY/dev/skills/...` paths symlinks back to the plugin copies so `godot-core` is the single maintained distribution surface.
- Expanded plugin metadata and `llms` docs to include the new WeChat/Douyin mini-game specialist workflows.
- Kept the bundled mini-game installer, upgrade monitor, and portable asset payload inside the plugin-managed copies.

## 0.1.0

- Initial `godot-core` plugin scaffold under `/Users/cY/.codex/plugins/godot-core`.
- Added four public skills: `godot-bug-triage`, `godot-feature-impl`, `godot-scene-refactor`, and `godot-export-release`.
- Retained validated specialized Godot skills in the plugin: `godot-core`, `godot-web-export`, and `godot-web-cjk-font-fix`.
- Removed `godot-mini-game` from the active plugin surface because it is not yet validated.
- Removed `godot-ai-coding-accelerator` because it was only a legacy compatibility router for the old monolithic setup.
- Replaced legacy standalone copies in `/Users/cY/.codex/skills` and `/Users/cY/dev/skills` with symlinks back to the plugin so the plugin is the single maintained copy.
- Added plugin-level LLM docs: `llms.txt`, `llms-medium.txt`, `llms-full.txt`, and [docs/llms.md](/Users/cY/.codex/plugins/godot-core/docs/llms.md).
- Added research and governance docs for source policy, architecture principles, and official pattern cases.
- Added eval prompt sets for the active plugin skills and rubric checklists for `godot-scene-refactor`, `godot-export-release`, `godot-web-export`, and `godot-web-cjk-font-fix`.
- Replaced cloud-publish TODO metadata with explicit local-only metadata and posture.
- Added a local maintenance script for cache sync, static validation, and optional smoke routing.
- Deliberately deferred packaged MCP, app integrations, and branded assets.
