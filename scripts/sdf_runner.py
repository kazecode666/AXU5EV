"""SDF-only process ownership and the existing xvlog/xelab/xsim flow.

Windows: a waiting bootstrap is assigned to a kill-on-close Job before it may
start cmd/bat/native children. Linux: one new process group. No name-based kill.
https://learn.microsoft.com/en-us/windows/win32/procthread/job-objects
"""
from __future__ import annotations

import argparse
import ctypes
import datetime as dt
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import threading
import time


ROOT = Path(__file__).resolve().parent.parent
TOOL_ERROR = re.compile(r"^(ERROR:|FATAL:|Fatal:|Error:)", re.I)
TIMING_ERROR = re.compile(
    r"timing violation|\$(setuphold|recrem|width|setup|hold|recovery|removal|period)\("
    r"|SDF.*(ERROR|WARNING)|WARNING:.*(SDF|annotat)|not annotated", re.I)


def now():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def save(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


class WindowsJob:
    """Only the current stage and its descendants; handles retain PID identity."""
    def __init__(self):
        from ctypes import wintypes as w
        self.w = w
        self.k = ctypes.WinDLL("kernel32", use_last_error=True)
        signatures = {
            "CreateJobObjectW": ([ctypes.c_void_p, w.LPCWSTR], w.HANDLE),
            "SetInformationJobObject": ([w.HANDLE, ctypes.c_int, ctypes.c_void_p, w.DWORD], w.BOOL),
            "QueryInformationJobObject": ([w.HANDLE, ctypes.c_int, ctypes.c_void_p, w.DWORD, ctypes.c_void_p], w.BOOL),
            "AssignProcessToJobObject": ([w.HANDLE, w.HANDLE], w.BOOL),
            "TerminateJobObject": ([w.HANDLE, w.UINT], w.BOOL),
            "OpenProcess": ([w.DWORD, w.BOOL, w.DWORD], w.HANDLE),
            "CloseHandle": ([w.HANDLE], w.BOOL),
            "GetProcessTimes": ([w.HANDLE] + [ctypes.POINTER(w.FILETIME)] * 4, w.BOOL),
            "GetExitCodeProcess": ([w.HANDLE, ctypes.POINTER(w.DWORD)], w.BOOL),
            "WaitForSingleObject": ([w.HANDLE, w.DWORD], w.DWORD),
            "QueryFullProcessImageNameW": ([w.HANDLE, w.DWORD, w.LPWSTR, ctypes.POINTER(w.DWORD)], w.BOOL),
        }
        for name, (args, result) in signatures.items():
            getattr(self.k, name).argtypes = args
            getattr(self.k, name).restype = result

        class Limits(ctypes.Structure):
            _fields_ = [("process_time", ctypes.c_longlong), ("job_time", ctypes.c_longlong),
                        ("flags", w.DWORD), ("min_ws", ctypes.c_size_t), ("max_ws", ctypes.c_size_t),
                        ("active", w.DWORD), ("affinity", ctypes.c_size_t),
                        ("priority", w.DWORD), ("scheduling", w.DWORD)]

        class Extended(ctypes.Structure):
            _fields_ = [("basic", Limits), ("io", ctypes.c_ulonglong * 6),
                        ("process_memory", ctypes.c_size_t), ("job_memory", ctypes.c_size_t),
                        ("peak_process", ctypes.c_size_t), ("peak_job", ctypes.c_size_t)]

        self.handle = self.k.CreateJobObjectW(None, None)
        if not self.handle:
            raise ctypes.WinError(ctypes.get_last_error())
        self.handles = {}
        self.records = {}
        self.terminated = set()
        info = Extended()
        info.basic.flags = 0x2000  # JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE; no breakaway.
        if not self.k.SetInformationJobObject(self.handle, 9, ctypes.byref(info), ctypes.sizeof(info)):
            error = ctypes.WinError(ctypes.get_last_error())
            self.close()
            raise error

    def assign(self, pid):
        handle = self.k.OpenProcess(0x0100 | 0x0001, False, pid)
        if not handle:
            raise ctypes.WinError(ctypes.get_last_error())
        try:
            if not self.k.AssignProcessToJobObject(self.handle, handle):
                raise ctypes.WinError(ctypes.get_last_error())
        finally:
            self.k.CloseHandle(handle)

    def members(self):
        capacity = 64
        while True:
            buffer = ctypes.create_string_buffer(8 + ctypes.sizeof(ctypes.c_size_t) * capacity)
            if self.k.QueryInformationJobObject(self.handle, 3, buffer, len(buffer), None):
                count = self.w.DWORD.from_buffer(buffer, 4).value
                return list((ctypes.c_size_t * count).from_buffer(buffer, 8))
            if ctypes.get_last_error() != 234:  # ERROR_MORE_DATA
                raise ctypes.WinError(ctypes.get_last_error())
            capacity *= 2

    def observe(self):
        active = self.members()
        for pid in active:
            if pid in self.records:
                continue
            handle = self.k.OpenProcess(0x1000 | 0x100000, False, pid)
            if not handle:  # It can exit between the Job query and OpenProcess.
                continue
            creation, exit_time, kernel, user = (self.w.FILETIME() for _ in range(4))
            if not self.k.GetProcessTimes(handle, ctypes.byref(creation), ctypes.byref(exit_time),
                                          ctypes.byref(kernel), ctypes.byref(user)):
                self.k.CloseHandle(handle)
                raise ctypes.WinError(ctypes.get_last_error())
            ticks = (creation.dwHighDateTime << 32) | creation.dwLowDateTime
            image = ctypes.create_unicode_buffer(32768)
            size = self.w.DWORD(len(image))
            image_ok = self.k.QueryFullProcessImageNameW(handle, 0, image, ctypes.byref(size))
            self.handles[pid] = handle
            self.records[pid] = {"pid": pid, "creation_filetime": ticks,
                                 "created_utc": dt.datetime.fromtimestamp(
                                     (ticks - 116444736000000000) / 10000000, dt.timezone.utc).isoformat(),
                                 "image": image.value if image_ok else None, "natural_exit_code": None}
        for pid, handle in self.handles.items():
            if self.k.WaitForSingleObject(handle, 0) == 0:
                code = self.w.DWORD()
                if not self.k.GetExitCodeProcess(handle, ctypes.byref(code)):
                    raise ctypes.WinError(ctypes.get_last_error())
                if pid not in self.terminated:
                    self.records[pid]["natural_exit_code"] = code.value
        return active

    def stop(self):
        self.terminated.update(self.observe())
        if self.terminated and not self.k.TerminateJobObject(self.handle, 125):
            raise ctypes.WinError(ctypes.get_last_error())
        for pid in self.terminated:
            if pid in self.records:
                self.records[pid]["termination"] = "stage supervisor; not a natural tool exit"

    def close(self):
        for handle in self.handles.values():
            self.k.CloseHandle(handle)
        if self.handle:
            self.k.CloseHandle(self.handle)
            self.handle = None


class LinuxGroup:
    def __init__(self, pid):
        self.pid = pid
        self.records = {}

    def observe(self):
        active = []
        boot = int(next(line.split()[1] for line in Path("/proc/stat").read_text().splitlines()
                        if line.startswith("btime ")))
        for item in Path("/proc").iterdir():
            if not item.name.isdecimal():
                continue
            try:
                fields = (item / "stat").read_text().rsplit(")", 1)[1].split()
                if int(fields[2]) != self.pid or fields[0] == "Z":
                    continue
                pid = int(item.name)
                active.append(pid)
                if pid not in self.records:
                    self.records[pid] = {"pid": pid, "creation_ticks": int(fields[19]),
                        "created_utc": dt.datetime.fromtimestamp(
                            boot + int(fields[19]) / os.sysconf("SC_CLK_TCK"), dt.timezone.utc).isoformat(),
                        "image": os.readlink(item / "exe"), "natural_exit_code": None}
            except (FileNotFoundError, ProcessLookupError, PermissionError):
                continue
        return active

    def stop(self):
        for pid in self.observe():
            self.records[pid]["termination"] = "stage supervisor; not a natural tool exit"
        for sig in (signal.SIGTERM, signal.SIGKILL):
            try:
                os.killpg(self.pid, sig)
            except ProcessLookupError:
                break
            deadline = time.monotonic() + 0.5
            while self.observe() and time.monotonic() < deadline:
                time.sleep(0.02)
            if not self.observe():
                break

    def close(self):
        pass


def tool_command(argv):
    if os.name == "nt" and Path(argv[0]).suffix.lower() in (".bat", ".cmd"):
        # Keep CMD's /s /c quoting separate from native Windows argv quoting.
        if any(re.search(r'["&|<>^%!\r\n]', word) for word in argv):
            raise ValueError("Unsupported CMD argument metacharacter")
        return '"' + os.environ["ComSpec"] + '" /d /s /c "' + " ".join('"' + a + '"' for a in argv) + '"'
    return argv


def run_tool(stage, argv, directory, timeout_ms, cancel_file=None):
    """Save output as it arrives; always stop/reap our tree before closing pipes."""
    directory = Path(directory)
    record_path = directory / (stage + ".process.json")
    console_path = directory / (stage + ".console.log")
    if record_path.exists() or console_path.exists():
        raise FileExistsError("Stage outputs exist; choose a new run directory")
    record = {"stage": stage, "status": "STARTING", "command": argv, "cwd": str(directory),
              "supervisor_pid": os.getpid(), "started_utc": now(), "timeout_ms": timeout_ms,
              "natural_exit_code": None, "remaining_pids": None, "processes": []}
    process = group = None
    assigned = False
    threads = []
    drain_errors = []
    cancelled = threading.Event()
    old_signals = {}
    logs = []
    lock = threading.Lock()

    def drain(pipe, destination):
        try:
            while chunk := os.read(pipe.fileno(), 65536):
                destination.write(chunk)
                with lock:
                    logs[0].write(chunk)
        except Exception as error:
            drain_errors.append(repr(error))

    try:
        for sig in (signal.SIGINT, signal.SIGTERM, getattr(signal, "SIGBREAK", signal.SIGINT)):
            if sig not in old_signals:
                old_signals[sig] = signal.signal(sig, lambda *_: cancelled.set())
        record["launch_command"] = tool_command(argv)
        logs = [open(console_path, "xb", buffering=0),
                open(directory / (stage + ".stdout.log"), "xb", buffering=0),
                open(directory / (stage + ".stderr.log"), "xb", buffering=0)]
        if cancel_file and Path(cancel_file).exists():
            record.update(status="CANCELLED", reason="explicit cancel file before launch")
        else:
            start = time.monotonic()
            if os.name == "nt":
                group = WindowsJob()
                # This process cannot start CMD until assignment to our Job succeeds.
                process = subprocess.Popen(
                    [sys.executable, str(Path(__file__).resolve()), "_bootstrap",
                     json.dumps(record["launch_command"]), str(directory / (stage + ".launch.json"))],
                    cwd=directory, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                    creationflags=subprocess.CREATE_NEW_PROCESS_GROUP | subprocess.CREATE_NO_WINDOW)
                group.assign(process.pid)
                assigned = True
            else:
                if not Path("/proc/stat").is_file():
                    raise RuntimeError("This process-group observer requires Linux /proc")
                process = subprocess.Popen(argv, cwd=directory, stdin=subprocess.DEVNULL,
                                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True)
                group = LinuxGroup(process.pid)
            record.update(status="RUNNING", root_pid=process.pid)
            for pipe, destination in ((process.stdout, logs[1]), (process.stderr, logs[2])):
                thread = threading.Thread(target=drain, args=(pipe, destination), daemon=True)
                thread.start()
                threads.append(thread)
            group.observe()
            record["processes"] = list(group.records.values())
            save(record_path, record)
            if os.name == "nt":
                process.stdin.write(b"GO\n")
                process.stdin.close()
            last_save = 0
            while True:
                group.observe()
                if cancelled.is_set() or (cancel_file and Path(cancel_file).exists()):
                    record.update(status="CANCELLED", reason="signal or explicit cancel file")
                    break
                code = process.poll()
                if code is not None:
                    record["natural_exit_code"] = code
                    record["status"] = "EXITED_OK" if code == 0 else "FAILED_EXIT"
                    break
                if (time.monotonic() - start) * 1000 >= timeout_ms:
                    record.update(status="TIMED_OUT", reason="stage wall-clock limit")
                    break
                if time.monotonic() - last_save >= 0.5:
                    record["processes"] = list(group.records.values())
                    save(record_path, record)
                    last_save = time.monotonic()
                time.sleep(0.02)
    except BaseException as error:
        record.update(status="CANCELLED" if isinstance(error, KeyboardInterrupt) else "START_OR_MONITOR_FAILED",
                      reason=repr(error))
    finally:
        try:
            if process and os.name == "nt" and not assigned:
                process.kill()  # Never received GO; no CMD/native descendants exist.
                process.wait(timeout=5)
            if group:
                # Normal exit also must not leave a detached stage descendant.
                deadline = time.monotonic() + (0.3 if record["status"] == "EXITED_OK" else 0)
                while group.observe() and time.monotonic() < deadline:
                    time.sleep(0.02)
                if group.observe():
                    if record["status"] == "EXITED_OK":
                        record.update(status="FAILED_CHILD_REMAINS", reason="root exited 0 with live stage descendants")
                    group.stop()
                if process:
                    process.wait(timeout=5)
                    record["root_observed_exit_code"] = process.returncode
                record["remaining_pids"] = group.observe()
                record["processes"] = list(group.records.values())
                if record["remaining_pids"]:
                    record["status"] = "CLEANUP_FAILED"
            elif process:
                process.kill()  # Bootstrap has not received GO, so has no tool descendants.
                process.wait(timeout=5)
        except BaseException as error:
            record.update(status="CLEANUP_FAILED", cleanup_error=repr(error))
        finally:
            if group:
                group.close()  # Windows kill-on-close is also a final ownership safeguard.
            for thread in threads:
                thread.join(timeout=5)
            if any(t.is_alive() for t in threads) or drain_errors:
                record.update(status="LOG_DRAIN_FAILED", drain_errors=drain_errors)
            for stream in logs:
                stream.close()
            if process:
                if process.stdin and not process.stdin.closed:
                    process.stdin.close()
                for pipe in (process.stdout, process.stderr):
                    if pipe:
                        pipe.close()
            for sig, previous in old_signals.items():
                signal.signal(sig, previous)
            record["finished_utc"] = now()
            if record["status"] == "EXITED_OK":
                with console_path.open(encoding="utf-8", errors="replace") as stream:
                    if any(TOOL_ERROR.search(line) for line in stream):
                        record.update(status="FAILED_LOG", reason="ERROR/FATAL in tool output")
            save(record_path, record)
    return record


def check_sdf(directory):
    annotation = False
    markers = []
    for stage in ("xelab", "xsim"):
        with (directory / (stage + ".console.log")).open(encoding="utf-8", errors="replace") as stream:
            for line in stream:
                if TIMING_ERROR.search(line):
                    raise RuntimeError("Review SDF annotation or timing violation: " + line.strip())
                if stage == "xelab" and "XSIM 43-3452" in line:
                    annotation = True
                if stage == "xsim" and line.startswith("PWM_SDF_PASS "):
                    markers.append(line.strip())
    if len(markers) != 1:
        raise RuntimeError("Missing or duplicate SDF test PASS")
    if not annotation:
        raise RuntimeError("Missing successful SDF backannotation confirmation")
    return markers[0]


def commands(hardware, testbench, vivado_bin, corner, xelab_o0=False, xelab_diagnostics=False):
    suffix = ".bat" if os.name == "nt" else ""
    tools = {name: vivado_bin / (name + suffix) for name in ("xvlog", "xelab", "xsim")}
    netdir = hardware / "timing_pl"
    glbl = (vivado_bin / "../data/verilog/src/glbl.v").resolve()
    for source in (netdir / "motor_routed.v", netdir / ("motor_" + corner + ".sdf"), testbench, glbl, *tools.values()):
        if not source.is_file():
            raise FileNotFoundError(source)
    plan = [
        ("xvlog", [str(tools["xvlog"]), "-sv", str(netdir / "motor_routed.v"), str(testbench), str(glbl)]),
        ("xelab", [str(tools["xelab"]), "work.timing_tb", "work.glbl", "-s", "pwm_timing", "-debug", "off",
                   "-timescale", "1ns/1ps", "-L", "simprims_ver", "-L", "unisims_ver", "-L", "secureip",
                   "-transport_int_delays", "-pulse_r", "0", "-pulse_int_r", "0", "-pulse_e", "0", "-pulse_int_e", "0",
                   "-sdfmax" if corner == "slow" else "-sdfmin",
                   "/timing_tb/dut=" + (netdir / ("motor_" + corner + ".sdf")).as_posix()]),
        ("xsim", [str(tools["xsim"]), "pwm_timing", "-runall"]),
    ]
    if xelab_o0:
        plan[1][1].append("--O0")  # Actual local 2026.1 -help spelling, not an HDL change.
    if xelab_diagnostics:
        plan[1][1].extend(["--stats", "--verbose", "1"])
    return plan


def main():
    parser = argparse.ArgumentParser(description="One SDF corner, existing event test and timing checks; no rebuild")
    parser.add_argument("--hardware", type=Path, required=True)
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--corner", choices=("slow", "fast"), default="slow")
    parser.add_argument("--vivado-bin", type=Path, required=True)
    parser.add_argument("--testbench", type=Path, default=ROOT / "verification/motor_control/timing_tb.sv")
    parser.add_argument("--tool-timeout-ms", type=int, default=10800000)
    parser.add_argument("--cancel-file", type=Path)
    parser.add_argument("--scope", default="routed full functional PL; PWM ILA black box; structural dbg_hub retained; PS clock/reset and AXI transaction sources substituted")
    parser.add_argument("--dry-run", action="store_true", help="Validate files and save commands; do not start tools")
    parser.add_argument("--xelab-o0", action="store_true", help="Explicit single-variable no-optimization candidate; not a proven speed fix")
    parser.add_argument("--xelab-diagnostics", action="store_true", help="2026.1 --stats --verbose 1; does not disable timing checks")
    args = parser.parse_args()
    if args.tool_timeout_ms <= 0:
        parser.error("tool-timeout-ms must be positive")
    directory = args.run_dir.resolve()
    directory.mkdir(parents=True, exist_ok=False)
    result = {"status": "RUNNING", "corner": args.corner, "hardware": str(args.hardware.resolve()),
              "run_dir": str(directory), "board": "NOT_RUN", "scope": args.scope,
              "started_utc": now(), "stages": [], "MC_TIMING_RTL_defined": False,
              "xelab_o0": args.xelab_o0, "xelab_diagnostics": args.xelab_diagnostics}
    exit_code = 1
    try:
        plan = commands(args.hardware.resolve(), args.testbench.resolve(), args.vivado_bin.resolve(), args.corner,
                        args.xelab_o0, args.xelab_diagnostics)
        save(directory / "commands.json", [{"stage": s, "argv": a} for s, a in plan])
        if args.dry_run:
            result["status"] = "DRY_RUN_PASS_NOT_SDF"
            exit_code = 0
        else:
            for stage, argv in plan:
                result["phase"] = stage
                save(directory / "summary.json", result)
                record = run_tool(stage, argv, directory, args.tool_timeout_ms,
                                  args.cancel_file.resolve() if args.cancel_file else None)
                result["stages"].append({"stage": stage, "status": record["status"], "record": stage + ".process.json"})
                print("SDF_TOOL_STATUS", stage, record["status"], flush=True)
                if record["status"] != "EXITED_OK":
                    result.update(status=record["status"], reason=record.get("reason", "see process record"))
                    exit_code = 124 if record["status"] == "TIMED_OUT" else 130 if record["status"] == "CANCELLED" else 1
                    break
            else:
                result["phase"] = "annotation_and_dynamic_checks"
                result["pass_marker"] = check_sdf(directory)
                result["status"] = "PASS"
                exit_code = 0
                print(result["pass_marker"], flush=True)
    except BaseException as error:
        result.update(status="CANCELLED" if isinstance(error, KeyboardInterrupt) else "FAILED",
                      reason=repr(error))
        exit_code = 130 if isinstance(error, KeyboardInterrupt) else 1
    finally:
        result["finished_utc"] = now()
        save(directory / "summary.json", result)
    if exit_code:
        print("SDF_RUN_STOP", result["status"], result.get("reason", ""), file=sys.stderr)
    return exit_code


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "_bootstrap":
        if sys.stdin.buffer.readline() != b"GO\n":
            sys.exit(125)
        child = subprocess.Popen(json.loads(sys.argv[2]), stdin=subprocess.DEVNULL)
        save(Path(sys.argv[3]), {"tool_root_pid": child.pid, "started_utc": now()})
        sys.exit(child.wait())
    sys.exit(main())
