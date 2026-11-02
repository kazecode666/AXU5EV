"""Build the common replay runner with generated Cortex-R C on the PC.

This checks call integration and numerics; it deliberately does not claim a
target ELF or target execution time. gcc path is an explicit argument.
"""
import argparse
from pathlib import Path
import subprocess

ROOT=Path(__file__).resolve().parents[1]


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--gcc',type=Path,required=True)
    p.add_argument('--generated',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
    generated=a.generated.resolve()
    sources=sorted(str(f) for f in generated.glob('*.c') if f.name!='ert_main.c')
    if not sources:raise SystemExit('no generated C sources')
    common=[str(a.gcc),'-std=c11','-O2','-fno-fast-math','-ffp-contract=off',
            '-Wall','-Wextra','-I'+str(generated),
            '-I'+str(ROOT/'integration/r5_host'),'-I'+str(ROOT/'firmware/r5/ax02a'),
            str(ROOT/'firmware/r5/ax02a/replay_runner.c'),
            str(ROOT/'integration/r5_host/ax01b_r5_bridge.c'),*sources]
    for name,source in [('host_replay',ROOT/'firmware/r5/ax02a/host_replay.c'),
                        ('runner_contract_test',ROOT/'verification/ax02a/runner_contract_test.c')]:
        subprocess.run([*common,str(source),'-lm','-o',str(a.output/(name+'.exe'))],check=True)
    subprocess.run([str(a.output/'runner_contract_test.exe')],check=True)


if __name__=='__main__':main()
