# Pitfalls

## exporter 与装配

1. 先 sync overlay，再导出；不要直接把本地修改长期留在 vendored `addons/ttsdk.editor/`。
2. 导出目录必须先 clean，再写入新产物，否则 Developer Tools 很容易导入到混合旧包。
3. `douyin-manifest.json` 和根 `game.js` build stamp 是判断“是否旧包”的第一证据。
4. 如果 Developer Tools 报 `Pack created with a newer version of the engine`，不要只看模板目录名；优先解压检查导出的 `godot/godot.wasm.br` 真实版本。
5. 一旦怀疑 runtime 版本漂移，先把官方 `web_nothreads_debug.zip` / `web_nothreads_release.zip` 同步回 vendored exporter，再重新导出。

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
4. 当控制台 build stamp 和当前导出包不一致时，优先把问题归为旧导入包或 IDE stale state，而不是当前代码回归。
5. iOS preview/basic startup 和 iOS remote debug 是两层不同能力；当前 WebGL 路线里，generic USB warning 不能直接当成项目运行失败。
6. 如果宿主产品当前不支持 iOS WebGL remote debug，就接受 iOS preview/basic startup 作为当前可达到的有意义验证层，把深度设备调试转移到 Android 或其他受支持路径。

## 可移植性

1. 不要把参考项目的绝对路径、设备名或固定输出目录写进验证脚本和诊断结论。
2. 任何需要定位产物目录的步骤，都应以目标仓当前 wrapper 输出或 repo-relative 路径为准。
