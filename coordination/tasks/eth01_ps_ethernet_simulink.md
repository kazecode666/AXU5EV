# 下一实施PR任务书：PR17 / ETH-01 — JL2121 PS以太网与Simulink最小通信接口

> 执行者：本地Codex；架构与Review：ChatGPT；实物核对、接线、板上运行和最终合并：用户。
> PR16已合并。本评论作为下一阶段任务交接，不重开PR16。PR17尚未创建，实际编号以GitHub为准；不要为任务书另开纯文档PR或占用新Issue编号。

**Goal：** 在AXU5EVB-E的Cortex-R5 #0 standalone环境建立可复用的JL2121/PS GEM TCP通信基础，并验证最小Simulink模型可以通过该基础交换数据，为后续替代JTAG大数据传输准备接口。

**Architecture：** Simulink是算法和实验接口的主要入口；PS GEM/JL2121/lwIP是平台服务；Vivado提供匹配板级连接的XSA，Vitis完成R5构建与调试。优先复用本机已安装、适合本目标的MathWorks模块；部署支持不足时才增加薄封装，不重新实现协议栈。网络服务与未来100µs控制step分开。

**Tech Stack：** 现有MATLAB/Simulink/Embedded Coder，SoC Blockset for AMD及相关支持包按本机实际安装核对；现有Vivado/Vitis 2026.1；R5 standalone、AMD BSP/lwIP Raw API、PS GEM、JL2121；PC测试工具优先Python标准库。

**版本化任务书：** 执行时将本任务保存为 `coordination/tasks/eth01_ps_ethernet_simulink.md`，与实现一起提交。

## 0. 起点、范围与硬边界

- 仓库 `kazecode666/AXU5EV`，本地 `D:/Project/AXU5EV`。检查时PR16 merge commit为 `24d86097bfd83abef28047dafd2594ee89a707db`。从包含该合并的当前main建立正常实现分支，建议 `codex/eth01-ps-ethernet`；不强制回退、不另clone/worktree、不覆盖用户本地修改。先读AGENTS/HANDOFF，将顶部过期的“PR16待合并”更新为实际状态，历史记录保留。
- PHY统一 **JL2121**。手册前部KSZ9031R是用户已确认的错误，不按KSZ9031R初始化。已有 `ACU5EV核心板原理图.pdf`、`AXU5EVB-E开发板原理图.pdf`（与AXU3EG底板共用）、用户手册和ALINX例程；优先查本地资料和索引，不让用户重复提供。JL2121型号确认不等于FPGA完整料号/PCB修订已签核。
- 不更换R5为A53/Linux，不增加FreeRTOS、R5_1、AMP、PL以太网MAC、AXI DMA或电机功率输出。A53只保留与新XSA匹配的FSBL启动辅助。
- 保留 `.runtime/ax02a/vitis_runtime_100us_r1`、原XSA/ELF/FSBL、模型参数、生成C/SV及全部板测数据；不覆盖/重建R1，不重跑完整motion/alignment、TTC ABA或旧RTL。新产物集中 `.runtime/ethernet/eth01/`；已有目录不得覆写。
- 不直接修改Vitis/MATLAB安装目录、厂商原件或全局配置；驱动适配通过项目内受控源码/库配置纳入构建并保留许可。不自动安装/升级/降级工具或支持包。
- MATLAB/Simulink沿用MCP，不使用Computer Use，不保存用户未保存模型、不关闭全部模型、不递归genpath。
- **Codex只自动执行离线核对、编程、仿真、测试和构建；不得探测/连接/复位/暂停/恢复/读写/下载/运行开发板，也不运行客户端探测板卡。** hw_server、真实网络连接和Windows测试网卡修改由用户操作；主机回环测试仅限显式localhost。
- 不写QSPI/eMMC/SD，不操作功率级，不全局关闭防火墙，不自动合并PR、不关闭Issue15。

### 本PR做到哪里

**包含：** 板级核对、SoC现成块适配矩阵、独立R5以太网工程、小数据通信、专用测试缓冲区大数据传输、最小Simulink通信模型的仿真/代码生成/目标构建，以及用户手动板测与真实结果归档。

**不包含：** 网络接入完整电机Runtime、重新验收100µs控制并发性能、在线示波器/GUI、External Mode/XCP、远程任意内存访问、正式电机控制命令、真正ADC/QEP/PWM/AXI外设实现、完整SoC Builder自定义支持包。ADC/PWM/AXI/任务管理本轮只针对性评估复用，不改当前控制模型。

## 1. Review重点

1. 型号正确但PHY地址/复位/RGMII延迟配错：不能用链路灯代替识别和有效收发。
2. 块能仿真/生成C但目标为APU/Linux：不能宣称已适配本板R5 standalone。
3. TCP分片、粘连、短读写、背压、断线：不得丢字节、重复提交或将未完成文件标为成功。
4. GEM DMA缓冲区、cache/MPU、网络定时器和中断所有权：不能隐式改变R1或侵占未来控制TTC。
5. Host/MEX通过冒充ARM实测，或暂停R5却期待同核TCP服务：状态和操作流程必须正确。

## 2. 建议文件与职责

优先复用已有等价入口；调整命名需在交接中给出唯一实际路径。

| 文件/目录 | 职责 |
|---|---|
| `coordination/tasks/eth01_ps_ethernet_simulink.md` | 版本化任务书 |
| `coordination/reports/eth01_platform_and_soc_reuse.md` | 板级依据、复用矩阵、方案选择与阶段结果，避免大量重复报告 |
| `hardware/axu5ev/eth01_ps_ethernet.tcl` | 独立以太网候选XSA |
| `firmware/r5/ethernet/` | 独立应用/配置、GEM/lwIP适配、必要JL2121适配、协议；已有BSP足够则不写重复PHY驱动 |
| `integration/r5_ethernet/` | 模型窄接口、目标适配与Host仿真后端 |
| `simulation/ethernet/` | 最小测试模型、必要薄封装库、生成/测试入口 |
| `scripts/eth01_build.py` | 离线构建、纯文件启动检查，复用已有方法而非复制整个旧工程 |
| `scripts/eth01_client.py` | 用户显式运行的PC测试客户端 |
| `tests/test_eth01_*.py`及对应C/模型测试 | 仅新增协议、队列、配置和模型接口相关验证 |
| `firmware/r5/ethernet/FIRST_BOARD_RUN_ZH.md` | 实际GUI路径、网口/网卡、停点及失败边界 |
| `verification/ethernet/eth01/` | 精简状态与构建/测试/板测摘要；大数据和生成物留.runtime |

## Task 1 — 硬件资料与本机工具核对

**输入：** 本地原理图、用户手册、ALINX例程、主线脚本与实际安装环境。
**输出：** 有来源的配置表，后续实现从该表落实，不猜常见值。

- [ ] 核对PS网口连接器/实物位置、GEM实例、RGMII/MDIO/MDC的MIO、电源/IO电压、时钟、PHY复位来源/极性/时序、strap/MDIO地址、收发延迟配置与中断方式。给出原理图页码、网络名或例程路径；未知项明确列出。
- [ ] 对照ALINX JL2121初始化、本机BSP/lwIP源码及PHY资料，确定识别寄存器、地址和速度协商处理；记录ID/修订掩码依据，不抄KSZ9031或其他PHY厂商寄存器序列。
- [ ] ALINX A53旧例程不能仅改核名成为R5工程；核对R5中断、ABI、链接、cache/MPU和2026.1 API。FPGA器件选项沿用当前有记录依据，不宣称解除旧物理签核项。
- [ ] 记录MATLAB release、已安装产品/支持包、Vivado/Vitis/BSP/lwIP版本。网上文档可能为R2026b，不据此推断本机相同；SoC Builder认可的Vivado版本与本机2026.1分别列出。
- [ ] 关键板级信息存在无法消解的矛盾时停下受影响配置并报告，不试写寄存器；无关主机协议测试可继续。

**验收：** 关键参数可追溯，硬件运行全部NOT_RUN。

## Task 2 — SoC Blockset现成模块优先评估

**输入：** 本机版本和实际块、对应官方文档。
**输出：** 复用矩阵与通信模型的单一实施选择。

- [ ] 检查TCP/UDP Read/Write、IO Data Source/Sink、Task Manager、Hardware Interrupt/Interrupt Channel、Register/Memory Channel、AXI相关读写块、ADC Interface/ADC Read、PWM Interface/PWM Write。QEP若有现成块，核对其输入/目标，不能把计数值输入当A/B/Z引脚解码。不全库扫描。
- [ ] 逐项填写：实际库路径/版本、仿真功能、C/HDL生成能力、支持CPU/OS/参考设计、本板尚缺的驱动/IP、实际最小验证、用于本轮或后续。分类为直接可用/仿真可用但部署需适配/暂不适用/未核实，不只写“支持”。
- [ ] 区分TCP消息端口与真实socket、Hardware Interrupt仿真端口与实际ISR映射；不能把AXI Manager主机访问当R5驱动。ADC/PWM Interface可建模采样转换与触发，但不自动提供任意外置ADC RTL或安全三相PWM。
- [ ] 标准通信块若真正支持本机R5 standalone与调度，则优先采用并提交生成源/目标编译证据；若仅APU/Linux等支持，则保留适合的仿真块，目标用C Caller/Legacy Code Tool薄封装。不改变R5架构迁就块，也不默认全部自造。
- [ ] 不迁移现有控制模型，不以Task Manager调度覆盖原TTC，不自动安装不同工具链；有需要作为后续选项列明。

**验收：** 选型有证据；不把仿真成功当部署成功，也不因部署限制否定模块的仿真价值。

## Task 3 — 独立PS以太网平台和R5底座

**输出：** 新XSA、匹配A53 FSBL、R5 BSP/ELF/map、可重复构建与纯文件检查。

- [ ] 从已验证PS/DDR配置最小扩展确认的GEM/MDIO/MIO及必要复位/时钟；不改变旧R1构建行为、不下载PL。资料若证明额外PL逻辑必需，报告而不擅自扩展。
- [ ] RPU split、R5 #0应用；A53仅执行匹配FSBL。核对实际ELF架构与launch路径，避免历史FSBL核选择错误；workspace/launch明确使用ethernet名称。
- [ ] 使用本机匹配的lwIP Raw API及有依据的JL2121适配，项目内可重复构建；未知PHY、MDIO失败、协商超时均有明确错误，不无限忙等、不静默套另一型号。
- [ ] GEM中断、网络时基、GIC初始化只有明确所有者；不将控制TTC0通道0/1用作未经记录的网络定时器，不在本PR声称通过并发实时性。
- [ ] 首版优先I-cache ON/D-cache OFF，不以开cache掩盖问题。检查GEM DMA描述符/缓冲区地址、对齐、MPU、可达性、屏障、所有权、栈堆及测试DDR区；确需不同条件单列候选理由，不改R1。
- [ ] MAC配置明确、测试网段唯一；使用有依据的地址或明确的本地管理单播地址，不照搬冲突demo地址。固定IP/端口可配置；候选PC192.168.50.1、板192.168.50.10/24、TCP5001，用户确认无网段冲突后使用。

**验收：** 真实R5离线构建及启动文件检查通过，给实际产物/日志；板卡连接仍NOT_RUN。

## Task 4 — 可复用通信接口、客户端与完整性

**输出：** 小数据与专用测试缓冲区批量传输，不是任意内存远程调试器。

- [ ] 分开平台、协议、模型接口和服务循环，不全塞入main。模型仅见固定容量字节数组、len/valid/seq/status，不见pcb/pbuf或PHY寄存器。
- [ ] 薄封装至少有Init、非阻塞RxTryPop/TxTryPush、GetStatus和独立NetService；模型载荷最大256字节，len=0..256。有界复制、满队列/断线显式返回，不等待ACK。NetService在独立服务循环，不进入未来Runtime_step。
- [ ] 先固定最小协议契约：版本、类型、传输/序列号、字节序、长度和内容校验；分块需总长度/位置。C/Python/模型共用契约，不裸传带填充结构体，不做通用RPC/文件系统。
- [ ] TCP按字节流处理：分片/粘连、pbuf链、短读写、ERR_MEM/背压、发送缓冲区生命周期、lwIP回调约束；一条完整命令只提交一次，断线重连不得复用未完成消息。
- [ ] 客户端仅用户明确运行并给目标IP时连接；import/test/build/model-load不连板。主机测试只localhost，不扫描网络、不改网卡/防火墙。
- [ ] 小数据后准备64KiB、1MiB、32MiB确定性数据上传/读回。按新链接布局定义专用测试DDR区及边界，有界分块；不栈上大数组、不无限分配、不读写历史实验区或任意地址。
- [ ] 总长度与完整内容核对，可用CRC32与已知模式检查；这仅针对传输完整性，不做全库哈希。中断保留.partial，长度/校验/完成状态均对才形成最终文件，不覆盖既有结果。
- [ ] 记录方向、字节、耗时、有效吞吐、协商速率、cache条件、错误。1MiB/s为首版目标而非承诺；不达标报告瓶颈，不减少校验冒称通过。

**测试要求：** 相关负例先失败后修正：帧头/载荷分段、多帧粘连，模型len=0/1/255/256/257，错误版本/长度/校验，截断文件，断开重连，慢接收端/满队列。不跑旧全库回归。

## Task 5 — 最小Simulink通信模型与目标代码集成

**输出：** 真正用于证明“模型→R5→网络”的最小模型，不是库图标展示。

- [ ] 独立simulation/ethernet测试模型，不改控制SLX/生成算法。收到有效测试消息后，将前len字节异或0x5A，原seq返回，并递增模型处理计数器。处理逻辑必须来自模型生成代码；平台层不能做同样变换伪装模型执行。
- [ ] 固定256字节数组及len/valid/seq/status；无新消息不重复处理，越界拒绝且计数不增；背压用有界待发送状态，不阻塞、不静默丢已接受请求。Host与目标语义一致。
- [ ] Host后端提供可控消息/队列，不读目标寄存器；适合时复用SoC IO Data Source/Sink、任务/通信建模块，明确消息模拟与真实socket区别。目标块按Task2结果选择，不强载APU/Linux设计。
- [ ] 完成模型更新、确定性仿真、实际代码生成、生成代码链接进R5 ELF，并检查调用链，不能只运行手写echo。使用独立测试调度，不当作100µs控制实时性证据。
- [ ] 明确仿真/生成/目标后端切换入口，优先用MATLAB入口串联构建；不做完整支持包或一键远程下载。
- [ ] 产品/编译器依赖缺失如实标记，不用Constant、空壳、未调用生成代码或Host通过冒充目标完成。

**验收：** 模型仿真、代码生成、ARM链接分别给证据；模型板上往返仍NOT_RUN，待用户执行。

## Task 6 — 离线完成后交付停点，用户手动上板

Codex完成Task1—5可完成的离线实现、测试和指南后提交推送，创建一个实现Draft PR（计划PR17）；先Review，再用户逐步板测。不得自动从构建进入实板。

指南必须含实际workspace/application/launch/ELF/FSBL及以下步骤：

1. 功率级断开；确认PS网口，网线/JTAG/PS UART连接。用户核对测试网卡/IP，不动其他网卡/VPN，不全局关闭防火墙。
2. 用户启动新应用，串口确认R5、构建身份、cache、GEM、PHY地址/ID；失败保存日志并停，不盲试寄存器。
3. 用户确认link up、实际速率/双工及必要ping；灯亮/ping不能替代TCP。百兆按百兆记录，不冒称千兆。
4. 用户小数据TCP测试，再验模型生成代码完成的异或往返、seq和处理计数，不只验手写echo。
5. 用户逐次64KiB→1MiB→32MiB并记录完整性/吞吐，再受控断线重连；首次异常保存并停，不自动重试凑PASS。
6. R5持续运行才能提供同核TCP服务；**不能停在R5完成断点后还要求下载**。调试暂停造成超时，不误判PHY失效。

用户回传日志后，Codex只读分析并归档。状态分 `DOC_CHECK/HOST_TEST/MODEL_SIM/CODEGEN/R5_BUILD/STARTUP_CHECK/PHY_LINK/TCP_IO/MODEL_BOARD_IO/BULK_TRANSFER`，未执行逐项NOT_RUN。HOST与BOARD分目录，测试载荷不得改名为电机实测。

## 3. 最终验收与后续边界

离线交接须具备：板级依据、SoC复用矩阵、新XSA/R5构建、协议负例、模型仿真/生成/目标链接、分步指南、实际路径与限制。

最终验收须用户实测：JL2121识别和链路、TCP小数据、模型真实往返、测试DDR大数据完整性及失败处理，并说明吞吐目标是否达成。不能把建立TCP连接等同替代全部JTAG实验流程。

**下一阶段**才接完整Runtime：输入装载→停用网络DMA/中断/维护时基→100µs自主回放→停计时/冻结结果→恢复网络并重新连接→导出原run/output/timing/report格式。新候选需重新验证数值/时间，不拿R1 PASS为新ELF背书。本PR仅记录边界、不实现完整控制集成、不重复旧两场景。

**交接返回：** 分支/实际提交SHA、已做/未做、测试及退出码、SoC块选择依据、构建路径、用户下一步唯一入口、真实阻塞项。保持Draft待Review，用户决定合并，Issue15未覆盖项保留。

## 4. 官方依据（须再对照本机版本）

- [SoC模型结构](https://www.mathworks.com/help/soc/ug/soc-blockset-model-structure.html)：顶层/FPGA/处理器模型和Channel，当前处理器示例为APU。
- [TCP Read](https://www.mathworks.com/help/soc/ref/tcpread.html)、[TCP Write](https://www.mathworks.com/help/soc/ref/tcpwrite.html)：模拟消息端口与实际生成实现需要区分。
- [Task Manager](https://www.mathworks.com/help/soc/ref/taskmanager.html)、[Hardware Interrupt](https://www.mathworks.com/help/soc/ref/hardwareinterrupt.html)。
- [ADC Interface](https://www.mathworks.com/help/soc/ref/adcinterface.html)、[PWM Interface](https://www.mathworks.com/help/soc/ref/pwminterface.html)。
- [支持工具/板卡与自定义参考设计](https://www.mathworks.com/help/soc/ug/supported-third-party-tools-and-hardware.html)：与本机2026.1的兼容性必须核对，不擅自换版本。
- [设备驱动封装](https://www.mathworks.com/help/rtw/ug/device-driver-io.html)：C Caller/Legacy Code Tool。
- [AMD 2026.1 lwIP支持](https://docs.amd.com/r/en-US/oslib_rm/Introduction)、[网络时基与GEM内部DMA](https://docs.amd.com/r/en-US/oslib_rm/Setting-up-the-Hardware-System)。
