---
name: godot-feature-impl
description: Implement ordinary Godot gameplay, UI, or systems work inside an existing project while respecting project constraints and validation commands. Use for normal feature delivery, behavior changes, and scoped extensions. Do not use for primarily structural scene refactors or export-and-release tasks.
---

# Godot Feature Implementation

Last verified: 2026-03-30

Primary sources:
- https://developers.openai.com/codex/learn/best-practices/#turn-repeatable-work-into-skills
- https://docs.godotengine.org/en/stable/getting_started/step_by_step/nodes_and_scenes.html
- https://docs.godotengine.org/en/stable/getting_started/first_2d_game/
- https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html

## When to use this

- add or adjust gameplay mechanics
- extend UI flow
- implement ordinary systems logic
- make scoped behavior changes in an existing Godot project

## When not to use this

- explicit scene-tree and reference refactors
- release preparation or export execution
- incident-driven root-cause diagnosis

## Inputs

- feature goal
- acceptance criteria
- target scene, script, or system if known
- platform constraints if relevant
- project validation commands if available

## Required workflow

1. Inspect the existing scene and script boundary before changing behavior.
2. Reuse existing project patterns unless the task explicitly asks for a new structure.
3. Keep the change set narrow and preserve scene ownership unless the feature requires a structural change.
4. Run the nearest project validation command and report the result or gap.
5. Summarize behavior changes and likely regression points.

## Guardrails

- Do not edit `addons/` unless the user explicitly requests it.
- Do not silently introduce a broad scene refactor during ordinary feature work.
- Treat typed public GDScript as a workflow preference that should follow the repo's style, not a universal engine rule.
- Keep C# and GDExtension support to compatibility notes unless the project already centers on them.

## Done when

- the feature boundary is clear
- the implementation follows existing project patterns where possible
- validation commands or validation gaps are reported
- likely regressions are named

## Positive examples

- `Use $godot-feature-impl to add a dash mechanic to the player and verify it with project commands.`
- `Add a pause menu and resume flow to this Godot project while keeping the current scene structure.`

## Negative example

- `Rename the Player node to Hero and update every broken reference.`
