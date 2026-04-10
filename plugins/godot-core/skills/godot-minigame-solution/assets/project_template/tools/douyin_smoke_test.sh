#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${1:-build/tt-minigame}"

bash "$ROOT_DIR/addons/minigame_solution/douyin/scripts/smoke_test.sh" "$OUTPUT_DIR" "$ROOT_DIR/data/minigame_subpackages.json"
