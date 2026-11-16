# AXU5EV — 当前交接（PR41 / Issue40）

> **现行状态入口，更新于2026-11-13。** 以本页与 [聚合验收状态](../verification/motor_control/results.json) 为准；较早的评论、说明和仿真日志用于追溯历史，不再构成新任务指令。PR41保持Draft，Issue40开放；是否接受全链动态SDF缺项并合并，由用户决定。

## 一、现阶段统一结论

| 范围 | 当前状态 | 证据 / 解释 |
|---|---|---|
| 统一模型及数值一致性 | **PASS（离线）** | 55帧模型；19帧FOC状态对照、57字零差；见聚合结果的`model`、`same_frame_numeric_comparison` |
| 完整ADC/QEP→FOC→PWM数字链RTL | **PASS（离线）** | RTL06 370245次检查，覆盖同帧身份、整组三相、取消及重臂；见聚合结果的`chain_rtl` |
| 完整布线设计STA/CDC | **PASS（原冻结候选）** | WNS +1.272ns、WHS +0.011ns，TNS/THS 0；[路由审计](../verification/motor_control/evidence/routed/hardware_02_audit.json) |
| PWM局部布线后SDF slow/max | **PASS** | [最终slow汇总](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/v2/slow/summary.json) |
| PWM局部布线后SDF fast/min | **PASS** | [最终fast汇总](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/v2/fast/summary.json) |
| 完整功能PL动态SDF | **NOT_COMPLETED** | Windows全量网表O0在编译阶段触发工具故障，O2在xelab运行24小时后超时；均没有完整动态验收 |
| R5应用构建及被动启动准备 | **PASS（离线准备）** | `vitis_01`产物存在的既有构建/检查记录；不等于板上R5已运行 |
| 无功率板测与R5实际采集连续性 | **NOT_RUN** | 没有现场执行证据或本轮上板授权 |
| 功率级、电机运动与完整外环/对齐 | **NOT_RUN / NOT_INTEGRATED** | 不在PR41当前签收范围 |

**两个SDF口径不可混用。** `PWM_CUT_SDF_SLOW/FAST`是已布线PWM桥局部切点在声明的输入边界模型下的两角门级动态验证；`FULL_CHAIN_SDF`仍未完成。局部SDF不覆盖原FOC/ADC内部计算、源至切点完整实际互连/时钟树、完整参考重臂策略或80字的板上读回。

## 二、当前唯一有效的技术基线

- **仓库与工作分支：** `kazecode666/AXU5EV`，`codex/motor-control-chain`；[Draft PR41](https://github.com/kazecode666/AXU5EV/pull/41)、[Issue40](https://github.com/kazecode666/AXU5EV/issues/40)。
- **已冻结的实施产物：** `.runtime/motor_control/hardware_02`的bit/ltx/XSA及已布线DCP；`.runtime/motor_control/vitis_01`的R5应用/平台/FSBL。服务器未修改生产RTL、Simulink模型、XDC或这些实施产物。
- **最终局部SDF证据：** [统一报告](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/RESULT_REPORT.md)、[物理极性证明](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/POLARITY_PROOF.md)、[最终Testbench](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/v2/pwm_cut_tb.sv)。`auto_inhibit`在RTL为高电平禁止，但该cut的物理边界承载`permission=!logical_inhibit`；反相关系**只在局部TB接口适配**，不能据此反转生产RTL接口。
- **局部SDF动态覆盖：** 每角756022次检查、11次请求/接受、8次谷值采用/回执、3次取消/重臂、三次Anchor启动、死区最小1000ns；slow/fast均实际完成，SDF注释确认且无真实时序异常。边界源延迟0.2ns是仿真假设，不是完整跨层实测延迟。
- **物理边界：** `physical_link_verified=0`，六路PWM尚非经过验证的外部驱动器接口；`fast_inhibit`在当前BD固定接0，独立动态覆盖N/A。48V为数字测试参考，不是实测母线。

## 三、接下来怎么做（本页只提供决策，不自动授权）

**当前：停止额外的服务器SDF诊断或长时间全量编译。** 已完成的PWM局部两角工作线收口，原失败和中断日志保留，不重跑已完成的模型/RTL/STA。

1. **本地Codex：** 更新本地工作副本前先确认分支和未提交变更，安全同步远程PR41的现行内容。不得自动强制覆盖、清理、暂存用户文件。核对PR正文、聚合结果和本页一致；无需重新运行Vivado/XSim或重新打包。
2. **用户决策：** 按“数字链已离线验证 + PWM局部SDF两角PASS + 完整设计STA PASS + 完整链动态SDF延期 + 板测未执行”的限定范围，决定是否允许PR41进入合并审查。没有用户授权不得自动合并、关闭Issue或把NOT_COMPLETED改PASS。
3. **未来现场阶段（另行授权）：** 使用[无功率板测手册](../firmware/r5/motor_control/FIRST_RUN_ZH.md)核对bit/ltx/XSA/ELF、UART、ILA和80字快照，再执行默认禁止、ADC校准、同帧反馈与采集连续性、参考采用、编码器、禁止/重臂。现场操作和功率级测试都不是本轮任务。
4. **更后续：** R5完整运动控制Runtime、外环及初始化对齐按独立任务开展；AQM参数/编码器尺度与电流PI基线复核不混入本次验收收尾。

## 四、历史索引（保留原始证据，不作为现行指令）

- [局部SDF第一轮](../verification/motor_control/evidence/pwm_cut_windows_20261113_01/README.md)：边界anchor保持时间违例、未完成。
- [局部SDF第二轮](../verification/motor_control/evidence/pwm_cut_windows_20261113_02/README.md)：源握手TB断言失败、未完成。
- [局部SDF第三轮](../verification/motor_control/evidence/pwm_cut_windows_20261113_03/README.md)：切点许可极性疑点硬停止。
- [第四轮最终证明及两角PASS](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/RESULT_REPORT.md)。
- [全量SDF历史记录](../verification/motor_control/evidence/full_sdf_20261110/README.md)、[编译工具故障报告](https://github.com/kazecode666/AXU5EV/pull/41#issuecomment-6801862540)、[24小时超时回执](https://github.com/kazecode666/AXU5EV/pull/41#issuecomment-6844442026)。
- 更早的执行计划和过程保留在PR41讨论、Issue40评论及Git提交历史，不再以重复的“当前/待运行”标题放入本页。

**文档规范：** 现行交接与验收仅采用PR/Issue、分支、相对路径、工具实际日志及结果状态；不新增文件摘要/校验任务或冗长提交标识。
