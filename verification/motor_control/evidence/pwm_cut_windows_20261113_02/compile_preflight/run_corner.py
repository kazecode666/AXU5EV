"""One-shot corner runner. Importing this file never starts simulation."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parent
LIMITS = {'xvlog': 600, 'xelab': 3600, 'xsim': 900}
TIMING = re.compile(r'timing\s+violation|(?:setup|hold|recovery|removal)\s+violation|\$(?:setuphold|setup|hold|recrem|recovery|removal).*?(?:violation|failed)', re.I)
SDF_ERROR = re.compile(r'(?:SDF|back.?annotat|INTERCONNECT).*?(?:error|fail|mismatch|not found|cannot|unable|unmatched|does not match|missing)|(?:error|fail|mismatch|cannot|unable|unmatched).*?(?:SDF|back.?annotat)', re.I)
DIAG = re.compile(r'\b(?:WARNING|ERROR|FATAL)\b|PWM_CUT(?:_SDF)?_FAIL|assertion.*fail', re.I)
PASS = re.compile(r'^PWM_CUT_SDF_PASS(?:\s+.*)?$')

def reviewed(line, stage, tb):
    # Three individually reviewed old TB messages; exact message and TB path.
    # No code-only or arbitrary-warning exemption. Changed text fails closed.
    if stage != 'xelab':
        return False
    path = re.escape(tb.as_posix())
    line = line.replace('\\', '/')
    patterns = [
        rf"WARNING: \[VRFC 10-3645\] port 's_axi_rresp' remains unconnected for this instance \[{path}:\d+\]",
        rf'WARNING: \[XSIM 43-4328\] File: {path} Line: \d+ : Sensitivity on input argument "id" of task "finish_offer" may never get triggered\.',
    ]
    return any(re.fullmatch(p, line) for p in patterns)

class Monitor:
    def __init__(self, run, stage, rec, tb):
        self.run, self.stage, self.rec, self.tb = run, stage, rec, tb
        self.offsets, self.tails, self.seen = {}, {}, set()
        self.reason = None
        rec.update(diagnostics=[], reviewed_warnings=[], annotation_markers=[], pass_markers=[],
                   last_scenario=None, last_simulation_time=None, last_progress_line=None, log_files=[])

    def line(self, path, text, complete=True, terminated=True):
        text = text.strip()
        if not text:
            return
        key = (str(path), text)
        if complete and key in self.seen:
            # PASS occurrences must not be deduplicated within canonical stdout.
            if not (self.stage == 'xsim' and path.name == 'xsim.stdout.log' and PASS.fullmatch(text)):
                return
        if complete:
            self.seen.add(key)
        category = None
        if TIMING.search(text):
            category = 'timing_violation'
        elif SDF_ERROR.search(text):
            category = 'sdf_matching_or_annotation_error'
        elif DIAG.search(text):
            if not complete:
                return
            if reviewed(text, self.stage, self.tb):
                self.rec['reviewed_warnings'].append({'source': str(path), 'line': text})
                return
            category = 'unknown_warning' if re.search('warning', text, re.I) else 'tool_or_testbench_error'
        if category:
            item = {'category': category, 'source': str(path), 'line': text}
            if item not in self.rec['diagnostics']:
                self.rec['diagnostics'].append(item)
            self.reason = self.reason or category + ': ' + text
        if not complete:
            return
        if self.stage == 'xelab' and re.search(r'INFO: \[XSIM 43-3452\] SDF backannotation was successful', text):
            self.rec['annotation_markers'].append({'source': str(path), 'line': text})
        if terminated and self.stage == 'xsim' and path.name == 'xsim.stdout.log' and PASS.fullmatch(text):
            self.rec['pass_markers'].append(text)
        if re.search(r'scenario|PWM_CUT.*(?:PROGRESS|STARTUP|START|PEAK|ADOPT|SOURCE_COVERAGE|BEGIN|CASE|STAGE)', text, re.I):
            self.rec['last_scenario'] = text
        # Simulation timestamps come only from tool/TB logs, never heartbeat wall time.
        stamp_ns = re.search(r'\bt_ns\s*=\s*([0-9.]+)', text, re.I)
        stamp = re.search(r'(?:\bt\s*=|\btime\s*[:=]?\s*)([0-9.]+\s*(?:fs|ps|ns|us|ms|s)?)', text, re.I)
        if stamp_ns:
            self.rec['last_simulation_time'] = stamp_ns.group(1) + ' ns'
        elif stamp:
            self.rec['last_simulation_time'] = stamp.group(1).strip()
        self.rec['last_progress_line'] = text

    def scan(self, final=False):
        paths = [self.run / (self.stage + '.stdout.log'), self.run / (self.stage + '.stderr.log')]
        # Include native kernel/crash/subdirectory logs; earlier stages were already
        # drained and validated, and must not be reclassified as xsim warnings.
        paths += sorted(p for p in self.run.rglob('*.log')
                        if not p.name.endswith(('.stdout.log', '.stderr.log', '.termination.log'))
                        and not (p.parent == self.run and p.name in
                                 {n + '.log' for n in LIMITS if n != self.stage}))
        for path in paths:
            if not path.exists():
                continue
            key = str(path.relative_to(self.run))
            if key not in self.rec['log_files']:
                self.rec['log_files'].append(key)
            with path.open('rb') as f:
                f.seek(self.offsets.get(key, 0))
                data = f.read()
                self.offsets[key] = f.tell()
            lines = (self.tails.get(key, b'') + data).split(b'\n')
            self.tails[key] = lines.pop()
            for line in lines:
                self.line(path, line.decode('utf-8', errors='replace'))
            if self.tails[key]:
                self.line(path, self.tails[key].decode('utf-8', errors='replace'), complete=final, terminated=False)
                if final:
                    self.tails[key] = b''

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('corner', choices=['slow', 'fast'])
    parser.add_argument('--tb', type=Path, default=ROOT / 'pwm_cut_tb.sv')
    parser.add_argument('--bin', type=Path, default=Path('D:/Software/2026.1/Vivado/bin'))
    args = parser.parse_args()
    tb = args.tb.resolve()
    netlist = ROOT / 'pwm_cut.v'
    sdf = ROOT / ('pwm_cut_' + args.corner + '.sdf')
    glbl = args.bin.parent.parent / 'data/verilog/src/glbl.v'
    inputs = [netlist, sdf, tb, glbl]
    for path in inputs + [args.bin / (name + '.bat') for name in LIMITS]:
        if not path.is_file():
            parser.error('missing required input: ' + str(path))
    input_paths = {name: str(path.resolve()) for name, path in
                   [('netlist', netlist), ('sdf', sdf), ('tb', tb), ('glbl', glbl)]}
    if args.corner == 'fast':
        slow_path = ROOT / 'slow' / 'summary.json'
        if not slow_path.is_file():
            parser.error('fast blocked: this new directory slow must actually PASS first')
        slow = json.loads(slow_path.read_text(encoding='utf-8'))
        stages = slow.get('stages', [])
        valid = (slow.get('status') == 'PASS' and slow.get('runner_schema') == 2
                 and [s.get('stage') for s in stages] == list(LIMITS)
                 and all(s.get('natural_exit') and s.get('exit_code') == 0 and not s.get('supervisor_stop') and not s.get('diagnostics') for s in stages)
                 and stages[1].get('annotation_markers') and len(stages[2].get('pass_markers', [])) == 1
                 and slow.get('run_directory') == str((ROOT / 'slow').resolve())
                 and all(slow.get('input_paths', {}).get(key) == input_paths[key]
                         for key in ['netlist', 'tb', 'glbl'])
                 and slow.get('input_paths', {}).get('sdf') == str((ROOT / 'pwm_cut_slow.sdf').resolve()))
        if not valid:
            parser.error('fast blocked: slow PASS evidence or recorded absolute paths invalid')
    run = ROOT / args.corner
    run.mkdir(exist_ok=False)  # Exclusive claim; no resume, retry or overwrite.
    result = {'runner_schema': 2, 'corner': args.corner, 'status': 'RUNNING', 'input_paths': input_paths,
              'run_directory': str(run.resolve()),
              'stages': [], 'limits_seconds': LIMITS, 'optimization': 'O2 only; one attempt',
              'timing_checks_disabled': False, 'board': 'NOT_RUN', 'stop_reason': None}
    def save():
        (run / 'summary.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    def kill_tree(process, rec, name):
        with (run / (name + '.termination.log')).open('ab') as log:
            killed = subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'], stdout=log, stderr=log)
        rec['taskkill_exit_code'] = killed.returncode
        process.wait(timeout=30)
    def stage(name, argv):
        command = '"' + os.environ.get('COMSPEC', 'C:/Windows/System32/cmd.exe') + '" /d /s /c "' + subprocess.list2cmdline(argv) + '"'
        rec = {'stage': name, 'argv': argv, 'command': command, 'limit_seconds': LIMITS[name],
               'started_epoch': time.time(), 'supervisor_stop': None, 'natural_exit': False,
               'exit_code': None, 'elapsed_seconds': None}
        result['stages'].append(rec)
        monitor = Monitor(run, name, rec, tb)
        save()
        start, process, heartbeat = time.monotonic(), None, 0.0
        try:
            with (run / (name + '.stdout.log')).open('xb') as out, (run / (name + '.stderr.log')).open('xb') as err:
                process = subprocess.Popen(command, cwd=run, stdout=out, stderr=err)
                rec['pid'] = process.pid
                while True:
                    monitor.scan()
                    if process.poll() is not None:
                        rec['natural_exit'] = True
                        break
                    reason = monitor.reason
                    if reason is None and time.monotonic() - start >= LIMITS[name]:
                        reason = 'wall_clock_limit_exceeded'
                    if reason:
                        rec['supervisor_stop'] = reason
                        kill_tree(process, rec, name)
                        break
                    rec['elapsed_seconds'] = time.monotonic() - start
                    save()
                    if time.monotonic() - heartbeat >= 2:
                        print(json.dumps({'stage': name, 'wall_seconds': rec['elapsed_seconds'], 'last_scenario': rec['last_scenario'], 'last_simulation_time': rec['last_simulation_time'], 'last_progress_line': rec['last_progress_line']}), flush=True)
                        heartbeat = time.monotonic()
                    time.sleep(0.25)
            monitor.scan(final=True)
            rec['exit_code'] = process.returncode
            rec['failure_reason'] = rec['supervisor_stop'] or monitor.reason or (None if process.returncode == 0 else 'nonzero_exit')
            return rec['failure_reason'] is None
        finally:
            if process is not None and process.poll() is None:
                rec['supervisor_stop'] = rec['supervisor_stop'] or 'runner_exception_or_interrupt'
                try:
                    kill_tree(process, rec, name)
                finally:
                    rec['exit_code'] = process.poll()
            rec['elapsed_seconds'] = time.monotonic() - start
            save()
    save()
    try:
        commands = [
            ('xvlog', ['-sv', str(netlist), str(tb), str(glbl)]),
            ('xelab', ['work.pwm_cut_tb', 'work.glbl', '-s', 'pwm_cut_timing', '-debug', 'off', '-timescale', '1ns/1ps', '-L', 'simprims_ver', '-L', 'unisims_ver', '-L', 'secureip', '-transport_int_delays', '-pulse_r', '0', '-pulse_int_r', '0', '-pulse_e', '0', '-pulse_int_e', '0', '-sdfmax' if args.corner == 'slow' else '-sdfmin', '/pwm_cut_tb/dut=' + sdf.as_posix(), '--O2']),
            ('xsim', ['pwm_cut_timing', '-runall']),
        ]
        for name, command_args in commands:
            if not stage(name, [str(args.bin / (name + '.bat'))] + command_args):
                raise RuntimeError(result['stages'][-1]['failure_reason'])
            if name == 'xelab' and not result['stages'][-1]['annotation_markers']:
                raise RuntimeError('missing XSIM 43-3452 successful annotation')
        if len(result['stages'][-1]['pass_markers']) != 1:
            raise RuntimeError('first xsim needs exactly one complete PWM_CUT_SDF_PASS stdout line')
        result['status'] = 'PASS'
        result['stop_reason'] = 'all stages naturally exited zero; annotation and unique dynamic PASS confirmed'
    except BaseException as exc:
        result['status'] = 'FAIL'
        result['stop_reason'] = type(exc).__name__ + ': ' + str(exc)
    finally:
        result['last_scenario'] = result['stages'][-1].get('last_scenario') if result['stages'] else None
        result['last_simulation_time'] = result['stages'][-1].get('last_simulation_time') if result['stages'] else None
        result['total_stage_wall_seconds'] = sum(s.get('elapsed_seconds') or 0 for s in result['stages'])
        save()
    print(json.dumps(result, indent=2), flush=True)
    return 0 if result['status'] == 'PASS' else 1

if __name__ == '__main__':
    sys.exit(main())
