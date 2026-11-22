"""Windows operator interface for the existing no-power GEM3 candidates."""

from PySide6.QtCore import QTimer
from PySide6.QtWidgets import (
    QCheckBox, QComboBox, QDoubleSpinBox, QFormLayout, QFrame, QGridLayout, QGroupBox,
    QHBoxLayout, QLabel, QLineEdit, QMainWindow, QScrollArea, QSpinBox, QTabWidget,
    QVBoxLayout, QWidget,
)

from scripts.motor_control_client import Action, Mode

from .charts import Charts
from .panels import Diagnostics, Preparation, Records, button, label
from .telemetry import PROFILES, Timeline
from .worker import Connection

MODES = {
    Mode.IDLE: "IDLE · 停止", Mode.CURRENT: "CURRENT · 电流测试", Mode.SPEED: "SPEED · 速度闭环",
    Mode.POSITION: "POSITION · 位置闭环", Mode.ALIGNMENT: "ALIGNMENT · 自动对齐",
}
REFERENCES = {
    Mode.IDLE: (), Mode.ALIGNMENT: (), Mode.CURRENT: ("id_a", "iq_a"),
    Mode.SPEED: ("speed_mm_s", "id_a"), Mode.POSITION: ("position_mm", "id_a"),
}
REFERENCE_LABELS = {"position_mm": "位置 (mm)", "speed_mm_s": "速度 (mm/s)",
                    "id_a": "Id (A)", "iq_a": "Iq (A)", "fine_phase_rad": "微调角 (rad)"}
DECISIONS = ("ACCEPTED", "BAD_REQUEST", "OUT_OF_RANGE", "STOP_FIRST", "NOT_READY",
             "REAL_INHIBITED", "PENDING", "PL_DENIED")
REAL_DISABLED = {Action.ARM, Action.START, Action.SETPOINT, Action.ALIGN_START,
                 Action.ALIGN_RESET, Action.DRIVER_RESET}
ACTION_NAMES = {
    Action.STOP: "STOP 停止", Action.SELECT: "选择模式", Action.CONFIRM: "确认选择",
    Action.CLEAR: "清除故障", Action.ARM: "ARM 内部许可", Action.START: "START 启动",
    Action.SETPOINT: "提交给定", Action.ALIGN_START: "开始对齐", Action.ALIGN_RESET: "对齐复位",
    Action.PI_RESET: "PI 复位", Action.DRIVER_RESET: "驱动复位", Action.CALIBRATE: "零偏校准",
    Action.FINE_PHASE: "提交角度微调",
}


class Studio(QMainWindow):
    def __init__(self, host="192.168.50.10", port=5002, demo_port=None):
        super().__init__()
        self.setWindowTitle("AXU5EV Motor Control Studio")
        self.resize(1390, 880)
        self.setMinimumSize(1000, 720)
        self.demo_port = demo_port
        self.worker = None
        self.closing = False
        self.disconnecting = False
        self.identity = {}
        self.control = {}
        self.latest = {}
        self.timeline = Timeline(window=20)
        self.redraw = True
        self.actions = {}
        self.refs = {}

        content = QWidget()
        layout = QVBoxLayout(content)
        layout.setContentsMargins(15, 10, 15, 8)
        layout.setSpacing(9)
        layout.addWidget(self.connection_panel(host, port))
        self.tabs = QTabWidget()
        self.tabs.addTab(self.run_panel(), "实时运行")
        self.records = Records(self.send, self.report)
        self.tabs.addTab(self.records, "实验记录")
        self.diagnostics = Diagnostics(self.send)
        self.tabs.addTab(self.diagnostics, "底层诊断")
        self.tabs.addTab(Preparation(), "实验准备")
        layout.addWidget(self.tabs, 1)
        self.notice = label("等待连接。实验目标由固件报告。", "detail")
        layout.addWidget(self.notice)
        self.setCentralWidget(content)
        self.refresh_controls()
        self.timer = QTimer(self, interval=100)
        self.timer.timeout.connect(self.draw_trend)
        self.timer.start()

    def connection_panel(self, host, port):
        panel = QFrame(objectName="connection")
        layout = QGridLayout(panel)
        layout.setContentsMargins(13, 8, 13, 9)
        title = label("AXU5EV Motor Control Studio", "title")
        title.setWordWrap(False)
        layout.addWidget(title, 0, 0, 1, 4)
        bar = QHBoxLayout()
        bar.addStretch()
        self.host = QLineEdit(host)
        self.host.setMaxLength(253)
        self.host.setMinimumWidth(155)
        self.host.setMaximumWidth(220)
        self.host.setAccessibleName("IP 地址")
        self.port = QSpinBox()
        self.port.setRange(1, 65535)
        self.port.setValue(port)
        self.port.setMaximumWidth(84)
        self.port.setAccessibleName("TCP 端口")
        self.connect_button = button("连接", self.connect_target, "primary")
        self.disconnect_button = button("断开", self.disconnect_target)
        for widget in (QLabel("IP"), self.host, QLabel("端口"), self.port,
                       self.connect_button, self.disconnect_button, self.action_button(Action.STOP)):
            bar.addWidget(widget)
        layout.addLayout(bar, 0, 4)
        self.profile_badge = label("未连接", "badge")
        layout.addWidget(self.profile_badge, 1, 0, 1, 3)
        self.identity_line = label("离线回环 · 模拟 PL" if self.demo_port else "等待读取候选身份")
        layout.addWidget(self.identity_line, 1, 3, 1, 2)
        layout.setColumnStretch(4, 1)
        return panel

    def run_panel(self):
        page = QWidget()
        layout = QHBoxLayout(page)
        left = QWidget()
        controls = QVBoxLayout(left)
        controls.setContentsMargins(0, 0, 3, 0)
        controls.setSpacing(7)

        state = QGroupBox("固件状态")
        state_layout = QVBoxLayout(state)
        self.running = label("等待控制状态")
        self.frame_receipt = label("等待帧回读")
        state_layout.addWidget(self.running)
        state_layout.addWidget(self.frame_receipt)
        controls.addWidget(state)
        commands = QGroupBox("模式与给定")
        command_layout = QVBoxLayout(commands)
        self.mode = QComboBox()
        self.mode.setAccessibleName("拟选择模式")
        for mode, text in MODES.items():
            self.mode.addItem(text, mode)
        command_layout.addWidget(label("拟选择模式"))
        command_layout.addWidget(self.mode)
        self.form = QFormLayout()
        for field, limit in (("position_mm", 110), ("speed_mm_s", 20), ("id_a", .5), ("iq_a", .3)):
            spin = QDoubleSpinBox()
            spin.setAccessibleName(REFERENCE_LABELS[field])
            spin.setDecimals(5)
            spin.setRange(-limit, limit)
            spin.setSingleStep(.01 if limit < 1 else 1)
            self.refs[field] = spin
            self.form.addRow(REFERENCE_LABELS[field], spin)
        command_layout.addLayout(self.form)
        main_actions = (Action.SELECT, Action.CONFIRM, Action.CLEAR, Action.ARM,
                        Action.START, Action.SETPOINT, Action.ALIGN_START)
        command_layout.addLayout(self.action_grid(main_actions))
        self.requested = label("尚未提交请求")
        self.receipt = label("等待命令回执", "response")
        command_layout.addWidget(self.requested)
        command_layout.addWidget(self.receipt)
        controls.addWidget(commands)

        setup = QGroupBox("校准与复位")
        setup_layout = QVBoxLayout(setup)
        gains = QHBoxLayout()
        self.gain_a = QLineEdit(placeholderText="实测 A 路")
        self.gain_b = QLineEdit(placeholderText="实测 B 路")
        self.gain_button = button("暂存 Q24", self.send_gains)
        for field in (self.gain_a, self.gain_b, self.gain_button):
            gains.addWidget(field)
        setup_layout.addLayout(gains)
        setup_layout.addWidget(label("REAL 两路有符号 Q24 增益。零电流时提交校准。"))
        setup_layout.addLayout(self.action_grid((Action.CALIBRATE, Action.ALIGN_RESET, Action.PI_RESET,
                                                 Action.DRIVER_RESET)))
        phase = QHBoxLayout()
        self.fine = QDoubleSpinBox()
        self.fine.setDecimals(6)
        self.fine.setRange(-3.141592, 3.141592)
        self.fine.setSingleStep(.01)
        self.fine.setSuffix(" rad")
        phase.addWidget(self.fine)
        phase.addWidget(self.action_button(Action.FINE_PHASE))
        setup_layout.addLayout(phase)
        controls.addWidget(setup)
        controls.addStretch()
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setWidget(left)
        scroll.setMinimumWidth(390)
        scroll.setMaximumWidth(450)
        layout.addWidget(scroll)

        trend = QWidget()
        trend_layout = QVBoxLayout(trend)
        trend_layout.setContentsMargins(4, 0, 0, 0)
        trend_bar = QHBoxLayout()
        self.sample_line = label("实时趋势 · 约 10 Hz · 最近 20 s")
        self.pause_draw = QCheckBox("暂停绘图")
        self.pause_draw.toggled.connect(self.resume_drawing)
        self.charts = Charts()
        trend_bar.addWidget(self.sample_line, 1)
        trend_bar.addWidget(self.pause_draw)
        trend_bar.addWidget(self.charts.channel_button())
        trend_layout.addLayout(trend_bar)
        trend_layout.addWidget(self.charts, 1)
        layout.addWidget(trend, 1)
        self.mode.currentIndexChanged.connect(self.refresh_controls)
        return page

    def action_grid(self, actions):
        layout = QGridLayout()
        for index, action in enumerate(actions):
            row, column = divmod(index, 2)
            layout.addWidget(self.action_button(action), row, column)
        return layout

    def action_button(self, action):
        item = button(ACTION_NAMES[action], lambda: self.send_action(action),
                      "stop" if action == Action.STOP else "")
        self.actions[action] = item
        return item

    def report(self, message):
        self.notice.setText(message)

    def connect_target(self):
        host = self.host.text().strip()
        if not host:
            self.report("请输入设备 IP 地址。")
            return
        if self.worker is not None:
            return
        if self.demo_port and (host != "127.0.0.1" or self.port.value() != self.demo_port):
            self.report("演示仅连接本地回环。")
            return
        self.control, self.latest = {}, {}
        self.timeline = Timeline(window=20)
        self.charts.show_rows((), 20)
        self.requested.setText("尚未提交请求")
        self.receipt.setText("等待命令回执")
        self.profile_badge.setText("连接中")
        self.report("正在读取 GEM3 候选身份…")
        self.worker = Connection(host, self.port.value(), self)
        self.worker.event.connect(self.on_event)
        self.worker.finished.connect(self.connection_finished)
        self.worker.start()
        self.refresh_controls()

    def disconnect_target(self):
        if self.worker is not None:
            self.disconnecting = True
            self.worker.submit("disconnect")
            self.refresh_controls()

    def connection_finished(self):
        worker = self.worker
        self.worker = None
        if worker is not None:
            worker.deleteLater()
        self.disconnecting = False
        self.identity, self.control, self.latest = {}, {}, {}
        self.timeline.interrupt()
        self.redraw = True
        self.profile_badge.setText("已断开")
        self.profile_badge.setProperty("online", False)
        self.profile_badge.style().unpolish(self.profile_badge)
        self.profile_badge.style().polish(self.profile_badge)
        self.identity_line.setText("离线回环 · 模拟 PL" if self.demo_port else "候选身份待重新读取")
        self.sample_line.setText("实时趋势 · 会话已中断")
        self.frame_receipt.setText("帧回读已中断")
        self.running.setText("控制状态待重新读取")
        self.records.set_connected(False)
        self.diagnostics.summary.setRowCount(0)
        self.diagnostics.raw.setRowCount(0)
        self.refresh_controls()
        if self.closing:
            self.close()

    def closeEvent(self, event):
        if self.worker is not None:
            self.closing = True
            self.disconnect_target()
            event.ignore()
        else:
            super().closeEvent(event)

    def refresh_controls(self):
        connected = bool(self.identity) and not self.disconnecting
        ready = connected and bool(self.control)
        real = self.identity.get("hardware_profile") == 2
        self.connect_button.setEnabled(self.worker is None)
        self.disconnect_button.setEnabled(self.worker is not None and not self.disconnecting)
        self.host.setEnabled(self.worker is None)
        self.port.setEnabled(self.worker is None)
        self.diagnostics.read.setEnabled(connected)
        draft = Mode(self.mode.currentData())
        board_mode = self.control.get("selected_mode")
        for field, widget in self.refs.items():
            self.form.setRowVisible(widget, field in REFERENCES[draft])
        for action, item in self.actions.items():
            enabled = ready and not (real and action in REAL_DISABLED)
            item.setEnabled(enabled)
            item.setToolTip("REAL IO 功率动作受限" if real and action in REAL_DISABLED else "")
        self.actions[Action.STOP].setEnabled(connected)
        self.actions[Action.SELECT].setEnabled(ready and draft != Mode.IDLE)
        selected = bool(self.control.get("selected_revision"))
        for action in (Action.CONFIRM, Action.FINE_PHASE):
            self.actions[action].setEnabled(ready and selected)
        self.actions[Action.START].setEnabled(ready and not real and selected and board_mode != Mode.ALIGNMENT)
        self.actions[Action.ALIGN_START].setEnabled(ready and not real and selected and board_mode == Mode.ALIGNMENT)
        self.actions[Action.SETPOINT].setEnabled(ready and not real and selected and board_mode == draft
                                                 and draft in (Mode.POSITION, Mode.CURRENT, Mode.SPEED))
        for widget in (self.gain_a, self.gain_b, self.gain_button):
            widget.setEnabled(ready and real)

    def send(self, kind, *args):
        if self.worker is not None and self.identity and not self.disconnecting:
            self.worker.submit(kind, *args)

    def send_action(self, action):
        mode = Mode(self.control.get("selected_mode", Mode.IDLE))
        revision = self.control.get("selected_revision", 0)
        values = {}
        if action in (Action.SELECT, Action.SETPOINT):
            mode = Mode(self.mode.currentData())
            values = {key: self.refs[key].value() for key in REFERENCES[mode]}
        elif action == Action.FINE_PHASE:
            values = {"fine_phase_rad": self.fine.value()}
        if action in (Action.START, Action.SETPOINT, Action.ARM, Action.ALIGN_START):
            revision = self.control.get("confirmed_revision", 0)
        detail = " · ".join(f"{REFERENCE_LABELS[key]} {value:g}" for key, value in values.items())
        self.requested.setText(f"请求 {action.name} / {mode.name} / 版本 {revision}" + (f"\n{detail}" if detail else ""))
        self.send("command", action, mode, revision, values)

    def send_gains(self):
        try:
            values = [int(field.text(), 10) for field in (self.gain_a, self.gain_b)]
            if any(not -(2**31) <= value < 2**31 or not value for value in values):
                raise ValueError
        except ValueError:
            self.report("请输入两路非零、有符号 32 位 Q24 整数。")
            return
        self.send("request", "calibration-gains", *values)

    def on_event(self, topic, data):
        if topic == "connected":
            self.identity = data
            self.profile_badge.setText(PROFILES.get(data["hardware_profile"], "未知候选"))
            self.profile_badge.setProperty("online", True)
            self.profile_badge.style().unpolish(self.profile_badge)
            self.profile_badge.style().polish(self.profile_badge)
            self.identity_line.setText(
                ("离线回环 · 模拟 PL ｜ " if self.demo_port else "") +
                f"GEM3 TCP · 协议 {data['protocol']} · schema {data['schema']} · Mode {data['hardware_profile']} · "
                f"App 0x{data['application_id']:08X} · PL 0x{data['pl_interface_id']:08X} · {data['link_mbps']} Mb/s")
            self.report("已连接。命令需显式提交。")
            self.records.set_connected(True)
            self.refresh_controls()
        elif topic == "status":
            self.update_status(data)
        elif topic == "reply":
            action, reply = data
            index = reply["decision"]
            decision = DECISIONS[index] if 0 <= index < len(DECISIONS) else f"DECISION {index}"
            self.receipt.setText(f"{action.name} · {decision} · 固件请求 {reply['firmware_request_id']}\n"
                                 f"已接受版本 {reply['accepted_revision'] or '—'}")
            self.update_status(reply)
        elif topic == "sample":
            self.latest = data
            self.timeline.append(data)
            self.redraw = True
            self.sample_line.setText(f"趋势 10 Hz ｜ ID {data['sample_id']} ｜ tick {data['tick']} ｜"
                                     f"有效组 0x{data['groups']:X} ｜ 窗口 20 s")
            self.update_frame(data)
        elif topic == "sample_gap":
            self.timeline.interrupt()
            self.redraw = True
            self.frame_receipt.setText("暂无可用快照")
        elif topic == "diagnostics":
            self.diagnostics.update_snapshot(data)
            self.report(f"已读取诊断快照 {data['sequence']}。")
        elif topic == "trace":
            self.records.update_trace(data)
        elif topic == "progress":
            self.records.update_progress(*data)
        elif topic == "downloaded":
            self.records.finish_download(data)
            self.report(f"已下载 {data['count']} 条冻结记录。")
        elif topic == "download_error":
            self.records.finish_download(None)
            self.report(f"记录传输未完成：{data}")
        elif topic == "calibration-gains":
            self.report("已暂存实测 Q24 增益。零电流时显式提交零偏校准。")
        elif topic == "error":
            self.report(f"通信或请求失败：{data}")

    def update_status(self, status):
        self.control = status
        mode = MODES.get(status["selected_mode"], "未知")
        ready = "已确认" if status["selection_confirmed"] else "待确认"
        self.running.setText(
            f"选中 {mode} ｜ {ready}\n选中 / 确认 / 下发版本 "
            f"{status['selected_revision']} / {status['confirmed_revision']} / {status['dispatched_revision']}\n"
            f"ARM {int(status['armed'])} · CLEAR {int(status['clear_confirmed'])} · STOP 待处理 {int(status['stop_pending'])}")
        self.refresh_controls()

    def update_frame(self, sample):
        if not sample["groups"] & 1:
            self.frame_receipt.setText("PS 未匹配 · 模型消费、COMMIT 和 P0 回读暂不可用")
            return
        adopted = f"{sample['p0_version']} → {sample['p0_target']}" if sample["p0_valid"] else "—"
        committed = (f"{sample['accepted_version']} → {sample['accepted_target']}" if sample["commit_accepted"]
                     else f"未确认（结果 {sample['commit_result']}）")
        self.frame_receipt.setText(
            f"运行 {MODES.get(sample['mode'], '未知')} · 对齐状态 {sample['alignment_state']} · 故障 0x{sample['fault']:X}\n"
            f"模型消费版本 {sample['command_revision']} · Host 回执 {sample['host_receipt_revision']}\n"
            f"COMMIT 接受 {committed}\n当前 P0 采用 {adopted}")

    def resume_drawing(self, paused):
        if not paused:
            self.redraw = True

    def draw_trend(self):
        if self.redraw and not self.pause_draw.isChecked() and self.tabs.currentIndex() == 0:
            self.charts.show_rows(self.timeline.rows, 20)
            self.redraw = False
