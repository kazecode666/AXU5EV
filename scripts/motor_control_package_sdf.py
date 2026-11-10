"""Build the explicit Issue40 input zip, then unpack and check it without Vivado."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import zipfile

from motor_control_sdf_inputs import audit, sha256


ROOT = Path(__file__).resolve().parent.parent


def write_json(path, value):
    path.write_bytes((json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True, encoding="utf-8").strip()


def checked(command, cwd, log, env=None):
    result = subprocess.run(command, cwd=cwd, env=env, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=30)
    log.write_bytes(result.stdout)
    if result.returncode:
        raise RuntimeError("Self-check failed; see " + str(log))
    return result


def build(args):
    output, check = args.output.resolve(), args.check_dir.resolve()
    if output.exists() or check.exists():
        raise FileExistsError("Output and check-dir must both be new; preserve all prior attempts")
    source_commit = git("rev-parse", "HEAD")
    runner_commit = git("log", "-1", "--format=%H", "--", "scripts/sdf_runner.py")
    test_commit = git("log", "-1", "--format=%H", "--", "verification/motor_control/timing_tb.sv")
    subprocess.run(["git", "diff", "--exit-code", "HEAD", "--", "scripts/sdf_runner.py",
                    "verification/motor_control/timing_tb.sv"], cwd=ROOT, check=True)
    output.mkdir(parents=True)
    name = "AXU5EV_Issue40_SDF_hardware_02_" + runner_commit[:7]
    payload = output / name
    payload.mkdir()
    inputs = {"inputs/hardware_02/timing_pl/" + filename: args.hardware.resolve() / "timing_pl" / filename
              for filename in ("motor_routed.v", "motor_slow.sdf", "motor_fast.sdf")}
    inputs.update({"verification/motor_control/timing_tb.sv": ROOT / "verification/motor_control/timing_tb.sv",
                   "scripts/sdf_runner.py": ROOT / "scripts/sdf_runner.py",
                   "scripts/motor_control_sdf_inputs.py": ROOT / "scripts/motor_control_sdf_inputs.py",
                   "README_ZH.md": ROOT / "firmware/r5/motor_control/SDF_SERVER_ZH.md"})
    hashes = {}
    source_sizes = {}
    for relative, source in inputs.items():
        target = payload / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        # Hash the exact bytes as they are copied from the selected source.
        import hashlib
        digest = hashlib.sha256()
        size = 0
        with source.open("rb") as reader, target.open("xb") as writer:
            while block := reader.read(1024 * 1024):
                writer.write(block)
                digest.update(block)
                size += len(block)
        shutil.copystat(source, target)
        hashes[relative] = digest.hexdigest()
        source_sizes[relative] = size
        print("BUNDLE_COPY", relative, size, flush=True)
    dependencies = audit(payload)
    write_json(payload / "dependency_audit.json", dependencies)
    known = json.loads((ROOT / "verification/motor_control/results.json").read_text(encoding="utf-8"))
    provenance = {"repository": "kazecode666/AXU5EV", "issue": 40, "pr": 41,
        "source_commit_at_build": source_commit, "runner_source_commit": runner_commit,
        "event_testbench_last_commit": test_commit,
        "functional_commit": known["functional_commit"], "disarm_fix_commit": known["disarm_fix_commit"],
        "timing_export_commit": known["timing_export_test_commit"], "hardware_candidate": "hardware_02",
        "netlist_export": "write_verilog -mode timesim -sdf_anno false -rename_top motor_routed",
        "vivado_version": "2026.1", "sw_build": "6511674", "ip_build": "6504888",
        "shared_data_build": "6501428", "additional_patch": "not identified in the existing export log",
        "file_bytes": source_sizes, "input_mode": "full functional PL; latest event testbench netlist branch",
        "MC_TIMING_RTL_defined": False, "O0": "NOT_SET_NOT_RUN",
        "production_artifacts": "copied unchanged; no DCP/bit/XSA/ELF or compile caches included",
        "server_execution": "NOT_RUN", "sdf_annotation": "NOT_COMPLETED", "sdf_dynamic": "NOT_RUN"}
    write_json(payload / "provenance.json", provenance)
    for extra in ("dependency_audit.json", "provenance.json"):
        hashes[extra] = sha256(payload / extra)
    (payload / "SHA256SUMS").write_bytes("".join(digest + "  " + relative + "\n"
                                                for relative, digest in sorted(hashes.items())).encode("utf-8"))
    archive_path = output / (name + ".zip")
    print("BUNDLE_COMPRESS", archive_path, flush=True)
    with zipfile.ZipFile(archive_path, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for relative in sorted([*hashes, "SHA256SUMS"]):
            archive.write(payload / relative, name + "/" + relative)
    archive_hash = sha256(archive_path)
    (output / (archive_path.name + ".sha256")).write_bytes(
        (archive_hash + "  " + archive_path.name + "\n").encode("ascii"))
    check.mkdir(parents=True)
    print("BUNDLE_EXTRACT", check, flush=True)
    with zipfile.ZipFile(archive_path) as archive:
        archive.extractall(check)  # Our explicit file list; ZipFile verifies member CRC on extraction.
    unpacked = check / name
    elsewhere = check / "outside_cwd"
    elsewhere.mkdir()
    checked([sys.executable, str(unpacked / "scripts/motor_control_sdf_inputs.py")], elsewhere,
            check / "input_check.json")
    input_check = json.loads((check / "input_check.json").read_text(encoding="utf-8"))
    assert input_check["status"] == "PASS_BUNDLE_INPUTS_NOT_SDF"
    dry_results = {}
    for corner in ("slow", "fast"):
        run = check / ("dry_" + corner)
        command = [sys.executable, str(unpacked / "scripts/sdf_runner.py"), "--hardware",
                   str(unpacked / "inputs/hardware_02"), "--vivado-bin", str(args.vivado_bin.resolve()),
                   "--corner", corner, "--run-dir", str(run), "--dry-run"]
        checked(command, elsewhere, check / ("dry_" + corner + ".log"))
        summary = json.loads((run / "summary.json").read_text(encoding="utf-8"))
        plan = json.loads((run / "commands.json").read_text(encoding="utf-8"))
        assert summary["status"] == "DRY_RUN_PASS_NOT_SDF"
        assert [stage["stage"] for stage in plan] == ["xvlog", "xelab", "xsim"]
        assert "MC_TIMING_RTL" not in json.dumps(plan) and "-O" not in plan[1]["argv"]
        assert ("-sdfmax" if corner == "slow" else "-sdfmin") in plan[1]["argv"]
        assert plan[0]["argv"][2:4] == [str(unpacked / "inputs/hardware_02/timing_pl/motor_routed.v"),
                                        str(unpacked / "verification/motor_control/timing_tb.sv")]
        dry_results[corner] = summary["status"]
    # Independent short fake install located outside the original repository.
    mock = check / "mock_install"
    bins = mock / "bin"
    bins.mkdir(parents=True)
    (mock / "data/verilog/src").mkdir(parents=True)
    (mock / "data/verilog/src/glbl.v").write_bytes(b"// MOCK ONLY\n")
    fake = mock / "fake_tool.py"
    fake.write_bytes(b"import os,sys,time\nstage=sys.argv[1]\nprint('MOCK_TOOL',stage,flush=True)\nprint('MOCK_STDERR',file=sys.stderr,flush=True)\ntime.sleep(0.1)\nif stage=='xelab' and os.environ.get('BUNDLE_MOCK_FAIL')=='1': sys.exit(7)\nif stage=='xelab': print('INFO: [XSIM 43-3452] MOCK',flush=True)\nif stage=='xsim': print('PWM_SDF_PASS MOCK_ONLY_NO_HDL',flush=True)\n")
    for stage in ("xvlog", "xelab", "xsim"):
        if os.name == "nt":
            (bins / (stage + ".bat")).write_bytes(
                ('@echo off\n"' + sys.executable + '" "' + str(fake) + '" ' + stage + '\nexit /b %errorlevel%\n').encode("utf-8"))
        else:
            launcher = bins / stage
            launcher.write_text('#!/bin/sh\nexec "' + sys.executable + '" "' + str(fake) + '" ' + stage + '\n')
            launcher.chmod(0o755)
    mock_results = {}
    for mode in ("normal", "fail"):
        run = check / ("mock_" + mode)
        command = [sys.executable, str(unpacked / "scripts/sdf_runner.py"), "--hardware",
                   str(unpacked / "inputs/hardware_02"), "--vivado-bin", str(bins),
                   "--run-dir", str(run), "--tool-timeout-ms", "5000", "--scope", "MOCK_ONLY_NOT_SDF"]
        env = os.environ.copy()
        env["BUNDLE_MOCK_FAIL"] = "1" if mode == "fail" else "0"
        completed = subprocess.run(command, cwd=elsewhere, env=env, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, timeout=20)
        (check / ("mock_" + mode + ".log")).write_bytes(completed.stdout)
        result = json.loads((run / "summary.json").read_text(encoding="utf-8"))
        assert (completed.returncode == 0) == (mode == "normal")
        assert result["status"] == ("PASS" if mode == "normal" else "FAILED_EXIT"), result
        if mode == "fail":
            assert not (run / "xsim.process.json").exists()
        mock_results[mode] = {"status": result["status"], "scope": "MOCK_ONLY_NOT_SDF"}
    report = {"status": "PASS_PACKAGE_AND_UNPACK_CHECKS_ONLY", "archive": str(archive_path),
        "archive_bytes": archive_path.stat().st_size, "archive_sha256": archive_hash,
        "archive_sha256_file": str(output / (archive_path.name + ".sha256")),
        "unpacked_root": str(unpacked), "check_directory": str(check), "checked_from": str(elsewhere),
        "runner_fix_commit": runner_commit, "testbench_commit": test_commit, "package_file_count": len(hashes) + 1,
        "source_file_bytes": source_sizes, "input_check": input_check["status"], "checksum_files": input_check["checked_files"],
        "extra_project_file_inputs": dependencies["additional_project_input_files"],
        "dry_runs": dry_results, "mock_portable_entry": mock_results, "platform_executed": sys.platform,
        "server_execution": "NOT_RUN", "real_vivado_launches": 0, "O0": "NOT_SET_NOT_RUN",
        "slow_annotation": "NOT_COMPLETED", "slow_dynamic": "NOT_RUN", "fast_dynamic": "NOT_RUN"}
    write_json(output / "package_report.json", report)
    print(json.dumps(report, ensure_ascii=False, indent=2), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--hardware", type=Path, default=ROOT / ".runtime/motor_control/hardware_02")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--check-dir", type=Path, required=True)
    parser.add_argument("--vivado-bin", type=Path, required=True, help="Only read files for dry-run; never start Vivado")
    args = parser.parse_args()
    try:
        build(args)
    except BaseException as error:
        if args.output.is_dir():
            write_json(args.output / "package_failure.json", {"status": "FAILED", "reason": repr(error),
                       "previous_files": "retained; choose new directories for any corrected attempt"})
        raise
