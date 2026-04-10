# Platform API Probe Playbook

This playbook turns the shared probe contract into a concrete validation flow for WeChat, Douyin, and final player-view acceptance.

## 1. Shared rules

Use the shared layers in this order:

1. build/export the target artifact
2. run shared smoke and API marker validation
3. run one or more runtime probes
4. complete a player-view manual acceptance pass

Useful helpers:

```bash
python3 addons/minigame_solution/validation/render_platform_api_probe_template.py --platform wechat --list
python3 addons/minigame_solution/validation/render_platform_api_probe_template.py --platform douyin --list
```

Current-project thin wrapper:

```bash
make probe-template PLATFORM=wechat TEMPLATE=readonly FORMAT=query
make probe-template PLATFORM=douyin TEMPLATE=readonly FORMAT=gdscript
```

The project wrapper lives at `tools/minigame_probe_template.py`.  
It keeps the shared probe contract unchanged, but can fill current-project values such as the Douyin subpackage name from `data/minigame_subpackages.json` and can warn when ad unit ids are empty in `project.godot`.

Render a query string:

```bash
python3 addons/minigame_solution/validation/render_platform_api_probe_template.py --platform wechat --template readonly --format query
```

Render a temporary GDScript call:

```bash
python3 addons/minigame_solution/validation/render_platform_api_probe_template.py --platform douyin --template readonly --format gdscript
```

Common launch-query keys:
- `api_probe=1`
- `api_probe_calls=...`
- `api_probe_ui=1`
- `api_probe_request_url=...`
- `api_probe_socket_url=...`
- `api_probe_subpackage=...`
- `api_probe_scene_id=...`
- `api_probe_rewarded_placement=...`

Interpretation rule:
- `pass`: the API call path worked in the current runtime
- `skip`: the API was intentionally not executable in the current run, for example missing ad unit, missing endpoint, or UI disabled
- `fail`: treat as a real compatibility or configuration issue until proven otherwise

## 2. WeChat flow

### 2.1 Build and static validation

```bash
make export-wechat
make wechat-smoke
python3 addons/minigame_solution/validation/validate_platform_apis.py --profile wechat --artifact-root build/wechat-minigame/minigame
```

### 2.2 Readonly runtime probe

Generate a readonly query:

```bash
python3 addons/minigame_solution/validation/render_platform_api_probe_template.py --platform wechat --template readonly --format query
```

Use that query through the host launch-parameter path available to your current WeChat debug toolchain.  
The exact UI entry can vary by tool version, so treat this as "custom compile / launch-parameter injection" rather than a fixed button label.

Expected behavior:
- Boot screen shows `Running platform API probe...`
- then shows `Probe pass:X fail:Y skip:Z`
- debug console prints the probe report in JSON when debug logging is enabled

### 2.3 Network runtime probe

Generate a network template, then replace placeholders:

```bash
python3 addons/minigame_solution/validation/render_platform_api_probe_template.py --platform wechat --template network --format query
```

Replace:
- `__SET_REQUEST_URL__`
- `__SET_SOCKET_URL__`

Use probe-specific endpoints, not gameplay business endpoints.

### 2.4 Interactive runtime probe

Generate an interactive probe:

```bash
python3 addons/minigame_solution/validation/render_platform_api_probe_template.py --platform wechat --template interactive --format query
```

Expected behavior:
- `share` should execute the share-config path
- `rewarded_ad` can validly skip if no ad unit is configured
- `modal` should only be used in a runtime where UI interruption is acceptable

### 2.5 WeChat player-view acceptance

After probe validation, manually verify:
- cold start into Home
- enter a real level
- aim, tap, and launch feel
- win or fail once
- background -> foreground restore
- restart persistence
- any enabled share or revive path from the actual game UI

## 3. Douyin flow

### 3.1 Build and static validation

```bash
make export-douyin
make douyin-smoke
python3 addons/minigame_solution/validation/validate_platform_apis.py --profile douyin --artifact-root build/tt-minigame
```

### 3.2 Readonly runtime probe

Generate a readonly query:

```bash
python3 addons/minigame_solution/validation/render_platform_api_probe_template.py --platform douyin --template readonly --format query
```

Use that query through the IDE launch-parameter path or a custom compile mode.  
The current Douyin IDE documentation explicitly mentions switching between ordinary compile and custom compile conditions for passing parameters, and the platform's side-bar test guide documents "添加编译模式" to simulate startup conditions.

### 3.3 Network and scene/subpackage probes

Render network:

```bash
python3 addons/minigame_solution/validation/render_platform_api_probe_template.py --platform douyin --template network --format query
```

Render subpackage and scene:

```bash
python3 addons/minigame_solution/validation/render_platform_api_probe_template.py --platform douyin --template subpackage_and_scene --format query
```

Replace:
- `__SET_REQUEST_URL__`
- `__SET_SOCKET_URL__`
- `__SET_SUBPACKAGE_NAME__`
- `__SET_SCENE_ID__`

### 3.4 Interactive runtime probe

```bash
python3 addons/minigame_solution/validation/render_platform_api_probe_template.py --platform douyin --template interactive --format query
```

Expected behavior:
- `share` path is exercised
- `keyboard` opens only when UI is allowed
- `rewarded_ad` and `interstitial` may validly skip when unit ids are missing

### 3.5 Douyin real-device debug

The current official Douyin documentation also describes:
- binding debug permission and test devices before preview or true-device debug
- launching true-device debug from the IDE toolbar
- scanning with Douyin to open the remote-debug session

Use that path for the strongest runtime evidence, especially for:
- touch correctness
- safe-area layout
- restart and foreground restore
- actual ad/share interruption behavior

### 3.6 Douyin player-view acceptance

After probe validation, manually verify:
- cold start into Home
- one real level entry path
- one win/fail path
- background -> foreground restore
- any enabled share, revive, interstitial, or deferred-pack path from the real UI

## 4. Temporary code-driven probe

When launch-parameter injection is inconvenient, use a temporary code call:

```gdscript
var report := await PlatformServices.run_platform_api_probe({
    "calls": ["launch_context", "ui_insets", "storage", "login"],
    "allow_ui": false,
    "timeout_ms": 1500
})
print(JSON.stringify(report))
```

Prefer query-driven triggering for repeatable host validation.  
Use code-driven triggering only when you need a temporary local hook.

## 5. Exit bar

Treat a mini-game build as fully validated only when:
- shared smoke passes
- platform API matrix validation passes
- the relevant runtime probes pass or skip for explicit reasons
- a human completes the target player-view path
