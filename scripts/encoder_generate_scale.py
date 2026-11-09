"""Export the explicit digital-test scale shared by PL and R5 numerical code."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
scale = json.loads((ROOT / "simulation/encoder/encoder_test_scale.json").read_text(encoding="utf-8"))
# The generated angle implementation is specialized to this period. A new
# scale requires regeneration and comparison, never a changed label alone.
assert scale["counts_per_electrical_period"] == 30000
assert scale["nanometres_per_count"] == 1000
out = ROOT / "generated/encoder/encoder_scale_pkg.sv"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(
    "// Generated from simulation/encoder/encoder_test_scale.json; TEST ONLY.\n"
    "package encoder_scale_pkg;\n"
    f"  localparam integer ENCODER_COUNTS_PER_PERIOD = {scale['counts_per_electrical_period']};\n"
    f"  localparam integer ENCODER_NM_PER_COUNT = {scale['nanometres_per_count']};\n"
    "endpackage\n", encoding="ascii"
)
print(out)
header = ROOT / "generated/encoder/encoder_test_scale.h"
header.write_text(
    "/* Generated from encoder_test_scale.json; TEST ONLY. */\n"
    "#ifndef ENCODER_TEST_SCALE_H\n#define ENCODER_TEST_SCALE_H\n"
    f"#define ENCODER_NM_PER_COUNT {scale['nanometres_per_count']}u\n"
    f"#define ENCODER_COUNTS_PER_PERIOD {scale['counts_per_electrical_period']}u\n"
    f"#define ENCODER_TICK_HZ {scale['tick_hz']}u\n"
    f"#define ENCODER_SAMPLE_ID_STEP {scale['sample_id_step']}u\n"
    f"#define ENCODER_SAMPLE_TICK_STEP {scale['sample_tick_step']}u\n"
    "#endif\n", encoding="ascii"
)
