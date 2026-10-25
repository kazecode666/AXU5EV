# AX-01 R5F—PL控制边界

目标AXU5EVB-E；本文件把现有算法端口对应到集成需求，尚未实现AXI寄存器/BRAM协议，也未分配新板IO。

## 算法与时序

`firmware/r5/AXU5EV_R5_Control.slx`由现有主模型的Control_Task与Alignment_Task提取。R5每100µs调用一次生成C的`AXU5EV_R5_Control_step()`；内部保留原调度器的1ms速度、10ms位置首相和保持行为。初始化一次调用`initialize()`，不能每帧初始化。板上定时/中断、任务抖动和WCET待实现及测量。

R5保留位置P、速度PI、Reference_Manager、五态对齐、一次性偏置和参考选择/故障置零。PL保留电流FOC、采样/位置同步、每帧角度与偏置应用、PWM及快速禁止。轨迹/命令由现有Simple_Host和`pmlsm_point_move_step`提供来源；本轮尚未将Host_Core/交互入口纳入部署模型，不把测试输入序列当成轨迹管理实现。

## 软件端口

输入均沿用double参考语义，单位不变；0/1命令不因此合并。

| 输入 | 来源/语义 |
|---|---|
| x_ref_mm、v_ref_cmd、id_ref_cmd、iq_test_ref | 现有命令/轨迹输出，mm、mm/s、Apeak |
| x_mm、v_mmps | 同一反馈快照的位置/速度，mm、mm/s；现有MIL使用理想反馈，硬件来源另适配 |
| Position_Loop_EN、Close_Loop_EN、iq_test_mode | 原模式选择 |
| PI_Reset_EN | 原PI复位；不等同Init_Reset、全局复位或驱动清故障 |
| Alignment_Enable、Init_Start、Init_Reset | 原对齐旁路/手动Start/复位；不自动Start |
| travel_fault_latch | 已锁存行程故障；不把此输入当成全部ERRI/ERRU保护的实现 |

| 输出 | 去向/语义 |
|---|---|
| id_ref_A、iq_ref_A | PL电流核参考，Apeak；已包括原对齐选择与原alignment_fault置零 |
| Theta_Offset_auto、Angle_Init_EN | 原子提交给PL的偏置rad及对齐模式；实时角度范围处理留PL |
| Init_Done、Init_State_Num、id_init_ref、x_align_mm_latch | 原状态/诊断；0..4依次IDLE/RAMP_ID/HOLD_ALIGN/RAMP_DOWN_ID/DONE |
| alignment_ready、done_or_bypass、alignment_fault、v_ref_mmps | 供命令/恢复与诊断，不能替代PL/驱动硬件快速禁止 |

原对齐10000/30000/2000拍、0.5A与一次性`mod(theta_align_const-2*pi*x/Tau_e_mm,2*pi)`未改变。PWM禁止后仍由原机械模型/真实机械继续演化，不以软件置零位置模拟停止。

## 继承接口及PL数值边界

需求来自[旧硬件接口](../../references/legacy/PMLSM_Hardware_Interface_Map.md)、MBDL4参数及MIL/DSP：YXPHM-MBDL4；独立ia/ib/ic，不默认重构ic；光栅0.1µm/count；RELCON、ENCON、F_Reset和低有效ERRI/ERRU。旧速度差分资料为50×100µs，不能把新模型的理想v输入误称已实现该采集链。旧DSP GPIO/ePWM/ADC配置不直接映射新板。

| 已接受FOC_DUT端口 | 原类型/比例 | 新集成约束 |
|---|---|---|
| ia/ib/ic、id_ref/iq_ref | signed32，24小数位，Apeak | 复用现有类型，新增转换必须对照模型验证；不缩位或标幺化 |
| theta_e | signed40，32小数位，rad | 由PL实时位置/偏置路径产生，不由R5每拍往返代算 |
| omega_e | signed40，24小数位，rad/s | 来源、方向及采样一致性需与位置链核对 |
| Vdc_V | unsigned32，24小数位，V | 当前48V基准；在线ADC尚未接入，不冒充已有实测 |
| PI_Reset_EN | boolean | 保留原积分/AW消费与提交语义，独立于核reset |
| duty_u/v/w_cmd | unsigned32，30小数位 | 连接新PWM时保留极性和一次死区/应用延迟，不能直接当门极线 |

类型依据为`pmlsm_foc_fixed_config.m`与`generated/legacy_m3_p3/FOC_DUT.sv`。p3原5000快时钟/帧和314拍输出仅是旧50MHz配置的来源事实；新5EV时钟/调度需重新配置并验证，不直接套用。

## 待实现的交换与硬件适配

- 多字段命令先暂存，再用序列号提交；PL在明确的电流帧边界一次采纳，反馈提供同拍快照、帧号与采用的命令序号。具体地址、字节序、40位打包、屏障/cache/MPU及应答逻辑尚未实现。
- 电流核不能等待每次R5计算；未收到新命令时的保持、过期阈值及禁止行为需在总线实现时确定，不能以本轮主机验证认定满足时限。
- ERRI/ERRU的PL/驱动快速禁止独立于R5计算；R5负责恢复管理。F_Reset、PI_Reset、Init_Reset及重新使能仍是分别请求，清故障不自动重启。
- 新板外置ADC选型/通道/量程、光栅接收/电平、MBDL4门极/RELCON/ENCON/故障接线、具体PCB/芯片料号与XDC仍待适配。原100µs控制、50µs应用和1µs死区是保留的算法参考，不是新板端到端实测。

本轮生成和回放的是Windows主机C。R5目标编译、Vitis域/BSP/启动、AXI/CDC实现、5EV综合/布线、ARM实测、板上时延、烧录/上电均NOT_RUN。
