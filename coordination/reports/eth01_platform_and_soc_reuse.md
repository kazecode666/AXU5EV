# ETH-01：PS Ethernet / SoC 模块复用与离线实现

2026-11-02，`kazecode666/AXU5EV`，任务来源 [PR16 评论6574356461](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6574356461)。基线 `origin/main=24d86097bfd83abef28047dafd2594ee89a707db`，PR16 已合并。实现分支 `codex/eth01-ps-ethernet`，协议为 **TCP**。

最新修正按[PR17评论6576959934](https://github.com/kazecode666/AXU5EV/pull/17#issuecomment-6576959934)：r2用户实板读出ID=937c4032后报PHY_FAIL code=6。本轮只把reg5/reg10伙伴广告位检查改为page0xA43/reg0x1A的PHYSR bit3实际双工状态，打印PHYSR/速率/双工，半双工仍拒绝。新候选vitis_ethernet_r3、sw_repo_r3、build0x45303103、launch eth01_tcp_manual_r3已离线编译及原有启动检查通过；r3板测NOT_RUN。下文r2构建/16项Host/模型结果为此前归档，本轮未重跑测试或生成模型。当前入口以唯一上板指南为准。

## Task1：本地板级证据

厂商原件均在 `资料/`，不提交原件。只针对所需页面提取文本并目视核对底板第7页；提取/渲染在 `.runtime/ethernet/eth01/recon/`。

| 参数 | 本次依据与实施 |
|---|---|
| PS 网口 | `00_hardware/01_原理图结构图等硬件资料/底板/AXU5EVB-E开发板原理图.pdf` 第7页 `PAGE07 PS Ethernet1`：J6/GE_RJ45、U5/JL2121；第8页为PL口，不使用。图框AXU3EG为已确认共用底板资料，不据此否定 |
| 核心连接 | 底板第3页PS_MIO网络，`核心板/ACU5EV核心板原理图.pdf`与用户手册第31—32页连接器映射；用户手册第37—39页Ethernet表 |
| MAC/RGMII | GEM3 `0xff0e0000`；TXCK64、TXD0—3=65—68、TXCTL69；RXCK70、RXD0—3=71—74、RXCTL75 |
| 管理接口 | MDC MIO76、MDIO MIO77；1.5k上拉至PHY1_IODVDD；固定地址1，不做地址扫描或fallback |
| 电源/时钟 | 第7页PHY1_IODVDD=1.8V，AVDD33=3.3V，V_SEL=10；Y1=25MHz；GEM3参考IOPLL约124.998749MHz（配置125MHz） |
| 复位 | 第7页RSTn低有效，经D9与PS_POR_B耦合，R35=100k/C36=10µF；无独立PS GPIO复位。名义RC约1s不能当精确复位释放时序；未有JL2121完整时序规格，实际释放时间/电压未测。软件不盲试GPIO或强制重配延迟；用户冷上电后至少等待稳定再启动，识别失败即停 |
| straps/延迟 | 手册第37页表3-5-1：地址001，RXD1_TXDLY/RXD0_RXDLY均2ns；第7页R105/R102上拉、R104/R101不装。XSA/SDT为rgmii-id，保留strap，不叠加另一个型号的延迟序列 |
| PHY中断 | INTB/WOL网络PHY1_INT_N有上拉，未见本工程所需PS中断映射；不启用PHY IRQ。GEM DMA IRQ由AMD SDT驱动安装 |
| 型号纠错 | 手册前部KSZ9031R与同手册Ethernet章节不一致；用户确认实物JL2121，第7页U5明确JL2121。只采用JL2121适配 |

JL初始化依据为本地 `资料/2020.1版本lwip例程专用库文件.zip` 中 `lwip211_v1_2/src/contrib/ports/xilinx/netif/xemacpsif_physpeed.c` 的 `get_phy_speed_JL2121`：ID1=0x937c，page0xa43/reg0x1a读速率、page-select reg0x1f。本次不复制其无界reset等待、不需要的LED写入或整个A53例程。

完整ID/修订掩码参考PHY驱动作者的[上游提交说明](https://lists.openwall.net/linux-kernel/2026/10/21/2205)：0x937c4030、mask0xfffffff0，JL2101与JL2121共享model，只靠这个mask不能区分两者；板型/BOM/用户确认选择JL2121。该来源是作者patch说明，**不是本板实测或已合并驱动声明**。现场若ID不匹配停止，不宽掩码碰运气。标准BMCR启动自协商、双读BMSR，最多300×100ms；所有MDIO返回检查。速率取ALINX的JL专页，标准partner能力用于拒绝半双工。本板实际ID/修订、复位时序、PCB与SoC完整料号仍待用户记录。

器件继续使用已验证PS-only流程的 `xczu5ev-sfvc784-2-i`；厂商XCI的XA/-1差异保留在Vivado日志，不解除实物签核项。

## Task2：本机版本与复用矩阵

MCP实际查询：MATLAB R2026b Update1 26.2.0.3433840，Simulink/Embedded Coder/SoC Blockset 26.2；AMD支持包26.2.3；MinGW支持26.2.3。完整定点清单在 `.runtime/ethernet/eth01/tools.json`。Vivado/Vitis2026.1，R5 GCC13.4.0，standalone9.5、emacps3.24、lwIP2.2.0（AMD lwip220_v1_4）、xiltimer2.4。本次没有安装、更换或修改这些工具。

实际库根为 `D:/Program Files/MATLAB/R2026b/toolbox/shared/soc/`。下表路径均通过本机load_system/find_system或which核实；C/HDL能力表示官方工作流能力，不是本板部署已通过。

| 实际库路径 | 仿真/生成能力与目标约束 | 最小检查、分类及本轮选择 |
|---|---|---|
| prociolib/TCP Read、TCP Write | SoC消息/数据端口，C由SoC Builder及目标后端生成；不是消息线直接建立socket | Read与IO Source真实仿真PASS，Write库/端口存在；**仿真可用但部署需适配**，本轮保留消息探针，不把APU/Linux后端当R5 lwIP |
| prociolib/UDP Read、UDP Write；hostiolib/UDP Read、UDP Write | 处理器消息模拟与Host UDP用途不同；标准C取决支持目标，无本板R5 Raw API证据 | 定点库检查；本轮TCP协议，**暂不适用** |
| prociodatalib/IO Data Source、IO Data Sink | 文件/对话框/时序对象/消息输入输出，测试平台；本身不是网络驱动，无独立硬件部署承诺 | Source→TCP Read探针PASS，Sink定点检查；**直接可用（仿真）** |
| Simulink/User-Defined Functions/C Caller | 标准外部C函数集成；本轮仅固定字节数组/len/valid/seq/status，不暴露pcb/pbuf | **直接可用**；ETH01_Target实际RxTryPop/TxTryPush块、Host仿真、C生成及R5链接全部PASS；复用本机AMD lwIP平台 |
| proctasklib/Task Manager、Hardware Interrupt | 可模拟任务/ISR事件，C调度依赖目标硬件映射；Hardware Interrupt的模拟事件不等于R5 GIC ISR | 块与esb_task后端检查；**仿真可用但部署需适配**；不接管原TTC |
| socmemlib、socmemlib2/Interrupt Channel、Register Channel | 模拟硬软通道及官方参考设计生成支持；需PL寄存器/中断与R5驱动 | 定点库检查；**仿真可用但部署需适配**，后续PS—PL阶段 |
| socmemlib2/AXI4 Random Access Memory、AXI4-Stream to Software、Software to AXI4-Stream；prociolib/Register Read/Write、Stream Read/Write | 模拟AXI/内存/寄存器；HDL或处理器C依赖具体参考设计/IP/驱动 | 定点检查；**暂不适用本PR**，无AXI DMA扩展；不声称通用R5驱动可直接用 |
| aximanager（toolbox/shared/fpgadebug_shared/aximanager.p） | 主机发起AXI访问，配套PL IP；不是R5设备驱动 | which确认，不创建会话或访问硬件；**暂不适用** |
| peripheralslib/ADC Interface；prociolib/ADC Read | 采样/转换延迟/触发建模；生成依赖指定ADC/FPGA参考设计或处理器驱动 | 定点检查；**仿真可用但部署需适配**，不是任意外置ADC RTL |
| peripheralslib/PWM Interface；prociolib/PWM Write | 波形/占空比/触发建模，C/HDL依赖目标；不保证安全三相PWM/死区/禁止 | 定点检查；**仿真可用但部署需适配**，保留原FOC架构 |
| QEP | 上述定点SoC处理器/外设库未发现QEP块；其他产品的QEP硬件支持未逐项验证 | **未核实跨产品部署**，不把输入计数值当A/B/Z引脚解码 |

官方[SoC模型结构](https://www.mathworks.com/help/soc/ug/soc-blockset-model-structure.html)的处理器设置为APU；[TCP Read](https://www.mathworks.com/help/soc/ref/tcpread.html)明确msg只用于仿真；[R2026b工具支持表](https://www.mathworks.com/help/soc/ug/supported-third-party-tools-and-hardware.html)列Vivado/Vitis HLS2025.1，本机是2026.1，AXU5EVB-E不在现成参考板列表。由此选择：保留现成SoC消息模拟价值，R5端复用本机AMD Raw API，生成模型通过窄C ABI接入；不换APU/Linux或工具版本迁就块，不自造协议栈。没有把“库存在”写成R5部署PASS。

## Task3：独立平台与内存/中断所有权

`hardware/axu5ev/eth01_ps_ethernet.tcl`复用已验证的厂商DDR迁移脚本，但输出为新的PS-only候选；随后只启用GEM3/MDIO，禁用TTC0，无PL bitstream。旧R1入口和产物保持原路径。

Vitis2026.1的依赖验证将原lwIP metadata的三个MAC驱动当作全部必需，因此第一次官方库添加失败。项目内 `eth01_lwip_overlay.py`复制受许可的安装库到新输出下的sw_repo_r2，改为本候选真实需要的emacps依赖，替换两个PHY入口。LOCAL repository优先选择这个无版本后缀的受控副本；不修改安装目录/原厂zip/全局repository。原始许可保留在副本源文件中。早期workspace `vitis_ethernet`及`vitis_ethernet_r1`留存；最终成功候选为 **vitis_ethernet_r2**（0x45303102），新overlay会拒绝适配源与缓存不一致。

网络时基为BSP默认PMU CPU/64，前台扩展32位回绕，`sys_check_timeouts`所有者为NetService；lwIP原默认NO_SYS_NO_TIMERS=1显式改为false。没有网络TTC、TTC IRQ或示例platform_setup_timer。必须持续服务；暂停超过PMU回绕约550秒后应重新启动测试，不依赖暂停期间的墙钟。

GEM IRQ由AMD SDT `init_dma→XSetupInterruptSystem`初始化GIC并绑定GEM一次；应用不另行DeviceInitialize。驱动保留DMA所有权/屏障/cache维护序列；D-cache关闭，I-cache开启。当前导出参数GEM3 IRQ编码0x403f/parent0xf9000000、PHY mode rgmii-id、CPU499994995Hz。

链接器把普通DDR限定在0x00100000—0x0fffffff；专用测试数组`.eth_bulk`为0x10000000—0x11ffffff、32MiB、64字节对齐/NOLOAD。ELF有独立filesz0、memsz32MiB PT_LOAD；程序、栈、堆均在测试区外。AMD `emac_bd_space`位于0x00400000、1MiB对齐，MEM_ALIGNMENT64；驱动R5分支使用现有MPU/内存属性及DMB/DSB和BD所有权路径。本PR没有改MPU为新cache策略，也未做板上DMA可达性测量。

MAC为明确本地管理单播02:45:30:31:00:10，仅一块测试板；IP192.168.50.10/24、网关0、TCP5001。用户核对无网段/MAC冲突后使用；IP末字节/端口可由应用宏配置，默认工程记录在构建命令中，不自动改PC网卡。

## Task4—5：实现与证据口径

协议见 `firmware/r5/ethernet/PROTOCOL.md`。平台、字节流服务、CRC帧、模型队列、生成算法、客户端分别独立。只有专用DDR测试传输，没有地址或文件系统远程RPC。

`simulation/ethernet/ETH01_Model.slx`为算法端口测试模型；256字节固定接口、len/valid/seq/TxReady，异或0x5A和计数/背压状态在MATLAB Function内，未由平台仿造。模型测试覆盖0/1/255/256/257、无消息、挂起回复与计数。**ETH01_Target.slx**为实际目标通信模型：RxTryPop C Caller→相同Process函数→TxTryPush C Caller，薄封装为`eth_caller.h/eth_queue.c`。`eth01_process.m`是两图内函数的共同可读源，生成C不是手改算法。

Host为可控有界队列与Dataset输入；目标是同一生成C及同一队列接口，独立前台服务调用。`ETH01_SoC_IO_Probe.slx`真正复用IO Data Source与TCP Read，4拍256字节消息仿真通过，**不会创建真实socket**。未将这个消息探针伪装为目标网络模型。

模型生成代码在 `.runtime/ethernet/eth01/model/codegen/` 的`ETH01_Model_ert_rtw`和`ETH01_Target_ert_rtw`，精简可审源归档在 `generated/ethernet/eth01/{model,target}/`；ARM objdump检查`EthModelService→ETH01_Target_step→Eth01Rx/Eth01Tx`，map包含生成对象。Host原生编译/localhost测试也链接实际Target生成C，不是手写echo替身。模型仅在初始化/断线清理时由窄适配操作自身生成状态，不读取网络寄存器。

初轮Review发现并修正了本机无括号时钟宏造成的4096倍误差、提前归还RX窗口引发的分片背压死锁、FIN半关闭丢回复、独立测试依赖旧EXE，以及双工验证不足。现在只在消费完整帧后归还窗口，FIN有界drain后close，本端只宣告支持的全双工模式；新增实际宏编译和生产回调提取测试。最终16/16相关Host测试通过，其中包含pbuf链、ERR_MEM、慢发送/满队列、断开保留partial、分片/粘连、CRC/版本/长度/序号与专用DDR边界。回调fixture模拟lwIP结果，不能替代板上驱动运行。

最终R5链接text/data/bss=92220/5100/37034480 bytes，部分BSP/FSBL生成源码有已记录warning（EMAC配置尾字段、废弃头、xtopology类型、遗留未用PHY函数、PS初始化宏重定义），本次原创Host源以-Wall -Wextra -Werror编译通过；不声称目标构建零warning。

详细阶段结果、测试命令与限制以 `verification/ethernet/eth01/status.json` 为准。只有本次新增测试，未跑旧全库/RTL/电机Runtime；所有PHY_LINK/TCP_IO/MODEL_BOARD_IO/BULK_TRANSFER为NOT_RUN。1MiB/s仅为用户板测目标，localhost吞吐不代表板上性能。

## 唯一用户上板入口

[FIRST_BOARD_RUN_ZH.md](../../firmware/r5/ethernet/FIRST_BOARD_RUN_ZH.md)。先Review，再用户逐步操作。后续接入完整Runtime时必须先停网络DMA/IRQ/时基再计时，完成冻结后恢复网络/重连；本PR不实现该并发或宣称沿用R1时间PASS。Issue15未覆盖事项继续保留。
