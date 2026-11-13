# One-shot corner runner

No simulation has been run as part of implementation. Static AST and in-memory Python compile validation passed; no pycache artifacts were written.

Run manually only when authorized: `python run_corner.py slow`, then `python run_corner.py fast`. Each claims a previously nonexistent corner directory. Existing results are never overwritten and there is no retry/resume or alternative optimization. Fast requires new-directory slow PASS with all three natural zero exits, annotation and unique dynamic marker, plus recorded absolute paths for the same new-directory run and inputs. No file hashing or content-digest verification is performed.

Limits per corner: xvlog 600 s, xelab 3600 s, xsim 900 s. O2 is the sole elaboration attempt. Transport interconnect delays, all four zero pulse arguments, SDF max/min root, libraries and timing checks are retained from the 1404 runner.

stdout/stderr redirect directly into separate files; the supervisor scans increments and native recursive logs at 250 ms intervals, prints a heartbeat every 2 s, and updates the summary with command, argv, per-stage monotonic wall time, PID, natural-exit versus supervised-stop state, native log paths, exact diagnostics, last TB scenario/time and complete PASS lines. Native stdout duplicates do not double-count PASS: only newline-terminated canonical xsim stdout is counted.

Timing violations and SDF matching/annotation errors stop the current PID tree using taskkill /PID /T /F. No process-name-wide termination is used. Unknown warnings stop conservatively and are not mislabeled SDF failures. Only exact message+TB-path variants of the three individually reviewed 1404 TB prompts are exempted during xelab: unconnected s_axi_rresp; finish_offer input id sensitivity at the two task lines (line numbers may move). New TB is expected to fix these, not depend on suppression.

Observed old slow evidence: xelab emitted those three prompts and XSIM 43-3452; first xsim reported FDPE hold timing violations at 760 ns and 820 ns. Those are real timing violations, never accepted warnings or PASS.

PASS requires xvlog/xelab/first xsim exit zero, successful XSIM 43-3452 annotation, exactly one complete PWM_CUT_SDF_PASS stdout line, and no actual or unknown diagnostic. A marker alone never overrides violations, timeout or nonzero exit. A runner/monitor interruption also terminates only its current stage tree and records failure.
