# Issue40 / PR41 完整功能PL网表SDF运行包

本包直接使用hardware_02已采用的完整功能PL网表、slow/fast SDF和PR41当前事件测试台；不重建、不裁剪、不定义MC_TIMING_RTL。服务器可运行仿真已确认，本交付只准备输入与入口，不登录、安装、上传或运行服务器。

生产来源及文件SHA256见 `provenance.json`、`SHA256SUMS`。原候选hardware_02、DUT禁止修复bc52d74、导出入口d63e96f，事件测试台最后修改0191fc7；修复运行器来源0bd081a。具体完整SHA在provenance中。网表及两角SDF原字节保留。

本地生成环境为Vivado/XSim2026.1，SW Build6511674、IP Build6504888、SharedData Build6501428；日志未标识另装补丁。服务器提供匹配Vivado/XSim、simprims_ver/unisims_ver/secureip和glbl.v；包不含工具安装、许可证/凭据、MATLAB/Vitis、编译缓存或bit/ELF/XSA/DCP。Python入口只用标准库，使用Python3.10或以上；本地实际短测为Windows11/Python3.14.6/PowerShell7.6.9。Linux分支和服务器实际执行尚NOT_RUN，不把本地自检写成服务器通过。

## 解压与输入检查

把zip整体解压，保留目录关系。包内主要文件：

- `inputs/hardware_02/timing_pl/motor_routed.v`、`motor_slow.sdf`、`motor_fast.sdf`
- `verification/motor_control/timing_tb.sv`
- `scripts/sdf_runner.py`：本次修复后的同一运行入口
- `scripts/motor_control_sdf_inputs.py`：SHA256、文件清单及可见文件依赖检查
- `provenance.json`、`dependency_audit.json`、`SHA256SUMS`和本说明

在解压根目录运行：

```sh
python3 scripts/motor_control_sdf_inputs.py
```

Windows把python3换成python。返回PASS_BUNDLE_INPUTS_NOT_SDF只表示输入完整性。可见源中没有include/readmem等额外项目输入文件；测试台的foc_frames.txt、motor_frames.txt是写入运行结果目录的输出。原保护的厂商模型块保留，由匹配的厂商仿真库解释；不修改网表去掉保护块。

## 配置与执行

以下在解压根目录执行。Linux示例的 `/opt/AMD/Vivado/2026.1/bin` 只是需要替换的工具安装路径。Windows PowerShell先设置 `$VIVADO_BIN='实际Vivado安装路径/bin'`，命令中的 `$VIVADO_BIN` 同样有效。Python脚本按本机平台选择工具入口，Linux不依赖CMD/BAT，所有项目输入均在本包内。

```sh
VIVADO_BIN=/opt/AMD/Vivado/2026.1/bin
# 只检查文件和生成命令，不启动任何工具；结果目录必须全新
python3 scripts/sdf_runner.py --hardware inputs/hardware_02 --vivado-bin "$VIVADO_BIN" --corner slow --run-dir ../sdf_results/dry_slow_01 --dry-run

# 实际slow/max：单工具上限6小时，stdout/stderr持续落盘
python3 scripts/sdf_runner.py --hardware inputs/hardware_02 --vivado-bin "$VIVADO_BIN" --corner slow --run-dir ../sdf_results/slow_01 --tool-timeout-ms 21600000 --cancel-file ../sdf_results/CANCEL_slow_01
```

先核对slow_01/summary.json中status严格为PASS，再手动运行fast；slow失败/超时/取消不得开始fast。入口每次只运行指定的一角，不自动串行或重试。

```sh
python3 scripts/sdf_runner.py --hardware inputs/hardware_02 --vivado-bin "$VIVADO_BIN" --corner fast --run-dir ../sdf_results/fast_01 --tool-timeout-ms 21600000 --cancel-file ../sdf_results/CANCEL_fast_01
```

也可在任意目录使用脚本及`--hardware`的绝对路径；默认测试台按脚本所在包定位，不需要原仓库。输出目录必须全新，不能对旧目录重跑或覆盖日志。未设置、未验证-O0，不把运行器修复当作耗时根因已解决。

## 停止、判定与回收

运行中在另一终端创建本次 `--cancel-file` 指定的文件即可显式取消；Ctrl+C交由Python信号处理。Windows专属Job或Linux新进程组只清理本轮子孙，不按工具名称批杀。强制结束监督器可能来不及完成JSON，缺最终结果或仍为RUNNING均不是PASS。显式取消文件方式已在本地短测。

每阶段保留 `*.stdout.log`、`*.stderr.log`、合并的 `*.console.log`、`*.process.json`及厂商原生日志；`commands.json`记录实际参数。process记录包含PID/创建时间、自然退出码或监督终止原因、剩余进程。Windows额外有bootstrap启动记录。`summary.json`是本角最终结果：超时TIMED_OUT、取消CANCELLED、工具/日志错误均非PASS；自然退出0只代表工具退出，还须通过注释和动态检查。

PASS仍要求唯一PWM_SDF_PASS、XSIM 43-3452成功注释确认、无SDF注释警告/错误或时序违例。最新测试台保留同帧捕获、三相整组、目标谷值、晚到取消、disarm、失锁显式重臂、互补死区和80字快照的事件判据；不使用旧固定六帧，也不恢复第二次六帧FOC oracle。

失败/超时保留整个结果目录，停止并报告，不关闭检查、不放宽判据、不自动重试或改DUT/约束。回收时带回两个角的完整结果目录（包括commands、summary、process、所有console/原生日志、foc_frames.txt及motor_frames.txt）；同时记录本包SHA256与服务器工具版本。未运行的角保持NOT_RUN，局部通过只按实际边界记结论。

仿真边界：仅PWM ILA黑盒，结构dbg_hub、功能FOC/mapper/ADC/PWM、跨频与禁止路径保留；PS时钟/复位和AXI刺激替代，LOCKED/ready故障及一次slave P0事务按测试台注入。不覆盖ARM执行、JTAG/ILA采集、所有PVT或真实板卡/驱动板/电机。本机只做短模拟工具及解包自检，slow注释NOT_COMPLETED、动态NOT_RUN，fast NOT_RUN。PR41保持Draft待Review，不自动合并、关闭Issue或关机。
