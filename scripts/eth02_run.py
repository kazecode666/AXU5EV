"""Explicit ETH02 experiment: upload real files, start once, reconnect/export/analyze.

Import and --help do not connect. Board calls are for the user after Review.
"""
import argparse
import csv
import ipaddress
import json
from pathlib import Path
import secrets
import shutil
import socket
import struct
import subprocess
import sys
import time
import zlib
from eth01_client import request, MAX_PAYLOAD
from ax02a_analyze_run import validate_timer

ROOT=Path(__file__).resolve().parents[1]
BUILD=0x45303201
SCENES={'current_motion':(2,64536),'current_alignment_reset':(3,43100)}
SCENE,BEGIN,WRITE,SEAL,START,QUERY,INFO,READ=range(0x10,0x18)


class Connection:
    def __init__(self,sock):
        self.sock=sock;self.transfer=secrets.randbelow(0xffffffff)+1;self.seq=0

    def call(self,kind,total=0,offset=0,payload=b''):
        self.seq+=1
        return request(self.sock,kind,self.transfer,self.seq,total,offset,payload)['payload']

    def status(self):
        fields=struct.unpack('!12I',self.call(QUERY))
        result=dict(zip(('build_id','phase','experiment','scenario','frames','uploaded',
            'status','completed_frames','failed_frame','negotiated_mbps','cache','mapping_version'),fields))
        if result['build_id']!=BUILD:raise ValueError('expected ETH02 build 45303201; select the new workspace/launch')
        return result

    def upload(self,object_id,path):
        size=path.stat().st_size;start=time.perf_counter();crc=0
        self.call(BEGIN,total=size,payload=struct.pack('!I',object_id))
        with path.open('rb') as source:
            for offset in range(0,size,MAX_PAYLOAD):
                data=source.read(min(MAX_PAYLOAD,size-offset));crc=zlib.crc32(data,crc)
                self.call(WRITE,total=size,offset=offset,payload=data)
                if (offset+len(data))//1048576!=offset//1048576:
                    print(f'上传 {path.name}: {offset+len(data)}/{size}',flush=True)
        ack=self.call(SEAL,total=size,payload=struct.pack('!I',crc))
        if ack!=struct.pack('!I',crc):raise ValueError('upload CRC mismatch: '+path.name)
        elapsed=time.perf_counter()-start
        print(f'上传完成 {path.name}: {size} bytes / {elapsed:.3f} s',flush=True)
        return dict(bytes=size,seconds=elapsed)

    def download(self,object_id,path):
        start=time.perf_counter()
        size,expected_crc=struct.unpack('!2I',self.call(INFO,payload=struct.pack('!I',object_id)))
        partial=path.with_name(path.name+'.partial');crc=0;received=0
        with partial.open('xb') as dest:
            while received<size:
                data=self.call(READ,total=size,offset=received,payload=struct.pack('!I',object_id))
                if len(data)!=min(MAX_PAYLOAD,size-received):raise ValueError('download length mismatch: '+path.name)
                dest.write(data);crc=zlib.crc32(data,crc);received+=len(data)
                if received//1048576!=(received-len(data))//1048576:
                    print(f'下载 {path.name}: {received}/{size}',flush=True)
        if received!=size or crc!=expected_crc:raise ValueError('download CRC mismatch: '+path.name)
        partial.rename(path);elapsed=time.perf_counter()-start
        print(f'下载完成 {path.name}: {size} bytes / {elapsed:.3f} s',flush=True)
        return dict(bytes=size,seconds=elapsed)


def analyze(out,source,run):
    hz,period=validate_timer(run['timer'])
    common=['--metadata',str(out/'metadata.json'),'--reference',str(source/'reference.bin')]
    numeric=subprocess.run([sys.executable,str(ROOT/'scripts/ax02a_compare_replay.py'),*common,
        '--actual',str(out/'output.bin'),'--timing',str(out/'timing.bin'),
        '--timer-hz',str(hz),'--period-ticks',str(period),'--origin','BOARD','--output',str(out/'analysis')])
    cross=subprocess.run([sys.executable,str(ROOT/'scripts/ax02a_post_report.py'),'crosscheck',*common,
        '--actual',str(out/'output.bin'),'--ticks',str(out/'timing.bin'),'--run',str(out/'run.json'),
        '--report',str(out/'report_v2.bin'),'--before-experiment',str(run['before_experiment']),
        '--output',str(out/'crosscheck')])
    summary=json.loads((out/'analysis/summary.json').read_text(encoding='utf-8'))
    if (out/'analysis/timing.csv').is_file():
        with (out/'analysis/timing.csv').open(encoding='utf-8',newline='') as f:
            rows={r['metric']:r for r in csv.DictReader(f) if r['category']=='all'}
        print(f"最大响应 {rows['response_us']['maximum']} us；最小slack {rows['slack_us']['minimum']} us")
    print(f"数值 {'PASS' if summary.get('numerical_failures')==0 else 'FAIL'}；"
          f"时序 {summary.get('timing','FAIL')}；crosscheck {'PASS' if cross.returncode==0 else 'FAIL'}",flush=True)
    return numeric.returncode==0 and cross.returncode==0


def run(args):
    ipaddress.IPv4Address(args.ip)
    scenario,frames=SCENES[args.scenario]
    source=ROOT/'.runtime/ax02a/replay'/args.scenario
    metadata=json.loads((source/'metadata.json').read_text(encoding='utf-8-sig'))
    if (metadata['scenario']!=args.scenario or metadata['frames']!=frames or metadata['Ts']!=.0001
        or (metadata['input_fields'],metadata['output_fields'])!=(20,41)):
        raise ValueError('source metadata does not match the accepted Runtime scenario')
    descriptor=ROOT/'.runtime/ax02a/full_scene_descriptors'/args.scenario/'reference_descriptor.bin'
    if (source/'input.bin').stat().st_size!=frames*160 or (source/'reference.bin').stat().st_size!=frames*328:
        raise ValueError('source file length does not match metadata')
    if descriptor.read_bytes()!=struct.pack('<8I',0x31464552,1,scenario,frames,41,0,frames*328,0):
        raise ValueError('source descriptor does not match this complete scenario')
    condition=args.conditions.encode('ascii')
    if not 1<=len(condition)<=192 or any(b<32 or b>126 or b in (34,92) for b in condition):
        raise ValueError('conditions must be 1..192 printable ASCII characters, without quotes or backslashes')
    args.out.mkdir(parents=True,exist_ok=False)
    shutil.copyfile(source/'metadata.json',args.out/'metadata.json')
    transfer=dict(status='FAIL',application='ETH02',ip=args.ip,port=args.port,scenario=args.scenario,
        evidence='USER_BOARD_RUN',source=str(source),uploads={},downloads={},errors=[])
    try:
        with socket.create_connection((args.ip,args.port),timeout=120) as sock:
            c=Connection(sock);initial=c.status();transfer['initial_status']=initial
            c.call(SCENE,payload=struct.pack('!3I',scenario,frames,1)+condition)
            upload_start=time.perf_counter()
            for object_id,path in [(1,source/'input.bin'),(2,source/'reference.bin'),(3,descriptor)]:
                transfer['uploads'][path.name]=c.upload(object_id,path)
            transfer['upload_seconds']=time.perf_counter()-upload_start
            ready=c.status()
            if ready['phase']!=2 or ready['uploaded']!=7:raise ValueError('inputs not READY')
            experiment,=struct.unpack('!I',c.call(START))
            transfer['experiment']=experiment
            if experiment!=initial['experiment']+1:raise ValueError('experiment number mismatch')
            print(f'已明确启动一次：experiment={experiment}；等待连接正常结束及Runtime回放',flush=True)
            sock.shutdown(socket.SHUT_WR)
            if sock.recv(1):raise ValueError('unexpected data after START reply')
        # One planned new connection, never retry the upload or START command.
        # GEM is stopped during replay; SYN may complete after network resumes.
        time.sleep(frames*metadata['Ts'])
        wait_start=time.perf_counter()
        with socket.create_connection((args.ip,args.port),timeout=120) as sock:
            c=Connection(sock);final=c.status();transfer['final_status']=final
            if (final['phase']!=5 or final['experiment']!=experiment or final['scenario']!=scenario or final['frames']!=frames):
                raise ValueError('not this experiment RESULT_READY')
            transfer['planned_reconnect_seconds']=time.perf_counter()-wait_start
            download_start=time.perf_counter()
            for object_id,name in [(7,'run.json'),(8,'pre_begin.json'),(4,'output.bin'),(5,'timing.bin'),(6,'report_v2.bin')]:
                transfer['downloads'][name]=c.download(object_id,args.out/name)
            transfer['download_seconds']=time.perf_counter()-download_start
        saved=json.loads((args.out/'run.json').read_text(encoding='utf-8'))
        if saved['experiment']!=experiment or saved['build_id']!=BUILD or saved['scenario']!=args.scenario:
            raise ValueError('saved run identity mismatch')
        print(f"总上传 {transfer['upload_seconds']:.3f} s；总下载 {transfer['download_seconds']:.3f} s",flush=True)
        if saved['state']!=3 or saved['result']['status'] or saved['result']['completed_frames']!=frames:
            raise RuntimeError('Runtime returned failure/incomplete; available scene and prefix preserved in '+str(args.out))
        passed=analyze(args.out,source,saved)
        transfer['status']='PASS' if passed else 'FAIL'
        return 0 if passed else 1
    except Exception as exc:
        transfer['errors'].append(str(exc));raise
    finally:
        (args.out/'transfer.json').write_text(json.dumps(transfer,indent=2)+'\n',encoding='utf-8')


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--ip',required=True);p.add_argument('--port',type=int,default=5001)
    p.add_argument('--scenario',choices=SCENES,required=True)
    p.add_argument('--start',action='store_true',required=True,help='explicitly start exactly one replay after upload')
    p.add_argument('--conditions',required=True);p.add_argument('--out',type=Path,required=True)
    args=p.parse_args()
    try:return run(args)
    except (ValueError,OSError,RuntimeError) as exc:
        print('ETH02 FAIL:',exc,file=sys.stderr);return 1


if __name__=='__main__':sys.exit(main())
