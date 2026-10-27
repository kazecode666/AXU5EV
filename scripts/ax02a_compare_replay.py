"""Compare AX02A row-major LE float64 outputs and optional R5 tick records.

Exit 0 means the supplied files pass the numeric/timing gate. Execution origin
is supplied by the caller and must never be inferred from a successful compare.
"""
import argparse
from array import array
import csv
import json
import math
from pathlib import Path
import struct
import sys

FIELDS = [
    'id_ref_A','iq_ref_A','v_ref_mmps','Init_Done','Init_State_Num',
    'id_init_ref_A','Angle_Init_EN','Theta_Offset_auto_rad','x_align_mm_latch',
    'alignment_ready','done_or_bypass','alignment_fault','x_ref_mm','Vdc_V',
    'load_N','Close_Loop_EN','Position_Loop_EN','PWM_request','v_ref_cmd',
    'id_ref_cmd','iq_test_mode','iq_test_ref','PI_Reset_request',
    'accepted_target_mm','Busy','in_position','command_status','segment_start_mm',
    'segment_start_s','trajectory_done','Ready','accepted_count','rejected_count',
    'segment_id','command_receive_s','interrupted','trajectory_V','trajectory_A',
    'trajectory_J','minRamp','Ts']
EXACT = {3,4,6,9,10,11,15,16,17,20,22,24,25,26,29,30,31,32,33,35}


def read_doubles(path, frames, width):
    expected = frames * width * 8
    if path.stat().st_size != expected:
        raise ValueError(f'{path}: expected {expected} bytes, got {path.stat().st_size}')
    data = array('d')
    with path.open('rb') as stream:
        data.fromfile(stream, frames * width)
    if sys.byteorder != 'little':
        data.byteswap()
    return data


def write_csv(path, rows):
    with path.open('w', newline='', encoding='utf-8') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]), lineterminator='\n')
        writer.writeheader()
        writer.writerows(rows)


def compare(reference, actual, frames, ts):
    stats = []
    for j, field in enumerate(FIELDS):
        maximum, maximum_k, sum_squared, first, failures = 0.0, 0, 0.0, None, 0
        for k in range(frames):
            expected, observed = reference[41*k+j], actual[41*k+j]
            finite = math.isfinite(expected) and math.isfinite(observed)
            delta = abs(observed-expected) if finite else math.inf
            if delta > maximum:
                maximum, maximum_k = delta, k
            sum_squared += delta*delta
            good = finite and (observed == expected if j in EXACT else
                               delta <= 1e-9 + 1e-9*abs(expected))
            if not good:
                failures += 1
                if first is None:
                    first = k
        stats.append(dict(field=j+1, name=field, comparison='exact' if j in EXACT else 'abs_rel_1e-9',
                          max_abs=maximum, rms=math.sqrt(sum_squared/frames), max_frame=maximum_k,
                          first_mismatch_frame='' if first is None else first,
                          first_mismatch_s='' if first is None else first*ts, failures=failures))
    return stats


def events(data, frames, ts):
    result = []
    previous = None
    indices = [4,26,30,31,32,33,35]
    for k in range(frames):
        current = tuple(data[41*k+j] for j in indices)
        if previous is None or current != previous:
            result.append(dict(frame=k, time_s=k*ts, Init_State_Num=current[0],
                               command_status=current[1], Ready=current[2],
                               accepted=current[3], rejected=current[4], segment_id=current[5],
                               interrupted=current[6], target_mm=data[41*k+23],
                               offset_rad=data[41*k+7]))
        previous = current
    return result


def timing_stats(path, frames, hz, period, outputs):
    if hz <= 0 or not math.isfinite(hz):
        raise ValueError('timer-hz must be finite and positive')
    payload = path.read_bytes()
    if len(payload) != frames*64:
        raise ValueError('timing record length does not match frame count (8 uint64 per frame)')
    records = list(struct.iter_unpack('<8Q', payload))
    epoch = records[0][2]
    # The source is configured from TTC ClockHz/interval/prescaler. Metadata
    # carries the actual measured/configured tick period, not rounded microseconds.
    if period <= 0:
        raise ValueError('period-ticks must be positive')
    groups = {name: [] for name in ['all','ordinary','speed_due','position_due','command_event','alignment_transition']}
    anomalies = []
    for k, record in enumerate(records):
        frame, seq, expected, release, start, step_begin, step_end, completion = record
        scheduled = epoch + round(k*period)
        if frame != k or seq != k or abs(expected-scheduled)>1:
            anomalies.append(dict(frame=k, reason='frame/sequence/expected_release mismatch'))
        if not expected <= release <= start <= step_begin <= step_end <= completion:
            anomalies.append(dict(frame=k, reason='nonmonotonic timestamps or early release'))
        slack = expected + period - completion
        if slack <= 0:
            anomalies.append(dict(frame=k, reason='deadline missed', slack_ticks=slack))
        sample = dict(frame=k, runtime_us=(step_end-step_begin)*1e6/hz,
                      task_us=(completion-start)*1e6/hz, response_us=(completion-expected)*1e6/hz,
                      jitter_us=(start-expected)*1e6/hz, slack_us=slack*1e6/hz)
        groups['all'].append(sample)
        classification = 'position_due' if k%100 == 99 else 'speed_due' if k%10 == 9 else 'ordinary'
        groups[classification].append(sample)
        if k and any(outputs[41*k+j] != outputs[41*(k-1)+j] for j in [31,32,33]):
            groups['command_event'].append(sample)
        if not k or outputs[41*k+4] != outputs[41*(k-1)+4]:
            groups['alignment_transition'].append(sample)
    summaries = []
    for group, samples in groups.items():
        if not samples:
            continue
        for metric in ['runtime_us','task_us','response_us','jitter_us','slack_us']:
            ordered = sorted(samples, key=lambda s:s[metric])
            worst = ordered[0] if metric == 'slack_us' else ordered[-1]
            summaries.append(dict(category=group, metric=metric, samples=len(samples),
                                  mean=sum(s[metric] for s in samples)/len(samples),
                                  p99=ordered[math.ceil(.99*len(samples))-1][metric],
                                  minimum=ordered[0][metric], maximum=ordered[-1][metric],
                                  worst_frame=worst['frame']))
    return summaries, anomalies


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--metadata', type=Path, required=True)
    parser.add_argument('--reference', type=Path, required=True)
    parser.add_argument('--actual', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--timing', type=Path)
    parser.add_argument('--timer-hz', type=float)
    parser.add_argument('--period-ticks', type=int, help='actual TTC interval * prescaler divisor')
    parser.add_argument('--origin', default='UNSPECIFIED', choices=['UNSPECIFIED','HOST','BOARD','SIMULATED'])
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    try:
        metadata = json.loads(args.metadata.read_text(encoding='utf-8-sig'))
        frames, ts = int(metadata['frames']), float(metadata['Ts'])
        if frames <= 0 or ts != .0001:
            raise ValueError('expected positive frame count and 100us Runtime step')
        reference = read_doubles(args.reference, frames, 41)
        actual = read_doubles(args.actual, frames, 41)
        stats = compare(reference, actual, frames, ts)
        write_csv(args.output/'signals.csv', stats)
        write_csv(args.output/'events.csv', events(actual, frames, ts))
        anomalies = []
        if args.timing:
            if args.timer_hz is None:
                raise ValueError('--timer-hz is required with --timing')
            period=args.period_ticks if args.period_ticks is not None else round(ts*args.timer_hz)
            timing, anomalies = timing_stats(args.timing, frames, args.timer_hz, period, actual)
            write_csv(args.output/'timing.csv', timing)
        passed = not any(s['failures'] for s in stats) and not anomalies
        summary = dict(passed=passed, origin=args.origin, frames=frames,
                       numerical_failures=sum(s['failures'] for s in stats),
                       timing='PASS' if args.timing and not anomalies else 'FAIL' if args.timing else 'NOT_RUN',
                       anomalies=anomalies)
        if args.timing:
            summary['actual_period_us']=period*1e6/args.timer_hz
            summary['period_quantization_us']=summary['actual_period_us']-ts*1e6
        (args.output/'summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8', newline='\n')
        print(json.dumps(summary))
        return 0 if passed else 1
    except (ValueError, OSError, KeyError, OverflowError) as error:
        print(f'FAIL: {error}', file=sys.stderr)
        (args.output/'summary.json').write_text(json.dumps({'passed':False,'error':str(error)}), encoding='utf-8', newline='\n')
        return 1


if __name__ == '__main__':
    sys.exit(main())
