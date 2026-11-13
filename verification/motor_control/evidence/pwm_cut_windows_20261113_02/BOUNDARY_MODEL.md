# Task A/B：路径核对与局部输入模型

原DCP一次定向只读查询154.512s完成，上限600s；源为design_1_i/adc_observer_0/inst/pwm_anchor_o_reg/Q，目的为design_1_i/pwm_control_0/inst/pwm/timebase/anchor_delayed_reg/D。

clk_pl_0周期20ns、rise0；clk_out1_design_1_pwm_clock_0周期10ns、rise0，MMCM乘2。恢复报告明确同相相关2:1，而非任意异步。

- min：Hold Min at Slow Corner，slack +0.244ns；CQ0.058ns+路由1.730ns=1.788ns，源/目的clock delay2.308/3.699ns。
- max：Setup Max at Slow Corner，slack +8.759ns；CQ0.078ns+路由2.502ns=2.580ns，源/目的clock delay2.606/4.012ns。

本查询只对指定路径，未重新做全设计STA签收。时钟树和源至cut外部完整路由不包含在局部门级网表内。报告中的路由是源Q到最终D的整体值，没有精确分离cut外和cut内分段；不得直接把1.788/2.580ns加到cut端口，造成内部SDF重复计算。

本轮固定采用Review允许的本地安全刺激模型：保留同相相关50/100MHz；anchor及auto valid/compare/seq/inhibit按50MHz上升沿源寄存器语义，使用0.2ns明确建模的源Q/边界延迟，anchor宽度恰一50MHz周期。0.2ns不是已测物理CQ/跨层延迟，也不表示上述全路径的SDF重建。相较上一轮零裕量直驱，该模型保留非零hold刺激且不人为压缩cut内部50→100MHz的10ns setup窗口。启动在下一PWM上升沿，源Q→启动9.8ns、→phase5000为39.8ns，仅为本地模型检查。

rstn/locked按异步安全控制输入建模，避开采样/释放沿；源请求在发射前半周期准备，实际auto端口只在posedge+0.2ns改变。所有cut内门级/SDF/时序检查不变。任何新真实时序异常立即停止，不改phase再试。

局部通过最多证明PWM内部在所声明边界下动态通过，真实源→cut路径仅有本次定向STA及原hardware_02 STA支持，不宣称跨层动态SDF PASS。fast_inhibit原BD恒零，独立动态N/A；上游显式reference rearm逻辑仍是环境假设。
