import ctypes as C
import importlib.util
import os
from pathlib import Path
import subprocess
import unittest
import zlib

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('client',ROOT/'scripts/eth01_client.py')
client=importlib.util.module_from_spec(spec);spec.loader.exec_module(client)

class ServiceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if hasattr(cls,'lib'): return
        gen=ROOT/'.runtime/ethernet/eth01/model/codegen/ETH01_Target_ert_rtw'
        gcc=Path('C:/ProgramData/MATLAB/SupportPackages/R2026b/3P.instrset/mingw_w64.instrset/bin/gcc.exe')
        env=dict(os.environ);env['PATH']=str(gcc.parent)+os.pathsep+env['PATH']
        sources=[ROOT/'firmware/r5/ethernet'/x for x in ('eth_protocol.c','eth_service.c')]+[ROOT/'integration/r5_ethernet/eth_model_if.c',ROOT/'integration/r5_ethernet/eth_queue.c',gen/'ETH01_Target.c']
        common=[str(gcc),'-std=c11','-O2','-Wall','-Wextra','-Werror','-I'+str(gen),'-I'+str(ROOT/'integration/r5_ethernet'),'-I'+str(ROOT/'firmware/r5/ethernet')]
        dll=ROOT/'.runtime/ethernet/eth01/service.dll'
        subprocess.run(common+['-shared']+list(map(str,sources))+['-o',str(dll)],check=True,env=env)
        subprocess.run(common+list(map(str,sources))+[str(ROOT/'tests/eth01_host_server.c'),'-o',str(ROOT/'.runtime/ethernet/eth01/host_server.exe')],check=True,env=env)
        cls.lib=C.CDLL(str(dll)); cls.lib.EthTxPeek.argtypes=[C.POINTER(C.c_size_t)];cls.lib.EthTxPeek.restype=C.c_void_p
        cls.bulk=C.create_string_buffer(client.MAX_BULK)
    def setUp(self): self.lib.EthSessionInit(self.bulk,0x45303101,1000)
    def feed(self,data): return self.lib.EthRxTryPush(data,len(data))
    def take(self,chunk=100000):
        n=C.c_size_t();p=self.lib.EthTxPeek(C.byref(n)); n=min(n.value,chunk)
        data=C.string_at(p,n);self.lib.EthTxConsume(n);return data
    def transact(self,k,s,total=0,off=0,p=b''):
        self.assertEqual(self.feed(client.encode(k,8,s,total,off,p)),0)
        self.assertEqual(self.lib.EthNetService(),1)
        return client.Decoder().feed(self.take())[0]
    def test_fragmentation_coalescing_and_tx_backpressure(self):
        a=client.encode(2,8,1,0,0,b'abc');b=client.encode(2,8,2,0,0,b'def')
        for byte in a[:-1]:
            self.assertEqual(self.feed(bytes([byte])),0);self.assertEqual(self.lib.EthNetService(),0)
        self.feed(a[-1:]+b);self.assertEqual(self.lib.EthNetService(),1)
        first=self.take(3);self.assertEqual(self.lib.EthNetService(),0)
        first+=self.take();r=client.Decoder().feed(first)[0]
        self.assertEqual(r['payload'],b'\0\0\0\1'+bytes(x^90 for x in b'abc'))
        self.assertEqual(self.lib.EthNetService(),1)
        self.assertEqual(client.Decoder().feed(self.take())[0]['payload'][:4],b'\0\0\0\2')
    def test_bad_crc_version_length_and_duplicate(self):
        good=client.encode(1,8,1,0,0,b'x')
        for pos in (0,4,27,31,32):
            self.lib.EthSessionReset();bad=bytearray(good);bad[pos]^=1
            self.feed(bytes(bad));self.assertEqual(self.lib.EthNetService(),-1)
        self.lib.EthSessionReset();self.transact(1,1,p=b'x')
        self.feed(good);self.assertEqual(self.lib.EthNetService(),-1)
    def test_full_queue_atomic_and_reset(self):
        self.assertEqual(self.feed(b'x'*8192),0);self.assertEqual(self.feed(b'y'),2)
        self.lib.EthSessionReset();self.assertEqual(self.transact(1,1,p=b'a')['payload'],b'a')
    def test_bulk_boundary_integrity_and_session_abandon(self):
        self.assertEqual(self.transact(3,1,client.MAX_BULK+1)['kind'],255)
        self.transact(3,2,65536);seq=3;crc=0
        self.assertEqual(self.transact(4,seq,65536,1,b'x')['kind'],255);seq+=1
        for off in range(0,65536,4096):
            p=client.pattern(off,4096);crc=zlib.crc32(p,crc)
            self.assertEqual(self.transact(4,seq,65536,off,p)['kind'],132);seq+=1
        self.assertEqual(self.transact(5,seq,65536)['kind'],255);seq+=1
        self.assertEqual(self.transact(6,seq,65536,p=crc.to_bytes(4,'big'))['payload'],crc.to_bytes(4,'big'));seq+=1
        self.assertEqual(self.transact(5,seq,65536,61440)['payload'],client.pattern(61440,4096))
        self.lib.EthSessionReset();self.assertEqual(self.transact(5,1,65536)['kind'],255)

if __name__=='__main__': unittest.main()
