# AXU5EV — R5F/PL 永磁直线电机研究平台

面向 AXU5EVB-E 和 AQM30-B2 Parallel，以 Simulink/Stateflow 维护控制算法，研究电流跟踪、动态响应、纹波和扰动恢复。Cortex-R5F 裸机运行位置 P、速度 PI、五态启动对齐、参考轨迹和运行管理。PL 负责同步采样、ABZ 计数与电角度、电流 PI-FOC、PWM 和快速禁止。R5 使用模型生成的 C，PL 算法使用 HDL Coder 生成的 SystemVerilog。

## 当前阶段

当前工作基线是 **GEM3 + R5/PL + Motor Control Studio 的无功率集成候选**。实机模型及其生成 C 版本为 **1.173**；GEM3 应用身份为 `0x41585205`、在线 API schema 为 1。此前 AX-04B R1（应用身份 `0x41585203`）是独立的历史离线候选，**不是当前 GEM3＋Studio 联调时应选的 ELF**。

| 范围 | 状态 |
| --- | --- |
| R5/PL 控制与在线 API | 实机模型、FOC/PWM、100 μs 帧合同、模式/给定、只读诊断与记录接口已实现并有对应离线验证。[现行交接](coordination/HANDOFF.md) · [实时接口](integration/ps_pl/AX04B_INTERFACE.md) |
| GEM3 无功率候选 | **SELFTEST `P61_TIMING_R02`** 与 **REAL IO `GEM3_Control_REAL_IO_R03`** 均通过成套离线启动检查。R03 另有 REAL 定向 RTL、Vitis 与布线后 STA 证据。[成套启动](firmware/r5/motor_control/FIRST_RUN_GEM3_ZH.md) · [R03 离线索引](verification/experiment/ax04b/real_r03_offline.json) |
| PC 上位机 | **Motor Control Studio** 已实现 GEM3 TCP 控制、约 10 Hz 趋势、10/20/60 秒视窗、独立趋势 CSV、固件 Trace 与按需诊断；Windows GUI 和主机 C 服务回环测试通过。[Windows 使用说明](docs/MOTOR_CONTROL_STUDIO_ZH.md) · [离线结果](verification/experiment/motor_control_studio/results.json) |
| SELFTEST R02 实板 | Issue #44 的板内无功率 SELFTEST、R5 执行及规定网络负载下的 IRQ→COMMIT 和下一 P0 采用已获 **限定范围 PASS**。A/B 组独立 PWM 同帧端点证据为 `PARTIAL`，C1 为 PASS。[#44 验收报告](coordination/reports/irq_timing_r02_t4_2026-11-24.md) |
| REAL IO R03 实板 | 候选具备离线启动准备条件。实体启动、GEM3 PHY/TCP、J15/J16 真实反馈、物理标定、完整 ALIGNMENT 和功率运动均为 `NOT_RUN`。[实机联调 #42](https://github.com/kazecode666/AXU5EV/issues/42) · [R03 首板步骤](firmware/r5/motor_control/FIRST_BOARD_REAL_R03_ZH.md) |
| J16 V0.3 接口板 | 用户已记录 J1 焊接与插合、9 路输出及 QEPA 一路反馈的空载静态验证；其余输入、动态 PWM 和驱动器负载待测。[首板实测记录](https://github.com/kazecode666/J16-MBDL4-Module/blob/main/docs/writing/interface_board_static_test_record.md) · [独立 VIO 工程](hardware/axu5ev/j16_level_test/README.md) |

**当前推荐无功率候选（位于本地 `.runtime/experiment/final/`，非 Git 跟踪的可下载附件）：**

| 用途 | 候选目录 | Vitis 启动项 | 配置和指南 |
| --- | --- | --- | --- |
| SELFTEST，内部合成 ADC/ABZ | `P61_TIMING_R02` | `Motor_Control_GEM3_SELFTEST_P61_Timing_R02` | [配置](firmware/r5/motor_control/build_config.gem3.selftest.timing.json) · [#44 启动与验收](firmware/r5/motor_control/IRQ_TIMING_ZH.md) |
| REAL IO，真实 ADC/ABZ 输入 | `GEM3_Control_REAL_IO_R03` | `Motor_Control_GEM3_REAL_IO_NoPower_R03` | [配置](firmware/r5/motor_control/build_config.gem3.real.r03.json) · [A/B/C 首板步骤](firmware/r5/motor_control/FIRST_BOARD_REAL_R03_ZH.md) |

在所选候选的 `vitis/` 工作区用对应启动项，使用同套 bit、LTX、XSA、FSBL 和 ELF。Studio 的准备入口按 profile 选候选，运行时以固件读回的实际 profile 为准。旧 SELFTEST R01 和 REAL IO R02 见历史启动记录。[GEM3 历史与当前候选](firmware/r5/motor_control/FIRST_RUN_GEM3_ZH.md)

REAL IO 拒绝 ARM/START，六路外部 PWM、PWM_EN、RELCON、ENCON 保持硬禁止。板卡启动和 J15 原码采集保持 `CTRL_EN=0`。电流零偏校准和经 U3 的 J16 联调可在各自现场前提满足后使用既有共享缓冲。所有现场步骤须另行取得用户授权，先启动开发板，再分段检查 J15 和 J16。[R03 首板步骤](firmware/r5/motor_control/FIRST_BOARD_REAL_R03_ZH.md) · [#30 ADC 物理验证](https://github.com/kazecode666/AXU5EV/issues/30)

## 日常入口

| 用途 | 入口 |
| --- | --- |
| 纯仿真 | [START_SIMULATION.m](simulation/START_SIMULATION.m) → [Hybrid 闭环](simulation/closed_loop/AXU5EV_Hybrid_ClosedLoop.slx) · [仿真参数](simulation/closed_loop/parameters/init_AXU5EV.m) |
| 实机模型与生成 | [START_EXPERIMENT.m](simulation/START_EXPERIMENT.m) → [实机主模型](simulation/experiment/AXU5EV_Motor_Control_System.slx) · [独立实机参数](simulation/experiment/parameters/axu5ev_experiment_parameters.m) · [实机模型白盒说明](docs/AXU5EV_EXPERIMENT_WHITEBOX_ZH.md) |
| 当前无功率部署准备 | [GEM3 SELFTEST/REAL IO 成套候选与首运行](firmware/r5/motor_control/FIRST_RUN_GEM3_ZH.md) · [SELFTEST R02 配置](firmware/r5/motor_control/build_config.gem3.selftest.timing.json) · [REAL IO R03 配置](firmware/r5/motor_control/build_config.gem3.real.r03.json) · [GEM3 TCP 协议](integration/r5_ethernet/MOTOR_CONTROL_GEM3_ZH.md) |
| PC 实验操作 | [Motor Control Studio 使用说明](docs/MOTOR_CONTROL_STUDIO_ZH.md) · [Windows 启动脚本](scripts/start_motor_control_studio.ps1) · [Python TCP 客户端](scripts/motor_control_client.py) |
| 历史 AX-04B R1 候选 | [原 R1 首运行指南](firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md) · [原 R5 生成源](generated/experiment/ax04b_r1_01/r5)（用于追溯，非 GEM3 当前 ELF） |
| 测试与历史模型 | [数字链测试夹具](simulation/tests/digital_chain/motor_control_README.md) · [旧阶段交接](coordination/HANDOFF_HISTORY_2026-10-31.md) |

`START_HERE.m` 转发到纯仿真入口。两类活动模型各用自己的算法和参数目录。打开步骤见 [Simulink 运行说明](simulation/README_运行说明.md)。

## 仓库导航

| 目录 | 内容 |
| --- | --- |
| [simulation](simulation) | 纯仿真、实机模型、测试及历史模型 |
| [hardware/axu5ev](hardware/axu5ev) · [firmware/r5](firmware/r5) | PL 工程、R5 平台与应用、操作指南 |
| [integration/ps_pl](integration/ps_pl) | PS/PL 接口与实时帧合同 |
| [generated](generated) · [verification](verification) | 版本化生成源与精简验证证据 |
| [references/legacy](references/legacy) · [baselines](baselines) | 精选 MIL/DSP 资料及旧器件冻结基线 |
| `.runtime/` | 本地构建、匹配部署产物、缓存和原始实验数据 |

[软件与 PL 架构](docs/ARCHITECTURE.md) · [工作区指南](docs/WORKSPACE_GUIDE_ZH.md) · [板卡资料](hardware/axu5ev/ALINX_BOARD_FACTS.md) · [协作规则](AGENTS.md)
