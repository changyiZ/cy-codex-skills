# Pitfalls

## exporter 与装配

1. 先 sync overlay，再导出；不要直接把本地修改长期留在 vendored `addons/ttsdk.editor/`。
2. 导出目录必须先 clean，再写入新产物，否则 Developer Tools 很容易导入到混合旧包。
3. `douyin-manifest.json` 和根 `game.js` build stamp 是判断“是否旧包”的第一证据。

## runtime probe 与桥接

1. runtime probe 文件放在源目录里不够，导出阶段必须复制到 `build/tt-minigame/platform-api-probe.js`，并从根 `game.js` 注入。
2. 不要对 plain JS bridge 做 Godot 反射式探测；优先走 export preset custom features 与固定名桥接。

## 分包与结构判断

1. `godot/game.js` 不是通用强约束。某些无子包或不同布局的有效导出不会带这个文件。
2. 更稳定的通用约束应放在：
   - 根 launcher
   - `godot/godot.js`
   - `godot/godot.wasm.br`
   - 主包 payload
3. 项目自己的分包名必须来自 `data/minigame_subpackages.json`，不要在 backend 或 smoke 里硬编码。

## Developer Tools 与真机

1. Helium/IDE 模拟器结论不能直接当真机结论。
2. 触控、安全区、前后台恢复、广告/分享中断这些问题，优先在真机路径确认。
3. 没有 ad unit id 时，interactive probe 里 rewarded/interstitial 出现 `skip` 是预期，不是失败。

## 可移植性

1. 不要把参考项目的绝对路径、设备名或固定输出目录写进验证脚本和诊断结论。
2. 任何需要定位产物目录的步骤，都应以目标仓当前 wrapper 输出或 repo-relative 路径为准。
