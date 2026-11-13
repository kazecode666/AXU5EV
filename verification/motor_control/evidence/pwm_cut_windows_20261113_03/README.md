# PR41 第三轮：统一源协议后遇native接受条件疑点

- [集中报告](<RESULT_REPORT.md>) / [最终矩阵](<results.json>) / [硬停止记录](<HARD_STOP.json>)。
- [候选与修改依据](<CANDIDATES.md>) / [固定执行边界](<EXECUTION_POLICY.md>)。
- [v1 TB](<v1/pwm_cut_tb.sv>) / [源协议静态设计记录](<v1/PROTOCOL.md>) / [运行器](<v1/run_corner.py>)。
- [语法预检](<v1/syntax/summary.json>)、[成功注释](<v1/slow/xelab.stdout.log>)、[首笔真实trace与500us进度](<v1/slow/xsim.stdout.log#L18-L31>)。

**SLOW=FAIL_HARD_STOP，FAST=NOT_RUN，FULL_CHAIN_SDF=NOT_COMPLETED。1/3候选，无v2/v3。**

首笔910ns源握手，910.2ns真实撤销，930ns没有重复；但native捕获CE0、busy/request0、500us仍未接受。native LUT INIT及reset条件对cut输入inhibit的直接含义与RTL相反，归因尚未确认，触发Review硬停止，未反相输入或调延迟重试。

原summary的RUNNING为中断快照；最终以HARD_STOP与results为准。PROTOCOL静态文档中的NOT_RUN是实现时快照，不是最终运行状态；其中服务器本地源文件/网表链接用于原现场定位，生成网表/SDF/原DCP不进入Git。本目录只精简原创TB/runner及文本日志证据，不改旧_01/_02或生产RTL。
