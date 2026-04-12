# 90-web-debug-playbook.md - Web Incident Playbook

Use this checklist for black screen, no input, no audio, or startup failures.

## 1) Basic Checks

1. Check browser console for wasm MIME, resource 404, CORS, and runtime exceptions.
2. Check network panel for wasm/pck status and stale cache hits.
3. Confirm `.wasm` is served as `application/wasm`.
4. If local template caches or fallback template directories are involved, confirm the exported runtime artifact itself reports the expected Godot version.

## 2) Threads-Related Checks

1. If `Use Threads` is on, verify COOP/COEP headers exist.
2. Or verify PWA workaround is active and service worker is functioning.

## 3) Asset and Path Checks

1. Confirm custom HTML shell matches exported file layout.
2. Confirm CDN rewrite or SPA fallback rules are not breaking resource paths.
3. Confirm the canonical `/index.wasm` path works in the actual preview/deploy contract, even when the exporter emits only a compressed wasm payload.

## 4) Validation Escalation

1. If headless or automation-only validation reports missing graphics features, re-run in a normal browser before calling the build broken.
2. Capture console milestones such as engine version, renderer line, startup logs, or first gameplay event before deciding whether the failure is runtime, browser, or validation-environment specific.

## 5) Incident Output

1. Key error logs or screenshots
2. Minimal reproducible URL plus browser version
3. Proposed fix path (headers, MIME, cache, export options)
