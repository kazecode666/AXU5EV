# AXU5EV 厂商资料筛选与使用指南

状态：2026-10-25 **仅依据用户提供的 `readme_资料目录.txt` 目录说明完成筛选**。实际 PDF/RAR/ZIP 尚未在此审阅、核对许可或上传；版本、器件和板卡接口尚未确认。本文件是本项目原创索引，不是原厂文档的复制件。

## 目标平台

- **R5F / PS**：位置/速度环、原对齐状态机、参考/轨迹、命令和系统管理，初版优先裸机周期任务。
- **PL**：电流环 FOC、采样接口及位置数据锁存、实时电角度、PWM/死区和快速故障禁止。
- **算法源**：Simulink/Stateflow；PS目标生成/集成 C、PL目标生成 HDL。厂商应用工程仅作板级配置和接口参考，不替换已接受电流算法。

## 按研发阶段分级

| 目录/资料 | 优先级 | 针对本项目要查的内容 | 建议仓库处理 |
|---|---|---|---|
| `00_hardware.rar/01_原理图结构图等硬件资料` | P0 | 核心板和底板修订、PS/PL Bank及电压、外部时钟、PS/PL管脚/板间插座、JTAG、启动模式和保护电气接口 | 摘要、文件哈希与精确版本优先；原理图仅在许可允许时再精选入库 |
| `00_hardware.rar/02_芯片手册` | P0 | DDR、QSPI/eMMC、时钟、PHY、接口电平及其官方规格引用 | 芯片型号/链接/版本索引；原厂第三方芯片手册不默认上传 |
| `xx用户手册.pdf` | P0 | 具体AXU5EV底板**完整后缀/修订**、完整ZU5EV料号、扩展口与时钟/PS配置说明 | 精准型号、页码、链接、SHA/版本索引；是否可上传原件单独核查 |
| `course_s2_ALINX_ZYNQ_MPSoC开发平台Vitis应用教程Vxx.pdf`＋`course_s2.zip` | P0 | PS/RPU时钟与复位、Vitis裸机BSP、R5F `standalone`、周期中断、GIC、PS—PL AXI、DMA、UART和缓存/内存映射 | 优先提取相关章节、工程/例程索引；**不得假定示例目标就是R5F** |
| `course_s1_ALINX_ZYNQ_MPSoC开发平台FPGA教程Vxx.pdf`＋`course_s1_fpga.zip` | P0 | PL时钟/复位、IO/XDC、AXI-Lite、BRAM、硬件中断、仿真/综合/时序、ADC/编码器适配可用的接口示例 | 选择相关demo、约束来源和工具版本，不将旧XDC盲套新板 |
| `factory_file/factory_vivado.zip` | P0参考 | 原厂PS配置、BD、PL时钟、AXI映射、reset以及引脚；对比目标Vitis/Vivado可复现性 | 默认本地参考，不整包入Git；不能直接当作2026.x工程 |
| `course_s0_Xilinx开发环境安装教程.pdf` | P1 | 安装顺序、工具组件和厂家支持版本 | 索引及安装要点，不上传安装包 |
| `配套模块` | P1条件 | 若实际存在ADC同步采样、RS422/LVDS位置编码器、SPI、隔离、CAN/RS485等模块，优先检查电平/时序/引脚 | 按实物与资料是否匹配决定，**目录本身并未证明这些模块存在** |
| `course_s6_MPSOC开发平台HLS教程Vxx.pdf`＋`course_s6.zip` | P1可选 | HLS IP/AXI与软硬协同示例 | HLS与HDL Coder不同，暂不作为电流算法必需项 |
| `lwip例程专用库文件.zip` | P2可选 | 如将来R5F/PS与上位机通过以太网交换数据才核对接口及版本 | 本地索引；不提前集成 |
| `course_s2_addition.zip` | P2可选 | eMMC测试，后续如需日志或参数持久化时参考 | 本地索引 |
| `factory_file/xx出厂bsp.rar`、`xx出厂SD卡镜像.rar`与恢复PDF | P2保底 | 出厂恢复/启动配置参考，辨别是否属于A53 Linux/PetaLinux路径 | 备份在本地，不上传镜像、不当R5F standalone BSP |
| `course_s3/s4/s5` PDF＋工程 | P3 | Linux/PetaLinux/驱动与GUI；当真需要A53 Linux时才用 | 仅索引 |
| `xx_AI.rar`、`vcu_demo.zip` | P3 | AI加速/视频编解码，当前无直接关系 | 不迁移 |

## 首先必须确认的板卡事实

1. **板卡丝印、完整销售型号与底板修订**：厂商公开资料存在 AXU5EV-E、AXU5EVB-E、AXU5EV-P 等不同变体。不要以产品名“5EV”猜底板接口与约束。
2. **芯片完整型号**：从实际核心板/原理图/包装核验 ZU5EV 的封装、速度等级、温度等级；外网手册中提及的型号只能用于交叉核对。
3. **R5F运行基础**：R5 split/lockstep、启动核选择、TCM/OCM/DDR、时钟/复位、GIC中断、Vitis `standalone` BSP、PS—PL总线与缓存一致性。
4. **实时反馈接口**：电流ADC的类型/转换时序/隔离，磁栅尺/光栅尺接口（ABZ、SSI、BiSS、EnDat等仅是候选协议，必须核对实际传感器），Bank电压/差分收发器/电平匹配。
5. **50 μs应用边界**：保留100 μs电流周期、1 ms速度环、10 ms位置环作为当前算法合同；新增AD转换、位置采样与PS—PL交换时间后重新计算最坏时延。
6. **保护链**：驱动器硬件故障输出、PL异步/快速禁止、R5恢复管理分层；不据厂商demo推定已有功率级保护。

## 版本与复用约束

厂商readme称其教程使用 **Vivado 2020.1**，并提示其他版本不予技术支持；目前AX-00验收记录使用 MATLAB R2026b、Vivado/xsim 2026.1。不要将旧BD直接作为新工程签核，不在用户原厂工程中原位升级；应保留原字节参考，核对IP/PS配置后在目标工具生成独立工程并复验接口、频率及约束。

AMD UG1137（2026.1）明确 `standalone` BSP 支持 RPU/R5F 的裸机软件栈；这不证明ALINX `course_s2` 的所有例程都可直接在R5上运行。来源： https://docs.amd.com/r/en-US/ug1137-zynq-ultrascale-mpsoc-swdev/Bare-Metal-Software-Stack

厂商公开手册存在多个版本，可用于**核对型号而不是选定型号**：
- https://www.alinx.com/public/upload/file/AXU5EV-E_User_Manual.pdf
- https://www.alinx.com/public/upload/file/AXU5EVB-E_User_Manual.pdf
- https://alinx.com/public/upload/file/AXU5EV-P_User_Manual.pdf

## 上传与版权

- 只上传本项目撰写的接口摘要、参数映射、文件索引、SHA-256、使用说明及版权允许的小型必要例程。
- 对采购所得原厂PDF、RAR、ZIP、出厂镜像、第三方数据手册和二进制IP **默认只建索引，不上传原件**。Private仓库不自动授予再分发权；许可不明确应征询厂商或保留本地。
- 对确实需要复现的第三方文件，确认许可、版本、体积和安全性后，按文件精选；保持原署名、必要许可信息，必要时考虑Git LFS。不要提交密钥、完整安装包、超大镜像及个人绝对路径中的敏感部分。
- 每项记录：原文件名、实际相对路径、大小、SHA-256、板卡版本、厂商版本、用途/优先级、许可、处理方式（INDEX_ONLY / LOCAL_ONLY / APPROVED_COPY / EXCLUDE）以及测试状态。未检查内容标 `NOT_INSPECTED`。

## 后续执行

见 [AX-00B 本地资料核查任务](../coordination/tasks/ax00b_alinx_vendor_materials_intake.md)。此阶段只核查和精选归档，不直接启动AX-01固件生成、部署、引脚约束设计或上电。
