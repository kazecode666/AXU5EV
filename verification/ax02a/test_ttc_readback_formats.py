"""XSDB readback formats and read-only compatibility of the real ABA metadata."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import tkinter
import unittest

ROOT=Path(__file__).resolve().parents[2]


class FormatsTests(unittest.TestCase):
    def setUp(self):
        self.t=tkinter.Tcl()
        self.t.call('source',str(ROOT/'firmware/r5/ax02a/readback_ttc_characterize.tcl'))

    def test_symbol_integer_and_four_little_endian_bytes(self):
        for value in ['1076016','0x00106b30','48 107 16 0']:
            self.assertEqual(int(self.t.call('ax02a_ttc_char::address',value)),0x106b30)
        for value in ['48 107 16','48 107 16 0 0','48 256 16 0','48 -1 16 0','a b c d','4294967296','-2147483649']:
            with self.subTest(value=value),self.assertRaises(tkinter.TclError):
                self.t.call('ax02a_ttc_char::address',value)

    def test_uint32_serialization_checked_before_unsigned_format(self):
        for value,expected in [(-1180983640,3113983656),(-15663104,0xff110000),(-15663100,0xff110004),(4294967295,4294967295)]:
            n=self.t.call('ax02a_ttc_char::uint32',value)
            self.assertEqual(int(n),expected)
            self.assertEqual(self.t.call('format','%lld',n),str(expected))
        for value in [-2147483649,4294967296,'1.5','unknown']:
            with self.assertRaises(tkinter.TclError):self.t.call('ax02a_ttc_char::uint32',value)

    def test_real_signed_metadata_readonly_and_candidate_identity(self):
        spec=importlib.util.spec_from_file_location('ttc_analysis',ROOT/'scripts/ax02a_analyze_ttc_characterize.py')
        mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
        d=Path(tempfile.mkdtemp(prefix='ttc_formats_',dir=ROOT/'.runtime/ax02a'))
        src=ROOT/'.runtime/ax02a/board_manual/ttc_aba_01'
        r=mod.compare_aba(src/'A1',src/'B',src/'A2',d/'analysis')
        self.assertEqual(r['conclusion'],'RAW_PLUS_ONE_COMPATIBLE')
        self.assertTrue(r['repeatable']);self.assertEqual(r['issues'],[])
        for x in r['runs']:
            self.assertEqual(x['run']['build_id'],3113983656)
            self.assertEqual(x['run']['config']['periodic_base'],0xff110000)
        self.assertEqual(json.loads((src/'A1/run.json').read_text())['build_id'],-1180983640)
        original=json.loads((src/'A1/run.json').read_text());bad=copy.deepcopy(original);bad['build_id']=-2147483649
        (d/'bad.json').write_text(json.dumps(bad))
        self.assertFalse(mod.evaluate(src/'A1/samples.bin',d/'bad.json')['acquisition_valid'])

    def test_actual_signed_readback_address_build_and_short_read_guards(self):
        t=self.t
        t.eval('set calls {}; set pointer {48 107 16 0}; set short 0; proc targets {args} {return [list [dict create is_current 1 name "Cortex-R5 #0" suspended 1]]}')
        t.eval('proc print {args} {set s [lindex $args end]; if {$s eq "&ax02a_ttc_char_samples"} {return [dict create $s $::pointer]}; return [dict create $s [dict get $::values [string range $s 23 end]]]}')
        t.eval('proc mrd {args} {lappend ::calls $args;set i [lsearch $args -file];set f [open [lindex $args [expr {$i+1}]] wb];puts -nonewline $f [string repeat A [expr {[lindex $args end]-$::short}]];close $f}')
        src=ROOT/'.runtime/ax02a/board_manual/ttc_aba_01/A1/run.json'
        run=json.loads(src.read_text());v={**run,**run['config'],'command':0,'case_id':1}
        def values(data):t.call('set','values',t.call('dict','create',*[y for k,x in data.items() if not isinstance(x,dict) for y in (k,int(x) if isinstance(x,bool) else x)]))
        values(v)
        d=Path(tempfile.mkdtemp(prefix='ttc_readback_',dir=ROOT/'.runtime/ax02a'))
        prov=d/'prov.tcl';prov.write_text('dict create build_id 3113983656 workspace candidate1 elf candidate1/app.elf samples_address 1076016')
        args=['A1',0,10000,prov.as_posix(),'warm01','same power session','false']
        t.call('ax02a_ttc_char::readback',(d/'good').as_posix(),*args)
        saved=json.loads((d/'good/run.json').read_text())
        self.assertEqual(saved['build_id'],3113983656);self.assertEqual(saved['config']['periodic_base'],0xff110000)
        self.assertEqual((d/'good/samples.bin').stat().st_size,16000)
        t.call('set','pointer','49 107 16 0')
        with self.assertRaises(tkinter.TclError):t.call('ax02a_ttc_char::readback',(d/'address').as_posix(),*args)
        t.call('set','pointer','48 107 16 0')
        for value in [123,4294967296,-2147483649]:
            values({**v,'build_id':value})
            with self.assertRaises(tkinter.TclError):t.call('ax02a_ttc_char::readback',(d/str(value)).as_posix(),*args)
        values(v);t.call('set','short',1)
        with self.assertRaises(tkinter.TclError):t.call('ax02a_ttc_char::readback',(d/'short').as_posix(),*args)
        self.assertTrue((d/'short/samples.bin.partial').exists());self.assertFalse((d/'short/samples.bin').exists())


if __name__=='__main__':unittest.main()
