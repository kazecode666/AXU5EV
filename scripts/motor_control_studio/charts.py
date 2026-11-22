"""Small, independently selectable plots for live and recorded samples."""

import numpy as np
import pyqtgraph as pg
from PySide6.QtWidgets import QGridLayout, QMenu, QToolButton, QWidget

from .telemetry import PANELS, SERIES, measured


class Charts(QWidget):
    def __init__(self):
        super().__init__()
        layout = QGridLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(8)
        self.plots, self.curves = [], {}
        self.last_drawn_time = 0.0
        for index, (title, unit, series) in enumerate(PANELS):
            chart = pg.PlotWidget(background="#152331")
            chart.setMinimumHeight(128)
            chart.setTitle(title, size="11pt", color="#e4edf6")
            chart.setLabel("left", units=unit)
            chart.setLabel("bottom", "PL 时间", units="s")
            chart.getAxis("left").enableAutoSIPrefix(False)
            chart.showGrid(x=True, y=True, alpha=0.24)
            chart.addLegend(offset=(8, 4), labelTextColor="#d8e3ee", labelTextSize="9pt")
            for label, key, _, _, color in series:
                self.curves[key] = chart.plot(name=label, pen=pg.mkPen(color, width=1.8), connect="finite")
            row, column = divmod(index, 2)
            layout.addWidget(chart, row, column, 1, 2 if index == 4 else 1)
            layout.setRowStretch(row, 1)
            self.plots.append(chart)
        layout.setColumnStretch(0, 1)
        layout.setColumnStretch(1, 1)

    def channel_button(self):
        button = QToolButton()
        button.setText("曲线通道")
        button.setPopupMode(QToolButton.ToolButtonPopupMode.InstantPopup)
        menu = QMenu(button)
        for title, _, series in PANELS:
            group = menu.addMenu(title)
            for label, key, *_ in series:
                action = group.addAction(label)
                action.setCheckable(True)
                action.setChecked(True)
                action.toggled.connect(self.curves[key].setVisible)
        button.setMenu(menu)
        return button

    def show_rows(self, rows, window=None):
        x = np.array([time for time, _ in rows], dtype=float)
        self.last_drawn_time = float(x[-1]) if len(x) else 0.0
        for line in SERIES:
            data = np.array([measured(sample, line) for _, sample in rows], dtype=float)
            self.curves[line[1]].setData(x, data, connect="finite")
        if window is not None:
            self.set_window(window)
        else:
            for plot in self.plots:
                plot.enableAutoRange(axis=pg.ViewBox.XAxis)

    def set_window(self, seconds):
        right = max(seconds, self.last_drawn_time)
        for plot in self.plots:
            plot.setXRange(right - seconds, right, padding=0)
