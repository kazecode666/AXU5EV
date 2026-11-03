# AX-02C1：用户手动运行17帧的唯一指南

> 当前候选为 **hardware_02 / aux_fixed**。原hardware_01将低有效辅助复位接零，导致AXI通路持续复位、START后挂起；旧镜像保留但不再用于运行。修复后已在用户授权的在线调试中完成一次真实17帧运行：`frames=17 complete_frames=17 compared=51 mismatch=0`，详见[主报告](../../../coordination/reports/ax02c1_r5_axi_foc.md)及[实板证据](../../../verification/ax02c/board_aux_fixed_01/)。

仓库`kazecode666/AXU5EV`，接续已合并PR20。以下为用户后续手动加载入口；本轮在线诊断及一次运行已有明确授权，后续复位、下载或运行仍由用户决定。功率级保持断开，没有ADC、编码器或门极PWM连接；实际芯片完整料号/PCB待签核的历史事实保留。

## 1. 工程及产物

| 项目 | 本轮路径/名称 |
|---|---|
| Workspace | `D:/Project/AXU5EV/.runtime/ax02c/vitis_ps_pl` |
| Platform / Domain | `ax02c_platform` / `r5_standalone` |
| Application / Launch | `ax02c_foc` / **ax02c_foc_manual** |
| R5 ELF | `D:/Project/AXU5EV/.runtime/ax02c/vitis_ps_pl/ax02c_foc/build/ax02c_foc.elf` |
| A53_0 FSBL | `D:/Project/AXU5EV/.runtime/ax02c/vitis_ps_pl/ax02c_platform/export/ax02c_platform/sw/boot/fsbl.elf` |
| 匹配PS初始化脚本 | `D:/Project/AXU5EV/.runtime/ax02c/vitis_ps_pl/ax02c_platform/hw/sdt/psu_init.tcl` |
| Bitstream | `D:/Project/AXU5EV/.runtime/ax02c/hardware_02/ax02c_ps_pl.bit` |
| 匹配XSA | `D:/Project/AXU5EV/.runtime/ax02c/hardware_02/ax02c_ps_pl.xsa` |
| Vivado工程 | `D:/Project/AXU5EV/.runtime/ax02c/hardware_02/project/ax02a_ps.xpr`（沿用脚本项目名；当前运行为`synth_aux_fixed` / `impl_aux_fixed`） |
| 固件及模块身份 | `0x43314301` |

本次只修正PL辅助复位接线；Workspace、手动Launch、原A53 FSBL、R5 BSP及R5 ELF保持原样。入口沿用R5_0 standalone、RPU split、A53_0执行匹配FSBL的既有方式；I-cache ON、D-cache OFF。实际AXI地址由原BSP引用，PL区沿用R5 BSP的Strongly Ordered内存属性。C1不启动网络服务或TTC调度，也不链接完整Runtime。

本轮BD实际分配外设基地址`0x80000000`、范围4KiB。PS PL0配置标称50MHz，工具从既有33.333MHz参考频率元数据回读为`49,999,500Hz`（约−10ppm）；5000拍对应元数据约100.001µs。这不是板上频率测量，不调整FOC参数或BSP频率掩盖该差异。

Vitis2026.1 FSBL/BSP/R5应用沿用此前`AX02C_BUILD_PASS`产物；R5 ELF为ARM32、FSBL为AArch64，软件实际构建日志为`D:/Project/AXU5EV/.runtime/ax02c/vitis_02.console.txt`。新hardware_02已完成综合、布局布线及bit/XSA生成；使用下一节的`aux_fixed`配置检查本次组合。

## 2. 离线文件检查与打开工程

以下命令只读现有产物，不连接目标：

```powershell
Set-Location D:/Project/AXU5EV
$env:AX02C_CONFIG='D:/Project/AXU5EV/firmware/r5/ax02c/build_config.aux_fixed.json'
python scripts/ax02c_build.py --check-startup
```

应为`OFFLINE_STARTUP_CHECK_PASS`，显示上述Workspace、Launch、A53 FSBL、R5 ELF、实际外设地址与hardware_02 bitstream。该配置组合已完成现有启动检查；配置文件为`firmware/r5/ax02c/build_config.aux_fixed.json`，此检查只读文件，不连接开发板。

打开Vitis：

```powershell
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -w D:/Project/AXU5EV/.runtime/ax02c/vitis_ps_pl
```

本轮运行结束后，R5已成功暂停在末尾`WFI`（`PC=0x0010333C`），Codex新建的XSDB已断开退出，hw_server没有活动硬件客户端。Vitis原调试树可能仍显示旧适配器缓存，不能在旧树上直接Continue；后续确需重新运行时，仅启动上述manual profile建立一个新会话，它会复位并重新加载。当前结果已完成，等待Review，无需重复实验。

## 3. 用户加载顺序：先PS初始化，再PL，再R5运行

UART沿用本板已验证的115200/8N1，用户打开串口并先开始保存日志。本轮已采集的原始日志为`D:/Project/AXU5EV/.runtime/ax02c/board/uart_17_aux_fixed_01.txt`；后续如需运行，另选新编号并保留该文件。

1. 在`ax02c_foc`选择 **ax02c_foc_manual**，由用户启动Launch。它执行系统复位、RPU split、A53_0匹配FSBL初始化，并下载R5应用，设置`stopAtEntry=true`。**此时保持R5停在应用入口，暂不Continue。**
2. 本Launch的`programDevice=false`。PS初始化完成后，由用户使用Vitis的Program Device（或已使用的Vivado Hardware Manager），显式选择`D:/Project/AXU5EV/.runtime/ax02c/hardware_02/ax02c_ps_pl.bit`。**不要使用GUI自动生成的`ax02c_foc_app_hw_1`；它及应用`_ide/bitstream`中的默认镜像仍指向旧hardware_01，不能作为本次修复候选。** 此步不要再次复位系统或重新运行另一个Launch；等待编程完成。

   若GUI仍报已知的`Connection not found with name`，在同一Vitis调试会话的XSDB Console加载明确的新文件（不要另开第二个硬件客户端）：

   ```tcl
   targets -set -filter {name =~ "PL"}
   fpga -file D:/Project/AXU5EV/.runtime/ax02c/hardware_02/ax02c_ps_pl.bit
   ```

   本轮实际在线验证使用了上述`fpga -file`入口，返回0、下载100%。GUI连接名解析错误与PL复位接线错误分别处理。
3. **加载bitstream之后还须解除PS—PL隔离并释放PL复位。** 在用户的Vitis XSDB Console沿用本次调试连接，选择A53_0内存访问目标，执行本轮匹配脚本的两个原生过程：

   ```tcl
   targets -set -filter {name =~ "Cortex-A53 #0"}
   source D:/Project/AXU5EV/.runtime/ax02c/vitis_ps_pl/ax02c_platform/hw/sdt/psu_init.tcl
   psu_ps_pl_isolation_removal
   psu_ps_pl_reset_config
   ```

   后续手动运行时由用户执行这些命令；本轮授权在线运行已实际使用同样的两个过程。此处不再调用完整`psu_init`，不重置DDR或重新下载应用。FSBL在JTAG handoff时只有看到PL_DONE才运行上述隔离/复位步骤；本指南先FSBL、后PL加载，因此必须补此步骤，不能把Program Device完成当作PS—PL已可访问。若出现Timeout/Error，保存输出并停止。
4. 返回调试视图选择 **R5_0**，再人工Continue R5。应看见`AX02C1 WAIT build=43314301 ... I-cache=ON D-cache=OFF; send s once`。不要误Continue A53_0。

程序在WAIT前后均不会自动访问PL；第一次MMIO在下一节的显式`s`之后。不能跳过新bitstream加载，也不能在后续系统复位后沿用“PL已就绪”的假设。如果初始化、编程或WAIT未正常完成，先保存日志并停止，不继续实验。

## 4. 第一条实验操作

确认上述顺序完成后，在UART终端发送一个小写ASCII字符：

```text
s
```

这是本轮唯一开始操作，不是MATLAB命令或XSDB内存写入。程序先核对模块身份、整体初始化一次，写入第1帧全部整数位串后提交并开始；其后每次结果读回立即提前提交下一帧。PL连续运行17个完整5000拍控制帧，post314/edge315合同不改，R5读取PL实际结果并暂存RAM。第17帧结果出现后仍等该帧完整结束，再输出全部UART结果；连续运行中不逐帧printf。

## 5. 应见输出及保存

本轮已授权在线运行中，R5在首条PL读指令`PC=0x001031BC`暂停，地址寄存器`r6=0x80000000`；执行该指令后停在`PC=0x001031C0`，读回`r2=0x43314301`，随后继续同一轮实验。此次断点只用于诊断首读；后续正常运行不需要重复设置。

正常输出先为`AX02C1 START frames=17 ...`，然后共17条`AX02C1 ROW`，每条包含：

- `n=0..16`，`frame=1..17`，`seq`及`adopted`与同帧序号一致；
- 三相`actual`、CSV对应的`expected`和逐位异或`xor`，全部`xor=00000000`；actual仅来自AXI读回；
- `submit`、`wait`、`read`为本次实际BSP PMU计数，末行`tick_hz`用于换算，`时间µs=计数×1000000/tick_hz`。这些时间是本次交换/轮询参考，不是WCET或50µs端到端控制验收。

本轮实际最终输出为：

```text
AX02C1 PASS code=0 fail_frame=0 frames=17 complete_frames=17 compared=51 mismatch=0 elapsed_ticks=13290 tick_hz=7812421
```

保存从WAIT到最后摘要的完整串口日志，并保留加载的Workspace/Launch、功率级断开和本次操作条件。程序随后停在结束等待，不自动再跑；不要为凑结果自动重复实验。若出现`FAIL`，保留实际前缀和摘要交Review，不能把部分帧当整轮通过。`code`：1轮询/停止超时、2帧或采用序号不符、3读取快照跨帧、4输入保持异常、5捕获相位不符、6模块身份不符、7待提交缓冲仍占用、8完整结束帧数不符、9三相位串不符。

## 6. 构建来源与边界

已有17帧来源为`verification/m3_foc/directed_probe_source_hex.csv`；`scripts/ax02c_build.py`仅按十六进制整数拆分theta/omega的40位字段，低字bits31:0、高字有效bits39:32，不经double重新量化。输入常量与golden分别用于AXI写入与结束后比较，golden不写入PL结果。

本次沿用已有软件，不需要重建或覆盖Workspace。修复候选的硬件构建来源为`hardware/axu5ev/ax02c_ps_pl.tcl`，新产物独立保存在`hardware_02`；旧`hardware_01`及其工程保持原样。

旧R1、ETH01 r3、ETH02及全部实验数据保持原样。C1结果只验证记录向量经R5—AXI驱动真实PL FOC的最小通路；没有真实传感器、电机闭环或50µs端到端时限结论。板测及合并由用户决定，不自动合并，不关闭Issue15。
