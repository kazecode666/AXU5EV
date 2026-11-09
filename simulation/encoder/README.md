# Encoder numerical entries

`encoder_test_scale.json` is the explicit synthetic scale: 1000nm per effective
decoded count, 30000 counts per electrical period, no additional x4. It does
not modify the legacy motor parameters or claim physical scale verification.
`scripts/encoder_generate_scale.py` exports the PL package and C constants.
The angle generator checks that its specialized period matches this source.

PL source is `encoder_angle_step.m`. The canonical reusable subsystem is
`AXU5EV_Encoder_Components.slx/Encoder_Angle`; the new
`AXU5EV_Encoder_Angle_HDL.slx` shell is a resolved library link to it. The
existing user-modified PL library and ADC models are never saved by this flow.
`encoder_generate_hdl(new_output_dir)` is the only HDL generation entry and
produces `generated/encoder/AXU5EV_Encoder_Angle_HDL/Encoder_Angle.sv` and
`Electric_Angle_Core.sv`. The MATLAB Function calls the single .m source;
neither the shell nor future consumers should copy its formula.

The existing FOC contract was read from `simulation/pmlsm_foc_fixed_config.m`
(`Angle`, signed40, fraction32) and the generated legacy `FOC_DUT.theta_e`
port. It is radians, not turns. This component returns integer Q32 bits in an
int64 container, with nonnegative values below 2pi; the low40 bits therefore
match that input format. It is not connected to FOC in this issue.
Legacy Runtime's generated alignment offset uses the negative mechanical
position contribution; here the manual `zero_count` is subtracted and the
manual phase offset is added. No alignment state machine is run or changed.

For the first ready frame or a manual zero change, the coordinate is the
nearest signed-modulo32 distance from raw `zero_count`. Subsequent frames use
nearest signed-modulo32 increments from the previous raw count and maintain
phase modulo30000, so crossing raw UINT32 or signed INT32 boundaries does not
change electrical phase spuriously. Direction1 negates that displacement;
phase_offset_count is added after direction and must be 0..29999. A manual
zero change creates a new coordinate epoch. Phase-offset or version-only
changes preserve the accumulated unoffset phase; direction changes negate
that retained phase before applying the new signed increment. This matters
after displacement has accumulated through a full modulo32 raw-count wrap:
re-anchoring to raw-zero for a version/offset change would introduce a
spurious 2^32 mod30000 =17296 count phase shift.
Not-ready clears the primed state. Every initial/increment displacement must
be strictly less than 2^31 counts in magnitude; the exact half-wrap is invalid
and requires re-priming. Z only appears in frame metadata and never resets
this algorithm.

For final phase p, the quantization is
`floor((p*943231700270 + 2^19)/2^20)` Q32 bits, where the coefficient is
`round(2*pi*2^52/30000)`. This differs from ideal round-to-nearest Q32 radians by
at most one LSB. The 32-step serial remainder avoids a wide modulo divider in
one 50MHz clock. An input event while busy is outside this component's
contract; integration supplies only one every5000 clocks.

`encoder_validate_angle(new_output_dir)` compares MATLAB with the linked model
and exports46 analytical vectors. Final model result is
`.runtime/encoder_feedback/angle_model_03`: 2208 clock steps, maximum ideal
error1 Q32 LSB. Its output sample-index offset is34, evaluated before the
discrete state update. Generated RTL was separately checked at post-edge
observation in `angle_rtl_04`:46 vectors/460 checks, result visible33 clocks
after the input-accept edge. A consuming parent register captures that result
on the following edge, at34 clocks; snapshot word29 reports this consumption
delay. These are explicit sampling conventions, not different algorithms.

The RTL comparison command is
`scripts/encoder_run_angle_rtl.ps1 -RunDir <new_directory> -Vectors <angle_model_dir>/angle_vectors.txt`.
Vectors cover quarter-periods, electrical boundary/negative motion, signed32
and modulo32 raw wraps, large accumulated displacement followed by version,
offset and direction changes, manual zero changes, not-ready and
the ambiguous half-wrap. Earlier path-escaping/latency-convention test failures
remain in angle_rtl_01/02. No generated HDL was hand-edited.

Software numerical source and C-generation/validation entries are
`encoder_position_speed.m`, `encoder_generate_c.m` and
`encoder_validate_software.m`. The same-frame zero/direction/scale/version is
passed by R5. Their original generated C is the only active software algorithm;
R5 hand code only reads frames, calls it and stores observations.
