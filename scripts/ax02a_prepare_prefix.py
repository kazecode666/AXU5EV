"""Extract a frame-zero current-parameter prefix on the PC; never runs hardware."""
import argparse
import json
from pathlib import Path


def prepare(source, output, frames=1000):
    source,output=Path(source),Path(output)
    m=json.loads((source/'metadata.json').read_text(encoding='utf-8-sig'))
    if m['scenario']!='current_motion' or m['Ts']!=.0001 or (m['input_fields'],m['output_fields'])!=(20,41):
        raise ValueError('expected current_motion, current parameters, 100us, 20/41 fields')
    if not isinstance(frames,int) or not 0<frames<=m['frames']:
        raise ValueError('prefix frames exceed source or are not positive')
    if output.exists():raise ValueError('output directory already exists; preserve it')
    for name,width in [('input.bin',20),('reference.bin',41)]:
        if (source/name).stat().st_size!=m['frames']*width*8:
            raise ValueError('source length does not match metadata: '+name)
    source_frames=m['frames']
    m.update(scenario='current_motion_prefix',frames=frames,first_s=0,
             last_s=(frames-1)*m['Ts'],source_scenario='current_motion',
             source_frames=source_frames,source_range=[0,frames],source_directory=str(source.resolve()),
             prefix_note='New experiment initializes once at source frame 0; not a middle slice or full-scene validation')
    output.mkdir(parents=True)
    for name,width in [('input.bin',20),('reference.bin',41)]:
        with (source/name).open('rb') as f:
            (output/name).write_bytes(f.read(frames*width*8))
    (output/'metadata.json').write_text(json.dumps(m,indent=2)+'\n',encoding='utf-8',newline='\n')
    return m


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
    p.add_argument('--frames',type=int,default=1000);a=p.parse_args()
    print(json.dumps(prepare(a.source,a.output,a.frames),indent=2))
