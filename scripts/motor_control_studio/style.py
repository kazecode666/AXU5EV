"""Studio palette and native widget styling."""

from PySide6.QtGui import QFont, QFontDatabase

STYLES = """
QWidget { color: #e4edf6; font-size: 13px; }
QMainWindow, QTabWidget::pane, QScrollArea, QScrollArea > QWidget > QWidget { background: #0f1823; }
QTabWidget::pane, QScrollArea { border: 0; }
QFrame#connection { background: #172633; border: 1px solid #304252; border-radius: 9px; }
QLabel#title { font-size: 25px; font-weight: 700; }
QLabel#muted, QLabel#detail { color: #a8bccc; }
QLabel#badge { padding: 6px 12px; color: #efc589; background: #372e27; border-radius: 5px; }
QLabel#badge[online="true"] { color: #74ead8; background: #153934; }
QLabel#response { color: #b7eadc; padding: 6px 0; }
QGroupBox { background: #152331; border: 1px solid #2b3e50; border-radius: 6px;
            margin-top: 12px; padding: 11px 8px 8px 8px; font-weight: 600; }
QGroupBox::title { subcontrol-origin: margin; left: 8px; padding: 0 6px; color: #9bd9d6; }
QPushButton, QToolButton, QComboBox, QSpinBox, QDoubleSpinBox, QLineEdit, QPlainTextEdit {
    background: #1c2d3d; border: 1px solid #3a5063; border-radius: 5px; padding: 6px 8px;
}
QPushButton:hover, QToolButton:hover { background: #294152; }
QPushButton:disabled, QToolButton:disabled, QComboBox:disabled, QLineEdit:disabled {
    color: #91a0ae; background: #16212c; border-color: #2c3947;
}
QPushButton#primary { background: #57d5c0; color: #0c2423; font-weight: 700; }
QPushButton#primary:disabled { background: #273f40; color: #9baaaa; }
QPushButton#stop { background: #982e3c; border: 1px solid #cf5a64; color: #fff3f4; font-weight: 700; }
QPushButton#stop:disabled { background: #3c292d; color: #a78589; border-color: #553338; }
QTabBar::tab { color: #a8bccc; padding: 9px 19px; background: #162331; margin-right: 3px; }
QTabBar::tab:selected { color: #89ebdd; background: #1b3440; border-bottom: 2px solid #57d5c0; }
QHeaderView::section { background: #213445; color: #c5dcea; padding: 5px; border: 0; }
QTableWidget {
    color: #e4edf6; background: #152331; alternate-background-color: #1b2c3b;
    gridline-color: #2b3e50; selection-color: #f5fffd; selection-background-color: #346165;
}
QMenu, QComboBox QAbstractItemView { background: #152331; gridline-color: #2b3e50; }
QMenu::item:selected { background: #346165; }
QProgressBar { border: 1px solid #395064; border-radius: 4px; background: #152331; text-align: center; }
QProgressBar::chunk { background: #287f77; }
QScrollBar:vertical { width: 8px; background: #162331; border: 0; }
QScrollBar::handle:vertical { background: #3b5366; border-radius: 3px; min-height: 24px; }
QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical { height: 0; }
"""


def style(app):
    app.setStyle("Fusion")
    if "Microsoft YaHei UI" in QFontDatabase.families():
        app.setFont(QFont("Microsoft YaHei UI", 10))
    app.setStyleSheet(STYLES)
