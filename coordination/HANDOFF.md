# AXU5EV 当前交接 — AX-04B R1 复审候选

2026-11-19，按 PR48 复审任务在原 `codex/ax04b-hardware-binding` 纳入已保存的实机模型 1.173、初始化参数与白盒说明 `bcbb1bca750636494f211cffa710891aff1e5f34`。新生成源 `generated/experiment/ax04b_r1_01/r5` 提交 `9f5cbb606dc41216e7e69d590496866eb6659fc5`，由该模型生成 Cortex-R ERT。317 项、275136 次 IRQ 的既有主机验证以及 Switch 和 PI_Reset 阈值直测通过。[Draft PR48](https://github.com/kazecode666/AXU5EV/pull/48) · [复审报告](reports/ax04b_hardware_binding.md)

- `b411733a2ee69331c132d914c885842c2b88b822` 修复 PL 停止后 R5 的对齐许可，`c6a2539bf86e5f5deaa51b0560dd342f15c61e13` 作废 STOP 前排队的 CLEAR。用同一份 1.173 生成 C 复现了三个旧反例，最终 12 个定向场景通过。运行许可撤销时立即停止 PL，必要时同一帧执行一次独立安全调用。显式 CLEAR 及 ARM 均有 PL 读回，重新对齐需要新的 Start。
- 当前 SELFTEST／REAL 候选分别为 `.runtime/experiment/ax04b/selftest_r1_02` 和 `.runtime/experiment/ax04b/real_r1_02`，应用身份 `0x41585203`。各自使用原 `*_02` 的匹配 PL 成果与新 R5 ELF。此次未重新构建 Vivado。两个候选的实际 ARM 执行、IRQ 实测时延、板内 SELFTEST、真实 IO 和功率运动均为 `NOT_RUN`。[无功率首运行指南](../firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md) · [验证状态](../verification/experiment/ax04b/results.json)

## 原 B1～B4 离线候选记录

2026-11-19，从合并 PR47 的完整 main `21847326e4e0d8e100f3aaa5f31b612f24f75e01` 建立 `codex/ax04b-hardware-binding`。PR46 经 PR45 分支再由 PR47 带入主线。本轮完成 B1～B4 并停在 [kazecode666/AXU5EV Draft PR48](https://github.com/kazecode666/AXU5EV/pull/48) Review。执行依据为 [PR47 任务书](tasks/ax04b_hardware_binding_and_first_run.md)、[Issue42 执行评论](https://github.com/kazecode666/AXU5EV/issues/42#issuecomment-6974714393)及 [Issue44 执行评论](https://github.com/kazecode666/AXU5EV/issues/44#issuecomment-6974720049)。

- B1 `a3817c7` 实现冻结反馈、高电平 IRQ、精确 ACK 和下一 P0 原子参考。B2 `7d821b4` 接实际实机 HDL、固定角/偏置及独立禁止。B3 `a05ba41` 将真实 GIC/MMIO 调度接入 PR46 v1.95 ERT。B4 `43d176589465e3dd296cbee8d8736cc9a77fddc6` 完成两套构建、XDC 确认和启动检查。[完整报告](reports/ax04b_hardware_binding.md)
- AXI 定向 866 项通过。链路 RTL 仿真实测 P76 早期 IRQ、P110 会合、P127 冻结、P443 结果、P2500 PWM 谷值采用、P2504 回传。SELFTEST/REAL 定向刺激均验证无效帧调度、固定/偏置切换和快速停止。
- `.runtime/experiment/ax04b/selftest_02` 与 `.runtime/experiment/ax04b/real_02` 各有匹配 bit/ltx/XSA/ELF。布线 STA 的 WNS/WHS 分别为 +0.355/+0.005 ns 与 +0.986/+0.011 ns，TNS/THS 均为 0。REAL 16 个 J16 引脚的最终设计核对通过。实际 Cortex-R5 裸机启动检查从各自 XSA/BSP/ELF 核对 `0x80002000`、GIC 121 高电平和 16 KiB IRQ 栈。[精简证据](../verification/experiment/ax04b/results.json)
- [唯一无功率首运行指南](../firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md)列出 `ax04b_realtime_manual` 及成套候选。ARM 执行、板内 SELFTEST、REAL 外部 IO、功率运动和实际中断预算均为 `NOT_RUN`。本次只做离线工作。原 PR41 候选、现有模型布局、未提交用户修改和全部数据继续保留。

## PR46 Review 修订历史

2026-11-17，继续 `kazecode666/AXU5EV` 同一 [Draft PR46](https://github.com/kazecode666/AXU5EV/pull/46) 的Task1～Task4。分支 `codex/ax04-experiment-model`、base `codex/issue42-task1-dsp-reuse`，保持Draft等待Review。

- 功能提交 `8f91bc7` 修复对齐许可、持续Start消费和RAMP_DOWN末拍安全优先级，新帧推进与安全处理分离。补充提交 `2a9692d` 统一既有PI_Reset非零语义。
- 来源提交 `6e28ebb` 将反馈/驱动/行程三实例固化于主模型实际使用位置，完整逐采样函数及Host局部调用链可直接查看。七份旧helper逐文件迁入tests/oracles，旧R5库及用户本地修改保留。
- 呈现提交 `75b7bde` 整理ISR与反馈内部，保留用户顶层34块位置和对齐五态原位置及连线路径。Stateflow对默认入口中点、标签及旁注产生几像素归一化差异，已记录具体范围。
- 最终主模型及C版本1.95，844块边界检查与端口/连线/Stateflow检查通过。ERT导出15份C/H，实际5份C经主机MEX完成317项检查、275136次IRQ调用，其中42项安全检查、227186次调用零失败。旧7项反例和PI_Reset=0.25反例均先由原候选实际复现。
- 双入口两种打开顺序通过，17项活动来源、7项退役helper、75参数/模型及6项Signal保存重开通过。原10份其余用户模型/参数修改和全部原始数据保留在工作树。
- 最终C/H位于 `generated/experiment/pr46_review_01/r5_final_03`，精简结果及8份图见 [本轮证据](../verification/experiment/pr46_review_01/results.json)，详细R1—R5位置与截图见[报告修订节](reports/ax04_experiment_model_and_layout.md#pr46-review修订--对齐安全就地编辑与呈现)。运行缓存及中间失败候选保留于 `.runtime/experiment/pr46_review_01`。
- `HW_BINDING_PENDING`、`BOARD_NOT_RUN`。IRQ/GIC、原子AXI、驱动电气、服务快照抢占一致性及匹配bit/XSA/ELF待交付B，ARM执行为NOT_RUN。PL沿用原候选，本轮无新HDL/Vivado/SDF或板卡操作，Issue44保持独立工作线。

## AX-04 交付A历史交接

2026-11-17，`kazecode666/AXU5EV` 的独立实机模型、simulation双入口及实际C/HDL生成已完成交付A，已发布 [Draft PR46](https://github.com/kazecode666/AXU5EV/pull/46)。分支 `codex/ax04-experiment-model` 基于未合并PR45的最新head `a7a5670350e94dc5e94db0562f34d4f8213e32c8`，PR46以 `codex/issue42-task1-dsp-reuse` 为base，停在Review。

- 目录与入口提交 `a223973`、等价源复制 `9c5fb4b`、B2参数及实机入口适配 `4c72c05`。85项路径映射见[旧新路径](reports/ax04_path_map.csv)。
- 纯仿真从 `simulation/START_SIMULATION.m` 进入，实机从 `simulation/START_EXPERIMENT.m` 进入。实机算法、参数、自定义函数及生成入口独立，当前主模型包含真实初始化、外部PL_Frame_IRQ、Qualified_Runtime、驱动行程及非实时服务。
- 主模型编译/589块边界检查、根层连线/端口/Stateflow检查通过。生成15份C/H，实际C经主机transport-only MEX通过90项检查与47762次IRQ调用，其中完整对齐42130次、行程5490次。
- 独立PL四边界实际生成51份SV，保留18项p3流水线配置。FOC模型1188帧通过，192帧RTL与48帧动态前馈RTL合计720项duty检查零差，相位314拍。辅助gm输出延时插入有警告，其gm等价验证为NOT_RUN。
- 双入口2种打开顺序、各24项which-all、75参数/模型和6项Signal磁盘重开通过，base碰撞哨兵保留。纯仿真model_fixed短检查为20ms、201帧。
- [实施报告](reports/ax04_experiment_model_and_layout.md)、[聚合结果](../verification/experiment/model_layout/results.json)、[依赖来源](../verification/experiment/model_layout/dependencies.json)包含实际范围和截图索引。新C/H位于 `generated/experiment/ax04_01/r5_02`，新SV位于 `generated/experiment/ax04_01/pl`。原始结果及失败检查点保留在 `.runtime/experiment/ax04_01`。
- 原9项用户模型/参数修改和未跟踪数据继续保留，旧数字链壳正确更名到tests。PR41冻结成果、原始数据及历史Workspace原位保留。
- `HW_BINDING_PENDING`、`BOARD_NOT_RUN`。物理IRQ/AXI/驱动绑定、可抢占服务快照、匹配bit/XSA/ELF、物理标定和总运动质量留待交付B及后续授权。ARM执行、综合/实现/STA/CDC/SDF均NOT_RUN。Issue44代码保持独立工作线。

## PR45 Task1历史交接

下面保留PR45与PR41阶段记录。较早simulation路径通过上面的85项映射追溯，当前双入口以本页首节为准。

# AXU5EV 当前交接 — Issue42 Task1

2026-11-17，基于含已合并PR41的main e36e358，工作分支 `codex/issue42-task1-dsp-reuse`。Task1共享反馈组件复用及受影响生成/离线验证完成，已发布 [kazecode666/AXU5EV Draft PR45](https://github.com/kazecode666/AXU5EV/pull/45)，关联Issue42，等待Review。

实施提交 `4852f1b676478aeaf76f8d28888fc9c0591bf9ff`，映射与证据提交 `9bcdb75d29de915f2889543effcf63d6889d14a1`。原PR41冻结交付继续保留，Issue42保持开放。

- 已实际读取DSP原模型和AQM备份，复用可见校准、两相电流、位置/50间隔测速及电角定点路径。统一模型的R5支路和新C生成壳链接同一组件。
- 电流49向量×14输出及RTL25项通过，电角46向量/RTL460项通过。R5模型与目标C均1493帧×7零差。统一模型55帧×18与PR41存档帧表零差。
- [Task1报告](reports/task1_dsp_reuse.md)、[旧DSP映射](reports/task1_dsp_component_map.csv)、[新候选结果](../verification/dsp_reuse/results.json)。统一MATLAB入口 `simulation/task1_dsp_reuse.m`，新生成源 `generated/dsp_reuse`。
- 原9项用户修改和未跟踪数据保留，编辑的共享PL库保留既有排版，其编辑前副本在 `.runtime/dsp_reuse/user_preserved`。其余用户模型及参数文件保持起始内容。
- 两份HDL生成各有1条复用优化警告。新综合/实现/STA/CDC/SDF、板卡与功率均NOT_RUN。Task2、Task3及Issue44代码保持各自边界。

## PR41签收历史入口

PR41已于2026-11-16合并。以下原文保留历史验收证据及其当时Review措辞，当前Task1以本页首节及新报告为准。

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
