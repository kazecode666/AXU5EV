# PMLSM Hardware Interface Map

## Current Direction

The active hardware target is now:

- `TMS320F28388D` CPU1
- `YXPHM-MBDL4` motor driver
- `AUM3-S4` linear motor
- `48 V` nominal DC bus
- `10 kHz` current-control and PWM rate

The first hardware-control version keeps the existing three-loop structure:

- position loop: P
- speed loop: PI
- current loop: PI

DPCC/DPICC, PICDO, and software dead-time voltage compensation are not part of
this code-generation migration stage. Complementary PWM dead time is still
implemented by the F28388D ePWM hardware.

The F28335 version is retained only as a backup. The active model and parameter
script are `PMSLM_Close_Loop_MBDL4.slx` and `PMSLM_Init_Params_MBDL4.m`.

## F28388D Implementation Status

The active model is configured for `TI F2838x`, CPU1, fixed-step `Ts`, and the
F28388D peripheral blocks. Model update succeeds. Embedded Coder completes TLC
and C-code generation, but the final compile/link stage is currently blocked
because the CCS C2000 EABI toolchain has not yet been configured in MATLAB.

Generated code has been checked for the following items:

- ePWM1/ePWM2/ePWM3 on GPIO0 through GPIO5
- ePWM1 SOCA triggering the three current ADC channels
- ADCA1 interrupt driving the control task
- GPIO30, GPIO62, GPIO63, and GPIO66 digital outputs
- GPIO67 and GPIO68 active-low fault inputs
- GPIO68 routed through INPUT X-BAR 1 to TZ1
- GPIO67 routed through INPUT X-BAR 2 to TZ2
- OSHT1 and OSHT2 enabled on all three ePWM modules, with trip outputs forced low

The generated-code output is kept separate from legacy MATLAB-version artifacts
under `generated/f28388d_r2026a`.

PWM polarity is not a current blocking item. The existing code-generation model
and real F28335 hardware have already driven the motor successfully in previous
hardware runs.

## PWM Interface

- `duty_a`
- `duty_b`
- `duty_c`

These duty signals remain consistent with the code-generation model. The MIL
`Inverter_Model` duty conversion is not changed at this stage.

F28388D ePWM configuration:

- PWM mode: up/down count
- time-base clock: `100 MHz`
- PWM frequency: `10 kHz`
- period count: `PWM_Period = 5000`
- complementary A/B outputs
- active-high complementary dead-band mode
- rising/falling dead time: `PWM_DeadTime_Count = 100`, equivalent to `1 us`
- one-shot trip inputs: TZ1 and TZ2
- trip action: force ePWM A and B low

Do not modify `Inverter_Model` polarity only from theoretical ePWM action
analysis. Revisit this only if future oscilloscope or hardware response tests
show an inconsistency between MIL voltage polarity and the real inverter output.

## Current Feedback Interface

The current hardware regression path uses three independent ADC current
feedback channels:

- `ia`
- `ib`
- `ic`

The MIL `Sensor_Model` should default to the same three-phase sampling path:

```text
ia -> ia_meas -> ia_feedback
ib -> ib_meas -> ib_feedback
ic -> ic_meas -> ic_feedback
```

The historical `ic = -ia - ib` reconstruction path is only a compatibility or
debug option, not the current hardware regression path.

F28388D ADC assignments and baseboard J9 signals:

| Feedback | F28388D ADC | Baseboard J9 | MBDL4 analog connector |
|---|---|---|---|
| `ia` | ADCA0 | pin 26, `ADC_A0A1_P` | pin 1, IA |
| `ib` | ADCB0 | pin 20, `ADC_B0B1_P` | pin 2, IB |
| `ic` | ADCC2 | pin 12, `ADC_C2C3_P` | pin 3, IC |
| `vdc` (planned) | ADCD0 | pin 8, `ADC_D0D1_P` | pin 5, VDC |

The current model samples the three phase currents. Online DC-bus sampling has
not yet been connected; the control parameter is presently `Udc = 48 V`.
ADC offsets and gains in the parameter script are commissioning starting values
only and must be recalibrated on the assembled F28388D + MBDL4 hardware before
closed-loop current control.

## Grating Encoder

The grating resolution is:

```text
0.1 um/count = 0.0001 mm/count
```

The eQEP position count is converted to millimetres using
`Grating_Resolution_mm_per_count`. Position direction, electrical zero, and the
relationship between the eQEP count direction and motor phase order must be
verified on the bench before enabling closed-loop motion.

## Speed Feedback

The confirmed speed measurement delay is:

```text
delay_N = 50
```

With fixed-step discrete `Ts = 1e-4 s`:

```text
v_meas_mmps = (x(k)-x(k-50))/(50*Ts)
```

## Driver Enable And Fault Interface

| Function | F28388D GPIO | Baseboard connector | Active level / behavior |
|---|---:|---|---|
| PWM level-shifter OE | GPIO30 | on-board U10 control | low enables, high disables |
| `RELCON` | GPIO62 | J5 pin 1 | manual command, forced inactive by system fault |
| `ENCON` | GPIO63 | J5 pin 2 | manual command, forced inactive by system fault |
| `F_Reset` | GPIO66 | J5 pin 6 | manual fault-reset command |
| `ERRI` | GPIO67 | J5 pin 7 | active-low driver fault input |
| `ERRU` | GPIO68 | J5 pin 8 | active-low driver fault input |

`ERRI` and `ERRU` must pass through suitable 5 V to 3.3 V level conversion
before reaching the F28388D GPIO pins. Either active-low input sets the software
fault latch and also triggers the independent ePWM one-shot hardware trip path.
The system-fault signal forces GPIO30 to the disabled level and prevents RELCON
and ENCON from being asserted.

GPIO30 does not have the same dedicated external pull-up arrangement as the old
F28335BPLUS design. Therefore, software initialization alone must not be treated
as a guaranteed safe state during reset or before GPIO configuration completes.
Keep RELCON and ENCON inactive and keep the DC bus isolated during the first
GPIO30/OE validation.

Recommended first GPIO30 bench check:

1. Use logic power only; disconnect the motor power path and keep the 48 V bus
   isolated.
2. Observe GPIO30, U10 OE, a CPU-side PWM pin, and the corresponding
   driver-side PWM signal with an oscilloscope or logic analyzer.
3. Command GPIO30 high and confirm that the level-shifter outputs are disabled.
4. Keep the ePWM modules in trip/forced-low state, command GPIO30 low, and
   confirm that the level shifter is enabled without an unintended output pulse.
5. Toggle a known low-duty PWM only after the static OE behavior is confirmed.
6. Verify that pulling either ERRI or ERRU low immediately forces all six PWM
   outputs to their trip state and that the fault remains latched.

## Initial Commissioning Limits

- conservative current PI: `Kp_ACR = 2.18125`, `Ki_ACR = 2962.5`
- initial q-axis current limit: `0.30 A`
- initial current-integrator limit: `0.10`
- nominal DC bus parameter: `48 V`

These are first-test values, not final tuned parameters. Start with disabled
power output, validate offsets/polarities/faults, and then increase authority in
small steps.

## Required Hardware Log Signals

The following signals should be recorded during hardware bring-up and MIL/HIL
comparison:

- `ia`
- `ib`
- `ic`
- `id_meas`
- `iq_meas`
- `id_ref`
- `iq_ref`

Additional useful logs include:

- `theta_e`
- `v_ref_cmd_mmps`
- `v_ref_safe`
- `iq_ref_normal`
- `fault_latch`
- `pwm_enable`
- `duty_a`
- `duty_b`
- `duty_c`
