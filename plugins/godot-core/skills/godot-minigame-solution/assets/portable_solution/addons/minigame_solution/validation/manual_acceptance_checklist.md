# Mini-game Acceptance Layers

`platform_api_matrix.json` and runtime probe execution solve two different problems:

1. Static artifact validation
   - proves the exported output still contains the required platform hooks
2. Executable API probe validation
   - proves selected platform APIs can actually be called in a live runtime

Neither layer replaces a user-perspective acceptance pass.

## Why manual acceptance is still required

Runtime probes can confirm that APIs such as login, storage, request, socket, share, keyboard, rewarded ad, or subpackage load are callable.  
They do not prove that the game still feels correct or that cross-system state transitions are healthy.

Probe coverage is not enough for:
- cold-start to playable-home latency and perceived loading quality
- safe-area layout, HUD overlap, and touch comfort
- aim feel, drag/tap recognition, and in-game coordinate correctness
- rewarded-ad fallback and revive flow continuity
- share panel behavior as seen by a real player
- app hide/show, restart, and persistence from a player perspective
- deferred content load while entering a real level path
- complete session flow such as Home -> Stage -> Result -> replay/next level

## Recommended final validation stack

1. Artifact validation
   - run shared smoke and platform API matrix checks
2. Runtime probe validation
   - run a readonly probe
   - run a network probe if the build depends on request or socket
   - run an interactive probe only when UI-bearing APIs need explicit host confirmation
3. User-perspective manual acceptance
   - cold start into the game
   - start a real level
   - play through basic win/fail flow
   - exercise background/foreground and restart persistence
   - verify any enabled share/ad/login/deferred-pack flow from the game UI

## Exit rule

Treat the build as fully validated only when:
- artifact validation passes
- the relevant runtime probes pass or skip for an explicit reason
- a human completes the target gameplay path from the player view
