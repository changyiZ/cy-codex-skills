# Validation

## 最低静态验证

1. `python3 tools/minigame_preflight.py`
2. `make export-douyin`
3. `make douyin-smoke`
4. `python3 addons/minigame_solution/validation/validate_platform_apis.py --profile douyin --artifact-root build/tt-minigame`

如果出现 pack/runtime 版本不匹配症状，再追加一层产物核验：检查当前导出包解压后的 `godot/godot.wasm.br` 版本和 build stamp，而不是只看 exporter 模板目录名。

如果目标仓输出目录不同，优先使用仓内 wrapper 打印出来的 artifact 路径，不要硬套别的项目目录名。

## 推荐 probe 验证

1. readonly probe
2. network probe
3. subpackage_and_scene probe
4. interactive probe

优先使用共享模板：
1. `python3 addons/minigame_solution/validation/render_platform_api_probe_template.py --platform douyin --list`
2. `make probe-template PLATFORM=douyin TEMPLATE=readonly FORMAT=query`

## 证据分层

1. `make douyin-smoke` 通过，只能证明静态产物结构正确。
2. Douyin Developer Tools startup/basic interaction 通过，才能证明宿主里基本可启动、可交互。
3. Android 或 iPhone 真机 startup/basic interaction 通过，才能证明真实设备路径基本成立。
4. remote debug 另算；它有帮助，但默认不是“平台已验证”的必需门槛。
5. 最终仍要补玩家视角验收。

## 环境能力上限

1. 如果当前机器没有 Douyin IDE / Developer Tools，只能停在静态验证和可离线执行的 probe 准备层。
2. 如果只有 IDE 没有真机，结论只能到宿主模拟/IDE 层，不能外推到真实设备。
3. 如果 remote debug UI 不可用，但 preview/basic startup 已经通过，不要把两者混写成同一个 blocker。
4. 如果目标项目没有 share、广告、登录或分包配置，只验证目标项目实际启用的路径，并把其余项记为未启用或待配置。

## 证据锚定

1. 手工验证结论要绑定当前 artifact 路径和 build stamp。
2. 如果 IDE 里还显示旧报错，先确认导入的是不是最新导出包，再决定是否继续排障。

## 当前推荐验收路径

1. 冷启动到主页
2. 进入真实关卡
3. 完成一次 win/fail
4. 前后台切换
5. 分享、广告、登录、分包路径按目标项目实际启用项验证
