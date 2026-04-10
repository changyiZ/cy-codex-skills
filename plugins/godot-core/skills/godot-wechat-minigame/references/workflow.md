# Workflow

## 当前稳定导出链

如果目标仓还没装这条路线，先回到总控 skill，运行它自带的：
1. `python3 scripts/install_portable_solution.py --project-root <target-repo>`
2. `python3 scripts/ensure_export_presets.py --project-root <target-repo>`

然后再走下面的稳定导出链：
1. `make export-wechat`
2. 共享导出入口先跑 Godot `Web` export，产出 `build/web/*`
3. `assemble_wechat.py` 复制 repo-owned template
4. 组装主包与 `engine` 子包
5. `make wechat-smoke`

如果目标仓没有这组 `make` 命令，按仓内 wrapper 实际名字执行；只有在 wrapper 缺失时，才直接调用共享脚本的 repo-relative 路径。

## 当前目录归属

1. 模板与壳层：`addons/minigame_solution/wechat/template/`
2. 导出与装配：`addons/minigame_solution/wechat/scripts/export.py`、`assemble_wechat.py`
3. 项目薄封装：`tools/wechat/*`、`platform/wechat/`、`autoload/PlatformServices.gd`

## 稳定产物结构

主包保留：
1. `game.js`
2. `game.json`
3. `project.config.json`
4. `project.private.config.json`
5. `weapp-adapter.js`
6. `godot-loader.js`
7. `js/godot-wx-bridge.js`
8. `js/fs-sync.js`
9. `js/subpackage-loader.js`
10. `js/update-manager.js`
11. `workers/response/index.js`
12. `game.data.bin`
13. `wechat-manifest.json`

`engine` 子包保留：
1. `engine/game.js`
2. `engine/godot.js`
3. `engine/godot.wasm.br`
4. `engine/godot.audio.worklet.js`
5. `engine/godot.audio.position.worklet.js`

## 当前设计结论

1. 引擎放 `engine` 子包是为了解决包体预算问题。
2. 主内容包不放 `engine` 子包，避免 GUI runtime 的读取权限问题。
3. 主内容包优先从 `js/inline-assets.js` 消费，只有缺失时才 fallback 到本地文件读取。
4. WeChat 导出期必须临时剥离 editor-only Douyin tooling，避免 `ttsdk.editor` 污染导出上下文。
5. 以上都是目标仓应达到的结构要求，不依赖任何固定项目名或固定设备目录。
