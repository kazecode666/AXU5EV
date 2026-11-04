"""Summarize only the saved PR24 perf_r1 board run; no board/build actions."""
import json
import math
from pathlib import Path
import statistics
import struct
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'scripts'))
from ax02a_compare_replay import compare, read_doubles
from ax02c2_analyze_failure import mrd_words, phase

BOARD = ROOT / '.runtime/ax02c2/board/current_motion_perf_r1_01'
OLD = ROOT / '.runtime/ax02c2/board/current_motion_01'
SOURCE = ROOT / '.runtime/ax02c2/prepared_04/data/current_motion'
OUT = Path(__file__).resolve().parent
N = 64536


def load(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def delta(later, earlier):
    return (later - earlier) & 0xffffffff


def summarize(samples, hz):
    ordered = sorted(samples, key=lambda item: item[1])
    n = len(ordered)
    return dict(samples=n, min_us=ordered[0][1]*1e6/hz,
                mean_us=statistics.mean(v for _, v in samples)*1e6/hz,
                p99_us=ordered[math.ceil(.99*n)-1][1]*1e6/hz,
                max_us=ordered[-1][1]*1e6/hz,
                max_records=[k for k, value in samples if value == ordered[-1][1]])


def main():
    run = load(BOARD / 'run.json')
    transfer = load(BOARD / 'transfer.json')
    saved_pl = load(BOARD / 'pl_summary.json')
    saved_numeric = load(BOARD / 'analysis/summary.json')
    hz = run['timer']['clock_hz']
    assert run['build_id'] == run['candidate']['build_id'] == 0x43324302
    assert run['result'] == dict(status=0, completed_frames=N, failed_frame=0)
    assert run['frames'] == N and run['captured_records'] == N
    assert run['measurement']['timing_schema'] == 'AX02C2_PMU16_V1'
    assert run['measurement']['output_log_placement'] == 'after commit_end; before wait_begin'
    assert hz == 7812421 and run['pl']['module_id'] == 0x43314301
    assert run['pl']['frame_clocks'] == 5000 and run['pl']['clock_hz_metadata'] == 49999500
    expected_sizes = dict(output_bin=N*41*8, timing_bin=N*64, pl_result_bin=N*32)
    actual_sizes = {name: (BOARD/name.replace('_bin', '.bin')).stat().st_size
                    for name in expected_sizes}
    assert actual_sizes == expected_sizes
    ticks = list(struct.iter_unpack('<16I', (BOARD/'timing.bin').read_bytes()))
    pl = list(struct.iter_unpack('<8I', (BOARD/'pl_result.bin').read_bytes()))
    golden = list(struct.iter_unpack('<3I', (SOURCE/'foc_reference.bin').read_bytes()))
    assert len(ticks) == len(pl) == len(golden) == N
    fields = compare(read_doubles(SOURCE/'reference.bin', N, 41),
                     read_doubles(BOARD/'output.bin', N, 41), N, .0001)
    numeric_failures = sum(row['failures'] for row in fields)
    duty_failures = sum(a != b for row, expected in zip(pl, golden)
                        for a, b in zip(row[5:], expected))
    relationship_failures = sum(row[:5] != (k, k, k+1, k+1, k+1)
                                for k, row in enumerate(pl))
    pmu_identity_failures = sum((t[0], t[1], t[2], t[3], t[12]) != (k, k+1, k+1, k+1, k+1)
                                for k, t in enumerate(ticks))
    capture_failures = sum(t[13] != 315 or t[14] != 0 or t[15] != 0 for t in ticks)
    p = run['pl']
    complete_stop = (p['complete_frames'] == p['last_frame'] == p['last_seq'] == N
                     and p['hold_error'] == p['stop_status'] == 0)
    assert numeric_failures == duty_failures == relationship_failures == pmu_identity_failures == capture_failures == 0
    assert complete_stop and saved_numeric['passed'] and saved_numeric['origin'] == 'BOARD'
    assert saved_numeric['frames'] == N and saved_numeric['numerical_failures'] == 0
    assert saved_pl['status'] == 'PASS' and saved_pl['records'] == N
    assert saved_pl['duty_comparisons'] == N*3 and saved_pl['complete_frame_stop']
    assert saved_pl['duty_bit_failures'] == saved_pl['relationship_failures'] == saved_pl['capture_failures'] == 0
    assert transfer['status'] == 'PASS' and transfer['errors'] == []
    assert transfer['initial_status']['build_id'] == transfer['final_status']['build_id'] == run['build_id']
    assert transfer['final_status']['completed_frames'] == N and transfer['final_status']['status'] == 0
    for name, item in transfer['downloads'].items():
        assert (BOARD/name).stat().st_size == item['bytes']

    # No new timestamps are invented. commit_end -> wait_begin bounds the
    # 328B log copy plus return/loop bookkeeping; the log alone is not isolated.
    pairs = {'input_copy': (5, 4), 'runtime': (6, 5), 'adapter_excluding_log': (7, 6),
             'axi_write_commit': (8, 7), 'prepare_commit': (8, 4),
             'post_commit_log_and_bookkeeping': (9, 8),
             'prepare_through_log': (9, 4), 'poll_wait': (10, 9),
             'result_read': (11, 10)}
    metrics = {name: [(k, delta(t[a], t[b])) for k, t in enumerate(ticks)]
               for name, (a, b) in pairs.items()}
    # Record0 was prepared before START; do not treat it as a steady-state
    # next-frame deadline sample. Its post-commit segment also contains START.
    for name in ('post_commit_log_and_bookkeeping', 'prepare_through_log'):
        metrics[name] = metrics[name][1:]
    metrics['previous_read_begin_to_commit'] = [(k, delta(ticks[k][8], ticks[k-1][10])) for k in range(1, N)]
    metrics['previous_read_end_to_commit'] = [(k, delta(ticks[k][8], ticks[k-1][11])) for k in range(1, N)]
    metrics['previous_read_begin_through_log'] = [(k, delta(ticks[k][9], ticks[k-1][10])) for k in range(1, N)]
    metrics['result_observation_interval'] = [(k, delta(ticks[k][10], ticks[k-1][10])) for k in range(1, N)]
    full = dict(all={name: summarize(values, hz) for name, values in metrics.items()})
    group_metrics = ('runtime', 'adapter_excluding_log', 'post_commit_log_and_bookkeeping',
                     'previous_read_begin_to_commit', 'previous_read_begin_through_log')
    for group in ('ordinary', 'speed_1ms_due', 'position_10ms_due'):
        full[group] = {name: summarize([(k, v) for k, v in metrics[name] if phase(k) == group], hz)
                       for name in group_metrics}

    # Confirm agreement with the already produced client statistics. No
    # writes to the raw board directory or replacement of prior analysis.
    names = dict(runtime='runtime', adapter_excluding_log='adapter', axi_write_commit='write_commit',
                 prepare_commit='prepare_commit', poll_wait='poll_wait', result_read='read_result',
                 previous_read_end_to_commit='next_record_prepare_commit', result_observation_interval='result_interval')
    for name, saved_name in names.items():
        for key in ('samples', 'min_us', 'mean_us', 'p99_us', 'max_us'):
            assert math.isclose(full['all'][name][key], saved_pl['statistics'][saved_name][key], rel_tol=1e-10, abs_tol=1e-8)

    old_run = load(OLD/'run.json')
    old_ticks = list(struct.iter_unpack('<16I', (OLD/'timing.bin').read_bytes()))
    memory = mrd_words(OLD/'failure_frame_1200_xsdb.txt')
    old_failed = tuple(memory[0x13012c00+4*j] for j in range(16))
    old_failed_pl = [memory[0x18009600+4*j] for j in range(8)]
    assert old_run['build_id'] == 0x43324301 and len(old_ticks) == 1200
    assert old_run['timer']['clock_hz'] == hz and old_run['result']['status'] == 11
    nominal = (5000-316)/50000000*1e6
    metadata_window = (5000-316)/run['pl']['clock_hz_metadata']*1e6

    def event(k, t, previous):
        spans = {name: delta(t[a], t[b])*1e6/hz for name, (a, b) in pairs.items()}
        spans['previous_read_begin_to_commit'] = delta(t[8], previous[10])*1e6/hz
        spans['previous_read_begin_through_log'] = delta(t[9], previous[10])*1e6/hz
        return dict(record=k, phase=phase(k), pmu_hex=[f'{v:08x}' for v in t], durations_us=spans)

    old_event = event(1200, old_failed, old_ticks[-1])
    # In the old image the log is inside step_end -> adapt_end, so use its
    # proper name rather than comparing old/new adapter columns as identical.
    old_event['durations_us']['output_log_and_adapter'] = old_event['durations_us'].pop('adapter_excluding_log')
    old_event['durations_us']['post_commit_bookkeeping_without_log'] = old_event['durations_us'].pop('post_commit_log_and_bookkeeping')
    old_event['durations_us']['previous_read_begin_to_wait_begin'] = old_event['durations_us'].pop('previous_read_begin_through_log')
    old_event['durations_us']['prepare_to_wait_begin'] = old_event['durations_us'].pop('prepare_through_log')
    old_event['pl_words_hex'] = [f'{v:08x}' for v in old_failed_pl]
    same_prefix = dict(old=summarize([(k, delta(old_ticks[k][8], old_ticks[k-1][10])) for k in range(1,1200)], hz),
                       new=summarize(metrics['previous_read_begin_to_commit'][:1199], hz))
    results = dict(status='BOARD_PASS', date='2026-11-04', repository='kazecode666/AXU5EV', pr=24,
        comment='https://github.com/kazecode666/AXU5EV/pull/24#issuecomment-6622743887',
        tested_source_commit='480a6cbe4a762e7a01504275706a4cdef6e64e07',
        build_id='0x43324302', board_root=BOARD.as_posix(), source_root=SOURCE.as_posix(),
        original_failure_root=OLD.as_posix(),
        original_backup_root=OLD.with_name('current_motion_01_fail1200_backup').as_posix(),
        original_backup_exists=OLD.with_name('current_motion_01_fail1200_backup').is_dir(),
        raw_paths={name: (BOARD/name).as_posix() for name in ('output.bin','timing.bin','pl_result.bin','report_v2.bin','UART.txt')},
        raw_bytes=actual_sizes,
        independent_saved_file_check=dict(runtime_values=N*41, numerical_failures=numeric_failures,
            maximum_runtime_absolute_difference=max(row['max_abs'] for row in fields),
            nonzero_difference_fields=[row for row in fields if row['max_abs']],
            duty_comparisons=N*3, duty_bit_failures=duty_failures,
            relationship_failures=relationship_failures, pmu_identity_failures=pmu_identity_failures,
            capture_or_status_failures=capture_failures, complete_frame_stop=complete_stop,
            archived_client_summaries_agree=True, downloaded_lengths_agree=True),
        timebase=dict(name='PMU CPU/64', clock_hz=hz, pl_hz_metadata=p['clock_hz_metadata'],
            frame_clocks=5000, result_publish_edge=316, nominal_publish_to_boundary_us=nominal,
            metadata_publish_to_boundary_us=metadata_window,
            percentile='nearest rank ceil(0.99*n); maxima list all tied zero-based record indices',
            initial_record='Record0 prepared before START; excluded from cross-record windows and post-commit/log summaries'),
        elapsed=dict(ticks=p['elapsed_ticks'], seconds=p['elapsed_ticks']/hz,
                     nominal_scene_seconds=N*.0001),
        transport=dict(upload_seconds=transfer['upload_seconds'], download_seconds=transfer['download_seconds'],
                       planned_reconnect_seconds=transfer['planned_reconnect_seconds'],
                       mbps=transfer['final_status']['negotiated_mbps']),
        statistics=full,
        nominal_window_comparison={name: dict(max_us=full['all'][name]['max_us'],
            nominal_remaining_us=nominal-full['all'][name]['max_us'],
            samples_above_nominal=sum(v*1e6/hz > nominal for _, v in metrics[name]))
            for name in ('previous_read_begin_to_commit', 'previous_read_begin_through_log')},
        baseline_comparison=dict(old_build_id='0x43324301', old_completed=1200, old_failure_record=1200,
            old_failure=old_event, new_same_records=[event(k,ticks[k],ticks[k-1]) for k in (1199,1200,1201)],
            same_successful_prefix_read_begin_to_commit=same_prefix),
        limitations=[
            'Only this recorded-feedback current_motion run; no WCET, real ADC/QEP/gate-PWM closed loop or same-frame50us signoff.',
            'post_commit_log_and_bookkeeping includes the 328B copy plus function/loop bookkeeping; copy alone has no timestamp.',
            'previous_read_begin_through_log includes the prior result read, next prepare/commit and its post-commit log, excluding polling idle.',
            'Nominal remaining time is a descriptive software-window comparison, not exact AXI acceptance slack; publication-to-observation latency is not measured.',
            'Configured PMU/PL frequency conversion is not independent physical clock measurement.',
            'Old adapter contains log copy; new adapter excludes it. No isolated per-function cycle savings inferred.',
            'Existing report_v2.bin retained without claiming a new board-report crosscheck; original TTC timing is not applicable.',
            'This archive reads saved local files only; no board operation, new experiment, build or regression run.'])
    (OUT/'timing_statistics.json').write_text(json.dumps(results, indent=2)+'\n', encoding='utf-8', newline='\n')
    print(json.dumps(dict(status=results['status'], checks=results['independent_saved_file_check'],
        elapsed=results['elapsed'], statistics=full['all'], comparison=results['nominal_window_comparison'],
        old1200=old_event, new1200=results['baseline_comparison']['new_same_records'][1]), indent=2))


if __name__ == '__main__':
    main()
