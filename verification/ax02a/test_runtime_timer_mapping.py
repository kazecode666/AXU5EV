"""Runtime R1 mapping is platform evidence scoped; legacy traces remain legacy."""
import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import tkinter
import unittest

ROOT=Path(__file__).resolve().parents[2]
SPEC=importlib.util.spec_from_file_location('analyze',ROOT/'scripts/ax02a_analyze_run.py')
ANALYZE=importlib.util.module_from_spec(SPEC);SPEC.loader.exec_module(ANALYZE)


def timer():
    return dict(clock_hz=100000000,interval=9999,prescaler=16,period_ticks=10000,
                timestamp_read_min_ticks=26,timestamp_read_max_ticks=26,start_window_ticks=91,
                mapping_version=1,candidate_id=0x52313031,periodic_base=0xff110000,timestamp_base=0xff110004,
                periodic_clock=0,timestamp_clock=0)


class RuntimeMappingTests(unittest.TestCase):
    def test_new_candidate_readback_identity_and_bad_snapshot_rejected(self):
        t=tkinter.Tcl();t.eval('set calls {}; proc targets {args} {return [list [dict create is_current 1 name "Cortex-R5 #0" suspended 1]]}')
        t.eval('proc print {args} {set n [lindex $args end];return [dict create $n [dict get $::values $n]]}')
        t.eval('proc mrd {args} {lappend ::calls $args;set f [open [lindex $args 4] wb];puts -nonewline $f [string repeat x [lindex $args end]];close $f}')
        t.call('source',str(ROOT/'firmware/r5/ax02a/readback_short.tcl'));self.assertEqual(t.eval('llength $calls'),'0')
        p=Path(tempfile.mkdtemp(prefix='runtime_r1_read_',dir=ROOT/'.runtime/ax02a'))
        prov=p/'candidate.tcl';prov.write_text('dict create candidate_id 1378955313 mapping_version 1 workspace candidate1 elf candidate1/app.elf')
        v={'ax02a_control.'+k:x for k,x in dict(state=3,command=0,mode=1,frames=1000,experiment=8).items()}
        v.update({'ax02a_control.result.'+k:x for k,x in dict(status=0,completed_frames=1000,failed_frame=0).items()})
        v.update({'ax02a_control.timer.'+k:x for k,x in timer().items() if k not in ['mapping_version','candidate_id','periodic_base','timestamp_base','periodic_clock','timestamp_clock']})
        v.update({'ax02a_ttc_snapshot.'+k:x for k,x in dict(valid=1,hardware_interval=9999,logical_period_ticks=10000,periodic_hz=100000000,timestamp_hz=100000000,periodic_base=-15663104,timestamp_base=-15663100,periodic_clock=0,timestamp_clock=0).items()})
        v.update(ax02a_runtime_candidate_id=0x52313031,ax02a_timer_mapping_version=1)
        def values(data):t.call('set','values',t.call('dict','create',*[y for item in data.items() for y in item]))
        values(v);args=[7,'same session I-cache ON D-cache OFF','false',prov.as_posix()]
        t.call('ax02a_short::readback',(p/'good').as_posix(),*args)
        r=json.loads((p/'good/run.json').read_text());self.assertEqual(ANALYZE.validate_timer(r['timer']),(100000000,10000))
        self.assertEqual((p/'good/report_v2.bin').stat().st_size,2400)
        for k,x in [('ax02a_runtime_candidate_id',0),('ax02a_control.timer.interval',10000),('ax02a_ttc_snapshot.valid',0),('ax02a_ttc_snapshot.periodic_base',0)]:
            values({**v,k:x})
            with self.assertRaises(tkinter.TclError):t.call('ax02a_short::readback',(p/k).as_posix(),*args)

    def test_new_mapping_and_mismatches(self):
        self.assertEqual(ANALYZE.validate_timer(timer()),(100000000,10000))
        for key,value in [('interval',10000),('period_ticks',9999),('clock_hz',99999999),('prescaler',0),
                          ('mapping_version',2),('candidate_id',0),('periodic_base',0xff110008),('periodic_clock',1),('timestamp_clock',32)]:
            with self.subTest(key=key),self.assertRaises(ValueError):ANALYZE.validate_timer({**timer(),key:value})
        for key in ['mapping_version','candidate_id','periodic_base','timestamp_base']:
            t=timer();del t[key]
            with self.subTest(missing=key),self.assertRaises((ValueError,KeyError)):ANALYZE.validate_timer(t)

    def test_legacy_still_uses_raw_period_and_retains_observed_drift(self):
        old=json.loads((ROOT/'.runtime/ax02a/board_manual/phase_p1000_01/run.json').read_text())
        self.assertEqual(ANALYZE.validate_timer(old['timer']),(100000000,10000))
        p=Path(tempfile.mkdtemp(prefix='runtime_r1_legacy_',dir=ROOT/'.runtime/ax02a'))
        base=ROOT/'.runtime/ax02a/replay/p1000';src=ROOT/'.runtime/ax02a/board_manual/phase_p1000_01'
        result=ANALYZE.analyze(base/'metadata.json',base/'reference.bin',src/'output.bin',src/'timing.bin',src/'run.json',0,1,p/'analysis')
        self.assertFalse(result['passed']);self.assertEqual(result['deadline_sequence'],'PASS')
        self.assertEqual(result['period_consistency'],'TREND_DETECTED')

    def test_real_platform_mapping_c_contract(self):
        header=ROOT/'firmware/r5/ax02a/timer_mapping.h'
        self.assertTrue(header.exists(),'missing scoped platform mapping')
        gcc=Path('C:/ProgramData/MATLAB/SupportPackages/R2026b/3P.instrset/mingw_w64.instrset/bin/gcc.exe')
        p=Path(tempfile.mkdtemp(prefix='runtime_r1_map_',dir=ROOT/'.runtime/ax02a'))
        source=p/'test.c';source.write_text('''#include "timer_mapping.h"
#include <assert.h>
int main(void) {uint32_t raw=0;
assert(ax02a_timer_map(0xff110000,0xff110004,100000000,16,10000,&raw)==0 && raw==9999);
assert(ax02a_timer_map(0xff110008,0xff110004,100000000,16,10000,&raw)!=0);
assert(ax02a_timer_map(0xff110000,0xff110008,100000000,16,10000,&raw)!=0);
assert(ax02a_timer_map(0xff110000,0xff110004,99999999,16,10000,&raw)!=0);
assert(ax02a_timer_map(0xff110000,0xff110004,100000000,0,10000,&raw)!=0);
assert(ax02a_timer_map(0xff110000,0xff110004,100000000,16,9999,&raw)!=0);
return 0;}
''')
        env={**os.environ,'PATH':str(gcc.parent)+os.pathsep+os.environ['PATH']}
        subprocess.run([str(gcc),'-std=c11','-O2','-Wall','-Wextra','-Werror','-I'+str(header.parent),str(source),'-o',str(p/'test.exe')],check=True,env=env)
        subprocess.run([str(p/'test.exe')],check=True)


if __name__=='__main__':unittest.main()
