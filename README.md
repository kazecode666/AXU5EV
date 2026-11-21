# AXU5EV — R5F/PL 永磁直线电机研究平台

面向 AXU5EVB-E 和 AQM30-B2 Parallel，以 Simulink/Stateflow 维护控制算法，研究电流跟踪、动态响应、纹波和扰动恢复。Cortex-R5F 裸机运行位置 P、速度 PI、五态启动对齐、参考轨迹和运行管理。PL 负责同步采样、ABZ 计数与电角度、电流 PI-FOC、PWM 和快速禁止。R5 使用模型生成的 C，PL 算法使用 HDL Coder 生成的 SystemVerilog。

## 当前阶段

| 范围 | 状态 |
| --- | --- |
| 交付 A 与 AX-04B R1 | 独立实机模型、生成源、R5/PL 绑定和离线验证已交付。当前 R5 模型和生成 C 为 1.173，应用身份 `0x41585203`。[当前交接](coordination/HANDOFF.md) · [AX-04B 结果](verification/experiment/ax04b/results.json) |
| R1 实板 | 板内 SELFTEST、ARM 执行、IRQ→COMMIT 时延、真实 IO 和功率运动均为 `NOT_RUN`。[无功率首运行指南](firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md) |
| J16 V0.3 接口板 | 用户已记录 J1 焊接与插合、9 路输出及 QEPA 一路反馈的空载静态验证。[首板实测记录](https://github.com/kazecode666/J16-MBDL4-Module/blob/main/docs/writing/interface_board_static_test_record.md) · [独立 VIO 工程](hardware/axu5ev/j16_level_test/README.md) |

下一阶段按 [#42 实机联调](https://github.com/kazecode666/AXU5EV/issues/42) 与 [#44 时延验收](https://github.com/kazecode666/AXU5EV/issues/44) 推进。分别取得现场授权后，按指南先做板内 SELFTEST，再核对 REAL 的真实输入与禁止态；物理标定、运动机械参数和功率运动另行验收。

## 日常入口

| 用途 | 入口 |
| --- | --- |
| 纯仿真 | [START_SIMULATION.m](simulation/START_SIMULATION.m) → [Hybrid 闭环](simulation/closed_loop/AXU5EV_Hybrid_ClosedLoop.slx) · [仿真参数](simulation/closed_loop/parameters/init_AXU5EV.m) |
| 实机模型与生成 | [START_EXPERIMENT.m](simulation/START_EXPERIMENT.m) → [实机主模型](simulation/experiment/AXU5EV_Motor_Control_System.slx) · [独立实机参数](simulation/experiment/parameters/axu5ev_experiment_parameters.m) · [实机模型白盒说明](docs/AXU5EV_EXPERIMENT_WHITEBOX_ZH.md) |
| 当前部署准备 | [R1 成套候选与首运行指南](firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md) · [R5 生成源](generated/experiment/ax04b_r1_01/r5) |
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
