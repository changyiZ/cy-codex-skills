# Godot Minigame Baseline

This directory pins the upstream `godothub/godot-minigame` project as an editor-only baseline for the WeChat mini-game route.

Current repo policy:

- Runtime output is still assembled by repo-local scripts.
- Gameplay code must not depend on this add-on.
- The add-on exists to keep the upstream baseline visible, reproducible, and refreshable while the repo-owned WeChat shell evolves.

Pinned upstream metadata lives in `VENDORED_FROM.json`.

Current export entrypoint:

- `make export-wechat`

Current smoke entrypoint:

- `make wechat-smoke`
