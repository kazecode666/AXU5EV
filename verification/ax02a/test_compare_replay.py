"""Small fault-oriented tests for the AX02A binary comparison gate."""
import importlib.util
import json
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'scripts/ax02a_compare_replay.py'


class ComparisonTests(unittest.TestCase):
    def run_case(self, alter=None, timing=None, period_ticks=None):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            rows = [[float(k + j) / 10 for j in range(41)] for k in range(3)]
            # All discrete fields start with integer data.
            for row in rows:
                for j in [3,4,6,9,10,11,15,16,17,20,22,24,25,26,29,30,31,32,33,35]:
                    row[j] = 0
            data = b''.join(struct.pack('<41d', *row) for row in rows)
            (folder / 'reference.bin').write_bytes(data)
            actual = [row[:] for row in rows]
            if alter:
                alter(actual)
            (folder / 'actual.bin').write_bytes(b''.join(struct.pack('<41d', *r) for r in actual))
            (folder / 'metadata.json').write_text(json.dumps({'frames':3,'Ts':0.0001}))
            args=[sys.executable,str(SCRIPT),'--metadata',str(folder/'metadata.json'),
                  '--reference',str(folder/'reference.bin'),'--actual',str(folder/'actual.bin'),
                  '--output',str(folder/'result')]
            if timing is not None:
                (folder/'timing.bin').write_bytes(b''.join(struct.pack('<8Q',*r) for r in timing))
                args += ['--timing',str(folder/'timing.bin'),'--timer-hz','100000000']
                if period_ticks is not None:
                    args += ['--period-ticks',str(period_ticks)]
            result = subprocess.run(args, capture_output=True, text=True)
            self.assertTrue(SCRIPT.exists(), 'comparison executable is missing')
            return result

    def test_equal(self):
        self.assertEqual(self.run_case().returncode,0)

    def test_missing_frame(self):
        self.assertNotEqual(self.run_case(lambda r:r.pop()).returncode,0)

    def test_discrete_one_tick_or_tiny_error_is_rejected(self):
        self.assertNotEqual(self.run_case(lambda r:r[1].__setitem__(30,1e-12)).returncode,0)

    def test_nan(self):
        self.assertNotEqual(self.run_case(lambda r:r[1].__setitem__(0,float('nan'))).returncode,0)

    def test_continuous_tolerance(self):
        self.assertEqual(self.run_case(lambda r:r[1].__setitem__(0,r[1][0]+1e-10)).returncode,0)

    def test_deadline_failure(self):
        records=[[k,k,10000*k,10000*k,10000*k,10000*k+20,10000*k+200,10000*k+250] for k in range(3)]
        records[1][-1]=20001
        self.assertNotEqual(self.run_case(timing=records).returncode,0)

    def test_valid_timing(self):
        records=[[k,k,10000*k,10000*k,10000*k,10000*k+20,10000*k+200,10000*k+250] for k in range(3)]
        self.assertEqual(self.run_case(timing=records).returncode,0)

    def test_one_millisecond_period_is_not_100us_pass(self):
        records=[[k,k,100000*k,100000*k,100000*k,100000*k+20,100000*k+200,100000*k+250] for k in range(3)]
        self.assertNotEqual(self.run_case(timing=records,period_ticks=100000).returncode,0)

    def test_lost_release_failure(self):
        records=[[k,k,10000*k,10000*k,10000*k,10000*k+20,10000*k+200,10000*k+250] for k in range(3)]
        records[1][1]=2
        self.assertNotEqual(self.run_case(timing=records).returncode,0)


if __name__ == '__main__':
    unittest.main()
