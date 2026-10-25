# AXU5EV — 当前交接

日期：2026-10-26。仓库 [kazecode666/AXU5EV](https://github.com/kazecode666/AXU5EV)，本地 `D:/Project/AXU5EV`。

AX-00迁移已完成（PR #1），资料任务PR #2、资料成果PR #4均已合并。PR #4合并提交`7492fc4a354d356f19123da0649e7861e6354943`。AX-00/AX-00B任务书及Issue #3保留为历史记录，其中哈希清单、全资料遍历、快照保护报表、字节一致性专项和额外资料冒烟要求不再适用于当前开发。不为文字修订重跑旧仿真/RTL。

## 当前方向与已有起点

- **目标板AXU5EVB-E，用户已确认。** 非B版资料仅作对照。PCB修订、芯片完整料号与厂商XA/-1、手册XC/-2的差异留待板级适配前核实，不阻塞R5软件提取。
- R5F提取现有位置P、速度PI、Reference_Manager/轨迹/命令、原五态对齐及一次性偏置；PL复用已接受的电流FOC，负责实时采样/位置/角度、PWM与快速禁止。
- 起点为 `simulink模型/PMLSM_PI_FOC_Float_Baseline.slx`、`PMLSM_FOC_FixedPoint.slx`及现有初始化/类型/轨迹脚本，PL来源为 `generated/legacy_m3_p3/FOC_DUT.sv` 和p3生成配置。StudyL1速度PI、原MIL/DSP与对齐来源均已迁入，无需从零重做PI/FOC/定点化或重复LED学习。
- 接口继承 [旧定义](../references/legacy/PMLSM_Hardware_Interface_Map.md)与`references/legacy/mil/PMSLM_Init_Params_MBDL4.m`：YXPHM-MBDL4、独立ia/ib/ic、0.1µm/count光栅、RELCON/ENCON/F_Reset及低有效ERRI/ERRU。只补AXU5EVB-E的外置ADC、电平/接收与接线适配，不照搬DSP GPIO/ePWM/ADC配置。

## 接下来执行

分支`codex/ax01-r5-pl-boundary`、[PR #5](https://github.com/kazecode666/AXU5EV/pull/5)已提取R5外环/Reference_Manager/原对齐模型并生成主机C，实施提交`7c9246a95d63bcd4012ac4d4f3d719d4faa15458`。五组组件对照及C回放通过，见[本批结果](reports/ax01_r5_extraction.md)和[PS—PL边界](../integration/ps_pl/INTERFACE.md)。新模型连线/排版已检查，Goto均局部，Inport/Outport保持默认大小与外观。

下一步继续Simple_Host/Host_Core的命令/轨迹部署提取、恢复管理与PS—PL原子交换/数值转换，之后做R5目标平台与PL按B-E的重定向和集成。厂商UART/TTC/AXI/BRAM只提供平台接口参考；不替换控制算法。AX-01/02尚未全部完成。

保持已有PI/位置P、时基、手动Start、五态对齐、一次死区和应用延迟；各类Reset/清故障语义分开。旧PR54/M4全HDL候选为历史，不再补成生产基线。普通Git提交/PR正常进行，报告只说明改动、依据、可复用内容和实际未完成项。

## 证据与未完成

已迁资产与既有仿真/RTL证据见[AX-00报告](reports/ax00_migration_report.md)；板卡资料实读、章节/工程入口见[AX-00B报告](reports/ax00b_vendor_review.md)、[板卡事实](../hardware/axu5ev/ALINX_BOARD_FACTS.md)及[R5指南](../firmware/r5/ALINX_R5_REUSE_GUIDE.md)。历史结果不是本轮复跑结果。

主机ERT C生成及独立C回放PASS；Simulink管理SIL尝试因MATLAB安装路径辅助构建失败，详见本批报告。R5目标编译与WCET、5EV综合/布线、ARM实测及实机仍NOT_RUN。新板外置ADC选型/三相通道、光栅接收/电平、门极/故障接线与端到端时延仍需适配。禁止自行烧录或上电。
