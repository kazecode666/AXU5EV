"""Verify migrated working/staged bytes, path isolation, and source preservation."""
from pathlib import Path
import csv,hashlib,json,subprocess,zipfile,re,sys
ROOT=Path(__file__).resolve().parents[1]
def sha(b):return hashlib.sha256(b).hexdigest()
def git(*args):return subprocess.check_output(['git','-C',str(ROOT),*args])
def main():
 with (ROOT/'coordination/reports/migration_inventory.csv').open(encoding='utf-8-sig',newline='') as f:rows=list(csv.DictReader(f))
 staged=set(git('diff','--cached','--name-only','-z').decode().split('\0'))
 tracked=set(git('ls-files','-z').decode().split('\0'))
 checked=0
 for row in rows:
  p=ROOT/row['dest_path'];assert p.is_file(),p
  assert sha(p.read_bytes())==row['dest_sha256'],str(p)
  if row['dest_path'] in tracked:
   assert sha(git('show',':'+row['dest_path']))==row['dest_sha256'],f'Staged bytes changed: {p}'
   checked+=1
 m=json.loads((ROOT/'generated/legacy_m3_p3/manifest.json').read_bytes())
 for kind in ['design_files','testbench_files','data_files']:
  for entry in m[kind]:assert sha((ROOT/'generated/legacy_m3_p3'/entry['path']).read_bytes())==entry['sha256']
 ident=json.loads((ROOT/'baselines/pr53_p3/source/identity.json').read_bytes())
 for e in ident['files']:assert sha((ROOT/'baselines/pr53_p3/source'/e['path']).read_bytes())==e['sha256']
 findings=[];absolute=[]
 for p in (ROOT/'simulink模型').iterdir():
  texts=[(p.name,p.read_text(encoding='utf8'))] if p.suffix=='.m' else []
  if p.suffix=='.slx':
   with zipfile.ZipFile(p) as z:texts=[(n,z.read(n).decode('utf8',errors='replace')) for n in z.namelist() if n.endswith(('.xml','.json','.m'))]
  for name,text in texts:
   assert not re.search(r'[A-Za-z]:[/\\]+Project[/\\]+FPGA_XC7A200T',text,re.I),f'Legacy path: {p}/{name}'
   for x in re.findall(r'<P Name="(?:\w*Fcn|ModelName|DataDictionary|LibraryName)">.*?</P>',text):findings.append(dict(file=p.name,part=name,entry=x))
   for x in re.findall(r'"(?:\w*Fcn|ModelName|DataDictionary|SourceBlock)"\s*:\s*"[^"\r\n]*"',text):findings.append(dict(file=p.name,part=name,entry=x))
   # MathWorks installation provenance in frozen model metadata is not an executable source dependency.
   for match in re.findall(r'[A-Za-z]:[/\\][^\r\n<"\u0000]{1,200}',text):absolute.append(dict(file=p.name,part=name,entry=match))
 protected=[];source_status='NOT_REQUESTED'
 if '--check-source' in sys.argv:
  source=Path(json.loads((ROOT/'coordination/reports/ax00_preflight.json').read_text(encoding='utf8'))['source_root']);protected=json.loads((ROOT/'.runtime/ax00/protected_files.json').read_text(encoding='utf8'))
  check_source(source,protected)
  source_status=True
 result=dict(status='PASS',inventory_files=len(rows),staged_hashes_checked=checked,frozen_inputs=len(ident['files']),manifest_payloads=sum(len(m[k]) for k in ['design_files','testbench_files','data_files']),protected_dirty_disk_files=len(protected),source_status_exact=source_status,active_legacy_absolute_paths=0,callbacks_and_references=findings,other_absolute_metadata=absolute,source_preservation='Old user files and snapshots unchanged when --check-source is selected; unsaved desktop state not captured',staged_paths=len(staged)-('' in staged))
 (ROOT/'coordination/reports/asset_verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
 print('AX00_ASSET_VERIFY_PASS',len(rows),'staged_hashes',checked)
def check_source(source,protected):
 for e in protected:assert sha((source/e['path']).read_bytes())==e['sha256'],f'Source modified: {e["path"]}'
 for folder in ['local_disk_snapshot','m4_not_accepted']:
  for p in (ROOT/'.runtime/ax00'/folder).rglob('*'):
   if p.is_file():assert p.read_bytes()==(source/p.relative_to(ROOT/'.runtime/ax00'/folder)).read_bytes(),f'Protected snapshot changed: {p}'
 before=(ROOT/'.runtime/ax00/source_status_before.bin').read_bytes()
 after=subprocess.check_output(['git','-C',str(source),'status','--porcelain=v1','-z'])
 assert before==after,'Old source status changed'
if __name__=='__main__':main()
