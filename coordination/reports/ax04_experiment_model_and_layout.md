# AX-04 独立实机模型与双入口

本轮执行 Issue42 评论6941278055及PR43任务书的交付A，基于PR45 `a7a5670` 建立 `codex/ax04-experiment-model`。已发布 [Draft PR46](https://github.com/kazecode666/AXU5EV/pull/46)，base为 `codex/issue42-task1-dsp-reuse`，停在Review。[执行任务](../tasks/ax04_experiment_model_and_simulation_layout.md)

## 来源与提交

目录与入口提交为 `a223973`，等价源复制提交为 `9c5fb4b`，B2参数及实机入口适配提交为 `4c72c05`。85项旧新路径及用途见[路径映射](ax04_path_map.csv)。

| 来源 | 实机副本 | 适配 |
|---|---|---|
| 当前Runtime的Host、轨迹、Reference_Manager、Motion_Control及五态对齐 | 实机主模型的Qualified_Runtime | 独立函数名、合格帧执行、继承调用时基 |
| PR45位置/测速组件 | Experiment_R5_Algorithms的Feedback_Measurement | 独立guard函数，保留连续计数及50间隔历史 |
| DSP Controller_Driver_IO_Manager | Experiment_R5_Algorithms同名组件 | GPIO边界改为8输入/5输出，低有效故障、明确清错与F_Reset分离 |
| DSP Travel_Safety_Manager | 实机Motion_Control中的库实例 | 软限方向阈值1mm/s改为0，外部锁存采用明确安全清除 |
| PR45双路校准、电流换算 | Experiment_PL_Algorithms及Current_HDL | 保留同帧资格、两相重构及一拍边界 |
| PR45串行电角度、Duty映射 | Experiment_Angle_HDL、Experiment_Duty_HDL | 独立函数及HDL命名 |
| 当前定点FOC | Experiment_FOC | 独立B2配置与18项p3流水线映射 |

复制阶段逐项比较Runtime的423个块、374条连接、MATLAB Function及Stateflow状态/迁移语义，通过后再进行实机适配。电流49向量×14输出与原oracle一致，电角度46向量、2208个模型步一致。[复制证据](../../verification/experiment/model_layout/source_copy.json)

原9项用户模型/参数工作树修改继续保留。旧数字链壳通过MATLAB更名到tests，工作树保留用户当前布局，提交采用原HEAD正确更名后的基线。原用户版本另存 `.runtime/experiment/ax04_01`，历史实验及冻结候选原位保留。

## 日常入口与参数

纯仿真使用 `simulation/START_SIMULATION.m`，参数位于 `closed_loop/parameters/init_AXU5EV.m`。兼容入口 `START_HERE.m` 转到纯仿真。已有参数及Dirty模型保留，显式初始化和构建由调用者选择。

实机使用 `simulation/START_EXPERIMENT.m`，主模型、算法和参数来自 `experiment`。参数快照采用ModelWorkspace。`axu5ev_experiment` 提供打开、检查、参数刷新及独立R5/PL生成动作。新缓存与结果采用调用者指定的新目录。[运行说明](../../simulation/README_运行说明.md)

实机候选采用Rs1.45Ω、Ld=Lq11.8mH、电周期30mm、0.001mm/count、固定控制参考48V。Kf按Apeak折算为21.496046N/A，psi由现有力方程推导为0.068424040Wb。电流PI采用原xi方法，Kp59、Ki7250、KiTs0.725、Kaw0.0122881356。Id对齐上限0.5A、Iq上限0.3A沿用原低电流调试范围。位置/速度增益采用AQM备份候选，总运动质量和物理标定仍待落实。

## 主模型与接口

主模型直接嵌入 `Motor_Control_ISR/Qualified_Runtime`，其中保留实际Host、轨迹、Reference_Manager、Alignment_Task及Motion_Control。实机R5库提供反馈、驱动与行程三个组件，活动实机依赖中没有纯仿真Model Reference。主模型的589个可见块通过编译与边界检查，根层端口、连线及Stateflow编辑期检查通过。

`Initialize_Controller` 在生成的 `AXU5EV_Motor_Control_System_initialize()` 内执行。初始化清零内部与外部状态，输出PWM关闭、PI复位、参考无效、RELCON/ENCON关闭及OE禁止。`PL_Frame_IRQ()` 是100us反馈帧的外部函数调用入口，R5中断注册与原子AXI读写留待交付B。`Service_Request()` 复制12字段轻量遥测并递增调用计数，通信及可抢占快照的一致性由交付B绑定。

接口版本为1。根输入包含20元素double命令、uint32原始计数/帧号/非法跳变数、uint64的50MHz帧时戳，以及编码器就绪、电流有效、ERRI_n/ERRU_n、软件清错和四项驱动请求boolean。输出含41元素运行状态、毫米位置、mm/s速度、int64连续计数、有效位/历史长度/状态字、8元素参考及提交帧号/版本、5元素驱动合同、遥测与服务计数。

内部20字段分组仍为 `[11 3 1 1 1 1 1 1]`。绑定器写入15号速度、19号故障和20号位置，关闭replay分支。参考8元素依次为Id(A)、Iq(A)、电角速度(rad/s)、角度偏置(rad)、对齐角使能、PWM许可、PI复位和参考有效。驱动5元素依次为RELCON、ENCON、F_Reset、OE_disable和外部故障锁存。

位置历史每个合格100us新帧更新，50间隔后速度有效。缺帧重建历史，重复帧保持Runtime状态；驱动F_Reset、PI_Reset、Init_Reset及安全软件清错分别处理。原速度/位置分频保持每10/100次合格控制调用及原9/99首拍关系。行程在软限处仅禁止继续向外，硬阈值包含±120mm并锁存，PWM关闭且反馈健康后接受显式清错。

纯仿真FOC与新实机FOC分别保留各自模型和配置。新PL预处理、电角度、FOC、Duty四个边界独立生成，不进入R5的C目标。主模型紫色分区中的PL接口输出采用上述合同，实际PL源位置写入模型说明。

## 实际验证

| 项目 | 结果 | 范围 |
|---|---|---|
| 目录迁移短仿真 | PASS | model_fixed，20ms、201帧，位置/速度快照与duty字检查零差 |
| 独立轨迹及胶合函数 | PASS | 1600点位帧及35项其余检查，最大差0 |
| B2 FOC模型 | PASS | 1188帧，饱和、AW恢复与PI复位 |
| 实际HDL生成 | PASS | 4边界、51份SV、50模块及1包 |
| FOC RTL短验证 | PASS | 连续192帧、576项duty检查、960000个时钟，覆盖12帧复位、128帧饱和及52帧早期恢复 |
| 动态前馈模型与RTL | PASS | 48帧，含首尾各4帧PI复位及40帧非零电流、四角度与±30rad/s组合，144项duty检查 |
| R5主模型与目标C | PASS | Cortex-R配置ERT生成15份C/H，5份实际C经transport-only MEX执行，90项检查、47762次IRQ调用 |
| 对齐与行程 | PASS | 其中42130次完整对齐调用、5490次行程调用；对齐跃迁0/10000/40000/42000、6项软硬限案例 |
| 双向打开及参数隔离 | PASS | 任意工作目录、2种顺序各24项which-all、75参数/模型、6项Signal保存重开及base碰撞哨兵保留 |
| 综合、实现、STA/CDC/SDF、ARM执行及板测 | NOT_RUN | 新候选当前范围为模型、代码生成与离线数值验证 |

新FOC使用5000使能时钟/帧及原18项p3流水线设置。生成元数据的三相输出相位均为314拍，两组RTL均在该拍的上升沿NBA更新后采样。新SV采用四组独立模块前缀，实际导出为Current16份、Angle4份、Duty2份、FOC29份，共50个模块及1个包。9处关键Gain/Constant的Q40值与实际SV常量一致，Ld/Lq/psi动态路径另以非零角度/速度验证。此处的314拍属于理想时钟RTL功能调度证据。[系数与前馈证据](../../verification/experiment/pl_coefficient_bindings.json)

FOC辅助`gm_AXU5EV_Experiment_FOC`的输出延时插入步骤出现`Failed to add integer delay to DUT output ports`，消息定位`/FOC_DUT/FOC_DUT`。该辅助gm模型的等价验证记为`NOT_RUN`。本轮expected来自已保存的独立FOC源模型，实际新SV通过192帧与48帧两组逐字比较，共720项duty检查。生成器的35项HDL全局参数及18项块流水线参数在生成后恢复，已保存的独立B2参数快照保留。原始失败、超时与改用短向量的记录保留在本轮新结果目录。

目标C实际生成与测试位于 `.runtime/experiment/ax04_01/r5_02`，最终日志为 `r5_02b.log`，版本化C/H位于 `generated/experiment/ax04_01/r5_02`。首次生成后的函数原型读取错误已修复，最终按实际BuildInfo中的5份C编译测试。该验证在主机执行，ARM目标链接与运行留待交付B。主模型排版前后执行连接、脚本及普通端口外观断言，Review发现的3项旧duty日志名已改成Id、Iq及速度参考名称。

双入口隔离的最终结果为 `isolation_02/entries.json`，纯仿真短结果为 `pure_02/entries.json`。最终主模型受控检查写入 `main_check_03`。C生成后仅调整排版、模型说明和SDI标签，连接及算法脚本断言保持一致；驱动的24项数据连接在几何重绘后逐项复核。保存过程中曾出现复杂模型保存耗时异常，本轮新模型采用关闭外层预览、跳过保存回调的检查点方式恢复并保存，模型回调静态检查为空；该异常根因尚未确认。

精简汇总与依赖结果分别为[交付A结果](../../verification/experiment/model_layout/results.json)和[模型及函数来源](../../verification/experiment/model_layout/dependencies.json)。原始CSV、MEX、工具缓存、失败记录及检查点保留在本轮新运行目录。顶层、ISR、Runtime、驱动及三个PL关键区域的实际截图位于 `verification/experiment/model_layout`。

## 硬件交接

当前为 `HW_BINDING_PENDING`、`BOARD_NOT_RUN`。AXI原子帧读写、GIC/PL中断注册、驱动IO与物理默认状态、服务快照的抢占一致性及匹配bit/XSA/ELF属于交付B。物理电流标定与总运动质量仍未落实。交付A停在Draft PR Review。

Issue44的独立分析及PR41冻结验收证据分别保留在各自工作线。

## PR46 Review修订 — 对齐安全、就地编辑与呈现

2026-11-17，继续同一Draft PR46执行Task1～Task4。本节记录新候选的实际范围，前文交付A的既有结果保留其历史范围。[本轮执行评论](https://github.com/kazecode666/AXU5EV/pull/46#issuecomment-6948838671)

### R1—R5修改位置

以下模型路径均位于 `AXU5EV_Motor_Control_System` 内。

| Review项 | 实际修改位置 | 行为与呈现 |
|---|---|---|
| R1 对齐许可 | `Motor_Control_ISR/Alignment_Permit` | 就地完整函数读取软件初始化、位置/电流/测速历史、当前故障、PWM及对齐请求、REL/EN、OE、F_Reset和复位条件。许可由上游合同推导，PI_Reset按既有非零语义解释，启动与保持条件可直接查看 |
| R2 终态优先级与安全处理 | `Motor_Control_ISR/Qualified_Runtime/Alignment_Task/Enabled_Original_MIL/Angle_Init`、`Runtime_Advance_Or_Safety`、`Qualified_Runtime/Host_New_Frame`及`Qualified_Runtime/Motion_Control/New_Frame_Only` | 进行中许可丢失中止并撤销本次对齐结果。复位/故障/许可撤销优先于RAMP_DOWN末拍完成。Start释放后再次触发才接受新启动。安全处理在重复或无效帧时仍可执行，Host/积分/调度计时按新帧推进 |
| R3 实际使用位置可编辑 | `Motor_Control_ISR/Feedback_Measurement`、`Controller_Driver_IO_Manager`、`Qualified_Runtime/Motion_Control/Travel_Safety_Manager` | 三实例固化为普通子系统，`LinkStatus=none`且`ReferenceBlock`为空。R5日常加载与生成实际取主模型，原R5库及用户对它的本地修改保留在原路径 |
| R4 完整逐采样算法 | `Feedback_Measurement/Frame_And_Count_Guard`、`Frame_And_Fault_Qualification`、`Reference_Commit`、`Capture_Latest_Observation`和`Host_New_Frame/Host_Core` | 计数、资格、参考与遥测算法完整位于块内。Host附有点位及Scurve局部函数。`Bind_Real_Feedback`采用可见字段绑定和布尔门控，有限值检查在其`Finite_Command`块内 |
| R5 可读性与接口 | ISR、反馈内部、Runtime字段旁注及根层接口说明 | 紫色中文分区，测量→资格→Runtime→参考封装主链，辅助长线使用局部Goto/From。用户重排的顶层块位置保留，Stateflow五态图保留原有节点及迁移布局 |

几何回查中五个Stateflow状态框与原位置一致，迁移端点差不超过1e-4px。默认迁移中点有4px归一化偏移，标签约3px，旁注不足1px。布局提交为 `75b7bde`，这些小幅显示偏移按实际回读记录。

许可只描述软件已知条件，物理电流建立及硬件绑定状态仍为待完成。正常重复帧保持位置/历史并将当次速度标为无效，已有完整51项历史可用于对齐保持判断。重复帧本身沿用既有故障语义，明确复位或许可撤销则进入安全处理。正常对齐继续采用10000/30000/2000拍，位置/速度分频及机械连续计数语义通过定向验证。

反馈块内已标出ID正常增量500、50MHz时戳正常增量5000，以及51项位置对应50个100us间隔。status位0～6分别表示启动、重复、缺帧、配置历史重置、无效编码器/非法跳变、半圈模糊和重新同步，资格块采用具名位组合替代裸116掩码。软限仍位于最终速度参考与Speed_Loop之间，向外禁止、向内允许。直接Iq测试的软限覆盖范围另行标注，硬±120mm及显式软件清错保持独立合同。

根层20/41/8/5字段接口、端口顺序与类型保持。`Initialized`表示软件初始化完成，`Reference_Commit`封装参考/许可/版本，AXI事务属于后续绑定。`Service_Request`提供最近遥测和计数，通信及长记录属于后续实现。驱动子系统依赖上层`system_fault`输入施加软件禁止，低有效ERRI_n/ERRU_n、F_Reset与软件清错分别处理。

### 活动来源与保留来源

日常R5算法的活动源已固化在上述三个使用位置。来源检查实际确认项目库链接和Model Reference均为0，逐块列出完整MATLAB Function及局部函数，外部逐采样`axu5ev_experiment_*`调用为0。打开、检查和直接R5生成共用来源检查，PL生成选择沿用其原有路径。

以下七份旧外部函数逐文件迁入 `simulation/tests/experiment/oracles/`，作为历史测试来源显式选用。历史R5库继续保留于 `simulation/experiment/r5/AXU5EV_Experiment_R5_Algorithms.slx`，日常R5加载选择取主模型。

```text
axu5ev_experiment_encoder_guard.m
axu5ev_experiment_frame_guard.m
axu5ev_experiment_bind_runtime_input.m
axu5ev_experiment_reference_commit.m
axu5ev_experiment_telemetry.m
axu5ev_experiment_point_move_step.m
axu5ev_experiment_scurve_profile.m
```

### 本轮实际验证

旧候选由原生成C的主机MEX复现7项反例，包含REL/EN/OE/PWM请求四种拒绝条件，以及RAMP_DOWN末拍Init_Reset、外部故障和许可撤销三种事件。旧结果记录为 `COUNTEREXAMPLES_REPRODUCED`，反例的安全断言均失败。本轮修复后以同类事件验证新的状态与输出合同。

独立Review随后发现PI_Reset的非零语义边界。源版本1.94的实际C在 `PI_Reset=0.25` 时仍进入RAMP_ID并产生0.00015A对齐命令。该反例已记录，修复 `2a9692d` 将许可检查改为非零判定，源版本为1.95，并在既有测试中追加9项检查、186次调用。下面生成与数值结果来自最终1.95候选，双入口隔离针对本轮来源调整执行。

| 验证对象 | 实际结果 | 范围 |
|---|---|---|
| 最终R5生成 | PASS | `r5_final_03`，ERT/Cortex-R配置导出15份C/H，实际BuildInfo中的5份C编译为主机transport-only MEX，源与C头部版本均为1.95 |
| 生成C定向集合 | PASS | 317项检查、275136次IRQ函数调用，初始化、反馈、清错、驱动、行程、对齐与服务 |
| 对齐安全 | PASS | 42项检查、227186次调用，拒绝开始、旧Start保持、新显式Start、三进行态中止、末拍优先级、重复及无效帧安全事件、非零PI复位 |
| 正常五态 | PASS | 正常流程42130次调用，跃迁0/10000/40000/42000，一次性偏置及机械计数保持，Id/Iq限值0.5A/0.3A |
| 反馈方向及回绕 | PASS | 183帧，正反向uint32计数回绕、帧号与uint64时戳回绕，速度±100mm/s |
| 行程 | PASS | 5490次调用，4项软限方向组合及2项含边界硬限，PI/Init复位保持故障，显式清错恢复 |
| 双入口和依赖隔离 | PASS | 两种打开顺序，各17项活动来源、7项退役helper退出日常路径、75参数/模型及6项Signal保存重开 |
| 主模型检查 | PASS | 844块边界检查及端口/连线/Stateflow检查通过，活动项目库链接、Model Reference及外部逐采样调用均为0 |
| ARM执行与硬件绑定 | NOT_RUN | `HW_BINDING_PENDING`、`BOARD_NOT_RUN` |

最终1.95候选生成目录为 `generated/experiment/pr46_review_01/r5_final_03`，原始生成日志和定向结果采用 `.runtime/experiment/pr46_review_01/r5_final_03`，日志为同级 `r5_final_03.log`。较早的 `r5`、`r5_final`、`r5_final_02`及反例记录继续保留。精简结果与截图位于[本轮证据目录](../../verification/experiment/pr46_review_01)。

最终生成日志保留两类警告。聚合`runtime_y`的部分来源缺少有效初始条件，因此Outport使用默认0。实际初始化安全输出由当次断言验证。直接读取RTW.BuildInfo时仍有原编译目录提示，后续实际源编译与MEX验证通过。这些主机结果的范围限于生成算法，IRQ/GIC/原子AXI、驱动电气、服务快照抢占一致性及目标ARM执行仍待交付B。

### 关键截图

- [用户顶层布局](../../verification/experiment/pr46_review_01/main_user_layout.png)
- [ISR主链及安全支路](../../verification/experiment/pr46_review_01/isr.png)
- [反馈内部](../../verification/experiment/pr46_review_01/feedback.png)
- [对齐状态与优先级](../../verification/experiment/pr46_review_01/alignment_state_priority.png)
- [对齐许可块内实际源码排印](../../verification/experiment/pr46_review_01/alignment_permit_source.png)
- [驱动合同](../../verification/experiment/pr46_review_01/driver.png)
- [行程速度参考路径](../../verification/experiment/pr46_review_01/travel_speed_path.png)
- [Runtime字段标注](../../verification/experiment/pr46_review_01/runtime_field_map.png)

本轮继续在PR46保持Draft并等待Review，参数、PI及PL HDL保持各自既有候选范围。板卡及电机操作继续等待相应硬件阶段授权。
