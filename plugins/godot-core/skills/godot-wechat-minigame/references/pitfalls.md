# Pitfalls

## 启动与装配

1. Web 先导出，再组装 WeChat。不要跳过 `build/web/` 前置步骤。
2. `_godot_js_eval(...)` 需要 patch 掉不安全的 `const global_eval = eval` 路径，否则 DevTools 里常见现象是“主页可见但点击无效”。
3. WeChat 导出前要临时移出 `addons/ttsdk.editor` 与共享 Douyin overlay 的 editor 目录，否则 `game.data.bin` 里会混入 editor-only 插件痕迹。

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
