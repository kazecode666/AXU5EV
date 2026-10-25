%% AUM3-S4 parallel PMLSM MIL plant and sensor parameters
% These variables are used only by PMLSM_Plant_Model, Inverter_Model, and
% Sensor_Model. They intentionally use a PMLSM_ prefix so they cannot
% shadow parameters in the original code-generation model.

%% Simulation timing
PMLSM_Ts_s = 1e-4;           % s, keep same as control period for first version

%% Electrical period / pole pitch
PMLSM_tau_NN_m  = 0.06;      % m, N-N electrical period, 60 mm
PMLSM_tau_NN_mm = 60;        % mm

PMLSM_tau_p_m   = 0.03;      % m, pole pitch used in paper-style formula
PMLSM_tau_p_mm  = 30;        % mm

% Compatibility name used by existing control/sensor angle logic.
% IMPORTANT: this is the full 2*pi electrical period for theta_e = 2*pi*x_mm/tau_e_mm.
PMLSM_tau_e_mm = PMLSM_tau_NN_mm;
PMLSM_theta_offset_rad = 0;

%% AUM3-S4 parallel dq electrical parameters
PMLSM_R_LL_ohm = 4.74;       % ohm, line-line resistance
PMLSM_Rs_ohm   = PMLSM_R_LL_ohm/2;       % 2.37 ohm

PMLSM_L_LL_H = 3.49e-3;      % H, line-line inductance
PMLSM_Ld_H   = PMLSM_L_LL_H/2;           % 1.745e-3 H
PMLSM_Lq_H   = PMLSM_L_LL_H/2;           % 1.745e-3 H

PMLSM_Kf_rms_N_per_Arms   = 31.4;        % N/Arms
PMLSM_Kf_peak_N_per_Apeak = PMLSM_Kf_rms_N_per_Arms/sqrt(2);

PMLSM_psi_f_Wb = 0.141;      % Wb, use previously calculated value

%% AUM3-S4 first-version mechanical parameters
PMLSM_M_kg = 0.91;           % kg, coil/mover mass first version
PMLSM_Bv_N_per_mps = 0;      % N/(m/s), first version
PMLSM_Fc_N = 0;              % N, first version
PMLSM_v_eps_mps = 1e-3;      % m/s, tanh friction smoothing

% Compatibility aliases for older MIL plant block parameter names.
PMLSM_Kf_N_per_A = PMLSM_Kf_peak_N_per_Apeak;
PMLSM_mass_kg = PMLSM_M_kg;
PMLSM_viscous_N_per_mps = PMLSM_Bv_N_per_mps;
PMLSM_coulomb_N = PMLSM_Fc_N;

%% Average inverter and sensor parameters retained for current MIL interfaces
PMLSM_vdc_V = 48;
PMLSM_pwm_period_counts = 7500;
PMLSM_deadtime_s = 1e-6;
PMLSM_pwm_freq_Hz = 1e4;
PMLSM_deadtime_ratio = PMLSM_deadtime_s * PMLSM_pwm_freq_Hz;
PMLSM_deadtime_current_eps_A = 1e-4;

PMLSM_sensor_delay_samples = 50;
PMLSM_grating_resolution_mm = 0.0001; % 0.1 um/count; verify against eQEP decode mode
PMLSM_current_feedback_mode = 3; % 3 = independent ia/ib/ic MIL sampling

PMLSM_x_min_soft_mm = -470;
PMLSM_x_max_soft_mm = 470;
PMLSM_x_min_hard_mm = -500;
PMLSM_x_max_hard_mm = 500;
