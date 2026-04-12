# Shared Architecture

这套统一方案的稳定边界分两层：

1. 共享包
   - `addons/minigame_solution/godot_contract/`
   - `addons/minigame_solution/wechat/`
   - `addons/minigame_solution/douyin/`
   - `addons/minigame_solution/validation/`
   - 当前 skill 内置资产源：`assets/portable_solution/`
2. 项目薄封装
   - `autoload/PlatformServices.gd`
   - `platform/PlatformBackend.gd`
   - `platform/wechat/`
   - `platform/douyin/`
   - `tools/wechat/`
   - `tools/douyin/`
   - `Makefile`
   - `data/minigame_subpackages.json`
   - 当前 skill 内置模板源：`assets/project_template/`

## 必须保持的归属

1. 共享壳层、共享导出装配、共享 smoke、共享 API probe、共享 capability matrix 都属于 `addons/minigame_solution/`。
2. 项目自己的 pack 名称、广告位、分享文案、登录交换、关卡入口、UI 业务钩子都属于项目本身。
3. `data/minigame_subpackages.json` 是项目真相源，GDScript runtime 与 Python/shell helpers 必须都读它，而不是各自硬编码。
4. `PlatformServices.run_platform_api_probe()` 是共享 probe 的 Godot 侧入口；壳层自己的 launcher/runtime-only probe 走 `globalThis.godotMinigameProbe`。
5. skill 的 `scripts/install_portable_solution.py` 与 `scripts/ensure_export_presets.py` 只是把内置真相源分发到目标仓，不应成为目标仓运行时依赖。

## 当前已验证的共享实现

1. WeChat 路线是 `Godot Web 导出 -> repo-owned shell/template -> repo-owned JS bridge -> engine 子包装配`。
2. Douyin 路线是 `vendored 官方 exporter -> overlay sync -> clean export -> manifest/build-stamp/probe 注入`。
3. 验证契约不再停留在结构检查，而是“结构 + capability markers + runtime probes + 玩家视角验收”。

## 当前证据基线

1. 该统一方案已经在两个独立的 Godot 4.6 项目上完成迁移验证。
2. 其中一条证据链已经覆盖：
   - WeChat DevTools + Android 真机
   - Douyin Developer Tools + Android 真机
   - 本地 Web 浏览器手工验证
3. 另一条证据链已经覆盖：
   - WeChat export/smoke + DevTools + Android 真机
   - Douyin export/smoke
4. 这意味着统一方案已经跨第二仓证明了迁移可行性，但第二仓的 Douyin 侧仍不应默认声称已有 Developer Tools/真机证据。

## 可移植性补充

1. skill 中出现的目录结构是目标仓应达到的形状，不是某个固定工程名的要求。
2. 对不同项目，输出目录、脚本名字、验证入口可能略有不同；优先遵循目标仓已经暴露的 wrapper 命令，其次才回退到共享脚本相对路径。
3. 当前 skill 已经自带完整共享资产；移植时不要再引用某台机器上的外部共享目录。
