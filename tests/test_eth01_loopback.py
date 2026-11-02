import argparse
import importlib.util
from pathlib import Path
import socket
import subprocess
import threading
import unittest
import uuid
import json

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('client',ROOT/'scripts/eth01_client.py')
client=importlib.util.module_from_spec(spec);spec.loader.exec_module(client)

class LoopbackTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        from test_eth01_service import ServiceTests
        ServiceTests.setUpClass()
    def execute(self,stage,n,interrupt=False):
        errors=[]
        listener=socket.socket();listener.bind(('127.0.0.1',0));listener.listen(1)
        port=listener.getsockname()[1]
        def serve():
            proc=None
            try:
                with listener,listener.accept()[0] as sock:
                    proc=subprocess.Popen([str(ROOT/'.runtime/ethernet/eth01/host_server.exe')],stdin=subprocess.PIPE,stdout=subprocess.PIPE)
                    while True:
                        try: header=client.recv_exact(sock,32)
                        except ConnectionError:break
                        n=client.HEADER.unpack(header)[-2];p=client.recv_exact(sock,n)
                        proc.stdin.write(header+p);proc.stdin.flush()
                        response=proc.stdout.read(32)
                        if len(response)!=32: raise ValueError('C server rejected request')
                        n=client.HEADER.unpack(response)[-2];response+=proc.stdout.read(n)
                        if interrupt and client.HEADER.unpack(header)[2]==5 and client.HEADER.unpack(header)[7]==4096:
                            sock.sendall(response[:7]);break
                        # Deliberately fragment header and payload, including slow reader.
                        sock.sendall(response[:7]);sock.sendall(response[7:31]);sock.sendall(response[31:])
            except Exception as e:errors.append(e)
            finally:
                if proc:
                    proc.stdin.close();proc.wait(timeout=5);proc.stdout.close()
        thread=threading.Thread(target=serve);thread.start()
        out=ROOT/'.runtime/ethernet/eth01/host'/str(uuid.uuid4())
        try:
            args=argparse.Namespace(ip='127.0.0.1',port=port,out=out,stage=stage,bytes=n)
            if interrupt:
                with self.assertRaises(ConnectionError):client.run(args)
            else:client.run(args)
        finally:thread.join(timeout=10)
        self.assertFalse(thread.is_alive());self.assertEqual(errors,[])
        report=json.loads((out/'result.json').read_text())
        self.assertEqual(report['status'],'FAIL' if interrupt else 'PASS');self.assertEqual(report['evidence'],'HOST_LOOPBACK')
        if interrupt:
            self.assertEqual((out/'readback.bin.partial').stat().st_size,4096)
            self.assertTrue((out/'transfer.json.partial').exists())
            self.assertFalse((out/'readback.bin').exists())
    def test_small_generated_model_roundtrip(self):self.execute('small',0)
    def test_bulk_64KiB(self):self.execute('bulk',65536)
    def test_bulk_1MiB(self):self.execute('bulk',1048576)
    def test_bulk_32MiB(self):self.execute('bulk',33554432)
    def test_interrupted_read_keeps_partial(self):self.execute('bulk',65536,True)

if __name__=='__main__':unittest.main()
