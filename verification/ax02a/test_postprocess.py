"""C2/C3: actual postprocessing C vs the accepted Python oracle, no target run."""
import os,_ctypes,ctypes as C,importlib.util,json,math,subprocess,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
GCC=Path('C:/ProgramData/MATLAB/SupportPackages/R2026b/3P.instrset/mingw_w64.instrset/bin/gcc.exe')
class Request(C.Structure):
 _fields_=[(n,C.c_uint32) for n in ['scenario','expected_scenario','experiment','expected_experiment','mode','expected_mode','frames','reference_frames','completed','program_status','interrupted','clock_hz','period_ticks']]
class Field(C.Structure):
 _fields_=[('failures',C.c_uint32),('max_frame',C.c_uint32),('first_mismatch',C.c_uint32),('reserved',C.c_uint32),('max_abs',C.c_double),('rms',C.c_double)]
class Metric(C.Structure):
 _fields_=[('samples',C.c_uint32),('worst_frame',C.c_uint32),('mean',C.c_double),('minimum',C.c_double),('maximum',C.c_double)]
class Report(C.Structure):
 _fields_=[(n,C.c_uint32) for n in ['magic','version','bytes','valid','scenario','experiment','mode','requested','completed','program_status','compare_status','timing_status','contract_errors','numeric_errors','timing_errors','p99_status']]+[('fields',Field*41),('metrics',(Metric*5)*6)]
class PostTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.available=(ROOT/'firmware/r5/ax02a/postprocess.c').exists()
  if not cls.available:return
  cls.temp=tempfile.TemporaryDirectory();cls.addClassCleanup(cls.temp.cleanup)
  dll=Path(cls.temp.name)/'post.dll'
  subprocess.run([str(GCC),'-shared','-O2','-fno-fast-math','-ffp-contract=off','-Wall','-Wextra','-Werror','-I'+str(ROOT/'firmware/r5/ax02a'),str(ROOT/'firmware/r5/ax02a/postprocess.c'),'-o',str(dll),'-lm'],check=True,env={**os.environ,"PATH":str(GCC.parent)+os.pathsep+os.environ.get("PATH","")})
  cls.dll_dir=os.add_dll_directory(str(GCC.parent));cls.addClassCleanup(cls.dll_dir.close)
  cls.lib=C.CDLL(str(dll));cls.addClassCleanup(lambda:_ctypes.FreeLibrary(cls.lib._handle));cls.fn=cls.lib.ax02a_postprocess
  cls.fn.argtypes=[C.POINTER(C.c_double),C.c_uint32,C.POINTER(C.c_double),C.c_uint32,C.POINTER(C.c_uint64),C.c_uint32,C.POINTER(Request),C.POINTER(Report)]
  s=importlib.util.spec_from_file_location('oracle',ROOT/'scripts/ax02a_compare_replay.py');cls.py=importlib.util.module_from_spec(s);s.loader.exec_module(cls.py)
 def call(self,actual,ref,n,mode=0,ticks=None,alter=None):
  self.assertTrue(self.available,'postprocessing C is missing')
  a=(C.c_double*len(actual))(*actual);r=(C.c_double*len(ref))(*ref)
  req=Request(1,1,8,8,mode,mode,n,n,n,0,0,100000000,10000)
  if alter:alter(req)
  tick=(C.c_uint64*len(ticks))(*ticks) if ticks is not None else None
  out=Report();self.fn(a,len(actual),r,len(ref),tick,len(ticks)//8 if ticks else 0,C.byref(req),C.byref(out))
  self.assertEqual(out.bytes,C.sizeof(Report));self.assertEqual(out.valid,0x434f4d50)
  return out
 def test_real_motion03_crosscheck(self):
  self.assertTrue(self.available,'postprocessing C is missing')
  ref=self.py.read_doubles(ROOT/'.runtime/ax02a/replay/current_motion/reference.bin',64536,41)
  actual=self.py.read_doubles(ROOT/'.runtime/ax02a/board_manual/motion_03/output.bin',64536,41)
  r=self.call(actual,ref,64536);py=self.py.compare(ref,actual,64536,.0001)
  self.assertEqual(r.compare_status,0);self.assertEqual(r.timing_status,2)
  for j,s in enumerate(py):
   self.assertEqual(r.fields[j].failures,s['failures']);self.assertEqual(r.fields[j].max_frame,s['max_frame']);self.assertEqual(r.fields[j].max_abs,s['max_abs'])
   self.assertEqual(r.fields[j].first_mismatch,0xffffffff if s['first_mismatch_frame']=='' else s['first_mismatch_frame'])
   self.assertAlmostEqual(r.fields[j].rms,s['rms'],delta=1e-15+1e-12*abs(s['rms']))
 def test_numeric_faults(self):
  self.assertTrue(self.available)
  for j,v,passed in [(30,1e-12,False),(0,1e-10,True),(0,1e-9,True),(0,1.000001e-9,False),(0,float('nan'),False),(0,float('inf'),False),(0,-0.,True)]:
   a=[0.]*123;a[41+j]=v;r=self.call(a,[0.]*123,3)
   p=self.py.compare([0.]*123,a,3,.0001)
   self.assertEqual(r.compare_status==0,passed)
   for i,s in enumerate(p):
    self.assertEqual(r.fields[i].failures,s['failures']);self.assertEqual(r.fields[i].max_abs,s['max_abs'])
 def test_contract_failures(self):
  for change in [lambda r:setattr(r,'completed',2),lambda r:setattr(r,'program_status',2),lambda r:setattr(r,'expected_scenario',2),lambda r:setattr(r,'expected_mode',1),lambda r:setattr(r,'expected_experiment',9),lambda r:setattr(r,'reference_frames',2),lambda r:setattr(r,'interrupted',1)]:
   r=self.call([0.]*123,[0.]*123,3,alter=change);self.assertNotEqual(r.compare_status,0)
  self.assertNotEqual(self.call([0.]*82,[0.]*123,3).compare_status,0)
 def test_timing_faults_and_boundaries(self):
  for fault in ['none','repeat','skip','backward','deadline','1ms']:
   ticks=[[k,k,k*10000,k*10000,k*10000,k*10000+10,k*10000+20,k*10000+30] for k in range(3)]
   if fault=='repeat':ticks[1][1]=0
   if fault=='skip':ticks[1][1]=2
   if fault=='backward':ticks[1][6]=ticks[1][5]-1
   if fault=='deadline':ticks[1][-1]=20000
   r=self.call([0.]*123,[0.]*123,3,1,[v for row in ticks for v in row],lambda r:setattr(r,'period_ticks',100000) if fault=='1ms' else None)
   self.assertEqual(r.timing_status==0,fault=='none')
   if fault=='none':
    p=Path(self.temp.name)/'ticks.bin';p.write_bytes(bytes((C.c_uint64*24)(*[v for row in ticks for v in row])))
    rows,err=self.py.timing_stats(p,3,100000000,10000,[0.]*123);self.assertFalse(err)
    cats=['all','ordinary','speed_due','position_due','command_event','alignment_transition'];metrics=['runtime_us','task_us','response_us','jitter_us','slack_us']
    for row in rows:
     m=r.metrics[cats.index(row['category'])][metrics.index(row['metric'])]
     self.assertEqual(m.samples,row['samples']);self.assertAlmostEqual(m.mean,row['mean']);self.assertEqual(m.maximum,row['maximum']);self.assertEqual(m.minimum,row['minimum'])
 def test_full_short_categories_and_wire_decoder(self):
  self.assertTrue(self.available)
  n=1000;out=[0.]*(n*41)
  ticks=[[k,k,k*10000,k*10000,k*10000+2,k*10000+10,k*10000+20,k*10000+30] for k in range(n)]
  r=self.call(out,out,n,1,[v for t in ticks for v in t])
  self.assertEqual([r.metrics[g][0].samples for g in range(6)],[1000,900,90,10,0,1])
  p=Path(self.temp.name)/'short_ticks.bin';p.write_bytes(bytes((C.c_uint64*(n*8))(*[v for t in ticks for v in t])))
  rows,err=self.py.timing_stats(p,n,100000000,10000,out);self.assertFalse(err)
  for b in rows:
   m=r.metrics[['all','ordinary','speed_due','position_due','command_event','alignment_transition'].index(b['category'])][['runtime_us','task_us','response_us','jitter_us','slack_us'].index(b['metric'])]
   self.assertEqual(m.worst_frame,b['worst_frame']);self.assertAlmostEqual(m.mean,b['mean'],delta=1e-12+1e-9*abs(b['mean']))
  spec=importlib.util.spec_from_file_location('decode',ROOT/'scripts/ax02a_post_report.py');d=importlib.util.module_from_spec(spec);spec.loader.exec_module(d)
  wire=d.decode(bytes(r));self.assertEqual(wire['requested'],1000);self.assertEqual(wire['p99'],'NOT_COMPUTED')
  meta=dict(scenario='current_motion_prefix',source_scenario='current_motion',source_range=[0,n],frames=n,Ts=.0001,input_fields=20,output_fields=41)
  run=dict(scenario='current_motion_prefix',experiment=8,mode=1,frames=n,state=3,interrupted=False,result=dict(status=0,completed_frames=n),timer=dict(clock_hz=100000000,period_ticks=10000,interval=10000,prescaler=16,timestamp_read_min_ticks=1,timestamp_read_max_ticks=3,start_window_ticks=2))
  self.assertTrue(d.crosscheck(wire,out,out,meta,run,7,p)['passed'])
  run['experiment']=7
  with self.assertRaises(ValueError):d.crosscheck(wire,out,out,meta,run,7,p)
  with self.assertRaises(ValueError):d.scenario(dict(meta,scenario='pr14_original'))
  for raw in [bytes(r)[:-1],bytes(len(bytes(r)))]:
   with self.assertRaises(ValueError):d.decode(raw)
 def test_reference_nonfinite_and_nonzero_tolerance(self):
  self.assertTrue(self.available)
  for v in [float('nan'),float('inf')]:
   ref=[0.]*123;ref[0]=v;self.assertNotEqual(self.call([0.]*123,ref,3).compare_status,0)
  for delta in [1e-8,1e-6]:
   ref=[100.]*123;a=ref[:];a[0]+=delta;r=self.call(a,ref,3)
   self.assertEqual(r.numeric_errors,sum(x['failures'] for x in self.py.compare(ref,a,3,.0001)))
if __name__=='__main__':unittest.main()
