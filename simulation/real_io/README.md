# ADC source and observation compatibility

The active observer is `simulation/AXU5EV_ADC_Observer.slx`; its linked
component is `AXU5EV_PL_Algorithm_Library/Current_Preprocess`.
The authoritative arithmetic remains `ax03b1_current_preprocess.m` here.
No formula is copied into either active shell. The old user-modified
`AXU5EV_RealIO_NoPower.slx` is preserved and is not a generation entry.

The compatibility `ax03b1_run_no_power` delegates to `simulation/adc/adc_run_observer`.
The sole HDL generator is `simulation/adc/adc_generate_hdl.m`, targeting
`AXU5EV_ADC_HDL/Current_Preprocess`, writing `generated/adc/AXU5EV_ADC_HDL/`.
See `hardware/axu5ev/motor_control/README.md` for the model, PL and old/new paths.

## Historical B1 observation semantics

The SLX separates the SIM-only peripheral stimulus, ADC pipeline reference,
current preprocessing, ideal already-synchronized ABZ logic reference,
sample snapshot and observation output. It contains no motor plant, FOC,
speed estimator, duty, ENCON or RELCON path. The ABZ function does not model
the physical synchronizer/filter latency; thin RTL verifies that separately.
Its first AB/Z observation establishes the initial phase and level with
count=0, illegal=0 and z_seen=false, including nonzero AB or initial Z high.
Only later transitions can create count, illegal or Z events.

For the PR29 startup regression, open the reviewed observer model and run
`ax03b1_validate_abz_startup(output_dir)` through MATLAB MCP, using a fresh
output directory under `.runtime/ax03b1/`. It covers all 8 AB/Z initial
combinations, both real directions and two independent resets (32 cases,
896 state checks), then the nominal model and two nonzero-AB/initial-high-Z
model runs. A scoped test-only path substitutes the SIM stimulus fixture;
the receive/numeric/snapshot model is neither edited nor saved. The path
and cache settings are restored on exit. Do not add the fixture directory
to the daily MATLAB path. This regression does not regenerate current HDL
or rerun unchanged RTL. Compact results: `verification/ax03b1/abz_startup_results.json`.

SIM_ASSUMPTION: 50 MHz logic, 5 MHz conversion clock, two independent
offset-binary buses and seven conversion-clock pipeline stages. Every 500th
conversion is observed (100 us). Conversion IDs are 0, 500, 1000, ... with
modulo-32-bit wrap. Sample-time position travels with ADC metadata, then
matches the numeric module's one-clock output register. These are logic
assumptions, not confirmed AN9238 hardware timing or physical mm/count.

The model uses explicitly marked synthetic offsets/gains. No initialization
of the user's motor model is performed. The 20-column `observer_frames.csv`
is ordered as: conversion ID, raw A, raw B, sampled count, ia/ib/ic Q24,
valid, clip, error, result marker, offset A/B Q16, calibration count A/B,
done A/B, calibration version, sampled Z-seen latch, sampled illegal-count.
The final two ABZ fields enter the same seven-conversion pipeline as sampled
position and then the same one-clock metadata delay as the current outputs.
The initial frame captures Z-seen=0, before the first Z pulse at logic tick
64; subsequent selected frames capture Z-seen=1. Returning ADC data never
substitutes the newest Z/illegal events for those belonging to its sample.

Production inputs are scalar types
declared on the DUT ports: raw uint16, offsets int32 Q16, signed gains int32
Q24 A/count and currents int32 Q24 A. Calibration N is 2^log2_N (0..10),
nominally 1024; tests explicitly use 4 to inspect independent pause/restart.
Each good channel accumulates independently. Completion preserves offsets;
restart clears completion/counts while preserving the last offset. Config
applies atomically and assigns its explicit version; restart and each new
channel offset commit increment the version modulo 2^32.

Products retain signed int64 Q40. Each current is rounded to Q24 with
nearest-even ties in a wide signed value. The c current is the negative sum
of the **unclipped** wide Q24 a/b values; only then are three int32 outputs
saturated. Clipping invalidates the numeric result. This preserves exact
Q24 zero sum when no clipping occurs and cannot diagnose sensor consistency.

The lower saturation predicate uses `bitshift(x,-31)<int64(-1)`, exactly
equivalent to `x<-2^31`. Actual RTL simulation exposed HDL Coder emitting a
32-bit unary-min literal inside a 64-bit comparison for the direct limit
constant, even when the limit was constructed with int64 bitshift. The
shift predicate generates a safe signed 64-bit comparison. Regeneration
checks for recurrence of the unsafe generated comparison; generated SV is
never patched. The original failed RTL log is retained locally.

All selected samples produce `result_strobe`, including bad/uncalibrated
samples and configuration/restart collisions. Invalid samples carry zero
current; clipped samples carry saturated current with valid=0. The same
one-clock register aligns every output. Hold `clk_enable=1` in the observer.
`error` bits: 0/1 missing capture or raw>4095, 2/3 OTR, 4/5 not calibrated,
6 invalid configuration, 7 clipping, 8 config/restart coinciding with sample.
Config/restart wins over calibration counting; bit 8 explicitly preserves
the discarded sample as an invalid observation rather than losing a frame.

Local results are under `.runtime/ax03b1/matlab/`: independent numeric
reference checks, all input/expected-output vectors, unique observer frames
and compact JSON evidence. `current_vectors.csv` has the 18 inputs followed
by 14 immediate function outputs, in the function signature order. Apply
the DUT's one-enabled-clock output delay when using those vectors in RTL.
Simulation and generation do not prove STA/CDC, analog calibration or boards.
