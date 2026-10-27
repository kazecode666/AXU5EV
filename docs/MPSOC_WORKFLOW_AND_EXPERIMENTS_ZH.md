# AXU5EVB-E：项目介绍、模型层次与MPSoC开发流程

日期：2026-10-26。本文说明本项目的开发路线，不代表以下硬件环节已经完成。项目状态以具体PR和运行报告为准；PR9仍在修复收尾，新的Ready/Send交互反馈继续在Issue #8及PR9处理。

## 1. 项目要解决什么问题

以永磁直线同步电机（PMLSM）为对象，建立以Simulink/Stateflow为算法源、以AXU5EVB-E为实验硬件的电流控制研究平台。当前用位置P—速度PI—电流PI-FOC作为统一基线；重点是在相同电机、逆变器、采样周期和外环条件下，研究与比较电流控制方法的跟踪、动态响应及扰动抑制效果，同时评估其硬件实现代价。

架构已经确定：单Cortex-R5F负责运动控制和运行管理，PL负责电流控制与快速采样/输出。未来复杂速度环、位置环和运动算法优先在R5软件侧迭代，不要求所有功能都生成HDL。旧XC7A200T项目的模型、定点FOC、p3流水线实现、轨迹和原对齐等成果继续复用；旧器件上的资源/时序结论不自动成为5EV验收。

| 分工 | 目标内容 |
|---|---|
| R5F软件 | 轨迹、命令、位置/速度控制、Reference_Manager、原对齐状态机、一次性偏置计算、状态与恢复管理 |
| PL硬件 | 电流FOC及后续电流算法、ADC数字接口、位置尺接收/同步、实时电角度、PWM时序及快速禁止 |
| PC上位机 | 设置目标和参数、观察波形、记录实验；不替代已部署的实时控制任务 |
| 外部电路 | 电流采样与ADC转换、位置尺收发/电平、功率逆变器/驱动、必要隔离与硬件保护 |

以上是项目选择。R5采用standalone裸机方向，第一版不以A53/Linux、复杂多核通信或HLS为前置条件；AMD官方提供R5F的standalone BSP支持。[S3]

## 2. 按用途分三类模型，而不是再维护三套控制算法

| 模型类别 | 控制器在哪里执行 | 电机与逆变器在哪里 | 主要回答的问题 |
|---|---|---|---|
| **一、纯MIL算法参考** | Simulink/Stateflow，通常先用浮点 | 数学/物理仿真模型 | 控制算法是否正确，参数、轨迹与控制性能如何 |
| **二、面向MPSoC的分区与代码联合仿真** | 软件部分可运行模型或生成C；PL部分可运行定点模型或实际HDL仿真 | 继续使用同一仿真对象 | 定点化、生成C/HDL、执行次序与接口接入是否保持预期行为 |
| **三、硬件部署与实机实验** | R5F执行目标程序，PL运行实现后的硬件电路 | 真实驱动板、真实电机与传感器 | 真实采集、通信时延、控制周期、保护和电机性能是否满足目标 |

第二类中维护两个有明确边界的算法源：**R5软件代码生成部分**和**PL电流代码生成部分**。软件部分生成C，PL部分生成SystemVerilog；试验用电机、负载、Scope、Dashboard和Windows MEX/XSI不属于目标控制器，不整体部署到芯片。MathWorks官方SoC流程也区分处理器可执行程序与FPGA配置。[S1]

三类是用途/执行环境的划分，不要求再复制三份参数和PI算法。日常活动模型与外部.m集中在`simulation/`，使用唯一参数入口，保持用户已有区域分组、简短中文注释和信号名称。原组件来源与当前Runtime若为独立副本，必须明确哪一份参与生成，不能误以为所有模型会自动同步。

### 当前三种后端属于第二类模型

- `model_fixed`：软件仍由Simulink模型执行，电流环由定点模型执行。
- `c_fixed`：生成C在PC上执行，电流环仍为定点模型。
- `c_rtl`：生成C在PC上执行，实际SystemVerilog在Vivado Simulator/XSI执行。

它们都不是板上R5执行；`model_fixed`也不是原来的全浮点MIL。当前Windows C闭环是已实现的主机执行方式，不能自动称为Simulink托管SIL或R5 PIL。PIL/HIL可按需要引入，但它们是验证方式，不是必须再增加的独立算法来源。

### ADC和编码器何时加入

在第二类模型中可以先加入采样时刻、量化、偏置、延迟及位置计数等接口模型，验证接口对闭环的影响。这仍然是仿真，不代表ADC或位置接口已经部署。

第三类中把这些理想反馈换成实际驱动/接口：外部ADC完成模数转换，PL触发/读取数字结果并做标定换算；PL接收光栅尺或磁栅尺的实际信号、形成位置/速度及电角度。传感器协议、电平和引脚继承现有电机/驱动资料并按B-E板映射，不能仅根据厂商示例猜测。

实机时不再把仿真电机输出接给控制器，也不把平均逆变器模型生成到FPGA代替功率级。SVPWM占空比还要经过真实PWM载波/比较、互补与死区、使能及故障关断逻辑，才能形成驱动板所需信号。

## 3. 工具各自负责什么

| 工具 | 本项目用途 | 主要产物/边界 |
|---|---|---|
| MATLAB / Simulink / Stateflow | 参数、控制和轨迹模型、对齐状态机、闭环仿真与日志 | 算法模型与外部参数；不是整板程序 |
| Simulink Coder / Embedded Coder | 从R5侧模型生成C；分别使用主机与目标配置 | C/H、数据/函数接口；还需目标编译和平台集成 |
| Fixed-Point Designer / HDL Coder | PL数据类型、定点运算与流水线、生成SystemVerilog或IP | HDL源及必要数据；不是直接可装入R5的程序 |
| HDL Verifier / Vivado Simulator / XSI | 实际HDL与Simulink对象联合仿真 | 主机仿真结果；不证明5EV布线时序或R5执行时间 |
| Vivado | 配置MPSoC硬件、PL逻辑/IP、AXI、时钟复位/中断、引脚约束、综合布局布线 | PL配置bitstream及硬件交接XSA |
| Vitis + Arm编译工具 + standalone BSP | 为R5创建平台/域、集成生成C与驱动、编译链接、调试与测量 | R5目标ELF程序、必要启动组件 |
| 示波器/逻辑分析/ILA及软件日志 | 后续测量采样、周期、PWM、总线和任务时间 | 实测波形与性能，不替代算法模型 |

现有报告采用MATLAB R2026b和Vivado 2026.1。沿用已跑通的本地工具组合，不为写流程自动升级。Vitis和目标代码生成支持需要按实际安装/许可核实；不把“工具里有Zynq按钮”视为AXU5EVB-E＋R5F的一键支持。

MathWorks的ZCU102 AXI示例面向Cortex-A53，并使用相应支持包；可参考分区和IP接口方法，但不能直接把它当作本板R5F裸机方案。[S2] 对本项目优先采用“模型生成算法＋Vivado/Vitis显式板级集成”的路径；需要自动化时再基于实际平台适配，不另造一套控制算法。

## 4. 从Simulink到MPSoC的两条生成链

```text
统一MIL与参数基线
        |
        +-- R5软件模型 -- Embedded Coder --> C/H
        |                                      |
        |                          R5平台/BSP/调度/接口适配
        |                                      |
        |                                Vitis编译链接
        |                                      |
        |                                  R5 .elf
        |
        +-- PL定点电流模型 -- HDL Coder --> SystemVerilog/IP
                                               |
                                 Vivado硬件设计/综合/布局布线
                                               |
                                  PL bitstream + 硬件XSA
                                                       |
                                             交给Vitis建平台
```

**C/H是源代码，ELF才是给处理器装载的目标程序；SV是硬件描述，bitstream配置PL电路；XSA描述硬件平台，连接Vivado与Vitis，不是第三份控制算法。** Vivado可导出包含bitstream的XSA，Vitis也支持某些软件开发阶段先使用不含bitstream的硬件描述，R5软件准备不必等全部PL实现完成。[S4][S5]

### 软件链：R5侧

1. 从已经可运行的外环/轨迹/对齐模型出发，保留原离散状态与采样关系。
2. 将代码生成目标从Windows主机切到适合R5的配置，生成C/H；当前主机代码中的处理器相关优化不能原样假定适用于ARM。数据类型、FPU/编译选项以目标工程核实，不为迁移擅自把所有double改single。
3. 在Vitis中由实际XSA建立R5 standalone平台/域，接入BSP、启动代码、链接脚本、周期任务、中断及PS—PL读写。
4. 初始化算法一次；由确定的调度调用生成step。当前软件基础周期100µs，内部速度/位置周期1ms/10ms；不要因为主循环很快就不受控地反复step。
5. 编译生成R5 ELF，板上再测实际执行时间、抖动与中断/通信开销。PC C能运行并不证明这些指标满足。

软件任务不仅是复制生成C到Vitis目录：还必须让它读到正确反馈、在约定时刻执行、提交正确格式的参考。这些薄平台代码和驱动在模型外集成，不手改生成的控制算法。[S3][S5]

### 硬件链：PL侧

1. 复用已有定点FOC模型、p3运算与流水线成果；研究新电流算法时在这一边界替换。
2. 由HDL Coder生成RTL/IP，在Vivado连接PS、总线、采样/位置接口、时钟复位、占空比更新和真实PWM/快速禁止。
3. 使用实际AXU5EVB-E器件和约束综合、布局布线，检查资源与关键路径，再生成bitstream；旧Artix-7结果不能直接作为5EV结果。
4. 导出XSA供软件侧建立对应平台。可以使用生成IP接口，也可在外部添加小型寄存器/握手适配；两者都要符合原控制时序，不为接口方便破坏算法状态递推。[S1][S4]

### 两边怎样协同

R5与PL通过AXI寄存器/BRAM等适合实际数据量的接口交换命令和反馈。初版以清晰的低带宽控制交换为目标，不预先引入大吞吐DMA框架。多字段参考在明确边界共同生效，反馈是同拍快照；并处理不同数据类型、字宽、方向和单位。仿真的20/41字段double向量不能直接当作已完成的AXI协议。

当前功能联合仿真把软件计算和交换视为零执行时间。实机必须重新安排“采样→读取/计算→参考提交→电流计算→PWM应用”各事件，记录可能引入的附加延迟。保持100µs电流周期和现有50µs应用边界是设计起点，不是未经测量就保证成立；不得既遗漏真实延迟，又重复增加已存在的等待。

## 5. 从功能仿真到实机的实施顺序

| 阶段 | 工作重点 | 该阶段的完成含义 |
|---|---|---|
| 当前收尾 | 默认点位、PI复位、Ready/Send交互、单一入口与目录 | 使用者按说明可以正常发目标；C/RTL对应关系清楚 |
| 目标平台 | B-E硬件设计、R5 standalone、正确目标C编译及PL重定向 | 有适合实际芯片的软硬件工程，不只是Windows MEX |
| 软硬件通信 | R5周期调用、PS—PL命令/反馈、实际时限 | 真实处理器和PL能按约定交换，不依赖PC软件做外环 |
| 采集与输出 | ADC、位置尺、电角度、PWM/死区、驱动使能及故障路径 | 实际接口的方向、电平、量程、时序可用 |
| 电机实验 | 先验证正确采集/输出与原PI-FOC，再比较研究算法 | 真实运动及电流效果可测量、可解释 |

上述是功能路线，不要求为每个小块另开一轮规划PR。任务可以成组完成；普通Git提交和PR审查即可。硬件下载及功率级上电仍须明确授权，不从文档或仿真通过推定可以直接带电机运行。

## 6. 实验目标与比较指标

| 实验目标 | 主要观察量 |
|---|---|
| 建立可靠PI-FOC基线 | dq参考/反馈、位置/速度、控制状态、默认死区、对齐与连续点位 |
| 比较电流控制效果 | 跟踪误差、峰值/均方根误差、动态响应、超调、稳态纹波 |
| 研究扰动抑制与适应性 | 负载变化、运行速度及参数变化下的电流/运动误差与恢复过程 |
| 评估实现代价 | PL资源/时序/采样到应用延迟，R5任务执行时间和抖动 |
| 支持后续运动算法 | 在保留PL电流接口的情况下替换R5速度/位置/轨迹算法 |

这些是实验方向，不是新设定的数值验收门槛。比较应注明电机参数、负载、外环、采样周期、调制、死区和限幅条件；不要在改变多项条件后把差异全部归因于电流算法。当前带光栅尺/磁栅尺的反馈方向不变，无感算法不是默认范围。J-MAG/Maxwell等电磁对象可后续替换仿真对象，不作为当前先修命令交互的前置条件。

## 7. 当前已完成、待修与尚未建设

依据项目PR5/PR7/PR9及用户2026-10-26反馈：

- **已有成果：** MIL基线、独立定点FOC与p3 RTL、R5侧控制/轨迹/原对齐模型、主机生成C与实际RTL功能联合仿真；PR9给出输入字段错位修复、默认10mm与C连续目标/复位结果。用户最新backend=0截图显示10/20mm段及30mm段跟随开始，不能由此推定30mm已经到位或C/RTL都完成新验收。
- **当前修补：** PR9复验保存目录的小缺陷；旧MEX升级一次性重建提示；用户真实操作的Ready/Send受理与Busy显示变化需要定位。`Host_Close_Loop_EN`是速度闭环使能，发送是`Host_Move_Request`，先澄清绑定和采样事件，不能拿模式开关代替发送。
- **尚待覆盖：** 修复后的完整RTL默认点位/到位，及实际交互反馈；213帧短RTL记录约21.3ms，不能替代轨迹开始后的完整运动。当前函数Ready可因位置离开窗口清零；Busy并非Ready的反相，不会仅因位置纹波重新置1。
- **后续平台工作：** R5目标编译/周期实测、真实AXI/CDC、5EV布线、ADC/位置尺与门极/保护集成。这些是尚未建设的功能，不统称当前软件bug。

不以旧阶段通过记录覆盖新问题；也不因为换了平台重做已经验证的PI/FOC。保留简短分段注释、紫色功能区域及单一参数入口。不追加哈希清单、快照报表、防御性基础设施或冒烟；验证限于实际改动和正常使用。

项目依据：[架构分工](ARCHITECTURE.md)、[PS—PL接口](../integration/ps_pl/INTERFACE.md)、[PR7](https://github.com/kazecode666/AXU5EV/pull/7)、[PR9与最新交互反馈](https://github.com/kazecode666/AXU5EV/pull/9)、[Issue #8](https://github.com/kazecode666/AXU5EV/issues/8)。此文不修改算法或声明已经完成板上运行。

## 8. 官方流程参考

官方资料用于说明工具机制，项目已完成状态来自仓库报告，二者不能互相代替。

- **[S1] MathWorks：Targeting FPGA and SoC Hardware Overview** — 软硬分区、处理器可执行程序与PL bitstream、定制板卡平台。https://www.mathworks.com/help/hdlcoder/ug/targeting-fpga-amp-soc-hardware-overview.html
- **[S2] MathWorks：Generate IP Core with AXI4-Lite Interface** — Zynq UltraScale+示例的IP/软件接口流程；示例针对ZCU102/A53，不代表AXU5EVB-E/R5F直接支持。https://www.mathworks.com/help/hdlcoder/ug/getting-started-with-hardware-software-codesign-workflow-for-zynq-ultrascale-mpsoc-devices.html
- **[S3] AMD UG1137（2026.1）：Bare Metal Software Stack** — R5F standalone BSP与外设软件基础。https://docs.amd.com/r/en-US/ug1137-zynq-ultrascale-mpsoc-swdev/Bare-Metal-Software-Stack
- **[S4] AMD UG1209（2026.1）：Exporting the Post-Implementation Hardware Platform** — bitstream及XSA导出。https://docs.amd.com/r/en-US/ug1209-embedded-design-tutorial/Exporting-the-Post-Implementation-Hardware-Platform
- **[S5] AMD XD260（2026.1）：Create Platform** — 从Vivado XSA建立Vitis平台、domain/BSP和启动环境。https://docs.amd.com/r/en-US/Vitis-Tutorials-Embedded-Software/Create-Platform
