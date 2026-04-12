#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_ROOT="$HOME/.codex/plugins/cache/local-personal-plugins/godot-core/local"
ARTIFACTS_DIR="$PLUGIN_ROOT/evals/artifacts"

usage() {
  cat <<'EOF'
Usage:
  scripts/local_plugin_maintenance.sh sync
  scripts/local_plugin_maintenance.sh validate
  scripts/local_plugin_maintenance.sh smoke [project_root] [label]
  scripts/local_plugin_maintenance.sh all

Commands:
  sync      Sync the local plugin into Codex's local plugin cache.
  validate  Validate plugin.json, skill frontmatter, openai.yaml files, and eval CSV files.
  smoke     Run real-project smoke, export checks, and routing replays from a Godot workspace.
  all       Run sync, then validate.
EOF
}

sync_plugin() {
  mkdir -p "$CACHE_ROOT"
  rsync -a --delete "$PLUGIN_ROOT/" "$CACHE_ROOT/"
  echo "Synced plugin to $CACHE_ROOT"
}

validate_plugin() {
  python3 - "$PLUGIN_ROOT" <<'PY'
from pathlib import Path
import csv
import json
import re
import sys
import yaml

root = Path(sys.argv[1])

with (root / ".codex-plugin" / "plugin.json").open() as f:
    json.load(f)

skills = sorted((root / "skills").glob("*/SKILL.md"))
assert skills, "No skills found"

for path in skills:
    text = path.read_text()
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    assert m, f"Missing frontmatter: {path}"
    data = yaml.safe_load(m.group(1))
    assert data["name"], f"Missing skill name: {path}"
    assert data["description"], f"Missing skill description: {path}"

openai_files = sorted((root / "skills").glob("*/agents/openai.yaml"))
assert openai_files, "No openai.yaml files found"
for path in openai_files:
    with path.open() as f:
        yaml.safe_load(f)

prompt_csvs = sorted((root / "evals" / "prompts").glob("*.csv"))
assert prompt_csvs, "No eval prompt CSV files found"
for path in prompt_csvs:
    with path.open(newline="") as f:
        rows = list(csv.DictReader(f))
    assert rows, f"Empty prompt CSV: {path}"

print(f"Validated plugin.json, {len(skills)} skills, {len(openai_files)} openai.yaml files, and {len(prompt_csvs)} prompt CSV files.")
PY
  python3 "$PLUGIN_ROOT/scripts/validate_task_catalog.py" "$PLUGIN_ROOT"
}

smoke_routes() {
  local project_root="${1:-$PWD}"
  local label="${2:-$(basename "$project_root")}"

  sync_plugin

  python3 "$PLUGIN_ROOT/scripts/run_real_project_eval.py" \
    --project-root "$project_root" \
    --label "$label"
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    sync)
      sync_plugin
      ;;
    validate)
      validate_plugin
      ;;
    smoke)
      shift || true
      smoke_routes "${1:-}" "${2:-}"
      ;;
    all)
      sync_plugin
      validate_plugin
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
