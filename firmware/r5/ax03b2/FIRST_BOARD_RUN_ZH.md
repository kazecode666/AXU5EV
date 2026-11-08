# AX-03B2：J15双路ADC首次板测

本轮先离线交付，**板测NOT_RUN**。Review后由用户按本说明操作；只接AXU5EVB-E和AN9238，不接驱动板、电机、真实ABZ或功率级。UART只观察ADC原码和名义SMA电压，不作电流校准，也不把数字变化当成模拟精度验收。

## 本轮文件

所有路径均位于`D:/Project/AXU5EV/`。

| 项目 | 路径/名称 |
|---|---|
| Workspace | `.runtime/ax03b2/vitis_adc_01` |
| Platform / Application / Launch | `ax03b2_platform` / `ax03b2_adc` / **ax03b2_adc_manual** |
| bit / ltx / XSA | `.runtime/ax03b2/hardware_01/ax03b2_adc.bit`、同目录`ax03b2_adc.ltx`、`ax03b2_adc.xsa` |
| R5 ELF | `.runtime/ax03b2/vitis_adc_01/ax03b2_adc/build/ax03b2_adc.elf` |
| A53_0 FSBL | `.runtime/ax03b2/vitis_adc_01/ax03b2_platform/export/ax03b2_platform/sw/boot/fsbl.elf` |
| 匹配初始化脚本 | `.runtime/ax03b2/vitis_adc_01/ax03b2_platform/hw/sdt/psu_init.tcl` |
| 接线依据 | [J15逐针表](../../../hardware/axu5ev/AX03B2_J15_MAP.csv) |
| R5身份 / 实际MMIO | `build=42324101`；BSP `XPAR_ADC_OBSERVER_0_BASEADDR=0x80000000`，范围至`0x80000fff` |

运行前可只读核对现有产物，不连接板卡：

```powershell
Set-Location D:/Project/AXU5EV
python scripts/ax03b2_build.py --check-startup
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -w D:/Project/AXU5EV/.runtime/ax03b2/vitis_adc_01
```

检查应输出`OFFLINE_STARTUP_CHECK_PASS`及上述路径。不要使用旧PR24工程或其bit/ELF，也不需要重建旧工程。

本轮Vitis2026.1实际构建已通过：R5 ELF为ARM32、212384字节，匹配FSBL为AArch64、340576字节；应用编译0 error/0 warning，独立被动启动文件检查PASS。完整构建日志为`.runtime/ax03b2/vitis_01.console.txt`。这些离线结果不代表已经启动或读取开发板。

## 接线与启动

1. 断电核对J15与AN9238的针1方向、电源/GND位置、39–40脚及模块板上设置，再按逐针表对插。实物方向和SMA J5/J6的通道归属尚未由本轮离线工作确认；不能仅凭排线颜色或SMA编号猜测。J16不接驱动信号。输入源按手册限制在±5V内，源地与模块模拟地正确连接；开路不是0V。
2. 上电后打开已验证的UART终端，115200/8N1，先开始保存一个**新文件**，例如`.runtime/ax03b2/board/uart_dc_01.txt`。不要覆盖旧实验文件。
3. 在Vitis应用`ax03b2_adc`中启动 **ax03b2_adc_manual**。它用A53_0执行本轮FSBL、设置RPU split并下载R5_0，`stopAtEntry=true`；保持R5停在入口，暂不Continue。
4. 该Launch的`programDevice=false`。由用户在同一调试会话的Program Device或Vivado Hardware Manager中，显式选择本轮`ax03b2_adc.bit`；Hardware Manager的probes文件选同目录`ax03b2_adc.ltx`。不要再次系统复位或另开第二个调试会话。
5. 加载bit后，在本Vitis会话的XSDB Console执行匹配初始化脚本的两个既有过程，解除PS—PL隔离并释放PL复位：

   ```tcl
   targets -set -filter {name =~ "Cortex-A53 #0"}
   source D:/Project/AXU5EV/.runtime/ax03b2/vitis_adc_01/ax03b2_platform/hw/sdt/psu_init.tcl
   psu_ps_pl_isolation_removal
   psu_ps_pl_reset_config
   ```

   不再调用完整`psu_init`。此顺序沿用已验证的“先FSBL、后加载PL”路径；单有Program Device完成不代表PS—PL复位已释放。
6. 选择R5_0 Continue，应出现`AX03B2 WAIT build=42324101 base=...`。此时程序尚未访问PL寄存器。示波器先核对J15两路ADC CLK均为约5MHz、同相、50%占空比；ILA可观察原始码、OTR、捕获/选样与发布事件。ILA数据不是板级时序或模拟精度证明。

本轮PS时钟元数据为49,999,500Hz，因此ADC为4,999,950Hz、发布约9999.9Hz；文中的50MHz/5MHz/10kHz为名义值，以上均非示波器实测。ILA `probe0`：rawA为bits[11:0]、rawB[23:12]、OTR{B,A}[25:24]、capture[26]、selected[27]、publish[28]、sample_id[60:29]。capture沿更新原码寄存器，ILA在同一沿看到旧寄存值，下一逻辑拍才看到新码，不把该一拍显示关系误判成ADC位序错误。

## 三步读数

每个输入条件稳定后，UART发送一次小写`s`。程序约每1ms读取一次最新冻结快照，保留64条，然后输出64行和SUMMARY，等待下一次`s`；不会自动重复。PL名义5MHz连续转换、10kHz发布与本次约1kHz软件观察不同。sample_id按每次转换计数，相邻发布相差500；软件每次观察通常跨过约5000个转换编号，跳号正常，UART记录不是全速采样。

1. 先看两路时钟、原始码和OTR是否可观察。开路如有读数，只记录现象。
2. 两个SMA分别接已知0V，发送`s`。offset-binary名义中码2048；记录实际均值、min/max、OTR和实测输入，不要求恰好2048。这是**0V输入**，不是零电流校准。
3. 两SMA分别给不同且已测量的低压DC，例如+0.5V与+1.0V，再发送`s`。名义码约2252与2456，正电压对应码增加；辨认两SMA与raw_a/raw_b的实际对应，记录通道、比例、偏差和波动。仅当需要辨认位序或捕获问题时，再加一次幅度在允许范围内的小幅低频变化输入。

每行包含`sample_id、raw_a/b、OTR_a/b、SMA_a/b_uV_nom、quality`。SMA名义换算来自AN9238手册分压5.02及VREF=1V：

`V_SMA=(raw−2048)×10.04/4096 V`，即每码约2.45117mV，程序用整数µV四舍五入。它是名义传递关系，不是本次实测校准结果。允许输入仍按手册±5V，不能把理论±5.02V范围当过驱许可。本最小工程不运行电流预处理/校准，不提供手动有效配置；保留电流字段未标定/无效，程序不显示电流。

SUMMARY给出64条原码的min/max、`mean_x1000`（除1000得平均码）和两路OTR次数。是否对应正确通道、已知输入比例及实际波动，由本次输入和测量记录判断；`DONE`只表示这64条软件观察结束，不是BOARD_PASS。

## 结束与保存

完成所需输入条件后发送`q`，出现`AX03B2 END`，R5进入等待；PL时钟/转换仍继续，实验结束后由用户断电并拆除输入。保存WAIT至END的完整UART日志、两路时钟测量、每个SMA的实测DC电压/连接通道、原码均值/min/max及必要ILA截图。旧Workspace、原始数据和用户模型保持原样。本轮不自动开展真实ABZ、电流校准或有功率实验。
