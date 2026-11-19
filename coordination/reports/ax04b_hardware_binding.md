# AX-04B 硬件绑定与首次无功率候选

## PR48 复审基线

本轮从 PR48 原实现 `d345e28398734d1bf5343f52c5e576e971546192` 接续。模型提交 `bcbb1bca750636494f211cffa710891aff1e5f34` 纳入已保存的主模型 1.173、初始化参数和白盒说明。生成前从磁盘重开了干净的实机主模型，逐项比较 Model Workspace 与 `axu5ev_experiment_parameters.m`。对 21 个 Switch 核对严格 `>0.5` 配置，检查 `CommandFrame(9)` 的非零 PI_Reset 解释，并用 Simulink 编译核对 77 个业务 Mux/Demux 端口及 20／41／5 槽接口。电流、速度、位置周期仍为 100 µs、1 ms、10 ms，测速需要 50 个间隔，帧步长为 500 个 ID 单位及 5000 个时戳 tick。独立纯仿真和历史生成目录原位保留。[原执行评论](https://github.com/kazecode666/AXU5EV/pull/48#issuecomment-7002641585) · [最新补充](https://github.com/kazecode666/AXU5EV/pull/48#issuecomment-7004130803) · [白盒说明](../../docs/AXU5EV_EXPERIMENT_WHITEBOX_ZH.md)

生成提交 `9f5cbb606dc41216e7e69d590496866eb6659fc5` 采用新的 `generated/experiment/ax04b_r1_01/r5`。MATLAB R2026b 生成 Cortex-R ERT 1.173，并以实际生成的五份 C 构建 host MEX。既有回归通过 317 项和 275136 次 IRQ 调用。Iq 测试模式输入 `0 / 0.5 / 1` 时，实际 Runtime Iq 输出为 `0 / 0 / 0.125 A`。PI_Reset 输入 `0 / 0.25 / −1` 时，Runtime 和 PL 参考的复位位均为 `0 / 1 / 1`。编译仍报告 `runtime_y` 信号对象初值被默认 0 取代的既有诊断。[模型及生成证据](../../verification/experiment/ax04b/r1_model_baseline.json) · [阈值用例](../../verification/experiment/ax04b/test_model_thresholds.m)

### R1 旧反例

保留原 `d345e28` 的实际 `frame_interrupt`、STOP/CLEAR/ARM 和命令槽处理，与本轮同一份 1.173 生成 C 一起编译。主机桩只提供平台和寄存器行为。在三个独立用例内，故障字为 0、电流和编码器均有效，软件请求保持开启。采样步长和 ACK 均通过断言。

| 触发 | 先前帧 27500 | 事件帧 28000 | 健康后续帧 28500 |
| --- | --- | --- | --- |
| COMMIT LATE | RAMP_ID，Id 0.000050 A | 回执 2、PL STOP，模型仍为 RAMP_ID，Id 0.000100 A | PL 已禁止，模型 PWM/REL/EN 请求仍开启，Id 0.000150 A |
| ARMED 丢失 | RAMP_ID，Id 0.000050 A | 未 armed、LIVE_INVALID=0，Id 0.000100 A | 模型仍许可，Id 0.000150 A |
| INHIBIT_LATCHED | RAMP_ID，Id 0.000050 A | 禁止锁存、LIVE_INVALID=0，Id 0.000100 A | 模型仍许可，Id 0.000150 A |

旧日志 `.runtime/experiment/ax04b/r1/old_01/result.txt` 的 `EXPECTED_OLD_COUNTEREXAMPLE` 表示预期的旧失败行为已复现。复跑命令使用新输出目录。

```powershell
python verification/experiment/ax04b/run_r5_runtime_test.py --cc C:/mingw64/bin/gcc.exe --output .runtime/experiment/ax04b/r1/old_replay_01 --expect-old --firmware-ref d345e28398734d1bf5343f52c5e576e971546192
```

### 停止与显式恢复

命令双槽仍由前台单写。IRQ 在栈上生成当次有效命令，从本地 ARM 会话与 PL 的 `ARMED`、`INHIBIT_LATCHED`、`LIVE_INVALID` 得出驱动许可。许可撤销时，实际模型输入为 PWM/REL/EN 关闭、OE 禁止、PI 复位。冻结帧的质量字段仍决定反馈有效性，未 armed 的启动过程能建立 51 项历史。

PL 禁止或软件 STOP 立即撤销许可并作废已排队的 CLEAR 与 Start。前台 STOP 在没有后续帧时保留 `stop_pending`，状态输出立即显示禁止。下一可处理的 IRQ 把停止传到模型。在普通帧调用之后遇到编码失败、COMMIT 失败或提交读回后的硬件许可丢失时，固件先 STOP 并精确 ACK，再用同一 ID/tick 执行一次安全调用。该调用独立标记为 `safety_pass`，无需第二次普通积分、Host 调度、COMMIT 或 ACK。首次到达 DONE 时，以本帧的匹配 COMMIT 回执与回读许可为本地完成边界，失败会撤销临时 DONE。已经正常完成的对齐状态沿用模型合同。下一 P0 采用仍使用独立的 PL 读回字段。

清错在新且有效的帧上请求 PL CLEAR，以读回的禁止、ARM、掉帧和实时状态确认。收到确认后，SELFTEST 才可显式 ARM 并再次读回；重新对齐需要新的 Start。机械位置及连续计数沿用模型状态。SELFTEST 的 Init_Reset 和 F_Reset 仍分别可用，停止时可编码独立 F_Reset 包。REAL 继续拒绝运动许可并保留校准、反馈和诊断。[IRQ 与命令处理](../../firmware/r5/motor_control/ax04b/ax04b_main.c) · [模型薄适配](../../firmware/r5/motor_control/ax04b/ax04b_adapter.c)

`s` 和 CSV 提供原 PL 状态、触发停止时的 PL 状态、停止原因、停止待处理、有效许可、Start ticket、对齐状态及 `safety_pass`。`stop_reason` 数值 0～10 依次为无、显式请求、快照异常、反馈合同、overrun、ARM 丢失、禁止锁存、实时故障、安全重复、编码失败、COMMIT 失败。失败记录的 `flags` 是提交时尝试发送的字，是否接受须看 `result`。快照身份读不一致继续走 STOP、屏蔽 GIC 并保留未确认事件的既有故障路径，本轮未对该分支做动态异常注入。串口及 CSV 输出位于前台。

### R1 定向验证

许可修复提交 `b411733a2ee69331c132d914c885842c2b88b822`，恢复顺序最终修订 `c6a2539bf86e5f5deaa51b0560dd342f15c61e13`。用最终提交运行同一个测试入口，通过 12 个场景。LATE 帧 28000 当帧归 IDLE，模型 PWM/REL/EN 均撤销，位置保持 1 mm，编码器和电流仍有效。健康帧 28500 保持 IDLE 和零 Id，并提交安全参考。对齐票据 1 在重臂后保持已消费，直至新票据 2 进入 RAMP_ID。一次在读到匹配的接受回执期间出现禁止锁存的注入也触发 STOP，同一帧只提交和确认一次。

复审额外验证先排队 `r`、后发 `x`、等待一帧再尝试 `a`。中间提交的 CLEAR/ARM 写计数为 1／1，最终修订为 0／0。重新显式 `r` 后可以确认 CLEAR 和 ARM。其余用例覆盖 CLEAR/ARM 被拒并重试、待命测速、硬件状态自行恢复而无新 Start、纯重复与许可变化重复、完成边界上的显式 STOP 和 LATE、已正常完成的五态及 0.1 A 内部 q 轴请求、两个独立重置和 REAL 的输入诊断。完成边界的 STOP 在下一 IRQ 前报告 `armed=0 permit=0 stop_pending=1`。无功率候选继续硬禁止外部功率输出。薄适配器的格式、回绕及服务用例也使用本轮生成 C 通过。[定向测试](../../verification/experiment/ax04b/test_r5_runtime.c)

```powershell
python verification/experiment/ax04b/run_r5_runtime_test.py --cc C:/mingw64/bin/gcc.exe --output .runtime/experiment/ax04b/r1/fixed_replay_01 --firmware-ref c6a2539bf86e5f5deaa51b0560dd342f15c61e13
```

### R1 部署与验收边界

| 配置 | 当前候选 | 同套硬件文件 | R5 目标文件 |
| --- | --- | --- | --- |
| SELFTEST | `.runtime/experiment/ax04b/selftest_r1_02` | `hardware/ax04b_selftest.{bit,ltx,xsa}`，来自 `selftest_02/hardware` | `vitis/ax04b_realtime/build/ax04b_realtime.{elf,map}` |
| REAL | `.runtime/experiment/ax04b/real_r1_02` | `hardware/ax04b_real.{bit,ltx,xsa}`，来自 `real_02/hardware` | `vitis/ax04b_realtime/build/ax04b_realtime.{elf,map}` |

Vitis 2026.1 使用各自匹配的 XSA 生成 BSP 和应用。两个 ELF 均为 ARMv7-R、小端、VFPv3-D16 硬浮点，SELFTEST 441100 字节、REAL 440708 字节。两套分别通过 `OFFLINE_STARTUP_CHECK_PASS`，核对 1.173 的五份生成 C、两份绑定 C、ELF 的身份 `0x41585203` 与模式、实时基址 `0x80002000`、高电平 GIC INTID 121 及 16 KiB IRQ 栈。bit、ltx 与 XSA 按配置逐文件核对原实现，XSA 中的 bit 与对应外置 bit 一致。布线、STA、CDC 证据沿用下面的 B4 记录。本轮未运行 Vivado、完整 SDF 或板卡操作。`BOARD_SELFTEST`、`REAL_IO`、`ARM_EXECUTION`、`IRQ_COMMIT_LATENCY_MEASUREMENT`、`POWER_MOTION` 均为 `NOT_RUN`。[首运行指南](../../firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md) · [候选与验证状态](../../verification/experiment/ax04b/results.json)

以下 B1～B4 记录对应原候选及其硬件实现。

## 基线与源选用

实现分支从 `main` 的 `21847326e4e0d8e100f3aaa5f31b612f24f75e01` 建立。PR45 的合并提交为 `3fdd140609b0ff91f1348965ebbd76c13c8821b3`。PR46 先合入 PR45 分支，合并提交为 `3884eed0c3088fe5941754523c7fa2cd48ef251f`，后由 PR47 补入。用 Git 核对 `8fd02bb91ef76fefb520fad501e7fbe2939c84e1` 是本轮基线的祖先，且两个树之间只增加了任务书。[PR47 任务书](../tasks/ax04b_hardware_binding_and_first_run.md) · [Issue42 执行评论](https://github.com/kazecode666/AXU5EV/issues/42#issuecomment-6974714393) · [Issue44 接入评论](https://github.com/kazecode666/AXU5EV/issues/44#issuecomment-6974720049)

R5 候选调用 PR46 最终 1.95 的实际 ERT 源和外部入口。硬件清单选择独立实机的 51 份 PR46 SV，包含电流预处理、电角度、FOC 和 duty 映射的四个完整生成边界。新增可见 `Control_Angle` 模型单独生成一份 SV，兼容性检查为零错误、零警告。原观察器和 PWM 采用桥按显式配置选择旧源或本轮实机源。本地用户布局和白盒说明书仍保存在工作区。[源清单](../../hardware/axu5ev/motor_control/sources.list) · [控制角模型](../../simulation/experiment/pl/AXU5EV_Experiment_Control_Angle_HDL.slx) · [控制角生成入口](../../simulation/experiment/scripts/axu5ev_experiment_generate_control_angle.m)

## 帧、角度和停止

早期 IRQ 由当前选中转换的电流资格寄存事件驱动，连同 P0 采集的编码器计数、完整 tick、采样号、校准及配置版本锁存。后续 FOC 读取冻结的电流资格与同帧角度。配置版本寄存按有效 APPLY 更新，单写 shadow 不改变后续结果标签。PS 同时可在观察窗口读取原慢速 80 字诊断。[实时接口与时间表](../../integration/ps_pl/AX04B_INTERFACE.md)

参考整包在目标 P0 采用。固定对齐期间选择 `theta_align_const=0 rad` 及零电角速度。常规帧以编码器角加已归一化偏置作一圈内回绕，从同一参考携带电角速度、Id/Iq 和 PI_Reset。源编码器相位偏置固定为零，机械计数原点采用实机既有合同。Q24 电流和 Q32 弧度值由传输层限幅及校验，母线控制常数 48 V。核从首个相位对齐后连续推进完整 5000 拍。[PL 观察器接入](../../hardware/axu5ev/motor_control/rtl/top/ax03b3_adc_observer.sv) · [FOC 调度](../../hardware/axu5ev/motor_control/rtl/control/motor_foc_control.sv)

低有效 ERRI/ERRU、失锁、撤销、非法或过期参考走 PL 禁止。短脉冲可立即撤销 PWM 邮箱，取消在途采用。已 armed 时的缺包 P0 触发禁止，接受停顿的看门狗为 10000 个逻辑时钟。故障或超时后先显式清除再重新 arm。软件清错、对齐重置、PI_Reset 和驱动 F_Reset 保持不同信号及调度动作。

REAL 的 16 项 J16 输出和输入对照 J16-MBDL4 V0.3 生产引脚表、原生原理图、板卡引脚表逐个核对，16/16 一致。V0.3 来源树为 `e388c58e6b3e8643aca555dd9847beaf314b3d8c`。CTRL_EN_A 单独允许 QEP/故障观测，启动保持低。F_Reset 物理脚空闲高，活动高的软件脉冲映射到低，相对驱动清锁存边沿为释放时的低到高。六路 PWM、PWM_EN_A、RELCON、ENCON 在此次无功率候选硬禁止，REAL APP 亦拒绝运动 arm。SELFTEST 使用合成 ADC/ABZ，内部 PWM 可观察，外部 J16 未引出。AN9238 继续使用 J15 约束。实际首板插合、外部故障电平、边沿、缓冲和真实电流比例是后续无功率检查。[J16 与 AXU5EVB-E 物理约束](../../hardware/axu5ev/motor_control/constraints/j16_ax04b_real.xdc) · [接口板 V0.3](https://github.com/kazecode666/J16-MBDL4-Module/tree/e388c58e6b3e8643aca555dd9847beaf314b3d8c)

## R5 绑定

PS 用匹配 XSA/BSP 读取实时寄存器基址及 SPI；本轮 BD 连接 PL_PS_IRQ0 的第 0 位，高电平保持至精确 ACK。启动检查 PL 身份、模式及尺度，然后初始化生成模型及 GIC。ISR 校验事件与序号，读取冻结数据并使用双槽命令快照，调用 `PL_Frame_IRQ()`，编码并提交目标下一帧，读取 PL 接受回执，最后 ACK。安全变化的重复帧可进入软件安全路径。无实际待处理中断的入口和纯重复身份不会推进普通控制。服务调用的临界区只用于复制，UART 发送与 CSV 导出在 ISR 之外。事件跟踪记录 PMU 与 PL 相位、R5 生成函数和实际接受/采用版本，具体板内预算留实测。

定向主机用例直接链接 PR46 实际五份 C，覆盖采样/tick 回绕、同身份异常、A/Q24 和角度编码、外部入口启动、测速资格、显式清错、内部 q 轴测试、固定角对齐及故障取消。目标构建使用单独启动平台和 16 KiB IRQ 栈，匹配检查读取 ELF 里的实际模式、地址、SPI 和入口。用户操作顺序和看板记录格式见首运行指南。[实机绑定源码](../../firmware/r5/motor_control/ax04b) · [定向适配用例](../../verification/experiment/ax04b/test_r5_adapter.c) · [首运行指南](../../firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md)

## 离线验证与交接

| 检查 | 结果 |
| --- | --- |
| AXI 原子反馈、IRQ 与参考事务 | XSim 通过 866 项，覆盖冻结、精确 ACK、并发到达、下一 P0 采用和拒绝路径 |
| 实机生成源数字链 | SELFTEST 通过 110297 项，REAL 数字激励通过 110299 项。各覆盖 3 个无效事件与 3 个有效事件。观察到 P76 IRQ、P110 反馈会合、P127 冻结输入、P443 算法结果、P2500 谷值采用和 P2504 采用确认 |
| 旧数字链定向回归 | 19 帧通过 370245 项，覆盖旧源与旧入口 |
| SELFTEST 布线 | WNS +0.355 ns，WHS +0.005 ns，TNS/THS 为 0 |
| REAL 布线 | WNS +0.986 ns，WHS +0.011 ns，TNS/THS 为 0。AN9238 捕获路径最小 setup/hold 裕量为 +2.857/+5.065 ns |
| REAL J16 | 16 项 pin 与 LVCMOS33 实现审计通过。三个 ABZ 和两个故障输入的时序例外限于首级同步器 D 端 |

两套布线均无路由错误、未加时钟的顺序单元和内部未约束端点。两套 CDC 报告各有四条 `dbg_hub` 的 CDC-15 警告，均无严重 CDC 项。REAL 的四项总线偏斜检查通过。两套 DRC 各有 805 条警告、零错误，主要为生成 DSP 流水线建议，并含转发 ADC 时钟寄存器的两条 IOB 警告。`check_timing` 标记五个异步 J16 输入、两个转发 ADC 时钟及 J16 的 CTRL_EN_A、F_Reset 输出，现场板级电气和外部响应时间仍待测。两套构建各使用一个 ILA，通过四组探针保留事件、参考身份及内部 PWM。

两套部署分别位于 `.runtime/experiment/ax04b/selftest_02` 与 `.runtime/experiment/ax04b/real_02`。同一配置的 XSA 内嵌 bit 与外部 bit 一致。两个实现各自导出的 LTX 内容一致，含同一 ILA 身份及探针连接。启动检查核对 LTX 结构、实际 BSP 与已链接 R5 ELF。ELF 的模式分别为 1 和 2，应用身份均为 `0x41585201`，实时基址 `0x80002000`，GIC SPI INTID 121，IRQ 栈 16 KiB。板内 SELFTEST、REAL 外部采集、功率运动和实际 IRQ/COMMIT 时延均为 `NOT_RUN`。原候选和原始记录保留在原路径。[精简验证结果](../../verification/experiment/ax04b/results.json) · [首运行指南](../../firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md)
