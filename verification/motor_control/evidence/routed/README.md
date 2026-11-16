# hardware02 精简布线证据

`hardware_02_audit.json` 来自 `.runtime/motor_control/route_audit_01` 对实际完整 routed DCP 的只读复核；原始报告全留在本机该目录。复核于 2026-11-09 18:38:54 退出0，未写回DCP、改约束或重新实现。

完整STA：WNS +1.272ns、WHS +0.011ns、WPWS +4.000ns，TNS/THS/TPWS均0，无时钟/未约束内部端点均为0。检查了FOC输入下降沿锁存与原核、50↔100MHz双向路径，以及自动禁止两段真实recovery/removal路径。原28个ADC引脚、26位输入的52条min/max路径保持2/10ns预算并通过；这些外部预算仍为工程假设。

整板LUT 78891（67.36%）、FF 94459（40.33%）、DSP 455（36.46%），实际占用CLB 13788/14640（94.18%）。功能CDC告警0，4条vendor告警均在dbg_hub；DRC仍有820条Warning（814条DSP流水建议及其余6条），方法学40条Warning和2条Advisory，未宣称零告警。

`export_boundary.json` 保留了本次SDF导出的失败、完整视图对照及最终修复记录：新AUTO路径只将不支持仿真的ILA置为黑盒，保留结构dbg_hub，正式入口成功输出匹配的timesim Verilog及slow/fast SDF。旧非AUTO默认边界不变，原DCP/bit/XSA未改。此记录证明导出与静态时序；SDF实际运行结果另记。板卡及功率级均NOT_RUN。
