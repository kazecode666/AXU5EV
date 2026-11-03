# AX-02C1 — R5—AXI—PL电流核最小联通

> 本文保存Issue21任务内容；本次用户已明确授权从已合并PR20的当前主线实施，原文末尾“当前会话只下发任务”是任务发布时的历史边界。复选项表示离线实现/必要短仿真/构建完成，不表示已执行板测。实际执行及未完成项见[AX-02C1主报告](../reports/ax02c1_r5_axi_foc.md)，已随实现提交[Draft PR22](https://github.com/kazecode666/AXU5EV/pull/22)待Review，本轮板测由用户手动完成。

接续已合并PR20。用户最新要求：继续推进正常功能链路，不增加过多防御性措施；资源、吞吐、时序余量优化等到实际需要时再做。由Codex在现有工作区实施，ChatGPT Review，用户手动上板并决定合并。本文是下一实现任务，不代表已构建或上板。

## 目标与本轮选择

将PR20已验证的FOC核真正放入AXU5EV的PL，由R5通过AXI写入九字段、读取三相duty。交付可加载的bitstream、匹配XSA/FSBL/R5 ELF，以及一次短序列板测的实际操作入口。

本轮选最简单的32位AXI4-Lite寄存器接口、PL侧总线与FOC同一50MHz时钟、R5轮询。不是再做LED/Hello World或独立空壳寄存器练习；寄存器联通和真实FOC运行在同一个实现PR内完成。DMA/共享DDR队列、中断调度、完整Runtime与FOC联动均不在C1内展开；后者在这条真实通路通过后作为C2接入。

C1仅使用已有记录向量，没有真实ADC/编码器、机械对象、门极PWM或电机闭环。通过R5注入theta/omega等测试字段不改变最终“PL本地角度路径”的架构分工。

## 直接复用的资产

- `coordination/reports/ax02b_pl_current_core.md`及PR20实际生成候选；FOC算术和p3流水不变，不重新做器件迁移或重复HDL生成。
- `integration/rtl/axu5ev_foc_frame_top.sv`及`integration/ps_pl/INTERFACE.md`。允许为AXI集成暴露必要的帧边界信号或增加薄封装，不手改生成SV。
- `hardware/axu5ev/eth02_ps_runtime_ethernet.tcl`和`ax02a_ps_minimal.tcl`中的本板PS配置、既有R5 standalone/FSBL构建方式；原ETH02平台与应用保持原样。
- `verification/m3_foc/directed_probe_source_hex.csv`已有17帧九字段输入和三相duty golden；直接使用整数位串，不经过double重新量化，不把golden拿来代替实际PL结果。

## Task 1 — 定义并实现最小寄存器与帧接口

- [x] 在同一个实现PR中写一份简短寄存器表及帧时序说明，明确地址偏移、访问方向、40位拆分及提交/采用/结果序号。不要先开纯设计文档PR。
- [x] 接口只需模块身份/运行状态、九字段暂存、一次提交、已采用序号、三相结果及对应帧/命令序号。可用一组待提交数据，不做队列、通用协议或自动恢复框架。
- [x] 32位字段保持原位串；theta_e/omega_e各用两个32位字承载，低字为bits31:0，高字有效部分为bits39:32，明确读写的符号解释。不改Q格式。
- [x] 软件先写完所有字段再提交；PL在明确的完整帧边界一次采用，不能让多次AXI写入直接改动本帧输入。结果及其来源序号对应同一帧；轮询读取期间以序号前后核对或等价的简单快照方法保证三相一致。
- [x] 沿用50MHz、5000拍完整帧、核心post314/封装edge315。不能在拿到第315拍结果后重启下一帧、停核心CE或每帧复位PI。正常运行timing_restart=0；每次新实验整体初始化一次。
- [x] 第一帧先装好数据再开始；后续向量提前提交给下一连续帧。没有新提交时保持已采用数据并如实保留采用序号；本轮17帧比较窗口不得插入未声明的重复计算帧或跳过向量。若正常轮询确实赶不上，报告实际问题，再针对处理。

这些只是数据能正确传输的必要语义；不扩展心跳、看门狗、断线重连、故障注入或全套异常状态机。

## Task 2 — 建立PS＋PL完整工程并生成bitstream

- [x] 从现有已验证PS配置建立独立集成工程。优先使用`M_AXI_HPM0_LPD`，经AMD标准AXI互连/协议转换接自定义AXI4-Lite外设。地址由实际BD/XSA分配并在R5侧一致引用，不将DDR数据地址当外设地址。
- [x] 使用PS导出的实际50MHz PL时钟，连接总线PL侧、寄存器及FOC；用现成复位IP完成对应域复位。首版不人为增加第二个PL工作时钟，不另造CDC框架。R5处理器与PL仍是不同硬件时钟域，其跨域由PS/标准AXI基础设施处理。
- [x] 保留已有DDR/UART和GEM3/TTC0配置便于后续复用，但C1短序列运行不启用网络并发或TTC调度FOC。FOC帧由PL自己的5000拍时基推进。
- [x] 接入PR20候选RTL及薄封装，执行完整综合/实现/bitstream导出，生成匹配XSA。FOC数据不引出电机IO，不分配ADC/门极引脚。
- [x] 本轮约束跟随真实集成设计和实际时钟，不把PR20理想OOC约束当最终时钟树约束。检查本次构建正常产生的时序与DRC报告即可；不预先为CLB占比或原0.034ns hold裕量开优化支线。有实际违例才定位修复。

交付：实际集成工程、bitstream、XSA和简短构建结果。沿用已记录目标器件，实物料号/PCB未签核的历史事实不自动改成已确认，但不为此重做资料调查。

## Task 3 — R5最小驱动与真实FOC短序列

- [x] 继续R5_0 standalone，复用既有A53 FSBL辅助启动、BSP和链接方法，不引入A53应用/Linux/RTOS。使用新XSA生成匹配平台，不覆盖ETH02 workspace/ELF。
- [x] 用本机BSP的MMIO访问方式和必要的寄存器内存属性/访问顺序实现写字段、提交、读序号/结果几个动作。沿用现有I-cache ON/D-cache OFF配置，不做缓存/TCM优化或自定义驱动框架。
- [x] 从已有CSV生成17帧常量输入与比较参考，R5在实验开始后逐帧经真实AXI提交，轮询取得实际PL三相结果，先存RAM。连续运行中不逐帧printf，不运行lwIP服务，不执行完整Runtime。
- [x] 检查17帧的序号、采用关系和51个三相duty整数位串；保持原状态递推。最后一帧完整运行结束后再结束实验、输出结果。记录实际AXI交换/等待时间供后续参考，不额外建立WCET/性能门槛。
- [x] 首轮数据很小，统一在结束后通过现有UART输出17帧实际值、参考差异及摘要即可；不新造ETH03传输协议或MATLAB界面，也不回到大文件XSDB读回流程。以太网已有能力保留，C2需要长序列时再直接复用。
- [x] 程序进入等待启动状态，由用户按唯一指南明确开始一次实验。正常轮询保留简单的失败退出/超时信息以避免卡死，不做恢复/重试框架。

## Task 4 — 必要验证、Review和一次用户板测

Codex先完成离线实现，复用现有向量做一次针对新AXI封装的短仿真，确认寄存器提交、连续17帧及结果对应；只覆盖新增通路，不重跑已验收的全套p3/长时RTL、TTC ABA、ETH02板测，不新增通用测试框架或压力/故障注入套件。

完成实际bitstream/XSA/FSBL/R5 ELF构建和已有启动文件检查后提交Draft PR，给出一份唯一的中文指南，列出真实workspace/launch、bitstream/ELF路径、加载顺序、开始操作、应见输出和结果保存位置。上板前为BUILD/离线结果，不写BOARD_PASS。

Review后用户手动完成一轮新集成板测：PS初始化→加载正确PL镜像→启动R5→显式运行17帧→保存UART结果。必须保证PL时钟/复位及bitstream已就绪，再访问外设。Codex不得自行连接、发现、复位、下载或运行板卡；功率级保持断开，不写启动介质。

**验收只看：** R5确实通过AXI驱动本次PL核；连续17帧与输入/结果序号对应；51个duty位串与现有golden相同；完整帧规则保持；集成构建可用且正常板测结束。不是整机闭环、真实传感器链或50µs端到端控制时限验收。实际板测失败时再针对问题修正，不预设额外实验轮次。

## 文件与工作方式

建议复用或新增：`hardware/axu5ev/ax02c_ps_pl.tcl`、`integration/rtl/axu5ev_foc_axi.sv`、`integration/ps_pl/AXI_REGISTERS.md`、`firmware/r5/ax02c/`、`verification/ax02c/`。新产物集中`.runtime/ax02c/`未占用子目录；一份主要实施报告和一份用户指南即可。Task随实现存入`coordination/tasks/`，更新当前HANDOFF/README摘要。

在`D:/Project/AXU5EV`现有工作区从包含PR20的当前主线开分支；不另clone/worktree、不自动stash/reset/clean、不覆盖用户模型或旧实验。算法仍来自Simulink，必要模型操作沿用MCP。当前会话只下发任务，不启动本地实施。合并由用户决定，Issue15遗留项不自动关闭。

## 紧接着的C2（本Issue不提前实现）

C1通过后，将已有R5 Runtime产生的参考、模式及对齐信息接入这条总线通路，并用记录反馈做100µs协同回放。根据真实交换和计算时间选定固定帧关系；同步更新模型的计算/传输延迟，不静默增加一拍或宣称零耗时。PL电流帧作为基准，不能让两套未同步的TTC/PL定时器各跑各的后假定永远对齐。

既有62.33µs回放响应不能作为未来负载WCET，也不能证明同帧50µs应用可行；本轮不为了它提前优化。C2需要时再决定采用已提交参考/固定相位，或经实测满足的同帧方案。ADC、编码器、门极PWM和真实电机仍在AX-03。

技术依据：AMD UG1085的PL AXI Interface及PL Accelerator Block and LPD Interaction（RPU经M_AXI_HPM0_LPD控制PL）；项目现有INTERFACE、ETH02平台与PR20报告。
