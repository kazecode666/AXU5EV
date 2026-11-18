# AX-04B：真实硬件绑定与首次无功率运行实施计划

> 2026-11-18。执行者：本地 Codex。逐任务实施、定向验证、小步提交；可使用 executing-plans 工作流。本文是交付B的执行计划，不是实现或板测通过声明，不授权下载、复位、接线或电机上电。

**Goal / 目标：** 将PR46的实机算法接入真实R5/PL工程，完成可重复构建的匹配bit/ltx/XSA/ELF和明确的无功率首运行入口；随后在用户单独授权下验证真实处理器、中断、总线、PL链和外部接口。

**Architecture / 架构：** 保持电流控制在PL、外环及运行管理在R5。PL发布选中的100us反馈帧，R5通过真实IRQ读取原子快照，调用现有生成控制函数，再原子提交后续帧参考。旧完整诊断快照不作为首选实时调度入口。使用同一源码的SELFTEST和REAL构建配置，不再新造一套控制算法或板级工程。

**Tech Stack / 工具：** 已有MATLAB/Simulink/Embedded Coder/HDL Coder、Vivado/Vitis、R5 Standalone BSP、现有SystemVerilog外设；模型操作走MATLAB MCP。

**Spec / 依据：** `coordination/tasks/ax04_experiment_model_and_simulation_layout.md` 第7节、PR46提交`8fd02bb`及复审5951712548、Issue42实物/参数定义、Issue44时序核对任务。以下“方案/任务”是本轮拟实施选择；“核对事实”是已读取仓库内容，不混同。

## 0. 已核对事实与基线补入

- PR45已于2026-11-18合并到main，合并提交`3fdd140609b0ff91f1348965ebbd76c13c8821b3`。
- PR46也已合并，但目标仍为`codex/issue42-task1-dsp-reuse`，合并提交`3884eed0c3088fe5941754523c7fa2cd48ef251f`。规划时main仍是`3fdd140`，尚未包含PR46。`8fd02bb...3884eed`比较结果无文件差异，只多一个合并提交。
- 本任务所在分支从`3884eed`建立，新增的开发内容只有本文。向main的补入PR会包含此前已经审查的PR46成果；这不是重新实施PR46，也不是交付B代码。
- 当前硬件`sources.list`仍引用旧`generated/adc`、`generated/encoder`和`generated/legacy_m3_p3`；`bd/adc.tcl`仍启用TEST_ABZ并将物理ABZ接零；`bd/pwm_clock.tcl`中fast_inhibit接零、无外部门极引脚。
- `firmware/r5/motor_control/main.c`仍是预提交TEST参考与80字快照观察器，并未调用新实机Runtime。
- PR41原时序说明为P0采用预提交参考、约P110反馈会合、P127/P128送FOC、约P442结果、P2500谷值采用、P2508后发布完整快照。新组件接入后必须核对实际边沿/生成元数据，不能照抄旧签核。
- 本次读取的Issue44仍是Open任务，未附已完成评估；把它的核对内容纳入B1，不假称已有结论，也不再单独等待一轮只读文档项目。

### B0：补齐主线，不重做A

- [ ] 先核对远端最新状态。补入PR46成果到main；通过普通PR完成，等待用户合并，不强推、不重放/手抄270个改动文件。不要把PR43的历史HANDOFF内容直接覆盖新状态。
- [ ] 已补入后，从包含PR46最终1.95模型及`r5_final_03`的main建立`codex/ax04b-hardware-binding`。若补入PR仍待合并，可以从本任务分支接续开发并先以它为base，待主线补齐后再改base为main；不得从缺失PR46的main重新搭A。
- [ ] 保护`D:/Project/AXU5EV`工作树、用户Dirty模型、旧生成物/Workspace/.runtime/原始测量；只核对本任务所需来源，不进行全仓库哈希、重复备份或清理。更新AGENTS/HANDOFF当前入口的过时待Review描述，历史证据不改写。

## 全局约束与交付边界

1. 保留纯仿真与实机独立、R5算法就地可见可编辑；不重新整理simulation，不把算法放回外部逐采样脚本。C驱动只做硬件传输、调度、格式适配，不手写第二套控制算法或手改生成C/SV。新增控制角等数值算法若确有需要，放在实机PL源模型的可见边界并生成HDL。
2. 参数、PI和低电流限制沿用PR46候选；电流100us、速度1ms、位置10ms及原首拍关系不变；测速100us更新、50间隔/51项；固定控制48V而非母线实测。电机为AQM30-B2、30mm、0.001mm/有效count；软限±110mm、硬阈值±120mm；机械原点与电相位偏置分离。
3. 复用既有ADC/QEP/PWM、AXI、PS配置、启动链及以太网事后传输能力，不新建Linux、RTOS、DMA、GUI或通用安全框架。不改变既有外设时钟/死区/电平定义来回避集成问题。
4. 原PR41冻结成果不覆盖。新工程必须明确选中本次实机生成源；旧STA/SDF/板测结论不自动覆盖新候选。不重复旧完整SDF长跑；新候选仍需相应功能、完整实施STA/CDC、IO约束及目标链接检查。
5. **本轮立即执行范围是B1～B4离线实现和构建，提交一个新的实现Draft PR后Review。** B5板内运行和B6真实IO验收必须分别得到用户明确授权。发布任务、编译成功、控制板可供电，都不是授权下载或运行电机。
6. 状态分别记录：`RTL_BINDING`、`R5_TARGET_BUILD`、`FULL_IMPLEMENTATION_STA_CDC`、`BOARD_SELFTEST`、`REAL_IO`、`POWER_MOTION`。未完成项写NOT_RUN/PENDING，不能用一个总PASS掩盖真实输入/功率链未测。

## B1：确定实时反馈、参考采用及停止合同，并落实最小接口

**读取/修改边界：** `hardware/axu5ev/motor_control/rtl/{top,axi,control}/`、现有BD、`firmware/r5/motor_control/`；参考`coordination/reports/ax02c2_runtime_pl_replay.md`和Issue44。新增短接口说明建议放`integration/ps_pl/AX04B_INTERFACE.md`，只作为本次实际接口说明，不另建规范体系。

**推荐方案：** 本帧PL使用已预提交参考独立执行电流环；尽早发布同帧的最小R5反馈并触发IRQ，R5计算后提交给下一P0。完整80字/PWM采用诊断留在慢速观察通路。若实际源码或目标时间测量不能满足，不得偷偷多延一帧或降低电流环频率；明确报告所需固定延迟与影响，再调整已记录合同。

- [ ] 根据现有采样/资格事件和新生成延迟列一张实际时序表：P0[k]、反馈可读/IRQ、R5入口/读取/计算/提交、PL接受、P0[k+1]采用、PWM谷值采用。标出sample_id、reference_version、目标帧、accepted/applied身份。正常sample_id增量500、tick增量5000/50MHz，不改成每IRQ加1后还沿用旧Guard。
- [ ] 明确控制快照最少字段：接口/候选版本、sample_id、完整uint64 tick、raw_count、非法跳变计数、编码器/电流资格、校准及配置状态、故障状态；诊断可单独读取。最早可读时刻以实际RTL为准，不能仅在ADC原码出现时抢发IRQ却拿上一帧current_valid。
- [ ] 选中的帧即使无效，也要有明确无效事件/故障通路；不能仅在有效帧触发IRQ，使启动校准和故障期间R5静默失去调度。全无新帧另由PL超时禁止处理。
- [ ] 复用/扩展既有快照冻结，定义BEGIN/读取/释放或等价原子操作。R5读到的count、id、tick与valid必须是一帧；未读完/未确认的新事件不能悄悄覆盖旧记录。定义overrun及读失败的有限处理，不在ISR无限重试。
- [ ] IRQ采用可确认的pending机制，依据实现选择并配置正确触发类型。ACK对应已处理序号，ACK与下一事件同拍不丢新事件；旧ACK不清新pending。伪中断/纯重复身份不再次调用普通算法或提交新的允许参考；真实故障/复位仍走安全处理，不被去重屏蔽。
- [ ] 参考从shadow整组冻结，经明确COMMIT后在规定边界采用。定义版本/目标帧回执、pending忙、迟到、重复提交、数据无效及跨域失败的处理；AXI写握手完成不是PL已经采用。晚到参考不得顺延成未声明的下一帧。
- [ ] 预算列出`IRQ延迟+读帧+生成函数+编码/写入+实际接受延迟 < 100us-反馈发布时间-边界余量`。旧回放最大86.017us只作历史线索，不是当前任务的WCET。测量点和失败判据在编码前明确，不先声称已满足。

**接口验收：** 用原TB扩展正常/无效帧、重复、丢帧、ACK竞态、半写提交、pending忙、边界前后提交和id/tick回绕；失效时不误用半包或旧参考。时序说明与实际实现同PR交付，不只交分析报告。

## B2：接入实机PL生成源、对齐角路径和独立禁止

**主要文件：** `hardware/axu5ev/motor_control/sources.list`、`build.tcl`、`bd/adc.tcl`、`bd/pwm_clock.tcl`、`rtl/control/motor_foc_control.sv`、`rtl/top/ax03b3_adc_observer.sv`、原AXI/PWM桥和constraints；`integration/rtl/axu5ev_foc_frame_top.sv`及需要的实机生成接口。保留旧冻结源选择；新的权威清单只收录一套有效的实机模块及包。

- [ ] 实际收录PR46的`generated/experiment/ax04_01/pl`四个边界，并适配模块前缀、端口、复位、使能及延迟。保留四边界完整文件集和原流水线设置，不把旧p3模块与新模块混合综合。无源变化不重复生成HDL；确需新增数值适配时只重生成受影响边界。
- [ ] 由同帧反馈和所采用参考共同确定FOC九字段，保持输入冻结及PI/AW连续状态。不能每帧global reset、只跑到结果出现就停核，或把不同帧的电流/角度/参考拼起来。
- [ ] **落实对齐角功能，不只传Id/Iq。** 把R5的固定角选择、相位偏置、PI复位及许可实际接到FOC控制角路径。对齐时使用明确的theta_align_const；正常时使用编码器角度和本次有效偏置。切换、偏置及参考必须按同一版本/帧原子采用。
- [ ] 对齐模式下的控制电角速度与固定角语义一致；测量速度可保留作诊断，不能未经核对把实际运动omega送入本应固定角的前馈。核对现有Alignment_Interface的预期关系，模型中说明转换。
- [ ] 列清rad/Q32、A/Q24、rad/s/Q24、比较值和bool字段的映射，明确舍入、饱和、有限值检查及高低字顺序。旧PL相位偏置用count、新R5偏置用rad，不能直接赋同一寄存器或把双精度二进制当Q值。避免偏置补偿两次；R5机械零点/方向与PL电角度基准必须一致，对齐不得移动行程原点。
- [ ] 增加本候选的真实IRQ端口和来源；实际PS连接、IRQ路由、触发类型和R5目标由BD/XSA/BSP核对，不猜中断编号。
- [ ] ERRI/ERRU快速禁止接入PL/驱动链，撤销许可、校准重启、失锁、超时和非法参考应取消在途采用并安全关断。不能再将fast_inhibit固定接零；也不能靠R5正常轮询保证快速故障响应。
- [ ] 增加基于参考/帧前进的最小超时保护：R5停机、挂起或不再提交时，PL不能无限保持最后允许输出。超时后的恢复必须显式清错/重臂，新版本号递增本身不能自动清除安全锁存。阈值按B1合同记录并验证，不使用无限超时。
- [ ] 依据最终J16-MBDL4制作版本/网表及AXU5EV资料核对真实ABZ、六PWM、RELCON/ENCON/F_Reset/OE、ERRI/ERRU和XDC。J15仍为AN9238。物理候选不启用TEST_ABZ、不把真实脚接常量；未取得可靠针号/极性依据的项明确PENDING，不猜测。
- [ ] 保留F_Reset与软件清错分离。驱动复位通路需要缓冲可用时，六PWM仍必须被独立强制禁止，REL/EN关闭；复位、配置、时钟失锁和PS尚未启动时的外部默认状态均要核对。无物理回执时只报告软件请求/PL采用，不虚构驱动READY。

**PL验收：** 新生成源的整链定向对比；固定角→编码器角切换及偏置一次应用；配置/参考版本不混帧；真实故障逻辑与无CPU提交时的禁止；复位/失锁/迟到不产生旧结果重放。软件仿真通过不替代外部电气验收。

## B3：R5裸机绑定，保留模型为唯一控制算法源

**主要文件：** 在`firmware/r5/motor_control/`内组织新实时应用和薄驱动；复用既有PS初始化/BSP/启动方法，不复制旧测试main冒充新Runtime。新增文件名称按现有工程风格决定，但职责分别为MMIO/IRQ、模型输入输出适配、主循环及轻量记录；相应修改`scripts/motor_control_build.py`和构建配置。

- [ ] 使用PR46最终`generated/experiment/pr46_review_01/r5_final_03`的实际BuildInfo源集和头文件；不使用旧encoder观察器C替代新主模型。如果B必须改模型接口，保持就地可编辑、单列变化并重新生成受影响C。
- [ ] 主程序先禁止物理输出、校验bit/软件身份、接口版本和反馈尺度，初始化模型，再注册GIC/PL IRQ。地址及IRQ号取实际XSA/BSP；硬件不匹配立即停在禁止态，不回退至旧地址/旧协议。
- [ ] ISR：确认事件→取得原子反馈/命令快照→更新模型输入→调用`PL_Frame_IRQ()`→编码并整组提交→确认/记录接受结果→按B1 ACK退出。启动期间与故障期允许必要处理但不自动arm；禁止重入同一生成模型。
- [ ] 上位机命令采用完整快照交给ISR，不能一边改20字段一边由ISR读一半。驱动仅处理传输/形式转换，位置、速度、轨迹、对齐和保护判断仍在SLX生成算法内。
- [ ] 串口/网络仅用于非实时命令与记录导出。ISR不打印长UART、不等待网络、不写文件。复用既有数据通道，不把新GUI或实时高速流作为首次运行前置。
- [ ] `Service_Request()`与ISR共享数据必须有明确互斥/快照策略。首版可采用短且有界的中断屏蔽只复制遥测快照，随后在中断外发送；把这个临界区计入响应预算，不把整个网络/打印操作放入临界区。
- [ ] 用现有方法完成实际Cortex-R编译和链接，核对int64/double、数学库、堆栈、内存区、缓存及MMIO属性、屏障与中断ABI。PC MEX通过不能替代目标ELF生成；不把50MHz PL时钟当R5 CPU计时频率。
- [ ] 实机启动顺序明确：输出禁止→身份检查→真实零流校准/资格建立→测速历史建立→满足安全条件后显式清错→另行显式使能/Start。数字TEST增益/原码不得当成物理电流标定，校准完成不自动启动对齐。

**R5验收：** 实际目标ELF/Map与新的平台匹配；适配定向用例覆盖Q格式/符号/高低字、无效值、重复帧和安全事件、未校准与手动启动。未上板的中断时延/ARM执行继续NOT_RUN，不借旧回放结果签核。

## B4：两种明确构建配置、完整部署候选及首次操作指南

**构建入口：** 继续使用`hardware/axu5ev/motor_control/build.tcl`、`scripts/motor_control_build_hw.ps1`及对应R5构建入口，按需加显式配置选择，不另造平行工程。

| 配置 | 用途 | 不可违反的边界 |
| --- | --- | --- |
| SELFTEST | 接口板未到时验证真实PL→IRQ→R5→AXI→FOC/PWM内部链 | 测试输入明确标记；外部六PWM及驱动使能硬禁止，不能被模型参考解除。可观察内部PWM，不声称真实传感器/驱动已验收 |
| REAL | 最终真实AN9238/ABZ/故障/驱动端口及J16约束 | TEST源关闭，无自动回退；启动和待命默认禁止。物理校准/电气验收未完成时拒绝运动使能 |

两配置同源、同算法，仅输入/输出测试边界和必要构建参数不同；各有明确身份与成套产物，不能拿SELFTEST通过代表REAL通过。J16资料未齐不阻塞SELFTEST；REAL构建/物理项缺失如实报告，不能填假管脚。

- [ ] 对各可完成配置执行必要综合、实现和bit导出；记录完整STA、CDC、时钟约束、真实IO输入输出约束与关键DRC结果。新跨域/快速禁止路径不能靠随意false_path掩盖；无SDF不等于可省略这些检查。
- [ ] 导出与bit来自同次实现的XSA及匹配ltx；Vitis平台/BSP/ELF基于该XSA构建。FSBL、psu_init、启动脚本只在配置一致时复用。新工作目录统一为`.runtime/experiment/ax04b/<独立候选>/`，不得覆盖旧Workspace。
- [ ] 提交简明候选配置：源码/模型及生成源版本、SELFTEST或REAL、bit/XSA/ELF路径、应用/接口身份、时钟、地址/IRQ、启动与安全默认状态。目的是防混包，不新增全仓库哈希审计。
- [ ] 更新`firmware/r5/motor_control/FIRST_RUN_ZH.md`或同目录独立AX04B指南：精确工作区/应用、用户操作次序、期望输出、采集和停止方式、失败时保持禁止的动作。不得让用户猜该下载哪份旧bit或直接使用历史串口t/m命令。
- [ ] 提交本轮报告`coordination/reports/ax04b_hardware_binding.md`、精简状态`verification/experiment/ax04b/results.json`、新源选择及构建结果，更新HANDOFF和AGENTS当前入口。B1～B4完成后交一个实现Draft PR并停在Review，不自行进入B5。

## B5：用户授权后，控制板首次无功率实测

这是后续现场任务，不包含在本次自动执行授权中。先供控制板，不上电机功率母线，不使能驱动；没有J16转换板时不直连5V PWM/QEP。

- [ ] 首先用SELFTEST候选验证真实R5启动、真实PL IRQ、同帧读取、生成算法、参考接受与内部PWM采用；记录数据来源确为TEST，外部输出保持硬禁止。
- [ ] 记录IRQ响应、读帧、算法、COMMIT接受、参考采用和返回/轻量记录窗口。包含1ms/10ms外环重拍、对齐状态切换及非实时服务负载；报告实际样本最大值及分布，不称为形式证明WCET。
- [ ] 在授权且外部安全禁止的条件下注入重复/缺帧、迟交、停提交及一次R5暂停/超时，验证独立禁止、锁存和显式恢复；不能为了跑通放宽截止时间或绕过反馈资格。
- [ ] 复用现有记录导出方式，保存同一次候选、UART/ILA/帧记录及失败上下文。验收重在真实闭链和安全行为，不重跑旧64536帧历史回放来代替本次实时反馈。

## B6：接口板可用后的真实IO无功率验收，以及B的退出条件

- [ ] 依据最终接口板版本先完成电源/地/缓冲方向/OE/默认态检查；验收真实ABZ方向/尺度、ADC零流与有效性、外部六PWM边沿/死区和故障禁止。驱动器功率级保持不工作，具体接线/测量步骤由届时操作指南和用户授权决定。
- [ ] 对照R5位置/速度、PL电角度和帧身份；明确电流增益、极性、零偏哪些已实测、哪些仍待后续受控标定。软硬限是软件坐标保护，不替代物理安全条件。
- [ ] B可分项签收：离线构建完成、板内SELFTEST通过、REAL IO通过。接口板未到时允许前两项推进，第三项PENDING；不得将其合写成全部实机通过。
- [ ] 受控母线、真实电流建立、实物对齐与首次运动另立现场场景并由用户授权。交付B不自动运行这些场景，也不因软件对齐状态到了DONE而宣布物理对齐成功。

## Review Focus / 最易遗漏的五项

1. **A已Merged但不在main：** B0核对祖先关系或实际内容；不得从旧main覆盖新模型。
2. **新SLX、旧生成物混搭：** B2/B4检查实际source list、模块前缀、候选身份和XSA/ELF对应。
3. **IRQ有了但帧/命令不一致：** B1/B3验证ACK竞态、原子快照、COMMIT实际接受、重复/晚到及帧号回绕。
4. **对齐只在R5计时，PL角度不切换：** B2验证固定角/正常角、omega、偏置单位/原点及一次应用；B6区分物理建立与软件许可。
5. **CPU停了而PWM保持或SELFTEST误外发：** B2/B4/B5验证独立超时/故障禁止、显式重臂和SELFTEST输出硬禁止；首次操作指南不包含功率运行授权。

## 给Codex的本轮执行口径

先处理B0基线，随后直接执行B1～B4；按接口、PL接入、R5绑定、部署构建分别提交。不要再只返回一份规划，不重复PR46已验收模型工作。遇到真实缺项，仅停受影响范围并保留准确状态；其他独立离线任务继续。完成实现Draft PR后等待Review和用户上板授权。

## 本次读取的依据与官方实现参考

- 已审查算法：`coordination/reports/ax04_experiment_model_and_layout.md`、`verification/experiment/pr46_review_01/results.json`。
- 当前旧部署：`hardware/axu5ev/motor_control/README.md`、`sources.list`、`bd/adc.tcl`、`bd/pwm_clock.tcl`、`rtl/control/motor_foc_control.sv`、`firmware/r5/motor_control/main.c`（按PR46最终源读取）。
- [Issue44](https://github.com/kazecode666/AXU5EV/issues/44)仅提供待核对的时序问题，不视为实现证据。
- [MathWorks Export-Function Models](https://www.mathworks.com/help/simulink/ug/export-function-models.html)：生成函数由外部调度器集成；不代表硬件IRQ自动完成。
- [AMD XScuGic APIs](https://xilinx.github.io/embeddedsw.github.io/scugic/doc/html/api/group__scugic__api.html)：中断注册、使能及触发类型接口；具体XSA/BSP和已安装版本仍是本工程绑定依据。
