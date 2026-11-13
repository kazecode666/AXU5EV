# PR41 Review6846401773 — 第二轮局部SDF真实结果

**SLOW=FAIL（首笔源握手唯一性断言），FAST=NOT_RUN，FULL_CHAIN_SDF=NOT_COMPLETED。**

- [实际执行报告](<RESULT_REPORT.md>)、[状态矩阵](<results.json>)。
- [源边界模型与限制](<BOUNDARY_MODEL.md>)；[TB](<pwm_cut_tb.sv>)、[runner](<run_corner.py>)。
- [真实注释日志](<slow/xelab.stdout.log>)：唯一xelab10.25s成功；两条task固定参数提示精确归类保留。
- [真实动态日志](<slow/xsim.stdout.log#L14-L23>)：20ns anchor和首次4997→5000已执行；930ns unique source offer fatal，无动态PASS。
- [命令、耗时及退出竞态](<slow/summary.json>)。
- task_a目录为原DCP154.5s定向查询，hold+.244ns、setup+8.759ns；未重做全设计STA。
- compile_preflight目录保留1522最初声明顺序编译失败的TB/runner/日志/summary；无xelab/xsim。最终candidate只移声明顺序并修runner文件路径误分类，见[前置纠正](<BUILD_CORRECTION.md>)。

本轮我新增源寄存器后，offer task的valid_request撤销晚了一拍，导致实际valid在930ns源边沿仍有效，触发原有唯一握手断言。不能将此TB源驱动/监视契约失败转嫁为生产DUT失败；真实新动态断言出现后停止，未删除断言或移动phase重跑。

完整三相/谷值/取消/lock/rearm/死区/边界占空比覆盖未完成；启动3次最终条件也未完成。局部边界0.2ns是显式假设，不是实际跨层SDF；上游FOC/ADC/reference重臂与外部clock/reset tree仍不在局部门级覆盖，fast_inhibit原BD恒零动态N/A。原STA/RTL证据不变。

旧1404 FAIL、本轮1522编译失败、1522_buildfix动态失败全保留。服务器原网表/SDF复用，无重导出/实现/哈希检查/打包/同步；Git仅原创文本证据，不含DCP/网表/SDF/缓存。没有板卡操作；PR41保持Draft，Issue40开放。
