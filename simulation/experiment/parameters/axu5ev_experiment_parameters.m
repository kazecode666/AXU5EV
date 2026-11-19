function [p,provenance]=axu5ev_experiment_parameters()
% AX-04 experiment parameters, loaded into experiment model workspaces only.
% The AQM30-B2 Parallel R/L, encoder and 48V definitions come from Issue42.
% Current PI uses the existing xi method. Outer-loop gains retain the AQM
% backup candidate because total moving mass has not been measured.
p=struct;
p.Experiment_Parameter_Version=uint32(20261117);
p.Hardware_Binding_Complete=false;
p.Physical_Calibration_Valid=false;
p.Total_Moving_Mass_Known=false;
p.Total_Moving_Mass_kg=NaN;

% Apeak and millimetre conventions follow the copied Runtime and FOC.
p.PMLSM_Rs_ohm=1.45;
p.PMLSM_Ld_H=0.0118;
p.PMLSM_Lq_H=0.0118;
p.PMLSM_tau_NN_m=0.03;
p.Tau_e_mm=30;
p.Grating_Resolution_mm_per_count=0.001;
p.Encoder_Nanometres_Per_Count=uint32(1000);
p.Encoder_Counts_Per_Electrical_Period=uint32(30000);
p.PMLSM_Kf_peak_N_per_Apeak=30.4/sqrt(2);
p.PMLSM_psi_f_Wb=p.PMLSM_Kf_peak_N_per_Apeak/(1.5*2*pi/p.PMLSM_tau_NN_m);
p.Udc=48;

% The active R5 model uses these periods for its feedback window and divider
% thresholds. A new hardware period also requires a matching PL candidate.
p.Ts_ACR=1e-4;
p.Ts=p.Ts_ACR;
p.Ts_ASR=1e-3;
p.Ts_POS=1e-2;
assert(positive_integer_ratio(p.Ts_ASR/p.Ts_ACR) && ...
    positive_integer_ratio(p.Ts_POS/p.Ts_ASR), ...
    'AX04:LoopPeriods','Outer-loop periods must be whole multiples of their input period.');
% Accepted positions are separated by delay_N current-control intervals.
p.delay_N=50;
assert(positive_integer_ratio(p.delay_N) && p.delay_N<255, ...
    'AX04:FeedbackWindow','The delay must contain 1 to 254 feedback intervals.');
p.Feedback_Tick_Hz=uint32(50000000);
p.Feedback_Id_Step=uint32(500);
ticks_per_frame=double(p.Feedback_Tick_Hz)*p.Ts_ACR;
assert(positive_integer_ratio(ticks_per_frame) && ...
    mod(round(ticks_per_frame),double(p.Feedback_Id_Step))==0, ...
    'AX04:FeedbackClock','The frame must contain a whole number of ticks per feedback ID.');
p.Feedback_Tick_Step=uint64(round(ticks_per_frame));

% Continuous Ki and per-sample Ki*Ts are distinct quantities.
p.Tuning_Current_Xi=1/sqrt(2);
p.Kp_ACR=p.PMLSM_Lq_H/(4*p.Tuning_Current_Xi^2*p.Ts_ACR);
p.Ki_ACR=p.Kp_ACR*p.PMLSM_Rs_ohm/p.PMLSM_Lq_H;
p.Kaw_d=min(0.2,p.Ts_ACR*p.PMLSM_Rs_ohm/p.PMLSM_Lq_H);
p.Kaw_q=p.Kaw_d;
% Preserve the source debug limits, including its 0.5 A alignment target.
p.Experiment_Id_Limit_A=0.50;
p.Experiment_Iq_Limit_A=0.30;

% Preserved AQM-backup outer-loop candidates. These require later tuning.
p.Kp_ASR=0.03;
p.Ki_ASR=0.05;
p.Kaw_s=0.4;
p.Kp_pos=5;
p.Iq_int_limit=0.20;
p.Speed_loop_Iq_Limit=p.Experiment_Iq_Limit_A;
p.Pos_deadband=0.02;
p.V_pos_max_mmps=20;
p.Iq_fric_start=0.40;
p.Iq_fric_run=0.05;
p.v_ff_eps=0.5;
p.v_over_eps=3;
p.v_ref_max=20;
p.v_ref_set_rate_up=100;
p.v_ref_set_rate_dn=100;
p.v_ref_set_step_up=p.v_ref_set_rate_up*p.Ts_ACR;
p.v_ref_set_step_dn=p.v_ref_set_rate_dn*p.Ts_ACR;
p.v_ref_zero_eps=0;
p.v_meas_zero_eps=0.5;
p.V_meas_max=500;

% Preserve the Runtime five-state alignment and explicit manual start.
p.theta_align_const=0;
p.Theta_Offset_Fine=0;
p.Ramp_Ticks=10000;
p.Hold_Ticks=30000;
p.Id_Release_Ramp_Ticks=2000;
p.Id_Init_Target=0.5;
p.Id_Init_Step=p.Id_Init_Target/p.Ramp_Ticks;

p.Host_Start_s=0.05;
p.Host_Load_N=0;
p.Host_Traj_Vmax=20;
p.Host_Traj_Amax=200;
p.Host_Traj_Jmax=1000;
p.Host_Speed_Ramp_s=0.2;
p.Host_Ready_Ticks=5;
p.Host_AutoStart_EN=0;

p.X_min_soft=-110;
p.X_max_soft=110;
p.X_min_hard=-120;
p.X_max_hard=120;

% AN9238 calibration is supplied by explicit frame/configuration ports.
p.ADC_Manual_Offset_Valid_A=false;
p.ADC_Manual_Offset_Valid_B=false;
p.ADC_Calibration_Log2_N=uint8(10);

foc=struct('Rs',p.PMLSM_Rs_ohm,'Ld',p.PMLSM_Ld_H, ...
    'Lq',p.PMLSM_Lq_H,'psi',p.PMLSM_psi_f_Wb, ...
    'Kp_ACR',p.Kp_ACR,'Ki_ACR',p.Ki_ACR, ...
    'Kaw_d',p.Kaw_d,'Kaw_q',p.Kaw_q,'Ts_ACR',p.Ts_ACR,'Udc',p.Udc);
p.FOC_Fixed_Parameters=foc;
p.FOC_Fixed_Config=axu5ev_experiment_foc_fixed_config(foc);

provenance=struct( ...
    'motor','AQM30-B2 Parallel; Issue42', ...
    'phase_rl','R_LL/2 and L_LL/2; Ld=Lq model assumption', ...
    'flux','DERIVED from Kf_peak and F=1.5*(2*pi/tau)*psi*iq', ...
    'bus','FIXED_CONTROL_REFERENCE; physical voltage acquisition absent', ...
    'current_limits','Source debug limits: Id 0.5 A including alignment; Iq 0.3 A; Issue42 and legacy MBDL4 parameters', ...
    'outer_loops','AQM F28335 backup candidate; mass-dependent retuning pending', ...
    'moving_mass','UNKNOWN; coil mass is not used as total moving mass', ...
    'calibration','PHYSICAL_CALIBRATION_PENDING', ...
    'hardware','HW_BINDING_PENDING; BOARD_NOT_RUN');
end

function is_integer=positive_integer_ratio(value)
is_integer=isfinite(value) && value>=1 && abs(value-round(value))<=eps(value);
end
