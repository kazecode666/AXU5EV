"""Reject the reported R5-FSBL-on-A53 mismatch before a manual GUI launch."""
import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[2]
SPEC=importlib.util.spec_from_file_location('ax02a_build_r5',ROOT/'scripts/ax02a_build_r5.py')
BUILD=importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BUILD)


class FsblTargetTests(unittest.TestCase):
    def inspect(self,elf_class=2,machine=183,kind=2):
        self.assertTrue(callable(getattr(BUILD,'inspect_fsbl',None)),
                        'missing offline FSBL architecture gate')
        ident=b'\x7fELF'+bytes([elf_class,1,1])+bytes(9)
        if elf_class==2:
            header=struct.pack('<16sHHIQQQIHHHHHH',ident,kind,machine,1,
                               0xfffc0000,0,0,0,64,56,0,64,0,0)
        else:
            header=struct.pack('<16sHHIIIIIHHHHHH',ident,kind,machine,1,
                               0xfffc0000,0,0,0x5000400,52,32,0,40,0,0)
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'fsbl.elf'
            path.write_bytes(header)
            return BUILD.inspect_fsbl(path)

    def test_a53_aarch64_executable(self):
        self.assertEqual(self.inspect()['machine'],'AArch64')

    def test_reported_r5_fsbl_is_rejected(self):
        with self.assertRaisesRegex(ValueError,'A53_0.*ELF64.*AArch64'):
            self.inspect(elf_class=1,machine=40)

    def test_64bit_non_aarch64_is_rejected(self):
        with self.assertRaisesRegex(ValueError,'AArch64'):
            self.inspect(machine=62)

    def test_relocatable_fsbl_is_rejected(self):
        with self.assertRaisesRegex(ValueError,'executable'):
            self.inspect(kind=1)


class StartupContractTests(unittest.TestCase):
    def setUp(self):
        self.folder=tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.ws=Path(self.folder.name)
        self.platform=self.ws/'ax02a_platform/vitis-comp.json'
        self.platform.parent.mkdir()
        self.platform.write_text(json.dumps({'configuration':{'domains':[
            {'name':'zynqmp_fsbl','processor':'psu_cortexa53_0'},
            {'name':'r5_standalone','processor':'psu_cortexr5_0'}]}}))
        self.fsbl=self.ws/'ax02a_platform/export/ax02a_platform/sw/boot/fsbl.elf'
        self.fsbl.parent.mkdir(parents=True)
        ident=b'\x7fELF\x02\x01\x01'+bytes(9)
        self.fsbl.write_bytes(struct.pack('<16sHHIQQQIHHHHHH',ident,2,183,1,
                                          0xfffc0000,0,0,0,64,56,0,64,0,0))
        app=self.ws/'ax02a_replay/build/ax02a_replay.elf'
        app.parent.mkdir(parents=True)
        ident=b'\x7fELF\x01\x01\x01'+bytes(9)
        header=struct.pack('<16sHHIIIIIHHHHHH',ident,2,40,1,0,52,0,0x5000400,52,32,1,0,0,0)
        app.write_bytes(header+struct.pack('<8I',1,84,0,0,4,4,5,4)+b'data')
        self.launch=self.ws/'ax02a_replay/_ide/launch.json'
        self.launch.parent.mkdir()
        self.profile=json.loads((ROOT/'firmware/r5/ax02a/launch_first_wait.json').read_text())
        self.write_launch()

    def write_launch(self):
        self.launch.write_text(json.dumps(self.profile))

    def test_matching_a53_fsbl_and_r5_app(self):
        result=BUILD.check_startup(self.ws)
        self.assertEqual(result['fsbl']['processor'],'psu_cortexa53_0')
        self.assertEqual(result['application']['processor'],'psu_cortexr5_0')

    def test_platform_name_cannot_hide_wrong_fsbl_domain(self):
        data=json.loads(self.platform.read_text())
        data['configuration']['domains'][0]['processor']='psu_cortexr5_0'
        self.platform.write_text(json.dumps(data))
        with self.assertRaisesRegex(ValueError,'zynqmp_fsbl must target psu_cortexa53_0'):
            BUILD.check_startup(self.ws)

    def test_metadata_cannot_hide_actual_r5_fsbl(self):
        self.fsbl.write_bytes(b'\x7fELF\x01\x01\x01'+bytes(64))
        with self.assertRaisesRegex(ValueError,'A53_0.*ELF64'):
            BUILD.check_startup(self.ws)

    def test_launch_cannot_point_to_another_workspace_fsbl(self):
        self.profile['configurations'][0]['targetSetup']['zuInitialization']['usingFSBL']['fsblFile']='../old/fsbl.elf'
        self.write_launch()
        with self.assertRaisesRegex(ValueError,'exported A53 FSBL'):
            BUILD.check_startup(self.ws)

    def test_launch_cannot_download_control_app_to_a53(self):
        self.profile['configurations'][0]['targetSetup']['downloadElf'][0]['core']='psu_cortexa53_0'
        self.write_launch()
        with self.assertRaisesRegex(ValueError,'only the R5_0 application'):
            BUILD.check_startup(self.ws)


if __name__=='__main__':unittest.main()
