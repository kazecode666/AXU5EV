"""Run Studio against the existing C GEM3 service with simulated PL."""

import argparse
from pathlib import Path
import shutil
import sys
import threading
import uuid

from test_motor_control_ethernet import Loopback, ROOT, build_fixture

sys.path.insert(0, str(ROOT))


def native_compiler():
    gcc = shutil.which("gcc")
    matlab = Path("C:/ProgramData/MATLAB/SupportPackages/R2026b/3P.instrset/mingw_w64.instrset/bin/gcc.exe")
    return gcc or (str(matlab) if matlab.is_file() else None)


def drive_frames(board, done):
    milliseconds = 0
    while not done.wait(.004):
        milliseconds += 2
        board.advance(20, milliseconds)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cc", default=native_compiler())
    parser.add_argument("--profile", choices=("SELFTEST", "REAL"), default="SELFTEST")
    args = parser.parse_args()
    if not args.cc:
        parser.error("需要本机 GCC，或使用 --cc 指定编译器。")
    output = ROOT / ".runtime/studio/demo" / uuid.uuid4().hex
    output.mkdir(parents=True)
    fixture = build_fixture(args.cc, output, 1 if args.profile == "SELFTEST" else 2)

    from PySide6.QtWidgets import QApplication
    from scripts.motor_control_studio.style import style
    from scripts.motor_control_studio.window import Studio

    app = QApplication([])
    style(app)
    with Loopback(fixture) as board:
        done = threading.Event()
        advancing = threading.Thread(target=drive_frames, args=(board, done))
        advancing.start()
        try:
            window = Studio("127.0.0.1", board.port, demo_port=board.port)
            window.show()
            return app.exec()
        finally:
            done.set()
            advancing.join()


if __name__ == "__main__":
    raise SystemExit(main())
