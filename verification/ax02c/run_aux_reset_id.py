"""Targeted reset-IP polarity and first AXI ID check; no historical replay."""
import argparse,json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'verification/ax02b'))
from run_checks import tool

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--out',type=Path,required=True)
p.add_argument('--reset-netlist',type=Path,required=True)
a=p.parse_args();out=a.out.resolve();out.mkdir(parents=True,exist_ok=False)
rtl=ROOT/'.runtime/ax02b/candidate_01/rtl/AX02B_P3_5EV'
m=json.loads((ROOT/'generated/legacy_m3_p3/manifest.json').read_text(encoding='utf-8'))
files=[rtl/x['path'] for x in m['design_files']]+[
 ROOT/'integration/rtl/axu5ev_foc_frame_top.sv',ROOT/'integration/rtl/axu5ev_foc_axi.sv',
 a.reset_netlist.resolve(),ROOT/'verification/ax02c/aux_reset_id_tb.sv',
 Path('E:/AMDDesignTools/2026.1/Vivado/data/verilog/src/glbl.v')]
args=out/'sources.args';args.write_text('--sv\n--work work\n'+''.join('"'+f.as_posix()+'"\n' for f in files),encoding='utf-8')
tool('xvlog',['-f',str(args)],out)
tool('xelab',['-L','unisims_ver','aux_reset_id_tb','glbl','-s','reset_id'],out)
log=tool('xsim',['reset_id','-runall'],out)
if 'AUX_RESET_ID_PASS original_resetn=0 fixed_resetn=1 id=43314301 checks=3' not in log:
 raise RuntimeError('targeted reset/ID check did not pass')
result=dict(status='AUX_RESET_ID_PASS',checks=3,original_resetn=0,fixed_resetn=1,
 id='0x43314301',native_reset_netlist=str(a.reset_netlist.resolve()),log=str(out/'xsim.log'),board='NOT_RUN')
(out/'result.json').write_bytes((json.dumps(result,indent=2)+'\n').encode())
print(json.dumps(result,indent=2))
