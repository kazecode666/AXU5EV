"""Adopt only proven local SLX graphics; leave frozen source and logging intact."""
from pathlib import Path
import hashlib,json,csv,zipfile,xml.etree.ElementTree as E,re
ROOT=Path(__file__).resolve().parents[1]
def sha(b):return hashlib.sha256(b).hexdigest()
def canonical(data):
 x=E.fromstring(data)
 for parent in x.iter():
  for child in list(parent):
   if child.tag=='P' and child.get('Name') in {'Position','Points','Labels','ModelReferenceVersion'}:parent.remove(child)
 return E.tostring(x)
def main():
 local=ROOT/'.runtime/ax00/local_disk_snapshot/simulink模型'
 proofs=[]
 for name in ['PMLSM_FOC_FixedPoint.slx','PMLSM_PI_FOC_Float_Baseline.slx']:
  accepted=ROOT/'baselines/pr53_p3/source'/name;latest=local/name;active=ROOT/'simulink模型'/name
  a=zipfile.ZipFile(accepted);b=zipfile.ZipFile(latest)
  assert set(a.namelist())==set(b.namelist())
  systems=[n for n in a.namelist() if n.startswith('simulink/systems/') and n.endswith('.xml') and a.read(n)!=b.read(n)]
  for n in systems:assert canonical(a.read(n))==canonical(b.read(n)),f'Non-graphical change: {name}/{n}'
  # The destination is created by AX-00, never an existing user file.
  assert active.read_bytes()==accepted.read_bytes(),'Refuse to replace a changed active file'
  with zipfile.ZipFile(active,'w') as out:
   for info in a.infolist():out.writestr(info,b.read(info.filename) if info.filename in systems else a.read(info.filename))
  proofs.append(dict(name=name,accepted_sha256=sha(accepted.read_bytes()),local_sha256=sha(latest.read_bytes()),active_sha256=sha(active.read_bytes()),adopted_systems=systems,allowed_graphics=['Position','Points','Labels'],version_only=['ModelReferenceVersion'],semantic_xml_exact=True,logging='Accepted graphicalInterface.json retained; LOCAL_DIRTY decimation/removed logs not adopted',metadata='Accepted root configuration and Stateflow retained'))
 inv=ROOT/'coordination/reports/migration_inventory.csv'
 with inv.open(encoding='utf-8-sig',newline='') as f:rows=list(csv.DictReader(f));fields=list(rows[0])
 for proof in proofs:
  for row in rows:
   if row['dest_path']=='simulink模型/'+proof['name']:
    row.update(dest_sha256=proof['active_sha256'],changed_reason='Adopt local layout-only system XML; preserve accepted logging and all algorithm/config bytes',verification='CANONICAL_SYSTEM_XML_EQUAL; runtime comparison required',classification='ACCEPTED_ALGORITHM_LOCAL_LAYOUT')
 with inv.open('w',encoding='utf-8-sig',newline='') as f:w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(rows)
 (ROOT/'coordination/reports/layout_adoption.json').write_text(json.dumps(proofs,ensure_ascii=False,indent=2),encoding='utf8')
 print('AX00_LAYOUT_ADOPTED',len(proofs))
if __name__=='__main__':main()
