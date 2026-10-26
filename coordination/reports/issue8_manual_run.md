# Issue #8：默认点位与运行入口修复

仓库 `kazecode666/AXU5EV`；来源为已合并 PR #7，按 Issue #8 及其最新评论继续。保留用户 Hybrid、Runtime、Control 的紫色区域布局；不调整 PI、轨迹或五态对齐算法。

开放实现[PR #9](https://github.com/kazecode666/AXU5EV/pull/9)。接口修复提交`08e727e64e2a04c4f9666b513d5704e71e8b84f2`，入口与验证结果提交`3d5d009e1c85b1bfddf3b041711c91496189c374`；不自动合并。

## 已确认的第一处错误边界

用户调整 Hybrid 接线后，`R5_Input_Snapshot` 的输入分组顺序已成为“命令11、replay3、速度1、对齐使能1、Start1、Reset1、故障1、位置1”；Runtime Demux 仍按“命令11、位置1、速度1、对齐4、replay3”解释。总宽度均20，因此旧配置能够编译，但位置读成replay速度0、速度读成replay PWM 1，其余字段也错位。

原参数10 mm、V10/A100、纯模型10 s复现：末位置16108.1573 mm，末速度1685.16125 mm/s，Busy=1、Ready=0；目标与x_ref仍正确，不是纵轴显示误判。错误首先发生在反馈快照字段边界，不应通过调PI或改目标掩盖。

首次错误已在t=0快照出现：旧位置槽12为0、旧速度槽13为1，而电机实际静止。首个速度事件t=0.0009 s即产生错误iq_ref=−0.0180334749 A，早于0.05 s轨迹开始。沿草稿→接受目标→x_ref→真实x/v与快照→速度/电流参考定位，错误先在反馈字段进入Runtime时产生；原mm/m/rad换算、反馈方向、PI及FOC计算继续复用。

按用户最新要求保留Hybrid接线顺序，统一两端分组宽度为`[11 3 1 1 1 1 1 1]`，Runtime第2路交给replay、第8路交给位置。添加两端旁注、字段名、单位及Demux端口号与字段索引的区别。输入新合同见[接口说明](../../integration/ps_pl/INTERFACE.md)。重新由Runtime模型生成C并重建MEX，未手改生成C/SV。

针对性短验证：相同10 mm参数运行0.3 s，model_fixed与c_fixed的41字段最大差5.5511151231257827e-16，电机位置差0；末位置0.730861601 mm、速度8.53188004 mm/s。此短验证仅证明反馈与两后端已接通，不代替完整到位验收。静态连线/Stateflow检查通过。

## 集中入口与模型角色

活动Hybrid、Runtime、Control、独立FOC、浮点基线及必要.m逐项迁入`simulation/`，没有保留第二套同名活动模型。历史baselines/references不动；用户的`verification/r5/AXU5EV_R5_Reference.slx`修改与未跟踪wrapper不纳入本次提交。保留用户紫色区域、注释、位置；只微调受影响接线、新观察器与旁注。

`init_AXU5EV.m`唯一日常参数入口，`START_HERE.m`加载参数后仅打开Hybrid，默认model_fixed/10 mm/5 s/V10/A100；暂停或运行时拒绝重新初始化。`axu5ev_prepare`不恢复默认目标，普通Run不生成C；旧入口仅薄转发。Runtime是生成C入口，Control是独立组件来源，复制的组件不会自动同步。具体操作、对齐/复位与重建条件见[同目录说明](../../simulation/README_运行说明.md)。

增加明确SDI命名及backend/仿真时间显示；草稿、接受目标、轨迹参考分别记录。补齐位置误差与backend日志，并用1 ms针对性运行确认可记录；不为日志/文字修改重跑旧阶段。

## 实际验证

均为本机MATLAB R2026b功能仿真；主机C由ERT生成，MinGW构建MEX。不是托管SIL或R5实机。

| 检查 | 结果 | 本轮实际证据 |
|---|---|---|
| 静态结构/连线/Stateflow | PASS | 受影响层无未连接端口/悬线，原chart lint通过；入口/关键脚本Code Analyzer无问题 |
| 新START_HERE默认model_fixed | PASS | 10 mm/5 s；末x=10.01646659 mm，峰值10.07832980 mm，首Ready=1.9199 s；Busy=0、Ready=1 |
| C与模型 | PASS | 0.3 s提交最大差5.5511151231257827e−16；正常10 mm首段0–2.0914 s的x/v/id/iq及三相应用duty差均0 |
| C同Run正常命令 | PASS | 10→0→−2 mm；2.0915 s接受0，2.1015 s的11 mm被Busy拒绝，5.2998 s接受−2；接受3、拒绝1、段号3、最终Ready=1 |
| 初始PI_Reset=1→0 | PASS | 原10 mm参数，0.2 s释放；至0.5999 s位置/速度均0，原中断status7保持，不自动续段 |
| 运动中PI_Reset=1→0 | PASS | 0.30 s置1、0.35 s释放；x_ref保持1.297594293 mm，位置峰值1.799554537 mm，0.9999 s位置1.276243658 mm，无发散 |
| Stop后新Run | PASS | 新Run位置从0开始，自动首段/段号均1；0.2999 s位置0.730008666 mm，参考正常推进 |
| 暂停继续/发送入口 | PASS（程序操作） | 使用实际Dashboard绑定的常数入口；暂停继续未清状态，双向翻转均处理，拒绝不排队；不是鼠标/键盘Dashboard实测 |
| 反馈快照与应用边界 | PASS | 五组新记录的位置字段20、速度字段15均与同拍真实反馈完全一致；应用duty字误差0，+50 µs时间误差≤1.17e−16 s |
| 实际c_rtl短链路 | PASS（仅短段） | 实际213帧，捕获315、有效1、保持违规0；反馈/50 µs应用检查通过 |
| 完整c_rtl的10 mm到位 | NOT_RUN | 本轮不改FOC/RTL，仅做上述接口链短验证；不把213帧或PR7旧1 mm结果称为本轮完整点位验收 |
| Dashboard实际点击/输入确认 | NOT_RUN | 用户要求后续只用MCP；绑定/信号已核对，中文说明给出最短人工操作步骤 |
| 托管SIL、R5目标执行、AXI、5EV综合/布线、ARM实测、实机 | NOT_RUN | 未重装工具、未上板、未烧录或上电 |

Ready沿用原10 ms位置事件和连续5次窗口规则。连续工况最后五个事件6.4099–6.4499 s误差最大0.01950930 mm；停止帧6.4535 s瞬时误差0.02030708 mm，因为事件之间机械仍演化。没有放宽0.02 mm窗口，也没有强制Ready。status3记录最近一次请求被拒绝，不取消当前已接受的运动；下一有效请求仍须等待实际Ready。

## 证据与复用边界

- [工况结果](../../verification/issue8/run_results.csv)、[命令事件](../../verification/issue8/command_events.csv)、[反馈/应用](../../verification/issue8/feedback_and_application.csv)、[正常首段模型/C差异](../../verification/issue8/model_C_prefix.csv)。完整MAT留本地`.runtime/issue8/`。
- [修复前10 s](../../verification/issue8/before_10mm.png)、[默认10 mm修复后](../../verification/issue8/after_10mm.png)、[连续目标](../../verification/issue8/continuous.png)、[运动中复位](../../verification/issue8/reset_moving.png)。纵轴未裁切以掩盖异常。
- 保留100 µs软件、1 ms速度、10 ms位置、1 µs对象、50 µs应用、一次死区、原五态10000/30000/2000拍及0.5 A。原PL核心及算术未修改；新接口C生成后，后续仅搬迁/排版不再次生成算法。
- 剩余验收为实际Dashboard操作和完整RTL点位；后续板级与R5目标执行仍单列。不自动合并本修复PR，不继续上电阶段。
