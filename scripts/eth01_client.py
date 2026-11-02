"""ETH01 v1 client. Import is inert; only explicit --ip connects. No retries."""
import argparse
import ipaddress
import json
from pathlib import Path
import secrets
import socket
import struct
import time
import zlib

HEADER = struct.Struct('!4sBBH6I')
MAX_PAYLOAD = 4096
MAX_BULK = 32 * 1024 * 1024

def encode(kind, transfer, seq, total, offset, payload):
    if len(payload) > MAX_PAYLOAD: raise ValueError('payload too large')
    return HEADER.pack(b'E01T',1,kind,0,transfer,seq,total,offset,len(payload),zlib.crc32(payload)) + payload

class Decoder:
    def __init__(self): self.buffer = bytearray()
    def feed(self, data):
        self.buffer.extend(data); result=[]
        while len(self.buffer) >= HEADER.size:
            magic,version,kind,res,tid,seq,total,off,n,crc = HEADER.unpack_from(self.buffer)
            if magic!=b'E01T' or version!=1 or res or n>MAX_PAYLOAD: raise ValueError('invalid header')
            if len(self.buffer)<HEADER.size+n: break
            payload=bytes(self.buffer[HEADER.size:HEADER.size+n])
            if zlib.crc32(payload)!=crc: raise ValueError('payload CRC mismatch')
            del self.buffer[:HEADER.size+n]
            result.append(dict(kind=kind,transfer=tid,seq=seq,total=total,offset=off,payload=payload))
        return result
    def finish(self):
        if self.buffer: raise ValueError('truncated frame')

def recv_exact(sock,n):
    data=bytearray()
    while len(data)<n:
        part=sock.recv(n-len(data))
        if not part: raise ConnectionError('stream closed before complete frame')
        data.extend(part)
    return bytes(data)

def request(sock,kind,tid,seq,total=0,offset=0,payload=b''):
    sock.sendall(encode(kind,tid,seq,total,offset,payload))
    h=recv_exact(sock,HEADER.size); n=HEADER.unpack(h)[-2]
    if n>MAX_PAYLOAD: raise ValueError('oversized response')
    frames=Decoder().feed(h+recv_exact(sock,n)); r=frames[0]
    if r['transfer']!=tid or r['seq']!=seq or r['kind']!=(kind|128) or r['total']!=total or r['offset']!=offset: raise ValueError('error or mismatched response: '+str(r))
    return r

def pattern(offset,n): return bytes(((offset+i)*17+3)&255 for i in range(n))

def run(args):
    # No hostname resolution, probes or fallback address.
    ipaddress.IPv4Address(args.ip)
    args.out.mkdir(parents=True,exist_ok=False)
    report=dict(status='FAIL',ip=args.ip,port=args.port,stage=args.stage,
                evidence='HOST_LOOPBACK' if ipaddress.ip_address(args.ip).is_loopback else 'USER_BOARD_RUN',errors=[])
    partial_manifest=args.out/'transfer.json.partial'
    partial_manifest.write_text(json.dumps(report,indent=2)+'\n')
    try:
        with socket.create_connection((args.ip,args.port),timeout=15) as sock:
            tid=secrets.randbelow(0xffffffff)+1; seq=1
            status=request(sock,7,tid,seq)['payload']; seq+=1
            if len(status)!=16: raise ValueError('status layout')
            build,speed,cache,count=struct.unpack('!4I',status)
            report.update(build_id=build,negotiated_mbps=speed,cache=cache,initial_model_count=count)
            if args.stage=='small':
                for n in (0,1,255,256):
                    p=pattern(0,n)
                    if request(sock,1,tid,seq,payload=p)['payload']!=p: raise ValueError('echo mismatch')
                    seq+=1
                    q=request(sock,2,tid,seq,payload=p)['payload']; seq+=1; count+=1
                    if q!=struct.pack('!I',count)+bytes(x^90 for x in p): raise ValueError('model bytes/count mismatch')
                report['model_count']=count
            else:
                n=args.bytes
                if n not in (65536,1048576,33554432): raise ValueError('use staged sizes')
                start=time.perf_counter(); request(sock,3,tid,seq,total=n); seq+=1
                crc=0
                for off in range(0,n,MAX_PAYLOAD):
                    p=pattern(off,min(MAX_PAYLOAD,n-off)); crc=zlib.crc32(p,crc)
                    request(sock,4,tid,seq,n,off,p); seq+=1
                q=request(sock,6,tid,seq,n,payload=struct.pack('!I',crc)); seq+=1
                if q['payload']!=struct.pack('!I',crc): raise ValueError('upload CRC mismatch')
                upload=time.perf_counter()-start; start=time.perf_counter(); readcrc=0
                partial=args.out/'readback.bin.partial'
                with partial.open('xb') as f:
                    for off in range(0,n,MAX_PAYLOAD):
                        q=request(sock,5,tid,seq,n,off); seq+=1; p=q['payload']
                        if q['total']!=n or q['offset']!=off or p!=pattern(off,min(MAX_PAYLOAD,n-off)): raise ValueError('readback contents/position mismatch')
                        f.write(p); readcrc=zlib.crc32(p,readcrc)
                download=time.perf_counter()-start
                if partial.stat().st_size!=n or readcrc!=crc: raise ValueError('incomplete readback')
                partial.rename(args.out/'readback.bin')
                report.update(bytes=n,crc32=crc,upload_seconds=upload,download_seconds=download,
                    upload_MiBps=n/upload/1048576,download_MiBps=n/download/1048576,
                    throughput_target_MiBps=1,throughput_target_met=min(n/upload,n/download)>=1048576)
        report['status']='PASS'
    except BaseException as exc:
        report['errors'].append(str(exc)); raise
    finally:
        (args.out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
        partial_manifest.write_text(json.dumps(report,indent=2)+'\n')
        if report['status']=='PASS': partial_manifest.rename(args.out/'transfer.complete.json')

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--ip',required=True); p.add_argument('--port',type=int,default=5001)
    p.add_argument('--stage',choices=['small','bulk'],required=True)
    p.add_argument('--bytes',type=int,default=65536); p.add_argument('--out',type=Path,required=True)
    run(p.parse_args())
