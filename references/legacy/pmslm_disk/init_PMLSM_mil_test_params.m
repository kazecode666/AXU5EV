%% PMLSM MIL 仿真专用启动与测试参数
% 这些变量只给当前 MIL 主模型使用，不应被 PMSLM_Close_Loop_MBDL4.slx 引用。

if ~exist('Ts_ACR', 'var')
    run(fullfile(fileparts(mfilename('fullpath')), 'PMSLM_Init_Params_MBDL4.m'));
end
if ~exist('PMLSM_Rs_ohm', 'var') || ~exist('PMLSM_Lq_H', 'var')
    run(fullfile(fileparts(mfilename('fullpath')), 'init_PMLSM_plant_params.m'));
end

MIL_Ts_s = 1e-4;

% 当前手动 Run 默认目标：
%   电流环 iq 注入/阶跃测试，走 duty -> Inverter_Model -> plant 路径。
%   Inverter_DeadTime_Mode=0/1 用于对比理想逆变器和 AHC 平均死区逆变器。
MIL_Mode = 1;          % 1: iq 注入/阶跃测试, 2: 速度环测试, 3: 位置环测试
Plant_Input_Mode = 2;  % 1: vd/vq 直接驱动 plant, 2: duty 经逆变器后驱动 plant
Inverter_DeadTime_Mode = 0;  % 0: 理想平均逆变器, 1: AHC 平均死区逆变器
Current_Control_Mode = 2;  % 1: PI, 2: DPCC, 3: DPICC, 4: half-delay DPICC, 5: half-delay PICDO-DPICC
DeadTime_Comp_Enable = 0;    % 0: 不补偿死区, 1: SVPWM 前启用死区补偿
MIL_StopTime_s = 7;
MIL_PWM_Update_Delay_Mode = 1;  % 0: no delay, 1: half-sample delay, 2: one-sample delay
% Optional event-accurate PWM update path. Keep disabled for compatibility
% with existing 100 us MIL scripts. Accurate timing runs override both
% values through Simulink.SimulationInput and use a 50 us solver/plant step.
MIL_PWM_Update_Delay_Accurate_Enable = 0;
MIL_PWM_Delay_Substep_s = MIL_Ts_s;
MIL_Current_Control_Ts_s = 1e-4;
Speed_Feedback_Mode = 1;  % 0: plant ideal v_mmps, 1: measured/estimated speed

Ts_DPICC = 1e-4;

% DPCC controller prediction model parameter factors. These affect only the
% DPCC voltage calculation, not the PMLSM plant parameters.
DPCC_Rs_Factor = 1;
DPCC_Ld_Factor = 1;
DPCC_Lq_Factor = 1;
DPCC_Psi_Factor = 1;

% Half-sample compensated DPICC controller-model inductance factors.
% These affect controller model inductance in modes 4 and 5 only;
% plant Ld/Lq remain unchanged.
DPICC_Ld_Factor = 1;
DPICC_Lq_Factor = 1;

% Half-delay PICDO-DPICC observer parameters. Mode 5 reuses the existing
% PMLSM_Rs_ohm and DPICC_Ld_Factor/DPICC_Lq_Factor controller model values.
% The plant inductances remain unchanged.
PICDO_Kx = 1.0;
PICDO_Kd = 0.25;
PICDO_Dhat_Limit_A = 3.0;

% 启动时序：
%   enable_cmd 在 MIL_EnableTime_s 后置 1；
%   控制核心 Angle_Init 完成后 Init_Done 置 1；
%   MIL_Mode=1 下，iq 测试从 Init_Done 后再延迟 MIL_IqInjectionDelay_s 开始。
MIL_EnableTime_s = 0.1;
MIL_InitDoneDelay_s = 1;

% iq 注入/阶跃测试波形：
%   iq_ref: 0 -> +MIL_IqInjection_A -> 0 -> -MIL_IqInjection_A -> 0。
%   MIL_IqRefRampTime_s=0 时就是阶跃；大于 0 时就是斜坡注入。
% Static q-axis current-step test for DPCC/PI comparison.
% The 1 A value is the step amplitude, not a long continuous injection.
% When enabled, PMLSM_MIL_ControlCore_Sim/PMLSM_Plant_Model freezes
% theta_e_actual, omega_e, x_mm, and v_mmps at zero so the mover stays
% stationary while the dq electrical current dynamics still run.
MIL_StaticCurrentStepTest_Enable = 1;
MIL_IqInjection_A = 1;
MIL_IqInjectionDelay_s = 0.02;
MIL_IqRefRampTime_s = 0;
MIL_IqPositiveDuration_s = 0.5;
MIL_IqZeroDuration_s = 0.5;
MIL_IqNegativeDuration_s = 0.5;
MIL_IqCycleCount = 1;

MIL_SpeedCommand_mmps = 5;
MIL_PositiveSpeedDuration_s = 1.5;
MIL_ZeroSpeedDuration_s = 0.8;
MIL_NegativeSpeedDuration_s = 1.5;

MIL_PositionStep_mm = 1;
MIL_PositionStepDelay_s = 0.2;

MIL_LoadForce_N = 0;
MIL_LoadStartRel_s = 0;
MIL_LoadEndRel_s = inf;
MIL_Vdc_V = 48;
Udc = MIL_Vdc_V;  % ControlCore SVPWM and dq limiter still reference Udc.

MIL_Fault_Test_Case = 0;
MIL_Fault_Start_s = 2.0;

%% AUM3-S4 MIL 电流环基准 PI
% PMSLM_Init_Params_MBDL4 保持为原始代码生成模型参数。
% 当前 MIL 主模型手动 Run 默认使用 AUM3-S4、xi=1 的电流环基准参数。
MIL_AUM3S4_Current_PI_xi = 1;
MIL_AUM3S4_Current_PI_Tc_s = Ts_ACR;
Kp_ACR = PMLSM_Lq_H/(4*MIL_AUM3S4_Current_PI_xi^2*MIL_AUM3S4_Current_PI_Tc_s);
Ki_ACR = Kp_ACR*PMLSM_Rs_ohm/PMLSM_Lq_H;
