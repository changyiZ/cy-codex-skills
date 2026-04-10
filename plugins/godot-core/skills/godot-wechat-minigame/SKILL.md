---
name: godot-wechat-minigame
description: Implement, validate, or debug the Godot 4.6 WeChat mini-game route built on Web export, a repo-owned shell, JS bridges, and engine-subpackage assembly. Use when Codex needs the WeChat export flow, WeChat DevTools or device validation, or WeChat-specific runtime triage such as input, wasm startup, packaged assets, or editor-only addon stripping.
---

# Godot WeChat Mini-Game

用这个 skill 处理 Godot 4.6 -> 微信小游戏的具体路径。

## 何时使用

适用于：
1. 需要接入或刷新 WeChat mini-game 导出链。
2. 需要检查 `make export-wechat`、`make wechat-smoke`、DevTools 或真机验证。
3. 需要排查 WeChat 壳层、桥接、输入、wasm 启动、包体、宿主差异问题。

不适用于：
1. 抖音平台问题。
2. 纯共享架构判定但还没锁定平台。
3. 与小游戏无关的普通 Godot Web 问题。

## 默认工作流

1. 先读 `references/solution-overview.md`，确认当前仓是否仍走 repo-owned WeChat shell 路线，以及这条路线的层次边界。
2. 再读 `references/workflow.md`，确认导出入口、目录归属和稳定产物结构。
3. 涉及验证时再读 `references/validation.md`。
4. 涉及点击失效、启动黑屏、包体、资源读取、编辑器插件串入、中文字体等问题时，再读 `references/pitfalls.md`。
5. 如果目标仓还没有 `addons/minigame_solution/`、`tools/wechat/` 或 `platform/wechat/`，先回到 `$godot-minigame-solution`，用它自带的安装脚本把完整方案落进目标仓，再继续平台排障。

## 可移植性规则

1. 先发现目标仓自己的 WeChat 入口命令；如果仓内没有 `make export-wechat` / `make wechat-smoke`，再回退到共享脚本相对路径。
2. 不要假设本机一定有 WeChat DevTools CLI、GUI 或真机调试条件；先检查，再决定验证上限。
3. 不要把某个参考项目的输出目录名字、工程名或绝对路径当成通用前提。

## WeChat 路线硬规则

1. WeChat 主路线是 `Godot Web 导出 -> repo-owned shell/template -> repo-owned JS bridge -> engine 子包装配`。
2. 场景和 gameplay 不得直接调用 `wx.*`；必须经 `PlatformServices` 与 `platform/wechat/`。
3. 引擎资产进 `engine` 子包；主内容包保留在主包，且当前稳定命名是 `game.data.bin`。
4. 启动时主包必须先显式加载 `engine` 子包，再启动 Godot。
5. WeChat 验证必须分清：
   - export/smoke
   - DevTools
   - 真机
6. 没有 DevTools 或真机能力时，结论只能停在可用层级，不能把静态验证包装成宿主验证。

## 产出要求

1. 说清当前问题是在导出、装配、壳层、桥接、输入、资源、还是验收层。
2. 说清已跑验证命令和仍缺的验证层级。
3. 如果修复的是 WeChat 特有问题，明确说明为什么修在壳层/桥接层，而不是 gameplay 层。

## 参考资料

1. `references/solution-overview.md`
2. `references/workflow.md`
3. `references/validation.md`
4. `references/pitfalls.md`
