# AXU5EV 软硬件架构

2026-10-25 确定由 Cortex-R5F 执行运动控制、PL 执行电流控制。AX-04B R1 已完成这一分工的离线绑定与构建，现场验收状态见[当前交接](../coordination/HANDOFF.md)。

## 1. 研究主线

PL保留可替换的电流控制核，PI-FOC为首个已验证算法基线；后续电流控制研究在此边界内迭代。速度/位置环与未来更复杂运动算法放R5软件，避免每次修改外环都重建硬件流水线。

| 功能 | 所有者 |
|---|---|
| 位置P、速度PI及未来外环算法 | R5F，软件周期任务 |
| 原Angle_Init五态、一次性位置锁存/偏置求解 | R5F，原采样语义 |
| 参考选择/斜率限制、轨迹、命令及参数管理 | R5F为主；GUI/文件可以留PC |
| 三相电流采样数字接口、编码器接收/计数/同步快照 | PL；实际ADC转换由外部器件完成 |
| 每帧控制电角度、偏置应用与范围处理 | PL实时数据路径；偏置由R5原子提交 |
| 电流控制、坐标变换、限幅、SVPWM | PL，由独立实机 FOC 模型生成 |
| 命令快照、有效性/超时、PWM时序和快速禁止 | PL及驱动硬件；R5做诊断和恢复决策 |
| 电机/平均逆变器与负载模型 | 仿真环境，绝不当作部署算法 |

纯仿真和实机分别维护模型、算法与参数。实机参数以 AQM30-B2 Parallel 为来源，名义电周期 30 mm、编码器 1 µm/有效计数，48 V 为固定控制参考。真实电流比例与极性、编码器方向与尺度以及总运动质量仍待确认。旧 AUM 设置归属于相应仿真或历史基线。[双入口说明](../simulation/README_运行说明.md) · [实机参数源](../simulation/experiment/parameters/axu5ev_experiment_parameters.m)

## 2. 时间与状态

电流及对齐基准周期 100 µs，速度环 1 ms，位置环 10 ms。纯仿真保留 1 µs 对象步长与既有 50 µs 应用边界。AX-04B PL 事件逻辑名义 50 MHz，PWM 域名义 100 MHz。ARM 实际执行与 IRQ→COMMIT 时延均为 `NOT_RUN`。[AX-04B 结果](../verification/experiment/ax04b/results.json)

现行构建使用 RPU split 模式下的 R5_0 裸机应用，启动由匹配的 A53_0 FSBL 和平台初始化文件配套完成。部署时使用同一候选的硬件与软件产物。[首运行指南](../firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md)

对齐保留IDLE→RAMP_ID→HOLD_ALIGN→RAMP_DOWN_ID→DONE、原计数/斜坡/公式。原五态在软件中执行，不重新设计偏置算法；正常运动中的电角度处理不因此绕到R5每拍往返。保持真实角与控制角分离。

## 3. PS—PL边界

选中采样的 P76 冻结最小同帧反馈并置 IRQ。R5 读取反馈，调用生成的 `PL_Frame_IRQ()`，提交下一 P0 的整包参考，并按精确事件序号确认 IRQ。反馈含样本身份与时标、编码器计数、电流资格、标定和故障。参考含 dq 给定、速度、角度偏置、复位与许可请求、目标身份和传输版本。PL 分别记录参考接受和实际采用，原 80 字诊断快照在 PWM 谷值后独立发布。[帧相位、字段与验收判据](../integration/ps_pl/AX04B_INTERFACE.md)

多字段命令采用暂存后一次提交，PL在明确的控制边界使用；反馈有一致快照。电流核不等待每次ARM计算才运行；外环任务超时、命令过期和快速故障禁止分别定义。故障清除不等于自动重新使能，也不等于清除驱动板故障。

J16-MBDL4 V0.3 有 14 路业务信号和 2 路使能。`PWM_EN` 控制 U1，`CTRL_EN` 由 U2/U3 共用。当前 REAL 候选允许在获授权的无功率阶段观察 ADC、编码器与故障输入，六路门极、PWM 缓冲使能及 `RELCON`/`ENCON` 硬禁止。模型字段 `OE_Disable` 属于软件许可逻辑，板上两个使能的连接由物理接口决定。[交付 B 报告](../coordination/reports/ax04b_hardware_binding.md) · [J16 首板静态记录](https://github.com/kazecode666/J16-MBDL4-Module/blob/main/docs/writing/interface_board_static_test_record.md)

## 4. 平台迁移历史

PR53的p3是Artix-7核心已接受实现，数值、复位、状态和5000拍合同可作参考；其资源、WNS、物理引脚和314拍结果不自动成为5EV整机结论。需确认AXU5EV实际板卡/核心板修订和器件全料号后重定向实现。

旧M4全三环HDL候选仅保留复用价值：已知接口、XSI连接、测试和失败定位。不要继续优化其对齐取模，也不要把未通过的候选标成生产基线。

AX-00 迁移阶段仅确定长期职责分工，软件生成、板级绑定与验证分别由后续工作交付。[AX-00 迁移记录](../coordination/reports/ax00_migration_report.md)
