# Issue #44 实时性测量候选

基线为 `kazecode666/AXU5EV` 的 PR61 合并提交 `f8c40db8b06596b5e19b006c6dbf7bf42b7f2823`。本轮范围是 T1/T2 测量准备和离线构建。T3 板测与 T4 实测判定均为 `NOT_RUN`。[任务书](https://github.com/kazecode666/AXU5EV/issues/44#issuecomment-7118374924)

Vitis R5 构建和文件级启动检查通过。原始构建日志、启动 JSON 与 host 模拟导出的路径见[离线结果](../../../verification/experiment/ax04b/irq_timing_offline.json)。日志保留首次长路径构建失败及短路径候选的后续结果。BSP 构建保留厂商代码的编译警告。

## 候选和启动

- 打开 `.runtime/experiment/final/P61_TIMING_R01/vitis`，选 `Motor_Control_GEM3_SELFTEST_P61_Timing_R01`。R5 ELF 为 `vitis/ax04b_realtime/build/ax04b_realtime.elf`，A53 FSBL 为 `vitis/ax04b_platform/export/ax04b_platform/sw/boot/fsbl.elf`，路径均相对候选根目录。
- 同一候选根目录的 `hardware/ax04b_selftest.{bit,ltx,xsa}` 和 A53 FSBL 与验收过的 `GEM3_Control_SELFTEST_P61_R01` 对应文件逐一核对。XSA 对应 PR61 实现。启动项由 FSBL 初始化并将 R5_0 停在入口，PL 在同一调试会话中手动加载。Studio 的 SELFTEST 准备入口使用这套 timing 候选。准备命令只写本地 Tcl。现场操作须另行授权。[GEM3 启动指南](FIRST_RUN_GEM3_ZH.md)
- `version` 应显示 `timing_schema=1`、SELFTEST profile 1、应用 `0x41585205`、PL `0x41584201`、dq `0x41583501`。R5 生成 C v1.173。旧固件可有相同应用和 PL 身份，现场同时保存实际 Workspace、启动项、bit/LTX 路径与加载回执、ELF 路径、PR 提交和版本响应。

```powershell
$env:MOTOR_CONTROL_CONFIG = 'firmware/r5/motor_control/build_config.gem3.selftest.timing.json'
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -s scripts/motor_control_build.py
python scripts/motor_control_build.py --check-startup
.\scripts\start_motor_control_studio.ps1 -Prepare SELFTEST -Output .\p61_timing.tcl
```

## 获准后的现场顺序

1. 保持 J15/J16、驱动器、电机、外部功率电源断开。先按 PR61 的零给定 CURRENT 顺序核对校准、控制状态、PWM 内部采用和显式 STOP。SPEED 和 POSITION 正式计时前各做零给定功能核对。ALIGNMENT 单独用有限窗口运行。
2. 稳定运行后启动窗口。下面是一段 10 秒汇总窗口，延时 2 秒后计入。A 组启动后让 CLI 退出，采集期间保持无业务请求。B 组启动后改由 Studio 单独持有连接，保留实际请求数与频率。C 组用单连接执行计划内负载，典型时长至少 60 秒。D 组单独记录状态转换，可用短 trace。
3. 按设定时间等待窗口结束并留出下一帧回执。切回 CLI 后显式 STOP，核对 `armed=false`、`stop_pending=false` 和业务 sample 的 `mode=0`，然后导出。必要时用 `timing-stop` 立即冻结早停窗口，末帧无后续回执时计入 `receipt_unresolved`。异常时保留数据，不自动重新 ARM。

```powershell
python scripts/motor_control_client.py timing-start --delay-ms 2000 --duration-ms 10000
# 窗口结束后，显式 STOP 并完成状态核对，再导出。
python scripts/motor_control_client.py timing-status
python scripts/motor_control_client.py timing-download .\current_idle_summary.ndjson
# 单独运行短窗口时，保留最先 256 条详细记录（约 25.6 ms）。
python scripts/motor_control_client.py timing-start --delay-ms 2000 --duration-ms 26 --detail
```

窗口按 50 MHz 冻结 PL tick 开始和结束。延时基于命令后的第一帧。末帧后的一次 IRQ 用于核对下一 P0。IRQ 完全停止时用 `timing-stop` 保存已采部分。控制 STOP 和 TCP 断线保留数据。新 `timing-start` 替换上一测量窗口。汇总可与业务 trace 共存。启用 detail 时，业务 trace 必须先冻结并导出，开始 detail 会接管共享 RAM。详细数据冻结后仍拥有 RAM，导出后可通过下一次汇总窗口释放。详细模式只存最先的 256 条 IRQ 记录，满后汇总继续，连续 10 kHz 时覆盖 25.6 ms。现场将汇总模式和详细模式分别记为独立工况。

## 时基、边界和扰动

| 观测 | 解释 |
| --- | --- |
| PL IRQ 和接受 | PR61 在 P76 冻结并置位 pending。P0 清零 `p0_age`，后续每拍递增。在 P4984 上升沿，判定使用边沿前的 4983。下一拍 4984 已达到 `COMMIT_LIMIT`，因此最晚有效边沿为 P4984。从 P76 到该边沿有 4908 拍，即 98.16 µs，距下一 P0 16 拍。 |
| 接受上下界 | 同一 IRQ 内、COMMIT 写前读 `P0_ID` 和 `PHASE`，接受回读后再读 `PHASE` 和 `P0_ID`。AR 握手读取旧 `p0_age`，读边沿编号为值 + 1。两个 P0_ID 等于冻结 sample_id，且相位与已核对的接受结果一致时，写前读边沿给出下界，写后读边沿与 P4984 的较小值给出上界。跨 P0 或不一致计 `unbracketed`，Window 的峰值和余量仅覆盖有界样本。 |
| IRQ 响应 | 初始 PHASE 读边沿给出 P76 至 C 入口的上界，含 GIC、向量、C 入口到状态读和相位 AR 的时间。PMU `entry` 取自 R5 C 回调，后续差值没有 GIC 响应。 |
| 接受回读、ACK 和 ISR | `accept_done` 在 DSB 后读完 RESULT、accepted version/target。ACK PMU 列使用精确序号写前到 DSB 后。IRQ 尾部记录覆盖 ACK 后的安全重入、原业务记录和测量更新，采点后仍有最终 IRQ 极值更新、C 函数返回、GIC EOI 和 BSP 退栈。下一 IRQ 结合序号、丢帧、overrun 核对。 |
| 下一 P0 与 P2500 | 当前 COMMIT 的 target 为 sample_id + 500，按 uint32 回绕。下一 IRQ 冻结身份内，在自身 COMMIT 之前读取前一包的 applied version/target。按 PL tick 差 5000、IRQ seq 差 1、sample_id、version 和 target 匹配。P2500 是当前帧 PL FOC/PWM 谷值采用，另用已有 diagnostics 和 ILA 观察。 |
| ILA/LTX | PR61 `realtime_ila` 在 100 MHz 的相关 PWM 时钟采样，深度 8192。probe0 低位顺序为 P0、frame、IRQ、active_valid、inhibit、fault，probe1 为 P0 ID，probe2 为 active target，probe3 为 PWM debug。可见 IRQ 置位和释放、P0 和 PWM 活动。真实 `accept_commit` 写判定边沿及接受相位没有导出。 |

R5 BSP 宏为 499,994,995 Hz，PR61 配套 PS 配置选择 RPU 时钟源及分频。启动汇编写 PMCR=0xD 并使能 PMCCNTR，因此该构建预期 PMU ÷64。导出读取实际 PMCR.D。短段使用 uint32 模差，约 550 秒绕回一次，整段窗口使用 PL uint64 tick。现场时基需结合实际载入的 PS 配置及导出值共同核对。

生成 C v1.173 的 `Software_Tick_DSTATE` 增加代表进入 Host_New_Frame。调用前读取两级计数和零交叉触发状态，确认本轮实际运行基频、1 ms 速度或 10 ms 位置共同到期路径。未运行模型、未接受提交、反馈无效、复位和安全重入不参与正常极值。停止、起动和复位转换保留在计数及可用的短记录中。

PL IRQ 121（优先级 0x90）与 GEM3 IRQ 95（0xA0）共享 GIC。R5 BSP IRQ 向量保存浮点现场，普通 IRQ 屏蔽至返回。GEM ISR 仅屏蔽自己的 GIC 线并置位。前台执行驱动回调、lwIP、TCP 和 JSON。`SYS_LIGHTWEIGHT_PROT=0`，相关 lwIP 宏为空。运行中 GEM DMA 调用 R5 BSP 的 cache flush/invalidate range，BSP 内部屏蔽 IRQ/FIQ。timing 候选在已计入首帧到冻结间把这些 cache 调用包在测量范围内，与应用 `irq_lock` 同计 `max_foreground_mask`。该度量包含包装开销，时间戳之外的 CPSR 指令和返回开销未计。

正常测量帧复用原 accepted 和 applied 回执，额外读取四个夹取寄存器及一次回执 P0_ID。IRQ 内只有固定存储、计数、范围累计和可选记录拷贝。读数本身消耗 AXI 时间，IRQ 上界衡量的是装有测量代码的候选。在同一工况分别保留汇总模式和详细模式结果。当前可在逐帧接受上下界有效时核对截止，无需改 PL。若现场出现无法夹取的样本，或需要准确的硬件接受峰值，可提交 Review 增加只读的接受相位寄存器，和现有 accepted version/target 同一边沿锁存并共用其有效语义。该方案需另行批准后修改 RTL 和实现。

## 导出与分析

NDJSON 首行为 `capture`、`version` 和 `rates`，其余每行为一条短窗口原始记录。每个 rate 含 8 个 metric，顺序如下。每项有 `count/min/max/sum/peak`，`peak` 带该最大值所在帧的 seq、sample_id、PL tick、entry phase、version、target、mode、result。

| 索引 | 字段 | 单位 |
| --- | --- | --- |
| 0 | P76 到入口相位读取的上界 | PL 拍 |
| 1 | entry 到 read_done，含反馈读取/资格检查和 P0 回执 | PMU tick |
| 2 | read_done 到 model_done，含准备和模型调用 | PMU tick |
| 3 | model_done 到 accept_done，含编码、写入、前界读和接受回读 | PMU tick |
| 4 | ack_begin 到 ack_done | PMU tick |
| 5 | entry 到 irq_end | PMU tick |
| 6、7 | P76 到接受判定的下界、上界 | PL 拍 |

分析表每行记工况、模式、负载请求数/速率/吞吐和错误、候选身份、采样范围、rate、计数、min/mean/max、max 帧身份、首异常及下一 P0 回执核对。均值为 `sum/count`。PMU 差值乘 `1e6 × pmu_divisor / cpu_hz` 转 µs，PL 拍乘 0.02 µs。全窗有界时最小保证余量为 `4908 − max(metric[7])` 拍。各段最大值分属各自峰值帧，端到端峰值取同帧 PL 上界。P99 可按 rate 对有效短记录复算，注明样本数和覆盖范围。

异常位 `1/2/4/8/16/32/64/128/256` 分别为间断、P0 回执不合、无效、拒绝、上下界不可用、伪 IRQ、预期转换、overrun、快照失败。`late_or_target` 是 RTL 共享结果码 2。`last_checked` 和 `receipt_frame` 给出最后一次已尝试配对的两帧身份。冻结时仍待配对的包计 `receipt_unresolved`。稳定窗口须报告全部新增异常与待确认数，现场观测最大值只适用于所记录的负载和时段。
