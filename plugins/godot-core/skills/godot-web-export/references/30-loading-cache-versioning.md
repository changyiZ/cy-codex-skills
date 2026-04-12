# 30-loading-cache-versioning.md - Web Cache and Versioning

## Goal

Use strong cache where safe while keeping controllable invalidation for new releases.

## Strategy

1. Prefer versioned or hashed output file names.
2. Keep entry HTML weak-cached (short TTL), static assets strong-cached (long TTL).
3. If file renaming is impossible, use query-string versioning as fallback.

## Local validation notes

1. During local preview and repeated re-export loops, prefer `Cache-Control: no-store` over clever caching. This avoids stale `index.js` or `.wasm` being paired with a newly written `.pck`.
2. If export output includes only a compressed wasm payload such as `.wasm.br`, either:
   - serve the canonical `/index.wasm` path with the correct content-encoding fallback, or
   - materialize a raw `.wasm` file after export for local preview and smoke checks.
3. If the browser reports `Pack created with a newer version of the engine`, do not assume cache is the only cause. Verify the exported runtime artifact actually matches the expected Godot version.

## Rollback

1. Keep previous full build directory (or storage prefix).
2. Roll back by switching entry pointer (`index.html` or manifest reference).
