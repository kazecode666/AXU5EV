"""Exercise actual Studio widgets against the C firmware host loopback."""

import argparse
import csv
import json
import os
from pathlib import Path
import sys
from threading import Event
from time import monotonic
import unittest
from unittest.mock import patch
import uuid

from run_motor_control_studio_demo import native_compiler
from test_motor_control_ethernet import Loopback, ROOT, build_fixture

sys.path.insert(0, str(ROOT))
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

from PySide6.QtGui import QFontDatabase
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QApplication

from scripts.motor_control_client import Action, Mode
from scripts.motor_control_studio.prepare import Candidate
from scripts.motor_control_studio.style import style
from scripts.motor_control_studio.telemetry import SERIES, Timeline, TrendCsv, load_record, measured
from scripts.motor_control_studio.window import Studio


def until(predicate, seconds=5):
    deadline = monotonic() + seconds
    while not predicate():
        if monotonic() >= deadline:
            raise AssertionError("Studio event did not arrive before timeout")
        QTest.qWait(20)


def csv_rows(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


class StudioTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not hasattr(cls, "compiler"):
            cls.compiler = native_compiler()
            if not cls.compiler:
                raise unittest.SkipTest("native GCC is needed for the Studio loopback")
            cls.output = ROOT / ".runtime/studio" / uuid.uuid4().hex
            cls.output.mkdir(parents=True)
        cls.app = QApplication.instance() or QApplication([])
        # The Qt offscreen platform on Windows has no system font fallback.
        font = Path("C:/Windows/Fonts/msyh.ttc")
        if cls.app.platformName() == "offscreen" and font.is_file():
            QFontDatabase.addApplicationFont(str(font))
        style(cls.app)

    def setup_window(self, board):
        window = Studio("127.0.0.1", board.port, demo_port=board.port)
        window.show()
        self.addCleanup(self.close_window, window)
        self.assertIsNone(window.worker)
        self.assertFalse(window.actions[Action.STOP].isEnabled())
        window.connect_button.click()
        until(lambda: window.control and window.latest)
        return window

    def close_window(self, window):
        window.close()
        until(lambda: window.worker is None)

    def action(self, window, action, decision="ACCEPTED"):
        self.assertTrue(window.actions[action].isEnabled(), action)
        window.actions[action].click()
        until(lambda: window.receipt.text().startswith(f"{action.name} · {decision}"))

    def test_selftest_widgets_and_stop_during_download(self):
        with Loopback(build_fixture(self.compiler, self.output, 1)) as board:
            responded = []
            first_batch = Event()
            release = Event()

            def watch(packet):
                data = json.loads(packet)
                responded.append(data)
                if "records" in data and not first_batch.is_set():
                    first_batch.set()
                    release.wait(.9)

            board.reply_hook = watch
            window = self.setup_window(board)
            try:
                self.assertIn("离线回环", window.identity_line.text())
                self.assertEqual(window.identity["hardware_profile"], 1)
                self.assertFalse(window.control["armed"])
                self.assertFalse(any("decision" in reply for reply in responded))
                window.mode.setCurrentIndex(Mode.CURRENT)
                window.refs["iq_a"].setValue(.1)
                self.action(window, Action.SELECT)
                self.action(window, Action.CONFIRM)
                self.action(window, Action.CLEAR)
                board.advance(1, 1)
                until(lambda: window.control.get("clear_confirmed"))
                self.action(window, Action.ARM)
                board.advance(1, 2)
                self.action(window, Action.START)
                board.advance(3, 4)
                until(lambda: window.latest.get("mode") == Mode.CURRENT)
                window.refs["iq_a"].setValue(.12)
                self.action(window, Action.SETPOINT)
                board.advance(5, 6)
                until(lambda: window.latest.get("commit_accepted") and "P0" in window.frame_receipt.text())
                self.assertIn("模型消费版本", window.frame_receipt.text())
                until(lambda: window.charts.curves["ia_a"].xData is not None
                      and len(window.charts.curves["ia_a"].xData) > 1)
                self.assertTrue(window.grab().save(str(self.output / "studio_selftest.png")))

                drawn = window.charts.curves["ia_a"].xData.copy()
                before = window.latest["sample_id"]
                trend_path = self.output / "motor_control_SELFTEST_trend.csv"
                with patch("scripts.motor_control_studio.window.QFileDialog.getSaveFileName",
                           return_value=(str(trend_path), "CSV (*.csv)")) as dialog:
                    window.start_trend_button.click()
                    self.assertIn("motor_control_SELFTEST_trend_", dialog.call_args.args[2])
                self.assertTrue(window.stop_trend_button.isEnabled())
                window.pause_draw.setChecked(True)
                board.advance(20, 8)
                until(lambda: window.latest["sample_id"] != before)
                paused_sample = window.latest
                self.assertGreater(window.trend_file.count, 0)
                self.assertEqual(window.charts.curves["ia_a"].xData.tolist(), drawn.tolist())
                window.pause_draw.setChecked(False)
                until(lambda: len(window.charts.curves["ia_a"].xData) > len(drawn))

                window.tabs.setCurrentIndex(2)
                window.diagnostics.read.click()
                until(lambda: window.diagnostics.raw.rowCount() == 80)
                self.assertGreaterEqual(window.diagnostics.summary.rowCount(), 12)
                window.tabs.setCurrentIndex(1)
                window.records.start.click()
                until(lambda: window.records.info.get("active"))
                for t in range(10, 22, 2):
                    board.advance(20, t)
                window.records.freeze.click()
                until(lambda: window.records.download.isEnabled())
                path = self.output / "studio_capture.ndjson"
                window.records.begin_download(path)
                until(first_batch.is_set)
                window.actions[Action.STOP].click()
                release.set()
                until(lambda: window.receipt.text().startswith("STOP · ACCEPTED"))
                first = next(i for i, reply in enumerate(responded) if "records" in reply)
                self.assertIn("decision", responded[first + 1])
                until(lambda: not window.records.downloading)
                self.assertIsNotNone(window.records.loaded, window.notice.text())
                info, samples = load_record(path)
                self.assertEqual(info["count"], 6)
                self.assertEqual(samples[1]["tick"] - samples[0]["tick"], 100_000)
                output = self.output / "studio_capture.csv"
                window.records.export_record(output)
                data = csv_rows(output)
                self.assertEqual(len(data), len(samples))
                self.assertEqual(int(data[0]["sample_id"]), samples[0]["sample_id"])
                self.assertTrue(window.stop_trend_button.isEnabled())
                window.tabs.setCurrentIndex(0)
                window.stop_trend_button.click()
                self.assertIsNone(window.trend_file)
                trend_rows = csv_rows(trend_path)
                self.assertTrue(any(
                    int(row["pl_tick [50 MHz ticks]"]) == paused_sample["tick"]
                    and int(row["sample_id"]) == paused_sample["sample_id"]
                    and int(row["groups"]) == paused_sample["groups"]
                    for row in trend_rows
                ))
                before = window.latest["sample_id"]
                board.advance(20, 24)
                until(lambda: window.latest["sample_id"] != before)
                self.assertEqual(csv_rows(trend_path), trend_rows)
                window.disconnect_button.click()
                until(lambda: window.worker is None)
                self.assertIsNone(window.timeline.rows[-1][1])
                before = sum("decision" in reply for reply in responded)
                window.connect_button.click()
                until(lambda: window.control and window.latest)
                self.assertEqual(sum("decision" in reply for reply in responded), before)
                self.assertFalse(window.control["armed"])
            finally:
                release.set()
                self.close_window(window)

    def test_real_widgets_calibrate_without_motion(self):
        with Loopback(build_fixture(self.compiler, self.output, 2)) as board:
            window = self.setup_window(board)
            try:
                self.assertIn("功率硬禁", window.profile_badge.text())
                self.assertFalse(window.latest["groups"] & (4 | 8))
                window.mode.setCurrentIndex(Mode.CURRENT)
                for action in (Action.ARM, Action.START, Action.SETPOINT, Action.ALIGN_START, Action.DRIVER_RESET):
                    self.assertFalse(window.actions[action].isEnabled())
                self.action(window, Action.CALIBRATE, "NOT_READY")
                window.gain_a.setText("-65536")
                window.gain_b.setText("65536")
                window.gain_button.click()
                until(lambda: "已暂存" in window.notice.text())
                self.action(window, Action.CALIBRATE)
                self.assertFalse(window.control["armed"])
                close_path = self.output / "motor_control_REAL_IO_close_trend.csv"
                window.begin_trend(close_path)
                until(lambda: window.trend_file.count > 0)
                self.close_window(window)
                self.assertIsNone(window.trend_file)
                closed = csv_rows(close_path)
                self.assertTrue(closed)
                self.assertTrue(all(row["ud_v [V]"] == "" and row["ud_v_valid"] == "0" for row in closed))

                window = self.setup_window(board)
                loss_path = self.output / "motor_control_REAL_IO_disconnect_trend.csv"
                window.begin_trend(loss_path)
                until(lambda: window.trend_file.count > 0)
                board.reply_hook = lambda _: False
                until(lambda: window.worker is None)
                self.assertIsNone(window.trend_file)
                self.assertFalse(window.stop_trend_button.isEnabled())
                self.assertTrue(csv_rows(loss_path))
            finally:
                self.close_window(window)

    def test_live_window_switch_preserves_history_when_paused(self):
        window = Studio()
        self.addCleanup(self.close_window, window)
        self.assertEqual(window.trend_window.currentData(), 20)
        for tenth in range(751):
            window.timeline.append({"tick": tenth * 5_000_000})
        window.draw_trend()
        retained = window.charts.curves["ia_a"].xData.copy()
        self.assertAlmostEqual(retained[0], 15)
        window.pause_draw.setChecked(True)
        window.timeline.append({"tick": 3_800_000_000})
        for seconds in (10, 60, 20):
            window.trend_window.setCurrentIndex(window.trend_window.findData(seconds))
            for plot in window.charts.plots:
                left, right = plot.getViewBox().viewRange()[0]
                self.assertAlmostEqual(right, 75)
                self.assertAlmostEqual(right - left, seconds)
            self.assertEqual(window.charts.curves["ia_a"].xData.tolist(), retained.tolist())

    def test_validity_and_tick_gaps(self):
        timeline = Timeline(frequency=50_000_000)
        ia = SERIES[0]
        sample = {"tick": (1 << 64) - 10, "groups": 2, "current_valid": True, "ia_a": 2.0}
        timeline.append(sample)
        timeline.append({**sample, "tick": 4990, "groups": 0})
        self.assertAlmostEqual(timeline.rows[-1][0], .0001)
        self.assertIsNone(measured(timeline.rows[-1][1], ia))
        timeline.interrupt()
        timeline.append({**sample, "tick": 9990, "current_valid": False})
        self.assertIsNone(timeline.rows[-2][1])
        self.assertIsNone(measured(timeline.rows[-1][1], ia))
        self.assertIsNone(measured({**sample, "ia_a": None}, ia))

        path = self.output / "motor_control_sample_validity.csv"
        recording = TrendCsv(path)
        recording.append({**sample, "sample_id": 4_294_967_295, "groups": 11,
                          "id_a": 0, "id_ref_a": .5, "ud_v": 8,
                          "position_mm": 0, "speed_mm_s": -2,
                          "position_valid": False, "speed_valid": True})
        recording.close()
        row, = csv_rows(path)
        self.assertEqual(int(row["pl_tick [50 MHz ticks]"]), sample["tick"])
        self.assertEqual(row["sample_id"], "4294967295")
        self.assertEqual(row["groups"], "11")
        self.assertEqual(row["position_valid"], "0")
        self.assertEqual((row["id_a [A]"], row["id_a_valid"]), ("0", "1"))
        self.assertEqual((row["id_ref_a [A]"], row["id_ref_a_valid"]), ("", "0"))
        self.assertEqual((row["ib_a [A]"], row["ib_a_valid"]), ("", "0"))
        self.assertEqual((row["position_mm [mm]"], row["position_mm_valid"]), ("", "0"))
        self.assertEqual(row["ud_v [V]"], "8")
        self.assertEqual(row["speed_mm_s [mm/s]"], "-2")

    def test_preparation_script_offline(self):
        from tkinter import Tcl

        for profile in ("SELFTEST", "REAL"):
            with self.subTest(profile=profile):
                candidate = Candidate.load(profile)
                path = self.output / f"prepare_{profile}.tcl"
                candidate.save_xsdb(path)
                tcl = Tcl()
                tcl.eval("set calls {}; rename source real_source; rename puts real_puts")
                for name in ("targets", "fpga", "source", "puts", "psu_ps_pl_isolation_removal",
                             "psu_ps_pl_reset_config"):
                    tcl.eval(f"proc {name} {{args}} {{lappend ::calls [linsert $args 0 {name}]}}")
                tcl.eval(path.read_text(encoding="utf-8"))
                calls = [tcl.splitlist(call) for call in tcl.splitlist(tcl.eval("set calls"))]
                self.assertEqual([call[0] for call in calls],
                                 ["targets", "fpga", "targets", "source", "psu_ps_pl_isolation_removal",
                                  "psu_ps_pl_reset_config", "targets", "puts"])
                self.assertEqual(calls[1][-1], candidate.bit.as_posix())
                self.assertEqual(calls[3][-1], candidate.psu_init.as_posix())

                launch_config = json.loads(candidate.config.read_text(encoding="utf-8"))
                launch = next(option for option in launch_config["configurations"]
                              if option["name"] == candidate.launch)
                setup = launch["targetSetup"]
                fsbl = setup["zuInitialization"]["usingFSBL"]
                files = ((setup["downloadElf"][0], "elfFile"), (fsbl, "fsblFile"))
                read_text = Path.read_text

                def read_launch_config(path, *args, **kwargs):
                    if path == candidate.config:
                        return json.dumps(launch_config)
                    return read_text(path, *args, **kwargs)

                with patch.object(Path, "read_text", read_launch_config):
                    for separator in ("/", "\\"):
                        with self.subTest(separator=separator):
                            for entry, field in files:
                                entry[field] = entry[field].replace("\\", "/").replace("/", separator)
                            self.assertEqual(Candidate.load(profile), candidate)

                    for entry, field in files:
                        with self.subTest(wrong_file=field):
                            original = entry[field]
                            entry[field] = original.rsplit("\\", 1)[0] + r"\different.elf"
                            with self.assertRaises(ValueError):
                                Candidate.load(profile)
                            entry[field] = original


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cc", default=native_compiler())
    parser.add_argument("--output", type=Path, required=True)
    args, rest = parser.parse_known_args()
    if not args.cc:
        parser.error("provide native GCC via --cc")
    args.output.mkdir(parents=True)
    StudioTests.compiler = args.cc
    StudioTests.output = args.output.resolve()
    unittest.main(argv=[__file__, *rest])
