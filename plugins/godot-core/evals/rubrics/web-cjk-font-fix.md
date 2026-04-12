# Web CJK Font Fix Rubric

Last verified: 2026-03-30

## Routing

- Should trigger for Godot Web Chinese, Japanese, or Korean tofu boxes, missing glyphs, garbled symbols, or oversized packaged-font payload prompts.
- Should not be the default for generic Web export, desktop typography, or non-CJK font styling tasks.

## Required workflow checks

- prefers packaged fonts over uncontrolled system fallback
- mentions subsetting, `woff2`, or equivalent payload-reduction strategy
- names or checks `make subset-font`, `make export-web`, `make web-smoke`, or project equivalents
- calls out glyph coverage for symbols and punctuation when relevant

## Output checks

- reports the font source or license posture
- reports validation results and before/after payload or artifact comparison when possible
