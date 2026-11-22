"""Compare independent AX-04 FOC RTL against its short B2 model trace."""

import argparse
import csv
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import time


ROOT = Path(__file__).resolve().parents[1]


def packed_vectors(csv_path, output, maximum_frames):
    widths = [32, 32, 32, 40, 40, 32, 32, 1, 32, 32, 32, 32]
    fractions = [24, 24, 24, 32, 24, 24, 24, 0, 24, 30, 30, 30]
    frames = 0
    with csv_path.open(newline="", encoding="utf-8-sig") as stream, output.open("x") as target:
        for row in csv.reader(stream):
            if maximum_frames is not None and frames >= maximum_frames:
                break
            assert len(row) == 13, "Expected time, nine inputs and three duty outputs"
            values = [float(value) for value in row]
            assert abs(values[0] - frames * 1e-4) < 1e-12
            packed = 0
            for index, (value, width, fraction) in enumerate(zip(values[1:], widths, fractions)):
                assert math.isfinite(value)
                scaled = value * (1 << fraction)
                assert abs(scaled) % 1 != .5, "Inspect exact-half stimulus using MATLAB fi"
                integer = round(scaled)
                if index >= 9:
                    assert abs(scaled - integer) < 1e-4, "Duty is not an exact UQ30 word"
                signed = index < 7
                minimum = -(1 << (width - 1)) if signed else 0
                maximum = (1 << (width - int(signed))) - 1
                assert minimum <= integer <= maximum, "Vector exceeds its HDL port type"
                packed = (packed << width) | (integer & ((1 << width) - 1))
            target.write(f"{packed:093x}\n")
            frames += 1
    assert 0 < frames <= 4096
    return frames


def run_tool(bin_dir, name, arguments, output_dir):
    executable = bin_dir / (name + ".bat")
    assert executable.is_file(), executable
    words = [str(executable), *arguments]
    assert all(not any(character in word for character in '"&|<>^%!\r\n') for word in words)
    quoted = " ".join('"' + word + '"' for word in words)
    command = '"' + os.environ["COMSPEC"] + '" /d /s /c "' + quoted + '"'
    started = time.monotonic()
    with (output_dir / (name + ".console.log")).open("x", encoding="utf-8") as log:
        process = subprocess.Popen(command, cwd=output_dir, stdout=log,
                                   stderr=subprocess.STDOUT,
                                   creationflags=subprocess.CREATE_NO_WINDOW)
        try:
            exit_code = process.wait(timeout=600)
        except subprocess.TimeoutExpired:
            subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"],
                           capture_output=True, timeout=30, check=False)
            process.wait(timeout=30)
            raise RuntimeError(f"{name} exceeded its 600-second limit") from None
    elapsed = time.monotonic() - started
    assert exit_code == 0, f"{name} exit {exit_code}, inspect its console log"
    return {"exit_code": exit_code, "elapsed_seconds": elapsed}


def validate(csv_path, output_dir, bin_dir, maximum_frames, source_dir=None, dq_vectors=None):
    assert not output_dir.exists(), "Choose a new RTL verification directory"
    output_dir.mkdir(parents=True)
    assert maximum_frames is None or maximum_frames > 0
    frames = packed_vectors(csv_path, output_dir / "foc_vectors.hex", maximum_frames)
    baseline = ROOT / "generated/experiment/ax04_01/pl/AXU5EV_Experiment_FOC"
    sources = sorted(baseline.glob("*.sv"), key=lambda path: (not path.name.endswith("_pkg.sv"), path.name))
    if source_dir is not None:
        if not source_dir.is_dir() or not (source_dir / "AX04_FOC_FOC_DUT.sv").is_file():
            raise FileNotFoundError(f"Missing FOC DUT overlay: {source_dir}")
        sources = [(source_dir / path.name) if (source_dir / path.name).is_file() else path
                   for path in sources]
    assert len(sources) == 29
    assert all(path.name.startswith("AX04_FOC_") for path in sources)
    testbench = ROOT / "simulation/tests/experiment/ax04_foc_duty_tb.sv"
    arguments = ["--sv", "--work work", *[f'"{path.as_posix()}"' for path in sources + [testbench]]]
    if dq_vectors is not None:
        shutil.copyfile(dq_vectors, output_dir / "foc_dq_vectors.hex")
        arguments.insert(1, "--define AX05A_FOC_OBSERVATION")
    (output_dir / "xvlog.args").write_text("\n".join(arguments) + "\n", encoding="utf-8")
    tools = {}
    tools["xvlog"] = run_tool(bin_dir, "xvlog", ["-f", "xvlog.args"], output_dir)
    tools["xelab"] = run_tool(bin_dir, "xelab", ["-debug", "off", "ax04_foc_duty_tb",
                                               "-s", "ax04_foc_snapshot"], output_dir)
    tools["xsim"] = run_tool(bin_dir, "xsim", ["ax04_foc_snapshot", "-runall",
                                             "-testplusarg", f"frames={frames}"], output_dir)
    result = json.loads((output_dir / "foc_rtl_result.json").read_text())
    assert result["status"] == "PASS", result
    assert result["frames"] == frames and result["checks"] == 3 * frames
    if dq_vectors is not None:
        marker = f"AX05A_DQ_MODEL_PASS frames={frames} checks={4 * frames}"
        assert marker in (output_dir / "xsim.console.log").read_text(encoding="utf-8", errors="replace")
        result["dq_checks"] = 4 * frames
    result.update(model_trace=str(csv_path), dut="AX04_FOC_FOC_DUT", tools=tools,
                  stimulus_scope=f"First {frames} consecutive model-trace frames",
                  synthesis="NOT_RUN", implementation="NOT_RUN", sta_cdc_sdf="NOT_RUN",
                  hardware="HW_BINDING_PENDING", board="BOARD_NOT_RUN")
    (output_dir / "rtl_verification.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--csv", type=Path, default=ROOT /
                        ".runtime/experiment/ax04_01/pl_b2_01/numeric_04/foc/foc_short_model.csv")
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--max-frames", type=int)
    parser.add_argument("--source-dir", type=Path, help="versioned experiment FOC HDL directory")
    parser.add_argument("--dq-vectors", type=Path, help="model-exported Q40 observation words")
    parser.add_argument("--vivado-bin", type=Path, default=Path("E:/AMDDesignTools/2026.1/Vivado/bin"))
    args = parser.parse_args()
    print(json.dumps(validate(args.csv.resolve(), args.run_dir.resolve(),
                              args.vivado_bin.resolve(), args.max_frames,
                              args.source_dir.resolve() if args.source_dir else None,
                              args.dq_vectors.resolve() if args.dq_vectors else None), indent=2))
