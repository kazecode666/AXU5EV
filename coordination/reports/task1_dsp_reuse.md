# Issue42 Task1 共享反馈组件复用

2026-11-17，分支 `codex/issue42-task1-dsp-reuse`，基线 `e36e358b9060a0eab99d1e3d78a3f0827302bd45`。已阅读 Draft PR43 路线图、Issue42 原规范及执行评论6936968803。本交付停在独立 Draft PR Review。[执行评论](https://github.com/kazecode666/AXU5EV/issues/42#issuecomment-6936968803)

## 来源与工作区

起始分支为 `codex/motor-control-chain`。安全 fetch 后确认其 HEAD 已包含于合并 PR41 的最新 main，再建立本轮分支。9项原有修改及全部未跟踪数据保留。MATLAB MCP 初次检查的会话没有已加载模型。

MATLAB 实际打开并读回 `references/legacy/mil/PMSLM_Close_Loop_MBDL4.slx` 与本地 `D:/Project/PMSLM_Simulation/PMSLM_Close_Loop_MBDL4_F28335_Backup.slx`。两者的校准 SID350、测量 SID465均已核对，结束时原来源模型 Dirty 均为 off。AQM 备份的校准为两相，主来源增加C相。读取了既有 `ax03a_legacy_module_map.csv`，新的逐项映射见 [Task1映射表](task1_dsp_component_map.csv)。历史索引保留其原时间口径。

本轮编辑的共享PL库继承用户原有排版。编辑前磁盘副本保存在 `.runtime/dsp_reuse/user_preserved/AXU5EV_PL_Algorithm_Library.slx`，ADC壳副本同目录。其余用户修改模型及 `init_AXU5EV.m` 保持本轮开始时内容，提交采用明确文件路径。

## 实际模型及生成边界

- `AXU5EV_PL_Algorithm_Library/Current_Offset_Calibration` 由 AQM 备份真实复制，保留其累加器、计数器、选择与偏置寄存块，裁为独立单路组件。`Current_Preprocess/Current_Processing` 链接两次，A/B分别按捕获有效位、OTR和校准许可推进。配置原子锁存、暂停、重启、手动seed、版本回绕及完成当拍无效语义延续现合同。
- 原 `ADC/QEP` 的 Subtract、Add、负增益块复制到电流图，接AN9238配置。运算路径显示原码Q16、减偏置、Q24增益、收敛舍入、宽位 `ic=-(ia+ib)`、末端int32饱和。14路输出继续共用原一拍寄存边界。
- `AXU5EV_Encoder_Components/Caculate_measurement` 复制旧位置减法、Gain5、Delay50、Add1和Gain1。Frame/Count guard承担已验证的资格、回绕连续化及机械原点管理。位置/差分/尺度/历史为可见块图。重复帧保持，缺帧、配置变化及非法输入重建历史，51个连续观察值形成50间隔，100us更新、5ms窗口。
- 旧DSP的速度IIR及对齐门控另列为来源差异。本候选延续PR41无滤波观察器。机械原点、电角偏置和Z元数据沿既有分工处理。
- `Encoder_Angle/Electric_Angle_Core` 复制旧测量Gain/Add并适配为可见Q52系数、加半LSB、移位20。原串行余数状态机提取为 `task1_encoder_phase_serial.m`，保持32步串行处理、30000测试周期及原输出寄存。逐采样资格、舍入/饱和等短函数各自保持有限职责。
- 新 `AXU5EV_Encoder_Feedback.slx` 链接同一测量组件，Embedded Coder生成ARM Cortex-R C。统一 `AXU5EV_Motor_Control_System` 的R5支路改为 `new_frame` 使能的同一库链接，两帧之间保持状态与输出。旧三个 `.m` 和旧 `motor_control_sim_r5` 标为冻结对照来源。

校准窗口、offset、gain、nm/count、零点、方向、版本均经可见配置端口传递。固定协议50间隔/100us和角度定点系数在块图显示，生成入口核对现有 `encoder_test_scale.json`。本轮沿用PR41测试尺度。

HDL/C新候选集中在 `generated/dsp_reuse/{adc,angle,feedback_c}`。原板级清单及 `generated/adc`、`generated/encoder` 继续承载PR41冻结源。FOC/PWM源、冻结bit/XSA/ELF、原SDF与Workspace继续保留。

## 有限验证

聚合结果见 [results.json](../../verification/dsp_reuse/results.json)，精简原始结果与RTL日志位于 [evidence](../../verification/dsp_reuse/evidence)。

| 层级 | 实际结果 |
| --- | --- |
| 模型结构 | 两共享组件、R5生成壳及受影响统一模型的端口/悬线/Stateflow检查通过 |
| 电流模型 | 原42项数值判据；49向量×14输出精确一致；一拍延迟；4帧ADC/QEP关联与重构通过 |
| 电流生成RTL | 原TB 25项断言通过，含1024样本窗口、独立校准、暂停/重启、完成边界及饱和 |
| 电角模型 | 46向量、2208模型步；34步模型前状态更新采样口径；理想角量化误差≤1 Q32 LSB |
| 电角生成RTL | 46向量、460检查通过；33个输入接受后边沿，父寄存下拍消费合同保持 |
| R5模型及目标C | 19场景、1493帧×7字段；各自对冻结来源零差，覆盖正反转、count/id/tick回绕、重复/缺帧、非法输入、满历史重建、配置及原点变化 |
| 统一模型连接 | 新共享反馈图运行55帧，18字段与仓库已有PR41帧表零差，包含同帧身份和三相比较值 |
| HDL生成诊断 | 电流与角度各0错误、1条 `ReuseRequiresInvariantConstants` 警告，涉及同原子子系统生成模块复用的内联条件 |
| 新综合/实现/STA/CDC/SDF | NOT_RUN |
| R5板上执行、ADC物理校准、外部接口及功率 | NOT_RUN |

适配中修正了旧校准图的double类型约束和信号对象绑定。Delay的 `level` 会在复位撤销时再清历史，本候选使用 `level hold`，1493帧对照已覆盖首次有效测速。布局PNG导出曾触发Simulink链接渲染/M3I警告，相关任务窗口已从已保存模型重新打开，库链接resolved，独立batch模型和数值检查通过。布局导出文件留在本地 `.runtime`。

## 打开、检查和生成

在MATLAB MCP调用统一入口。每次选择新的证据目录。

```matlab
addpath('D:/Project/AXU5EV/simulation');
task1_dsp_reuse('open');
task1_dsp_reuse('verify','D:/Project/AXU5EV/.runtime/dsp_reuse/my_verify');
task1_dsp_reuse('generate','D:/Project/AXU5EV/.runtime/dsp_reuse/my_generation');
```

必要的生成RTL定向检查采用现有TB。

```powershell
./scripts/task1_run_numeric_rtl.ps1 -RunDir D:/Project/AXU5EV/.runtime/dsp_reuse/my_rtl -AngleVectors D:/Project/AXU5EV/.runtime/dsp_reuse/my_verify/angle/angle_vectors.txt
```

统一模型仍使用 `simulation/motor_control/motor_control_run.m` 的隔离batch入口。依赖暂存现在取当前共享反馈组件，FOC与数值对照源保留原冻结版本，并记录既有source_relation文件。

后续Task2参数/PI、Task3驱动IO/行程、完整Runtime/五态对齐与Issue44时序研究仍待其各自阶段。新候选待Review，Issue42保持开放。
