# AXU5EV — R5F/PL 永磁直线电机研究平台

**当前状态：按PR #6完成AX-01B Runtime生成C＋p3共享闭环；三后端四组正常场景通过，真实RTL共99432帧逐位一致，提交开放实现PR等待Review。目标AXU5EVB-E。** 私有仓库为 [kazecode666/AXU5EV](https://github.com/kazecode666/AXU5EV)，本地根目录 `D:/Project/AXU5EV`。实际结果和限制见[AX-01B报告](coordination/reports/ax01b_runtime_hybrid.md)；R5实机与5EV部署尚未执行。

## 目标与分工

以 Simulink/Stateflow 维护算法，重点研究电流控制方法。Cortex-R5F 承担速度/位置控制、原启动对齐、参考/轨迹及运行管理；PL 承担电流控制、同步采样与接口、PWM时序及快速禁止。R5软件由模型生成C，PL算法由HDL Coder生成SystemVerilog；初版采用一个R5F实时核、裸机方向，不预设A53/Linux或多核通信。

旧项目 `kazecode666/FPGA_XC7A200T_Study` 保留为来源和历史验证记录。本项目独立Git历史；迁移采用精选复制，不移动/删除旧工程，也不继承旧M4“所有控制功能必须生成HDL”的交付要求。

## 从哪里开始

1. [当前交接](coordination/HANDOFF.md)和[协作规则](AGENTS.md)。
2. [现有软硬件接口需求](references/legacy/PMLSM_Hardware_Interface_Map.md)及[板卡事实](hardware/axu5ev/ALINX_BOARD_FACTS.md)。AX-00任务已完成，仅作历史。
3. [软硬件分工](docs/ARCHITECTURE.md)、[来源与迁移清单](docs/MIGRATION_SOURCES.md)。

## 目录职责

| 目录 | 用途 |
|---|---|
| `simulink模型/` | 迁移后的活动参考模型、独立FOC及外部初始化；首轮保留原文件名 |
| `firmware/r5/` | 后续R5软件、模型生成C的集成及最小平台适配；AX-00不冒充已有固件 |
| `hardware/axu5ev/` | 经板卡版本核对后的Vivado/Vitis平台脚本与硬件清单 |
| `integration/ps_pl/` | 本轮仿真交换字段、事件顺序及后续硬件总线合同 |
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

日期：2026-10-26。AX-01B主机功能集成之后，继续实际R5F平台、PS—PL访问和AXU5EVB-E板级适配；继承已有模型与MBDL4接口，无需重做PI/FOC或重复LED学习。参数、代码生成和硬件测试状态见实际提交报告，不从目录存在推定已实现。

首批[R5软件提取结果](coordination/reports/ax01_r5_extraction.md)提供外环/Reference_Manager/原对齐来源。本轮新`AXU5EV_R5_Runtime.slx`纳入原Host_Core／轨迹，生成C在线接入`integration/AXU5EV_Hybrid_ClosedLoop.slx`；三种后端共用原对象、量化和50µs应用边界。软件/PL端口及帧顺序见[接口边界](integration/ps_pl/INTERFACE.md)。

混合闭环从 `addpath('scripts'); ax01b_prepare_hybrid('c_fixed');` 开始；停止后可选`model_fixed`／`c_rtl`。首次构建、同次Run改目标／Send、对齐及正常场景见[操作指南](docs/AXU5EV_HYBRID_RUN_GUIDE_ZH.md)。`c_rtl`实际运行原p3 SV，不以GM模型或录制输入替代反馈。

## 本地打开与复验

在本仓库根目录执行 `setup_AXU5EV; init_PMLSM_PI_FOC_Float_Baseline;`，再打开 `PMLSM_PI_FOC_Float_Baseline`。初始化仍是外部 `.m` 入口；默认10 mm、5 s、V10/A100未改。停止后选择 `FOC_Impl_Select=0` 浮点或 `1` 固定FOC。不要给 references/baselines 使用递归 genpath。

独立复验命令见[运行说明](verification/AX00_REPRODUCE.md)。本轮支持原点位测试的 `live` 和对齐测试的 `chart` 阶段；没有搬运全套历史学习回归依赖。`references/legacy/mil` 是旧库磁盘来源，`pmslm_disk` 是完整 PMSLM 工程磁盘参考，后者不加入活动路径。未保存窗口未被保存或导出。
