"""Directed AX-02B qualification using existing p3 bit/state checker and oracle.

No long closed-loop RTL, board access, general test framework or hash inventory.
"""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'scripts'))
from m3_build_scoreboard import load_golden,RECORD_BITS
BIN=Path('E:/AMDDesignTools/2026.1/Vivado/bin')

def logic(text):
    text=re.sub(r'/\*.*?\*/|//[^\n]*','',text,flags=re.S)
    return re.findall(r'\S+',text)

def tool(name,args,cwd):
    with (cwd/(name+'.log')).open('w',encoding='utf-8') as log:
        # Windows subprocess uses the installed .bat launchers, no board tools.
        words=' '.join('"'+str(x)+'"' for x in [BIN/(name+'.bat'),*args])
        r=subprocess.run('cmd.exe /d /s /c "'+words+'"',cwd=cwd,stdout=log,stderr=subprocess.STDOUT)
    content=(cwd/(name+'.log')).read_text(encoding='utf-8',errors='replace')
    if r.returncode or re.search(r'^(ERROR:|FATAL:|M3_RTL_FAIL|AX02B_FRAME_FAIL)',content,re.M):
        raise RuntimeError(f'{name} failed; see {cwd}')
    return content

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--candidate',type=Path,required=True)
    p.add_argument('--out',type=Path,required=True)
    p.add_argument('--mode',choices=['normal','reset','ce','frame']);a=p.parse_args()
    rtl=a.candidate.resolve()/'rtl/AX02B_P3_5EV';out=a.out.resolve();out.mkdir(parents=True,exist_ok=False)
    m=json.loads((ROOT/'generated/legacy_m3_p3/manifest.json').read_text(encoding='utf-8'))
    files=[rtl/x['path'] for x in m['design_files']]
    differences=[];byte_differences=[]
    for f in files:
        old=ROOT/'generated/legacy_m3_p3'/f.name
        if f.read_bytes()!=old.read_bytes():byte_differences.append(f.name)
        if logic(f.read_text())!=logic(old.read_text()):differences.append(f.name)
    result=dict(rtl_dir=str(rtl),design_files=len(files),byte_differences=byte_differences,
        logic_differences=differences,phase=314,tests={},board='NOT_RUN')
    (out/'rtl_equivalence.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    if differences:raise ValueError('Generated logic changed; qualify schedule/state mapping before using p3 contract')
    records,_,n=load_golden(ROOT/'verification/m3_foc/directed_probe_source_hex.csv',None)
    memory=out/'directed.mem';memory.write_text(''.join(f'{x:0{(RECORD_BITS+3)//4}X}\n' for x in records),encoding='ascii')
    (out/'used_sources.txt').write_text('\n'.join(str(f) for f in files)+'\n',encoding='utf-8')
    for mode in ([a.mode] if a.mode else ('normal','reset','ce','frame')):
        work=out/mode;work.mkdir()
        top='ax02b_frame_contract_tb' if mode=='frame' else 'm3_foc_scoreboard'
        tb=[ROOT/'integration/rtl/axu5ev_foc_frame_top.sv',ROOT/'verification/ax02b/frame_contract_tb.sv'] if mode=='frame' else [ROOT/'verification/m3_foc/m3_foc_scoreboard.sv']
        args=work/'sources.args'
        args.write_text('--sv\n--work work\n-d M3_PI_COMMIT_NEXT_FRAME\n'+''.join('"'+f.as_posix()+'"\n' for f in files+tb),encoding='utf-8')
        tool('xvlog',['-f',str(args)],work)
        tool('xelab',['-debug','typical',top,'-s','qualified'],work)
        plus=['-testplusarg','vectors='+memory.as_posix()]
        if mode!='frame':
            for value in [f'frames={n}',f'mode={mode}','case_name=directed_probe','output_phase=314','result='+(work/'scoreboard.json').as_posix()]:
                plus+=['-testplusarg',value]
        console=tool('xsim',['qualified','-runall',*plus],work)
        if mode=='frame':
            hit=re.search(r'AX02B_FRAME_PASS frames=(\d+) checks=(\d+)',console)
            if not hit or int(hit[1])!=21 or int(hit[2])<=100000:raise ValueError('missing/countless adapter success')
            result['tests'][mode]=dict(status='PASS',frames=int(hit[1]),checks=int(hit[2]))
        else:
            hit=re.search(r'M3_RTL_PASS frames=(\d+) checks=(\d+) bit_mismatch=0 protocol_errors=0 deadline_errors=0',console)
            if not hit or int(hit[1])!=n+(2 if mode=='reset' else 0) or int(hit[2])!=20011*n-4+(40422 if mode=='reset' else 0):
                raise ValueError('checker failed or wrong effective comparison count')
            result['tests'][mode]=json.loads((work/'scoreboard.json').read_text())
        print(f'AX02B {mode} PASS',flush=True)
        (out/'result.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    result['status']='SELECTED_CHECKS_PASS' if a.mode else 'FUNCTION_AND_FRAME_PASS'
    (out/'result.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')

if __name__=='__main__':main()
