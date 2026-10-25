# ALINX 裸机资料怎样用于 R5F

**已查工程的目标是A53，不是R5F可执行基线。** 以下均为`PROJECT_INSPECTED`或`DOC_VERIFIED`；编译、运行、R5时间测量和2026.1兼容性均`NOT_RUN`。只整理入口，不在本轮生成固件、BSP或内存/寄存器合同。

所有路径以`VENDOR_ROOT=资料/`为根；下文`S2=course_s2/`。PDF指`course_s2_ALINX_ZYNQ_MPSoC开发平台Vitis应用教程V1.06.pdf`，页序从1开始。逐文件SHA与已读页见[索引](../../references/alinx/ALINX_MATERIALS_INVENTORY.csv)。

## 先辨认处理器域

实读40个S2 `vitis/auto_create_vitis/build_vitis.tcl`：全部平台选`psu_cortexa53_0`、64-bit；`18_freertos`选`freertos10_xilinx`，其余为`standalone`。addition另1份脚本也是A53/64-bit。`17_dualcore_amp`第二域是`psu_cortexa53_1`。本地没有保留生成的`app.spr/platform.spr/*.mss`；目标核结论来自创建脚本，而非文件缺失推测。PDF p15解释保留XSA/源代码/创建脚本的交付方式。

R5架构出现在PDF p64的GIC介绍；`01_ps_hello/vivado/ps_hello.srcs/sources_1/bd/design_1/design_1.bd`中R5时钟请求500MHz、ACT_FREQ约499.995MHz、`RPU_COHERENCY=0`，仅是PS配置。没有由这些字段证实R5 domain、启动、split/lockstep或TCM/MPU布局。

## 本地原始TRM提供的R5基础

`00_hardware/02_芯片手册/Ultrascale+/ug1085-zynq-ultrascale-trm.pdf`实际为 **UG1085 v1.7（2017-12-22）**，1165页。只读12个相关页及封面/修订页，未称其为当前最新版。以下是`DOC_VERIFIED`架构能力，不是本项目已配置/运行：

| TRM PDF页 | 能据此确认什么 | 对A53例程适配的意义 |
|---|---|---|
| 82–83 | R5F是ARMv7-R，含VFPv3、各32KB I/D cache及MPU能力 | A53 ARMv8/64bit链接脚本不能直接当R5方案；生成C/BSP浮点ABI和MPU/cache属性仍待核对 |
| 85–86 | split独立双核与lockstep冗余模式，模式切换涉及处理器复位边界 | 不能把A53双核AMP脚本当RPU模式设置；本轮不选择或修改模式 |
| 91–93 | split每核64KB ATCM+64KB BTCM；lockstep合并256KB TCM | 可区分本地TCM和DDR；不等于当前链接/电源/初始化正确，不在此分配地址 |
| 311、317 | RPU GICv1与APU GICv2；同MPCore SGI和异构IPI有不同用途 | A53 SGI/CPU mask不能原样作为A53–R5通信；目标RPU路由/IRQ仍需检查 |
| 512–513 | OCM是独立256KB共享片上RAM，四个64KB bank，存在仲裁/保护 | 可达不等于cache一致或确定延迟，不能凭共享指针演示推定已满足控制合同 |

另读p87仅确认ECC/中断注入能力，未配置/验证，也不据此宣称项目安全等级。MPU详细配置、TCM地址映射和lockstep初始化序列未在本轮审阅；不凭书签补造启动程序。

## 最有价值的实际入口

| 顺序/用途 | S2下的原始工程/文件 | 文档页码 | 复用判定及R5适配点 |
|---|---|---|---|
| 1 平台与最小程序 | `01_ps_hello/vitis/auto_create_vitis/build_vitis.tcl`；对应`vivado/ps_hello.xpr`与BD | 14–15、40、86 | **需适配**：选实际R5处理器/domain、standalone BSP、启动与异常入口、链接内存；不能只替换核名字便宣称通过 |
| 2 UART/中断接线 | `04_ps_uart/vitis/auto_create_vitis/src/ps_uart/main.c`、`uart_parameter.h` | 94–97 | **可直接查用API用法，软件需适配**：XUartPs、XScuGic、FIFO/ISR示例；重查目标BSP中的device/IRQ、串口归属；含sleep的演示循环不是调度器 |
| 3 周期中断 | `33_lcd7_touch/vitis/auto_create_vitis/src/lcd_touch/PS_timer.c`；同目录`display_demo.c` | 398–400 | **需适配**：实际用XTtcPs interval/prescaler，APP示例100Hz；只取定时器参考，不搬LCD。周期、首相、抖动与WCET另验 |
| 4 PS—PL AXI/IRQ | `13_ps_axi_gpio/vivado/ps_axi_gpio.srcs/sources_1/bd/design_1/design_1.bd`；`vitis/auto_create_vitis/src/xgpio_intr_tapp_example/xgpio_intr_tapp_example.c` | 160–177 | **可直接学习互联结构，需适配软件**：HPM0_LPD→AXI GPIO、PL IRQ→pl_ps_irq0；新XSA重定基地址/中断号、路由和触发，不能继承旧常量 |
| 5 AXI-Lite封装 | `16_custom_pwm_ip/vitis/auto_create_vitis/src/pwm/ax_pwm.h`、`helloworld.c`；`vivado/ip_repo/ax_pwm_1.0/src/ax_pwm.v` | 198、209–210 | **仅复用封装思路**：32bit寄存器offset0/4演示频率/占空比；是单路呼吸灯PWM，不是三相互补/死区/快速禁止模块，不替换已有FOC/PWM |
| 6 小批量双口存储 | `20_bram_test/vitis/auto_create_vitis/src/bram_test/main.c`、`pl_bram_ctrl.h`；对应BD | 235、240–244 | **可学习PS/PL双口BRAM与完成中断，需适配**：scanf/printf和ISR打印不进入实时路径；命令原子性、一致快照、超时语义由AX-01另定 |
| 7 大数据/缓存 | `21_dma_loopback/vitis/auto_create_vitis/src/dma/dma_intr.c`；对应BD | 245、250–251、259 | **需适配，可后置**：DMA7.1/simple、HP0_FPD、AXIS FIFO、flush/invalidate；重新核实R5 cache/MPU、DMA可达内存与描述符，不以吞吐量证明50µs时限 |
| 8 DDR窗口 | `19_pl_read_write_ps_ddr/vivado/pl_read_write_ps_ddr.srcs/sources_1/bd/design_1/design_1.bd` | 225–226、233–234 | **暂非首要**：PL经HP写DDR/ILA观察；Hello World APP不是共享内存协议或一致性实现 |
| 9 AMP概念 | `17_dualcore_amp/vitis/auto_create_vitis/src/cpu0_app/`、`cpu1_app/`中的`.c`与`lscript.ld` | 214–220 | **当前不直接采用**：双A53、ARMv8链接脚本；0x3FF00000共享演示与SGI 1/2不是A53–R5 IPI或R5 TCM方案；不能推定cache一致性已解决 |

RTC例程`02_ps_rtc/.../xrtcpsu_periodic_alarm_interrupt_example.c`及PDF p62–67可读GIC/报警流程，秒级RTC不作为1ms/10ms任务时基。CAN/RS485只提供通信参考；eMMC addition含格式化/删除/写文件示例，本轮只读，不执行。

## ADC与PL的边界

| 实际模块/入口 | 能查到什么 | 不能由demo推定什么 |
|---|---|---|
| AN108/AD9280：`23_ad9280_dma_dp/vivado/ip_repo/ad9280_sample/src/ad9280_sample.v`，PDF p260–262、275 | 8bit并行、ADC时钟和异步FIFO→AXIS；文档32MSPS | 不证明电机采样分辨率/模拟调理/隔离足够 |
| AN9238/AD9238：`24_ad9238_dma_dp/vivado/repo/ad9238_sample_1.0/src/ad9238_sample.v`，p287–294 | 双12bit、65MSPS、12→16bit、两个DMA及跨域 | 不把显示例程的采样/数据格式和XDC直接当电流反馈 |
| AN706/AD7606：`25_ad7606_dma_dp/vivado/ip_repo/ad7606_sample_1.0/src/ad7606_if.v`、`ad7606_sample.v`，p297–303 | 八通道16bit、文档200kSPS；CONVSTA/B、BUSY、并行读及FIFO打包 | 底层转换状态机自行循环，sample_start主要控制缓存；未见PWM同步触发输入。需要按实际模块核对转换完成、通道顺序、CDC、时间戳和采样/应用延时 |

例程存在不证明模块实物或电流传感器存在。100µs电流、1ms速度、10ms位置、50µs应用边界继续作为算法参考；新硬件链路的最坏延迟必须另测。

## 阅读时应避开的旧平台残留

- PDF p214写`ps7_cortexa53_0`，p216写`ps7_cortexa9_1`，实际脚本是`psu_cortexa53_0/1`；p220又明确A53 1。不要按截图中的旧核名创建R5域。
- p177的UG585/M_AXI_GP0、p225的Zynq-7000描述不能提供MPSoC新地址；p400写XScuTimer而实际源码为XTtcPs。
- 教程V1.06版本表日期2022-07-13（p3），教学工具仍为Vivado/Vitis2020.1（p14–15）。XSCT脚本、BSP宏、ARMv8链接脚本和旧IP版本均需在独立新平台核对，未原位升级任何厂家工程。
- Linux/FreeRTOS、视频DP、lwIP、存储、双A53AMP和SG DMA不作为初版单R5裸机启动前提。

后续学习顺序：确认实物/料号与启动资料→R5最小平台/UART→TTC和中断测量→AXI GPIO/BRAM学习→按AX-01审查软件与交换合同；DMA和高带宽采集按实需追加。这里是学习路线，不是已实施的R5固件。
