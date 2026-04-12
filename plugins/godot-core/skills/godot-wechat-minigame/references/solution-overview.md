# WeChat Unified Solution Overview

## 目的

这份说明把已经验证过的 Godot 4.6 -> 微信小游戏主路线抽成 skill 内部可移植版本，供别的设备和项目直接使用。

它回答四个问题：
1. 当前主路线是什么。
2. 为什么当前主路线不是把 gameplay 直接绑到 `wx.*` 或官方历史适配链。
3. 构建期和运行期各自由哪些层负责。
4. 一个目标仓装完这套方案后，应该长成什么样。

## 方案结论

当前稳定路线是：

`Godot Web 导出 -> repo-owned WeChat shell/template -> repo-owned JS runtime bridge -> engine 子包装配 -> PlatformServices + platform/wechat`

这条路线的关键判断是：
1. 先稳定产出 Godot `Web` 构建物，再把它重组为微信小游戏产物。
2. 微信运行时契约留在 repo-owned shell 和 `platform/wechat/`，不让场景和 gameplay 直接依赖 `wx.*`。
3. 引擎放进 `engine` 子包，主内容包保留在主包，避免把大 wasm 和引擎胶水挤进主包预算。
4. 当前主路线不是依赖外部 transformer 作为黑盒，而是依赖目标仓内可审计、可复现、可维护的模板、桥接和装配脚本。

## 分层模型

### 1. Godot Web 导出层

负责产出标准 Web 构建物，例如：
1. `index.js`
2. `index.wasm`
3. `index.pck`
4. 音频 worklet

这一层只负责 Godot 自己的 Web 产物，不直接理解微信小游戏目录结构。

### 2. WeChat 装配层

由 `addons/minigame_solution/wechat/scripts/export.py` 和 `assemble_wechat.py` 把 Web 产物重组为小游戏结构。

这一层负责：
1. 复制 repo-owned template。
2. 把 `index.js` 后处理为 `engine/godot.js`。
3. 把 `index.wasm` 转成 `engine/godot.wasm.br`。
4. 把 `index.pck` 改名为主包里的 `game.data.bin`。
5. 写出 `wechat-manifest.json` 等装配元数据。

### 3. WeChat 运行时壳层

由 `addons/minigame_solution/wechat/template/` 提供小游戏启动入口、桥接文件、子包加载器、文件同步、更新管理和 probe 入口。

这一层负责：
1. 提供 `game.js`、`game.json`、`weapp-adapter.js`。
2. 在启动时显式加载 `engine` 子包。
3. 暴露 repo-owned JS bridge，而不是让场景脚本直接碰 `wx.*`。

### 4. Godot 平台边界层

由 `autoload/PlatformServices.gd` 和 `platform/wechat/` 提供稳定接口。

这一层负责：
1. 把场景和玩法代码隔离在平台 API 之外。
2. 承接存档、生命周期、分享、子包、能力探测等平台逻辑。
3. 只通过桥接契约与小游戏壳交互。

## 稳定导出与运行链

一个目标仓装好方案后，稳定导出链应当是：
1. `make export-wechat` 或等价 wrapper。
2. 共享导出入口先执行 Godot `Web` export。
3. `assemble_wechat.py` 复制并填充 repo-owned template。
4. 生成主包和 `engine` 子包。
5. `make wechat-smoke` 做静态结构校验。
6. 需要时在 DevTools 或真机上用 runtime probe 做宿主证据补充。

运行链应当是：
1. 微信入口 `game.js` 启动。
2. 显式加载 `engine` 子包。
3. Godot 引擎启动后回到场景与 gameplay。
4. gameplay 通过 `PlatformServices` 间接使用微信能力。

## 目标仓应具备的稳定结构

### 共享实现

1. `addons/minigame_solution/wechat/template/`
2. `addons/minigame_solution/wechat/scripts/export.py`
3. `addons/minigame_solution/wechat/scripts/assemble_wechat.py`

### 项目薄封装

1. `tools/wechat/`
2. `platform/wechat/`
3. `autoload/PlatformServices.gd`

### 最终产物结构

主包通常包含：
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

`engine` 子包通常包含：
1. `engine/game.js`
2. `engine/godot.js`
3. `engine/godot.wasm.br`
4. `engine/godot.audio.worklet.js`
5. `engine/godot.audio.position.worklet.js`

## 已验证的关键设计决策

1. 引擎资产进 `engine` 子包，主内容包留在主包。
2. 主内容包优先走 inline main pack，文件读取只做 fallback。
3. `godot.js` 的微信兼容 patch 属于壳层和装配层问题，不应回灌到 gameplay。
4. 导出期要剥离 editor-only 的 Douyin tooling，避免污染 WeChat 导出上下文。
5. 交互坐标要以桥接层的 `getBoundingClientRect()` 契约为准，不能在 gameplay 层再做二次缩放修补。
6. 不要依赖宿主字体；字体资源要随项目打包，或在 UI 方案里显式规避宿主字体差异。

## 验证边界

微信方案的有效证据要分三层：
1. export / smoke
2. WeChat DevTools
3. 真机

没有更高层级能力时，只能停在当前层给结论，不能把静态结构校验包装成宿主可用性结论。

## 与项目文档的关系

这份文件是从已验证项目里的 WeChat 方案文档提炼出来的 skill 内部版本。
它保留了稳定路线、目录职责、产物结构和关键技术判断，但移除了某个具体项目的尺寸快照、任务历史和本机目录假设。
