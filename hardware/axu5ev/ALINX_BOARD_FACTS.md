# ALINX 板卡事实与电机接口边界

本轮只读本地资料，标记 `DOC_VERIFIED`（文档事实）、`PROJECT_INSPECTED`（工程参数）、`INFERRED`（本项目判断）、`NOT_RUN`（未执行）。**目标板AXU5EVB-E，用户已确认**；具体PCB修订和芯片完整料号另待板级核对。非B版仅作对照。表中页码均为PDF从1开始的页序；原理图标题号可能与PDF页序不同。

## 来源定位

`VENDOR_ROOT` 是本地项目下的 `资料/`，原件不入Git。完整SHA256及读取范围见[资料索引](../../references/alinx/ALINX_MATERIALS_INVENTORY.csv)。

| ID | VENDOR_ROOT 下的原始文件 |
|---|---|
| H1 | `AXU5EVB-E开发板用户手册.pdf`，51页，版本记录到REV1.2（p2） |
| H2 | `00_hardware/01_原理图结构图等硬件资料/核心板/ACU5EV核心板原理图.pdf`，21张，图框Rev1.0 |
| H3 | `00_hardware/01_原理图结构图等硬件资料/底板/AXU5EVB-E开发板原理图.pdf`，19张，图框Rev1.0 |
| H4 | 同目录 `AXU5EV-E开发板原理图.pdf`，19张；只作变体对照，不替代H3 |
| F1 | `factory_file/factory_vivado/board_test.xpr`、`board_test.srcs/sources_1/bd/design_1/design_1.bd`及`board_test.srcs/constrs_1/new/` |
| R1 | `00_hardware/02_芯片手册/Ultrascale+/ug1085-zynq-ultrascale-trm.pdf`，UG1085 v1.7（2017-12-22），1165页；架构参考而非当前配置 |

## 资源表

| 资源 | 文档/工程事实 | 对本项目的用途与限制 | 来源/状态 |
|---|---|---|---|
| 产品/芯片 | 目标AXU5EVB-E，用户已确认；H1标ACU5EV，芯片`XCZU5EV-2SFVC784I`，工业级SFVC784、-2 | 芯片完整料号、底板/核心板实际修订待核；生成板级XDC前核对，不阻塞R5软件整理 | H1 p1–2、6、9–11；DOC_VERIFIED；购买型号USER_CONFIRMED |
| 厂商工程器件 | S1与出厂XPR选`xazu5ev-sfvc784-1-i` | 与手册的XC/-2不同；不能只改字符串冒充已适配或已验证 | F1 XPR Part；PROJECT_INSPECTED |
| 处理器 | 4×A53、2×R5；手册同页分别写R5最高500与600MHz | 可支持既定R5F职责；时钟实际值、split/lockstep和WCET未确认 | H1 p10；DOC_VERIFIED，运行NOT_RUN |
| RPU片内基础 | ARMv7-R/VFPv3；split每核128KB TCM、lockstep合并256KB；OCM独立256KB；RPU GICv1 | 是芯片架构能力，不是新平台模式/链接/中断已经配置 | R1 p82–83、85–86、91–93、311、317、512–513；DOC_VERIFIED |
| PL | 256.2K逻辑单元、117.12K LUT、234.24K FF、5.1Mb BRAM、1248 DSP、4 CMT | 仅资源容量资料，不是FOC资源/时序验收 | H1 p11；DOC_VERIFIED |
| 存储 | PS DDR4 4GB/64bit；PL DDR4 1GB/16bit；QSPI256Mbit；eMMC在p9写8GB、p18–19写32GB但型号仍MTFC8GAKAJCN-4M | eMMC容量保留冲突，实物待核；不能据DDR容量确定R5内存布局 | H1 p9、11、17–19；DOC_VERIFIED |
| 核心时钟 | PS参考33.333MHz，R16；RTC32.768kHz，N17/N18；PL差分200MHz，AE5/AF5（Bank64） | 200MHz输入不是电流控制采样频率，也不是旧50MHz合同已经迁移 | H1 p20–21；H2 p2、5、17；DOC_VERIFIED |
| Bank43–46 | 核心板VCCO为3.3V，扩展数字IO | 可作为外接采样/位置/PWM/故障线的候选资源；不等于耐受5V输入 | H2 p4、18–19；H1 p41–42；DOC_VERIFIED |
| Bank64 | 核心板1.2V、PL DDR4及200MHz时钟 | 不当通用3.3V扩展口使用 | H2 p5、15、17；DOC_VERIFIED |
| Bank65/66、MIO | 核心说明65/66最高1.8V；B-E底板65=1.2V、66=1.8V；MIO=1.8V | 与3.3V扩展口分开；MIPI/PL以太网等已占资源不能直接挪用 | H1 p23–24、49–50；H2 p18–19；H3 p19；DOC_VERIFIED |
| J15/J16扩展口 | 各40针、34数字IO；1脚GND、2脚+5V、37/38脚GND、39/40脚+3.3V | 共68个候选数字IO；电源脚与逻辑电平分开；未分配新的电机信号 | H1 p41–42；H3 PDF p18（图框仍写RS485）；DOC_VERIFIED |
| 板间连接 | 核心J29–J32，4×120pin；AXK5A2137YG/AXK6A2337YG | 自制载板才需深入板间连接；先用已证实扩展口事实 | H1 p24–32；H2 p18–19；DOC_VERIFIED |
| 调试UART | PS MIO43/K19 TX、MIO42/L18 RX；PL AH12 TX、AH11 RX；CP2102GM | 可参考日志和命令调试；PS侧经TXS0102进行1.8/3.3V转换 | H1 p39–40；H3 p11，U33/U34/U30；DOC_VERIFIED |
| RS485 | 两路MAX3485ESA、收发方向控制DE，120Ω终端和TVS；J7-2一路/J7-1二路 | 半双工通信电路参考；不是现成ABZ/SSI/BiSS/EnDat位置接收器，也未证明隔离 | H3 p14，U24/U28、R33/R42；H1 p43–44；DOC_VERIFIED/INFERRED |
| CAN | 两路SN65HVD232C连接PS MIO32/33及39/38 | 可用于上层通信；不是电流环实时反馈通道的既定选择 | H1 p42–43；H3 p13；DOC_VERIFIED/INFERRED |
| 启动/复位 | SW1模式0000 JTAG、0010 QSPI、0101 SD、0110 eMMC；KEY2→MR；核心PMIC产生PS_POR_B | PS系统复位、PI_Reset、Init_Reset和驱动故障清除语义仍分开；只记录，未拨动开关 | H1 p48–49；H3 p4；H2 p2、19、21；DOC_VERIFIED/NOT_RUN |
| 电源/保护 | 板输入12V；DC/DC供5/3.3/1.8V等；输入有3A熔断器 | 是开发板电源，不是48V电机功率级；未找到门极驱动互锁/电流硬件比较器/急停链 | H1 p49–50；H3 p19；DOC_VERIFIED/INFERRED |
| 模拟采样 | 手册介绍片内System Monitor用于温度/电压；S2另有外接AD9280/AD9238/AD7606例程 | 片内监控不能直接当已验收电机电流ADC；外接模块实物、模拟调理与同步关系未确认 | H1 p11；S2相关工程，见教程表；DOC_VERIFIED/PROJECT_INSPECTED |

## 接口事实与缺项

逐针事实在[PL_IO_RESOURCE_MAP.csv](PL_IO_RESOURCE_MAP.csv)。目标为用户确认的AXU5EVB-E；该表记录原厂连接，不分配本项目PWM、ADC或故障脚，也不是可执行约束。F1仍使用J45/J46等旧端口名；例如J45的B10/C11与H1的J16.3/.4相同，只作为按封装脚比对的工程别名。

项目需求继承[旧接口定义](../../references/legacy/PMLSM_Hardware_Interface_Map.md)、`references/legacy/mil/PMSLM_Init_Params_MBDL4.m`及相关MIL/DSP模型：YXPHM-MBDL4、独立三相ia/ib/ic、光栅0.1µm/count、RELCON/ENCON/F_Reset、低有效ERRI/ERRU。厂商没有专用电路或例程不代表项目没有定义；旧DSP GPIO/ePWM/ADC配置仅作来源，不能直接当新板引脚或PL实现。

| 所需接口 | 本地实际依据 | 结论 |
|---|---|---|
| 三相电流ADC | 旧工程已有MBDL4独立ia/ib/ic需求；S2有AD7606等采样/DMA参考 | 待适配：外置ADC选型、三通道映射、量程/调理/隔离、同步转换及读取延迟。旧ADC偏置/增益不能直接用于新ADC |
| 位置反馈 | 旧工程已有光栅计数、0.1µm/count与eQEP来源；厂商未提供匹配的电机编码器例程 | 待适配：光栅到新PL的接收电路、电平/终端、计数方向与同步锁存。保留分辨率和速度差分语义；RS485教学例程不替代光栅接口 |
| PWM与门极接口 | 已有三相duty、互补PWM/1µs死区和MBDL4需求；厂商仅单路教学PWM | 复用已接受电流FOC；待实现新PL PWM时序、互锁、快速禁止以及MBDL4门极接线/电平适配，不照搬旧DSP ePWM配置 |
| 故障/急停 | 旧工程已有RELCON/ENCON/F_Reset和低有效ERRI/ERRU、故障锁存与独立禁止要求 | 待适配：新板IO、电平转换、驱动禁止及故障路径；急停新接线待定。保留PL快速禁止、驱动硬件保护、R5恢复管理分层，复位/清故障与重新使能分开 |
| PS—PL交换 | S2 AXI GPIO、AXI-Lite PWM、BRAM、HP DMA | 需适配至R5 domain、内存属性/缓存与中断；原子命令/一致快照和超时边界仍由AX-01定义，本轮不设计寄存器 |

## 必须带入后续工作的冲突

1. H1 p10自身的R5最高频率500/600MHz不一致；F1的ACT_FREQ字段是设计配置，不是处理器实测。
2. H1 p24/41正文写Bank24/25/26等，与同手册逐针表及H2 p4的Bank43–46不一致。本表按**逐针表+核心原理图**记录Bank43–46，保留正文冲突。
3. H3/H4图框标题仍写AXU3EG，且p17标题EXTEND IO实际是MIPI，p18标题RS485实际是J15/J16。引用必须用PDF页序加网名，不能只认标题。
4. H1 p2版本记录提J46，而当前扩展表为J15/J16；factory工程也留J45/J46名称。目标板已确认为AXU5EVB-E，板级接线按B-E资料并核对实际PCB修订。
5. 手册XC/-2与工程XA/-1不一致，实际核心板/底板修订和芯片完整料号仍待核；这是器件实施前的核对项，不是R5模型提取的阻塞。没有创建XSA/XDC或签核时钟。
6. H1的eMMC容量8/32GB有冲突；p44把第二路RS485 TXD2的网名写成B43_L1_N，而AG10在H2 p4为B43_L1_P。逐针表列原来源和更正依据，不静默修订厂商资料。

后续沿用100µs电流、1ms速度、10ms位置及50µs应用边界作为算法参考合同。新增ADC转换、位置采样、跨时钟和PS—PL交换后，须重新测量端到端时延；本轮没有运行厂家工程、R5程序、RTL仿真、综合、布局布线或硬件。
