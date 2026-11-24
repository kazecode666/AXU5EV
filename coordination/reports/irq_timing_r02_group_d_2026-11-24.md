# Issue #44 R02 T3-D 控制转换实板阶段报告

2026-11-24，七个无功率 SELFTEST 窗口完成指定控制转换及最终 STOP 核对。D2 在明确的 STOP 边沿再现 1 次待采用参考取消。其原始 `receipt_errors=1` 保留，其他窗口为 0。七窗均无新增 overrun、迟交或拒绝、缺帧、间断、未夹取、回执待确认、伪 IRQ 或快照失败。IRQ 内提交后安全重入未触发，记录为 `NOT_RUN`。[Issue #44 任务书](https://github.com/kazecode666/AXU5EV/issues/44#issuecomment-7118374924) · [C1 复审](https://github.com/kazecode666/AXU5EV/pull/62#pullrequestreview-6038365579)

## 会话与判读

用户现场确认 J15/J16、驱动器、电机和外部功率电源均物理断开，并授权本轮。开始时 GEM3 读回超时。Vitis 19:34 的启动日志记录了现有 R02 的 A53 FSBL 和 R5 ELF 下载，XSDB 确认 R5_0 暂停在 `0x3c`。按既有流程加载配套 PR61 SELFTEST bit，完成 PS–PL 初始化并通过 `main()` 断点继续运行。GEM3 核对 timing schema 2、profile 1、app `0x41585205`、PL `0x41584201`、dq `0x41583501`、1000 Mb/s 和空时序、业务 trace。候选固件来源为 `cb5ffee8c9453435ee75aada9008c4cb1a31b7d1`，本轮复用已构建产物。[Vitis 启动记录](../../verification/experiment/ax04b/evidence/irq-timing-r02/sessions/20261124_193442_D/vitis_launch_excerpt.txt) · [XSDB 回执](../../verification/experiment/ax04b/evidence/irq-timing-r02/sessions/20261124_193442_D/xsdb_receipt.txt) · [版本](../../verification/experiment/ax04b/evidence/irq-timing-r02/sessions/20261124_193442_D/version.json)

首轮上板功能核对中，辅助脚本把 ARM 后的正常待机状态误按未 ARM 检查。显式 STOP 后确认 IDLE、未 ARM、`CTRL_EN=0`。核对原始回执后修正检查，完成两路数字零偏校准（版本 4）、零给定 CURRENT 功能检查和 STOP。首轮误判发生在启动任何时序采集前。[初次检查记录](../../verification/experiment/ax04b/evidence/irq-timing-r02/attempts/D_initial_armed_idle_check/host_exchange.json) · [正式前置检查](../../verification/experiment/ax04b/evidence/irq-timing-r02/sessions/20261124_193442_D/initial_host_exchange.json)

每个工况用单一 GEM3 连接发有界控制命令及必要读回。每窗 `timing-start 0 25 1`，自然到期并保留 250 条 Detail，覆盖正式窗口的全部 250 帧。每窗显式 STOP 后核对 `mode=0`、`fault=0`、`armed=false`、`stop_pending=false`、`reference_permitted=false`、`rt_ctrl_enable=0`、`rt_fault=0` 和 `pwm_use_permission=0`，再导出。以 `python scripts/irq_timing_analyze.py <timing.ndjson> --group D` 复算，每窗的 `stable_timing` 为 `NOT_APPLICABLE`。本报告按实际控制边沿、安全状态和参考身份判定对应路径。与控制相关的请求及响应带主机时标归档。

## 转换覆盖

| 工况 | 实际证据 | Detail seq 范围 | 转换 seq | 有效 / 已采用 / 转换帧 |
| --- | --- | --- | ---: | ---: |
| [D1 START](../../verification/experiment/ax04b/evidence/irq-timing-r02/D/D1_START/) | ARM 后仍为 IDLE 且禁止参考，显式 START 后 0→CURRENT | 1,745,266–1,745,515 | 1,745,278 | 238 / 238 / 12 |
| [D2 STOP](../../verification/experiment/ax04b/evidence/irq-timing-r02/D/D2_STOP_1/) | CURRENT→IDLE，事件 578，取消上一待采用参考 | 1,748,364–1,748,613 | 1,748,377 | 13 / 12 / 237 |
| [D3 CLEAR/重新 ARM/START](../../verification/experiment/ax04b/evidence/irq-timing-r02/D/D3_REARM_START/) | CLEAR 已确认，重新 ARM 后维持 IDLE 且参考禁止，显式 START 后 0→CURRENT | 1,751,537–1,751,786 | 1,751,693 | 94 / 94 / 156 |
| [D4 ALIGN_START](../../verification/experiment/ax04b/evidence/irq-timing-r02/D/D4_ALIGN_START/) | 0→ALIGNMENT，事件 576，合成反馈下读到内部状态 1、`alignment_done=false` | 1,754,888–1,755,137 | 1,754,903 | 234 / 234 / 16 |
| [D5 PI_RESET](../../verification/experiment/ax04b/evidence/irq-timing-r02/D/D5_PI_RESET/) | CURRENT 中单帧重置边沿，事件 576，保持 CURRENT | 1,758,340–1,758,589 | 1,758,355 | 249 / 249 / 1 |
| [D6 ALIGN_RESET](../../verification/experiment/ax04b/evidence/irq-timing-r02/D/D6_ALIGN_RESET/) | IDLE 中单帧 Init_Reset，事件 576，读回对齐状态 0 | 1,761,295–1,761,544 | 1,761,309 | 0 / 0 / 250 |
| [D7 DRIVER_RESET](../../verification/experiment/ax04b/evidence/irq-timing-r02/D/D7_DRIVER_RESET/) | IDLE 中单帧驱动复位命令，事件 576，下一 P0 采用停机参考 | 1,764,152–1,764,401 | 1,764,165 | 0 / 0 / 250 |

D1、D3 的普通 START 由 Detail 中的模式跳变确认。固件的 START 标记使用 `start_delivered`，通常由 ALIGN_START 提升 start ticket，D1、D3 的 `transition_peak` 为 null。D3 的 CLEAR 后和 ARM 后读回 tick 分别为 8,757,955,000 和 8,758,280,000，均位于窗口内且处于 IDLE。CLEAR 和 ARM 的相邻 IRQ 各自没有专用事件位，表中仅对显式 START 的首个 CURRENT 帧计单帧阶段时间。D4 覆盖进入 ALIGNMENT 及内部状态 1，后续五态进程和物理对齐为 `NOT_RUN`。D6 的命令前后已处于状态 0，证据覆盖复位边沿。D7 的证据覆盖 SELFTEST 命令、IRQ 边沿及参考读回，外部复位引脚测量为 `NOT_RUN`。

## 转换阶段实测

下表时间单位为 µs。各行取上表所列的同一转换帧。每个边沿均有反馈读、模型、提交、ACK 的有效采点和同帧 PL 接受夹取。D6、D7 的正常有效样本为 0，阶段读数来自 Detail 的 IDLE 转换帧。七个转换帧各自接受的参考均核对了下一 P0 实际采用。每窗的 `detail_stage_statistics.json` 保存全部 250 帧的阶段统计和峰值身份。

| 工况 | IRQ 入口上界 | 反馈读 | 模型及准备 | 写入和回读 | ACK | ISR | 接受区间 | 该帧截止余量 | 全窗 ISR 最大 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| D1 | 2.04 | 9.088 | 22.272 | 9.856 | 0.512 | 52.225 | 40.80–42.96 | 55.20 | 52.225 |
| D2 | 1.26 | 9.984 | 22.784 | 9.856 | 0.512 | 50.305 | 41.40–43.56 | 54.60 | 57.729 |
| D3 | 3.34 | 9.728 | 24.704 | 10.240 | 0.384 | 55.297 | 45.00–47.14 | 51.02 | 55.297 |
| D4 | 1.22 | 9.216 | 22.656 | 10.368 | 0.384 | 49.280 | 40.92–43.08 | 55.08 | 53.505 |
| D5 | 1.36 | 9.856 | 21.504 | 9.600 | 0.512 | 47.872 | 39.76–41.90 | 56.26 | 55.425 |
| D6 | 1.32 | 9.216 | 18.944 | 10.240 | 0.512 | 45.056 | 37.18–39.34 | 58.82 | 51.713 |
| D7 | 1.70 | 8.832 | 19.456 | 8.320 | 0.512 | 42.880 | 35.78–37.94 | 60.22 | 50.049 |

使用 R5 BSP 499,994,995 Hz、PMU ÷64、PL 名义 50 MHz，P76→P4984 的截止为 98.16 µs。7 窗 1,750 帧的接受上界均可夹取，最大值为 D3 的 47.14 µs。全窗 ISR 最大为 D2 的窗口首帧 seq 1,748,364（57.729 µs）。前台中断屏蔽最大观测为 D3 的 4.096 µs。IRQ 入口上界含首次相位读取，ISR 尾部采点在 GIC EOI 和 BSP 退栈之前。Detail 记录写入计入窗口开销，实测最大值适用于这些窗口。提交后因 PL 失去许可或提交失败而触发的 IRQ 内 `safety_reentry` 在全部 Detail 中为 false，该分支、故障注入及全局复位为 `NOT_RUN`。

## D2 与 B1 的 STOP 取消证据

D2 的 seq 1,748,376 在 CURRENT 中接受 version 1,739,983 / target 874,188,000，接受上界为 29.54 µs。下一 IRQ seq 1,748,377 的 sample_id 为 874,188,000，两帧 PL tick 相差 5,000。两帧 PL 状态读数分别为 `0x355`、`0x343`。bit2 ARMED 和 bit4 ACTIVE_VALID 从 1 变为 0，bit1 INHIBIT 从 0 变为 1。bit3 REF_QUEUED 两次均读为 0；队列取消由提交、STOP、采用回执及下述 RTL 行为共同支持。该帧 `fault=0`、`stop_reason=1`（显式 STOP），应用回执仍保留前一采用的 version 1,739,982 / target 874,187,500。停止帧自身的安全参考 version 1,739,984 / target 874,188,500 在 seq 1,748,378 取得下一 P0 采用。[D2 前后帧](../../verification/experiment/ax04b/evidence/irq-timing-r02/D/D2_STOP_1/transition_verification.json)

B1 初次尝试的 seq 2,779,800 同样为事件 578、mode 0、stop_reason 1、PL 状态 `0x343` 和 fault 0。期望 version/target 2,366,273 / 1,389,899,500，实际保留 2,366,272 / 1,389,899,000。两次都符合 RTL 的 STOP 写触发 `cancel_all` 并清除 queued/active 的路径。D2 用前一帧已接受、STOP 后许可撤销、实际旧回执及后续安全参考采用把该因果链定位到具体 P0。两个原始窗口各保留 `receipt_errors=1`。D2 的这一次归类为有证据的预期取消，其余正常应采用的参考均已配对。B1 历史尝试仍为提前冻结的 `INCOMPLETE`。[B1 原始分析](../../verification/experiment/ax04b/evidence/irq-timing-r02/attempts/B1_no_studio/recovered_analysis.json) · [PL STOP 逻辑](../../hardware/axu5ev/motor_control/rtl/axi/ax04b_realtime_axi.sv#L127)

## 归档

七份时序 NDJSON 与本地原始文件逐字节一致，回执及分析文本为 UTF-8/LF。本地采集源为 `.runtime/board_tests/irq_timing_r02/20261124_193442_D`，现场辅助脚本在相邻的 `D_tools`。C1 已另从原始 pcapng 离线导出 9,128 条 TCP 请求，正式窗复算 6,000/600/600 次，应用发送和响应分别为 89,400、7,729,506 字节。C1 无重测。T4、REAL IO 和功率实验为 `NOT_RUN`，本提交供 ChatGPT Review。[验证索引](../../verification/experiment/ax04b/irq_timing_board.json) · [C1 TCP 复算方法](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/TCP_REASSEMBLY_ZH.md)
