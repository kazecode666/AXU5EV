# AX-02A：真实目标构建与离线数值验证

当前入口与数据保存规则见[工作区指南](../../docs/WORKSPACE_GUIDE_ZH.md)和[HANDOFF](../HANDOFF.md)。本报告保留分阶段证据；旧段落中的NOT_RUN/当前候选按该段日期理解。

初始报告日期2026-10-27；仓库`kazecode666/AXU5EV`，[Issue #15](https://github.com/kazecode666/AXU5EV/issues/15)。基点为PR14合并`ae9a11d2d59abc952cce0b979d004a315878639a`，分支`codex/ax02a-r5-target`。本报告记录实际成果；不展开AX-02B/C或AX-03。

成果为草稿[PR #16](https://github.com/kazecode666/AXU5EV/pull/16)，未合并。实现提交`8d892695705a61a1295389a3bc7343e87ca59aa7`，ARM对象/周期门禁`6d9e5397478361762e947b5812b701dc554b24da`，验证补充`77a7d358baf1b0bd8577e8c929be9156026fcf84`；本轮完整PS平台/BSP/ELF与构建证据`1b4834526275b1824098ad66a2c2a6ce0d04dc0b`。本PR不关闭真实R5数值/周期验收。

## 当前验收状态

### 2026-11-02：两个完整R1 mode1场景真实PASS

完整motion64536帧及alignment/reset43100帧数值/100µs时序/板报交叉均PASS。本次alignment两条正式CLI exit0，motion复用既有PASS报告，不覆盖原始证据。[完整时间统计与Issue15 A4/A5逐条验收审计](ax02a_full_board_results_2026-11-02.md)，[motion证据](../../verification/ax02a/runtime_r1_motion_01/evidence.json)，[alignment证据](../../verification/ax02a/runtime_r1_alignment_reset_01/evidence.json)。最大Runtime分别38.74/17.43µs，最小slack39.18/61.61µs；两次零截止期/序号异常、ISR无趋势。仅观察最大值，不是WCET。A5冷启动条件证据不足、A4严格mode0阶段签收待Review；器件/PCB签核与最终用户决定仍待完成，不将所有条款自动签PASS。PR16 Draft，Issue15开放，无板卡操作或重Build。后文NOT_RUN为历史阶段状态。

### 2026-10-31：Runtime R1 P1000真实PASS归档及完整场景准备

从 `cc4dee9ef202e9ff4597c59e997d8813383b1c20` 接续。只读 `.runtime/ax02a/board_manual/runtime_r1_p1000_01/` 的run/output328000B/timing64000B/report_v2 2400B、同次 `.runtime/ax02a/runtime_r1_pre_begin_01.json` 与 `replay/p1000` 参考。现有ax02a_analyze_run和修正后板报crosscheck两条CLI均exit0：1000×41数值0失败，最大绝对差4.336808689942018e-19；deadline/sequence PASS，原始异常0；999 ISR斜率−0.0005598825278183996tick/帧，原阈值0.012544565142580701，NO_TREND_DETECTED；crosscheck_consistent=true、passed=true，无状态/统计矛盾。

最大观测Runtime37.61µs、task52.96µs、response59.19µs、start jitter7.26µs，最小slack40.81µs。按此候选100MHz配置换算，不是独立测频或WCET。pre-begin raw9999/logical10000、clock/control/IER符合候选，TTC0选择/上游lpd_lsbus_ctrl/iopll_ctrl与此前基线分别保持0/16779778/80896，只有预期raw从10000改为9999。精简PASS证据/数值/时间/板报及配置在[本次归档](../../verification/ax02a/runtime_r1_p1000_01/evidence.json)，大型原始二进制只留本地。仅签收带Runtime的100µs短段，不代替完整A4/A5。

现有R1 ELF可直接接受current_motion64536和current_alignment_reset43100的mode1。纯文件启动/实际候选常量检查通过；实际ELF main反汇编仍含65536帧比较及timing/replay/postprocess调用。对应workspace导入源支持scenario2/3和32B描述符。两组input/output/timing/reference的实际长度全部落在原DDR窗口，帧预算645380000/431020000tick低于UINT32_MAX，不改逻辑周期/超时/截止期。

两份描述符已由原工具生成于 `.runtime/ax02a/full_scene_descriptors/{current_motion,current_alignment_reset}/reference_descriptor.bin`，输入/参考直接复用replay下同名目录；readback_short.tcl末尾新增显式场景参数，帧数固定64536/43100，沿用64KiB分块、身份及失败保存逻辑，旧P1000调用不变。只新增一个全尺寸功能用例覆盖两场景：先复现旧入口拒绝，再经真实Tcl分块/合并送入现有完整数值/时间CLI及板报CLI，两个场景均通过。HOST C报告/参考副本与合成ticks只证明读回及分析可用；相关离线回归73/73、0失败/错误/跳过，不能当ARM证据。[准备和静态能力](../../verification/ax02a/full_scene_r1/preparation.json)、[验证记录](../../verification/ax02a/full_scene_r1/validation.json)。

当前 **OFFLINE_READY_FOR_REVIEW**。具体逐次Vitis/XSDB及两个独立保存/分析路径见[完整场景指南](../../firmware/r5/ax02a/FULL_SCENE_RUN_ZH.md)和首次指南第14节。motion原始目录预定board_manual/runtime_r1_motion_01，alignment/reset为runtime_r1_alignment_reset_01；两次完整实验均NOT_RUN，用户Review后手动执行并各自保存pre-begin。完整A4/A5/WCET未完成，不关闭Issue15、不合并PR16。没有重新生成模型/算法、修改参数、重建当前ELF、重复ABA、清理或连接板卡；全部workspace及原始数据保留。

### 2026-10-31：ABA实测闭合与Runtime 100µs R1候选

按[任务6541052405](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6541052405)执行T1—T3，任务原文在`coordination/tasks/ax02a_runtime_100us_r1.md`。T1独立提交`b46fdf6`：只读`board_manual/ttc_aba_01/{A1,B,A2}`各16000B/1000真实IRQ，raw=10000/9999/10000、experiment=1/2/3、同一构建3113983656/同会话且未中断。事件周期复算10000.999985476985／9999.999988308988／10000.999700386701 ticks；全窗口RAW_PLUS_ONE_COMPATIBLE、repeatable=true、issues=[]。证据在`verification/ax02a/ttc_aba_01/`。这支持本板TTC0内部同源100MHz、无分频间隔模式的映射，不是Runtime时间/完整A5验收，也不要求重采ABA或可选C。

同次T1正式修复XSDB地址4小端字节/单整数兼容及uint32序列化。逐字节检查长度/0..255，仍核对候选地址；邮箱值先核范围再转无符号，宽整数十进制写JSON。旧run.json只在PC内存中转换build_id及两个基址，原文件/样本不改；摘要保留转换记录，错地址/构建/越界/短读均有反例。先复现4项缺陷测试失败，修正后4/4通过，T1相关全套57/57通过。

T2提交`2aa9a9a`：自有`timer_mapping.h`限定通道/频率/分频/目标，`timing.c`先算logical10000再映射hardware9999；其他配置拒绝。timer.interval及快照保存真实raw，period_ticks、expected、deadline、释放超时、防回绕仍按10000；未改ISR、runner生产逻辑、算法或阈值。PC按mapping_version1及候选标识0x52313031严查9999/10000、时钟/通道/分频；历史无版本数据保留旧约定和旧趋势拒绝。新增正反例先失败后通过，HOST实际链接原生成Runtime并执行旧及logical10000的漏拍/超期退出合同。

T3真实离线构建于`.runtime/ax02a/vitis_runtime_100us_r1`，应用`ax02a_replay`（非TTC-only）。Vitis2026.1 SW6511674／R5 GCC13.4.0，复用原PS-only XSA、A53 FSBL→R5_0 split与原生成源、O2/FP/cache/默认布局。ELF32/ARM/v7-Realtime/VFPv3-D16/hard-float，入口0x3c；text46134/data5100/bss28216B，LOAD[0,0x7d8)、[0x100000,0x112e90)。heap[0x10c690,0x10d690)、主stack[0x10d690,0x111690)，其余栈至0x112e90，与回放/参考/报告DDR窗口无交叠。实际ELF两个候选常量与新被动manifest一致；启动检查在仓库根及新workspace按绝对config执行结果相同。

完整ELF/map在该workspace的`ax02a_replay/build/`；实际AArch64 FSBL在`ax02a_platform/export/ax02a_platform/sw/boot/fsbl.elf`；日志`.runtime/ax02a/vitis_runtime_100us_r1.console.txt`。BSP弃用和FSBL宏重定义警告保留，未改厂商源。精简构建/属性/日志/测试在`verification/ax02a/runtime_100us_r1/`。最终63/63相关测试通过，0失败/0跳过；独立审查无新P1/P2或Minor，先前纯文件R-profile属性复验限制仍在，实际本候选构建时readelf已通过。

状态OFFLINE_READY_FOR_REVIEW。新读回入口以被动候选记录核对实际ELF标识、开始前快照和timer，保留原4参数历史入口；新run带mapping/candidate、before_experiment及ELF来源，并保存output328000B/timing64000B/report_v2 2400B。Review后用户按指南第13节从开始菜单Set Workspace到main/WAIT，配置P1000和一次性后处理、begin前取证后移除断点，结束再读同次四文件并PC交叉；测量中不暂停/读写。Runtime候选板验T4=NOT_RUN，完整A4/A5/WCET仍未验收。无Simulink/生成代码/参数更改，无RTL/板卡操作，所有旧workspace/ELF及原始数据保留，PR保持Draft不合并。

### 2026-10-30 TTC-only T1—T3：OFFLINE_READY_FOR_REVIEW

按[评论6525374617](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6525374617)直接执行，原任务书在`coordination/tasks/ax02a_ttc_aba_characterization.md`。下文原“当前候选”属于历史相位回放应用；本轮新增独立TTC-only应用，不替代完整A4/A5。

T1先独立提交`1c55a3e`：只读`board_manual/phase_p1000_01`的328000B output、64000B timing、2400B report_v2及run.json，对照本地`replay/p1000/reference.bin`及metadata，确认experiment0→1、mode1、1000帧、state3/status0、interrupted=false。1000×41独立数值错误0，最大差4.336808689942018e-19；deadline_sequence=PASS，period_consistency=TREND_DETECTED，斜率+0.9977908489651977tick/frame。41字段、30组时间统计和相位摘要与板上v2一致，crosscheck_consistent=true。两条分析命令退出1表示周期拒绝，不是数值/构建失败。证据在`verification/ax02a/phase_p1000_01/`；开始前配置来源`.runtime/ax02a/ttc_pre_begin_01.json`，原始文件未改。

T2提交`e070bb6`：独立邮箱、固定16B×1000全局数组、真实IRQ采集、自由计数器超时与停转保护；分析器与合成故障测试先失败后实现。T3加入候选build_id、被动读回和新构建器。不调用/链接Runtime，不改生成代码、原`timing.c`映射、deadline与v2协议。nominal始终10000；9999仅为B条件。PC先从F−P窗口估计事件周期，再比较raw/raw+1；保留ISR相位、P趋势、窗口/残差/首尾、全部及排除第一真实IRQ的并列结果。异常不被过滤成根因结论，硬件IRQ loss=UNKNOWN。A1/A2不重复或候选/配置/会话不同即INCONCLUSIVE，阈值与限制见协议文档。

真实离线构建：Vitis2026.1 SW6511674／R5 GCC13.4.0，复用既有PS-only XSA，新workspace `.runtime/ax02a/vitis_ttc_characterize`，应用`ax02a_ttc_characterize`，launch=`ax02a_ttc_characterize_hw`。A53_0 FSBL为ELF64/AArch64；应用ELF32/ARM/v7-Realtime/VFPv3-D16/hard-float，入口0x3c，text24174/data5152/bss43228B，LOAD[0,0x7d8)、[0x100000,0x1113a0)。邮箱[0x10581c,0x105880)100B；数组[0x106b30,0x10a9b0)16000B；heap[0x10aba0,0x10bba0)、主stack[0x10bba0,0x10fba0)，IRQ等栈至0x1113a0。实际map核对不交叠，数组未放栈。保留原0x4000主栈/0x1000heap及BSP默认DDR策略，I-cache ON、D-cache OFF。

完整ELF/map在新workspace应用build目录，完整日志`.runtime/ax02a/vitis_ttc_characterize.console.txt`保留。BSP有xbasic_types弃用、FSBL有CRL_APB_RST_LPD_TOP宏重定义警告；应用无已发现编译警告，未改厂商源。精简证据在`verification/ax02a/ttc_characterize/`。纯文件启动检查从仓库根与新workspace使用绝对config实跑，结果一致，检查实际域/FSBL/ELF/launch及数组布局，不套ax02a_replay路径。

被动读回source只定义过程；用户到done显式调用才核对暂停R5、协议、本次experiment、case/raw、build_id及数组符号。已有目录拒绝覆盖，失败只读已完成记录并保留ERROR；不连接/选目标/复位/写寄存器/恢复运行、不读中断状态。run.json包含实际配置、时钟依据、候选/会话条件与中断声明，完整采集16000B，无需21MB输出或reference。

独立代码审查仅发现一项P2：分析器漏核本次timeout预算。新增错预算与超预算反例实际RED→GREEN修复，不改固件。P3暂缓：纯文件check的R-profile属性门禁弱于构建时readelf门禁；当前候选构建已实际验证Realtime/VFP，此限制不使本ELF失效，不能把check当任意替换ELF的完整属性复验。

最终实际验证：`python -m unittest discover -s verification/ax02a -p 'test_ttc_characterize.py' -v` 10/10通过；`python -m unittest discover -s verification/ax02a -p 'test_*.py' -v` 51/51通过，0失败、0跳过。覆盖原P1000/v2、HOST实际数据交叉、新合成故障、真实C HOST HAL与Tcl被动读回桩；这些不等于板上IRQ或GUI会话验证。完整测试输出见`verification/ax02a/ttc_characterize/tests.txt`，构建/布局与限制汇总见`validation.json`。

停在Review：用户Review后按`FIRST_BOARD_RUN_ZH.md`第12节从开始菜单Set Workspace，main→WAIT后逐次显式A1(10000)→B(9999)→A2(10000)，同一供电/会话/ELF，逐次停止读回，不自动三连跑。T4板验NOT_RUN、根因UNCONFIRMED、正式修复NOT_RUN，A4剩余场景与完整A5未验收。原三个workspace/ELF、用户模型/参数与所有原始数据保留；未操作板卡、未重跑RTL、未合并或关闭Issue15。

2026-10-30本轮先闭合exp2：按任务6516979286、执行确认6517272543及Review5708766094，只读新capture；1000×41数值PASS，最大差4.336808689942018e-19、数值错误0。run确认before1→experiment2/state3/mode1/1000帧/status0/completed1000/interrupted=false，本次timer100MHz/period10000/prescaler16。input/reference使用配套p1000，未取motion_03前缀冒充actual。旧分析器写入全新`.runtime/ax02a/analysis_exp2_legacy`；其timing PASS仅表明旧序号/截止期规则无异常，不能关闭周期漂移缺口。

新的精简证据在`verification/ax02a/p1000_exp2/`（summary/run/signals/events/timing）。ISR帧1..999相位OLS斜率0.999271094742 tick/frame，截距251.3174ticks，残差RMS15.0052ticks；0帧为软件epoch，排除。ISR读取时间不是中断边沿，尚不证明硬件N/N+1根因。**数值PASS／旧规则deadline-sequence PASS／period-consistency未确认，完整周期不接受**；不得继续将原始轨迹“无异常”解释为周期一致性PASS。旧数据/旧分析结果保留，下述早前actual缺失说明属历史阶段。


**2026-10-30 C1更新**：用户已在10月28日证明BOARD_BOOT/FIRST_WAIT通过（评论6459108843），10月30日提交motion_03完整数值PASS（评论6514447858）。本地完整output.bin及三份compare文件均存在；本轮只读原数据，调用原比较器写入独立`c1_recheck`再次通过。未连接硬件、未修改/重建当前调试ELF、未重跑RTL。此前启动失败与21MB单次读回中断仍属有效历史记录，以下历史NOT_RUN不覆盖本节新证据。

| 项目 | 本次结果 | 依据/未完成项 |
|---|---|---|
| A1 / TARGET_BUILD | **PASS（构建）** | 手册part的PS-only XSA继续复用；新workspace已构建A53_0 FSBL与R5 standalone BSP/应用ELF/map，离线启动架构检查通过。旧R5 FSBL不能用于当前GUI初始化；实物完整料号/修订仍待签核 |
| A2 | **生成/完整目标链接PASS；用户R5首次motion运行PASS** | 独立Cortex-R配置的同份生成C经官方R5 GCC13.4.0链接进新BSP；ARM32/v7-Realtime/VFPv3-D16/hard-float及装载段检查通过 |
| A3 | **离线PASS** | 原MAT64536帧完整导出，当前模型同输入参考与43100帧对齐/复位/故障参考；20/41字段、LE double全文件回读一致 |
| A4 / BOARD_REPLAY | **PARTIAL** | motion_03首次完整64536×41用户BOARD数值PASS，timing NOT_RUN；第二次独立motion及43100帧alignment/reset仍NOT_RUN |
| A5 / BOARD_PERIODIC_100US | **NOT_RUN** | P1000局部原始轨迹已按规则检查通过；完整A5尚未验收，不能据1000帧外推WCET |
| A6 | **离线成果PR** | 可提交源码、入口及精简证据；不能据此关闭板上验收 |
| BOARD_BOOT / FIRST_WAIT | **PASS（用户硬件证据）** | A53 FSBL退出＋状态0、R5入口/main/UART/WAIT，见评论6459108843 |
| 托管SIL/PIL、5EV综合/布线、AXI/ADC/编码器/PWM、实机、烧录/功率级上电 | **NOT_RUN** | 不从PS回放推导外设、电机闭环或功率级验收 |
| 完整RTL重跑 | **NOT_RUN** | 复用PR14原始记录，没有再跑c_rtl |

## 相位盲区修正与本机TTC核查（当前候选）

本轮先独立提交并推送exp2数据结论`1096f56daba0f811ada044c925a863a3598bde6d`，之后才修改诊断与构建。新增`release_phase`排除软件赋值k0，以ISR帧1..999的released−expected做中心化OLS和两遍残差统计；真实斜率0.999271094742tick/frame，截距251.3174ticks，残差RMS15.0052ticks，slope SE0.0016478563，筛查阈值0.011891146tick/frame，检出趋势。均值ISR间隔10000.91383ticks与OLS间隔趋势10000.99927ticks不同，均含ISR延迟，不能称硬件边沿周期或独立测频。

判据至少32个ISR样本，abs(slope)>6×残差标准误+2ticks/(n−1)时标TREND_DETECTED；两ticks是拟合跨度的计数分辨率余量，标准误项给固定噪声/随机抖动留余量，不强制斜率精确零。OLS噪声假设受相关ISR延迟影响，因此这是描述性趋势筛查，不能当“6σ频率证明”。不足样本标INSUFFICIENT_SPAN/NOT_RUN，不整体PASS。原序号/单调性/名义deadline检验独立保留，坏记录不通过过滤变成好拟合。PC和C分别提供deadline、period与aggregate状态，未更改数值容差或deadline。

实测与合成+1tick/周期反例均是数值/旧deadline规则通过但period拒绝；固定延迟、固定延迟+随机扰动对照不报趋势，负趋势也能检出。Python/C在同份exp2 actual/ticks上的结果一致：compare0、deadline0、period1、aggregate不接受；`crosscheck_consistent=true`不等于周期通过。新分析在`.runtime/ax02a/analysis_exp2_phase`，新HOST结果在`.runtime/ax02a/phase_host/exp2_crosscheck`；精简数据见`p1000_exp2/phase_diagnostic.json`和`phase_validation.json`。旧analysis_exp2_legacy和原始capture均保留。

### 本机驱动/时钟证据与真正未完成项

| 已只读核对的来源 | 事实 / 不能推导的结论 |
|---|---|
| 本机2026.1、BSP ttcps3.23 `xttcps.c` CalcIntervalFromFreq约599–625行 | InputClock/Freq，100MHz/10000→10000，prescaler16；没有隐藏的减1 |
| `xttcps.h` SetInterval约368行 | 直接写interval寄存器，没有自动N−1补偿 |
| `xttcps.c` SetPrescaler及SetOptions | 16关闭预分频；两个通道期望内部clock，周期interval模式、计数器自由计数 |
| ConfigTable / xparameters / platform_settings / psu_init | TTC0通道0/1为0xff110000/04，BSP均100000000Hz；PSS_REF33333000、IOPLL FB60/DIV2、LPD除10，配置ACT_FREQ约99.999001MHz。是配置链，不是测频；同模块共享上层选择，不能直接用BSP整数舍入解释相对每帧1tick偏差 |
| `xttcps.c`中InterruptHandler实际函数体 | 读取/应答中断状态并回调，没有每次ISR软件复位counter；不能按过时函数注释猜测行为 |
| 当前`bspconfig.h` | XPM_SUPPORT未定义，Release的XPm_ReleaseNode分支未编入，本次不能归咎节点释放 |

[UG1085 Interval Mode](https://docs.amd.com/api/khub/documents/xzMsp_c5sG9J6A3u7NkJYQ/content)说明等于interval时回零，但当前文字及驱动不足以单独判定实际边沿的N/N+1计数；**硬件根因未确认，本轮没有盲改9999，没有仅改logical_period_ticks或加宽deadline。** [TTC寄存器](https://docs.amd.com/r/en-US/ug1087-zynq-ultrascale-registers/TTC-Module)的clock/control/interval/IER可在开始前只读，ISR状态有清读副作用，排除。[IOU_TTC_APB_CLK](https://docs.amd.com/r/en-US/ug1087-zynq-ultrascale-registers/IOU_TTC_APB_CLK-IOU_SLCR-Register)选择上层接口时钟，[LPD_LSBUS_CTRL](https://docs.amd.com/r/en-US/ug1087-zynq-ultrascale-registers/LPD_LSBUS_CTRL-CRL_APB-Register)给出源与分频；实际板值须用户取证。

### 最小实现、协议及独立构建

`timing.c`保留原ISR/计时循环和raw interval10000/nominal period10000，改为不同变量名避免混淆；新增开始前只读`ax02a_ttc_snapshot`（52B），读取两个通道基址/Hz、clock/control/IER、raw interval及nominal period，并对当前内部未分频配置做失败拒绝。快照valid仅表示读回完成，非设置正确或周期PASS；物理根因仍等待用户GUI暂停begin之前的配置记录和独立复验。新后处理仍在timer停止之后，默认关闭。

报告v2=2400B，在v1的2336B后追加64B（两个状态、样本数、保留字、6double）；解码器保留v1历史读取但拒绝把旧mode1 timing PASS升级为周期通过。参考描述符仍32B/version1。报告区仍0x16000000，末地址0x16000960，与原input/output/ticks/reference/descriptor及ELF/栈堆无交叠。main/control旧字段不改；只读脚本source不执行，用户显式调用才读取非清读配置，需保留实际暂停位置，pre_begin字符串本身不证明PC状态。

实际Vitis2026.1新构建到`.runtime/ax02a/vitis_phase_diagnostic`，退出0；旧两个workspace/ELF未覆盖或重建。R5 GCC13.4.0、原O2/FP/double/cache/TCM布局策略不变，text45990/data5100/bss28216B、entry0x3c、LOAD[0,0x7d8)/[0x100000,0x112e00)。精简ELF与HOST证据为`phase_validation.json`/`phase_elf_attributes.txt`。独立只读审查覆盖最终代码/协议/指南及本机驱动，无P1/P2发现，并独立复跑41测试通过；未由审查者重建或操作硬件。41项相关测试通过；先观察缺失诊断失败，再实现；覆盖真trace/+1tick/固定延迟/随机扰动/负趋势/32ISR边界、短样本拒绝、v1不误放行、v2C/PC一致及只读脚本被动加载。没有重跑RTL或模型生成。

下一轮用户Review后先用新workspace到WAIT、装载/verify匹配P1000输入参考描述符、begin入口采只读配置后移除断点、再运行；完成后保存全量output/ticks/run、新2400B报告并交叉分析。具体GUI/命令在指南第8节。**验收盲区已离线修复；物理释放漂移原因/补偿仍待上述用户证据，候选上板与完整A4/A5仍NOT_RUN。** 不要求为离线任务持续供电，不自动连接板卡或合并PR。

## P1000追加实测证据：仅时间轨迹检查，整体未完成

C2/C3已提交9e846c0b6ee71598b8757b8682e6535d33697181后读取到用户[评论6515463934](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6515463934)：继续用旧基线ELF，before experiment1，结束experiment2、mode1、frames1000、state3、status0、completed1000、failed_frame0，con-block正常到完成断点。timer为clock_hz100000000/interval10000/prescaler16/period_ticks10000，读取计数间隔26/26ticks，start_window91ticks。未切到新后处理固件。

实际本地原始`p1000_01/timing.bin`64000B，1000×8uint64完整；原比较器时间规则检查序号、预期周期、帧内时间顺序和严格截止期均无异常。`verification/ax02a/p1000_01/timing.csv`列出all/ordinary900/speed90/position10及Python ceil P99。100MHz是BSP换算依据，非独立测频；冷/热状态未记录，26ticks=0.26µs只是读取间隔，91ticks=0.91µs只是启动窗口。

| 指标 | 最大观测值（µs） | 最差帧 |
|---|---:|---:|
| 纯Runtime | 38.42 | 699 |
| 本帧task | 54.11 | 709 |
| response（completion−expected） | 69.25 | 899 |
| start jitter | 16.49 | 994 |
| 最小slack | 30.75 | 899 |

同份C后处理在HOST对真实ticks的上述四类统计与Python一致（统计容差如C3）；因本次actual缺失，C数值输入仅用reference占位来调用接口，其数值结果和依赖actual的command/alignment分类**不作为验证证据**。没有在新固件目标上运行后处理。用户所指`motion_03/output.bin`核实仍为旧mode0的21,167,808B、时间戳11:18:27；本次ticks时间戳13:19:17。没有截取旧输出冒充exp2的328000B actual；新增回归测试确认该旧全长文件被门禁拒绝。

尚缺本次exp2输出以及独立保存的完整run.json/中断声明，后续由用户保持完成停点，按第6节工具读入全新目录（before_experiment1，按事实声明interrupted）。**P1000：运行自检完成/时间轨迹检查PASS，数值NOT_RUN、整体INCOMPLETE；不是完整A5或WCET，新后处理板上验证仍NOT_RUN。**

## C1：成功基线与P1000离线工具（2026-10-30）

执行依据为[评论6514858529](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6514858529)。用户motion_03的summary为origin BOARD、passed true、64536帧、numerical_failures0、timing NOT_RUN；必要原报告与来源说明保留在`verification/ax02a/board_motion_03/`，完整二进制仍在原.runtime路径。缺少本地独立保存的原邮箱run.json；state3/status0/completed64536/experiment1来自用户评论/截图转写。本机当前ELF355228B、时间戳10月28日；main副本与仓库无差异，ELF/map及实际编译配置只读核对，text41620/data5100/bss28136B、原O2/FP/cache/栈堆配置。没有独立证明板上所载文件的逐字节身份，不补写哈希或伪造运行状态。

前缀入口从current_motion的[0,1000)提取input160000B、reference328000B，Ts100µs、参数/字段/来源保留；不裁中段或重生成算法。实际产物`.runtime/ax02a/replay/p1000/`，精简metadata在`verification/ax02a/p1000_metadata.json`。读回Tcl被source只定义过程，用户显式调用才检查现有暂停R5目标及本次实验，再以≤64KiB块读328000B输出及64000B ticks；失败只读取completed_frames完整记录，保留failed_frame，不读取未完成尾部作有效证据。

分析入口先核对场景/模式/请求帧数/experiment递增/未中断/完整完成和文件长度，再复用原41字段比较与时间规则。失败实验不能靠正确前缀PASS。独立审查发现并修正中断标记P2：读回要求显式传入true/false，保留用户中断声明；Tcl生成中断记录后分析器拒绝的回归测试通过。时间报告含普通/速度到期/位置到期与事件分类、最大观测值/最差帧/P99（原ceil规则）/最小slack、计数读取和start_window及冷/热条件；无样本分类明确0。ClockHz为本次TTC配置换算依据，不声称独立测频。C1提交时P1000数据尚未提供；后续收到ticks的局部结论见上节，数值仍待本次actual；它不是完整A4/A5或WCET证明。

## C2/C3：结束后后处理及HOST交叉验证（2026-10-30）

C1先独立提交`64466414773038524dce40c120dd99434102e7e8`并推送PR16，之后才增加新固件。当前在用的`vitis_target_a53fsbl`及其10月28日355228B ELF未被重建或覆盖；新`.runtime/ax02a/vitis_postprocess`由Vitis2026.1/官方R5 GCC13.4.0实际构建成功，退出0。复用同一个XSA与独立Cortex-R生成源，不重生成模型/控制算法，不改cache/PI/采样周期/首相/O2/FP，不重跑RTL。

`postprocess.c/.h`只实现回放结束后的纯数值/时间统计，HOST和R5链接同一份C。main另加默认关闭的`ax02a_post_control`，一次性enabled1；原邮箱字段与mode/START_COMMAND保留。程序启动和每次实验使旧报告valid失效，`ax02a_replay`已经调用stop返回后才后处理；结果全部写完，release fence后最后发布valid，再到原完成断点。程序status、数值compare_status、timing_status分开；mode0的timing仍NOT_RUN。失败或不完整实验、长度/场景/模式/experiment不符均不能PASS。原始output/ticks不被后处理写入，failed_frame仍在原邮箱，失败帧不算完整有效记录。

数值覆盖全部41字段：有限EXACT用数值相等（±0相等），其他abs+rel各1e-9，NaN/Inf失败；每字段failure_count/max_abs/最差帧/first_mismatch/RMS和总体错误数全部保留。时间复用Python分类/边界，检查frame/seq/expected/单调/deadline（恰等deadline失败），给出6类别×5指标的数量、mean/min/max/最差帧；C版P99明确NOT_COMPUTED，不用均值冒充，Python可从原始ticks继续算ceil P99。timer的频率/读取开销/start_window仍从本次邮箱保存，配置值不是独立测频。

新布局：descriptor32B@0x12f00000；reference最大21,495,808B@0x14000000；报告2336B@0x16000000。实际XSA的DDR覆盖核对至0x17000000，各窗口与原input/output/ticks及ELF装载/栈堆无重叠；不排序，不另申请大工作区，沿用16KB栈/4KB堆。新ELF为ELF32/ARM/v7-Realtime/VFPv3-D16/hard-float，entry0x3c、LOAD[0,0x7d8)、[0x100000,0x112ad0)，text45225/data5100/bss28160B。原cache设置不变，但新布局和指令足迹已变化，不能继承旧ELF性能结论。精简证据在`postprocess_validation.json`及`postprocess_elf_attributes.txt`。

实际HOST交叉入口`ax02a_post_report.py host`使用motion_03完整output和current_motion reference，输出`.runtime/ax02a/c3_motion03_host/`：全部字段判定/错误位置/max_abs一致；RMS统计abs1e-15/rel1e-12，时间摘要abs1e-12/rel1e-9，仅用于统计一致性，不放宽PASS容差或截止期。HOST run身份来自用户评论转写文件，非自动采集。独立只读审查覆盖C2/C3代码、最终指南/API与新构建证据，无P1/P2发现；独立复跑32项测试通过，未重建或运行硬件。本轮相关32项Python测试通过，其中6项C后处理测试内部覆盖离散微差、连续容差内/外/边界、非零参考容差、NaN/Inf（actual/reference）、±0、缺帧/未完成/模式场景实验号错误、中断、重复/跳号、非单调、恰deadline、错误1ms，以及1000帧900/90/10分类及tie最差帧、报告协议/本次身份。真实motion_03仅用于数值HOST交叉；时间测试全为合成，不能输出为板上µs或WCET。

指南给出Review后的新workspace加载/WAIT、PC准备参考描述符、用户dow/verify参考、显式启用、完成后小报告读回、decode及全量P1000 crosscheck段。脚本导入/source均不连接板卡。**C2/C3离线构建/HOST通过；目标后处理及完整A5仍NOT_RUN；用户P1000后续已收到ticks但数值actual尚缺，见追加证据节；A4第二次motion和alignment/reset仍待补齐。** 本轮未连接/发现/暂停恢复/复位/下载/读写/运行任何板卡，PR16继续Draft，Issue15开放，不自动合并。

## 首次启动故障与离线修正（历史阶段）

依据[PR16故障分析评论](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6443462085)，用户两次自动launch均先选择`Cortex-A53 #0`，下载旧workspace导出的`fsbl.elf`后等待`XFsbl_Exit`超时。此次本机只读复查同路径FSBL实际为ELF32/ARM/v7-Realtime，平台`zynqmp_fsbl`域为`psu_cortexr5_0`，与日志的A53初始化核不匹配。这是离线可确认的缺陷；修正后的启动是否成功仍需用户重新验证。JTAG-HS1、xczu5/arm_dap和Bootmode0000已由用户日志确认；后来的R5 Suspended不能证明FSBL或DDR成功。没有增大timeout或修改控制算法来掩盖故障。

`scripts/ax02a_build_r5.py`改为显式`fsbl_target='psu_cortexa53_0'`，应用域仍为`psu_cortexr5_0 / r5_standalone`。复用既有`.runtime/ax02a/ps_target/ax02a_ps.xsa`及原Cortex-R生成C，在全新`.runtime/ax02a/vitis_target_a53fsbl`实际创建并构建platform、两个域的BSP、A53 FSBL和R5应用。命令为设置`AX02A_BUILD_CONFIG`至`.runtime/ax02a/build_config_a53fsbl.json`后执行`vitis.bat -s scripts/ax02a_build_r5.py`；实际退出码0。旧workspace、旧配置与旧`target_*`历史证据保留，没有打开IDE或启动硬件会话。

| 新工作区实际产物 | 本轮离线结果 |
|---|---|
| `ax02a_platform/export/ax02a_platform/sw/boot/fsbl.elf` | **ELF64 / EXEC / AArch64 / little-endian**，入口`0xfffc0000`，PT_LOAD均在OCM，存在已定义的`XFsbl_Exit` |
| `zynqmp_fsbl`编译 | AArch64 GCC13.4.0、`-DSDT -Os -DARMA53_64`；GNU size text64604/data3336/bss83024B |
| `ax02a_replay/build/ax02a_replay.elf`及map | **ELF32 / ARM / v7-Realtime / VFPv3-D16 / hard-float**，入口0x3c；R5 GCC13.4.0及原O2/FP配置 |
| 新应用布局/大小 | ATCM[0,0x7d8)、DDR[0x100000,0x111ca0)，与回放区无重叠；text41620/data5100/bss28136B，原主栈16KB/堆4KB、D-cache关闭/I-cache开启 |
| 新被动launch | `ax02a_first_wait_a53fsbl`，初始化A53 FSBL→R5_0应用；split、禁PL/另一条psu_init、Stop at entry；没有预装输入/发实验命令 |

精简新证据为`verification/ax02a/startup_validation.json`和`startup_elf_attributes.txt`；完整日志`.runtime/ax02a/vitis_target_a53fsbl.console.txt`。新增`--check-startup`只读检查域、**实际导出**FSBL架构、实际应用ELF、launch指向路径及应用核，在普通Python中运行，不导入Vitis客户端、不连接或发现目标。它对新工作区实际通过，对旧R5 FSBL实际拒绝；检查通过不等于GUI/板上已通过。新增9项启动门禁测试与原13项形成22项定向Python集。首次4项FSBL测试先复现缺失门禁失败；修复后通过，另覆盖域信息掩盖错误架构、错误FSBL路径、误将R5应用配置到A53等情况。

指南已将GUI主线切到新workspace和新配置，分别核对A53启动域与R5控制域；日志应先在A53执行新FSBL、再在R5加载应用。`downloadElf[].core`只选应用核，并不会让GUI改用R5运行FSBL；本机schema没有FSBL目标核字段，故以与用户日志一致的A53 FSBL修复，不是改文件名。FSBL状态仍需“本次退出点＋`0xffd80060`为0＋无错误”联合确认；GUI退出点后自动下载的既有限制保留。分段XSDB改成显式A53 FSBL→切R5应用，移除复位时不可见`RPU`分组的依赖；这些命令只作文本检查，未执行。

本轮不改生成C、应用控制/计时源码、模型、参数或参考，不重跑Vivado/RTL/主机数值回放。最终22项Python测试、实际`--check-startup`、10段Tcl文本`info complete`及`git diff --check`均通过。独立只读审查复核真实域/产物/配置/退出源码，并独立复跑22项测试、实际启动检查与diff检查，无P1/P2发现；没有重复构建或执行GUI/硬件。上板由用户本人完成，首次仍到已有等待消息与`state=1/experiment=0`即停止。**BOARD_BOOT/REPLAY/PERIODIC_100US保持NOT_RUN，明确保留旧启动失败，PR16继续Draft、不合并。**

下列“补齐组件后的真实平台与ELF”及“用户首次手动PS操作交接”是此前提交的历史阶段记录；其中旧R5 FSBL和旧首次配置已由本节新入口替代。

## 来源、工具与目标配置

保留用户已有Hybrid/Runtime/Reference SLX、`init_AXU5EV.m`和本地wrapper/S-function修改，未保存/覆盖这些模型，未将用户修改纳入本次提交。模型当前版本1.50；本次参考基于这些本地状态，不能称它们是PR14原算法/参数的已提交快照。

本次会话最初无已加载初始化参数，运行唯一`simulation/init_AXU5EV.m`一次。当前参数Vmax20mm/s、Amax200mm/s²、Jmax1000mm/s³、minRamp0.2s、速度设置变化率100；旧PR14为V10/A100/minRamp0.1/rate50。PI与采样周期未改：Ts100µs/1ms/10ms，Kp_ASR=0.018033474852681124、Ki_ASR=1.4426779882144898、Kp_pos=22。对齐仍10000/30000/2000拍与0.5A。

实际工具：MATLAB26.2.0.3386108/R2026b；Vivado2026.1 SW6511674；Vitis原HLS安装为SW6497934，用户手动增补Embedded后当前为SW6511674、官方R5 GCC13.4.0。主机MinGW64 GCC由已安装MATLAB支持包提供，主机构建`-O2 -fno-fast-math -ffp-contract=off`。此前使用既有STM32CubeCLT `arm-none-eabi-gcc`12.3.1完成对象编译，历史证据保留；本轮完整ELF使用新官方工具链。

`simulation/axu5ev_build_r5_target.m`查询本机`target.get('Processor','ARM Compatible-ARM Cortex-R')`后，复制活动配置集；ERT、C、nonreusable、GenCodeOnly。实际产物头注明`ARM Compatible->ARM Cortex-R`，little-endian、char8/short16/int32/long32/longlong64、word32、double64。仅生成C/H，没有交叉编译。退出已核对活动配置`Configuration`、`Intel->x86-64 (Windows64)`、Dirty=off，原fileGen目录恢复；PC生成目录/MEX不重建。两份新增.m的Code Analyzer检查无问题。

用既有Arm GNU12.3.1实际交叉编译了6个Runtime/bridge/runner对象并打包`libax02a_runtime.a`，选项`-O2 -fno-fast-math -ffp-contract=off -mcpu=cortex-r5 -marm -mlittle-endian -mfpu=vfpv3-d16 -mfloat-abi=hard`。readelf实际显示ELF32/ARM、CPU7-R、v7/Realtime、VFPv3-D16、VFP寄存器传参；精简证据见`verification/ax02a/arm_runtime_build.json`和`arm_runtime_attributes.txt`。Runtime单对象text6196B/bss852B；这是对象占用，**不代表含BSP/数学库/栈的最终链接占用**。

该静态库自身没有启动代码/BSP或可执行入口，不能冒称standalone ELF。后续本轮已通过`scripts/ax02a_build_r5.py`的Vitis2026.1 Python API路径创建真实平台并链接完整应用，见下节。独立`--runtime-only`路径仍使用上述已有GNU工具。生成日志的MinGW不是R5工具链；ARM运行仍**NOT_RUN**。

## 补齐组件后的真实平台与ELF

用户手动安装Zynq UltraScale+ MPSoCs与Vitis Embedded Development后，两条实际命令均退出0，未操作板卡：

```powershell
& E:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat -mode batch -nojournal -log .runtime/ax02a/ps_target.log -source hardware/axu5ev/ax02a_ps_minimal.tcl -tclargs xczu5ev-sfvc784-2-i .runtime/ax02a/ps_target 资料/course_s2/01_ps_hello/vivado/ps_hello.srcs/sources_1/bd/design_1/design_1.bd
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -s scripts/ax02a_build_r5.py
```

本地JSON由`firmware/r5/ax02a/build_config.example.json`复制，指向该XSA、既有独立Cortex-R生成目录与新workspace`.runtime/ax02a/vitis_target`。输出目录已存在；复验须换新目录并同步JSON，不重置或删除原工程。

厂商2020.1 BD不能直接载入新版目录。平台入口只复制其PS XCI，在本地副本运行官方`upgrade_ip`将3.3迁移到3.5，再以迁移后的参数创建新PS-only BD。已复现Vivado回调将全局`config`由3376项改成54项，导致参数字典被替换、DRAM退回8bit/UART未选；不能把该失败归为本板DDR不符。局部proc隔离构建状态后，DDR64bit/x16/8Gbit每颗/DDR4_2400P、UART0 MIO42/43及校验通过。只传硬件参数，排除GUI/接口与BD只读派生元数据；关闭非UART0/TTC0外设、全部fabric AXI、PL时钟/复位。厂商原件未修改，未综合、布线或生成bitstream。

真实平台配置：R5请求500MHz、配置499.994995MHz，PS参考33.333MHz。新SDT BSP给出TTC0三项，基址`0xff110000/4/8`、100MHz、编码IRQ`0x4024/25/26`；原生驱动直接采用各通道地址，执行层的前两项是独立通道。stdout/stderr选UART0 `0xff000000`。**均为平台/BSP配置，未测量硬件时钟或中断。** RPU split模式仍需授权启动时设置并验证。

Vitis实际建立`psu_cortexr5_0`/`r5_standalone`，构建BSP和R5 FSBL。应用包含同一生成C、既有bridge与`main/replay_runner/timing`；编译命令实际含`-DSDT -mcpu=cortex-r5 -mfpu=vfpv3-d16 -mfloat-abi=hard -O2 -g3 -fno-fast-math -ffp-contract=off`。未引入MEX、XSI、host main或`ert_main`，未修改生成算法。

| 实际产物/布局 | 结果 |
|---|---|
| XSA | `.runtime/ax02a/ps_target/ax02a_ps.xsa`，part `xczu5ev-sfvc784-2-i`，DDR窗口覆盖回放区 |
| 应用ELF/map | `.runtime/ax02a/vitis_target/ax02a_replay/build/ax02a_replay.elf`及同目录`.map` |
| 启动FSBL | `ax02a_platform/zynqmp_fsbl/build/fsbl.elf`，已检查为ARM可执行文件 |
| ELF | EXEC、ARM32、little-endian、入口0x3c、EABI5/hard-float、v7/Realtime、VFPv3-D16/VFP寄存器传参 |
| ATCM装载 | [0,0x7d8)，向量及启动数据；2008B |
| DDR装载 | [0x100000,0x111c80)，代码/状态/堆/栈；文件44692B、内存72832B |
| GNU size | text41588B、data5100B、bss28136B；包含启动、BSP、库及链接保留区 |
| 主栈/堆 | 16KB/4KB，另含BSP异常模式栈；不是动态栈峰值测量 |

两段均不与回放预留[0x10000000,0x14000000)重叠；采用默认BSP链接布局，热点代码/状态还未迁入TCM，不能先宣称100µs足够。精简证据为`verification/ax02a/target_build.json`、`target_elf_attributes.txt`、`target_map_excerpt.txt`；完整XSA/BSP/ELF/map/日志留`.runtime/ax02a/`。

完整构建产物又经独立只读审查：配置、三路TTC、Runtime/BSP链接与装载区无发现；13项定向测试本轮再次通过。**TARGET_BUILD=PASS；BOARD_BOOT/REPLAY/PERIODIC_100US仍NOT_RUN。**

## 用户首次手动PS操作交接（离线准备）

按[PR16最新评论](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6439330483)，新增`firmware/r5/ax02a/FIRST_BOARD_RUN_ZH.md`与`launch_first_wait.json`，README仅保留入口。指南用当前workspace解释XSA→platform/domain/BSP→ELF/map→FSBL初始化→R5_0→UART/邮箱，按目标识别、入口/main、WAIT分停点；第一次以已有启动消息和`state=1/experiment=0`为终点，不装载数据或发实验命令。

启动配置从当前2026.1生成的launch结构调整：保留匹配的R5 FSBL和split，关闭PL下载、另一条psu_init与trace/cross-trigger，启用Stop at entry。模板只作为被动配置；本地workspace追加同名首次配置，保留原配置，不启动调试。GUI字段由本机编辑器/schema及官方2026.1文档离线核对，未实际打开IDE点击验证。XSDB连接/初始化/加载/读写命令仅作为分段文档，由用户亲自执行；不是一键上板脚本。

UART从当前BSP与FSBL初始化核对为UART0 `0xff000000`、MIO42/43、约115200/8N1；不是照抄泛用教程的UART1。后续mode=0/1段要求先装输入、最后发command，完成停点核对本次experiment/status/frames后才读出，使用ELF符号访问邮箱，不猜地址偏移。性能窗口不设路径断点或进行读写/传输。

独立复核指出FSBL错误路径也会到达`XFsbl_Exit`，指南已修正为“本次退出点＋FSBL状态寄存器0＋无错误”才放行。当前FSBL的完成/错误标记为PMU `0xffd80060`；XSDB在应用下载前分段检查，GUI自动launch不能在退出点后按该值拦截下载，故明确其限制，并在应用入口暂停时检查后才Resume。没有把命中退出符号冒称初始化成功。

本轮仅做本地文件/配置/语法核对，不执行Vivado/Vitis构建、MATLAB、仿真/RTL、IDE、hw_server、XSDB会话或板卡操作。BOARD_BOOT/REPLAY/PERIODIC仍NOT_RUN，PR16保持草稿。

实际离线检查通过：所列XSA/FSBL/ELF/map/初始化文件存在，64536/43100帧输入与参考长度匹配，首次配置关键开关符合上述范围，10段Tcl仅以`info complete`检查结构完整性（作为文本，不求值执行）。独立复核所提FSBL成功判断P2已修正并复核无新增发现；语法和配置检查不等于命令已在硬件通过。

## 原始输入与当前模型参考

输入来自`.runtime/ax01c/c_fixed_continuous.mat`的真实`r5_snapshot`，输出历史参考为`r5_commit`；20/41列、同一时间轴、100µs步长、64536帧，末时6.4535s。Send翻转帧k=20915/21016/52999，对应2.0915/2.1016/5.2999s。未使用10ms抽样CSV插值。

`simulation/axu5ev_export_r5_replay.m`导出三个明确分开的场景：

| 场景 | 帧数 | 参考来源 |
|---|---:|---|
| `pr14_original` | 64536 | 原MAT，保持旧V10/A100输出，仅历史保留 |
| `current_motion` | 64536 | 原100µs输入/反馈不变，喂当前Runtime模型产生新参考 |
| `current_alignment_reset` | 43100 | 当前Runtime模型，手动Start、原五态完整计数、独立PI/PWM/Init/fault切换 |

`current_motion`是**当前Runtime在记录反馈上的回放参考**，未重跑电机对象闭环，不能称为当前新参数的电机闭环验收。历史PR14的10→0→−2mm闭环验收继续有效于其原版本。

输入逐帧20个double（运动10,325,760B），输出逐帧41个double（运动21,167,808B）；显式转置写little-endian，全部回读与原矩阵相等，包含首末帧和三次命令行。完整MAT/二进制/生成C和日志留`.runtime/ax02a/`；简明证据在`verification/ax02a/`。

## 数值结果（HOST，非ARM）

相同Cortex-R类型配置生成源、现有bridge及同一runner编译成主机程序，和当前Simulink Runtime参考逐字段比较：

| 运行 | 帧数×字段 | 最大绝对差 | 离散字段不一致 |
|---|---:|---:|---:|
| 运动实验1 | 64536×41 | 1.7763568394002505e−15 | 0 |
| 运动实验2（独立新初始化） | 64536×41 | 1.7763568394002505e−15 | 0 |
| 手动对齐/复位/故障 | 43100×41 | 0 | 0 |

运动接受3/拒绝1/段号3；三次发送结果2/3/2，首次Ready为1.9199/3.9599/6.3499s；末拍Ready仍0。逐信号max/RMS/首次不一致及事件见`verification/ax02a/host_motion_1`、`host_motion_2`、`host_alignment_reset`。连续量门限`1e−9+1e−9*abs(reference)`，布尔/枚举/计数/段号精确比较，非有限值失败。

对齐状态转换k=10→1、10010→2、40010→3、42010→4；完整原始10000/30000/2000拍。x=3.25mm，偏置5.942846103040692rad，一次性锁存；随后Init_Reset在k42300返回0、手动重启k42310、故障k42400返回0。软件序列不证明实物转子对齐。PI_Reset输入k42150–42160、PWM禁用k42200–42210与Init_Reset、fault分别施加。

比较器9项定向测试通过：相等、缺帧、离散微小差异、NaN、连续门限、有效计时、超期、漏释放，以及拒绝将1ms周期误判为100µs通过。独立审查发现最后一项缺口，先复现失败再修复：实际周期只能偏离100µs至多一个源时钟tick。通用runner链接真实生成源的测试通过：k0在epoch、漏释放停止、超期停止。合成计时测试只验证判错逻辑，不能转换成R5实测µs。

完整Python定向集现为13项（上述9项及4项可执行文件门禁：ARM可执行格式、拒绝重定位对象、拒绝A53、拒绝DDR缓冲重叠），均通过。新增通用GNU ARM对象编译模式实际执行通过并自行检查产物；独立审查覆盖首个实现提交，未对该后加模式作第二轮审查。已修复审查唯一P2；没有遗留小项。硬件/BSP/链接真实性未获判定，继续保持NOT_RUN，错误成本不会被主机测试抵销。

## 平台依据与此前失败记录

用户确认核心板参考`ACU5EV核心板原理图.pdf`、底板参考`AXU5EVB-E开发板原理图.pdf`；底板与AXU3EG共用，标题不能据此否定。用户实物确认以太网收发芯片JL2121；本阶段不使用以太网。芯片以用户指定的《AXU5EVB-E开发板用户手册》PDF p10–11为依据：`XCZU5EV-2SFVC784I`，Vivado器件名`xczu5ev-sfvc784-2-i`；实物PCB修订尚未提供。

手册p11：PS DDR4为4×MT40A512M16LY-062E，64bit/4GB；p20：PS参考33.333MHz；p39：UART0 MIO42/43。厂商hello BD对应64bit、16bit DRAM、8192Mbit/颗、DDR4_2400P及MIO42/43。原BD实际R5请求500MHz/配置499.994995MHz、TTC0100MHz，**不是当前平台配置或实测频率**。厂商XA/-1仍与手册XC/-2不同。

补齐组件前的真实执行记录保留：

- Vivado最小平台入口在`get_parts xczu5ev-sfvc784-2-i`报`part unavailable`并退出；额外只读`get_parts *zu5*`为空。没有改用XA或其他芯片生成“通过”平台。
- Vitis2026.1 Python API用厂商旧XSA做一次独立R5域探测，原中文路径与ASCII复制路径均在`Error in generating SDT`退出；探测XSA不是新目标交付。没有调用XSCT或原位升级厂商工程。
- 当时目标构建入口preflight实际报`missing PS-only XSA`并返回非零，原2026.1安装没有R5 GNU编译器。

历史日志：`.runtime/ax02a/ps_minimal.console.txt`、`parts.console.txt`、`probe_vitis_ascii.log`、`r5_preflight.txt`。用户补齐组件后上述环境阻塞已解除；成功日志为`ps_target.console.txt`和`vitis_target.console.txt`，未重跑RTL。

## 板上待验收与可复用点

`firmware/r5/ax02a/main.c`为已链接的standalone回放应用，等待内存命令后执行；D-cache关闭、I-cache开启，输入/输出/计时DDR窗口与ELF装载段已核对不重叠。实际DDR初始化/容量/可达性、split启动、时钟和中断运行仍须上板核实。

`timing.c`依BSP表选择两路TTC，第一路释放、第二路独立计数。ISR仅记录时间/递增序号；唯一前台执行Runtime。检测丢拍/重复/序号与独立时间，失败停止。记录预期/实际释放、开始、纯Runtime与完成；比较器可生成普通/速度/位置/命令/对齐分类的样本数、均值/P99/max/最小slack。计数频率、读计数开销、周期量化、启动窗口和真实帧记录均待板上采集，**当前无任何R5执行时间或截止期通过结论**。

最短实际入口、数据格式、目标源码边界和待验证启动条件见[应用README](../../firmware/r5/ax02a/README.md)。板卡复位、JTAG加载/运行需要本次明确授权与连接确认；功率级保持隔离。未加载PL镜像、未写启动介质、未上电功率级、未自动合并。A4/A5完成后才能判定BOARD_REPLAY/BOARD_PERIODIC_100US，不能以本报告的主机结果关闭Issue15。

实现所用API依据为本机Vitis2026.1 Python源码/示例与SDT TTC3.23驱动，以及[AMD UG1400迁移说明](https://docs.amd.com/r/en-US/ug1400-vitis-embedded/XSCT-to-Python-API-Migration)、[官方TTC例程](https://xilinx.github.io/embeddedsw.github.io/ttcps/doc/html/api/xttcps__intr__example_8c.html)。
