#!/usr/bin/env python3
"""Stage the independent M3 checker with hash-verified generated RTL.

No control arithmetic is reproduced here. Hexadecimal inputs, duties, and
source/gm old-state values are packed without conversion through float.
Every output directory is new; existing evidence is never overwritten.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import shutil
import sys
from pathlib import Path


FIELDS: tuple[tuple[str, int], ...] = (
    ("sample_id", 32),
    ("ia", 32), ("ib", 32), ("ic", 32),
    ("theta_e", 40), ("omega_e", 40),
    ("iq_ref", 32), ("id_ref", 32), ("PI_Reset_EN", 1), ("Vdc_V", 32),
    ("duty_u_cmd", 32), ("duty_v_cmd", 32), ("duty_w_cmd", 32),
    ("x_d_old", 64), ("x_q_old", 64), ("aw_d_old", 64), ("aw_q_old", 64),
)
RECORD_BITS = sum(width for _, width in FIELDS)
MODES = ("normal", "bit_negative", "cycle_negative", "ce", "reset")
HEX = re.compile(r"[0-9a-fA-F]+\Z")
SAFE_CASE = re.compile(r"[A-Za-z0-9_.-]+\Z")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def bounded_path(root: Path, relative: str) -> Path:
    """Resolve one declared file, rejecting absolute paths and root escapes."""
    path = Path(relative)
    if path.is_absolute() or ".." in path.parts:
        raise ValueError(f"manifest file must be root-relative: {relative!r}")
    resolved = (root / path).resolve()
    try:
        resolved.relative_to(root)
    except ValueError as error:
        raise ValueError(f"manifest file escapes root: {relative!r}") from error
    if not resolved.is_file():
        raise ValueError(f"declared source file is missing: {resolved}")
    return resolved


def load_golden(path: Path, limit: int | None) -> tuple[list[int], list[list[str]], int]:
    records: list[int] = []
    canonical: list[list[str]] = []
    with path.open("r", encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        expected_names = [name for name, _ in FIELDS]
        if reader.fieldnames != expected_names:
            raise ValueError(f"golden CSV header must be exactly {','.join(expected_names)}; got {reader.fieldnames!r}")
        for row_index, row in enumerate(reader):
            if limit is not None and row_index >= limit:
                break
            if None in row or any(row[name] is None for name in expected_names):
                raise ValueError(f"malformed CSV row {row_index + 2}")
            packed = 0
            normalized: list[str] = []
            for name, width in FIELDS:
                token = row[name].strip()
                if name == "sample_id":
                    if not re.fullmatch(r"[0-9]+", token):
                        raise ValueError(f"sample_id is not an unsigned decimal integer at row {row_index + 2}")
                    value = int(token, 10)
                    if value != row_index:
                        raise ValueError(f"sample_id must be consecutive from zero: row {row_index}, value {value}")
                    normalized.append(str(value))
                else:
                    if not HEX.fullmatch(token):
                        raise ValueError(f"{name} is not a hexadecimal bit string at CSV row {row_index + 2}: {token!r}")
                    value = int(token, 16)
                    normalized.append(f"{value:0{(width + 3) // 4}X}")
                if value >= 1 << width:
                    raise ValueError(f"{name} exceeds declared {width}-bit width at CSV row {row_index + 2}")
                packed = (packed << width) | value
            records.append(packed)
            canonical.append(normalized)
    if not records:
        raise ValueError("golden CSV has zero selected frames")
    if limit is not None and len(records) != limit:
        raise ValueError(f"requested {limit} frames but CSV supplies only {len(records)}")
    if len(records) > 8192:
        raise ValueError("scoreboard supports at most 8192 frames per independent run")
    return records, canonical, len(records)


def file_entry(root: Path, path: Path) -> dict[str, str]:
    return {"path": path.relative_to(root).as_posix(), "sha256": sha256(path)}


def stage(args: argparse.Namespace) -> dict:
    manifest_path = args.manifest.resolve()
    source = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
    phase=274
    pi_next_frame=False
    if 'candidate_id' in source:
        from m3_candidate_contract import validate
        entry=source['candidate_contract'];file=Path(entry['path'])
        if not file.is_absolute():
            repo=Path(__file__).resolve().parents[1]
            file=(repo/file) if str(file).startswith('.runtime') else (manifest_path.parent/file)
        if sha256(file)!=entry['sha256']:raise ValueError('candidate contract hash mismatch')
        contract=json.loads(file.read_text(encoding='utf8'))
        validate(contract,{'candidate_id':source['candidate_id'],
                          'configuration_sha256':source['build_identity']['configuration_sha256'],
                          'output_phase_cycles':entry['output_phase_cycles']})
        phase=contract['output_phase_cycles']
        pi_next_frame=contract['state_events']['pi_commit']==1
    source_root_value = source.get("root_dir", ".")
    source_root = Path(source_root_value)
    if not source_root.is_absolute():
        source_root = manifest_path.parent / source_root
    source_root = source_root.resolve()
    design = source.get("design_files")
    if not isinstance(design, list) or not design:
        raise ValueError("source manifest requires nonempty ordered design_files")
    if source.get("dut_top", "FOC_DUT") != "FOC_DUT":
        raise ValueError("independent checker is specific to the generated FOC_DUT interface")
    if source.get("clock_port", "clk") != "clk" or float(source.get("clock_period_ns", 20)) != 20:
        raise ValueError("M3 contract requires the clk input at 20 ns")
    source_data = source.get("data_files", [])
    if not isinstance(source_data, list):
        raise ValueError("source manifest data_files must be an array")
    checked: list[tuple[str, dict, Path]] = []
    seen: set[str] = set()
    for category, entries in (("design_files", design), ("data_files", source_data)):
        for entry in entries:
            if not isinstance(entry, dict) or not isinstance(entry.get("path"), str):
                raise ValueError(f"{category} entries require path and sha256")
            relative = Path(entry["path"]).as_posix()
            key = relative.casefold()
            if key in seen:
                raise ValueError(f"duplicate file path in source manifest: {relative}")
            seen.add(key)
            source_file = bounded_path(source_root, entry["path"])
            expected_hash = str(entry.get("sha256", "")).lower()
            if not re.fullmatch(r"[0-9a-f]{64}", expected_hash):
                raise ValueError(f"missing or invalid SHA-256: {relative}")
            if sha256(source_file) != expected_hash:
                raise ValueError(f"source manifest hash mismatch: {relative}")
            checked.append((category, entry, source_file))

    records, canonical, frames = load_golden(args.golden.resolve(), args.frames)
    if args.mode in ("ce", "reset") and frames < 3:
        raise ValueError("CE/reset directed modes require at least three frames")
    if not SAFE_CASE.fullmatch(args.case):
        raise ValueError("case must contain only ASCII letters, digits, dot, underscore, or hyphen")
    negative_sample = 0
    if args.mode == "cycle_negative":
        changed_rows = [index for index in range(1, frames)
                        if canonical[index][10:13] != canonical[index - 1][10:13]]
        if args.negative_sample is not None:
            negative_sample = args.negative_sample
            if negative_sample not in changed_rows:
                raise ValueError("--negative-sample must identify a real adjacent duty change in the selected golden rows")
        elif changed_rows:
            negative_sample = changed_rows[0]
        else:
            raise ValueError("one-clock-early negative requires golden data with an actual adjacent duty change")

    output = args.out.resolve()
    stage_root = output.parent
    if stage_root.exists():
        raise ValueError(f"new staging directory required; already exists: {stage_root}")
    scoreboard_source = Path(__file__).resolve().parents[1] / "verification" / "m3_foc" / "m3_foc_scoreboard.sv"
    if not scoreboard_source.is_file():
        raise ValueError(f"scoreboard source is missing: {scoreboard_source}")
    # All input/manifest checks above precede any output creation.
    stage_root.mkdir(parents=True, exist_ok=False)
    staged: dict[str, list[dict]] = {"design_files": [], "data_files": []}
    for category, entry, source_file in checked:
        target = stage_root / "design" / entry["path"]
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists():
            raise ValueError(f"refusing to overwrite a staging file: {target}")
        shutil.copy2(source_file, target)
        new_entry = file_entry(stage_root, target)
        if new_entry["sha256"] != entry["sha256"].lower():
            raise ValueError(f"copied file hash mismatch: {target}")
        staged[category].append(new_entry)

    scoreboard = stage_root / "testbench" / scoreboard_source.name
    scoreboard.parent.mkdir()
    shutil.copy2(scoreboard_source, scoreboard)
    data_dir = stage_root / "vectors"
    data_dir.mkdir()
    memory = data_dir / f"{args.case}.mem"
    digits = (RECORD_BITS + 3) // 4
    with memory.open("x", encoding="ascii", newline="\n") as stream:
        for record in records:
            stream.write(f"{record:0{digits}X}\n")
    canonical_csv = data_dir / f"{args.case}_golden.csv"
    with canonical_csv.open("x", encoding="ascii", newline="") as stream:
        writer = csv.writer(stream, lineterminator="\n")
        writer.writerow([name for name, _ in FIELDS])
        writer.writerows(canonical)
    staged["data_files"].extend((file_entry(stage_root, memory), file_entry(stage_root, canonical_csv)))

    expected_frames = frames + (2 if args.mode == "reset" else 0)
    # Actual checker operations: three duty comparisons per emitted frame,
    # old/next-state comparisons, four register commit checks per active edge.
    expected_checks = 20011 * frames - 4
    if args.mode == "reset":
        expected_checks += 40422
    if args.mode == "cycle_negative":
        expected_checks += 3
    result = {
        "schema_version": 1,
        "root_dir": str(stage_root),
        "dut_top": "FOC_DUT",
        "tb_top": "m3_foc_scoreboard",
        "clock_port": "clk",
        "part": source.get("part", "xc7a200tfbg484-2"),
        "clock_period_ns": 20,
        "defines": ["M3_PI_COMMIT_NEXT_FRAME"] if pi_next_frame else [],
        "design_files": staged["design_files"],
        "testbench_files": [file_entry(stage_root, scoreboard)],
        "data_files": staged["data_files"],
        "simulation": {
            "expected_frames": expected_frames,
            "expected_checks": expected_checks,
            "timeout_seconds": args.timeout_seconds,
            "plusargs": [f"frames={frames}", f"case_name={args.case}", f"mode={args.mode}", f"negative_sample={negative_sample}",f"output_phase={phase}"],
            "plusarg_files": {"vectors": memory.relative_to(stage_root).as_posix()},
            "plusarg_outputs": {"result": "scoreboard.json"},
        },
        "independent_scoreboard": {
            "mode": args.mode,
            "source_manifest_sha256": sha256(manifest_path),
            "source_golden_sha256": sha256(args.golden.resolve()),
            "input_frames": frames,
            "record_bits": RECORD_BITS,
            "fields": [{"name": name, "bits": width} for name, width in FIELDS],
            "frame_clocks": 5000,
            "output_post_edge_phase": phase,
            "old_state_pre_edge_phase": 5000,
            "pi_commit_post_edge_phase":1 if pi_next_frame else 5000,
            "deadline_clocks": 2500,
            "expected_negative": args.mode in ("bit_negative", "cycle_negative"),
            "negative_sample": negative_sample,
            "cycle_negative_mechanism": "observe actual duties at phase 273 against the selected changed row golden; ineffective early check must be rejected by caller, not manufactured as FAIL",
            "validity": "fixed external checker contract; generated ce_out is fast CE, not frame-valid",
            "global_reset_oracle": "predetermined cancellation then zero-initial-state source/gm replay; gm has no global reset input",
            "state_mapping": {
                "x_d_old": "dut.u_Id.x_d_z_out1 before phase-5000 PI commit",
                "x_q_old": "dut.u_Iq.x_q_z_out1 before phase-5000 PI commit",
                "aw_d_old": "dut.dq_voltage_limiter_du_d_z at PI consuming event, including AW selector",
                "aw_q_old": "dut.dq_voltage_limiter_du_q_z at PI consuming event, including AW selector",
            },
        },
    }
    output.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return {"manifest": str(output), "frames": expected_frames, "checks": expected_checks, "mode": args.mode}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, required=True, help="hash-locked B design manifest")
    parser.add_argument("--golden", type=Path, required=True, help="exact 17-column source/gm golden CSV")
    parser.add_argument("--out", type=Path, required=True, help="manifest path inside a NEW staging directory")
    parser.add_argument("--case", required=True)
    parser.add_argument("--mode", choices=MODES, default="normal")
    parser.add_argument("--frames", type=int)
    parser.add_argument("--negative-sample", type=int, help="changed golden row for actual phase-273 early observation")
    parser.add_argument("--timeout-seconds", type=int, default=1800)
    args = parser.parse_args()
    if args.frames is not None and args.frames < 1:
        parser.error("--frames must be positive")
    if args.timeout_seconds < 1:
        parser.error("--timeout-seconds must be positive")
    try:
        result = stage(args)
    except (ValueError, OSError, json.JSONDecodeError, csv.Error) as error:
        print(f"M3_SCOREBOARD_STAGE_FAIL: {error}", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
