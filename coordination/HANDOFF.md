# AXU5EV — 当前交接（PR41 已合并 / Issue42 实机集成）

> **2026-11-17 最新交接：PR41 已于2026-11-16合并。** 数字链已接受原定范围的离线验收，完整功能PL动态SDF仍 **NOT_COMPLETED**，无功率板测/R5现场连续采集、外部六路PWM及完整实机运动仍 **NOT_RUN**。新阶段以 [AQM30-B2实机集成路线图（Draft PR43）](https://github.com/kazecode666/AXU5EV/pull/43)、[Issue42](https://github.com/kazecode666/AXU5EV/issues/42) Task1→Task2→Task3 和 [Issue44](https://github.com/kazecode666/AXU5EV/issues/44) 的跨帧时序评估为执行入口。此变更仅为规划与交接，**没有启动开发/板测，不得自动合并或上电**。下文2026-11-13旧合并决策及旧分支描述属于历史；技术验收矩阵和局部SDF边界仍有效。

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

- **仓库与新任务基线：** `kazecode666/AXU5EV` 的 `main`（已包含[合并PR41](https://github.com/kazecode666/AXU5EV/pull/41)）；`codex/motor-control-chain` 是原历史实施分支。当前新任务/规划见[Issue42](https://github.com/kazecode666/AXU5EV/issues/42)、[Draft PR43](https://github.com/kazecode666/AXU5EV/pull/43)、[Issue44](https://github.com/kazecode666/AXU5EV/issues/44)。
- **已冻结的实施产物：** `.runtime/motor_control/hardware_02`的bit/ltx/XSA及已布线DCP；`.runtime/motor_control/vitis_01`的R5应用/平台/FSBL。服务器未修改生产RTL、Simulink模型、XDC或这些实施产物。
- **最终局部SDF证据：** [统一报告](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/RESULT_REPORT.md)、[物理极性证明](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/POLARITY_PROOF.md)、[最终Testbench](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/v2/pwm_cut_tb.sv)。`auto_inhibit`在RTL为高电平禁止，但该cut的物理边界承载`permission=!logical_inhibit`；反相关系**只在局部TB接口适配**，不能据此反转生产RTL接口。
- **局部SDF动态覆盖：** 每角756022次检查、11次请求/接受、8次谷值采用/回执、3次取消/重臂、三次Anchor启动、死区最小1000ns；slow/fast均实际完成，SDF注释确认且无真实时序异常。边界源延迟0.2ns是仿真假设，不是完整跨层实测延迟。
- **物理边界：** `physical_link_verified=0`，六路PWM尚非经过验证的外部驱动器接口；`fast_inhibit`在当前BD固定接0，独立动态覆盖N/A。48V为数字测试参考，不是实测母线。

## 三、新阶段任务与停止点（2026-11-17，仅规划，不自动执行）

当前：**停止旧的完整功能PL动态SDF编译/参数搜索长跑**，不重跑已通过的整链RTL/STA/PWM局部两角SDF。不把PR41已合并视为实体接口板测完成。

1. **首先执行 Issue42 Task1：** 复用DSP旧采集换算/编码器子系统到现有共享Simulink组件及代码生成边界；保护本地用户文件，只验证受影响数字链；**不修改AQM参数、驱动IO或R5运行调度**。交单独Draft PR待Review。
2. **然后分别执行 Issue42 Task2、Task3：** 恢复AQM30-B2参数和PI候选并真正更新受影响生成C/HDL；复用驱动IO/行程管理、将J16最终PCB定义转为待板测端口/XDC。不得覆盖PR41冻结证据或把新实现标成已上板。
3. **可并行只读执行 Issue44：** 确认完整快照名义P2508发布与旧AX-02C2 Runtime耗时是否能满足新跨帧参考合同；只输出评估/建议，不提前修改生产控制代码。随后Review方案再做R5 Runtime/原五态对齐集成、闭环仿真与实验日志。
4. **未来现场阶段：** 接口板完成电气核对、取得现场安全条件及用户逐项明确授权后，再使用[无功率板测指南](../firmware/r5/motor_control/FIRST_RUN_ZH.md)和**与新实现匹配**的 bit/ltx/XSA/ELF 验证真实链路。旧指南中的PR41冻结候选不能被当成新AQM候选；先无功率，后再考虑受控上电/运动。

详见[路线图所在Draft PR43](https://github.com/kazecode666/AXU5EV/pull/43)。各Task的源码/生成/仿真/布局布线/板测状态分别以实际PR及日志为准，不自动合并或关闭Issue。

## 四、历史索引（保留原始证据，不作为现行指令）

- [局部SDF第一轮](../verification/motor_control/evidence/pwm_cut_windows_20261113_01/README.md)：边界anchor保持时间违例、未完成。
- [局部SDF第二轮](../verification/motor_control/evidence/pwm_cut_windows_20261113_02/README.md)：源握手TB断言失败、未完成。
- [局部SDF第三轮](../verification/motor_control/evidence/pwm_cut_windows_20261113_03/README.md)：切点许可极性疑点硬停止。
- [第四轮最终证明及两角PASS](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/RESULT_REPORT.md)。
- [全量SDF历史记录](../verification/motor_control/evidence/full_sdf_20261110/README.md)、[编译工具故障报告](https://github.com/kazecode666/AXU5EV/pull/41#issuecomment-6801862540)、[24小时超时回执](https://github.com/kazecode666/AXU5EV/pull/41#issuecomment-6844442026)。
- 更早的执行计划和过程保留在PR41讨论、Issue40评论及Git提交历史，不再以重复的“当前/待运行”标题放入本页。

**文档规范：** 现行交接与验收仅采用PR/Issue、分支、相对路径、工具实际日志及结果状态；不新增文件摘要/校验任务或冗长提交标识。
