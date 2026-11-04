"""Read the saved C2 fail1200 experiment; no target/network/build operations."""
import argparse
from array import array
import json
import math
from pathlib import Path
import re
import statistics
import struct
import sys
from ax02a_compare_replay import compare

ROOT = Path(__file__).resolve().parents[1]
TICK_FIELDS = ('record_index', 'command_seq', 'pl_frame', 'result_seq',
    'prepare_begin', 'step_begin', 'step_end', 'adapt_end', 'commit_end',
    'wait_begin', 'read_begin', 'read_end', 'adopted_seq', 'capture_edge',
    'status', 'reserved')
PL_FIELDS = ('record_index', 'runtime_step', 'pl_frame', 'command_seq',
             'adopted_seq', 'duty_u', 'duty_v', 'duty_w')
METRICS = {'input_copy': (5, 4), 'runtime': (6, 5),
    'output_copy_and_adapter': (7, 6), 'axi_write_commit': (8, 7),
    'prepare_commit': (8, 4), 'poll_wait': (10, 9), 'result_read': (11, 10)}


def doubles(path, values=None):
    data = array('d')
    with path.open('rb') as stream:
        data.frombytes(stream.read() if values is None else stream.read(values * 8))
    if sys.byteorder != 'little':
        data.byteswap()
    return data


def phase(k):
    # Generated Runtime increments speed counter every step and position counter
    # at each speed event, retaining its original first phase.
    return 'position_10ms_due' if k % 100 == 99 else 'speed_1ms_due' if k % 10 == 9 else 'ordinary'


def summary(samples):
    ordered = sorted(samples, key=lambda item: item[1])
    n = len(ordered)
    return dict(samples=n, min_us=ordered[0][1], mean_us=statistics.mean(v for _, v in samples),
                p99_us=ordered[math.ceil(.99*n)-1][1], max_us=ordered[-1][1],
                max_record=ordered[-1][0])


def mrd_words(path):
    memory = {}
    for line in path.read_text(encoding='utf-8-sig').splitlines():
        match = re.match(r'^([0-9A-Fa-f]{8}):\s+([0-9A-Fa-f]{8})\s*$', line)
        if match:
            memory[int(match[1], 16)] = int(match[2], 16)
    return memory


def analyze(board, source):
    run = json.loads((board/'run.json').read_text(encoding='utf-8-sig'))
    transfer = json.loads((board/'transfer.json').read_text(encoding='utf-8-sig'))
    ticks = list(struct.iter_unpack('<16I', (board/'timing.bin').read_bytes()))
    pl = list(struct.iter_unpack('<8I', (board/'pl_result.bin').read_bytes()))
    n = run['result']['completed_frames']
    assert n == len(ticks) == len(pl) == 1200
    assert run['result'] == dict(status=11, completed_frames=1200, failed_frame=1200)
    hz = run['timer']['clock_hz']
    assert hz == 7812421 and run['measurement']['timing_schema'] == 'AX02C2_PMU16_V1'
    us = lambda later, earlier: ((later-earlier) & 0xffffffff)*1e6/hz
    window_us = (5000-316)*20e-3
    snapshot = mrd_words(board/'failure_frame_1200_xsdb.txt')
    failed_tick = tuple(snapshot[0x13012c00 + 4*j] for j in range(16))
    failed_pl = tuple(snapshot[0x18009600 + 4*j] for j in range(8))
    previous_tick = tuple(snapshot[0x13012bc0 + 4*j] for j in range(16))
    assert previous_tick == ticks[-1]

    prefix_actual = doubles(board/'output.bin')
    reference = doubles(source/'reference.bin')
    fields = compare(reference, prefix_actual, n, .0001)
    golden = list(struct.iter_unpack('<3I', (source/'foc_reference.bin').read_bytes()))
    numeric_failures = sum(row['failures'] for row in fields)
    duty_failures = sum(a != b for row, expected in zip(pl, golden) for a, b in zip(row[5:], expected))
    relationship_failures = sum(row[:5] != (k, k, k+1, k+1, k+1) for k, row in enumerate(pl))
    timing_identity_failures = sum((r[0], r[1], r[2], r[3], r[12], r[13], r[14]) !=
        (k, k+1, k+1, k+1, k+1, 315, 0) for k, r in enumerate(ticks))

    groups = {}
    for name in ('all', 'ordinary', 'speed_1ms_due', 'position_10ms_due'):
        ids = [k for k in range(n) if name == 'all' or phase(k) == name]
        groups[name] = {metric: summary([(k, us(ticks[k][a], ticks[k][b])) for k in ids])
                        for metric, (a, b) in METRICS.items()}
    windows = [(k, us(ticks[k][8], ticks[k-1][10])) for k in range(1, n)]
    failed_window = us(failed_tick[8], previous_tick[10])
    feedback = doubles(source/'feedback.bin')
    first_feedback = {name: next((k for k in range(len(feedback)//5) if feedback[k*5+j] != 0), None)
                      for j, name in enumerate(('ia_A', 'ib_A', 'ic_A', 'theta_rad', 'omega_radps'))}
    first_runtime = {name: next((k for k in range(len(reference)//41) if reference[k*41+j] != 0), None)
                     for j, name in [(0, 'id_ref_A'), (1, 'iq_ref_A'), (2, 'v_ref_mmps')]}
    events = []
    for k in (1198, 1199, 1200):
        f = list(feedback[5*k:5*(k+1)])
        y = reference[41*k:41*(k+1)]
        # Source-path inference only: these are the generated Convergent
        # rt_remd_snf(...,2) branch conditions, not hardware call tracing.
        scaled = [f[0]*2**24, f[1]*2**24, f[2]*2**24, f[3]*2**32,
                  f[4]*2**24, y[1]*2**24, y[0]*2**24, y[13]*2**24]
        events.append(dict(record=k, phase=phase(k), feedback=f, runtime_reference_iq=y[1],
            runtime_reference_v_ref=y[2],
            inferred_rounding_remainder_calls=sum(abs(v)<2**52 and abs(v)>.5 for v in scaled)))

    sizes = {p.name: p.stat().st_size for p in board.iterdir() if p.is_file()}
    backup = board.with_name('current_motion_01_fail1200_backup')
    backup_sizes = {p.name: p.stat().st_size for p in backup.iterdir() if p.is_file()}
    return dict(status='ORIGINAL_BOARD_FAILURE_ANALYZED', board_status='FAIL_SEQUENCE_AT_RECORD_1200',
        experiment=1, planned_frames=run['frames'], completed_frames=n, failure_record=1200,
        data_root=board.as_posix(), backup_root=backup.as_posix(), backup_exists=backup.is_dir(),
        original_file_bytes=sizes, backup_file_bytes=backup_sizes,
        source=source.as_posix(), source_build_id=hex(run['build_id']),
        network_mbps=transfer['final_status']['negotiated_mbps'],
        transport=dict(upload_seconds=transfer['upload_seconds'], download_seconds=transfer['download_seconds'],
                       reconnect_seconds=transfer['planned_reconnect_seconds'],
                       objects_downloaded=list(transfer['downloads'])),
        timebase=dict(name='PMU CPU/64', clock_hz=hz, nominal_pl_hz=50000000,
                      clock_hz_metadata=run['pl']['clock_hz_metadata'], frame_clocks=5000,
                      axi_publish_edge=316, nominal_publish_to_boundary_us=window_us),
        prefix_check=dict(records=n, runtime_values=n*41, runtime_numeric_failures=numeric_failures,
            max_runtime_abs=max(r['max_abs'] for r in fields),
            runtime_difference_fields=[r for r in fields if r['max_abs']],
            duty_values=n*3, duty_bit_failures=duty_failures,
            relationship_failures=relationship_failures, timing_identity_failures=timing_identity_failures,
            interpretation='Only the valid 1200-record prefix; not a complete64536-frame pass'),
        timing_groups=groups,
        timing_scope='Per-record groups include record0 preparation before START; next-frame window samples exclude record0 and cover successful records1..1199. Failure record1200 is separately read from the saved XSDB snapshot.',
        previous_read_begin_to_next_commit=dict(**summary(windows),
            above_nominal_window=sum(v>window_us for _, v in windows),
            smallest_nominal_margin_us=window_us-max(v for _, v in windows)),
        failure=dict(pl=dict(zip(PL_FIELDS, failed_pl)), pmu=dict(zip(TICK_FIELDS, failed_tick)),
            pmu_hex=[f'{v:08x}' for v in failed_tick], previous_pmu=dict(zip(TICK_FIELDS, previous_tick)),
            phase=phase(1200), previous_phase=phase(1199),
            durations_ticks={name: (failed_tick[a]-failed_tick[b]) & 0xffffffff for name,(a,b) in METRICS.items()},
            durations_us={name: us(failed_tick[a],failed_tick[b]) for name,(a,b) in METRICS.items()},
            previous_read_begin_to_commit_ticks=(failed_tick[8]-previous_tick[10]) & 0xffffffff,
            previous_read_begin_to_commit_us=failed_window,
            exceeds_nominal_window_us=failed_window-window_us,
            deadline_evidence='Previous read_begin cannot precede previous AXI publication; commit_end is after the COMMIT write and barrier. Its budget excess is approximate; exact AXI acceptance time is not sampled. The observed old adopted_seq directly proves the boundary was missed.',
            stopped_complete_frames=run['pl']['complete_frames'], hold_error=run['pl']['hold_error'],
            stop_status=run['pl']['stop_status']),
        data_dependent_transition=dict(first_nonzero_feedback_records=first_feedback,
            first_nonzero_runtime_reference_records=first_runtime, local_events=events,
            inference='k1199 first nonzero iq_ref/v_ref and 10ms branch; k1200 is ordinary but first nonzero physicalfeedback. Generated rounding activates additional remainder/math branches, matching the measured adapter jump. PMU does not isolate each function or identify cache/DDR contributions.'),
        conclusion='R5 serial result-read + prepare + commit misses next PL adopt boundary; no evidence of AUX/network/FOC numeric failure in valid prefix',
        limitations=['No board connection or rerun performed',
            'Configured clock conversion is approximate, not independently measured hardware frequency',
            'read_begin-to-commit excludes publication-to-poll observation latency and commit_end is a software timestamp',
            'No complete-scene or future-load WCET/timing signoff; candidate still needs separately authorized board validation'])


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--board', type=Path, default=ROOT/'.runtime/ax02c2/board/current_motion_01')
    p.add_argument('--source', type=Path, default=ROOT/'.runtime/ax02c2/prepared_04/data/current_motion')
    p.add_argument('--output', type=Path, required=True)
    a = p.parse_args()
    result = analyze(a.board.resolve(), a.source.resolve())
    a.output.parent.mkdir(parents=True, exist_ok=True)
    a.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8', newline='\n')
    print(json.dumps(dict(status=result['status'], prefix=result['prefix_check'], failure=result['failure'],
                          data_dependent_transition=result['data_dependent_transition']), indent=2))


if __name__ == '__main__':
    main()
