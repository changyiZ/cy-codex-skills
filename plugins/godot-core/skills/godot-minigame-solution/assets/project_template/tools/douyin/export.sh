#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
OUTPUT_DIR="${1:-build/tt-minigame}"
GODOT_BIN="${2:-godot}"

python3 "$ROOT_DIR/addons/minigame_solution/douyin/scripts/export.py" \
  --project-root "$ROOT_DIR" \
  --output-dir "$OUTPUT_DIR" \
  --godot-bin "$GODOT_BIN"

if [[ "$OUTPUT_DIR" = /* ]]; then
  OUTPUT_ABS="$OUTPUT_DIR"
else
  OUTPUT_ABS="$ROOT_DIR/$OUTPUT_DIR"
fi
OUTPUT_ABS="$(python3 -c 'import os, sys; print(os.path.abspath(sys.argv[1]))' "$OUTPUT_ABS")"
printf 'Douyin artifact: %s\n' "$OUTPUT_ABS"
