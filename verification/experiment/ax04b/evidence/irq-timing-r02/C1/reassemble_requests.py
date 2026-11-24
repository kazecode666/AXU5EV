"""Reassemble the archived C1 capture into an audit CSV without board access."""

import argparse
from collections import Counter
import csv
from decimal import Decimal
import json
from pathlib import Path
import struct
import subprocess
import sys


FIELDS = ("frame.number", "frame.time_epoch", "tcp.stream", "ip.src", "tcp.seq_raw", "tcp.payload")
MASK = 0xffffffff
PACKET_DROP_OPTIONS = {4: "ifrecv", 5: "ifdrop", 6: "filteraccept", 7: "osdrop", 8: "usrdeliv"}


def tshark_fields(exe, path, display_filter, fields):
    cmd = [exe, "-n", "-r", str(path), "-Y", display_filter, "-T", "fields"]
    for field in fields:
        cmd.extend(("-e", field))
    return subprocess.check_output(cmd, text=True).splitlines()


def read_requests(exe, path, host):
    buffers = {}
    transactions = {}
    for row in tshark_fields(exe, path, "tcp.len > 0", FIELDS):
        packet, epoch, stream, ip, seq, payload = row.split("\t")
        key = (stream, ip)
        seq = int(seq)
        position, pending = buffers.get(key, (seq, b""))
        gap = (seq - position) & MASK
        if 0 < gap < (1 << 31):
            raise ValueError(f"TCP sequence gap at packet {packet}, stream {stream}")
        chunk = bytes.fromhex(payload.replace(":", ""))[(position - seq) & MASK:]
        position = (position + len(chunk)) & MASK
        pending += chunk
        while b"\n" in pending:
            line, pending = pending.split(b"\n", 1)
            size = len(line) + 1
            if ip == host:
                id_, verb, *_ = line.decode("ascii").split()
                request = (stream, id_)
                if request in transactions:
                    raise ValueError(f"duplicate request ID at packet {packet}")
                transactions[request] = dict(stream=stream, id=id_, verb=verb, tx_packet=packet,
                                             tx_epoch=epoch, request_bytes=size)
            else:
                reply = json.loads(line)
                request = (stream, str(reply["id"]))
                record = transactions[request]
                if "rx_packet" in record:
                    raise ValueError(f"duplicate reply ID at packet {packet}")
                record.update(rx_packet=packet, rx_epoch=epoch, response_bytes=size,
                              error=reply.get("error"), sample_tick=reply.get("sample", {}).get("tick"))
        buffers[key] = (position, pending)
    if any(remaining for _, remaining in buffers.values()):
        raise ValueError("unterminated application line in capture")
    return list(transactions.values())


def pcapng_statistics(path):
    blocks = Counter()
    interface_stats = []
    data = path.read_bytes()
    offset = 0
    while offset < len(data):
        kind, length = struct.unpack_from("<II", data, offset)
        end = offset + length
        if length < 12 or end > len(data) or struct.unpack_from("<I", data, end - 4)[0] != length:
            raise ValueError(f"invalid little-endian pcapng block at offset {offset}")
        blocks[kind] += 1
        if kind == 5:
            interface, = struct.unpack_from("<I", data, offset + 8)
            stats = {"interface": interface}
            opt = offset + 20
            while opt < end - 4:
                code, size = struct.unpack_from("<HH", data, opt)
                if code == 0:
                    break
                if opt + 4 + size > end - 4:
                    raise ValueError("invalid pcapng interface statistics option")
                if size == 8 and code in PACKET_DROP_OPTIONS:
                    stats[PACKET_DROP_OPTIONS[code]], = struct.unpack_from("<Q", data, opt + 4)
                opt += 4 + ((size + 3) // 4) * 4
            interface_stats.append(stats)
        offset = end
    return {"packets": blocks[6], "interface_statistics": interface_stats}


def summarize(rows, duration_s, timeout):
    counts = Counter(r["verb"] for r in rows)
    by_verb = {}
    for verb in counts:
        subset = [r for r in rows if r["verb"] == verb]
        times = [Decimal(r["tx_epoch"]) for r in subset]
        maximum_gap = max((b-a for a, b in zip(times, times[1:])), default=None)
        maximum_reply = max((Decimal(r["rx_epoch"])-Decimal(r["tx_epoch"])
                             for r in subset if "rx_epoch" in r), default=None)
        request_bytes = sum(r["request_bytes"] for r in subset)
        response_bytes = sum(r.get("response_bytes", 0) for r in subset)
        by_verb[verb] = dict(request_bytes=request_bytes, response_bytes=response_bytes,
                             request_bytes_s=request_bytes / duration_s, response_bytes_s=response_bytes / duration_s,
                             max_request_gap_ms=float(maximum_gap*1000) if maximum_gap is not None else None,
                             max_reply_ms=float(maximum_reply*1000) if maximum_reply is not None else None)
    return dict(request_counts=dict(counts), hz={k: v / duration_s for k, v in counts.items()},
                request_bytes=sum(r["request_bytes"] for r in rows),
                response_bytes=sum(r.get("response_bytes", 0) for r in rows),
                errors=sum(bool(r.get("error")) for r in rows),
                missing_replies=sum("rx_epoch" not in r for r in rows),
                timeouts=sum("rx_epoch" in r and Decimal(r["rx_epoch"]) - Decimal(r["tx_epoch"]) >= timeout
                             for r in rows), by_verb=by_verb)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tshark", default="tshark")
    args = parser.parse_args()
    evidence = Path(__file__).resolve().parent
    capture = evidence / "gem3.pcapng"
    rows = read_requests(args.tshark, capture, "192.168.50.20")
    bounds = json.loads((evidence / "pc_bounds.json").read_bytes(), parse_float=Decimal)
    parameters = json.loads((evidence / "run_configuration.json").read_bytes(), parse_float=Decimal)
    trial_ids = {str(json.loads(line)["id"])
                 for line in (evidence / "trial_nominal_host.ndjson").read_bytes().splitlines()}
    start, = [r for r in rows if r["verb"] == "timing-start"]
    lo = min(Decimal(start["tx_epoch"]), bounds["start_request_pc_epoch"]) + bounds["delay_s"]
    hi = max(Decimal(start["rx_epoch"]), bounds["start_reply_pc_epoch"]) + bounds["delay_s"] + Decimal(".0001")
    end_lo, end_hi = lo + bounds["duration_s"], hi + bounds["duration_s"]
    for row in rows:
        epoch = Decimal(row["tx_epoch"])
        if hi <= epoch < end_lo:
            row["scope"] = "formal"
        elif lo <= epoch < hi or end_lo <= epoch < end_hi:
            row["scope"] = "boundary_uncertain"
        elif row["stream"] == start["stream"] and row["id"] in trial_ids:
            row["scope"] = "preflight"
        else:
            row["scope"] = "outside"
    columns = ("stream", "id", "verb", "scope", "tx_packet", "tx_epoch", "request_bytes",
               "rx_packet", "rx_epoch", "response_bytes", "error", "sample_tick")
    writer = csv.DictWriter(sys.stdout, fieldnames=columns, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    capture_stats = pcapng_statistics(capture)
    tcp_flags = ("tcp.analysis.lost_segment", "tcp.analysis.retransmission",
                 "tcp.analysis.out_of_order", "tcp.analysis.ack_lost_segment")
    diagnostic = tshark_fields(args.tshark, capture, " || ".join(tcp_flags), ("frame.number", "tcp.stream"))
    with (evidence / "timing.ndjson").open(encoding="utf-8") as source:
        timing = json.loads(source.readline())["capture"]
    samples = [row for row in rows if row.get("sample_tick") is not None and row["stream"] == start["stream"]]
    before = max((row for row in samples if Decimal(row["rx_epoch"]) < lo
                  and row["sample_tick"] < timing["first"]["pl_tick"]), key=lambda row: Decimal(row["rx_epoch"]))
    after = min((row for row in samples if Decimal(row["tx_epoch"]) >= end_hi
                 and row["sample_tick"] >= timing["receipt_frame"]["pl_tick"]),
                key=lambda row: Decimal(row["tx_epoch"]))
    formal = [r for r in rows if r["scope"] == "formal"]
    if {r["stream"] for r in formal} != {start["stream"]} or any(
            Decimal(a["rx_epoch"]) > Decimal(b["tx_epoch"]) for a, b in zip(formal, formal[1:])
            if "rx_epoch" in a):
        raise ValueError("formal requests did not use one serial connection")
    summary = dict(**capture_stats, tcp_diagnostic_frames=diagnostic,
                   application_requests=len(rows), request_stream=start["stream"],
                   pc_start_bounds=[str(lo), str(hi)], pc_end_bounds=[str(end_lo), str(end_hi)],
                   boundary_uncertain=sum(r["scope"] == "boundary_uncertain" for r in rows),
                   covering_sample_ids=[before["id"], after["id"]],
                   covering_sample_ticks=[before["sample_tick"], after["sample_tick"]],
                   preflight=summarize([r for r in rows if r["scope"] == "preflight"], 12, parameters["reply_timeout_s"]),
                   formal=summarize(formal, int(bounds["duration_s"]), parameters["reply_timeout_s"]))
    print(json.dumps(summary, ensure_ascii=False, indent=2), file=sys.stderr)


if __name__ == "__main__":
    main()
