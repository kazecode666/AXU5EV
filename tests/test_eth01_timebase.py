from pathlib import Path
import re
import unittest
import os
import subprocess
ROOT=Path(__file__).resolve().parents[1]
class TimebaseTests(unittest.TestCase):
    def test_macro_expression_has_grouped_frequency(self):
        code=(ROOT/'firmware/r5/ethernet/eth_platform.c').read_text()
        expression=re.search(r'return \(u32_t\)\((ticks\*1000U/.*?)\);',code).group(1)
        # Installed xiltimer defines CPU/64 without parentheses. The grouping
        # must remain at the use site; a second division by64 is 4096x wrong.
        source=ROOT/'.runtime/ethernet/eth01/timebase_test.c'
        source.write_text('#include <stdint.h>\n#define COUNTS_PER_SECOND 499994995/64\nint main(void){uint64_t ticks=7812421; return ('+expression+')==1000?0:1;}\n')
        gcc=Path('C:/ProgramData/MATLAB/SupportPackages/R2026b/3P.instrset/mingw_w64.instrset/bin/gcc.exe')
        env=dict(os.environ);env['PATH']=str(gcc.parent)+os.pathsep+env['PATH']
        exe=source.with_suffix('.exe')
        subprocess.run([str(gcc),str(source),'-o',str(exe)],check=True,env=env)
        subprocess.run([str(exe)],check=True)
if __name__=='__main__':unittest.main()
