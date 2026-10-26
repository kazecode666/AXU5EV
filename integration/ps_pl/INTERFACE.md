# AX-01B R5F—PL控制边界

目标AXU5EVB-E。本轮已有主机生成C＋p3 XSI仿真交换；尚未实现AXI寄存器/BRAM协议，也未分配新板IO。

## 算法与时序

PR5的`simulation/AXU5EV_R5_Control.slx`为组件来源。本轮新增`AXU5EV_R5_Runtime.slx`，复用其中Motion_Control／Alignment_Task并直接纳入原Simple_Host/Host_Core；每100µs调用一次生成C的`AXU5EV_R5_Runtime_step()`。内部保留1ms速度、10ms位置首相和保持行为。初始化仅在新Run发生，暂停／继续不初始化。板上定时/中断、任务抖动和WCET待实现及测量。

R5保留位置P、速度PI、Reference_Manager、五态对齐、一次性偏置和参考选择/故障置零。原Host_Core调用原`pmlsm_point_move_step`／`pmlsm_scurve_profile`，状态位于生成C。PL职责仍为电流FOC、采样/位置同步、每帧角度与偏置应用、PWM及快速禁止；本轮角度和实际许可仍由共享集成模型显式计算，尚未硬件化。

| 同拍顺序 | 本轮实现 |
|---|---|
| 采样 | 读取命令／机械位置速度／复位故障的20字段快照 |
| Runtime | 原Alignment_Task → 原Host_Core → 原Motion_Control；软件时基为整数拍计数×100µs，后更新计数 |
| 提交 | 一次输出41字段向量；电流参考、偏置、模式等同次提交，不逐字段异步更新 |
| FOC输入 | 原Alignment_Interface选择实时／固定角并应用偏置；九字段ZOH和共同定点量化 |
| p3 | 帧首前negedge锁存九字段，50MHz全5000拍；核心post314结果由外寄存器在edge315捕获 |
| 应用 | 同一个半帧function-call采样器在采样后50µs采用三相duty；初值0.5，原一次死区仍在逆变器中 |

软件计算及仿真交换为零执行耗时的功能因果模型。XSI每次调用批量推进完整100µs，期间输入保持、不读取未来电机反馈；不会把批量执行耗时加进仿真时间。此处不构成R5/AXI时限结论。

## Runtime实际交换字段

输入`runtime_u[20]`与输出`runtime_y[41]`均为double向量；表中位置为MATLAB的一基索引。命名和单位明确，真实AXI打包另行设计。

| 输入索引 | 字段 |
|---|---|
| 1–11 | 目标草稿mm、速度mm/s、id A、iq测试模式、iq测试A、位置环使能、速度环使能、PWM请求、PI复位请求、replay使能、Send翻转位 |
| 12–14 | 原replay速度mm/s、PWM、PI复位输入 |
| 15 | 同拍v_mmps |
| 16–19 | Alignment_Enable、Init_Start、Init_Reset、travel_fault_latch |
| 20 | 同拍x_mm |

Issue #8 按用户现有接线统一输入顺序。Hybrid Mux 与 Runtime Demux 均显式设置分组宽度 `[11 3 1 1 1 1 1 1]`：前两路分别为11字段命令与3字段replay，其余6路均为标量。Demux的输出端口号不等于向量字段索引；第8路才是位置反馈（字段20）。两端旁注列出同一映射。输出41字段顺序保持不变。

旧PR7记录中的输入顺序为命令、位置、速度、对齐4字段、replay3字段。旧波形保留其原合同，不能直接按本表解释；改接口后必须由Runtime模型重新生成C并重建MEX，再使用新运行记录对照，不能只重接模型而继续加载旧MEX。

| 输出索引 | 字段 |
|---|---|
| 1–3 | id_ref_A、iq_ref_A、v_ref_mmps |
| 4–9 | Init_Done、Init_State_Num、id_init_ref、Angle_Init_EN、Theta_Offset_auto rad、x_align_mm_latch |
| 10–12 | alignment_ready、done_or_bypass、alignment_fault |
| 13–18 | x_ref_mm、Vdc V、load N、Close_Loop_EN、Position_Loop_EN、PWM请求 |
| 19–23 | v_ref_cmd、id_ref_cmd、iq_test_mode、iq_test_ref、原PI复位请求 |
| 24–30 | 接受目标mm、Busy、in_position、命令状态、段起点mm、段起时s、轨迹完成 |
| 31–36 | Ready、接受数、拒绝数、segment_id、命令接收软件时刻s、中断状态 |
| 37–41 | 原轨迹V、A、J、minRamp、Ts配置 |

原有效PI复位为`请求 || !PWM请求 || alignment_fault`，与Init_Reset、全局reset分开。对齐、参考选择和外环消费顺序沿用原模型，未给命令额外增加一帧延迟。Host面板只产生命令输入，不再另算轨迹。

`integration/r5_host/ax01b_r5_sfun.c`在每100µs新采样时装载输入并调用一次step，重复求解器Outputs调用只返回当前结果。bridge翻译单元隔离SimStruct和生成类型；新Run清理生成状态后initialize，不修改生成C。当前是非重入的单实例封装，不应在同一MATLAB进程复制多个独立实例共享同一生成全局状态。

## 继承的PR5组件端口

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

集成模型共同使用Convergent舍入、Saturate转换，再以可精确表示的double物理量交给两种FOC后端。XSI桥按对应小数位转回原整数位串；40位用64位整数承载，未截成int32；duty按2^-30还原，无counts/Gain/Bias或极性翻转。

`axu5ev_foc_frame_top.sv`不改p3算术／PI状态。整体reset连接核心reset，timing_restart只连接时序控制复位，PI_Reset仍是独立数据端口；正常运行timing_restart=0。仿真顶层在10/30ns两拍整体复位、35ns释放，40ns锁存首帧，50ns首有效上升沿；之后每帧完整5000拍。`ce_out`未作结果有效。捕获结果保持可读，状态为`[frame_id,capture_edge,result_valid,hold_violation]`；本配置捕获315、hold违规必须0。新增结果寄存器没有再增加50µs等待。

## 待实现的交换与硬件适配

- 多字段命令先暂存，再用序列号提交；PL在明确的电流帧边界一次采纳，反馈提供同拍快照、帧号与采用的命令序号。具体地址、字节序、40位打包、屏障/cache/MPU及应答逻辑尚未实现。
- 电流核不能等待每次R5计算；未收到新命令时的保持、过期阈值及禁止行为需在总线实现时确定，不能以本轮主机验证认定满足时限。
- ERRI/ERRU的PL/驱动快速禁止独立于R5计算；R5负责恢复管理。F_Reset、PI_Reset、Init_Reset及重新使能仍是分别请求，清故障不自动重启。
- 新板外置ADC选型/通道/量程、光栅接收/电平、MBDL4门极/RELCON/ENCON/故障接线、具体PCB/芯片料号与XDC仍待适配。原100µs控制、50µs应用和1µs死区是保留的算法参考，不是新板端到端实测。

本轮执行的是Windows主机生成C反馈闭环，不是Simulink托管SIL或R5实机。R5目标编译、Vitis域/BSP/启动、AXI/CDC实现、5EV综合/布线、ARM实测、板上时延、烧录/上电均NOT_RUN。
