"""AX-02C1 Vitis build and existing passive-startup file check; no board client."""
import argparse
import csv
import json
import os
from pathlib import Path
import re
import shutil
import struct
import zipfile
from ax02a_build_r5 import check_startup as passive_startup
from ax02a_build_ttc_characterize import symbols

ROOT=Path(__file__).resolve().parents[1]
CONFIG=Path(os.environ.get('AX02C_CONFIG',ROOT/'firmware/r5/ax02c/build_config.json'))
C=json.loads(CONFIG.read_text(encoding='utf-8-sig'))
WS=(ROOT/C['workspace']).resolve()
XSA=(ROOT/C['xsa']).resolve()
BIT=(ROOT/C['bitstream']).resolve()
APP='ax02c_foc'
PLATFORM='ax02c_platform'
LAUNCH='ax02c_foc_manual'


def vector_header():
    rows=list(csv.DictReader((ROOT/'verification/m3_foc/directed_probe_source_hex.csv').open(newline='')))
    if len(rows)!=17:raise ValueError('C1 uses the existing 17-row directed sequence')
    result=['/* Generated from directed_probe_source_hex.csv integer bit strings; no float conversion. */',
            'static const Ax02cVector ax02c_vectors[AX02C_FRAMES] = {']
    for row in rows:
        n=lambda key:int(row[key],16)
        words=[n('ia'),n('ib'),n('ic'),n('theta_e')&0xffffffff,n('theta_e')>>32,
               n('omega_e')&0xffffffff,n('omega_e')>>32,n('iq_ref'),n('id_ref'),n('PI_Reset_EN'),n('Vdc_V')]
        duty=[n('duty_u_cmd'),n('duty_v_cmd'),n('duty_w_cmd')]
        fmt=lambda values:', '.join(f'0x{x:08x}U' for x in values)
        result.append('    {{'+fmt(words)+'}, {'+fmt(duty)+'}},')
    return '\n'.join(result+['};',''])


def bsp_base():
    include=WS/PLATFORM/'export'/PLATFORM/'sw/r5_standalone/include'
    params=(include/'xparameters.h').read_text(encoding='utf-8')
    bases=re.findall(r'^#define\s+(XPAR_\w*FOC\w*_BASEADDR)\s+(0x[0-9a-fA-F]+)',params,re.M)
    values={int(value,16) for _,value in bases}
    if len(values)!=1:raise ValueError('expected one actual FOC AXI base in BSP xparameters.h')
    base=values.pop()
    if not 0x80000000<=base<=0xbfffffff:raise ValueError('FOC must use BSP Strongly Ordered PL memory region')
    return base,bases[0][0]


def initialized_word(elf,name):
    data=elf.read_bytes();table=symbols(elf);address=table[name]['address']
    h=struct.unpack_from('<16sHHIIIIIHHHHHH',data)
    for i in range(h[10]):
        kind,off,va,pa,filesz,memsz,flags,align=struct.unpack_from('<8I',data,h[5]+i*h[9])
        if kind==1 and va<=address and address+4<=va+filesz:
            return struct.unpack_from('<I',data,off+address-va)[0]
    raise ValueError('initialized ELF marker not in a file-backed segment: '+name)


def check_startup():
    result=passive_startup(WS,0,PLATFORM,APP,LAUNCH)
    marker=(WS/PLATFORM/'export/.buildstatus').read_text(encoding='utf-8')
    if 'export=SUCCESS' not in marker:raise ValueError('platform export build marker is not SUCCESS')
    elf=WS/APP/'build'/(APP+'.elf')
    base,macro=bsp_base()
    if initialized_word(elf,'ax02c_application_id')!=0x43314301:raise ValueError('wrong AX02C application ID')
    if initialized_word(elf,'ax02c_mmio_base')!=base:raise ValueError('ELF MMIO base differs from actual BSP')
    include=WS/PLATFORM/'export'/PLATFORM/'sw/r5_standalone/include'
    timer=(include/'xtimer_config.h').read_text(encoding='utf-8')
    if not all(x in timer for x in ['XTIMER_NO_TICK_TIMER','XTIMER_IS_DEFAULT_TIMER','XPAR_CPU_CORE_CLOCK_FREQ_HZ/64']):
        raise ValueError('expected existing no-IRQ default PMU timer')
    with zipfile.ZipFile(XSA) as xsa:
        bitfiles=[name for name in xsa.namelist() if name.lower().endswith('.bit')]
        initfiles=[name for name in xsa.namelist() if name.endswith('psu_init.tcl')]
        if len(bitfiles)!=1 or not initfiles:raise ValueError('matching XSA must include bitstream and PS init')
    psu_init=WS/PLATFORM/'hw/sdt/psu_init.tcl'
    psu_text=psu_init.read_text(encoding='utf-8')
    if not all('proc '+name+' {}' in psu_text for name in ['psu_ps_pl_isolation_removal','psu_ps_pl_reset_config']):
        raise ValueError('matching generated PS-PL post-load procedures missing')
    reset_data=re.search(r'set psu_ps_pl_reset_config_data \{(.*?)\n\}',psu_text,re.S)
    if not reset_data or 'mask_write' not in reset_data[1]:raise ValueError('generated fabric reset sequence missing')
    if not BIT.is_file() or BIT.stat().st_size==0:raise ValueError('missing integrated bitstream')
    result.update(workspace=WS.as_posix(),platform=PLATFORM,application_name=APP,
                  xsa=XSA.as_posix(),bitstream=BIT.as_posix(),xsa_bit_member=bitfiles[0],
                  elf=elf.as_posix(),base_address=f'0x{base:08x}',base_macro=macro,
                  psu_init=psu_init.as_posix(),
                  postload_reset_data='nonempty generated fabric reset sequence',
                  memory_attribute='BSP startup PL region 0x80000000..0xbfffffff Strongly Ordered',
                  frames=17,board='NOT_RUN',
                  manual_order=['launch A53 FSBL initialization; R5 stops at application entry (stopAtEntry)',
                                'user programs this bitstream without system reset',
                                'user sources matching psu_init.tcl; psu_ps_pl_isolation_removal; psu_ps_pl_reset_config',
                                'user continues R5; UART WAIT; send s once for first MMIO'])
    return result


def build(resume=False):
    if (WS/'startup_validation.json').exists():raise ValueError('verified workspace preserved; choose a new workspace')
    if WS.exists() and not resume:raise ValueError('existing workspace preserved; --resume only for this unfinished build')
    import vitis
    client=vitis.create_client()
    try:
        client.set_workspace(str(WS))
        if resume:p=client.get_component(name=PLATFORM)
        else:p=client.create_platform_component(name=PLATFORM,hw_design=str(XSA),
            cpu='psu_cortexr5_0',os='standalone',domain_name='r5_standalone',
            no_boot_bsp=False,fsbl_target='psu_cortexa53_0',generate_dtb=False,compiler='gcc')
        rc=p.build()
        # The installed 2026.1 API returns SUCCESS=0 before its export status
        # file is published. Final startup inspection checks that marker
        # alongside the actual FSBL/BSP/ELF after the application build.
        if rc!=0:raise RuntimeError('platform build failed')
        base,macro=bsp_base()
        generated=WS/'inputs';generated.mkdir(exist_ok=True)
        (generated/'ax02c_vectors.h').write_text(vector_header(),encoding='utf-8')
        (generated/'ax02c_hw.h').write_text('#include "xparameters.h"\n#define AX02C_FOC_BASEADDR '+macro+'\n',encoding='utf-8')
        sources=[ROOT/'firmware/r5/ax02c/main.c',ROOT/'firmware/r5/ax02c/ax02c_registers.h',
                 generated/'ax02c_vectors.h',generated/'ax02c_hw.h']
        if (WS/APP).exists():
            app=client.get_component(name=APP)
            for source in sources:shutil.copyfile(source,WS/APP/source.name)
        else:
            xpfm=WS/PLATFORM/'export'/PLATFORM/(PLATFORM+'.xpfm')
            app=client.create_app_component(name=APP,platform=str(xpfm),domain='r5_standalone',template='empty_application')
            for source in sources:app.import_files(from_loc=str(source.parent),files=[source.name])
        app.set_app_config(key='USER_COMPILE_OPTIMIZATION_LEVEL',values='-O2')
        app.set_app_config(key='USER_COMPILE_OTHER_FLAGS',values='-mcpu=cortex-r5 -mfpu=vfpv3-d16 -mfloat-abi=hard')
        app.set_app_config(key='USER_LINK_OTHER_FLAGS',values='-Wl,-Map=ax02c_foc.map')
        ld=app.get_ld_script();ld.set_stack_size('0x10000');ld.set_heap_size('0x4000')
        if app.build()!=0:raise RuntimeError('R5 application build failed')
        elf=WS/APP/'build'/(APP+'.elf')
        if not elf.is_file():raise RuntimeError('R5 ELF not generated')
        (WS/APP/'build/.buildstatus').write_text('hw=SUCCESS\n',encoding='utf-8')
        launch_path=WS/APP/'_ide/launch.json'
        launch=json.loads(launch_path.read_text(encoding='utf-8'))
        profile=json.loads((ROOT/'firmware/r5/ax02a/launch_first_wait.json').read_text(encoding='utf-8'))['configurations'][0]
        profile['name']=LAUNCH
        profile['targetSetup']['zuInitialization']['usingFSBL']['fsblFile']='${workspaceFolder}/ax02c_platform/export/ax02c_platform/sw/boot/fsbl.elf'
        profile['targetSetup']['downloadElf'][0]['elfFile']='${workspaceFolder}/ax02c_foc/build/ax02c_foc.elf'
        launch['configurations']=[x for x in launch['configurations'] if x['name']!=LAUNCH]+[profile]
        launch_path.write_text(json.dumps(launch,indent=2)+'\n',encoding='utf-8')
        (WS/'startup_validation.json').write_text(json.dumps(check_startup(),indent=2)+'\n',encoding='utf-8')
    finally:vitis.dispose()


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check-startup',action='store_true')
    parser.add_argument('--resume',action='store_true')
    args=parser.parse_args()
    if args.check_startup:print(json.dumps(check_startup(),indent=2))
    else:
        build(args.resume)
        print('AX02C_BUILD_PASS')
