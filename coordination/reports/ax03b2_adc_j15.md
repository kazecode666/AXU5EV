# AX-03B2：J15最小真实ADC采集工程

本轮执行[kazecode666/AXU5EV Issue30](https://github.com/kazecode666/AXU5EV/issues/30)，从已合并PR29的`origin/main 33f8237ad0d3fa08b9eac4b9fa5c97f0cf241e8d`建立`codex/ax03b2-adc-j15`。实现范围为AN9238→J15→PL原码快照→最小R5 UART观察，板测尚未执行。不接驱动板、电机、真实ABZ、FOC或功率输出。

## 实现与接口依据

[J15逐针表](../../hardware/axu5ev/AX03B2_J15_MAP.csv)和[XDC](../../hardware/axu5ev/ax03b2_adc_j15.xdc)由本地AN9238 UG、AXU5EVB-E底板/核心板原理图及`资料/course_s2/24_ad9238_dma_dp/`对照得出。仅导出26个数据/OTR输入与两个时钟输出，电源/GND/NC不变成FPGA端口；CH1非升序数据位逐位落地，J16不连接信号。

送出时钟由同一50MHz名义PS PL0时钟的十拍计数器产生：phase0两路同时上升，phase5同时下降；phase4同时捕获双12位码和两OTR。没有新增内部ADC时钟域。模拟采样身份/tick在实际送出上升沿保存，在该转换的capture event入七事件队列，E7捕获返回码与E0身份关联；选取每500次转换的一帧，约10kHz发布。ILA probe0为64位：raw A[11:0]、raw B[23:12]、OTR{B,A}[25:24]、capture[26]、selected capture[27]、publish[28]、返回sample_id[60:29]。原码debug寄存器在capture沿更新，ILA同沿所见为更新前值，下一逻辑拍可见新码。

时序依据：[ADI AD9238 Rev.D](https://www.analog.com/media/en/technical-documentation/data-sheets/AD9238.pdf)第6页Table4/Figure2给出tPD=2..6ns、流水线7周期、最低1MSPS；tPD条件包括输出5pF、表列DRVDD条件。外部时钟正向/数据返回各0..2ns是短1:1对插的工程预算，非实测，故input delay min=2ns/max=10ns。OTR暂用同输出预算，原件没有另列OTR tPD保证。两路送出时钟均建立同源/10 generated clock；[UG903 Input Delay](https://docs.amd.com/r/en-US/ug903-vivado-using-constraints/Input-Delay)所述min/max延时约束用于全部26条返回输入。未加false_path或multicycle，STA按最早20ns逻辑边沿检查，比实际上升后80ns捕获更严格。实现通过只证明这些明确预算下的数字时序，实际负载、走线预算、OTR及模拟精度仍由首次现场观察核对。

快照直接复用B1的`ax03b1_adc_receiver`和`ax03b1_snapshot_axi`，BEGIN/32word payload/终字响应释放不变；最小写通道只返回SLVERR以完成AXI互连。B2身份`0x42324F42`、schema1，raw在word6/7，quality bit3/4为OTR。电流/校准/ABZ字段保持0，current valid=0，error包含未标定A/B及OTR位；ABZ filter_cycles=0表明未接入。没有PWM、ENCON、RELCON或运行许可端口，也没有控制写入。没有为了观察原码硬设manual_valid或启用零流校准。

R5应用每次UART `s`观察64条最新冻结帧，名义约1ms间隔，完成后才逐行打印。PL连续转换、PL选样发布和低速软件观察是三个不同频率，sample_id跳号正常。SMA名义电压为`(raw−2048)×10.04/4096 V`：来自AN9238 UG第6页5.02分压及第8页VREF=1V/offset binary，代码用整数µV。它不是实测电压校准，更不是带载电流`A/count`；0V与开路均不作为零电流校准。每窗给出raw均值/min/max及OTR次数。

## 构建、证据与首次操作

新增硬件入口为`scripts/ax03b2_build_hw.ps1`，使用原已工作的PS配置升级路径、DDR/UART、LPD AXI及复位接法，独立产物位于`.runtime/ax03b2/hardware_01/`；仅为Windows工具路径兼容准备两份vendor PS输入文件，不复制整个厂商工程。新增R5入口`scripts/ax03b2_build.py`从本轮XSA/BSP取实际地址、生成R5 standalone和A53 FSBL；旧PR24产物不重建。

实际离线结果见[精简证据](../../verification/ax03b2/results.json)及[原始时序摘录](../../verification/ax03b2/implementation_excerpt.txt)。

| 项目 | 本轮实际结果 |
|---|---|
| 新接口RTL仿真 | PASS，9482检查/549捕获/3发布；2/10ns延时、七转换关联、选样OTR、跨发布冻结、reset及只读写应答；日志`.runtime/ax03b2/interface_02/` |
| 综合/布局布线 | PASS，xczu5ev-sfvc784-2-i；顶层综合0错误/0严重警告；2029 LUT、3544寄存器、2 BRAM Tile、0 DSP |
| 最终建立/保持/脉宽 | 整体WNS +1.826ns、WHS +0.014ns、WPWS +8.500ns，TNS/THS/TPWS及失败端点全0；ADC输入最差setup +1.826ns、hold +5.516ns |
| 约束覆盖 | 两路pad时钟均同源/10；26输入no/partial_input_delay均0，no_clock/generated_clock/multiple_clock/未约束内部端点均0；28个PACKAGE_PIN/LVCMOS33与接线表全部相符 |
| bit / ltx / 含bit XSA | PASS，分别7797907 / 14234 / 711670 B；LTX确有一个64位probe0 ILA及debug hub；最终`AX03B2_BUILD_PASS` |
| 最小R5/FSBL | PASS，ELF212384 B、A53 FSBL340576 B；应用编译0警告/0错误，实际BSP宏`XPAR_ADC_OBSERVER_0_BASEADDR=0x80000000`，4KiB范围 |
| 既有被动启动检查 | OFFLINE_STARTUP_CHECK_PASS，ARM32 R5 + AArch64 FSBL，唯一Launch `ax03b2_adc_manual`，停止入口/不自动programDevice |
| 实板/已知输入/真实电流校准 | NOT_RUN |

PS实际频率元数据为49,999,500Hz，ADC为4,999,950Hz、发布9999.9Hz；STA报告显示名义20.000/200.000ns周期。外部预算仍是工程假设，频率元数据不是示波器实测。没有重复B1全量回归或PR24，没有改变电流数值源，因此未重生HDL、未建第二套模型。

**保留的警告与范围：** 最终DRC无错误/严重警告，但有6条Warning：debug hub的PDCN-1569三条、RTSTAT-10一条，以及两路输出时钟寄存器IOB打包未实现的REQP-1617两条。两个FDRE实际均在SLICE_X9Y167，路径包含各自FF C→Q、fabric路由、OBUF及pad；代表性Slow setup路径到pad分别6.855/7.012ns，差0.157ns，属STA模型结果而非实测或跨全部角落的skew上界。实际输出延迟已进入ADC返回时序，未宣称OLOGIC或物理零偏差。

当前重新运行的methodology报告仍有26条TIMING-18，原文要求相对`clk_pl_0`补输入delay；另有LUTAR-1五条和XDCB-5四条。TIMING-18是当前警告，不能归为旧缓存。本接口外部数据由5MHz送出pad时钟发起，50MHz为内部捕获时钟；已对两路5MHz参考给出完整min/max，实际5MHz→50MHz路径全部计时且check_timing无缺失/部分输入延时。没有另一路50MHz外部发起流可补。因此本轮按接口合同复核后保留该methodology警告，不增加错误的50MHz发起约束、false_path或抑制规则；这是工程判断，不冒称官方工具缺陷豁免或methodology零警告。两个clock输出的no_output_delay仅为已定义时钟端口LOW提示，非遗漏数据输出。完整报告保留`.runtime/ax03b2/hardware_01/reports/`供Review。

构建中修正过模块引用缓存的50MHz频率元数据及XDC内部层级：最终使用实际49.9995MHz元数据和BD公开时钟边界。按最终XDC仅重跑了本轮顶层综合/实现，生成状态一致的最终产物；没有重建原FOC或B1数值DUT。

唯一现场入口：[首次板测指南](../../firmware/r5/ax03b2/FIRST_BOARD_RUN_ZH.md)。它列明本轮bit/ltx/XSA/ELF、FSBL→加载bit→解除隔离/释放PL复位→R5 WAIT/s/q顺序，以及时钟、已知0V、不同低压DC的观察与保存方法。针1/电源/39–40脚实物插接、模块独立双总线设置和SMA J5/J6归属仍须用户断电核对/不同DC确认，未编造已完成实物检查。

本轮板卡发现/连接/复位/加载/运行均NOT_RUN；没有真实ADC输入结果，不称BOARD_PASS或电流标定完成。AQM/AUM参数、PI、原FOC/Runtime、用户SLX修改和全部旧数据保留。完成Draft PR后停止，等待Review，不自动合并，不自动启动真实ABZ或有功率工作。
