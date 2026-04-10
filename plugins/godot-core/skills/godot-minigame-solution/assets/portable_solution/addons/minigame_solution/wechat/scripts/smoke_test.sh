#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../../.." && pwd)"
OUTPUT_DIR="${1:-build/wechat-minigame}"
PROJECT_DIR="$OUTPUT_DIR/minigame"

required_files=(
  "$PROJECT_DIR/game.js"
  "$PROJECT_DIR/game.json"
  "$PROJECT_DIR/README.md"
  "$PROJECT_DIR/project.config.json"
  "$PROJECT_DIR/project.private.config.json"
  "$PROJECT_DIR/weapp-adapter.js"
  "$PROJECT_DIR/godot-loader.js"
  "$PROJECT_DIR/js/godot-wx-bridge.js"
  "$PROJECT_DIR/js/fs-sync.js"
  "$PROJECT_DIR/js/subpackage-loader.js"
  "$PROJECT_DIR/js/update-manager.js"
  "$PROJECT_DIR/js/platform-api-probe.js"
  "$PROJECT_DIR/js/vendor/pako_inflate.min.js"
  "$PROJECT_DIR/plugins/screen-adapter.js"
  "$PROJECT_DIR/workers/response/index.js"
  "$PROJECT_DIR/game.data.bin"
  "$PROJECT_DIR/engine/godot.js"
  "$PROJECT_DIR/engine/godot.wasm.br"
  "$PROJECT_DIR/engine/game.js"
  "$PROJECT_DIR/engine/godot.audio.worklet.js"
  "$PROJECT_DIR/engine/godot.audio.position.worklet.js"
  "$PROJECT_DIR/wechat-manifest.json"
)

for path in "${required_files[@]}"; do
  if [[ ! -f "$path" ]]; then
    echo "WeChat smoke: missing required file: $path" >&2
    exit 1
  fi
done

if [[ -f "$PROJECT_DIR/game.pck" ]]; then
  echo "WeChat smoke: legacy game.pck should not exist in the current export" >&2
  exit 1
fi

if [[ -d "$PROJECT_DIR/wx-game-kit" ]]; then
  echo "WeChat smoke: wx-game-kit should not exist in the current export" >&2
  exit 1
fi

if rg -n "WXGameKit|wxe5a48f1ed5f544b7|UnityWebData1.0|wx-transformer" "$PROJECT_DIR" -g '!weapp-adapter.js' >/dev/null 2>&1; then
  echo "WeChat smoke: found legacy common-adaptation markers in the current export" >&2
  exit 1
fi

if ! rg -n "\\[godot-wx\\] build stamp" "$PROJECT_DIR/game.js" >/dev/null 2>&1; then
  echo "WeChat smoke: generated game.js is missing the build stamp marker" >&2
  exit 1
fi

if ! rg -n "godotWxSubpackages\\.load\\(" "$PROJECT_DIR/game.js" >/dev/null 2>&1; then
  echo "WeChat smoke: generated game.js is missing the engine subpackage loader" >&2
  exit 1
fi

if ! rg -n "globalThis\\[[\"']Engine[\"']\\]\\s*=\\s*Engine" "$PROJECT_DIR/engine/godot.js" >/dev/null 2>&1; then
  echo "WeChat smoke: processed engine script is missing the global Engine export" >&2
  exit 1
fi

if ! rg -n "__godotWxWasmPath|__godotWxPathWebAssembly" "$PROJECT_DIR/engine/godot.js" >/dev/null 2>&1; then
  echo "WeChat smoke: processed engine script is missing the WeChat wasm bridge" >&2
  exit 1
fi

if ! rg -n "FS\\.mount\\(MEMFS,\\s*\\{\\},\\s*path\\)" "$PROJECT_DIR/engine/godot.js" >/dev/null 2>&1; then
  echo "WeChat smoke: processed engine script is missing the MEMFS userfs patch" >&2
  exit 1
fi

if ! rg -n "globalThis\\.fsUtils\\s*&&\\s*typeof globalThis\\.fsUtils\\.localFetch === [\"']function[\"']" "$PROJECT_DIR/engine/godot.js" >/dev/null 2>&1; then
  echo "WeChat smoke: processed engine script is missing the localFetch bridge" >&2
  exit 1
fi

if ! rg -n "decodeLocalBuffer" "$PROJECT_DIR/engine/godot.js" >/dev/null 2>&1; then
  echo "WeChat smoke: processed engine script is missing the local decode bridge" >&2
  exit 1
fi

python3 - "$PROJECT_DIR/game.json" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
if data.get("plugins") not in ({}, None):
    raise SystemExit("WeChat smoke: game.json should not declare legacy plugins")
subpackages = data.get("subpackages") or []
if not any(item.get("name") == "engine" and item.get("root") == "engine" for item in subpackages):
    raise SystemExit("WeChat smoke: game.json should declare the engine subpackage")
PY

python3 "$ROOT_DIR/addons/minigame_solution/validation/validate_platform_apis.py" \
  --profile wechat \
  --artifact-root "$PROJECT_DIR"

echo "WeChat smoke: OK ($PROJECT_DIR)"
