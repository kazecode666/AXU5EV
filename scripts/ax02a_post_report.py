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
 (output/'source.json').write_text(json.dumps(dict(scenario=m['scenario'],scenario_id=s,frames=m['frames'],reference=str(reference.resolve()),reference_bytes=m['frames']*328,descriptor_address='0x12f00000',reference_address='0x14000000',report_address='0x16000000',report_bytes=2336),indent=2)+'\n',encoding='utf-8',newline='\n')
def decode(raw):
 if len(raw)!=2336:raise ValueError('report length must be exactly2336')
 h=struct.unpack_from('<16I',raw)
 if h[:4]!=(0x31505841,1,2336,0x434f4d50):raise ValueError('report version/size/final valid marker mismatch')
 names=['scenario','experiment','mode','requested','completed','program_status','compare_status','timing_status','contract_errors','numeric_errors','timing_errors','p99_status']
 r=dict(zip(names,h[4:]));r.update(version=1,fields=[],metrics=[],p99='NOT_COMPUTED')
 for j in range(41):
  f=struct.unpack_from('<4I2d',raw,64+32*j)
  r['fields'].append(dict(field=j+1,name=py.FIELDS[j],failures=f[0],max_frame=f[1],first_mismatch_frame='' if f[2]==0xffffffff else f[2],max_abs=f[4],rms=f[5]))
 for g in range(6):
  for j in range(5):
   x=struct.unpack_from('<2I3d',raw,64+41*32+(g*5+j)*32)
   r['metrics'].append(dict(category=GROUPS[g],metric=METRICS[j],samples=x[0],worst_frame=x[1],mean=x[2],minimum=x[3],maximum=x[4]))
 return r
def identity(report,m,run,before):
 if (report['scenario']!=scenario(m) or report['requested']!=m['frames'] or report['experiment']!=before+1
  or run['experiment']!=report['experiment'] or run['mode']!=report['mode'] or run['frames']!=report['requested']
  or run['scenario']!=m['scenario'] or run['state']!=3 or run['result']['status']!=0
  or run['result']['completed_frames']!=m['frames'] or run['interrupted'] is not False):raise ValueError('saved run/report identity or completion mismatch')
 return not any(report[k] for k in ['program_status','compare_status','contract_errors','numeric_errors','timing_errors']) and report['completed']==m['frames'] and report['timing_status']==(0 if report['mode'] else 2)
def crosscheck(r,reference,actual,m,run,before,ticks=None):
 claimed=identity(r,m,run,before);stats=py.compare(reference,actual,m['frames'],m['Ts']);errors=[]
 for a,b in zip(r['fields'],stats):
  for k in ['failures','max_frame','first_mismatch_frame','max_abs']:
   if a[k]!=b[k]:errors.append(dict(field=a['field'],metric=k))
  if not math.isclose(a['rms'],b['rms'],abs_tol=1e-15,rel_tol=1e-12):errors.append(dict(field=a['field'],metric='rms'))
 anomalies=[]
 if r['mode']:
  hz,period=validate_timer(run['timer'])
  rows,anomalies=py.timing_stats(ticks,m['frames'],hz,period,actual)
  for b in rows:
   a=next(x for x in r['metrics'] if x['category']==b['category'] and x['metric']==b['metric'])
   for k in ['samples','worst_frame']:
    if a[k]!=b[k]:errors.append(dict(category=b['category'],metric=k))
   for k in ['mean','minimum','maximum']:
    if not math.isclose(a[k],b[k],abs_tol=1e-12,rel_tol=1e-9):errors.append(dict(category=b['category'],metric=b['metric'],stat=k))
 return dict(passed=claimed and not errors and not anomalies and not any(s['failures'] for s in stats),origin='HOST_POSTPROCESS',input_origin='BOARD motion_03 or explicitly supplied run; HOST is not target postprocessor validation',frames=m['frames'],field_metrics_mismatches=errors,python_timing_anomalies=anomalies,p99='NOT_COMPUTED in C v1; Python retains its ceil P99',statistics_tolerances='RMS abs1e-15/rel1e-12; time summaries abs1e-12/rel1e-9; no change to numeric PASS tolerances')
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
  lib=C.CDLL(str(a.library.resolve()));buf=C.create_string_buffer(2336)
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
