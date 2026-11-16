"""Check this Issue40 SDF bundle's transfer hashes and visible file inputs."""
import argparse
import hashlib
import json
from pathlib import Path
import re


def sha256(path):
    value = hashlib.sha256()
    with path.open("rb") as stream:
        while block := stream.read(1024 * 1024):
            value.update(block)
    return value.hexdigest()


def source_dependencies(path):
    text = path.read_text(encoding="utf-8", errors="strict")
    protected = re.compile(r"`pragma\s+protect\s+begin_protected\b.*?`pragma\s+protect\s+end_protected\b", re.S)
    protected_count = len(protected.findall(text))
    text = protected.sub("", text)
    # Preserve quoted strings; comments and RAM-name attributes are not files.
    text = re.sub(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*.*?\*/',
                  lambda match: match[0] if match[0].startswith('"') else " ", text, flags=re.S)
    inputs, outputs, unresolved = [], [], []
    for match in re.finditer(r'`include\s+([^\r\n]+)', text):
        literal = re.fullmatch(r'"([^"\n]+)"\s*', match[1])
        (inputs if literal else unresolved).append(
            {"kind": "include", "file": literal[1]} if literal else {"kind": "include", "expression": match[1][:160]})
    for match in re.finditer(r'\$(readmemh|readmemb|fopen|sdf_annotate)\s*\((.*?)\)', text, re.S):
        literal = re.match(r'\s*"([^"\n]+)"\s*(?:,|$)', match[2])
        if not literal:
            unresolved.append({"kind": match[1], "expression": match[2][:160]})
            continue
        entry = {"kind": match[1], "file": literal[1]}
        if match[1] == "fopen":
            mode = re.search(r',\s*"([rwa][+b]*)"\s*$', match[2])
            if mode:
                entry["mode"] = mode[1]
                (inputs if mode[1].startswith("r") else outputs).append(entry)
            else:
                unresolved.append(entry)
        else:
            inputs.append(entry)
    for match in re.finditer(r'\.\s*([A-Za-z_]\w*FILE\w*)\s*\(\s*"([^"\n]*)"\s*\)', text, re.I):
        if match[2].lower() not in ("", "none", "unused", "null"):
            inputs.append({"kind": "file_parameter:" + match[1], "file": match[2]})
    return {"inputs": inputs, "outputs": outputs, "unresolved": unresolved,
            "protected_vendor_blocks": protected_count,
            "vendor_scope": "opaque vendor model blocks retained verbatim; matching Vivado/secureip libraries are external tool dependencies"}


def audit(root):
    sources = ["inputs/hardware_02/timing_pl/motor_routed.v", "verification/motor_control/timing_tb.sv"]
    found = {name: source_dependencies(root / name) for name in sources}
    # The adopted files have no include, readmem or other external data inputs.
    # Fail visibly on a future changed source instead of silently omitting one.
    missing = [dict(source=name, **entry) for name, info in found.items()
               for entry in info["inputs"] + info["unresolved"]]
    if missing:
        raise RuntimeError("File dependencies need explicit packaging/path handling: " + json.dumps(missing, ensure_ascii=False))
    return {"status": "PASS_VISIBLE_INPUT_AUDIT", "sources": found,
            "additional_project_input_files": [],
            "external_tool_dependencies": ["Vivado/XSim 2026.1 matching simulation libraries",
                                           "simprims_ver", "unisims_ver", "secureip",
                                           "<configured Vivado bin>/../data/verilog/src/glbl.v"],
            "real_sdf": "NOT_RUN"}


def verify(root):
    entries = []
    for line in (root / "SHA256SUMS").read_text(encoding="utf-8").splitlines():
        expected, name = line.split("  ", 1)
        path = root / name
        if not path.is_file() or sha256(path) != expected:
            raise RuntimeError("Transfer checksum mismatch: " + name)
        entries.append(name)
    actual = sorted(p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file()
                    and "__pycache__" not in p.parts)
    if actual != sorted(entries + ["SHA256SUMS"]):
        raise RuntimeError("Bundle file inventory differs from SHA256SUMS")
    dependencies = audit(root)
    return {"status": "PASS_BUNDLE_INPUTS_NOT_SDF", "checked_files": len(entries),
            "dependency_audit": dependencies, "sdf_annotation": "NOT_COMPLETED", "sdf_dynamic": "NOT_RUN"}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args()
    print(json.dumps(verify(args.root.resolve()), ensure_ascii=False, indent=2))
