"""Run the firmware's real dispatch and generated R5 control on a host."""
import argparse
import os
from pathlib import Path
import re
import subprocess


BSP = """#pragma once
#include <stdint.h>
typedef uintptr_t UINTPTR;
typedef struct { int unused; } XScuGic;
typedef struct { UINTPTR CpuBaseAddress; } XScuGic_Config;
typedef void (*Xil_ExceptionHandler)(void *);
enum { XIL_EXCEPTION_ID_IRQ_INT, XIL_EXCEPTION_IRQ, XST_SUCCESS };
#define XPAR_XSCUGIC_0_BASEADDR 0xf9000000u
#define AX04B_MMIO_BASE 0x80002000u
#define AX04B_DIAG_BASE 0x80000000u
#define AX04B_FABRIC_IRQ 121u
uint32_t Xil_In32(UINTPTR address);
void Xil_Out32(UINTPTR address, uint32_t value);
XScuGic_Config *XScuGic_LookupConfig(UINTPTR address);
int XScuGic_CfgInitialize(XScuGic *, XScuGic_Config *, UINTPTR);
int XScuGic_Connect(XScuGic *, uint32_t, Xil_ExceptionHandler, void *);
void XScuGic_Disable(XScuGic *, uint32_t);
void XScuGic_Enable(XScuGic *, uint32_t);
void XScuGic_SetPriorityTriggerType(XScuGic *, uint32_t, uint8_t, uint8_t);
void XScuGic_InterruptHandler(void *);
void Xil_ExceptionRegisterHandler(int, Xil_ExceptionHandler, void *);
void Xil_ExceptionEnableMask(int);
void Xil_ExceptionDisableMask(int);
void Xil_ExceptionInit(void);
void Xil_ICacheEnable(void);
void Xil_DCacheEnable(void);
int xil_printf(const char *, ...);
"""


def single_replacement(source, pattern, replacement):
    result, count = re.subn(pattern, replacement, source, flags=re.MULTILINE | re.DOTALL)
    if count != 1:
        raise RuntimeError(f"Expected one Cortex-R5 platform primitive for {pattern}, found {count}")
    return result


def local_main(source):
    # Preserve the IRQ, commands, initialization, diagnostics, and MMIO calls.
    # Only assembly instructions for the target CPU are excluded on the host.
    for call, body in (
        ("barrier", ""),
        ("completion_barrier", ""),
        ("pmu_tick", "static uint32_t value; return ++value;"),
        ("pmu_divisor", "return 1u;"),
        ("irq_lock", "return host_irq_lock();"),
        ("irq_unlock", "host_irq_unlock(cpsr);"),
    ):
        pattern = rf"(static (?:inline )?(?:void|uint32_t) {call}\([^\n]*\)\n\{{).*?^\}}"
        source = single_replacement(source, pattern, rf"\g<1>\n    {body}\n}}")
    if "__asm__" in source:
        raise RuntimeError("Unrecognized target assembly in host copy")
    return source


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True, help="new, isolated log directory")
    parser.add_argument("--cc", default="gcc")
    parser.add_argument("--generated", type=Path,
                        default=Path("generated/experiment/ax04b_r1_01/r5"))
    parser.add_argument("--firmware-ref", help="Git revision of the firmware, for old counterexamples")
    parser.add_argument("--expect-old", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[3]
    output = args.output.resolve()
    output.mkdir(parents=True)  # An existing result is evidence and must not be overwritten.
    generated = args.generated.resolve()
    firmware = Path("firmware/r5/motor_control/ax04b")
    env = dict(os.environ)
    compiler = Path(args.cc)
    if compiler.is_absolute():
        env["PATH"] = str(compiler.parent) + os.pathsep + env["PATH"]

    for file in ("ax04b_main.c", "ax04b_adapter.c", "ax04b_adapter.h", "ax04b_registers.h"):
        relative = (firmware / file).as_posix()
        source = (subprocess.check_output(["git", "show", f"{args.firmware_ref}:{relative}"],
                                          cwd=root).decode("utf-8")
                  if args.firmware_ref else (root / relative).read_text(encoding="utf-8"))
        if file == "ax04b_main.c":
            file = "ax04b_main_host.inc"
            source = local_main(source)
        (output / file).write_text(source, encoding="utf-8", newline="\n")

    for file in ("ax04b_bsp.h", "xil_cache.h", "xil_exception.h", "xil_io.h",
                 "xil_printf.h", "xparameters.h", "xscugic.h"):
        (output / file).write_text('#include "ax04b_host_platform.h"\n', encoding="utf-8")
    (output / "ax04b_host_platform.h").write_text(BSP, encoding="utf-8", newline="\n")

    sources = [generated / file for file in ("AXU5EV_Motor_Control_System.c",
               "AXU5EV_Motor_Control_System_data.c", "rtGetInf.c", "rtGetNaN.c", "rt_nonfinite.c")]
    if not all(file.is_file() for file in sources):
        raise FileNotFoundError(f"Expected all model compilation units in {generated}")
    header = (generated / "AXU5EV_Motor_Control_System.h").read_text(encoding="utf-8")
    version = re.search(r"Model version\s*:\s*(\S+)", header)
    if not version or version.group(1) != "1.173" or "ARM Cortex-R" not in header:
        raise ValueError("Expected the verified PR48 v1.173 Cortex-R generated source")
    profile_cases = [(1, ["old-late", "old-armed", "old-inhibit"])] if args.expect_old else [
        (1, ["late", "rejected", "armed", "inhibit", "accepted-loss", "stale", "duplicate",
             "boundary", "boundary-late", "normal", "clear"]),
        (2, ["real"]),
    ]
    with (output / "result.txt").open("x", encoding="utf-8") as log:
        print(f"model={version.group(1)} source={generated}", file=log, flush=True)
        print(f"firmware={args.firmware_ref or subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip() + '+worktree'}", file=log, flush=True)
        for mode, scenarios in profile_cases:
            binary = output / f"r5_runtime_{mode}.exe"
            subprocess.run([args.cc, "-std=c11", "-O2", "-Wall", "-Wextra", "-Werror",
                            "-fno-fast-math", "-ffp-contract=off", f"-DAX04B_BUILD_MODE={mode}",
                            f"-DAX04B_TEST_FIXED={int(not args.expect_old)}",
                            f"-I{output}", f"-I{generated}",
                            str(Path(__file__).with_name("test_r5_runtime.c")),
                            str(output / "ax04b_adapter.c"), *map(str, sources), "-lm",
                            "-o", str(binary)], cwd=root, env=env, check=True)
            for case in scenarios:
                result = subprocess.run([str(binary), case], cwd=output, env=env,
                                        input="65536 65536\n" if mode == 2 else "",
                                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
                print(result.stdout, end="", file=log, flush=True)
                print(result.stdout, end="", flush=True)
                result.check_returncode()


if __name__ == "__main__":
    main()
