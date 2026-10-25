# AXU5EV — 当前交接

日期：2026-10-26。仓库 `kazecode666/AXU5EV`，本地 `D:/Project/AXU5EV`。

AX-00迁移PR #1、资料任务PR #2、资料成果PR #4、R5首批提取PR #5及AX-01B任务PR #6均已合并。迁移和资料阶段结束，继续已有控制开发，不重新走资料盘点、StudyL1或LED学习。

## 当前任务

已实施 [AX-01B：R5命令/轨迹集成与生成C＋FOC RTL电机闭环](tasks/ax01b_r5_runtime_hybrid_closed_loop.md)。Runtime、在线C包装、p3帧适配及共享电机闭环已接通；三后端四组正常场景均完成，真实RTL共99432帧逐位一致。实际结果见[AX-01B报告](reports/ax01b_runtime_hybrid.md)，操作见[混合闭环指南](../docs/AXU5EV_HYBRID_RUN_GUIDE_ZH.md)。

本轮交付完整链：原Host_Core/轨迹与必要运行管理纳入R5运行模型 → 生成C在线执行 → 数值/帧转换及p3结果提交 → 同一个电机环境内的实际C＋RTL反馈闭环 → 正常点位、连续命令和原对齐/启停场景 → 用户操作指南与一个开放实现PR。等待Review，不自动合并；下一轮接实际R5F平台与板级适配。

不在本轮同时开展实际R5 BSP/Vitis平台、AXI硬件总线、5EV综合布线或ADC/编码器板级设计；这些接在混合功能闭环之后。C在PC执行不等于R5已经运行，仿真交换不等于AXI已经实现。

## 固定方向与已有起点

- **目标板AXU5EVB-E，用户已确认。** 非B版仅对照。PCB/芯片完整料号和厂商示例器件差异留待板级适配前核对，不阻塞当前软件/功能仿真。
- Cortex-R5F负责位置P、速度PI、原五态对齐与偏置、参考/轨迹/命令和恢复管理；PL复用电流FOC，负责实时采样/位置/角度、PWM与快速禁止。
- 原参考为 `simulink模型/PMLSM_PI_FOC_Float_Baseline.slx`、`PMLSM_FOC_FixedPoint.slx`、既有初始化及类型/点位/S曲线函数；原主模型不因新集成而被改成另一算法。
- PR5已交付 `firmware/r5/AXU5EV_R5_Control.slx`、组件对照和主机C回放；本轮在独立 `AXU5EV_R5_Runtime.slx` 中复用原组件并增加Host_Core，不手写另一套PI或对齐。用户原有SLX修改未覆盖。
- PL来源为 `generated/legacy_m3_p3/FOC_DUT.sv` 及p3配置，按原5000拍和输入保持/状态合同做功能集成；314拍不是新增外围后的整链总延迟。
- `pmlsm_point_move_step.m`、`pmlsm_scurve_profile.m`继续提供到位后再次发送目标的行为，不新增运动中重规划。
- 继承 `references/legacy/PMLSM_Hardware_Interface_Map.md`、MBDL4参数和MIL/DSP：YXPHM-MBDL4、三相ia/ib/ic、0.1µm/count光栅、RELCON/ENCON/F_Reset、低有效ERRI/ERRU；不照搬DSP引脚，不要求用户重述已有需求。

## 工作方式

按用户要求正常开发、Git提交和PR。只做本轮功能所需的编译/模型与闭环运行，不增加哈希清单、全资料遍历、快照保护报表、字节一致性专项、防御性基础设施或额外冒烟测试。旧任务书/Issue #3相关要求是历史，不再作为当前流程。现有控制保护功能与此不同，不擅自删除。

保持原参数、首相、手动Start、五态计数、一次死区、50µs应用边界及PWM禁止后机械继续。From/Goto局部，端口默认大小，检查新模型实际连线和排版；不修改用户未保存窗口或无关本地内容，不批量删除。报告写实际改动、结果和未完成项即可，不要求用户额外提交哈希值。

## 当前证据与边界

PR5主机ERT C生成、五组组件对照和独立C回放见[结果](reports/ax01_r5_extraction.md)。本轮已用薄C MEX在线执行完整Runtime，三后端四组正常闭环及同输入比较完成，真实p3 RTL累计99432帧逐位一致；Simulink管理SIL仍未通过，不为其重装工具。完整数据与边界见[AX-01B报告](reports/ax01b_runtime_hybrid.md)。

[PS—PL边界](../integration/ps_pl/INTERFACE.md)已包含本轮实际仿真字段和事件顺序，仍不是总线驱动。R5目标编译/任务时间、真实AXI、5EV综合布线、ADC/位置/PWM板级适配和实机均未完成。旧Artix结果不当作5EV验收。

原迁移资料见[AX-00报告](reports/ax00_migration_report.md)，厂商参考见[AX-00B报告](reports/ax00b_vendor_review.md)及[R5指南](../firmware/r5/ALINX_R5_REUSE_GUIDE.md)。只在当前需要时查用，不重复整轮阅读。硬件烧录和功率级上电仍需用户另行授权，不自动合并PR。
