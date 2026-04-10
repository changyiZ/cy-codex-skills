# Upgrade Monitoring

这套 skill 现在自带一套“升级巡检”机制，不再只靠作者手动想起来再检查。

## 监控目标

分四层：
1. 官方文档变化
   - 微信通用引擎适配概览 / QuickStart / Tech Principle
   - 抖音 WebGL 方案概述
   - 抖音服务端指引
   - 抖音分包文档
   - 抖音引擎选择建议
2. 外部/社区方案变化
   - `godothub/godot-minigame`
   - `godotengine/godot` 最新 release 线
3. 依赖变化
   - WeChat 导出链里用到的 `esbuild`
4. skill 内置资源漂移
   - `assets/portable_solution/` 与实现仓 `addons/` 是否同步
   - `assets/project_template/` 与实现仓薄封装核心文件是否同步

## 入口脚本

主入口：
1. `scripts/check_upstream_updates.py`

配置：
1. `monitoring/watchlist.json`

## 推荐执行方式

作者本机巡检：

```bash
python3 scripts/check_upstream_updates.py --source-repo <implementation-repo>
```

如果只想看官方/外部/依赖信号，不做本地资源漂移比对：

```bash
python3 scripts/check_upstream_updates.py
```

如果要把结果交给自动化或别的脚本消费：

```bash
python3 scripts/check_upstream_updates.py --source-repo <implementation-repo> --output-format json
```

## 结果解释

重点状态：
1. `baseline`
   - 首次记录基线，还没有“上次”可比
2. `no_change`
   - 本次和上次相比没有变化
3. `changed`
   - 上游内容或版本线发生变化，需要人工复核
4. `behind`
   - 当前 pinned 版本或兼容基线落后于上游
5. `drift`
   - skill 内置资源与实现源不一致，需要刷新 bundle
6. `error`
   - 当前检查失败，不能把它当“无变化”

## 作者维护建议

1. 周期性巡检至少按周跑一次。
2. 只要出现 `changed` / `behind` / `drift`，都应该进入人工复核队列。
3. 官方文档变化先判断“文档编辑”还是“方案变化”。
4. 资源漂移优先处理，因为这说明 skill 打包载荷已经和当前实现源脱节。
5. 升级完成后再次运行巡检，让状态文件写入新的基线。
