# AXU5EV 实机电机控制模型白盒说明书

本说明对应 `simulation/experiment/AXU5EV_Motor_Control_System.slx` 及同目录的独立实机算法。以下字段编号采用 Simulink/MATLAB 的 **1 起始**编号，C 数组下标需减一。位置统一用 mm，速度用 mm/s，电角度用 rad，电流用 Apeak，时间用 s。状态字段采用 bool 或以 double 表示的 0/1，具体以各端口定义为准。[实机主模型](../simulation/experiment/AXU5EV_Motor_Control_System.slx)

## 当前离线基线（2026-11-19，PR48 R1）

本文当前算法对照为 PR48 已复审提交 `f31aa8c` 中的主模型及 Cortex-R ERT **1.173**，生成源位于 `generated/experiment/ax04b_r1_01/r5`。SELFTEST 与 REAL 固件候选分别为 `.runtime/experiment/ax04b/selftest_r1_02` 和 `.runtime/experiment/ax04b/real_r1_02`，应用身份均为 **`0x41585203`**。各自复用原 `*_02/hardware` 的未变 bit/ltx/XSA；旧 `*_02/vitis` 与 PR46 的 1.95 C 是历史来源，不是当前R5部署选择。[当前生成头文件](../generated/experiment/ax04b_r1_01/r5/AXU5EV_Motor_Control_System.h) · [模型基线记录](../verification/experiment/ax04b/r1_model_baseline.json) · [当前候选索引](../verification/experiment/ax04b/results.json) · [首运行指南](../firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md)

IRQ/GIC、原子 AXI、许可撤销与显式恢复的代码绑定及成套构建已经离线完成。**ARM 实际执行、IRQ/COMMIT 实测时延、板内 SELFTEST、真实 IO 和功率运动仍为 NOT_RUN**。两种候选均保持外部功率输出硬禁止，REAL 当前用于后续获授权的真实输入及禁止态检查。PR49 独立验证 J16-MBDL4 接口板，实测范围见[首板静态记录](https://github.com/kazecode666/J16-MBDL4-Module/blob/main/docs/writing/interface_board_static_test_record.md)。

AX-04B 部署使用上述 1.173 R5 生成源和独立的 PL 实机源。其新增控制角模型在同帧选择固定对齐角或编码器角加偏置，PL 通过实时 AXI 接口与 R5 交换冻结反馈及下一帧参考。硬件调度和无功率候选见对应的交付文档。[控制角模型](../simulation/experiment/pl/AXU5EV_Experiment_Control_Angle_HDL.slx) · [实时接口](../integration/ps_pl/AX04B_INTERFACE.md) · [交付 B 报告](../coordination/reports/ax04b_hardware_binding.md)

## 1. 入口、执行分工与参数

运行 `simulation/START_EXPERIMENT.m`，打开 `AXU5EV_Motor_Control_System`。实机入口显式加载 experiment 下的源，拒绝已从其他路径加载的同名模型。主模型和 FOC 的参数快照各保存在自己的 Model Workspace 中。日常打开保留已有快照，仅在模型干净、已停止且确有缺项时补缺。需要应用参数源时可显式调用 `axu5ev_experiment('parameters')`，它更新内存，保存由使用者决定。模型检查和生成会对比参数源与 Workspace 快照。纯仿真入口是 `START_SIMULATION.m`，其模型、参数与调试场景独立。[实机入口](../simulation/START_EXPERIMENT.m) · [入口实现](../simulation/experiment/scripts/axu5ev_experiment.m) · [实验参数源](../simulation/experiment/parameters/axu5ev_experiment_parameters.m)

| 执行边界 | 触发方式 | 主要职责 |
|---|---|---|
| `Initialize_Controller` | C 初始化函数内部的 Initialize 事件 | 生成配置初始化内部状态和外部 I/O，模型写入 `Initialized=true` |
| `Motor_Control_ISR` | 外部函数调用 `PL_Frame_IRQ()`，名义 100 µs/帧 | 位置与速度测量、资格与锁存、授权、五态对齐、位置 P、速度 PI、PL 参考和遥测取样 |
| `NonRealtime_Service` | 外部函数调用 `Service_Request()` | 把最近一次 ISR 的遥测快照复制到服务输出，服务计数加一 |
| PL 模型 | 独立 HDL 生成边界 | 电流预处理、编码器相位转换、定点电流环及 duty 到比较值映射 |

`AXU5EV_Motor_Control_System_initialize()` 完成后，既有生成 C 测得参考初值 `[0 0 0 0 0 0 1 0]`，驱动初值 `[0 0 0 1 0]`，即 PWM 禁止、PI 复位、参考无效、REL/EN 关闭、OE 禁止。帧版本、服务计数、连续计数、反馈有效性及历史长度从零开始。软件 `Initialized` 由一次初始化事件建立，反馈与当前限额的物理有效性由后续接口提供。[生成头文件](../generated/experiment/ax04b_r1_01/r5/AXU5EV_Motor_Control_System.h) · [初始化断言](../simulation/tests/experiment/ax04_validate_generated_control.m)

实机参数版本为 `20261117`。R5 外环候选参数为 `Kp_pos=5`、`Kp_ASR=0.03`、`Ki_ASR=0.05`、`Kaw_s=0.4`。位置容差 0.02 mm，位置环和速度给定限幅均为 20 mm/s。速度输出限幅 ±0.3 A，积分状态限幅 ±0.20 A。总运动质量尚未测定，位置和速度增益沿用 AQM 备份候选。48 V 是控制参考常量，遥测中的位置与速度来自编码器，`runtime_frame` 的母线与负载字段分别来自参数 `Udc` 与 `Host_Load_N`。[实验参数源](../simulation/experiment/parameters/axu5ev_experiment_parameters.m)

数值型 0/1 Switch 统一采用严格的 `> 0.5`，因此 `0.5` 和零附近的微小值走假分支。原生 `boolean` 控制线只有真、假两种值，编译后的 Switch 直接按布尔值选择。`CommandFrame` 第 9 项 PI_Reset 仍按 PR46 的非零立即复位协议解释，包含正的非整数和负值。常量和初始化参数在使用点用 Constant 引用，局部标签用于运行时信号。[Switch 控制口规则](https://www.mathworks.com/help/simulink/slref/switch.html)

修改 `axu5ev_experiment_parameters.m` 后，用 `axu5ev_experiment('parameters')` 经检查更新模型工作区，再保存已审查的模型。`Ts_ACR`、`Ts_ASR`、`Ts_POS`、`delay_N` 和反馈时戳参数共同决定 R5 的时序。离线构建候选的周期与 PL 的 50 MHz、5000 拍帧合同成对，改变硬件周期时要同步复核两端。当前 ERT 使用 `Inlined`，模型工作区的数值参数适合重新生成；若以后指定需要在线调参的字段，在同一初始化文件定义初值，并为该字段配套明确的可调存储接口和上位机／调试器写入范围。[初始化入口](../simulation/experiment/scripts/axu5ev_experiment.m) · [R5/PL 接口](../integration/ps_pl/AX04B_INTERFACE.md)

## 2. 主模型根接口与 ISR 执行链

| 根输入 | 类型 | 用法 |
|---|---|---|
| `PL_Frame_IRQ`、`Service_Request` | function-call | 两个独立外部调用入口 |
| `CommandFrame` | double[20] | 版本 1 的控制命令 |
| `raw_count`、`sample_id`、`illegal_count` | uint32 | 原始编码器计数、反馈帧标识、非法跳变累计 |
| `sample_tick` | uint64 | 同帧 50 MHz 时戳，单位 20 ns |
| `encoder_ready`、`current_valid` | boolean | 编码器就绪、电流测量有效 |
| `ERRI_n`、`ERRU_n`、`clear_fault` | boolean | 两路低有效驱动故障、独立软件清错请求 |
| `request_relcon`、`request_encon`、`request_freset`、`request_oe_disable` | boolean | 独立的驱动请求 |

| 根输出 | 类型 | 来源 |
|---|---|---|
| `runtime_frame` | double[41] | 外环、对齐和 Host 诊断 |
| `position_mm`、`speed_mm_s` | double | 计数换算、5 ms 差分速度 |
| `position_valid`、`speed_valid` | boolean | 当次反馈的有效性 |
| `history_count` | uint8 | 当前连续历史已有的位置项数，0～51 |
| `feedback_status` | uint32 | 测量状态位 |
| `continuous_count` | int64 | 展开的长计数，方向与机械零点在位置/速度换算中应用 |
| `reference_commit` | double[8] | PL 参考、使能与复位合同 |
| `commit_sample_id`、`reference_version` | uint32 | 最近一次新帧的标识及参考版本 |
| `drive_outputs` | boolean[5] | RELCON、ENCON、F_Reset、OE_disable、外部故障锁存，依序排列 |
| `telemetry`、`service_count` | double[12]、uint32 | 服务入口发布的最近观测及累计调用次数 |

ISR 的数据依赖链如下。驱动、对齐、外环三路的禁止条件汇合后，才能形成 PL 端可用的 PWM 许可。

```text
编码器快照 → Feedback_Measurement → 帧资格/系统故障锁存
                                      ├→ 驱动输出与外部故障锁存
                                      └→ Control_Fault 与软件对齐许可
命令 + 实测位置/速度 + Control_Fault → Bind_Real_Feedback → Qualified_Runtime
Runtime + 帧状态 + 驱动/行程条件 → Reference_Commit
最新参考 + Runtime + 测量 + Control_Fault → LatestTelemetry → Service_Request
```

帧资格输出 `new_frame`、`healthy`、`fault_latched` 和 `clear_allowed`。其中 `new_frame = Initialized && position_valid && !duplicate`，`healthy` 再要求当前无系统锁存、原始故障或硬限，电流有效、命令字段全有限且当前未请求 F_Reset。带位置的缺帧或故障仍可能是 `new_frame`，此时外环按故障条件计算，参考有效位被健康门控撤销。测量正常重复帧只维持历史，`new_frame=false`，安全路径仍可因许可撤销而进入 Runtime。这里的 `new_frame` 与参考有效位应分别取证。[主模型](../simulation/experiment/AXU5EV_Motor_Control_System.slx) · [已生成 C 对照](../generated/experiment/ax04b_r1_01/r5/AXU5EV_Motor_Control_System.c)

上述为模型内部依赖。R1 的硬件绑定在模型调用前，结合本地 ARM 会话和 PL 的 `ARMED`、`INHIBIT_LATCHED`、`LIVE_INVALID`，形成当次有效命令。提交失败后的同帧安全处理、STOP 待处理及 CLEAR／ARM／新 Start 的确认由绑定层承接；它不把待命未 armed 一律当成反馈无效。[R1 实施及定向记录](../coordination/reports/ax04b_hardware_binding.md#停止与显式恢复) · [实际 IRQ 调度](../firmware/r5/motor_control/ax04b/ax04b_main.c)

## 3. 四个子系统的数据和状态

### 3.1 Feedback_Measurement

`Frame_And_Count_Guard` 保存上一组计数、ID、时戳与非法跳变数，以及连续计数、机械原点、配置和历史填充深度。取当前与上次的模差，正常 100 µs 帧要求 `sample_id` 加 500，50 MHz `sample_tick` 加 5000。ID 与时戳均支持原位宽回绕。相同 ID 和时戳且计数、非法跳变累计一致，判正常重复。只有同帧标识而数据变化，判无效并要求重新同步。计数模差以有符号代表值扩成 int64，恰好半圈的差值视为方向歧义。

完整倍数缺帧需同时满足 ID 增量为 500 的正整数倍、未超过半域且 tick 增量为 ID 增量的 10 倍。该分支连续计数仍累计，但重建速度历史并交由上层锁存缺帧故障。编码器未就绪、非法跳变数变化或时序异常使当前反馈无效，下一次接受时重新建立起点。启动、原点/方向/配置版本/比例变化也会重建历史。ISR 当前接入零计数 0、正向、配置版本 1、1000 nm/count，测量 reset 端接 false。

位置由 `s × (total − origin) × nm_per_count × 10⁻⁶` 得到，反向时 `s=−1`，正向时 `s=+1`。只有 `advance` 才更新位置和启停延迟。`delay_N` 同时决定位置延迟、测速增益 `1/(delay_N*Ts_ACR)` 和历史就绪门槛 `delay_N+1`。默认第 51 个位置样本形成 50 个 100 µs 间隔，速度为 `[x(k) − x(k−50)] / 0.005`。无有效速度时速度输出为 0 并拉低有效位，普通重复帧保持位置与 `history_count`。因此查看速度必须同时查看 `speed_valid`。

| 位（从 0 起） | 掩码 | 意义 |
|---|---:|---|
| 0 | 1 | 启动或重新接入后的首帧 |
| 1 | 2 | 重复帧 |
| 2 | 4 | 可识别的整倍数缺帧 |
| 3 | 8 | 配置变化导致历史重建 |
| 4 | 16 | 编码器或帧反馈无效，包括非法跳变 |
| 5 | 32 | 半圈模差歧义 |
| 6 | 64 | 要求重新同步 |

上层故障资格检查状态位 2、4、5、6，同时检查位置与电流有效性。普通启动、配置历史重建和正常重复有各自的等待行为。[PR46 历史反馈/资格实施证据](../coordination/reports/ax04_experiment_model_and_layout.md#r1r5修改位置) · [PR46 历史反馈回绕记录](../verification/experiment/pr46_review_01/feedback_direction_wrap_result.json)

### 3.2 Controller_Driver_IO_Manager

外部驱动故障为 `!ERRI_n || !ERRU_n`。`External_Fault_Latch` 用 Unit Delay 保存故障，当前硬件故障或未获安全清除的上一拍故障使锁存为真。上层 `Control_Fault` 是系统锁存和外部驱动锁存的 OR。驱动 REL/EN 的门控另取 `system_fault_latch` 与 F_Reset，当前低有效驱动故障也在上层资格中进入系统锁存。

| 逻辑输出 | 当前模型关系 |
|---|---|
| RELCON | `request_relcon && !system_fault_latch && !request_freset` |
| ENCON | `request_encon && !system_fault_latch && !request_freset` |
| F_Reset | `request_freset` 直接传出 |
| OE_disable | 独立禁止请求为真，或系统故障已锁存且当前未请求 F_Reset |
| external_fault_latch | 原始驱动故障有效，或上拍已锁存且未获安全清除。安全清除要求 `clear_allowed && ERRI_n && ERRU_n` |

`clear_allowed` 要求软件已初始化、有有效的非重复位置、软件清错请求为真、反馈健康、外部故障已解除、位置在硬限以内、命令全有限且原命令字段 8 严格等于 0。它传入驱动外部锁存及 Motion_Control 行程锁存。F_Reset 期间 REL/EN 和参考 PWM 均禁止，OE 仍按表中的组合逻辑计算。AX-04B 已实现物理脚映射及快速禁止逻辑，真实电气和响应时间仍待现场确认。[主模型](../simulation/experiment/AXU5EV_Motor_Control_System.slx) · [PR46 历史驱动离线证据](../verification/experiment/pr46_review_01/generated_control_result.json) · [当前绑定报告](../coordination/reports/ax04b_hardware_binding.md)

### 3.3 Bind_Real_Feedback

`Finite_Command` 若见任一非有限命令就输出一组全零命令，同时从原输入单独抽取 `command(9) ~= 0` 的 PI 复位请求。上层资格也对原命令检查有限性并锁存故障。绑定器以此把诊断输入安全地接入真实反馈。下表左列既是根命令槽号，也是绑定后 `runtime_u` 的槽号。

图上所有业务 Mux／Demux 端口均有信号名，保留的向量旁注明宽度。`Move_Request` 对应槽 11，`alignment_commands[3]` 是槽 16–18。被覆盖的八个旧字段各用一条具名标量线终止，包含原 Replay 三个字段。运行时接口 `runtime_u[20]`、`runtime_y[41]`、`drive_outputs[5]` 保持原有字段顺序。

| 槽号 | 输入字段 | 实机绑定 |
|---|---|---|
| 1 | 绝对目标位置 mm | 保留 |
| 2 | 速度给定 mm/s | 保留 |
| 3 | Id 请求 A | 保留 |
| 4–5 | Iq 测试模式、Iq 测试请求 A | 保留 |
| 6–7 | 位置闭环、速度闭环使能 | 保留 |
| 8 | PWM 请求 | 故障时置零 |
| 9 | PI_Reset | 原请求非零、Control_Fault 或速度无效时置 1 |
| 10 | Replay 选择 | 置零 |
| 11 | Move_Request | 保留，点位发送采用值翻转 |
| 12–14 | Replay 的速度、PWM 与 PI_Reset | 全零 |
| 15 | 速度反馈 mm/s 槽 | 接实测速度 |
| 16–18 | Alignment_Enable、Init_Start、Init_Reset | 保留 |
| 19 | 故障槽 | 接 Control_Fault |
| 20 | 位置反馈 mm 槽 | 接实测位置 |

`Qualified_Runtime/Command_Feedback_Fields` 按 `[11 3 1 1 1 1 1 1]` 分组，输出端口 1 是字段 1–11，端口 2 是字段 12–14，端口 3–8 依序对应字段 15–20。上层个别许可用 >0.5，部分命令路径用非零。命令发送端采用 0/1，读诊断时以具体块中的比较为准。[主模型](../simulation/experiment/AXU5EV_Motor_Control_System.slx)

**测速有效位接线复查。** 整理前 ISR 顶层缺少 `Feedback_Measurement.speed_valid → Bind_Real_Feedback.speed_valid`。断线时，生成代码将 `Speed_Not_Qualified` 折叠为 `true`。经确认，仅从既有 `[isr_speed_valid]` 增加一个局部 From 接回端口，原块位置、分区及线段保持原样。主机 MEX 用 61 个反馈帧定向复查。两次末帧均得到 `speed_valid=1` 和 `speed_mm_s=10`。在命令未发 PI 复位的情况下，`runtime_frame(23)` 和 `reference_commit(7)` 均由修复前的 1 变为修复后的 0。修复后重新生成的 C 通过原 317 项主机检查。

### 3.4 Qualified_Runtime 的两条执行路径

外层使能为 `new_frame || safety_process`，后者为 `Initialized && !alignment_permit`。内部 `Host_New_Frame` 和 `Motion_Control` 的使能单独接 `Frame_Advance=new_frame`，无新帧时保持 Host 轨迹、速度/位置调度与积分。对齐图在外层执行，故而重复帧或无效帧上的复位、故障、撤权仍能使进行中的对齐中止。满足保持许可的正常重复帧不会推动对齐状态。

#### 对齐许可与五态图

ISR 的 `Alignment_Permit` 要求初始化已完成、位置与电流有效、速度有效或普通重复帧已积满 51 项历史、无 Control_Fault、PWM 和对齐请求均 >0.5、驱动 REL/EN 开启、OE 未禁止、无 F_Reset、无 Init_Reset（>0.5）且 PI_Reset 为零。许可只由软件可见输入推导。进入 `Alignment_Task/Enabled_Original_MIL/Angle_Init` 后，Start 必须先见低电平再见高电平。一次已消费的高电平持续保持时，故障恢复后仍需释放再启动。

| 状态号 | 状态 | 进入、保持或退出 |
|---:|---|---|
| 0 | IDLE | Id=0、Init_Done=0、固定电角选择关闭。收到已武装的 Start 与有效许可后进入 RAMP_ID |
| 1 | RAMP_ID | 固定电角选择开启，Id 从零按 0.00005 A/拍上升，10000 拍后进入保持 |
| 2 | HOLD_ALIGN | Id=0.5 A，30000 拍后锁存一次机械位置并计算电角偏置 |
| 3 | RAMP_DOWN_ID | 继续选择固定电角，Id 按 0.00025 A/拍下降，2000 拍后进入 DONE |
| 4 | DONE | Id 对齐分支回零，撤固定电角选择，Init_Done=1，沿用一次性偏置 |

状态 1、2、3 中，Init_Reset、故障、许可撤销优先于时间迁移，撤销本次偏置和锁存位置并返回 IDLE，包含释放末拍。DONE 在 Init_Reset 或故障时返回 IDLE，该迁移未给已保存偏置/位置赋零，后续成功 HOLD 会覆盖。偏置公式为 `mod(theta_align_const − 2π × x_align_mm_latch / Tau_e_mm, 2π)`，取 `theta_align_const=0`、`Tau_e_mm=30`。对齐位置的锁存只用于电角度偏置，机械测量原点仍由测量配置给定。正常流程从启动起按 0、10000、40000、42000 的调用偏移迁移，连续 100 µs 新帧下三段名义合计 4.2 s。[PR46 历史五态验证结果](../verification/experiment/pr46_review_01/alignment_control_result.json) · [PR46 历史安全边界结果](../verification/experiment/pr46_review_01/alignment_safety_result.json) · [当前 R1 调度验证](../verification/experiment/ax04b/test_r5_runtime.c)

`Init_Done_Or_Bypass = !Alignment_Enable || Init_Done`。启用对齐时，Runtime 另检查绑定后的复位和故障，形成 Host 所用 `Alignment_Ready`。对齐未就绪且启用时，Host 把位置、速度闭环请求归零并选择零 Iq 测试分支。有效对齐态由 Motion_Control 选用对齐 Id 并强制 Iq=0。对齐相关故障使 Runtime 的 Id 与 Iq 为零，Reference_Commit 继续做独立门控。

#### Host 命令时基与轨迹

`Host_New_Frame/Software_Tick` 只随内部 Frame_Advance 更新，Host 使用 `t = tick × Ts_ACR`。`Host_Core` 把轨迹状态保存在 22 个元素的内部记录，点位函数和 S 曲线函数就地定义。首次调用把目标初始化为当前位置，并记住当前 Move_Request。后续每次请求翻转在新拍消费。Allowed 要求位置及速度闭环均开启、非 Iq 测试、PWM 请求有效、PI_Reset 为零且对齐就绪。

到位条件于每个 100 Hz 位置事件检查，要求 Allowed、理论轨迹完成、未中断且机械位置误差在 0.02 mm 内。连续 5 个位置事件成立后，`in_position` 成立、Busy 清除，此时满足其他许可才可发布 Ready。发生模式切换时按当拍 Ready/Allowed 决定是否接受翻转。Busy=0 可能仍在等待到位或许可。运动中 PWM 请求撤销或 PI_Reset 非零会终止当前段，保持前一位置给定，并锁存 `move_interrupted`。启用对齐且再次出现对齐 Ready 的上升状态会重建位置起点。

| `command_status` | 含义 |
|---:|---|
| 0 | 初始状态 |
| 1 | AutoStart 接收，当前参数 `Host_AutoStart_EN=0` |
| 2 | 接收新目标，记录段号、目标、段起点和时间 |
| 3 | 未 Ready 拒绝，当次翻转已消费 |
| 4 | 请求位非 0/1 或字段非法，被 Host 拒绝。原帧的非有限值同时受上层资格和绑定器处理 |
| 5 | 请求与当前已接收目标相同，无新段 |
| 6 | 许可条件不成立，拒绝 |
| 7 | 运动中 PWM 撤销或 PI_Reset 引起中断 |

新段从上一个已接受目标起步，使用静止到静止的绝对点位规划。对位移幅值 `D`，设 `C=10/√3`，峰值速度为 `V=min(Vmax, D/minRamp, √(D·Amax/1.875), (D²·Jmax/C)^(1/3))`。坡道时间为 `Ta=max(minRamp, 1.875·V/Amax, √(C·V/Jmax))`，匀速时间 `Tc=max(0,D/V−Ta)`。速度上升段使用归一化五次多项式 `10s³−15s⁴+6s⁵`，末段镜像减速，在 `2Ta+Tc` 后固定在目标位置。零位移立即完成。参数为 Vmax=20 mm/s、Amax=200 mm/s²、Jmax=1000 mm/s³、最短速度坡道 0.2 s。当前 Host 采用手动发送，时间观测字段属于软件帧时基。

#### Motion_Control 分频、串级控制与行程

1. `Scheduler_10k_1k_100` 从 `Ts_ASR/Ts_ACR` 得到速度分频，从 `Ts_POS/Ts_ASR` 得到位置分频。默认每 10 次 Frame_Advance 发布速度事件，每 10 次速度事件发布位置事件。从首个 100 µs 调用按 0 编号，首个速度/位置事件分别在偏移 9、99。两个外环均为触发子系统，间隔期间保持上次输出。
2. `Position_Loop` 用给定减实测，经过 ±0.02 mm Dead Zone，乘 `Kp_pos=5` 后限幅至 ±20 mm/s。位置速度前馈口在上级接零，位置复位口终止于 Terminator，位置环实现为 P。
3. `Reference_Manager` 在位置环输出和手动速度给定间选择。内部速度斜率限制每次 Motion_Control 调用步进不超过 ±0.01 mm/s，速度再限幅到 ±20 mm/s，速度环关闭或对齐未完成时输出门控为零。Id 一般沿用 Id 命令，Iq 从 ASR 或直接 Iq 测试选取，随后叠加对齐和故障选择。
4. `Travel_Safety_Manager` 位于最终速度参考与 Speed_Loop 之间。机械位置 ≥+110 mm 时正速度给定置零，≤−110 mm 时负速度给定置零，向内给定继续通过。直接 Iq 测试绕过这条软限速度路径。机械位置 ≥+120 mm 或 ≤−120 mm 触发行程锁存并把速度给定置零，同时上层资格在同一极限锁存软件故障。上层 `clear_allowed` 单独清除行程状态。参考封装检查行程锁存，未清除时拒发有效参考并禁止 PWM。
5. `Speed_Loop` 计算 `e_v = v_safe − v_actual`。当前速度环输出为 `sat(0.03 × e_v + x_s, ±0.3 A)`。摩擦补偿子系统在图中标为注释禁用。令 `ΔIq = Iq_unsat − Iq_sat`，积分更新为 `sat(x_s + 0.00005 × e_v − 0.4 × ΔIq_prev, ±0.20 A)`，饱和差通过一拍延迟反馈。硬复位由对齐态、有效 PI_Reset、Iq 测试或速度闭环关闭触发，速度 PI 的输出和积分归零。超速分支在 `abs(v_safe)>0.5` 且 `sign(v_safe)×e_v<−3` 时额外清积分。零速积分比较是 `abs(v_safe)<v_ref_zero_eps`，当前阈值为 0，比较恒假。

Runtime 对速度 PI 的有效复位组合使用绑定后的 PI_Reset、无 PWM 请求和开启对齐时的故障。上述内部复位作用在各自子系统事件上。参考封装直接由本次资格撤销 PWM，故障停发不等待 1 kHz PI 触发。[实验参数源](../simulation/experiment/parameters/axu5ev_experiment_parameters.m) · [PR46 历史行程离线验证](../verification/experiment/pr46_review_01/travel_control_result.json) · [当前生成算法对照](../generated/experiment/ax04b_r1_01/r5/AXU5EV_Motor_Control_System.c)

#### Runtime 的 41 字段输出

运行输出由 37 路 Mux 输入拼成 41 个 double。最后一路为五元素轨迹参数。

| 字段 | 顺序与含义 |
|---|---|
| 1–3 | 选定 Id、选定 Iq、行程门控后速度参考 |
| 4–9 | Init_Done、Init_State_Num、对齐 Id、固定角使能、自动偏置、对齐位置锁存 |
| 10–12 | Alignment_Ready、Init_Done_Or_Bypass、Alignment_Fault_Active |
| 13–15 | 位置轨迹给定、母线控制参考、Host 负载参数 |
| 16–23 | 速度闭环使能、位置闭环使能、Host PWM 请求、Host 速度命令、Host Id 命令、Iq 测试模式、Iq 测试给定、Host 侧 PI_Reset（已过输入绑定） |
| 24–30 | 已接受目标、Busy、In Position、命令状态、段起点位置、段起始时间、轨迹完成 |
| 31–36 | Ready、接受计数、拒绝计数、段号、命令接收时间、中断标志 |
| 37–41 | `Host_Traj_Vmax`、`Host_Traj_Amax`、`Host_Traj_Jmax`、`Host_Speed_Ramp_s`、`Ts_ACR` |

## 4. 参考、遥测和复位合同

`Reference_Commit` 在新帧时递增 uint32 版本（最大值下一次为 0），并保存本次 `sample_id`。版本计数随 `new_frame` 更新，最终发布有效性由另一组条件决定。没有新帧时版本和 `commit_sample_id` 保持，当前输出仍会重新计算。根输出是模型数据合同；实际原子提交、接受回执及下一 P0 采用由 AX-04B 绑定层实现，不能把模型封装完成等同于 PL 已采用。[实时接口](../integration/ps_pl/AX04B_INTERFACE.md)

| 参考槽 | 含义和条件 |
|---|---|
| 1、2 | Runtime 的 Id、Iq 限幅至 ±0.50 A、±0.30 A，参考无效时归零 |
| 3 | `speed_mm_s × 2π / Tau_e_mm`，速度无效或结果非有限时归零 |
| 4、5 | Runtime 自动角度偏置和固定角使能，Runtime 有任一非有限字段时归零 |
| 6 | PWM permit 要求参考有效、Host PWM 非零、REL/EN 均为真，并且 OE 禁止、F_Reset、Init_Reset 均为假 |
| 7 | PI reset，Host PI_Reset 非零、PWM 禁止或参考无效三者任一成立 |
| 8 | ReferenceValid，新帧、健康、速度有效、外部故障未锁存、行程未锁存、Runtime 全有限同时成立 |

`Capture_Latest_Observation` 每次 ISR 写入 `LatestTelemetry`。服务导出的 12 字段依序为当前读入的 `sample_id`、参考版本、机械位置、实测速度、对齐状态号、Id 参考、Iq 参考、电角速度、自动偏置、PWM 许可、参考有效、Control_Fault。服务入口读取最近记录并递增 uint32 服务计数，计数在最大值后回绕。该入口是轻量复制机制；当前 C 绑定在有界中断屏蔽区内调用服务并复制快照，随后在前台打印或导出，真实抢占时延仍待 ARM 实测，不能视为完整长程记录系统。[主模型](../simulation/experiment/AXU5EV_Motor_Control_System.slx) · [生成接口](../generated/experiment/ax04b_r1_01/r5/AXU5EV_Motor_Control_System.h) · [服务绑定](../firmware/r5/motor_control/ax04b/ax04b_main.c)

| 操作或条件 | 作用边界 |
|---|---|
| 全局初始化 | 初始化模型状态、内部锁存和接口初值，建立软件 `Initialized` |
| PI_Reset | 进入对齐许可和控制器复位逻辑，在参考合同传递到 PL PI。建立故障后仍须独立清错 |
| Init_Reset | 对齐状态回退，当前参考 PWM 禁止。DONE 与进行态的偏置处理按状态迁移分别执行 |
| F_Reset | 独立驱动复位请求，抑制 REL/EN 和参考 PWM，撤销对齐许可 |
| clear_fault | 通过健康非重复帧、原始 PWM 请求为 0 等资格后，允许清系统、驱动和行程锁存 |
| measurement reset | 清测量内部状态及位置历史，当前主模型将它接 false |

## 5. 源码追踪、生成与离线复查

R5 的活动实现是主模型三处已经固化的普通子系统 `Feedback_Measurement`、`Controller_Driver_IO_Manager`、`Motion_Control/Travel_Safety_Manager`，以及使用位置上的 Stateflow 和 MATLAB Function。R5 检查/生成通过 `axu5ev_experiment_check_r5_source` 检查项目库链接、Model Reference 和外部逐拍 helper。历史库与 oracles 由测试显式选用。生成使用 `axu5ev_experiment('generate_r5')`。它在临时配置中使用 ERT、C、Cortex-R、小端、非复用函数接口及 Code Only，从新目录导出 C/H，并通过 BuildInfo 中实际 C 文件和薄 transport 编译主机 MEX。[来源校验](../simulation/experiment/scripts/axu5ev_experiment_check_r5_source.m) · [生成入口](../simulation/experiment/scripts/axu5ev_experiment_generate_control.m) · [历史 R5 来源](../simulation/experiment/r5/README.md)

定位时可先看根输出和两类有效性，再沿局部 From/Goto 标签回读来源。速度一直为 0 时，同时查看 `speed_valid`、`history_count`、`feedback_status`。PWM 请求有而许可无时，沿根 `reference_commit` 第 8、6、7 项检查帧健康、行程、驱动四个输出及软件复位。点位未接受时同时查看 `move_ready`、`move_busy`、`command_status` 和 `move_interrupted`。调试对齐需一同查看状态号、许可、固定角使能、对齐 Id 和偏置字段。

当前 PR48 模型及生成 C 为 **1.173**。提交的记录包括 317 项、275136 次主机 IRQ 调用、Switch 与 PI_Reset 阈值检查，以及链接同一份生成 C 的 12 个真实调度代码主机场景。三个旧许可反例单列为预期失败行为，不算修复 PASS。两种新 ELF 的目标编译、源选择和离线启动匹配检查已记录完成；这些检查没有运行真实 ARM 或电机。[当前模型基线](../verification/experiment/ax04b/r1_model_baseline.json) · [R1 调度测试](../verification/experiment/ax04b/test_r5_runtime.c) · [当前结果索引](../verification/experiment/ax04b/results.json) · [R1 报告](../coordination/reports/ax04b_hardware_binding.md#pr48-复审基线)

PR46 的 1.95 生成结果和当时的 `HW_BINDING_PENDING` 仅作为历史交付 A 证据保留，不能用于描述当前绑定状态，也不能替代当前 1.173 的源选择。当前为**代码绑定与构建离线完成、板上运行未测**；`BOARD_SELFTEST`、`REAL_IO`、`ARM_EXECUTION`、IRQ/COMMIT 时延和功率运动继续为 `NOT_RUN`。[PR46 历史最终结果](../verification/experiment/pr46_review_01/results.json) · [PR46 历史实施记录](../coordination/reports/ax04_experiment_model_and_layout.md)

## 6. PL 数值链与 HDL 生成边界

实机方案把位置 P、速度 PI、对齐、行程和参考封装放在 R5，把电流闭环留在 PL。实机主模型提供 PL 反馈入口与参考输出，PL 电流、角度、FOC、比较值四个边界独立生成，AX-04B 另接入可见的控制角选择模型。下面是对接时的数据走向，箭头经过的采样锁存、PS/PL 交换和 PWM 采用边界属于板级集成。

```text
双路 ADC 原始码 ──> Current_Preprocess ──> ia / ib / ic、valid、标定状态
ABZ 解码计数 ─────> Encoder_Angle ──────> 快电角度、valid、配置版本
           └──────> 反馈快照 ──> R5 位置/测速、外环与对齐 ──> 参考组
同帧电流 + 所选电角度 + 已采用参考组 + Vdc
           └──────> FOC_DUT ──> U/V/W Q30 ──> Duty_To_Compare ──> 三相比较值
```

| HDL 边界 | 模型与可编辑算法 | 主要输入 | 主要输出 |
|---|---|---|---|
| `AX04_Current_Current_Preprocess` | [电流生成壳](../simulation/experiment/pl/AXU5EV_Experiment_Current_HDL.slx)链接[双路标定与电流预处理库](../simulation/experiment/pl/AXU5EV_Experiment_PL_Algorithms.slx) | 采样事件、A/B 原始码、各路捕获有效与 OTR、标定/配置请求、Q16 偏置种子、Q24 增益和版本 | 三相 `int32` Q24 电流，各路 Q16 偏置、样本数和完成位，标定版本、有效、限幅、错误码和结果事件 |
| `AX04_Angle_Encoder_Angle` | [角度生成壳](../simulation/experiment/pl/AXU5EV_Experiment_Angle_HDL.slx)链接[编码器数值库](../simulation/experiment/pl/AXU5EV_Experiment_Encoder_Components.slx) | 采样事件、`uint32` 已解码计数、就绪、零点计数、相位偏移计数、方向和配置版本 | `int64` Q32 电角度、`uint16` 相位、有效、结果事件和版本 |
| `AX04_FOC_FOC_DUT` | [独立实机定点 FOC](../simulation/experiment/pl/AXU5EV_Experiment_FOC.slx) | 三相电流及两轴参考为有符号 32 位 Q24，电角度为有符号 40 位 Q32，电角速度为有符号 40 位 Q24，`Vdc` 为无符号 32 位 Q24，另有 `PI_Reset_EN` | 三相 duty 为无符号 32 位 Q30 |
| `AX04_Duty_Duty_To_Compare` | [比较值模型](../simulation/experiment/pl/AXU5EV_Experiment_Duty_HDL.slx)调用[映射函数](../simulation/experiment/pl/axu5ev_experiment_duty_to_compare.m) | 同组 U/V/W Q30 与采样事件 | 同拍寄存的三个 `uint16` 比较值及结果事件 |

### 双路电流标定与重构

`Current_Preprocess/Current_Processing` 先做帧资格和配置选择，再由 `Calibration_A/B` 各自维护累加和、样本计数、偏置和完成位。每路有效条件为捕获有效、OTR 为假、原始码不超过 4095。活动采样还要求这一拍没有 `config_apply` 或 `cal_restart`。合法配置要求两路种子均在 `[0,4095] counts` 的 Q16 范围内，且 `cal_log2_N ≤ 10`。有效应用装入增益、窗口、偏置种子和手工完成位，标定版本取请求版本。重新标定清累计与完成位，并递增版本。自动标定需要配置已建立且使能，各路分别收满 `2^cal_log2_N` 个合格样本。完成时以累加和左移 `16−cal_log2_N` 得到 Q16 均值，并按完成路数递增版本。

电流换算使用前一拍两路标定均完成、两路数据都合格且配置有效的采样。每路以 `(raw×2^16−offset_q16)×gain_q24` 做宽位乘法，右移 16 位时按最接近值、恰好一半取偶数舍入。用尚未饱和的舍入结果计算 `ic=−(ia+ib)`，随后三路分别限幅到 `int32`。不具备换算资格时电流输出为零。具备资格但任一路饱和时保留饱和值，置 `clip` 并撤销 `valid`。数据、诊断、版本与采样事件在输出边界共同寄存一拍。应联合检查 `result_strobe` 和 `valid`。

| `error` 掩码 | 含义 |
|---|---|
| `0x001 / 0x002` | A/B 捕获无效或码值超过 4095 |
| `0x004 / 0x008` | A/B OTR |
| `0x010 / 0x020` | A/B 在本帧进入时尚未完成标定 |
| `0x040` | 配置尚未建立，或本次 `config_apply` 的配置不合格 |
| `0x080` | 合格换算在三相 `int32` 限幅中发生裁剪 |
| `0x100` | 采样与应用配置或重启标定同拍 |

这些标志可以组合。诊断优先级为应用配置、重启标定、普通采样。数值与状态可与生成模块的对应端口及图内 `Frame_Qualification`、`Frame_Diagnostics` 逐项核对。 [电流生成模块](../generated/experiment/ax04_01/pl/AXU5EV_Experiment_Current_HDL/AX04_Current_Current_Preprocess.sv)

### 快电角度

`Encoder_Angle/Electric_Angle_Core` 使用每电周期 30,000 个已解码计数。空闲时锁存事件和配置，首帧或零点改变时从零点计数建立基准，连续帧使用相邻 `uint32` 原始计数的模 2³² 有符号差分。方向改变时翻转保留的无偏移相位坐标及新差分。恰好半范围的差分、未就绪或 `phase_offset_count ≥ 30000` 会给出无效结果，并使后续采样重新建立基准。串行状态机逐位求余 32 拍，再由收尾状态合成环内相位并叠加配置偏移，忙期间的 `sample_strobe` 不会另开任务。

相位缩放在图中可见。对 `phase_count ∈ [0,29999]` 计算 `theta_q32 = (phase_count×943231700270 + 524288) >> 20`，对应将 2π/30000 rad/count 的 Q52 系数换成 Q32 弧度码。角度、相位、有效、结果事件和本次配置版本经同一输出寄存边界。此处的 `phase_offset_count` 属于 PL 角度端口配置，R5 参考中的 `Theta_Offset_auto` 属于弧度字段。AX-04B 将源编码器相位偏置固定为零，另由已生成的 `Control_Angle` 按已采用参考选择固定角或叠加一次归一化弧度偏置；固定角期间电角速度为零。 [串行状态机](../simulation/experiment/pl/axu5ev_experiment_encoder_phase_serial.m) · [角度生成模块](../generated/experiment/ax04_01/pl/AXU5EV_Experiment_Angle_HDL/AX04_Angle_Encoder_Angle.sv) · [控制角生成模块](../generated/experiment/ax04b_01/pl/AXU5EV_Experiment_Control_Angle_HDL/AX04B_Angle_Control_Angle.sv)

### 定点电流环与 SVPWM

1. `Clark` 从三相峰值电流构造 `iα=(2/3)(ia−ib/2−ic/2)`、`iβ=(ib−ic)/√3`。Park 变换用 `theta_e` 得到 d/q 电流。各轴跟踪误差是参考减测量。
2. `Id` 和 `Iq` 用上一控制拍积分状态和本拍比例误差给出 PI 电压，再叠加 `−ωe Lq iq` 和 `+ωe(Ld id+ψf)` 解耦电压。积分更新为 `x[k+1]=x[k]+KiTs·e[k]−Kaw·Δu[k−1]`，其中 `Δu=u_raw−u_lim`。`PI_Reset_EN` 使本拍原始电压及下一拍积分为零，电压差反馈仍由限幅器 Unit Delay 维护。
3. `dq_voltage_limiter` 用公共比例 `s=min(1,(0.9·Vdc/√3)/(√(ud_raw²+uq_raw²)+ε))` 同时缩放两轴，`ε=10⁻⁶`，并将两轴电压差延迟一控制拍回送。逆 Park 把限幅后的电压转换到 α/β。
4. `SVPWMG` 由 α/β 的符号组合判定扇区，`XYZ Calculate` 用 `Ts_ACR/Vdc` 缩放电压中间量，`T1T2 Calculate` 按扇区选择两段矢量时间，和超过一个周期时按比例压缩。三路候选边沿用 `(Ts−T1−T2)/4`、`(Ts+T1−T2)/4`、`(Ts+T1+T2)/4` 计算，再按扇区排列为 U/V/W，经过 `1−2t/Ts` 及 Q30 转换输出。

FOC 的工作量和系数为有符号 64 位 Q40，定点配置使用收敛舍入与饱和。上述公式以实数表达信号依赖，逐位复算以模型类型、截断位置及生成 SV 为准。工程验证包络可在 `FOC_Fixed_Config.Ranges` 查看，其中相电流和参考各 2 A、`|theta|≤8π rad`、`|ωe|≤100 rad/s`、Vdc 12–60 V 属于定点工程验证假设。 [定点配置](../simulation/experiment/pl/axu5ev_experiment_foc_fixed_config.m) · [FOC 生成模块](../generated/experiment/ax04_01/pl/AXU5EV_Experiment_FOC/AX04_FOC_FOC_DUT.sv) · [系数与动态前馈证据](../verification/experiment/pl_coefficient_bindings.json)

### 比较值、时钟与周期

比较值映射将 Q30 码饱和到 `2^30`，以 `floor((min(d,2^30)×5000+2^29)/2^30)` 得到闭区间 `[0,5000]` 的比较值，半 LSB 向上舍入。三路与事件共同寄存一拍。PWM 载波、整组三相采用、门极互补/死区和禁能属于外层。 [比较值生成模块](../generated/experiment/ax04_01/pl/AXU5EV_Experiment_Duty_HDL/AX04_Duty_Duty_To_Compare.sv)

四个生成边界使用 `clk`、`clk_enable`、高有效同步 `reset` 和 `ce_out`。电流、角度、比较值的 `ce_out` 是时钟使能，结果事件由各自的 `result_strobe` 指出。FOC 增加 `reset_FOC_DUT_tc` 作为时序控制器的复位输入。设计以 50 MHz、5000 个使能拍对应 100 µs 控制周期，`ce_out` 随主使能，三相结果相位由生成元数据和 RTL 检查确定为 314 拍。封装需要保持完整的使能和帧相位关系，并在对应拍捆绑结果身份。314 拍在理想 50 MHz 时钟下是 6.28 µs 的生成核调度量，系统从采样到 PWM 谷值采用的延迟取决于外层时序。 [FOC 时序控制器](../generated/experiment/ax04_01/pl/AXU5EV_Experiment_FOC/AX04_FOC_FOC_DUT_tc.sv) · [生成相位记录](../generated/experiment/ax04_01/pl/AXU5EV_Experiment_FOC/hdlcodegenstatus.json) · [p3 块级设置](../simulation/experiment/pl/axu5ev_experiment_foc_pipeline.json)

### 实机参数与生成来源

主模型和独立 FOC 从各自保存的 Model Workspace 取参数。`START_EXPERIMENT.m` 通过用途专属路径打开模型，补齐缺失变量并保留已存在值。`axu5ev_experiment('parameters')` 可在模型停止且干净时显式刷新参数内存快照，审阅后由调用方保存。PL 的部分标度是 HDL 边界常量，生成器同时核对 FOC 保存的配置、PI 参数、30,000 counts/周期、1000 nm/count 和 100 µs 周期。修改某项标度时应沿对应信号链复核其实现位置。 [实机入口](../simulation/START_EXPERIMENT.m) · [参数与来源](../simulation/experiment/parameters/axu5ev_experiment_parameters.m) · [实机入口实现](../simulation/experiment/scripts/axu5ev_experiment.m)

| 参数组 | 当前值与来源 |
|---|---|
| AQM30-B2 Parallel | 每相 Rs = 1.45 Ω，Ld = Lq = 11.8 mH，取线间 R/L 的一半并采用等电感假设 |
| 位置与磁链 | 电周期 30 mm，光栅 0.001 mm/count，推力常数 30.4/√2 N/Apeak，由推力关系推得 ψf ≈ 0.068424 Wb |
| 电流 PI | ξ = 1/√2，Kp = Lq/(4ξ²Ts) = 59，连续 Ki = Kp·Rs/Lq = 7250，每拍 Ki·Ts = 0.725，两轴 Kaw ≈ 0.0122881 |
| 供电与调试参考 | 固定控制参考 48 V，R5 调试限值 Id ±0.50 A、Iq ±0.30 A；不是物理母线实测值 |
| ADC 标定默认值 | 双路手工有效均为 false，`cal_log2_N=10` 对应每路 1024 个合格样本，增益与偏置经 PL 显式配置端口输入 |

`axu5ev_experiment('generate_pl', <新运行目录>, <新版输出目录>)` 读取已保存的四个边界，执行 `checkhdl` 和 `makehdl`，以 `AX04_Current_`、`AX04_Angle_`、`AX04_Duty_`、`AX04_FOC_` 标记输出。R5 可独立用 `generate_r5`，两者共同生成用 `generate`。新版本导出到 `generated/experiment/<版本>`，工作缓存与生成日志归入 `.runtime/experiment/<新目录>`。纯仿真由 `START_SIMULATION.m` 进入，其闭环和参数归 `simulation/closed_loop`。 [PL 生成器](../simulation/experiment/scripts/axu5ev_experiment_generate_pl.m) · [当前 SV 源索引](../verification/experiment/generated_sources.list) · [纯仿真入口](../simulation/START_SIMULATION.m)

### PS/PL 已实现的离线绑定与待实测边界

- **反馈发布与 IRQ。** AX-04B 在选中帧的电流资格寄存事件后，连同 P0 编码器元数据冻结最小反馈并置高电平 IRQ；当前 RTL 记录为 P76 发布。R5 通过精确序号 ACK，检查同帧身份。GIC 注册、原子读、超时及丢帧处理已有代码和离线证据，目标处理器响应时间仍待实测。
- **参考提交与采用。** R5 模型给出 8 个 double 字段、`commit_sample_id` 和 `reference_version`；传输层有独立版本和目标下一 P0 样本号，完成定点转换、整组提交与接受回执读取。实际采用身份另行读回。R1 将真实许可撤销反馈给模型；模型封装、总线接受与 PL 采用是三个不同阶段。
- **PWM 与驱动。** 低有效故障、快速禁止、整组三相采用和 J16 引脚约束已接入离线工程。当前 SELFTEST 外部输出硬禁止；REAL 六 PWM、缓冲使能及 RELCON/ENCON 也硬禁止，仅保留真实输入与禁止态验收用途。外部电平、响应时间、正常 PWM 波形/死区及物理标定仍需单独验证，不能用本离线基线代替。
- **服务快照。** `Service_Request()` 在模型层复制最近遥测并计数。当前绑定在有界屏蔽区完成快照复制，打印与 CSV 在前台执行；实际抢占窗口和 IRQ 时限必须在目标板测量。

以上对应[AX-04B 实时接口](../integration/ps_pl/AX04B_INTERFACE.md)、[当前绑定报告](../coordination/reports/ax04b_hardware_binding.md)和[首运行指南](../firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md)。两种当前候选的 bit/ltx/XSA、ELF、BSP 及启动检查已有离线交付记录；PL 路由、STA、CDC 复用同一未变硬件的 B4 结果，R1 没有重新实现。ARM 执行、真实 IO、时限实测、功率运动与动态 SDF 不因文档更新或合并而变成 PASS。

**历史交付 A 记录：** 当时生成 51 份 SV（50 模块、1 包），独立 FOC 模型检查 1188 帧，连续 RTL 192 帧以及动态前馈 RTL 48 帧共 720 项 duty 逐字检查零差；辅助 gm FOC 输出延时插入有警告，gm 等价验证为 `NOT_RUN`。当时的 `HW_BINDING_PENDING` 及未构建状态是交付 A 的历史边界，后续绑定与构建以 AX-04B/R1 记录为准。PR41 证据也只归属当时的候选；物理标定及总运动质量仍待落实。[AX-04 历史交付 A 验证](../verification/experiment/model_layout/results.json) · [历史实施与交接](../coordination/reports/ax04_experiment_model_and_layout.md) · [PR41 历史集成链记录](../coordination/reports/motor_control_chain.md)

## 7. 2026-11-18 布局整理与复查（历史记录）

四个入口及其内部的 16 张 Simulink 图按功能划为 42 个区域。新增 41 个 Goto 和 55 个对应的 From，Goto 全部采用 `local`，从各自区域即可读到标签。Inport/Outport 采用 30×14 像素的标准胶囊外观。五态图通过外层接口查看，MATLAB Function 的算法在各函数块中查看。视觉核对涵盖所有整理图。复查也检查了分区与块边框重叠、直角走线和线段穿越块内部的情况。

以整理前磁盘快照比较，16 张图的 432 条逻辑连接按端口消解 From/Goto 后一致。核对同时覆盖信号名、算法参数、Stateflow 内容、Model Workspace 和 ISR 顶层几何。以 SLX 中保存的显式折线段计，`Qualified_Runtime` 最长的一段从 4199 像素缩短到 300 像素，块体和分区重叠归零。工程检查在磁盘重开后通过，检查覆盖 944 个块。整理前与整理后都出现 `runtime_y` 的既有信号对象初值警告 `Simulink:blocks:WarnSigObjWithICIgnoredDefaultIC`。检查中诊断曾指向 `Init_Done` 或 `Angle_Init_EN`，该端口采用默认初值 0。

使用现有 ERT 生成入口隔离输出了 15 份 C/H。实际生成的 5 个 C 源文件由主机 MEX 执行，317 项验证通过，共 275136 次 IRQ 调用，含对齐、安全、行程、反馈和非实时服务用例。另做了第 3.3 节的测速有效后 PI 复位观察。该次布局验证等级为静态检查、Simulink 编译和主机生成代码复查；当前版本与硬件绑定状态见本文开头及第 5、6 节。该次图像和运行结果保存在 `.runtime/experiment/ax04_isr_layout_01`。[R5 生成入口](../simulation/experiment/scripts/axu5ev_experiment_generate_control.m) · [现有主机检查](../simulation/tests/experiment/ax04_validate_generated_control.m)
