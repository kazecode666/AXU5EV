%% PMLSM controller parameters
% The hardware-facing parameter file now targets F28388D + MBDL4 + AUM3-S4.
% MIL plant/test-only parameters remain in their separate initialization layers.

PMSLM_Init_Params_MBDL4;

PMLSM_Control_Param_Source = 'PMSLM_Init_Params_MBDL4.m';
PMLSM_Control_Param_Frozen = false;
