"""Offline ETH02 Vitis build / existing startup inspection; never opens a target."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from ax02a_build_r5 import source_files, runtime_candidate, check_startup as runtime_startup
from ax02a_build_ttc_characterize import symbols
from eth01_lwip_overlay import prepare

ROOT=Path(__file__).resolve().parents[1]
CONFIG=Path(os.environ.get('ETH02_CONFIG',ROOT/'firmware/r5/ethernet_runtime/build_config.json'))
C=json.loads(CONFIG.read_text(encoding='utf-8-sig'))
OUT=(ROOT/C['output']).resolve()
WS=(ROOT/C['workspace']).resolve()
APP='eth02_runtime'
PLATFORM='eth02_platform'
LAUNCH='eth02_runtime_manual'
BUILD=0x45303201


def check_startup():
    result=runtime_startup(WS,1,PLATFORM,APP,LAUNCH,BUILD)
    include=WS/PLATFORM/'export'/PLATFORM/'sw/r5_standalone/include'
    params=(include/'xparameters.h').read_text(encoding='utf-8')
    timer=(include/'xtimer_config.h').read_text(encoding='utf-8')
    opts=(include/'lwipopts.h').read_text(encoding='utf-8')
    assert '#define XPAR_XEMACPS_0_BASEADDR 0xff0e0000' in params
    assert '#define XPAR_XTTCPS_0_BASEADDR 0xff110000' in params
    assert '#define XPAR_XTTCPS_1_BASEADDR 0xff110004' in params
    assert '#define XTIMER_NO_TICK_TIMER' in timer and '#define XTIMER_IS_DEFAULT_TIMER' in timer
    assert 'XPAR_CPU_CORE_CLOCK_FREQ_HZ/64' in timer
    assert not re.search(r'^#define NO_SYS_NO_TIMERS\s+1',opts,re.M)
    elf=WS/APP/'build'/(APP+'.elf');syms=symbols(elf)
    assert all(n in syms for n in ['Eth02Execute','ax02a_replay','ax02a_postprocess',
        'AXU5EV_R5_Runtime_step','eth02_application_id','emac_bd_space','_heap','_stack'])
    assert 'test_ddr' not in syms
    for name in ['emac_bd_space','_heap','_stack']:
        s=syms[name];assert s['address']+s['bytes']<0x10000000
    ld=(WS/APP/'src/lscript.ld').read_text(encoding='utf-8')
    assert 'LENGTH = 0xFF00000' in ld and '.eth_bulk' not in ld
    tool=Path('E:/AMDDesignTools/2026.1/Vitis/gnu/armr5/nt/gcc-arm-none-eabi/bin')
    attributes=subprocess.check_output([str(tool/'armr5-none-eabi-readelf.exe'),'-W','-A',str(elf)],text=True)
    assert all(x in attributes for x in ['Realtime','VFPv3-D16','VFP registers'])
    result.update(workspace=WS.as_posix(),elf=elf.as_posix(),build_id=hex(BUILD),
        symbols={n:syms[n] for n in ['emac_bd_space','_heap','_stack','AXU5EV_R5_Runtime_step']},
        board='NOT_RUN')
    return result


def build(resume=False):
    if (WS/'startup_validation.json').exists():raise ValueError('verified candidate preserved; select a new workspace')
    if WS.exists() and not resume:raise ValueError('existing workspace preserved; --resume is only for this unfinished candidate')
    xsa=(ROOT/C['xsa']).resolve();generated=(ROOT/C['generated']).resolve()
    files=[p for p in source_files(generated) if p.name!='main.c']
    files += [ROOT/'firmware/r5/ethernet'/n for n in
        ['eth_platform.c','eth_service.c','eth_service.h','eth_protocol.c','eth_protocol.h']]
    files += [ROOT/'integration/r5_ethernet/eth_model_if.h',
        ROOT/'firmware/r5/ethernet_runtime/eth02_runtime.c',ROOT/'firmware/r5/ethernet_runtime/eth02_runtime.h']
    repo=prepare(ROOT,OUT)
    import vitis
    client=vitis.create_client()
    try:
        client.set_workspace(str(WS));client.add_embedded_sw_repo(level='LOCAL',path=str(repo))
        if resume:p=client.get_component(name=PLATFORM)
        else:p=client.create_platform_component(name=PLATFORM,hw_design=str(xsa),
            cpu='psu_cortexr5_0',os='standalone',domain_name='r5_standalone',
            no_boot_bsp=False,fsbl_target='psu_cortexa53_0',generate_dtb=False,compiler='gcc')
        d=p.get_domain('r5_standalone')
        if not (WS/PLATFORM/'psu_cortexr5_0/r5_standalone/bsp/libsrc/lwip220').exists():d.set_lib('lwip220')
        d.set_config(option='lib',param='lwip220_tcp_wnd',value='8192',lib_name='lwip220')
        d.set_config(option='lib',param='lwip220_no_sys_no_timers',value='false',lib_name='lwip220')
        p.build()
        if (WS/APP).exists():
            app=client.get_component(name=APP)
            for source in files:shutil.copyfile(source,WS/APP/source.name)
        else:
            xpfm=WS/PLATFORM/'export'/PLATFORM/(PLATFORM+'.xpfm')
            app=client.create_app_component(name=APP,platform=str(xpfm),domain='r5_standalone',template='empty_application')
            for source in files:app.import_files(from_loc=str(source.parent),files=[source.name])
        app.set_app_config(key='USER_COMPILE_OPTIMIZATION_LEVEL',values='-O2')
        app.set_app_config(key='USER_COMPILE_OTHER_FLAGS',values=
            '-fno-fast-math -ffp-contract=off -mcpu=cortex-r5 -mfpu=vfpv3-d16 -mfloat-abi=hard '
            '-DETH02_RUNTIME -DETH_BUILD_ID=0x45303201U -DAX02A_RUNTIME_CANDIDATE_ID=0x45303201U')
        app.set_app_config(key='USER_LINK_LIBRARIES',values=['m'])
        app.set_app_config(key='USER_LINK_OTHER_FLAGS',values='-Wl,-Map=eth02_runtime.map')
        ld=app.get_ld_script();ld.set_stack_size('0x10000');ld.set_heap_size('0x40000')
        script=WS/APP/'src/lscript.ld';text=script.read_text(encoding='utf-8')
        text=re.sub(r'(psu_r5_ddr_0_memory_0[^\n]*LENGTH\s*=\s*)0x[0-9a-fA-F]+',r'\g<1>0xFF00000',text)
        script.write_text(text,encoding='utf-8')
        app.build()
        launch_path=WS/APP/'_ide/launch.json'
        launch=json.loads(launch_path.read_text(encoding='utf-8'))
        profile=json.loads((ROOT/'firmware/r5/ax02a/launch_first_wait.json').read_text(encoding='utf-8'))['configurations'][0]
        profile['name']=LAUNCH
        profile['targetSetup']['zuInitialization']['usingFSBL']['fsblFile']='${workspaceFolder}/eth02_platform/export/eth02_platform/sw/boot/fsbl.elf'
        profile['targetSetup']['downloadElf'][0]['elfFile']='${workspaceFolder}/eth02_runtime/build/eth02_runtime.elf'
        launch['configurations']=[x for x in launch['configurations'] if x['name']!=LAUNCH]+[profile]
        launch_path.write_text(json.dumps(launch,indent=2)+'\n',encoding='utf-8')
        candidate=runtime_candidate(WS,APP,BUILD)
        (WS/'runtime_candidate.json').write_text(json.dumps(candidate,indent=2)+'\n',encoding='utf-8')
        (WS/'startup_validation.json').write_text(json.dumps(check_startup(),indent=2)+'\n',encoding='utf-8')
    finally:vitis.dispose()


if __name__=='__main__':
    if '--check-startup' in sys.argv:print(json.dumps(check_startup(),indent=2))
    else:
        build('--resume' in sys.argv)
        print('ETH02_BUILD_PASS')
