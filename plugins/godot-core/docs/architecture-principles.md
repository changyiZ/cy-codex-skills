# Architecture Principles

Last verified: 2026-03-30

Primary sources:
- https://developers.openai.com/codex/concepts/customization/#skills
- https://developers.openai.com/codex/concepts/customization/#mcp
- https://developers.openai.com/codex/learn/best-practices/#turn-repeatable-work-into-skills
- https://developers.openai.com/codex/skills/#best-practices

## Skills are the authoring unit, the plugin is the distribution unit

The workflow lives in `SKILL.md`, optional references, and optional helper assets. The plugin exists to install those workflows consistently across Codex surfaces.

## Local-first until validation passes

Treat this plugin as local-only until routing, validation artifacts, and maintenance scripts are stable enough to trust. Do not optimize for cloud publication, public branding, or external metadata before the local workflow is repeatable.

## One skill, one job

Every public skill should cover one repeatable workflow and have clear non-goals. If a task mainly changes skill routing, improve the skill name, description, and examples before adding scripts.

## Project adaptation stays outside the plugin

The plugin should not try to encode project-specific preset names, forbidden folders, scene catalogs, or proprietary build commands. Those belong in project `AGENTS.md`, project docs, and project tooling.

## Validation beats prose

The plugin should always prefer exact project commands over generic claims of correctness. If the project does not expose import, smoke, test, or export commands, the gap must be stated explicitly.

## Stable docs beat habit

When local workflow habits conflict with official Codex or Godot documentation, prefer the official source. Local habits that remain useful but not fully standardized should be labeled as heuristics.

## MCP is for off-repo capabilities

Do not use MCP as a thin wrapper around local file inspection or shell commands. Package MCP only when the workflow needs structured capabilities beyond the local repository or when a stable Godot workspace server boundary has emerged.

## Expansion requires eval evidence

New public skills should be added only after repeated prompts and rubric checks show that the workflow is stable enough to route reliably and validate consistently.
