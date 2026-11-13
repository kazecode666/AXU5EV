# v1 one-shot corner runner

Implementation only: no xvlog, xelab or xsim has been run by this editing task. Final validation uses Python AST, in-memory compile and synthetic in-memory monitor assertions only; no pycache or test output files.

## Authorized invocation

From this directory, syntax preflight is `python run_corner.py --syntax-only`. It claims a previously nonexistent `syntax` directory and runs only xvlog there, for at most 600 seconds. The zero-exit clean result is SYNTAX_PASS, never corner PASS. Syntax artifacts remain isolated; formal `python run_corner.py slow` still recompiles xvlog using the identical TB/netlist paths and version, then elaborates and simulates once. This deliberately does not copy or reuse a potentially stale syntax library. Follow with `python run_corner.py fast` only after authorized slow completes PASS. An explicit `--tb` absolute path may be supplied consistently in all invocations.

## Fixed budgets and progress

xvlog 600 s; xelab 600 s; xsim 3600 s, measured by monotonic wall time per stage. No dynamic extension, retry, resume or alternative optimization exists. In particular, a dynamic run with no simulated-time advancement still receives only the fixed 3600-second budget. O2 is the sole elaboration attempt. Transport interconnect delays, all four zero pulse arguments, max/min SDF root, libraries and enabled timing checks are retained from the buildfix runner.

The supervisor scans separate stdout/stderr and recursive native logs every 250 ms, saves per-stage wall elapsed time and emits a heartbeat every 2 s. Wall heartbeat is liveness only, never simulation progress. Real scenario/progress lines must be PWM_CUT log records; simulation time must be explicitly reported in xsim log text (t_ns or t/time with units). Compile/elaboration stages retain null simulation/scenario fields rather than inventing progress. Generic tool messages do not replace the last actual progress line. Summary records preserve each stage, including commands, PID, log paths, elapsed wall time, actual scenario/time and diagnostics.

## Strict acceptance and termination

Real timing violations, SDF matching/annotation errors and unknown warnings retain separate fail-closed classifications. Only the exact previously reviewed ordinary xelab warning text plus exact TB path (movable line numbers) is accepted: unconnected s_axi_rresp, and finish_offer input-id sensitivity at its two occurrences. No warning-code-wide exemption exists. No TB, production netlist or SDF is modified. No content fingerprinting is used.

Each corner claims its own previously nonexistent directory; existing evidence cannot be overwritten. PASS requires all three stages naturally exiting zero, no supervisor stop or diagnostic, successful XSIM 43-3452 annotation, and exactly one complete newline-terminated canonical xsim stdout PWM_CUT_SDF_PASS line. Native duplicated PASS text is not double-counted; repeated canonical PASS lines fail uniqueness. A marker cannot override errors, timeout, interruption or a nonzero exit.

Termination targets only the current PID tree via taskkill /PID /T /F, never process names. A process may exit between poll and taskkill: taskkill exit 128 is recorded as stop_requested_taskkill_128_possible_exit_race, with actual process exit code retained. The stop request is not erased and natural_exit is not retroactively set, so even an eventual exit 0 cannot promote that race to PASS. A genuinely observed unrequested natural exit is classified natural_exit; diagnostics found by final drain still fail it.

Fast requires same-directory slow summary PASS, the three ordered natural zero exits with no stop/diagnostics, annotation and unique marker, and exact recorded absolute slow-run/netlist/TB/glbl/slow-SDF paths. Syntax success cannot satisfy it.
