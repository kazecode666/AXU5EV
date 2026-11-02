import importlib.util
from pathlib import Path
import struct
import unittest
import zlib

ROOT = Path(__file__).resolve().parents[1]

class ProtocolTests(unittest.TestCase):
    def setUp(self):
        p = ROOT / 'scripts/eth01_client.py'
        self.assertTrue(p.exists(), 'ETH01 protocol/client not implemented')
        spec = importlib.util.spec_from_file_location('client', p)
        self.m = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.m)

    def test_segments_and_coalescing(self):
        a = self.m.encode(2, 3, 4, 5, 0, b'hello')
        b = self.m.encode(1, 3, 5, 0, 0, b'')
        for split in range(len(a) + 1):
            d = self.m.Decoder()
            got = d.feed(a[:split]) + d.feed(a[split:] + b)
            self.assertEqual([x['payload'] for x in got], [b'hello', b''])

    def test_bad_headers_crc_truncation(self):
        a = self.m.encode(2, 3, 4, 5, 0, b'hello')
        for index in (0, 4, 6, 27, 31, 34):
            b = bytearray(a); b[index] ^= 1
            with self.assertRaises(ValueError): self.m.Decoder().feed(b)
        d = self.m.Decoder(); d.feed(a[:-1])
        with self.assertRaises(ValueError): d.finish()

    def test_exact_read_short_and_disconnect(self):
        class Stream:
            def __init__(self): self.data = bytearray(b'abc')
            def recv(self, n):
                if not self.data: return b''
                return bytes([self.data.pop(0)])
        s = Stream()
        self.assertEqual(self.m.recv_exact(s, 3), b'abc')
        with self.assertRaises(ConnectionError): self.m.recv_exact(s, 1)

    def test_pattern_chunk_independence(self):
        self.assertEqual(self.m.pattern(4096, 9000), self.m.pattern(4096, 4000)+self.m.pattern(8096,5000))

if __name__ == '__main__': unittest.main()
