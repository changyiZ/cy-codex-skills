---
name: godot-minigame-solution
description: Route Godot WeChat and Douyin mini-game work through a shared solution workflow covering adoption, refresh, validation, upstream monitoring, and platform-specific triage. Use when a Godot project needs the reusable mini-game package installed or updated, when a repo should keep thin wrappers around `addons/minigame_solution/`, when Codex must check latest official or external solution drift and dependency updates, or when Codex must decide whether to load the WeChat or Douyin mini-game workflow for validation and debugging.
short_description: Route Godot WeChat/Douyin mini-game workflows.
icon_small: ./assets/godot-minigame-solution-small.svg
icon_large: ./assets/godot-minigame-solution.png
---

# Godot Minigame Solution

用这个 skill 处理 Godot 微信/抖音小游戏统一方案的总入口工作。

它不直接替代平台 skill，而是负责：
1. 判断当前任务是接入、刷新、验证还是排障。
2. 锁定共享包、薄封装、项目配置归属这些硬规则。
3. 需要时联动 `$godot-wechat-minigame` 或 `$godot-douyin-minigame`。
4. 处理上游官方文档、社区方案、依赖版本、以及 skill 内置资源漂移的周期巡检。

这不是纯文档 skill。当前目录已经直接内置了可移植解决方案资产：
1. `assets/portable_solution/` 放共享 addon 与平台基线依赖。
2. `assets/project_template/` 放目标仓薄封装模板、wrapper、预检脚本和 Makefile 片段。
3. `scripts/install_portable_solution.py` 负责把内置方案落进任意目标 Godot 仓。
4. `scripts/ensure_export_presets.py` 负责在目标仓生成可移植的 Web / WeChat / Douyin 导出预设。

## 可移植性规则

1. 先检查目标仓，而不是假设它长得和任何参考仓一样。至少确认：`project.godot`、`export_presets.cfg`、`Makefile`、`platform/`、`tools/`、`addons/`。
2. 所有路径和命令默认按目标仓根目录相对路径表达，不要把某台机器上的绝对路径写进工作流或结论。
3. 不要假设本机已经装好 WeChat DevTools、Douyin IDE 或真机调试链路；先发现能力，再声明验证上限。
4. 如果目标仓还没有 `addons/minigame_solution/`，优先使用本 skill 自带的 `assets/` 和 `scripts/` 完成真实接入，而不是再回头寻找某台机器上的外部共享包目录。

## 何时使用

适用于：
1. 给现有 Godot 项目接入微信和抖音小游戏统一方案。
2. 把已经接入的项目刷新到新的共享包或新的验证契约。
3. 审查一个项目是否还保持了 `addons/minigame_solution/` + thin wrappers 的结构。
4. 需要先判断该走 WeChat 还是 Douyin 平台 skill。
5. 需要周期性检查官方和外界最新方案，以及 skill 打包依赖和资源是否该升级。

不适用于：
1. 纯 gameplay/UI 需求。
2. 单一平台后端内部的小改动，且路径已经明确。
3. 与小游戏无关的 Godot Web、桌面、移动原生问题。

## 路由规则

1. 先读 `references/shared-architecture.md`，确认仓库当前是否仍符合统一方案边界。
2. 如果任务主语是“接入新仓/第二仓/刷新共享包/薄封装检查”，继续读 `references/adoption-flow.md`，并优先考虑直接运行 `scripts/install_portable_solution.py --project-root <target-repo>`；刷新已有接入时优先加 `--overwrite-existing`。
3. 如果任务主语是“验证/验收/回归”，继续读 `references/shared-validation-contract.md`。
4. 如果任务主语是“检查最新方案/监控上游变化/定期提醒升级”，继续读 `references/upgrade-monitoring.md` 并优先运行 `scripts/check_upstream_updates.py`。
5. 如果问题已经明确落在微信路径，立刻联动 `$godot-wechat-minigame`。
6. 如果问题已经明确落在抖音路径，立刻联动 `$godot-douyin-minigame`。
7. 如果同一任务同时涉及两端平台，先用本 skill 锁定共享规则，再分别读取平台 skill。

## 硬规则

1. 共享执行真相源必须在 `addons/minigame_solution/`，不要把壳层、导出装配、验证矩阵重新散回项目私有脚本。
2. 这套 skill 的可执行真相源已经内置在当前 skill 目录：
   - `assets/portable_solution/`
   - `assets/project_template/`
   - `scripts/install_portable_solution.py`
   - `scripts/ensure_export_presets.py`
3. 项目层必须保持薄封装：
   - `platform/PlatformBackend.gd` 只做共享 contract 的薄包装。
   - `tools/wechat/*`、`tools/douyin*` 只调用共享脚本。
   - `Makefile` 只提供项目入口，不复制共享逻辑。
4. 项目配置必须留在项目内：
   - `project.godot` 的 `[wechat]` / `[douyin]`
   - `data/minigame_subpackages.json`
   - 项目自己的 `platform/wechat/`、`platform/douyin/`、`autoload/PlatformServices.gd`
5. 目标仓如果还没有 `export_presets.cfg` 或预设不完整，优先运行 `scripts/ensure_export_presets.py --project-root <target-repo>`，不要再依赖某台机器上的旧预设文件。
6. 验证必须先走三层闭环，再把 remote debug 单列为可选第四层：
   - 产物/marker 验证
   - 可执行 probe 验证
   - 玩家视角 startup/basic interaction 与手工验收
   - 可选 remote debug
7. 如果只有 export/smoke 通过，没有 DevTools 或真机证据，只能报告“结构验证通过”，不能报告“平台已验证”。
8. 如果目标仓没有统一命令面，先按仓内实际入口发现并记录，再决定是否补齐 `make export-wechat` / `make export-douyin` 等标准入口。
9. 周期巡检类任务不要只盯官方文档；必须把外部方案、依赖版本、和 skill 内置资源漂移一起检查。

## 产出要求

1. 说清当前任务属于接入、刷新、验证还是排障。
2. 说清应该继续读哪个 reference，或应该联动哪个平台 skill。
3. 说清当前仓库是否仍符合统一方案的薄封装边界。
4. 验证类任务必须列出已完成层级和仍缺的层级，并把证据锚定到当前 artifact 路径和 build stamp。

## 参考资料

1. `references/shared-architecture.md`
2. `references/adoption-flow.md`
3. `references/shared-validation-contract.md`
4. `references/cross-project-pitfalls.md`
5. `references/upgrade-monitoring.md`
