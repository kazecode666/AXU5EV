# AXU5EV — R5F/PL 永磁直线电机研究平台

**当前状态：项目初始化资料；资产迁移及本机验证尚未执行。** 新仓库拟为 `kazecode666/AXU5EV`，由 AX-00 核实并创建。这里不是已经部署成功的 AXU5EV 工程。

## 目标与分工

以 Simulink/Stateflow 维护算法，重点研究电流控制方法。Cortex-R5F 承担速度/位置控制、原启动对齐、参考/轨迹及运行管理；PL 承担电流控制、同步采样与接口、PWM时序及快速禁止。R5软件由模型生成C，PL算法由HDL Coder生成SystemVerilog；初版采用一个R5F实时核、裸机方向，不预设A53/Linux或多核通信。

旧项目 `kazecode666/FPGA_XC7A200T_Study` 保留为来源和历史验证记录。本项目独立Git历史；迁移采用精选复制，不移动/删除旧工程，也不继承旧M4“所有控制功能必须生成HDL”的交付要求。

## 从哪里开始

1. [当前交接](coordination/HANDOFF.md)和[协作规则](AGENTS.md)。
2. [AX-00建仓与迁移任务](coordination/tasks/ax00_project_bootstrap_migration.md)。
3. [软硬件分工](docs/ARCHITECTURE.md)、[来源与迁移清单](docs/MIGRATION_SOURCES.md)。

## 目录职责

| 目录 | 用途 |
|---|---|
| `simulink模型/` | 迁移后的活动参考模型、独立FOC及外部初始化；首轮保留原文件名 |
| `firmware/r5/` | 后续R5软件、模型生成C的集成及最小平台适配；AX-00不冒充已有固件 |
| `hardware/axu5ev/` | 经板卡版本核对后的Vivado/Vitis平台脚本与硬件清单 |
| `integration/ps_pl/` | 后续命令、反馈、采样与故障接口合同 |
| `scripts/`、`verification/` | 可移植构建、必要复验与精简证据 |
| `baselines/pr53_p3/` | 不改字节的八份已验收来源、p3配置与必要证据，默认不加入MATLAB路径 |
| `generated/legacy_m3_p3/` | 原生p3 RTL/TB/data/manifest；是旧器件功能基线，不是5EV时序结果 |
| `references/legacy/` | 精选MIL/DSP/StudyL1资料，仅作来源与研究参考 |
| `references/` | 资料索引；无分发许可的PDF和厂商大包放忽略的`local_only/` |
| `coordination/`、`docs/` | 当前任务、交接、来源和报告 |
| `.runtime/` | 本地缓存、波形、DCP及未公开快照，不入库 |

只创建真正需要的目录，不放虚假的板级配置或空壳应用。旧Artix引脚、器件约束和通过结论不得直接套给AXU5EV；完整芯片料号、板卡版本和工具配置由本地已有资料确认。

## 初始里程碑

- **AX-00：** 建立独立仓库、精选资产迁移、移除对旧绝对路径的运行依赖、恢复现有仿真基线。
- **AX-01：** R5侧模型边界/C与SIL、PS—PL接口合同，保留外环/对齐现有语义。
- **AX-02：** 5EV电流核重生成/实现、R5/PL混合闭环及实际处理器时限验证。
- **AX-03：** ADC、光栅/磁栅、门极PWM、驱动板保护和受控硬件集成，另行授权上电。

日期：2026-10-25。只有AX-00为当前任务，其余为后续方向。参数、代码生成和硬件测试状态见实际提交报告，不从目录存在推定已实现。
