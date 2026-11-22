# AX-05A 实机在线接口

[Issue #52](https://github.com/kazecode666/AXU5EV/issues/52) 在 AX-04B 帧合同上提供前台 C API。Cortex-R 仍调用模型 1.173 的 `PL_Frame_IRQ`，向下一 P0 提交一个完整参考包。观测/导出在前台拉取，P76 中断由原程序独占 ACK 和提交。SELFTEST 允许内部合成数据试验，REAL 保持物理功率硬禁止与固件 ARM 拒绝。

## 业务观测和有效性

`ax05a_read_sample` 返回 schema 1 的 `Ax05aSample`。它通过一次独立 PL 诊断 BEGIN 读取必要字段，读完 word 79 释放。读取在 IRQ 运行状态下进行。第一个 AX-04B P0 采用出现前返回无数据。PL 快照与 R5 最近四个有效调度记录通过 uint32 `sample_id` 和 uint64 `tick` 两项匹配。匹配不到时清除 PS 组有效位。组位 `PS=1, ADC=2, FOC_REF=4, DQ=8`。PS 组还提供独立的位置与速度有效位。名义时基 50 MHz，选中样本间隔 5000 ticks，sample_id 每次加 500，字段可按原位宽回绕。

| 字段与旧 F28335 名称 | 来源、单位和采样边界 |
| --- | --- |
| `ia_a/ib_a/ic_a` 对应 `obs_ia/ib/ic` | 同帧 ADC 预处理，诊断 words 8–10，signed Q24 Apeak。完整配对、A/B 校准、无 OTR/clip 并且电流有效才置 `current_valid`。c 相沿用模型重构。 |
| `id_a/iq_a`、`ud_v/uq_v` | FOC 的 Park 输出和电压限幅器到逆 Park 的输出。Simulink FOC 原计算为 signed Q40，观测端缩至 signed Q20，越界饱和。dq 电压为控制器计算值。PWM 谷值后冻结到 words 73–76，word 77 为扩展标识 `0x41583501`。DQ 还要求同帧 FOC 捕获有效且保持无违例。 |
| `id_ref_a/iq_ref_a` | FOC 在 P127 冻结的实际输入，words 49–50，signed Q24 Apeak。伴随实际参考传输版本 word 45。 |
| `position_mm/speed_mm_s`、`position_ref_mm/speed_ref_mm_s` | R5 位置、速度和 Runtime 的位置轨迹／行程门控后速度给定，单位 mm、mm/s。另读已生成的 `obs_v_ref_pos` 位置环速度给定，按位置模式解释。 |
| `encoder_angle_rad/electrical_angle_rad` | words 32–33 为 signed Q32 编码器电角，使用 encoder_angle_valid。words 51–52 为 FOC 冻结控制角，使用 FOC_REF。 |
| `offset_a_counts/offset_b_counts` | words 11–12 为 ADC signed Q16 码值。两路完成位及校准版本单列。实际模拟零电流及标定仍待验证。 |
| `mode/alignment_state/alignment_done/fault/stop_reason` | R5 运行模式、原五态、IRQ 故障状态及停机原因。模式切换后返回本次模型消费的命令版本。 |

PS 的 `commit_*` 是当前 P76 为**下一 P0** 提交的参考。只有精确版本与目标均匹配时 `commit_accepted` 才有效。当前帧 P0 的采用是另一个 `p0_version/target`，以 `p0_valid` 为准。PWM 实际比较值采用另一个确认序号。记录同时保存这些身份，供主机明确选择要对比的事件。移植规格见 [AX-04B 帧合同](AX04B_INTERFACE.md)。

REAL 禁止态可读 ADC、编码器与资格信息。由于固件拒绝 REAL ARM，当前禁止态没有有效 FOC 捕获时，FOC_REF／DQ 组保持无效。SELFTEST 可在内部许可后验证 dq 观测。

## 命令、确认和回读

`ax05a_submit(Ax05aRequest)` 由单一前台所有者调用。schema 1 的 uint32 请求号使用模数前进顺序，重放拒绝。STOP 在 schema 匹配时始终可立即撤销许可。先 STOP → SELECT → 读回选中版本 → CONFIRM → CLEAR 且确认 → ARM 且确认 → 显式 START。ALIGNMENT 选择使用 ALIGN_START。内部 ARM 只确认 PL 状态，START 之前固件维持零参考、PWM 禁止和 PI reset。停机、失去许可会作废确认，后续需要再次确认和显式 START。

| 旧变量或操作 | AX-05A |
| --- | --- |
| `x_ref_mm/v_ref_set/Id_Ref_Set/Iq_Test_Ref` | SELECT/SETPOINT 传整组 double。限位 ±110 mm、±20 mm/s、±0.50 A Id、±0.30 A Iq。限值与实机参数、模型内部最终参考保护对应。非有限、越界或与所选模式无关的非零字段拒绝。 |
| `Iq_Test_Mode/Close_Loop_EN/Pos_Loop_EN` | CURRENT、SPEED、POSITION 三个互斥模式。模式选择和相位修改必须停机。开始位置模式后，另发 SETPOINT 触发既有 Host Move 翻转。需要上一帧 Ready，实际接受/拒绝仍由原 Host 决定，以 `host_receipt_revision/status` 为准。 |
| `Init_Start/Init_Reset/Align_EN` | ALIGN_START 走原五态自动对齐，ALIGN_RESET 独立且限停机。旧手动 `Align_EN` 的固定零电角由原五态在需要的状态内部选择，本接口无单独强制零角操作。 |
| `PI_Reset_EN/OffsetCal_EN/Theta_Offset_Fine` | 一帧 PI_RESET、停机 CALIBRATE、停机 FINE_PHASE（±π rad）。微调经再次 CONFIRM 后随下一次显式启动生效，加在自动偏置进入既有 PL 角度选择器之前，固定角期间由生成模型选择固定角。REAL 校准使用既有人工输入的实测 Q24 增益。 |
| `ENCON_Manual/FReset_Manual/GPIO48_J4_EN_Manal` | 驱动许可由原状态机整组处理，保留 REAL 硬禁止。SELFTEST 的 DRIVER_RESET 与 CLEAR 分开，停机时为单独包，保持 PWM、REL/EN 禁止。旧 DSP GPIO 编号只用于查原接线。 |

限幅与相关 Runtime 槽位可查[实机模型说明](../../docs/AXU5EV_EXPERIMENT_WHITEBOX_ZH.md#33-bind_real_feedback)。请求成功返回 `request_id/accepted_revision`；`ax05a_control_status` 给出选择、确认、下发版本及 ARM/CLEAR 状态。下发版本须经匹配 PS 帧确认处理，参考还须检查 COMMIT 与 P0/FOC 身份。CALIBRATE、CLEAR、ARM 的实际状态分别由校准版本与完成位、CLEAR 回读、ARM 状态确认。

## 诊断与记录

- `ax05a_read_diagnostics` 按需冻结并完整读取 80 字 PL 包。ADC 原码为 words 6–7，OTR 和校准见 2、13–15、21。QEP count、Z count/tick 和非法计数见 words 16–20，Z 已见位在 word 2。请求态、采样态和物理信号分属各自来源。
- word 78 的低 12 位依次为 PWM、RELCON、ENCON、F_Reset、OE 禁止请求，reference valid，快速禁止，最终 PWM_EN、RELCON、ENCON、F_Reset_n、CTRL_EN。最终位是 RTL 输出逻辑，实际电气状态需现场验证。早期 PS fault 分别记 ERRI/ERRU 的逻辑故障判定，输入缓冲关闭时两路判为故障。另有 IRQ 帧数、精确 ACK、overrun、COMMIT 和 STOP 原因。
- PWM 读取 `0x80001000` 独立从机，只返回已采用比较值（偏移 `0x30–0x38`）。采样前后比较采用序号和状态，稳定且完成时置 `pwm_receipt_coherent`。周期、死区使用 PWM 拍，use_permission 为只读诊断。
- `ax05a_trace_start(mask)` 触发，`ax05a_trace_poll()` 拉取并按组掩码记录，`ax05a_trace_stop()` 冻结，`ax05a_trace_info()` 返回捕获 ID、PL 扩展／应用／硬件 profile、时基、通道和计数，以及首条记录中有效的控制模式、FOC 实际参考和 ADC 偏置。用 `ax05a_trace_read(capture,index,...)` 读取冻结记录。容量 256 条，满后冻结。重复快照不占槽，前台跳过的帧按 tick、sample_id、PL 发布序号累计，身份不连续冻结。原 IRQ 时序 trace 与业务记录共享 RAM，一次一个捕获。业务采样由调用者调度，采集率与负担待 ARM 验证。
- Issue #53 通过此 API 接收结构化请求和响应，并自行序列化有效字段。C 结构体含填充和宿主枚举布局。底层诊断和业务拉取都以单前台所有者串行化。

## 串口使用

`o <action> <mode> <selected_revision> <position_mm> <speed_mm_s> <id_a> <iq_a> <fine_phase_rad>` 后接换行。动作编号以 [ax05a_online.h](../../firmware/r5/motor_control/ax04b/ax05a_online.h) 中的枚举顺序为准，从 0 开始。模式 1/2/3/4 为电流/速度/位置/自动对齐。串口自动编号，不使用的字段填 0。运行读回用 `n`，立即停机用 `x`，低层快照用 `d`。业务 trace 按 `L`、多次 `K`、`P` 捕获和下载，旧 IRQ 时序入口为 `l/p`。
