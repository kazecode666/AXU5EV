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
from run_r5_runtime_test import BSP, local_main


def build_fixture(compiler, output, mode):
    firmware = ROOT / "firmware/r5/motor_control/ax04b"
    service = firmware.parent / "ethernet"
    transport = ROOT / "firmware/r5/ethernet"
    generated = ROOT / "generated/experiment/ax04b_r1_01/r5"
    for header in ("ax04b_bsp.h", "xil_cache.h", "xil_exception.h", "xil_io.h",
                   "xil_printf.h", "xparameters.h", "xscugic.h"):
        (output / header).write_text(BSP, encoding="utf-8")
    main = local_main((firmware / "ax04b_main.c").read_text(encoding="utf-8"))
    (output / "ax04b_main_host.inc").write_text(main, encoding="utf-8")
    binary = output / f"motor_control_{mode}.dll"
    files = [Path(__file__).with_name("motor_control_ethernet_fixture.c"),
             firmware / "ax04b_adapter.c", service / "motor_control_ethernet.c",
             transport / "eth_service.c",
             *sorted(generated.glob("*.c"))]
    env = dict(os.environ)
    if Path(compiler).is_absolute():
        env["PATH"] = str(Path(compiler).parent) + os.pathsep + env["PATH"]
    exports = ["-Wl,--export-all-symbols"] if os.name == "nt" else []
    subprocess.run([compiler, "-std=c11", "-DAX05A_ONLINE=1", "-DMOTOR_CONTROL_ETHERNET=1",
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
            self.assertEqual(client.command(Action.CALIBRATE)["decision"], 4)
            for gains in ((0, 65536), (65536, -2147483649)):
                with self.assertRaisesRegex(RequestError, "BAD_GAINS"):
                    client.request("calibration-gains", *gains)
            self.assertEqual(client.command(Action.CALIBRATE)["decision"], 4)
            self.assertTrue(client.request("calibration-gains", -65536, 65536)["staged"])
            self.assertEqual(client.command(Action.CALIBRATE)["decision"], 0)
            board.advance(1, 2)
            for action in (Action.ARM, Action.START, Action.SETPOINT, Action.ALIGN_START, Action.DRIVER_RESET):
                self.assertEqual(client.command(action, Mode.CURRENT)["decision"], 5)
            self.assertFalse(client.request("status")["armed"])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cc", default="gcc")
    parser.add_argument("--output", type=Path, required=True)
    parsed, rest = parser.parse_known_args()
    parsed.output.mkdir(parents=True)
    MotorControlNetworkTests.compiler = parsed.cc
    MotorControlNetworkTests.output = parsed.output.resolve()
    unittest.main(argv=[__file__, *rest])
