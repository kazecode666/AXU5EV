"""Emit model_edit operations for the reused DSP position/measurement graph.

The caller resolves the legacy source paths through their inspected SIDs and
passes them in source_paths. All mutations run through model_edit. MATLAB
Function Script assignment is returned separately for the EMChart property.
"""
import argparse
import json


INPUTS = [
    ("raw_count", "uint32"),
    ("sample_id", "uint32"),
    ("sample_tick", "uint64"),
    ("encoder_ready", "boolean"),
    ("illegal_count", "uint32"),
    ("zero_count", "uint32"),
    ("reverse", "boolean"),
    ("config_version", "uint32"),
    ("nm_per_count", "uint32"),
    ("reset", "boolean"),
]
OUTPUTS = [
    ("position_mm", "double"),
    ("speed_mm_s", "double"),
    ("position_valid", "boolean"),
    ("speed_valid", "boolean"),
    ("history_count", "uint8"),
    ("status", "uint32"),
    ("continuous_count", "int64"),
]
GUARD_OUTPUTS = [
    "continuous_count", "origin_count", "advance", "restart_history",
    "position_valid", "speed_valid", "history_count", "status",
]


def guard_script():
    inputs = ",".join(name for name, _ in INPUTS)
    outputs = ",".join(GUARD_OUTPUTS)
    return (
        f"function [{outputs}] = f({inputs})\n"
        "%#codegen\n"
        f"[{outputs}]=task1_encoder_guard({inputs});\n"
        "end\n"
    )


def component(source_paths, delay_ports=None):
    """Populate an empty Caculate_measurement scope.

    source_paths keys identify legacy SIDs 1055, 1058, 469, 1682 and 486.
    Delay ports are supplied after querying the configured block if the local
    Simulink release reports a different enable/reset/IC input ordering.
    """
    if delay_ports is None:
        delay_ports = {"data": 1, "enable": 2, "reset": 3, "initial": 4}
    operations = []

    def add(block_type, name, ref, params=None):
        operation = {"op": "add_block", "type": block_type, "name": name, "ref": ref}
        if params:
            operation["params"] = params
        operations.append(operation)

    def wire(source, destination):
        operations.append({"op": "connect", "target": f"{source} -> {destination}"})

    for port, (name, data_type) in enumerate(INPUTS, 1):
        add("Inport", name, name, {
            "Port": str(port), "OutDataTypeStr": data_type, "SampleTime": "-1",
        })
    for port, (name, data_type) in enumerate(OUTPUTS, 1):
        add("Outport", name, f"out_{name}", {
            "Port": str(port), "OutDataTypeStr": data_type,
        })
    add("MATLAB Function", "Frame_And_Count_Guard", "guard")
    add(source_paths["count_origin"], "Continuous_Position_Count", "relative", {
        "Inputs": "+-", "OutDataTypeStr": "int64", "AccumDataTypeStr": "int64",
    })
    add("DataTypeConversion", "Position_Count_To_Double", "position_double", {
        "OutDataTypeStr": "double",
    })
    add("DataTypeConversion", "Scale_To_Double", "scale_double", {
        "OutDataTypeStr": "double",
    })
    add(source_paths["position_scale"], "Nanometres_To_Millimetres", "scale", {
        "Gain": "1e-6", "OutDataTypeStr": "double",
    })
    add("Constant", "Forward_Direction", "forward", {"Value": "1", "OutDataTypeStr": "double"})
    add("Constant", "Reverse_Direction", "backward", {"Value": "-1", "OutDataTypeStr": "double"})
    add("Switch", "Mechanical_Direction", "direction", {"Criteria": "u2 ~= 0"})
    add("Product", "Position_Millimetres", "position", {"Inputs": "***", "OutDataTypeStr": "double"})
    add("Constant", "Zero", "zero", {"Value": "0", "OutDataTypeStr": "double"})
    add("UnitDelay", "Position_Hold", "position_hold", {"InitialCondition": "0", "SampleTime": "-1"})
    add("Switch", "New_Frame_Position", "new_position", {"Criteria": "u2 ~= 0"})
    add("Switch", "Reset_Position", "reset_position", {"Criteria": "u2 ~= 0"})
    add(source_paths["history"], "Delay_50_Intervals", "history", {
        "DelayLength": "50", "ShowEnablePort": "on", "ExternalReset": "level hold",
        "InitialConditionSource": "Input port",
    })
    add(source_paths["difference"], "Count_Difference_50_Intervals", "difference", {
        "Inputs": "+-", "OutDataTypeStr": "int64", "AccumDataTypeStr": "int64",
    })
    add("DataTypeConversion", "Difference_To_Double", "difference_double", {"OutDataTypeStr": "double"})
    add("Product", "Displacement_Millimetres", "displacement", {"Inputs": "***", "OutDataTypeStr": "double"})
    add(source_paths["speed_scale"], "Five_Millisecond_Speed", "speed", {
        "Gain": "1/(50*100e-6)", "OutDataTypeStr": "double",
    })
    add("Switch", "Qualified_Speed", "qualified_speed", {"Criteria": "u2 ~= 0"})

    for port, (name, _) in enumerate(INPUTS, 1):
        wire(f"#{name}.y1", f"#guard.u{port}")
    wire("#guard.y1", "#relative.u1")
    wire("#guard.y2", "#relative.u2")
    wire("#relative.y1", "#position_double.u1")
    wire("#nm_per_count.y1", "#scale_double.u1")
    wire("#scale_double.y1", "#scale.u1")
    wire("#backward.y1", "#direction.u1")
    wire("#reverse.y1", "#direction.u2")
    wire("#forward.y1", "#direction.u3")
    wire("#position_double.y1", "#position.u1")
    wire("#scale.y1", "#position.u2")
    wire("#direction.y1", "#position.u3")
    wire("#position.y1", "#new_position.u1")
    wire("#guard.y3", "#new_position.u2")
    wire("#position_hold.y1", "#new_position.u3")
    wire("#zero.y1", "#reset_position.u1")
    wire("#reset.y1", "#reset_position.u2")
    wire("#new_position.y1", "#reset_position.u3")
    wire("#reset_position.y1", "#position_hold.u1")
    wire("#reset_position.y1", "#out_position_mm.u1")
    wire("#relative.y1", f"#history.u{delay_ports['data']}")
    wire("#guard.y3", f"#history.u{delay_ports['enable']}")
    wire("#guard.y4", f"#history.u{delay_ports['reset']}")
    wire("#relative.y1", f"#history.u{delay_ports['initial']}")
    wire("#relative.y1", "#difference.u1")
    wire("#history.y1", "#difference.u2")
    wire("#difference.y1", "#difference_double.u1")
    wire("#difference_double.y1", "#displacement.u1")
    wire("#scale.y1", "#displacement.u2")
    wire("#direction.y1", "#displacement.u3")
    wire("#displacement.y1", "#speed.u1")
    wire("#speed.y1", "#qualified_speed.u1")
    wire("#guard.y6", "#qualified_speed.u2")
    wire("#zero.y1", "#qualified_speed.u3")
    wire("#qualified_speed.y1", "#out_speed_mm_s.u1")
    for guard_port, name in [(5, "position_valid"), (6, "speed_valid"),
                             (7, "history_count"), (8, "status"), (1, "continuous_count")]:
        wire(f"#guard.y{guard_port}", f"#out_{name}.u1")
    return split_operations(operations, {"guard": guard_script()})


def shell():
    operations = []
    for port, (name, data_type) in enumerate(INPUTS, 1):
        operations.append({"op": "add_block", "type": "Inport", "name": name,
                           "ref": name, "params": {"Port": str(port),
                           "OutDataTypeStr": data_type, "SampleTime": "100e-6",
                           "Interpolate": "off"}})
    operations.append({"op": "add_block",
                       "type": "AXU5EV_Encoder_Components/Caculate_measurement",
                       "name": "Caculate_measurement", "ref": "measurement"})
    for port, (name, data_type) in enumerate(OUTPUTS, 1):
        operations.append({"op": "add_block", "type": "Outport", "name": name,
                           "ref": f"out_{name}", "params": {"Port": str(port),
                           "OutDataTypeStr": data_type}})
    for port, (name, _) in enumerate(INPUTS, 1):
        operations.append({"op": "connect", "target": f"#{name}.y1 -> #measurement.u{port}"})
    for port, (name, _) in enumerate(OUTPUTS, 1):
        operations.append({"op": "connect", "target": f"#measurement.y{port} -> #out_{name}.u1"})
    return split_operations(operations, {})


def split_operations(operations, scripts):
    return {
        "blocks": [operation for operation in operations if operation["op"] != "connect"],
        "scripts": scripts,
        "wires": [operation for operation in operations if operation["op"] == "connect"],
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("scope", choices=["component", "shell"])
    parser.add_argument("--source-model", default="PMSLM_Close_Loop_MBDL4")
    arguments = parser.parse_args()
    base = arguments.source_model + "/FOC_3Close_Loop_Control/"
    paths = {
        "count_origin": base + "ADC//QEP/Subtract2",
        "position_scale": base + "ADC//QEP/Gain5",
        "difference": base + "Caculate_measurement/Add1",
        "history": base + "Caculate_measurement/Delay",
        "speed_scale": base + "Caculate_measurement/Gain1",
    }
    print(json.dumps(component(paths) if arguments.scope == "component" else shell()))
