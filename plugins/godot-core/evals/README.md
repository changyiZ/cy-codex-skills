# Evals

Last verified: 2026-03-30

Primary sources:
- https://developers.openai.com/codex/skills/#best-practices
- https://developers.openai.com/codex/learn/best-practices/#turn-repeatable-work-into-skills

The first goal of these evals is routing and workflow stability, not benchmark scale.

For routine local maintenance, prefer:

```bash
bash scripts/local_plugin_maintenance.sh validate
```

```bash
bash scripts/local_plugin_maintenance.sh sync
```

Run smoke replays from a disposable or test Godot workspace:

```bash
bash /Users/cY/.codex/plugins/godot-core/scripts/local_plugin_maintenance.sh smoke \
  /Users/cY/dev/godot/game0226 \
  game0226
```

## Included prompt sets

- [prompts/godot-bug-triage.csv](/Users/cY/.codex/plugins/godot-core/evals/prompts/godot-bug-triage.csv)
- [prompts/godot-core.csv](/Users/cY/.codex/plugins/godot-core/evals/prompts/godot-core.csv)
- [prompts/godot-feature-impl.csv](/Users/cY/.codex/plugins/godot-core/evals/prompts/godot-feature-impl.csv)
- [prompts/godot-scene-refactor.csv](/Users/cY/.codex/plugins/godot-core/evals/prompts/godot-scene-refactor.csv)
- [prompts/godot-export-release.csv](/Users/cY/.codex/plugins/godot-core/evals/prompts/godot-export-release.csv)
- [prompts/godot-web-export.csv](/Users/cY/.codex/plugins/godot-core/evals/prompts/godot-web-export.csv)
- [prompts/godot-web-cjk-font-fix.csv](/Users/cY/.codex/plugins/godot-core/evals/prompts/godot-web-cjk-font-fix.csv)

## Higher-risk rubric checks

- [rubrics/scene-refactor.md](/Users/cY/.codex/plugins/godot-core/evals/rubrics/scene-refactor.md)
- [rubrics/export-release.md](/Users/cY/.codex/plugins/godot-core/evals/rubrics/export-release.md)
- [rubrics/web-export.md](/Users/cY/.codex/plugins/godot-core/evals/rubrics/web-export.md)
- [rubrics/web-cjk-font-fix.md](/Users/cY/.codex/plugins/godot-core/evals/rubrics/web-cjk-font-fix.md)

## Task baselines

- [tasks/README.md](/Users/cY/.codex/plugins/godot-core/evals/tasks/README.md)
- [tasks/game0226/README.md](/Users/cY/.codex/plugins/godot-core/evals/tasks/game0226/README.md)

## Real-project smoke notes

- The current maintained validation workspace is `/Users/cY/dev/godot/game0226`.
- `validate` now checks both plugin packaging surfaces and the per-skill task catalog under `evals/tasks/game0226/`.
- `smoke` now runs `make smoke`, `make export-web-check`, `make export-web`, `make web-smoke`, `make browser-smoke`, and `make subset-font-verify` before one positive and one negative prompt per active skill.
- Route replays use a bounded timeout and may be recorded as `pass-timeout` when the correct skill boundary is already visible before the full `codex exec` turn ends.
- The latest clean full artifact run is `/Users/cY/.codex/plugins/godot-core/evals/artifacts/game0226-20260330T221417`.

## Suggested `codex exec --json` smoke commands

Run these from a disposable or test Godot workspace after restarting Codex so the local plugin is discoverable:

```bash
codex exec --json \
  'Use $godot-scene-refactor to rename Player to Hero and update references. Do not modify files; outline the workflow only.' \
  > evals/artifacts/scene-refactor-route.json
```

```bash
codex exec --json \
  'Use $godot-export-release to export the Web preset to build/web/index.html.zip and list the checks you would perform. Do not modify files.' \
  > evals/artifacts/export-release-route.json
```

```bash
codex exec --json \
  'Use $godot-web-export to diagnose a Godot HTML5 black screen after CDN deploy. Do not modify files; outline the workflow only.' \
  > evals/artifacts/web-export-route.json
```

```bash
codex exec --json \
  'Use $godot-web-cjk-font-fix to repair Chinese glyph tofu boxes in the Godot Web build and list the validation steps only.' \
  > evals/artifacts/web-cjk-route.json
```

```bash
codex exec --json \
  'Implement wall jump and air dash. Do not modify files; tell me which skill would fit.' \
  > evals/artifacts/feature-routing-negative.json
```

## What to look for

- the intended skill should route for explicit positive prompts
- explicit-only skills should not appear for ordinary feature work
- the response should mention the required workflow steps from the skill
- missing project commands should be reported as gaps, not hidden
- specialized skills should not steal generic Godot work unless the prompt boundary is explicit
- regressions caused by an earlier rename or move should start with `godot-bug-triage` unless the user explicitly asks to perform the structural refactor
