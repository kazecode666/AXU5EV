"""Two requested full scenes: chunked Tcl transfer -> existing comparison CLIs.

HOST C produces reports from references and synthetic ticks; this is not board
or Runtime execution evidence. Tests retain artifacts and never access hardware.
"""
import ctypes as C
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import tkinter
import unittest

import test_postprocess as wire

ROOT = Path(__file__).resolve().parents[2]


class FullSceneReadbackTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        parent = ROOT/'.runtime/ax02a/runtime_r1_full_handoff'
        parent.mkdir(exist_ok=True)
        cls.folder = Path(tempfile.mkdtemp(prefix='transfer_',dir=parent))
        dll = cls.folder/'post.dll'
        subprocess.run([str(wire.GCC),'-shared','-O2','-fno-fast-math','-ffp-contract=off',
                        '-I'+str(ROOT/'firmware/r5/ax02a'),str(ROOT/'firmware/r5/ax02a/postprocess.c'),
                        '-o',str(dll),'-lm'],check=True,
                       env={**os.environ,'PATH':str(wire.GCC.parent)+os.pathsep+os.environ.get('PATH','')})
        cls.dll_dir = os.add_dll_directory(str(wire.GCC.parent))
        cls.lib = C.CDLL(str(dll))
        cls.lib.ax02a_postprocess.argtypes = [C.POINTER(C.c_double),C.c_uint32,
            C.POINTER(C.c_double),C.c_uint32,C.POINTER(C.c_uint64),C.c_uint32,
            C.POINTER(wire.Request),C.POINTER(wire.Report)]

    @classmethod
    def tearDownClass(cls):
        import _ctypes
        _ctypes.FreeLibrary(cls.lib._handle)
        cls.dll_dir.close()

    def test_full_motion_and_alignment_are_readable_by_existing_clis(self):
        for scene,n,scenario_id in [('current_motion',64536,2),('current_alignment_reset',43100,3)]:
            with self.subTest(scene=scene):
                p=self.folder/scene;p.mkdir()
                replay=ROOT/'.runtime/ax02a/replay'/scene
                reference=(replay/'reference.bin').read_bytes()
                values=(C.c_double*(n*41)).from_buffer_copy(reference)
                records=[]
                for k in range(n):
                    e=k*10000;r=e+(100 if k else 0)
                    records.extend([k,k,e,r,r+2,r+10,r+20,r+30])
                ticks=(C.c_uint64*(n*8))(*records)
                report=wire.Report()
                q=wire.Request(scenario_id,scenario_id,9,9,1,1,n,n,n,0,0,100000000,10000)
                self.assertEqual(self.lib.ax02a_postprocess(values,n*41,values,n*41,ticks,n,C.byref(q),C.byref(report)),0)
                images={0x11000000:reference,0x13000000:bytes(ticks),0x16000000:bytes(report)}
                calls=[]
                def mrd(path,address,count):
                    address=int(address);count=int(count);calls.append((address,count))
                    for base,data in images.items():
                        if base<=address and address+count<=base+len(data):
                            Path(path).write_bytes(data[address-base:address-base+count])
                            return ''
                    raise AssertionError('transfer outside completed data')
                t=tkinter.Tcl();t.createcommand('fixture_read',mrd)
                t.eval('proc targets {args} {return [list [dict create is_current 1 name "Cortex-R5 #0" suspended 1]]}; proc print {args} {set n [lindex $args end];return [dict create $n [dict get $::values $n]]}; proc mrd {args} {fixture_read [lindex $args 4] [lindex $args 5] [lindex $args 6]}')
                t.call('source',str(ROOT/'firmware/r5/ax02a/readback_short.tcl'))
                self.assertFalse(calls)
                prior=json.loads((ROOT/'.runtime/ax02a/board_manual/runtime_r1_p1000_01/run.json').read_text())
                v={'ax02a_control.'+k:x for k,x in dict(state=3,command=0,frames=n,mode=1,experiment=9).items()}
                v.update({'ax02a_control.result.'+k:x for k,x in dict(status=0,completed_frames=n,failed_frame=0).items()})
                v.update({'ax02a_control.timer.'+k:prior['timer'][k] for k in ['clock_hz','interval','prescaler','period_ticks','timestamp_read_min_ticks','timestamp_read_max_ticks','start_window_ticks']})
                v.update({'ax02a_ttc_snapshot.'+k:x for k,x in prior['ttc_snapshot'].items()})
                v.update(ax02a_runtime_candidate_id=0x52313031,ax02a_timer_mapping_version=1)
                v['ax02a_post_control.state']=2
                t.call('set','values',t.call('dict','create',*[x for pair in v.items() for x in pair]))
                capture=p/'capture'
                try:
                    t.call('ax02a_short::readback',str(capture),8,'SIMULATED transfer','false',
                           str(ROOT/'.runtime/ax02a/vitis_runtime_100us_r1/runtime_candidate.tcl'),scene)
                except tkinter.TclError as error:
                    self.fail('full scene transfer unavailable: '+str(error))
                run=json.loads((capture/'run.json').read_text())
                self.assertEqual((run['scenario'],run['frames'],run['captured_records']),(scene,n,n))
                self.assertEqual((capture/'output.bin').read_bytes(),reference)
                self.assertEqual((capture/'timing.bin').read_bytes(),bytes(ticks))
                self.assertTrue(all(count<=65536 for _,count in calls))
                self.assertEqual(sum(count for _,count in calls),n*(328+64)+2400)
                commands=[['scripts/ax02a_compare_replay.py','--timing',str(capture/'timing.bin'),
                           '--timer-hz','100000000','--period-ticks','10000','--origin','SIMULATED',
                           '--output',str(p/'compare')],
                          ['scripts/ax02a_post_report.py','crosscheck','--ticks',str(capture/'timing.bin'),
                           '--run',str(capture/'run.json'),'--report',str(capture/'report_v2.bin'),
                           '--before-experiment','8','--output',str(p/'crosscheck')]]
                for command in commands:
                    result=subprocess.run([sys.executable,*command,'--metadata',str(replay/'metadata.json'),
                              '--reference',str(replay/'reference.bin'),'--actual',str(capture/'output.bin')],
                              cwd=ROOT,capture_output=True,text=True)
                    self.assertEqual(result.returncode,0,result.stdout+result.stderr)
                self.assertTrue(json.loads((p/'crosscheck/crosscheck.json').read_text())['crosscheck_consistent'])


if __name__=='__main__':
    unittest.main()
