# Review6846401773 Task A–D 实施对应

- A已完成：见[probe](<probe_anchor.tcl>)、[真实源/端点](<endpoints.txt>)、[min](<anchor_min.rpt>)、[max](<anchor_max.rpt>)、[时钟关系](<clock_relationships.rpt>)；没有全量路径扫描或实现。
- B已修复：[TB](<pwm_cut_tb.sv>)源posedge+0.2ns、20ns anchor、同相相关2:1；原36条检查保留，新44条，3次启动/peak强制非空，35原生端口全部连接。其余自动输入使用同一源寄存器语义，异步控制显式安全边界；[模型限制](<BOUNDARY_MODEL.md>)。
- WARNING门禁：[runner](<run_corner.py>)不以任意WARNING判SDF失败，仅对逐条审过的旧TB提示精确匹配；真实SDF/时序异常和未知warning仍停止。旧未接读响应已接线，固定任务参数等待增加guard。没有新增输入文件哈希。
- C每角一次：[范围和预算](<ROUND_SCOPE.md>)；slow实际PASS才fast；记录每阶段命令、退出、墙钟、真实进度/时间、marker。原网表/SDF只复用，未编辑/重导出。
- D执行结果将单独归档实际summary/报告，不覆盖旧FAIL，不自动进入重试；局部结果与FULL_CHAIN_SDF/原STA/RTL严格区分。无板卡操作。
