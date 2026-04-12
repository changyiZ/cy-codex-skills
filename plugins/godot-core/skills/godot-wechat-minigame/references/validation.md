# Validation

## 最低静态验证

1. `python3 tools/minigame_preflight.py`
2. `make export-wechat`
3. `make wechat-smoke`
4. `python3 addons/minigame_solution/validation/validate_platform_apis.py --profile wechat --artifact-root build/wechat-minigame/minigame`

`make wechat-smoke` 不应只检查文件存在；它还应覆盖当前共享 patch 的关键启动约束，例如处理后的 `engine/godot.js` 不能出现“函数体引用 `mainWasm`、但 `Engine.load(...)` 签名没有声明它”的半修状态。

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
2. WeChat DevTools startup/basic interaction 通过，才能证明宿主里基本可启动、可交互。
3. Android 或 iPhone 真机 startup/basic interaction 通过，才能证明真实设备路径基本成立。
4. remote debug 另算；它有帮助，但默认不是“平台已验证”的必需门槛。
5. 最终仍要补玩家视角验收。

## 环境能力上限

1. 如果当前机器没有 WeChat DevTools，只能停在静态验证和可离线执行的 probe 准备层。
2. 如果只有 DevTools 没有真机，结论只能到宿主模拟/IDE 层，不能外推到真实设备。
3. 如果 remote debug 不可用或宿主产品当前不支持，不要倒推 DevTools startup/basic interaction 或真机 startup/basic interaction 也无效。
4. 如果目标项目没有 share、revive、login 等业务配置，只验证目标项目实际启用的路径，并把其余项记为未启用或待配置。

## 证据锚定

1. 手工验证结论要绑定当前 artifact 路径和 build stamp。
2. 如果 DevTools 仍显示旧错误，先确认导入的是不是最新导出包，再决定是否继续排障。

## 当前推荐验收路径

1. 冷启动到主页
2. 进入真实关卡
3. 完成一次 win/fail
4. 前后台切换
5. 重启与存档恢复
6. 项目实际启用的 share / revive / login
