# AX-02C1：R5—AXI—PL 电流核最小联通

仓库`kazecode666/AXU5EV`，2026-11-03，依据[Issue21](https://github.com/kazecode666/AXU5EV/issues/21)，从包含已合并PR20的当前main建立`codex/ax02c1-r5-axi-foc`。用户原有四份模型/参数修改及两个未跟踪源文件保留，不纳入本次提交；R1、ETH01 r3、ETH02和所有实验数据不变。

## 离线结果，待Draft PR Review

| 项目 | 结果 |
|---|---|
| 新AXI寄存器及连续17帧短仿真 | PASS，51个duty位串、85000个运行时钟、283399次检查 |
| PS＋PL完整综合/实现/bitstream/XSA | PASS，实际bit与include-bit XSA已生成，构建退出0 |
| 匹配R5 standalone/FSBL/启动文件检查 | PASS，Vitis原生构建退出0，OFFLINE_STARTUP_CHECK_PASS |
| 用户一次新集成板测 | NOT_RUN |

唯一用户入口为[手动17帧指南](../../firmware/r5/ax02c/FIRST_BOARD_RUN_ZH.md)，寄存器和帧语义见[AXI_REGISTERS](../../integration/ps_pl/AXI_REGISTERS.md)。本轮没有板卡发现、连接、复位、下载或运行；没有AXI DMA、中断调度、完整Runtime、真实ADC/编码器、门极PWM或电机闭环。

## Task 1：薄AXI封装及帧合同

原样复用PR20实际候选`.runtime/ax02b/candidate_01/rtl/AX02B_P3_5EV`的29份design SV和`integration/rtl/axu5ev_foc_frame_top.sv`，不重新运行HDL生成，不改算法、Q格式、PI/AW、流水或历史封装。新增`axu5ev_foc_axi.sv`只实现32位AXI4-Lite、11个暂存字、一个pending九字段、一个active九字段及结果快照。

AW/W独立接收；R5写完全部字段，屏障后写COMMIT序号。首次数据提交后START，首个negedge锁存；后续pending只在完整5000拍边界采用。无新提交时保持active数据/采用序号，实际PL帧号仍递增，软件会拒绝17帧窗口内重复采用或跳帧。正常运行timing_restart固定0，不逐帧复位PI，不在edge315后停CE或提前开始下一帧。

原核心post314、原封装edge315捕获；AXI封装edge316共同发布三相、来源命令及结果帧号，VALID持续为1。R5读帧号→序号/三相→再读帧号核对一致，结果先放RAM。最后一帧结果后请求STOP_AFTER_FRAME，完整运行至edge5000才停止、完成计数17，然后输出UART。捕获相位和hold状态保留到INIT，0.5初值不等同硬件门极关断。停止状态下核心保持reset；每个新实验整体初始化，不承诺跨实验PI状态保留。

## Task 2：PS＋PL构建

复用`eth02_ps_runtime_ethernet.tcl`和`ax02a_ps_minimal.tcl`的DDR/UART、GEM3、TTC0及厂商PS参数迁移方法，在`.runtime/ax02c/hardware_01`创建独立工程。目标仍为`xczu5ev-sfvc784-2-i`；实际芯片完整料号/PCB未签核的历史事实保留，不重复资料调查。

M_AXI_HPM0_LPD经AMD SmartConnect连接真实FOC AXI-Lite外设，PS导出的PL0时钟共同驱动LPD AXI端口、互连、寄存器、FOC及proc_sys_reset。对应域复位采用现成IP；R5与PL的跨域由PS/标准AXI设施处理。GEM3/TTC0硬件配置保留，C1应用不启用网络服务或TTC调度。FOC数据没有引出电机IO。

本轮使用真实PS时钟及集成约束，不读取PR20理想OOC XDC。PS原生XDC在PS8/PLCLK[0]定义clk_pl_0、20ns周期；没有为10ppm元数据差异放宽周期。原生module-reference FOC子综合阶段没有独立XDC，其结果不是最终时序签核，须等带真实时钟树的完整顶层实现。BD验证已PASS：M_AXI_HPM0_LPD的Data地址空间实际分配FOC基址`0x80000000`、范围4KiB；SmartConnect采用原生Ultralite模式。PS启用一个fabric reset，proc_sys_reset从连接派生active-low极性，回读C_EXT_RESET_HIGH=0。DDR64位/器件16位、UART0 MIO42..43、GEM3、TTC0设置继续保留。实际设置见`hardware_01/integration_settings.txt`。

PS PL0从IOPLL请求50MHz；沿用PSS_REF_CLK元数据33.333MHz，实际pin回读49,999,500Hz（名义50MHz，-10ppm），对应5000拍约100.001µs。未改变板卡参考时钟参数、5000/2500拍基准或算法来掩盖此工具元数据差异；这也不是实测板钟。FOC与PL侧AXI始终共用此一个时钟，短仿真使用名义20ns周期验证拍数/位串。下述资源、时序及DRC均来自本次完整顶层，未使用PR20的WNS/WHS替代。

实际Vivado2026.1顶层综合0 Error/0 Critical Warning；完整布局、布线和bitgen已成功，最终include-bit XSA已导出，构建退出0（AX02C_BUILD_PASS）。[精简硬件证据](../../verification/ax02c/hardware.json)。最终Routed资源与STA如下（均为本次集成报告）：

| 资源 | 数量 / 器件占比 |
|---|---|
| LUT | 70902 / 60.54%（逻辑66957、SRL3945） |
| FF | 82651 / 35.28% |
| DSP48E2 | 431 / 34.54% |
| BRAM / URAM | 0 / 0 |
| CLB | 12462 / 85.12% |
| 时钟/控制缓冲 | BUFG_PS 1、BUFGCE 2；MMCM/PLL 0 |

135099条routable net全部完成，routing errors、failed/unrouted/partially routed及overlap均0。时钟报告只有一个功能时钟`clk_pl_0`，20ns、{0 10}：PS8/PLCLK[0]→BUFG_PS驱动86930个clock loads。两个BUFGCE均为工具默认高扇出控制网分布（wstrb_reg[0]网77521个非时钟负载、running_i_1网1128个非时钟负载），clock loads均0、Clock/Period均n/a；不是额外PL工作时钟，未人为新增时钟或优化指令。

| 完整顶层时序 | 最差裕量ns | 总负裕量ns | 失败端点 / 受测端点 |
|---|---:|---:|---:|
| Setup | WNS +3.160 | TNS 0.000 | 0 / 179351 |
| Hold | WHS +0.011 | THS 0.000 | 0 / 179351 |
| Pulse width | WPWS +8.500 | TPWS 0.000 | 0 / 86924 |

`check_timing`全部12类计数0，含no_clock、unconstrained_internal_endpoints、no_input/output_delay、loops/multiple_clock。DRC无Error或Critical Warning，仅761条原FOC的DSP流水性能建议：DPIP-2=271、DPOP-3=199、DPOP-4=291。本轮不改变p3流水消除建议；完整顶层没有旧OOC的RTSTAT/无HD.CLK_SRC/无物理端口边界警告。

最差setup是`design_1_i/foc_axi_0/inst/frame_core/theta_h_reg[8]/C`（fall@10）→`core/u_InversePark/If_Action_Subsystem_Out1_1_reg[24]/D`（rise@20），真实10ns半周期预算，数据延迟6.356ns、裕量3.160ns。完整时钟路径SCD2.641ns、DCD2.381ns、CPR0.160ns，uncertainty0.409ns，已经包含物理PS→BUFG分布，不是旧OOC的unset时钟网。最差hold为同核`u_SVPWMG/u_T1T2_Calculate/u_Fcn2/u_Defined_Quotient/d94_p_reg[50]/C`→`d95_p_reg[50]/D`，rise→rise、要求0ns、裕量0.011ns。Fast/Slow均分析max/min，完整路径及其角点见`hardware_01/reports/{setup,hold,timing_summary}.rpt`。没有通过放宽周期、deadline、修改算法或预先资源/时序优化凑PASS。

第一次BD整合暴露继承配置`NUM_FABRIC_RESETS=0`及复位IP极性参数为只读/派生，导致找不到pl_resetn0、整合退出。保留`integrate_01.log`，仅修正PS fabric reset数量并由连接派生复位极性，再验证同一候选；不重新生成FOC或重复PS基础迁移。

## Task 3：R5最小程序与启动顺序

`scripts/ax02c_build.py`复用既有Vitis平台/应用构建和只读启动文件检查，使用本轮匹配XSA、R5_0 standalone和A53_0辅助FSBL，独立Workspace，不覆盖旧ELF。MMIO基址读取本轮BSP导出，不使用DDR数据地址；沿用本机BSP的PL Strongly Ordered区域、Xil_In32/Out32及必要DMB顺序，I-cache ON、D-cache OFF，不引入自定义MPU/驱动框架。

实际Vitis2026.1使用最终include-bit XSA构建PASS：`ax02c_platform`导出标记export=SUCCESS，A53_0 FSBL为AArch64/ELF64（340392字节），R5_0应用为ARM/ELF32（214448字节，text/data/bss=17889/1824/89148）。`XPAR_FOC_AXI_0_BASEADDR=0x80000000`、HIGHADDR=0x80000fff；应用ELF内身份及基址与本次BSP一致。现有启动文件检查在构建后通过，主代理再次执行只读`python scripts/ax02c_build.py --check-startup`退出0；[精简证据](../../verification/ax02c/startup_check.json)。只检查文件，没有启动Launch或访问目标。

第一次软件构建原生平台已完成，但包裹脚本过早读取尚未发布的export/.buildstatus而停止，保留`vitis_01.console.txt`。仅继续同一未完成Workspace，将原生export标记放在应用构建后的最终启动检查核对，不新增等待/重试框架；最终成功日志为`vitis_02.console.txt`。生成FSBL有既有CRL_APB_RST_LPD_TOP宏重定义警告（两处为同一地址表达式，仅括号/空格形式不同），R5应用无新增编译警告；未改旧平台或硬件镜像。

17帧常量从已有`directed_probe_source_hex.csv`按整数位串导出；40位theta/omega分成低32与高8位，不经double重新量化。golden只用于结束后的51个duty位串比较，实际值只来自AXI。程序等待UART小写`s`后才首次访问PL，逐帧写入/提交/轮询/读回，不执行软件FOC、完整Runtime或lwIP；运行中不逐帧printf，结束后输出17行actual/expected/xor、采用/结果序号及BSP计时摘要。简单超时/失败退出，不恢复或重试，不建立WCET门槛。

启动顺序必须覆盖PS初始化、正确bitstream及PS—PL隔离/复位释放，再继续R5。既有FSBL的JTAG handoff仅在检测到PL DONE时执行PS—PL后配置，因此不能把“先运行FSBL、后用Hardware Manager加载bit”直接当作外设已就绪。指南已明确：用户加载bit后，在A53_0的XSDB上下文source匹配平台的`hw/sdt/psu_init.tcl`，依次调用`psu_ps_pl_isolation_removal`和`psu_ps_pl_reset_config`，随后返回R5继续。实际集成生成文件中这两个过程存在，reset配置已非空，包含EMIO31高→低→高释放序列。未盲用可能为空/职责不同的`psu_post_config`。Codex只检查文件，不执行这些硬件操作。

## Task 4：新增通路短仿真及交接

唯一新增仿真为`verification/ax02c/axi_sequence_tb.sv`，调用实际p3核，通过真实AXI握手写入/提交九字段，再经AXI读出17组三相并与既有golden比较。逐拍检查新封装与原帧计数对齐、九字段全5000拍保持、315捕获、315后CE持续使能；提前提交下一行不能改变当前采用序号。开始前无隐藏运算，结束后完整帧数17，运行时钟严格85000，没有插入重复计算帧。

实际结果：`.runtime/ax02c/axi_sequence_01/xsim.log`，17帧、51个duty、283399次有效检查PASS；精简结果在[validation.json](../../verification/ax02c/validation.json)。没有重新运行旧normal/reset/CE、完整长时RTL、TTC ABA或ETH02板测，没有新增通用测试平台、压力/故障注入或哈希清单。

复现短仿真（repo根目录，指定新的输出目录）：

```powershell
python verification/ax02c/run_axi_sequence.py --out .runtime/ax02c/axi_sequence_new
```

实际完整产物（均在D:/Project/AXU5EV）：

| 产物 | 实际路径 |
|---|---|
| 完整Vivado工程 | `.runtime/ax02c/hardware_01/project/ax02a_ps.xpr` |
| Bitstream，7797907字节 | `.runtime/ax02c/hardware_01/ax02c_ps_pl.bit` |
| include-bit XSA，2802035字节 | `.runtime/ax02c/hardware_01/ax02c_ps_pl.xsa` |
| Routed DCP | `.runtime/ax02c/hardware_01/project/ax02a_ps.runs/impl_1/design_1_wrapper_routed.dcp` |
| Vitis Workspace / Launch | `.runtime/ax02c/vitis_ps_pl` / `ax02c_foc_manual` |
| R5 ELF / map | `.runtime/ax02c/vitis_ps_pl/ax02c_foc/build/ax02c_foc.elf` / `ax02c_foc.map` |
| A53 FSBL | `.runtime/ax02c/vitis_ps_pl/ax02c_platform/export/ax02c_platform/sw/boot/fsbl.elf` |
| 匹配PS后配置脚本 | `.runtime/ax02c/vitis_ps_pl/ax02c_platform/hw/sdt/psu_init.tcl` |
| 实际软件成功日志 | `.runtime/ax02c/vitis_02.console.txt` |
| 预留用户UART结果（尚未采集） | `.runtime/ax02c/board/uart_17_01.txt` |
| 实际报告及硬件成功日志 | `.runtime/ax02c/hardware_01/reports/`、`.runtime/ax02c/build_01.log` |

综合/实现复现入口为`hardware/axu5ev/ax02c_ps_pl.tcl`，默认all阶段仅对未占用输出目录运行；本次失败的integrate_01日志保留，integrate_02与build_01成功。例（使用新的输出，不覆盖本候选）：

```powershell
Set-Location D:/Project/AXU5EV/.runtime/ax02c
& E:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat -mode batch -nojournal -log hardware_new.log -source D:/Project/AXU5EV/hardware/axu5ev/ax02c_ps_pl.tcl -tclargs D:/Project/AXU5EV/.runtime/ax02c/hardware_new 'D:/Project/AXU5EV/资料/course_s2/01_ps_hello/vivado/ps_hello.srcs/sources_1/bd/design_1/design_1.bd' D:/Project/AXU5EV/.runtime/ax02b/candidate_01/rtl/AX02B_P3_5EV all
```

Vitis入口为`scripts/ax02c_build.py`；重新构建须用新的配置副本，将workspace/xsa/bitstream指向新目录，通过AX02C_CONFIG指定，设置任务内XILINX_VITIS_DATA_DIR后用本机`vitis.bat -s`执行。已有确认候选不覆盖；`--resume`只继续本轮尚未完成的Workspace。用户只运行已有候选时不需要重新构建，按唯一指南的只读启动文件检查即可。

本轮验收是正常记录向量经R5—AXI驱动真实PL FOC的最小通路。名义50MHz/100µs帧及50µs应用参考不变，但不是整机闭环、真实传感器或同帧50µs端到端时限验收。C2才接入既有Runtime并依据实测时间确定固定帧关系/数据年龄；不预先优化、增加一拍或宣称零耗时。本轮离线结果不能写为BOARD_PASS，最终Draft PR等待Review，不自动合并，不关闭Issue15。
