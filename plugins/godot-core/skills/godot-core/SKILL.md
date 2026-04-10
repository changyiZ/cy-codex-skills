---
name: godot-core
description: Plan-first Godot engineering for feature implementation, bug fixing, architecture review, and performance diagnosis with official-doc routing and explicit validation. Use for day-to-day Godot project work when the task is not primarily a scene-interface refactor, preset-driven release/export task, Web deployment incident, or Web CJK font failure.
---

# Godot Core

Last verified: 2026-03-30

Primary sources:
- https://developers.openai.com/codex/skills/#best-practices
- https://docs.godotengine.org/en/stable/getting_started/step_by_step/nodes_and_scenes.html
- https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html
- https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html

## When to use this

- day-to-day Godot gameplay, UI, and systems work that spans more than a narrow one-file change
- multi-file bug fixing or cleanup that is not primarily a scene-interface rename or move
- architecture or coupling review
- performance diagnosis that needs evidence and project-aware validation
- plan-first Godot work where the right implementation path is not obvious yet

## When not to use this

- explicit node-name, node-path, scene-path, or signal-interface refactors
- preset-driven export or release execution
- Web deployment, hosting, cache, or browser-runtime incidents
- Godot Web CJK glyph or packaged-font failures

## Inputs

- goal or failure summary
- affected scenes, scripts, systems, or folders if known
- project root and pinned Godot version if known
- target platform constraints if relevant
- project validation commands if available

## Required workflow

1. Run `scripts/godot_project_snapshot.sh <project-root>` or perform an equivalent read-only scan before editing.
2. Read official Godot docs first for API and engine-behavior decisions; load local references only after the source-of-truth path is clear.
3. Produce a short plan before editing when the change touches multiple systems, multiple scenes, or a performance-sensitive surface.
4. Keep edits local, preserve scene ownership, and follow existing project patterns unless the task explicitly asks for a structural change.
5. Run the nearest available formatter, linter, and test or smoke commands in order, then report exact commands and summarized results or gaps.

## Guardrails

- Prefer the project's pinned Godot version over the generic plugin baseline.
- Do not silently expand ordinary engineering work into a scene-interface refactor, release flow, or Web-specific incident task.
- Do not edit `addons/` unless the user explicitly requests it.
- Treat performance claims as evidence-backed work: capture the symptom, the likely cause, and the validation result.
- Keep mini-game or platform-product constraints explicit in project docs and `AGENTS.md` rather than hiding them in generic workflow assumptions.

## Done when

- the scope and chosen workflow are stated
- the implementation or refactor path follows project patterns and official-doc guidance
- exact validation commands or validation gaps are reported
- likely regression surfaces or residual risks are named

## Positive examples

- `Use $godot-core to review this Godot combat architecture, reduce coupling, and propose a plan-first refactor with validation commands.`
- `Implement a save/load cleanup across scenes and scripts with $godot-core and keep the change set narrow.`

## Negative example

- `Use $godot-export-release to export the Web preset and list signing or preset risks.`

## Helpful local references

- `scripts/godot_project_snapshot.sh`
- `references/llm.txt`
- `references/llm-medium.txt`
- `references/05-plan-first.md`
- `references/50-testing.md`
- `references/60-decoupling.md`
- `references/70-debug-perf.md`
