# GEM3 电机控制通信

GEM3 使用 JL2121、ETH-02 的 192.168.50.10/24 和 MAC `02:45:30:31:00:10`。电机控制 TCP 端口为 `5002`。应用身份为 `0x41585205`，沿用 [R5 在线 API schema 1](../ps_pl/AX05A_ONLINE_ZH.md)。

## 请求和回执

客户端发送一行 ASCII，格式为 `id 操作 [参数...]\n`。固件回一行 JSON，含相同的正整数 `id`。一次连接内客户端按顺序发出请求并读取回执。请求最长 191 字节（不含 LF），也可用 CRLF。格式错误返回 `error: BAD_REQUEST`，无可读样本时返回 `NO_SAMPLE` 或 `NO_DIAGNOSTICS`。

| 操作 | 回执 |
| --- | --- |
| `version` | 协议号 `protocol=1`、API `schema`、应用和 PL 身份、硬件 profile（1 SELFTEST，2 REAL）、PHY 初始化协商速率。 |
| `status` | 所选、确认及下发版本，所选模式、许可、清故障确认和停止待处理状态。 |
| `sample` | `sample` 对象，包含 `sample_id`、50 MHz `tick`、`pl_sequence`、业务有效位、观测与实际生效回读。 |
| `diagnostics` | 按需返回 80 字快照 `words`、PWM 采用比较值、实时状态与 IRQ/ACK/COMMIT 计数。字索引见线上 API 合同。 |
| `command action mode rev x v id_a iq_a fine` | `firmware_request_id`、`decision`、`accepted_revision` 和最新控制状态。 |
| `calibration-gains gain_a_q24 gain_b_q24` | 暂存 REAL 的两路实测、非零、有符号 32 位 Q24 ADC 增益并保持停止状态。成功回 `staged: true`，非法值或 SELFTEST 回 `BAD_GAINS`。 |
| `trace-start groups` | 开始使用现有 256 帧记录器。传 `15` 选择全部业务组。与已有记录互斥时返回 `TRACE_BUSY`。 |
| `trace-status` / `trace-stop` | 查询或冻结记录，返回 `capture_id`、记录数、首帧元数据、跳过帧和连续性标记。 |
| `trace-read capture_id index` | 读取冻结记录，返回 0–2 条 `records`、起始索引和 `next_index`。索引从 0 开始，等于总数时返回空批。活动记录、过期 ID 或越界返回 `TRACE_UNAVAILABLE`。 |

`Action`、`Mode` 和 `decision` 数值与 [固件头文件](../../firmware/r5/motor_control/ax04b/ax05a_online.h)相同。位置用 mm，速度用 mm/s，电流用 A，电压用 V，角度用 rad。命令字段 `rev` 是选定模式的版本。按原 API 执行选择、确认、CLEAR、ARM 和显式 Start，查看 `decision=0` 后仍要检查 `sample` 的模型消费、COMMIT 接受和 P0 采用字段。REAL 校准先用 `calibration-gains` 暂存本机实测的 Q24 增益，再在零电流条件下显式发 `CALIBRATE`。REAL 拒绝运行、ARM 和驱动复位，PL 硬禁止保持。

`groups` 的 bit 0–3 分别表示 PS、ADC、FOC 实际参考、dq 有效组。组内还需检查 `position_valid`、`speed_valid`、`current_valid` 等标记。数字占位和非有限值对应的 `null` 均不能代替有效性判断。位置与速度参考、电流参考和 dq 电压使用与该样本身份匹配的来源，`ud_v`、`uq_v` 只有 dq 组有效时可用。

## 轮询、记录与重连

- Python 客户端的 `watch` 每约 100 ms 请求一次最新业务快照。诊断按需读。记录器在前台每隔至少 2 ms 尝试抓取最近帧，`missed` 包含降采样跳过的帧。实际采样间隔以记录的 tick 为准。
- 下载按两帧分批进行，保留记录 ID、首帧信息、有效性与每帧 ID/tick。NDJSON 第一行含 `capture` 元数据，随后每行是一帧。传输或写入中断时会保留 `.partial`。
- TCP 新连接取代上一个连接，只清理传输缓冲区。PC 的 `id` 可从 1 开始。固件给通过 TCP 解析的控制命令分配递增的内部请求号。TCP 断开或 PC 超时没有控制操作副作用，已接受命令和记录保留。重连后先读状态并根据需要显式发命令。客户端不重发超时命令，也不恢复上一次使能。

[Python 客户端](../../scripts/motor_control_client.py)可供 #54 直接导入，主要入口为 `MotorControlClient.request`、`command`、`sample`、`download` 和 `Action`、`Mode`。GUI 可在各自 I/O 线程串行调用同一个连接。
