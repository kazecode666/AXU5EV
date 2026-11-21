# AXU5EV 当前交接

## AX-05A 在线接口候选

[Issue #52](https://github.com/kazecode666/AXU5EV/issues/52) 复用 AX-04B 实机控制路径。在线 API schema 1 使用应用身份 `0x41585204`、R5 模型/C 1.173 和 FOC 模型 1.30。业务与诊断数据由前台按需读，PS 和 PL 结果按采样 ID 与 tick 匹配，命令回执区分所选、模型处理、COMMIT 接受及 P0 采用。进入下一阶段 #53 时复用这套 API。见[信号和操作合同](../integration/ps_pl/AX05A_ONLINE_ZH.md)、[离线结果](../verification/experiment/ax05a/results.json)和[候选报告](reports/ax05a_online_interface.md)。

SELFTEST 和 REAL 已完成新 PL 布线、Vitis 目标构建与离线启动核对。两套候选为 `.runtime/experiment/ax04b/selftest_ax05a_02` 和 `.runtime/experiment/ax04b/real_ax05a_02`，各自使用本目录内的 bit/ltx/XSA、R5 ELF、A53 FSBL 与 `ax04b_realtime_manual`。板内 SELFTEST、实际 ARM 执行／IRQ→COMMIT 负担、REAL IO 和功率运动均为 `NOT_RUN`。REAL 保持硬禁止。下方 AX-04B R1 记录保留对应旧候选及现场验收入口。

## AX-04B R1 基线

更新于 2026-11-21。[PR46](https://github.com/kazecode666/AXU5EV/pull/46) 的独立实机模型与双入口由 [PR47](https://github.com/kazecode666/AXU5EV/pull/47) 带入主线。[PR48](https://github.com/kazecode666/AXU5EV/pull/48) 已合并并提供 AX-04B R1 实时控制候选。[PR49](https://github.com/kazecode666/AXU5EV/pull/49) 已合并并提供独立的 J16 静态 VIO 测试。各阶段原验收、报告和失败证据见[历史交接](HANDOFF_HISTORY_2026-10-31.md)。

## 当前模型与部署候选

| 用途 | 来源与入口 |
| --- | --- |
| 纯仿真 | [START_SIMULATION.m](../simulation/START_SIMULATION.m) · [仿真参数](../simulation/closed_loop/parameters/init_AXU5EV.m)。`START_HERE.m` 为兼容转发。 |
| 实机算法 | [START_EXPERIMENT.m](../simulation/START_EXPERIMENT.m) · [AXU5EV_Motor_Control_System.slx](../simulation/experiment/AXU5EV_Motor_Control_System.slx) · [实机参数](../simulation/experiment/parameters/axu5ev_experiment_parameters.m) · [白盒说明](../docs/AXU5EV_EXPERIMENT_WHITEBOX_ZH.md)。 |
| R1 SELFTEST | `.runtime/experiment/ax04b/selftest_r1_02`，使用内部合成 ADC/ABZ。复用 `selftest_02/hardware` 的已布线 PL 成果。 |
| R1 REAL | `.runtime/experiment/ax04b/real_r1_02`，用于真实输入和禁止态核对。复用 `real_02/hardware` 的已布线 PL 成果。 |
| R1 构建与启动 | 两候选均使用模型 1.173 的 [R5 生成 C](../generated/experiment/ax04b_r1_01/r5)、应用 `ax04b_realtime`、身份 `0x41585203`、启动项 `ax04b_realtime_manual`。按[首运行指南](../firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md)配套使用 bit、ltx、XSA、R5 ELF、A53 FSBL 和启动项。 |

现行证据见 [AX-04B results.json](../verification/experiment/ax04b/results.json) 的 `current_revision`、`r1_review` 和[交付报告](reports/ax04b_hardware_binding.md)。`*_02/vitis` 中的旧 ELF（`0x41585201`）和 R1 中间试编译版本（`0x41585202`）按历史候选保存。

## 已交付与尚待验收

- **离线 R5/PL。** B1～B4 已实现冻结反馈、定相电平 IRQ、精确 ACK、下一 P0 原子参考、FOC/PWM 接入和 GIC/MMIO 调度。匹配 PL 候选已有 RTL、布线 STA 和引脚设计核对，R1 R5 ELF 已完成目标构建和文件启动检查。R1 主机验证覆盖阈值和停止恢复，定向验证含复现的旧反例。停止恢复依次确认 CLEAR、确认 ARM，再发一次显式 Start。见[交付报告](reports/ax04b_hardware_binding.md)及[实时帧与时序表](../integration/ps_pl/AX04B_INTERFACE.md)。
- **R1 现场。** `BOARD_SELFTEST`、`ARM_EXECUTION`、`IRQ_COMMIT_LATENCY_MEASUREMENT`、`REAL_IO`、`POWER_MOTION` 均为 `NOT_RUN`。REAL 的六路物理门极、PWM 缓冲使能及 RELCON/ENCON 硬禁止，当前应用拒绝 REAL ARM。PR24 的回放时间和 PR41 冻结候选的 PWM 局部 SDF 各适用于其原场景。当前 IRQ→COMMIT 窗口仍须 ARM 实测，完整动态 SDF 未纳入本轮验证。
- **J16 独立静态验证。** PR49 的构建记录保存了当时的 `NOT_RUN`。随后用户报告 J1 自行焊接并插合 J16，完成 9 路输出和 QEPA 一路反馈的空载静态验证。QEPB、QEPZ、ERRI、ERRU 的外部高电平逐路输入、动态 PWM/死区、驱动器负载和电机运动仍待验证。见[独立 VIO 工程](../hardware/axu5ev/j16_level_test/README.md)及[J16 首板实测记录](https://github.com/kazecode666/J16-MBDL4-Module/blob/main/docs/writing/interface_board_static_test_record.md)。

## 下一阶段入口

- [#42 AQM 实机集成](https://github.com/kazecode666/AXU5EV/issues/42)跟踪物理标定、未确认的机械参数和现场验收。实机模型采用 AQM30-B2 Parallel 候选参数，实际 ADC 零偏/增益/极性、编码器尺度与方向、运动总质量及外环候选值的适用性仍需现场证据。
- [#44 IRQ→COMMIT 实板时延](https://github.com/kazecode666/AXU5EV/issues/44)跟踪实现后的执行时间及目标帧验收。记录 ARM 执行窗口和参考接受/应用的帧身份。
- 分别取得现场授权后，按[无功率首运行指南](../firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md)先进入 B5 SELFTEST，再进入 B6 REAL 真实输入和禁止态核对。功率运动另行授权。
