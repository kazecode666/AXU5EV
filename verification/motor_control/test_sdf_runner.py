"""Short process-tree fixtures only. No Vivado, HDL, SDF annotation or board."""
import argparse
import ctypes
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import time


ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("sdf_runner", ROOT / "scripts/sdf_runner.py")
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


def alive(pid):
    if os.name == "nt":
        from ctypes import wintypes as w
        k = ctypes.WinDLL("kernel32", use_last_error=True)
        k.OpenProcess.argtypes = [w.DWORD, w.BOOL, w.DWORD]
        k.OpenProcess.restype = w.HANDLE
        k.WaitForSingleObject.argtypes = [w.HANDLE, w.DWORD]
        k.CloseHandle.argtypes = [w.HANDLE]
        handle = k.OpenProcess(0x100000, False, pid)
        if not handle:
            return False
        try:
            return k.WaitForSingleObject(handle, 0) == 258
        finally:
            k.CloseHandle(handle)
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False


def fixture(role, mode, stage):
    print(role + "_OUT_BEGIN", flush=True)
    print(role + "_ERR_BEGIN", file=sys.stderr, flush=True)
    if role == "leaf":
        Path("leaf.pid").write_text(str(os.getpid()))
        print("LEAF_MID", flush=True)
        print("LEAF_ERR_MID", file=sys.stderr, flush=True)
        time.sleep(0.8 if mode == "normal" else 30)
    else:
        selected = os.environ.get("SDF_MOCK_MODE", mode)
        failed = selected == "failure" or (selected == "fail_xelab" and stage == "xelab")
        hold = selected in ("timeout", "cancel") or failed
        Path(stage + ".native.log").write_text("MOCK_NATIVE_STARTED\n")
        child = subprocess.Popen([sys.executable, __file__, "--fixture", "leaf",
                                  "hold" if hold else "normal", stage], stdin=subprocess.DEVNULL)
        time.sleep(0.25)
        print("NATIVE_BEFORE_WAIT", flush=True)
        print("NATIVE_ERR_BEFORE_WAIT", file=sys.stderr, flush=True)
        if failed:
            print("NATIVE_END_NONZERO", flush=True)
            print("NATIVE_ERR_END_NONZERO", file=sys.stderr, flush=True)
            return 7
        child.wait()
        if stage == "xelab":
            print("INFO: [XSIM 43-3452] MOCK annotation confirmation", flush=True)
        elif stage == "xsim":
            print("PWM_SDF_PASS MOCK_ONLY_NO_HDL", flush=True)
    print(role + "_OUT_END", flush=True)
    print(role + "_ERR_END", file=sys.stderr, flush=True)
    return 0


def driver(directory, mode, bat):
    result = runner.run_tool("mock", [bat], Path(directory), 900 if mode == "timeout" else 8000,
                             Path(directory) / "CANCEL" if mode == "cancel" else None)
    return 0 if result["status"] == "EXITED_OK" else 124 if result["status"] == "TIMED_OUT" else 130 if result["status"] == "CANCELLED" else 1


def tests(output):
    output.mkdir(parents=True, exist_ok=False)
    bins = output / "fake tool 空格" / "bin"
    bins.mkdir(parents=True)
    glbl = bins.parent / "data/verilog/src/glbl.v"
    glbl.parent.mkdir(parents=True)
    glbl.write_text("// mock only; no compiler\n")
    cases = []
    unrelated = subprocess.Popen([sys.executable, "-c", "import time;time.sleep(60)"],
                                 stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        for mode, expected, code in (("normal", "EXITED_OK", 0), ("failure", "FAILED_EXIT", 7),
                                     ("timeout", "TIMED_OUT", None), ("cancel", "CANCELLED", None)):
            directory = output / mode
            directory.mkdir()
            bat = bins / (mode + ".bat")
            bat.write_text('@echo off\n"' + sys.executable + '" "' + str(Path(__file__).resolve()) +
                           '" --fixture native ' + mode + ' mock\nexit /b %errorlevel%\n', encoding="utf-8")
            with (directory / "driver.log").open("wb") as log:
                process = subprocess.Popen([sys.executable, __file__, "--driver", str(directory), mode, str(bat)],
                                           stdout=log, stderr=subprocess.STDOUT)
                try:
                    deadline = time.monotonic() + 6
                    live_saved = False
                    while time.monotonic() < deadline and process.poll() is None:
                        out = directory / "mock.stdout.log"
                        err = directory / "mock.stderr.log"
                        if (out.exists() and err.exists() and b"LEAF_MID" in out.read_bytes()
                                and b"LEAF_ERR_MID" in err.read_bytes()
                                and b"NATIVE_BEFORE_WAIT" in out.read_bytes()
                                and b"NATIVE_ERR_BEFORE_WAIT" in err.read_bytes()):
                            live_saved = True
                            break
                        time.sleep(0.02)
                    assert live_saved, (mode, "stdout/stderr were not saved while running")
                    if mode == "cancel":
                        (directory / "CANCEL").write_text("explicit test cancellation\n")
                    process.wait(timeout=10)
                finally:
                    if process.poll() is None:
                        process.kill()
                        process.wait(timeout=5)
            result = json.loads((directory / "mock.process.json").read_text(encoding="utf-8"))
            assert result["status"] == expected, result
            assert result["natural_exit_code"] == code, result
            assert result["remaining_pids"] == [], result
            assert result["processes"] and all(p.get("created_utc") for p in result["processes"]), result
            if os.name == "nt":
                assert any(p["image"] and p["image"].lower().endswith("cmd.exe") for p in result["processes"]), result
                assert len(result["processes"]) >= 4, result  # bootstrap -> cmd/bat -> native Python -> leaf
            assert not alive(int((directory / "leaf.pid").read_text())), mode
            assert unrelated.poll() is None, "unrelated same-name Python process was affected"
            out = (directory / "mock.stdout.log").read_text(encoding="utf-8")
            err = (directory / "mock.stderr.log").read_text(encoding="utf-8")
            assert "native_OUT_BEGIN" in out and "native_ERR_BEGIN" in err
            if mode == "normal":
                assert "native_OUT_END" in out and "native_ERR_END" in err
            if mode == "failure":
                assert "NATIVE_END_NONZERO" in out and "NATIVE_ERR_END_NONZERO" in err
            assert (directory / "mock.native.log").is_file()
            cases.append({"case": mode, "status": "PASS", "observed": result["status"],
                          "live_stdout_stderr": live_saved, "natural_exit_code": code,
                          "observed_processes": len(result["processes"]), "remaining": 0,
                          "unrelated_process_unchanged": True})

        for stage in ("xvlog", "xelab", "xsim"):
            (bins / (stage + ".bat")).write_text(
                '@echo off\n"' + sys.executable + '" "' + str(Path(__file__).resolve()) +
                '" --fixture native normal ' + stage + '\nexit /b %errorlevel%\n', encoding="utf-8")
        hardware = output / "mock_hardware/timing_pl"
        hardware.mkdir(parents=True)
        for name in ("motor_routed.v", "motor_slow.sdf", "motor_fast.sdf"):
            (hardware / name).write_text("MOCK_ONLY_NOT_A_DESIGN\n")
        for mode in ("normal", "fail_xelab", "timeout", "cancel"):
            directory = output / ("powershell_" + mode)
            env = os.environ.copy()
            env["SDF_MOCK_MODE"] = mode
            command = ["pwsh", "-NoProfile", "-File", str(ROOT / "scripts/motor_control_run_sdf.ps1"),
                       "-Hardware", str(hardware.parent), "-RunDir", str(directory),
                       "-VivadoBin", str(bins), "-ToolTimeoutMs", "900" if mode == "timeout" else "8000",
                       "-Python", sys.executable]
            if mode == "cancel":
                command.extend(["-CancelFile", str(directory / "CANCEL")])
            process = subprocess.Popen(command, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            try:
                if mode == "cancel":
                    deadline = time.monotonic() + 6
                    while time.monotonic() < deadline:
                        log = directory / "xvlog.stderr.log"
                        if log.exists() and b"NATIVE_ERR_BEFORE_WAIT" in log.read_bytes():
                            (directory / "CANCEL").write_text("explicit wrapper cancel\n")
                            break
                        time.sleep(0.02)
                    else:
                        raise AssertionError("wrapper cancellation never reached live output")
                console, _ = process.communicate(timeout=20)
            finally:
                if process.poll() is None:
                    process.kill()
                    process.wait(timeout=5)
            (output / ("powershell_" + mode + ".log")).write_bytes(console)
            result = json.loads((directory / "summary.json").read_text(encoding="utf-8"))
            assert (process.returncode == 0) == (mode == "normal"), console
            expected_status = {"normal": "PASS", "fail_xelab": "FAILED_EXIT", "timeout": "TIMED_OUT", "cancel": "CANCELLED"}[mode]
            assert result["status"] == expected_status, result
            if mode != "normal":
                assert not (directory / "xsim.process.json").exists(), "xsim started after failed xelab"
                assert "pass_marker" not in result
            cases.append({"case": "powershell_" + mode, "status": "PASS",
                          "mock_flow_status": result["status"], "real_sdf": "NOT_RUN"})

        for name, annotation, simulation in (
            ("missing_annotation", "no annotation\n", "PWM_SDF_PASS MOCK\n"),
            ("timing_violation", "XSIM 43-3452\n", "timing violation MOCK\nPWM_SDF_PASS MOCK\n"),
            ("missing_pass", "XSIM 43-3452\n", "no pass\n"),
            ("sdf_warning", "XSIM 43-3452\nWARNING: SDF MOCK\n", "PWM_SDF_PASS MOCK\n")):
            directory = output / name
            directory.mkdir()
            (directory / "xelab.console.log").write_text(annotation)
            (directory / "xsim.console.log").write_text(simulation)
            try:
                runner.check_sdf(directory)
                raise AssertionError("invalid SDF result accepted: " + name)
            except RuntimeError:
                pass
            cases.append({"case": name, "status": "PASS", "invalid_result": "REJECTED"})
        result = {"status": "PASS", "scope": "short mock tools only; no Vivado/HDL/SDF/board",
                  "platform": sys.platform, "python": sys.version, "cases": cases,
                  "unrelated_process_unchanged": unrelated.poll() is None, "real_sdf": "NOT_RUN"}
        runner.save(output / "results.json", result)
        print(json.dumps(result, ensure_ascii=False, indent=2))
    finally:
        unrelated.terminate()  # Only this test-created independent fixture, never by process name.
        unrelated.wait(timeout=5)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--fixture":
        sys.exit(fixture(*sys.argv[2:5]))
    if len(sys.argv) > 1 and sys.argv[1] == "--driver":
        sys.exit(driver(*sys.argv[2:5]))
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()
    tests(arguments.output.resolve())
