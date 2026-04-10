# Adoption Flow

给新 Godot 仓接入这套统一方案时，按下面顺序做，不要倒序。

## 0. 先做环境预检

1. 找到目标仓根目录，而不是沿用别的机器上的绝对路径。
2. 确认当前机器是否有：
   - Godot 命令
   - WeChat DevTools CLI 或 GUI
   - Douyin IDE / Developer Tools
   - 真机调试条件
3. 如果缺少其中任何一项，继续做能完成的层级，但在结论里明确验证天花板。
4. 当前 skill 已经直接携带共享包与项目模板；除非用户明确要求别的来源，否则默认从当前 skill 的 `assets/` 资产安装，不要再回头找外部共享包目录。

## 1. 先检查仓库适配条件

1. Godot 版本是否与当前共享方案兼容，默认按 Godot 4.6 基线处理。
2. 项目是否已经有明确的 `platform/` 边界；如果没有，先补边界，再谈小游戏。
3. 项目是否使用显式 `export_files`；如果使用，后续所有新增 runtime 资源都必须同步进 `export_presets.cfg`。

## 2. 再落共享包和基线依赖

1. 首次接入直接运行 `python3 scripts/install_portable_solution.py --project-root <target-repo>`。
2. 刷新已经接入过的目标仓时，运行 `python3 scripts/install_portable_solution.py --project-root <target-repo> --overwrite-existing`。
3. 这一步会从当前 skill 的 `assets/portable_solution/` 复制：
   - `addons/minigame_solution/`
   - `addons/godot-minigame/`
   - `addons/ttsdk/`
   - `addons/ttsdk.editor/`
4. 同时会从 `assets/project_template/` 复制项目薄封装模板：
   - `autoload/PlatformServices.gd`
   - `autoload/TTBridge.gd`
   - `platform/`
   - `tools/wechat/`
   - `tools/douyin/`
   - `tools/minigame_preflight.py`
   - `data/minigame_subpackages.json`
5. 不要先复制项目私有 wrappers，再回头补共享包；顺序反了容易导致薄封装失败。

## 3. 最后做项目薄封装

1. 安装后先跑 `python3 tools/minigame_preflight.py`，确认最小接入面已经齐。
2. 再运行 `python3 scripts/ensure_export_presets.py --project-root <target-repo>` 或确认安装器已自动完成这一步。
3. `Makefile` 暴露统一命令：
   - `make export-wechat`
   - `make wechat-smoke`
   - `make export-douyin`
   - `make douyin-smoke`
4. 可以把 skill 自带的 `Makefile.minigame.mk` 合并进目标仓原有命令面，但不要让目标仓长期依赖 skill 目录外部执行。
5. `tools/wechat/*` 与 `tools/douyin*` 只保留共享脚本入口。
6. `platform/PlatformBackend.gd` 只做 shared contract 薄包装。
7. 项目私有差异留在：
   - `project.godot`
   - `data/minigame_subpackages.json`
   - `platform/wechat/`
   - `platform/douyin/`

## 4. 接入完成的最低验证

1. `make export-web`
2. `make export-wechat`
3. `make wechat-smoke`
4. `make export-douyin`
5. `make douyin-smoke`

如果这里只跑通到第 5 步，结论只能是：
- 统一方案已在该仓结构接入成功
- 还不能声称平台端运行已验证

## 5. 接入后常见补项

1. CJK 字体不能依赖宿主，必须打包进仓。
2. 对任意目标仓，至少保留 `tools/minigame_preflight.py` 这类提前失败机制；如果目标仓坚持显式 `export_files`，再额外补本仓自己的导出合同校验。
3. WeChat 与 Douyin 的 ad unit id 缺失时，interactive probe 预期是 `skip`，不是失败。
