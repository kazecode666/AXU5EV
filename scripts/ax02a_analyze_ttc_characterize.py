"""Offline TTC-only 16-byte records. Compatibility is not a hardware root-cause proof."""
import argparse
import json
import math
from pathlib import Path
import statistics
import struct

MAGIC = 0x31435454
WINDOW_QUANTIZATION_TICKS = 2


def ols(values):
    n=len(values); x=(n-1)/2; mean=statistics.fmean(values)
    slope=sum((k-x)*(v-mean) for k,v in enumerate(values))/sum((k-x)**2 for k in range(n))
    residual=[v-(mean+slope*(k-x)) for k,v in enumerate(values)]
    return dict(slope=slope, first=values[0], last=values[-1], minimum=min(values), maximum=max(values),
                residual_rms=math.sqrt(statistics.fmean(v*v for v in residual)),
                residual_max=max(abs(v) for v in residual))


def summaries(rows):
    seq,fb,p,fa=zip(*rows)
    lows=[f-v for f,v in zip(fb,p)]; highs=[f-v for f,v in zip(fa,p)]
    centers=[(l+h)/2 for l,h in zip(lows,highs)]
    widths=[h-l for l,h in zip(lows,highs)]
    # Deterministic endpoint read-window bounds, enlarged by two counter ticks
    # at either end. Not a statistical confidence interval or an atomic edge.
    span=seq[-1]-seq[0]
    margin=2*WINDOW_QUANTIZATION_TICKS
    bounds=[(lows[-1]-highs[0]-margin)/span,(highs[-1]-lows[0]+margin)/span]
    return dict(count=len(rows),event=ols(centers),p_count=ols(p),
                isr_phase=ols([(f+a)/2-(k+1)*10000 for k,f,v,a in rows]),
                read_window=ols(widths),event_period_bounds=bounds,
                first_event_window=[lows[0],highs[0]],last_event_window=[lows[-1],highs[-1]])


def candidate_epoch(rows, period):
    """Intersect every event window's epoch constraint; never fit away a conflict."""
    q=WINDOW_QUANTIZATION_TICKS
    windows=[(seq,fb-p-q-seq*period,fa-p+q-seq*period) for seq,fb,p,fa in rows]
    lower=max(windows,key=lambda w:w[1]);upper=min(windows,key=lambda w:w[2])
    return dict(period_ticks=period,quantization_ticks=q,
                epoch_lower=lower[1],epoch_upper=upper[2],
                lower_sequence=lower[0],upper_sequence=upper[0],
                feasible=lower[1]<=upper[2])


def evaluate(samples_path, run_path):
    result=dict(acquisition_valid=False,usable_samples=0,hypothesis='INCONCLUSIVE',issues=[],
                hypothesis_reason='ACQUISITION_INVALID',
                hardware_irq_loss='UNKNOWN',origin='TTC_ONLY',
                limitation='Same-source synchronous counters assumed. Read-window edge estimates are not atomic; multiple rollovers inside the window and all merged IRQs cannot be proven absent. No A4/A5/WCET conclusion.')
    try:
        r=json.loads(Path(run_path).read_text(encoding='utf-8-sig'));result['run']=r
        raw=r['requested_raw']; cfg=r['config']
        if (r['magic']!=MAGIC or r['version']!=1 or r['record_bytes']!=16 or raw not in [9999,10000,10001]
            or r['actual_raw']!=raw or r['nominal_period']!=10000 or r['requested_samples']!=1000
            or r['case_id'] not in ['A1','B','A2','C']
            or raw!={'A1':10000,'B':9999,'A2':10000,'C':10001}[r['case_id']]
            or not 0<=r['before_experiment']<0xffffffff or r['experiment']!=r['before_experiment']+1):
            raise ValueError('protocol / case / raw / experiment mismatch')
        if (cfg['periodic_clock']!=0 or cfg['timestamp_clock']!=0
            or cfg['periodic_control']!=35 or cfg['timestamp_control']!=33
            or cfg['periodic_ier']!=1 or cfg['timestamp_ier']!=0
            or cfg['periodic_hz']!=cfg['timestamp_hz'] or cfg['periodic_hz']!=100000000
            or cfg['periodic_base']!=0xff110000 or cfg['timestamp_base']!=0xff110004):
            raise ValueError('unverified counter configuration')
        if not all(r[k] for k in ['conditions','session_id','clock_basis','workspace','elf','build_id']):
            raise ValueError('missing provenance / session conditions')
        n=r['completed_samples']
        if not 0<=n<=1000: raise ValueError('invalid count')
        budget=1100*(raw+1)+100000
        if r['timeout_ticks']!=budget:raise ValueError('timeout budget differs from firmware contract')
        data=Path(samples_path).read_bytes()
        if len(data)!=n*16: raise ValueError('record length mismatch (not P1000 uint64 ticks)')
        rows=list(struct.iter_unpack('<4I',data))
        if r['state']!=3 or r['error']!=0 or n!=1000 or r['interrupted'] is not False:
            result['issues'].append('incomplete / failed / debugger interrupted acquisition')
        usable=[];previous=None
        for i,(seq,fb,p,fa) in enumerate(rows):
            why=[];width=fa-fb
            if seq!=i: why.append('sequence')
            if fa<fb or (previous is not None and fb<=previous): why.append('uint32 wrap / nonmonotonic F')
            if fa>=budget: why.append('record exceeds this-run timeout budget')
            if width<0 or width>=raw//4: why.append('wide read window')
            if p<=width or p+width>=raw: why.append('possible rollover during read window')
            if p>raw//4: why.append('late / ambiguous IRQ sampling')
            if why: result['issues'].append(dict(sample=i,reasons=why))
            else: usable.append((seq,fb,p,fa))
            previous=fa
        result['usable_samples']=len(usable)
        # Never silently filter anomalies into support for a mapping hypothesis.
        if len(rows)>=2:
            result['all_samples']=summaries(rows)
            result['after_first']=summaries(rows[1:]) if len(rows)>2 else None
            result['exclusion_rule']='All samples authoritative; after_first is a parallel startup diagnostic only (first sample is real IRQ).'
            centers=[(fb+fa)/2-p for seq,fb,p,fa in rows]
            period=result['all_samples']['event']['slope']
            gaps=[centers[k]-centers[k-1] for k in range(1,len(rows))]
            if period<=0 or any(abs(g-period)>max(100,abs(period)*.2) for g in gaps):
                result['issues'].append('suspected missing / merged IRQ or inconsistent event intervals')
            window=max(fa-fb for seq,fb,p,fa in rows)
            if result['all_samples']['event']['residual_max']>window+4:
                result['issues'].append('event residual exceeds read-window model')
        result['acquisition_valid']=not result['issues'] and len(usable)==1000
        if result['acquisition_valid']:
            lo,hi=result['all_samples']['event_period_bounds']
            candidates={label:candidate_epoch(rows,value) for value,label in
                        [(raw,'RAW_COMPATIBLE'),(raw+1,'RAW_PLUS_ONE_COMPATIBLE')]}
            result['candidate_feasibility']=candidates
            compatible=[label for label,c in candidates.items() if c['feasible'] and lo<=c['period_ticks']<=hi]
            result['threshold_basis']='All samples must share a feasible epoch for the candidate period, with 2 ticks per window endpoint; also require endpoint slope bound width <=0.25 tick/IRQ, consistent gaps and residuals. This resolution gate is not the old P1000 trend threshold.'
            if not compatible:result['hypothesis_reason']='NO_CANDIDATE_HAS_COMMON_EPOCH'
            elif len(compatible)>1:result['hypothesis_reason']='MULTIPLE_FEASIBLE_CANDIDATES'
            elif hi-lo>.25:result['hypothesis_reason']='INSUFFICIENT_PERIOD_RESOLUTION'
            else:
                result['hypothesis']=compatible[0]
                result['hypothesis_reason']='UNIQUE_CANDIDATE_WITH_COMMON_EPOCH'
    except (OSError,ValueError,KeyError,TypeError,struct.error,ZeroDivisionError) as e:
        result['issues'].append(str(e))
    return result


def write_new(output_dir, result):
    output_dir=Path(output_dir)
    output_dir.mkdir(parents=True,exist_ok=False)
    (output_dir/'summary.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    return result


def analyze_run(samples_path, run_path, output_dir):
    if Path(output_dir).exists(): raise ValueError('analysis output exists')
    return write_new(output_dir,evaluate(samples_path,run_path))


def compare_aba(a1_dir, b_dir, a2_dir, output_dir):
    if Path(output_dir).exists(): raise ValueError('analysis output exists')
    runs=[evaluate(Path(d)/'samples.bin',Path(d)/'run.json') for d in [a1_dir,b_dir,a2_dir]]
    issues=[];repeatable=False;conclusion='INCONCLUSIVE'
    try:
        identities=[x['run'] for x in runs];a,b,c=identities
        if [x['case_id'] for x in identities]!=['A1','B','A2']:issues.append('case order mismatch')
        if not (b['before_experiment']==a['experiment'] and c['before_experiment']==b['experiment']):issues.append('nonconsecutive experiments')
        for key in ['elf','workspace','build_id','session_id','conditions','config','clock_basis']:
            if a[key]!=b[key] or a[key]!=c[key]:issues.append('mixed candidate / session / conditions: '+key)
        if all(x['acquisition_valid'] for x in runs):
            x,z=[runs[i]['all_samples'] for i in [0,2]]
            # Repeatability requires overlapping event-period ranges and comparable P trends.
            repeatable=(max(x['event_period_bounds'][0],z['event_period_bounds'][0])<=min(x['event_period_bounds'][1],z['event_period_bounds'][1])
                        and abs(x['p_count']['slope']-z['p_count']['slope'])<=.05)
            if not repeatable:issues.append('A1/A2 not repeatable')
            if any(x['hypothesis']=='INCONCLUSIVE' for x in runs):
                issues.append('single-run candidate inference inconclusive; inspect per-run window feasibility and resolution')
            if not issues and repeatable and len(set(x['hypothesis'] for x in runs))==1:
                conclusion=runs[0]['hypothesis']
        else:issues.append('invalid acquisition; do not infer mapping')
    except (KeyError,TypeError): issues.append('incomplete metadata')
    return write_new(output_dir,dict(conclusion=conclusion,repeatable=repeatable,issues=issues,runs=runs,
         limitation='Compatibility in TTC-only conditions, not confirmed N+1 or a production correction. Hardware IRQ loss remains UNKNOWN.'))


def main():
    p=argparse.ArgumentParser(description=__doc__);s=p.add_subparsers(dest='action',required=True)
    r=s.add_parser('run');r.add_argument('samples',type=Path);r.add_argument('run',type=Path);r.add_argument('output',type=Path)
    r=s.add_parser('aba')
    for name in ['a1','b','a2','output']:r.add_argument(name,type=Path)
    a=p.parse_args()
    result=analyze_run(a.samples,a.run,a.output) if a.action=='run' else compare_aba(a.a1,a.b,a.a2,a.output)
    print(json.dumps(result,indent=2))
    return 0 if result.get('acquisition_valid',False) or result.get('conclusion','INCONCLUSIVE')!='INCONCLUSIVE' else 1


if __name__=='__main__':raise SystemExit(main())
