import json, os, re, subprocess, sys, time
from pathlib import Path
ROOT=Path(__file__).resolve().parent
BIN=Path('D:/Software/2026.1/Vivado/bin')
corner=sys.argv[1]
assert corner in ('slow','fast')
if corner=='fast':
    assert json.loads((ROOT/'slow'/'summary.json').read_text())['status']=='PASS', 'slow must PASS first'
run=ROOT/corner
run.mkdir(exist_ok=False)
summary={'corner':corner,'status':'NOT_RUN','stages':[],'board':'NOT_RUN','xelab_limit_seconds':3600,'optimization':'O2 (one attempt)','timing_checks_disabled':False}
def save(): (run/'summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
def stage(name,args,limit):
    cmd=[str(BIN/(name+'.bat'))]+args
    rec={'stage':name,'argv':cmd,'limit_seconds':limit,'started_epoch':time.time()}
    summary['stages'].append(rec); summary['status']='RUNNING'; save()
    command='"'+os.environ.get('COMSPEC','C:/Windows/System32/cmd.exe')+'" /d /s /c "'+subprocess.list2cmdline(cmd)+'"'
    with (run/(name+'.stdout.log')).open('wb') as out, (run/(name+'.stderr.log')).open('wb') as err:
        p=subprocess.Popen(command,cwd=run,stdout=out,stderr=err)
        rec['pid']=p.pid; save()
        try:
            code=p.wait(timeout=limit); rec['status']='EXITED_OK' if code==0 else 'FAIL'
        except subprocess.TimeoutExpired:
            with (run/(name+'.termination.log')).open('wb') as k:
                subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],stdout=k,stderr=k)
            p.wait(); rec['status']='TIMED_OUT'; code=p.returncode
    rec['exit_code']=code;rec['elapsed_seconds']=time.time()-rec['started_epoch'];save()
    if rec['status']!='EXITED_OK':
        summary['status']='TIMED_OUT' if rec['status']=='TIMED_OUT' else 'FAIL';save();return False
    return True
save()
try:
    if not stage('xvlog',['-sv',str(ROOT/'pwm_cut.v'),str(ROOT/'pwm_cut_tb.sv'),'D:/Software/2026.1/data/verilog/src/glbl.v'],600): sys.exit(1)
    args=['work.pwm_cut_tb','work.glbl','-s','pwm_cut_timing','-debug','off','-timescale','1ns/1ps','-L','simprims_ver','-L','unisims_ver','-L','secureip','-transport_int_delays','-pulse_r','0','-pulse_int_r','0','-pulse_e','0','-pulse_int_e','0','-sdfmax' if corner=='slow' else '-sdfmin','/pwm_cut_tb/dut='+str(ROOT/('pwm_cut_'+corner+'.sdf')).replace(chr(92),'/'),'--O2']
    if not stage('xelab',args,3600): sys.exit(1)
    # Do not proceed to dynamics after an annotation/timing warning or tool error.
    elaboration='\n'.join(p.read_text(errors='replace') for p in run.glob('xelab*.log'))
    bad=re.findall(r'(?im)^.*(?:WARNING:|ERROR:|CRITICAL WARNING:|SDF[^\n]*(?:warning|error|failed)|Timing Violation|timing violation).*$' ,elaboration)
    summary['annotation_confirmed']=bool(re.search(r'43-3452',elaboration))
    if bad or not summary['annotation_confirmed']:
        summary.update(status='FAIL',reason='annotation not clean or missing success marker',diagnostics=bad);save();sys.exit(1)
    if not stage('xsim',['pwm_cut_timing','-runall'],3600): sys.exit(1)
    sim='\n'.join(p.read_text(errors='replace') for p in run.glob('xsim*.log'))
    bad=re.findall(r'(?im)^.*(?:WARNING:|ERROR:|CRITICAL WARNING:|Timing Violation|timing violation|PWM_CUT_SDF_FAIL|Fatal:).*$' ,sim)
    # stdout and native xsim.log may repeat the same PASS, so count in stdout only.
    out=(run/'xsim.stdout.log').read_text(errors='replace')
    passed=len(re.findall(r'(?m)^PWM_CUT_SDF_PASS(?: |$)',out))==1 and not bad
    summary.update(status='PASS' if passed else 'FAIL',reason='dynamic assertions completed' if passed else 'missing unique PASS or dynamic diagnostics',diagnostics=bad)
    save()
except Exception as exc:
    summary.update(status='FAIL',reason=repr(exc));save();raise
sys.exit(0 if summary['status']=='PASS' else 1)
