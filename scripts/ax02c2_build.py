"""Native Vitis C2 Runtime/AXI/PL application build; file-only startup inspection."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
from ax02a_build_r5 import check_startup as passive_startup
from ax02a_build_ttc_characterize import symbols
from ax02c_build import initialized_word
from eth01_lwip_overlay import prepare

ROOT=Path(__file__).resolve().parents[1]
C=json.loads(Path(os.environ.get('AX02C2_CONFIG',ROOT/'firmware/r5/ax02c2/build_config.json')).read_text(encoding='utf-8-sig'))
OUT=(ROOT/C['output']).resolve();WS=(ROOT/C['workspace']).resolve()
XSA=(ROOT/C['xsa']).resolve();BIT=(ROOT/C['bitstream']).resolve()
APP='ax02c2_runtime';PLATFORM='ax02c2_platform';LAUNCH='ax02c2_runtime_manual';BUILD=0x43324301


def bsp_base():
    include=WS/PLATFORM/'export'/PLATFORM/'sw/r5_standalone/include'
    params=(include/'xparameters.h').read_text(encoding='utf-8')
    bases=re.findall(r'^#define\s+(XPAR_\w*FOC\w*_BASEADDR)\s+(0x[0-9a-fA-F]+)',params,re.M)
    values={int(v,16) for _,v in bases}
    if len(values)!=1 or not 0x80000000<=next(iter(values))<=0xbfffffff:
        raise ValueError('expected one actual FOC base in BSP Strongly Ordered PL region')
    return values.pop(),bases[0][0]


def check_startup():
    result=passive_startup(WS,0,PLATFORM,APP,LAUNCH)
    if 'export=SUCCESS' not in (WS/PLATFORM/'export/.buildstatus').read_text():
        raise ValueError('platform export is not built')
    elf=WS/APP/'build'/(APP+'.elf');base,macro=bsp_base();syms=symbols(elf)
    if initialized_word(elf,'ax02c2_application_id')!=BUILD or initialized_word(elf,'ax02c2_mmio_base')!=base:
        raise ValueError('wrong C2 ELF identity or MMIO base')
    if not all(n in syms for n in ['AXU5EV_R5_Runtime_step','ax02c2_replay','Eth02Execute','emac_bd_space','_heap','_stack']):
        raise ValueError('missing actual Runtime/PL/network application symbols')
    if any(n in syms for n in ['ax02a_timing_prepare','ax02a_replay']):
        raise ValueError('C2 must not link the independent TTC replay scheduler')
    for name in ['emac_bd_space','_heap','_stack']:
        if syms[name]['address']+syms[name]['bytes']>=0x10000000:raise ValueError('ELF data overlaps replay DDR')
    include=WS/PLATFORM/'export'/PLATFORM/'sw/r5_standalone/include'
    params=(include/'xparameters.h').read_text();timer=(include/'xtimer_config.h').read_text()
    if '#define XPAR_XEMACPS_0_BASEADDR 0xff0e0000' not in params:raise ValueError('matching GEM3 missing')
    if not all(x in timer for x in ['XTIMER_NO_TICK_TIMER','XTIMER_IS_DEFAULT_TIMER','XPAR_CPU_CORE_CLOCK_FREQ_HZ/64']):
        raise ValueError('expected BSP no-IRQ PMU CPU/64 timestamp timer')
    if 'LENGTH = 0xFF00000' not in (WS/APP/'src/lscript.ld').read_text():raise ValueError('ELF DDR boundary changed')
    result.update(workspace=WS.as_posix(),platform=PLATFORM,application_name=APP,build_id=hex(BUILD),
        xsa=XSA.as_posix(),bitstream=BIT.as_posix(),elf=elf.as_posix(),base_address=hex(base),base_macro=macro,
        symbols={n:syms[n] for n in ['emac_bd_space','_heap','_stack','AXU5EV_R5_Runtime_step','ax02c2_replay']},
        runtime_scheduler='PL complete5000-clock frames / R5 polling; no TTC IRQ',
        timestamp='BSP PMU CPU/64; actual COUNTS_PER_SECOND exported in run.json',
        memory_attribute='BSP PL region 0x80000000..0xbfffffff Strongly Ordered',board='NOT_RUN')
    return result


def build(resume=False,platform_only=False):
    if (WS/'startup_validation.json').exists():raise ValueError('verified workspace preserved; choose a new workspace')
    if WS.exists() and not resume:raise ValueError('existing workspace preserved; resume only this unfinished build')
    repo=prepare(ROOT,OUT)
    import vitis
    client=vitis.create_client()
    try:
        client.set_workspace(str(WS));client.add_embedded_sw_repo(level='LOCAL',path=str(repo))
        if resume:p=client.get_component(name=PLATFORM)
        else:p=client.create_platform_component(name=PLATFORM,hw_design=str(XSA),cpu='psu_cortexr5_0',
            os='standalone',domain_name='r5_standalone',no_boot_bsp=False,fsbl_target='psu_cortexa53_0',generate_dtb=False,compiler='gcc')
        marker=WS/PLATFORM/'export/.buildstatus'
        if not marker.exists() or 'export=SUCCESS' not in marker.read_text():
            d=p.get_domain('r5_standalone');d.set_lib('lwip220')
            d.set_config(option='lib',param='lwip220_tcp_wnd',value='8192',lib_name='lwip220')
            d.set_config(option='lib',param='lwip220_no_sys_no_timers',value='false',lib_name='lwip220')
            if p.build()!=0:raise RuntimeError('platform build failed')
        if platform_only:
            print('AX02C2_PLATFORM_BUILD_COMPLETE');return
        generated=(ROOT/C['generated']).resolve()
        files=list(generated.glob('*.h'))+[p for p in generated.glob('*.c') if p.name!='ert_main.c']
        files += [ROOT/'integration/r5_host'/n for n in ['ax01b_r5_bridge.c','ax01b_r5_bridge.h']]
        files += [ROOT/'firmware/r5/ax02a'/n for n in ['postprocess.c','postprocess.h','replay_runner.h']]
        files += [ROOT/'firmware/r5/ethernet'/n for n in ['eth_platform.c','eth_protocol.c','eth_protocol.h','eth_service.c','eth_service.h']]
        files += [ROOT/'firmware/r5/ethernet_runtime'/n for n in ['eth02_runtime.c','eth02_runtime.h']]
        files += [ROOT/'firmware/r5/ax02c2'/n for n in ['replay.c','replay.h']]
        files += [ROOT/'firmware/r5/ax02c/ax02c_registers.h',ROOT/'integration/r5_ethernet/eth_model_if.h']
        files += [ROOT/'integration/ax02c2_adapter'/n for n in ['ax02c2_adapter_api.c','ax02c2_adapter_api.h']]
        _,macro=bsp_base();inputs=WS/'inputs';inputs.mkdir(exist_ok=True)
        header=inputs/'ax02c_hw.h';header.write_text('#include "xparameters.h"\n#define AX02C_FOC_BASEADDR '+macro+'\n',encoding='utf-8')
        files.append(header)
        if (WS/APP).exists():app=client.get_component(name=APP)
        else:app=client.create_app_component(name=APP,platform=str(WS/PLATFORM/'export'/PLATFORM/(PLATFORM+'.xpfm')),
                domain='r5_standalone',template='empty_application')
        for source in files:app.import_files(from_loc=str(source.parent),files=[source.name])
        # Keep the two generated models' headers in separate source directories.
        adapter=(ROOT/C['adapter']).resolve()
        for source in adapter.glob('*.h'):app.import_files(from_loc=str(source.parent),files=[source.name],dest_dir_in_cmp='src/adapter')
        adapter_c=[];runtime_c={f.name for f in generated.glob('*.c')}
        for source in adapter.glob('*.c'):
            if source.name=='ert_main.c' or source.name in runtime_c:continue # shared generated runtime utilities already linked once
            app.import_files(from_loc=str(source.parent),files=[source.name],dest_dir_in_cmp='src/adapter')
            adapter_c.append((WS/APP/'src/adapter'/source.name).as_posix())
        app.set_app_config(key='USER_INCLUDE_DIRECTORIES',values=[(WS/APP).as_posix(),(WS/APP/'src/adapter').as_posix()])
        # set_app_config replaces the imported source list; retain every real
        # Runtime/bridge/network/replay source as well as the isolated adapter.
        ordinary_c=[(WS/APP/f.name).as_posix() for f in files if f.suffix=='.c']
        app.set_app_config(key='USER_COMPILE_SOURCES',values=ordinary_c+adapter_c)
        app.set_app_config(key='USER_COMPILE_OPTIMIZATION_LEVEL',values='-O2')
        app.set_app_config(key='USER_COMPILE_OTHER_FLAGS',values='-fno-fast-math -ffp-contract=off -mcpu=cortex-r5 -mfpu=vfpv3-d16 -mfloat-abi=hard -DETH02_RUNTIME -DAX02C2_RUNTIME -DETH_BUILD_ID=0x43324301U')
        app.set_app_config(key='USER_LINK_LIBRARIES',values=['m'])
        app.set_app_config(key='USER_LINK_OTHER_FLAGS',values='-Wl,-Map=ax02c2_runtime.map')
        ld=app.get_ld_script();ld.set_stack_size('0x10000');ld.set_heap_size('0x40000')
        script=WS/APP/'src/lscript.ld';text=script.read_text()
        text=re.sub(r'(psu_r5_ddr_0_memory_0[^\n]*LENGTH\s*=\s*)0x[0-9a-fA-F]+',r'\g<1>0xFF00000',text)
        script.write_text(text,encoding='utf-8')
        if app.build()!=0:raise RuntimeError('C2 R5 application build failed')
        if not (WS/APP/'build'/(APP+'.elf')).is_file():raise RuntimeError('native build produced no ELF')
        launch_path=WS/APP/'_ide/launch.json';launch=json.loads(launch_path.read_text())
        profile=json.loads((ROOT/'firmware/r5/ax02a/launch_first_wait.json').read_text())['configurations'][0]
        profile['name']=LAUNCH
        profile['targetSetup']['zuInitialization']['usingFSBL']['fsblFile']='${workspaceFolder}/'+PLATFORM+'/export/'+PLATFORM+'/sw/boot/fsbl.elf'
        profile['targetSetup']['downloadElf'][0]['elfFile']='${workspaceFolder}/'+APP+'/build/'+APP+'.elf'
        launch['configurations']=[x for x in launch['configurations'] if x['name']!=LAUNCH]+[profile]
        launch_path.write_text(json.dumps(launch,indent=2)+'\n',encoding='utf-8')
        (WS/'startup_validation.json').write_text(json.dumps(check_startup(),indent=2)+'\n',encoding='utf-8')
    finally:vitis.dispose()


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--check-startup',action='store_true')
    p.add_argument('--resume',action='store_true');p.add_argument('--platform-only',action='store_true');a=p.parse_args()
    if a.check_startup:print(json.dumps(check_startup(),indent=2))
    else:
        build(a.resume,a.platform_only)
        print('AX02C2_BUILD_PASS' if not a.platform_only else 'AX02C2_PLATFORM_ONLY')
