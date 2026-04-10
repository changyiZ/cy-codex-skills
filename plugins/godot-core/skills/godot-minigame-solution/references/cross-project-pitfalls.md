# Cross-Project Pitfalls

这些坑都已经在独立 Godot 项目的真实迁移过程中出现过，默认按高优先级排查。

## 迁移与结构类

1. 共享 WeChat 导出必须自己先产出 `build/web/`。如果把这个前置步骤留在目标仓 Makefile，第二仓很容易接入失败。
2. Douyin export 前必须先 sync overlay，并校验 vendored exporter 基线版本；不要直接手改 `addons/ttsdk.editor/` 当唯一真相源。
3. 统一命令面必须 implementation-agnostic。对用户只暴露 `export-wechat` / `wechat-smoke` / `export-douyin` / `douyin-smoke`。
4. 不要把某台机器上的绝对路径、私有目录名或固定仓名写进技能说明、排障步骤或最终结论。
5. 不要让目标仓继续依赖某个外部共享目录；共享 addon、模板和导出预设生成逻辑应直接来自当前 skill 内置资产。

## 验证与证据类

1. 结构 smoke 太弱，必须再加 capability matrix。
2. capability matrix 也不等于真实可运行，必须再加 runtime probe。
3. runtime probe 也不等于玩家体验正常，必须再加玩家视角验收。
4. 证据必须锚定一个当前 artifact 路径和 build stamp，不能混历史目录。

## 运行时边界类

1. plain JS bridge object 不是 Godot 反射对象。不要对这类桥接对象调用 `has_method()`、`callv()` 或 container 风格 `get(...)`。
2. 平台识别要优先走 export preset custom features，再走固定名字桥接，不要靠脆弱的 JS 反射探测。
3. query-driven probe 比项目自定义 debug UI 更可复用。

## 资源与导出合同类

1. 显式 `export_files` 仓库里，新增字体、脚本、场景、桥接文件都属于导出合同变更，不是“代码写完就算完成”。
2. 宿主字体不可靠。CJK 文本要靠仓内打包字体或字图资产。
3. 新资源漏进 `export_presets.cfg` 时，症状可能是运行时大量 `Nil` 或“空对象”报错，而不是直接报缺文件。
