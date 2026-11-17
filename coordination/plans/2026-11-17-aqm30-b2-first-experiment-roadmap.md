# AXU5EV — AQM30-B2 首次实机实验模型集成路线图

> 规划日期：2026-11-17。**本文件是开发规划，不代表已经完成实现、板测或授权上电。**
> 主线：保留 [PR41](https://github.com/kazecode666/AXU5EV/pull/41) 已合并的 ADC/QEP→FOC→PWM 数字链，以 [Issue42](https://github.com/kazecode666/AXU5EV/issues/42) 为 M1～M3 的原始技术任务书，后续集成 R5 Runtime、对齐、驱动管理和实验记录。J16-MBDL4 电平转换模块正在制板；未到货前不进行外部 PWM/QEP 的 5 V/3.3 V 物理联调。

## 1. 目标、已完成基线和验收边界

**目标：** 在接口板到货前，完成可复用算法整理、AQM30-B2 参数/代码生成、驱动 IO/行程逻辑、R5 Runtime/PL 时序、闭环仿真及实验记录，形成**待无功率实板验收**的成套候选；接口板到货后再进行电气检查、真实反馈标定、无功率联调和审慎的首次运动实验。

已验收、不从头重复：
- PR33/PR36 的双通道 ADC 校准/电流处理、统一模型/生成入口；PR37～PR41 的 ABZ、电角度、50 间隔测速与同帧 ADC/QEP→FOC→三相 PWM（仅数字链和对应离线证据）。
- PR41 已于 **2026-11-16 合并**；整链 RTL、原冻结候选的完整 STA/CDC、PWM 局部 slow/max 和 fast/min SDF 为既有证据；**完整功能 PL 动态 SDF 未完成**。原 `hardware_02/vitis_01` 等候选的无功率板测、R5 连续读回和六路外部物理接口未验收，不得误标 PASS。
- 旧 AX-02C2 的 R5 Runtime 与 PL 已有 64536 帧实际板载回放证据，但它使用**预先提供的反馈与旧调度合同**，不是新 ADC/QEP 实时机械闭环；ETH-01/02 的网络/数据传输成果可复用，不新建通信平台。
- 当前 `firmware/r5/motor_control/main.c` 是测试参考预提交与 128 条快照观察程序；`simulation/motor_control/AXU5EV_Motor_Control_System.slx` 的数字 SIM_ONLY 输入不含电机/逆变器 plant、完整外环或自动对齐。不得将其称为已完成的实机系统模型。

**职责分工：** PL（现有 SystemVerilog 外设与生成 HDL）负责 ADC 接收/电流预处理、ABZ/电角度、同帧冻结、FOC/SVPWM、载波/死区和快速禁止；R5（模型生成 C 为主）负责位置/50 间隔测速、位置 P、速度 PI、轨迹/参考、原五态启动对齐、驱动管理/故障恢复。电机/逆变器/负载只存在于仿真 plant 中。基准周期：电流 100 μs、速度 1 ms、位置 10 ms、测速位置历史 100 μs 更新且跨 50 间隔；不把 50MHz 误当成 R5 CPU 时钟。

## 2. 可执行任务包与先后依赖

| 阶段 | 唯一开发目标与原任务出处 | 完成标准（不等于板测） | 前置条件 |
|---|---|---|---|
| **M1（立即）** | **旧 DSP 子系统复用/代码生成边界**。执行 Issue42 Task1；读回 `references/legacy/mil/PMSLM_Close_Loop_MBDL4.slx`、本地 AQM 旧备份及 `ax03a_legacy_module_map.csv`。复用 `Current_Offset_Calibration`、`Caculate_measurement` 等到现有共享组件/Model Reference，接现有 ADC/QEP 接口，不再维护平行算法。 | 提供旧子系统→新组件映射、清晰可见的 Simulink 路径、原复位/校准/连续计数/位宽/延迟和 51 项历史语义，受影响的 MATLAB/HDL/C 生成与短测试 PASS；不改电机物理参数/PI，旧活动模型与用户未提交内容原样保留。独立 Draft PR。 | PR41 已合并；按 Issue42 原来源核实。 |
| **M2** | **AQM30-B2（Parallel）参数/PI 与生成一致性**。执行 Issue42 Task2，保留原 AUM 可复现基线。 | `τ_e=30mm`、`0.001mm/count`、30000有效count/电周期、固定控制 `Vdc=48V`（非实测）、`Rs=1.45Ω`、`Ld=Lq=11.8mH`（模型假设）在 plant、Runtime、角度/FOC 和受影响 C/HDL 生成物中一致；电流 PI `Kp=59,Ki=7250` 为待实机整定候选，完成 AW/48V 饱和/量化和定向阶跃验证；Ke 定义核查，总运动质量未知则显式参数化、不阻塞电流环。独立 Draft PR。 | M1 审核通过后；禁止只改 init 而继续用旧生成产物。 |
| **M3** | **原驱动 IO / 行程保护与真实 J16 端口候选**。执行 Issue42 Task3，并依据最终制板接口约束接入 PL 快速禁止。 | 复用旧 `Controller_Driver_IO_Manager`、`Travel_Safety_Manager`；清楚区分 RELCON、ENCON、F_Reset、OE、低有效 ERRI/ERRU、软件锁存与显式重臂；±110mm 软限向外禁止/向内退出、±120mm 硬阈值锁存；OE 不阻断故障复位通路；对比 PCB 最终网表生成端口映射/XDC，定向验证禁止/清错/复位。**外部信号、真实引脚、电平与驱动器仍 NOT_RUN。** 独立 Draft PR。 | M1可复用管理算法；J16最终引脚、缓冲方向与默认电平由PCB资料核对，不凭旧 DSP GPIO 号猜测。 |
| **M4** | **真实反馈→R5 Runtime→预提交参考→当前 PL 自动链，包含五态对齐**。复用 AX-02C2 Runtime、原 Reference/Alignment/Motion 控制模型，不改写新 C 算法。 | 完成正式跨帧合同，模型生成 C 与现有 AXI/PL 接口连接；编码器位置/速度、R5 产生 id/iq/omega 与控制模式、角度锁定/切回、相位偏置原子提交、异常与正常停机均有数值/时序证据；不再以测试常量/串口 `t/j/m` 作为运行算法。必要时分为 M4a（时序合同）和 M4b（集成），分别 Review。 | M1/M2；M4a 可先行只读分析，与 M1 并行。 |
| **M5** | **闭环模型与实验记录整合**。复用 Hybrid 的机械/平均逆变器 plant，统一算法与新部署参数；复用现有数据回放/网络事后下载。 | 没有第二套算法；覆盖启动、对齐、低电流指令、有限运动、故障/行程/禁止/恢复；统一帧号/时间戳记录电流、角度、位置/速度、参考、三相比较/有效/故障等，能导出并复现。现有 128 条快照仅 12.8ms，不能当成完整运动记录。生成匹配的新 bit/XSA/ELF 候选并完成必要功能、STA/CDC 检查；未做板测标 NOT_RUN。 | M2/M3/M4。 |
| **M6（等接口板）** | **分阶段实物验收**。 | ①接口板供电/地/方向/OE/安全默认状态核对；②**无功率** R5、ADC、ABZ、PWM、故障与冻结采集，保存 UART/快照/ILA；③AN9238 实际零流/增益/极性与读头方向/尺度确认；④具备独立安全条件和用户明确授权后，才逐步开展受限电流、对齐、首次运动/外环实验。 | 接口板电气与机械安全检查实际完成；逐场景授权，不能自动带功率。 |

## 3. 必须提前解决的跨帧时序风险（M4a，可与 M1 并行）

PR41 的完整 80 字控制快照在采样后的目标谷值采用确认之后（名义约 +50 μs）才发布；旧 PR24 实板回放中，上一结果读起到下一参考 COMMIT 最慢约 86.017 μs，旧模型为不同的反馈/发布合同。**因此旧 PR24 的 PASS 不能证明新 100μs 周期下 R5 可等完整快照再计算并在下一个 P0 提交。**

先只读核对：`hardware/axu5ev/motor_control/rtl/`、`firmware/r5/motor_control/main.c`、`coordination/reports/ax02c2_runtime_pl_replay.md`、`simulation/AXU5EV_R5_Runtime.slx`、`simulation/motor_control/AXU5EV_Motor_Control_System.slx`。
- 比较**方案 A**：在既有同帧有效身份条件下，向 R5 提前提供最小外环反馈（位置/速度所需数据），80 字完整快照继续用于诊断；与**方案 B**：明确定义固定跨帧（例如延一帧）参考更新，并在模型和身份检查中表达延迟。
- 输出：采样/发布/读取/计算/COMMIT/下一 P0 采用的时序图与 `sample_id`、`ref_version`、`applied_seq` 映射；包括帧丢失、无效、故障、对齐切换和 deadline miss 的安全状态。明确软件预算、必要的仪表点和目标板待测项。
- M4a 只提交评估报告和小范围可验证接口方案，**不直接更改冻结生产 RTL 或实施 R5 控制**；方案 Review 后由 M4b 执行。首轮不新增 DMA/RTOS/实时网络流。

## 4. 实施顺序、交付与停止点

1. **现在启动 M1 / Issue42 Task1**：一份只包含算法复用和生成边界的 Draft PR；不要把 M2 电机参数、M3 驱动 IO、M4 Runtime 混入首 PR。开始前先检查本地未提交/未保存模型及对应依赖来源；保护所有用户数据。
2. **同时允许 M4a 只读时序评审**：与 M1 不共享生产代码改动；先确定新 R5→PL 外环反馈的时间合同。
3. 用户 Review M1 后推进 **M2 → M3 → M4b → M5**。M3 的 PCB 引脚映射依赖最终网表，可并行做模型/逻辑，不假设制板通过即物理验收。
4. **接口板到货后再执行 M6**，先无功率后有限上电；用户对每次真实板卡下载、复位与功率操作分别授权。

按 `AGENTS.md`：主工作树/用户 SLX、`.runtime`、已有 bit/XSA/ELF/ILA、旧 PR41 SDF、真实测量数据不得被覆盖/清理；Git 小步提交，独立 Draft PR 等 Review，不自动合并/关 Issue。只做受影响测试；模型运行、主机/RTL、生成、时序、板测分别判定 PASS/FAIL/NOT_RUN。**不重复启动完整 SDF 24小时长跑，也不把 PWM 局部 SDF 当作全链通过。**

本规划只记录下一阶段的任务和边界；各项具体完成状态以**后续 PR、实验原始数据及对应报告**为准，不预先打勾。
