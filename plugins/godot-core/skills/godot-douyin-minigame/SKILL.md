---
name: godot-douyin-minigame
description: Implement, validate, or debug the Godot 4.6 Douyin mini-game route built on the vendored official exporter, repo-owned overlay sync, clean export assembly, and platform-specific runtime validation. Use when Codex needs Douyin export setup, Douyin Developer Tools or device evidence, or Douyin-specific triage for launcher startup, subpackages, runtime probes, or exporter compatibility patches.
---

# Godot Douyin Mini-Game

用这个 skill 处理 Godot 4.6 -> 抖音小游戏的具体路径。

## 何时使用

适用于：
1. 需要接入或刷新 Douyin mini-game 导出链。
2. 需要检查 `make export-douyin`、`make douyin-smoke`、Developer Tools 或真机验证。
3. 需要排查 exporter、launcher、subpackage、runtime probe、build stamp 或宿主差异问题。

不适用于：
1. 微信平台问题。
2. 还没锁定平台的统一方案判定。
3. 与官方 exporter 无关的普通 Godot Web 问题。

## 默认工作流

1. 先读 `references/solution-overview.md`，确认当前仓是否仍走“vendored exporter + overlay sync”路线，以及这条路线的分层边界。
2. 再读 `references/workflow.md`，确认导出入口、目录归属和稳定产物结构。
3. 涉及验证时再读 `references/validation.md`。
4. 涉及导出后疑似旧包、template/runtime 版本漂移、subpackage、Developer Tools 与真机差异、iOS remote debug / USB 提示、桥接对象探测等问题时，再读 `references/pitfalls.md`。
5. 如果目标仓还没有 `addons/minigame_solution/`、`addons/ttsdk.editor/`、`tools/douyin/` 或 `platform/douyin/`，先回到 `$godot-minigame-solution`，用它自带的安装脚本把完整方案落进目标仓，再继续平台排障。

## 可移植性规则

1. 先发现目标仓自己的 Douyin 入口命令；如果仓内没有 `make export-douyin` / `make douyin-smoke`，再回退到共享脚本相对路径。
2. 不要假设本机一定有 Douyin IDE、Developer Tools 或真机调试条件；先检查，再决定验证上限。
3. 不要把某个参考项目的输出目录名字、工程名或绝对路径当成通用前提。

## Douyin 路线硬规则

1. Douyin 主路线不是 repo-owned shell，而是“vendored 官方 exporter + repo-owned overlay + repo-owned export assembly”。
2. 导出前必须 sync overlay，不要把 `addons/ttsdk.editor/` 当唯一可编辑源。
3. 导出目录要先 clean，再重建，并写入 build stamp 与 `douyin-manifest.json`。
4. 根 `game.js` 需要注入 runtime probe 入口，不能只把 probe 文件留在源目录。
5. 场景和 gameplay 不得直接调用 `tt.*`；必须经 `PlatformServices` 与 `platform/douyin/`。
6. iOS preview/basic startup 与 iOS remote debug 是两层不同能力，不能混为一谈。
7. 当出现 “Pack created with a newer version of the engine” 一类报错时，优先相信当前导出产物解压后的 runtime 版本和 build stamp，不要先相信模板目录名或旧 IDE 导入状态。
8. 没有 Developer Tools 或真机能力时，结论只能停在可用层级，不能把静态验证包装成宿主验证。

## 产出要求

1. 说清问题是在 exporter、overlay、launcher、subpackage、runtime probe、还是验收层。
2. 说清已跑验证命令和仍缺的验证层级。
3. 说清当前证据锚定的 artifact 路径和 build stamp，避免把旧导入包和新导出包混在一起。
4. 如果修复的是 Douyin 特有问题，明确说明为什么修在 exporter/overlay/backend，而不是 gameplay 层。

## 参考资料

1. `references/solution-overview.md`
2. `references/workflow.md`
3. `references/validation.md`
4. `references/pitfalls.md`
