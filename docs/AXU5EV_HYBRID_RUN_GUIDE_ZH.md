# AX-01B 混合闭环运行

目标板为 AXU5EVB-E。本轮在 Windows 主机执行模型生成 C，Vivado XSI 执行原 p3 SV；电机、逆变器、位置反馈均来自原仿真环境。没有连接功率级，也没有运行 R5 板上程序。

## 打开与构建

在仓库根目录的 MATLAB 命令窗口执行：

```matlab
addpath('scripts');
ax01b_prepare_hybrid('c_fixed');
```

模式为 `model_fixed`（Runtime 模型＋定点 FOC）、`c_fixed`（生成 C＋定点 FOC）或 `c_rtl`（相同生成 C＋实际 p3 SV）。停止仿真后再换模式。三者使用同一集成模型、量化、对象和应用边界。

首次 C 模式会由 `firmware/r5/AXU5EV_R5_Runtime.slx` 生成 ERT C，并构建薄 MEX。首次 RTL 模式还构建 XSI DLL 和调用块，需要本机 Vivado 2026.1。工具位置在 `ax01b_prepare_hybrid.m` 的 `vivado` 变量及 `ax01b_build_xsi.ps1` 默认参数；若安装位置不同，改这两个入口后重建。缓存、DLL、MEX及完整波形都在 `.runtime/ax01b/`。

普通 Run 不重新生成控制代码。要明确重新生成：

```matlab
ax01b_prepare_hybrid('c_rtl',true);
```

生成 C 使用原外部初始化参数。修改 PI、采样或轨迹配置等生成时参数后，先停止，再以 `true` 重建；不能只改 MATLAB 工作区便认为编译进 C 的参数已变化。目标、Send、PWM/PI/Init 等运行输入不需要重编译。不要在其他闭环进程使用 DLL/MEX 时重建。

## 同次 Run 下发点位

准备入口保留原默认：10 mm、5 s、V10/A100、原可选自动首段。长场景可在停止时延长模型 StopTime。真实 RTL 在本机明显慢于仿真时间，应以仿真时间和 Ready 判断进度。

1. 点击 Run。关闭对齐时，沿用原自动首段行为。
2. 在 `Set_Host_Target_mm` 修改目标草稿。修改草稿不启动运动。
3. 等待 `View_move_ready` 为 1，再将 `Send_Move_Toggle` 翻转一次；0→1 和 1→0 都算一次发送。
4. `View_command_status`、`View_move_busy` 和接受目标日志可确认接收。Busy 时发送会拒绝，不排队；重复已接受目标只确认，不重新起段。
5. 可在同次 Run 中继续发送正向、反向目标。保留原 0.02 mm 窗和连续 5 次位置事件条件；Ready 可能随原闭环纹波变化，不以轨迹时长结束替代到位。

面板绑定的是 `Simple_Host` 中的运行输入；轨迹只在 Runtime 模型／生成 C 中计算，没有另一条 PC 外环旁路。暂停／继续不初始化 C 或 RTL 状态；新的 Run 才初始化。

## 对齐、停止与复位

停止时启用 `Set_Alignment_Enable`，Run 后手动将 `Set_Init_Start` 置 1，再释放为 0。保留原 RAMP_ID 10000 拍、HOLD_ALIGN 30000 拍、RAMP_DOWN_ID 2000 拍、0.5 A。等待 `View_Init_Done`，然后按 Ready／Send 继续发点位。总对齐约 4.2 s，不能用短 Run 判断完成。

`Set_Host_PWM_EN` 是请求；实际许可还受原对齐／故障链约束。PWM 禁止作用于逆变器输出，机械位置和速度仍演化。`Set_Host_PI_Reset_EN` 复位控制积分／原参考状态；`Set_Init_Reset` 复位原对齐；二者不等同整体仿真重置或驱动清故障。中断／故障后沿用原命令恢复语义，清故障不自动续跑。`Simulation_Travel_Fault` 是已有仿真故障入口，不是 ERRI/ERRU 硬件驱动实现。

## 正常场景与结果

```matlab
ax01b_run_closedloop('c_fixed','point');       % 1 mm / 1.2 s
ax01b_run_closedloop('c_fixed','continuous');  % 草稿、Busy拒绝、Ready后两次新目标、反向、重复确认
ax01b_run_closedloop('c_fixed','alignment');   % 手动Start、物理对齐、随后运动
ax01b_run_closedloop('c_fixed','stop_reset');  % PWM、PI/Init与已有故障入口
```

同样的 scene 可用于其他两种 mode。脚本通过面板所绑定的常数入口在暂停点改变命令，不直接写下游 x_ref。连续场景在实际 Ready 后发下一命令，仿真暂停不会清状态。

结果保存为 `.runtime/ax01b/<mode>_<scene>.mat`。`out.logsout` 包含 `x_mm`、`target_mm`（x_ref）、`v_mmps`、`id`、`iq`、三相电流、真实／控制角、`vd_applied/vq_applied` 和 `duty_u/v/w_applied`。`r5_commit` 包含 v/id/iq 参考、接受目标、Ready、命令状态及对齐／偏置，字段见 [接口](../integration/ps_pl/INTERFACE.md)。`duty_result` 为计算结果；`foc_frame` 为实际送入 FOC 的九字段；`rtl_frame_events` 为帧号、捕获边沿、有效和保持违规。可在仿真数据检查器／原监视器查看。

```matlab
ax01b_compare_reference('c_fixed','point');
```

此命令对实际闭环记录做同输入模型／C和定点／RTL参考比较。回放只用于独立数值核对；`c_rtl` 的控制反馈由实时 XSI 计算，绝非录制输入驱动的 RTL 回放。并行 RTL MATLAB 会话不需要同时加载 Motor Control Blockset；定点参考比较在持有该许可的会话运行。

本轮实测、未完成项和曲线见 [AX-01B 报告](../coordination/reports/ax01b_runtime_hybrid.md)。R5 目标编译、真实 AXI、WCET、5EV 综合／布线、ADC／位置板级接口和实机均 NOT_RUN。
