---
name: godot-web-export
description: Handle Godot Web export, deployment, and runtime diagnosis with explicit thread, header, cache, and smoke-check gates. Use for HTML5 export, CDN or object-storage deployment, custom shell issues, WebView adaptation, or browser black-screen and startup failures. Do not use for generic desktop/mobile export or non-Web feature work.
---

# Godot Web Export

Last verified: 2026-03-31

Primary sources:
- https://developers.openai.com/codex/skills/#best-practices
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html

## When to use this

- Godot HTML5 or Web export setup
- CDN, object-storage, or static-host deployment checks
- browser black-screen, startup, input, or audio incidents after Web export
- thread, header, MIME, cache, or custom HTML shell diagnosis
- WebView adaptation that still depends on Godot Web export behavior

## When not to use this

- generic desktop or mobile export tasks with no Web-specific failure mode
- ordinary gameplay or UI feature work
- scene-interface refactors
- CJK packaged-font and glyph-specific failures

## Inputs

- target preset, target URL, or deployment path if known
- hosting stack or CDN details if known
- exact browser symptom, console error, or network failure if available
- thread setting, custom shell, and cache policy details if known
- export, smoke, and local preview commands if the project already provides them

## Required workflow

1. Identify the target Web export path, preset, smoke command, and local preview command, or state the missing project contract explicitly.
2. Treat `Use Threads = off` as the default until secure context and COOP/COEP requirements are proven.
3. Check the deployment contract: `.wasm` MIME, thread headers, compression, cache/versioning, and custom shell or path assumptions.
4. Inspect browser console and network evidence before proposing the fix path.
5. Report the exact export or smoke commands used, the deployment assumptions checked, and the residual compatibility risks.

## Preferred local preview contract

- For iterative Godot Web work, prefer a canonical project command: `make preview-web`.
- `make preview-web` should rebuild the Web export, stop the previous project-owned preview server, and restart a stable local preview URL, typically `http://127.0.0.1:8000/`.
- Pair it with `make stop-web-preview` for explicit shutdown.
- Implement the restart logic in a small project script such as `tools/preview_web.sh`, rather than relying on ad-hoc `python3 -m http.server` commands during normal development.
- The preview restart flow must only kill the previous server if it was started by the same project workflow; it must not kill unrelated listeners on the same port.

## Guardrails

- Do not enable threads by assumption; require explicit evidence that the deployment contract supports them.
- Keep export configuration problems separate from gameplay bugs unless evidence proves the runtime issue is content-driven.
- Treat the stable-doc note that Godot 4 Web export does not support C# projects as a hard compatibility constraint.
- Do not claim release readiness without runtime or deployment verification.
- Do not normalize a project onto manual one-off preview servers when the repo can provide a reusable preview command contract.
- Do not kill unknown processes just to free the preview port; only stop the previous project-owned preview server.

## Done when

- the preset, deploy target, or missing project contract is identified
- a local preview command is reported or the missing preview contract is called out
- thread, header, cache, and MIME assumptions are checked or called out as gaps
- a concrete export or smoke command is reported
- residual browser, hosting, or rollout risks are listed

## Positive examples

- `Use $godot-web-export to diagnose why this Godot HTML5 build works locally but shows a black screen after CDN deploy.`
- `Prepare the Godot Web export for release, verify thread and header requirements, and list the smoke checks before claiming success.`

## Negative example

- `Fix Chinese tofu boxes in the Godot Web build and shrink the bundled font payload.`

## Helpful local references

- `references/10-threads-decision.md`
- `references/20-server-headers.md`
- `references/30-loading-cache-versioning.md`
- `references/40-local-preview-contract.md`
- `references/90-web-debug-playbook.md`
- `assets/templates/tools/web_smoke_test.sh`
- `assets/templates/tools/preview_web.sh`
