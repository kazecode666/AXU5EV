"""Emit scoped model_edit operations for the Issue42 ADC extraction.

Run from the repository root. The channel stage takes the name-to-blk_ID JSON
read from the actual copied AQM subsystem. Each stage edits one scope only.
"""

import argparse
import json


SOURCE = "PMSLM_Close_Loop_MBDL4_F28335_Backup/FOC_3Close_Loop_Control/ADC//QEP"
INPUTS = [
    "sample_strobe", "raw_a", "raw_b", "capture_valid_a", "capture_valid_b",
    "otr_a", "otr_b", "cal_en", "cal_restart", "config_apply", "config_version",
    "offset_seed_a_q16", "offset_seed_b_q16", "manual_valid_a", "manual_valid_b",
    "gain_a_q24", "gain_b_q24", "cal_log2_N",
]
OUTPUTS = [
    "ia_q24", "ib_q24", "ic_q24", "offset_a_q16", "offset_b_q16",
    "cal_count_a", "cal_count_b", "cal_done_a", "cal_done_b", "cal_version",
    "valid", "clip", "error", "result_strobe",
]


class Graph:
    def __init__(self):
        self.ops = []
        self.scripts = {}
        self.post = []

    def add(self, kind, name, **params):
        self.ops.append({"op": "add_block", "type": kind, "name": name,
                         "ref": name, "params": params})
        return "#" + name

    def configure(self, target, **params):
        self.ops.append({"op": "configure", "target": target, "params": params})

    def wire(self, source, target, inp=1, out=1):
        self.ops.append({"op": "connect", "target": f"{source}.y{out} -> {target}.u{inp}"})

    def constant(self, name, value, dtype):
        return self.add("Constant", name, Value=value, OutDataTypeStr=dtype)

    def function(self, name, script):
        self.scripts[name] = script
        return self.add("MATLABFunction", name)

    def select(self, name, control, yes, no, dtype=None):
        params = {"Criteria": "u2 ~= 0"}
        if dtype:
            params["OutDataTypeStr"] = dtype
        block = self.add("Switch", name, **params)
        self.wire(yes, block, 1)
        self.wire(control, block, 2)
        self.wire(no, block, 3)
        return block

    def logic(self, name, operator, sources):
        block = self.add("Logic", name, Operator=operator, Inputs=str(len(sources)))
        for port, source in enumerate(sources, 1):
            self.wire(source, block, port)
        return block


def install():
    g = Graph()
    g.ops.append({"op": "create_subsystem", "name": "Current_Processing",
                  "ref": "core", "interface": {"inputs": INPUTS, "outputs": OUTPUTS}})
    for port in range(1, 19):
        g.wire(f"blk_{97+port}", "#core", port)
    registers = [124, 125, 126, 127, 128, 117, 118, 119, 120, 121, 130, 122, 123, 129]
    for port, sid in enumerate(registers, 1):
        g.wire("#core", f"blk_{sid}", out=port)
    g.ops.append({"op": "delete", "target": "blk_116"})
    return split_steps(g)


def channel(names):
    """Adapt the copied AQM graph in-place, preserving its actual arithmetic."""
    g = Graph()
    retained = {
        "ADC_A_raw", "ADC_B_raw", "OffsetCal_EN", "ADC_OffsetA_auto",
        "ADC_OffsetB_auto", "Offset_Cal_Done", "dbg_count_state", "dbg_cal_running",
        "sumA_add", "sumA_z", "sumA_next", "count_plus_one", "count_z",
        "count_next", "offsetA_next", "offsetA_z",
    }
    for name, block in names.items():
        if name not in retained:
            g.ops.append({"op": "delete", "target": block})
    renamed = {
        "ADC_A_raw": ("raw", 1), "ADC_B_raw": ("advance", 2),
        "OffsetCal_EN": ("clear_epoch", 3),
        "ADC_OffsetA_auto": ("offset_q16", 1), "ADC_OffsetB_auto": ("count", 2),
        "Offset_Cal_Done": ("done", 3), "dbg_count_state": ("old_done", 4),
        "dbg_cal_running": ("complete", 5),
    }
    for old, (name, port) in renamed.items():
        g.configure(names[old], Name=name, Port=str(port))
    for old in ["ADC_OffsetA_auto", "ADC_OffsetB_auto", "Offset_Cal_Done", "dbg_count_state", "dbg_cal_running"]:
        g.configure(names[old], OutDataTypeStr="Inherit: auto")
    raw, advance, clear = [names[x] for x in ["ADC_A_raw", "ADC_B_raw", "OffsetCal_EN"]]
    for port, (name, dtype) in enumerate([
        ("seed_q16", "int32"), ("manual_valid", "boolean"),
        ("log2_N", "uint8"), ("seed_apply", "boolean")], 4):
        g.add("Inport", name, Port=str(port), OutDataTypeStr=dtype)
    g.configure(raw, OutDataTypeStr="uint16")
    g.configure(advance, OutDataTypeStr="boolean")
    g.configure(clear, OutDataTypeStr="boolean")
    for key, dtype in [("sumA_z", "uint32"), ("count_z", "uint16"), ("offsetA_z", "int32")]:
        g.configure(names[key], InitialCondition=f"{dtype}(0)", SampleTime="-1")
    g.configure(names["sumA_add"], Inputs="++", OutDataTypeStr="uint32")
    g.configure(names["count_plus_one"], Inputs="++", OutDataTypeStr="uint16")
    for key, dtype in [("sumA_next", "uint32"), ("count_next", "uint16"), ("offsetA_next", "int32")]:
        g.configure(names[key], Criteria="u2 ~= 0", OutDataTypeStr=dtype)
    raw32 = g.add("DataTypeConversion", "Raw_U32", OutDataTypeStr="uint32")
    g.wire(raw, raw32)
    zero32 = g.constant("Zero_U32", "0", "uint32")
    zero16 = g.constant("Zero_U16", "0", "uint16")
    one16 = g.constant("One_U16", "1", "uint16")
    false = g.constant("False", "false", "boolean")
    done = g.add("UnitDelay", "done_z", InitialCondition="false", SampleTime="-1")
    not_done = g.logic("Not_Done", "NOT", [done])
    go = g.logic("cal_running_logic", "AND", [advance, not_done])
    g.wire(names["sumA_z"], names["sumA_add"], 1)
    g.wire(raw32, names["sumA_add"], 2)
    g.wire(names["count_z"], names["count_plus_one"], 1)
    g.wire(one16, names["count_plus_one"], 2)
    for old, summation, state in [
        ("sumA_next", "sumA_add", "sumA_z"),
        ("count_next", "count_plus_one", "count_z")]:
        g.wire(names[summation], names[old], 1)
        g.wire(go, names[old], 2)
        g.wire(names[state], names[old], 3)
    sum_next = g.select("Sum_Clear", clear, zero32, names["sumA_next"], "uint32")
    count_next = g.select("Count_Clear", clear, zero16, names["count_next"], "uint16")
    g.wire(sum_next, names["sumA_z"])
    g.wire(count_next, names["count_z"])
    n = g.function("Calibration_Window", "function n=f(log2_N)\n%#codegen\nn=bitshift(uint16(1),int32(log2_N));\nend")
    g.wire("#log2_N", n)
    finish_test = g.add("RelationalOperator", "count_eq_N", Operator="==")
    g.wire(names["count_plus_one"], finish_test, 1)
    g.wire(n, finish_test, 2)
    finish = g.logic("Complete", "AND", [go, finish_test])
    mean = g.function("Mean_Q16", "function y=f(total,log2_N)\n%#codegen\ny=int32(bitshift(uint64(total),int32(16)-int32(log2_N)));\nend")
    g.wire(names["sumA_add"], mean, 1)
    g.wire("#log2_N", mean, 2)
    g.wire(mean, names["offsetA_next"], 1)
    g.wire(finish, names["offsetA_next"], 2)
    g.wire(names["offsetA_z"], names["offsetA_next"], 3)
    offset_next = g.select("Seed_Offset", "#seed_apply", "#seed_q16", names["offsetA_next"], "int32")
    g.wire(offset_next, names["offsetA_z"])
    done_hold = g.logic("Done_Hold", "OR", [done, finish])
    seed_done = g.select("Seed_Done", "#seed_apply", "#manual_valid", false, "boolean")
    done_next = g.select("Done_Clear", clear, seed_done, done_hold, "boolean")
    g.wire(done_next, done)
    for source, old in [(offset_next, "ADC_OffsetA_auto"), (count_next, "ADC_OffsetB_auto"),
                        (done_next, "Offset_Cal_Done"), (done, "dbg_count_state"),
                        (finish, "dbg_cal_running")]:
        g.wire(source, names[old])
    g.post.append({"op": "configure", "target": f"{names['count_z']}.y1 -> {names['count_plus_one']}.u1",
                   "params": {"MustResolveToSignalObject": "off", "Name": ""}})
    return split_steps(g)


QUALIFICATION = """function [good_cfg,good_a,good_b,active]=f(sample,raw_a,raw_b,cv_a,cv_b,otr_a,otr_b,restart,apply,seed_a,seed_b,log2_N)
%#codegen
limit=int32(268369920);
good_cfg=log2_N<=uint8(10) && seed_a>=int32(0) && seed_a<=limit && seed_b>=int32(0) && seed_b<=limit;
good_a=cv_a && ~otr_a && raw_a<=uint16(4095);
good_b=cv_b && ~otr_b && raw_b<=uint16(4095);
active=sample && ~apply && ~restart;
end"""

ROUND = """function y=f(x)
%#codegen
negative=x<int64(0);a=x;
if negative,a=-x;end
q=bitshift(a,-16);r=bitand(a,int64(65535));
if r>int64(32768) || (r==int64(32768) && bitand(q,int64(1))~=int64(0)),q=q+int64(1);end
if negative,y=-q;else,y=q;end
end"""

SATURATE = """function [y,clipped]=f(x)
%#codegen
below=bitshift(x,-31)<int64(-1);clipped=x>int64(2147483647)||below;
if x>int64(2147483647),y=int32(2147483647);
elseif below,y=int32(-2147483648);
else,y=int32(x);end
end"""

VERSION = """function y=f(previous,apply,good_cfg,requested,restart,complete_a,complete_b)
%#codegen
y=previous;
if apply
 if good_cfg,y=requested;end
elseif restart
 y=increment(y);
else
 if complete_a,y=increment(y);end
 if complete_b,y=increment(y);end
end
end
function y=increment(x)
if x==uint32(4294967295),y=uint32(0);else,y=x+uint32(1);end
end"""

ERROR = """function error=f(sample,apply,restart,good_cfg,raw_a,raw_b,cv_a,cv_b,otr_a,otr_b,old_done_a,old_done_b,configured,clip)
%#codegen
error=uint16(0);
if apply
 if sample,error=uint16(256);end
 if ~good_cfg,error=bitor(error,uint16(64));end
elseif restart
 if sample,error=uint16(256);end
elseif sample
 if ~cv_a || raw_a>uint16(4095),error=bitor(error,uint16(1));end
 if ~cv_b || raw_b>uint16(4095),error=bitor(error,uint16(2));end
 if otr_a,error=bitor(error,uint16(4));end
 if otr_b,error=bitor(error,uint16(8));end
 if ~old_done_a,error=bitor(error,uint16(16));end
 if ~old_done_b,error=bitor(error,uint16(32));end
 if ~configured,error=bitor(error,uint16(64));end
 if clip,error=bitor(error,uint16(128));end
end
end"""


def core(interface):
    """Fill the interface produced by create_subsystem in install()."""
    g = Graph()
    p = {name: interface[name] for name in INPUTS + OUTPUTS}
    q = g.function("Frame_Qualification", QUALIFICATION)
    for port, key in enumerate([
        "sample_strobe", "raw_a", "raw_b", "capture_valid_a", "capture_valid_b",
        "otr_a", "otr_b", "cal_restart", "config_apply", "offset_seed_a_q16",
        "offset_seed_b_q16", "cal_log2_N"], 1):
        g.wire(p[key], q, port)
    # Multioutput helper ports are exposed through named From/Goto-free adapters.
    good_cfg = g.add("SignalConversion", "Good_Config")
    good_a = g.add("SignalConversion", "Good_A")
    good_b = g.add("SignalConversion", "Good_B")
    active = g.add("SignalConversion", "Active_Sample")
    for port, dest in enumerate([good_cfg, good_a, good_b, active], 1):
        g.wire(q, dest, out=port)
    configured = g.add("UnitDelay", "configured_z", InitialCondition="false", SampleTime="-1")
    configured_next = g.select("Configured_Next", p["config_apply"], good_cfg, configured, "boolean")
    g.wire(configured_next, configured)
    load = g.logic("Config_Load", "AND", [p["config_apply"], good_cfg])
    clear = g.logic("Clear_Epoch", "OR", [p["config_apply"], p["cal_restart"]])
    config = {}
    for key, dtype, initial in [("gain_a_q24", "int32", "0"), ("gain_b_q24", "int32", "0"), ("cal_log2_N", "uint8", "10")]:
        state = g.add("UnitDelay", key + "_z", InitialCondition=f"{dtype}({initial})", SampleTime="-1")
        nxt = g.select(key + "_next", load, p[key], state, dtype)
        g.wire(nxt, state)
        config[key] = state
    channels = []
    old_done = []
    complete = []
    for phase, good in [("a", good_a), ("b", good_b)]:
        advance = g.logic("Advance_" + phase.upper(), "AND", [active, configured, p["cal_en"], good])
        cal = g.add("AXU5EV_PL_Algorithm_Library/Current_Offset_Calibration", "Calibration_" + phase.upper())
        for port, source in enumerate([p["raw_" + phase], advance, clear,
                                       p["offset_seed_" + phase + "_q16"],
                                       p["manual_valid_" + phase], config["cal_log2_N"], load], 1):
            g.wire(source, cal, port)
        channels.append(cal)
        old = g.add("SignalConversion", "Old_Done_" + phase.upper())
        pulse = g.add("SignalConversion", "Complete_" + phase.upper())
        g.wire(cal, old, out=4)
        g.wire(cal, pulse, out=5)
        old_done.append(old)
        complete.append(pulse)
        for out, name in [(1, "offset_" + phase + "_q16"), (2, "cal_count_" + phase), (3, "cal_done_" + phase)]:
            g.wire(cal, p[name], out=out)
    usable = g.logic("Current_Qualified", "AND", [active, configured, good_a, good_b] + old_done)
    wide = []
    for index, phase in enumerate(["a", "b"]):
        raw = g.add("DataTypeConversion", "Raw_" + phase.upper() + "_I64", OutDataTypeStr="int64")
        raw_q16 = g.add("Gain", "Raw_" + phase.upper() + "_Q16", Gain="65536", OutDataTypeStr="int64", ParamDataTypeStr="int64")
        offset = g.add("DataTypeConversion", "Offset_" + phase.upper() + "_I64", OutDataTypeStr="int64")
        gain = g.add("DataTypeConversion", "Gain_" + phase.upper() + "_I64", OutDataTypeStr="int64")
        subtract = g.add(SOURCE + ("/Subtract" if phase == "a" else "/Subtract1"), "Subtract_Offset_" + phase.upper())
        g.configure(subtract, Inputs="+-", OutDataTypeStr="int64")
        product = g.add("Product", "AN9238_Gain_" + phase.upper(), Inputs="**", OutDataTypeStr="int64")
        rounder = g.function("Convergent_Q24_" + phase.upper(), ROUND)
        g.wire(p["raw_" + phase], raw)
        g.wire(raw, raw_q16)
        g.wire(channels[index], offset, out=1)
        g.wire(config["gain_" + phase + "_q24"], gain)
        g.wire(raw_q16, subtract, 1)
        g.wire(offset, subtract, 2)
        g.wire(subtract, product, 1)
        g.wire(gain, product, 2)
        g.wire(product, rounder)
        wide.append(rounder)
    reconstruction = g.add(SOURCE + "/Add", "Two_Phase_Sum")
    g.configure(reconstruction, Inputs="++", OutDataTypeStr="int64")
    negate = g.add(SOURCE + "/Gain4", "Reconstruct_IC")
    g.configure(negate, Gain="-1", OutDataTypeStr="int64", ParamDataTypeStr="int64")
    g.wire(wide[0], reconstruction, 1)
    g.wire(wide[1], reconstruction, 2)
    g.wire(reconstruction, negate)
    wide.append(negate)
    zero = g.constant("Zero_Current", "0", "int32")
    clips = []
    for phase, source in zip(["a", "b", "c"], wide):
        limiter = g.function("Saturate_I" + phase.upper(), SATURATE)
        g.wire(source, limiter)
        limited = g.select("Qualified_I" + phase.upper(), usable, limiter, zero, "int32")
        g.wire(limited, p["i" + phase + "_q24"])
        flag = g.add("SignalConversion", "Clip_I" + phase.upper())
        g.wire(limiter, flag, out=2)
        clips.append(flag)
    any_clip = g.logic("Any_Clip", "OR", clips)
    clip = g.logic("Qualified_Clip", "AND", [usable, any_clip])
    not_clip = g.logic("Not_Clip", "NOT", [clip])
    valid = g.logic("Valid_Current", "AND", [usable, not_clip])
    g.wire(clip, p["clip"])
    g.wire(valid, p["valid"])
    version = g.add("UnitDelay", "version_z", InitialCondition="uint32(0)", SampleTime="-1")
    version_next = g.function("Calibration_Version", VERSION)
    for port, source in enumerate([version, p["config_apply"], good_cfg, p["config_version"], p["cal_restart"]] + complete, 1):
        g.wire(source, version_next, port)
    g.wire(version_next, version)
    g.wire(version_next, p["cal_version"])
    error = g.function("Frame_Diagnostics", ERROR)
    error_inputs = [p["sample_strobe"], p["config_apply"], p["cal_restart"], good_cfg,
                    p["raw_a"], p["raw_b"], p["capture_valid_a"], p["capture_valid_b"],
                    p["otr_a"], p["otr_b"]] + old_done + [configured, clip]
    for port, source in enumerate(error_inputs, 1):
        g.wire(source, error, port)
    g.wire(error, p["error"])
    g.wire(p["sample_strobe"], p["result_strobe"])
    return split_steps(g)


def split_steps(graph):
    """Assign EMChart.Script after creation and before port-dependent wiring."""
    return {
        "blocks": [op for op in graph.ops if op["op"] != "connect"],
        "scripts": graph.scripts,
        "wires": [op for op in graph.ops if op["op"] == "connect"] + graph.post,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("stage", choices=["install", "channel", "core"])
    parser.add_argument("mapping", nargs="?", help="UTF-8 name-to-block-ID JSON")
    args = parser.parse_args()
    if args.stage == "install":
        operations = install()
    else:
        with open(args.mapping, encoding="utf-8-sig") as stream:
            mapping = json.load(stream)
        operations = channel(mapping) if args.stage == "channel" else core(mapping)
    print(json.dumps(operations, ensure_ascii=True, separators=(",", ":")))
