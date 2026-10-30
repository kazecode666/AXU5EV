"""TTC-only contracts; synthetic IRQs are never hardware evidence."""
import importlib.util
from contextlib import contextmanager
import json
import os
from pathlib import Path
import random
import struct
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


@contextmanager
def preserved_temp():
    # Project forbids batch deletion; leave explicit test artifacts in ignored runtime.
    yield tempfile.mkdtemp(prefix='ttc_test_',dir=ROOT/'.runtime/ax02a')


def module(name):
    path = ROOT / 'scripts' / (name + '.py')
    if not path.exists():
        raise AssertionError('missing implementation: ' + name)
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def fixture(path, case='A1', raw=10000, extra=0, delay_growth=0, jitter=False, experiment=8):
    path.mkdir()
    rng = random.Random(42)
    rows = []
    for k in range(1000):
        delay = 100 + delay_growth*k + (rng.randrange(-20, 21) if jitter else 0)
        event = 500 + (k+1)*(raw+extra)
        rows.append([k, event+delay-4, delay, event+delay+4])
    run = dict(magic=0x31435454, version=1, record_bytes=16, case_id=case,
               before_experiment=experiment-1, experiment=experiment, requested_raw=raw,
               actual_raw=raw, nominal_period=10000, requested_samples=1000,
               completed_samples=1000, state=3, error=0, interrupted=False,
               timeout_ticks=1100*(raw+1)+100000,
               conditions='same warm session I-cache ON D-cache OFF', session_id='session1',
               clock_basis='BSP configuration, not measured', workspace='candidate1', elf='candidate1/app.elf',build_id=123,
               config=dict(periodic_clock=0, timestamp_clock=0, periodic_control=35,
                           timestamp_control=33, periodic_ier=1, timestamp_ier=0,
                           periodic_hz=100000000, timestamp_hz=100000000,
                           periodic_base=0xff110000, timestamp_base=0xff110004))
    return rows, run


def save(path, rows, run):
    (path/'samples.bin').write_bytes(b''.join(struct.pack('<4I', *r) for r in rows))
    (path/'run.json').write_text(json.dumps(run))


class AnalyzeTests(unittest.TestCase):
    def setUp(self):
        self.path = Path(tempfile.mkdtemp(prefix='ttc_analysis_',dir=ROOT/'.runtime/ax02a'))
        self.mod = module('ax02a_analyze_ttc_characterize')

    def single(self, extra=0, growth=0, jitter=False, mutate=None):
        d = self.path / ('run'+str(len(list(self.path.iterdir()))))
        rows, run = fixture(d, extra=extra, delay_growth=growth, jitter=jitter)
        if mutate: mutate(rows, run)
        save(d, rows, run)
        return self.mod.analyze_run(d/'samples.bin', d/'run.json', self.path/(d.name+'out'))

    def test_raw_and_raw_plus_one_fixed_and_random_delay(self):
        for extra in [0, 1]:
            for jitter in [False, True]:
                r = self.single(extra, jitter=jitter)
                self.assertTrue(r['acquisition_valid'])
                self.assertEqual(r['hypothesis'], 'RAW_PLUS_ONE_COMPATIBLE' if extra else 'RAW_COMPATIBLE')
                self.assertAlmostEqual(r['all_samples']['event']['slope'], 10000+extra)
                self.assertEqual(r['hardware_irq_loss'], 'UNKNOWN')
                self.assertEqual(r['all_samples']['count'], 1000)
                self.assertEqual(r['after_first']['count'], 999)

    def test_delay_growth_does_not_become_event_drift(self):
        r = self.single(growth=1)
        self.assertEqual(r['hypothesis'], 'RAW_COMPATIBLE')
        self.assertAlmostEqual(r['all_samples']['p_count']['slope'], 1)
        self.assertAlmostEqual(r['all_samples']['isr_phase']['slope'], 1)
        self.assertAlmostEqual(r['all_samples']['event']['slope'], 10000)

    def test_timeout_metadata_and_late_capture_rejected(self):
        def late(rows,run):
            for x in rows: x[1]+=8000000; x[3]+=8000000
        for fault in [late,lambda rows,run: run.update(timeout_ticks=20000000)]:
            r=self.single(mutate=fault)
            self.assertFalse(r['acquisition_valid'])
            self.assertEqual(r['hypothesis'],'INCONCLUSIVE')

    def test_bad_data_never_supports_mapping(self):
        faults = [
            lambda a,r: r.update(version=2), lambda a,r: r.update(actual_raw=9999),
            lambda a,r: r.update(interrupted=True), lambda a,r: r.update(completed_samples=999),
            lambda a,r: a.pop(), lambda a,r: a[30].__setitem__(0,29),
            lambda a,r: a[30].__setitem__(1,a[30][3]+1),
            lambda a,r: a[30].__setitem__(2,9999),
            lambda a,r: a[30].__setitem__(2,1),
            lambda a,r: a[30].__setitem__(3,a[30][1]+7000),
            lambda a,r: [v.__setitem__(1,v[1]+10000) or v.__setitem__(3,v[3]+10000) for v in a[30:]],
            lambda a,r: a[999].__setitem__(1,0),
        ]
        for fault in faults:
            with self.subTest(fault=fault):
                r=self.single(mutate=fault)
                self.assertFalse(r['acquisition_valid']); self.assertEqual(r['hypothesis'],'INCONCLUSIVE')
                self.assertTrue(r['issues'])

    def test_negative_phase_and_wide_ambiguous_window(self):
        def shift(a,r):
            for x in a: x[1]-=9000; x[3]-=9000
        r=self.single(mutate=shift)
        self.assertTrue(r['acquisition_valid']); self.assertLess(r['all_samples']['isr_phase']['first'],0)
        r=self.single(mutate=lambda a,r: [x.__setitem__(3,x[1]+800) for x in a])
        self.assertEqual(r['hypothesis'],'INCONCLUSIVE')

    def test_aba_identity_repeatability_and_mapping(self):
        for extra in [0,1]:
            paths=[]
            for case,raw,e in [('A1',10000,8),('B',9999,9),('A2',10000,10)]:
                d=self.path/(case+str(extra)); a,r=fixture(d,case,raw,extra,experiment=e);save(d,a,r);paths.append(d)
            out=self.path/('aba'+str(extra))
            r=self.mod.compare_aba(*paths,out)
            self.assertEqual(r['conclusion'],'RAW_PLUS_ONE_COMPATIBLE' if extra else 'RAW_COMPATIBLE')
            self.assertTrue(r['repeatable'])
            with self.assertRaises(ValueError): self.mod.compare_aba(*paths,out)
            a2=paths[2];r=json.loads((a2/'run.json').read_text());r['elf']='other';(a2/'run.json').write_text(json.dumps(r))
            self.assertEqual(self.mod.compare_aba(*paths,self.path/('mixed'+str(extra)))['conclusion'],'INCONCLUSIVE')

    def test_aba_nonrepeatable_and_wrong_case(self):
        paths=[]
        for case,raw,e,extra in [('A1',10000,3,0),('B',9999,4,0),('A2',10000,5,1)]:
            d=self.path/case;a,r=fixture(d,case,raw,extra,experiment=e);save(d,a,r);paths.append(d)
        r=self.mod.compare_aba(*paths,self.path/'out');self.assertFalse(r['repeatable'])
        self.assertEqual(r['conclusion'],'INCONCLUSIVE')
        r=self.mod.compare_aba(paths[1],paths[0],paths[2],self.path/'wrong');self.assertEqual(r['conclusion'],'INCONCLUSIVE')


class FirmwareTests(unittest.TestCase):
    def test_lifecycle_real_c_with_host_hal(self):
        self.assertTrue((ROOT/'firmware/r5/ax02a/ttc_characterize.c').exists(),'TTC collection C missing')
        gcc=Path('C:/ProgramData/MATLAB/SupportPackages/R2026b/3P.instrset/mingw_w64.instrset/bin/gcc.exe')
        with preserved_temp() as d:
            exe=Path(d)/'contract.exe'
            subprocess.run([str(gcc),'-std=c11','-O2','-Wall','-Wextra','-Werror','-DAX02A_TTC_HOST',
                            '-I'+str(ROOT/'firmware/r5/ax02a'),str(ROOT/'firmware/r5/ax02a/ttc_characterize.c'),
                            str(ROOT/'verification/ax02a/ttc_characterize_contract.c'),'-o',str(exe)],check=True,
                           env={**os.environ,'PATH':str(gcc.parent)+os.pathsep+os.environ['PATH']})
            p=subprocess.run([str(exe)],capture_output=True,text=True,check=True)
            self.assertIn('TTC_HOST_CONTRACT_PASS',p.stdout)


class DeliveryTests(unittest.TestCase):
    def test_config_paths_independent_of_cwd(self):
        m=module('ax02a_build_ttc_characterize')
        config=ROOT/'firmware/r5/ax02a/build_config.ttc_characterize.json'
        expected=m.load_config(config)
        old=Path.cwd()
        try:
            os.chdir(ROOT/'.runtime/ax02a/vitis_phase_diagnostic')
            self.assertEqual(m.load_config(config),expected)
            self.assertEqual(expected['workspace'],ROOT/'.runtime/ax02a/vitis_ttc_characterize')
        finally:os.chdir(old)

    def test_passive_readback_stale_mixed_failed_and_existing(self):
        import tkinter
        t=tkinter.Tcl();t.eval('set calls {}; proc targets {args} {return [list [dict create is_current 1 name "Cortex-R5 #0" suspended 1]]}')
        t.eval('proc print {args} {set s [lindex $args end]; if {$s eq "&ax02a_ttc_char_samples"} {return [dict create $s 2097152]}; set f [string range $s 23 end]; return [dict create $s [dict get $::values $f]]}')
        t.eval('proc mrd {args} {lappend ::calls $args;set i [lsearch $args -file];set f [open [lindex $args [expr {$i+1}]] wb];puts -nonewline $f [string repeat A [lindex $args end]];close $f}')
        script=ROOT/'firmware/r5/ax02a/readback_ttc_characterize.tcl'
        self.assertTrue(script.exists(),'passive readback missing')
        t.call('source',script.as_posix());self.assertEqual(t.eval('llength $calls'),'0')
        with preserved_temp() as tmp:
            d=Path(tmp);prov=d/'prov.tcl'
            prov.write_text('dict create build_id 123 workspace candidate1 elf candidate1/app.elf samples_address 2097152')
            values=dict(magic=0x31435454,version=1,record_bytes=16,state=3,command=0,experiment=8,case_id=1,
                        requested_raw=10000,actual_raw=10000,nominal_period=10000,requested_samples=1000,
                        completed_samples=1000,error=0,timeout_ticks=11101100,build_id=123,
                        periodic_hz=100000000,timestamp_hz=100000000,periodic_base=0xff110000,timestamp_base=0xff110004,
                        periodic_clock=0,timestamp_clock=0,periodic_control=35,timestamp_control=33,periodic_ier=1,timestamp_ier=0)
            def setvalues(v):t.call('set','values',t.call('dict','create',*[y for x in v.items() for y in x]))
            setvalues(values)
            args=['A1',7,10000,prov.as_posix(),'session1','same warm session','false']
            t.call('ax02a_ttc_char::readback',(d/'A1').as_posix(),*args)
            r=json.loads((d/'A1/run.json').read_text());self.assertEqual(r['completed_samples'],1000)
            self.assertEqual((d/'A1/samples.bin').stat().st_size,16000)
            with self.assertRaises(tkinter.TclError):t.call('ax02a_ttc_char::readback',(d/'A1').as_posix(),*args)
            for key,value in [('build_id',124),('actual_raw',9999),('experiment',7),('case_id',2)]:
                v={**values,key:value};setvalues(v)
                with self.assertRaises(tkinter.TclError):t.call('ax02a_ttc_char::readback',(d/key).as_posix(),*args)
            setvalues({**values,'state':4,'error':3,'completed_samples':12})
            t.call('ax02a_ttc_char::readback',(d/'failed').as_posix(),*args)
            self.assertEqual((d/'failed/samples.bin').stat().st_size,192)
            self.assertEqual(json.loads((d/'failed/run.json').read_text())['state'],4)


if __name__ == '__main__': unittest.main()
