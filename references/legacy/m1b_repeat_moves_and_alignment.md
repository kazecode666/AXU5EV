# M1B连续点位、原对齐与只读FOC准备验收

实现PR：[PR49](https://github.com/kazecode666/FPGA_XC7A200T_Study/pull/49)，open、非draft、未合并。

2026-10-24，原checkout `D:/Project/FPGA_XC7A200T`，分支 `codex/m1b-repeat-moves-alignment`。起点为已合并[PR48](https://github.com/kazecode666/FPGA_XC7A200T_Study/pull/48)，`main@9b63e9ae1e17901b663f3cf82290363fa1bfdbaf`；PR48只有任务/交接文档，未发现追加评论。依据[任务书](../tasks/m1b_repeat_moves_and_alignment.md)连续执行A—E。本报告区分模型行为、源图等价、标称物理验证、UI/API及HDL准备结果。

## 来源和本地改动保护

进入时先保存HEAD/status、原始二进制patch、新浮点SLX/init快照及8个只读来源快照，随后从origin/main非强制创建实现分支；没有worktree/clone/stash/reset/clean。以用户本地新浮点SLX增量编辑，没有用远端SLX覆盖它。旧Simple及其init/MAT、完整MIL、ControlCore、DSP、原轨迹函数和整定函数与进入时快照逐字节一致；29个无关原始patch片段完整保留。[保护验收](../../docs/reports/m1b_repeat_moves_alignment/workspace_preservation.json)。硬件资料的既有移动/删除、RTL/学习结果和用户配置没有纳入实现提交。

用户本地操作默认已是10 mm/5 s/V10/A100，Host已100 µs。依用户“最新本地为基础”保留它们；任务要求的1 mm/1.2 s/V5/A50作为显式回归工况。此项偏离任务文字中的日常默认，未覆盖用户设定。PI/电机、Pos_deadband=.02、J1000、100 µs/1 ms/10 ms/1 µs、50 µs更新及1 µs平均死区均保留；没有通过调参追求通过。

编辑通过MATLAB MCP，独立验证用本机MATLAB -batch进程；实际版本R2026b 26.2.0.3386108。进入MCP时无已加载用户模型。没有computer use或鼠标自动点击。库策略gate found=false/gatePass=true。结构编辑用原生SID/Stateflow API；已有toolkit自动布局对链接库的递归问题不适合本轮保留布局约束，故只在新增子系统局部安排，不改工具配置、不全局布局。未保存或改写旧模型。

## A：先测旧行为，冻结参考

修订前独立运行默认标准工况，原始 `.runtime/m1b_20261024/baseline/default_1mm_1p2s.mat` 在生产改动前取得，不覆盖。末位置0.9849676863605962 mm，差在原.02 mm窗内；关键增益/物理参数随参考保存。

两次旧实际目标入口live测试均先到.2 mm，再在连续running时间约.8 s时编辑真实Constant：

- .2→.4：旧全局计时已超过新轨迹总时长，参考直接到.4，表现为阶跃。
- .2→10：旧计时尚未超过新轨迹时长，参考从旧全局进度约3.3 mm取样，并非从.2 mm开始新段。

目标参数实际收到，仿真没有重新Run；因此结论是“缺少连续分段封装”，不是完全收不到目标。[原始行为结果](../../docs/reports/m1b_repeat_moves_alignment/baseline_behavior.json)。缺口测试先报告 `M1B:POINT_COMMANDS_PENDING`，再实施B。初次捕获的结构体赋值错误没有导致覆盖参考，重试复用已有原始数据；事件时间按实际参考最早变化重新提取，避免粗抽取草稿日志造成误标。

## B：单一Host中的连续绝对点位

新增纯函数 `pmlsm_point_move_step`，全部状态由Host_Core显式持有；没有helper隐藏状态或第二套轨迹。每次Host_Move_Request的0/1变化只消费一次，在100 µs边界判断Ready，锁存绝对目标、上一段终点和当前段时刻，复用原S曲线。编辑草稿不提交；Busy、非法目标和对齐禁止请求明确消费/拒绝，无队列。重复当前目标仅ACK，不重置时钟/积分或再运动。

Ready沿用实际.02 mm窗+1e-9浮点比较容差，在原位置事件上连续5拍，且轨迹完成、三闭环/PWM/复位/对齐条件允许。PWM/PI中断冻结该段参考，不能将非零规划速度直接当Ready，也不承诺自动恢复。原Reference_Manager/FOC数学未重写。

保存的Host显示用DSM供running状态只读观察Ready和本段信息，不参与控制回馈。API直接调Dashboard所绑定的Constant，和正常面板是同一路径，不直接给下游x_ref，不预填目标序列。

| 验收 | 实际结果 |
|---|---|
| 纯状态合同 | 正/反/短程累计绝对坐标，接受4、拒绝Busy+NaN共2；重复目标ACK |
| 原曲线V/A/J | 四种位移实测不超过冻结5/50/1000限制；[helper结果](../../docs/reports/m1b_repeat_moves_alignment/helper_acceptance.json) |
| 单次Run、3个新目标 | 首段.1后，Ready时临时提交.2→-.1→-.09；全部完成，含反向 |
| 接收延迟/段公式 | 均≤100 µs（最终旁路48 µs、对齐46 µs；先前检查点测到100 µs，浮点余差<1e-9 s），每段按记录的起点/时刻生成，公式误差0 |
| 非动作行为 | Busy的10 mm请求未排队；Ready时仅编辑99不动作；重复ACK；NaN拒绝、参考有限；实际pause/continue保持时间语义 |
| 证据 | [最终live](../../docs/reports/m1b_repeat_moves_alignment/point_live.json)、[逐段时间/到位误差](../../docs/reports/m1b_repeat_moves_alignment/commands.csv)、[实际轨迹](../../docs/reports/m1b_repeat_moves_alignment/point_live.png) |

一条测试函数只有一次start；在running中等待真实Ready并提交。API是控制链证据，**未自动点击UI**。墙钟耗时与仿真时间分开，等待有600 s上限，不放宽位置窗。

## C：直接复制原MIL对齐

主来源是实际 `PMLSM_ControlCore_Block/PMLSM_ControlCore/Angle_Init` SID128，完整MIL通过模型引用使用它；DSP对应图只读核对。复制chart到独立100 µs function-call包装，默认Alignment_Enable=0；源状态、动作、转移优先级、Signal解析及初值保持。完整迁移表见[来源映射](../../docs/reports/m1b_repeat_moves_alignment/alignment_source_map.md)与[源导出](../../docs/reports/m1b_repeat_moves_alignment/alignment_source.json)。

保留原IDLE0→RAMP_ID1→HOLD_ALIGN2→RAMP_DOWN_ID3→DONE4，10000/30000/2000拍、.5 A，原偏置锁存公式，以及固定角/反馈角、电流选择、q禁止、外环放行、复位及故障禁止语义。必要选择器从源Reference_Manager复制，不重写算法。未迁移原测速差分/IIR或硬件外设。

使用独立同相100 µs initiator、明确优先级使对齐先于控制任务；实际阶段进入时间为.0001、1.0001、4.0001、4.2001 s。真实角仍供plant/逆变器，控制角单独选择；对齐完成先保持实际当前位置，不清机械坐标，不用过期全局计时。

| 验收层次 | 实际结果与范围 |
|---|---|
| chart逐拍 | normal/no_start/reset/fault/reset_after_done五类，每类70001拍×6输出，状态和时间精确相同，最大数值差0 |
| Reset偏置有效性 | 非零位置4 mm的chart输入验证：Reset使Init_Done失效，但按原图保留旧偏置数值；不是清全部偏置/故障 |
| 原MIL物理参考 | 独立仅源模型进程，原静态电流测试零位置/零真实角场景；模式2，id保持最大误差.0175737802165 A、iq=0、周期角差0 |
| 新模型物理集成 | 同一标称零初态，id保持误差0、iq=0、周期角差0，真实/控制角分开记录；不是只看DONE |
| 对齐期间请求 | 10 mm请求被消费并拒绝，没有在DONE后执行 |
| DONE后连续两段 | 同一次Run按实际Ready提交.1→-.1 mm，均到位；草稿/重复/NaN/暂停继续亦核查 |

[对齐验收](../../docs/reports/m1b_repeat_moves_alignment/alignment_acceptance.json)、[源物理实测](../../docs/reports/m1b_repeat_moves_alignment/source_mil_physical_corrected.json)、[最终对齐后live](../../docs/reports/m1b_repeat_moves_alignment/point_aligned-live.json)、[逐段数据](../../docs/reports/m1b_repeat_moves_alignment/aligned_commands.csv)。

**物理适用范围限制：** 原保存场景只提供已知零位置/零角度（静态电流分支还冻结位置）的可运行参考，没有可证明未知非零安装偏置的现成场景。本轮未另造偏置入口，不能由chart一致或零角差宣称未知偏置识别成功。travel_fault_latch输入以明确标识的Simulation_Travel_Fault默认0注入，未恢复真实行程检测/完整故障管理。

## D：联合操作、日志与回归

[中文指南](../../docs/PMLSM_FLOAT_BASELINE_GUIDE_ZH.md)包含一次init/Run、Ready→草稿→切换发送、绝对10→20→5、三模式停止后选择、PWM/Stop差异、可选对齐Start/Reset和中断限制。运行/暂停预览读取当前锁存段；停止默认预览新首段，显式segment读取out最后一段；都复用原轨迹且不init。

- 正常保存模型直接Run：67个唯一日志名，原41个全保留；id_ref/iq_ref改为最终选择后真实FOC参考，选择前另用before_alignment名字记录。theta_true/control与控制Park电流独立。
- [信号表](../../docs/reports/m1b_repeat_moves_alignment/signals.csv)按实际日志时间导出：speed_memory/x_speed为1 ms；Host/命令/状态100 µs全采；物理曲线默认1 µs×100抽取=100 µs。未改plant步长。
- 102个Goto均local，144个From同父层唯一匹配，活动输入/输出无悬空；内嵌图仍绑定真实Host:1/plant:6，11路Motor_Control_Monitor保留。只整理新增对齐、选择器和显示区域，原FOC/PI/plant内部不全局重排。
- 修订前标准参考12路在共同时间戳上最大误差0；原9类电流/速度/位置正负、理想死区、负载、PWM/PI复位及plant步长检查共240指标全部通过，使用原M1A容差。新结果写独立目录，没有覆盖旧M1A报告。
- 独立MATLAB进程只复制六个必需文件运行，无旧MAT/旧模型/FPGA变量依赖，1.2 s末位置仍.9849676863605962 mm。实际点位段中PWM关闭另验中断、非Ready及应用电压零。

[接口验收](../../docs/reports/m1b_repeat_moves_alignment/interface_acceptance.json)、[默认等价](../../docs/reports/m1b_repeat_moves_alignment/default_equivalence.csv)、[240项回归](../../docs/reports/m1b_repeat_moves_alignment/legacy_regression/closedloop_metrics.csv)、[fresh](../../docs/reports/m1b_repeat_moves_alignment/fresh_acceptance.json)、[顶层布局](../../docs/reports/m1b_repeat_moves_alignment/model_layout.png)、[控制层布局](../../docs/reports/m1b_repeat_moves_alignment/control_layout.png)。布局图片为MATLAB导出；CSV为API元数据，未冒充SDI侧栏截图。面板绑定检查/API运行通过，鼠标点击未自动验收。

## E：FOC只读准备

完成当前8输入/3输出、参数/实际块/库链接/离散状态和类型盘点；明确Vdc来自内部Constant/Base、没有显式Vdc或enable端口。临时副本观测170个数值端口，补充live/反向及标称对齐的输入/状态范围，观察范围不代替设计上限。

当前官方帮助确认后运行 `checks=checkhdl(FOC)`，无代码生成：**1 Error、11 Warning、3 Message**。错误为DUT位于触发子系统内 `DutInsideTrigger`；浮点sector控制等仍有警告。内部全面观测暴露SVPWM两处未选中0/0分支各1199个NaN；实际输出与正常日志有限，原浮点核心未为此改写。记录为M2必须定义的数值语义，不报告兼容性通过。

[FOC准备报告](../../docs/FOC_FIXED_POINT_READINESS.md)区分已查、风险、范围待定和建议的最小M2：仅独立FOC定点实现，外环/Host/对齐/plant继续浮点。未定字长、未建正式定点SLX、未生成HDL/C或执行硬件工作。

## 失败、修复和未测项汇总

1. 初次chart捕获被ToWorkspace默认1000点截尾，不能证明全过程；已改无限点并重跑五类各70001拍，旧尾部结果保留runtime。
2. 源物理初次观测误把Model Reference输出8/9/10当id/iq/角度，实际是duty，结果无效。重读实际Outport编号3/4/5后独立重跑取得上述源物理结果；错误原始MAT/JSON留runtime，不作物理失败结论。
3. 迁移编译中遇Signal IC冲突、混合double/boolean逻辑及函数调用分支的输入依赖：保留原Signal初值继承，逻辑输入允许混合类型，改明确顺序的独立同相initiator；实际时序和逐拍测试验证。
4. 旧回归PWM观测沿用100倍抽取，而新增逻辑输出本已100 µs，导致时间轴不等。仅适配新路径日志抽取为1，原控制/容差不动，9场景240指标通过。
5. 发现复制源chart的一路Angle_Init_EN自带日志，与包装输出重名；取消复制图内部该一路日志，保留明确包装输出，该项修复时66路唯一性重跑通过，复审新增配置观测后共67路。
6. 第一次FOC全面观测误标记库内部动作端口，无法仿真；改为对非链接数值路径和库边界观测，保留库内部只读清单。之后0/0为真实观察风险，保留NaN计数而不将其隐去或改0。
7. 一次MATLAB MCP在默认比较已写出通过CSV后返回界面刷新错误；后续独立接口进程重跑默认12路差0。CLI退出时出现调参模型dirty无法自动关闭的提示，没有保存测试调参到源SLX。测试屏蔽对齐状态日志时Dashboard有无数据警告，仅该开发测试观测被关闭；正常保存模型记录完整。
8. 一次联合测试在观察Ready后又等待20 ms才发重复目标，实际到位窗已失效，模型正确拒绝，但测试误假定Ready持续保持而失败。原始数据保留aligned_repeat_ready_transient.mat；修正测试为提交前再次等待Ready，并按日志中的接收时Ready断言ACK或未Ready拒绝，不移动控制事件/放宽位置窗。指南已说明Ready可随实际窗口变化。
9. 最终独立只读复审未发现Critical，提出1项P2：历史segment预览混用当前Base的轨迹限制。针对性测试先实际失败（Saved segment changed after reinit），随后Host输出并记录trajectory_config，预览读取历史段实际配置，运行中读取同一Host快照。重新init后位置/速度/时间轴不变且与旧日志匹配；接口/运行中预览和六文件fresh重新通过。只加观测，控制与对齐数学未改。新增Host观测线用5对同层local标签整理；[Host布局](../../docs/reports/m1b_repeat_moves_alignment/host_layout.png)。一次与纯显示标签保存并行的测试出现磁盘源更改提示，随后在源稳定后重跑接口验收。
10. 没有computer use/鼠标点击、未知非零偏置物理识别、运动中重规划/热切环、完整故障管理、定点实现或HDL生成验收。

完整原始MAT、不可覆盖参考、测试日志/失败现场在 `.runtime/m1b_20261024`（不提交大体积数据）；可审查小表/JSON/图像在结果目录。脚本命令、范围及返回结果见[索引](../../docs/reports/m1b_repeat_moves_alignment/README.md)。提交一个开放实现PR等待Review，不自动合并或进入M2。
