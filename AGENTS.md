# AXU5EV 协作与工作区规则

> 当前：PR18已合并，执行Issue19 AX-02B，分支codex/ax02b-pl-current-core。独立5EV候选生成、p3等价和定向位/帧检查已PASS，5EV OOC综合/布局布线及内部STA已PASS（理想时钟边界；WNS+3.020ns、WHS+0.034ns，TNS/THS=0）。目标xczu5ev-sfvc784-2-i、50MHz/100µs帧/50µs应用参考边界；实物料号/PCB待核。主报告coordination/reports/ax02b_pl_current_core.md，所有新产物.runtime/ax02b。只离线，不连接板卡、不做AXI/ADC/编码器/门极PWM，不改Runtime/TTC/ETH02，不重跑长时RTL/ETH02板测。以下PR18待Review等记录为已合并前历史，不作为当前指令。

## 当前开发

- AX-02B当前结果与待Review状态以主报告为准；保留全部旧workspace/ELF、用户未提交SLX/参数和原始实验数据，不自动合并或关闭Issue15。

### 历史阶段记录

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
- 继续取消C源码学习、逐行讲解及教学配置更改。Ready是当拍许可，Busy=0不保证Ready=1；status3未Ready拒绝、不排队。Issue #11和AX-02B/C不在本轮实施。活动模型和必要.m集中在`simulation/`，唯一日常参数入口`init_AXU5EV.m`，启动入口`START_HERE.m`。保留用户本地SLX/参数修改；旧PR14输入可复用，但当前参数参考必须独立标识。目标生成不覆盖PC目录/MEX、不保存未保存模型。板卡复位/JTAG加载运行须本次明确授权。
- 当前按PR16“用户手动上板与首次PS开发学习”评论补齐离线操作交接，上板由用户本人完成；Codex不连接、复位、写内存、加载或运行板卡，也不自动探测已接好的线。首次手动测试只到现有R5应用等待输入；操作见`firmware/r5/ax02a/FIRST_BOARD_RUN_ZH.md`。不恢复C语法教学，不另建Hello World/LED/QEMU项目，不把后续回放段自动执行。
- PR16首次故障已定位旧GUI将R5 FSBL加载到A53_0；当前离线启动工程为`.runtime/ax02a/vitis_target_a53fsbl`，A53_0 FSBL＋R5_0应用，launch为`ax02a_first_wait_a53fsbl`。先用构建入口的`--check-startup`核对实际架构/域/路径；保留旧workspace，旧`ax02a_first_wait_manual`不再用于GUI重试。用户修正后BOARD_BOOT和首次motion已有PASS；其他板上验收见C1—C3首条，不把旧R5 Suspended当初始化成功。
- 板型以《AXU5EVB-E开发板用户手册》为依据；用户确认核心板可参考`ACU5EV核心板原理图.pdf`，底板可参考`AXU5EVB-E开发板原理图.pdf`（与AXU3EG底板共用），实物以太网收发芯片JL2121。不得仅凭图框AXU3EG否定底板资料，也不因此在AX-02A扩展网络适配。
- 保留用户现有紫色分区与Host/Alignment_Task/Motion_Control布局；修改仅微调受影响区域。MATLAB/Simulink操作使用MCP，不使用Computer Use。

## 工作区与接口

- 使用已确认的 `D:/Project/AXU5EV` 和 `kazecode666/AXU5EV`，旧 `D:/Project/FPGA_XC7A200T` 只读；不额外clone/worktree，不复制旧`.git`。
- 继承 `references/legacy/PMLSM_Hardware_Interface_Map.md`、MBDL4参数及MIL/DSP的三相电流、光栅、RELCON/ENCON/F_Reset与ERRI/ERRU需求；单列AXU5EVB-E的新ADC、电平和接线适配，不要求用户重述已有定义，不照搬DSP引脚。
- 不自动stash/reset/clean、强制pull/push、覆盖用户修改、保存未保存窗口或关闭全部模型。活动模型与冻结/历史副本分开；不用根目录递归genpath。
- 禁止批量删除。需要删除时，一次只删除一个明确路径的文件；批量删除交由用户手动进行。

## 开发与验证

- 保持已有PI/位置P、采样周期、五态对齐与手动Start；PI_Reset、Init_Reset、global reset、故障清除分别处理。保留一次死区、应用延迟和PWM禁止后机械继续的语义。
- 向量接口同时维护Mux、Demux、旁注与C生成来源；当前Runtime输入分组宽度`[11 3 1 1 1 1 1 1]`，位置在字段20。Demux前两路仍是向量，不把输出端口号当字段索引。
- 只做变更所需验证；不要求提交文件哈希/清单，不做全资料哈希遍历、快照保护报表、字节一致性专项或额外资料冒烟测试。历史证据原样保留；文字修订不重跑旧仿真/RTL。
- 报告说明做了什么、相关文件/章节、可复用点和真正未完成项；区分静态检查、主机仿真/SIL、RTL、综合、布线、ARM实测和实机，未运行写NOT_RUN。
- 不增加位置积分、运动中重规划、CORDIC、标幺化、缩位或旧全HDL对齐优化，除非用户另行要求。

## 协作与交付

- ChatGPT负责架构/Review；Codex在本仓库实施并按需验证，普通小步Git提交与PR正常进行。记录完整owner/repo、PR和提交SHA，旧新编号分开。
- 用户决定研究方向与合并、硬件操作；明确授权后可执行指定PR合并。烧录bitstream、功率级上电须另行授权。
- 使用现有登录与权限，不索要/打印token，不复制密钥或全局工具配置。厂商原件默认本地保留，只提交原创整理和必要索引；第三方文件遵守许可。
