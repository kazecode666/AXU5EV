# AX-03B1 observation model

Run through MATLAB MCP:

```matlab
addpath('D:/Project/AXU5EV/simulation/real_io');
result = ax03b1_run_no_power(true);
```

`false` runs the new numeric checks and no-power simulation; `true` also
regenerates `generated/ax03b1/AXU5EV_RealIO_NoPower/Current_Preprocess.sv`
and `Numeric_Algorithm.sv` from the **Current_Preprocess** subsystem.
Generated RTL is never edited. The entry restores path/cache settings and
leaves models open. It saves only this newly authored model when recording
its HDL generation settings.

The SLX separates the SIM-only peripheral stimulus, ADC pipeline reference,
current preprocessing, ideal already-synchronized ABZ logic reference,
sample snapshot and observation output. It contains no motor plant, FOC,
speed estimator, duty, ENCON or RELCON path. The ABZ function does not model
the physical synchronizer/filter latency; thin RTL verifies that separately.

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
