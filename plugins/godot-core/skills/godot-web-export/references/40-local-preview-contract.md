# 40-local-preview-contract.md - Canonical Local Web Preview Contract

## Goal

Every Godot Web project that expects iterative browser QA should expose a stable one-command local preview workflow.

## Preferred commands

- `make preview-web`
- `make stop-web-preview`

## Behavior contract

`make preview-web` should:

1. rebuild the Web export
2. stop the previous preview server only if it was started by the same project workflow
3. start a fresh local preview server on a stable URL, preferably `http://127.0.0.1:8000/`
4. serve the canonical `/index.wasm` path even if the export emitted only a compressed wasm file
5. disable browser cache for local validation, preferably with `Cache-Control: no-store`
6. print the URL, PID, and log path

`make stop-web-preview` should:

1. stop the current project-owned preview server
2. leave unrelated listeners untouched

## Implementation preference

- Put the restart logic in `tools/preview_web.sh`.
- Keep the server project-local and stateful through a PID file and log file.
- Refuse to kill unknown listeners occupying the preview port.
- Avoid making ad-hoc `python3 -m http.server` the default documented workflow.
- Prefer a tiny project-owned server wrapper when raw `http.server` cannot satisfy the wasm/compression/cache contract.

## Minimum Makefile shape

```make
preview-web: export-web
	bash tools/preview_web.sh restart

stop-web-preview:
	bash tools/preview_web.sh stop
```
