# GEM3 与 R5 电机控制离线验收

[Issue #53](https://github.com/kazecode666/AXU5EV/issues/53) 从合入 PR #55 的 `81e7f4c` 接续。两套候选复用同 profile 的已布线 XSA、bit、LTX 和 R5 生成 C 1.173。

## 复用与中断

- **ETH-01/ETH-02** 复用 `eth_platform.c` 的 AMD GEM3/lwIP 初始化、链式 pbuf 接收、消费后归还 TCP 窗口信用、分段发送和 PMU 自由运行计时。复用 `eth01_lwip_overlay.py` 及 `jl2121.inc` 的 GEM/PHY 适配。TCP 会话送入 AX-05A 前台 API。独立 ETH-02 实验的模型回放、TTC 调度和大文件协议保留在其原入口。
- **同一套 GIC** 由 AX-04B 应用初始化并注册一次 CPU IRQ 向量。PL INTID 121、优先级 `0x90`、高电平保持。GEM3 的 BSP 编码 `0x403f` 表示高电平 SPI，INTID 为 95，优先级 `0xa0`。GEM3 ISR 屏蔽自身 GIC 线路并置标志。前台执行原 AMD `XEmacPs_IntrHandler` 的 DMA/错误处理再开 GEM 线路。驱动注册钩子使用同一个 GIC 实例。PL 控制 ISR 的 ADC/FOC/COMMIT/ACK 路径保持原实现。
- **TCP 前台** 统一提供模式、给定、采样、诊断和记录操作。REAL 的两路实测 Q24 增益可经 TCP 暂存，随后走原零偏校准。UART 保留 BSP 与启动日志，进入前台后关闭字符输出，规避 AMD 驱动异常日志等待 UART。TCP 每轮执行至多 1 个应用请求和 1 次最多 1460 字节的 `tcp_write`，保留 lwIP 流控。AMD 裸机配置的 `xemacif_input` 每次至多消耗 1 个接收包。RX/TX 各有 16 个描述符。RX 在这一轮退回旧描述符后统一补充，连续流量无法耗用本轮刚补的描述符。捕获每隔至少 2 ms 尝试一次，下载每批最多 2 帧。

## 控制时序边界

PL 的现有窗口是 P76 至 P4984，名义约 98.16 μs，周期保持 100 μs。R5 普通 IRQ 入口期间 IRQ 被屏蔽，优先级仅决定待处理中断的顺序。GEM ISR 中新增的屏蔽段只有 GIC 分派、禁用一个 SPI 和保存标志，lwIP 和 DMA 回调放在可被控制 IRQ 抢占的前台。该单前台配置关闭 lwIP 的全局轻量级保护。D-cache 保持启用，使用 AMD 的非缓存描述符区和 DMA 缓冲区维护。运行期仍有 BSP D-cache 的短屏蔽段。以普通最大 1536 B 和 32 B cache line 推导，单次维护至多覆盖 49 条 cache line，耗时还包含屏障与总线等待。上线负荷也会共享 DDR 和 AXI。上述界限是工作量，时间上限须用实板 PMU 与 PL 相位关联测量。保留既有 IRQ trace 和 PMU 分段统计作为 [#44](https://github.com/kazecode666/AXU5EV/issues/44) 的测量入口。

## 验证

| 项目 | 证据 |
| --- | --- |
| AX-05A 在线 API | 主机 6 个场景通过，含上一轮 Ready 重放和 REAL 拒绝。 |
| Python 和 C 回环 | SELFTEST、REAL 2 个测试通过。覆盖分片及合并请求、控制和生效回读、TCP 重连与请求编号、REAL 增益校准、限幅拒绝、按需诊断、分批下载及帧身份。主机使用真实 C 服务和 R5 控制代码，PL 和 TCP 端点为主机测试环境。 |
| 复用 TCP 回调 | 上一轮链式 pbuf、发送背压、接收窗口回收及半关闭主机回归通过。该传输层沿用原实现。 |
| Vitis | SELFTEST R01 与 REAL IO R02 均以 Vitis 2026.1 完成目标构建及独立启动文件核对，结果为 `OFFLINE_STARTUP_CHECK_PASS`。两套 ELF 均无串口业务入口、输入和输出队列符号，UART 输出仅在启动阶段启用。复用原 Vivado 布线结果。见[结果索引](../../verification/experiment/motor_control_gem3/results.json)。 |
| 实板 | 此次 #53 离线验收时尚未上板。后续验收见下方 PR61 记录。 |

可用 `python tests/test_motor_control_ethernet.py --cc <本机GCC> --output <新目录> -v` 重跑两套回环。Vitis 冷启动协商和首次 DMA/MPU 设置在控制停止态进行。现场启动耗时和首帧时序未测量。

上一轮候选保留在原目录。此次重建存入 `.runtime/experiment/final/`，正式名称、版本和启动项保持原样。

## PR61 无功率 CURRENT 实板验收

PR61 SELFTEST + dq 使用已通过实现后时序的 bit 和独立 Vitis 候选。实体 JTAG Debug、手动 PL 下载、GEM3 通信、单次零给定 CURRENT 及显式 STOP 已完成。B→C 按 50 MHz tick 计为 850.9 ms、8,509 帧。B/C 的 `word[41]=0x03`、`groups=0xF`、`capture_valid=1`、`lock_blocked=0`。内部 PWM offer +8,509，FOC invalid +0，PWM 已采用序号 +4,254,500，两端回执一致。旧 R01 的 756.4 ms、7,564 帧窗口中 `word[41]=0xB1`、`groups=0x3`、invalid +7,564，offer 与采用序号维持 0。

现场 STOP 后核对了 `armed=false`、`stop_pending=false`、业务 `mode=0`、`fault=0`。J15/J16、驱动器、电机和外部功率级断开，外部硬禁止的结论来自软件回读，功率输出端电气未测。4 ns 是定向 XSim 注入，旧 bit 的物理脉冲未被直接观测。REAL 实现后时序及上板、#44 WCET、持续吞吐和功率运动为 `NOT_RUN`。

[PR61 九份原始 JSON](../../verification/experiment/ax04b/evidence/pr61-current/) · [旧 R01 六份 B/C 原始 JSON](../../verification/experiment/ax04b/evidence/r01-current-baseline/) · [字段与计数](https://github.com/kazecode666/AXU5EV/pull/61#issuecomment-7101789649) · [最终实板验收 Review](https://github.com/kazecode666/AXU5EV/pull/61#pullrequestreview-6022081411)。

[部署与启动](../../firmware/r5/motor_control/FIRST_RUN_GEM3_ZH.md) · [协议和 #54 复用入口](../../integration/r5_ethernet/MOTOR_CONTROL_GEM3_ZH.md)
