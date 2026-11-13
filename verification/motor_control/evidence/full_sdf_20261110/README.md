# 完整功能PL网表 slow/max：延长上限后仍未完成

本次按Issue40评论6745328232、PR41评论6745337679及用户运行中追加的更长等待授权执行。源提交0191fc773102bc4aa5d71c89e652137cce10c350，复用hardware_02已有完整功能PL网表/slow SDF和当前事件测试台网表分支，未定义MC_TIMING_RTL。仅PWM ILA为黑盒，结构dbg_hub与功能链保留；PS时钟/复位和AXI刺激由测试台替代。

| 阶段 | 实际结果 |
| --- | --- |
| xvlog / static elaboration | PASS / COMPLETED；不代表整个xelab完成 |
| 原wrapper | 00:32:36启动，03:32:48到原3h上限后报xelab timed out退出 |
| 同一次原生xelab | PID8028，00:32:48.542启动；未重启，继续监督至06:32:48.542的6h上限，届时仍在运行 |
| 安全停止 | 核实路径、完整命令及精确启动时间后，于06:34:15.828终止本轮原生进程树；剩余0。终止码-1来自监督停止，非自然工具退出码 |
| 快照 / 注释 | 无xsimk.exe；无XSIM 43-3452成功确认；NOT_COMPLETED |
| slow/max动态检查 | NOT_RUN |
| fast/min | NOT_RUN；slow未通过，未建目录/启动 |

可用xelab日志没有显式ERROR/FATAL，持续CPU活动也不能证明内部进度、注释成功或DUT无误。这是展开阶段超时，尚无动态断言失败或通过结论；不以STA、既有RTL3035检查或导出成功替代。

同帧捕获、三相整组、目标谷值、晚到取消、disarm、失锁显式重臂、互补死区、80字快照在本次网表动态中全部NOT_RUN，两角SDF验收继续开放。第二次固定六帧FOC oracle保留NOT_RUN历史，仍为NOT_REQUIRED_DUPLICATE。

精简机器记录见[result.json](result.json)，原生日志见[xelab.log](xelab.log)。全部原始调用、进程、wrapper超时、继续监督及停止记录和编译中间文件保留于 `.runtime/motor_control/sdf_full_slow_01`，相邻invocation.json也保留。原wrapper退出后stdout/stderr管道完整性无法保证，独立进程句柄不保护管道；未取得真实自然退出0或完整注释证据。

未重试、未启动下一角、未再裁剪或重建hardware_02/vitis_01，生产DCP/bit/XSA、DUT/算法/约束和用户文件未改。PR41保持Draft，Issue40不关闭；后续路线交Review决定，不自动续跑或操作板卡。
