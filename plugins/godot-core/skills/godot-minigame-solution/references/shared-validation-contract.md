# Shared Validation Contract

统一方案的验证一定要分层，不要把任何单层结果误判成“全部完成”。

## 第一层：静态产物验证

目标：
1. 确认导出目录结构正确。
2. 确认平台所需文件和 patch markers 还在。
3. 确认 capability matrix 里的关键 API markers 还在。

典型命令：
1. `python3 tools/minigame_preflight.py`
2. `make wechat-smoke`
3. `make douyin-smoke`
4. `python3 addons/minigame_solution/validation/validate_platform_apis.py --profile wechat --artifact-root ...`
5. `python3 addons/minigame_solution/validation/validate_platform_apis.py --profile douyin --artifact-root ...`

## 第二层：可执行 runtime probe

目标：
1. 真正调用登录、存储、request、socket、share、keyboard、subpackage 等能力。
2. 不通过项目私有 debug UI，而通过共享 query-driven probe 合同触发。

典型触发：
1. `api_probe=1`
2. `api_probe_calls=...`
3. `api_probe_request_url=...`
4. `api_probe_socket_url=...`
5. `api_probe_subpackage=...`

解释规则：
1. `pass` 表示当前运行时里调用成功。
2. `skip` 只在理由明确时成立，比如广告位没批下来、接口地址未配置、当前 probe 禁止 UI。
3. `fail` 默认按真实兼容性或配置问题处理。

## 第三层：宿主与玩家视角验收

至少区分：
1. DevTools / IDE startup/basic interaction
2. 真机 startup/basic interaction
3. 玩家视角手工验收

不要把这三者写成同一层证据；它们可以逐步建立，但不能相互替代。

必须手工验证：
1. 冷启动进入主页
2. 真正进入一局
3. 至少一次 win/fail 流程
4. 前后台恢复
5. 重启与存档
6. 实际启用的分享、广告、登录、分包路径

## 第四层：可选 remote debug

1. remote debug 对深层设备诊断有帮助，但默认不是“平台已验证”的必需退出门槛。
2. 如果当前宿主产品或当前 WebGL 路线不支持 remote debug，不要因此倒推 DevTools 或真机 startup/basic interaction 也无效。
3. 如果任务目标明确要求设备侧深调、性能或网络抓取，再把这一层提升成必答项。

## 证据锚定

1. 手工验证结论必须锚定到当前 artifact 路径。
2. 手工验证结论必须锚定到当前 build stamp 或等价版本标识。
3. 发现 IDE 里还是旧错误时，先排除旧导入包、旧缓存、旧 build stamp，再继续怀疑当前导出逻辑。

## 退出门槛

只有同时满足下面三点，才能说“该平台已验证”：
1. 静态产物验证通过
2. 相关 runtime probes 通过或有明确 `skip`
3. 目标验收面的宿主 startup/basic interaction 与玩家视角手工验收完成

remote debug 只有在任务明确要求时，才进入必需门槛。
