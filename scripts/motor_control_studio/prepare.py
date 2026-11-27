"""Prepare an existing no-power candidate without opening any debug target."""

import json
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


@dataclass(frozen=True)
class Candidate:
    workspace: Path
    launch: str
    config: Path
    bit: Path
    ltx: Path
    xsa: Path
    elf: Path
    fsbl: Path
    psu_init: Path

    @classmethod
    def load(cls, profile):
        preset = {"SELFTEST": "selftest.timing", "REAL": "real.r03"}[profile]
        config = json.loads((ROOT / f"firmware/r5/motor_control/build_config.gem3.{preset}.json")
                            .read_text(encoding="utf-8"))
        workspace = ROOT / config["workspace"]
        app = workspace / "ax04b_realtime"
        platform = workspace / "ax04b_platform"
        candidate = cls(workspace, config["launch"], app / "_ide/launch.json",
                        ROOT / config["bitstream"], ROOT / config["ltx"], ROOT / config["xsa"],
                        app / "build/ax04b_realtime.elf",
                        platform / "export/ax04b_platform/sw/boot/fsbl.elf",
                        platform / "hw/sdt/psu_init.tcl")
        for path in (candidate.config, candidate.bit, candidate.ltx, candidate.xsa, candidate.elf,
                     candidate.fsbl, candidate.psu_init):
            if not path.is_file():
                raise FileNotFoundError(path)
        options = json.loads(candidate.config.read_text(encoding="utf-8"))["configurations"]
        matches = [option["targetSetup"] for option in options if option["name"] == candidate.launch]
        if len(matches) != 1:
            raise ValueError("找不到唯一匹配的 Vitis 启动项")
        setup = matches[0]
        elf = setup["downloadElf"][0]
        fsbl = setup["zuInitialization"]["usingFSBL"]
        expected_elf = "${workspaceFolder}/" + candidate.elf.relative_to(workspace).as_posix()
        expected_fsbl = "${workspaceFolder}/" + candidate.fsbl.relative_to(workspace).as_posix()
        elf_file, fsbl_file = elf["elfFile"], fsbl["fsblFile"]
        if (setup.get("programDevice") is not False or elf.get("stopAtEntry") is not True
                or elf["core"] != "psu_cortexr5_0" or not isinstance(elf_file, str)
                or elf_file.replace("\\", "/") != expected_elf
                or not fsbl["initWithFSBL"] or not isinstance(fsbl_file, str)
                or fsbl_file.replace("\\", "/") != expected_fsbl):
            raise ValueError("启动项必须使用配套 FSBL/ELF，并将 R5 停在入口")
        return candidate

    def save_xsdb(self, path):
        with path.open("x", encoding="utf-8", newline="\n") as stream:
            stream.write(
                "# Run in the existing XSDB session after Vitis has paused R5 at entry.\n"
                'targets -set -filter {name =~ "PL"}\n'
                f"fpga -file {tcl_path(self.bit)}\n"
                'targets -set -filter {name =~ "Cortex-A53 #0"}\n'
                f"source {tcl_path(self.psu_init)}\n"
                "psu_ps_pl_isolation_removal\n"
                "psu_ps_pl_reset_config\n"
                'targets -set -filter {name =~ "Cortex-R5 #0"}\n'
                'puts "PL/PS-PL operations finished. Verify the target before continuing R5_0."\n'
            )


def tcl_path(path):
    value = path.resolve().as_posix()
    for char in ('\\', '"', '$', '[', ']'):
        value = value.replace(char, '\\' + char)
    return '"' + value + '"'
