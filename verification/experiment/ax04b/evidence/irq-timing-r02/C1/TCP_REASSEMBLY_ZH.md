# C1 TCP 请求清单复算

原始 [gem3.pcapng](gem3.pcapng) 为 11,489,708 字节。复算导出 [逐请求 CSV](tcp_request_list.csv) 和 [汇总 JSON](tcp_reassembly_summary.json)。该补充仅对已归档文件离线运行。

在仓库根目录执行以下命令。将 `--tshark` 指向本地 tshark 4.6.10 可执行文件，或省略该参数使用 PATH 中的 tshark。

```powershell
$c1 = 'verification/experiment/ax04b/evidence/irq-timing-r02/C1'
python -B "$c1/reassemble_requests.py" --tshark 'D:/Program Files/Wireshark/tshark.exe' > "$env:TEMP/c1_requests.csv" 2> "$env:TEMP/c1_reassembly.json"
```

脚本从 tshark 的 `frame.number`、`frame.time_epoch`、`tcp.stream`、`ip.src`、`tcp.seq_raw`、`tcp.payload` 字段读取有载荷的包。按流和方向处理 32 位序号，跳过已接收的重复字节，遇到前向缺口停止，以换行切出应用请求和 JSON 响应。按 `(stream, id)` 配对。CSV 中的 `tx_packet`、`rx_packet` 是各应用行完整可读的包号，时标为对应抓包 Unix 秒。字节数包括行终止符。空 `error` 表示响应无错误字段，空 `rx_epoch` 表示未配到响应，`sample_tick` 仅在 sample 回包存在时填入。[复算脚本](reassemble_requests.py)

- `preflight` 由 12 秒主机预跑日志中的请求 ID 与流号关联，复算 1,200/120/120 次 sample/status/diagnostics。
- `formal` 取最晚起点至最早终点。起点范围由 timing-start 在 PC 日志及 pcap 的发送和响应时标加 3 s 得到，上界额外加一帧 100 µs，终点范围加 60 s。范围内存在边界歧义时标记 `boundary_uncertain`，本次为 0。前后覆盖样本 ID 1841/9042 的 PL tick 为 3,167,615,000 和 6,168,135,000，包住首帧和末帧下一 P0 回执。[主机边界](pc_bounds.json) · [时序导出](timing.ndjson)
- 筛选 `scope=formal` 后按 `verb` 计数并除以 60 得到实际 Hz。发送、响应字节分别求和并除以 60 得到 B/s。按类取相邻 `tx_epoch` 最大差和 `rx_epoch-tx_epoch` 最大值。超时阈值为 1.3 s。共 7,200 次请求、89,400 发送字节、7,729,506 响应字节，错误、缺回复、超时均为 0。
- 从 pcapng 增强包块计 18,280 包，从接口统计块读取 `ifrecv=18280` 和 `ifdrop=0`。tshark 的缺段、重传、乱序和 ACK 缺段过滤均无结果。[原采集复算](pcap_diagnostic_verification.json)

CSV 含整段抓包中 9,128 个应用请求，包括预跑、正式窗和窗外命令、诊断及导出。脚本保留 pcap 小数时间戳。与原统计的浮点纪元值相比，个别四舍五入值有亚微秒差异，请求归属和字节数一致。
