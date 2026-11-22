"""Display units and file handling for the existing GEM3 schema."""

import csv
import json
import math
from collections import deque
from itertools import islice

TICK_HZ = 50_000_000
TICK_MASK = (1 << 64) - 1
PROFILES = {1: "SELFTEST · 内部自测 · 无功率", 2: "REAL IO · 实际输入 · 功率硬禁"}

# label, field, validity group, optional quality flag, color
PANELS = (
    ("三相电流", "A", (
        ("Ia", "ia_a", 2, "current_valid", "#49d7c8"),
        ("Ib", "ib_a", 2, "current_valid", "#f3b96b"),
        ("Ic", "ic_a", 2, "current_valid", "#a99af3"),
    )),
    ("dq 电流", "A", (
        ("Id", "id_a", 8, None, "#49d7c8"),
        ("Iq", "iq_a", 8, None, "#83adfa"),
        ("Id 参考", "id_ref_a", 4, None, "#f3b96b"),
        ("Iq 参考", "iq_ref_a", 4, None, "#a99af3"),
    )),
    ("位置", "mm", (
        ("实际", "position_mm", 1, "position_valid", "#49d7c8"),
        ("参考", "position_ref_mm", 1, "position_valid", "#f3b96b"),
    )),
    ("速度", "mm/s", (
        ("实际", "speed_mm_s", 1, "speed_valid", "#49d7c8"),
        ("参考", "speed_ref_mm_s", 1, "speed_valid", "#f3b96b"),
    )),
    ("控制器计算电压（非端电压）", "V", (
        ("Ud", "ud_v", 8, None, "#49d7c8"),
        ("Uq", "uq_v", 8, None, "#83adfa"),
    )),
)
SERIES = tuple(line for _, _, lines in PANELS for line in lines)


def measured(sample, series):
    _, field, group, flag, _ = series
    if not sample or not sample.get("groups", 0) & group or (flag and not sample.get(flag)):
        return None
    value = sample.get(field)
    return value if isinstance(value, (int, float)) and math.isfinite(value) else None


class Timeline:
    """Keep integer tick differences until conversion to seconds."""

    def __init__(self, frequency=TICK_HZ, window=None, gap=0.35):
        self.frequency = frequency
        self.window = window
        self.gap = gap
        self.rows = deque(maxlen=1000)
        self.elapsed = 0.0
        self.last_tick = None

    def interrupt(self):
        if self.rows and self.rows[-1][1] is not None:
            self.rows.append((self.elapsed, None))

    def append(self, sample):
        tick = sample["tick"]
        if self.last_tick is not None:
            delta = (tick - self.last_tick) & TICK_MASK
            if not delta:
                return
            if delta > TICK_MASK // 2:
                self.rows.clear()
                self.elapsed = 0.0
            else:
                seconds = delta / self.frequency
                if seconds > self.gap:
                    self.interrupt()
                self.elapsed += seconds
        self.rows.append((self.elapsed, sample))
        self.last_tick = tick
        if self.window is not None:
            while self.rows[0][0] < self.elapsed - self.window:
                self.rows.popleft()


def load_record(path):
    with path.open(encoding="utf-8-sig") as stream:
        try:
            info = json.loads(next(stream))["capture"]
            rows = [json.loads(line) for line in islice(stream, 257)]
            if (not 0 <= info["count"] <= 256 or len(rows) != info["count"]
                    or info["pl_ticks_hz"] <= 0 or type(info["capture_id"]) is not int):
                raise ValueError("记录数量或 PL 时基无效")
            for row in rows:
                if (any(type(row.get(key)) is not int for key in ("tick", "sample_id", "groups"))
                        or not 0 <= row["tick"] <= TICK_MASK or not 0 <= row["sample_id"] < 2**32
                        or not 0 <= row["groups"] <= 15):
                    raise ValueError("采样身份或有效组无效")
        except (AttributeError, KeyError, StopIteration, TypeError) as error:
            raise ValueError("缺少记录元数据或采样字段") from error
    return info, rows


def export_csv(path, info, rows):
    fields = ("capture_id", "tick", "sample_id", "groups", "elapsed_s",
              "current_valid", "position_valid", "speed_valid", *(line[1] for line in SERIES))
    with path.open("w", encoding="utf-8-sig", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(fields)
        for row in rows:
            elapsed = ((row["tick"] - rows[0]["tick"]) & TICK_MASK) / info["pl_ticks_hz"]
            writer.writerow((info["capture_id"], row["tick"], row["sample_id"], row["groups"], elapsed,
                             *(row.get(flag) for flag in fields[5:8]),
                             *(measured(row, line) for line in SERIES)))
