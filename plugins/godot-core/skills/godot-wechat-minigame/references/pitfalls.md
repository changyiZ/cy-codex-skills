# Pitfalls

## 启动与装配

1. Web 先导出，再组装 WeChat。不要跳过 `build/web/` 前置步骤。
2. `_godot_js_eval(...)` 需要 patch 掉不安全的 `const global_eval = eval` 路径，否则 DevTools 里常见现象是“主页可见但点击无效”。
3. WeChat 导出前要临时移出 `addons/ttsdk.editor` 与共享 Douyin overlay 的 editor 目录，否则 `game.data.bin` 里会混入 editor-only 插件痕迹。
4. 处理 Godot 4.6.2 紧凑输出里的 `_emscripten_get_now` 时，只改右侧表达式，不要把 `var` 声明关键字再写回去；否则会变成 `var var ...` 并在 transpile 阶段报语法错。
5. 处理 `mainWasm` 时，要同时改 `Engine.load(...)` 的调用点和 `Engine.load = function (basePath, size, mainWasm)` 的函数签名；只改 body 或调用点会在 DevTools 启动时报 `ReferenceError: mainWasm is not defined`。
6. WeChat wrapper 应优先确保原生 `esbuild` 可用；`esbuild-wasm` 只应作为慢速 fallback，不应默默长期留在主路径。

## DevTools 与宿主链路

1. WeChat DevTools CLI 卡住时，先查是不是旧 GUI 实例占着 `.ide` 或 service port，而不是先判定导出包坏了。
2. 如果 `cli open --port ...` 能重新写出 `~/Library/Application Support/微信开发者工具/.../Default/.ide` 并恢复 HTTP 控制端口，优先把问题归到 IDE launch/profile 层。
3. remote debug 是单独能力层，不要把它和 DevTools startup/basic interaction 或真机 startup/basic interaction 混为一谈。

## 输入与宿主契约

1. `weapp-adapter.js` 里的 `canvas.getBoundingClientRect()` 必须返回 `x`、`y`、`right`、`bottom`，不能只给 `top/left/width/height`。
2. Godot 一旦拿到正确 adapter 坐标，`platform/wechat/WeChatPlatformBackend.gd` 不得再做第二次缩放；否则点击会整体偏移。

## 资源与文件系统

1. 主内容包当前稳定文件名是 `game.data.bin`，不要回退到根包 `.pck`。
2. `http://usr/...` 对 WeChat 来说仍是本地打包资源，不应被当成远程 URL。
3. 主内容包应先走 inline asset，再走 `fsUtils.localFetch(...)` fallback，避免 Android 真机读本地文件噪音。

## 字体与文本

1. 不要依赖宿主字体。中文文本要打包 subsetted CJK 字体或等价字图方案。
2. 对显式 `export_files` 仓库，新增字体后必须同步更新 `export_presets.cfg`，否则症状可能是脚本编译失败和一串误导性的 `Nil` 报错。

## 可移植性

1. 不要把参考项目的绝对路径、设备名或固定输出目录写进验证脚本和诊断结论。
2. 任何需要定位产物目录的步骤，都应以目标仓当前 wrapper 输出或 repo-relative 路径为准。
