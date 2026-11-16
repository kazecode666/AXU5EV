# PR41 评论 6847609985：TB 候选 1（仅静态审核）

## 范围与依据

本候选仅新增 [pwm_cut_tb.sv](<pwm_cut_tb.sv>) 与本文；未改网表、SDF、旧 TB 或 RTL。未运行编译、展开或仿真，不能宣称 SDF PASS。

只读依据：
- [旧 buildfix TB](<../../pwm_cut_sdf_20261113_1522_buildfix/pwm_cut_tb.sv>)。
- [真实 bridge](<../../Issue40_PWM_Cut_Handoff/hardware/axu5ev/motor_control/rtl/axi/pwm_config_bridge.sv#L121-L129>)：posedge 接收条件为 valid && ready && !inhibit，冻结 compare/seq，置 request/busy；ready 由 !busy、online 和 mailbox reset 共同决定。
- [真实 motor_foc_control](<../../github_pr41_evidence_checkout/hardware/axu5ev/motor_control/rtl/control/motor_foc_control.sv#L103-L117>)：posedge 产生 valid/payload；真实握手同沿通过 NBA 撤销 valid，并进入 waiting_applied。这里只模拟其边界握手，不替代 FOC 算法或声称覆盖其 deadline。
- [真实 cut busy 寄存器](<pwm_cut.v#L1333-L1351>)：保留 dut.busy（busy_reg.Q），仅作只读 trace，不 force。

## 唯一驱动与任务协议

1. 所有 anchor、valid、compare、seq、inhibit 仅由同一个 posedge aclk 驱动块以 delayed NBA 更新（声明初始化除外）。任务只提交 mailbox，不写这些边界信号。
2. 请求提交于 negedge aclk +0.2ns；offer_request 为单槽请求 token；driver 取走后记 offer_claimed。任务只在 offer_done 等于当前请求后返回。任务串行，不支持同时取消尚未握手的 offer；本轮取消一律发生在实际接收 pending 之后。
3. driver 在每个源上升沿读取旧 valid/ready/inhibit。只有 valid===1 && ready===1 && inhibit===0 才记完成；不以“预计第二个沿”或事后 ready 电平推断握手。
4. valid 为高时不再重载 compare/seq；backpressure 下三者保持。握手沿 E 后 E+0.2ns 撤销 valid，payload 继续稳定；E+20.2ns 才由同一 driver 污染 live payload 为 seq=63、compare=17/31/47，以验证 cut 的冻结银行。
5. inhibit_request 同步到边界；锁丢失/全局 reset 仍在旧安全相位独立注入，先验证真实关闭后再显式环境 disarm。取消恢复沿用同一个 driver，不额外拥有 valid。既有旧请求 token 已消费，不会在恢复时重发。
6. pulse_anchor 仅写 anchor_request；保持 3 个等待源周期和恰好一个源周期高电平。online、pending 及 finish_offer 使用显式时钟轮询；finish_offer 保留 active_seq!=id、adopted_seq!=id、ready!==1 三项比较，不使用对固定 task 入参的 wait 敏感性推导。
7. hold_cycles 保持 n 个真实 PWM 周期和 #4ns settled 观察窗，返回前对齐 negedge aclk+0.2ns；没有第二套输出驱动。

## 保持的时间模型与断言

aclk 上升沿 10+20n ns；pclk 上升沿 10+10n ns，同相 2:1。source CQ=0.2ns 是 LOCAL CUT 假设，不是提取的上游 CQ；anchor 宽度 20ns，首个 PWM 采用边沿距 anchor Q 9.8ns，phase4997 后三沿到 phase5000（39.8ns）。不改相位、不改旧 #4ns settled 窗。

静态逐项比对：旧、新 44 条 check 调用的完整表达式和字符串完全相同（另一个 check( 匹配是 task 声明，不计调用）。保留两方向 >=990ns 死区、原子冻结银行、首个 eligible valley、取消禁止复活、真实 Q/两 falling-edge release、0/5000 边界等全部关键判据。精确目标仍为 11 offer/11 accept、8 adopt/8 ack、3 cancel/3 rearm、3 anchor/3 start/3 peak；原 carrier/边沿/边界非空阈值不变。

## 首笔 trace 与进度

PWM_CUT_FIRST_EDGE 从第一笔请求开始逐个源上升沿打印 valid/ready/inhibit/seq/pending/accepted/dut.busy、真实 capture_ce=dut.frozen_compare0 和 dut_request=dut.request_reg_n_0、请求/领取/完成 token 和 handshake；握手后额外四个源沿用于观察 valid 已撤销及 busy 的实际传播。PWM_CUT_FIRST_HANDSHAKE 打印 E 与预期退休时间 E+0.2ns；PWM_CUT_FIRST_RETIRE 在真实 valid 下降事件打印实际时刻及同组状态。trace 有界，不在长 hold 阶段逐沿刷屏。

原 100us 周期真实计数进度、场景/采用/anchor/start/peak 日志、5ms hard watchdog 原样保留。trace 尚未执行，不能把预期时间或静态推理称作实测。

## 静态审核结果

- 44 条旧 check 调用内容/顺序全部保留；未放宽阈值。
- valid_request 已消除；任务中无 valid/compare/seq/anchor/inhibit 输出赋值。
- 全部 wait(...) 已改为显式时钟轮询；没有 force 语句。
- 仅两个授权新文件写入；无全局 todo，无仿真，无硬件操作。

状态：STATIC_REVIEWED；COMPILE/ELAB/SDF_SIM NOT_RUN。后续运行和验收由父流程决定。
