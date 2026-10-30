"""Gate saved run identity/completion before reusing the numeric/timing comparator."""
import argparse
import json
from pathlib import Path
import sys
import struct

sys.path.insert(0,str(Path(__file__).resolve().parent))
import ax02a_compare_replay as compare


def validate_timer(t):
    hz=t['clock_hz'];period=t['period_ticks']
    divisor=1<<(t['prescaler']+1) if 0<=t['prescaler']<16 else 1
    if t['prescaler'] not in range(17) or t['interval']*divisor!=period:
        raise ValueError('timer interval/prescaler/period mismatch')
    if not 0<=t['timestamp_read_min_ticks']<=t['timestamp_read_max_ticks'] or t['start_window_ticks']<0:
        raise ValueError('invalid counter-read/start-window measurement')
    return hz,period


def analyze(metadata,reference,actual,ticks,run,before_experiment,mode,output,origin='BOARD'):
    output=Path(output)
    if output.exists():raise ValueError('analysis output exists; select a new directory')
    output.mkdir(parents=True)
    summary=dict(passed=False,origin=origin,timing='NOT_RUN',scope='short technical precheck, not full A4/A5 or WCET')
    try:
        m=json.loads(Path(metadata).read_text(encoding='utf-8-sig'))
        r=json.loads(Path(run).read_text(encoding='utf-8-sig'))
        summary['run']=r
        n=m['frames']
        if (m['scenario']!='current_motion_prefix' or m['source_scenario']!='current_motion'
                or m['source_range']!=[0,n] or m['Ts']!=.0001
                or (m['input_fields'],m['output_fields'])!=(20,41) or not 0<n<=65536):
            raise ValueError('wrong source/prefix/field contract')
        if (r['scenario']!=m['scenario'] or r['mode']!=mode or mode not in (0,1)
                or r['frames']!=n or r['experiment']!=before_experiment+1
                or r['interrupted'] is not False or not r.get('conditions')):
            raise ValueError('run identity/mode/frames/experiment/conditions mismatch or interrupted')
        result=r['result']
        summary['valid_completed_records']=min(n,result['completed_frames'])
        if r['state']!=3 or result['status']!=0 or result['completed_frames']!=n:
            raise ValueError('experiment incomplete/failed: never validate only its correct prefix or stale DDR tail')
        ref=compare.read_doubles(Path(reference),n,41)
        out=compare.read_doubles(Path(actual),n,41)
        stats=compare.compare(ref,out,n,m['Ts'])
        compare.write_csv(output/'signals.csv',stats)
        compare.write_csv(output/'events.csv',compare.events(out,n,m['Ts']))
        anomalies=[]
        if mode:
            t=r['timer'];hz,period=validate_timer(t)
            rows,anomalies=compare.timing_stats(Path(ticks),n,hz,period,out)
            phase=compare.release_phase(list(struct.iter_unpack('<8Q',Path(ticks).read_bytes())))
            compare.write_csv(output/'timing.csv',rows)
            incomplete=phase['status']=='INSUFFICIENT_SPAN' and not any(a.get('category')!='period' for a in anomalies)
            summary.update(timing='NOT_RUN' if incomplete else 'FAIL' if anomalies else 'PASS',timer=t,
                deadline_sequence='FAIL' if any(a.get('category')!='period' for a in anomalies) else 'PASS',
                release_phase=phase,period_consistency=phase['status'],
                counter_read_us=[t['timestamp_read_min_ticks']*1e6/hz,t['timestamp_read_max_ticks']*1e6/hz],
                start_window_us=t['start_window_ticks']*1e6/hz,
                clock_basis='This-run TTC BSP ClockHz; conversion basis, not independently measured frequency',
                conditions=r['conditions'],coverage={c:next((s['samples'] for s in rows if s['category']==c),0)
                    for c in ['ordinary','speed_due','position_due','command_event','alignment_transition']})
        failures=sum(s['failures'] for s in stats)
        summary.update(frames=n,numerical_failures=failures,anomalies=anomalies,passed=not failures and not anomalies)
    except (ValueError,OSError,KeyError,TypeError,OverflowError) as e:
        summary.update(passed=False,error=str(e))
        if mode:summary['timing']='FAIL'
    (output/'summary.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8',newline='\n')
    return summary


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for name in ['metadata','reference','actual','run','output']:p.add_argument('--'+name,type=Path,required=True)
    p.add_argument('--ticks',type=Path);p.add_argument('--before-experiment',type=int,required=True)
    p.add_argument('--mode',type=int,choices=[0,1],default=1)
    p.add_argument('--origin',choices=['BOARD','HOST','SIMULATED'],default='BOARD');a=p.parse_args()
    s=analyze(a.metadata,a.reference,a.actual,a.ticks,a.run,a.before_experiment,a.mode,a.output,a.origin)
    print(json.dumps(s,indent=2));sys.exit(0 if s['passed'] else 1)
