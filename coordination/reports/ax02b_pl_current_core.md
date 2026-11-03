# AX-02B：5EV PL 电流核迁移与模块实现

2026-11-03，仓库kazecode666/AXU5EV，分支`codex/ax02b-pl-current-core`。依据[Issue19](https://github.com/kazecode666/AXU5EV/issues/19)，从包含已合并PR18的当前main开始。仅离线工作；所有旧workspace、ELF、用户SLX/参数修改和实验原始数据保留。

**结果：B1来源核对、B2独立生成、B3定向功能/帧合同均PASS；B4为`5EV_MODULE_IMPLEMENTATION_PASS`，仅限下述理想时钟OOC边界；B5已提交[Draft PR20](https://github.com/kazecode666/AXU5EV/pull/20)，等待Review。板上运行NOT_RUN，实物料号/PCB、真实时钟树、IO/复位/CDC及整机签核均未完成。**

## B1—B2：来源与生成

使用`baselines/pr53_p3/source/PMLSM_FOC_FixedPoint.slx`及同目录冻结初始化/类型函数，逐项应用`baselines/pr53_p3/codegen/candidate.json`的18项p3流水设置；未混用当前`simulation/init_AXU5EV.m`。当前FOC SLX与冻结包不是字节相同，差异为布局、图元数据与Vdc_V→Vdc命名；按SID检查块参数和Src/Dst连接、排除显示属性并归一化母线名后无差异。这是来源核对，不是对当前用户模型重新签全仿真。[核对记录](../../verification/ax02b/source_relation.json)。

MATLAB R2026b Update1 26.2.0.3433840、HDL Coder26.2，Vivado2026.1；未安装或更换工具。HDL Coder family枚举从本机2025.1插件的device_list.xml读取，确实含`xczu5ev-sfvc784-2-i`，回读为Zynq UltraScale+／xczu5ev／sfvc784／-2、50MHz。Vivado本机get_parts确认为同一合法part。手册XC/-2与厂商XA/-1差异继续保留，实际芯片完整料号/PCB修订仍待用户核对，未宣称实物匹配。

新入口`simulation/axu5ev_build_pl_target.m`在独立MATLAB batch进程内，把冻结模型复制为`AX02B_P3_5EV`，隔离path/cache/codegen并恢复配置；未保存用户模型，也未在交互base workspace初始化控制参数。Oversampling5000、同步reset、CE、PI_Reset、时序重启及全部数值类型不变。源采样100µs、快时钟50MHz、duty应用参考边界50µs均保留。

本轮实际生成成功：`.runtime/ax02b/candidate_01`。29份design SV与`generated/legacy_m3_p3/`对应文件**逐字节相同**，没有逻辑/相位变化或7系列专用原语/IP。三相HDL调度报告仍为post-edge314；不是只替换旧报告的器件名称。[生成设置回读](../../verification/ax02b/hdl_config_readback.json)、[生成记录](../../verification/ax02b/generation.json)。

生成日志保留了固定三角查表/系数量化的既有精度警告；最终HDL检查0错误、4个默认除法/倒数ShiftAdd实现警告及8条消息（含非ASCII注解）。未通过改系数、位宽或算法消除警告，实际SV与p3相同。

## B3：必要的位级、状态与帧合同检查

复用`verification/m3_foc/directed_probe_source_hex.csv`的17行source/gm bit oracle和原`m3_foc_scoreboard.sv`。覆盖正常/参考变化、饱和与恢复、PI_Reset，另用原reset/CE模式检查global reset和状态消费/提交；不重跑长时10→0→−2mm闭环。新帧探针仅检查本轮复用封装的锁存/相位/复位合同，不是通用测试平台。

| 检查 | 有效帧 | 实际比较数 | 结果 |
|---|---:|---:|---|
| 原normal位串/PI/AW递推 | 17 | 340183 | PASS，bit/state/XZ/protocol/deadline全0 |
| 原global reset取消帧及零态前缀 | 19 | 380605 | PASS，全0错误 |
| 原CE暂停诊断 | 17 | 340183 | PASS，正常合同仍是5000个使能拍 |
| 帧封装探针 | 21 | 518436 | PASS，hold_violation=0 |

封装探针在合法锁存边界前共同提供九字段，然后每拍扰动外部输入，检查帧内保持至5000拍末尾；314后仍连续运行核心CE，post314核结果与edge315外寄存器分别对golden位串比较。frame_id每次捕获加1，capture_edge315，result_valid首结果后保持1；跨帧不能把它当脉冲。reset后外duty为0x20000000（0.5）、valid0，**不代表门极硬件安全关断**。

PI_Reset沿原数据路径消费，不等同global reset；global reset同步清算法存储。timing_restart连接核心TC复位而不连接算法reset，并重置封装phase/frame_id/valid/duty及保持输入（包括pi_h=1）。探针检查其首个有效重启边沿没有同步清PI/AW存储；AW旁路输出会随时序使能改变，因此不能把旁路端口当状态存储，也不能把此检查解释为任意长度重启期间“算法状态不变/无缝续算”的承诺。AX-02C须按实际边界使用，不给timing_restart新增PI清零指令语义。

首轮检查的Windows plusarg引用失败保留在checks_01；checks_02的帧断言把重启后的AW旁路变化误当清零，定位后只改探针观察点为实际存储，仅重跑frame得到checks_03 PASS，算法/封装均未改。有效normal/reset/CE来自checks_02，frame来自checks_03，不能用其未完成的总运行状态代替分项结果。[精简结果](../../verification/ax02b/validation.json)。

## B4：5EV OOC 实现与时序

实际运行`synth_design → opt_design → place_design → route_design`完成，Vivado退出0，已生成`D:/Project/AXU5EV/.runtime/ax02b/implementation_01/routed.dcp`。本轮30份综合源为29份新生成design SV加原帧封装，源名/顺序记录在同目录`sources.txt`。[精简实现证据](../../verification/ax02b/implementation.json)。

新入口`hardware/axu5ev/ax02b_pl_current_core.tcl`读入同一候选design SV及原样`axu5ev_foc_frame_top.sv`，不综合testbench、XSI或MEX。新OOC XDC只定义20ns、波形{0 10}理想快时钟；无false_path、multicycle或5000拍放宽。negedge输入保持寄存器与posedge核心、反向posedge→negedge均保留真实半周期约束。未编造板级引脚或输入延时。

OOC边界输入/输出预算、真实50MHz时钟产生/抖动、系统复位、CDC和最终系统路由未签核。边界缺省约束须与内部reg-to-reg报告分开解释；不能由正WNS推导整机通过。pulse-width按器件限值检查，仍不构成实际时钟品质测量。依据：[UG835 report_pulse_width](https://docs.amd.com/r/en-US/ug835-vivado-tcl-commands/report_pulse_width)、[UG906](https://docs.amd.com/r/en-US/ug906-vivado-design-analysis/Report-Pulse-Width)。

| Routed资源 | 实际数量 | 器件占比 |
|---|---:|---:|
| CLB LUT（逻辑66001＋SRL3944） | 69945 / 117120 | 59.72% |
| FF | 81057 / 234240 | 34.60% |
| DSP48E2 | 431 / 1248 | 34.54% |
| BRAM / URAM | 0 / 0 | 0% |
| 已占用CLB | 12480 / 14640 | 85.25% |
| BUFG各类 / MMCM / PLL | 0 / 0 / 0 | 0% |

层级Routed LUT/FF/DSP：封装自身112/690/0；FOC核69833/80367/431；其中SVPWM36902/47694/155、dq限幅器21853/27399/76、Park3319/983/48、InversePark3839/1015/48、Id1565/1132/44、Iq1530/1091/44、Clark499/264/16。综合阶段为70375 LUT、82126 FF、431 DSP，最终资源以上表为准；Vivado映射/优化不等于修改算法流水。CLB占用85.25%，不能把剩余LUT百分比直接当作未来系统的可用布局余量；本轮不做资源优化。

路由561099条logical net中，134102条routable net全部完成，routing errors=0；另外379870条内部已路由、46754条无负载、373条隐式边界端口。工具报告failed/unrouted/partially routed/overlap均0，不能将边界隐式路由解释为完成板级布线。

| 内部STA（Fast/Slow均分析max/min） | 最差裕量ns | 总负裕量ns | 失败端点 / 总受测端点 |
|---|---:|---:|---:|
| Setup | WNS +3.020 | TNS 0.000 | 0 / 96328 |
| Hold | WHS +0.034 | THS 0.000 | 0 / 96328 |
| Pulse width | WPWS +9.468 | TPWS 0.000 | 0 / 85328 |

`report_pulse_width -all_violators`无违例条目。最差setup为`theta_h_reg[9]/C`（fall@10）→`core/u_Park/Sum_out1_last_value_reg[39]/D`（rise@20），预算10.000ns、数据延迟6.760ns、裕量3.020ns。反向半周期最差为`phase_reg[0]/C`（rise@0）→`vdc_h_reg[7]/CE`（fall@10），预算10.000ns、裕量6.201ns。最差hold为`core/u_SVPWMG/u_T1T2_Calculate/u_Fcn2/u_Defined_Quotient/d23_p_reg[17]/C`→同模块`d24_p_reg[17]/D`，两端均rise@0，要求0ns、裕量0.034ns。完整路径和边沿分别保存在`setup.rpt`、`hold.rpt`、`negedge_to_core.rpt`、`to_negedge.rpt`。

`check_timing`：no_clock、constant_clock、unconstrained_internal_endpoints、multiple_clock、loops、latch_loops及partial input/output delay均0；no_input_delay=275、no_output_delay=136，是本轮没有建立预算的外部边界。`report_exceptions`无有效例外。时钟报告为20ns、{0 10}、50MHz。

警告及验收范围：

- 综合/布局/布线日志均0 Error、0 Critical Warning。综合的未使用端口/位、顺序元件裁剪属已映射优化；`Synth 8-589`把封装hold监视器的`!==`映射为硬件`!=`，不应把该监视器当X/Z或亚稳态检测电路。
- DRC共762条Warning：DPIP-2=271、DPOP-3=199、DPOP-4=291为DSP输入/MREG/PREG流水性能建议，不在本轮改变已验收流水；RTSTAT-10=1指三相duty及result_valid共97条输出网没有可路由的外部负载。无DRC Error/Critical Warning。`DRC 23-814`说明OOC未运行全部连接类检查，不能据此签最终系统DRC。
- `Route 35-197`及`Timing 38-242`：clk无HD.CLK_SRC，不能核查上游时钟放置/准确时钟延迟和偏斜；时钟资源为0，路径中clk net标为`unset`，少量估计延迟不是实际时钟树。最差setup还含工具默认0.235ns uncertainty（含0.200ns duty-cycle distortion），不代表已提供真实板钟抖动。本轮不编造物理时钟位置以消警告。
- `Route 35-198`：边界端口无HD.PARTPIN_LOCS，不能导出其部分路由或签核到/来自端口的时序；不编造端口位置和输入/输出delay。内部数据路径实现与STA只适用于声明的OOC输入时钟条件。AX-02C须在真实时钟树、交换边界和实际复位/CDC上重新收敛，尤其不能把0.034ns hold裕量外推为整机余量。

因此本轮结论为条件明确的`5EV_MODULE_IMPLEMENTATION_PASS`，不是5EV整机时序或上板许可；没有生成bitstream。

## B5：复现入口、产物与AX-02C交接

生成需由MATLAB MCP启动独立MATLAB `-batch`进程，其表达式为（每次更换未占用candidate路径）：

```matlab
addpath('D:/Project/AXU5EV/simulation');
axu5ev_build_pl_target('D:/Project/AXU5EV/.runtime/ax02b/candidate_02');
```

不要在交互会话直接执行该表达式：入口会检查batch模式，避免污染用户参数。实际首轮生成日志`.runtime/ax02b/generate_02.log`，HTML调度/资源/优化报告在`candidate_01/rtl/AX02B_P3_5EV/html`，生成SLX也只在该候选目录。

全部大型产物根为`D:/Project/AXU5EV/.runtime/ax02b/`：`candidate_01`是本轮源副本/RTL，`checks_02/{normal,reset,ce}`与`checks_03/frame`为有效检查，`implementation_01`含synth/routed DCP及资源、时钟、route、DRC、check_timing、exceptions、setup/hold/半周期/pulse-width原始报告；实现日志为`implementation_01.log`。这些是离线Vivado产物，没有新Vitis Workspace/Launch或上板命令。

验证与实现命令（repo根目录，替换新的输出目录；已有目录保留）：

```powershell
python verification/ax02b/run_checks.py --candidate .runtime/ax02b/candidate_01 --out .runtime/ax02b/checks_new
& E:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat -mode batch -nojournal -log .runtime/ax02b/implementation_new.log -source hardware/axu5ev/ax02b_pl_current_core.tcl -tclargs .runtime/ax02b/candidate_01/rtl/AX02B_P3_5EV .runtime/ax02b/implementation_new
```

`--mode frame`等只选择必要分项；任何工具/位比较失败均非零退出，检查有效帧和比较数。原始失败与成功日志保留，不生成全库哈希清单。

AX-02C接口保持原九字段：ia/ib/ic/id_ref/iq_ref为signed32/24小数位Apeak，theta_e为signed40/32小数位rad，omega_e为signed40/24小数位rad/s，Vdc为unsigned32/24小数位V，PI_Reset为boolean；三相duty为unsigned32/30小数位。输入需在首个negedge前共同建立，保持完整5000拍；结果捕获315拍后保持，帧识别结合frame_id与持续valid。三个复位职责及重启注意事项见B3，既有完整接口仍在`integration/ps_pl/INTERFACE.md`。

ETH02旧current_motion最大响应62.33µs大于现有50µs应用参考点，不能据此宣称“本帧反馈→R5同帧计算→PL再算→仍在50µs应用”成立。AX-02C应将实际计算/交换延迟和数据年龄纳入模型，再定原子命令与同帧反馈快照；本轮没有AXI、ADC、编码器、门极PWM、bitstream或板卡操作。Issue15遗留签核项保留；Draft PR等待Review，不自动合并。
