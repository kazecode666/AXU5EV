"""The executable gate must never accept Runtime objects or another CPU."""
import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[2]
SPEC=importlib.util.spec_from_file_location('ax02a_build_r5',ROOT/'scripts/ax02a_build_r5.py')
BUILD=importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BUILD)


class ExecutableGateTests(unittest.TestCase):
    def inspect(self,kind=2,machine=40,address=0):
        ident=b'\x7fELF\x01\x01\x01'+bytes(9)
        header=struct.pack('<16sHHIIIIIHHHHHH',ident,kind,machine,1,address,52,0,0x5000400,52,32,1,0,0,0)
        segment=struct.pack('<8I',1,84,address,address,4,4,5,4)
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'sample.elf';path.write_bytes(header+segment+b'data')
            return BUILD.inspect_elf(path)

    def test_arm_executable(self):
        self.assertEqual(self.inspect()['machine'],'ARM')

    def test_relocatable_is_not_executable(self):
        with self.assertRaisesRegex(ValueError,'relocatable'):
            self.inspect(kind=1)

    def test_a53_or_x86_is_not_r5(self):
        with self.assertRaisesRegex(ValueError,'EM_ARM'):
            self.inspect(machine=183)

    def test_buffer_overlap(self):
        with self.assertRaisesRegex(ValueError,'overlaps'):
            self.inspect(address=0x10000000)


if __name__=='__main__':unittest.main()
