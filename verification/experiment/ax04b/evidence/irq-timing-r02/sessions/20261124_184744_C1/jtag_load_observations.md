# C1 R02 调试会话

日期为 2026-11-24（UTC+8）。用户确认 J15/J16、驱动器、电机和外部功率电源已物理断开。正式运行采用 Vitis 日志中 18:47 启动的会话。起初 TCP 连接超时，XSDB 核对 R5_0 暂停在 R02 ELF 入口 `0x3c`。完成配套 PL 加载并继续 R5_0 后，GEM3 读回未使用的捕获 ID 0。

工作区为 `D:/Project/AXU5EV/.runtime/experiment/final/P61_TIMING_R02/vitis`，启动项为 `Motor_Control_GEM3_SELFTEST_P61_Timing_R02`。候选根目录下的文件路径如下。

| 文件 | 路径 |
| --- | --- |
| A53 FSBL | `vitis/ax04b_platform/export/ax04b_platform/sw/boot/fsbl.elf` |
| R5 ELF | `vitis/ax04b_realtime/build/ax04b_realtime.elf` |
| PL bit | `hardware/ax04b_selftest.bit` |
| 配套 LTX | `hardware/ax04b_selftest.ltx` |
| 配套 XSA | `hardware/ax04b_selftest.xsa` |
| PS–PL 初始化 | `vitis/ax04b_platform/hw/sdt/psu_init.tcl` |

已用既有 `.runtime/experiment/issue44/studio-prepare-r02/prepare_SELFTEST.tcl` 完成 bit 下载、PS–PL isolation removal 和 reset config，XSDB 出现 Legacy Debug Hub。第一次继续停于 `main()`（`0x126488`），再次继续返回 R5_0 `Running`。LTX 为候选配套文件。本次采集通过 GEM3 完成，ILA 为 `NOT_RUN`。[Vitis 摘录](vitis_launch_excerpt.txt) · [XSDB 回执](xsdb_receipt.txt) · [GEM3 初始时序状态](../../C1/initial_timing_status.json)
