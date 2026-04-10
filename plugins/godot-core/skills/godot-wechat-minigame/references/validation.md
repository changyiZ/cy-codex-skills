# Validation

## 最低静态验证

1. `python3 tools/minigame_preflight.py`
2. `make export-wechat`
3. `make wechat-smoke`
4. `python3 addons/minigame_solution/validation/validate_platform_apis.py --profile wechat --artifact-root build/wechat-minigame/minigame`

如果目标仓输出目录不同，优先使用仓内 wrapper 打印出来的 artifact 路径，不要硬套别的项目目录名。

## 推荐 probe 验证

1. readonly probe
2. network probe
3. interactive probe

优先使用共享模板：
1. `python3 addons/minigame_solution/validation/render_platform_api_probe_template.py --platform wechat --list`
2. `make probe-template PLATFORM=wechat TEMPLATE=readonly FORMAT=query`

## 证据分层

1. `make wechat-smoke` 通过，只能证明静态产物结构正确。
2. WeChat DevTools 通过，才能证明宿主里基本可启动、可交互。
3. Android 或 iPhone 真机通过，才能证明真实设备路径基本成立。
4. 最终仍要补玩家视角验收。

## 环境能力上限

1. 如果当前机器没有 WeChat DevTools，只能停在静态验证和可离线执行的 probe 准备层。
2. 如果只有 DevTools 没有真机，结论只能到宿主模拟/IDE 层，不能外推到真实设备。
3. 如果目标项目没有 share、revive、login 等业务配置，只验证目标项目实际启用的路径，并把其余项记为未启用或待配置。

## 当前推荐验收路径

1. 冷启动到主页
2. 进入真实关卡
3. 完成一次 win/fail
4. 前后台切换
5. 重启与存档恢复
6. 项目实际启用的 share / revive / login
