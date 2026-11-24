# Issue #44 R02 B 组 Studio 监控负载实板阶段报告

2026-11-24，B1 CURRENT、B2 SPEED、B3 POSITION 的 10 s 稳定时序均为 **PASS**。三组共确认 300,000 个有效帧和下一 P0 采用，新增时序违约为 0。负载来自真实 Motor Control Studio。独立 PWM MMIO 严格同帧端点仍为 `PARTIAL`，C/D 和 T4 为 `NOT_RUN`。[任务书](https://github.com/kazecode666/AXU5EV/issues/44#issuecomment-7118374924) · [A 组复审](https://github.com/kazecode666/AXU5EV/pull/62#pullrequestreview-6035154268) · [A 组报告](irq_timing_r02_group_a_2026-11-24.md) · [实板索引](../../verification/experiment/ax04b/irq_timing_board.json)

## 会话、候选与采集

本轮在独立的 R02 加载会话 `20261124_163054_B` 完成。用户现场确认 J15/J16、驱动器、电机和外部功率电源均物理断开。Vitis 已下载 R02 ELF 并暂停在 R5_0 入口，同一会话手动加载配套 PR61 SELFTEST bit、执行 PS–PL 初始化后继续 R5_0。固件来源为 `cb5ffee8c9453435ee75aada9008c4cb1a31b7d1`。GEM3 回读 timing schema 2、profile 1、app `0x41585205`、PL `0x41584201`、dq `0x41583501`、1000 Mb/s。数字零偏校准版本为 3，两路均完成且电流有效，各正式工况前诊断的 `rt_ctrl_enable=0`。本轮使用既有 ELF、bit、LTX、XSA 与 A53 FSBL。[加载路径及 XSDB 回执摘录](../../verification/experiment/ax04b/evidence/irq-timing-r02/sessions/20261124_163054_B/jtag_load_observations.md) · [校准读回](../../verification/experiment/ax04b/evidence/irq-timing-r02/sessions/20261124_163054_B/calibrated_sample.json)

每组使用零给定，CLI 确认模式、CLEAR、ARM、显式 START 并做功能回读，然后设置 55 s 延时、10 s Summary。CLI 释放连接，Studio 在正式窗口前单独接管，实时运行页保持趋势监控。自然到期并观察到窗口后的 Studio 样本后，结束本轮专用 Studio 进程，再由 CLI 采后诊断、显式 STOP、读回和导出。三组最终读回均为 `armed=false`、`stop_pending=false`、`mode=0`、`fault=0`。

在 PC 的以太网 6（`192.168.50.20/24`）用 Wireshark 4.6.10 的 tshark 被动抓包，过滤 `host 192.168.50.10 and tcp port 5002`。按 TCP 流、方向、序号重组负载，按应用请求 ID 配对。使用 timing-start 的 PC 发送、接收时间及抓包时间加延时确定窗口边界，入窗统计采用最晚起点至最早终点。三个窗口前后都有 Studio 样本响应，边界不确定区间内请求数均为 0。表中带宽为应用负载，不含 TCP/IP 头。

| 工况及原始抓包 | PC 起点范围（UTC+8） | PC 终点范围（UTC+8） | sample / status | 应用请求 / 响应（B/s） | 错误 / 超时 / 缺回复 |
| --- | --- | --- | --- | ---: | ---: |
| [B1 CURRENT](../../verification/experiment/ax04b/evidence/irq-timing-r02/B1/gem3.pcapng) | 16:40:09.961544–09.963133 | 16:40:19.961544–19.963133 | 93 / 10（9.3 / 1.0 Hz） | 113.3 / 11,259.3 | 0 / 0 / 0 |
| [B2 SPEED](../../verification/experiment/ax04b/evidence/irq-timing-r02/B2/gem3.pcapng) | 16:42:24.146305–24.147914 | 16:42:34.146305–34.147914 | 93 / 10（9.3 / 1.0 Hz） | 113.3 / 11,259.3 | 0 / 0 / 0 |
| [B3 POSITION](../../verification/experiment/ax04b/evidence/irq-timing-r02/B3/gem3.pcapng) | 16:44:27.262914–27.264491 | 16:44:37.262914–37.264491 | 93 / 9（9.3 / 0.9 Hz） | 112.2 / 11,204.7 | 0 / 0 / 0 |

三个窗口的最大采样请求间距分别为 110.69、111.29、110.92 ms。正式窗口流中只有 `sample` 和 `status`，未见 CLI 与 Studio 并发接管，也未触发业务 trace 或趋势 CSV 导出。

## A/B 时序复算

对三份 `timing.ndjson` 分别执行 `python scripts/irq_timing_analyze.py <文件> --group B`，与归档 `analysis.json` 逐项一致。每窗 base/speed_1ms/position_10ms 为 90,000/9,000/1,000，PMU 阶段和 PL 上下界计数均完整。各窗均自然到期，缺帧、间断、拒绝、迟交或目标错误、新增 overrun、无效、转换、夹取失效、回执错配或待确认、伪 IRQ、快照失败均为 0。最后一帧均核对了下一 P0 回执。Summary 详细记录数为 0，P99 为 null。

| 工况 | PL 首→末 tick | 接受上界峰值 IRQ seq | 末次采用 version / target |
| --- | --- | ---: | --- |
| [B1](../../verification/experiment/ax04b/evidence/irq-timing-r02/B1/analysis.json) | 32363455000 → 32863450000 | 6564716 | 6159165 / 3286345500 |
| [B2](../../verification/experiment/ax04b/evidence/irq-timing-r02/B2/analysis.json) | 39072715000 → 39572710000 | 7889326 | 7501017 / 3957271500 |
| [B3](../../verification/experiment/ax04b/evidence/irq-timing-r02/B3/analysis.json) | 45228565000 → 45728560000 | 9136166 | 8732187 / 277889204 |

| 指标（µs，A → B） | CURRENT | SPEED | POSITION |
| --- | ---: | ---: | ---: |
| IRQ 响应上界最大 | 1.32 → 3.08 | 1.34 → 2.76 | 1.58 → 3.32 |
| 前台中断屏蔽最大观测 | 1.920 → 2.304 | 1.920 → 2.304 | 1.920 → 2.304 |
| 模型及准备均值，base / speed / position | 11.695/12.034/12.214 → 11.850/12.242/12.504 | 11.817/12.294/12.449 → 12.188/12.682/12.905 | 12.025/12.498/12.862 → 12.228/12.700/13.178 |
| ISR 观测最大 | 40.576 → 53.633 | 41.600 → 52.481 | 40.704 → 53.121 |
| IRQ→COMMIT 最大接受上界 | 35.06 → 44.82 | 35.04 → 44.74 | 34.92 → 45.14 |
| 最小保证余量 | 63.10 → 53.34 | 63.12 → 53.42 | 63.24 → 53.02 |

截止为 P76→P4984，4,908 拍（98.16 µs）。B 组复用 R02、R5 BSP 499,994,995 Hz、PMU ÷64、PL 名义 50 MHz。A/B 的接受上界增长 9.70–10.22 µs，对应不同上电会话下的观测差异。IRQ 入口上界含到首次相位读取的开销，ISR 尾部观测不含 EOI 和退栈。接受上界来自同帧相位夹取。有限窗口观察不能建立形式化 WCET。

## 窗口前后 FOC/PWM

采集在窗口外进行，保留每次为取得同帧证据而补采的响应（每端最多 12 次）。六个冻结快照中 `words[41]=3`，FOC sample_id/tick 与冻结快照一致，`words[63/64]` 等于冻结样本号。冻结快照覆盖正式窗口。FOC offer 和冻结采用序号的 32 位模差与冻结诊断 tick 差一致。IRQ/ACK/COMMIT 增量与独立 `rt_tick` 的帧差一致。B1、B3 的 RT 与冻结读数跨度差 1 帧。

| 工况 | 冻结诊断 tick 前→后 | 冻结间隔帧 / offer 增量 | IRQ/ACK/COMMIT 各增量 | 独立 PWM 相对冻结偏移 前 / 后 |
| --- | --- | ---: | ---: | ---: |
| B1 | 29613205000 → 32954270000 | 668,213 | 668,214 | 0 / +500 |
| B2 | 36322010000 → 39660640000 | 667,726 | 667,726 | +500 / 0 |
| B3 | 42478330000 → 45815060000 | 667,346 | 667,345 | +500 / 0 |

FOC late、invalid、overrun、reject 新增均为 0，历史累计 overrun 保持 413,525，来源未定位。独立 PWM 的六个端点许可均为 127。三个端点的序号比冻结样本晚一帧。B2 后端点的序号相同，但 `pwm_receipt_coherent=false`。B1 前、B3 后端点同时满足序号匹配和独立读回一致。冻结诊断支持连续内部 PWM 采用，严格同帧证据为 `PARTIAL`。本实验限于 SELFTEST 内部观测，外部 PWM 电气、REAL IO、真实电机跟踪及功率运行仍待验证。

## 先前 B1 尝试与归档

- 初次 B1 因 Studio 接管未成功触发保护性 STOP；记录提前冻结为 `INCOMPLETE`，共 6,507 帧，其中 6,291 有效、6,290 确认采用。保留原抓包和提前冻结证据。[初次尝试](../../verification/experiment/ax04b/evidence/irq-timing-r02/attempts/B1_no_studio/)
- 第一次获准重测取得时序 PASS。实时抓包输出交付滞后，PC 监督器未在原等待时限读到窗口后样本，触发保护性 STOP，缺少运行中的窗口后诊断。离线读原 pcapng 确认正式窗口有 92 次 sample、10 次 status，且窗口后仍有有效回执。第二次获准重测将末尾判定改为基于抓包时间戳并预留交付时间。[抓包交付滞后尝试](../../verification/experiment/ax04b/evidence/irq-timing-r02/attempts/B1_capture_delivery_lag/)
- NDJSON 和 pcapng 均逐字节保留，文本统一为 UTF-8/LF。正式结果、两次 B1 保留记录和会话身份集中在证据目录。本地辅助脚本留在 `.runtime/board_tests/irq_timing_r02/20261124_163054_B/`。[证据目录](../../verification/experiment/ax04b/evidence/irq-timing-r02/)
