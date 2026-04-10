# Pattern Cases

Last verified: 2026-03-30

Primary sources:
- https://docs.godotengine.org/en/stable/getting_started/first_2d_game/
- https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html
- https://docs.godotengine.org/en/stable/tutorials/misc/instancing_with_signals.html
- https://docs.godotengine.org/en/stable/getting_started/step_by_step/nodes_and_scenes.html
- https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html
- https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_web.html
- https://github.com/godotengine/godot-demo-projects

This file condenses a few official Godot patterns into plugin-friendly guidance.

## Case 1: Signal-first decoupling

Official sources:

- `Using signals`
- `Instancing with signals`
- `Your first 2D game`

Pattern:

- let child scenes emit signals instead of reaching upward through brittle tree traversal
- prefer clear event boundaries between gameplay nodes, HUD, and orchestration scenes

Plugin implication:

- `godot-feature-impl` should prefer signal-based coordination when a change crosses scene boundaries
- `godot-scene-refactor` must search and update signal names and connection points whenever scene structure changes

## Case 2: Scene composition through instancing

Official sources:

- `Nodes and Scenes`
- `Creating instances`
- `Your first 2D game`

Pattern:

- a project is composed from reusable scenes rather than one giant root scene
- scene identity matters because file paths, root node names, and attached scripts become part of the integration surface

Plugin implication:

- `godot-feature-impl` should preserve existing scene ownership unless the request explicitly asks for a larger structural change
- `godot-scene-refactor` must treat scene paths, node paths, and attached scripts as public integration points until proven otherwise

## Case 3: Resource and path discipline

Official sources:

- `Resources`
- `godot-demo-projects`

Pattern:

- resource paths, imported assets, and serialized scene references are operational dependencies, not cosmetic details
- moving a resource or scene is often more than a file rename

Plugin implication:

- `godot-bug-triage` should treat missing resources and path regressions as a first-class failure family
- `godot-scene-refactor` should search for resource and scene references across scripts, scenes, and exported configs before claiming a rename is safe

## Case 4: Export is a contract, not a final button click

Official sources:

- `Exporting projects`
- `Exporting for the Web`

Pattern:

- export presets define the build contract
- `export_presets.cfg` is safe for version control, while `.godot/export_credentials.cfg` contains confidential settings
- command-line exports require a preset and an explicit output path
- Web exports have target-specific constraints such as single-thread defaults, COOP/COEP requirements for threaded builds, and the Godot 4 C# Web limitation

Plugin implication:

- `godot-export-release` should verify presets, credentials gaps, output paths, logs, and target-specific residual risk
- `godot-bug-triage` should classify export failures separately from ordinary gameplay bugs
