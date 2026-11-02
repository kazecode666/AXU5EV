import os
from pathlib import Path
import subprocess
import unittest
ROOT=Path(__file__).resolve().parents[1]
def function(text,signature):
    a=text.index(signature);b=text.index('{',a);depth=1;e=b+1
    while depth:
        depth+=(text[e]=='{')-(text[e]=='}');e+=1
    return text[a:e]
class RawCallbackTests(unittest.TestCase):
    def test_pbuf_chain_err_mem_credit_and_half_close(self):
        text=(ROOT/'firmware/r5/ethernet/eth_platform.c').read_text()
        code='\n'.join(function(text,s) for s in ['static err_t received(', 'static void NetService('])
        source=ROOT/'.runtime/ethernet/eth01/raw_callback_test.c'
        source.write_text((ROOT/'tests/eth01_raw_fixture.c').read_text().replace('/* PRODUCTION_FUNCTIONS */',code))
        gcc=Path('C:/ProgramData/MATLAB/SupportPackages/R2026b/3P.instrset/mingw_w64.instrset/bin/gcc.exe')
        env=dict(os.environ);env['PATH']=str(gcc.parent)+os.pathsep+env['PATH']
        gen=ROOT/'.runtime/ethernet/eth01/model/codegen/ETH01_Target_ert_rtw'
        files=[source,ROOT/'firmware/r5/ethernet/eth_protocol.c',ROOT/'firmware/r5/ethernet/eth_service.c',ROOT/'integration/r5_ethernet/eth_model_if.c',ROOT/'integration/r5_ethernet/eth_queue.c',gen/'ETH01_Target.c']
        exe=source.with_suffix('.exe')
        subprocess.run([str(gcc),'-std=c11','-O2','-Wall','-Wextra','-Werror','-I'+str(gen),'-I'+str(ROOT/'firmware/r5/ethernet'),'-I'+str(ROOT/'integration/r5_ethernet'),*map(str,files),'-o',str(exe)],check=True,env=env)
        subprocess.run([str(exe)],check=True,timeout=10)
if __name__=='__main__':unittest.main()
