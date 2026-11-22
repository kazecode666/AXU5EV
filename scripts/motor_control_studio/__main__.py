"""Launch Studio, or prepare an XSDB script locally without opening a target."""

import argparse
from pathlib import Path

from .prepare import Candidate


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prepare", choices=("SELFTEST", "REAL"))
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.prepare:
        if not args.output:
            parser.error("--prepare requires --output")
        try:
            candidate = Candidate.load(args.prepare)
            candidate.save_xsdb(args.output)
        except (OSError, ValueError, KeyError, IndexError) as error:
            parser.exit(1, f"{error}\n")
        print(f"Vitis workspace: {candidate.workspace}\nLaunch: {candidate.launch}\n"
              f"XSDB script: {args.output.resolve()}\nHardware execution: NOT_RUN")
        return 0
    if args.output:
        parser.error("--output is used with --prepare")

    from PySide6.QtWidgets import QApplication
    from .style import style
    from .window import Studio

    app = QApplication([])
    style(app)
    window = Studio()
    window.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
