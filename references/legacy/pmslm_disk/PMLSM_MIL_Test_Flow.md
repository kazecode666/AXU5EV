# PMLSM MIL Test Flow

## Main Idea

`PMLSM_MIL_ControlCore_Sim.slx` is the MIL simulation model. It is not a test
script.

Daily debugging should start from the Simulink model:

1. Edit `init_PMLSM_mil_test_params.m` for simple numeric conditions.
2. Edit `Simple_Command_Profile` only when the command timing or sequence needs
   to change.
3. Click **Run** in Simulink.
4. Observe variables with Signal Logging / Data Inspector. Scope and
   To Workspace blocks can be added later when needed.
5. Run the automated scripts only after the manual behavior is stable.

The model InitFcn loads:

```matlab
init_PMLSM_control_params;
init_PMLSM_plant_params;
init_PMLSM_mil_test_params;
```

So manual Run uses the current base-workspace parameters. The scripts are not
the only simulation entry point.

`Startup_And_Commands` is the simulation test bench. It now contains two visible
command-layer blocks:

- `Startup_Enable_Sequencer`
- `Simple_Command_Profile`

The external `Startup_Bus` field names are unchanged.

## Startup_Enable_Sequencer

This block only handles startup and basic fault command generation:

- `enable_cmd`
- `fault_i`
- `fault_u`
- `close_loop_en`
- `init_start`
- `init_reset`
- `pi_reset_en`
- `pwm_enable`

It does not force `Init_Done`. It does not bypass `Angle_Init`.

`Close_Loop_EN` is the upper-loop enable for the speed loop and position loop.
It is not the current-loop enable. The current loop is closed by default in the
current FOC path.

`enable_cmd = 0` only disables PWM and resets startup. It is not treated as a
fault latch event.

`fault_i` and `fault_u` are hardware fault injection inputs. They disable PWM
and are still passed to the control core fault latch path.

## Simple_Command_Profile

This block only handles the three MIL tests needed at the current stage:

```matlab
MIL_Mode = 1;  % iq injection test
MIL_Mode = 2;  % speed closed-loop test
MIL_Mode = 3;  % position-loop / three-loop test
MIL_Mode = 4;  % static closed-loop iq step for DPICC delay validation
```

`MIL_Mode = 1` waits for `Init_Done = 1`, then runs a long positive/zero/
negative current-step profile:

```text
wait MIL_IqInjectionDelay_s
+MIL_IqInjection_A for MIL_IqPositiveDuration_s
0 A for MIL_IqZeroDuration_s
-MIL_IqInjection_A for MIL_IqNegativeDuration_s
0 A for MIL_IqZeroDuration_s
repeat for MIL_IqCycleCount cycles
0 A to the end
```

In `MIL_Mode = 1`, `Close_Loop_EN` remains 0. This mode is:

```text
Angle_Init -> current-loop closed iq injection
```

It is not a full open-loop voltage test. Voltage open-loop injection should be
implemented by signals such as `Ud_Test_EN` or `Uq_Test_EN`, which bypass the
current PI output before SVPWM. That is outside the current `MIL_Mode = 1`
scope.

`MIL_Mode = 4` reuses the same iq injection profile but waits for both
`Init_Done` and `Close_Loop_EN`. It exists for DPICC timing tests whose state
reset and activation rules require `Close_Loop_EN = 1`; normal mode 1 behavior
is unchanged.

The iq-injection check should not use `x_mm` staying exactly still as a
pass/fail condition. At the current stage it checks that no travel fault is
latched, the measured current follows the positive and negative steps, and the
voltage/duty outputs are not abnormal. If travel protection is still triggered,
reduce `MIL_IqInjection_A` first, for example to `0.02 A`, rather than returning
to a short pulse that ends before the current loop settles.

`MIL_Mode = 2` waits for startup, then runs:

```text
+MIL_SpeedCommand_mmps -> 0 -> -MIL_SpeedCommand_mmps -> 0
```

`MIL_Mode = 3` waits for startup, enables `pos_loop_en`, then releases
`x_ref_mm = MIL_PositionStep_mm`.

For every mode, `MIL_LoadForce_N` remains gated by
`Init_Done && Close_Loop_EN`. The optional window
`MIL_LoadStartRel_s <= test_timer_s < MIL_LoadEndRel_s` controls when the
load is active. Its defaults are `0` and `inf`, preserving the historical
constant-load behavior after closed-loop startup.


The previous `MIL_Command_Profile = 1..7` layer has been removed from the main
path. Load-step, Vdc-drop, and custom workspace profiles can be added later
when they become necessary.

## Scripts

Main scripts to keep using:

- `run_PMLSM_MIL_full_startup_check.m`
- `run_PMLSM_MIL_iq_injection_test.m`
- `run_PMLSM_MIL_fault_injection_tests.m`
- `check_controlcore_equivalence.m`

These scripts are for final validation, automatic pass/fail checks, saved
`logsout` MAT files, PNG figures, and report data. They are not the daily
debugging entry point.

Use `run_PMLSM_MIL_case.m` when a script needs to run the MIL model and save
logs/plots consistently.

Do not change these while working on the MIL test layer:

- PI parameters
- plant parameters
- `PMLSM_ControlCore_Block.slx`
- `PMSLM_Close_Loop_MBDL4.slx`
- `PMLSM_Plant_Model`
- `Inverter_Model`
- `Sensor_Model`
