"""Single owner of the GEM3 connection and its blocking client."""

from itertools import count
from queue import Empty, PriorityQueue
from time import monotonic

from PySide6.QtCore import QThread, Signal

from scripts.motor_control_client import Action, MotorControlClient, RequestError


class Connection(QThread):
    event = Signal(str, object)

    def __init__(self, host, port, parent=None):
        super().__init__(parent)
        self.host, self.port = host, port
        self._jobs = PriorityQueue()
        self._sequence = count()

    def submit(self, kind, *args):
        priority = 2
        if kind == "disconnect":
            priority = 0
        elif kind == "command" and args[0] == Action.STOP:
            priority = 1
        self._jobs.put((priority, next(self._sequence), kind, args))

    def run(self):
        transfer = None
        try:
            with MotorControlClient(self.host, self.port, timeout=1.2) as client:
                identity = client.request("version")
                if (identity.get("protocol"), identity.get("schema"), identity.get("application_id")) != (1, 1, 0x41585205):
                    raise RequestError("候选身份或协议版本不匹配")
                self.event.emit("connected", identity)
                self.event.emit("status", client.request("status"))
                next_sample = monotonic()
                next_status = next_sample + 1
                stop_sequence = -1
                transfer_turn = False
                while True:
                    deadline = min(next_sample, next_status)
                    try:
                        wait = max(0, deadline - monotonic()) if transfer is None else 0
                        _, sequence, kind, args = self._jobs.get(timeout=wait)
                    except Empty:
                        kind = "poll"
                        args = ()

                    try:
                        if kind == "disconnect":
                            return
                        if kind == "command":
                            if sequence < stop_sequence:
                                continue
                            action, mode, revision, values = args
                            if action == Action.STOP:
                                stop_sequence = sequence
                            reply = client.command(action, mode, revision, **values)
                            self.event.emit("reply", (action, reply))
                        elif kind == "request":
                            verb, *params = args
                            if verb == "calibration-gains" and sequence < stop_sequence:
                                continue
                            data = client.request(verb, *params)
                            topic = "trace" if verb.startswith("trace-") else verb
                            self.event.emit(topic, data)
                        elif kind == "download":
                            if transfer is None:
                                transfer = client.download_steps(args[0])
                        else:
                            now = monotonic()
                            if transfer is not None and (transfer_turn or now < deadline):
                                transfer_turn = False
                                try:
                                    self.event.emit("progress", next(transfer))
                                except StopIteration as done:
                                    transfer = None
                                    self.event.emit("downloaded", done.value)
                                except (FileExistsError, PermissionError, RequestError) as error:
                                    transfer.close()
                                    transfer = None
                                    self.event.emit("download_error", str(error))
                            elif now >= next_sample:
                                try:
                                    self.event.emit("sample", client.sample())
                                except RequestError as error:
                                    if error.code != "NO_SAMPLE":
                                        raise
                                    self.event.emit("sample_gap", None)
                                next_sample = monotonic() + 0.1
                                transfer_turn = True
                            elif now >= next_status:
                                next_status = now + 1
                                self.event.emit("status", client.request("status"))
                                transfer_turn = True
                    except RequestError as error:
                        self.event.emit("error", error.code)
        except (OSError, ValueError, KeyError, RequestError) as error:
            self.event.emit("error", str(error))
        finally:
            if transfer is not None:
                transfer.close()
