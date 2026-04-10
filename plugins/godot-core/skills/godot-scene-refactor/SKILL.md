---
name: godot-scene-refactor
description: Safely refactor a Godot scene tree or scene path while preserving references. Use only when the user explicitly asks to rename, move, reparent, or reconnect scene structure. Do not use for ordinary gameplay code changes or for regressions that should start as bug triage.
---

# Godot Scene Refactor

Last verified: 2026-03-30

Primary sources:
- https://developers.openai.com/codex/skills/#best-practices
- https://docs.godotengine.org/en/stable/getting_started/step_by_step/nodes_and_scenes.html
- https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html
- https://docs.godotengine.org/en/stable/tutorials/misc/instancing_with_signals.html
- https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html

## When to use this

- rename nodes
- move or rename scene files
- change node paths
- reconnect or rename signals
- adjust scene structure that other scripts or scenes depend on

## When not to use this

- ordinary gameplay or UI logic edits that keep structure stable
- export or release execution
- root-cause debugging with no intended structural change
- regressions after a past rename or move when the current task is to diagnose and fix the breakage

## Inputs

- target scene or scenes
- intended rename, move, reparent, or signal change
- known node-path, scene-path, or autoload dependencies
- project validation commands if available

## Required workflow

1. Inspect the target scene and the scripts attached to key nodes.
2. Search the repository for references to the scene path, node path, node name, signal name, and autoload assumptions tied to the change.
3. Apply the smallest structure change that satisfies the request.
4. Update broken references before declaring the refactor done.
5. Report likely regression points and the validation command run or missing.

## Guardrails

- Never rename or move third-party assets under `addons/` unless the user explicitly requests it.
- Do not assume a node-path change is local to one file.
- Preserve public scene interfaces when possible.
- Treat scene paths, node paths, and signal names as integration surfaces until proven otherwise.

## Done when

- all intended renames, moves, or signal changes are applied
- direct references are updated or explicitly listed as follow-up
- likely regression points are called out
- validation command or validation gap is reported

## Positive examples

- `Use $godot-scene-refactor to rename the Player node to Hero and update all references.`
- `Move res://scenes/hud.tscn to res://ui/hud.tscn and reconnect any broken references.`

## Negative example

- `Fix this missing node path error after moving the HUD scene.`
