# motor_control 统一模型与 PL 工程入口

## Issue40：同帧反馈到 FOC/PWM 的自动通路

从已合并PR39的main `ffaa5683322e2a485d96a23cc1b8a9e88fbcdb13` 建立 `codex/motor-control-chain`。本轮不复制ADC/QEP/PWM工程，不接完整外环、Runtime或自动对齐。原始ADC针脚/ABZ接收器→原电流/角度生成HDL→原p3 FOC→新模型生成比较值→原整组三相PWM的路径实际连通。六路仍只在内部观察，physical_link_verified=0，板卡操作NOT_RUN。

| 工作 | 唯一入口/来源 |
|---|---|
| 查看/运行整个数值链 | `simulation/motor_control/AXU5EV_Motor_Control_System.slx`；`motor_control_run(<新结果目录>)` |
| 电流数值/生成 | `simulation/real_io/ax03b1_current_preprocess.m`、原 `Current_Preprocess` 库块；`adc_generate_hdl` |
| PL电角度数值/生成 | `simulation/encoder/encoder_angle_step.m`、`Encoder_Angle` 库块；`encoder_generate_hdl` |
| 原FOC数值/生成合同 | `baselines/pr53_p3/source/PMLSM_FOC_FixedPoint.slx`；直接复用 `generated/legacy_m3_p3/manifest.json` 列出的29份设计SV及原 `integration/rtl/axu5ev_foc_frame_top.sv`，未重新生成或手改 |
| duty到PWM比较值 | `simulation/motor_control/duty_to_compare.m`；`motor_control_generate_mapper`，生成两份SV到 `generated/motor_control/AXU5EV_Duty_Adapter_HDL/` |
| R5位置/50间隔测速 | `simulation/encoder/encoder_position_speed.m`；原 `encoder_generate_c`，复用其生成C和原字段适配器 |
| 外设/冻结/调度/跨频接口 | 本目录 `rtl/` 与原 `integration/rtl/ax03b1/ax03b1_abz_receiver.sv`；`sources.list` 为实际清单 |
| 板级装配/时钟/XDC/构建 | 本目录 `build.tcl`、`bd/`、`constraints/`；`scripts/motor_control_build_hw.ps1` |
| 匹配R5观察器/操作 | `scripts/motor_control_build.py`、`firmware/r5/motor_control/build_config.json`、该目录 `FIRST_RUN_ZH.md` |

系统壳实际调用同一个电流/角度库组件、原FOC Model Reference和原R5函数。ADC/QEP/PWM的系统模型部分明确标为SIM_ONLY，逻辑参考采用一帧对齐，不能将其显示延迟当作物理调度；实际接收器、同步资格和互补/死区由RTL和路由后定向测试验证。数值类型、受控原依赖及模型运行方法详见 `simulation/motor_control/README.md`。安全入口在新结果目录从上述Git基线取原库/FOC依赖进行隔离运行，不保存用户已修改的模型或改变交互MATLAB的电机/PI参数。

### 自动候选及时间合同

`MC_AUTO=1` 只选择本轮自动候选，包装脚本用try/finally恢复原进程环境；它仍调用原编码器/PWM构建入口。`AUTO_CONTROL=1`、`AUTO_FOC=1` 是静态来源选择；自动候选拒绝原手动PWM COMMIT/许可写，旧 `AUTO_FOC=0` 保持原语义。数值换算只在生成的Duty_To_Compare中执行：unsignedQ30限幅至0..1，乘5000并half-up舍入，三路整组交接。

| 相对于选中ADC phase0（P0，50MHz拍） | 自动通路 |
|---|---|
| P0 | 采用已预提交参考，锁存原ADC/QEP身份及元数据 |
| P110，名义+2.2us | 原电流/角度会合，冻结同帧结果 |
| P127/P128 | 冻结九字段；原FOC下降沿壳捕获后，在P128第一次接受 |
| P442，名义+8.84us附近 | 原结果post314/外部edge315就绪，捕获带本帧身份的三相duty |
| P445附近 | 一拍模型映射后向原PWM整组邮箱交接 |
| P2400，名义+48us | 尚未完成的晚到交接取消并禁止，不冒充目标采用成功 |
| P2500，名义+50us | 原100MHz共同载波下一谷值整组三相采用 |
| P2508之后 | 收集采用确认并发布80字控制快照；精确传播相位以本轮RTL/SDF结果为准 |

50MHz ADC/算法/AXI、2倍频100MHz PWM、5MHz转换及500转换/100us选样保持原合同。FOC一次启动后连续使能，每帧完整5000拍；不逐帧global reset/timing_restart或在结果出现后停钟。无效/未许可帧仍以零电流/参考/角度/速度、48V和PI_Reset=1运行，结果不提交。首次有效结果之前保持禁止；禁止/重校准/失锁取消在途数据，重新允许只能用新有效结果在谷值生效。失锁后须新的参考版本或显式arm低/高，保持旧arm不会自动恢复。

固定捕获后的disarm/失锁/晚到只立即禁止并取消PWM，不改变本帧已冻结输入。下一捕获根据当时有效性及显式PI_Reset决定递推/复位PI；已经显式重臂且反馈有效则保持原状态，不增加隐式global reset或自动PI恢复。

### 参考与快照

ADC原基址0x80000000不变。参考shadow写0x180/184=id/iq signedQ24，0x188/18c=omega低32/高8 signedQ24，0x190=Vdc unsignedQ24，0x194=PI_Reset，0x198=版本，0x19c=arm；0x1a0写1冻结整组并在下一P0采用，pending时第二次提交拒绝，后续shadow写不污染冻结组。0x1a4写1立即disarm。48V母线和omega均为明确TEST参考，未宣称实测。

新快照MCT1（0x4d435431）/schema3/epoch0x4d430003为80字；BEGIN、冻结及原前41字单位保留，最后word79 **0x148读响应** 才释放。原写寄存器与读取空间独立，不能沿用0x88或0xac作为新候选释放位置。word41为控制标志，42–44=FOC采样ID/tick，45=参考版本，46–56=完整冻结九字段，57–59=Q30 duty，60–62=比较值，63=提交采样ID，64=最后确认采用ID，65–67=提交/晚到/无效计数，68/69=原核帧号/capture_edge，70–71=目标tick，72=结果数；73–79保留0。word64是采用历史，须与禁止/有效/late位联合判断，不能表示禁止后仍有输出。

最终候选、模型/RTL逐位对比、完整STA/CDC、定向SDF及R5构建结果见 `verification/motor_control/results.json` 和HANDOFF首节。所有旧结果目录/Workspace、用户8个模型/参数修改及未跟踪文件均保留。以下段落是PR39及先前工程的历史入口说明，不能用其旧“未接FOC”或旧时序证据替代本轮结果。

## Issue38 编码器同帧增量

基线为已合并PR37的main `5c9aca2`。仍只使用本目录的 `build.tcl`、`sources.list` 和BD；`scripts/encoder_feedback_build_hw.ps1` 临时设置 `MC_ENCODER=1` 并调用原PWM入口。默认 ADC-only/PWM旧入口保持32字B3OB；本轮候选启用 `ENCODER_FEEDBACK=1, TEST_ABZ=1`，仍是原50MHz ADC/AXI、100MHz PWM、5MHz转换和500转换/反馈帧。ABZ源码直接引用原 `integration/rtl/ax03b1/ax03b1_abz_receiver.sv`，没有第二份解码器。

在phase0实际ADC采样沿锁存已注册count、ready、Z seen/count/tick、illegal_count及整组编码器配置；同沿AB/Z接受读取更新前状态。元数据在phase4随原码身份送入七事件管线。既有两级同步及两拍稳定资格条件保留，锁存的是经过这些延迟的数字状态，不能称为无延迟物理位置。电流一拍结果先冻结，角度生成路径完成后再与其会合发布，sample_id/tick仍是采样身份而非发布时间。

电角度权威源 `simulation/encoder/encoder_angle_step.m`，组件 `AXU5EV_Encoder_Components/Encoder_Angle`，新HDL壳链接引用它，生成入口 `encoder_generate_hdl.m`；未保存用户修改的原共享库。输出以int64存储Q32弧度，低40位与既有FOC有符号40/Q32端口匹配，本轮不连接FOC。首次ready/手动位置零点变化以signed-modulo(count-zero)建立参考；之后将每帧模2^32增量连续化，电周期内相位按30000count取余。仅更新电相位偏置/版本不重建连续相位，反向将已保持的无偏置相位取反后继续累计，软件也保留连续位置原点。每次计数变化必须严格小于2^31count，恰半圈歧义失效并重新建立状态。机械位置零点、电相位偏置分开；Z仅观察。

数字TEST尺度为AQM30mm电周期、每有效解码count为1μm，得到30000count/周期；不再乘除4，不改旧AUM参数。相位偏置以count表达，正方向结果为 `(连续相位 + 偏置) mod 30000`，反向先对计数方向取反再加偏置。Q32系数和公布量化误差见新数值源/验证。物理分辨率尚未实测。

同一ADC AXI基址0x80000000，快照BEGIN/epoch/flags协议不变。新identity `0x454e4346`（ENCF）、schema2、epoch `0x454e0002`，41字；最后word40在字节地址 **0xac** 响应完成时释放，旧word31/0x88不再释放。旧字段含义保留，以下为新增或启用字段：

| payload字 | 内容/单位 |
| --- | --- |
| 2 | 原质量位；新增bit9 encoder ready、10 Z seen、11 angle valid、18 TEST_ABZ；bit17 physical_link_verified仍0 |
| 3 / 4–5 | 转换编号sample_id（正常帧+500）/50MHz sample_tick（正常帧+5000） |
| 16 / 17 / 18–19 / 20 | 原始模2^32 count / Z锁存count / Z锁存tick / illegal_count |
| 27 / 28 | 既有稳定资格2拍 / 电流生成延迟1拍 |
| 29 | 角度生成结果由父模块消费的延迟34拍；生成输出在接受沿后第33拍NBA更新可见，父模块下一沿捕获 |
| 32–33 | 电角度int64 Q32弧度，低字在前 |
| 34–37 | 本帧配置version、zero_count、phase_offset_count、reverse（0正1负） |
| 38 | bit0 encoder ready、bit1 angle valid、bit2 TEST_ABZ |
| 39–40 | counts/electrical period、nm/effective count（显式TEST尺度） |

配置写地址0x140/144/148/14c分别为上述zero/phase/reverse/version，0x150 bit0提交整组、bit1运行TEST_ABZ。提交冻结，不受后续shadow写影响；在下一个选中phase0采用并随该帧传递，pending时第二次提交返回SLVERR。原电流0x100–118及PWM基址0x80001000/寄存器语义保留。配置version由调用者显式递增。

本候选ABZ外部输入在BD接常量，内部TEST源默认停止，手动允许后每500个50MHz拍输出一个合法正向转换（名义10μs），Z为step计数bit5；停止保持AB/Z状态。测试源位于原接收器之前，不绕过同步/解码链。没有ABZ外部XDC、驱动板/电机接线或物理许可。唯一新操作说明 `firmware/r5/encoder_feedback/FIRST_RUN_ZH.md`；本轮新结果以 `verification/encoder_feedback/results.json` 和HANDOFF首节为准。下列PR37/ADC证据均为历史基线。

Issue34 在原工程增加独立 PWM 域，未复制 ADC 工程。新分支普通 merge 纳入 main `811dd56`（PR33）及 `bb6314c`（PR36），也保留先前本地发布历史；main 未被自动更新。下文 ADC 整理说明是 Issue35 已审查基线；最新验证以 `verification/pwm_adc/results.json` 和 HANDOFF 首节为准。

## PWM/ADC 100MHz 增量

`scripts/pwm_adc_build_hw.ps1` 设置 `MC_PWM=1` 后仍调用同一个 `build.tcl`/`sources.list`/`bd/adc.tcl`。`bd/pwm_clock.tcl` 只增加 Clocking Wizard、PWM 模块和 PWM ILA。实际 IP 读回 MMCM M=24、D=1、O=12，PS 元数据 49.9995MHz → 99.999MHz，严格2:1；不是实测晶振频率。PS 分频、ADC 原复位/时钟、J15 约束未迁移，未接外部200MHz。

载波用共同相位索引 `phase=0..9999` 编码三角波 `phase<=5000 ? phase : 10000-phase`；因此峰值5000、整周期10000拍，无端点多算。三相比较尺度0..5000，无死区请求高拍数精确2*C；0/100%单列。`rtl/pwm/pwm_timebase.sv`、`pwm_three_phase.sv` 负责相位/整组采用及六路互补死区；`rtl/axi/pwm_config_bridge.sv` 负责单槽冻结提交与状态握手。编译期频率/周期/上下死区集中于 `pwm_timebase.sv` 的 `pwm_parameters`，由100MHz、10kHz、上下1000ns推导10000拍/100拍；不增加运行时调频。上下开通死区各100拍，按实际元数据约1.000010us；周期约100.001000us、PWM约9.9999kHz。仅数字测试参数。

| 相对于选中 ADC 采样沿 | 行为 |
|---|---|
| -40ns（名义） | 原50MHz域注册 look-ahead anchor；仅新增输出，不更改原采样计数 |
| -30ns | PWM第一次收到新的 anchor 沿，启动相位4997；后续anchor不重置载波 |
| 0 | ADC送出时钟上升，选中转换身份sample_id；PWM相位5000峰值 |
| +80ns | 原phase4捕获窗口；身份在七次转换事件管线推进 |
| +1480ns | 对应样本的第七转换返回，在接收器输出 pair_strobe/原码/原sample_tick |
| +1500ns | 原数值一级输出寄存更新、result_strobe；valid另行标记是否已校准 |
| +50us | 下一谷值采用已pending的三相组；没有新组则保持 |

表是逻辑边沿合同，物理传播及SDF间隔另记结果。上电/失锁后等待一个完整的新anchor沿才对齐，未对齐时无输出许可；之前的ADC帧仍正常采集。PWM禁止不停止载波或ADC。sample_tick单位仍50MHz，PWM相位单位100MHz，不直接相减。

### 配置、反馈及优先级

实际 BD 地址 ADC `0x80000000/4KiB` 保留，PWM `0x80001000/4KiB`；R5构建再从实际BSP取得宏。原ADC冻结payload布局不改。

| PWM字节偏移 | 语义 |
|---|---|
| 0x00 | ID=0x50574d01 |
| 0x04 | bit0 online、1 busy、2 received、3 completed、4 cancelled |
| 0x08 / 0x0c | 最近确认接收 / 最近确认采用的序号 |
| 0x10/14/18/1c | 三相暂存C / 用户序号 |
| 0x20 | 写1 COMMIT；busy或未online拒绝SLVERR，不覆盖冻结组 |
| 0x24 | 许可bit6 global，bit[2:0]三相H，bit[5:3]三相L |
| 0x28/2c | 取消 / 拒绝计数 |
| 0x30/34/38 | 最近确认采用的C三相（历史快照，不是实时相位） |
| 0x40/44 | 周期10000 / `{low_dead=100,high_dead=100}` |

一次完整提交冻结39位三相和序号；目的域确认接收后仍等谷值采用。同一谷值沿刚接收到的新组留下一谷值，后续暂存写不污染pending。busy包含握手返回清理阶段；ACK接收与实际采用分开。采用序号/组由保持握手返回，不裸传10ns脉冲或逐位同步拼组。

优先级：复位/失锁/数字快速禁止关闭输出并清待开通状态；常规许可下降到PWM域后下一拍内关闭；许可上升只在谷值生效并重新计死区。许可只能筛选互补请求，不能强制导通。失锁取消在途握手，50MHz侧清许可，恢复不自动重试/使能。数字fast_inhibit端口在RTL覆盖，本候选外部故障引脚未确认、BD固定0；实际R5用许可0禁止。LOCKED异步关断无需PWM时钟仍跳动。新域复位以两级下降沿寄存释放，至正常上升沿逻辑保留半周期，相关setup/hold/recovery/removal仍由工具检查；不放宽例外。

本机 BASIC 许可拒绝两个 ILA（hardware_01 原日志保留），采用候选仅保留100MHz PWM ILA，原ADC50MHz原子快照观察仍可用；不把50MHz探针当作PWM毛刺验证。ILA debug低位：H[2:0]、L[5:3]、phase[19:6]、valley20、peak21、started22、accepted23、applied24、pending25、请求[28:26]、源许可[35:29]、active_seq[67:36]、active_C[106:68]。

SDF从同一候选导出功能PL边界，按[PG172](https://docs.amd.com/api/khub/documents/w1BckBqYd0w2WsdXTPu1og/content)将不支持仿真的ILA/debug hub仅在内存中置为black box；不重布线、不覆盖检查点，完整STA与bit仍包含调试IP。PS时钟/复位和AXI主事务源由测试台替代，SmartConnect及功能互连保留。SDF观察的是候选真实路由内部H/L节点；外部PWM引脚未导出，因此这些间隔不是驱动板或外部管脚的实测死区。ILA采集操作仍待后续手动验证。

外部六路未导出到J16，驱动缓冲、极性、配对和上板验收均PENDING；未连接功率输出/ABZ/FOC/Runtime。唯一操作说明为 `firmware/r5/pwm_adc/FIRST_RUN_ZH.md`。原厂文档能力参考：[PG065时钟输出配置](https://docs.amd.com/r/en-US/pg065-clk-wiz/Configuring-Output-Clocks)、[UG835 SDF导出](https://docs.amd.com/r/en-US/ug835-vivado-tcl-commands/write_sdf)；实际结果需看本次工程证据。

### 本轮离线验收

候选 `.runtime/pwm_adc/hardware_05` 完整综合/布局布线、bit/ltx/含bit XSA已完成；新R5 Workspace `.runtime/pwm_adc/vitis_02` 构建及A53 FSBL/R5 ELF/Launch被动检查PASS。模型原三条断言恢复后只运行一次：42项、49×14一级延迟、4观察帧PASS。短RTL：PWM 694175检查/30谷值，接收器前ADC场景135检查/10帧，原B3 2064帧含两轮1024与restart，均PASS。

| 完整候选STA项目 | 最差余量ns |
|---|---:|
| setup WNS / hold WHS / pulse WPWS | 2.419 / 0.015 / 4.000 |
| 50→100最大路径（本次最差为reset recovery） / hold | 3.359 / 0.016 |
| 100→50 setup / hold | 7.827 / 0.716 |
| ADC输入 setup / hold | 2.419 / 5.280 |
| 全设计适用removal（debug hub） | 0.091 |

TNS/THS/TPWS及失败端点均0；no_clock、未约束内部端点、no_input_delay和partial_input_delay均0。两项no_output_delay是已定义的ADC转发时钟输出。最差setup为ADC B[0]到接收寄存器，20ns边沿要求、uncertainty 0.209ns；最差hold为原冻结快照第511位，不能拿WHS推导提频空间。28个J15管脚匹配，26路输入仍为原min2/max10ns工程预算，未增加或放宽例外。

55项DRC warning无error/critical：原数值DSP流水建议49、LUT3、IOB2、debug未连接负载1；methodology保留reset组合LUT与26项TIMING-18（数据实际按200ns转发ADC时钟约束，非漏约束）、IP查询/时钟位置建议。CDC告警4项仅vendor debug hub TCK，相关50/100MHz功能路径完整计时；vendor bus-skew最差+9.524ns。未为消除建议改数值流水或采样合同。

SDF slow/max与fast/min均PASS，各515检查、9次选样、37次开通边沿、6完整周期，1ps精度、注释成功且无告警/时序违例/未知失败。内部关断间隔slow为999.977–1000.023ns、fast为999.991–1000.009ns；ADC引脚采样沿相对内部峰值分别固定晚2.772ns/1.332ns（路由传播，无整拍偏移或漂移）。两角均完成阶跃、禁止、失锁取消及显式恢复。动态边界不覆盖PS执行/调试采集，也不代表全部四种PVT列组合；完整覆盖仍依靠STA。精简证据为 `verification/pwm_adc/results.json`，采用 `sdf_pl_slow_02` / `sdf_pl_fast_02`；早期失败/中断输出全部保留。板卡/驱动板/电机操作NOT_RUN，外部接口与ILA实际采集PENDING。

## 模型：一份算法，一个共享组件

在 MATLAB 中（通过 MCP）打开：

```matlab
addpath('D:/Project/AXU5EV/simulation', ...
        'D:/Project/AXU5EV/simulation/adc', ...
        'D:/Project/AXU5EV/simulation/real_io');
open_system('AXU5EV_ADC_HDL');
open_system('AXU5EV_ADC_Observer');
```

- **改数值算法**：唯一权威源仍为 `simulation/real_io/ax03b1_current_preprocess.m`，未改公式。库中 MATLAB Function 只调用该函数，没有脚本复制。
- **改算法端口/寄存器**：`simulation/AXU5EV_PL_Algorithm_Library.slx` 的 `Current_Preprocess`。保留原18个输入、14个输出以及各输出一级 UnitDelay。
- **HDL 壳/后续算法顶层复用边界**：`simulation/AXU5EV_ADC_HDL.slx`。raw/采样资格/校准控制从左输入，电流/状态从右输出，内部是库链接。后续顶层引用同一库块，不复制算法；本次未接旧FOC。
- **观察验证壳**：`simulation/AXU5EV_ADC_Observer.slx`，同样为库链接。激励、ADC流水参考、理想ABZ参考和显示均属 SIM_ONLY，不整体综合。

原 `simulation/AXU5EV_RealIO_NoPower.slx` 有用户本地修改，原样保留，不作为活动HDL生成源。新观察壳取自 PR33 已审查版本并改成库链接，未取用或覆盖用户未提交的模型/参数。旧名称仅保留历史，不维护第二套活动算法组件。

## 生成与验证

唯一 ADC HDL 生成入口：

```matlab
adc_generate_hdl('D:/Project/AXU5EV/.runtime/adc_consolidation/matlab_01');
```

实际 DUT 为 `AXU5EV_ADC_HDL/Current_Preprocess`，生成文件为 `generated/adc/AXU5EV_ADC_HDL/Current_Preprocess.sv` 与 `Numeric_Algorithm.sv`。生成配置集中在该函数：SystemVerilog、同步高有效reset、clk_enable、Oversampling=1、关闭分布式/时钟率流水优化；`clk_enable` 在 RTL adapter 中恒1，sample_strobe 单独推动采样消费。生成器附带的模型/报告留本地，源清单只收上述两份SV，不手改生成代码。

`adc_validate_component(新结果目录)` 复用原42项数值检查/49行向量，对库链接壳14路输出检查原有一级延迟，再运行观察壳。`adc_run_observer(true,新结果目录)` 顺序调用验证及唯一生成入口；旧 `ax03b1_run_no_power` 仅薄转发。

```powershell
./scripts/ax03b3_run_rtl.ps1 -RunDir .runtime/adc_consolidation/b3_rtl_01
./scripts/ax03b1_run_rtl.ps1 -Suite current -RunDir .runtime/adc_consolidation/current_rtl_01
```

这些目录为本次已占用证据目录；重跑需另取新目录。旧 `generated/ax03b1/` 为历史生成记录，活动工程与短测试不加载它。

## PL：统一源清单与装配

唯一活动板级入口为 `hardware/axu5ev/motor_control/build.tcl`，通过 `sources.list` 分开收集手写RTL、两份生成RTL和XDC；`bd/adc.tcl` 装配 PS、SmartConnect、时钟复位、ILA。复用现有厂商PS配置，不复制厂商工程。PS基址与R5寄存器布局、冻结读取协议不变。

```powershell
$env:AX03B3_TEST='0'  # 默认REAL；TEST明确设1，使用另一个新目录
./scripts/ax03b3_build_hw.ps1 -Stage validate -Output .runtime/adc_consolidation/hardware_real_01
```

本次候选执行 base/integrate、validate_bd_design、综合和综合设计约束核对，**不生成新可上板 bit/XSA**。集成中产生的 prebit XSA 仅为候选元数据，未替换R5配置。已有 PR33 bit/ltx/XSA/ELF仍在原路径；本次实现、R5重建、板卡操作均 NOT_RUN，不沿用旧布线报告宣称新候选完成布线。

采样语义保持：名义50MHz逻辑、10拍一次约5MHz转换、500次转换选一帧约100µs；不是500次平均，尚未与PWM同步。七转换事件身份/tick关联保留；一级结果寄存与result_strobe、numeric_valid区别不变。双路独立1024合格帧校准、完成当帧无效、Q16偏置/Q24电流和宽结果重构c相均不变。REAL/TEST共用处理链、来源标记与physical_link_verified=0保留。真实零流/增益/极性/噪声仍待后续物理验证。

## 旧 → 新路径

| 旧路径 | 当前入口/落点 |
|---|---|
| `AXU5EV_RealIO_NoPower/Current_Preprocess` | `AXU5EV_PL_Algorithm_Library/Current_Preprocess`，由ADC_HDL和ADC_Observer库链接引用 |
| `simulation/real_io/ax03b1_run_no_power.m` 的生成段 | `simulation/adc/adc_generate_hdl.m`；旧入口薄转发 |
| `generated/ax03b1/AXU5EV_RealIO_NoPower/*.sv` | `generated/adc/AXU5EV_ADC_HDL/{Current_Preprocess,Numeric_Algorithm}.sv` |
| `integration/rtl/ax03b1/ax03b1_adc_receiver.sv`、`ax03b1_current_adapter.sv` | `motor_control/rtl/adc/` 同名文件 |
| `integration/rtl/ax03b1/ax03b1_snapshot_axi.sv` | `motor_control/rtl/axi/ax03b1_snapshot_axi.sv` |
| `integration/rtl/ax03b3/ax03b3_adc_observer.sv` | `motor_control/rtl/top/ax03b3_adc_observer.sv` |
| `hardware/axu5ev/ax03b3_adc.tcl` | 薄转发至 `motor_control/build.tcl`，装配实现在 `bd/adc.tcl` |
| `hardware/axu5ev/ax03b2_adc_j15.xdc` | 薄转发至 `motor_control/constraints/adc_j15.xdc`，顶层显式加载 |

表中 `motor_control/` 均相对 `hardware/axu5ev/`。B1/B2历史重现脚本已同步共享RTL路径；B2 raw-only板级装配保留为历史复现，非另一个活动B3入口。R5仍在 `firmware/r5/ax03b3/`，配置/应用和既有工作区保持原路径。精简结果见 `verification/adc_consolidation/results.json`。

本次实际结果：模型/HDL检查0错误0警告；42项数值检查及49×14输出一级延迟对比通过，新观察壳4×20字段与既有验收记录一致；B3短RTL2064帧/两轮1024及restart检查、定向数值RTL25检查通过。统一REAL候选BD验证/综合通过，4手写+2生成+1XDC均唯一加载，28引脚/LVCMOS33及两路200ns送出时钟命中，26输入min=2ns/max=10ns覆盖完整，寄存器基址0x80000000/4KiB及PL元数据49.9995MHz保留。

综合态 `check_timing` 保留no_clock=1235（1227为debug hub所驱ILA引脚，8为PS8外设输出时钟引脚）和unconstrained_internal_endpoints=1746（全部位于adc_ila）；no_input_delay/partial_input_delay/generated_clocks问题数均0。本次只核对综合态装配和约束加载，不宣称debug/板级物理时序完成签核，没有为消除这些条目修改约束。
