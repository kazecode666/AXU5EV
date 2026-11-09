# Issue34 — latest execution contract

Source: https://github.com/kazecode666/AXU5EV/issues/34 (retrieved 2026-11-08/09).

## 最新执行方案：只提高PWM时钟，其他执行条件不变

用户已明确选择：**只把新PWM外设的逻辑时钟提高到名义100MHz，其他频率和算法不变。** 本文是更新后的Codex任务依据。旧正文中的50MHz PWM计数方案、评论6722219595中“外部200MHz统一重建50/100MHz时钟源”的候选不再作为本轮实施要求；保留旧评论作讨论历史。原评论要求的互补/死区/上下路许可及上板前仿真、时序验收仍保留。

**目标：** 在PR36整理后的统一PL工程内，实现100MHz三相PWM、整组更新、互补死区和输出许可，完成与既有50MHz ADC链的时序关联；顺手恢复PR36遗漏的观察断言。先固定duty和预设阶跃，无功率、离线交付。

**实施架构：** 保留当前PS输出的pl_clk0及其50MHz ADC/AXI路径，只新增Clocking Wizard/MMCM派生的2倍频PWM时钟和必要的50↔100MHz接口。ADC原数值源与生成RTL直接复用，R5只新增最小配置/观察，不接完整Runtime。

**来源：** 用户最新选择、《规划实机联调接口》中的PWM阶段范围、PR33/PR36及Review 5817918529、仓库现有ADC和模型参数。下述接口和测试安排是本轮设计，不是已实现/实测的事实。

本次只发布任务，没有启动本地Codex、改变源码/时钟、构建或操作板卡。任务文档随实施保存到`coordination/tasks/pwm_adc_100mhz.md`即可，不另开纯任务书或断言PR。

## 1. 范围冻结与方案选择

| 项目 | 本轮要求 |
|---|---|
| 现有PS→PL时钟及ADC/AXI逻辑 | 保持现有约50MHz配置、时钟来源与原复位路径 |
| 新PWM逻辑域 | 从原50MHz经专用时钟资源派生严格2:1的名义100MHz，仅驱动PWM及必要接口逻辑 |
| 外部200MHz差分时钟 | 本轮不接入，不新增AE5/AF5约束，不迁移现有50MHz时钟树 |
| ADC转换 | 保持约5MHz连续转换，每10个原逻辑拍一个转换周期 |
| ADC反馈帧 | 保持每500次转换一帧、名义100us；只做与PWM相位关联所必需的薄接口调整 |
| 电流预处理 | 原Q格式、公式、采样/配置/restart语义、一级输出寄存延迟不变 |
| FOC | 本轮不接入、不提频、不重新生成；保留既有50MHz、5000使能拍/100us合同 |
| PWM输出频率 | 仍名义10kHz，不是把开关频率提高到100MHz |
| R5 Runtime、外环、轨迹/对齐、PI及电机参数 | 全部不改；只新增最小PWM配置/观察应用 |

选择本方案是为了只增加PWM时间分辨率。全PL提频会改变已有接收/生成调度；更换外部参考源会扩大ADC和AXI时钟迁移范围，均不实施。

注意“其他不变”不等于不允许接线：PWM命令/状态跨频、复位/锁定和ADC相位关联是新增PWM必需的集成工作，但不能借机改采样率、数值算法或完整控制调度。

## 2. 基线与文件职责

本轮查询main仍为`811dd56364b6c27d8653d7d3ab8821dd2d497e17`。PR33已进main；PR36合并提交`bb6314c8a7ff17499ee7cb793c62fa046962e8e8`此前进入了PR33功能分支。启动时重新核实：main已含PR36就从main接续；否则在新的任务分支正常merge纳入已审查PR36成果，保留双方历史，不自动更新main，不重复复制实现。最终Draft PR以main为目标，区分已审查基线纳入与本轮新增变更。

在现有`D:/Project/AXU5EV`工作区开展，不另clone/worktree，不强制stash/reset/clean，不覆盖未提交/未保存模型。真实冲突只报告具体文件，不替用户丢弃修改。

复用入口：
- `simulation/adc/adc_validate_component.m`：仅恢复观察断言。
- `simulation/AXU5EV_PL_Algorithm_Library.slx/Current_Preprocess`、`simulation/real_io/ax03b1_current_preprocess.m`、`generated/adc/AXU5EV_ADC_HDL/`：原数值来源与生成物，本轮不改。
- `hardware/axu5ev/motor_control/build.tcl`、`sources.list`、`bd/adc.tcl`及原`rtl/adc/`、`rtl/axi/`、`rtl/top/`、`constraints/adc_j15.xdc`：同一工程增量集成。
- B3原校准/冻结快照寄存器和R5观察基础：保留布局和语义。

新增文件建议（已有等价入口则复用，不为命名重复造模块）：
- `hardware/axu5ev/motor_control/bd/pwm_clock.tcl`：Clocking Wizard及新PWM域复位连接。
- `hardware/axu5ev/motor_control/rtl/pwm/pwm_timebase.sv`：共同载波与更新事件。
- `hardware/axu5ev/motor_control/rtl/pwm/pwm_three_phase.sv`：三相比较、互锁、死区、许可。
- `hardware/axu5ev/motor_control/rtl/axi/pwm_config_bridge.sv`：最小寄存器/整组提交与跨频交接，可按清晰职责最小拆分。
- `verification/pwm_adc/`及一个短仿真入口：新增PWM/采样相位检查，不建通用验证框架。
- `firmware/r5/pwm_adc/`：复用现有BSP组织的配置观察应用。
- `.runtime/pwm_adc/<新的未占用目录>/`：原始仿真、硬件、时序与软件构建结果，旧产物不移动、不覆盖。

## Task 1 — 基线接续并恢复三条既有断言

在原Observer帧检查处恢复：

```matlab
assert(frames(1,4)==0 && frames(2,4)==1250, ...
    'Sample-time position association differs.');
assert(frames(1,19)==0 && all(frames(2:end,19)==1), ...
    'Sample-time Z event association differs.');
assert(all(frames(:,20)==0), ...
    'Legal AB stimulation produced illegal transitions.');
```

仅适用于原合成刺激；不把0/1250等写成真实硬件或新PWM场景要求。保留已有49×14输出延迟、帧数/valid、sample_id和零和检查，不改模型或刺激来迁就断言。

运行一次`adc_validate_component(新的结果目录)`并记录结果。此项独立小提交，但随同一个PWM PR交付；不因此重生成HDL或重建旧硬件。

## Task 2 — 只新增100MHz PWM域与确定的跨频接口

### 时钟与启动

- 原`pl_clk0`仍直接服务现有ADC/数值/AXI链。新增Clocking Wizard/MMCM，以该时钟为输入，经专用全局时钟资源产生2倍频PWM时钟；不在普通逻辑中翻转寄存器来“倍频”，不切换外部200MHz。
- 读回真实IP配置和时钟报告。现有元数据约49.9995MHz时，2倍频约99.999MHz；这不是新测得的晶振频率。使用严格整数比例，不为凑精确100.000MHz而使两个域产生漂移，不修改现有PS分频。实际工具可用配置先验证，不能猜VCO/原语参数。
- 使用LOCKED建立新域的复位/禁止条件；复位释放同步到对应域。未锁定时不输出，失锁时关闭输出并清待开通状态，不能依赖已经停掉的PWM时钟才产生关断沿。锁定恢复后仍需显式使能及确定边界，不自动恢复旧输出许可。不要因此让原ADC链每次PWM启停都复位。
- 明确新域与原域的真实边沿关系、复位首相和启动对齐；同源不等于计数器自然同相。Clocking Wizard的时钟模型/约束进入同一个工程，检查相关时钟的setup/hold，不将50/100MHz整组声明为异步来掩盖路径。

### 50MHz配置→100MHz采用

50MHz侧暂存三相比较值及整组配置，COMMIT后冻结一次完整请求；100MHz侧接收为pending，只有规定谷值才成为active。多字段采用保持＋握手等最小可靠方式交接，禁止把每个位单独双触发器同步后拼成一组。

一个待提交/待采用槽即可。软件能区分busy、接收/取消状态、实际采用序号；busy时新COMMIT拒绝，不悄悄覆盖，待生效组不受后续暂存写污染。ACK接收与PWM真正采用不是同一个概念，状态不能混写。复位/失锁取消未完成请求，不让遗留请求在恢复后意外生效；不加自动重试或队列。

100MHz→50MHz的状态和事件不能裸送单个10ns脉冲；采用具有明确捕获保证的事件/快照交接。对相位敏感的采样事件使用确定性调度，不用一个可能改变到达时刻的普通同步脉冲直接决定采样相位。

**本任务验证：** 先检查倍频配置、锁定/复位和一次完整跨频请求，覆盖两种相对到达相位、busy、取消、实际采用反馈。若工具或时序不支持预期配置，报告具体限制，不私自把ADC提频/换源或回退PWM频率并宣称完成。

## Task 3 — PWM波形与许可逻辑

### 计数和参数

- 中心对齐、三相共同上下计数载波。名义100MHz下完整周期10000拍，峰值5000，周期不能变成10002拍；PWM仍约10kHz。
- 先用整数比较尺度0..5000，三相各13位足够；明确duty=C/5000。稳定、无死区时一周期有效高侧请求拍数应为2*C，0/100%明确处理，不能因相等比较带来隐含一拍偏差。未来FOC定点duty转换不在本轮实现。
- 谷值每完整周期只采用一次pending组，无新组保持active。同一个100MHz边沿刚接收的新组不在该沿生效，留到下一谷值；所有边界判定以目的域实际接收时刻为准，不把R5写入时刻当作已到达PWM域。
- 上/下路开通死区分别参数化，首版均100拍、名义1us，仅数字测试起点。配置由名义时钟、周期/死区参数集中推导，报告用实际工程频率换算；本轮不做动态调频或运行中更改死区。

### 输出行为

- 六路为三个桥臂的互补请求，经死区与互锁后输出；上/下路不得同时有效。短于死区的请求撤销后不得补出迟到脉冲。
- 具备全局使能、三相上路许可和下路许可、数字快速禁止及复位。许可只能允许/屏蔽既有PWM请求，不能作为绕过互锁的强制导通。
- 复位/未锁定/快速禁止/关闭许可优先于正常提交。常规disable到达PWM本地域后最迟下一拍关闭，不等待谷值；其AXI及跨频传输延迟须另列，不能声称R5发指令后10ns必定关断。
- 0→1重新允许在约定谷值生效，重新执行必要死区；关闭时清待开通状态，不能复活旧计时。使能/上下许可变化与已提交参数的优先级明确，不以组合门直接放行一个正在为高的内部请求。
- 常规PWM禁止不得停止原ADC转换；载波在时钟锁定期间持续运行。0/100%测试仅验证数字边界，不作为功率级允许长期导通的声明。

**短测试通过条件：** 25%/50%/75%、一次三相阶跃、边界前后/同沿提交、pending保持、0/100%及死区附近窄脉冲、上下许可组合、运行中禁止/重新使能、复位/失锁均有自检。对最终六路检查互斥和关断间隔，计数必须实际执行而非只打印PASS；无需电机plant、长时FOC回归或通用异常矩阵。

## Task 4 — 与原ADC采样相位关联，不改变ADC接收和数值条件

- 保持原50MHz、10拍ADC转换周期、原捕获窗口、七转换事件身份管线、每500转换一帧及数值一级输出寄存；sample_id/tick单位与旧快照一致，不能把它悄悄换成100MHz tick。
- 利用同源2:1关系，在启动阶段建立PWM峰值与规定ADC采样沿的确定关系；谷值更新在其半周期之后。优先对齐新PWM时基到原50MHz采样安排，只做必需的薄相位接口，不另造自由运行“100us软件定时器”。
- 相位协同必须在采样之前确定，不能在pair_strobe/result_strobe到达后才触发那次模拟采样，也不能每帧随意清PWM计数造成周期伸缩。跨频与注册延迟计入简短时序表；若并非峰值精确同沿，明确固定偏差并调整调度/报告，不能隐藏一拍延迟。
- config_apply/restart仍不得与样本消费冲突；clk_enable保持原合同，不能每100us只使能一拍。result_strobe与numeric_valid分清，校准完成当帧无效等语义不变。
- 用接收器之前的合成两路转换编号和已知七转换延迟，在实际5000个50MHz拍/10000个PWM拍关系下核对多个完整帧：每帧仅一次选样，原码与sample_id/tick及电流结果匹配，选样相位固定无漂移，PWM谷值采用事件对应明确。不要仅靠接收器之后的B3 TEST注入验证接口时序。
- 原B3 TEST标记与physical_link_verified=0保持；本轮duty来自测试配置，不由采样电流计算，不能宣称真实反馈→R5→FOC在同帧50us内完成。

新增PWM状态使用单独明确的100MHz计数/帧字段或统一转换后的时间，不能将50MHz和100MHz裸tick直接相减。允许必要状态寄存器，不改原冻结payload布局/字段含义。

## Task 5 — 统一工程、最小R5观察及三层验收

### 工程与外部边界

在现有build.tcl、sources.list和BD内加载新增PWM/时钟/接口逻辑，保持一个ADC实例和一套数值来源；不要复制第二个PS/ADC工程。数值源没改就不重生成HDL。ILA按各自时钟域组织，不能用50MHz探针代替100MHz窄脉冲/毛刺验证。

增加不冲突的PWM寄存器/配置状态，实际绝对地址从BD/XSA/BSP取得。新R5观察应用只写比较值、提交、许可/禁止和低速读取状态；不改Runtime/外环/中断调度，不通过串口决定实时PWM边沿。复用旧BSP构建组织，在新Workspace生成匹配新XSA的应用；旧ELF/FSBL/Launch不覆盖。

J15引脚和ADC时序预算不变；若新增顶层改变层级，必须检查旧XDC对象仍命中，不能为通过而放宽。J16只在原板卡资料能确认FPGA管脚时导出逻辑观察信号，说明内部A_H/A_L等与外部驱动PWM1..6的映射是否已确认。外部驱动缓冲、极性/配对尚无依据时，用内部ILA方案交付并将外部输出验收标PENDING，不猜引脚、不把PL逻辑电平当已允许直驱MBDL4。功率相关ENCON/RELCON及外部运行许可保持禁止。

### A. RTL功能仿真

复用前述PWM与ADC短测试，以及受顶层/相位接口改动影响的B3集成检查。保留两轮1024校准完成和restart断言；不重跑PR24/历史全量。先建立预期断言，再实现相应逻辑；每项给出实际执行检查数量和失败退出，不只目视波形。

### B. 采用候选的完整布局布线与STA

新设计实际综合、布局布线。原ADC仍50MHz也会受到新布局/时钟资源使用影响，因此要在新整体实现内重新检查，不能引用PR33旧WHS作为新候选结果。

完成setup/hold/pulse-width和适用的recovery/removal、相关跨频路径、输入输出与时钟检查：WNS/WHS/WPWS>=0，TNS/THS/TPWS=0，无应检查路径失败或遗漏。查看最差起终点、边沿、clock uncertainty及例外；WHS不能用来推导可提频空间。

功能相关的no_clock/未约束路径、非法跨域及关键DRC必须解决；确有静态/硬核/未接外部接口边界时如实注明，不伪造外部时序预算、不宣称所有物理接口已签核。不用宽泛false_path、异步时钟组、无依据multicycle、降低不确定度或放宽ADC预算来凑PASS。适用的局部例外须有实际语义和边沿证明。

### C. 定向实现后SDF时序仿真

以该候选真实路由网表及匹配SDF，对PWM边沿、死区、提交、许可/禁止、复位和采样跨频边界运行短场景。至少slow/max检查建立侧、fast/min检查保持侧；这不等于宣称动态仿真覆盖所有PVT组合，完整时序覆盖仍靠STA。核对SDF注释覆盖、仿真精度、时序检查和输出未知态，不能使用无SDF功能仿真冒称已完成。

RTL中的100拍死区与实现后的引脚边沿间隔分开记录：路由/输出传播差会影响实际间隔，应核对预算及无重叠，不宣称物理间隔精确等于1us。若PS/IP不支持所需网表仿真，限定到从真实候选导出的可仿真PL边界并写清未覆盖部分；无法取得必要证据则标未完成，不宣称可上板。

三层通过才具备请求下一步无功率板测的条件；本任务本身仍不发现/连接/复位/下载/运行板卡。新bit/ltx/含bit XSA及必要ELF只离线构建；原始报告放新结果目录，精简证据放`verification/pwm_adc/`。

## Task 6 — 交接、Review和停止点

提交一个以main为目标的独立Draft PR，附：精简时钟/采样/采用时序表、寄存器和上下许可优先级说明、三层验证结果、最差时序路径与未完成项、一份明确bit/XSA/ELF/Workspace及后续手动观察步骤的操作说明。优先更新既有motor_control README与HANDOFF首节，不写多套重复报告。任务书与实现一起保存。

断言恢复、时钟/接口、PWM、集成验证按可审查的小提交组织，不要求分成多轮PR。不要自动合并/关闭Issue或继续ABZ/FOC。下一独立任务才是ABZ—位置—电角度—R5测速，再后续全链集成与AQM参数恢复。

全程不安装升级工具、不改旧FOC/Runtime、电机参数/PI、ADC算法/频率，不引入滤波、DMA、以太网、HLS替代、看门狗、自动恢复或通用防御框架；保留全部旧Workspace和原始数据。

## 外部工具依据（仅说明能力，不是本工程通过证明）

- AMD PG065 Features / Configuring Output Clocks：Clocking Wizard按输入输出要求选择MMCM/PLL倍分频，必须回读实际频率与相位配置。https://docs.amd.com/r/en-US/pg065-clk-wiz/Features ，https://docs.amd.com/r/en-US/pg065-clk-wiz/Configuring-Output-Clocks
- AMD UG949 Using Clock Modifying Blocks：LOCKED、复位、相位和时钟资源连接。https://docs.amd.com/r/en-US/ug949-vivado-design-methodology/Using-Clock-Modifying-Blocks-MMCM-and-PLL
- AMD UG900：实现后网表/SDF、slow/max与fast/min检查及动态仿真覆盖边界。https://docs.amd.com/r/en-US/ug900-vivado-logic-simulation/Running-Timing-Simulation-Using-Third-Party-Tools

