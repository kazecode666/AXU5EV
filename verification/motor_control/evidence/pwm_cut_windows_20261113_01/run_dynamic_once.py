import json, os, re, subprocess, sys, time
from pathlib import Path
root=Path(__file__).resolve().parent
run=root/'slow'
result_path=run/'dynamic_review.json'
assert not result_path.exists()
base=json.loads((run/'summary.json').read_text())
assert base['annotation_confirmed'] and base['stages'][-1]['exit_code']==0
log=(run/'xelab.stdout.log').read_text(errors='replace')
warnings=[x for x in log.splitlines() if 'WARNING:' in x]
assert len(warnings)==3 and all(('VRFC 10-3645' in x and "port 's_axi_rresp'" in x) or ('XSIM 43-4328' in x and 'finish_offer' in x) for x in warnings)
assert not re.search(r'(?im)ERROR:|CRITICAL WARNING:|timing violation|SDF[^\n]*(?:warning|error|failed)',log)
r={'status':'RUNNING','review':'Initial supervisor rejected non-SDF/non-timing TB warnings. First xsim of same successful snapshot; no re-elaboration or timing suppression.','reviewed_warnings':warnings,'started_epoch':time.time(),'limit_seconds':3600,'xelab_seconds':base['stages'][-1]['elapsed_seconds']}
def save():result_path.write_text(json.dumps(r,indent=2),encoding='utf-8')
save()
argv=['D:/Software/2026.1/Vivado/bin/xsim.bat','pwm_cut_timing','-runall']
r['argv']=argv
cmd='"'+os.environ['COMSPEC']+'" /d /s /c "'+subprocess.list2cmdline(argv)+'"'
with (run/'xsim.stdout.log').open('xb') as out,(run/'xsim.stderr.log').open('xb') as err:
 p=subprocess.Popen(cmd,cwd=run,stdout=out,stderr=err);r['pid']=p.pid;save()
 try:r['exit_code']=p.wait(timeout=3600)
 except subprocess.TimeoutExpired:
  with (run/'xsim.termination.log').open('wb') as k:subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],stdout=k,stderr=k)
  p.wait();r['status']='TIMED_OUT'
r['elapsed_seconds']=time.time()-r['started_epoch']
text='\n'.join(p.read_text(errors='replace') for p in run.glob('xsim*.log'))
out=(run/'xsim.stdout.log').read_text(errors='replace')
r['diagnostics']=re.findall(r'(?im)^.*(?:WARNING:|ERROR:|CRITICAL WARNING:|timing violation|PWM_CUT_FAIL|Fatal:).*$',text)
r['pass_markers']=len(re.findall(r'(?m)^PWM_CUT_SDF_PASS(?: |$)',out))
if r['status']!='TIMED_OUT':r['status']='PASS' if r['exit_code']==0 and not r['diagnostics'] and r['pass_markers']==1 else 'FAIL'
save()
sys.exit(0 if r['status']=='PASS' else 1)
