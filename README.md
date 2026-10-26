# AXU5EV — R5F/PL 永磁直线电机研究平台

**当前优先：Issue #13，仿真收尾与R5侧模块搭建说明。目标AXU5EVB-E。** 私有仓库为 [kazecode666/AXU5EV](https://github.com/kazecode666/AXU5EV)，本地根目录 `D:/Project/AXU5EV`。PR #9/#12已合并；本轮比较相同命令时刻的10→0→−2 mm生成C/真实RTL闭环，并补充[模块搭建与连接说明](simulation/README_运行说明.md#模块怎样组成闭环)。原C源码学习任务取消，Issue #11仍为后续讨论。

日常仍从`simulation/START_HERE.m`开始。只读显示给出R5采样Send、同拍Ready/Busy及最近请求时间/结果/计数；Busy=0不保证Ready=1，未Ready拒绝且不排队。Issue #11为后续架构讨论，不在本轮实施。实际鼠标Dashboard操作/刷新仍NOT_RUN；本轮完整RTL三段运动已完成。

本轮完整C/真实RTL同Run `10→0→−2 mm` 已完成：实际RTL 64536帧，三段均满足原Ready，接受3/拒绝1；位置、速度、dq电流、参考及应用duty差均0。见[AX-01C结果与曲线](coordination/reports/ax01c_simulation_closeout.md)。先前默认点位修复与发送回执分别见[Issue #8原报告](coordination/reports/issue8_manual_run.md)、[发送报告](coordination/reports/issue8_send_ready.md)。

开放实现[PR #14](https://github.com/kazecode666/AXU5EV/pull/14)供Review，不自动合并。

## 目标与分工

以 Simulink/Stateflow 维护算法，重点研究电流控制方法。Cortex-R5F 承担速度/位置控制、原启动对齐、参考/轨迹及运行管理；PL 承担电流控制、同步采样与接口、PWM时序及快速禁止。R5软件由模型生成C，PL算法由HDL Coder生成SystemVerilog；初版采用一个R5F实时核、裸机方向，不预设A53/Linux或多核通信。

旧项目 `kazecode666/FPGA_XC7A200T_Study` 保留为来源和历史验证记录。本项目独立Git历史；迁移采用精选复制，不移动/删除旧工程，也不继承旧M4“所有控制功能必须生成HDL”的交付要求。

## 从哪里开始

1. [当前交接](coordination/HANDOFF.md)和[协作规则](AGENTS.md)。
   日常仿真直接进入[simulation](simulation/README_运行说明.md)，编辑`init_AXU5EV.m`，运行`START_HERE.m`，再点击Hybrid的Run。
2. [现有软硬件接口需求](references/legacy/PMLSM_Hardware_Interface_Map.md)及[板卡事实](hardware/axu5ev/ALINX_BOARD_FACTS.md)。AX-00任务已完成，仅作历史。
3. [软硬件分工](docs/ARCHITECTURE.md)、[来源与迁移清单](docs/MIGRATION_SOURCES.md)。

## 目录职责

| 目录 | 用途 |
|---|---|
| `simulation/` | 唯一活动模型与日常.m入口：Hybrid、Runtime、Control、FOC、浮点基线及参数/轨迹/构建辅助 |
| `simulink模型/` | 旧初始化的薄转发及用户本地wrapper；不放第二套活动模型/参数定义 |
| `firmware/r5/` | R5复用/平台说明；软件模型已集中到simulation，尚无R5 BSP |
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

日期：2026-10-27。Issue #13本轮仿真收尾已完成；实际R5F平台、PS—PL访问和AXU5EVB-E板级适配留待后续授权。继承已有模型与MBDL4接口，无需重做PI/FOC或重复LED学习。

首批[R5软件提取结果](coordination/reports/ax01_r5_extraction.md)提供外环/Reference_Manager/原对齐来源。`simulation/AXU5EV_R5_Runtime.slx`纳入原Host_Core／轨迹，生成C在线接入同目录Hybrid；三种后端共用原对象、量化和50µs应用边界。软件/PL端口及帧顺序见[接口边界](integration/ps_pl/INTERFACE.md)。

混合闭环从`simulation/START_HERE.m`开始，默认`model_fixed`；停止后可选`c_fixed`／`c_rtl`。首次构建、同次Run改目标／Send、对齐及复位见[同目录中文说明](simulation/README_运行说明.md)。保留用户紫色分区；MATLAB/Simulink通过MCP操作，不用Computer Use。

## 本地打开与复验

日常运行`simulation/START_HERE.m`，默认10 mm、5 s、V10/A100不变。需研究原浮点基线时，在同一初始化后打开同目录`PMLSM_PI_FOC_Float_Baseline`；停止后选择`FOC_Impl_Select=0/1`。不要给references/baselines使用递归genpath。

独立复验命令见[运行说明](verification/AX00_REPRODUCE.md)。本轮支持原点位测试的 `live` 和对齐测试的 `chart` 阶段；没有搬运全套历史学习回归依赖。`references/legacy/mil` 是旧库磁盘来源，`pmslm_disk` 是完整 PMSLM 工程磁盘参考，后者不加入活动路径。未保存窗口未被保存或导出。
