# AX-04B B6-1 · REAL IO R03 无功率首板步骤

获得现场授权后，从 A 到 C 分段执行。每段结束都可停机退出。全程断开直流母线、功率级和电机动力线，机械移动仅限 C 段的安全手动位移。保存每段的新文件，记录候选、连接条件、仪器、结果与未测项。[Issue #42 任务书](https://github.com/kazecode666/AXU5EV/issues/42#issuecomment-7211202786)

**J16 放行条件。** RTL 将六路外部 PWM、PWM_EN、RELCON 和 ENCON 固定为 0。固件拒绝 ARM、START、ALIGN_START、SETPOINT 和 DRIVER_RESET。现有 REAL `CALIBRATE` 在收到两路实测增益并通过门槛后会置位 `CTRL_EN` 请求。J16 接口板的 U2 控制输出与 U3 反馈输入共用该使能。STOP 和复位清零。如果现场边界要求 `CTRL_EN=0`，执行 A、B 的原码步骤和 C 的独立接口静态检查。B 的电流零偏校准和 C 的 R03 经 U3 联动需要复审明确允许这一缓冲行为，且必须隔离接口板的控制输出与驱动器。[AX-04B IO_CONTROL 合同](../../../integration/ps_pl/AX04B_INTERFACE.md) · [J16 接口与静态工程](../../../hardware/axu5ev/j16_level_test/README.md)

## A. 仅启动 AXU5EVB-E

1. 保持 J15、J16 空置，PC 与 GEM3 接隔离实验网。PC 可用 `192.168.50.20/24`，板端为 `192.168.50.10:5002`。在仓库根目录运行下列本地文件检查及 Studio 准备。它们只生成或读取本机文件。

   ```powershell
   Set-Location D:/Project/AXU5EV
   $candidate = '.runtime/experiment/final/GEM3_Control_REAL_IO_R03'
   $env:MOTOR_CONTROL_CONFIG = 'firmware/r5/motor_control/build_config.gem3.real.r03.json'
   python scripts/motor_control_build.py --check-startup
   $session = ".runtime/experiment/b6_board/$(Get-Date -Format yyyyMMdd_HHmmss)"
   New-Item -ItemType Directory $session
   .\scripts\start_motor_control_studio.ps1 -Prepare REAL -Output "$session/prepare_REAL_R03.tcl"
   'source "' + ((Resolve-Path "$session/prepare_REAL_R03.tcl").Path -replace '\\','/') + '"'
   ```

   看到 `OFFLINE_STARTUP_CHECK_PASS`，并核对下面的路径都在同一 R03 根目录。Studio 的“实验准备 → REAL IO”也可生成相同脚本。

   | 文件 | 相对于 R03 |
   | --- | --- |
   | bit / LTX / XSA | `hardware/ax04b_real.bit`、`hardware/ax04b_real.ltx`、`hardware/ax04b_real.xsa` |
   | R5_0 ELF | `vitis/ax04b_realtime/build/ax04b_realtime.elf` |
   | A53_0 FSBL | `vitis/ax04b_platform/export/ax04b_platform/sw/boot/fsbl.elf` |
   | PS–PL 初始化 | `vitis/ax04b_platform/hw/sdt/psu_init.tcl` |

2. 断电设置 SW1 为 `0000`（JTAG），接调试线，再给开发板单独供 12 V。在 Vitis 2026.1 打开 `$candidate/vitis`，启动 **Motor_Control_GEM3_REAL_IO_NoPower_R03**。等待 A53_0 FSBL 路径完成、R5_0 下载并停在入口。启动项 `programDevice=false`。在同一调试会话的 XSDB Console 执行上一步打印的 `source` 命令。核对手动下载回执使用 R03 bit，PS–PL 隔离解除与复位配置成功后，再手动 Resume R5_0。需要 ILA 时加载配套 LTX。[AXU5EVB-E 板卡资料](../../../hardware/axu5ev/ALINX_BOARD_FACTS.md)
3. 启动 `.\scripts\start_motor_control_studio.ps1` 并连接。实际设备应显示 **REAL IO**。需保存 JSON 或读细项时先断开 Studio，再运行 CLI。下列命令可在同一 PowerShell 窗口运行，文件名在同一实验目录中只用一次。

   ```powershell
   python scripts/motor_control_client.py version | Tee-Object "$session/A_version.json"
   python scripts/motor_control_client.py status | Tee-Object "$session/A_status.json"
   python scripts/motor_control_client.py diagnostics | Tee-Object "$session/A_diag.json"
   python scripts/motor_control_client.py sample | Tee-Object "$session/A_sample.json"
   ```

4. **通过判据**为 `hardware_profile=2`、`protocol=1`、`schema=1`、`application_id=0x41585205`、`pl_interface_id=0x41584201`、`dq_extension_id=0x41583501`（JSON 的身份数值用十进制输出），`armed=false`、`stop_pending=false`。应用身份沿用 R02，R03 用 Vitis 下载的路径和回执追溯。若匹配到 PS 业务组，实际 `mode=0` 且无参考许可。检查 `rt_ctrl_enable=0`，`words[78]` 的 bit 7–9、11 为 0，bit 10 为 1（F_Reset_n 未断言）。J16 空置且缓冲关闭时，两路 `rt_fault` 可报故障。遇到身份、禁止位或加载不匹配，或持续无诊断回复，停止该段并保存回执。保存 Vitis/XSDB 的 FSBL、ELF、bit 回执和上述 JSON。ARM/START 不作为现场测试。

## B. J15 AN9238 原码与电流标定

1. 断电按 J15 逐针表确认针 1、针 2 的 +5 V、GND、39–40 脚及 AN9238 插接方向。J16 继续空置。先用示波器测两个物理 CLK（J15.3 为 CH2，J15.31 为 CH1）。预期同相、约 5 MHz 和 50% 占空比。保存频率、占空比、两路相位和截图。[J15 逐针表](../../../hardware/axu5ev/AX03B2_J15_MAP.csv) · [AN9238 原始板测判据](../ax03b2/FIRST_BOARD_RUN_ZH.md)
2. 分别接两个已知 0 V，然后给两个不同的低压 DC（例如 +0.5 V、+1.0 V）。SMA 电压保持在已核实的模块允许范围内（既有 AN9238 指南为 ±5 V），实测接入后的端电压与公共地。每个电平稳定后，用 Studio“底层诊断 → 读取诊断快照”重复取样，或用下列命令把原始响应写入新文件。每个电平选不同文件名。

   ```powershell
   1..20 | ForEach-Object {
       python scripts/motor_control_client.py diagnostics
       if ($LASTEXITCODE -ne 0) { throw '诊断读取失败' }
   } | Set-Content -Encoding utf8 "$session/B_zero_volts.ndjson"
   ```

   `words[3]` 为所选采样 ID，`[4:5]` 分别为 tick 低、高字，`[6]` / `[7]` 为 A/B 的 12 位原码。仅用 `words[2]` 的 bit 0–2 均为 1 的配对数据，bit 3/4 为 A/B OTR。CH1 对应 A、CH2 对应 B，现场用单路改变量确认两个 SMA 到实际通道的对应。名义传递 `V_SMA = (raw−2048) × 10.04/4096 V`，0 V 附近为中码，正输入码增加。通过判据为两路时钟符合预期、输入通道和方向正确、比例与模块名义值相符且正常电压下 OTR 为 0。记录实测电压、码均值、范围与 OTR 次数。时钟缺失、通道错配、持续饱和或异常跳码时停止。开路只记录现象。诊断为低速读取，采样 ID 跳号是预期现象。
3. **电流标定另有前提。** 有完整传感链、独立电流参考、真实零流条件和上面的 `CTRL_EN` 放行条件后，才发 CALIBRATE。先用独立参考和原码在零流与多个已知电流点分别求两路带符号斜率 `ΔI_ref[A]/Δraw[count]`，确认极性及线性。Q24 整数为 `round(斜率 × 2^24)`，两路都必须为非零 signed int32。0 V 或开路不能代作传感器零流，名义 SMA 比例不能代作电流增益。条件未齐时完成原码步骤并把电流标定记为待测。[Issue #30](https://github.com/kazecode666/AXU5EV/issues/30)
4. 条件齐备且仍处于真实零流时，在 Studio 输入两路实测 Q24 并暂存，再点“零偏校准”。CLI 等效操作为 `calibration-gains <A整数> <B整数>` 后接 `command CALIBRATE`。回执应为 `staged=true`、`decision=0`。读取 `words[11:12]` 的 signed Q16 码偏置、`[13:14]` 的两路累积、`[15]` 的已应用版本及 `words[2]` bit 5/6 完成位。TCP 没有已应用 Q24 增益读回，保存发送的增益、回执和对应版本。两个完成位均为 1、`groups & 2` 且 `current_valid=true` 才比较 `ia_a/ib_a/ic_a` 与参考（Apeak，`ic=−(ia+ib)`）。记录零流残差、已知电流的比例与极性。失配、过量程或有效位丢失就停测。采完按文末检查 STOP。

## C. J16 编码器与反馈

1. 保持功率级和电机动力线断开。用已验证的电平转换、正确供电和公共地，将编码器接收器的 A/B/Z 和允许的故障反馈接到 J16。FPGA 侧为 3.3 V，禁止直送 5 V 或差分信号；控制输出与驱动器保持隔离。接口板初测只覆盖 QEPA 一路反馈，先在独立 J16 VIO 工程分别验证 QEPB、QEPZ、ERRI、ERRU 的外部低/高电平及通道，保存测点电压、VIO 前后状态。独立工序完成后回到 R03 启动项，核对禁止态。未完成逐路电气核对或共享缓冲放行时，R03 经 U3 联动保持待测。[J16 静态工程与管脚](../../../hardware/axu5ev/j16_level_test/README.md)
2. 联动条件齐备后，沿用 B 的合规零偏校准入口开启反馈缓冲。确认 `rt_ctrl_enable=1` 且 `words[78]` bit 11 为 1，同时 bit 7–9 仍为 0、F_Reset_n 保持 1、业务仍 IDLE 且未 ARM。在安全行程内手动小幅正反移动，并通过实际 Z 标记。每个稳定点保存诊断和业务样本。观察 `words[16]` signed QEP count、`[17]` signed Z 锁存计数、`[18:19]` 的 Z tick 低、高字、`[20]` 非法跳变计数和 `words[2]` bit 10 的 Z 已见。Z 是锁存事件。试验前后比较计数与 tick。
3. **通过判据**为计数方向与约定一致、正反移动可复核、非法计数不增加、经过 Z 地标时锁存更新，且已知位移的计数比例约为 **0.001 mm/有效计数**（1 mm 对应 1000 有效计数）。读取 `groups & 1` 下有效的 `position_mm/speed_mm_s`，分别检查 `position_valid/speed_valid`。速度按 **50 × 100 µs = 5 ms** 差分，速度历史填满后才使用。低速近匀速段可与独立位移/时间比较。读取 `encoder_angle_rad` 时检查 `encoder_angle_valid`，**30000 有效计数/电周期**，1 mm 名义角变化约 0.20944 rad，跨周按模 2π 比较。机械原点、Z 记录和电角度偏置分别留证。角度随位移变化只验收数字尺度，真实电磁相位对齐另测。
4. 静止且隔离时按逐路已验证的输入条件检查 ERRI/ERRU。观察 `rt_fault` 的 bit 0/1 分别响应对应的有效低输入。结合 `rt_ctrl_enable` 判读，缓冲关闭时两路被判故障。保持 RTL 功率禁止，读 `words[78]` 及必要引脚逻辑。若禁止位变化、方向错误、非法跳变累积或信号电平不符，立即停止该段。保存实际位移、计数、Z、带有效位的 JSON（或 Studio 趋势 CSV）、故障和禁止回读、必要波形。无有效 FOC 捕获时，FOC 控制角 `electrical_angle_rad` 和 dq 组无效。动态 PWM/死区走独立无功率工程，完整 ALIGNMENT、真实驱动使能与功率运动另立任务。[观测字段合同](../../../integration/ps_pl/AX05A_ONLINE_ZH.md)

每段结束用 Studio **STOP** 或断开 Studio 后用 `python scripts/motor_control_client.py command STOP`。保存 STOP 回执、`status` 和 `diagnostics`，核对未 ARM、`stop_pending=false`、`rt_ctrl_enable=0` 及功率禁止位。接线变化先给相关设备断电。R03 的 `REAL_IO`、物理输出/反馈电平和 `POWER_MOTION` 当前均为 `NOT_RUN`。
