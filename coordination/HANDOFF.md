# AXU5EV — 当前交接

## 2026-11-13 PR41当前结论

按[Task 1评论6850181652](https://github.com/kazecode666/AXU5EV/pull/41#issuecomment-6850181652)接续服务器交付 `a392af056ae19ab18a975203b39e86f6d98a6763`。PWM_CUT_SDF_SLOW=PASS、PWM_CUT_SDF_FAST=PASS，仅覆盖hardware_02已布线PWM cut及声明的源边界模型。[最新报告](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/RESULT_REPORT.md)、[slow/max](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/v2/slow/summary.json)、[fast/min](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/v2/fast/summary.json)。[极性证明](../verification/motor_control/evidence/pwm_cut_windows_20261113_04/POLARITY_PROOF.md)确认物理cut输入为permission = !logical_inhibit，v2测试台在接口适配该极性，生产RTL无需据此修改。

FULL_CHAIN_SDF=NOT_COMPLETED，完整Windows O0后端编译ICE、O2 xelab 24h超时，全链动态未运行。FULL_DESIGN_STA与FULL_CHAIN_RTL沿用[原STA](../verification/motor_control/evidence/routed/hardware_02_audit.json)及[整链RTL06](../verification/motor_control/evidence/rtl06/summary.json)独立PASS证据，本轮未重跑。局部cut覆盖之外仍有FOC/ADC计算与同帧快照、源至cut的完整实际互连/时钟树、完整late/disarm/reference重臂策略和80字读回；fast_inhibit在原BD接常量0，独立动态N/A。

board_no_power与r5_capture_continuity均NOT_RUN，当前尚无现场执行授权。服务器暂停，PWM局部SDF工作线收口；下方O0/24h命令及各轮FAIL/中断记录均为历史。当前状态见[聚合结果](../verification/motor_control/results.json)。本次仅整理文档/状态，PR41保持Draft、Issue40开放，全链动态SDF验收例外与合并等待用户决定，停在Review。

## 2026-11-13 第三轮：Review6847609985原生cut边界疑点硬停止

v1统一唯一同步源驱动，语法预检通过；slow xvlog0.766s/xelab10.250s正常退出且SDF注释成功。实际910ns握手、910.2ns撤销valid，930ns无重复源握手，但native capture_ce=0、busy/request=0，模拟推进至500us仍offers1/accepts0。只读native LUT5 INIT08000000及reset LUT2 INIT7对cut端口auto_inhibit的直接解释与RTL !inhibit接受条件不符；可能涉及RETARGET/跨层pin inversion/导出模型语义，未确认硅DUT或RTL有错。已触疑似DUT/无法归类硬停止，不反相输入、不改CQ/相位，不创建v2/v3（1/3候选）。

[第三轮集中证据](<../verification/motor_control/evidence/pwm_cut_windows_20261113_03/README.md>)、[报告](<../verification/motor_control/evidence/pwm_cut_windows_20261113_03/RESULT_REPORT.md>)、[原生cone只读摘录](<../verification/motor_control/evidence/pwm_cut_windows_20261113_03/native_cone_excerpt.txt>)。SLOW=FAIL_HARD_STOP、FAST=NOT_RUN、FULL_CHAIN_SDF=NOT_COMPLETED；旧结构保留检查不等于cut逻辑极性功能等价。全部旧FAIL/原始RUNNING停机快照保留，HARD_STOP另记最终判定。原STA/RTL证据不变，无DCP重查/导出/实现、RTL/约束/参数变更、SHA核查或板卡操作。PR41仍Draft、Issue40开放，等待Review边界语义。

## 2026-11-13 第二轮：按PR41 Review6846401773执行后停止

已实际完成定向DCP anchor查询（154.5s，hold+.244ns/setup+8.759ns），修复局部TB源posedge寄存器/20ns anchor与WARNING分类，复用已导出网表和SDF。前置xvlog声明顺序错误原样归档，仅修声明顺序后，唯一slow xelab10.25s exit0且注释成功；唯一动态xsim3.468s运行到930ns，首次20ns anchor与4997→5000启动已观察，但首笔seq1触发unique source offer断言，按规则停止，fast未启动。新增源寄存器与旧task撤销语义未闭合，actual valid又暴露一个源沿；属于本轮TB源驱动/监视契约失败，不据此判生产DUT失败。未删断言、调相位或重跑动态。

结果PWM_CUT_SDF_SLOW=FAIL、FAST=NOT_RUN、FULL_CHAIN_SDF=NOT_COMPLETED；完整动态覆盖未完成，原STA/RTL证据独立保留。[第二轮证据与限制](<../verification/motor_control/evidence/pwm_cut_windows_20261113_02/README.md>)、[报告](<../verification/motor_control/evidence/pwm_cut_windows_20261113_02/RESULT_REPORT.md>)、[真实日志](<../verification/motor_control/evidence/pwm_cut_windows_20261113_02/slow/xsim.stdout.log>)。0.2ns仅本地边界模型，非物理跨层SDF。1404旧hold失败、1522编译失败和本次动态失败均保留。未修改生产RTL/参数/约束、重建硬件或操作板卡；不打包/同步/哈希验证、不恢复全量24h xelab。PR41继续Draft、Issue40开放，等待Review。

## 2026-11-13 补充：Windows PWM cut SDF 一次性执行已停止

服务器本轮既有hardware_02 DCP在指定PWM桥切点原生导出228.6s完成，196766→1204 primitives；slow/max xelab14.20s exit0且SDF注释成功。首次xsim检出anchor_delayed_reg在760/820ns的60ps hold违例，按停止规则终止，未重跑或启动fast。已识别本轮TB的anchor与PWM采样沿重合、零保持裕量边界缺陷，不能据此认定生产DUT失败；未完成整组/谷值/取消/死区等动态场景。PWM_CUT_SDF_SLOW=FAIL、PWM_CUT_SDF_FAST=NOT_RUN；FULL_CHAIN_SDF继续NOT_COMPLETED，既有全设计STA及整链RTL证据不变。

本轮精简证据与完整限定见[索引](<../verification/motor_control/evidence/pwm_cut_windows_20261113_01/README.md>)、[报告](<../verification/motor_control/evidence/pwm_cut_windows_20261113_01/RESULT_REPORT.md>)、[原始动态日志](<../verification/motor_control/evidence/pwm_cut_windows_20261113_01/slow/xsim.stdout.log>)。大DCP/网表/SDF/缓存留服务器原目录，不进Git。未改生产RTL/参数/约束，未重建硬件、未操作板卡；本次只归档，不启动新的验证轮。PR41继续Draft、Issue40开放，等待Review。以下2026-11-11计划及更早记录原样保留，不能当作本轮自动长跑授权。

更新：2026-11-11，仓库kazecode666/AXU5EV，本地D:/Project/AXU5EV。

## 当前：服务器完整SDF与本地有限无功率板测并行

按[PR41评论6784312486](https://github.com/kazecode666/AXU5EV/pull/41#issuecomment-6784312486)接续56bdd63及同一分支，公共候选为hardware_02/vitis_01。一次产物核对已完成，14项关系通过，包括实现bit/ltx、XSA内bit、平台XSA、FSBL与PS初始化、Launch和ELF身份。实际应用ID4d435401、BSP基址80000000，冻结参数TEST_INPUT=0、TEST_ABZ=1、AUTO_CONTROL=1、AUTO_FOC=1。准确路径/字节/SHA256、生成来源与文档head分别记录在 `verification/motor_control/evidence/parallel_plan_20261111/artifact_correspondence.json`。

本地原38MB大zip记录路径当前缺失。公开Release两包的大小/digest仍与发布回执一致，当前网表/两角SDF/TB也与原包清单一致，服务器下载沿用该Release。核对结果保留这一局限，服务器副本与运行状态依据用户回执更新。

服务器由用户手动运行，长命令见 `firmware/r5/motor_control/WINDOWS_SERVER_SDF_ZH.md`。slow/max和fast/min均显式 `-ToolTimeoutMs 86400000`，24h/工具为启动前资源预算。A线内部保持slow完整PASS后才执行fast，沿用原O0、默认日志级别和全部时序/事件判据。已有同候选任务先核实际命令/预算，保持该次运行。服务器SDF与本地板测各自推进。

本地现场条件已由用户确认，具备接线确认的ADC模块及可靠输入。有限板测步骤见 `firmware/r5/motor_control/FIRST_RUN_ZH.md`，从现有bit/ltx、A53 FSBL和R5 ELF的WAIT/s启动，逐项执行数字校准、t/j参考、m合成编码器、d禁止/显式重臂及局部ILA。现场操作由用户执行，Codex协助下载/采集按用户明确授权的具体动作开展。r最多128条、阻塞采集，p在结束后打印20列选定字段，完整80字保存在records中。R5连续性按sample_id+500、tick+5000、50间隔历史独立归档，ILA按40.96us局部窗口记录。

本轮执行准备和说明修订完成，四条实际验收状态 `server_sdf_slow_max`、`server_sdf_fast_min`、`board_no_power`、`r5_capture_continuity` 当前均为NOT_RUN。精简证据分别归档server_sdf_20261111与board_no_power_01，完整原始日志保留各自新目录。工具/资源异常单列，DUT功能或时序失败暂停受影响场景并报告具体证据。两条线完成后统一Review，PR41继续Draft，Issue40开放。

以下为历史交付与执行安排，当前入口以上述并行计划为准。

## 前轮：Windows服务器手动SDF交接发布

按Issue40评论6759938887、PR41评论6759942425接续1eba754，Windows本机执行，服务器暂缓；Linux专项不作前置、不补测、不重新打包。沿Review5835164071只读检查旧目录：仅650份解析sdb，无生成源/对象/kernel，不能定位具体内部瓶颈。本机xelab2026.1帮助实际支持--O0（禁用优化）、--stats、--verbose 1；短help与命令差异核对通过。只改变编译策略--O0，额外两项仅诊断；debug off、mt隐式auto、1ps及所有原时序/事件判据不变，不将运行器修复当作性能修复。

13:50在新目录 `.runtime/motor_control/sdf_o0_slow_01` 启动，预算单工具60min；xvlog通过，详细日志进入FOC各层SDF端口延迟处理。用户随后改为服务器手动执行、不远程操作，允许上传GitHub供下载。14:18:11核实身份后终止本轮监督器，其kill-on-close Job成员句柄均退出、剩余0；这是用户取消，不是到限或原生自然失败。原RUNNING JSON保留，user_stop_result.json另记取消，少量性能样本及全部日志原位保留。没有kernel/成功注释确认，slow注释NOT_COMPLETED、动态NOT_RUN，fast未启动；--O0提速/根因均未证明。

已发布文件分发预发布（非验收）：https://github.com/kazecode666/AXU5EV/releases/tag/issue40-windows-sdf-20261110 ，目标入口源提交d376e56。原server_bundle_01大包38,281,015字节/SHA256不变；另附Windows小入口包12,654字节、SHA256SUMS.txt。两zip的GitHub端digest已核对，并以无认证公开下载验证小包SHA256；精简发布回执见evidence/windows_o0_20261110/github_release.json。大包未进入Git历史。

用户下载后手动执行，不自动登录服务器，不使用computer-use。新入口在原包外，显式TB/硬件路径，原9项SHA256不失效。服务器只启用--O0、保留默认日志级别和全部时序检查；不带verbose1，因为其INFO映射中error_register名称会触发原宽泛匹配式（本机23处均INFO，明确ERROR/WARNING前缀0）。新包装5项短自检和小包解压入口dry-run通过，真实SDF未通过；下载与步骤见 `firmware/r5/motor_control/WINDOWS_SERVER_SDF_ZH.md`，本轮精简现场见 `verification/motor_control/evidence/windows_o0_20261110/`。DUT/算法/约束及hardware_02/vitis_01不改，不重跑旧全量/重复oracle、不补Linux专项、不操作板卡、不关机。

以下运行包与修复记录保留为上一轮交付；server_bundle_01及全部旧产物原样保留。

## 前轮：Issue40运行器与服务器包自检PASS

按Issue40评论6757750944接续同一分支/PR，服务器可运行仿真已确认。先独立提交运行器修复 `0bd081a902397d5365f0b608f1678c6d4ce04d0a`：共用 `scripts/sdf_runner.py` 管理专属进程树、持续日志、finally清理和自然/超时/取消分类，原PowerShell包装保留。Windows12项短模拟测试PASS：四类退出各5进程/剩余0、运行中及已产生的末尾stdout/stderr保留、同名无关进程未受影响；包装传播与四类SDF拒绝判据也通过。证据 `verification/motor_control/evidence/runner_fix_20261110/`，原始runner_fix_01/02保留。

随后已生成实际服务器包：`D:\Project\AXU5EV\.runtime\motor_control\server_bundle_01\AXU5EV_Issue40_SDF_hardware_02_0bd081a.zip`，**38,281,015字节**，SHA256 `6932398ee982936da54521c60d5bd978234c5bd55698e76de720910fb509e05b`，相邻.zip.sha256也保留。10文件中含hardware_02原网表/两角SDF、0191fc7事件TB、修复运行器/输入校验、中文说明及来源/清单；没有工具安装或无关Workspace。无额外可见项目文件输入，厂商库/glbl由配置的同版工具提供。已解压至原仓库外C:/Users/lww/AppData/Local/Temp/AXU5EV_Issue40_unpack_20261110_01，从包外工作目录完成9项SHA256/清单、依赖、两角命令dry-run及短假工具正常/失败传播，均PASS_NOT_SDF；实际平台仅Windows，服务器/Linux运行NOT_RUN。包未加入Git或上传；精简证据 `verification/motor_control/evidence/server_bundle_20261110/`，中文入口 `firmware/r5/motor_control/SDF_SERVER_ZH.md`（包内README_ZH.md）。

本轮没有启动真实Vivado/长SDF、-O0、硬件/R5重建或裁剪，DUT/算法/约束不变；未登录/安装/运行服务器或操作板卡。**不自动关机**，替代下列历史关机指令。slow注释NOT_COMPLETED、动态NOT_RUN，fast未运行，SDF验收仍开放；运行器/包自检PASS不等于SDF PASS。8个原用户修改文件、全部旧产物和日志保留。交付同一PR41后保持Draft，停在Review；服务器实际两角另行安排，不自动执行。

## 历史：完整功能PL网表slow/max超时

按Issue40评论6745328232、PR41评论6745337679接续0191fc7，复用hardware_02已有完整功能PL网表及两角SDF，当前事件测试台网表分支，未定义MC_TIMING_RTL。新目录 `.runtime/motor_control/sdf_full_slow_01`：00:32:36启动；xvlog通过、static elaboration完成，原wrapper在03:32:48报3h超时退出。用户追加允许更长等待后，仅同一次原生PID8028继续监督，未重启/重编译；到其启动后6h（06:32:48.542）仍未完成。核实原生路径/命令/精确启动时间后，于06:34:15.828终止该任务进程树，剩余0。原wrapper管道完整性无法保证，未取得原生自然退出0；监督终止码-1不是自然工具失败码。

**本轮不是SDF PASS**：没有kernel或XSIM 43-3452注释成功确认，slow注释NOT_COMPLETED、动态NOT_RUN，fast/min未启动。可用日志无显式ERROR/FATAL，但不能因此证明进度或DUT无误；没有动态断言结论。同帧、三相整组、目标谷值、晚到取消、disarm、失锁重臂、死区和80字快照的网表动态验收仍全部开放。精简证据 `verification/motor_control/evidence/full_sdf_20261110/README.md`、分角记录 `results.json/full_functional_sdf`；原始调用、进程、超时/继续监督/停止日志与中间文件全部原位保留。没有重试或下一角，也没有再裁剪、修改DUT/算法/约束、重建hardware_02/vitis_01或重跑旧回归/重复oracle。停在同一Draft PR41等待Review，不合并、不关闭Issue、不操作板卡；后续路线或延期交Review决定，不自动续跑。用户明确要求交接推送完成后正常关机，不强制关闭或保存用户窗口。

下列为前轮有限收尾记录，原停止点已仅对本次授权SDF解除；生产DUT/算法/约束及旧产物仍保持。

## 前轮记录：Issue40 有限收尾（定向SDF缺项开放）

从包含已合并PR39的main `ffaa5683322e2a485d96a23cc1b8a9e88fbcdb13` 接续独立分支 `codex/motor-control-chain`，已创建 [kazecode666/AXU5EV Draft PR41](https://github.com/kazecode666/AXU5EV/pull/41)，目标main，关联Issue40。实现/整链RTL/数值比较/新STA/R5构建已有证据；**SDF注释和动态验证仍未完成**。本轮按用户与 [6740612318](https://github.com/kazecode666/AXU5EV/issues/40#issuecomment-6740612318) 执行有限收尾，并保留 [6740096397](https://github.com/kazecode666/AXU5EV/issues/40#issuecomment-6740096397) 的边界判据。不转Ready、不合并、不关闭Issue。

**新测试已验证，不能叫SDF PASS**：现有timing_tb改为事件驱动，直接监测实际active_seq/active_compare采用沿及三相整组；实际注入ready晚到、pending时失锁并显式重臂，保留两项disarm、无效/OTR、互补死区、两级下降沿释放和80字/0x148释放。最终 `timing_preflight_03` 3035检查PASS：6次实际采用、1晚到、1失锁、2重臂、2 disarm、1 P0握手、5释放、15快照；15帧是事件序列结果，不是固定门槛。只改测试期望1位的反例在首次实际采用250514ns按预期失败，DUT未改。RTL预跑不包含真实MMCM/SmartConnect/布线/SDF，详情 `verification/motor_control/evidence/timing_events/README.md`。

**一轮裁剪核对已用完，到停止点**：只读hardware_02的 `routed_boundary_probe_01` 找到P127/下降沿寄存器各270、旧核内首次接收顺序对象628、输出侧源192、帧壳结果102，以及mapper/邮箱/active/回执/释放对象。整核黑盒会删除必须保留的实际边界；到boundary get_timing_paths循环触及600秒上限，未完成路径/时钟复位树及局部切点保留证明。仅此一次，已停止专属进程树并核查剩余0；临时导出0次、routed xelab0次。不是证明所有裁剪不可能，但没有选定可证明的视图。按用户要求不再试切点、不扩大检查、不回退完整网表长跑。证据及具体缺口见 `verification/motor_control/evidence/routed/BOUNDED_VIEW_CHECK.md`。

**安全断点（2026-11-09 19:54:37）**：用户为关机明确要求暂停。仅终止本轮slow_01的xelab PID31032，外层CMD39140与pwsh6516自然退出，进程树核查剩余0；未启动fast或模型比对。最后阶段为Completed static elaboration之后的执行核准备，没有生成kernel、未完成SDF注释、动态仿真NOT_RUN，不计PASS。原目录、console、xelab.log及停止记录全部保留，证据 `verification/motor_control/evidence/sdf_pause_20261109.json`。没有替用户保存/关闭未保存窗口，也没有执行关机。

**剩余由用户决定路线**：新增边界slow/max、fast/min的匹配注释和动态验证均NOT_RUN，仍是Issue40完整离线验收缺项。没有局部或完整整链SDF PASS。需要用户另行决定验证方案或明确延期，不能自行豁免；即便将来局部通过也只记AFFECTED_BOUNDARIES_SDF_PASS。hardware_02/vitis_01、旧模型/19帧比较/原整链RTL/综合实现全部复用，不重跑。原第二次固定六帧FOC oracle保留NOT_RUN历史，按本轮用户与Review改为NOT_REQUIRED_DUPLICATE，不再作为固定门槛；此前43c9378的完整两角六帧恢复命令是历史，不再作为自动续跑入口。

原ADC/QEP接收器→原电流/角度生成HDL→原p3 FOC→新模型生成比较值→原PWM的自动PL数据路径已连通，保持50/100MHz、5MHz转换和100us帧。统一系统模型实际55帧、最终RTL06同表Current20事件/280字、Angle19事件及连续原FOC19帧/57个Q30字逐位对比、生成mapper31向量/125RTL检查已PASS。最终整链RTL06 370245检查PASS，含19发布/9采用/9无效、92386原核CE拍、晚到/失锁与两项disarm优先级；未修RTL05先复现失败，bc52d74最小清ref_pending后再通过。

`hardware_01` 在综合阶段因上述禁止优先级问题有选择地取消，仅终止本轮已核实的batch及子进程；其项目、日志和superseded记录全部保留，不计完整实现PASS。新 `hardware_02` 初次集成模块发现失败；48份源存在/语法有效，入口改为包在前的一次完整登记。source_entry_02冷启动46源/两AUTO模块引用PASS，02从尚未完成的integrate/build阶段续建，完整布局布线及bit/ltx/含bit XSA已PASS，原失败日志保留，未重跑all。

新整体完整STA为WNS+1.272ns、WHS+0.011ns、WPWS+4.000ns，TNS/THS/TPWS=0，no_clock/未约束内部端点/缺失及部分输入延时均0。实际CLB13788/14640=94.18%（LUT67.36%），不能以LUT余量代替布局空间；4项CDC warning均位于原dbg_hub，相关50/100MHz功能路径由STA计时。route_audit_01实际完成16组端点及新增恢复/移除路径审计，均已约束且非负，28管脚/26路ADC输入min2/max10ns预算及6个ABZ同步FF保留。

匹配新R5 Workspace `vitis_01` 构建及被动启动检查PASS，实际基址0x80000000、应用ID4d435401，A53 FSBL64/R5 ELF32匹配，text/data/bss=43859/2196/135520，应用零警告、厂商BSP/FSBL七条警告保留，ARM服务时序NOT_RUN。原debug黑盒化触发Vivado NULL ParentLH工具异常；最小修正仅在MC_AUTO仿真导出中黑盒ILA、保留结构dbg_hub，生产入口两角网表/SDF导出PASS，bit/DCP不变。原完整网表slow准备已在19:54暂停，fast未启动；本轮没有匹配局部视图，不追加门级长跑。全部失败/对照目录保留，未重建候选或改变约束。

唯一模型运行入口 `simulation/motor_control/motor_control_run.m`，单一PL构建 `scripts/motor_control_build_hw.ps1`，操作说明 `firmware/r5/motor_control/FIRST_RUN_ZH.md`，实施及来源见 `coordination/tasks/motor_control_chain.md` 与 `coordination/reports/motor_control_chain.md`。无完整外环/Runtime/自动对齐，电机参数/PI/原电流公式不改；8个用户已修改文件、未跟踪文件及全部旧Workspace/原始数据保留。板卡发现/连接/下载/运行NOT_RUN，六路仍内部观察，physical_link_verified=0。

以下Issue38已随PR39合并，其原待Review文字为历史。

## 历史：Issue38 编码器同帧与PL/R5反馈（PR39已合并）

从含已合并PR37的最新 `origin/main 5c9aca2ad23792645366cc58b748bcdca4001e85` 建立独立分支 `codex/encoder-feedback`，执行 [kazecode666/AXU5EV Issue38](https://github.com/kazecode666/AXU5EV/issues/38)，任务正文与实施顺序在 `coordination/tasks/encoder_feedback.md`。没有接续旧PWM功能分支，main未自动更新，正常Git保留历史。

已提交 [kazecode666/AXU5EV Draft PR39](https://github.com/kazecode666/AXU5EV/pull/39)，目标main，停在Review。功能提交 `336b4da4403aad6df1f27ace295b54afd61ab910`；后续仅补最终证据与交接链接，均正常Git推送，无连接器提交映射、强推或reset。本轮不自动合并或关闭Issue。

原B1 ABZ接收器直接加入统一motor_control源清单，无第二份解码器/ADC/PWM工程；phase0实际ADC采样沿锁存旧注册count/Z/ready/illegal及本帧配置，phase4捕获ADC原码，经原七事件链对齐。角度单源模型生成HDL，电流一拍结果先冻结，等角度结果整组发布：选样到发布110个50MHz拍（名义2.2us）。ENCF identity/schema2扩展到41字，最后0xac响应释放；原ADC-only仍32字B3OB，原电流及PWM寄存器合同不变。

新共享组件 `AXU5EV_Encoder_Components/Encoder_Angle` 由新HDL壳库链接复用，唯一算法源 `simulation/encoder/encoder_angle_step.m`。未保存用户修改的原共享库/ADC模型。电角度匹配旧FOC signed40/Q32弧度，用int64存储；TEST尺度JSON统一生成PL常量与C头，1000nm/有效count、30000count/电周期，不额外乘除4。连续化处理模32增量；仅改电相位偏置/版本不重建机械参考，反向保持连续原点并取反，显式zero改变才重定参考。恰半回绕失效；Z仅观察，不归零或启动对齐。

模型与生成HDL最终46向量/2208模型步、460项RTL检查PASS，Q32理想误差≤1LSB。软件函数生成的实际ARM native64 C与MATLAB共1301帧/17类场景PASS；51项100us历史实现50间隔测速，启动/重复/缺帧/回绕/配置变化有独立有效位。真实RTL的两组8帧×41字快照经同一R5字段适配器回放给MATLAB和目标C均一致。接收器前集成普通/有符号边界两组各271检查、8发布、7次PWM峰值选样PASS，含同沿接受、phase4新计数、原码/电流/角度/版本同帧及快照冻结释放。复用的相关PWM/ADC/B3短验证和原接收器定向验证PASS，未跑旧FOC全量。

采用新候选 `.runtime/encoder_feedback/hardware_02`，完整综合/布局布线、bit/ltx/含bit XSA PASS；WNS+1.818ns、WHS+0.010ns、WPWS+4.000ns，TNS/THS/TPWS=0。新角度路径setup/hold+8.352/+0.044ns，新增元数据/整帧会合/快照实际端点均受约束且非负；全局最差hold为meta_pipe[6][105]→pair_meta[105]。原28个J15管脚、26路min2/max10ns预算命中，6个ABZ ASYNC_REG FF保留，相关50/100MHz双向通过。58项DRC warning、37项methodology warning及2项advisory、4项vendor debug CDC warning保留，无功能CDC违例。完整定向审计为 `.runtime/encoder_feedback/route_audit_03`，未放宽约束或改频。

匹配R5新Workspace `.runtime/encoder_feedback/vitis_02` 构建及被动启动检查PASS，实际BSP地址0x80000000，应用ID45464301、Launch encoder_feedback_manual，ARM32/R5和AArch64/A53 FSBL匹配；应用零警告/错误，text/data/bss=43707/2188/116064。真实逐帧服务/无漏帧NOT_RUN。

最终功能PL边界 `sdf_slow_01` / `sdf_fast_01` 各730检查、9选样、37开通边沿、6周期、2完整41字编码器/电流快照、10次原子发布PASS；注释告警/时序违例/未知失败均0。slow/fast内部死区分别999.966–1000.034ns / 999.984–1000.016ns；ADC pad相对内部峰值固定晚3.388/1.659ns，pad采样沿到快照Q固定2195.211/2197.538ns。这些是路由传播下的内部观察，不是板上测量。仅在内存导出视图black-box不支持仿真的ILA/debug hub，保留功能时钟/ADC/AXI/PWM互连，PS时钟/复位与主AXI事务源替代；不覆盖ARM执行/ILA采集或全部PVT动态组合。

`hardware_01` 因复核发现回绕后偏置/版本更新重定原点的数值边界问题被替代，保留不计最终PASS；修正在MATLAB源中完成并重新生成HDL/C，未手改生成物，新向量和真实ABZ回绕集成已覆盖。`vitis_01` 构建后暴露标准uint32与生成类型的指针告警，手写记录改用生成uint32_T，再于vitis_02构建通过；数值C未因ABI存储修正改变。模型/脚本/审计早期失败及全部原始输出也保留。

唯一操作说明 `firmware/r5/encoder_feedback/FIRST_RUN_ZH.md`，字段/工程说明 `hardware/axu5ev/motor_control/README.md`，精简结果 `verification/encoder_feedback/results.json`。TEST_ABZ源位于原接收器前，复位后停住，R5显式命令才走数；无外部ABZ管脚或XDC，六路PWM仍只接内部ILA。physical_link_verified=0，板卡发现/连接/下载/运行NOT_RUN。完整FOC/Runtime、对齐、驱动板/电机均未接入；原电机参数/PI/电流公式及50/100MHz、5MHz、100us合同保留。8个用户修改文件、2个用户未跟踪文件、全部旧Workspace/原始数据保留。完成独立Draft PR后停在Review，不合并或关闭Issue，不操作板卡。

以下PR37已合并；其旧Review/关机措辞为历史，不作为本次动作。

## 历史：PR37 Review 最小收尾（已合并）

按 [kazecode666/AXU5EV PR37](https://github.com/kazecode666/AXU5EV/pull/37) 最新 Review（审查 head `902ff0852f9021586467beefda8152b2d826c76c`）仅修构建环境隔离与 ILA 说明。`scripts/pwm_adc_build_hw.ps1` 保存 MC_PWM/AX03B3_TEST 的存在状态和原值，设置与调用均置于 try/finally，正常或异常返回后恢复；原本不存在的变量通过 Env: 赋 null 移除，避免当前 PowerShell 的 .NET null→空字符串转换。

轻量验证 `verification/pwm_adc/test_build_environment.ps1` 在新目录 `.runtime/pwm_adc/review_pr37_02` 使用真实包装脚本副本及相邻构建 stub：两变量各自存在/不存在的4种组合×正常返回/抛错，共8例PASS，同时检查子调用期间 MC_PWM=1、AX03B3_TEST=0，未启动Vivado。首次候选的空字符串恢复失败保留于 `review_pr37_01`，不计PASS。复跑此轻量验证必须指定未占用的 RunDir。

`firmware/r5/pwm_adc/FIRST_RUN_ZH.md` 补充4096点约100MHz的连续窗口约40.96us，小于完整PWM周期及选样到下一采用边界，分别触发观察死区、整组更新和许可/重新使能边界。ILA深度、PWM/ADC RTL、时钟及数值算法未改，hardware_05/vitis_02沿用原产物；本次综合实现、SDF、R5构建、旧全量回归均NOT_RUN，未连接或操作板卡。用户6个已修改文件、2个未跟踪文件、旧Workspace和原始数据保留。推送同一Draft PR37后停止等待复审，不自动合并或关闭Issue。

以下为原Issue34实现和发布记录；其硬件/软件验证是上轮结果，本次未重跑。

## 当前：Issue34 PWM 100MHz 与 ADC 选样协同（离线完成，待Review）

执行 [Issue34 最新正文](https://github.com/kazecode666/AXU5EV/issues/34)，任务书 `coordination/tasks/pwm_adc_100mhz.md`。已提交 [kazecode666/AXU5EV Draft PR37](https://github.com/kazecode666/AXU5EV/pull/37)，目标 main，停在 Review。分支 `codex/pwm-adc-100mhz` 普通 merge 纳入 main `811dd56364b6c27d8653d7d3ab8821dd2d497e17`（PR33）和 PR36 merge `bb6314c8a7ff17499ee7cb793c62fa046962e8e8`；两项祖先检查通过，未自动更新 main。Git HTTPS两次失败后使用连接器发布；远端合并提交 `eff47db0774194676057cb5466fd058917f19c40` 保留上述两个父提交，其树与本地合并 `36c57e3` 一致。以下实现提交逐项核对 Git 树一致，本地原历史保留，不强推/reset；网络恢复后可正常 fetch/merge 保留双方历史。

| 本地提交 | 连接器发布提交 |
| --- | --- |
| `eff59b0c1d8983dda6f5ae149486e68236457f22` | `b65ec9a34ddea17afc24f8d78b680898f81ba971` |
| `21317163c41c8ecc3a0bac8d6f248bf72a816be8` | `9b3fcabea6d6c1dfc846699d2dd83123702d13bb` |
| `37649ba6ec75b1bb0b2cd6c42d04cce9c97d25cb` | `9fde2285b413ebe1fb36714cfb1c050efd250586` |
| `d9ec28123a00ee0b4547e9c8dc9c4146527fe046` | `4c3e4172e240b47e146a360452b68dc8e11f72c1` |
| `b0a4efbff02f32af20977eeff6df6a58707df2c1` | `99bd630a996dc66934f9ebfc36a7fc9523726f40` |
| `a23e4093dca2492ca6702c5254b37f85af53568c` | `4c62ef2366685e8f26dad75a950d332ff9555f57` |
| `c5597d5a5cea5b67ed5d757c4a9a362a8ba2daf0` | `7667ec43703144f9c61e521c46f629c4e2f05010` |
| `cbbe0c2add1ce3721ac5375be5cb95a506dfd1bf` | `6cc7875b2d432d72e33284916bd1f6aaf6d3ac32` |

此表覆盖实现与验证记录；后续提交仅补齐本节 PR 链接和发布映射。

同一 `motor_control` 工程从既有 PS 49.9995MHz 元数据派生严格2倍 PWM 时钟99.999MHz（MMCM M24/D1/O12），ADC/AXI仍为原域。共同载波10000拍、三相冻结整组谷值采用、上下100拍死区、许可/禁止/重新允许、失锁取消已实现。ADC只增加采样前相位锚，原采样/七事件返回/数值一级延迟和REAL/TEST合同不变；旧FOC/Runtime/电机参数/PI未改。外部200MHz、ABZ新功能和完整闭环均未接入。

PR36三条原位置/Z/illegal_count断言已恢复，并只运行一次对应模型验证：42项数值、49×14一级延迟、4帧PASS。最终短RTL：`pwm_rtl_07` 694175检查/30谷值；`adc_rtl_08` 接收器前刺激10帧、135检查、9次相位、6帧有效结果；`b3_rtl_03` 2064帧、两路各两次首次done=1024、restart清零PASS。原始输出均在 `.runtime/pwm_adc/`。

采用候选 `.runtime/pwm_adc/hardware_05` 完整综合/布局布线及bit/ltx/含bit XSA PASS：WNS+2.419ns、WHS+0.015ns、WPWS+4.000ns，TNS/THS/TPWS=0。28个J15管脚和原26路min2/max10ns输入预算均命中；功能路径无缺失时钟/未约束端点，相关50/100MHz和适用recovery/removal通过。保留的工具建议与具体最差路径见精简结果，未放宽约束。

功能PL边界真实路由SDF `sdf_pl_slow_02` / `sdf_pl_fast_02` 均PASS：各515检查、9选样、37开通边沿、6周期，注释/时序/未知态零失败。内部死区slow为999.977–1000.023ns，fast为999.991–1000.009ns；ADC pad相对内部峰值固定晚2.772/1.332ns，无漂移。按PG172仅在内存仿真视图中black-box不支持仿真的ILA/debug hub，保留功能时钟/ADC/AXI/PWM/互连；完整STA和bit仍含真实调试IP，不覆盖PS执行、ILA采集或全部PVT组合。最小R5新Workspace `.runtime/pwm_adc/vitis_02` 构建及被动启动检查PASS，实际BSP PWM地址0x80001000，A53 FSBL与R5 ELF/Launch匹配；明确产物路径见唯一指南。

早期/失败/中断候选及日志全部保留，未作PASS：双ILA许可限制、裁剪/直接force从机边界、Vivado子进程启动失败；SDF测试台AW/W相互等待已改为独立握手。ADC计数器试验属性已撤回，原逻辑不变。真实新域首级reset removal告警通过两级下降沿释放留半周期解决，最终STA/SDF已确认。

唯一工程/寄存器/时序说明为 `hardware/axu5ev/motor_control/README.md`，唯一操作指南为 `firmware/r5/pwm_adc/FIRST_RUN_ZH.md`。六路仅接100MHz内部ILA，外部引脚/缓冲/极性/配对与板上验收PENDING；physical_link_verified仍0、ENCON/RELCON未接入。本轮板卡发现/连接/下载/运行均NOT_RUN。用户6个已修改文件、2个未跟踪文件及全部旧Workspace/原始数据保留，未保存用户模型。完成同一Draft PR后停在Review，不合并/关闭Issue；按用户要求随后仅请求正常关机，不强制关闭未保存窗口。

以下为 PR36 及先前阶段的历史记录，不作为本轮新验证结论。

## 历史：Issue35 ADC 单源组件与统一PL入口整理

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
