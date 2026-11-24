# Issue #44 R02 T3-C1 持续网络负载实板阶段报告

2026-11-24，P61_TIMING_R02 在 SELFTEST 无功率、POSITION 零给定下完成 60 s Summary。稳定时序 **PASS**，600,000 个有效帧全部取得下一 P0 采用回执。实际业务负载为 sample 100 Hz、status 10 Hz、diagnostics 10 Hz。最大 IRQ→COMMIT 接受上界 46.82 µs，最小保证余量 51.34 µs。C1 的冻结 FOC/PWM 连续计数及独立 PWM 前后同帧端点均通过，显式 STOP 已核对。[C1 任务书](https://github.com/kazecode666/AXU5EV/issues/44#issuecomment-7128027083) · [实板索引](../../verification/experiment/ax04b/irq_timing_board.json)

## 现场与候选

用户现场确认 J15/J16、驱动器、电机和外部功率电源均物理断开。最初的 GEM3 连接在 ARM 前超时，PC 邻居状态为 `Unreachable`。Vitis 日志显示 18:47 已启动 R02 调试、执行 A53 FSBL，并下载 R5 ELF。XSDB 读回 R5_0 暂停在 ELF 入口 `0x3c`。随后复用该调试会话的 FSBL/ELF，加载 R02 工作区的配套 PR61 SELFTEST bit，完成 PS–PL isolation removal 和 reset config。R5_0 在 `main()` 断点停住后继续，XSDB 回读 `Running`，GEM3 恢复响应。初次抓包在关闭前记录了恢复后的三个只读查询，初次尝试未发送控制命令或创建时序窗口。[加载路径及回执](../../verification/experiment/ax04b/evidence/irq-timing-r02/sessions/20261124_184744_C1/jtag_load_observations.md) · [超时尝试](../../verification/experiment/ax04b/evidence/irq-timing-r02/attempts/C1_prearm_timeout/)

固件来源为 `cb5ffee8c9453435ee75aada9008c4cb1a31b7d1`。工作区为 `.runtime/experiment/final/P61_TIMING_R02/vitis`，启动项为 `Motor_Control_GEM3_SELFTEST_P61_Timing_R02`。使用该候选现有 ELF、bit、LTX、XSA 和 A53 FSBL。GEM3 回读 timing schema 2、SELFTEST profile 1、app `0x41585205`、PL `0x41584201`、dq `0x41583501` 和 1000 Mb/s。新会话初始 IDLE、无故障、`CTRL_EN=0`，时序捕获 ID 为 0。数字零偏校准版本 3，两路完成且电流有效。SELECT POSITION 后确认选中版本，CLEAR 确认后 ARM，发一次显式 START。功能样本确认 POSITION、位置和速度有效、零位置给定、参考获准、COMMIT 接受和 P0 有效。[版本](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/version.json) · [校准](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/calibrated_sample.json) · [功能样本](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/functional_sample.json)

## 实际负载与覆盖

Python 客户端在一条 TCP 连接上串行发出请求，读全响应后才发下一条。每类请求按固定周期调度，跨过的时隙跳过，启用 `TCP_NODELAY`。正式窗口前以同一 POSITION 工况试跑 12 s，主机日志和抓包各确认 1,200/120/120 次请求，实际 100/10/10 Hz，零响应错误、超时或缺回复。预定规则为任一类达到率低于 98% 时将该类降至实测速率的 90%（向下取整）并预跑一次。本次保留原计划。正式窗口前后连续维持该业务负载，窗内无控制命令或业务 trace。[预跑统计](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/trial_nominal.json) · [调度配置](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/run_configuration.json)

Wireshark 4.6.10 的 tshark 在以太网 6（`192.168.50.20/24`）被动保存 `host 192.168.50.10 and tcp port 5002`。离线按 TCP 流、方向和序号重组字节，去除重复载荷，按应用请求 ID 配对并与主机日志交叉核对，确认正式窗口流为 0 且每次仅一个请求在途。用主机与抓包的 `timing-start 3000 60000 0` 请求、响应时间加延时，并给起/止上边界各预留一个 100 µs 帧，PC 起点范围为 19:07:11.316904–19:07:11.318826，终点范围为 19:08:11.316904–19:08:11.318826（UTC+8）。确定入窗以最晚起点至最早终点统计。边界不确定区间请求数为 0。窗口前样本 tick 3,167,615,000 小于正式首帧 3,167,990,000。窗口后样本 tick 6,168,135,000 已超过末帧的下一 P0 回执 tick 6,167,990,000。[原始 pcapng](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/gem3.pcapng) · [复算结果](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/pcap_diagnostic_verification.json)

| 业务 | 确定入窗请求 | 实际 Hz | 发送 / 响应应用字节每秒 | 最大请求间距 ms | 最大响应时间 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| sample | 6,000 | 100 | 1,200 / 118,290.9 | 11.961 | 6.266 |
| status | 600 | 10 | 120 / 1,840.0 | 100.633 | 1.940 |
| diagnostics | 600 | 10 | 170 / 8,694.2 | 101.132 | 4.591 |
| 合计 | 7,200 | 120 | 1,490 / 128,825.1 | 11.170 | 6.266 |

共发送 89,400 应用字节，收到 7,729,506 应用字节。错误、超时和缺回复均为 0。原始 pcapng 共 18,280 个包，接口丢包计数 0，TCP 分析无缺段、重传、乱序或 ACK 缺段标记。捕获自然关闭后统一复算，现场监督直接使用客户端回执和 PL tick。

## 时序与 A3/B3/C1 对比

使用现有 `python scripts/irq_timing_analyze.py <timing.ndjson> --group C` 复算。捕获 ID 1，自然到期 `elapsed`。base/speed_1ms/position_10ms 为 540,000/54,000/6,000，各阶段和 PL 夹取计数一致。缺帧、间断、无效、转换、拒绝、迟交或目标错误、overrun、伪 IRQ、快照失败、未夹取、回执错配或待确认均为 0。末帧 IRQ seq 1,233,598，采用版本 1,225,209、target 616,799,000，在 seq 1,233,599 的同帧回执中匹配，PL tick 相差 5,000 拍。全窗最大接受上界在 speed_1ms 的 IRQ seq 950,729，PL tick 4,753,640,000。Summary 详细样本数为 0，P99 为 null。[原始时序 NDJSON](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/timing.ndjson) · [时序分析](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/analysis.json)

| 指标 | A3 无主动业务 | B3 Studio | C1 持续网络 |
| --- | ---: | ---: | ---: |
| 窗口 / 有效及采用帧 | 10 s / 100,000 | 10 s / 100,000 | 60 s / 600,000 |
| sample / status / diagnostics 实际 Hz | 0 / 0 / 0（操作记录） | 9.3 / 0.9 / 0 | 100 / 10 / 10 |
| IRQ 响应上界最大（µs） | 1.58 | 3.32 | 4.86 |
| 前台中断屏蔽最大观测（µs） | 1.920 | 2.304 | 2.560 |
| 模型及准备均值，base / speed / position（µs） | 12.025 / 12.498 / 12.862 | 12.228 / 12.700 / 13.178 | 12.637 / 13.592 / 13.314 |
| ISR 最大观测（µs） | 40.704 | 53.121 | 55.553 |
| IRQ→COMMIT 最大接受上界（µs） | 34.92 | 45.14 | 46.82 |
| 最小保证余量（µs） | 63.24 | 53.02 | 51.34 |

三个窗口使用 R5 BSP 499,994,995 Hz、PMU ÷64、PL 名义 50 MHz。P76→P4984 截止为 4,908 拍（98.16 µs）。C1 接受上界比 A3 和 B3 分别高 11.90、1.68 µs。负载、会话和窗口长度均有差别，峰值差只作为工况观测。IRQ 入口上界含首次相位读取，ISR 尾部采点在 EOI 和退栈之前。有限窗口无法建立形式化 WCET。[A 组报告](irq_timing_r02_group_a_2026-11-24.md) · [B 组报告](irq_timing_r02_group_b_2026-11-24.md)

## FOC/PWM 端点与停止

窗口外冻结诊断 tick 为 3,017,845,000 → 6,198,955,000，覆盖正式首尾。两端 `words[41]=3`，FOC sample_id/tick 和冻结快照一致，offer 及采用序号与冻结样本号一致。间隔 636,222 帧，offer 增 636,222、冻结 PWM 采用序号增 318,111,000。独立 RT tick 跨 636,223 帧，IRQ/ACK/COMMIT 各增 636,223。FOC late/invalid、reject 和新增 overrun 均为 0，历史累计 overrun 保持 8,388，来源未定位。两端独立 PWM 序号偏移均为 0，`pwm_receipt_coherent=true`，`pwm_use_permission=0x7F`。C1 前后独立同帧证据为 **PASS**。A/B 原结论仍按各自证据为 `PARTIAL`。[窗口前诊断](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/before_diagnostics.json) · [窗口后诊断](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/after_diagnostics.json)

负载跨过自然到期并取得后续样本后，保持运行读取后端点诊断，随后显式 STOP。回读业务 sample `mode=0`（IDLE）、`fault=0`，状态 `armed=false`、`stop_pending=false`，诊断 `rt_ctrl_enable=0`、`rt_fault=0`。D、T4、REAL IO 及功率实验为 `NOT_RUN`。[STOP 响应](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/stop_reply.json) · [STOP 状态](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/stop_status.json) · [STOP 样本](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/stop_sample.json) · [STOP 诊断](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/stop_diagnostics.json)

B1 首次早停保留一笔下一 P0 回执差异。首异常 seq 2,779,800（mode 0）期待 version/target 为 2,366,273 / 1,389,899,500，实际保留 2,366,272 / 1,389,899,000。该证据与 STOP 清除尚待采用的参考相符，留待 D 组核对 STOP 取消和安全语义。[B 组复审](https://github.com/kazecode666/AXU5EV/pull/62#pullrequestreview-6036264129) · [B1 首次尝试](../../verification/experiment/ax04b/evidence/irq-timing-r02/attempts/B1_no_studio/)

原始 pcapng 和时序 NDJSON 与本地采集源逐字节一致，其余文本以 UTF-8/LF 归档。正式采集源为 `.runtime/board_tests/irq_timing_r02/C1_POSITION_20261124_190653`，本地辅助脚本在相邻的 `C1_tools`。候选未重建。[C1 证据目录](../../verification/experiment/ax04b/evidence/irq-timing-r02/C1/)
