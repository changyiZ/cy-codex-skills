---
name: godot-bug-triage
description: Diagnose Godot runtime, scene-loading, editor, or export failures and drive toward the smallest defensible fix. Use when the task is driven by an error, regression, crash, null instance, missing node path, failed load, or export failure, including breakage caused by an earlier rename or move. Do not use for ordinary feature requests or planned refactors.
---

# Godot Bug Triage

Last verified: 2026-03-30

Primary sources:
- https://developers.openai.com/codex/skills/#best-practices
- https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html
- https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html

## When to use this

- runtime errors or crashes
- null instance or invalid get index incidents
- missing scene, resource, or node-path failures
- regressions caused by an earlier node rename, scene move, or signal change when the current task is diagnosis and repair
- editor load failures
- export failures

## When not to use this

- ordinary feature work
- planned scene-tree refactors
- release execution that already centers on an export preset workflow

## Inputs

- exact error text or reproduction steps
- affected scene, script, resource, or preset if known
- expected behavior
- project verification commands if available

## Required workflow

1. Capture the exact symptom and expected behavior.
2. Classify the failure family: scene path, node path, signal, resource, scripting, or export.
3. Inspect the smallest relevant scene, script, resource, or preset path first.
4. Prefer the smallest defensible fix over a broad cleanup.
5. Re-run the nearest available verification command and state any missing quality gate explicitly.

## Guardrails

- Do not expand a bug fix into a broad refactor unless the user asks for it.
- Do not edit `addons/` unless the user explicitly requests it.
- Prefer the project's pinned engine version over the generic plugin baseline.
- Treat missing verification commands as a gap, not a silent success.

## Done when

- the likely root cause is stated
- the smallest defensible fix is described or applied
- a verification command or verification gap is reported
- nearby regression risks are listed

## Positive examples

- `Use $godot-bug-triage to diagnose this null instance error in inventory.gd and propose the smallest fix.`
- `The project fails to load res://scenes/hud.tscn after a rename. Diagnose the regression with godot-bug-triage.`

## Negative example

- `Implement wall jump and air dash for the player.`
