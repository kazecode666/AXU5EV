"""Loopback TCP with the production C service and real AX-05A API on simulated PL."""

import argparse
import ctypes
import json
import os
from pathlib import Path
import select
import shutil
import socket
import subprocess
import sys
import threading
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
sys.path.insert(0, str(ROOT / "verification/experiment/ax04b"))
from motor_control_client import Action, Mode, MotorControlClient, RequestError
from irq_timing_analyze import analyze, frame_metrics, load_capture
from run_r5_runtime_test import BSP, local_main


def build_fixture(compiler, output, mode, timing=False):
    firmware = ROOT / "firmware/r5/motor_control/ax04b"
    service = firmware.parent / "ethernet"
    transport = ROOT / "firmware/r5/ethernet"
    generated = ROOT / "generated/experiment/ax04b_r1_01/r5"
    for header in ("ax04b_bsp.h", "xil_cache.h", "xil_exception.h", "xil_io.h",
                   "xil_printf.h", "xparameters.h", "xscugic.h"):
        (output / header).write_text(BSP, encoding="utf-8")
    main = local_main((firmware / "ax04b_main.c").read_text(encoding="utf-8"))
    (output / "ax04b_main_host.inc").write_text(main, encoding="utf-8")
    binary = output / f"motor_control_{mode}{'_timing' if timing else ''}.dll"
    files = [Path(__file__).with_name("motor_control_ethernet_fixture.c"),
             firmware / "ax04b_adapter.c", service / "motor_control_ethernet.c",
             transport / "eth_service.c",
             *sorted(generated.glob("*.c"))]
    if timing:
        files.append(firmware / "ax04b_timing.c")
    env = dict(os.environ)
    if Path(compiler).is_absolute():
        env["PATH"] = str(Path(compiler).parent) + os.pathsep + env["PATH"]
    exports = ["-Wl,--export-all-symbols"] if os.name == "nt" else []
    subprocess.run([compiler, "-std=c11", "-DAX05A_ONLINE=1", "-DMOTOR_CONTROL_ETHERNET=1",
                    *(["-DAX04B_TIMING=1", "-DXPAR_CPU_CORE_CLOCK_FREQ_HZ=499994995u"] if timing else []),
                    f"-DAX04B_BUILD_MODE={mode}", "-DAX04B_APPLICATION_ID=0x41585205u",
                    "-O2", "-Wall", "-Wextra", "-Werror", "-Wno-unused-function",
                    "-fno-fast-math", "-ffp-contract=off", "-shared", *exports,
                    *(f"-I{folder}" for folder in (output, firmware, service, transport, generated,
                                                  ROOT / "integration/r5_ethernet")),
                    *map(str, files), "-lm", "-o", str(binary)], check=True, env=env)
    return ctypes.CDLL(str(binary))


class Loopback:
    """TCP on localhost. The C firmware owns stream framing and command execution."""

    def __init__(self, fixture):
        self.c = fixture
        self.reply_hook = None
        self.c.EthRxTryPush.argtypes = (ctypes.c_char_p, ctypes.c_size_t)
        self.c.EthRxTakeCredit.restype = ctypes.c_size_t
        self.c.EthTxPeek.argtypes = (ctypes.POINTER(ctypes.c_size_t),)
        self.c.EthTxPeek.restype = ctypes.c_void_p
        self.c.EthTxConsume.argtypes = (ctypes.c_size_t,)
        self.lock = threading.Lock()
        self.listener = socket.socket()
        self.listener.bind(("127.0.0.1", 0))
        self.listener.listen()
        self.listener.settimeout(0.1)
        self.port = self.listener.getsockname()[1]
        self.done = threading.Event()
        self.error = None
        self.c.fixture_boot()

    def __enter__(self):
        self.thread = threading.Thread(target=self.serve)
        self.thread.start()
        return self

    def __exit__(self, *_):
        self.done.set()
        self.thread.join(5)
        self.listener.close()
        if self.thread.is_alive():
            raise TimeoutError("loopback server did not stop")
        if self.error:
            raise self.error

    def serve(self):
        try:
            while not self.done.is_set():
                try:
                    connection, _ = self.listener.accept()
                except TimeoutError:
                    continue
                with connection:
                    connection.settimeout(3)
                    with self.lock:
                        self.c.EthSessionReset()
                    while data := connection.recv(53):
                        with self.lock:
                            assert self.c.EthRxTryPush(data, len(data)) == 0
                            while (progress := self.c.EthNetService()) > 0:
                                assert self.c.EthRxTakeCredit() > 0
                                count = ctypes.c_size_t()
                                pointer = self.c.EthTxPeek(ctypes.byref(count))
                                packet = ctypes.string_at(pointer, count.value)
                                if self.reply_hook is not None and self.reply_hook(packet) is False:
                                    return
                                connection.sendall(packet[:7])
                                self.c.EthTxConsume(7)
                                connection.sendall(packet[7:])
                                self.c.EthTxConsume(count.value - 7)
                            assert progress == 0
        except Exception as error:
            self.error = error

    def client(self):
        return MotorControlClient("127.0.0.1", self.port)

    def advance(self, frames, now_ms):
        with self.lock:
            self.c.fixture_advance(frames, now_ms)

class MotorControlNetworkTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not hasattr(cls, "compiler"):
            cls.compiler = shutil.which("gcc")
            if cls.compiler is None:
                raise unittest.SkipTest("native GCC is needed for the R5 host fixture")
            cls.output = ROOT / ".runtime/experiment/motor_control_gem3" / uuid.uuid4().hex
            cls.output.mkdir(parents=True)

    def test_stream_commands_and_trace(self):
        with Loopback(build_fixture(self.compiler, self.output, 1)) as board:
            with socket.create_connection(("127.0.0.1", board.port), timeout=3) as raw:
                raw.sendall(b"1 vers")
                self.assertEqual(select.select([raw], [], [], .03)[0], [])
                raw.sendall(b"ion\r\n2 invalid\n")
                with raw.makefile("rb") as replies:
                    self.assertEqual(json.loads(replies.readline())["hardware_profile"], 1)
                    self.assertEqual(json.loads(replies.readline()), {"id": 2, "error": "BAD_REQUEST"})
            with board.client() as client:
                identity = client.request("version")
                self.assertEqual((identity["id"], identity["protocol"], identity["application_id"]),
                                 (1, 1, 0x41585205))
                sample = client.sample()
                self.assertEqual(sample["groups"], 15)
                self.assertEqual([sample[key] for key in ("ia_a", "ib_a", "ic_a", "id_a",
                                 "iq_a", "ud_v", "uq_v", "id_ref_a", "iq_ref_a")],
                                 [-1, .5, .5, .5, -.5, 8, -10, .25, -.125])
                self.assertEqual((sample["offset_a_counts"], sample["offset_b_counts"]), (2048.5, 2080))
                self.assertTrue(sample["position_valid"] and sample["speed_valid"])
                self.assertEqual((sample["position_mm"], sample["alignment_state"], sample["fault"]), (1, 0, 0))
                diag = client.request("diagnostics")
                self.assertEqual(len(diag["words"]), 80)
                self.assertEqual(diag["pwm_compare"], [1000, 2500, 4000])
                selected = client.command(Action.SELECT, Mode.CURRENT, iq_a=.125)
                revision = selected["accepted_revision"]
                self.assertEqual(selected["decision"], 0)
                self.assertFalse(client.request("status")["selection_confirmed"])
                self.assertEqual(client.sample()["sample_id"], sample["sample_id"])
                confirmed = client.command(Action.CONFIRM, Mode.CURRENT, revision)
                self.assertEqual(confirmed["decision"], 0)
                self.assertEqual(confirmed["firmware_request_id"], selected["firmware_request_id"] + 1)
                self.assertTrue(client.request("status")["selection_confirmed"])
                cleared = client.command(Action.CLEAR)
                self.assertEqual(cleared["firmware_request_id"], confirmed["firmware_request_id"] + 1)
                self.assertEqual(cleared["decision"], 0)
                board.advance(1, 1)
                self.assertEqual(client.command(Action.ARM, Mode.CURRENT, revision)["decision"], 0)
                board.advance(1, 2)
                self.assertEqual(client.command(Action.START, Mode.CURRENT, revision)["decision"], 0)
                board.advance(3, 3)
                running = client.sample()
                self.assertEqual(running["mode"], Mode.CURRENT)
                self.assertTrue(running["commit_accepted"])
                self.assertTrue(running["p0_valid"])
                self.assertEqual(client.command(Action.SETPOINT, Mode.CURRENT, revision,
                                                iq_a=1.0)["decision"], 2)
                capture = client.request("trace-start", 15)
                for time_ms in (4, 6, 8, 10, 12):
                    board.advance(20, time_ms)
                with self.assertRaisesRegex(RequestError, "TRACE_UNAVAILABLE"):
                    client.request("trace-read", capture["capture_id"], 0)
            # Reconnection restarts the PC ID. Firmware command IDs and trace survive.
            with board.client() as reconnected:
                resumed = reconnected.request("status")
                self.assertEqual(resumed["id"], 1)
                self.assertTrue(resumed["armed"])
                snapshot = reconnected.request("trace-stop")
                self.assertEqual(snapshot["count"], 5)
                self.assertEqual(snapshot["missed"], 76)
                self.assertEqual(snapshot["duplicates"], 0)
                self.assertFalse(snapshot["discontinuous"])
                path = self.output / "experiment.ndjson"
                reconnected.download(path)
                records = [json.loads(line) for line in path.read_text().splitlines()]
                self.assertEqual(records[0]["capture"]["capture_id"], capture["capture_id"])
                self.assertEqual(len(records), 6)
                self.assertTrue(all(record["groups"] == 15 for record in records[1:]))
                self.assertEqual([b["tick"] - a["tick"] for a, b in zip(records[1:], records[2:])],
                                 [100000] * 4)
                stopped = reconnected.command(Action.STOP)
                self.assertFalse(stopped["armed"])
                self.assertGreater(stopped["firmware_request_id"], cleared["firmware_request_id"])
                again = reconnected.command(Action.SELECT, Mode.SPEED)
                self.assertEqual(again["firmware_request_id"], stopped["firmware_request_id"] + 1)

    def test_real_calibrates_and_rejects_running_commands(self):
        with Loopback(build_fixture(self.compiler, self.output, 2)) as board, board.client() as client:
            self.assertEqual(client.request("version")["hardware_profile"], 2)
            self.assertEqual(client.request("diagnostics")["rt_ctrl_enable"], 0)
            self.assertEqual(client.command(Action.CALIBRATE)["decision"], 4)
            for gains in ((0, 65536), (65536, -2147483649)):
                with self.assertRaisesRegex(RequestError, "BAD_GAINS"):
                    client.request("calibration-gains", *gains)
            self.assertEqual(client.command(Action.CALIBRATE)["decision"], 4)
            self.assertTrue(client.request("calibration-gains", -65536, 65536)["staged"])
            self.assertEqual(client.request("diagnostics")["rt_ctrl_enable"], 0)
            self.assertEqual(client.command(Action.CALIBRATE)["decision"], 0)
            self.assertEqual(client.request("diagnostics")["rt_ctrl_enable"], 1)
            board.advance(1, 2)
            for action in (Action.ARM, Action.START, Action.SETPOINT, Action.ALIGN_START, Action.DRIVER_RESET):
                self.assertEqual(client.command(action, Mode.CURRENT)["decision"], 5)
            self.assertFalse(client.request("status")["armed"])
            self.assertEqual(client.command(Action.STOP)["decision"], 0)
            self.assertEqual(client.request("diagnostics")["rt_ctrl_enable"], 0)

    def test_timing_window_and_trace_ownership(self):
        fixture = build_fixture(self.compiler, self.output, 1, timing=True)
        fixture.fixture_check_timing_math()
        with Loopback(fixture) as board:
            with board.client() as client:
                self.assertEqual(client.request("version")["timing_schema"], 2)
                revision = client.command(Action.SELECT, Mode.CURRENT)["accepted_revision"]
                self.assertEqual(client.command(Action.CONFIRM, Mode.CURRENT, revision)["decision"], 0)
                self.assertEqual(client.command(Action.CLEAR)["decision"], 0)
                board.advance(1, 1)
                self.assertEqual(client.command(Action.ARM, Mode.CURRENT, revision)["decision"], 0)
                self.assertEqual(client.command(Action.START, Mode.CURRENT, revision)["decision"], 0)
                board.advance(5, 2)
                self.assertTrue(client.sample()["commit_accepted"])
                client.request("trace-start", 15)
                with self.assertRaisesRegex(RequestError, "TRACE_BUSY"):
                    client.request("timing-start", 0, 30, 1)
                summary = client.request("timing-start", 0, 1, 0)
                board.advance(11, 4)
                self.assertTrue(client.request("trace-status")["active"])
                self.assertEqual(client.request("timing-status")["capture_id"], summary["capture_id"])
                client.request("trace-stop")
                capture = client.request("timing-start", 2, 30, 1)
                board.advance(20, 6)
                self.assertTrue(client.request("timing-status")["active"])
                with self.assertRaisesRegex(RequestError, "TRACE_UNAVAILABLE"):
                    client.request("timing-read", capture["capture_id"], 0)
            board.advance(301, 36)
            with board.client() as client:
                info = client.request("timing-status")
                self.assertEqual((info["frames"], info["valid"], info["applied"]), (300, 300, 300))
                self.assertEqual((info["end_reason"], info["planned_frames"]), ("elapsed", 300))
                self.assertEqual((info["receipt_errors"], info["receipt_unresolved"], info["missing"]), (0, 0, 0))
                self.assertEqual(info["count"], 256)
                self.assertFalse(info["active"])
                self.assertFalse(client.command(Action.STOP)["armed"])
                with self.assertRaisesRegex(RequestError, "TRACE_BUSY"):
                    client.request("trace-start", 15)
                path = self.output / "timing.ndjson"
                client.timing_download(path)
                meta, *frames = map(json.loads, path.read_text().splitlines())
                self.assertEqual([row["metrics"][1]["count"] for row in meta["rates"]], [270, 27, 3])
                self.assertEqual(len(frames), 256)
                for previous, current in zip(frames, frames[1:]):
                    self.assertTrue(current["applied_coherent"])
                    self.assertEqual((current["applied_version"], current["applied_target"]),
                                     (previous["frame"]["version"], previous["frame"]["target"]))
                report = load_capture(path, "A")
                self.assertEqual(report["stable_timing"], "PASS")
                self.assertEqual(report["detail_scope"]["records"], 256)
                self.assertEqual(report["full_window_bounds"]["minimum_margin_cycles"], 4907)
                self.assertEqual(report["rates"]["base"]["accept_upper"]["detail_p99_us"], 0.02)
                meta["rates"][0]["metrics"][7]["count"] -= 1
                report = analyze(meta["capture"], meta["rates"], meta["evidence"], frames, "A")
                self.assertEqual(report["stable_timing"], "FAIL")
                self.assertIsNone(report["full_window_bounds"])
                client.request("timing-start", 100, 50, 0)
                board.advance(1, 150)
                client.request("timing-stop")
                idle = client.request("timing-status")
                self.assertEqual((idle["end_reason"], idle["planned_frames"]), ("not_started", 500))
                self.assertEqual((idle["frames"], idle["applied"], idle["missing"]), (0, 0, 0))
                idle_path = self.output / "timing-delay-stop.ndjson"
                client.timing_download(idle_path)
                self.assertEqual(load_capture(idle_path, "A")["stable_timing"], "INCOMPLETE")
                self.assertTrue(client.request("trace-start", 15)["active"])

    def test_timing_early_stop_and_events_after_detail_capacity(self):
        output = self.output / "timing_events"
        output.mkdir()
        fixture = build_fixture(self.compiler, output, 1, timing=True)
        with Loopback(fixture) as board, board.client() as client:
            def start_current(now):
                rev = client.command(Action.SELECT, Mode.CURRENT)["accepted_revision"]
                self.assertEqual(client.command(Action.CONFIRM, Mode.CURRENT, rev)["decision"], 0)
                self.assertEqual(client.command(Action.CLEAR)["decision"], 0)
                board.advance(1, now)
                self.assertEqual(client.command(Action.ARM, Mode.CURRENT, rev)["decision"], 0)
                self.assertEqual(client.command(Action.START, Mode.CURRENT, rev)["decision"], 0)
                board.advance(5, now + 1)

            start_current(1)
            client.request("timing-start", 0, 1, 0)
            board.advance(10, 3)
            self.assertTrue(client.request("timing-status")["active"])
            client.request("timing-stop")
            partial = client.request("timing-status")
            self.assertEqual(partial["end_reason"], "early_stop")
            self.assertEqual((partial["frames"], partial["planned_frames"], partial["applied"]), (10, 10, 9))
            self.assertEqual((partial["missing"], partial["receipt_unresolved"]), (0, 1))
            path = output / "early.ndjson"
            client.timing_download(path)
            self.assertEqual(load_capture(path, "A")["stable_timing"], "INCOMPLETE")

            client.request("timing-start", 0, 5, 0)
            board.advance(5, 4)
            client.request("timing-stop")
            partial = client.request("timing-status")
            self.assertEqual((partial["frames"], partial["planned_frames"], partial["missing"]), (5, 50, 0))
            self.assertEqual(partial["end_reason"], "early_stop")

            capture = client.request("timing-start", 0, 1, 0)
            board.advance(10, 5)
            # Cancel the last accepted packet before the drain IRQ reads its P0 receipt.
            client.command(Action.STOP)
            board.advance(1, 6)
            wrong_receipt = client.request("timing-status")
            self.assertEqual(wrong_receipt["end_reason"], "elapsed")
            self.assertEqual((wrong_receipt["frames"], wrong_receipt["applied"]), (10, 9))
            self.assertEqual((wrong_receipt["receipt_errors"], wrong_receipt["receipt_unresolved"]), (1, 0))
            receipt = client.request("timing-evidence", capture["capture_id"])["first_anomaly"]
            self.assertEqual(receipt["events"], 2)
            self.assertEqual(receipt["expected_version"], wrong_receipt["last"]["version"])
            self.assertEqual(receipt["expected_target"], wrong_receipt["last"]["target"])
            path = output / "missing-final-receipt.ndjson"
            client.timing_download(path)
            self.assertEqual(load_capture(path, "A")["stable_timing"], "FAIL")

            start_current(7)
            capture = client.request("timing-start", 0, 30, 1)
            board.advance(260, 30)
            self.assertFalse(client.command(Action.STOP)["armed"])
            board.advance(41, 35)
            stop = client.request("timing-evidence", capture["capture_id"])["transition_peak"]
            self.assertEqual(stop["frame"]["stop_reason"], 1)  # AX04B_STOP_REQUEST
            self.assertTrue(stop["events"] & 512)
            self.assertTrue(stop["ack_done_valid"])
            path = output / "stop-after-capacity.ndjson"
            client.timing_download(path)
            report = load_capture(path, "D")
            self.assertEqual(report["stable_timing"], "NOT_APPLICABLE")
            self.assertEqual(report["capture"]["valid"], 260)
            self.assertIsNone(report["full_window_bounds"])
            self.assertGreater(stop["frame"]["pl_tick"], report["detail_scope"]["last"]["pl_tick"])

            start_current(36)
            client.request("timing-start", 0, 30, 1)
            board.advance(260, 64)
            fixture.fixture_reject_late()
            board.advance(41, 70)
            path = output / "reject-after-capacity.ndjson"
            client.timing_download(path)
            report = load_capture(path, "C")
            capture = report["capture"]
            self.assertEqual((capture["frames"], capture["valid"], capture["rejects"]), (300, 260, 1))
            self.assertEqual(capture["late_or_target"], 1)
            self.assertEqual(report["stable_timing"], "FAIL")
            events = report["exceptional_irqs"]
            reject = events["first_anomaly"]["raw"]
            self.assertEqual(reject["frame"]["result"], 2)
            self.assertGreater(reject["frame"]["pl_tick"], report["detail_scope"]["last"]["pl_tick"])
            self.assertTrue(reject["attempted"] and not reject["accepted"] and reject["safety_reentry"])
            self.assertEqual(reject["before_id"], reject["frame"]["sample_id"])
            self.assertEqual(reject["after_id"], reject["frame"]["sample_id"])
            self.assertNotEqual(reject["accepted_target"], reject["frame"]["target"])
            self.assertEqual(events["anomaly_peak"]["raw"], reject)
            elapsed = events["anomaly_peak"]["durations_us"]
            self.assertGreater(elapsed["irq"], elapsed["submit"])
            self.assertGreater(elapsed["safety_reentry"], 0)
            self.assertNotIn("accept_upper", elapsed)
            self.assertEqual(sum(row["irq"]["count"] for row in report["rates"].values()), 260)

            # Stages absent on an early handler return cannot produce modulo differences.
            omitted = {**reject, "entry": 0xFFFFFFFD, "irq_end": 1,
                       "read_done_valid": False, "ack_done_valid": False, "model_ran": False,
                       "attempted": False, "safety_reentry": False}
            self.assertEqual(frame_metrics(omitted, capture), {"irq": 4})


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cc", default="gcc")
    parser.add_argument("--output", type=Path, required=True)
    parsed, rest = parser.parse_known_args()
    parsed.output.mkdir(parents=True)
    MotorControlNetworkTests.compiler = parsed.cc
    MotorControlNetworkTests.output = parsed.output.resolve()
    unittest.main(argv=[__file__, *rest])
