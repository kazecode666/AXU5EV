# AXU5EV — R5F/PL 永磁直线电机研究平台

面向 AXU5EVB-E 和 AQM30-B2 Parallel，以 Simulink/Stateflow 维护控制算法，研究电流跟踪、动态响应、纹波和扰动恢复。Cortex-R5F 裸机运行位置 P、速度 PI、五态启动对齐、参考轨迹和运行管理。PL 负责同步采样、ABZ 计数与电角度、电流 PI-FOC、PWM 和快速禁止。R5 使用模型生成的 C，PL 算法使用 HDL Coder 生成的 SystemVerilog。

## 当前阶段

当前工作基线是 **GEM3 + R5/PL + Motor Control Studio 的无功率集成候选**。实机模型及其生成 C 版本为 **1.173**；GEM3 应用身份为 `0x41585205`、在线 API schema 为 1。此前 AX-04B R1（应用身份 `0x41585203`）是独立的历史离线候选，**不是当前 GEM3＋Studio 联调时应选的 ELF**。

| 范围 | 状态 |
| --- | --- |
| R5/PL 控制与在线 API | 实机模型、FOC/PWM、100 μs 帧合同、模式/给定、只读诊断与记录接口已实现并有对应离线验证。[现行交接](coordination/HANDOFF.md) · [实时接口](integration/ps_pl/AX04B_INTERFACE.md) |
| GEM3 无功率候选 | **SELFTEST R01 / REAL IO R02** 两套匹配的 PL bit/XSA、FSBL 与 R5 ELF 已通过 Vitis 2026.1 离线启动检查；使用同一应用身份 `0x41585205`。[候选和启动说明](firmware/r5/motor_control/FIRST_RUN_GEM3_ZH.md) · [构建结果](verification/experiment/motor_control_gem3/results.json) |
| PC 上位机 | **Motor Control Studio** 已实现 GEM3 TCP 控制、约 10 Hz 趋势、10/20/60 秒视窗、独立趋势 CSV、固件 Trace 与按需诊断；Windows GUI 和主机 C 服务回环测试通过。[Windows 使用说明](docs/MOTOR_CONTROL_STUDIO_ZH.md) · [离线结果](verification/experiment/motor_control_studio/results.json) |
| 当前整套系统实板 | GEM3 PHY/TCP、当前固件板内 SELFTEST、ARM 执行、网络负载下 IRQ→COMMIT、REAL IO 及功率运动均为 `NOT_RUN`，**不能将离线 PASS 当作实板 PASS**。[实机联调 #42](https://github.com/kazecode666/AXU5EV/issues/42) · [时延验收 #44](https://github.com/kazecode666/AXU5EV/issues/44) |
| J16 V0.3 接口板 | 用户已记录 J1 焊接与插合、9 路输出及 QEPA 一路反馈的空载静态验证；其余输入、动态 PWM 和驱动器负载待测。[首板实测记录](https://github.com/kazecode666/J16-MBDL4-Module/blob/main/docs/writing/interface_board_static_test_record.md) · [独立 VIO 工程](hardware/axu5ev/j16_level_test/README.md) |

**当前推荐无功率候选（位于本地 `.runtime/experiment/final/`，非 Git 跟踪的可下载附件）：**

| 用途 | 候选目录 | Vitis 启动项 |
| --- | --- | --- |
| 内部合成 ADC/ABZ，优先上板验证 | `GEM3_Control_SELFTEST_R01` | `Motor_Control_GEM3_SELFTEST_NoPower_R01` |
| 真实 ADC/ABZ 输入、PL 功率输出硬禁止 | `GEM3_Control_REAL_IO_R02` | `Motor_Control_GEM3_REAL_IO_NoPower_R02` |

两套候选不能混用 bit、FSBL、ELF。Studio 只能读取已加载固件的实际硬件 profile，不能通过软件下拉框切换 FPGA 硬件配置。**REAL IO 继续拒绝 ARM/START，并保持外部功率硬禁止。** 程序加载和无功率板测须另行取得现场授权。

下一阶段以 [#42 实机联调](https://github.com/kazecode666/AXU5EV/issues/42)、[#44 时延验收](https://github.com/kazecode666/AXU5EV/issues/44) 和 [#30 ADC 物理验证](https://github.com/kazecode666/AXU5EV/issues/30) 为入口，先板内 SELFTEST 与 GEM3 通信，测量网络负载下 100 μs 控制链，再核对 REAL IO 的输入与禁止态；电机功率运行另行安排。

## 日常入口

| 用途 | 入口 |
| --- | --- |
| 纯仿真 | [START_SIMULATION.m](simulation/START_SIMULATION.m) → [Hybrid 闭环](simulation/closed_loop/AXU5EV_Hybrid_ClosedLoop.slx) · [仿真参数](simulation/closed_loop/parameters/init_AXU5EV.m) |
| 实机模型与生成 | [START_EXPERIMENT.m](simulation/START_EXPERIMENT.m) → [实机主模型](simulation/experiment/AXU5EV_Motor_Control_System.slx) · [独立实机参数](simulation/experiment/parameters/axu5ev_experiment_parameters.m) · [实机模型白盒说明](docs/AXU5EV_EXPERIMENT_WHITEBOX_ZH.md) |
| 当前无功率部署准备 | [GEM3 SELFTEST/REAL IO 成套候选与首运行](firmware/r5/motor_control/FIRST_RUN_GEM3_ZH.md) · [匹配构建配置](firmware/r5/motor_control/build_config.gem3.selftest.json) · [GEM3 TCP 协议](integration/r5_ethernet/MOTOR_CONTROL_GEM3_ZH.md) |
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
