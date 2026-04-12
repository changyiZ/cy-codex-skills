# Douyin Unified Solution Overview

## 目的

这份说明把已经验证过的 Godot 4.6 -> 抖音小游戏主路线抽成 skill 内部可移植版本，供别的设备和项目直接使用。

它回答四个问题：
1. 当前主路线是什么。
2. 为什么当前主路线是“官方 exporter + repo-owned overlay”，而不是完全 repo-owned shell。
3. 构建期和运行期各自由哪些层负责。
4. 一个目标仓装完这套方案后，应该长成什么样。

## 方案结论

当前稳定路线是：

`Godot 导出预设 -> vendored 官方 Douyin exporter -> repo-owned overlay sync -> repo-owned export assembly -> PlatformServices + platform/douyin`

这条路线的关键判断是：
1. 当前抖音主路线依赖 vendored 官方 exporter，而不是自写完整壳层替代它。
2. 真正可维护的 repo-owned 真相源是 overlay、同步脚本和导出装配，不是直接把 vendored `addons/ttsdk.editor/` 当唯一编辑面。
3. 场景和 gameplay 不直接依赖 `tt.*`，而是经 `PlatformServices` 与 `platform/douyin/`。
4. 当前可运行性的关键不只是“导出成功”，而是 overlay 补丁、runtime probe、subpackage 装配和宿主验证一起闭环。

## 分层模型

### 1. Godot 导出层

负责通过导出预设产出抖音主包与可选章节分包。

这一层只负责 Godot 自己的导出入口，不负责宿主兼容补丁。

### 2. vendored 官方 exporter 层

由 `addons/ttsdk/` 与 `addons/ttsdk.editor/` 提供官方小游戏导出与启动基础。

这一层负责：
1. 生成 `game.js`、`game.json`、`godot.config.js` 等基础文件。
2. 生成 `godot` 子包与可选分包。
3. 提供 `tt` autoload 与官方导出逻辑基线。

### 3. repo-owned overlay 与装配层

由 `addons/minigame_solution/douyin/overlay/ttsdk.editor/`、`sync_ttsdk_overlay.py` 和 `export.py` 提供。

这一层负责：
1. 在导出前同步 overlay 到 vendored exporter。
2. clean 输出目录，避免旧包残留。
3. 写入 `douyin-manifest.json` 与 build stamp。
4. 把 shared runtime probe 复制到导出根目录，并从根 `game.js` 注入启动。

### 4. Godot 平台边界层

由 `autoload/PlatformServices.gd` 和 `platform/douyin/` 提供稳定接口。

这一层负责：
1. 把场景和玩法代码隔离在平台 API 之外。
2. 承接生命周期、子包、能力探测、存档等平台逻辑。
3. 只通过明确桥接契约与 `tt` 宿主能力交互。

## 稳定导出与运行链

一个目标仓装好方案后，稳定导出链应当是：
1. `make prepare-douyin` 或等价 wrapper。
2. overlay sync 完成并通过基线检查。
3. `make export-douyin` clean 并重建导出目录。
4. 导出主包和需要的章节分包。
5. 写入 `douyin-manifest.json`、build stamp 和 runtime probe。
6. `make douyin-smoke` 做静态结构校验。
7. 需要时在 Developer Tools 或真机上补宿主证据。

运行链应当是：
1. 根 `game.js` 作为真正稳定入口启动。
2. launcher 或 GodotPlugin 启动引擎。
3. `godot` 子包装载 wasm、主包和桥接。
4. gameplay 通过 `PlatformServices` 间接使用抖音能力。

## 目标仓应具备的稳定结构

### 共享实现

1. `addons/ttsdk/`
2. `addons/ttsdk.editor/`
3. `addons/minigame_solution/douyin/overlay/ttsdk.editor/`
4. `addons/minigame_solution/douyin/scripts/sync_ttsdk_overlay.py`
5. `addons/minigame_solution/douyin/scripts/export.py`
6. `addons/minigame_solution/douyin/runtime/platform-api-probe.js`

### 项目薄封装

1. `tools/douyin/`
2. `platform/douyin/`
3. `autoload/PlatformServices.gd`
4. `data/minigame_subpackages.json`

### 最终产物结构

根目录通常包含：
1. `game.js`
2. `game.json`
3. `godot.config.js`
4. `godot.launcher.js`
5. `project.config.json`
6. `douyin-manifest.json`
7. `platform-api-probe.js`

`godot` 子包通常包含：
1. `godot/godot.js`
2. `godot/godot.wasm.br`
3. `godot/main.pck`
4. `godot/main.br`
5. `godot/game.js`

可选延迟分包通常包含：
1. `subpackages/<name>/data.pck`
2. `subpackages/<name>/data.br`
3. `subpackages/<name>/game.js`

## 已验证的关键设计决策

1. Douyin 主路线是“官方 exporter + overlay sync + repo-owned assembly”，不是完全 repo-owned shell。
2. overlay 才是兼容补丁真相源；直接手改 vendored exporter 会立刻失去可维护性。
3. 导出前必须 clean 目标目录，避免导入旧包后误判“代码没生效”。
4. `douyin-manifest.json` 和根 `game.js` build stamp 是稳定的版本追踪点。
5. shared runtime probe 必须落到导出根目录，并从根 `game.js` 主动加载；不能只把 probe 留在源码目录。
6. `godot/game.js` 不是所有布局都稳定存在，所以 probe 注入点要优先选根 `game.js`。
7. 不要对 plain JS bridge 做 GDScript 反射式探测；平台桥接能力要通过明确约定的接口和 marker 暴露。

## 验证边界

抖音方案的有效证据要分三层：
1. export / smoke
2. Developer Tools
3. 真机

没有更高层级能力时，只能停在当前层给结论，不能把静态结构校验包装成宿主可用性结论。

## 与项目文档的关系

这份文件是从已验证项目里的 Douyin 方案文档提炼出来的 skill 内部版本。
它保留了稳定路线、目录职责、产物结构和关键技术判断，但移除了某个具体项目的尺寸快照、任务历史和本机目录假设。
