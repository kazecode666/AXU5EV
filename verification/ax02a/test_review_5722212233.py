"""Review counterexamples through real CLI/Tcl, with HOST C report production."""
import ctypes as C
import importlib.util
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import tkinter
import unittest

ROOT = Path(__file__).resolve().parents[2]
GCC = Path('C:/ProgramData/MATLAB/SupportPackages/R2026b/3P.instrset/mingw_w64.instrset/bin/gcc.exe')


def kept_dir():
    # Never restore prior temporary paths or delete test artifacts.
    parent = ROOT / '.runtime/ax02a/review_5722212233'
    parent.mkdir(exist_ok=True)
    return Path(tempfile.mkdtemp(prefix='case_', dir=parent))


class ReportCrosscheckTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location('post_types', Path(__file__).with_name('test_postprocess.py'))
        cls.types = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.types)
        cls.folder = kept_dir()
        dll = cls.folder / 'post.dll'
        subprocess.run([str(GCC), '-shared', '-O2', '-fno-fast-math', '-ffp-contract=off',
                        '-Wall', '-Wextra', '-Werror', '-I'+str(ROOT/'firmware/r5/ax02a'),
                        str(ROOT/'firmware/r5/ax02a/postprocess.c'), '-o', str(dll), '-lm'],
                       check=True, env={**os.environ, 'PATH':str(GCC.parent)+os.pathsep+os.environ.get('PATH','')})
        cls.dll_dir = os.add_dll_directory(str(GCC.parent))
        cls.lib = C.CDLL(str(dll))
        cls.lib.ax02a_postprocess.argtypes = [C.POINTER(C.c_double), C.c_uint32,
            C.POINTER(C.c_double), C.c_uint32, C.POINTER(C.c_uint64), C.c_uint32,
            C.POINTER(cls.types.Request), C.POINTER(cls.types.Report)]

    @classmethod
    def tearDownClass(cls):
        import _ctypes
        _ctypes.FreeLibrary(cls.lib._handle)
        cls.dll_dir.close()

    def crosscheck(self, fault=None, change=None, n=1000, mode=1):
        p = kept_dir()
        out = [0.] * (n*41)
        if fault == 'numeric':
            out[41] = 1.
        ref = (C.c_double*(n*41))()
        actual = (C.c_double*(n*41))(*out)
        records = []
        for k in range(n):
            e = k*10000
            release = e + (k if fault == 'trend' else 0)
            row = [k,k,e,release,release+2,release+10,release+20,release+30]
            if fault == 'deadline' and k == 2:
                row[-1] = e+10000
            records.extend(row)
        ticks = (C.c_uint64*(n*8))(*records)
        report = self.types.Report()
        q = self.types.Request(1,1,8,8,mode,mode,n,n,n,0,0,100000000,10000)
        self.lib.ax02a_postprocess(actual,n*41,ref,n*41,ticks,n,C.byref(q),C.byref(report))
        raw = bytearray(bytes(report))
        if change:
            offset, value = change
            struct.pack_into('<I',raw,offset,value)
        (p/'report.bin').write_bytes(raw)
        (p/'reference.bin').write_bytes(bytes(ref))
        (p/'output.bin').write_bytes(bytes(actual))
        (p/'timing.bin').write_bytes(bytes(ticks))
        meta = dict(scenario='current_motion_prefix',source_scenario='current_motion',
                    source_range=[0,n],frames=n,Ts=.0001,input_fields=20,output_fields=41)
        timer = dict(clock_hz=100000000,interval=9999,prescaler=16,period_ticks=10000,
                     timestamp_read_min_ticks=1,timestamp_read_max_ticks=3,start_window_ticks=2,
                     mapping_version=1,candidate_id=0x52313031,periodic_base=0xff110000,
                     timestamp_base=0xff110004,periodic_clock=0,timestamp_clock=0)
        run = dict(scenario=meta['scenario'],experiment=8,mode=mode,frames=n,state=3,
                   interrupted=False,conditions='SIMULATED review',
                   result=dict(status=0,completed_frames=n),timer=timer)
        (p/'metadata.json').write_text(json.dumps(meta))
        (p/'run.json').write_text(json.dumps(run))
        cmd = [sys.executable,str(ROOT/'scripts/ax02a_post_report.py'),'crosscheck']
        for key,name in [('metadata','metadata.json'),('reference','reference.bin'),
                         ('actual','output.bin'),('ticks','timing.bin'),('run','run.json'),
                         ('report','report.bin'),('output','analysis')]:
            cmd += ['--'+key,str(p/name)]
        result = subprocess.run(cmd+['--before-experiment','7'],capture_output=True,text=True)
        self.assertTrue((p/'analysis/crosscheck.json').is_file(),result.stderr)
        summary = json.loads((p/'analysis/crosscheck.json').read_text())
        return result.returncode, summary

    def test_report_mutations_cannot_pass_or_claim_consistency(self):
        # Fixed wire offsets from the report ABI, independent of decoder logic.
        for name,offset,value in [('deadline_status',2336,1),('phase_samples',2344,0),
                                  ('empty_command_samples',2016,1),('compare_status',40,1),
                                  ('timing_status',44,2),('numeric_errors',52,1),
                                  ('timing_errors',56,1),('completed',32,999),
                                  ('contract_errors',48,1),('p99_status',60,0)]:
            with self.subTest(name=name):
                code,s = self.crosscheck(change=(offset,value))
                self.assertEqual(code,1)
                self.assertFalse(s['passed'])
                self.assertFalse(s['crosscheck_consistent'])

    def test_agreeing_pass_and_agreeing_rejections_remain_distinct(self):
        for fault,passed in [(None,True),('numeric',False),('deadline',False),('trend',False)]:
            with self.subTest(fault=fault):
                code,s = self.crosscheck(fault=fault)
                self.assertEqual(code,0 if passed else 1)
                self.assertEqual(s['passed'],passed)
                self.assertTrue(s['crosscheck_consistent'])
        code,s = self.crosscheck(n=3)
        self.assertEqual(code,1)
        self.assertFalse(s['passed'])
        self.assertTrue(s['crosscheck_consistent'])
        code,s = self.crosscheck(mode=0)
        self.assertEqual(code,0)
        self.assertTrue(s['crosscheck_consistent'])


class FailureReadbackTests(unittest.TestCase):
    def setUp(self):
        self.p = kept_dir()
        self.t = tkinter.Tcl()
        self.t.eval('set calls {}; proc targets {args} {return [list [dict create is_current 1 name "Cortex-R5 #0" suspended 1]]}')
        self.t.eval('proc print {args} {set n [lindex $args end];return [dict create $n [dict get $::values $n]]}')
        self.t.eval('proc mrd {args} {lappend ::calls $args;set f [open [lindex $args 4] wb];puts -nonewline $f [string repeat x [lindex $args end]];close $f}')
        self.t.call('source',str(ROOT/'firmware/r5/ax02a/readback_short.tcl'))
        self.assertEqual(self.t.eval('llength $calls'),'0')
        self.prov = self.p/'candidate.tcl'
        self.prov.write_text('dict create candidate_id 1378955313 mapping_version 1 workspace candidate1 elf candidate1/app.elf')

    def values(self, status=0, count=1000, timer_ok=True, post=2, overrides=None):
        v = {'ax02a_control.'+k:x for k,x in dict(state=4 if status else 3,command=0,
             mode=1,frames=1000,experiment=8).items()}
        v.update({'ax02a_control.result.'+k:x for k,x in dict(status=status,
             completed_frames=count,failed_frame=count if status else 0).items()})
        timer = dict(clock_hz=100000000,interval=9999,prescaler=16,period_ticks=10000,
                     timestamp_read_min_ticks=1,timestamp_read_max_ticks=3,start_window_ticks=2)
        snapshot = dict(valid=1,periodic_base=0xff110000,timestamp_base=0xff110004,
                        periodic_hz=100000000,timestamp_hz=100000000,hardware_interval=9999,
                        logical_period_ticks=10000,periodic_clock=0,timestamp_clock=0,
                        periodic_control=35,timestamp_control=33,periodic_ier=1,timestamp_ier=0)
        if not timer_ok:
            timer = dict.fromkeys(timer,0)
            snapshot['valid'] = 0
        v.update({'ax02a_control.timer.'+k:x for k,x in timer.items()})
        v.update({'ax02a_ttc_snapshot.'+k:x for k,x in snapshot.items()})
        v.update(ax02a_runtime_candidate_id=0x52313031,ax02a_timer_mapping_version=1)
        v['ax02a_post_control.state'] = post
        v.update(overrides or {})
        self.t.call('set','values',self.t.call('dict','create',*[y for pair in v.items() for y in pair]))

    def read(self,name='capture'):
        self.t.call('ax02a_short::readback',(self.p/name).as_posix(),7,'SIMULATED review','false',self.prov.as_posix())
        return self.p/name

    def test_prepare_failure_saves_metadata_without_stale_ddr(self):
        self.values(status=3,count=0,timer_ok=False,post=0)
        try:
            p = self.read()
        except tkinter.TclError as error:
            self.fail('confirmed ERROR must save run.json: '+str(error))
        run = json.loads((p/'run.json').read_text())
        self.assertEqual(run['result']['status'],3)
        self.assertEqual(run['result']['completed_frames'],0)
        self.assertEqual(run['timer']['clock_hz'],0)
        self.assertEqual(run['ttc_snapshot']['valid'],0)
        self.assertEqual(run['captured_records'],0)
        self.assertFalse(run['report_captured'])
        self.assertEqual(self.t.eval('llength $calls'),'0')
        self.assertEqual([x.name for x in p.iterdir()],['run.json'])

    def test_failed_prefix_is_bounded_and_no_report_is_claimed(self):
        self.values(status=2,count=7,post=0)
        p = self.read()
        self.assertEqual((p/'output.bin').stat().st_size,7*328)
        self.assertEqual((p/'timing.bin').stat().st_size,7*64)
        self.assertFalse((p/'report_v2.bin').exists())
        self.assertFalse(json.loads((p/'run.json').read_text())['report_captured'])

    def test_complete_success_and_missing_postprocess_are_distinct(self):
        self.values()
        p = self.read('complete')
        self.assertEqual((p/'report_v2.bin').stat().st_size,2400)
        self.values(post=0)
        p = self.read('no_report')
        self.assertFalse((p/'report_v2.bin').exists())
        self.assertFalse(json.loads((p/'run.json').read_text())['report_captured'])

    def test_failure_cannot_bypass_identity_or_success_checks(self):
        for i,override in enumerate([{'ax02a_runtime_candidate_id':0},
                                     {'ax02a_timer_mapping_version':0},
                                     {'ax02a_control.experiment':7},
                                     {'ax02a_control.state':2},
                                     {'ax02a_control.result.completed_frames':1001}]):
            self.values(status=3,count=0,timer_ok=False,overrides=override)
            with self.assertRaises(tkinter.TclError):
                self.read('bad'+str(i))
            self.assertFalse((self.p/('bad'+str(i))).exists())
        self.values(timer_ok=False)
        with self.assertRaises(tkinter.TclError):
            self.read('bad_success')
        self.assertEqual(self.t.eval('llength $calls'),'0')


class BuildVersionTests(unittest.TestCase):
    def test_explicit_r1_preflight_accepts_version_without_creating_workspace(self):
        p = kept_dir()
        config = json.loads((ROOT/'firmware/r5/ax02a/build_config.runtime_100us_r1.json').read_text())
        config['workspace'] = str(p/'must_not_be_created')
        (p/'config.json').write_text(json.dumps(config))
        compiler_dir = 'E:/AMDDesignTools/2026.1/Vitis/gnu/armr5/nt/gcc-arm-none-eabi/bin'
        result = subprocess.run([sys.executable,str(ROOT/'scripts/ax02a_build_r5.py'),
                  '--config',str(p/'config.json'),'--preflight'],capture_output=True,text=True,
                  env={**os.environ,'PATH':compiler_dir+os.pathsep+os.environ.get('PATH','')})
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('R5_BUILD_PREFLIGHT_PASS',result.stdout)
        self.assertFalse((p/'must_not_be_created').exists())

    def test_complete_build_and_preflight_reject_undeclared_versions_before_creation(self):
        for version in [None,0,2,True,'1']:
            for preflight in [False,True]:
                with self.subTest(version=version,preflight=preflight):
                    p = kept_dir()
                    config = json.loads((ROOT/'firmware/r5/ax02a/build_config.phase.json').read_text())
                    config['workspace'] = str(p/'must_not_be_created')
                    if version is not None:
                        config['runtime_mapping'] = version
                    (p/'config.json').write_text(json.dumps(config))
                    result = subprocess.run([sys.executable,str(ROOT/'scripts/ax02a_build_r5.py'),
                              '--config',str(p/'config.json')]+(['--preflight'] if preflight else []),
                              capture_output=True,text=True)
                    self.assertEqual(result.returncode,1)
                    self.assertIn('runtime_mapping=1',result.stderr)
                    self.assertFalse((p/'must_not_be_created').exists())

    def test_existing_legacy_and_r1_readonly_startup_stay_compatible(self):
        for name in ['phase','runtime_100us_r1']:
            result = subprocess.run([sys.executable,str(ROOT/'scripts/ax02a_build_r5.py'),
                      '--config',str(ROOT/f'firmware/r5/ax02a/build_config.{name}.json'),
                      '--check-startup'],capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual(json.loads(result.stdout)['status'],'OFFLINE_STARTUP_CHECK_PASS')


if __name__ == '__main__':
    unittest.main()
