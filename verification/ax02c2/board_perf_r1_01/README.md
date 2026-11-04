# AX-02C2 perf_r1 实板签收证据

2026-11-04，按[PR24评论6622743887](https://github.com/kazecode666/AXU5EV/pull/24#issuecomment-6622743887)归档用户已完成的单次`current_motion`实验。受测软件提交`480a6cbe4a762e7a01504275706a4cdef6e64e07`，身份`0x43324302`。本次归档只读本机保存数据，没有新的板卡操作、构建或回归。

64536条完整完成，2645976个Runtime值按原判据零失败；193608个duty位串、记录/命令/采用序号、315捕获及完整停止全部通过。Runtime相对参考最大差为`1.7763568394002505e-15`（x_ref_mm，k3644），在原容差内；这里没有把浮点容差通过写成逐位相同。`analysis/summary.json`的`timing=NOT_RUN`仅指旧TTC判据不适用。本次验收以真实PL记录和PMU计时为依据。

| 文件 | 来源或作用 |
|---|---|
| `run.json` | 原始板报身份、完整帧数、停止及PMU频率 |
| `pl_summary.json` | 实验入口已有的PL逐位与帧关系检查/时间摘要 |
| `analysis/summary.json` | 原Runtime数值比较器已有BOARD结果 |
| `transfer.json` | 完整上传/下载、1000Mbps及对象长度 |
| `UART.txt` | 用户保存的原串口文本，身份、TCP_READY及RESULT_READY |
| `timing_statistics.json` | 本次只读复算结果、完整时间窗口、普通/1ms/10ms分组和旧失败点对照 |
| `summarize_saved_run.py` | 仅解析上述已保存数据，复用原Runtime比较器；不导入板卡连接/构建入口 |

原始数据根目录为`D:/Project/AXU5EV/.runtime/ax02c2/board/current_motion_perf_r1_01`。大文件不提交：`output.bin`21167808B、`timing.bin`4130304B、`pl_result.bin`2065152B、`report_v2.bin`2400B；原串口完整路径为`D:/Project/AXU5EV/.runtime/ax02c2/board/current_motion_perf_r1_01/UART.txt`。`metadata.json`、`pre_begin.json`及`analysis/signals.csv`等原件也在该目录保留。未对`report_v2.bin`另做板报交叉签核，保留其原始未验证标识。

复算命令（仅本机离线文件）：

```powershell
Set-Location D:/Project/AXU5EV
python verification/ax02c2/board_perf_r1_01/summarize_saved_run.py
```

原失败目录`D:/Project/AXU5EV/.runtime/ax02c2/board/current_motion_01`及`current_motion_01_fail1200_backup`完整保留；[原故障复算](../perf_fix_01/failure_analysis.json)不覆盖。新k1200的PL/命令/采用序号均为1201，旧同记录PL=1201但命令/采用=1200。新候选完整场景未再出现该故障。

PMU为CPU/64、7812421Hz，P99为最近秩`ceil(0.99*n)`。首记录在START前准备，不计入64535个跨记录窗口。**COMMIT后的328B日志已计入**：`commit_end[k] → wait_begin[k]`含日志及返回/循环开销，均值/最大9.245/10.880µs；不能把该段当作单独memcpy耗时。上一结果`read_begin[k-1] → commit_end[k]`最大86.017µs；再包含日志至`wait_begin[k]`最大95.617µs，204条超过名义93.68µs。后者包含已提交后的工作，不是命令提交超时；本次采用序号及完整回放全部通过。两列各自最大值发生在不同记录，不能相减求某次日志耗时。

这些是已知反馈记录的本次分布，不是WCET、真实ADC/QEP/门极PWM闭环或同帧50µs端到端签核。窗口余量只与名义时钟比较，不含未测得的发布到软件观察延迟，不等同精确AXI接受余量。完整统计与旧失败对照见[主报告当前节](../../../coordination/reports/ax02c2_runtime_pl_replay.md)。PR24待用户最终Review，不自动合并。
