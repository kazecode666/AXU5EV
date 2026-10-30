"""Release phase trends must not be hidden by nominal deadline checks."""
import importlib.util,random,struct,unittest,tkinter,tempfile,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
s=importlib.util.spec_from_file_location('compare',ROOT/'scripts/ax02a_compare_replay.py');m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
class PhaseTests(unittest.TestCase):
 def phase(self,drift=0,jitter=False,n=1000):
  self.assertTrue(callable(getattr(m,'release_phase',None)),'release phase diagnostic missing')
  rng=random.Random(191);records=[]
  for k in range(n):
   expected=k*10000;released=expected+(round(drift*k)+300+(rng.randrange(-30,31) if jitter else 0) if k else 0)
   records.append((k,k,expected,released,released+10,released+20,released+30,released+40))
  return m.release_phase(records)
 def test_plus_one_tick_synthetic_must_flag(self):
  p=self.phase(1);self.assertEqual(p['status'],'TREND_DETECTED');self.assertAlmostEqual(p['slope_ticks_per_frame'],1)
 def test_fixed_latency_and_random_jitter_not_drift(self):
  self.assertEqual(self.phase()['status'],'NO_TREND_DETECTED')
  self.assertEqual(self.phase(jitter=True)['status'],'NO_TREND_DETECTED')
 def test_negative_drift_also_detected(self):
  self.assertEqual(self.phase(-.1)['status'],'TREND_DETECTED')
 def test_short_span_inconclusive(self):
  self.assertEqual(self.phase(n=10)['status'],'INSUFFICIENT_SPAN')
  self.assertEqual(self.phase(n=32)['status'],'INSUFFICIENT_SPAN')
  self.assertEqual(self.phase(1,n=33)['status'],'TREND_DETECTED')
 def test_passive_config_recipe_and_no_status_reads(self):
  t=tkinter.Tcl();t.eval('set calls {}; proc targets {args} {return [list [dict create is_current 1 name "Cortex-R5 #0" suspended 1]]}')
  t.eval('proc mrd {args} {set a [lindex $args end]; lappend ::calls $a; if {$a in {0xff11000c 0xff110010}} {return 0x23}; return 0}')
  t.call('source',str(ROOT/'firmware/r5/ax02a/read_ttc_config.tcl'))
  self.assertEqual(t.eval('llength $calls'),'0')
  with tempfile.TemporaryDirectory() as d:
   f=Path(d)/'config.json';t.call('ax02a_ttc::read_config',f.as_posix(),'pre_begin')
   self.assertEqual(json.loads(f.read_text())['stage'],'pre_begin')
   calls=t.splitlist(t.eval('set calls'))
   self.assertFalse(any(x in calls for x in ['0xff110054','0xff110058','0xff11005c']))
 def test_real_capture_detected_and_k0_excluded(self):
  self.assertTrue(callable(getattr(m,'release_phase',None)))
  records=list(struct.iter_unpack('<8Q',(ROOT/'.runtime/ax02a/board_manual/p1000_exp2_capture/timing.bin').read_bytes()))
  p=m.release_phase(records);self.assertEqual(p['status'],'TREND_DETECTED');self.assertEqual(p['samples'],999)
  self.assertAlmostEqual(p['slope_ticks_per_frame'],.9992710947420367,places=10)
  records[0]=(0,0,0,999999,999999,999999,999999,999999)
  self.assertEqual(m.release_phase(records)['slope_ticks_per_frame'],p['slope_ticks_per_frame'])
if __name__=='__main__':unittest.main()
