# Scene Refactor Rubric

Last verified: 2026-03-30

## Routing

- Should trigger only when the task explicitly changes scene structure, node names, node paths, scene paths, signal wiring, or autoload-facing structure.

## Required workflow checks

- inspects the target scene or states that it must inspect it
- searches for references to scene paths, node paths, signal names, and autoload assumptions
- avoids third-party `addons/` edits unless explicitly requested
- names at least one validation command or states that the project lacks one

## Regression risk checks

- updates or calls out signal connection risk
- updates or calls out scene path and node path risk
- explicitly lists likely breakpoints after the refactor
