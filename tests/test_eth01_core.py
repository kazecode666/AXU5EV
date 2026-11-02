from pathlib import Path
import subprocess
import unittest
import os

ROOT=Path(__file__).resolve().parents[1]
class CoreTests(unittest.TestCase):
    def test_native_generated_model_and_queues(self):
        header=ROOT/'integration/r5_ethernet/eth_model_if.h'
        self.assertTrue(header.exists(),'bounded model interface not implemented')
        compiler=Path('C:/ProgramData/MATLAB/SupportPackages/R2026b/3P.instrset/mingw_w64.instrset/bin/gcc.exe')
        self.assertTrue(compiler.exists())
        gen=ROOT/'.runtime/ethernet/eth01/model/codegen/ETH01_Target_ert_rtw'
        exe=ROOT/'.runtime/ethernet/eth01/host_core.exe'
        env=dict(os.environ);env['PATH']=str(compiler.parent)+os.pathsep+env['PATH']
        subprocess.run([str(compiler),'-std=c11','-Wall','-Wextra','-Werror','-O2',
          '-I'+str(gen),'-I'+str(header.parent),'-I'+str(ROOT/'firmware/r5/ethernet'),
          str(ROOT/'tests/eth01_core_test.c'),str(header.with_suffix('.c')),str(header.parent/'eth_queue.c'),str(gen/'ETH01_Target.c'),
          str(ROOT/'firmware/r5/ethernet/eth_protocol.c'),'-o',str(exe)],check=True,env=env)
        subprocess.run([str(exe)],check=True)
if __name__=='__main__':unittest.main()
