# SDF运行器修复：12项短模拟测试PASS

依据Issue40评论6757750944，接续3cfad00；本提交先修运行器，服务器包尚未制作。本机没有启动Vivado或真实SDF。

原PowerShell入口改为调用同一 `scripts/sdf_runner.py`。Windows使用本轮专属Job：bootstrap等待GO，先加入Job，再启动CMD→BAT→原生子进程，避免先启动子孙再登记的窗口；禁用breakaway、Job关闭时终止成员。stdout/stderr逐块持续落盘，保留合并console、原生日志、命令、PID/创建时间和阶段记录；finally先清理/等待本轮树，再排空管道并保存退出分类。未按进程名终止其他任务。

运行 `python verification/motor_control/test_sdf_runner.py --output .runtime/motor_control/runner_fix_02`，Windows 11、PowerShell7.6.9、Python3.14.6，12项通过：

- 直接短模拟工具的正常0、失败7、900ms超时、显式取消文件：每项观察到5个所属进程，运行中stdout/stderr已可读；末尾已产生输出保留、自然退出与监督终止分开、子孙剩余0，同名无关Python未受影响。
- 经过实际motor_control PowerShell包装的正常、xelab失败、超时、显式取消四项：状态传播正确，失败后xsim未启动，不生成PASS结果。
- 缺成功注释确认、时序违例、缺PASS标记、SDF警告四种结果全部拒绝。原XSIM 43-3452、唯一PWM_SDF_PASS和时序/注释检查保留。

机器结果见[results.json](results.json)，四项直接测试的PID/时间/日志证据见[process_records.json](process_records.json)。第一次10项测试及本次完整原始目录均保留。取消文件是本轮实际验证的显式取消方式；信号处理和Linux进程组分支不冒称已在服务器验收。

运行器参数新增 `-Python`、`-CancelFile`；原Hardware/RunDir/Corner/ToolTimeoutMs保留。对运行中的任务，在另一个终端创建传给CancelFile的文件即可取消；Ctrl+C按Python收到的信号处理。若强制终止监督器，Windows Job句柄关闭负责清理子孙，但来不及完成的JSON只代表未完成，不能认PASS。

此修复没有查明旧xelab耗时根因，没有加入或运行-O0，没有修改事件测试台、DUT、算法、约束、hardware_02/vitis_01。真实slow注释NOT_COMPLETED、动态NOT_RUN，fast NOT_RUN；不能用模拟工具的假注释/PASS文本替代真实SDF验收。本轮明确不关机。
