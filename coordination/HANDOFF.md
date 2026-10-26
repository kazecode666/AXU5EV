# AXU5EV — 当前交接

日期：2026-10-26。仓库`kazecode666/AXU5EV`，本地`D:/Project/AXU5EV`。PR #7已合并；AX-00迁移、资料阶段结束，旧Issue #3及M4不作为当前流程。

## 当前任务与结果

按Issue #8及最新评论修复正常用户运行。已确认Hybrid接线顺序改变后，Runtime仍按旧20字段合同拆分：位置被读为replay速度0、速度被读为replay PWM 1。默认10 mm纯模型10秒复现位置16108 mm；现保留用户接线，统一Mux/Demux宽度`[11 3 1 1 1 1 1 1]`，字段20为位置、15为速度，旁注明确映射。

接口修复后由Runtime重新生成C并构建MEX。默认model_fixed的10 mm/5秒末位置10.01647 mm、首Ready=1.9199秒；C同Run完成10→0→−2 mm，Busy请求拒绝不排队，接受3/拒绝1。初始及运动中PI_Reset释放、Stop后新Run、暂停继续均完成程序验证。实际证据、Ready事件语义和范围见[Issue #8报告](reports/issue8_manual_run.md)。

活动模型和必要.m已逐项迁到`simulation/`。用户只编辑`init_AXU5EV.m`，运行`START_HERE.m`后点击Hybrid的Run；默认model_fixed，不自动Run。旧入口仅薄转发，不重复恢复默认目标。操作见[同目录中文说明](../simulation/README_运行说明.md)。

用户Hybrid、Runtime、Control紫色分区保留；只微调受影响接线与新观察器。MATLAB/Simulink后续只通过MCP操作，不用Computer Use。Dashboard绑定及程序输入已验证，实际鼠标/键盘操作NOT_RUN；说明已给最短人工步骤。c_rtl本轮仅实际213帧短链路验证通过，完整10 mm RTL到位NOT_RUN，不拿PR7旧1 mm结果替代。

本轮开放修复[PR #9](https://github.com/kazecode666/AXU5EV/pull/9)，等待Review与上述人工核验，不自动合并，不继续上板。接口修复提交`08e727e64e2a04c4f9666b513d5704e71e8b84f2`；入口/验证结果提交`3d5d009e1c85b1bfddf3b041711c91496189c374`。仓库均为`kazecode666/AXU5EV`，不是旧仓库编号。

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
