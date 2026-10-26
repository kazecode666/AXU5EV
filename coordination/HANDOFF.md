# AXU5EV — 当前交接

日期：2026-10-26。仓库`kazecode666/AXU5EV`，本地`D:/Project/AXU5EV`。PR #7已合并；AX-00迁移、资料阶段结束，旧Issue #3及M4不作为当前流程。

## 当前任务与结果

当前执行Issue #8最新评论的Send/Ready采样边界核对，PR #9已合并，合并提交`e5c348eb23fd117dcca805ac9f01781c5b939b30`。Issue #11仅为后续架构讨论，不实施。新证据及复验入口见[发送与Ready报告](reports/issue8_send_ready.md)。

本轮开放实现[PR #12](https://github.com/kazecode666/AXU5EV/pull/12)，仓库`kazecode666/AXU5EV`，实现提交`bff686425bfdc440bad421d03ae9737483fca69b`，等待Review，不自动合并。model_fixed/c_fixed六次发送均采集，模型/C全41字段最大差1.77635683940025e−15；10→0→−2 mm，接受3/拒绝3/段号3。

默认10 mm实际复现Ready在1.9199 s升1、1.9799 s回0，Busy保持0；后一个位置事件误差0.020406857 mm超出原窗口。1.97985 s暂停看到Ready=1后翻转Send，下一R5拍1.9799 s请求被采集但status3拒绝；2.09 s反向翻转后正常接受。旧说明把3笼统称为Busy拒绝，并缺少明显回执，容易误判为未采集。本轮只修正说明、增加只读100 µs同拍状态/请求时间、结果、计数、段号显示；原Ready、PI、轨迹及拒绝不排队策略不变。

活动模型和必要.m已逐项迁到`simulation/`。用户只编辑`init_AXU5EV.m`，运行`START_HERE.m`后点击Hybrid的Run；默认model_fixed，不自动Run。旧入口仅薄转发，不重复恢复默认目标。操作见[同目录中文说明](../simulation/README_运行说明.md)。

用户Hybrid、Runtime、Control紫色分区保留；只向右扩展受影响面板，原块位置未移动。MATLAB/Simulink只通过MCP操作，不用Computer Use。新增`axu5ev_verify_send`读取Dashboard Binding变量并调节同一变量；程序调参不等同鼠标/键盘操作，实际UI刷新仍NOT_RUN。本轮不重生成C或RTL，不重跑无关阶段；完整RTL点位和板级验证仍NOT_RUN。

先前已合并[PR #9](https://github.com/kazecode666/AXU5EV/pull/9)完成接口字段修复、simulation集中入口、默认10 mm、复位释放及连续命令验证，实际范围见[原报告](reports/issue8_manual_run.md)。接口修复提交`08e727e64e2a04c4f9666b513d5704e71e8b84f2`；入口/验证提交`3d5d009e1c85b1bfddf3b041711c91496189c374`。旧213帧RTL与PR7旧1 mm均不作为本轮发送验证。后续实现PR供Review，不自动合并，不继续上板。

## 固定方向与可复用来源

- 目标板AXU5EVB-E；PCB/芯片完整料号、厂商XA/-1与手册XC/-2差异留待板级适配前核对。
- 单Cortex-R5F负责位置P、速度PI、原五态对齐/偏置、Host/参考/轨迹/恢复管理；PL复用电流FOC，负责同步采样/位置/角度、PWM与快速禁止。
- 活动算法源均在`simulation/`。Hybrid是日常整体闭环；Runtime是软件C生成入口；Control是PR5独立组件来源，复制进Runtime后不自动同步。不手改生成C/SV补算法。
- 原点位/S曲线函数、PI、采样周期与首相、手动Start、10000/30000/2000拍与0.5 A、一次死区、50 µs应用、PWM禁止后机械继续保留。
- PL来源`generated/legacy_m3_p3/FOC_DUT.sv`，仍按5000拍/帧合同；314拍不是新增外围后的整链延迟。
- 继承`references/legacy/PMLSM_Hardware_Interface_Map.md`、MBDL4和MIL/DSP的ia/ib/ic、0.1µm/count光栅、RELCON/ENCON/F_Reset及低有效ERRI/ERRU。不照搬DSP引脚，不重复索要已有定义。

## 工作与验证边界

保留当前本地编辑，不stash/reset/clean、不额外clone/worktree、不保存未保存窗口、不批量删除；From/Goto局部、端口默认外观，不全图重排。不增加位置积分、运动中重规划、CORDIC、标幺化或缩位。只做变更所需验证，不增加哈希清单、快照保护报表、额外冒烟或无关历史回归。

本轮为Windows主机生成C/MEX及有限实际RTL功能验证；托管SIL、R5目标编译/任务时间、真实AXI、5EV综合/布线、ADC/编码器/PWM板级适配、ARM实测、烧录与实机均NOT_RUN。硬件下载和功率级上电须另行授权。旧Artix结果不能当5EV验收。

原AX-01B结果见[历史报告](reports/ax01b_runtime_hybrid.md)，原R5提取见[PR5报告](reports/ax01_r5_extraction.md)，厂商/R5参考见[AX-00B](reports/ax00b_vendor_review.md)和[R5指南](../firmware/r5/ALINX_R5_REUSE_GUIDE.md)，仅当前需要时查用。旧运行指南已转向新的simulation入口。
