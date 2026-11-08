"""AX-03B3 current observer: offline Vitis build, no board connection.

Build: vitis.bat -s scripts/ax03b3_build.py
Read existing files only: python scripts/ax03b3_build.py --check-startup
AX03B3_CONFIG may point to a config with a new workspace for a later build.
"""
import argparse
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
CONFIG=Path(os.environ.get('AX03B3_CONFIG',ROOT/'firmware/r5/ax03b3/build_config.json'))
C=json.loads(CONFIG.read_text(encoding='utf-8-sig'))
WS=(ROOT/C['workspace']).resolve()
XSA=(ROOT/C['xsa']).resolve()
BIT=(ROOT/C['bitstream']).resolve()
LTX=(ROOT/C['ltx']).resolve()
APP='ax03b3_adc'
PLATFORM='ax03b3_platform'
LAUNCH='ax03b3_adc_manual'


def initialized_word(elf,name):
    # Existing C1 startup inspection, local here to avoid loading its config.
    data=elf.read_bytes();address=symbols(elf)[name]['address']
    h=struct.unpack_from('<16sHHIIIIIHHHHHH',data)
    for i in range(h[10]):
        kind,off,va,pa,filesz,memsz,flags,align=struct.unpack_from('<8I',data,h[5]+i*h[9])
        if kind==1 and va<=address and address+4<=va+filesz:
            return struct.unpack_from('<I',data,off+address-va)[0]
    raise ValueError('Initialized ELF word not file-backed: '+name)


def bsp_base():
    params=(WS/PLATFORM/'export'/PLATFORM/'sw/r5_standalone/include/xparameters.h').read_text()
    bases=re.findall(r'^#define\s+(XPAR_\w*(?:AX03B3|ADC_OBSERVER)\w*_BASEADDR)\s+(0x[0-9a-fA-F]+)',params,re.M)
    values={int(value,16) for _,value in bases}
    if len(values)!=1:
        raise ValueError('Expected one ADC observer address in actual BSP xparameters.h')
    base=values.pop()
    return base,bases[0][0]


def check_startup():
    result=passive_startup(WS,0,PLATFORM,APP,LAUNCH)
    base,macro=bsp_base()
    elf=WS/APP/'build'/(APP+'.elf')
    if initialized_word(elf,'ax03b3_application_id')!=0x42334101:
        raise ValueError('Wrong ADC observation application')
    if initialized_word(elf,'ax03b3_mmio_base')!=base:
        raise ValueError('Application base differs from actual BSP')
    if 'export=SUCCESS' not in (WS/PLATFORM/'export/.buildstatus').read_text():
        raise ValueError('Platform export did not finish successfully')
    with zipfile.ZipFile(XSA) as archive:
        bit_members=[n for n in archive.namelist() if n.lower().endswith('.bit')]
        if len(bit_members)!=1:
            raise ValueError('Matching XSA must include its bitstream')
    for path in [BIT,LTX]:
        if not path.is_file() or path.stat().st_size==0:
            raise ValueError('Missing hardware output: '+str(path))
    psu_init=WS/PLATFORM/'hw/sdt/psu_init.tcl'
    psu=psu_init.read_text()
    for proc in ['psu_ps_pl_isolation_removal','psu_ps_pl_reset_config']:
        if 'proc '+proc+' {}' not in psu:
            raise ValueError('Missing matching post-load PS procedure: '+proc)
    result.update(workspace=WS.as_posix(),platform=PLATFORM,application_name=APP,
                  xsa=XSA.as_posix(),bitstream=BIT.as_posix(),ltx=LTX.as_posix(),
                  elf=elf.as_posix(),base_address=f'0x{base:08x}',base_macro=macro,
                  psu_init=psu_init.as_posix(),observations=64,board='NOT_RUN',
                  source=C['source'],
                  current_calibration='explicit commands; digital test gain only',
                  manual_order=['A53 FSBL; R5 stopAtEntry',
                                'program this bitstream without another system reset',
                                'matching psu_init: isolation_removal then reset_config',
                                'continue R5; UART WAIT; send s for one 64-row window'])
    return result


def build(resume=False):
    if (WS/'startup_validation.json').exists():
        raise ValueError('Completed workspace preserved; select a new workspace')
    if WS.exists() and not resume:
        raise ValueError('Existing workspace preserved; --resume only continues this unfinished build')
    import vitis
    client=vitis.create_client()
    try:
        client.set_workspace(str(WS))
        if resume:platform=client.get_component(name=PLATFORM)
        else:platform=client.create_platform_component(name=PLATFORM,hw_design=str(XSA),
            cpu='psu_cortexr5_0',os='standalone',domain_name='r5_standalone',
            no_boot_bsp=False,fsbl_target='psu_cortexa53_0',generate_dtb=False,compiler='gcc')
        if platform.build()!=0:
            raise RuntimeError('Platform build failed')
        base,macro=bsp_base()
        generated=WS/'inputs';generated.mkdir(exist_ok=True)
        (generated/'ax03b3_hw.h').write_text('#include "xparameters.h"\n#define AX03B3_ADC_BASEADDR '+macro+'\n#define AX03B3_SOURCE '+json.dumps(C['source'])+'\n',encoding='utf-8')
        sources=[ROOT/'firmware/r5/ax03b3/main.c',generated/'ax03b3_hw.h']
        if (WS/APP).exists():
            app=client.get_component(name=APP)
            for source in sources:shutil.copyfile(source,WS/APP/source.name)
        else:
            xpfm=WS/PLATFORM/'export'/PLATFORM/(PLATFORM+'.xpfm')
            app=client.create_app_component(name=APP,platform=str(xpfm),domain='r5_standalone',template='empty_application')
            for source in sources:app.import_files(from_loc=str(source.parent),files=[source.name])
        app.set_app_config(key='USER_COMPILE_OPTIMIZATION_LEVEL',values='-O2')
        app.set_app_config(key='USER_COMPILE_OTHER_FLAGS',values='-mcpu=cortex-r5 -mfpu=vfpv3-d16 -mfloat-abi=hard')
        app.set_app_config(key='USER_LINK_OTHER_FLAGS',values='-Wl,-Map=ax03b3_adc.map')
        ld=app.get_ld_script();ld.set_stack_size('0x10000');ld.set_heap_size('0x4000')
        if app.build()!=0:
            raise RuntimeError('R5 ADC app build failed')
        (WS/APP/'build/.buildstatus').write_text('hw=SUCCESS\n',encoding='utf-8')
        launch_path=WS/APP/'_ide/launch.json'
        launch=json.loads(launch_path.read_text())
        profile=json.loads((ROOT/'firmware/r5/ax02a/launch_first_wait.json').read_text())['configurations'][0]
        profile['name']=LAUNCH
        profile['targetSetup']['zuInitialization']['usingFSBL']['fsblFile']='${workspaceFolder}/'+PLATFORM+'/export/'+PLATFORM+'/sw/boot/fsbl.elf'
        profile['targetSetup']['downloadElf'][0]['elfFile']='${workspaceFolder}/'+APP+'/build/'+APP+'.elf'
        # This new minimal workspace has one documented manual startup route.
        launch['configurations']=[profile]
        launch_path.write_text(json.dumps(launch,indent=2)+'\n',encoding='utf-8')
        (WS/'startup_validation.json').write_text(json.dumps(check_startup(),indent=2)+'\n',encoding='utf-8')
    finally:
        vitis.dispose()


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--resume',action='store_true')
    parser.add_argument('--check-startup',action='store_true')
    args=parser.parse_args()
    if args.check_startup:print(json.dumps(check_startup(),indent=2))
    else:
        build(args.resume)
        print('AX03B3_BUILD_PASS')
