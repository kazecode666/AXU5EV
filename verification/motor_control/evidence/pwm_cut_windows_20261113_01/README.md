# Issue40 / PR41 — Windows PWM cut SDF 一次性证据

**本轮已执行后停止：SLOW=FAIL，FAST=NOT_RUN，无动态SDF PASS。**

- [实际执行报告](<RESULT_REPORT.md>)、[状态矩阵](<results.json>)。
- [slow展开/注释日志](<slow/xelab.stdout.log#L14-L15>)：xelab14.20秒、exit0、SDF注释成功，非原全量性能超时。
- [首次动态日志](<slow/xsim.stdout.log#L14-L15>)：anchor_delayed_reg在760/820ns出现60ps hold违例；[实际动态记录](<slow/dynamic_review.json>)；[终止记录](<termination_record.json>)。
- [原样归档TB](<pwm_cut_tb.sv>)、[原生导出Tcl](<export_cut.tcl>)及[保留结构审核](<cut_audit.md>)。

## 判定与边界

本轮TB在50MHz下降沿直接切换anchor，恰与所建100MHz上升沿重合，形成零保持裕量。该边界刺激缺陷足以解释已见hold违例；未修正复验，不能排除其他问题，不能据此认定生产DUT失败。取消/谷值/整组/死区等场景没有完整跑完。遵守一次性停止规则，未改后重跑、换优化等级、重建硬件或运行fast。

完整39位frozen/pending/active银行、握手、release、时基与三相死区静态保留。fast_inhibit在原routed设计已无有效连接，独立输入动态覆盖N/A；上游FOC/ADC、外部时钟/复位树及完整跨切点互连不在覆盖范围；sticky inhibit/显式reference重臂是环境假设。FULL_CHAIN_SDF继续NOT_COMPLETED；原FULL_DESIGN_STA及FULL_CHAIN_RTL证据不变。

## 归档口径

本目录是原执行现场的精简文本归档，不是已修正/可直接重跑的生产验证入口；脚本中的本机绝对路径和运行器前置门控缺陷均原样保留。不得直接运行并当作新的授权。

[初始summary](<slow/summary.json>)的FAIL是过宽WARNING门控停机；之后人工只审查三条非SDF/时序警告，对同一成功快照执行首次xsim，[dynamic_review](<slow/dynamic_review.json>)才是该次真实动态结果。没有重复xelab。总体验收以[results](<results.json>)为准。

原报告的GitHub“未发布”描述是授权前快照；之后已完成官方CLI授权并发布[结果评论](https://github.com/kazecode666/AXU5EV/pull/41#issuecomment-6846128862)，见[授权后回执](<github_posted_after_auth.json>)。本次仅追加证据提交及链接评论，不改变当时原始记录。

原始DCP、导出的网表/SDF、编译缓存及完整现场保留在服务器 D:/Weiwen Li/AXU5EV/pwm_cut_sdf_20261113_1404。它们不进入本次Git提交；审核记录中指向这些未提交文件的链接/行号是服务器本地定位，不是GitHub附件。没有生成文件哈希、提交摘要校验或重跑旧验证。

PR41保持Draft，Issue40开放；没有生产RTL、参数或约束变更，没有板卡/驱动器/电机操作。
