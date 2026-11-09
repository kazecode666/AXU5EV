# 统一无功率数字链入口

本轮只离线构建和仿真，不连接/发现/下载/运行板卡，不接驱动板、电机或外部PWM/QEP线。六路只在内部观察，physical_link_verified=0。本说明不是上板授权。

## 查看、运行和生成

统一模型为 `simulation/motor_control/AXU5EV_Motor_Control_System.slx`，唯一运行入口 `motor_control_run(<新结果目录>)`，通过MATLAB MCP调用。它运行真实电流/角度库组件、原FOC和模型数值映射；SIM_ONLY接口/显示不代替RTL接收器或100MHz边沿验证。用户已修改的ADC/共享库不保存，受控运行在隔离batch中使用Git已提交的原依赖，详见数值入口说明。

原FOC/电流/角度生成物直接复用；新Q30到比较值算法源 `simulation/motor_control/duty_to_compare.m`，生成入口 `motor_control_generate_mapper`。R5位置与50间隔测速继续复用 `simulation/encoder/encoder_position_speed.m` 生成的C，未加入外环或自动对齐。改算法、改RTL接口和生成索引见统一motor_control README。

PL继续使用 `hardware/axu5ev/motor_control/build.tcl`，包装入口 `scripts/motor_control_build_hw.ps1`；静态AUTO_CONTROL/AUTO_FOC选择自动来源，手动duty提交在自动候选返回SLVERR。不能同时写两个active来源。

```powershell
# 复现时均指定新目录，不重新执行已完成候选的all：
./scripts/motor_control_run_rtl.ps1 -RunDir .runtime/motor_control/<新RTL目录>
./scripts/motor_control_build_hw.ps1 -Stage all -Output .runtime/motor_control/<新硬件目录>
# 按新硬件修改build_config和未占用Workspace后：
vitis.bat -s scripts/motor_control_build.py
python scripts/motor_control_build.py --check-startup
```

采用的硬件/Workspace及实际PASS项以 `verification/motor_control/results.json`、`coordination/HANDOFF.md` 首节为准。默认新配置为 `.runtime/motor_control/hardware_02/ax03b3_adc.bit/.ltx/.xsa`、Workspace `.runtime/motor_control/vitis_01`，平台 `motor_control_platform`、应用 `motor_control_observer`、Launch `motor_control_manual`。ELF为Workspace下 `motor_control_observer/build/motor_control_observer.elf`，A53 FSBL为 `motor_control_platform/export/motor_control_platform/sw/boot/fsbl.elf`。

## 后续获准后手动观察

1. 另行获准后才按既有A53 FSBL＋R5路径手动启动，显式选本次bit/ltx和匹配平台的PS初始化。Launch不自动下载PL。应用只到 `MOTOR_CONTROL 4d435401 WAIT`，不自动arm。
2. `c`先禁止，再请求数字TEST电流校准：N16、gain65536。它只是本轮数字尺度，不是真实电流标定。当前输入来自真实ADC针脚路径，未接入的模拟信号/母线不能当传感器实测。
3. `t`停止内部ABZ测试运动，预提交id=0、iq约0.1A、omega=0、Vdc=48V和arm。静止向量只在编码器停止后解释。等待快照参考版本/有效位，首个有效FOC结果前保持禁止。
4. `j`预提交iq约0.2A阶跃，仍由PL反馈→FOC→模型比较值→PWM自动交接；R5不逐帧写duty。
5. `m`显式启动原接收器前的合成ABZ源；每10us一个有效count，TEST的0.001mm/count与30mm电周期对应名义omega=20.943951rad/s（Q24=351381190）。这是声明的测试参考，不是R5把mm/s直接当rad/s或真实速度传感器测量。
6. `r`按PL新快照轮询最多128帧，期间不打印；`p`在采集停止后导出位置/速度、FOC输入身份、参考版本、duty、比较值及实际采用身份。真实无漏帧服务能力NOT_RUN，历史不足/重复/缺帧规则沿用PR39。`s`只读一次状态。
7. `d`通过独立禁止命令停止逻辑输出，同时取消此前已提交但尚未在P0采用的参考；恢复须在它之后重新显式提交arm，旧pending不会自动复活。不将其称作板卡/驱动器急停。重启PL/换候选须重新启动R5观察器，重新建立历史和显式提交，不能跨无法辨识的复位声称连续位置/速度。

## 字段与时间

MCT1 identity=0x4d435431、schema3，共80字；BEGIN=0x00冻结，payload从0x0c开始，最后word79在 **0x148读响应** 后释放。读/写通道分开，原电流和编码器写地址保留；不能用旧0x88/0xac释放位置。

前41字的单位沿用PR39（sample_id正常+500、tick正常+5000）。新增word41为控制标志，42–44为FOC采样ID/tick，45参考版本，46–56整组冻结九字段（theta/omega各占两字，不截成32位），57–59为unsignedQ30 duty，60–62为0..5000比较值，63本次提交采样ID，64最后已确认采用的ID，65–67为提交/晚到/无效计数，68–69为原核帧号/capture_edge，70–71目标谷值tick，72结果数。73–79保留0。

word64是最后确认的采用历史，不代表禁止后仍有当前使能输出；必须联合word41的有效/禁止/late位与采样ID/参考版本判断。预提交参考在选中phase0采用；反馈约2.2us准备好，FOC输入在固定P128接受、原核全5000使能拍继续运行，结果在P442附近捕获。比较值到100MHz域后只在sample_tick+2500（名义+50us）的目标谷值整组采用，晚到不冒充该边界成功；控制快照在该谷值确认后发布。实际相位测量见整链验证记录。

固定捕获以后发生disarm、失锁或晚到，只立即禁止/取消PWM，不在本帧中途改变已冻结的FOC输入或global reset。下一次固定捕获若仍无效，则使用零电流/参考/角度/速度、48V与PI_Reset=1；若已显式重臂且反馈有效，则继续原PI状态，不增加隐式PI恢复系统。

IQ/id单位A，角度Q32 rad，omega Q24 rad/s，Vdc Q24 V；Q30映射饱和到[0,1]后乘5000、half-up舍入。母线48V、omega及AQM测试尺度均为明确测试量；旧AUM电机参数/PI不改，不能因此称为参数一致的真实机械闭环。模型不叠加第二次平均死区，实际互补和死区由原PWM RTL验证。

当前PWM ILA仍为4096点、约100MHz，连续窗口约40.96us，短于完整100us PWM周期及选样峰值到下一采用谷值的50us。后续获准采集时，分别触发观察死区、整组采用和许可/重新使能边界；同帧FOC身份与输入/结果用80字原子快照核对。不能用一次ILA窗口声称看到了完整采样→计算→采用周期。本轮未增加ILA深度。

外部引脚/电平、真实电流标定、AQM完整参数恢复、完整R5外环/Runtime/对齐及有功率联调均为后续任务。保留全部旧Workspace和原始输出。
