---
name: godot-web-cjk-font-fix
description: Fix Godot 4 Web Chinese, Japanese, and Korean glyph failures with packaged fonts, subsetting, payload optimization, and explicit Web regression checks. Use when editor text is correct but Web output shows tofu boxes, missing glyphs, garbled symbols, or oversized bundled fonts.
short_description: Godot Web CJK glyph repair and font-size control
icon_small: ./assets/godot-web-cjk-font-fix-small.svg
icon_large: ./assets/godot-web-cjk-font-fix.png
---

# Godot Web CJK Font Fix

Last verified: 2026-03-30

Primary sources:
- https://developers.openai.com/codex/skills/#best-practices
- https://docs.godotengine.org/en/stable/
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html

## When to use this

- editor text looks correct but the Web build shows tofu boxes or missing CJK glyphs
- Web output renders Chinese, Japanese, or Korean symbols incorrectly after export
- packaged font payload is too large and needs subsetting or `woff2` conversion
- the fix depends on packaged fonts, Web-only theme injection, or glyph coverage checks

## When not to use this

- generic Web deployment, MIME, COOP/COEP, or CDN black-screen incidents
- desktop-only typography adjustments
- visual font-choice discussions with no glyph failure or payload issue
- non-CJK font rendering problems that do not depend on the Web export path

## Inputs

- broken text examples, screenshots, or specific missing glyphs if available
- current font path, theme setup, and target scene or script if known
- existing subset, export, or smoke commands if the project provides them
- payload target or artifact-size concern if known
- font license/source constraints if known

## Required workflow

1. Confirm the issue qualifies as a Web CJK font failure rather than a general deployment or runtime incident.
2. Inspect the packaged font path, Web-only theme injection path, and current export artifacts before changing the font strategy.
3. Prefer a distributable packaged font, `woff2` subset output, and explicit glyph coverage over uncontrolled system fallback.
4. Run `make subset-font`, `make export-web`, and `make web-smoke`, or project equivalents, then perform a manual browser regression if needed.
5. Report the font source, validation results, and before/after payload impact on `build/web`, `index.pck`, or `index.wasm` when possible.

## Guardrails

- Do not rely on system font fallback as the primary fix path for Web delivery.
- Do not subset a font before capturing the glyph inventory needed by the project text and symbols.
- Do not ship a font with unclear redistribution terms.
- Treat punctuation and symbol coverage such as `→`, `✕`, and CJK punctuation as part of the validation surface.
- If project subset or Web smoke commands are missing, state that gap explicitly instead of claiming the fix is verified.

## Done when

- the packaged font path and Web-only application strategy are identified
- glyph coverage and payload strategy are clear
- exact subset, export, and smoke commands or gaps are reported
- artifact-size change and residual Web font risks are listed

## Positive examples

- `Use $godot-web-cjk-font-fix to fix Chinese tofu boxes in this Godot Web export and verify the optimized build.`
- `Editor text is correct, but the Web build shows missing CJK glyphs and broken symbols. Repair the font pipeline and keep payload size under control.`

## Negative example

- `Diagnose COOP and COEP header issues for a threaded Godot Web export.`

## Helpful local references

- `scripts/fetch_font.sh`
- `references/font-subsetting.md`
