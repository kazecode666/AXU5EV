% 唯一手动初始化入口；重新运行恢复默认命令，仿真运行中不要执行。
PMLSM_M1A_InitVersion=0; %#ok<NASGU> 失败时使旧标识失效
%% 常用仿真与上位机命令（mm、mm/s、Apeak）
M1A_StopTime_s= 5;
Host_Target_mm= 10; Host_Speed_mmps=0; Host_Id_A=0; Host_Iq_A=0;
Host_Position_Loop_EN=1; Host_Close_Loop_EN=1; Host_Iq_Test_Mode=0;
Host_PWM_EN=1; Host_PI_Reset_EN=0;
Host_Move_Request=0; Host_AutoStart_EN=1; Host_Ready_Ticks=5;
Host_Replay_EN=0; % 0手动，1经Host选择自动回放Speed/PWM/Reset
Host_Load_N=0; % 仿真负载；修改负载场景用M1A_Load_ts，母线用Udc

%% 电机物理参数
% 相电阻、相电感；电流为Apeak；60 mm为电气周期而非极距。
PMLSM_Rs_ohm=2.37;
PMLSM_Ld_H=1.745e-3; PMLSM_Lq_H=PMLSM_Ld_H;
PMLSM_psi_f_Wb=0.141; PMLSM_M_kg=0.91;
PMLSM_Kf_peak_N_per_Apeak=31.4/sqrt(2);
PMLSM_tau_NN_m=0.06; PMLSM_theta_offset_rad=0;
PMLSM_Bv_N_per_mps=0; PMLSM_Fc_N=0; PMLSM_v_eps_mps=1e-3;
Udc=48;

%% 控制与对象时基
% 控制周期、对象步长、PWM更新延迟、死区分别设置。
T_pwm=1e-4; Ts_ACR=T_pwm; Ts=Ts_ACR;
Ts_ASR=10*Ts_ACR; Ts_POS=10*Ts_ASR;
Ts_Plant=1e-6; PMLSM_Ts_s=Ts_Plant;
M1A_PWM_Update_Delay_s=T_pwm/2;


%% PI及运行限幅
% Ki为连续积分增益，离散积分使用Ki*Ts；速度PI积分限幅与输出限幅不同。
Tuning_Current_Xi=1/sqrt(2); Tuning_Speed_h=10; Tuning_Position_Separation=20;
Tuning_Gains=design_PMLSM_three_loop(PMLSM_Rs_ohm,PMLSM_Ld_H, ...
    PMLSM_M_kg,PMLSM_Kf_peak_N_per_Apeak,Ts_ACR,Ts_ASR,Ts_POS, ...
    Tuning_Current_Xi,Tuning_Speed_h,Tuning_Position_Separation);
Kp_ACR=Tuning_Gains.Kp_ACR; Ki_ACR=Tuning_Gains.Ki_ACR;
Kaw_d=Tuning_Gains.Kaw_d; Kaw_q=Tuning_Gains.Kaw_q;
Kp_ASR=Tuning_Gains.Kp_ASR; Ki_ASR=Tuning_Gains.Ki_ASR;
Kaw_s=Tuning_Gains.Kaw_s; Kp_pos=Tuning_Gains.Kp_pos;

Iq_int_limit=0.5; Speed_loop_Iq_Limit=1;
Pos_deadband=0.02; V_pos_max_mmps=20;
v_ff_eps=0.5; v_over_eps=3; v_ref_max=20;
v_ref_set_rate_dn=50; v_ref_set_rate_up=50;
v_ref_set_step_dn=v_ref_set_rate_dn*Ts_ACR;
v_ref_set_step_up=v_ref_set_rate_up*Ts_ACR;
v_ref_zero_eps=0;

%% 平均逆变器
PMLSM_deadtime_s=1e-6;
PMLSM_deadtime_ratio=PMLSM_deadtime_s/T_pwm;
PMLSM_deadtime_current_eps_A=1e-4;

%% 轨迹规划（停止后设置）
Host_Enable_Schedule=[0 1 1 1];

Host_Speed_Ramp_s=0.1;
Host_Start_s=0.05;
Host_Traj_Amax=100; Host_Traj_Jmax=1000; Host_Traj_Vmax=10;

M1A_Load_ts=timeseries([Host_Load_N;Host_Load_N],[0;M1A_StopTime_s]);
M1A_LoadStep_ts=timeseries([0;0.5;0],[0;0.8;1.0]);
M1A_PWM_ts=timeseries([1;1],[0;M1A_StopTime_s]);
M1A_Reset_ts=timeseries([0;0],[0;M1A_StopTime_s]);
M1A_Speed_ts=timeseries([0;0],[0;M1A_StopTime_s]);
M1A_Load_ts=setinterpmethod(M1A_Load_ts,'zoh');
M1A_LoadStep_ts=setinterpmethod(M1A_LoadStep_ts,'zoh');
M1A_PWM_ts=setinterpmethod(M1A_PWM_ts,'zoh');
M1A_Reset_ts=setinterpmethod(M1A_Reset_ts,'zoh');
M1A_Speed_ts=setinterpmethod(M1A_Speed_ts,'zoh');

%% 原MIL启动对齐（默认旁路，开启需停止后设置）
Alignment_Enable=0; Init_Start=0; Init_Reset=0;
Simulation_Travel_Fault=0; % 仅仿真注入，不代表真实行程检测
Ramp_Ticks=10000; Hold_Ticks=30000; Id_Release_Ramp_Ticks=2000;
Id_Init_Target=0.5; Id_Init_Step=Id_Init_Target/Ramp_Ticks;
theta_align_const=0; Tau_e_mm=PMLSM_tau_NN_m*1000; Theta_Offset_Fine=0;

% 保留原chart的显式Signal解析及0初值，仅提供其必要接口对象。
Alignment_Signal_Names={'Init_Done','Init_State_Num','id_init_ref','Angle_Init_EN','Theta_Offset_auto','x_align_mm_latch'};
for Alignment_Index=1:numel(Alignment_Signal_Names)
 Alignment_Signal=Simulink.Signal; Alignment_Signal.DataType='double'; Alignment_Signal.InitialValue='0';
 assignin('base',Alignment_Signal_Names{Alignment_Index},Alignment_Signal);
end

%% 连续交互日志（物理曲线按100us；命令事件不抽取）
M1B_Physical_Log_Decimation=100;

%% FOC实现（停止后选择，默认浮点参考）
FOC_Impl_Select=0;
FOC_Fixed_Parameters=struct('Rs',PMLSM_Rs_ohm,'Ld',PMLSM_Ld_H,'Lq',PMLSM_Lq_H, ...
 'psi',PMLSM_psi_f_Wb,'Kp_ACR',Kp_ACR,'Ki_ACR',Ki_ACR, ...
 'Kaw_d',Kaw_d,'Kaw_q',Kaw_q,'Ts_ACR',Ts_ACR,'Udc',Udc);
FOC_Fixed_Config=pmlsm_foc_fixed_config(FOC_Fixed_Parameters);

%% 初始化成功标识（必须最后设置）
PMLSM_M1A_InitVersion=20261023;
