---
name: pixi-wechat-minigame-adapter
description: Bootstrap a new PixiJS + Vite + TypeScript game onto the reusable WeChat mini-game path using the starter template, living playbook, and verification matrix from the source repository.
---

# Pixi WeChat Mini-Game Adapter

Use this skill when a PixiJS project does not yet have a WeChat mini-game target and needs to adopt the reusable adapter layer from `印灵排布`.

## Source of truth
- Starter template:
  - `/Users/cY/dev/games/game0307/templates/pixi-wechat-minigame/README.md`
- Standard solution:
  - `/Users/cY/dev/games/game0307/knowledge/project/pixi-wechat-minigame-standard-solution.md`
- Pitfalls:
  - `/Users/cY/dev/games/game0307/knowledge/project/pixi-wechat-minigame-pitfalls.md`
- Bootstrap checklist:
  - `/Users/cY/dev/games/game0307/knowledge/project/pixi-wechat-minigame-bootstrap-checklist.md`
- Verification matrix:
  - `/Users/cY/dev/games/game0307/knowledge/project/pixi-wechat-minigame-verification-matrix.md`

## When to use
Use this skill for:
1. adding a WeChat mini-game target to a new Pixi project
2. reusing the adapter-layer runtime fixes in another Pixi repo
3. standardizing build, debug, release, and audit flows for WeChat packaging
4. seeding a new project with the same evidence model for incomplete validation

Do not use this skill for:
1. existing dual-target maintenance when the target repo already has a healthy WeChat path
2. cross-engine reuse
3. publishing a generic npm package

For already-adapted dual-target repos, use the existing `pixi-web-wechat-dual-target` skill instead.

## Workflow
1. Preflight the target repo.
   - confirm it is PixiJS + Vite + TypeScript
   - confirm shared gameplay code can stay platform-neutral
   - confirm there is a clean `src/platform/` boundary or create one first
2. Copy the starter template.
   - take the files from `/Users/cY/dev/games/game0307/templates/pixi-wechat-minigame/`
   - keep the copied tests until equivalent coverage exists in the target repo
3. Adapt only the documented integration points.
   - bootstrap export path
   - design size and viewport assumptions
   - storage namespace
   - asset manifest and glyph-atlas aliases
   - `WX_MINIGAME_APPID`, `WX_MINIGAME_PROJECT_NAME`, `WX_MINIGAME_LIB_VERSION`
4. Keep all WeChat fixes in the adapter layer.
   - runtime prep belongs in `prepareWeChatRuntime.ts`
   - WebGL normalization belongs in `wechatWebGLCompat.ts`
   - lifecycle/storage/canvas ownership belongs in `WeChatPlatformBridge.ts`
   - packaging rules belong in `vite.wechat.config.ts` and `tools/build-wechat.mjs`
5. Run the minimum validation set.
   - `build:web`
   - `build:wechat`
   - `build:wechat:debug`
   - `audit:wechat`
   - runtime-prep, WebGL compat, build, audit, and glyph-atlas tests
6. Record the state honestly.
   - copy the verification-matrix model into the target repo
   - mark incomplete items as `partially_verified`, `pending_validation`, or `blocked_by_missing_device_or_tooling`
7. Write back new knowledge.
   - if a new runtime failure appears, add it to the target repo’s pitfalls doc
   - if the standard path changed, update the target repo’s standard solution and starter copy

## Hard rules
1. Do not hardcode `gameContext` paths into shared runtime code.
2. Do not patch gameplay hit testing to compensate for WeChat pointer bugs.
3. Do not reintroduce `CanvasRenderer` fallback as the default submission path.
4. Do not report missing device coverage as “verified”.
5. Do not leave new runtime learnings only in task chat or ad hoc notes.

## Deliverable checklist
1. target repo builds Web and WeChat debug/release outputs
2. target repo has a release audit command
3. target repo has a verification matrix
4. target repo has a pitfalls log for new failures
5. target repo clearly states which rows are still unverified
