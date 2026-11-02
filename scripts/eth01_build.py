"""Offline build only. No debugger imports, discovery, or network client."""
import argparse
import json
from pathlib import Path
import shutil
import sys
import os
import re
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / '.runtime/ethernet/eth01'
WS = OUT / 'vitis_ethernet_r2'
APP = 'eth01_tcp'

def check_startup():
    from ax02a_build_r5 import inspect_fsbl
    from ax02a_build_ttc_characterize import symbols
    platform=WS/'eth01_platform';elf=WS/APP/'build/eth01_tcp.elf'
    fsbl=platform/'export/eth01_platform/sw/boot/fsbl.elf'
    config=json.loads((platform/'vitis-comp.json').read_text(encoding='utf-8'))['configuration']
    for name,cpu in [('zynqmp_fsbl','psu_cortexa53_0'),('r5_standalone','psu_cortexr5_0')]:
        assert len([d for d in config['domains'] if d['name']==name and d['processor']==cpu])==1,'domain mismatch'
    data=elf.read_bytes();h=struct.unpack_from('<16sHHIIIIIHHHHHH',data)
    assert data[:6]==b'\x7fELF\x01\x01' and h[1]==2 and h[2]==40,'application must be little-endian ARM ELF32 EXEC'
    segments=[]
    for i in range(h[10]):
        kind,off,vaddr,paddr,filesz,memsz,flags,align=struct.unpack_from('<8I',data,h[5]+i*h[9])
        if kind==1:
            assert (vaddr==0x10000000 and memsz==0x2000000 and filesz==0) or vaddr+memsz<=0x10000000,'program outside allowed ETH01 memory layout'
            segments.append(dict(address=vaddr,file_bytes=filesz,memory_bytes=memsz))
    assert len([x for x in segments if x['address']==0x10000000])==1
    e=dict(machine='ARM',elf_class=32,entry=h[4],segments=segments)
    f=inspect_fsbl(fsbl);s=symbols(elf)
    assert all(n in s for n in ['main','EthNetService','EthModelService','ETH01_Target_step','Eth01Rx','Eth01Tx','eth_phy_id','test_ddr','_heap','_stack'])
    assert s['test_ddr']==dict(address=0x10000000,bytes=0x2000000),'DDR arena mismatch'
    assert s['_heap']['address']<0x10000000 and s['_stack']['address']<0x10000000
    launch=json.loads((WS/APP/'_ide/launch.json').read_text(encoding='utf-8'))
    profile=[x for x in launch['configurations'] if x['name']=='eth01_tcp_manual'];assert len(profile)==1
    p=profile[0];t=p['targetSetup'];z=t['zuInitialization'];apps=t['downloadElf']
    def local(v):return Path(v.replace('${workspaceFolder}',WS.as_posix())).resolve()
    assert p['type']=='tcf-debug' and p['request']=='launch' and p['debugType']=='baremetal-zu'
    assert t['enableRPUSplitMode'] and t['resetSystem'] and not t['programDevice'] and not t['bitstreamFile']
    assert z['isFsbl'] and z['usingFSBL']['initWithFSBL'] and z['usingFSBL']['fsblExitSymbol']=='XFsbl_Exit'
    assert local(z['usingFSBL']['fsblFile'])==fsbl.resolve() and not z['usingPsuInit']['runPsuInit']
    assert len(apps)==1 and apps[0]['core']=='psu_cortexr5_0' and apps[0]['stopAtEntry'] and local(apps[0]['elfFile'])==elf.resolve()
    include=platform/'export/eth01_platform/sw/r5_standalone/include'
    params=(include/'xparameters.h').read_text(encoding='utf-8')
    opts=(include/'lwipopts.h').read_text(encoding='utf-8')
    timer=(include/'xtimer_config.h').read_text(encoding='utf-8')
    assert '#define XPAR_XEMACPS_0_BASEADDR 0xff0e0000' in params
    assert not re.search(r'^#define NO_SYS_NO_TIMERS\s+1',opts,re.M) and re.search(r'#define TCP_WND\s+8192',opts)
    assert '#define XTIMER_NO_TICK_TIMER' in timer and '#define XTIMER_IS_DEFAULT_TIMER' in timer and 'XPAR_CPU_CORE_CLOCK_FREQ_HZ/64' in timer
    ld=(WS/APP/'src/lscript.ld').read_text(encoding='utf-8')
    assert 'LENGTH = 0xFF00000' in ld and '.eth_bulk 0x10000000 (NOLOAD)' in ld and '> eth_test_ddr' in ld
    tool=Path('E:/AMDDesignTools/2026.1/Vitis/gnu/armr5/nt/gcc-arm-none-eabi/bin')
    attributes=subprocess.check_output([str(tool/'armr5-none-eabi-readelf.exe'),'-W','-h','-l','-A',str(elf)],text=True)
    calls=subprocess.check_output([str(tool/'armr5-none-eabi-objdump.exe'),'-d','--disassemble=EthModelService',str(elf)],text=True)
    assert all(x in attributes for x in ['Realtime','VFPv3-D16','VFP registers'])
    assert '<ETH01_Target_step>' in calls,'model not called in ARM binary'
    generated_calls=subprocess.check_output([str(tool/'armr5-none-eabi-objdump.exe'),'-d','--disassemble=ETH01_Target_step',str(elf)],text=True)
    assert all(x in generated_calls for x in ['<Eth01Rx>','<Eth01Tx>']),'C Caller model backend not called in ARM binary'
    return dict(status='STARTUP_CHECK_PASS',workspace=str(WS),elf=str(elf),fsbl=str(fsbl),
                launch='eth01_tcp_manual',r5=e,a53_fsbl=f,symbols={k:s[k] for k in ['test_ddr','_heap','_stack','ETH01_Target_step']},
                arm_call_chain=calls,generated_call_chain=generated_calls,attributes=attributes,board='NOT_RUN')

def build(resume=False):
    if (WS/'startup_validation.json').exists(): raise ValueError('verified candidate preserved; select a NEW workspace in config')
    if WS.exists() and not resume: raise ValueError('existing workspace preserved; use --resume for this unfinished ETH01 candidate')
    from eth01_lwip_overlay import prepare
    repo=prepare(ROOT,OUT)
    import vitis
    client = vitis.create_client()
    try:
        client.set_workspace(str(WS))
        client.add_embedded_sw_repo(level='LOCAL',path=str(repo))
        if resume: p=client.get_component(name='eth01_platform')
        else: p = client.create_platform_component(name='eth01_platform', hw_design=str(OUT/'ps_target/eth01_ps.xsa'),
            cpu='psu_cortexr5_0', os='standalone', domain_name='r5_standalone', no_boot_bsp=False,
            fsbl_target='psu_cortexa53_0', generate_dtb=False, compiler='gcc')
        d = p.get_domain('r5_standalone')
        if not (WS/'eth01_platform/psu_cortexr5_0/r5_standalone/bsp/libsrc/lwip220').exists(): d.set_lib('lwip220')
        d.set_config(option='lib',param='lwip220_tcp_wnd',value='8192',lib_name='lwip220')
        d.set_config(option='lib',param='lwip220_no_sys_no_timers',value='false',lib_name='lwip220')
        p.build()
        create_app(client)
        result=check_startup()
        (WS/'startup_validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
        (OUT/'platform_ready.json').write_text(json.dumps({'workspace':str(WS)},indent=2))
    finally: vitis.dispose()

def create_app(client):
    gen=OUT/'model/codegen/ETH01_Target_ert_rtw'
    if (WS/APP).exists():
        app=client.get_component(name=APP)
        for folder in [ROOT/'firmware/r5/ethernet',ROOT/'integration/r5_ethernet',gen]:
            for source in folder.iterdir():
                if source.suffix in ('.c','.h') and source.name!='ert_main.c': shutil.copyfile(source,WS/APP/source.name)
    else:
        app=client.create_app_component(name=APP,platform=client.find_platform_in_repos('eth01_platform'),domain='r5_standalone',template='empty_application')
        for folder in [ROOT/'firmware/r5/ethernet',ROOT/'integration/r5_ethernet',gen]:
            files=[x.name for x in folder.iterdir() if x.suffix in ('.c','.h') and x.name!='ert_main.c']
            app.import_files(from_loc=str(folder),files=files)
    app.set_app_config(key='USER_COMPILE_OPTIMIZATION_LEVEL',values='-O2')
    app.set_app_config(key='USER_COMPILE_OTHER_FLAGS',values='-fno-fast-math -ffp-contract=off -mcpu=cortex-r5 -mfpu=vfpv3-d16 -mfloat-abi=hard -DETH_BUILD_ID=0x45303102U')
    app.set_app_config(key='USER_LINK_OTHER_FLAGS',values='-Wl,-Map=eth01_tcp.map')
    ld=app.get_ld_script();ld.set_stack_size('0x10000');ld.set_heap_size('0x40000')
    script=WS/APP/'src/lscript.ld'
    if not script.exists(): raise ValueError('generated linker script path missing')
    text=script.read_text(encoding='utf-8')
    if '.eth_bulk' not in text:
        import re
        text=re.sub(r'(psu_r5_ddr_0_memory_0[^\n]*LENGTH\s*=\s*)0x[0-9a-fA-F]+',r'\g<1>0xFF00000',text)
        text=text.replace('SECTIONS\n{','SECTIONS\n{\n .eth_bulk 0x10000000 (NOLOAD) : { KEEP(*(.eth_bulk)) }\n')
        script.write_text(text,encoding='utf-8')
    # Explicitly split the test DDR arena from all program/stack/heap regions.
    import re
    text=script.read_text(encoding='utf-8')
    text=re.sub(r'(psu_r5_ddr_0_memory_0[^\n]*LENGTH\s*=\s*)0x[0-9a-fA-F]+',r'\g<1>0xFF00000',text)
    if 'eth_test_ddr :' not in text:
        text=text.replace('MEMORY\n{','MEMORY\n{\n eth_test_ddr : ORIGIN = 0x10000000, LENGTH = 0x2000000')
    if '> eth_test_ddr' not in text:
        text=text.replace('KEEP(*(.eth_bulk)) }','KEEP(*(.eth_bulk)) } > eth_test_ddr')
    script.write_text(text,encoding='utf-8')
    app.build()
    launch_path=WS/APP/'_ide/launch.json'
    launch=json.loads(launch_path.read_text(encoding='utf-8'))
    profile=json.loads((ROOT/'firmware/r5/ax02a/launch_first_wait.json').read_text(encoding='utf-8'))['configurations'][0]
    profile['name']='eth01_tcp_manual'
    profile['targetSetup']['zuInitialization']['usingFSBL']['fsblFile']='${workspaceFolder}/eth01_platform/export/eth01_platform/sw/boot/fsbl.elf'
    profile['targetSetup']['downloadElf'][0]['elfFile']='${workspaceFolder}/eth01_tcp/build/eth01_tcp.elf'
    launch['configurations']=[x for x in launch['configurations'] if x['name']!='eth01_tcp_manual']+[profile]
    launch_path.write_text(json.dumps(launch,indent=2)+'\n',encoding='utf-8')

if __name__ == '__main__':
    config=Path(os.environ.get('ETH01_CONFIG',ROOT/'firmware/r5/ethernet/build_config.json'))
    c=json.loads(config.read_text(encoding='utf-8-sig'))
    OUT=(ROOT/c['output']).resolve();WS=(ROOT/c['workspace']).resolve()
    if not OUT.is_relative_to(ROOT/'.runtime/ethernet') or not WS.is_relative_to(OUT): raise ValueError('ETH01 output/workspace must remain inside .runtime/ethernet')
    if '--check-startup' in sys.argv: print(json.dumps(check_startup(),indent=2))
    else:
        build('--resume' in sys.argv)
        print('ETH01_BUILD_PASS')
