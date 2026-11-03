# ETH-02 两场景用户实板结果

2026-11-03，kazecode666/AXU5EV PR18，依据[评论6596653379](https://github.com/kazecode666/AXU5EV/pull/18#issuecomment-6596653379)。两次同一ETH02应用build45303201，实验号0→1→2，功能、数值和100µs时序均用户实板PASS，待最终Review。

| 场景 | 实验/完整帧数 | 数值失败/时序异常 | 最大/P99响应µs | 最小slackµs | 上传/下载s |
|---|---|---|---|---|---|
| current_motion | 1 / 64536 | 0 / 0 | 62.33 / 59.92 | 37.67 | 28.74 / 22.13 |
| current_alignment_reset | 2 / 43100 | 0 / 0 | 39.17 / 36.52 | 60.83 | 18.87 / 13.71 |

两组transfer PASS、analysis passed=true/timing=PASS、crosscheck passed=true/consistent=true，板报numeric_errors=0；ISR相位均NO_TREND_DETECTED，TTC均100MHz/raw9999/logical10000，pre_begin一致。时间以本次配置换算，非WCET结论。

本轮只读核对现有JSON、timing CSV和二进制文件长度，复制各场景run/transfer/pre_begin/analysis summary/crosscheck共五份JSON；详细统计见上级status.json。全部二进制内容、计时记录独立复算和输出有限值检查的结论来自上述评论中的先前核查，本轮未重复执行。

原始output.bin、timing.bin、report_v2.bin、完整分析及压缩包均留在D:/Project/AXU5EV/.runtime/ethernet/eth02/board对应01目录，不上传大文件、不覆盖数据。这两个01目录已完成并占用，无需重跑。本轮无测试、新构建、板卡操作或哈希清单；候选Workspace/Launch不变。PR18保持Draft待最终Review，不自动合并，Issue15保留；持续遥测及PL集成属于后续阶段。
