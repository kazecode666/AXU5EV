# AX-02C1：用户手动运行17帧的唯一指南

仓库`kazecode666/AXU5EV`，接续已合并PR20。本轮只完成离线实现与构建；本次PS＋PL联通板测为 **NOT_RUN**，Review通过后由用户执行一次。功率级保持断开，没有ADC、编码器或门极PWM连接；实际芯片完整料号/PCB待签核的历史事实保留。

## 1. 工程及产物

| 项目 | 本轮路径/名称 |
|---|---|
| Workspace | `D:/Project/AXU5EV/.runtime/ax02c/vitis_ps_pl` |
| Platform / Domain | `ax02c_platform` / `r5_standalone` |
| Application / Launch | `ax02c_foc` / **ax02c_foc_manual** |
| R5 ELF | `D:/Project/AXU5EV/.runtime/ax02c/vitis_ps_pl/ax02c_foc/build/ax02c_foc.elf` |
| A53_0 FSBL | `D:/Project/AXU5EV/.runtime/ax02c/vitis_ps_pl/ax02c_platform/export/ax02c_platform/sw/boot/fsbl.elf` |
| 匹配PS初始化脚本 | `D:/Project/AXU5EV/.runtime/ax02c/vitis_ps_pl/ax02c_platform/hw/sdt/psu_init.tcl` |
| Bitstream | `D:/Project/AXU5EV/.runtime/ax02c/hardware_01/ax02c_ps_pl.bit` |
| 匹配XSA | `D:/Project/AXU5EV/.runtime/ax02c/hardware_01/ax02c_ps_pl.xsa` |
| Vivado工程 | `D:/Project/AXU5EV/.runtime/ax02c/hardware_01/project/ax02a_ps.xpr`（沿用脚本项目名，目录为本轮独立目录） |
| 固件及模块身份 | `0x43314301` |

入口沿用R5_0 standalone、RPU split、A53_0执行匹配FSBL的既有方式；I-cache ON、D-cache OFF。实际AXI地址由匹配XSA生成的BSP引用，PL区沿用R5 BSP的Strongly Ordered内存属性。C1不启动网络服务或TTC调度，也不链接完整Runtime。

本轮BD实际分配外设基地址`0x80000000`、范围4KiB。PS PL0配置标称50MHz，工具从既有33.333MHz参考频率元数据回读为`49,999,500Hz`（约−10ppm）；5000拍对应元数据约100.001µs。这不是板上频率测量，不调整FOC参数或BSP频率掩盖该差异。

匹配的Vitis2026.1 FSBL/BSP/R5应用已实际构建，`AX02C_BUILD_PASS`及现有纯文件启动检查`OFFLINE_STARTUP_CHECK_PASS`。启动证据为Workspace内`startup_validation.json`；R5 ELF为ARM32、FSBL为AArch64。实际构建日志为`D:/Project/AXU5EV/.runtime/ax02c/vitis_02.console.txt`，板测仍为NOT_RUN。

## 2. 离线文件检查与打开工程

以下命令只读现有产物，不连接目标：

```powershell
Set-Location D:/Project/AXU5EV
python scripts/ax02c_build.py --check-startup
```

应为`OFFLINE_STARTUP_CHECK_PASS`，显示上述Workspace、Launch、A53 FSBL、R5 ELF、实际外设地址与bitstream。此检查不是BOARD_PASS。

打开Vitis：

```powershell
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -w D:/Project/AXU5EV/.runtime/ax02c/vitis_ps_pl
```

## 3. 用户加载顺序：先PS初始化，再PL，再R5运行

UART沿用本板已验证的115200/8N1，用户打开串口并先开始保存日志。建议本轮新日志文件为`D:/Project/AXU5EV/.runtime/ax02c/board/uart_17_01.txt`；该文件为本次待生成结果，不代表已采集板测。若已经存在，换新编号，保留旧文件。

1. 在`ax02c_foc`选择 **ax02c_foc_manual**，由用户启动Launch。它执行系统复位、RPU split、A53_0匹配FSBL初始化，并下载R5应用，设置`stopAtEntry=true`。**此时保持R5停在应用入口，暂不Continue。**
2. 本Launch的`programDevice=false`；它不会把PL镜像就绪视为已完成。PS初始化完成后，由用户使用Vitis的Program Device（或已使用的Vivado Hardware Manager）加载表中**本轮ax02c_ps_pl.bit**。此步不要再次复位系统或重新运行另一个Launch；等待编程完成。
3. **加载bitstream之后还须解除PS—PL隔离并释放PL复位。** 在用户的Vitis XSDB Console沿用本次调试连接，选择A53_0内存访问目标，执行本轮匹配脚本的两个原生过程：

   ```tcl
   targets -set -filter {name =~ "Cortex-A53 #0"}
   source D:/Project/AXU5EV/.runtime/ax02c/vitis_ps_pl/ax02c_platform/hw/sdt/psu_init.tcl
   psu_ps_pl_isolation_removal
   psu_ps_pl_reset_config
   ```

   这些命令由用户执行，Codex未连接或操作板卡。此处不再调用完整`psu_init`，不重置DDR或重新下载应用。FSBL在JTAG handoff时只有看到PL_DONE才运行上述隔离/复位步骤；本指南先FSBL、后PL加载，因此必须补此步骤，不能把Program Device完成当作PS—PL已可访问。若出现Timeout/Error，保存输出并停止。
4. 返回调试视图选择 **R5_0**，再人工Continue R5。应看见`AX02C1 WAIT build=43314301 ... I-cache=ON D-cache=OFF; send s once`。不要误Continue A53_0。

程序在WAIT前后均不会自动访问PL；第一次MMIO在下一节的显式`s`之后。不能跳过新bitstream加载，也不能在后续系统复位后沿用“PL已就绪”的假设。如果初始化、编程或WAIT未正常完成，先保存日志并停止，不继续实验。

## 4. 第一条实验操作

确认上述顺序完成后，在UART终端发送一个小写ASCII字符：

```text
s
```

这是本轮唯一开始操作，不是MATLAB命令或XSDB内存写入。程序先核对模块身份、整体初始化一次，写入第1帧全部整数位串后提交并开始；其后每次结果读回立即提前提交下一帧。PL连续运行17个完整5000拍控制帧，post314/edge315合同不改，R5读取PL实际结果并暂存RAM。第17帧结果出现后仍等该帧完整结束，再输出全部UART结果；连续运行中不逐帧printf。

## 5. 应见输出及保存

正常输出先为`AX02C1 START frames=17 ...`，然后共17条`AX02C1 ROW`，每条包含：

- `n=0..16`，`frame=1..17`，`seq`及`adopted`与同帧序号一致；
- 三相`actual`、CSV对应的`expected`和逐位异或`xor`，全部`xor=00000000`；actual仅来自AXI读回；
- `submit`、`wait`、`read`为本次实际BSP PMU计数，末行`tick_hz`用于换算，`时间µs=计数×1000000/tick_hz`。这些时间是本次交换/轮询参考，不是WCET或50µs端到端控制验收。

最终应为：

```text
AX02C1 PASS code=0 fail_frame=0 frames=17 complete_frames=17 compared=51 mismatch=0 ...
```

保存从WAIT到最后摘要的完整串口日志，并保留加载的Workspace/Launch、功率级断开和本次操作条件。程序随后停在结束等待，不自动再跑；不要为凑结果自动重复实验。若出现`FAIL`，保留实际前缀和摘要交Review，不能把部分帧当整轮通过。`code`：1轮询/停止超时、2帧或采用序号不符、3读取快照跨帧、4输入保持异常、5捕获相位不符、6模块身份不符、7待提交缓冲仍占用、8完整结束帧数不符、9三相位串不符。

## 6. 构建来源与边界

已有17帧来源为`verification/m3_foc/directed_probe_source_hex.csv`；`scripts/ax02c_build.py`仅按十六进制整数拆分theta/omega的40位字段，低字bits31:0、高字有效bits39:32，不经double重新量化。输入常量与golden分别用于AXI写入与结束后比较，golden不写入PL结果。

离线构建入口（只用于新的/本次未完成Workspace，不覆盖已确认候选）：

```powershell
$env:XILINX_VITIS_DATA_DIR='D:/Project/AXU5EV/.runtime/ax02c/vitis_data'
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -s D:/Project/AXU5EV/scripts/ax02c_build.py
```

旧R1、ETH01 r3、ETH02及全部实验数据保持原样。C1结果只验证记录向量经R5—AXI驱动真实PL FOC的最小通路；没有真实传感器、电机闭环或50µs端到端时限结论。板测及合并由用户决定，不自动合并，不关闭Issue15。
