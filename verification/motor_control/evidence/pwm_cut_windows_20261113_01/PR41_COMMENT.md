Windows服务器一次性PWM cut SDF结果（2026-11-13）：

- 原hardware_02 DCP，仅原生导出design_1_i/pwm_control_0/inst；未重建硬件，未编辑网表/SDF，未改生产RTL，未操作板卡。
- Task1导出228.6s；primitive 196766→1204（163.4×），网表95.23MB→0.377MB（252.4×），两角SDF约486/489MB→1.62/1.64MB（约299×）。frozen/pending/active各39位、相关握手/release/时基/死区保留，静态SDF路径匹配。
- slow/max：xvlog1.78s、xelab14.20s exit0；XSIM43-3452确认SDF成功注释并生成快照。首次xsim实际启动，约142.67s墙钟后按停止规则终止：anchor_delayed_reg在模拟760ns及820ns报告60ps hold违例，无动态PASS。
- 根因边界：本轮适配TB在50MHz下降沿直接切换anchor，恰好与所建100MHz上升沿重合，切掉外部数据/时钟传播后造成零保持裕量。属于该局部TB刺激/边界建模失败，不据此认定生产DUT功能失败。不修改后重跑、不换优化等级；fast/min NOT_RUN。
- PWM_CUT_SDF_SLOW=FAIL；PWM_CUT_SDF_FAST=NOT_RUN；FULL_CHAIN_SDF继续NOT_COMPLETED；原FULL_DESIGN_STA及FULL_CHAIN_RTL证据不变，不以局部替代。整组/谷值/取消/失锁/死区动态场景尚未完成。
- fast_inhibit在原routed设计已无有效连接，独立输入动态覆盖N/A；外部时钟树/互连、FOC/ADC、上游显式重臂策略不在局部SDF覆盖范围。
- 建议后续单独授权建立有明确相位、源clock-to-Q及输入预算的RTL上游+局部SDF PWM混合边界，再验证；本轮未执行，不恢复全量24小时xelab。

完整现场保留服务器D:/Weiwen Li/AXU5EV/pwm_cut_sdf_20261113_1404，含TB、导出Tcl、原始日志及报告；不提交巨大生成文件。PR保持Draft待Review，Issue保持开放。
