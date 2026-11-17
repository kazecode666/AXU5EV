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
