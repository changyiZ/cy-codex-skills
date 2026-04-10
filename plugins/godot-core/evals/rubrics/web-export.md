# Web Export Rubric

Last verified: 2026-03-30

## Routing

- Should trigger for Godot Web export, HTML5 deployment, hosting headers, cache policy, browser-runtime failure, or WebView adaptation prompts.
- Should not be the default for generic desktop export or non-Web gameplay work.

## Required workflow checks

- names or checks a Web export command, preset, or project-specific equivalent
- mentions thread enablement as an explicit decision, not an implicit default
- checks or plans to check `application/wasm`, COOP/COEP, cache/version policy, or equivalent hosting contract
- identifies at least one concrete smoke or browser verification step

## Risk checks

- calls out residual browser, hosting, CDN, or thread-compatibility risks
- avoids claiming release readiness without runtime or deployment evidence
