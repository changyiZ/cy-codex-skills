# Workflow

## 当前稳定导出链

如果目标仓还没装这条路线，先回到总控 skill，运行它自带的：
1. `python3 scripts/install_portable_solution.py --project-root <target-repo>`
2. `python3 scripts/ensure_export_presets.py --project-root <target-repo>`

然后再走下面的稳定导出链：
1. `make prepare-douyin`
2. `make export-douyin`
3. `make douyin-smoke`

如果目标仓没有这组 `make` 命令，按仓内 wrapper 实际名字执行；只有在 wrapper 缺失时，才直接调用共享脚本的 repo-relative 路径。

## 当前目录归属

1. vendored exporter baseline：`addons/ttsdk/`、`addons/ttsdk.editor/`
2. repo-owned overlay：`addons/minigame_solution/douyin/overlay/ttsdk.editor/`
3. overlay sync：`addons/minigame_solution/douyin/scripts/sync_ttsdk_overlay.py`
4. repo-owned export assembly：`addons/minigame_solution/douyin/scripts/export.py`
5. runtime probe bridge：`addons/minigame_solution/douyin/runtime/platform-api-probe.js`

## 当前稳定产物

根目录：
1. `game.js`
2. `game.json`
3. `godot.config.js`
4. `godot.launcher.js`
5. `project.config.json`
6. `douyin-manifest.json`
7. `platform-api-probe.js`

`godot` 子包：
1. `godot/godot.js`
2. `godot/godot.wasm.br`
3. `godot/main.pck`
4. `godot/main.br`
5. `godot/game.js` 仅在某些分包布局下存在

可选延迟分包：
1. `subpackages/<name>/data.pck`
2. `subpackages/<name>/data.br`
3. `subpackages/<name>/game.js`

## 当前设计结论

1. Douyin export 需要 clean 输出目录，避免导入旧包或残留文件。
2. `douyin-manifest.json` 与根 `game.js` build stamp 是追踪“当前导入的是不是最新构建”的稳定手段。
3. shared probe 需要在导出阶段复制到产物根目录，并从根 `game.js` 主动 `require(...)`。
4. 以上都是目标仓应达到的结构要求，不依赖任何固定项目名或固定设备目录。
