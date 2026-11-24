# Issue #44 R02 A 组无业务网络负载实板阶段报告

2026-11-24，A1 CURRENT、A2 SPEED、A3 POSITION 的 10 s Summary 窗口稳定时序均为 **PASS**。三窗共计 300,000 个有效帧，全部核对了下一 P0 采用，窗口内新增违约计数为 0。冻结 FOC/PWM 诊断支持连续内部采用，独立 PWM MMIO 的严格同帧端点证据仍有保留。B/C/D 和 T4 综合判定为 `NOT_RUN`。[Issue #44 阶段总结](https://github.com/kazecode666/AXU5EV/issues/44#issuecomment-7124023504) · [PR62 阶段审查](https://github.com/kazecode666/AXU5EV/pull/62#issuecomment-7124025231) · [实板结果索引](../../verification/experiment/ax04b/irq_timing_board.json)

## 候选与会话

| 项目 | 本次证据 |
| --- | --- |
| 实测固件来源 | `kazecode666/AXU5EV` Draft PR62，`cb5ffee8c9453435ee75aada9008c4cb1a31b7d1`，R5 生成 C v1.173 |
| 运行身份 | SELFTEST profile 1、timing schema 2、应用 `0x41585205`、PL `0x41584201`、dq `0x41583501`、GEM3 1000 Mb/s。两会话的 version 与对应 NDJSON 中身份字段相同 |
| 候选路径 | `.runtime/experiment/final/P61_TIMING_R02`，启动项 `Motor_Control_GEM3_SELFTEST_P61_Timing_R02`，R5 ELF 为 `vitis/ax04b_realtime/build/ax04b_realtime.elf` |
| 时基 | 导出 CPU Hz 499,994,995 来自 R5 BSP，PMU divider 为 64，PL 名义 50 MHz。基础帧周期 100 µs，速度及位置共同到期周期分别为 1 ms 和 10 ms |
| 工况 | 零给定、SELFTEST 无功率隔离、外部功率输出硬禁止。网线保持连接，正式窗口内无主动 TCP 业务请求，依据现场操作记录。无独立抓包 |
| 会话 | A1 使用 `20261124_104755`；A2 和 A3 使用另一次独立上电的 `20261124_133846`。统计区间只在各自会话内使用 tick 和累计计数 |

本地核对了两个会话的 `commit.txt`、`version.json` 和 R02 已有的 `vitis/startup_validation.json`。既有启动检查记录为 `OFFLINE_STARTUP_CHECK_PASS`。R02 的 bit、LTX、XSA 和 A53 FSBL 与 PR61 原候选文件逐字节一致。当前本地 Vitis 启动项指向配套 R5 ELF、FSBL 和手动加载路径，`programDevice=false` 且 R5_0 入口暂停。IDE 填入的 bit 缓存与候选 bit 一致。本地检视范围内未找到能独立核实两次现场实际下载路径的 JTAG/XSDB 加载回执。候选路径来自现场记录，启动 JSON 和文件比对证明本地候选配套关系。[离线索引](../../verification/experiment/ax04b/irq_timing_offline.json)

## 稳定窗口复算

在仓库根目录逐组运行现有分析脚本，例如 `python scripts/irq_timing_analyze.py verification/experiment/ax04b/evidence/irq-timing-r02/A1/current_noload.ndjson --group A`。三份输出解析后的 JSON 均与当场保存的 `analysis.json` 完全相等。数值复核与 Issue #44 阶段总结一致。下表采用同帧 PL 接受上下界及各自 PMU 统计，P76 到 P4984 截止为 4,908 拍（98.16 µs）。

| 工况 | 有效 / 采用帧 | 最慢帧的接受区间（µs） | 最小保证余量（µs） | ISR 最大观测（µs） | IRQ 响应上界最大（µs） |
| --- | ---: | ---: | ---: | ---: | ---: |
| [A1 CURRENT](../../verification/experiment/ax04b/evidence/irq-timing-r02/A1/analysis.json) | 100,000 / 100,000 | 32.90–35.06 | 63.10 | 40.576 | 1.32 |
| [A2 SPEED](../../verification/experiment/ax04b/evidence/irq-timing-r02/A2/analysis.json) | 100,000 / 100,000 | 32.88–35.04 | 63.12 | 41.600 | 1.34 |
| [A3 POSITION](../../verification/experiment/ax04b/evidence/irq-timing-r02/A3/analysis.json) | 100,000 / 100,000 | 32.76–34.92 | 63.24 | 40.704 | 1.58 |

三个最大接受上界均来自 base 帧，IRQ 序号依次为 `35650161`、`7289282`、`28417525`。三个窗口的最大前台屏蔽观测均为 1.920 µs。每窗延时 2 s，均自然到期 `elapsed`，base / speed / position 计数均为 90,000 / 9,000 / 1,000，所有 PMU 阶段和 PL 接受夹取计数覆盖完整。缺帧、间断、拒绝、迟交或目标错误、新增 overrun、无效、转换、夹取失效、回执错误或待确认、伪 IRQ、快照失败均为 0。三份 Summary 的详细记录数为 0，因此没有 P99。

| 工况 | 正式窗口首→末 PL tick | 末帧采用 PL tick | 末帧采用 version / target |
| --- | --- | ---: | --- |
| A1 | 177794135000 → 178294130000 | 178294135000 | 35500135 / 649544316 |
| A2 | 36425665000 → 36925660000 | 36925665000 | 6583033 / 3692566500 |
| A3 | 141846290000 → 142346285000 | 142346290000 | 27667158 / 1349727112 |

末帧的 `last_checked` 与 `last` 相等，回执的 IRQ 序号加 1、PL tick 加 5000、样本号按 uint32 加 500。回读的 version/target 与末帧提交一致。各组功能样本确认了对应模式、零给定、`groups=0xF`、接受及下一 P0 采用。正式计时后的显式 STOP 均返回接受，后续读回 `armed=false`、`stop_pending=false`、`mode=0`、`fault=0`。A1 的独立功能复核没有单独保存 STOP 后的 status/sample，A2 的独立功能复核同样只有 STOP 回执。三组正式窗口均有完整的 STOP 后记录。

| 平均耗时（µs），依次 base / speed / position | A1 CURRENT | A2 SPEED | A3 POSITION |
| --- | --- | --- | --- |
| 模型与准备 | 11.695 / 12.034 / 12.214 | 11.817 / 12.294 / 12.449 | 12.025 / 12.498 / 12.862 |
| ISR 观测窗口 | 33.475 / 33.824 / 33.987 | 33.575 / 34.052 / 34.168 | 33.779 / 34.264 / 34.570 |
| COMMIT 接受上界 | 29.202 / 29.541 / 29.726 | 29.310 / 29.796 / 29.942 | 29.521 / 30.006 / 30.358 |

基频帧的反馈读与编码提交回读合计均值约 16.7 µs。POSITION 共同到期帧的模型与准备均值比 CURRENT 同类帧高约 5.3%。两工况分属独立上电会话，该差值只作为此次观测。

## FOC/PWM 交叉核对

冻结诊断取 `words[4:6]` 的 uint64 tick 和 `words[3]` 的 sample_id，三组前后端点均包住各自正式窗口。两端的 `words[41]=3`，FOC 捕获有效且无 hold/lock/late 标记。FOC 样本和 tick 与冻结快照一致，`words[63/64]` 均等于冻结 sample_id。冻结 PWM 采用序号的 32 位模差等于诊断间隔帧数 × 500（取低 32 位），A2 的诊断区间实际跨过 sample_id 回绕。

| 工况 | 冻结诊断 PL tick 前→后 | 间隔帧数及 IRQ/ACK/COMMIT/PWM offer 各增量 | 冻结采用序号模差 | 独立 PWM 相对冻结样本偏移 前 / 后 | 历史累计 Overrun 前 / 后 |
| --- | --- | ---: | ---: | ---: | ---: |
| A1 | 177292560000 → 183190735000 | 1,179,635 | 589,817,500 | 0 / +500 | 158,691 / 158,691 |
| A2 | 34818800000 → 43452510000 | 1,726,742 | 863,371,000 | +500 / +500 | 802,099 / 802,099 |
| A3 | 141412055000 → 143002245000 | 318,038 | 159,019,000 | +500 / +500 | 802,099 / 802,099 |

诊断区间内 FOC invalid、late、overrun、reject 的 uint32 模差均为 0。累计 Overrun 原值保留，历史来源未确定。独立 PWM 回读两端均有 `pwm_receipt_coherent=true`、`pwm_use_permission=127`。其中五个端点的独立 MMIO 回读比冻结快照晚一个样本（500 个转换序号）。该 coherent 标志只保证独立 PWM 从机内部回读一致，冻结诊断和独立 MMIO 的严格同帧端点留待确认。上表的采用序号模差来自冻结端点，保留独立回读原值。已结束的窗口无法用新的诊断快照补证。

## 证据边界和现场问题

- 测得的是带观测代码的 R02 候选。PL 侧报告同帧相位夹取的接受上界，精确接受时刻未知。PMU ISR 尾部采点之后还有极值更新、GIC EOI 和 BSP 退栈。有限窗口最大值只适用于这三段记录，形式化 WCET 未建立。
- SELFTEST 零给定验证覆盖内部 FOC/PWM 和控制回执。真实电机跟踪、外部门极 PWM 电气、REAL IO 和功率运行仍为 `NOT_RUN`。
- **Studio 首次显示。** 现场记录首次打开时窗口可能超过屏幕可用区、布局错位，最大化后恢复。初始窗口几何、最小尺寸和 DPI 待独立检查，未定位原因。
- **Vitis Debug 断联。** 现场报告调试会话曾断联，此后 GEM3 TCP 仍有响应，PL tick 和 COMMIT 继续增长。断联原因未确认，未找到独立的调试会话断联日志。现有时序测试范围保持 A 组窗口。

## 本地归档

三份原始 NDJSON 逐字节保留。原现场 JSON 和 commit 文本由 UTF-16LE BOM、CRLF 转成 UTF-8、LF，内容保持一致。A1/A2/A3 目录分别有 13 / 17 / 19 个文件，包含原分析、窗口 start/status、前后 diagnostics/sample/status、正式 STOP 与可用功能复核。另有两份会话身份目录合计 15 个文件，含 A1 初始、ARM 与运行复核。A2 和 A3 的本地目录与原 ZIP 内文件逐字节一致，归档采用展开文件。现场原始目录及原 ZIP 保留在本地。[证据目录](../../verification/experiment/ax04b/evidence/irq-timing-r02/)
