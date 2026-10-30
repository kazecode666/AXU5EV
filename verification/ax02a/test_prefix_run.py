"""C1 contracts: frame-zero prefix and completed-run gate before comparison."""
import importlib.util,json,struct,tempfile,unittest,tkinter
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def module(name):
 p=ROOT/'scripts'/('ax02a_'+name+'.py')
 if not p.exists():return None
 s=importlib.util.spec_from_file_location(name,p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
class PrefixTests(unittest.TestCase):
 def test_prefix_and_rejections(self):
  m=module('prepare_prefix');self.assertIsNotNone(m,'prefix tool missing')
  with tempfile.TemporaryDirectory() as d:
   p=Path(d);s=p/'source';s.mkdir()
   meta=dict(scenario='current_motion',frames=3,Ts=.0001,input_fields=20,output_fields=41,format='little-endian float64, frame-major',parameters={'Host_Traj_Vmax':20})
   (s/'metadata.json').write_text(json.dumps(meta));(s/'input.bin').write_bytes(bytes(range(160))*3);(s/'reference.bin').write_bytes(b'R'*984)
   m.prepare(s,p/'prefix',2)
   self.assertEqual((p/'prefix/input.bin').read_bytes(),(s/'input.bin').read_bytes()[:320])
   self.assertEqual((p/'prefix/reference.bin').stat().st_size,656)
   out=json.loads((p/'prefix/metadata.json').read_text());self.assertEqual(out['source_range'],[0,2]);self.assertEqual(out['parameters'],meta['parameters'])
   for dest,n in [(p/'prefix',2),(p/'big',4)]:
    with self.assertRaises(ValueError):m.prepare(s,dest,n)
   (s/'input.bin').write_bytes(b'bad')
   with self.assertRaises(ValueError):m.prepare(s,p/'bad',2)
 def test_old_reference_rejected(self):
  m=module('prepare_prefix');self.assertIsNotNone(m)
  with tempfile.TemporaryDirectory() as d:
   p=Path(d);(p/'metadata.json').write_text(json.dumps(dict(scenario='pr14_original',frames=1,Ts=.0001,input_fields=20,output_fields=41)))
   with self.assertRaises(ValueError):m.prepare(p,p/'out',1)
class RunTests(unittest.TestCase):
 def test_passive_tcl_and_explicit_readback(self):
  t=tkinter.Tcl()
  t.eval('proc targets {args} {return [list [dict create is_current 1 name "Cortex-R5 #0" suspended 1]]}')
  t.eval('proc print {args} {set n [lindex $args end]; set v 0; switch -glob -- $n {*.state {set v 3} *.mode {set v 1} *.frames - *.completed_frames {set v 1000} *.experiment {set v 8} *.clock_hz {set v 100000000} *.interval - *.period_ticks {set v 10000} *.prescaler {set v 16}}; return [dict create $n $v]}')
  t.eval('proc mrd {args} {set f [open [lindex $args 4] wb]; puts -nonewline $f [string repeat x [lindex $args end]]; close $f}')
  t.call('source',str(ROOT/'firmware/r5/ax02a/readback_short.tcl'))
  with tempfile.TemporaryDirectory() as d:
   out=Path(d)/'new'
   t.call('ax02a_short::readback',out.as_posix(),7,'warm I-cache, D-cache off','false')
   self.assertEqual(json.loads((out/'run.json').read_text())['experiment'],8)
   self.assertEqual((out/'output.bin').stat().st_size,328000)
   self.assertEqual((out/'timing.bin').stat().st_size,64000)
   interrupted=Path(d)/'interrupted'
   t.call('ax02a_short::readback',interrupted.as_posix(),7,'warm I-cache, D-cache off','true')
   self.assertTrue(json.loads((interrupted/'run.json').read_text())['interrupted'])
   meta=Path(d)/'meta.json';meta.write_text(json.dumps(dict(scenario='current_motion_prefix',source_scenario='current_motion',source_range=[0,1000],frames=1000,Ts=.0001,input_fields=20,output_fields=41)))
   r=module('analyze_run').analyze(meta,out/'output.bin',interrupted/'output.bin',interrupted/'timing.bin',interrupted/'run.json',7,1,Path(d)/'rejected','SIMULATED')
   self.assertFalse(r['passed']);self.assertIn('interrupted',r['error'])
 def test_run_gate_and_timing_faults(self):
  m=module('analyze_run');self.assertIsNotNone(m,'run analyzer missing')
  with tempfile.TemporaryDirectory() as d:
   p=Path(d);meta=dict(scenario='current_motion_prefix',source_scenario='current_motion',source_range=[0,3],frames=3,Ts=.0001,input_fields=20,output_fields=41)
   (p/'metadata.json').write_text(json.dumps(meta));raw=struct.pack('<123d',*([0.]*123))
   (p/'reference.bin').write_bytes(raw);(p/'output.bin').write_bytes(raw)
   ticks=[[k,k,k*10000,k*10000,k*10000,k*10000+10,k*10000+20,k*10000+30] for k in range(3)]
   def save_ticks():(p/'timing.bin').write_bytes(b''.join(struct.pack('<8Q',*r) for r in ticks))
   save_ticks()
   state=dict(scenario='current_motion_prefix',state=3,mode=1,frames=3,experiment=8,interrupted=False,result=dict(status=0,completed_frames=3,failed_frame=0),timer=dict(clock_hz=100000000,period_ticks=10000,interval=10000,prescaler=16,timestamp_read_min_ticks=1,timestamp_read_max_ticks=3,start_window_ticks=2),conditions='warm instruction cache, D-cache off; synthetic HOST test')
   def run(label):
    (p/'run.json').write_text(json.dumps(state));return m.analyze(p/'metadata.json',p/'reference.bin',p/'output.bin',p/'timing.bin',p/'run.json',7,1,p/label,'SIMULATED')
   self.assertTrue(run('ok')['passed'])
   for field,value in [('experiment',7),('mode',0),('frames',2),('state',1),('scenario','pr14_original'),('interrupted',True)]:
    old=state[field];state[field]=value;self.assertFalse(run('bad_'+field)['passed']);state[field]=old
   state['result']['status']=2;self.assertFalse(run('failed_status')['passed']);state['result']['status']=0
   state['result']['completed_frames']=2;self.assertFalse(run('partial')['passed']);state['result']['completed_frames']=3
   for change in ['seq','deadline','backward','period']:
    old=[r[:] for r in ticks]
    if change=='seq':ticks[1][1]=0
    if change=='deadline':ticks[1][-1]=20000
    if change=='backward':ticks[1][6]=ticks[1][5]-1
    if change=='period':state['timer']['period_ticks']=100000
    save_ticks();self.assertFalse(run(change)['passed']);ticks=old;state['timer']['period_ticks']=10000
   (p/'output.bin').write_bytes(raw[:-8]);self.assertFalse(run('short')['passed'])
if __name__=='__main__':unittest.main()
