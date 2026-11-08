# AXU5EV — 当前交接

更新：2026-11-08，仓库kazecode666/AXU5EV，本地D:/Project/AXU5EV。

## 当前：Issue35 ADC 单源组件与统一PL入口整理

2026-11-08，分支 `codex/adc-source-consolidation` 明确接续 PR33 已审查 head `07e245c0919645b7049b4414d0f6549b9d9c7256`（启动时PR33仍Draft，未自动合并）。本轮为独立整理PR，不重新开发B3，不进入PWM/ABZ。

共享组件为 `simulation/AXU5EV_PL_Algorithm_Library.slx/Current_Preprocess`；新 `AXU5EV_ADC_HDL` 与 `AXU5EV_ADC_Observer` 均库链接引用它。MATLAB Function只调用原权威数值源 `simulation/real_io/ax03b1_current_preprocess.m`，没有第二套公式。唯一生成入口 `simulation/adc/adc_generate_hdl.m`，活动生成物 `generated/adc/AXU5EV_ADC_HDL/` 两份SV。用户修改的原 `AXU5EV_RealIO_NoPower.slx` 保留，不作活动生成源；新观察壳从PR33已审查模型建立。

统一PL入口为 `hardware/axu5ev/motor_control/build.tcl`，源清单 `sources.list`，PS/AXI/时钟复位/ILA装配 `bd/adc.tcl`，手写RTL和XDC按功能归集；旧B3入口薄转发，历史重现调用路径已同步。所有采样节拍、数值、一级延迟、寄存器/帧身份、REAL/TEST和物理许可语义保留。

实际模型检查/HDL生成PASS，42项数值检查、49行×14输出一级延迟对比、原4×20观察记录一致；B3短RTL2064帧及定向数值RTL25检查PASS，含两轮1024完成/restart断言。新REAL候选 `.runtime/adc_consolidation/hardware_real_01` 完成BD验证/综合/源与约束命中核对；实现、新bitstream、R5重建、旧全量回归和板卡操作NOT_RUN。本次无新可上板产物，保留PR33原bit/XSA/ELF及全部旧工作区/数据，不能沿用旧布线时序宣称新候选已实现。综合态debug/PS未约束项保留，详见精简结果。

唯一[入口与旧新路径说明](../hardware/axu5ev/motor_control/README.md)，[精简结果](../verification/adc_consolidation/results.json)。已提交[kazecode666/AXU5EV Draft PR36](https://github.com/kazecode666/AXU5EV/pull/36)，base为PR33分支，当前停止等待Review。Git HTTPS连续失败后改用连接器发布：远端实现提交`e4a237edfed92119a41b0be651ac005ab9c071a9`与本地`77b0362`实现树一致；本地原历史保留，未强推/reset，后续网络恢复可正常fetch/merge保留双方历史。用户原5个修改文件和2个未跟踪文件保持原样；不改旧FOC/Runtime/电机参数/PI。提交Draft PR后停止Review，不自动合并或关闭Issue。

以下B3/板测相关状态为原阶段记录，不作为本轮新运行结果。

## 当前：AX-03B3 双路校准与电流观察离线集成

PR33最新Review [5817361622](https://github.com/kazecode666/AXU5EV/pull/33#pullrequestreview-5817361622)最小收尾已完成：硬件脚本默认REAL输出统一为hardware_real_02；现有短测试补齐两轮A/B首次done各count==1024，以及restart消费并输出更新后两路count/done清零断言。仅新跑 `.runtime/ax03b3/review_5817361622_01`，2064帧、4次首次done和1次restart清零检查PASS，原检查保留。没有实现错误；本次综合实现/R5重建/HDL生成/旧全量回归均NOT_RUN，以下硬件和R5结果为原交付记录。原产物/工作区/用户修改保留，板卡操作NOT_RUN；推送同一PR33后继续等待Review。

2026-11-08，执行[kazecode666/AXU5EV Issue32](https://github.com/kazecode666/AXU5EV/issues/32)，基于已合并PR31的main `810939798c76ed66ee8f96a450d5283f6b6f3656`，分支 `codex/ax03b3-current-observer`。B1生成数值链接入B2采集；新增最小参数提交/显式重校准、R5观察及固定TEST输入。数值源/生成SV、电机参数/PI/旧FOC不变。

新增2064帧RTL集成验证PASS。REAL/TEST综合实现均PASS：WNS +1.361/+1.757ns，WHS +0.015/+0.012ns，TNS/THS均0，bit/ltx/含bit XSA已生成。工作区分别`.runtime/ax03b3/vitis_real_01`与`vitis_test_01`；R5最终结果以[主报告](reports/ax03b3_current_observer.md)和[精简证据](../verification/ax03b3/results.json)为准。唯一[操作说明](../firmware/r5/ax03b3/FIRST_RUN_ZH.md)。已提交[kazecode666/AXU5EV Draft PR33](https://github.com/kazecode666/AXU5EV/pull/33)，实现提交`90f70e62803c9e7de49e24d42793f8154e2279bf`，REAL/TEST R5构建及被动启动检查均PASS。当前停止等待Review，不自动合并。

无MBDL4驱动板，全部板卡发现/连接/下载/运行NOT_RUN。TEST绕过模拟前端和ADC针脚，不作为真实标定；默认gain仅数字测试比例，physical_link_verified仍0。原5个用户修改文件、2个未跟踪文件及全部Workspace/数据保留；B2零流原始记录仅作历史观测归档。完成Draft PR后停止Review，不合并、不关闭Issue、不进入其他阶段。

以下B2待Review为历史：PR31现已合并。

## 当前：AX-03B2 J15最小ADC工程离线完成，待Review

已提交[kazecode666/AXU5EV Draft PR31](https://github.com/kazecode666/AXU5EV/pull/31)，关联Issue30，实现提交`95678fac7184923dca4b293118dfcba13d608f17`。实现提交已通过普通Git完成；最后交接链接补丁因Git HTTPS及连接器文件写入失败改由GitHub API发布，本地历史保留。后续正常fetch/merge保留双方历史，不强推或reset。旧B1连接器映射保留作历史；当前停止等待Review，不自动合并或操作板卡。

按用户启动的[kazecode666/AXU5EV Issue30](https://github.com/kazecode666/AXU5EV/issues/30)，从含已合并PR29的`origin/main 33f8237ad0d3fa08b9eac4b9fa5c97f0cf241e8d`建立`codex/ax03b2-adc-j15`。新采集RTL、J15逐针表/XDC、B1快照复用和最小R5 UART应用已实现；新增接口9482项短仿真通过。独立Vivado bit/ltx/含bit XSA与最小R5 ELF均已实际构建通过；WNS +1.826ns/WHS +0.014ns、TNS/THS=0，ADC输入setup/hold +1.826/+5.516ns。应用0警告/0错误、既有启动检查PASS，唯一Workspace `.runtime/ax03b2/vitis_adc_01`、Launch `ax03b2_adc_manual`，BSP实际地址0x80000000。保留的IOB/debug hub DRC及26项TIMING-18 methodology警告已按实际pad时钟合同说明；实际结果以[本轮报告](reports/ax03b2_adc_j15.md)为准。

唯一现场入口为[首次板测指南](../firmware/r5/ax03b2/FIRST_BOARD_RUN_ZH.md)。本轮只离线完成、提交Draft PR后停止：板卡操作NOT_RUN，无真实输入结果；不接驱动板/电机/真实ABZ/功率级，不改参数/PI/FOC/Runtime，不重跑PR24/B1全量、不重生数值HDL、不保存用户SLX。保留5个已修改文件（含B1观测SLX）、2个原未跟踪文件及全部旧Workspace/实验数据。

PR29已合并。以下为当时交付/Review历史，原停止点及未授权措辞不替代本轮Issue30明确授权；不据此重复旧实验或硬件动作。

## 历史：AX-03B1离线无功率反馈观测链完成，待Review

PR29 Review P2（[discussion_r4478150575](https://github.com/kazecode666/AXU5EV/pull/29#discussion_r4478150575)）已在原分支修正：ABZ理想参考首次输入建立AB/Z基准，无虚假位移/非法/Z事件，正确RTL不改。MATLAB定向矩阵32用例/896检查、原名义4帧及非零初相/Z高模型两次各5帧通过，数值42项同次复跑通过。[独立修正证据](../verification/ax03b1/abz_startup_results.json)保留原始结果，详情见主报告新增小节。未修改/保存当前已变更的观测SLX，未改电流数值源/生成SV/RTL，HDL生成和RTL回归本次NOT_RUN；所有用户修改和数据保留。修正提交仍交PR29复审，B1停止边界不变。

按用户明确启动的[Issue28](https://github.com/kazecode666/AXU5EV/issues/28)，从包含已合并PR27的`origin/main d3a10cf627b55984c16fc58a5e6d56b991ea27a5`建立`codex/ax03b1-feedback-observer`。独立`simulation/AXU5EV_RealIO_NoPower.slx`、模型生成两相电流预处理、薄RTL双ADC/ABZ和原子只读快照已实现，未接完整控制Runtime或FOC。见[实施报告](reports/ax03b1_feedback_observer.md)、[执行记录](tasks/ax03b1_feedback_observer.md)和[精简证据](../verification/ax03b1/results.json)。

42项MATLAB参考检查、新模型4条20字段一致观测、数值HDL生成及结构检查通过；新增RTL的ADC/ABZ1341项、32/40字快照81/89项、生成数值25项、整链508项/最小间隔580项通过。实际RTL测试发现并从模型源修复生成的有符号下界比较差异，未手改SV；原失败日志仍留本地。两份生成SV输出同组1拍，整链保留采样时刻的位置/Z历史。运行入口及具体PASS/NOT_RUN口径见报告。

已发布[kazecode666/AXU5EV Draft PR29](https://github.com/kazecode666/AXU5EV/pull/29)，关联Issue28，当前停止等待Review。本机Git HTTPS连续连接失败，使用已连接GitHub服务发布：远端实现提交`d3835aeed0d680a94f841b0f9a1c3ee2bdf33e22`与本地原实现提交`bc35d03b9b2fb90af980dddb1213a85a603eeea0`的Git树一致。本地提交历史未改写，用户文件不受影响；后续网络恢复时正常fetch/merge远端分支保留双方历史，不强推或reset。交接链接另有文档提交。

双独立offset binary、七转换事件、候选时钟与滤波均SIM_ASSUMPTION；物理link_verified保持0，PWM六路/ENCON/RELCON/F_Reset/run_permission固定禁止。无板卡发现/连接/复位/下载/运行，无真实标定、板级XDC/STA/物理CDC签核、综合/布线或新Vitis工程；未重跑PR24，不改AQM/AUM参数、PI、已接受FOC、旧模型或数据。原4个修改文件和2个未跟踪文件仍保留且未纳入。完成本轮Draft PR后停止，等待ChatGPT Review；G1—G8未解除，不自动合并/关闭Issue或进入AX-03B2/C。

PR24和PR27现均已合并；以下“PR24待Review”等为当时归档原文，只作历史，不要求重新板测或执行旧关机指令。

## 历史：2026-11-04 PR24 perf_r1完整实板签收

2026-11-04，按PR24评论6622743887归档用户已完成的perf_r1单次current_motion实板：身份0x43324302，64536条完整处理、2645976个Runtime值原判据零失败、193608个duty位串零差，帧/命令/采用及完整停止PASS。PMU7812421Hz：Runtime均值/最大25.025/39.040us，上一read_begin到下一commit_end均值/P99/最大70.204/83.457/86.017us；COMMIT后328B日志及返回开销均值/最大9.245/10.880us，计入日志的完整窗口均值/P99/最大79.449/92.929/95.617us。后者204条超名义93.68us但提交在先、实际采用均正确，不能宣称全部软件工作在93.68us内完成或WCET。原失败k1200提交95.873us，新同记录75.009us，含日志窗口96.257→84.481us。

本机只读复核全量output/PL/PMU及原有摘要，结果一致。回放计时6.453738s；上传/下载29.616512/22.052247s，1000Mbps，UART确认RESULT_READY status0/completed64536。Runtime相对参考最大差1.7763568394002505e-15（原容差通过），不误称ARM/PC逐位相同。旧TTC timing NOT_RUN为不适用；板报二进制保留其原未验证标识。

实际Workspace`.runtime/ax02c2/vitis_runtime_pl_perf_r1`、Launch`ax02c2_runtime_manual`不变，仍复用native64平台/BSP/FSBL及hardware_02。原始实板数据`board/current_motion_perf_r1_01`已占用；[本次精简证据](../verification/ax02c2/board_perf_r1_01/README.md)及[主报告](reports/ax02c2_runtime_pl_replay.md)记录完整分布和原失败对照。[唯一指南](../firmware/r5/ax02c2/FIRST_EXPERIMENT_ZH.md)保留已执行步骤，当前不要求再次加载/START。

本轮只读取已保存数据归档；未连接/操作板卡，没有新的构建或测试。保留current_motion_01、current_motion_01_fail1200_backup及全部Workspace/用户模型/数据；PR24未合并，交用户最终Review，不关闭Issue15、不因旧指令再次关机。以下候选NOT_RUN、待上板和关机交接均为历史。

## 历史：AX-02C2初版离线交付，板测当时NOT_RUN

已正常提交并推送[kazecode666/AXU5EV Draft PR24](https://github.com/kazecode666/AXU5EV/pull/24)。用户已说明会接回原ETH02直连网络，随后最新指令为完成离线实现后关闭计算机；本轮据此不执行C2加载或实板实验，板测留待后续继续。完成交接推送后正常关机，不强制关闭或代保存未保存窗口。保留已有模型修改和所有产物，PR待Review、不自动合并。

真实Runtime每逻辑100µs一次，输出41字段送原模型生成薄适配，经现有AXI-Lite提交真实PL FOC。PL完整5000拍帧调度，记录0先计算后START，当前结果后预装下一记录，最后完整STOP；不启用独立TTC IRQ。同源current_motion64536条、20输入/41参考、feedback5及新model_fixed duty参考已备好；最终生成C709896+88word零差。复用原ETH02上传/停GEM/执行/冻结/恢复下载，只增加feedback9/PLresult10和C2身份。

原生Vitis最终build PASS，应用0warning，ELF1015452B、A53FSBL341352B，现有启动检查和实际map/对象区核对PASS。唯一Workspace`.runtime/ax02c2/vitis_runtime_pl_native64`，Launch`ax02c2_runtime_manual`，build0x43324301；复用原`.runtime/ax02c/hardware_02` bit/XSA，没有Vivado/旧RTL/C1/ETH02板测重跑。数据`.runtime/ax02c2/prepared_04/data/current_motion`，最终适配源`.runtime/ax02c2/adapter_native_01`。

见[主报告](reports/ax02c2_runtime_pl_replay.md)、[唯一指南](../firmware/r5/ax02c2/FIRST_EXPERIMENT_ZH.md)、[精简证据](../verification/ax02c2/)。用户已说明将接回原ETH02直连网卡并设192.168.50.x；按其最新离线交付后关机指令，本轮不加载或运行C2，未改OS网络设置；C2 BOARD_NOT_RUN，不能引用C1成功替代。保留全部旧Workspace/SLX/参数/数据，不自动合并或关闭Issue15。下文为历史阶段记录。

## 历史：AX-02C1 AUX复位修复及一次授权17帧实板PASS，PR22现已合并

原hardware_01的AUX reset低有效却接零，导致SmartConnect/FOC持续复位；最小改接one/dout，debug reset仍为0。hardware_02完整构建/启动文件检查PASS，WNS+3.149ns、WHS+0.011ns、TNS/THS=0，时序失败端点均0；原Workspace/ELF/FSBL和全部数据保留。

用户明确批准一次系统复位、加载新bit与原FSBL/R5 ELF及一次17帧。新实验首读实测：PC0x001031BC、r6=0x80000000，单步到0x001031C0返回r2=0x43314301；继续同一次实验，只发送一次s，最终PASS code0/fail_frame0/frames17/complete_frames17/compared51/mismatch0，elapsed_ticks13290、tick_hz7812421。原挂起现场没有取得PC；新首读实测不能倒记为旧现场PC。[当前实板证据](../verification/ax02c/board_aux_fixed_01/evidence.json)，原始UART`.runtime/ax02c/board/uart_17_aux_fixed_01.txt`；构建JSON中的BOARD_NOT_RUN仅为构建时快照。

实际bit/XSA在`.runtime/ax02c/hardware_02`，沿用Workspace`.runtime/ax02c/vitis_ps_pl`、Launch`ax02c_foc_manual`、原R5 ELF及A53 FSBL。启动检查配置`firmware/r5/ax02c/build_config.aux_fixed.json`；manual入口programDevice=false、未启用bitstreamFile已备份并清空，必须显式选新bit，不能用默认app_hw_1自动加载旧镜像。唯一入口见[指南](../firmware/r5/ax02c/FIRST_BOARD_RUN_ZH.md)，详细经过见[主报告](reports/ax02c1_r5_axi_foc.md)。

最终stop成功，R5_0停0x0010333C（末尾WFI），DSCR0x03186003/HALTED=1，无APB错误；A53_0仍停FSBL出口，R5_1 Reset，其余A53 PowerOnReset。Codex已disconnect并退出自建XSDB31752，3121仅hw_server30848监听、Established连接0，可由用户单一Vitis会话接手。本次在线操作完成，进一步系统复位/下载/破坏现场写入仍须另获确认。不重复本轮实验、不扩展完整Runtime/ADC/编码器/门极PWM或压力/优化项目。PR22保持Draft等待最终Review，不自动合并、不关闭Issue15。下文为历史阶段记录。

## 原离线阶段：AX-02C1离线实现/短仿真/完整构建及启动检查PASS，待Review

已推送[kazecode666/AXU5EV Draft PR22](https://github.com/kazecode666/AXU5EV/pull/22)，停在Review，不自动合并。

[主报告](reports/ax02c1_r5_axi_foc.md)，[用户唯一指南](../firmware/r5/ax02c/FIRST_BOARD_RUN_ZH.md)。复用真实p3核和原帧封装；新增AXI-Lite暂存/整帧采用/三相来源快照与R5轮询。短仿真17帧/51个duty/85000clocks/283399检查PASS；真实M_AXI_HPM0_LPD地址0x80000000，单一名义50MHz PL时钟，工具回读49.9995MHz。新产物.runtime/ax02c，完整bit/XSA/FSBL/R5 ELF及启动文件检查已PASS；WNS+3.160ns/WHS+0.011ns，TNS/THS=0，时序失败端点均0。实际Workspace为.runtime/ax02c/vitis_ps_pl、Launch为ax02c_foc_manual；完整产物及顺序见唯一指南。板测NOT_RUN，由用户Review后手动加载、释放PS—PL隔离/复位并显式发送UART s开始；Codex不操作板卡。保留原workspace、ELF、用户修改及实验数据，不接完整Runtime、不自动合并或关闭Issue15。

## 已合并基线：AX-02B生成/位与帧合同、5EV OOC内部实现PASS

[唯一主报告](reports/ax02b_pl_current_core.md)。冻结p3源、配置及29份设计RTL已独立5EV生成并确认字节相同；原normal/reset/CE检查通过，新帧探针21帧/518436检查通过，核心314/捕获315、全5000拍保持、sticky valid和三类复位职责有证据。50MHz/100µs/50µs参考边界不改。候选.runtime/ax02b/candidate_01，验证checks_02及checks_03；实际实现.runtime/ax02b/implementation_01/routed.dcp；WNS+3.020ns、WHS+0.034ns、TNS/THS=0，setup/hold/pulse失败端点均0。资源69945 LUT/81057 FF/431 DSP，CLB占用85.25%。仅理想时钟OOC内部数据路径通过，HD.CLK_SRC/外部IO预算未指定，真实时钟树和整机时序未签核；详见主报告。

目标器件xczu5ev-sfvc784-2-i已由本机get_parts确认，实物料号/PCB签核仍未完成。该阶段仅模块OOC，尚未接AXI/ADC/编码器/门极PWM；原R1/ETH01 r3/ETH02及全部数据保留。[kazecode666/AXU5EV PR20](https://github.com/kazecode666/AXU5EV/pull/20)现已合并；本轮AXI集成状态见本文首节，Issue15遗留项不自动关闭。

## 已合并基线：ETH-02两场景用户实板PASS

[已合并PR18](https://github.com/kazecode666/AXU5EV/pull/18)，[实现结果及用户实验唯一入口](../firmware/r5/ethernet_runtime/FIRST_EXPERIMENT_ZH.md)。真实输入/参考/描述符经以太网上传，START回执与连接收尾后停GEM收发/DMA/IRQ，原TTC0/Runtime回放与后处理完成后冻结结果、恢复网络并计划内重连下载，自动调用原分析工具。新固件身份0x45303201，原计时映射/数值与时序判据不改。新XSA同时启用GEM3与TTC0，复用JL2121 r3、原冻结生成代码及数据。

实际Workspace为`D:/Project/AXU5EV/.runtime/ethernet/eth02/vitis_runtime_ethernet`，应用eth02_runtime，Launch **eth02_runtime_manual**。必要Vivado/Vitis构建与现有启动检查通过，Python语法与MATLAB Code Analyzer通过；[精简启动证据](../verification/ethernet/eth02/startup_check.json)。两次ETH02整合板测现均用户实板PASS，见[精简归档](../verification/ethernet/eth02/board_results/README.md)及[当前状态](../verification/ethernet/eth02/status.json)。

按[评论6596653379](https://github.com/kazecode666/AXU5EV/pull/18#issuecomment-6596653379)，同一应用current_motion实验1/64536帧、current_alignment_reset实验2/43100帧均完整完成；41字段零失败、截止期/序号及相位PASS、板报crosscheck一致。最大/P99响应分别62.33/59.92与39.17/36.52µs，最小slack37.67/60.83µs；上传/下载28.74/22.13与18.87/13.71s。原始数据保留在.runtime/ethernet/eth02/board两个01目录，已占用且无需重跑。本轮仅精简归档和状态更新，不测试、不重建、不上板；原R1/ETH01 r3及全部数据保留。PR18保持Draft待最终Review及用户决定合并，Issue15保留，持续遥测/PL集成后续另行安排。

## 已合并基线：ETH-01用户实板PASS

入口：[实板精简证据](../verification/ethernet/eth01/board_r3/README.md)、[用户分步上板指南](../firmware/r5/ethernet/FIRST_BOARD_RUN_ZH.md)、[板级/SoC复用报告](reports/eth01_platform_and_soc_reuse.md)、[阶段状态](../verification/ethernet/eth01/status.json)。用户已在`.runtime/ethernet/eth01/vitis_ethernet_r3`完成PS J6/JL2121板测，应用eth01_tcp、launch eth01_tcp_manual_r3、构建身份0x45303103不变。PHY ID=937c4032、PHYSR=0x182e、1000Mbps全双工、TCP_READY；PHY_LINK/TCP_IO/MODEL_BOARD_IO/BULK_TRANSFER均为用户实板PASS。small的0/1/255/256字节生成模型往返通过，计数0→4；64KiB/1MiB/32MiB完整性均PASS，上传/下载分别0.994/1.371、1.019/1.455、0.990/1.412MiB/s。32MiB耗时32.33/22.67s，64KiB和32MiB上传未达1MiB/s目标，如实保留，本轮不优化。

本轮只读核对四份本地result.json及三份readback.bin长度，精简归档四份JSON和文字摘要；逐字节内容/报告CRC一致的完整复核来自评论所载ChatGPT对board.zip的检查。本机SoC消息探针、实际C Caller目标模型、既有构建/启动检查证据保留，未重跑测试、生成模型或重新构建。原始大二进制留`.runtime/ethernet/eth01/board`，r2/旧R1及所有历史候选不动。PR17保持Draft待最终Review和用户决定合并；不操作板卡、不接完整Runtime、不替R1并发时序背书、不关闭Issue15。断链恢复和性能优化留待后续按实际需要安排。

## 当前入口

- [工作区、上板工程与数据保存位置](../docs/WORKSPACE_GUIDE_ZH.md)：目录职责、完整ELF/FSBL路径、数据命名和ChatGPT交接。
- [首次指南第14节](../firmware/r5/ax02a/FIRST_BOARD_RUN_ZH.md#14-runtime-r1完整场景review后用户逐次执行)及[完整场景操作步骤](../firmware/r5/ax02a/FULL_SCENE_RUN_ZH.md)：已完成两个场景；链接保留操作来源，当前以本次汇总及最终Review为准。
- 日常仿真：`simulation/START_HERE.m`；唯一参数入口 `simulation/init_AXU5EV.m`，保留本地模型/参数/wrapper修改，不保存未保存窗口。
- 原逐阶段交接保留在 [HANDOFF_HISTORY_2026-10-31.md](HANDOFF_HISTORY_2026-10-31.md)。其中“当前”“NOT_RUN”等按当时阶段理解，不覆盖本文状态。

## 2026-11-02：两个完整场景真实PASS，待最终Review

current_alignment_reset/scenario3/mode1/43100帧本次完整比较及板报crosscheck均exit0，passed=true/consistent=true；与已有current_motion/64536帧PASS一起归档。原始数据/已有分析不覆盖，两场景精简证据在verification/ax02a/runtime_r1_motion_01及runtime_r1_alignment_reset_01。alignment experiment2/before1，承接相同R1候选motion experiment1；两次数值零失败、deadline/sequence PASS、ISR无趋势。

motion最大runtime/task/response/jitter为38.74/54.42/60.82/6.94µs、最小slack39.18µs；alignment为17.43/32.33/38.39/6.92µs、最小slack61.61µs。全组均值/P99/极值/最坏帧和Issue15 A4/A5逐条审计见[本次汇总](reports/ax02a_full_board_results_2026-11-02.md)。计时为100MHz配置换算，不是WCET。

两个完整场景现在均为真实PASS，不再是NOT_RUN。A5.6独立冷启动/冷cache条件尚缺明确声明；A4严格连续mode0分阶段签收口径待最终Review（R1两场景mode1，历史mode0 motion_03为旧workspace）。同ELF两个独立不同场景已满足数量条件，不擅加必须同输入重跑的门槛。A1器件/PCB签核和最终Review/用户决定仍未完成。PR16保持Draft、Issue15开放；无新实验、Build、模型/参数/TTC修改或板卡操作。下文NOT_RUN均按历史阶段理解，不覆盖本节。

## 历史：2026-11-02板测前交接

只读核对runtime_r1_motion_01的run/analysis/crosscheck和pre-begin：已有64536帧mode1数值/时间PASS、板报一致，无趋势；本轮未重跑/覆盖。第二场景input/reference/metadata/32B描述符匹配43100帧/scenario3；R1纯文件启动检查PASS，ELF未重建。读回runtime_r1_alignment_reset_01及runtime_r1_alignment_reset_pre_begin_01.json均未占用，采用01。实际路径、停点预期和手动命令见[本次交接](reports/ax02a_alignment_manual_handoff_2026-11-02.md)。current_alignment_reset仍NOT_RUN；不连接/操作板卡，停在交接处。下文“两次均NOT_RUN”属准备时历史状态，不覆盖此次motion已有实测结论。

## 本轮：R1 P1000实测PASS，完整场景准备待Review

已只读分析 `.runtime/ax02a/board_manual/runtime_r1_p1000_01`、同次runtime_r1_pre_begin_01.json和replay/p1000参考，两条正式分析命令均exit0。1000×41数值0失败、最大差4.336808689942018e-19；deadline/sequence PASS，999 ISR相位斜率−0.000559882528tick/帧，低于原阈值0.012544565143；NO_TREND_DETECTED，板报与PC一致。最大Runtime37.61µs、task52.96µs、response59.19µs、jitter7.26µs，最小slack40.81µs；仅本次100MHz配置换算，非WCET/独立测频。上游配置与旧pre-begin基线一致，raw9999/logical10000符合本候选。[真实PASS证据](../verification/ax02a/runtime_r1_p1000_01/evidence.json)。

现有R1 ELF静态检查可复用到两完整场景，不重建：实际ELF保留65536帧上限和timing/replay/postprocess调用，数据/参考均在DDR边界内且帧预算低于32位回绕。已生成 `.runtime/ax02a/full_scene_descriptors/{current_motion,current_alignment_reset}/reference_descriptor.bin`。readback_short.tcl末尾新增显式场景参数，沿用64KiB分块及原身份/失败路径；旧P1000调用不变。现有完整比较器和板报CLI可直接分析，prefix-only analyze_run不用于完整场景。

完整场景原始数据预定为 `.runtime/ax02a/board_manual/runtime_r1_motion_01` 和 `runtime_r1_alignment_reset_01`，开始前配置分别为 `.runtime/ax02a/runtime_r1_motion_pre_begin_01.json` / `runtime_r1_alignment_reset_pre_begin_01.json`。操作见第14节链接；两个场景板验均NOT_RUN，由用户Review后逐次执行，不自动采集。原输入/参考及所有workspace/ELF留原路径。

仅增加一个相关全尺寸传输用例覆盖两场景，先失败再通过；相关离线回归73/73，0失败/错误/跳过。[准备/限制与验证](../verification/ax02a/full_scene_r1/preparation.json)。不改模型/参数/生成代码/TTC映射/截止期，不运行板卡，不重复ABA，不清理。PR16保持Draft、Issue15开放；完整A4/A5/WCET仍待实际两次回放证据。

## 历史：Review 5722212233修复交接

从目录整理提交 `f6c0fcb` 接续，已按[Review](https://github.com/kazecode666/AXU5EV/pull/16#pullrequestreview-5722212233)修复两个P2及完整构建版本保护。反例先复现：8项测试、23个失败子用例；修正后AX-02A相关离线回归72/72通过，0失败/0错误/0跳过。见[本轮报告](reports/ax02a_review_5722212233.md)及[验证记录](../verification/ax02a/review_5722212233/validation.json)。该阶段状态 **OFFLINE_FIXES_READY_FOR_REREVIEW**；此后的P1000实测结果见上节，PR16保持Draft。

板报状态/样本数/空组计数与PC原始结果逐项核对；双方一致拒绝与矛盾分开。合法早失败保存run.json及真实timer/snapshot（valid=0时不信任残留字段），不读旧DDR；有效失败前缀排除失败帧，不读报告。完整成功且后处理完成才捕获报告，仍须PC交叉。当前R1 ELF不重建，workspace、输入/参考/描述符/原始数据路径不变。

用户已按清单手动删除此前临时目录；不恢复、不再清理。本轮新测试产物集中在 `.runtime/ax02a/review_5722212233/`，无删除。源码/参数/模型本地修改继续保留。

## Runtime R1已有任务与证据

最新为[任务6541052405](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6541052405)，[版本化任务书](tasks/ax02a_runtime_100us_r1.md)。T1—T3完成，状态 **OFFLINE_READY_FOR_REVIEW**：

| 阶段 | 实际提交 | 结果 |
|---|---|---|
| T1 | `b46fdf69830baa36072af6b8ab047b4196e1c900` | ABA真实数据闭合；XSDB地址及uint32兼容，原始run/samples不改 |
| T2 | `2aa9a9aa691c78f7ca70c897b091635a8ff37283` | 仅已验证TTC0通道0/1、内部同源100MHz、无分频10kHz映射raw9999/logical10000；其他配置拒绝，expected/deadline不变 |
| T3 | `44872ec40e4df2efced9bf557f7459664ce72d31` | 独立Runtime R1真实构建、实际ELF身份检查及第13节交接；当时相关63/63离线测试通过 |

六套workspace和全部ELF保留。**下一次选择 `.runtime/ax02a/vitis_runtime_100us_r1`**，应用 `ax02a_replay`，launch `ax02a_first_wait_a53fsbl`。旧workspace存在同名launch，必须核对路径；候选0x52313031、mapping_version1。完整路径及纯文件检查见工作区指南。现有候选不随未提交模型/参数自动更新。

| 验收项 | 当前实际状态/证据 |
|---|---|
| BOARD_BOOT/FIRST_WAIT | 用户实测PASS；A53 FSBL→R5_0启动，旧架构不匹配失败保留作历史 |
| 首次完整运动数值 | motion_03，64536×41 PASS；[精简证据](../verification/ax02a/board_motion_03/baseline.json) |
| 旧exp2及phase P1000 | 数值、deadline/sequence PASS；ISR约+1tick/帧，周期不接受，不是R1板验 |
| TTC-only ABA | 三组各1000真实IRQ/16000B；周期10000.999985/9999.999988/10000.999700ticks，全窗口RAW_PLUS_ONE_COMPATIBLE、repeatable=true、issues=[]；[摘要](../verification/ax02a/ttc_aba_01/summary.json) |
| Runtime R1 P1000 | **用户实测及PC/板报交叉PASS**；[本次证据](../verification/ax02a/runtime_r1_p1000_01/evidence.json)，不替代完整A4/A5 |
| 完整A4 | 第二次独立完整motion、43100帧alignment/reset仍未验收 |
| 完整A5/WCET | 未完成，TTC-only和短段P1000不替代 |

ABA及R1 P1000已完成，不重复ABA/C或P1000。第13节保留为其历史步骤；下一次按第14节使用两个完整场景的各自输入/参考/描述符，原始和分析目录不得覆盖。

本次T4只记“带Runtime的100µs短段通过”；失败保留首个异常，不改9998、expected、deadline或容差。之后完整A4/A5另行推进，不扩展ADC/QEP/PS—PL/实物FOC。

## 本轮目录整理

统一README、固件入口、当前状态和工作区指南，历史交接单独保留；workspace/原始数据/生成源物理路径不变。历史清理项见[清单](reports/workspace_cleanup_2026-10-31.md)，用户已手动删除；本轮不恢复、不再清理。`.runtime/`不入库，推送GitHub不备份本地原始数据。

## 固定方向与工作边界

- AXU5EVB-E；PCB/完整芯片料号及厂商XA/-1与手册XC/-2差异待板级核对。核心板参考ACU5EV、底板参考AXU5EVB-E/共用AXU3EG资料，实物以太网JL2121，本轮不做网络适配。
- R5F负责位置P、速度PI、原五态对齐/一次偏置、Host/参考/轨迹/恢复；PL复用FOC及采样/位置/角度/PWM/快速禁止。算法源为Simulink/Stateflow，不手改生成C/SV补算法，不改PI、时基、首相、一次死区、50µs应用边界。
- 保留紫色分区和Host/Alignment_Task/Motion_Control布局；MATLAB/Simulink仅MCP操作，From/Goto局部，端口默认。Ready为当拍许可，Busy=0不保证Ready，未Ready拒绝、不排队。
- 不stash/reset/clean、强制同步、clone/worktree、批量删除或覆盖用户修改，不保存未保存窗口。旧 `D:/Project/FPGA_XC7A200T` 只读。
- Codex不连接/发现/复位/读写/下载/运行板卡，不启动或连接hw_server；用户本人Review后操作。合并和功率级上电另行授权。
- C教学、Issue11、AX-02B/C及旧M4不在本轮范围。区分HOST、RTL、目标构建、ARM实测，未运行写NOT_RUN。

详细实际结果见[AX-02A阶段报告](reports/ax02a_r5_target_validation.md)；基线方向见[架构](../docs/ARCHITECTURE.md)、[接口需求](../references/legacy/PMLSM_Hardware_Interface_Map.md)及[历史交接](HANDOFF_HISTORY_2026-10-31.md)。
