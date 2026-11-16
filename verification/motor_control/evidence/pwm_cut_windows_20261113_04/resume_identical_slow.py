"""Infrastructure recovery only; unchanged v2 TB/native inputs; narrower aggregate budget."""
import runpy,sys
from pathlib import Path
p=Path(__file__).resolve().parent/'v2'/'run_corner.py'
d=runpy.run_path(str(p),run_name='bounded_recovery_import')
d['LIMITS'].update(xvlog=595,xelab=575,xsim=3300)
sys.argv=[str(p),'slow']
raise SystemExit(d['main']())
