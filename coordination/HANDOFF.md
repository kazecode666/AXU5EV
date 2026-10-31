# AXU5EV — 当前交接

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
