# Issue40 / PR41 Review6847609985 — 第三轮集中报告

## 结果

**SLOW=FAIL（疑似native-cut边界语义不一致而硬停止），FAST=NOT_RUN，FULL_CHAIN_SDF=NOT_COMPLETED。** 无完整动态PASS。使用1/3个候选，未创建v2/v3：三候选授权不允许在疑似生产DUT/无法归类的问题出现后继续试刺激。

## 已实际实施与运行

对照真实bridge的valid&&ready&&!inhibit以及上游motor_foc_control的同沿NBA撤销，v1统一为唯一源posedge驱动器。task只提交单槽mailbox；握手同沿+0.2ns撤销valid，背压期间payload稳定，握手后下一源沿才污染live payload。offer/finish_offer/取消/恢复统一该协议；finish_offer同步轮询无固定参数wait提示。首笔打印实际busy/捕获CE/request/pending/accepted。原44条check完整表达式与顺序不变，无force、阈值放宽或时钟重相位。

保留50/100MHz同相2:1、0.2ns明确局部源Q假设、20ns anchor、5ms看门狗。此模型非真实上游跨cut SDF。取消场景按原协议在已接受pending后执行，不声称覆盖尚未握手时取消，也不声称上游reference恢复算法动态覆盖。

|阶段|实际墙钟|结果|
|---|---:|---|
|独立xvlog语法预检|1.047s|自然exit0，无展开/动态|
|slow正式xvlog|0.766s|自然exit0|
|slow唯一xelab O2|10.250s|自然exit0，XSIM43-3452成功注释，无warning|
|slow唯一xsim|最后runner记录84.469s|人为监督硬停，最后实测模拟500000ns；非自然完成|

预算600/600/3600s；没有预算到限，没有无模拟推进停滞（实际推进到500us），不是5ms看门狗失败。整个受管作业95.992s后终止，只终止本作业树。PID52548及XSim进程均确认退出。无新SDF/timing/fatal诊断记录，不能以此短区间说明完整时序通过。

## 首笔实测：TB重复源offer已消除，但native不接受

[原始trace](<v1/slow/xsim.stdout.log#L18-L31>)记录：

- 890ns：valid0，ready1，inhibit0；驱动器首次发射。
- **910ns：valid1、ready1、inhibit0、源seq1，handshake1；native busy0、capture_ce0、request0。**
- **910.2ns：实际valid下降为0**，payload仍seq1，未提前污染。
- 930ns：valid0、handshake0，无旧930ns重复源offer断言。
- 950ns：live payload才变seq63；busy/request仍0。
- 100/200/300/400/500us进度均offers1、accepts0、adoptions0、acks0。

804ns phase4997、810.2ns 20ns脉宽、834ns phase5000已各观察首次；最终所需3次条件未完成。全部取消/恢复、整组谷值采用/回执、死区/0与5000完整覆盖均未达到，不得签收。

## 硬停止的静态证据：不是继续改TB撤销的理由

现有原生网表（未编辑）显示以下逻辑；这是文件只读分析，不是新仿真、DCP查询或实现。

1. pwm_cut.v:2152–2160的frozen_seq[31]_i_1为LUT5 INIT=32'h08000000，仅bit27为1。输入I0=p_15_in(reset_replica&&locked)、I1=auto_valid_i、I2=busy、I3=auto_inhibit_i、I4=online_pipe[1]。地址{I4,I3,I2,I1,I0}：

|reset/lock|valid|busy|cut端口inhibit|online|地址|CE|
|---:|---:|---:|---:|---:|---:|---:|
|1|1|0|0|1|19|0|
|1|1|0|1|1|27|1|

2. pwm_cut.v:3281–3286的request_i_1为LUT2 INIT=4'h7，request=!(auto_inhibit_i && reset_replica)，request连busy_reg.R(:1351)及request_reg.R(:3335)。按当前端口直接含义，inhibit0令这两个同步reset恒1。
3. ready LUT(:1144–1151)不含inhibit，因而可同时出现ready1、源握手1但CE0及busy持续reset，与trace吻合。

真实RTL握手要求!auto_inhibit_i，故**当前native cut端口直接解释与RTL接口语义存在不一致**。LUT有RETARGET属性，可能涉及跨层pin inversion/优化吸收/导出接口语义；现有证据没有证明或排除其映射。不能断言硅实现或生产RTL坏，也不能把“反转TB inhibit试试”归类为已证实的TB-only修复。

按Review疑似生产DUT/无法归类硬停止条件，已停止，不创建v2/v3、不试inhibit反相、不延长valid、不改0.2ns/相位/断言。后续需先Review native边界映射语义，未在本轮重导出、查DCP或改网表。

**更正旧证据解释边界**：前两轮结构计数/路径匹配只能说明相应单元保留，不能证明cut端口逻辑极性与源RTL功能等价；旧结论不能用于跳过本轮这一新发现。

## 原始状态与最终判定

受管作业硬停中断runner，原[summary](<v1/slow/summary.json>)保留RUNNING及最后进度快照，没有自然exit或最终PASS；不覆盖它。最终结论见[HARD_STOP](<HARD_STOP.json>)及[results](<results.json>)。没有伪造timeout/fatal或把受控终止exit1当DUT断言退出。

原两轮FAIL及本轮语法/slow所有日志均保留。直接复用服务器网表/SDF，未重复DCP/STA审计、重新导出/实现、打包/同步、SHA核查。生产RTL/约束/电机参数不变，无板卡操作。fast_inhibit原BD恒零独立动态N/A。原全设计STA及整链RTL证据独立保留，即使未来局部通过FULL_CHAIN_SDF仍不可PASS。PR41保持Draft，Issue40开放，不合并或关闭。
