#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
OUTPUT_DIR="${1:-build/wechat-minigame}"
GODOT_BIN="${2:-${GODOT:-godot}}"

python3 "$ROOT_DIR/addons/minigame_solution/wechat/scripts/export.py" \
  --project-root "$ROOT_DIR" \
  --godot "$GODOT_BIN" \
  --web-dir build/web \
  --output-dir "$OUTPUT_DIR"

if [[ "$OUTPUT_DIR" = /* ]]; then
  OUTPUT_ABS="$OUTPUT_DIR"
else
  OUTPUT_ABS="$ROOT_DIR/$OUTPUT_DIR"
fi
OUTPUT_ABS="$(python3 -c 'import os, sys; print(os.path.abspath(sys.argv[1]))' "$OUTPUT_ABS")"
ARTIFACT_DIR="$OUTPUT_ABS/minigame"
printf 'WeChat artifact: %s\n' "$ARTIFACT_DIR"
