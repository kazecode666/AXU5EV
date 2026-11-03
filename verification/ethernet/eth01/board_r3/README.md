# ETH-01 r3 用户实板精简归档

实测日期2026-11-02，归档日期2026-11-03；仓库kazecode666/AXU5EV、PR17。依据为[用户实板结果评论6577441490](https://github.com/kazecode666/AXU5EV/pull/17#issuecomment-6577441490)及本地现有结果。本轮仅只读核对和归档，没有重新构建、运行测试或操作板卡。

用户使用PS J6/JL2121，Workspace为`D:/Project/AXU5EV/.runtime/ethernet/eth01/vitis_ethernet_r3`，Launch为`eth01_tcp_manual_r3`。评论记录串口build45303103、PHY地址1、ID937c4032、PHYSR=0x182e、1000Mbps全双工及TCP_READY 192.168.50.10:5001；这是用户串口记录，非本轮新增采集日志。四份本地JSON均为USER_BOARD_RUN、PASS、errors=[]、build_id=1160786179（0x45303103）、negotiated_mbps=1000、cache=1（I-cache ON / D-cache OFF）。

| 目录 / 入库结果 | 实板完整性结果 | 上传MiB/s | 下载MiB/s | 上传/下载秒 | 1MiB/s双向目标 |
|---|---|---:|---:|---:|---|
| [small_01](small_01/result.json) | PASS；0/1/255/256字节，模型计数0→4 | — | — | — | 不适用 |
| [bulk_64k_01](bulk_64k_01/result.json) | PASS；65536字节 | 0.994 | 1.371 | 0.062876 / 0.045574 | 未达（上传） |
| [bulk_1m_01](bulk_1m_01/result.json) | PASS；1048576字节 | 1.019 | 1.455 | 0.981748 / 0.687110 | 达成 |
| [bulk_32m_01](bulk_32m_01/result.json) | PASS；33554432字节 | 0.990 | 1.412 | 32.325830 / 22.666858 | 未达（上传） |

本地原始数据仍位于`D:/Project/AXU5EV/.runtime/ethernet/eth01/board/{small_01,bulk_64k_01,bulk_1m_01,bulk_32m_01}`；本目录只复制四份result.json。三份readback.bin的本地实际长度与各JSON字节数一致；大二进制和transfer.complete.json保留原路径，不入库。四个01目录已占用，不覆盖或要求重跑。

完整内容证据来自上述评论：ChatGPT已读取用户board.zip，并完整逐字节检查三份readback.bin，长度、内容和报告CRC全部一致。本轮本地只核对已有JSON与文件长度，没有重新执行内容校验或生成哈希清单。

PHY_LINK/TCP_IO/MODEL_BOARD_IO/BULK_TRANSFER记为用户实板PASS；完整性通过与吞吐目标分别记录，64KiB和32MiB上传略低于1MiB/s，本轮不优化。既有r3构建/启动检查证据及r2故障工程保留；不接完整电机Runtime，不据此宣称网络/100µs控制并发时序通过。断链恢复和性能优化以后按实际需要安排。PR17保持Draft待最终Review及用户决定合并，不自动合并或关闭Issue15。
