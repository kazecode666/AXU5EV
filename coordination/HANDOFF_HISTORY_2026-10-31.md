# AXU5EV 历史交接与阶段记录

本页归档旧阶段进度、验收结论和会话背景。当前交接见 [HANDOFF.md](HANDOFF.md)，稳定规则见 [AGENTS.md](../AGENTS.md)。归档内的部署步骤、到期授权、Review 状态、PID 与关机要求仅作历史追溯。

## 2026-11-21 入口整理前的历史快照

来源为 Issue #50 起始 main 中的 HANDOFF、README 和 AGENTS 阶段记录。下文保留各阶段原结论、当时状态及证据入口。PR46 成果通过 PR47 进入主线，PR48 与 PR49 后续均已合并。

### 原 HANDOFF

#### AXU5EV 当前交接 — AX-04B R1 复审候选

2026-11-19，按 PR48 复审任务在原 `codex/ax04b-hardware-binding` 纳入已保存的实机模型 1.173、初始化参数与白盒说明 `bcbb1bca750636494f211cffa710891aff1e5f34`。新生成源 `generated/experiment/ax04b_r1_01/r5` 提交 `9f5cbb606dc41216e7e69d590496866eb6659fc5`，由该模型生成 Cortex-R ERT。317 项、275136 次 IRQ 的既有主机验证以及 Switch 和 PI_Reset 阈值直测通过。[Draft PR48](https://github.com/kazecode666/AXU5EV/pull/48) · [复审报告](reports/ax04b_hardware_binding.md)

- `b411733a2ee69331c132d914c885842c2b88b822` 修复 PL 停止后 R5 的对齐许可，`c6a2539bf86e5f5deaa51b0560dd342f15c61e13` 作废 STOP 前排队的 CLEAR。用同一份 1.173 生成 C 复现了三个旧反例，最终 12 个定向场景通过。运行许可撤销时立即停止 PL，必要时同一帧执行一次独立安全调用。显式 CLEAR 及 ARM 均有 PL 读回，重新对齐需要新的 Start。
- 当前 SELFTEST／REAL 候选分别为 `.runtime/experiment/ax04b/selftest_r1_02` 和 `.runtime/experiment/ax04b/real_r1_02`，应用身份 `0x41585203`。各自使用原 `*_02` 的匹配 PL 成果与新 R5 ELF。此次未重新构建 Vivado。两个候选的实际 ARM 执行、IRQ 实测时延、板内 SELFTEST、真实 IO 和功率运动均为 `NOT_RUN`。[无功率首运行指南](../firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md) · [验证状态](../verification/experiment/ax04b/results.json)

#### 原 B1～B4 离线候选记录

2026-11-19，从合并 PR47 的完整 main `21847326e4e0d8e100f3aaa5f31b612f24f75e01` 建立 `codex/ax04b-hardware-binding`。PR46 经 PR45 分支再由 PR47 带入主线。本轮完成 B1～B4 并停在 [kazecode666/AXU5EV Draft PR48](https://github.com/kazecode666/AXU5EV/pull/48) Review。执行依据为 [PR47 任务书](tasks/ax04b_hardware_binding_and_first_run.md)、[Issue42 执行评论](https://github.com/kazecode666/AXU5EV/issues/42#issuecomment-6974714393)及 [Issue44 执行评论](https://github.com/kazecode666/AXU5EV/issues/44#issuecomment-6974720049)。

- B1 `a3817c7` 实现冻结反馈、高电平 IRQ、精确 ACK 和下一 P0 原子参考。B2 `7d821b4` 接实际实机 HDL、固定角/偏置及独立禁止。B3 `a05ba41` 将真实 GIC/MMIO 调度接入 PR46 v1.95 ERT。B4 `43d176589465e3dd296cbee8d8736cc9a77fddc6` 完成两套构建、XDC 确认和启动检查。[完整报告](reports/ax04b_hardware_binding.md)
- AXI 定向 866 项通过。链路 RTL 仿真实测 P76 早期 IRQ、P110 会合、P127 冻结、P443 结果、P2500 PWM 谷值采用、P2504 回传。SELFTEST/REAL 定向刺激均验证无效帧调度、固定/偏置切换和快速停止。
- `.runtime/experiment/ax04b/selftest_02` 与 `.runtime/experiment/ax04b/real_02` 各有匹配 bit/ltx/XSA/ELF。布线 STA 的 WNS/WHS 分别为 +0.355/+0.005 ns 与 +0.986/+0.011 ns，TNS/THS 均为 0。REAL 16 个 J16 引脚的最终设计核对通过。实际 Cortex-R5 裸机启动检查从各自 XSA/BSP/ELF 核对 `0x80002000`、GIC 121 高电平和 16 KiB IRQ 栈。[精简证据](../verification/experiment/ax04b/results.json)
- [唯一无功率首运行指南](../firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md)列出 `ax04b_realtime_manual` 及成套候选。ARM 执行、板内 SELFTEST、REAL 外部 IO、功率运动和实际中断预算均为 `NOT_RUN`。本次只做离线工作。原 PR41 候选、现有模型布局、未提交用户修改和全部数据继续保留。

#### PR46 Review 修订历史

2026-11-17，继续 `kazecode666/AXU5EV` 同一 [Draft PR46](https://github.com/kazecode666/AXU5EV/pull/46) 的Task1～Task4。分支 `codex/ax04-experiment-model`、base `codex/issue42-task1-dsp-reuse`，保持Draft等待Review。

- 功能提交 `8f91bc7` 修复对齐许可、持续Start消费和RAMP_DOWN末拍安全优先级，新帧推进与安全处理分离。补充提交 `2a9692d` 统一既有PI_Reset非零语义。
- 来源提交 `6e28ebb` 将反馈/驱动/行程三实例固化于主模型实际使用位置，完整逐采样函数及Host局部调用链可直接查看。七份旧helper逐文件迁入tests/oracles，旧R5库及用户本地修改保留。
- 呈现提交 `75b7bde` 整理ISR与反馈内部，保留用户顶层34块位置和对齐五态原位置及连线路径。Stateflow对默认入口中点、标签及旁注产生几像素归一化差异，已记录具体范围。
- 最终主模型及C版本1.95，844块边界检查与端口/连线/Stateflow检查通过。ERT导出15份C/H，实际5份C经主机MEX完成317项检查、275136次IRQ调用，其中42项安全检查、227186次调用零失败。旧7项反例和PI_Reset=0.25反例均先由原候选实际复现。
- 双入口两种打开顺序通过，17项活动来源、7项退役helper、75参数/模型及6项Signal保存重开通过。原10份其余用户模型/参数修改和全部原始数据保留在工作树。
- 最终C/H位于 `generated/experiment/pr46_review_01/r5_final_03`，精简结果及8份图见 [本轮证据](../verification/experiment/pr46_review_01/results.json)，详细R1—R5位置与截图见[报告修订节](reports/ax04_experiment_model_and_layout.md#pr46-review修订--对齐安全就地编辑与呈现)。运行缓存及中间失败候选保留于 `.runtime/experiment/pr46_review_01`。
- `HW_BINDING_PENDING`、`BOARD_NOT_RUN`。IRQ/GIC、原子AXI、驱动电气、服务快照抢占一致性及匹配bit/XSA/ELF待交付B，ARM执行为NOT_RUN。PL沿用原候选，本轮无新HDL/Vivado/SDF或板卡操作，Issue44保持独立工作线。

#### AX-04 交付A历史交接

2026-11-17，`kazecode666/AXU5EV` 的独立实机模型、simulation双入口及实际C/HDL生成已完成交付A，已发布 [Draft PR46](https://github.com/kazecode666/AXU5EV/pull/46)。分支 `codex/ax04-experiment-model` 基于未合并PR45的最新head `a7a5670350e94dc5e94db0562f34d4f8213e32c8`，PR46以 `codex/issue42-task1-dsp-reuse` 为base，停在Review。

- 目录与入口提交 `a223973`、等价源复制 `9c5fb4b`、B2参数及实机入口适配 `4c72c05`。85项路径映射见[旧新路径](reports/ax04_path_map.csv)。
- 纯仿真从 `simulation/START_SIMULATION.m` 进入，实机从 `simulation/START_EXPERIMENT.m` 进入。实机算法、参数、自定义函数及生成入口独立，当前主模型包含真实初始化、外部PL_Frame_IRQ、Qualified_Runtime、驱动行程及非实时服务。
- 主模型编译/589块边界检查、根层连线/端口/Stateflow检查通过。生成15份C/H，实际C经主机transport-only MEX通过90项检查与47762次IRQ调用，其中完整对齐42130次、行程5490次。
- 独立PL四边界实际生成51份SV，保留18项p3流水线配置。FOC模型1188帧通过，192帧RTL与48帧动态前馈RTL合计720项duty检查零差，相位314拍。辅助gm输出延时插入有警告，其gm等价验证为NOT_RUN。
- 双入口2种打开顺序、各24项which-all、75参数/模型和6项Signal磁盘重开通过，base碰撞哨兵保留。纯仿真model_fixed短检查为20ms、201帧。
- [实施报告](reports/ax04_experiment_model_and_layout.md)、[聚合结果](../verification/experiment/model_layout/results.json)、[依赖来源](../verification/experiment/model_layout/dependencies.json)包含实际范围和截图索引。新C/H位于 `generated/experiment/ax04_01/r5_02`，新SV位于 `generated/experiment/ax04_01/pl`。原始结果及失败检查点保留在 `.runtime/experiment/ax04_01`。
- 原9项用户模型/参数修改和未跟踪数据继续保留，旧数字链壳正确更名到tests。PR41冻结成果、原始数据及历史Workspace原位保留。
- `HW_BINDING_PENDING`、`BOARD_NOT_RUN`。物理IRQ/AXI/驱动绑定、可抢占服务快照、匹配bit/XSA/ELF、物理标定和总运动质量留待交付B及后续授权。ARM执行、综合/实现/STA/CDC/SDF均NOT_RUN。Issue44代码保持独立工作线。

#### PR45 Task1历史交接

下面保留PR45与PR41阶段记录。较早simulation路径通过上面的85项映射追溯，当前双入口以本页首节为准。

#### AXU5EV 当前交接 — Issue42 Task1

2026-11-17，基于含已合并PR41的main e36e358，工作分支 `codex/issue42-task1-dsp-reuse`。Task1共享反馈组件复用及受影响生成/离线验证完成，已发布 [kazecode666/AXU5EV Draft PR45](https://github.com/kazecode666/AXU5EV/pull/45)，关联Issue42，等待Review。

实施提交 `4852f1b676478aeaf76f8d28888fc9c0591bf9ff`，映射与证据提交 `9bcdb75d29de915f2889543effcf63d6889d14a1`。原PR41冻结交付继续保留，Issue42保持开放。

- 已实际读取DSP原模型和AQM备份，复用可见校准、两相电流、位置/50间隔测速及电角定点路径。统一模型的R5支路和新C生成壳链接同一组件。
- 电流49向量×14输出及RTL25项通过，电角46向量/RTL460项通过。R5模型与目标C均1493帧×7零差。统一模型55帧×18与PR41存档帧表零差。
- [Task1报告](reports/task1_dsp_reuse.md)、[旧DSP映射](reports/task1_dsp_component_map.csv)、[新候选结果](../verification/dsp_reuse/results.json)。统一MATLAB入口 `simulation/task1_dsp_reuse.m`，新生成源 `generated/dsp_reuse`。
- 原9项用户修改和未跟踪数据保留，编辑的共享PL库保留既有排版，其编辑前副本在 `.runtime/dsp_reuse/user_preserved`。其余用户模型及参数文件保持起始内容。
- 两份HDL生成各有1条复用优化警告。新综合/实现/STA/CDC/SDF、板卡与功率均NOT_RUN。Task2、Task3及Issue44代码保持各自边界。

#### PR41签收历史入口

PR41已于2026-11-16合并。以下原文保留历史验收证据及其当时Review措辞，当前Task1以本页首节及新报告为准。

#### AXU5EV — 当前交接（PR41 / Issue40）

> **现行状态入口，更新于2026-11-13。** 以本页与 [聚合验收状态](../verification/motor_control/results.json) 为准；较早的评论、说明和仿真日志用于追溯历史，不再构成新任务指令。PR41保持Draft，Issue40开放；是否接受全链动态SDF缺项并合并，由用户决定。

#### 一、现阶段统一结论

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

#### 二、当前唯一有效的技术基线

- **仓库与工作分支：** `kazecode666/AXU5EV`，`codex/motor-control-chain`；[Draft PR41](https://github.com/kazecode666/AXU5EV/pull/41)、[Issue40](https://github.com/kazecode666/AXU5EV/issues/40)。
- **已冻结的实施产物：** `.runtime/motor_control/hardware_02`的bit/ltx/XSA及已布线DCP；`.runtime/motor_control/vitis_01`的R5应用/平台/FSBL。服务器未修改生产RTL、Simulink模型、XDC或这些实施产物。
- **最终局部SDF证据：** [统一报告](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/RESULT_REPORT.md)、[物理极性证明](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/POLARITY_PROOF.md)、[最终Testbench](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/v2/pwm_cut_tb.sv)。`auto_inhibit`在RTL为高电平禁止，但该cut的物理边界承载`permission=!logical_inhibit`；反相关系**只在局部TB接口适配**，不能据此反转生产RTL接口。
- **局部SDF动态覆盖：** 每角756022次检查、11次请求/接受、8次谷值采用/回执、3次取消/重臂、三次Anchor启动、死区最小1000ns；slow/fast均实际完成，SDF注释确认且无真实时序异常。边界源延迟0.2ns是仿真假设，不是完整跨层实测延迟。
- **物理边界：** `physical_link_verified=0`，六路PWM尚非经过验证的外部驱动器接口；`fast_inhibit`在当前BD固定接0，独立动态覆盖N/A。48V为数字测试参考，不是实测母线。

#### 三、接下来怎么做（本页只提供决策，不自动授权）

**当前：停止额外的服务器SDF诊断或长时间全量编译。** 已完成的PWM局部两角工作线收口，原失败和中断日志保留，不重跑已完成的模型/RTL/STA。

1. **本地Codex：** 更新本地工作副本前先确认分支和未提交变更，安全同步远程PR41的现行内容。不得自动强制覆盖、清理、暂存用户文件。核对PR正文、聚合结果和本页一致；无需重新运行Vivado/XSim或重新打包。
2. **用户决策：** 按“数字链已离线验证 + PWM局部SDF两角PASS + 完整设计STA PASS + 完整链动态SDF延期 + 板测未执行”的限定范围，决定是否允许PR41进入合并审查。没有用户授权不得自动合并、关闭Issue或把NOT_COMPLETED改PASS。
3. **未来现场阶段（另行授权）：** 使用[无功率板测手册](../firmware/r5/motor_control/FIRST_RUN_ZH.md)核对bit/ltx/XSA/ELF、UART、ILA和80字快照，再执行默认禁止、ADC校准、同帧反馈与采集连续性、参考采用、编码器、禁止/重臂。现场操作和功率级测试都不是本轮任务。
4. **更后续：** R5完整运动控制Runtime、外环及初始化对齐按独立任务开展；AQM参数/编码器尺度与电流PI基线复核不混入本次验收收尾。

#### 四、历史索引（保留原始证据，不作为现行指令）

- [局部SDF第一轮](../verification/motor_control/evidence/pwm_cut_windows_20261113_01/README.md)：边界anchor保持时间违例、未完成。
- [局部SDF第二轮](../verification/motor_control/evidence/pwm_cut_windows_20261113_02/README.md)：源握手TB断言失败、未完成。
- [局部SDF第三轮](../verification/motor_control/evidence/pwm_cut_windows_20261113_03/README.md)：切点许可极性疑点硬停止。
- [第四轮最终证明及两角PASS](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/RESULT_REPORT.md)。
- [全量SDF历史记录](../verification/motor_control/evidence/full_sdf_20261110/README.md)、[编译工具故障报告](https://github.com/kazecode666/AXU5EV/pull/41#issuecomment-6801862540)、[24小时超时回执](https://github.com/kazecode666/AXU5EV/pull/41#issuecomment-6844442026)。
- 更早的执行计划和过程保留在PR41讨论、Issue40评论及Git提交历史，不再以重复的“当前/待运行”标题放入本页。

**文档规范：** 现行交接与验收仅采用PR/Issue、分支、相对路径、工具实际日志及结果状态；不新增文件摘要/校验任务或冗长提交标识。

### 原 README

#### AXU5EV — R5F/PL 永磁直线电机研究平台

> Issue40 当前入口：在包含PR39的main基线上整合原ADC/QEP→模型生成电流/电角度→原FOC→原PWM自动通路。统一数值模型为 `simulation/motor_control/AXU5EV_Motor_Control_System.slx`，用 `motor_control_run(新结果目录)` 安全运行；见[模型入口](../simulation/tests/digital_chain/motor_control_README.md)、[同一个PL工程](../hardware/axu5ev/motor_control/README.md)、[简短操作说明](../firmware/r5/motor_control/FIRST_RUN_ZH.md)与[当前交接](../coordination/HANDOFF.md)。R5保留位置/测速及预提交参考；完整外环/Runtime/自动对齐未接入，板卡操作NOT_RUN。以下旧阶段“当前”及关机措辞为历史。

> 当前PR24：perf_r1已由用户单次完整实板PASS，64536条Runtime数值、193608个duty位串、帧/序号及完整停止通过，身份0x43324302。实际提交窗口最大86.017us，计入COMMIT后328B日志的完整软件窗口最大95.617us；不宣称WCET或同帧50us签核。[实板证据](../verification/ax02c2/board_perf_r1_01/README.md)、[耗时及原失败对照](../coordination/reports/ax02c2_runtime_pl_replay.md)、[唯一指南](../firmware/r5/ax02c2/FIRST_EXPERIMENT_ZH.md)已更新。原数据/Workspace保留，本轮只归档，无构建或板卡操作；等待用户最终Review，不自动合并。以下候选NOT_RUN与关机交接均为历史。

> 最新交付：[AX-02C2 Draft PR24](https://github.com/kazecode666/AXU5EV/pull/24)已提交推送，必要离线验证与目标构建PASS。按用户最新“完成离线实现后关闭计算机”要求，本轮不执行新板测，BOARD_NOT_RUN，交接后正常关机；后续从[唯一指南](../firmware/r5/ax02c2/FIRST_EXPERIMENT_ZH.md)继续，等待Review、不自动合并。

> 当前AX-02C2：[PR22](https://github.com/kazecode666/AXU5EV/pull/22)已合并并签收C1一次实板结果，不再复现。Issue23的真实R5 Runtime＋原模型薄适配＋AXI/PL连续回放已离线实现，64536条同源记录及必要适配对照、原生构建/启动检查PASS；复用hardware_02，不重跑RTL/ETH02。新Workspace`.runtime/ax02c2/vitis_runtime_pl_native64`，Launch`ax02c2_runtime_manual`，新板测NOT_RUN，先Draft PR待Review。见[主报告](../coordination/reports/ax02c2_runtime_pl_replay.md)及[唯一指南](../firmware/r5/ax02c2/FIRST_EXPERIMENT_ZH.md)。以下旧阶段“当前/待Review”等按历史理解。

> 当前AX-02C1：原hardware_01的低有效AUX复位接零导致START后挂起，已最小修复并独立构建hardware_02。经用户授权在线验证，首个MMIO返回正确ID，唯一一次17帧/51个duty逐位一致、完整帧数17，BOARD_PASS；结束后R5可正常暂停，XSDB已断开。[Draft PR22](https://github.com/kazecode666/AXU5EV/pull/22)等待Review。原Workspace/ELF/FSBL及旧工程保留；使用新bit，见[主报告](../coordination/reports/ax02c1_r5_axi_foc.md)、[实板证据](../verification/ax02c/board_aux_fixed_01/evidence.json)与[用户唯一指南](../firmware/r5/ax02c/FIRST_BOARD_RUN_ZH.md)。以下AX-02B/ETH02待Review等文字均为历史记录。

> 2026-11-03 当前：PR18已合并，AX-02B独立5EV生成及必要位/帧检查PASS，OOC综合/布局布线及内部STA PASS（理想时钟边界，WNS+3.020ns、WHS+0.034ns）。 已提交[Draft PR20](https://github.com/kazecode666/AXU5EV/pull/20)待Review；详见[AX-02B主报告](../coordination/reports/ax02b_pl_current_core.md)。下文旧阶段待Review/待上板文字按历史理解。

> 2026-11-03最新：PR18评论6596653379所述两场景现已用户实板PASS，待最终Review。精简证据：verification/ethernet/eth02/board_results，当前状态：verification/ethernet/eth02/status.json。两个01结果目录已占用，无需重跑；Workspace/Launch不变。本轮仅归档，不新增测试、构建或上板。下文NOT_RUN及待用户执行均为此前准备阶段记录。

**当前：ETH-02离线实现/构建及现有启动检查通过，待新Draft PR Review。** PR17已合并，新应用整合真实文件上传、停网执行原100µs Runtime、恢复网络下载与原分析器，提供MATLAB `RUN_ETH02`入口。新Workspace/Launch及用户两次实验见[唯一指南](../firmware/r5/ethernet_runtime/FIRST_EXPERIMENT_ZH.md)；两次整合板测NOT_RUN。原R1、ETH01 r3和全部既有数据保留，下条待Review状态按历史阶段理解。

**已合并基线：ETH-01用户实板PASS。** r3已完成JL2121千兆全双工链路、TCP小数据、生成模型往返及64KiB/1MiB/32MiB完整性板测；32MiB上传/下载0.990/1.412MiB/s，上传未达1MiB/s目标，未做优化。见[实板精简证据](../verification/ethernet/eth01/board_r3/README.md)、[复用与实现报告](../coordination/reports/eth01_platform_and_soc_reuse.md)、[阶段状态](../verification/ethernet/eth01/status.json)和[用户上板唯一入口](../firmware/r5/ethernet/FIRST_BOARD_RUN_ZH.md)。原始大文件与R1均保留；其余限制按原PR阶段理解。以下AX-02A记录按历史阶段理解，不重复既有板测。

**2026-11-02：两个完整R1场景真实数值/100µs时序/板报交叉已PASS。** [统计与A4/A5逐条审计](../coordination/reports/ax02a_full_board_results_2026-11-02.md)。仍有冷启动条件及分阶段验收口径待Review，不等同整项验收完成；以下操作准备状态按原阶段理解。

**当前优先：[Issue #15](https://github.com/kazecode666/AXU5EV/issues/15)，AX-02A真实R5目标工程、数值回放与100µs时间验证。目标AXU5EVB-E。** 私有仓库为 [kazecode666/AXU5EV](https://github.com/kazecode666/AXU5EV)，本地根目录 `D:/Project/AXU5EV`。PR #14已合并；完整RTL结果直接复用，不默认重跑。见[AX-02A实际结果与阻塞](../coordination/reports/ax02a_r5_target_validation.md)及[R5构建/回放入口](../firmware/r5/ax02a/README.md)。C源码教学已取消，Issue #11和AX-02B/C不在本轮实施。

**目录与保存位置统一入口：[工作区指南](../docs/WORKSPACE_GUIDE_ZH.md)。当前上板候选为 `.runtime/ax02a/vitis_runtime_100us_r1`，R1 P1000实测已PASS；下一步Review后按[完整场景指南](../firmware/r5/ax02a/FULL_SCENE_RUN_ZH.md)，不重复ABA/C或P1000。**

日常仍从`simulation/START_HERE.m`开始。只读显示给出R5采样Send、同拍Ready/Busy及最近请求时间/结果/计数；Busy=0不保证Ready=1，未Ready拒绝且不排队。Issue #11为后续架构讨论，不在本轮实施。实际鼠标Dashboard操作/刷新仍NOT_RUN；本轮完整RTL三段运动已完成。

本轮完整C/真实RTL同Run `10→0→−2 mm` 已完成：实际RTL 64536帧，三段均满足原Ready，接受3/拒绝1；位置、速度、dq电流、参考及应用duty差均0。见[AX-01C结果与曲线](../coordination/reports/ax01c_simulation_closeout.md)。先前默认点位修复与发送回执分别见[Issue #8原报告](../coordination/reports/issue8_manual_run.md)、[发送报告](../coordination/reports/issue8_send_ready.md)。

[PR #14](https://github.com/kazecode666/AXU5EV/pull/14)已合并（`ae9a11d2d59abc952cce0b979d004a315878639a`）。用户补齐2026.1组件后，手册5EV器件的PS-only XSA、R5 standalone BSP/FSBL及含Runtime的真实ELF/map已构建通过；全采样导出与主机数值证据保持有效。用户BOARD_BOOT/FIRST_WAIT及motion_03首次完整数值已PASS；TTC-only ABA实测已闭合。Runtime R1 P1000数值/时间及板报交叉已PASS，两个完整场景待用户执行，完整A4/A5/WCET未完成；见[构建与验证报告](../coordination/reports/ax02a_r5_target_validation.md)。

#### 目标与分工

以 Simulink/Stateflow 维护算法，重点研究电流控制方法。Cortex-R5F 承担速度/位置控制、原启动对齐、参考/轨迹及运行管理；PL 承担电流控制、同步采样与接口、PWM时序及快速禁止。R5软件由模型生成C，PL算法由HDL Coder生成SystemVerilog；初版采用Windows开发工具环境和单R5F裸机实时核。

旧项目 `kazecode666/FPGA_XC7A200T_Study` 保留为来源和历史验证记录。本项目独立Git历史；迁移采用精选复制，不移动/删除旧工程，也不继承旧M4“所有控制功能必须生成HDL”的交付要求。

#### 项目介绍与实验目标

本项目不是将所有电机控制功能搬进FPGA，而是建立一个便于研究电流控制、并可持续升级运动算法的 **AXU5EVB-E / Cortex-R5F＋PL** 实验平台。以现有位置P—速度PI—电流PI-FOC为基线，保持Simulink为算法来源，逐步贯通功能仿真、代码联合仿真和真实电机实验。

实验重点为：在明确的电机、负载、采样、调制与死区条件下，比较电流跟踪、动态响应、纹波及扰动恢复；同时记录PL资源/计算延迟与R5任务时间。高级外环和运动算法优先在R5侧迭代，不因增加管理功能重新硬件化全部控制器。实验指标是研究方向，不是尚未证明的性能承诺。

开发按 **纯MIL → 面向MPSoC的分区与C/RTL联合仿真 → 硬件部署和实机** 三类模型组织，复用相同算法与参数。最终交付不是一份SLX直接烧板，而是 **R5目标程序ELF＋PL配置bitstream**，通过Vivado导出的XSA与Vitis平台衔接。当前Windows C、MEX与XSI是主机仿真产物，不等于R5已经部署。

完整说明见 **[MPSoC开发流程、工具分工与实验目标](../docs/MPSOC_WORKFLOW_AND_EXPERIMENTS_ZH.md)**。当前日常运行与交互修复以[Issue #8](https://github.com/kazecode666/AXU5EV/issues/8)及[PR #9](https://github.com/kazecode666/AXU5EV/pull/9)为准；该文档不会把未合并修复或板级工作标成已完成。PR9中的单一`simulation/`入口用于后续日常操作，其合并前后的具体状态请看相应PR。

#### 从哪里开始

1. [当前交接](../coordination/HANDOFF.md)和[协作规则](../AGENTS.md)。
   日常仿真直接进入[simulation](../simulation/README_运行说明.md)，编辑`init_AXU5EV.m`，运行`START_HERE.m`，再点击Hybrid的Run。
2. [现有软硬件接口需求](../references/legacy/PMLSM_Hardware_Interface_Map.md)及[板卡事实](../hardware/axu5ev/ALINX_BOARD_FACTS.md)。AX-00任务已完成，仅作历史。
3. [软硬件分工](../docs/ARCHITECTURE.md)、[来源与迁移清单](../docs/MIGRATION_SOURCES.md)。

#### 目录职责

| 目录 | 用途 |
|---|---|
| `simulation/` | 唯一活动模型与日常.m入口：Hybrid、Runtime、Control、FOC、浮点基线及参数/轨迹/构建辅助 |
| `simulink模型/` | 旧初始化的薄转发及用户本地wrapper；不放第二套活动模型/参数定义 |
| `firmware/r5/` | 版本化回放/平台源码、配置与手动指南；当前R1板验待Review后用户执行 |
| `hardware/axu5ev/` | 经板卡版本核对后的Vivado/Vitis平台脚本与硬件清单 |
| `integration/ps_pl/` | 本轮仿真交换字段、事件顺序及后续硬件总线合同 |
| `scripts/`、`verification/` | 可移植构建、必要复验与精简证据 |
| `baselines/pr53_p3/` | 不改字节的八份已验收来源、p3配置与必要证据，默认不加入MATLAB路径 |
| `generated/legacy_m3_p3/` | 原生p3 RTL/TB/data/manifest；是旧器件功能基线，不是5EV时序结果 |
| `references/legacy/` | 精选MIL/DSP/StudyL1资料，仅作来源与研究参考 |
| `references/` | 资料索引；无分发许可的PDF和厂商大包放忽略的`local_only/` |
| `coordination/`、`docs/` | 当前任务、交接、来源和报告 |
| `.runtime/` | 本地workspace、XSA/ELF、生成源、输入/参考与原始板测数据；不入库，不可整体清理 |

只创建真正需要的目录，不放虚假的板级配置或空壳应用。旧Artix引脚、器件约束和通过结论不得直接套给AXU5EV；完整芯片料号、板卡版本和工具配置由本地已有资料确认。

#### 初始里程碑

- **AX-00：** 建立独立仓库、精选资产迁移、移除对旧绝对路径的运行依赖、恢复现有仿真基线。
- **AX-01：** R5侧模型边界/C与SIL、PS—PL接口合同，保留外环/对齐现有语义。
- **AX-02：** 5EV电流核重生成/实现、R5/PL混合闭环及实际处理器时限验证。
- **AX-03：** ADC、光栅/磁栅、门极PWM、驱动板保护和受控硬件集成，另行授权上电。

更新：2026-10-31。Issue #13已完成；当前实施Issue #15，板卡复位/JTAG运行须本次明确授权。PS—PL与电机接口适配不在AX-02A提前展开。继承已有模型与MBDL4接口，无需重做PI/FOC或重复LED学习。

首批[R5软件提取结果](../coordination/reports/ax01_r5_extraction.md)提供外环/Reference_Manager/原对齐来源。`simulation/AXU5EV_R5_Runtime.slx`纳入原Host_Core／轨迹，生成C在线接入同目录Hybrid；三种后端共用原对象、量化和50µs应用边界。软件/PL端口及帧顺序见[接口边界](../integration/ps_pl/INTERFACE.md)。

混合闭环从`simulation/START_HERE.m`开始，默认`model_fixed`；停止后可选`c_fixed`／`c_rtl`。首次构建、同次Run改目标／Send、对齐及复位见[同目录中文说明](../simulation/README_运行说明.md)。保留用户紫色分区；MATLAB/Simulink通过MCP操作，不用Computer Use。

#### 本地打开与复验

日常运行`simulation/START_HERE.m`，参数取自唯一入口 `simulation/init_AXU5EV.m`；保留用户本地修改，不用PR14历史V10/A100覆盖当前参数。需研究原浮点基线时，在同一初始化后打开同目录`PMLSM_PI_FOC_Float_Baseline`；停止后选择`FOC_Impl_Select=0/1`。不要给references/baselines使用递归genpath。

独立复验命令见[运行说明](../verification/AX00_REPRODUCE.md)。本轮支持原点位测试的 `live` 和对齐测试的 `chart` 阶段；没有搬运全套历史学习回归依赖。`references/legacy/mil` 是旧库磁盘来源，`pmslm_disk` 是完整 PMSLM 工程磁盘参考，后者不加入活动路径。未保存窗口未被保存或导出。

### 原 AGENTS 阶段记录

#### AXU5EV 协作与工作区规则

#### AX-04B 当前执行入口

2026-11-19，PR47 已将完整 PR46 带入 main `21847326`。`codex/ax04b-hardware-binding` 完成 B1～B4 和 R1 复审离线修订，停在 [kazecode666/AXU5EV Draft PR48](https://github.com/kazecode666/AXU5EV/pull/48) Review。当前入口为 [HANDOFF](../coordination/HANDOFF.md) 首节、[交付报告](../coordination/reports/ax04b_hardware_binding.md) 和 [首运行指南](../firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md)。

- 当前两个候选分别在 `.runtime/experiment/ax04b/selftest_r1_02` 和 `.runtime/experiment/ax04b/real_r1_02`。R5 使用已保存的实机模型 1.173 及本轮新生成 C，应用身份 `0x41585203`。各自复用原 `*_02/hardware` 实现，bit/ltx/XSA、R5 ELF、FSBL 和启动项必须成套使用。停止恢复按确认 CLEAR、确认 ARM、再次显式 Start 的顺序。
- B5 板内 SELFTEST、B6 真实 IO 和功率运动均为 `NOT_RUN`，后续分别取得明确授权。REAL 物理门极、PWM 缓冲及 RELCON/ENCON 硬禁止，目前可用于将来获准的真实输入及禁止态核对。实际 IRQ 计算窗口继续等待 ARM 实测。

#### AX-04A 历史入口

2026-11-17，按 Issue42 评论6941278055及PR43任务书完成交付A，已发布 [kazecode666/AXU5EV Draft PR46](https://github.com/kazecode666/AXU5EV/pull/46)，停在Review。分支 `codex/ax04-experiment-model`，叠加在PR45 `codex/issue42-task1-dsp-reuse`。最终验证记录见 `coordination/HANDOFF.md` 首节。本文以下AX-03及更早阶段的授权/待Review措辞保留作历史。

- 纯仿真入口为 `simulation/START_SIMULATION.m`，兼容入口为 `START_HERE.m`，参数源为 `closed_loop/parameters/init_AXU5EV.m`。
- 实机入口为 `simulation/START_EXPERIMENT.m`，算法、参数、生成入口位于 `experiment`。实机采用独立副本与ModelWorkspace参数，后续修改在各自用途目录进行。
- 实机R5主模型导出初始化、`PL_Frame_IRQ`及非实时服务函数，PL电流控制及数值预处理采用独立HDL生成边界。硬件驱动/IRQ绑定为 `HW_BINDING_PENDING`，板卡状态为 `BOARD_NOT_RUN`。
- 新生成源位于 `generated/experiment/<版本>`，缓存与本地结果采用 `.runtime/experiment/<新目录>`。原PR41冻结成果及历史实验目录原位保留。
- 目录迁移逐文件保留用户本地修改，打开入口保留Dirty内容和已有参数。库/模型切换仅使用显式用途路径。交付A完成后提交独立Draft PR，停在Review。

> AX-03B1交付入口：[kazecode666/AXU5EV Draft PR29](https://github.com/kazecode666/AXU5EV/pull/29)，关联Issue28，停在Review。本机Git HTTPS不可用，已通过连接器发布并核对本地/远端实现树一致；提交映射见当前HANDOFF，不强推或reset来抹平历史。后续B2/C、板卡、参数/PI恢复仍未授权。

> 当前开发：2026-11-05，用户已启动Issue28 AX-03B1；从含已合并PR27的main d3a10cf建立codex/ax03b1-feedback-observer，独立无功率观测模型/新数值生成/ADC与ABZ薄RTL/只读原子快照已离线实现并通过新增验证。当前交接以coordination/HANDOFF.md首节与coordination/reports/ax03b1_feedback_observer.md为准。只读观测无功率许可，所有硬件未知保留SIM_ASSUMPTION/PENDING；未改电机/PI/旧模型/FOC/Runtime，未重跑PR24、未操作板卡。提交本轮Draft PR后停在Review，不自动合并/关闭Issue、不进入B2/C。PR24、PR27均已合并，以下待Review/旧关机措辞为历史；保留全部Workspace、用户修改和实验数据。

> 当前签收：2026-11-04，按PR24评论6622743887归档用户已完成的perf_r1单次current_motion实板：身份0x43324302，64536条完整处理、2645976个Runtime值原判据零失败、193608个duty位串零差，帧/命令/采用及完整停止PASS。PMU7812421Hz：Runtime均值/最大25.025/39.040us，上一read_begin到下一commit_end均值/P99/最大70.204/83.457/86.017us；COMMIT后328B日志及返回开销均值/最大9.245/10.880us，计入日志的完整窗口均值/P99/最大79.449/92.929/95.617us。后者204条超名义93.68us但提交在先、实际采用均正确，不能宣称全部软件工作在93.68us内完成或WCET。原失败k1200提交95.873us，新同记录75.009us，含日志窗口96.257→84.481us。Workspace.runtime/ax02c2/vitis_runtime_pl_perf_r1，Launch ax02c2_runtime_manual；原native64平台/FSBL与hardware_02不变。精简证据verification/ax02c2/board_perf_r1_01，主报告及唯一指南已更新。原失败目录/备份及全部Workspace/数据保留。本轮仅离线读文件归档，不连接/操作板卡、不构建/回归；PR24待用户最终Review，不自动合并。以下性能候选BOARD_NOT_RUN、旧关机等记录均为历史，不作为当前动作。

> 最新交付：AX-02C2离线实现及必要适配/构建/启动检查PASS，已推送kazecode666/AXU5EV Draft PR24（https://github.com/kazecode666/AXU5EV/pull/24）。用户已回复将接回原ETH02直连网卡，随后最新要求离线完成后关机；本轮不再执行C2加载/运行，BOARD_NOT_RUN，留待后续继续。交接推送完成后正常关机，不强制关闭或自动保存未保存窗口。C1实板不复现，原模型参数和所有工作区/数据保留，PR24待Review，不自动合并。

> 当前：PR22已合并，从当前origin/main实施Issue23 AX-02C2，分支codex/ax02c2-runtime-pl-replay。真实R5 Runtime→原模型生成薄适配→原AXI轮询→真实PL FOC连续记录回放已离线实现；同源current_motion64536条，最终adapter709896+88words零差，原生构建及现有启动检查PASS。唯一Workspace.runtime/ax02c2/vitis_runtime_pl_native64，Launch ax02c2_runtime_manual，build43324301；复用hardware_02 bit/XSA，不重跑C1/RTL/ETH02。数据prepared_04/data/current_motion，最终adapter_native_01；主报告coordination/reports/ax02c2_runtime_pl_replay.md，唯一指南firmware/r5/ax02c2/FIRST_EXPERIMENT_ZH.md。C2板测NOT_RUN；用户已说明将接回原ETH02直连网卡，最新要求离线完成后关机，本轮不执行C2加载或实验，后续从Draft PR24继续；不扩展为无限操作，不接功率级、不写启动介质、不自动合并。保留所有旧Workspace/用户模型参数/数据。下述PR22待Review及旧PID/暂停状态均为当时历史，PR22已合并，C1成功已验收不复现。

> 当前：PR22 AX-02C1原hardware_01的AUX reset低有效却接0，已最小改接1（debug仍0）。hardware_02 bit/XSA完整构建及aux_fixed启动检查PASS，时序WNS+3.149ns/WHS+0.011ns、TNS/THS=0。2026-11-03用户明确授权在线诊断，并另准一次复位/加载新bit及原FSBL/R5 ELF、一次17帧；新首读PC1031BC→1031C0实得ID43314301，同次实板17帧/51duty/完整17帧PASS、mismatch0。旧故障现场PC未取得，不能与新首读实测混同。当前证据verification/ax02c/board_aux_fixed_01/evidence.json，原始UART.runtime/ax02c/board/uart_17_aux_fixed_01.txt；hardware_aux_fixed.json的NOT_RUN仅为构建快照。沿用原Workspace/Launch/ELF/FSBL，当前bit用hardware_02，不自动加载旧平台镜像。最终R5已halt于0010333C WFI，DSCR03186003/HALTED1；自建XSDB31752已断开退出，3121仅hw_server30848监听/无Established，用户可单一Vitis会话接手。本次授权动作已完成，进一步复位/下载/破坏现场寄存器写入仍须说明并征得确认。保留原工程及全部数据，PR22待最终Review，不自动合并。

#### 当前开发

- AX-02C1已推送[kazecode666/AXU5EV Draft PR22](https://github.com/kazecode666/AXU5EV/pull/22)，停在待Review；实际结果与产物以本轮主报告为准；保留全部用户修改和旧工作区/数据。

##### 已合并AX-02B记录

- AX-02B已通过并合并[kazecode666/AXU5EV PR20](https://github.com/kazecode666/AXU5EV/pull/20)；当时OOC结果以AX-02B主报告为准；保留全部旧workspace/ELF、用户未提交SLX/参数和原始实验数据，不自动合并或关闭Issue15。

##### 历史阶段记录

- ETH-02当前实现已推送[kazecode666/AXU5EV Draft PR18](https://github.com/kazecode666/AXU5EV/pull/18)，停在待Review；未执行两次新应用板测，不自动合并。

- 2026-11-03 ETH-02：PR17已合并，从当前main建立codex/eth02-runtime-ethernet，执行评论6595084647。新产物.runtime/ethernet/eth02，新Workspace vitis_runtime_ethernet、应用eth02_runtime、Launch eth02_runtime_manual、build0x45303201；GEM3+TTC0平台/真实文件传输/停网回放恢复/原分析与RUN_ETH02入口已离线实现、构建及现有启动检查PASS，两次整合板测NOT_RUN。唯一指南firmware/r5/ethernet_runtime/FIRST_EXPERIMENT_ZH.md，待新Draft PR Review后用户先current_motion再同应用current_alignment_reset。保留R1、ETH01 r3及所有实验数据，不操作板卡、不新增测试套件/额外功能/哈希清单、不重跑旧RTL、不自动合并、不关闭Issue15。下条ETH01待Review等状态按历史理解，PR17已合并。

- 2026-11-03 ETH-01：按PR17评论6577441490精简归档用户r3实板结果。当前workspace为.runtime/ethernet/eth01/vitis_ethernet_r3、launch eth01_tcp_manual_r3、build0x45303103；JL2121 ID=937c4032、PHYSR=182e、1000Mbps全双工。PHY_LINK/TCP_IO/MODEL_BOARD_IO/BULK_TRANSFER均用户实板PASS；small计数0→4，64KiB/1MiB/32MiB完整性PASS，32MiB上传/下载0.990/1.412MiB/s，上传未达1MiB/s目标，本轮不优化。精简证据verification/ethernet/eth01/board_r3，原始数据仍在.runtime/ethernet/eth01/board，r2/旧R1均保留。PR17保持Draft待最终Review和用户决定合并；不重建、不加功能/测试、不操作板卡、不接完整电机Runtime、不合并、不关闭Issue15。阶段状态status.json，唯一上板入口firmware/r5/ethernet/FIRST_BOARD_RUN_ZH.md。下列PR16待合并等记录按历史阶段理解。

- 2026-11-02最新：R1 motion64536帧与alignment_reset43100帧真实mode1均数值/时序/板报交叉PASS，精简证据分别在verification/ax02a/runtime_r1_motion_01和runtime_r1_alignment_reset_01。alignment本次两CLI均exit0，motion既有结果只读归档。详见coordination/reports/ax02a_full_board_results_2026-11-02.md的Issue15逐条审计：A5冷启动条件未明确、A4严格mode0分阶段口径待Review，不能自动全签。PR16保持Draft、Issue15开放，待最终Review/用户决定；不重跑实验、不改模型参数/TTC、不操作板卡。以下NOT_RUN按历史阶段理解。

- 最新R1 P1000用户实测已复算PASS：1000×41/数值零失败、deadline/sequence PASS、相位无趋势、PC/板报一致，证据 `verification/ax02a/runtime_r1_p1000_01/`。本轮完整场景准备已离线完成：现有R1 ELF不重建，描述符在 `.runtime/ax02a/full_scene_descriptors/`，readback_short.tcl末尾显式场景支持current_motion64536/current_alignment_reset43100。下一步指南第14节及FULL_SCENE_RUN_ZH.md，用户Review后手动逐次执行；两次完整板验NOT_RUN，73/73离线回归不代替ARM实测。保留全部workspace/原始数据，不重复ABA/不清理/不改算法参数。

- PR16 Review5722212233从f6c0fcb接续：板报假PASS、初始化失败现场保存及完整构建显式runtime_mapping=1保护已离线修复，72/72相关回归通过，待复审。当前R1 ELF不重建，TTC映射/deadline/生成代码/模型不改，不操作板卡。用户已手动清理旧临时目录，不恢复、不再清理；本轮新测试隔离于 `.runtime/ax02a/review_5722212233/`。

- 目录/上板/数据保存统一索引为 `docs/WORKSPACE_GUIDE_ZH.md`；当前状态读 `coordination/HANDOFF.md`，历史交接见 `coordination/HANDOFF_HISTORY_2026-10-31.md`。下一次Runtime R1完整场景用指南第14节及 `vitis_runtime_100us_r1`；历史清理候选已由用户手动删除，不恢复、不再清理；workspace/原始数据不搬动。

- 当前执行PR16任务6541052405 T1—T3：用户`ttc_aba_01`三组真实IRQ已复算，全窗口RAW_PLUS_ONE_COMPATIBLE、A1/A2可重复；只读兼容旧uint32签名元数据，原始run/samples保留。Runtime平台仅对已验证TTC0通道0/1内部同源100MHz、无分频、10kHz映射raw9999/logical10000，其他配置拒绝；不改expected/deadline。新候选workspace `.runtime/ax02a/vitis_runtime_100us_r1`，旧workspace/ELF全保留。T4必须Review后用户按指南第13节手动P1000，Runtime候选板验NOT_RUN，不重复ABA/C，不操作板卡、不合并。

- PR16评论6525374617的T1—T3已离线实施：最新phase_p1000_01独立数值PASS，趋势仍约+0.99779tick/frame；新TTC-only workspace `.runtime/ax02a/vitis_ttc_characterize`及应用`ax02a_ttc_characterize`真实构建，OFFLINE_READY_FOR_REVIEW。原三个workspace/ELF保留。用户Review后按指南第12节逐次A1(10000)→B(9999)→A2(10000)，每次1000真实IRQ/16000B；9999仅实验条件，nominal10000与原deadline不变。T4用户上板NOT_RUN、物理根因UNCONFIRMED、正式修复NOT_RUN；Codex不连接/操作板卡，不合并。

- 相位候选为`.runtime/ax02a/vitis_phase_diagnostic`，v2报告2400B，原两个workspace及ELF保留。exp2本次数值PASS、deadline/sequence PASS，但ISR phase趋势0.999271tick/帧被新PC/C诊断拒绝；硬件根因未确认，interval/logical period仍10000，不盲减1、不宽deadline。GUI只读配置取证/复验见指南第8节；候选板上NOT_RUN。

- 最新执行PR16评论6516979286/6517272543及Review5708766094：exp2新capture已完整，数值PASS但存在约1tick/帧ISR相位累积趋势，周期一致性未确认。先提交数据结论，再诊断/核查TTC/证据充分后最小修正；不能盲改9999、修改名义period掩盖漂移或放宽deadline。保留`vitis_target_a53fsbl`与`vitis_postprocess`及全部原始数据，候选新目录；不连接/发现/操作板卡，寄存器步骤交用户。

- C1已提交64466414773038524dce40c120dd99434102e7e8；C2/C3新固件只在`.runtime/ax02a/vitis_postprocess`离线构建，默认后处理关闭，目标后处理/P1000周期未验证。当前执行PR16评论6514858529的C1—C3。用户BOARD_BOOT/FIRST_WAIT及motion_03首次64536×41真板数值PASS已有评论/本地报告证据；A4第二次motion、alignment/reset及完整A5仍待验收。先提交C1不改固件，再做C2/C3离线后处理。用户正在调试`.runtime/ax02a/vitis_target_a53fsbl`，禁止覆盖/重建其ELF；新固件独立输出。Codex不得连接、发现、暂停/恢复、复位、下载、读写或运行板卡。原始output/ticks保留；比较/时间摘要只在实验结束且计时器停止后做，开关默认关闭，不改算法/cache/TCM/采样首相，不重跑RTL。

- 目标板：AXU5EVB-E，用户已确认。具体PCB修订、芯片完整料号及厂商工程XA/-1与手册XC/-2差异，在板级适配前核对，不阻塞R5软件整理。
- R5F：位置P、速度PI、原五态对齐及一次性偏置、Reference_Manager/轨迹/命令与恢复管理。
- PL：复用已接受的电流FOC，负责同步采样/位置接口、运行中角度/偏置应用、PWM及快速禁止。
- 算法源为现有Simulink/Stateflow；不手改生成SV/C补算法，不重做PI/FOC和定点化，不强制三环全部HDL化。
- Simulink搭建完成后逐层检查连线与排版；From/Goto使用局部作用域，Inport/Outport保持默认大小与外观。
- 先读 `coordination/HANDOFF.md`。AX-00迁移已完成；旧迁移任务、Issue #3及旧M4仅作历史记录，不作为继续开发的流程清单。
- 当前优先Issue #15的AX-02A（A1—A6）：先真实R5目标工程、数值与100µs时间证据，不重规划全项目、不默认重跑完整RTL。PR #14已合并（ae9a11d2d59abc952cce0b979d004a315878639a），Issue #13仿真收尾仅作既有证据。当前Cortex-R生成/全采样导出/主机比较及真实5EV PS-only XSA、R5 standalone BSP/FSBL/ELF/map构建通过；10月27日历史BOARD_BOOT/REPLAY/PERIODIC为NOT_RUN；10月30日新状态见本节首条及`coordination/reports/ax02a_r5_target_validation.md`。不得以构建或主机结果关闭板上验收。
- 继续取消C源码学习、逐行讲解及教学配置更改。Ready是当拍许可，Busy=0不保证Ready=1；status3未Ready拒绝、不排队。Issue #11和AX-02B/C不在本轮实施。活动模型与必要.m按用途集中在`simulation/`。纯仿真参数入口为`closed_loop/parameters/init_AXU5EV.m`，实机参数入口为`experiment/parameters/axu5ev_experiment_parameters.m`，分别使用`START_SIMULATION.m`与`START_EXPERIMENT.m`。`START_HERE.m`转到纯仿真入口。保留用户本地SLX/参数修改；旧PR14输入可复用，但当前参数参考必须独立标识。目标生成不覆盖PC目录/MEX、不保存未保存模型。板卡复位/JTAG加载运行须本次明确授权。
- 当前按PR16“用户手动上板与首次PS开发学习”评论补齐离线操作交接，上板由用户本人完成；Codex不连接、复位、写内存、加载或运行板卡，也不自动探测已接好的线。首次手动测试只到现有R5应用等待输入；操作见`firmware/r5/ax02a/FIRST_BOARD_RUN_ZH.md`。不恢复C语法教学，不另建Hello World/LED/QEMU项目，不把后续回放段自动执行。
- PR16首次故障已定位旧GUI将R5 FSBL加载到A53_0；当前离线启动工程为`.runtime/ax02a/vitis_target_a53fsbl`，A53_0 FSBL＋R5_0应用，launch为`ax02a_first_wait_a53fsbl`。先用构建入口的`--check-startup`核对实际架构/域/路径；保留旧workspace，旧`ax02a_first_wait_manual`不再用于GUI重试。用户修正后BOARD_BOOT和首次motion已有PASS；其他板上验收见C1—C3首条，不把旧R5 Suspended当初始化成功。
- 板型以《AXU5EVB-E开发板用户手册》为依据；用户确认核心板可参考`ACU5EV核心板原理图.pdf`，底板可参考`AXU5EVB-E开发板原理图.pdf`（与AXU3EG底板共用），实物以太网收发芯片JL2121。不得仅凭图框AXU3EG否定底板资料，也不因此在AX-02A扩展网络适配。
- 保留用户现有紫色分区与Host/Alignment_Task/Motion_Control布局；修改仅微调受影响区域。MATLAB/Simulink操作使用MCP，不使用Computer Use。

---

## 2026-10-31 整理前存档

本文保留整理前逐阶段记录，其中“最新”“当前”“NOT_RUN”等按原阶段理解。当前任务与状态请读 [HANDOFF.md](HANDOFF.md)，路径请读[工作区指南](../docs/WORKSPACE_GUIDE_ZH.md)。本存档不作为下一次上板入口。

### 原交接（2026-10-31）

日期：2026-10-31。仓库`kazecode666/AXU5EV`，本地`D:/Project/AXU5EV`。PR #7/#9/#12已合并；AX-00迁移、资料阶段结束，旧Issue #3及M4不作为当前流程。

## 当前任务与结果

最新执行任务6541052405（`tasks/ax02a_runtime_100us_r1.md`）。T1提交`b46fdf6`闭合用户ABA实测及读回格式：周期10000.999985／9999.999988／10000.999700 ticks，全窗口RAW_PLUS_ONE_COMPATIBLE、repeatable=true、issues=[]；原始数据保留。T2 `2aa9a9a`以板测限定配置在Runtime平台映射raw9999/logical10000，PC按版本1/候选身份区分新旧timer；旧漂移仍拒绝，expected/deadline/超时不改。T3独立workspace为`.runtime/ax02a/vitis_runtime_100us_r1`，应用`ax02a_replay`，候选标识0x52313031；用户Review后按指南第13节运行带Runtime的P1000并保存run/output/timing/report_v2四文件。ABA实测已完成，不重复ABA或可选C；Runtime候选板验仍NOT_RUN。历史TTC-only/相位候选记载按所属阶段理解，旧工程/模型/生成源/原始数据全部保留。

最新按PR16评论6525374617执行T1—T3，任务书在`tasks/ax02a_ttc_aba_characterization.md`。T1 `1c55a3e`独立比较最新phase_p1000_01：1000×41数值PASS、deadline_sequence PASS、相位+0.997790848965tick/frame仍拒绝，板上v2/PC一致。T2 `e070bb6`独立TTC-only采集/分析；T3真实新构建在`.runtime/ax02a/vitis_ttc_characterize`，应用`ax02a_ttc_characterize`，launch`ax02a_ttc_characterize_hw`，原三个workspace保留。OFFLINE_READY_FOR_REVIEW；用户Review后按FIRST_BOARD_RUN_ZH.md第12节从开始菜单Set Workspace，逐次显式A1(raw10000)→B(9999)→A2(10000)，每次1000条/16000B。9999仅实验条件，不用旧P1000比较器。T4硬件NOT_RUN、根因UNCONFIRMED、正式修复NOT_RUN，完整A4/A5仍未验收；Codex不操作硬件、不合并。以下候选/缺actual描述按历史阶段理解。

当前相位候选已在独立`.runtime/ax02a/vitis_phase_diagnostic`构建；两个旧workspace保留。PC/C加入k0排除、至少32ISR样本的OLS趋势筛查（6SE+2tick/span），数值/旧deadline/period状态分开；实测exp2与+1tick反例不再整体PASS，固定延迟/随机抖动对照正常。报告升级v2/2400B，v1的mode1不再可证明周期一致。41测试通过，物理根因尚未确认：原硬件interval/logical period10000均未改，deadline未放宽；本机驱动直接写interval、当前XPM禁用，没有证据可盲改9999。候选开始前保存ax02a_ttc_snapshot；用户只读寄存器/GUI复验步骤在FIRST_BOARD_RUN_ZH.md第8节。候选目标运行/完整A4/A5仍未验收，不能把诊断修复写成硬件漂移已消除。


2026-10-30最新任务为PR16评论6516979286/6517272543和Review5708766094。用户`p1000_exp2_capture`的本次328000B output、64000B ticks、run.json已只读核验；配套P1000参考比较1000×41数值PASS，错误0，最大绝对差4.336808689942018e-19。旧规则下序号/截止期无异常，但ISR帧1..999的release−expected斜率0.999271094742 tick/frame，周期一致性不接受；第0帧软件时间戳不拟合。先提交数据结论，再补诊断/本机TTC核查/最小修正，不能盲改interval或放宽deadline。保留两个现有workspace/ELF与原始capture，候选新目录，硬件仅用户操作。新证据在`verification/ax02a/p1000_exp2/`；以下“缺actual”是此前历史记录，已被此次完整capture取代。


最新补充：用户PR16评论6515463934提供旧ELF的P1000 experiment1→2完成回执，本地`p1000_01/timing.bin`64000B完整，原Python规则检查1000条记录无序号/时间顺序/截止期异常。最大观测Runtime38.42µs、task54.11µs、response69.25µs、start jitter16.49µs，最小slack30.75µs；仅按本次TTC100MHz配置换算，非WCET/独立测频。`motion_03/output.bin`经核对仍为旧mode0的21167808B，不能拿其前1000帧替代exp2输出；本次328000B actual尚缺，P1000整体INCOMPLETE，完整A5及新后处理板验收仍未完成。详见`verification/ax02a/p1000_01/`。C2/C3离线成果已推送9e846c0b6ee71598b8757b8682e6535d33697181。


C1已独立提交并推送`64466414773038524dce40c120dd99434102e7e8`。随后C2/C3完成离线最小后处理：`postprocess.c/.h`＋main默认关闭的一次性新控制口，独立`.runtime/ax02a/vitis_postprocess`已真实构建ELF/map；旧调试workspace未重建。HOST用真实motion_03全64536×41数据与Python逐字段交叉通过，32项相关测试通过。新参考/descriptor/2336B报告区与ELF及原buffer无交叠；原output/ticks保留，C的P99为NOT_COMPUTED。指南第7节仅供Review后用户决定加载；P1000原始ticks后续已收到，数值actual尚缺；目标后处理和完整A5仍NOT_RUN，A4缺项保留。见`verification/ax02a/postprocess_validation.json`。


当前按[PR16 C1—C3评论6514858529](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6514858529)执行。**用户已完成BOARD_BOOT/FIRST_WAIT与motion_03首次完整64536×41字段真板数值PASS；A4第二次motion及43100帧alignment/reset未完成，A5计时NOT_RUN。** 本地motion_03完整输出21,167,808B及报告存在，C1重新调用原比较器通过；必要基线整理于`verification/ax02a/board_motion_03/`。旧失败与中断读回记录保留，以下10月27日启动未运行描述属历史阶段，不能覆盖新证据。

C1不改固件；已准备`.runtime/ax02a/replay/p1000/`第0帧起1000帧配套数据、`scripts/ax02a_prepare_prefix.py`、`ax02a_analyze_run.py`与被动`firmware/r5/ax02a/readback_short.tcl`。P1000只作技术预检，不替代A4/A5。**用户正在调试vitis_target_a53fsbl，禁止覆盖/重建该workspace的ELF；新固件用独立输出。Codex不连接/发现/暂停恢复/复位/下载/读写/运行板卡。** 用户手动P1000步骤见FIRST_BOARD_RUN_ZH.md第6节。

当前主线为[Issue #15](https://github.com/kazecode666/AXU5EV/issues/15) AX-02A，沿A1—A6推进真实R5目标工程/数值/100µs时间验证，不重规划全项目、不默认重跑完整RTL。见[AX-02A实际报告](reports/ax02a_r5_target_validation.md)与[R5应用入口](../firmware/r5/ax02a/README.md)。

用户最新按[PR16故障评论](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6443462085)要求离线修正启动：旧GUI将R5 FSBL下载到A53_0并超时；本机ELF32/ARM/R-profile检查确认架构不匹配。现已真实构建新`.runtime/ax02a/vitis_target_a53fsbl`：A53_0 FSBL＋原R5_0 standalone应用，采用`ax02a_first_wait_a53fsbl`配置，并提供纯文件检查`--check-startup`；旧workspace/配置保留，旧`ax02a_first_wait_manual`不再用于GUI重试。见[首次PS操作指南](../firmware/r5/ax02a/FIRST_BOARD_RUN_ZH.md)。**上板由用户本人操作，Codex不连接/复位/写内存/加载/运行板卡**。第一次仍只到启动消息与`state=1/experiment=0`，不发实验命令；修正后的板上启动未运行，BOARD_BOOT/REPLAY/PERIODIC继续NOT_RUN。用户旧R5 Suspended不代表初始化成功。

成果草稿[PR #16](https://github.com/kazecode666/AXU5EV/pull/16)，仓库`kazecode666/AXU5EV`，未合并。初始实现`8d892695705a61a1295389a3bc7343e87ca59aa7`；ARM对象与周期门禁`6d9e5397478361762e947b5812b701dc554b24da`；可执行门禁`77a7d358baf1b0bd8577e8c929be9156026fcf84`；完整PS平台/BSP/ELF与证据`1b4834526275b1824098ad66a2c2a6ce0d04dc0b`。Issue15板上验收继续开放。

PR #14已合并，合并提交`ae9a11d2d59abc952cce0b979d004a315878639a`，实现提交`9a6877546581301638a2bde7203db47896b4f8aa`。原Issue #13仿真收尾见[AX-01C报告](reports/ax01c_simulation_closeout.md)；不重复执行。C源码教学、Issue #11及AX-02B/C仍不在当前范围。

AX-02A已完成离线Cortex-R独立代码生成并恢复PC配置、既有Arm GNU12.3.1真实交叉编译Runtime/bridge/runner为6个ARMv7-R/VFPv3-D16对象与静态库、原始64536帧数据导出、当前Runtime同输入参考与43100帧完整手动对齐/复位/故障参考。当前用户参数V20/A200/minRamp0.2/rate100；原PR14 V10/A100输出单列保留，不混用。相同生成源的主机两次运动实验全41字段最大差1.7763568394002505e−15，定向场景差0；比较器9项故障测试（含拒绝错误1ms周期）和runner序号/截止期测试通过。没有重跑RTL/对象闭环。

用户已手动补齐2026.1的MPSoC/Vitis Embedded组件；本轮真实构建得到`.runtime/ax02a/ps_target/ax02a_ps.xsa`与`.runtime/ax02a/vitis_target/ax02a_replay/build/ax02a_replay.elf`、同目录map、R5 BSP及FSBL，**TARGET_BUILD=PASS**。Vivado/Vitis均SW6511674，官方R5 GCC13.4.0；ELF32/ARM/v7-Realtime/VFPv3-D16/hard-float，入口0x3c，装载[0,0x7d8)、[0x100000,0x111c80)，与回放DDR窗口无重叠。text41588/data5100/bss28136B，代码/状态/栈位于DDR，向量/启动数据位于ATCM；不是已完成TCM性能优化。精简产物证据在`verification/ax02a/target_*`。

平台脚本仅复制/原生升级厂商PS XCI到3.5，再创建新BD。已复现并修复Vivado回调覆盖全局`config`的构建错误；构建状态放入局部proc，DDR64bit/x16/8Gbit/2400P与UART0 MIO42/43检查通过。新BSP的TTC0确有三个独立通道，前两项供周期/计数使用，配置100MHz；新平台R5配置499.994995MHz。这些是配置值，非硬件实测。新增构建已独立只读审查无发现，13项定向测试再次通过；没有重跑RTL/对象闭环。

**BOARD_BOOT/BOARD_REPLAY/BOARD_PERIODIC_100US仍NOT_RUN**。器件安装与完整目标链接的旧阻塞已经解除；实际芯片/PCB修订、RPU split启动、DDR可达性、数值与周期证据仍待板上确认。板卡复位/JTAG加载运行须本次明确授权与连接确认，功率级隔离；不得以构建结果关闭Issue15。

用户最新确认：核心板可参考`ACU5EV核心板原理图.pdf`，底板可参考`AXU5EVB-E开发板原理图.pdf`（与AXU3EG底板共用），实物以太网收发芯片JL2121。本轮按用户手册选择XC/-2，不将厂商XA/-1旧XSA冒称当前目标平台。

以下为已合并PR14的既有证据：

完整RTL已结束，实际64536帧/每帧5000拍，捕获315、有效1、保持违规0；墙钟15527.072198 s。与c_fixed相同参数/初态，实际采样命令均为2.0915、2.1016、5.2999 s；接受3/拒绝1/段号3。三段首次Ready为1.9199、3.9599、6.3499 s，五事件最大误差分别0.01987350、0.01951992、0.01962843 mm。末帧6.4535 s位置−2.018663179 mm、Busy=0、Ready=0；Ready原规则回落，未强制保持。

完整41字段、位置/速度/dq电流/四项参考与三相应用duty差均0；字差0，+50 µs时间误差≤1.1653e−16 s。精简CSV/曲线在`verification/ax01c/`，完整MAT/日志留`.runtime/ax01c/`。3份相关.m的Code Analyzer无问题，实际曲线与SLX局部图已检查。MCP请求曾超时但后台继续完成，未重复Run。普通Run不编译；旧PR7映射升级显式重建一次已在PR9完成。

已合并[PR #12](https://github.com/kazecode666/AXU5EV/pull/12)，合并提交`22c783d57a8ed43773efa2c986f2d5dab9731852`，实现提交`bff686425bfdc440bad421d03ae9737483fca69b`。其model_fixed/c_fixed六次发送均采集，模型/C全41字段最大差1.77635683940025e−15；证据见[发送报告](reports/issue8_send_ready.md)。当前基于该合并继续，不重复排查既有拒绝问题。

PR9反馈字段错位与PR12发送回执已有根因/修复证据，不重复排查。Ready为当拍许可，Busy=0不保证Ready=1；status3未Ready拒绝、不排队。状态7可由运动中断异步产生，不能当作新请求回执。

活动模型和必要.m已逐项迁到`simulation/`。用户只编辑`init_AXU5EV.m`，运行`START_HERE.m`后点击Hybrid的Run；默认model_fixed，不自动Run。旧入口仅薄转发，不重复恢复默认目标。操作见[同目录中文说明](../simulation/README_运行说明.md)。

用户Hybrid、Runtime、Control紫色分区保留；本轮未编辑SLX、生成C/SV或控制算法。MATLAB/Simulink只通过MCP操作。修复`axu5ev_run_case`缺失输出目录，并增加同拍收尾运行/导出辅助；模块说明集中在原README，不另做C教材。程序调参不等同鼠标/键盘操作，实际UI刷新仍NOT_RUN；本轮完整RTL三段已完成，板级工作仍NOT_RUN。

先前已合并[PR #9](https://github.com/kazecode666/AXU5EV/pull/9)完成接口字段修复、simulation集中入口、默认10 mm、复位释放及连续命令验证，实际范围见[原报告](reports/issue8_manual_run.md)。接口修复提交`08e727e64e2a04c4f9666b513d5704e71e8b84f2`；入口/验证提交`3d5d009e1c85b1bfddf3b041711c91496189c374`。旧213帧RTL与PR7旧1 mm均不作为本轮完整运动验收。实现PR供Review，不自动合并，不继续上板。

## 固定方向与可复用来源

- 目标板AXU5EVB-E；PCB/芯片完整料号、厂商XA/-1与手册XC/-2差异留待板级适配前核对。
- 单Cortex-R5F负责位置P、速度PI、原五态对齐/偏置、Host/参考/轨迹/恢复管理；PL复用电流FOC，负责同步采样/位置/角度、PWM与快速禁止。
- 活动算法源均在`simulation/`。Hybrid是日常整体闭环；Runtime是软件C生成入口；Control是PR5独立组件来源，复制进Runtime后不自动同步。不手改生成C/SV补算法。
- 原点位/S曲线函数、PI、采样周期与首相、手动Start、10000/30000/2000拍与0.5 A、一次死区、50 µs应用、PWM禁止后机械继续保留。
- PL来源`generated/legacy_m3_p3/FOC_DUT.sv`，仍按5000拍/帧合同；314拍不是新增外围后的整链延迟。
- 继承`references/legacy/PMLSM_Hardware_Interface_Map.md`、MBDL4和MIL/DSP的ia/ib/ic、0.1µm/count光栅、RELCON/ENCON/F_Reset及低有效ERRI/ERRU。不照搬DSP引脚，不重复索要已有定义。

## 工作与验证边界

保留当前本地编辑，不stash/reset/clean、不额外clone/worktree、不保存未保存窗口、不批量删除；From/Goto局部、端口默认外观，不全图重排。不增加位置积分、运动中重规划、CORDIC、标幺化或缩位。只做变更所需验证，不增加哈希清单、快照保护报表、额外冒烟或无关历史回归。

PR14阶段为Windows主机生成C/MEX与完整一组实际RTL反馈联合仿真；20/41字段向量不是实际AXI。本轮AX-02A已另行完成R5目标构建；托管SIL/PIL、R5实际任务时间、真实AXI、5EV综合/布线、ADC/编码器/PWM板级适配、ARM实测、烧录与实机仍NOT_RUN。硬件下载和功率级上电须另行授权。旧Artix结果不能当5EV验收。

原AX-01B结果见[历史报告](reports/ax01b_runtime_hybrid.md)，原R5提取见[PR5报告](reports/ax01_r5_extraction.md)，厂商/R5参考见[AX-00B](reports/ax00b_vendor_review.md)和[R5指南](../firmware/r5/ALINX_R5_REUSE_GUIDE.md)，仅当前需要时查用。旧运行指南已转向新的simulation入口。
