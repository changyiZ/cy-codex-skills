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

## 第三层：玩家视角验收

必须手工验证：
1. 冷启动进入主页
2. 真正进入一局
3. 至少一次 win/fail 流程
4. 前后台恢复
5. 重启与存档
6. 实际启用的分享、广告、登录、分包路径

## 退出门槛

只有同时满足下面三点，才能说“该平台已验证”：
1. 静态产物验证通过
2. 相关 runtime probes 通过或有明确 `skip`
3. 玩家视角手工验收完成
