"""Analyze a frozen AX-04B timing NDJSON capture. Uses local files only."""

import argparse
import json
from pathlib import Path


RATES = ("base", "speed_1ms", "position_10ms")
METRICS = ("entry_upper", "read", "model", "submit", "ack", "irq",
           "accept_lower", "accept_upper")
FRAME_CYCLES = 5000
ANOMALIES = ("transitions", "invalid", "unbracketed", "missing", "discontinuities",
             "overruns", "rejects", "late_or_target", "spurious", "bad_snapshots",
             "receipt_errors", "receipt_unresolved")


def pmu_delta(frame, end, start):
    return (frame[end] - frame[start]) & 0xFFFFFFFF


def frame_metrics(frame, capture):
    """Return only observed stages. PMU zero is a valid timestamp after wrap."""
    values = {"irq": pmu_delta(frame, "irq_end", "entry")}
    for metric, valid, end, start in (
        ("read", "read_done_valid", "read_done", "entry"),
        ("model", "model_ran", "model_done", "read_done"),
        ("submit", "attempted", "accept_done", "model_done"),
        ("ack", "ack_done_valid", "ack_done", "ack_begin"),
        ("safety_reentry", "safety_reentry", "safety_done", "safety_begin"),
    ):
        if frame[valid]:
            values[metric] = pmu_delta(frame, end, start)
    irq = capture["irq_phase"]
    deadline = capture["deadline_phase"]
    sample_id = frame["frame"]["sample_id"]
    entry = frame["frame"]["entry_phase"]
    before, after = frame["before_phase"], frame["after_phase"]
    if (frame["accepted"] and frame["before_id"] == sample_id == frame["after_id"]
            and irq - 1 <= entry <= before <= after < FRAME_CYCLES - 1 and before < deadline):
        values.update(entry_upper=entry + 1 - irq, accept_lower=before + 1 - irq,
                      accept_upper=min(after + 1, deadline) - irq)
    return values


def analyze(capture, rate_rows, evidence, detail, group):
    if capture["timing_schema"] != 2 or capture["active"]:
        raise ValueError("expected a frozen timing schema 2 capture")
    if len(detail) != capture["count"]:
        raise ValueError("detail record count does not match the export")
    pmu_us = 1e6 * capture["pmu_divisor"] / capture["cpu_hz"]
    pl_us = 1e6 / capture["pl_hz"]
    scale = dict.fromkeys(("entry_upper", "accept_lower", "accept_upper"), pl_us)
    if [row["rate"] for row in rate_rows] != list(range(len(RATES))):
        raise ValueError("expected rate rows in base, speed, position order")
    samples = [{name: [] for name in METRICS} for _ in RATES]
    for frame in detail:
        if frame["valid"]:
            for name, value in frame_metrics(frame, capture).items():
                samples[frame["frame"]["rate"]][name].append(value)

    rates = {}
    rate_counts = []
    brackets_match = True
    stages_match = True
    upper_peaks = []
    budget = capture["deadline_phase"] - capture["irq_phase"]
    for rate, row, per_rate in zip(RATES, rate_rows, samples):
        if row["capture_id"] != capture["capture_id"] or len(row["metrics"]) != len(METRICS):
            raise ValueError("rate row does not match the capture")
        report = rates[rate] = {}
        counts = {}
        for name, metric in zip(METRICS, row["metrics"]):
            count = counts[name] = metric["count"]
            factor = scale.get(name, pmu_us)
            raw = sorted(per_rate[name])
            rank = (99 * len(raw) + 99) // 100
            report[name] = {"count": count, "min_us": metric["min"] * factor if count else None,
                            "mean_us": metric["sum"] / count * factor if count else None,
                            "max_us": metric["max"] * factor if count else None,
                            "peak": metric["peak"] if count else None,
                            "detail_p99_us": raw[rank - 1] * factor if rank else None,
                            "detail_samples": len(raw)}
            if name == "accept_upper" and count:
                upper = metric["max"]
                upper_peaks.append(upper)
                brackets_match &= 0 <= upper <= budget
        rate_counts.append(counts["irq"])
        stages_match &= all(counts[name] == counts["irq"] for name in ("read", "model", "submit", "ack"))
        brackets_match &= all(counts[name] == counts["irq"] for name in scale)
    timing_end = capture["end_reason"] == "elapsed"
    checks = {
        "elapsed": timing_end,
        "planned_frames_present": capture["frames"] == capture["planned_frames"] > 0,
        "all_frames_valid": capture["valid"] == capture["frames"],
        "all_valid_frames_applied": capture["applied"] == capture["valid"],
        "rate_counts_match": stages_match and sum(rate_counts) == capture["valid"],
        "phase_counts_match": brackets_match,
        "zero_anomalies": all(capture[key] == 0 for key in ANOMALIES),
    }
    # A deadline bound can describe a fully covered window even if a separate
    # next-P0 or PWM check fails. Any phase or frame-coverage gap removes it.
    covered = all(checks[key] for key in ("elapsed", "planned_frames_present", "all_frames_valid",
                                         "rate_counts_match", "phase_counts_match"))
    covered &= not any(capture[key] for key in ("unbracketed", "missing", "discontinuities"))
    bounds = None
    if covered and upper_peaks:
        upper = max(upper_peaks)
        bounds = {"max_upper_cycles": upper, "max_upper_us": upper * pl_us,
                  "minimum_margin_cycles": budget - upper, "minimum_margin_us": (budget - upper) * pl_us}
    if group == "D":
        status = "NOT_APPLICABLE"
    elif not timing_end:
        status = "INCOMPLETE"
    else:
        status = "PASS" if all(checks.values()) else "FAIL"
    exceptional = {}
    for key, frame in evidence.items():
        exceptional[key] = None if frame is None else {
            "raw": frame,
            "durations_us": {name: value * scale.get(name, pmu_us)
                             for name, value in frame_metrics(frame, capture).items()},
        }
    return {
        "group": group, "stable_timing": status, "checks": checks, "capture": capture,
        "max_foreground_mask_us": capture["max_foreground_mask"] * pmu_us,
        "full_window_bounds": bounds, "rates": rates,
        "detail_scope": {"records": len(detail), "first": detail[0]["frame"] if detail else None,
                         "last": detail[-1]["frame"] if detail else None},
        "exceptional_irqs": exceptional,
    }


def load_capture(path, group):
    with path.open(encoding="utf-8") as stream:
        header = json.loads(stream.readline())
        detail = [json.loads(line) for line in stream]
    if header["capture"].get("timing_schema") != 2 or header["version"].get("timing_schema") != 2:
        raise ValueError("expected a timing schema 2 export")
    return analyze(header["capture"], header["rates"], header["evidence"], detail, group)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ndjson", type=Path)
    parser.add_argument("--group", choices=("A", "B", "C", "D"), required=True)
    args = parser.parse_args()
    try:
        result = load_capture(args.ndjson, args.group)
    except (OSError, ValueError, KeyError, TypeError, IndexError, ZeroDivisionError) as error:
        parser.exit(1, f"{error}\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
