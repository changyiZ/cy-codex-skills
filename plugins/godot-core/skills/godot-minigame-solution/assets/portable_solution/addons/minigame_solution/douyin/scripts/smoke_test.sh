#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../../.." && pwd)"
DIR="${1:-build/tt-minigame}"
MANIFEST_PATH="${2:-}"

if [[ ! -d "$DIR" ]]; then
  echo "Douyin smoke: missing directory $DIR" >&2
  exit 1
fi

for required in game.js game.json godot.config.js godot.launcher.js project.config.json douyin-manifest.json platform-api-probe.js; do
  if [[ ! -f "$DIR/$required" ]]; then
    echo "Douyin smoke: missing $required in $DIR" >&2
    exit 1
  fi
done

for required in godot/godot.js godot/godot.wasm.br; do
  if [[ ! -f "$DIR/$required" ]]; then
    echo "Douyin smoke: missing $required in $DIR" >&2
    exit 1
  fi
done

if [[ -d "$DIR/subpackages" ]] && ! find "$DIR/subpackages" -maxdepth 2 -type f -name 'game.js' | grep -q .; then
  echo "Douyin smoke: missing subpackage launcher in $DIR/subpackages" >&2
  exit 1
fi

if ! find "$DIR/godot" -maxdepth 1 -type f \( -name 'main.pck' -o -name 'main.bin' -o -name 'main.br' -o -name '*.ttsg' \) | grep -q .; then
  echo "Douyin smoke: missing main package payload in $DIR" >&2
  exit 1
fi

while IFS= read -r disallowed; do
  echo "Douyin smoke: found disallowed export content $disallowed" >&2
  exit 1
done < <(find "$DIR" \
  \( -path "*/docs" -o -path "*/docs/*" \
  -o -path "*/knowledge" -o -path "*/knowledge/*" \
  -o -path "*/build" -o -path "*/build/*" \) \
  -print)

python3 - "$DIR/douyin-manifest.json" <<'PY'
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
build_stamp = manifest.get("build_stamp", "")
route = manifest.get("route", "")
if not isinstance(build_stamp, str) or not build_stamp.strip():
    raise SystemExit(f"Douyin smoke: invalid build_stamp in {manifest_path}")
if route != "douyin":
    raise SystemExit(f"Douyin smoke: unexpected route {route!r} in {manifest_path}")
PY

if [[ -n "$MANIFEST_PATH" && -f "$MANIFEST_PATH" ]]; then
  python3 - "$DIR" "$MANIFEST_PATH" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
manifest = pathlib.Path(sys.argv[2])
data = json.loads(manifest.read_text(encoding="utf-8"))
platforms = data.get("platforms", {})
douyin = platforms.get("douyin", {}) if isinstance(platforms, dict) else {}
subpackages = douyin.get("subpackages", []) if isinstance(douyin, dict) else []

for entry in subpackages:
    if not isinstance(entry, dict):
        continue
    name = entry.get("name", "")
    root_dir = entry.get("root", "")
    pack_path = entry.get("pack_path", "")
    compressed_path = entry.get("compressed_path", "")
    if not root_dir or not pack_path:
        raise SystemExit(f"Douyin smoke: invalid subpackage entry {entry!r}")
    sub_root = root / root_dir
    if not sub_root.is_dir():
        raise SystemExit(f"Douyin smoke: missing subpackage directory {sub_root} for {name}")
    pack_file = root / pack_path
    if not pack_file.is_file():
        raise SystemExit(f"Douyin smoke: missing subpackage pack {pack_file} for {name}")
    if compressed_path:
        compressed_file = root / compressed_path
        if not compressed_file.is_file():
            raise SystemExit(f"Douyin smoke: missing compressed subpackage payload {compressed_file} for {name}")
PY
fi

python3 "$ROOT_DIR/addons/minigame_solution/validation/validate_platform_apis.py" \
  --profile douyin \
  --artifact-root "$DIR"

echo "Douyin smoke: OK ($DIR)"
