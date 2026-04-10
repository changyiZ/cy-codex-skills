---
name: godot-export-release
description: Execute or diagnose a Godot preset-driven export and release workflow. Use only when the task explicitly asks to export, prepare a release, or debug an export-specific failure. Do not use for ordinary feature work or scene refactors.
---

# Godot Export Release

Last verified: 2026-03-30

Primary sources:
- https://developers.openai.com/codex/skills/#best-practices
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html
- https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_web.html
- https://godotengine.org/download/archive/

## When to use this

- export a preset for release
- prepare a release checklist around `export_presets.cfg`
- diagnose export-specific failures
- inspect target-specific release risks

## When not to use this

- ordinary gameplay implementation
- pure scene-tree refactors
- runtime debugging that is not export-specific

## Inputs

- target platform
- preset name
- output path
- signing or credentials prerequisites if known
- project export and smoke commands if available

## Required workflow

1. Verify the target preset exists or state that it must be checked in `export_presets.cfg`.
2. Identify the export command and output path that match the target platform.
3. Call out missing templates, SDKs, signing material, or confidential credentials before claiming success.
4. Run the export path that exists, inspect logs, and note target-specific residual risks.
5. Report exact commands used, exact output location, and exact validation or smoke result.

## Guardrails

- Do not claim an export succeeded without an exact command or log path.
- Treat `export_presets.cfg` as version-controlled project config and `.godot/export_credentials.cfg` as confidential machine-local data.
- For Godot 4 Web targets, remember that C# projects are not supported in the stable Web export docs.
- If GDExtension is involved for Web, note that Web-specific extension builds are required.

## Done when

- the preset and output path are named or the missing information is called out
- missing templates, credentials, or SDK gaps are reported
- export or smoke commands are reported with results
- target-specific residual risks are listed

## Positive examples

- `Use $godot-export-release to export the Windows Desktop preset to build/game.exe and list any missing prerequisites.`
- `Prepare a Web export for release, inspect the preset, and call out target-specific risks before claiming success.`

## Negative example

- `Rename the MainMenu root node to TitleScreen and update references.`
