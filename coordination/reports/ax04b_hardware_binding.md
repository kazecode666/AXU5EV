# AX-04B 硬件绑定与首次无功率候选

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
