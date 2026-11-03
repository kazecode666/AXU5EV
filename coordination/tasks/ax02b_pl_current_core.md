# AX-02B — 5EV PL电流核实施计划

> 接续用户已合并的 PR #18；合并提交 `db927b4d24720b69a0c03da3dd11ce61f41829a9`。本文记录Issue19的任务及验收边界；本轮实际离线执行结果见[主报告](../reports/ax02b_pl_current_core.md)，不表示已经上板。由 Codex 在现有本地工作区实施，ChatGPT Review，用户决定合并；不另开纯任务书 PR。

**目标：** 将已验证的 p3 定点电流 FOC 及其帧封装落实到 5EV 目标，保持算法和采样语义，完成必要的数值/帧合同检查，以及目标器件上的综合、布局布线、资源和内部时序验证，为 AX-02C 的真实 R5—PL 交换提供可集成模块。

**架构选择：** 首版保留 50MHz 快时钟、100µs/5000拍控制帧和采样后50µs/2500拍 duty应用参考边界。建立独立的5EV目标生成/实现入口，复用现有p3源、配置、RTL比较依据和帧封装。不同时开展提频、算法优化、AXI、ADC、编码器或门极PWM。

**工具：** 沿用项目已有 MATLAB/Simulink/HDL Coder R2026b、Vivado 2026.1；启动时核对本机实际版本，不安装/升级工具。MATLAB/Simulink操作沿用MCP。

**需求与来源：** PR18最终Review已经指定后续转入AX-02B；总体顺序见 Issue #15。具体源与时序依据为 `baselines/pr53_p3/`、`generated/legacy_m3_p3/`、`integration/rtl/axu5ev_foc_frame_top.sv`、`integration/ps_pl/INTERFACE.md`、`hardware/axu5ev/ALINX_BOARD_FACTS.md`。Issue #11是后续架构讨论，不在本轮顺带实施。

## 1. 当前基线与实施选择

PR18的ETH-02已通过两个实板场景：current_motion 64536帧、current_alignment_reset 43100帧；两者41字段零失败，100µs时序和板报交叉通过。该结论属于“以太网上传→停GEM网络→原R5回放→恢复网络下载”，不是网络与控制并发，也不是实际PS—PL闭环。

已有p3配置回读仍是Artix7/xc7a200t/fbg484/-2，旧时序结果不能作为5EV实现证据。现有帧封装已经提供输入保持和输出捕获，优先复用，不从头编写FOC。

采用“独立5EV候选＋必要等价检查＋模块级实现”，不采用以下两种路径：
- 仅复制旧Artix报告、修改器件名称后宣布迁移完成。
- 一次合入AXI、ADC、位置采集、PWM和实时以太网，导致问题无法隔离。

本轮不要求把FOC核直接连接到板卡IO；模块级实现通过不等于最终整机时序或硬件闭环通过。

## 2. 全局约束

- 算法唯一来源仍为Simulink/Stateflow；不得手改生成C/SV修补算法。不改PI参数、AW、限幅/死区顺序、定点位宽、舍入、饱和或三相独立采样语义。
- 不覆盖用户本地SLX/参数、未保存窗口、旧p3包、R1/ETH01/ETH02 workspace、ELF或任何原始板测数据。新工作集中在 `.runtime/ax02b/` 的未占用子目录。
- 在 `D:/Project/AXU5EV` 现有工作区创建实现分支；不额外clone/worktree，不自动stash/reset/clean、强制pull/push或批量清理。只确认当前基线包含PR18合并提交，不强制回退到该提交。
- 不默认重跑完整10→0→−2mm长时RTL闭环、两个ETH02板测、TTC ABA或旧学习回归。仅验证本轮新增或改变的部分；只有证据显示原有功能受影响才扩大验证。
- 不新增全库哈希清单、防御性框架、通用测试平台、GUI或教学工程。优先复用现有清单、checker和构建代码。
- 本Issue仅安排离线工作：不连接/发现/复位板卡，不下载bitstream/ELF，不启动电机，不写启动介质。功率级和硬件操作继续由用户另行明确授权。
- 不修改已通过的R5 Runtime、TTC映射、ETH02协议或网络策略；不提前引入A53应用、Linux、RTOS或新的PS—PL DMA方案。
- Issue #15的器件/PCB、冷启动条件及历史分阶段验收遗留项继续如实保留，不因PR18已合并而自动关闭或宣称全签。

## 3. 文件职责

以下新增名称为计划入口；若仓库/本地已有等价入口则复用，不能为目录命名重复造轮子。

| 位置 | 职责 |
|---|---|
| `baselines/pr53_p3/`、`generated/legacy_m3_p3/` | 只读的源、配置、RTL和既有验证依据 |
| `simulation/axu5ev_build_pl_target.m` | 独立5EV HDL生成入口；隔离构建配置并恢复用户会话 |
| `hardware/axu5ev/ax02b_pl_current_core.tcl` | 源清单、目标器件、OOC综合、模块级布局布线及报告 |
| `hardware/axu5ev/ax02b_pl_current_core_ooc.xdc` | 模块级时钟约束；与最终板级约束明确分开 |
| `integration/rtl/axu5ev_foc_frame_top.sv` | 优先原样复用；若确有硬件综合问题，只做有依据的最小封装修正，不改生成核 |
| `verification/ax02b/` | 必要的定向检查入口和精简结果；复用既有checker |
| `coordination/tasks/ax02b_pl_current_core.md` | 随实现PR版本化本任务，不单独开文档PR |
| `coordination/reports/ax02b_pl_current_core.md` | 一份主要报告：来源、配置、等价、帧合同、资源、时序、限制 |
| `.runtime/ax02b/` | 构建副本、生成RTL、Vivado工程/DCP、原始报告和日志，不提交大型产物 |

## 4. Task B1 — 核对来源、器件与可复用入口

**产出：** 可追溯的输入源及5EV候选配置，不以不明来源的当前模型覆盖已验收基线。

- [x] 只读检查当前工作区、工具版本以及PR18合并基线；识别用户未提交修改并保留。
- [x] 核对当前 `simulation/PMLSM_FOC_FixedPoint.slx` 与p3冻结来源的关系。默认以已验收p3源和配置为首版迁移基线；存在实际算法差异时记录差异，不自动混用当前参数和历史golden。
- [x] 查找现有生成、RTL比较和实现入口。旧项目只读；确有缺失时仅精选移植必要脚本及依赖，不复制整个旧工程。
- [x] 依据已记录的手册目标 `XCZU5EV-2SFVC784I` 核对Vivado合法part；候选为 `xczu5ev-sfvc784-2-i`，必须以本机 `get_parts` 实际结果确认。不得沿用厂商 `xazu5ev-sfvc784-1-i` 而不说明差异。
- [x] 区分“手册/既有平台选用的目标器件”与“实际芯片完整料号、PCB修订已签核”。后者证据不足时允许继续条件化的离线实现，但必须标为待核，不能宣布实物匹配或授权上板。

**通过条件：** 本轮源、p3配置、目标part、工具和用户修改的处理方式明确；不存在静默混用。

## 5. Task B2 — 独立5EV目标生成与构建入口

**输入：** B1确认的p3源和配置。**产出：** 本轮实际使用的RTL清单、生成设置回读和模块依赖。

- [x] 复用p3流水配置，在隔离构建副本/临时配置中设定5EV目标和50MHz；具体HDL Coder枚举从本机支持列表读取，不猜family/device字符串。
- [x] 保持Oversampling=5000及既有数值类型；不顺带优化流水、共享乘法器或修改采样率。同步reset、CE、PI_Reset和timing_restart的职责保持独立。
- [x] 实际生成一次独立5EV候选，记录配置和调度报告。与冻结RTL区分纯注释/路径变化和实际逻辑/相位变化；通用RTL相同是可接受结果，不为体现迁移而强行制造差异。
- [x] 优先复用 `axu5ev_foc_frame_top`，不要把XSI测试顶层、MEX或testbench综合进去。检查是否含7系列专用原语、旧IP或旧器件约束；有则按生成配置处理，不编辑生成算法。
- [x] 若新候选的输出相位、状态消费/提交或接口发生变化，先报告差异及影响；不得盲用旧314/315，或只移动采样点掩盖变化。

**通过条件：** 5EV目标入口可从明确源重建，实际综合清单与被验证RTL一致，用户活动模型和旧产物不变。

## 6. Task B3 — 最小必要的数值与帧合同验证

**输入：** B2实际候选和原有golden/checker。**产出：** 与本轮RTL绑定的定向等价及接口证据。

- [x] 优先复用既有测试向量/比较器，验证正常输入、参考变化、饱和恢复、PI_Reset及global reset的已有相关场景；验证三相duty位串以及必要的PI/AW状态/递推一致性。若RTL逻辑未变，不重新证明全部旧长时场景。
- [x] 核对九字段在规定边界共同锁存并保持完整5000拍。核心即使已出结果也必须继续运行完整帧，不能在第315拍后停CE或提前开始下一帧。
- [x] 若保留p3原调度，检查核心post-edge314、外寄存器edge315、frame_id递增和hold_violation=0；重新生成时以上仅为待验证预期，最终以实际证据为准。
- [x] 检查reset后duty=0.5和result_valid=0等既有语义。当前 `result_valid` 在首个结果后保持为1，不是每帧脉冲；新帧识别需结合frame_id，不得在后续接口中误用。
- [x] PI_Reset、global_reset与timing_restart分别验证各自既有行为；不赋予timing_restart清PI状态的新语义，不把0.5 duty称为硬件安全关断。
- [x] 测试结果必须有实际有效比较数量，错误返回失败；只在现有checker需要适配时增加与改动直接相关的最小反例，不另建测试套件。

**通过条件：** 相关位级/状态检查通过，帧序和保持检查通过；不把普通编译/烟雾测试当作等价证明。

## 7. Task B4 — 5EV综合、布局布线与内部时序验收

**输入：** B3验证的候选及帧封装。**产出：** 指定5EV目标上的实现DCP、资源、路由和时序报告。

- [x] 建立模块级OOC流程，覆盖核心及复用的帧封装，不创建ADC/PWM/AXI外设。运行真实综合、优化、布局及布线，而不是停在综合估算。
- [x] 按50MHz建立20ns、50%占空比时钟约束。特别检查现有封装的negedge输入锁存到posedge核心，以及相关反向边沿路径；它们存在半周期约束，不能一律按20ns整周期解释。
- [x] 不因算法100µs调用一次而把内部流水路径统一放宽为5000拍；不得用宽泛false_path/multicycle消掉真实违例。任何例外必须逐条有硬件语义依据。
- [x] 明确OOC边界假设。模块内部reg-to-reg时序与外部输入/输出预算分开报告；未建模的边界必须标为尚未签核，留AX-02C集成约束处理，不凭整体WNS为正宣称整机通过，也不编造板级引脚/ADC输入延时。
- [x] 导出LUT、FF、DSP、BRAM和时钟资源的实际数量、占比及必要层级分布；不预设“应占多少”或为优化数字改算法。
- [x] 检查route完成状态、DRC、check_timing、setup/hold及适用的pulse-width检查。内部受测路径要求WNS≥0、TNS=0、WHS≥0、THS=0，无失败端点；其他适用时序检查无违例。所有未约束/例外/critical warning须解释其范围及影响。
- [x] 保存最差setup/hold路径及其起终点/边沿关系。若失败，先定位真实路径和约束，报告原因；不得自动降频、放宽deadline、修改采样或重做流水来凑PASS。

**通过条件：** `5EV_MODULE_IMPLEMENTATION_PASS`仅表示明确目标和OOC条件下，FOC+帧封装的内部实现/时序通过。最终系统路由、实际时钟、复位、CDC和板级IO均未签核；不要求生成或下载bitstream。

## 8. Task B5 — 交接、状态更新与Review

- [x] 在一份主报告中汇总B1—B4的真实结果及失败/未执行项；原始大文件留本地，仓库仅保留必要脚本、精简结果和路径。
- [x] 给AX-02C留下明确接口：九字段类型/单位、输入保持、输出相位、frame_id/result_valid语义、三个复位相关信号的职责，以及本轮时钟/边界限制。不在本轮写AXI寄存器实现。
- [x] 更新README/HANDOFF/AGENTS的“当前”摘要为PR18已合并、AX-02B当前状态；保留旧记录为历史，不把旧NOT_RUN或待Review段落继续当当前指令。
- [x] 任务书和说明随实现代码一起进入同一个Draft PR，按实际完成情况提交；不自动合并，不关闭Issue15，不因为等待硬件而添加无关任务。

**交接状态：** 功能、帧合同、综合、实现、内部时序分别给出PASS/FAIL/NOT_RUN；本轮板上运行固定为NOT_RUN。来源、实际part和边界未签核项必须可见。

## 9. 下一阶段顺序与提前识别的时序风险

AX-02B通过后再单独制定AX-02C：先把真实计算/交换延迟纳入模型，再实现R5—PL原子命令和同帧反馈快照，明确反馈采样帧、R5读帧、命令提交帧和PL采用帧；先用记录/合成反馈，不接功率级。以太网先继续复用PR18的“实验前后传输、测量期停网”方式。

必须注意：ETH02 current_motion的既有最大响应是62.33µs，而当前仿真duty应用参考点是采样后50µs。该响应含现有回放/测量路径，并非未来AXI集成负载或算法WCET；但它已经说明，不能直接声称“本帧反馈→R5本帧算完→PL再算→仍在50µs应用”已经成立。AX-02C应验证固定相位/已提交参考的调度或经测量的同帧方案，并在模型中体现实际数据年龄，不静默增加或抹掉一帧延迟。

AX-03再进行ADC、位置采集、电角度、真实PWM/互锁/快速禁止和接线适配。功率级上电单独授权。持续遥测/网络并发另立任务，不作为AX-02B验收条件。

## 10. 工具依据

- MathWorks《Model Configuration Parameters: Target》：目标family/device/package/speed/frequency需显式配置并核对。
- AMD UG901《Setting a Bottom-Up, Out-of-Context Flow》及UG903《Out-of-Context Constraints》：OOC模块有独立时钟/约束边界。
- AMD UG906《Check Timing Section》：时序检查必须审查缺失/不完整约束，不能只读取正的WNS。

B1—B4已离线执行并通过所声明的OOC模块边界验收，B5已随实现提交[Draft PR20](https://github.com/kazecode666/AXU5EV/pull/20)，等待Review；板上NOT_RUN。详细结果和未签核项以主报告为准。
