"""GEM3 motor-control console and record downloader for the no-power profiles."""

import argparse
from enum import IntEnum
import json
from pathlib import Path
import socket
import time


class Action(IntEnum):
    SELECT = 0
    SETPOINT = 1
    CONFIRM = 2
    START = 3
    STOP = 4
    ARM = 5
    ALIGN_START = 6
    ALIGN_RESET = 7
    CALIBRATE = 8
    FINE_PHASE = 9
    PI_RESET = 10
    CLEAR = 11
    DRIVER_RESET = 12


class Mode(IntEnum):
    IDLE = 0
    CURRENT = 1
    SPEED = 2
    POSITION = 3
    ALIGNMENT = 4


class RequestError(Exception):
    """A complete error response from the firmware."""

    def __init__(self, code):
        self.code = code
        super().__init__(code)


class MotorControlClient:
    def __init__(self, host="192.168.50.10", port=5002, timeout=3.0):
        self._socket = socket.create_connection((host, port), timeout=timeout)
        self._reader = self._socket.makefile("rb")
        self._request_id = 0

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.close()

    def close(self):
        self._reader.close()
        self._socket.close()

    def request(self, verb, *args):
        self._request_id = self._request_id % 0xFFFFFFFF + 1
        line = " ".join(map(str, (self._request_id, verb, *args))) + "\n"
        try:
            self._socket.sendall(line.encode("ascii"))
            data = self._reader.readline(4129)
            if not data.endswith(b"\n"):
                raise ConnectionError("incomplete motor-control response")
            response = json.loads(data)
            if response["id"] != self._request_id:
                raise ConnectionError("reply ID does not match request")
        except (OSError, ValueError, KeyError):
            self.close()
            raise
        if "error" in response:
            raise RequestError(response["error"])
        return response

    def command(self, action, mode=Mode.IDLE, revision=0, *,
                position_mm=0.0, speed_mm_s=0.0, id_a=0.0, iq_a=0.0, fine_phase_rad=0.0):
        return self.request("command", int(action), int(mode), revision, position_mm,
                            speed_mm_s, id_a, iq_a, fine_phase_rad)

    def sample(self):
        return self.request("sample")["sample"]

    def download(self, path):
        """Download only a frozen capture, preserving its metadata and frame identity."""
        info = self.request("trace-status")
        if info["active"] or not info["schema"]:
            raise RequestError("TRACE_UNAVAILABLE")
        path = Path(path)
        partial = path.with_name(path.name + ".partial")
        if path.exists():
            raise FileExistsError(path)
        with partial.open("x", encoding="utf-8") as out:
            out.write(json.dumps({"capture": info}) + "\n")
            index = 0
            while index < info["count"]:
                data = self.request("trace-read", info["capture_id"], index)
                records = data["records"]
                end = data["next_index"]
                if (data["capture_id"] != info["capture_id"] or data["index"] != index
                        or not records or end != index + len(records) or end > info["count"]):
                    raise RequestError("TRACE_UNAVAILABLE")
                for sample in records:
                    out.write(json.dumps(sample) + "\n")
                index = end
        partial.rename(path)
        return info


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="192.168.50.10")
    parser.add_argument("--port", type=int, default=5002)
    commands = parser.add_subparsers(dest="verb", required=True)
    for name in ("version", "status", "sample", "diagnostics", "trace-status", "trace-stop"):
        commands.add_parser(name)
    start = commands.add_parser("trace-start")
    start.add_argument("--groups", type=int, default=15)
    download = commands.add_parser("download")
    download.add_argument("path", type=Path)
    watch = commands.add_parser("watch", help="poll the latest sample at 10 Hz")
    watch.add_argument("--count", type=int, default=10)
    command = commands.add_parser("command")
    command.add_argument("action", type=str.upper, choices=list(Action.__members__))
    command.add_argument("--mode", type=str.upper, choices=list(Mode.__members__), default="IDLE")
    command.add_argument("--revision", type=int, default=0)
    for param in ("position-mm", "speed-mm-s", "id-a", "iq-a", "fine-phase-rad"):
        command.add_argument("--" + param, type=float, default=0.0)
    args = parser.parse_args()
    try:
        with MotorControlClient(args.host, args.port) as client:
            if args.verb == "command":
                result = client.command(Action[args.action], Mode[args.mode], args.revision,
                                        position_mm=args.position_mm, speed_mm_s=args.speed_mm_s,
                                        id_a=args.id_a, iq_a=args.iq_a, fine_phase_rad=args.fine_phase_rad)
            elif args.verb == "trace-start":
                result = client.request("trace-start", args.groups)
            elif args.verb == "download":
                result = client.download(args.path)
            elif args.verb == "watch":
                for i in range(args.count):
                    if i:
                        time.sleep(0.1)
                    try:
                        print(json.dumps(client.sample()), flush=True)
                    except RequestError as error:
                        if error.code != "NO_SAMPLE":
                            raise
                        print(json.dumps({"error": error.code}), flush=True)
                return
            else:
                result = client.request(args.verb)
            print(json.dumps(result))
    except (OSError, ValueError, RequestError) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
