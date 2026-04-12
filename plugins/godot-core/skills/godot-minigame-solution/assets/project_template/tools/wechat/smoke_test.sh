#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
OUTPUT_DIR="${1:-build/wechat-minigame}"

bash "$ROOT_DIR/addons/minigame_solution/wechat/scripts/smoke_test.sh" "$OUTPUT_DIR"
