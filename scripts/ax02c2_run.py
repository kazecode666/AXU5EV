"""One explicit Runtime + real PL replay. Reuse ETH02 file transport unchanged."""
import argparse
import ipaddress
import json
import math
from pathlib import Path
import shutil
import socket
import struct
import subprocess
import sys
import time
from eth02_run import Connection,SCENE,START

ROOT=Path(__file__).resolve().parents[1]
BUILD=0x43324301
FRAMES=64536
SOURCE=ROOT/'.runtime/ax02c2/prepared_04/data/current_motion'


def analyze(out,source,run):
    numeric=subprocess.run([sys.executable,str(ROOT/'scripts/ax02a_compare_replay.py'),
        '--metadata',str(out/'metadata.json'),'--reference',str(source/'reference.bin'),
        '--actual',str(out/'output.bin'),'--origin','BOARD','--output',str(out/'analysis')])
    # The old comparator's timing=NOT_RUN refers only to its TTC IRQ criterion.
    # Here the records contain PMU timestamps and PL frame/command identities.
    timing=out/'timing.bin';actual=out/'pl_result.bin';expected=source/'foc_reference.bin'
    if actual.stat().st_size!=FRAMES*32 or timing.stat().st_size!=FRAMES*64:
        raise ValueError('C2 result objects do not contain the full record window')
    hz=run['timer']['clock_hz']
    if not isinstance(hz,int) or hz<=0 or run['measurement']['timing_schema']!='AX02C2_PMU16_V1':
        raise ValueError('C2 PMU timestamp identity missing')
    ref=list(struct.iter_unpack('<3I',expected.read_bytes()))
    rows=list(struct.iter_unpack('<8I',actual.read_bytes()))
    ticks=list(struct.iter_unpack('<16I',timing.read_bytes()))
    duty_failures=relationship_failures=capture_failures=0;first=None
    metrics={k:[] for k in ['runtime','adapter','write_commit','prepare_commit','poll_wait','read_result','next_record_prepare_commit','result_interval']}
    delta=lambda a,b:((a-b)&0xffffffff)*1e6/hz
    for k,(row,t,golden) in enumerate(zip(rows,ticks,ref)):
        if row[:5]!=(k,k,k+1,k+1,k+1) or (t[0],t[1],t[2],t[3],t[12])!=(k,k+1,k+1,k+1,k+1):
            relationship_failures+=1
        if t[13]!=315 or t[14]!=0:capture_failures+=1
        for phase,(value,want) in enumerate(zip(row[5:],golden)):
            if value!=want:
                duty_failures+=1
                if first is None:first=dict(record_index=k,phase=phase,actual=f'{value:08x}',expected=f'{want:08x}')
        for name,a,b in [('runtime',6,5),('adapter',7,6),('write_commit',8,7),('prepare_commit',8,4),('poll_wait',10,9),('read_result',11,10)]:
            metrics[name].append(delta(t[a],t[b]))
        if k:
            metrics['next_record_prepare_commit'].append(delta(t[8],ticks[k-1][11]))
            metrics['result_interval'].append(delta(t[10],ticks[k-1][10]))
    stats={}
    for name,values in metrics.items():
        ordered=sorted(values);n=len(values)
        stats[name]=dict(samples=n,mean_us=sum(values)/n,min_us=ordered[0],p99_us=ordered[math.ceil(.99*n)-1],max_us=ordered[-1])
    p=run['pl'];end_ok=(p['complete_frames']==FRAMES and p['last_frame']==FRAMES and p['last_seq']==FRAMES and not p['hold_error'] and not p['stop_status'])
    passed=(numeric.returncode==0 and not duty_failures and not relationship_failures and not capture_failures and end_ok)
    summary=dict(status='PASS' if passed else 'FAIL',records=FRAMES,duty_comparisons=FRAMES*3,
        duty_bit_failures=duty_failures,relationship_failures=relationship_failures,capture_failures=capture_failures,
        complete_frame_stop=end_ok,first_duty_mismatch=first,timebase='PMU CPU/64',clock_hz=hz,
        ttc_irq_timing='NOT_RUN_NOT_APPLICABLE',statistics=stats,
        interpretation='Recorded-feedback pipeline replay; no same-frame50us or WCET signoff')
    (out/'pl_summary.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
    print(f"Runtime数值 {'PASS' if numeric.returncode==0 else 'FAIL'}；PL duty位串 {'PASS' if not duty_failures else 'FAIL'}；"
          f"帧/序号 {'PASS' if not relationship_failures and not capture_failures and end_ok else 'FAIL'}",flush=True)
    return passed


def run(args):
    ipaddress.IPv4Address(args.ip);source=args.source.resolve()
    metadata=json.loads((source/'metadata.json').read_text(encoding='utf-8-sig'))
    if (metadata['scenario']!='current_motion' or metadata['frames']!=FRAMES or metadata['Ts']!=.0001
            or (metadata['input_fields'],metadata['output_fields'])!=(20,41)):
        raise ValueError('C2 input metadata differs from the accepted current_motion record window')
    for name,width in [('input.bin',160),('reference.bin',328),('feedback.bin',40),('foc_reference.bin',12)]:
        if (source/name).stat().st_size!=FRAMES*width:raise ValueError('C2 source size mismatch: '+name)
    descriptor=ROOT/'.runtime/ax02a/full_scene_descriptors/current_motion/reference_descriptor.bin'
    if descriptor.read_bytes()!=struct.pack('<8I',0x31464552,1,2,FRAMES,41,0,FRAMES*328,0):
        raise ValueError('current_motion descriptor mismatch')
    conditions=args.conditions.encode('ascii')
    if not 1<=len(conditions)<=192 or any(b<32 or b>126 or b in (34,92) for b in conditions):
        raise ValueError('conditions must be printable ASCII, without quotes/backslashes')
    args.out.mkdir(parents=True,exist_ok=False);shutil.copyfile(source/'metadata.json',args.out/'metadata.json')
    transfer=dict(status='FAIL',application='AX02C2',ip=args.ip,port=args.port,scenario='current_motion',
        evidence='USER_BOARD_RUN',source=source.as_posix(),uploads={},downloads={},errors=[])
    try:
        with socket.create_connection((args.ip,args.port),timeout=120) as sock:
            c=Connection(sock,expected_build=BUILD);initial=c.status();transfer['initial_status']=initial
            c.call(SCENE,payload=struct.pack('!3I',2,FRAMES,0)+conditions)
            begin=time.perf_counter()
            for object_id,path in [(1,source/'input.bin'),(2,source/'reference.bin'),(3,descriptor),(9,source/'feedback.bin')]:
                transfer['uploads'][path.name]=c.upload(object_id,path)
            transfer['upload_seconds']=time.perf_counter()-begin
            ready=c.status()
            if ready['phase']!=2 or ready['uploaded']!=0x107:raise ValueError('C2 objects not READY')
            experiment,=struct.unpack('!I',c.call(START));transfer['experiment']=experiment
            if experiment!=initial['experiment']+1:raise ValueError('experiment number mismatch')
            print(f'已明确启动C2一次：experiment={experiment}；停网络，PL完整帧调度Runtime协同回放',flush=True)
            sock.shutdown(socket.SHUT_WR)
            if sock.recv(1):raise ValueError('unexpected data after START reply')
        time.sleep(FRAMES*metadata['Ts'])
        begin=time.perf_counter()
        # One planned reconnect only; never repeat upload/START on timeout.
        with socket.create_connection((args.ip,args.port),timeout=120) as sock:
            c=Connection(sock,expected_build=BUILD);final=c.status();transfer['final_status']=final
            if final['phase']!=5 or final['experiment']!=experiment or final['scenario']!=2 or final['frames']!=FRAMES:
                raise ValueError('not this C2 experiment RESULT_READY')
            transfer['planned_reconnect_seconds']=time.perf_counter()-begin;begin=time.perf_counter()
            for object_id,name in [(7,'run.json'),(8,'pre_begin.json'),(4,'output.bin'),(5,'timing.bin'),(6,'report_v2.bin'),(10,'pl_result.bin')]:
                transfer['downloads'][name]=c.download(object_id,args.out/name)
            transfer['download_seconds']=time.perf_counter()-begin
        saved=json.loads((args.out/'run.json').read_text())
        if saved['experiment']!=experiment or saved['build_id']!=BUILD or saved['application']!='AX02C2':
            raise ValueError('saved C2 identity mismatch')
        if saved['state']!=3 or saved['result']['status'] or saved['result']['completed_frames']!=FRAMES:
            raise RuntimeError('C2 replay incomplete/failed; available result prefix preserved in '+str(args.out))
        passed=analyze(args.out,source,saved);transfer['status']='PASS' if passed else 'FAIL'
        print(f"总上传 {transfer['upload_seconds']:.3f}s；总下载 {transfer['download_seconds']:.3f}s",flush=True)
        return 0 if passed else 1
    except Exception as exc:
        transfer['errors'].append(str(exc));raise
    finally:(args.out/'transfer.json').write_text(json.dumps(transfer,indent=2)+'\n',encoding='utf-8')


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--ip',required=True);p.add_argument('--port',type=int,default=5001)
    p.add_argument('--source',type=Path,default=SOURCE);p.add_argument('--scenario',choices=['current_motion'],default='current_motion')
    p.add_argument('--start',action='store_true',required=True);p.add_argument('--conditions',required=True);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args()
    try:return run(a)
    except (ValueError,OSError,RuntimeError) as exc:print('AX02C2 FAIL:',exc,file=sys.stderr);return 1


if __name__=='__main__':sys.exit(main())
