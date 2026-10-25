# 面向R5F＋PL电机控制的ALINX学习地图

这是实际阅读后的路线，非目录猜测。`VENDOR_ROOT=资料/`，`S1=course_s1_fpga.zip!/course_s1_fpga/`（本地未解压，只读成员），`S2=course_s2/`，`F=factory_file/factory_vivado/`。页码均为原PDF的1基页序。S1指FPGA教程V1.02（228页），S2指Vitis教程V1.06（423页）。每项原件的哈希和已读范围在[索引](../references/alinx/ALINX_MATERIALS_INVENTORY.csv)。

## 按目的查资料

| 优先/目的 | 实读章节 | 实际工程入口 | 可以带走的知识/仍需适配 |
|---|---|---|---|
| P0 硬件识别 | 用户手册p2、6、9–11、20–24、39–50；核心/底板原理图 | [板卡事实](../hardware/axu5ev/ALINX_BOARD_FACTS.md)、[逐针表](../hardware/axu5ev/PL_IO_RESOURCE_MAP.csv) | **可直接查询事实**；先处理E/B-E/图框AXU3EG及XA/-1和XC/-2冲突，实物未确认前不生成XDC |
| P0 PL时钟/IO | S1 p27–28、74–75、85、88–90、109、111–112 | `S1/01_led/led.xpr`、`led.srcs/constrs_1/new/led.xdc`；`S1/02_pll_test/pll_test.xpr`、`pll_test.srcs/sources_1/new/pll_test.v`及`constrs_1/new/pll.xdc` | 学差分200MHz、Clock Wizard、时钟/IO约束；**需适配**IP、实际Bank/电平/复位、内部ILA网名，不能照搬旧50MHz文字 |
| P0 PL缓存/CDC | S1 p117、120、132、135–136、142 | `S1/03_ram_test/ram_test.xpr`、`S1/04_rom_test/rom_test.xpr`、`S1/05_fifo_test/fifo_test.xpr`及`fifo_test.srcs/sources_1/new/fifo_test.v`、`sim_1/new/vtf_fifo_tb.v` | **可学习端口/读延迟/满空保护**；FIFO例子不替代新采样链CDC、复位和时序验证；RAM实验不是AXI BRAM实验 |
| P0 PS/R5入口 | S2 p14–15、40、62–67、94–97、398–400 | `S2/01_ps_hello/.../build_vitis.tcl`、`04_ps_uart/.../src/ps_uart/main.c`、`33_lcd7_touch/.../src/lcd_touch/PS_timer.c`；中间`...`统一是`vitis/auto_create_vitis` | **软件需适配**：实际A53 standalone平台；UART/GIC/TTC可查，R5 BSP、TCM/MPU、启动/中断及WCET未运行，见[R5指南](../firmware/r5/ALINX_R5_REUSE_GUIDE.md) |
| P0 PS—PL寄存器/IRQ | S1 p11–16仅概念；S2 p160–177、198、209–210 | `S2/13_ps_axi_gpio/vivado/ps_axi_gpio.xpr`；`S2/16_custom_pwm_ip/vivado/custom_pwm_ip.xpr`、`vitis/auto_create_vitis/src/pwm/ax_pwm.h` | **结构可参考，接口需适配**：HPM0_LPD、AXI GPIO/中断及AXI-Lite封装；示例基地址/IRQ不成为本项目地址分配 |
| P0 PS—PL小块交换 | S2 p235、240–244 | `S2/20_bram_test/vivado/bram_test.xpr`；`vitis/auto_create_vitis/src/bram_test/main.c`和`pl_bram_ctrl.h` | 学双口BRAM和完成中断；**需适配**命令/反馈一致性、超时、R5缓存与中断，不把scanf/ISR打印带入实时路径 |
| P0 ADC接口 | S1 p187–196、197–198、200–204；S2 p260–262、275、287–303 | `S1/14_ad7606_hdmi_test/ad7606_hdmi_test.xpr`；其`sources_1/src/ad7606_if.v`、`ad7606_sample.v`（均在`.srcs`内）；`S1/15_ad9238_hdmi_test/ad9238_hdmi_test.xpr`；`S2/23_ad9280_dma_dp`、`24_ad9238_dma_dp`、`25_ad7606_dma_dp` | **需适配**：实际AN108/AN9238/AN706演示；显示链降精度/分批等待、PLL锁定/CDC和CONVST同步不能照搬；实际模块与模拟前端仍需核实 |
| P1 调试串口/485 | S1 p154–157、159、163–165；S2工程静态检索 | `S1/08_uart_test/uart_test.xpr`、`uart_test.srcs/sources_1/new/uart_test.v`；`S1/09_rs485_test/rs485_test.xpr`、`rs485_test.srcs/sources_1/new/rs485_top.v`；`S2/14_rs485_test` | 学UART波特率/帧与485方向；**不是**ABZ/SSI/BiSS/EnDat解码器，RS485不自动满足位置尺收发/隔离要求 |
| P1 高速记录/批量搬运 | S2 p225–226、233–235、245、250–251、259、306–307 | `S2/19_pl_read_write_ps_ddr`、`20_bram_test`、`21_dma_loopback`；后续SG DMA目录 | **可后置**：HP_FPD、AXIS/DMA与缓存维护；带宽不等于50µs控制时限，R5内存可达性/缓存仍需确认 |
| P0参考 出厂集成 | `F/board_test.xpr`、`board_test.srcs/sources_1/bd/design_1/design_1.bd`、`hw_handoff/design_1.hwh`、`synth/design_1.v`及`board_test.srcs/constrs_1/new/*.xdc` | `F/board_test.srcs/sources_1/new/top.v`；`F/repo/ip/`；`F/top.xsa`只读元数据 | **参考后重建**PS/时钟/reset/AXI/IRQ，视频/以太网/DDR测试不搬入电流路径；XSA旧bit未执行 |
| P1/P2 工具/存储/HLS | S0、S6及addition目录 | `course_s0_Xilinx开发环境安装教程.pdf`、`course_s6_MPSOC开发平台HLS教程V1.02.pdf`、`course_s2_addition` | addition已查为A53/文件系统演示；S0/S6本轮仅元数据索引，内容NOT_INSPECTED；不作为R5启动前提 |
| P3 当前不需要 | Linux、AI、VCU、视频/恢复包 | `course_s3.rar`、`course_s4.tar.gz`、`course_s5.tar.gz`、`AXU5EV_AI.rar`、`vcu_demo.rar`等 | 只留文件元数据/哈希；未解包、未运行，不上传原件 |

## factory需要重点核对的静态事实

- `board_test.xpr`/BD/XSA元数据为2020.1和`xazu5ev-sfvc784-1-i`。旧BD的`validated=true`不是本次工具验证。
- 主AXI网络来自外部200MHz→`util_ds_buf_0`→`axi_ethernet_0_refclk`的200MHz输出；该Wizard另出125MHz给以太网。PS的PL0/1 ACT_FREQ字段约148.147/190.474MHz不能代替实际网路追踪，也不是板上量测。
- HPM0_LPD为32bit；DMA/视频分别用HP0/HP1_FPD、128bit。IRQ0经过concat汇集以太网、DMA、两路UART16550、PL按键；不据线序猜R5 GIC中断号。
- 生成BD网表`design_1.v`中`rst_ps8_0_200M.dcm_locked`绑1，PS `pl_resetn0`是低有效外复位输入；Wizard locked另经NOT作为`clk_200m_rst`给DDR测试。该端口元数据却写ACTIVE_LOW，未来重建时须核对逻辑与极性；本轮未修补或判定硬件失败。
- 顶层`top.v`把fan固定1；BD无`ax_pwm`实例。`repo/ip/ax_pwm_1.0`是附带未接入单路参考，不能称出厂工程已有电机PWM。
- factory `peripheral_0`只有一般status/control寄存器参考；没有由已读代码证明原子多字段提交、一致快照或控制超时协议。原厂地址窗口只属于原厂设计，本轮不定义本项目寄存器。
- 所读8个用户XDC只有`system.xdc`含输入create_clock，未见外部IO的input/output delay；生成IP仍有自己的约束，不能据此宣称全工程无约束或时序已通过。

## 最短学习顺序

1. 对照实物丝印解除型号/Bank/料号冲突，查H1/H2/H3与逐针表；先明确哪些电机底板电路实际存在。
2. S1 LED/XDC→PLL→FIFO，只学习时钟、复位、接口和仿真读法；不重新设计控制器。
3. S2最小平台→UART/GIC→TTC；随后在AX-01明确R5 domain、链接内存和周期任务语义，再做实际运行测量。
4. S2 AXI GPIO→BRAM→中断与一致性交换学习；原速度/位置/对齐/命令合同仍来自已接受模型。
5. 对实际ADC/位置模块逐项匹配资料，进入AX-02时再预算CONVST/BUSY、CDC、位置锁存、PWM应用边界和故障禁止。
6. DMA、DDR、以太网等按记录带宽需求追加；Linux/视频/AI不作为当前路线前置条件。

所有运行/迁移结果均`NOT_RUN`。本轮不执行原厂脚本，不升级原工程，不更改已接受Simulink/FOC，不新建固件、HDL、XSA或XDC。
