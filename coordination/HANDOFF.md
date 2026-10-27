# AXU5EV — 当前交接

日期：2026-10-27。仓库`kazecode666/AXU5EV`，本地`D:/Project/AXU5EV`。PR #7/#9/#12已合并；AX-00迁移、资料阶段结束，旧Issue #3及M4不作为当前流程。

## 当前任务与结果

本轮完成Issue #13最新正文：必要小修、同命令时刻的完整10→0→−2 mm生成C/真实RTL比较，以及短的Simulink模块搭建说明。C源码阅读/逐行学习任务已取消；Issue #11和板级工作不实施。见[本轮报告](reports/ax01c_simulation_closeout.md)及[唯一运行说明](../simulation/README_运行说明.md)。

开放实现[PR #14](https://github.com/kazecode666/AXU5EV/pull/14)，仓库`kazecode666/AXU5EV`，实现提交`9a6877546581301638a2bde7203db47896b4f8aa`，待Review，不自动合并。

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

本轮为Windows主机生成C/MEX与完整一组实际RTL反馈联合仿真；没有真实R5或其指令集/周期精确模型，20/41字段向量不是实际AXI。托管SIL/PIL、R5目标编译/任务时间、真实AXI、5EV综合/布线、ADC/编码器/PWM板级适配、ARM实测、烧录与实机均NOT_RUN。硬件下载和功率级上电须另行授权。旧Artix结果不能当5EV验收。

原AX-01B结果见[历史报告](reports/ax01b_runtime_hybrid.md)，原R5提取见[PR5报告](reports/ax01_r5_extraction.md)，厂商/R5参考见[AX-00B](reports/ax00b_vendor_review.md)和[R5指南](../firmware/r5/ALINX_R5_REUSE_GUIDE.md)，仅当前需要时查用。旧运行指南已转向新的simulation入口。
