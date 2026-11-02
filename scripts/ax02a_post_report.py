"""Local descriptor preparation, compact report decode and HOST C/Python crosscheck."""
import argparse,ctypes as C,json,math,os,struct,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import ax02a_compare_replay as py
from ax02a_analyze_run import validate_timer
GROUPS=['all','ordinary','speed_due','position_due','command_event','alignment_transition']
METRICS=['runtime_us','task_us','response_us','jitter_us','slack_us']
def scenario(m):
 n=m['frames']
 if m['Ts']!=.0001 or (m['input_fields'],m['output_fields'])!=(20,41) or not 0<n<=65536:raise ValueError('wrong metadata contract')
 if m['scenario']=='current_motion_prefix':
  if m['source_scenario']!='current_motion' or m['source_range']!=[0,n]:raise ValueError('prefix must start at source frame0')
  return 1
 if m['scenario']=='current_motion':return 2
 if m['scenario']=='current_alignment_reset':return 3
 raise ValueError('unknown/current-reference scenario required')
def descriptor(metadata,reference,output):
 m=json.loads(metadata.read_text(encoding='utf-8-sig'));s=scenario(m)
 if reference.stat().st_size!=m['frames']*328:raise ValueError('reference length mismatch')
 if output.exists():raise ValueError('descriptor output directory exists')
 output.mkdir(parents=True)
 (output/'reference_descriptor.bin').write_bytes(struct.pack('<8I',0x31464552,1,s,m['frames'],41,0,m['frames']*328,0))
 (output/'source.json').write_text(json.dumps(dict(scenario=m['scenario'],scenario_id=s,frames=m['frames'],reference=str(reference.resolve()),reference_bytes=m['frames']*328,descriptor_address='0x12f00000',reference_address='0x14000000',report_address='0x16000000',report_bytes=2400),indent=2)+'\n',encoding='utf-8',newline='\n')
def decode(raw):
 if len(raw) not in (2336,2400):raise ValueError('report length must be v1=2336 or v2=2400')
 h=struct.unpack_from('<16I',raw)
 if h[0]!=0x31505841 or (h[1],h[2]) not in [(1,2336),(2,2400)] or h[2]!=len(raw) or h[3]!=0x434f4d50:raise ValueError('report version/size/final valid marker mismatch')
 names=['scenario','experiment','mode','requested','completed','program_status','compare_status','timing_status','contract_errors','numeric_errors','timing_errors','p99_status']
 r=dict(zip(names,h[4:]));r.update(version=h[1],fields=[],metrics=[],p99='NOT_COMPUTED')
 for j in range(41):
  f=struct.unpack_from('<4I2d',raw,64+32*j)
  r['fields'].append(dict(field=j+1,name=py.FIELDS[j],failures=f[0],max_frame=f[1],first_mismatch_frame='' if f[2]==0xffffffff else f[2],max_abs=f[4],rms=f[5]))
 for g in range(6):
  for j in range(5):
   x=struct.unpack_from('<2I3d',raw,64+41*32+(g*5+j)*32)
   r['metrics'].append(dict(category=GROUPS[g],metric=METRICS[j],samples=x[0],worst_frame=x[1],mean=x[2],minimum=x[3],maximum=x[4]))
 if h[1]==2:
  d=struct.unpack_from('<4I6d',raw,2336)
  if d[0]>2 or d[1]>2:raise ValueError('invalid v2 deadline/period status')
  r.update(deadline_status=d[0],period_status=d[1],release_phase=dict(status=['NO_TREND_DETECTED','TREND_DETECTED','INSUFFICIENT_SPAN'][d[1]],samples=d[2],slope_ticks_per_frame=d[4],intercept_ticks=d[5],residual_rms_ticks=d[6],slope_standard_error=d[7],threshold_ticks_per_frame=d[8],mean_isr_interval_ticks=d[9]))
 else:
  r.update(deadline_status=r['timing_status'],period_status=2,release_phase=dict(status='UNAVAILABLE_V1',samples=0),legacy_warning='v1 timing PASS did not screen release phase drift')
 return r
def identity(report,m,run,before):
 if (report['scenario']!=scenario(m) or report['requested']!=m['frames'] or report['experiment']!=before+1
  or run['experiment']!=report['experiment'] or run['mode']!=report['mode'] or run['frames']!=report['requested']
  or run['scenario']!=m['scenario'] or run['state']!=3 or run['result']['status']!=0
  or run['result']['completed_frames']!=m['frames'] or run['interrupted'] is not False):raise ValueError('saved run/report identity or completion mismatch')
 return not any(report[k] for k in ['program_status','compare_status','contract_errors','numeric_errors','timing_errors']) and report['completed']==m['frames'] and report['timing_status']==(0 if report['mode'] else 2) and (not report['mode'] or (report['version']>=2 and report['deadline_status']==0 and report['period_status']==0 and report['release_phase']['samples']==m['frames']-1))
def crosscheck(r,reference,actual,m,run,before,ticks=None):
 claimed=identity(r,m,run,before);stats=py.compare(reference,actual,m['frames'],m['Ts']);errors=[]
 for a,b in zip(r['fields'],stats):
  for k in ['failures','max_frame','first_mismatch_frame','max_abs']:
   if a[k]!=b[k]:errors.append(dict(field=a['field'],metric=k))
  if not math.isclose(a['rms'],b['rms'],abs_tol=1e-15,rel_tol=1e-12):errors.append(dict(field=a['field'],metric='rms'))
 # Derive report statuses/counts from the raw PC comparison, independently of
 # the board's PASS claim. Agreement on a rejection is still not a PASS.
 numeric_errors=sum(s['failures'] for s in stats)
 expected=dict(program_status=run['result']['status'],completed=m['frames'],
  contract_errors=0,numeric_errors=numeric_errors,compare_status=int(bool(numeric_errors)),
  p99_status=2,timing_errors=0,timing_status=2,deadline_status=2,period_status=2)
 anomalies=[];rows=[]
 phase=dict(status='INSUFFICIENT_SPAN',samples=0)
 if r['mode']:
  hz,period=validate_timer(run['timer'])
  rows,anomalies=py.timing_stats(ticks,m['frames'],hz,period,actual)
  phase=py.release_phase(list(struct.iter_unpack('<8Q',ticks.read_bytes())))
  deadline_errors=sum(a.get('category')!='period' for a in anomalies)
  period_status={'NO_TREND_DETECTED':0,'TREND_DETECTED':1,'INSUFFICIENT_SPAN':2}[phase['status']]
  timing_errors=deadline_errors+int(period_status==1)
  expected.update(deadline_status=int(bool(deadline_errors)),period_status=period_status,
   timing_errors=timing_errors,timing_status=1 if timing_errors else period_status)
  if r['version']>=2:
   for key in ['slope_ticks_per_frame','intercept_ticks','residual_rms_ticks','slope_standard_error','threshold_ticks_per_frame','mean_isr_interval_ticks']:
    if not math.isclose(r['release_phase'][key],phase[key],abs_tol=1e-10,rel_tol=1e-9):errors.append(dict(phase=key))
  else:errors.append(dict(phase='UNAVAILABLE_V1'))
 if r['version']>=2:
  if r['release_phase']['status']!=phase['status']:errors.append(dict(phase='status'))
  if r['release_phase']['samples']!=phase['samples']:errors.append(dict(phase='samples'))
 status_errors=[dict(status=k,reported=r[k],expected=v) for k,v in expected.items() if r[k]!=v]
 # PC omits empty groups; the wire report must still describe all 30 slots.
 by_metric={(b['category'],b['metric']):b for b in rows}
 for a in r['metrics']:
  b=by_metric.get((a['category'],a['metric']),dict(samples=0,worst_frame=0,mean=0.,minimum=0.,maximum=0.))
  for k in ['samples','worst_frame']:
   if a[k]!=b[k]:errors.append(dict(category=a['category'],metric=a['metric'],stat=k))
  for k in ['mean','minimum','maximum']:
   if not math.isclose(a[k],b[k],abs_tol=1e-12,rel_tol=1e-9):errors.append(dict(category=a['category'],metric=a['metric'],stat=k))
 consistent=not errors and not status_errors
 return dict(passed=claimed and consistent and not anomalies and not numeric_errors,crosscheck_consistent=consistent,period_status=r['release_phase']['status'],origin='HOST_POSTPROCESS',input_origin='BOARD motion_03 or explicitly supplied run; HOST is not target postprocessor validation',frames=m['frames'],field_metrics_mismatches=errors,report_status_mismatches=status_errors,python_timing_anomalies=anomalies,p99='NOT_COMPUTED in C v1/v2; Python retains its ceil P99',statistics_tolerances='RMS abs1e-15/rel1e-12; time summaries abs1e-12/rel1e-9; no change to numeric PASS tolerances')
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('action',choices=['descriptor','decode','host','crosscheck'])
 for k in ['metadata','output']:p.add_argument('--'+k,type=Path,required=True)
 for k in ['reference','actual','ticks','run','report','library','gcc-bin']:p.add_argument('--'+k,type=Path)
 p.add_argument('--before-experiment',type=int);a=p.parse_args()
 if a.action=='descriptor':descriptor(a.metadata,a.reference,a.output);return 0
 m=json.loads(a.metadata.read_text(encoding='utf-8-sig'));run=json.loads(a.run.read_text(encoding='utf-8-sig'))
 if a.output.exists():raise ValueError('output exists; preserve earlier evidence')
 a.output.mkdir(parents=True)
 if a.action=='decode':
  r=decode(a.report.read_bytes());r['reported_pass']=identity(r,m,run,a.before_experiment)
  r['limitation']='Report claim only; compare full P1000 output/ticks with Python before target validation'
 elif a.action=='crosscheck':
  r=decode(a.report.read_bytes());ref=py.read_doubles(a.reference,m['frames'],41);actual=py.read_doubles(a.actual,m['frames'],41)
  check=crosscheck(r,ref,actual,m,run,a.before_experiment,a.ticks);check['origin']='BOARD_REPORT_VS_PC'
  (a.output/'crosscheck.json').write_text(json.dumps(check,indent=2)+'\n',encoding='utf-8',newline='\n')
  r['reported_pass']=check['passed']
 else:
  n=m['frames'];ref=py.read_doubles(a.reference,n,41);actual=py.read_doubles(a.actual,n,41)
  x=(C.c_double*len(actual))(*actual);y=(C.c_double*len(ref))(*ref)
  tdata=a.ticks.read_bytes() if a.ticks else b''
  if run['mode'] and len(tdata)!=n*64:raise ValueError('tick length mismatch')
  t=(C.c_uint64*(len(tdata)//8)).from_buffer_copy(tdata) if tdata else None
  timer=run.get('timer',{});s=scenario(m)
  q=(C.c_uint32*13)(s,s,run['experiment'],a.before_experiment+1,run['mode'],run['mode'],n,n,run['result']['completed_frames'],run['result']['status'],int(run['interrupted']),timer.get('clock_hz',0),timer.get('period_ticks',0))
  handle=os.add_dll_directory(str(a.gcc_bin)) if a.gcc_bin else None
  lib=C.CDLL(str(a.library.resolve()));buf=C.create_string_buffer(2400)
  lib.ax02a_postprocess(x,len(actual),y,len(ref),t,len(tdata)//64,C.byref(q),buf)
  raw=buf.raw;(a.output/'report.bin').write_bytes(raw);r=decode(raw)
  check=crosscheck(r,ref,actual,m,run,a.before_experiment,a.ticks)
  (a.output/'crosscheck.json').write_text(json.dumps(check,indent=2)+'\n',encoding='utf-8',newline='\n')
  r['reported_pass']=check['passed']
  if handle:handle.close()
 (a.output/'report.json').write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8',newline='\n')
 print(json.dumps(dict(passed=r['reported_pass'],output=str(a.output),p99='NOT_COMPUTED')));return 0 if r['reported_pass'] else 1
if __name__=='__main__':
 try:sys.exit(main())
 except (ValueError,OSError,TypeError,KeyError) as e:print('FAIL:',e,file=sys.stderr);sys.exit(1)
