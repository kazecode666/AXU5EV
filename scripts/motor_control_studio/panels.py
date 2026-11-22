"""Recording, low-rate diagnostics, and candidate preparation tabs."""

from pathlib import Path

from PySide6.QtWidgets import (
    QCheckBox, QComboBox, QFileDialog, QHBoxLayout, QHeaderView, QLabel, QPlainTextEdit,
    QProgressBar, QPushButton, QTableWidget, QTableWidgetItem, QVBoxLayout, QWidget,
)

from .charts import Charts
from .prepare import Candidate, tcl_path
from .telemetry import PROFILES, Timeline, export_csv, load_record


def button(text, clicked, name=""):
    item = QPushButton(text)
    item.setObjectName(name)
    item.clicked.connect(clicked)
    return item


def label(text="", name="muted"):
    item = QLabel(text)
    item.setObjectName(name)
    item.setWordWrap(True)
    return item


def capture_summary(data):
    if not data.get("schema"):
        return "尚无捕获记录"
    state = "采集中" if data.get("active") else "已冻结"
    if data.get("full"):
        state += " · 已满"
    if data.get("discontinuous"):
        state += " · 帧身份不连续"
    return (f"捕获 {data.get('capture_id', '—')} ｜{state} ｜{data['count']} / 256 条 ｜"
            f"跳过 {data.get('missed', '—')} ｜重复 {data.get('duplicates', '—')}")


class Records(QWidget):
    def __init__(self, send, report):
        super().__init__()
        self.send, self.report = send, report
        self.saved_file = None
        self.loaded = None
        self.connected = False
        self.downloading = False
        self.info = {}
        layout = QVBoxLayout(self)
        layout.addWidget(label("固件记录 · 256 条，每至少 2 ms 尝试取最近帧"))
        controls = QHBoxLayout()
        self.start = button("开始记录", lambda: send("request", "trace-start", 15))
        self.refresh = button("读取状态", lambda: send("request", "trace-status"))
        self.freeze = button("冻结记录", lambda: send("request", "trace-stop"))
        self.download = button("下载 NDJSON", self.choose_download, "primary")
        for widget in (self.start, self.refresh, self.freeze, self.download):
            controls.addWidget(widget)
        controls.addStretch()
        layout.addLayout(controls)
        self.state = label("固件记录状态等待读取")
        layout.addWidget(self.state)
        self.progress = QProgressBar()
        self.progress.hide()
        layout.addWidget(self.progress)
        files = QHBoxLayout()
        files.addWidget(button("打开 NDJSON", self.choose_record))
        self.export = button("导出 CSV", self.choose_export)
        self.export.setEnabled(False)
        files.addWidget(self.export)
        self.charts = Charts()
        files.addWidget(self.charts.channel_button())
        files.addStretch()
        layout.addLayout(files)
        self.file_state = label("打开实验记录以回看")
        layout.addWidget(self.file_state)
        layout.addWidget(self.charts, 1)
        self.set_connected(False)

    def set_connected(self, connected):
        self.connected = connected
        if not connected:
            self.info = {}
            self.downloading = False
            self.progress.hide()
            self.state.setText("固件记录状态等待读取")
        self.update_buttons()

    def update_buttons(self):
        self.start.setEnabled(self.connected and not self.downloading and not self.info.get("active"))
        self.refresh.setEnabled(self.connected)
        self.freeze.setEnabled(self.connected and not self.downloading)
        self.download.setEnabled(self.connected and not self.downloading and
                                 bool(self.info.get("schema")) and not self.info.get("active"))

    def update_trace(self, info):
        self.info = info
        self.state.setText(capture_summary(info))
        self.update_buttons()

    def choose_download(self):
        path, _ = QFileDialog.getSaveFileName(self, "保存冻结记录", "motor_control_record.ndjson",
                                              "NDJSON (*.ndjson)")
        if path:
            self.begin_download(Path(path))

    def begin_download(self, path):
        self.saved_file = path
        self.downloading = True
        self.progress.setRange(0, 0)
        self.progress.show()
        self.update_buttons()
        self.send("download", path)

    def update_progress(self, done, total):
        self.progress.setRange(0, max(total, 1))
        self.progress.setValue(done)

    def finish_download(self, info):
        self.downloading = False
        self.progress.hide()
        if info is not None:
            self.update_trace(info)
            self.open_record(self.saved_file)
        self.update_buttons()

    def choose_record(self):
        path, _ = QFileDialog.getOpenFileName(self, "打开实验记录", "", "NDJSON (*.ndjson)")
        if path:
            self.open_record(Path(path))

    def open_record(self, path):
        try:
            info, rows = load_record(path)
        except (ValueError, OSError) as error:
            self.report(f"无法打开记录：{error}")
            return
        self.loaded = info, rows
        timeline = Timeline(frequency=info["pl_ticks_hz"], gap=0.03)
        for row in rows:
            timeline.append(row)
        self.charts.show_rows(timeline.rows)
        profile = PROFILES.get(info.get("hardware_profile"), "未知候选")
        self.file_state.setText(f"{path.name} ｜ {profile} ｜ {capture_summary(info)}")
        self.export.setEnabled(True)

    def choose_export(self):
        path, _ = QFileDialog.getSaveFileName(self, "导出记录", "motor_control_record.csv", "CSV (*.csv)")
        if path:
            self.export_record(Path(path))

    def export_record(self, path):
        try:
            export_csv(path, *self.loaded)
            self.report(f"CSV 已保存：{path}")
        except (ValueError, OSError) as error:
            self.report(f"CSV 导出失败：{error}")


def table(headers):
    widget = QTableWidget(0, len(headers))
    widget.setHorizontalHeaderLabels(headers)
    widget.verticalHeader().hide()
    widget.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
    widget.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
    widget.setAlternatingRowColors(True)
    return widget


def rows(widget, data):
    widget.setRowCount(len(data))
    for row, values in enumerate(data):
        for column, value in enumerate(values):
            widget.setItem(row, column, QTableWidgetItem(str(value)))


def signed32(value):
    return value - (1 << 32) if value & 0x80000000 else value


class Diagnostics(QWidget):
    def __init__(self, send):
        super().__init__()
        layout = QVBoxLayout(self)
        controls = QHBoxLayout()
        self.read = button("读取诊断快照", lambda: send("request", "diagnostics"), "primary")
        self.read.setEnabled(False)
        controls.addWidget(self.read)
        controls.addWidget(label("单次读取 · RTL 逻辑状态与控制请求分列"))
        controls.addStretch()
        layout.addLayout(controls)
        self.summary = table(("项目", "快照读数"))
        layout.addWidget(self.summary, 1)
        raw = QCheckBox("展开 80 个原始字")
        layout.addWidget(raw)
        self.raw = table(("字索引", "无符号值", "十六进制"))
        self.raw.hide()
        layout.addWidget(self.raw, 1)
        raw.toggled.connect(self.raw.setVisible)

    def update_snapshot(self, data):
        word = data["words"]
        quality = word[2]
        calibrated = ("完成" if quality & 32 else "未完成", "完成" if quality & 64 else "未完成")
        rows(self.summary, [
            ("诊断序号 / 实时采样 ID / tick", f"{data['sequence']} / {data['rt_sample_id']} / {data['rt_tick']}"),
            ("ADC A / B 原码", f"{word[6]} / {word[7]}"),
            ("ADC A / B 零偏（码值）", f"{signed32(word[11]) / 65536:.4f} / {signed32(word[12]) / 65536:.4f}"),
            ("ADC 标定 A / B / 版本", f"{calibrated[0]} / {calibrated[1]} / {word[15]}"),
            ("QEP 计数 / Z 计数 / 非法计数", f"{signed32(word[16])} / {signed32(word[17])} / {word[20]}"),
            ("PWM 采用序号 / 比较值 / 一致性",
             f"{data['pwm_adopted_sequence']} / {data['pwm_compare']} / {'有效' if data['pwm_receipt_coherent'] else '无效'}"),
            ("PWM 周期 / 死区寄存器字（只读）", f"{data['pwm_period']} / 0x{data['pwm_deadtime']:08X}"),
            ("实时故障 / STOP 原因", f"0x{data['rt_fault']:08X} / {data['stop_reason']}"),
            ("实时 CTRL_EN / 驱动请求字", f"{data['rt_ctrl_enable']} / 0x{data['rt_drive_flags']:08X}"),
            ("RTL 最终输出逻辑（word 78[11:7]）", f"0x{(word[78] >> 7) & 31:02X}"),
            ("IRQ / 精确 ACK / Overrun", f"{data['irq_frames']} / {data['exact_ack_count']} / {data['overruns']}"),
            ("COMMIT / 拒绝", f"{data['commits']} / {data['rejects']}"),
        ])
        rows(self.raw, [(index, value, f"0x{value:08X}") for index, value in enumerate(word)])


class Preparation(QWidget):
    def __init__(self):
        super().__init__()
        layout = QVBoxLayout(self)
        controls = QHBoxLayout()
        self.profile = QComboBox()
        for index, name in ((1, "SELFTEST"), (2, "REAL")):
            self.profile.addItem(PROFILES[index], name)
        controls.addWidget(self.profile)
        controls.addWidget(button("核对候选文件", self.refresh))
        self.save = button("生成 XSDB 脚本", self.choose_script, "primary")
        controls.addWidget(self.save)
        controls.addStretch()
        layout.addLayout(controls)
        layout.addWidget(label("选择用于准备的本地候选。运行中的硬件模式以 TCP 读回为准。"))
        self.details = QPlainTextEdit()
        self.details.setReadOnly(True)
        layout.addWidget(self.details, 1)
        self.profile.currentIndexChanged.connect(self.refresh)
        self.refresh()

    def refresh(self):
        try:
            self.candidate = Candidate.load(self.profile.currentData())
            self.details.setPlainText(candidate_text(self.candidate))
        except (OSError, ValueError, KeyError, IndexError) as error:
            self.candidate = None
            self.details.setPlainText(f"候选文件无法核对：{error}\n请先完成对应候选的离线构建。")
        self.save.setEnabled(self.candidate is not None)

    def choose_script(self):
        path, _ = QFileDialog.getSaveFileName(self, "保存 XSDB 辅助脚本", "prepare_motor_control.tcl",
                                              "Tcl 脚本 (*.tcl)")
        if path:
            try:
                self.candidate.save_xsdb(Path(path))
                self.details.setPlainText(candidate_text(self.candidate) + f"\n\nXSDB Console\nsource {tcl_path(Path(path))}")
            except OSError as error:
                self.details.appendPlainText(f"\n写入脚本失败：{error}")


def candidate_text(candidate):
    return (
        "获现场授权后，在 Vitis 中打开以下工作区并运行启动项。\n"
        "等 R5 停在入口后，在同一 XSDB Console 执行生成的脚本。\n"
        "核对 PL 配置与目标选择，随后手动继续 R5_0。最后连接 Studio TCP。\n\n"
        f"Vitis 工作区    {candidate.workspace}\n"
        f"Vitis 启动项    {candidate.launch}\n"
        f"启动配置       {candidate.config}\n"
        f"R5 ELF        {candidate.elf}\n"
        f"A53 FSBL      {candidate.fsbl}\n"
        f"PL bit        {candidate.bit}\n"
        f"LTX           {candidate.ltx}\n"
        f"XSA           {candidate.xsa}\n"
        f"PS 初始化      {candidate.psu_init}\n\n"
        "加载和实机执行状态：NOT_RUN"
    )
