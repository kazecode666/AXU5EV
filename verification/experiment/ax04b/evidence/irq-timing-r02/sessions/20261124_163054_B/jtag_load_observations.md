# T3-B R02 加载与启动

日期 2026-11-24（Asia/Shanghai）。用户现场确认板卡已上电并且 J15/J16、驱动器、电机、外部功率电源全断开。

- Vitis 当前工作区为 `D:/Project/AXU5EV/.runtime/experiment/final/P61_TIMING_R02/vitis`，启动项为 `Motor_Control_GEM3_SELFTEST_P61_Timing_R02 [ax04b_realtime]`。本地启动配置 `programDevice=false`。A53_0 停在 `XFsbl_Exit`。
- 已在 Vitis XSDB Console 观察到 `Successfully downloaded D:/Project/AXU5EV/.runtime/experiment/final/P61_TIMING_R02/vitis/ax04b_realtime/build/ax04b_realtime.elf`。R5_0（目标 6）暂停，`rrd pc` 返回 `0000003c`。初次 GEM3 连接超时发生在 R5_0 暂停期间。
- 同一 XSDB Console 执行 `source "D:/Project/AXU5EV/.runtime/experiment/issue44/studio-prepare-r02/prepare_SELFTEST.tcl"`。脚本向唯一 PL 目标手动下载 `D:/Project/AXU5EV/.runtime/experiment/final/P61_TIMING_R02/hardware/ax04b_selftest.bit`（配套同名 LTX/XSA），然后从同候选的 `vitis/ax04b_platform/hw/sdt/psu_init.tcl` 执行 PS–PL isolation removal 和 reset config。控制台显示 `100% 7MB 1.2MB/s 00:06` 及 `PL/PS-PL operations finished. Verify the target before continuing R5_0.`
- R5_0 第一次继续停在 `main()` 的 `0x126488` 硬件断点。再次选择 R5_0 并继续，控制台返回 `Info: Cortex-R5 #0 (target 6) Running`。GEM3 version 回读见本目录原始 JSON。CTRL_EN 读回 0。初始化所选 A53 FSBL 为 R02 候选的 `vitis/ax04b_platform/export/ax04b_platform/sw/boot/fsbl.elf`。以上为控制台和 UI 现场摘录。
