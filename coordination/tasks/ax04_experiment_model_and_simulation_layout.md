# AX-04：独立实机代码生成模型与 simulation 目录整理实施任务

> 2026-11-17 用户最新要求。执行者：本地 Codex；按任务逐项实施、小步提交及验证，不只输出另一份规划。保留 PR45 已有组件复用成果。此文档与 Issue42 最新评论为本阶段执行入口，替代“继续美化 SIM_ONLY 顶层”和“纯仿真/实机必须共享活动算法”的旧方向。

**目标：** 将 `AXU5EV_Motor_Control_System.slx` 改建为可编辑、可代码生成的实机开发主模型；将纯仿真、实机源模型、测试模型和历史内容分开；随后接通真实 AXI/PL→R5 硬件中断并构建新的 bit/XSA/ELF 候选。

**架构：** 纯仿真保留原 Hybrid 及其算法。实机控制算法一次性复制为独立来源，复用旧 DSP 实机子系统和 PR45 的适配成果；实机内部可引用自己的库/子模型，但不反向依赖纯仿真算法、参数和初始化。R5 主模型导出由外部 ISR 调用的控制函数；电流控制、预处理、电角度和比较值由实机专用 PL 模型生成 HDL，实际外设/时基/AXI 复用已有 RTL。

**工具：** 本地已安装 MATLAB/Simulink、Embedded Coder、HDL Coder、Vivado/Vitis；Simulink 修改使用 MATLAB MCP。不是新建 Linux、RTOS、DMA 或通用通信平台。

**设计依据：** [用户方向更正](https://github.com/kazecode666/AXU5EV/pull/45#issuecomment-6940377982)、[Issue42](https://github.com/kazecode666/AXU5EV/issues/42)、[Issue44](https://github.com/kazecode666/AXU5EV/issues/44)。本任务已核对 PR45 `a7a5670` 的目录、`START_HERE.m`、`axu5ev_prepare.m`、`axu5ev_build_runtime.m`、`axu5ev_build_pl_target.m`；本地未推送/未保存内容必须由执行者现场核对，不以远端覆盖。

## 1. 全局约束与交付分段

- 工作区仍为 `D:/Project/AXU5EV`；不另 clone/worktree，不自动 stash/reset/clean/强推，不批量删除，不保存或关闭用户未保存模型。移动已跟踪文件逐项进行，并保留其本地修改；遇到 Dirty 模型只暂停受影响文件，先完成可独立工作。
- PR45 尚未合并时，基于其当前最新 head 创建 `codex/ax04-experiment-model`，新实现 PR 的 base 为 PR45 分支；若已合并则基于包含其成果的 main。不得从遗漏 PR45 的 main 重做 Task1，不自动合并任何 PR。
- **交付 A（立即执行）：目录整理＋完整的独立实机算法模型＋C/HDL 生成。** 必须有真实算法和连线，不以空子系统、文件夹树、注释图或一份报告代替交付。A 的外部 IRQ/硬件驱动未接好时必须写 `HW_BINDING_PENDING`，不能称已可上电。完成 A 的 Draft PR 后停在 Review。
- **交付 B（A Review 后）：真实 AXI/驱动 IO/PL→R5 IRQ＋匹配的硬件软件构建。** 不再重新规划 A；Issue44 的分析作为 B 的输入。板测另行授权，接口板未到不接 5V PWM/QEP。
- 控制职责和原有时序不因目录或复制改变：电流100us、速度1ms、位置10ms；测速历史100us更新、50间隔/51项。FOC在PL，不搬入R5 ISR；PL不等待R5当次返回才执行电流帧。
- 实机参数采用 Issue42 已确认的 AQM30-B2、30mm电周期、0.001mm/有效count、固定48V及软±110mm/硬阈值±120mm；不增母线ADC或虚构限位开关。总运动质量/物理标定未落实项如实列出，不用线圈质量或旧AUM质量冒充。
- 不覆盖 PR41 冻结 bit/XSA/ELF、生成源、SDF、所有 `.runtime` 结果和原始测量。新候选不能沿用旧实现的 STA/SDF/板测 PASS；不重复全量SDF长跑或无关全项目回归。

## 2. 目标目录：按用途分，不按“.m/.slx扩展名”分

以下为要实施的目标，不表示目录已存在。保留现有仓库一级目录，不发起全仓库搬迁。

```text
simulation/
  README_运行说明.md                   # 只说明两个日常入口和测试/历史位置
  START_SIMULATION.m                  # 打开原纯仿真，不自动Run/重建
  START_EXPERIMENT.m                  # 打开实机主模型，不下载、不上电
  START_HERE.m                        # 兼容旧习惯，仅转到纯仿真入口
  closed_loop/
    AXU5EV_Hybrid_ClosedLoop.slx       # 纯仿真唯一日常主模型
    components/                      # 原Runtime/Control/FOC/plant依赖
    parameters/                      # 原init_AXU5EV及相关参数来源
    scripts/                         # 纯仿真prepare/build/run/export
  experiment/
    AXU5EV_Motor_Control_System.slx   # 实机R5代码生成主入口
    r5/                              # 实机专用外环/轨迹/五态对齐/管理组件
    pl/                              # 实机专用反馈/FOC/映射库与HDL生成模型
    parameters/                      # 实机独立参数来源
    scripts/                         # 实机打开、检查、C/HDL生成入口
  tests/
    adc/                             # ADC观察/定向验证模型及MATLAB驱动
    encoder/                         # 编码器定向验证
    digital_chain/                   # 原SIM_ONLY数字链测试壳
    ethernet/                        # 原传输/回放验证用MATLAB工具
  archive/                           # 仅确认无活动依赖的历史模型/脚本
```

层次不继续无意义加深；`r5/pl`只放源模型和必要源函数。实际 SystemVerilog 外设仍在 `hardware/axu5ev/motor_control/`，R5平台/驱动仍在 `firmware/r5/`。新版本化生成C/SV放 `generated/experiment/`，新缓存/构建与本地结果放 `.runtime/experiment/<新目录>/`，精简证据放 `verification/experiment/`。既有这些目录的历史内容不搬、不清理。

### 已知文件归属与例外

| 现有内容 | 目标处理 |
|---|---|
| `AXU5EV_Hybrid_ClosedLoop.slx` | 移至 `closed_loop/`，只修路径，不改闭环行为 |
| `AXU5EV_R5_Runtime.slx`、`AXU5EV_R5_Control.slx`、`PMLSM_FOC_FixedPoint.slx`、浮点基线及关联函数 | 默认放 `closed_loop/components/`；是否历史只根据实际调用关系，不因文件早或名字旧直接归档 |
| `init_AXU5EV.m`、`design_PMLSM_three_loop.m`等纯仿真参数/整定来源 | 放 `closed_loop/parameters/`，保留现有参数；实机需要的自定义函数复制为明确独立来源，不能继续隐式调用它 |
| `axu5ev_prepare/build_runtime/run_case/export/verify_*` | 根据真实用途归入纯仿真scripts或tests，不把全部build脚本当成实机脚本 |
| `AXU5EV_ADC_HDL.slx`及Current/Encoder/Duty生成模型和库 | 它们是HDL的输入源模型，不是生成垃圾；作为实机组件迁移或复制至 `experiment/pl/`，保留需要的测试引用/冻结参考 |
| `AXU5EV_ADC_Observer.slx`、`AXU5EV_RealIO_NoPower.slx` | 作为测试/观察模型归入 `tests/`；有用户修改或仍被依赖时先解决归属，不删除 |
| 原 `motor_control/AXU5EV_Motor_Control_System.slx` 测试壳 | 保存到 `tests/digital_chain/AXU5EV_DigitalChain_Test.slx`，通过MATLAB正确更名并修测试入口；`AXU5EV_Motor_Control_System` 名称只留给新实机顶层 |
| `adc/encoder/real_io/motor_control/ethernet`下的.m | 按“活动算法/生成入口/测试激励/冻结oracle/传输工具”拆分归属，不能整目录盲搬 |
| 原目标回放、FOC冻结基线构建入口 | 保留历史复现能力或明确标为旧候选入口；新实机生成不得仍指向冻结基线 |
| `.runtime`、原始UART/ILA、板测文件、`baselines`、旧generated | 原位保留，不纳入本次目录美化 |

必须同步修复 MATLAB 相对路径、回调、Library Link、Model Reference、数据字典、S-function/MEX、Python/PowerShell/Tcl中的调用、source list和当前README。实际已发现 `axu5ev_prepare`/`axu5ev_build_runtime` 用两层 `fileparts` 推根且硬编码 `root/simulation`，原 `axu5ev_build_pl_target` 始终取 `baselines/pr53_p3/source`；移动后不能原样运行，也不能用它宣称已生成独立实机FOC。

## 3. A1 — 完成最小目录迁移与两个可靠入口

**涉及：** 上表路径；`simulation/START_HERE.m`；新增 `START_SIMULATION.m`、`START_EXPERIMENT.m`；相关 `scripts/`、`integration/` 中真正受影响的路径。

- [ ] 先记录现有模型实际解析路径、Dirty状态、活动脚本/引用关系；只做任务需要的清点，不搞全仓库哈希或备份报表。写一份简短旧路径→新路径→用途映射，附在最终报告。
- [ ] 按上表逐项移动文件，并立即修改依赖。新生成物不能误加入MATLAB搜索路径；归档目录不默认加入路径；不用整个工程的 `genpath`，不靠MATLAB当前目录或启动顺序偶然解析成功。
- [ ] 纯仿真保留原模型名称、数值/参数/后端语义；新实机模型及其自定义组件/函数使用独立名称，建议 `AXU5EV_Experiment_*` / `axu5ev_experiment_*`，防止同名模型、函数和生成SV模块遮蔽。
- [ ] 入口只显式添加各自必需的目录；切换入口不自动保存/关闭其他模型，不 `clear all`/`restoredefaultpath`，不自动重编译MEX。实机参数优先用自己的数据字典/模型工作区，不能从纯仿真base workspace偷取同名值。
- [ ] 检查 `which ... -all` 与模型 `FileName`；分别以“纯仿真→实机”和“实机→纯仿真”顺序打开，确认来源正确、参数互不污染。需要干净生成环境时沿用受控batch，不改变用户当前会话。
- [ ] 迁移后运行一个已有的短纯仿真模型/数值检查，确认仅路径变更不改变结果；不重新跑旧完整RTL/板测。目录改动单独提交，便于与后续算法修改区分。

## 4. A2 — 创建独立实机算法和参数来源

**读取来源：** `references/legacy/mil/PMSLM_Close_Loop_MBDL4.slx`、已知本地AQM备份、PR45共享反馈库与 `coordination/reports/task1_dsp_component_map.csv`；原Hybrid的实际Runtime与FOC来源。

**目标：** `experiment/r5/`、`experiment/pl/`、`experiment/parameters/`，不修改纯仿真控制器。

- [ ] 复用PR45已抽取的校准、换算、编码器算法，不重做Task1。复用旧DSP `Controller_Driver_IO_Manager`、`Travel_Safety_Manager` 的有效结构。
- [ ] 把现有Runtime的实际Host/轨迹、Reference_Manager、Motion_Control、五态Alignment_Task复制为实机专用算法；FOC复制实际定点算法和必要生成配置。DSP旧版与Runtime新版同功能选择一份明确来源，不保留两套对齐/PI同时工作。
- [ ] 切断指向纯仿真的Library Link/Model Reference、自定义函数、参数字典、初始化回调；将需要的自定义源及配置一并独立化。MathWorks系统库不用复制；实机内部引用自己的组件允许保留。不手改生成C/SV代替模型修改。
- [ ] 复制阶段保持原行为并用现有短向量核对；再以单独提交应用AQM30-B2实机参数及PI候选。Issue42 的电机/编码器/母线和行程定义直接使用；纯仿真参数不被一并切换。实际电流增益/零流未标定不得冒称实测。
- [ ] 新实机FOC生成入口真正读 `experiment/pl/` 的副本；保留原p3流水线设置但逐项核对块映射，不盲套旧SID。源清单按实际新生成模块组织，不把旧/新同名SV同时载入一个工程。
- [ ] 最终报告列“复制来源、实机副本、必要差异”；校验实机依赖闭包不包含 `closed_loop/` 或测试激励。测试可调用实机算法，反向依赖不允许。

## 5. A3 — 把主模型搭成可生成的实机控制入口

**目标文件：** `simulation/experiment/AXU5EV_Motor_Control_System.slx`；实机R5/PL组件；`simulation/experiment/scripts/axu5ev_experiment.m`。

**入口建议接口：** `axu5ev_experiment('open')` 只打开；`axu5ev_experiment('check',new_dir)` 检查；`axu5ev_experiment('generate_r5',new_dir)` 与 `('generate_pl',new_dir)` 分别生成。目录必须明确且不覆盖现有结果。入口不包含上板操作。

- [ ] R5主模型采用可导出函数的结构：初始化、外部 `PL_Frame_IRQ` 函数调用入口、`Motor_Control_ISR`、非实时服务。外部输入/输出以有明确类型/单位/版本的真实反馈与命令合同定义；A阶段允许根端口等待硬件绑定，但不允许常量0假反馈或空C驱动冒充真实接口。
- [ ] ISR中接实际独立算法：反馈检查→位置/50间隔测速→原对齐/Host/轨迹/位置速度环及驱动行程管理→整组参考/许可提交→轻量记录。顺序依旧状态消费与数据依赖确定；1ms/10ms分频与首拍关系明确。中断内部不做大量UART打印或阻塞网络。
- [ ] 从活动实机顶层移出所有 `SIM_ONLY_*`、仿真Function-Call Generator、MEX/XSI执行壳、plant/平均逆变器、纯显示用ZOH。真实同帧冻结、单位适配、PI复位和PWM采用功能仍留在实际算法/RTL/驱动中，不因删测试块而消失。
- [ ] PL预处理、电角度、FOC、比较值模块使用独立HDL生成边界，不被Embedded Coder误编译成R5电流环；顶层的PL接口区标清链接到哪份实机PL源，不放虚假连线声称一张混合模型一次生成全部软硬件。
- [ ] 按用户原有紫色区域和中文标题划分：初始化/中断、采集测量、对齐/外环/参考、驱动/行程、PL控制接口、记录通信。主通路左到右，观测支路不穿算法区，局部Goto/From受控；保留正常端口外观。提交真实MATLAB顶层与关键子系统截图。
- [ ] 实际生成R5算法C及受影响PL HDL，确认调用和模型来源，不能只交“能打开”的空壳。用已有短向量做复制等价、对齐/复位/参考及受影响定点检查；测试激励放在tests或临时验证目录，不塞回实机顶层。新模型与生成证据一致。

## 6. A4 — 有限验收并交第一份实现PR

验收项：
1. 两个入口可从任意工作目录使用；打开互不覆盖参数/未保存模型；所有活动模型/函数解析到预期路径。
2. 纯仿真只有路径变化；实机没有对纯仿真活动算法/参数/测试源的隐式依赖。
3. 实机顶层有实际控制子系统、外部调用入口和清楚的PL边界；C/HDL生成确实使用这些副本。
4. 功能复制与AQM参数变更分开提交；变化所需的短测试和截图齐全。
5. 明确记录 `MODEL/C_GENERATION/HDL_GENERATION` 的实际结果，以及 `HW_BINDING_PENDING`、`BOARD_NOT_RUN`。A不是可直接上电的完成态。

更新 `simulation/README_运行说明.md`、`coordination/HANDOFF.md`、`docs/WORKSPACE_GUIDE_ZH.md` 及AGENTS当前入口说明，修正与“纯仿真/实机独立”冲突的旧规则。报告建议 `coordination/reports/ax04_experiment_model_and_layout.md`，精简结果 `verification/experiment/model_layout/results.json`。不把旧证据的历史路径改写成新实验路径，不搬旧Workspace/数据。新Draft PR关联#42、#45和本任务，完成A后停在Review。

## 7. B — Review后的真实外设/IRQ与部署接入（不是A完成项）

- 基于A实机模型与Issue44时序分析，在原PL工程中接真实ADC/QEP、六PWM、RELCON/ENCON/F_Reset/OE、ERRI/ERRU与最终J16 XDC；停用物理候选中的TEST_ABZ/常量引脚，依据PCB最终版本映射，不猜针号。
- 以选定100us反馈帧可读事件驱动PL→PS IRQ；R5中断控制器与Vitis薄驱动实际注册/清除/调用生成控制函数。5MHz ADC每次转换与50MHz时钟均不是R5中断频率。硬件地址和IRQ取实际XSA/BSP。
- 在真实AXI接口中实现原子反馈读取/命令提交、帧号、pending/ACK及安全失效处理。不得等约+50us完整诊断快照后再无依据假定R5赶上下一P0；明确反馈和参考对应哪帧。缺帧/重复/超时不重复积分、不自动重臂；PL/驱动快速故障禁止不依赖R5正常执行。
- 构建新的匹配bit/ltx/XSA/ELF，必要RTL、STA/CDC和目标链接检查只覆盖受影响内容。新硬件IO/IRQ尚无实测时保留NOT_RUN，完整SDF既有缺项不得伪改PASS。
- 接口板到货后的电气检查、无功率联调、标定、受限上电和真实对齐/运动，均需用户另行明确授权。

## 8. Review重点（对应上面各任务）

- 路径搬迁后脚本仍用旧层数推根或冻结p3源：A1/A2检查实际解析和生成来源，不只看文件存在。
- 两模型仅SLX独立但参数/函数仍共享：A1的双向打开及A2依赖检查必须发现，不靠先运行某个init侥幸成功。
- 旧测试壳同名遮蔽新主模型、归档默认进路径：A1要求正确更名和受控路径，A3生成只用实机模型。
- 新中断入口只有图标没有硬件绑定：A阶段明确pending，B必须提供实际驱动/BD/IRQ代码与构建，不用host MEX充当R5执行证明。
- 为整理覆盖用户Dirty模型或原始结果：逐文件保护并报告受阻项，不强制保存、不批量清理、不运行旧关机命令。

技术参考（仅说明实现方式，不证明本工程已完成）：MathWorks [Export-Function Models](https://www.mathworks.com/help/simulink/ug/export-function-models.html)、[Generate Component Source Code](https://www.mathworks.com/help/rtw/ug/export-generated-cc-source-code.html)、[Analyze Model Dependencies](https://www.mathworks.com/help/simulink/ug/model-dependency-viewer.html)。
