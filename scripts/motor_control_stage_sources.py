"""Stage accepted model dependencies for an isolated run, never replace user models."""
import json,subprocess,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[1]).resolve()
out.mkdir(parents=True,exist_ok=False)
base='ffaa5683322e2a485d96a23cc1b8a9e88fbcdb13'
paths=['simulation/AXU5EV_PL_Algorithm_Library.slx',
       'simulation/encoder/AXU5EV_Encoder_Components.slx',
       'simulation/real_io/ax03b1_current_preprocess.m',
       'simulation/encoder/encoder_angle_step.m',
       'simulation/encoder/encoder_position_speed.m']
paths += [p.relative_to(root).as_posix() for p in (root/'baselines/pr53_p3/source').glob('*.m')]
paths += ['baselines/pr53_p3/source/PMLSM_FOC_FixedPoint.slx']
for path in paths:
    data=subprocess.check_output(['git','show',f'{base}:{path}'],cwd=root)
    (out/Path(path).name).write_bytes(data)
(out/'source_relation.json').write_text(json.dumps({'base':base,'files':paths},indent=2)+'\n')
print(out)
