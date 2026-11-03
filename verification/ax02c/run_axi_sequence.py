"""Run only the C1 AXI-connected 17-frame sequence, reusing p3 vectors/tool launch."""
import argparse
import json
from pathlib import Path
import re
import sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'verification/ax02b'))
from run_checks import tool,load_golden,RECORD_BITS

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--out',type=Path,required=True);a=p.parse_args()
 out=a.out.resolve();out.mkdir(parents=True,exist_ok=False)
 rtl=ROOT/'.runtime/ax02b/candidate_01/rtl/AX02B_P3_5EV'
 manifest=json.loads((ROOT/'generated/legacy_m3_p3/manifest.json').read_text(encoding='utf-8'))
 files=[rtl/x['path'] for x in manifest['design_files']]
 files += [ROOT/'integration/rtl/axu5ev_foc_frame_top.sv',ROOT/'integration/rtl/axu5ev_foc_axi.sv',ROOT/'verification/ax02c/axi_sequence_tb.sv']
 records,_,n=load_golden(ROOT/'verification/m3_foc/directed_probe_source_hex.csv',None)
 if n!=17:raise ValueError('C1 requires existing 17-frame input')
 mem=out/'directed.mem';mem.write_text(''.join(f'{x:0{(RECORD_BITS+3)//4}X}\n' for x in records),encoding='ascii')
 args=out/'sources.args';args.write_text('--sv\n--work work\n'+''.join('"'+f.as_posix()+'"\n' for f in files),encoding='utf-8')
 tool('xvlog',['-f',str(args)],out)
 tool('xelab',['-debug','typical','ax02c_axi_sequence_tb','-s','c1'],out)
 log=tool('xsim',['c1','-runall','-testplusarg','vectors='+mem.as_posix()],out)
 m=re.search(r'AX02C_AXI_PASS frames=(\d+) duty_checks=(\d+) run_clocks=(\d+) checks=(\d+)',log)
 if not m or [int(x) for x in m.groups()[:3]]!=[17,51,85000]:raise RuntimeError('C1 sequence did not complete; see xsim.log')
 result=dict(status='AXI_SEQUENCE_PASS',frames=17,duty_checks=51,run_clocks=85000,checks=int(m[4]),rtl_dir=str(rtl),log=str(out/'xsim.log'),board='NOT_RUN')
 (out/'result.json').write_bytes((json.dumps(result,indent=2)+'\n').encode())
 print(json.dumps(result,indent=2))

if __name__=='__main__':main()
