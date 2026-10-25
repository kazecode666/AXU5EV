%% =====================================================================
%  AUM3-S4 PMLSM FOC 控制系统 - F28388D 实机初始化参数
%  适用硬件：TMS320F28388D + YXPHM-MBDL4 + AUM3-S4
% =====================================================================
clear; clc;

%% --- 1. 系统主频与 PWM 硬件参数 ---
CPU_Clock = 200e6;                % F28388D CPU1 SYSCLK (200 MHz)
EPWM_Clock = 100e6;               % F2838x ePWM 模块时钟，最终以时钟树配置复核
PWM_Freq = 10000;                 % PWM 开关频率 (10kHz)
Ts = 1 / PWM_Freq;                % 控制器绝对采样步长 (0.0001秒)

EPWM_HSPCLKDIV = 1;
EPWM_CLKDIV = 1;
TBCLK = EPWM_Clock / (EPWM_HSPCLKDIV * EPWM_CLKDIV);
PWM_Period = TBCLK / (2 * PWM_Freq); % Up-Down, 10 kHz 时初值 5000
PWM_DeadTime_s = 1e-6;
PWM_DeadTime_Count = round(PWM_DeadTime_s * TBCLK); % 初值 100，示波器复核

%% --- 2. 电机铭牌与增量式编码器参数 ---
qep_mid_cnt = 2147483648;
Grating_Resolution_mm_per_count = 0.0001; % 0.1 um/count；结合 eQEP 计数模式复核
Tau_e_mm = 60;  % AUM3-S4 完整 2*pi 电气周期

%% --- 3. AUM3-S4 电机物理参数（相量/dq 参数）---
Rs = 2.37;              % ohm，相电阻 = 4.74 ohm / 2
Ls = 1.745e-3;          % H，相电感 = 3.49 mH / 2
Ld = Ls;
Lq = Ls;
flux = 0.141;           % Wb，当前 AUM3-S4 磁链基准

% 当前 ControlCore PI 路径使用的兼容命名。
PMLSM_Rs_ohm = Rs;
PMLSM_Ld_H = Ld;
PMLSM_Lq_H = Lq;
PMLSM_psi_f_Wb = flux;

%% --- 4. 驱动板硬件参数 ---
ADC_OffsetA = 2253;      % 理论初值，必须在 PWM 禁止时自动/实测校准
ADC_OffsetB = 2253;
ADC_OffsetC = 2253;
ADC_GainA = 0.01664;     % A/count，按 3.0 V ADC 与 44 mV/A 理论初值
ADC_GainB = 0.01664;
ADC_GainC = 0.01664;
Three_Current_Sampling_EN = Simulink.Parameter;
Three_Current_Sampling_EN.CoderInfo.StorageClass = 'ExportedGlobal';
Three_Current_Sampling_EN.DataType = 'boolean';
Three_Current_Sampling_EN.Value = true; % 1: IA/IB/IC独立采样；0: IC=-IA-IB兼容路径
VDC_ADC_V_per_count = 3.0/4096;
VDC_Scale_V_per_V = 20; % MBDL4: DCIN = 20 * VDC1
Udc = 48;                % 首轮控制计算标称值；后续接入实测 VDC

%% --- 5. 工业级 PI 控制器参数 ---
Ts_ACR = 1e-4;     % 电流环 10 kHz
Ts_ASR = 1e-3;     % 速度环 1 kHz
Ts_POS = 1e-2;     % 位置环 100 Hz
Ts_SCI = 1e-3;     % 串口发送 1 kHz
% 1. 位置环(POS)参数
Kp_pos = 5;    
Pos_deadband = 0.02;
V_pos_max_mmps = 10;
% 2. 电流环 (ACR) 参数 - 首轮实机按 AUM3-S4 xi=1 基准的 50% 启动
Kp_ACR_Baseline = Lq/(4*Ts_ACR);          % 4.3625
Ki_ACR_Baseline = Kp_ACR_Baseline*Rs/Lq; % 5925
ACR_Commissioning_Scale = 0.5;
Kp_ACR = ACR_Commissioning_Scale*Kp_ACR_Baseline; % 2.18125
Ki_ACR = ACR_Commissioning_Scale*Ki_ACR_Baseline; % 2962.5
Iq_Limit = 0.30;  % 首轮低电流限幅，确认方向/采样后再逐步提高
Kaw_q = 0.2;        %anti-windup 回算系数如果发现：一旦饱和，恢复还是太慢,就加大到;如果发现：一进饱和就抖,那就减小。​
Kaw_d = Kaw_q;
% 3. 速度环 (ASR) 参数 - (单位是RPM，需大幅缩小比例项)
Kp_ASR = 0.03;
Ki_ASR = 0.05;
Kaw_s  = 0.4;
Speed_loop_Iq_Limit = Iq_Limit;
Iq_int_limit = 0.10;
%速度环摩擦补偿
Iq_fric_start = 0.40;   % 静止启动补偿
Iq_fric_run   = 0.05;   % 运行中补偿
v_stick_on  = 1.0;   % 低于 1 mm/s，认为接近静止，进入启动补偿
v_stick_off = 3.0;   % 高于 3 mm/s，认为已经运动，切到运行补偿
v_ff_eps      = 0.5;    % mm/s，速度给定小于这个就不补偿
v_over_eps = 3;   % mm/s，允许略微超过给定
%速度测量
delay_N = 50;%速度采样延迟50拍
% 停止复位
v_ref_zero_eps  = 0.2;   % mm/s
v_meas_zero_eps = 0.5;   % mm/s
%速度给定
v_ref_max = 20;
v_ref_set_rate_up = 50;     % 手动速度给定上升斜率，mm/s^2
v_ref_set_rate_dn = 50;     % 手动速度给定上升斜率，mm/s^2
v_ref_set_step_up = v_ref_set_rate_up * Ts;   % 0.01 mm/s per step
v_ref_set_step_dn = v_ref_set_rate_dn * Ts;   % 0.01 mm/s per step

%% --- 6. 初始启动对齐阶段
theta_align_const = 0;     % 初始化时固定电角度
Id_Init_Target    = 0.5;  % 首轮实机低电流对齐
Ramp_Ticks = 10000;   % 约 1 s
Hold_Ticks = 30000;   % 约 3 s
Id_Release_Ramp_Ticks = 2000;  % 0.2 s @ 10 kHz, smooth id_init_ref release after alignment
Id_Init_Step = Id_Init_Target / Ramp_Ticks;
    

%% --- 7. 电机行程限制
V_meas_max = 500;

X_min_soft = -470;
X_max_soft =  470;
X_min_hard = -500;
X_max_hard =  500;
%% --- 8. 全局在线调试变量 (CCS 实时控制) ---
%PWM使能
ENCON_Manual = Simulink.Parameter;
ENCON_Manual.CoderInfo.StorageClass = 'ExportedGlobal';
ENCON_Manual.DataType = 'boolean';
ENCON_Manual.Value = false;  %初始为0，PWM使能先关闭，等稳定之后，手动开启PWM使能

%MBDL4主继电器控制
RELCON_Manual = Simulink.Parameter;
RELCON_Manual.CoderInfo.StorageClass = 'ExportedGlobal';
RELCON_Manual.DataType = 'boolean';
RELCON_Manual.Value = false; % 初始不吸合，必须由受控上电顺序放行

%短脉冲复位信号
FReset_Manual = Simulink.Parameter;
FReset_Manual.CoderInfo.StorageClass = 'ExportedGlobal';
FReset_Manual.DataType = 'boolean';
FReset_Manual.Value = false; %只有手动清故障锁存时，在 CCS 里把它短暂改成 1，再回到 0。

%F28388D底板PWM电平转换器OE，低有效；首轮上电保持禁止
GPIO30_PWM_OE_Disable = Simulink.Parameter;
GPIO30_PWM_OE_Disable.CoderInfo.StorageClass = 'ExportedGlobal';
GPIO30_PWM_OE_Disable.DataType = 'boolean';
GPIO30_PWM_OE_Disable.Value = true;

% 目标转速给定 (电子油门)
v_ref_set = Simulink.Parameter;
v_ref_set.CoderInfo.StorageClass = 'ExportedGlobal';
v_ref_set.Value = 0; % 初始转速为 0

% D轴目标电流给定 (用于每次上电的抱轴标定)
Id_Ref_Set = Simulink.Parameter;
Id_Ref_Set.CoderInfo.StorageClass = 'ExportedGlobal';
Id_Ref_Set.Value = 0;    % 恢复为0，我们要在 CCS 里手动给 1 标定

% 积分器复位使能开关 (充当算法的“手刹”)
PI_Reset_EN = Simulink.Parameter;
PI_Reset_EN.CoderInfo.StorageClass = 'ExportedGlobal';
PI_Reset_EN.Value = 1;  % 初始值为1：强制锁死 PI 积分器，清零误差，防止暴走！

% 强制 0 度对齐模式开关 (用于上电抱轴认零)
Align_EN = Simulink.Parameter;
Align_EN.CoderInfo.StorageClass = 'ExportedGlobal';
Align_EN.Value = 0; % 初始值为1：强制输出0度电角度，切断编码器反馈引起的跳动

% 速度环测试
Iq_Test_Mode = Simulink.Parameter;
Iq_Test_Mode.CoderInfo.StorageClass = 'ExportedGlobal';
Iq_Test_Mode.Value = 0;   % 0: 速度环输出, 1: 固定iq测试

Iq_Test_Ref = Simulink.Parameter;
Iq_Test_Ref.CoderInfo.StorageClass = 'ExportedGlobal';
Iq_Test_Ref.Value = 0;  % 固定iq测试值

% I/F启动后手动切到速度环
Close_Loop_EN = Simulink.Parameter;
Close_Loop_EN.CoderInfo.StorageClass = 'ExportedGlobal';
Close_Loop_EN.Value = 0;  % 手动切入纯速度闭环的允许标志 (0: 等待, 1: 允许切入)

%位置环使能
Pos_Loop_EN = Simulink.Parameter;
Pos_Loop_EN.CoderInfo.StorageClass = 'ExportedGlobal';
Pos_Loop_EN.Value = 0;  %位置环开：选Nr_ref_pos；位置环关：选 Nr_Ref_Set

%目标位置给定
x_ref_mm = Simulink.Parameter;
x_ref_mm.CoderInfo.StorageClass = 'ExportedGlobal';
x_ref_mm.Value = 0;

Theta_Offset_Fine = Simulink.Parameter;
Theta_Offset_Fine.Value = 0;
Theta_Offset_Fine.DataType = 'double';
Theta_Offset_Fine.CoderInfo.StorageClass = 'ExportedGlobal'; 

%上电自动校准零电流偏置
OffsetCal_EN = Simulink.Parameter;
OffsetCal_EN.CoderInfo.StorageClass = 'ExportedGlobal';
OffsetCal_EN.DataType = 'double';
OffsetCal_EN.Value = 0;  % 1：自动校准零电流偏置；0：所有内部状态保持当前值，offset 保持不变

% 注压测试
Ud_Test_EN = Simulink.Parameter;
Ud_Test_EN.CoderInfo.StorageClass = 'ExportedGlobal';
Ud_Test_EN.DataType = 'double';
Ud_Test_EN.Value = 0;% Ud_Test_EN = 0：正常控制；Ud_Test_EN = 1：测试注压

sine_EN = Simulink.Parameter;
sine_EN.CoderInfo.StorageClass = 'ExportedGlobal';
sine_EN.DataType = 'double';
sine_EN.Value = 0;

Uq_Zero_EN = Simulink.Parameter;
Uq_Zero_EN.CoderInfo.StorageClass = 'ExportedGlobal';
Uq_Zero_EN.DataType = 'double';
Uq_Zero_EN.Value = 0;% Uq_Zero_EN = 1：q 轴强制 0;Uq_Zero_EN = 0：q 轴用正常 PI

Uq_Test_EN = Simulink.Parameter;
Uq_Test_EN.CoderInfo.StorageClass = 'ExportedGlobal';
Uq_Test_EN.DataType = 'double';
Uq_Test_EN.Value = 0;

Ud_Test = Simulink.Parameter;
Ud_Test.CoderInfo.StorageClass = 'ExportedGlobal';
Ud_Test.DataType = 'double';
Ud_Test.Value = 0;

Uq_Test = Simulink.Parameter;
Uq_Test.CoderInfo.StorageClass = 'ExportedGlobal';
Uq_Test.DataType = 'double';
Uq_Test.Value = 0;

%上电初始对齐使能打开
Init_Start = Simulink.Parameter;
Init_Start.CoderInfo.StorageClass = 'ExportedGlobal';
Init_Start.DataType = 'double';
Init_Start.Value = 0;

%上电初始对齐使能结束
Init_Reset = Simulink.Parameter;
Init_Reset.CoderInfo.StorageClass = 'ExportedGlobal';
Init_Reset.DataType = 'double';
Init_Reset.Value = 1;

%全局观测变量
obs_ia_calc = Simulink.Signal;
obs_ia_calc.DataType = 'double';
obs_ia_calc.InitialValue = '0';
obs_ia_calc.CoderInfo.StorageClass = 'ExportedGlobal';

obs_ib_calc = Simulink.Signal;
obs_ib_calc.DataType = 'double';
obs_ib_calc.InitialValue = '0';
obs_ib_calc.CoderInfo.StorageClass = 'ExportedGlobal';

obs_ia = Simulink.Signal; 
obs_ia.InitialValue = '0';
obs_ia.CoderInfo.StorageClass = 'ExportedGlobal';

obs_ib = Simulink.Signal;
obs_ib.InitialValue = '0';
obs_ib.CoderInfo.StorageClass = 'ExportedGlobal';

obs_ic = Simulink.Signal;
obs_ic.InitialValue = '0';
obs_ic.CoderInfo.StorageClass = 'ExportedGlobal';

obs_id = Simulink.Signal; 
obs_id.InitialValue = '0';
obs_id.CoderInfo.StorageClass = 'ExportedGlobal';

obs_iq = Simulink.Signal; 
obs_iq.InitialValue = '0';
obs_iq.CoderInfo.StorageClass = 'ExportedGlobal';

obs_QPOSCNT = Simulink.Signal; obs_QPOSCNT.CoderInfo.StorageClass = 'ExportedGlobal';

obs_v_mmps = Simulink.Signal;
obs_v_mmps.InitialValue = '0';
obs_v_mmps.CoderInfo.StorageClass = 'ExportedGlobal';

obs_etheta = Simulink.Signal;
obs_etheta.InitialValue = '0';
obs_etheta.CoderInfo.StorageClass = 'ExportedGlobal';

obs_id_ref = Simulink.Signal;
obs_id_ref.InitialValue = '0';
obs_id_ref.CoderInfo.StorageClass = 'ExportedGlobal';

obs_iq_ref = Simulink.Signal;
obs_iq_ref.InitialValue = '0';
obs_iq_ref.CoderInfo.StorageClass = 'ExportedGlobal';

obs_ud = Simulink.Signal;
obs_ud.InitialValue = '0';
obs_ud.CoderInfo.StorageClass = 'ExportedGlobal';

obs_uq = Simulink.Signal;
obs_uq.InitialValue = '0';
obs_uq.CoderInfo.StorageClass = 'ExportedGlobal';

obs_ud_raw = Simulink.Signal;
obs_ud_raw.InitialValue = '0';
obs_ud_raw.CoderInfo.StorageClass = 'ExportedGlobal';

obs_ud_lim = Simulink.Signal;
obs_ud_lim.InitialValue = '0';
obs_ud_lim.CoderInfo.StorageClass = 'ExportedGlobal';

obs_s = Simulink.Signal;
obs_s.CoderInfo.StorageClass = 'ExportedGlobal';

obs_uq_raw = Simulink.Signal;
obs_uq_raw.InitialValue = '0';
obs_uq_raw.CoderInfo.StorageClass = 'ExportedGlobal';

obs_uq_lim = Simulink.Signal;
obs_uq_lim.InitialValue = '0';
obs_uq_lim.CoderInfo.StorageClass = 'ExportedGlobal';

obs_e_q = Simulink.Signal;
obs_e_q.InitialValue = '0';
obs_e_q.CoderInfo.StorageClass = 'ExportedGlobal';

obs_sat_flag_z = Simulink.Signal;
obs_sat_flag_z.CoderInfo.StorageClass = 'ExportedGlobal';

U_max = Simulink.Signal;
U_max.CoderInfo.StorageClass = 'ExportedGlobal';

obs_ADC_OffsetA_auto = Simulink.Signal;
obs_ADC_OffsetA_auto.DataType = 'double';
obs_ADC_OffsetA_auto.InitialValue = '2253';
obs_ADC_OffsetA_auto.CoderInfo.StorageClass = 'ExportedGlobal';

obs_ADC_OffsetB_auto = Simulink.Signal;
obs_ADC_OffsetB_auto.DataType = 'double';
obs_ADC_OffsetB_auto.InitialValue = '2253';
obs_ADC_OffsetB_auto.CoderInfo.StorageClass = 'ExportedGlobal';

obs_ADC_OffsetC_auto = Simulink.Signal;
obs_ADC_OffsetC_auto.DataType = 'double';
obs_ADC_OffsetC_auto.InitialValue = '2253';
obs_ADC_OffsetC_auto.CoderInfo.StorageClass = 'ExportedGlobal';

obs_Offset_Cal_Done = Simulink.Signal;
obs_Offset_Cal_Done.DataType = 'double';
obs_Offset_Cal_Done.InitialValue = '0';
obs_Offset_Cal_Done.CoderInfo.StorageClass = 'ExportedGlobal';

obs_count_z = Simulink.Signal;
obs_count_z.DataType = 'double';
obs_count_z.InitialValue = '0';
obs_count_z.CoderInfo.StorageClass = 'ExportedGlobal';

obs_offsetcal_en_z = Simulink.Signal;
obs_offsetcal_en_z.DataType = 'double';
obs_offsetcal_en_z.InitialValue = '1';
obs_offsetcal_en_z.CoderInfo.StorageClass = 'ExportedGlobal';

obs_OffsetCal_EN_effective = Simulink.Signal;
obs_OffsetCal_EN_effective.DataType = 'double';
obs_OffsetCal_EN_effective.InitialValue = '0';
obs_OffsetCal_EN_effective.CoderInfo.StorageClass = 'ExportedGlobal';

dbg_count_state = Simulink.Signal;
dbg_count_state.DataType = 'double';
dbg_count_state.InitialValue = '0';
dbg_count_state.CoderInfo.StorageClass = 'ExportedGlobal';

dbg_cal_running = Simulink.Signal;
dbg_cal_running.DataType = 'double';
dbg_cal_running.InitialValue = '0';
dbg_cal_running.CoderInfo.StorageClass = 'ExportedGlobal';

obs_x_mm = Simulink.Signal;
obs_x_mm.InitialValue = '0';
obs_x_mm.CoderInfo.StorageClass = 'ExportedGlobal';

obs_v_ref = Simulink.Signal;
obs_v_ref.InitialValue = '0';
obs_v_ref.CoderInfo.StorageClass = 'ExportedGlobal';

obs_v_ref_pos = Simulink.Signal;
obs_v_ref_pos.InitialValue = '0';
obs_v_ref_pos.CoderInfo.StorageClass = 'ExportedGlobal';

obs_RELCON = Simulink.Signal;
obs_RELCON.CoderInfo.StorageClass = 'ExportedGlobal';

travel_fault_latch_z = Simulink.Signal;
travel_fault_latch_z.InitialValue = '0';
travel_fault_latch_z.CoderInfo.StorageClass = 'ExportedGlobal';

Init_State_Num = Simulink.Signal;
Init_State_Num.InitialValue = '0';
Init_State_Num.CoderInfo.StorageClass = 'ExportedGlobal';

Init_Done = Simulink.Signal;
Init_Done.InitialValue = '0';
Init_Done.CoderInfo.StorageClass = 'ExportedGlobal';

Theta_Offset_auto = Simulink.Signal;
Theta_Offset_auto.InitialValue = '0';
Theta_Offset_auto.CoderInfo.StorageClass = 'ExportedGlobal';

Angle_Init_EN = Simulink.Signal;
Angle_Init_EN.InitialValue = '0';
Angle_Init_EN.CoderInfo.StorageClass = 'ExportedGlobal';

id_init_ref = Simulink.Signal;
id_init_ref.InitialValue = '0';
id_init_ref.CoderInfo.StorageClass = 'ExportedGlobal';

x_align_mm_latch = Simulink.Signal;
x_align_mm_latch.InitialValue = '0';
x_align_mm_latch.CoderInfo.StorageClass = 'ExportedGlobal';
% ... 其他你需要的变量 ...

disp('F28388D + MBDL4 + AUM3-S4 参数加载成功；当前为安全禁止输出的初始状态。');
