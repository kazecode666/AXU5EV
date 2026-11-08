"""Offline PWM configuration/observation build. No target connection.

vitis.bat -s scripts/pwm_adc_build.py
python scripts/pwm_adc_build.py --check-startup
PWM_ADC_CONFIG selects a new hardware/workspace configuration.
"""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import zipfile
from ax02a_build_r5 import check_startup as passive_startup
from ax03b3_build import initialized_word

ROOT=Path(__file__).resolve().parents[1]
C=json.loads(Path(os.environ.get('PWM_ADC_CONFIG',ROOT/'firmware/r5/pwm_adc/build_config.json')).read_text(encoding='utf-8-sig'))
WS=(ROOT/C['workspace']).resolve()
XSA=(ROOT/C['xsa']).resolve()
APP='pwm_adc_observer'
PLATFORM='pwm_adc_platform'
LAUNCH='pwm_adc_manual'

def bsp_address(kind='PWM_CONTROL|PWM_CONFIG'):
    p=(WS/PLATFORM/'export'/PLATFORM/'sw/r5_standalone/include/xparameters.h').read_text()
    matches=re.findall(r'^#define\s+(XPAR_\w*(?:'+kind+r')\w*_BASEADDR)\s+(0x[0-9a-fA-F]+)',p,re.M)
    values={int(v,16) for _,v in matches}
    if len(values)!=1:raise ValueError('Expected one actual BSP PWM base')
    return values.pop(),matches[0][0]

def check_startup():
    r=passive_startup(WS,0,PLATFORM,APP,LAUNCH)
    base,macro=bsp_address()
    elf=WS/APP/'build'/(APP+'.elf')
    if initialized_word(elf,'pwm_adc_application_id')!=0x50574101:raise ValueError('Application ID')
    if initialized_word(elf,'pwm_adc_mmio_base')!=base:raise ValueError('BSP address mismatch')
    with zipfile.ZipFile(XSA) as z:
        if len([n for n in z.namelist() if n.endswith('.bit')])!=1:raise ValueError('Missing included bit')
    for key in ['bitstream','ltx']:
        if not (ROOT/C[key]).is_file():raise ValueError('Missing '+key)
    r.update(workspace=WS.as_posix(),xsa=XSA.as_posix(),elf=elf.as_posix(),
             pwm_base=f'0x{base:08x}',pwm_macro=macro,board='NOT_RUN',external_pwm='PENDING_INTERNAL_ILA_ONLY')
    return r

def build(resume):
    if (WS/'startup_validation.json').exists():raise ValueError('Completed workspace preserved')
    if WS.exists() and not resume:raise ValueError('Use a new workspace; --resume only for this unfinished build')
    import vitis
    client=vitis.create_client()
    try:
        client.set_workspace(str(WS))
        if resume:platform=client.get_component(name=PLATFORM)
        else:platform=client.create_platform_component(name=PLATFORM,hw_design=str(XSA),
            cpu='psu_cortexr5_0',os='standalone',domain_name='r5_standalone',
            no_boot_bsp=False,fsbl_target='psu_cortexa53_0',generate_dtb=False,compiler='gcc')
        if platform.build()!=0:raise RuntimeError('Platform build failed')
        base,macro=bsp_address()
        inputs=WS/'inputs';inputs.mkdir(exist_ok=True)
        adc_base,adc_macro=bsp_address('ADC_OBSERVER|AX03B3')
        (inputs/'pwm_adc_hw.h').write_text('#include "xparameters.h"\n#define PWM_ADC_BASEADDR '+macro+'\n#define ADC_OBSERVER_BASEADDR '+adc_macro+'\n',encoding='utf-8')
        sources=[ROOT/'firmware/r5/pwm_adc/main.c',inputs/'pwm_adc_hw.h']
        if (WS/APP).exists():
            app=client.get_component(name=APP)
            for s in sources:shutil.copyfile(s,WS/APP/s.name)
        else:
            xpfm=WS/PLATFORM/'export'/PLATFORM/(PLATFORM+'.xpfm')
            app=client.create_app_component(name=APP,platform=str(xpfm),domain='r5_standalone',template='empty_application')
            for s in sources:app.import_files(from_loc=str(s.parent),files=[s.name])
        app.set_app_config(key='USER_COMPILE_OPTIMIZATION_LEVEL',values='-O2')
        app.set_app_config(key='USER_COMPILE_OTHER_FLAGS',values='-mcpu=cortex-r5 -mfpu=vfpv3-d16 -mfloat-abi=hard')
        app.set_app_config(key='USER_LINK_OTHER_FLAGS',values='-Wl,-Map=pwm_adc_observer.map')
        ld=app.get_ld_script();ld.set_stack_size('0x10000');ld.set_heap_size('0x4000')
        if app.build()!=0:raise RuntimeError('PWM R5 build failed')
        (WS/APP/'build/.buildstatus').write_text('hw=SUCCESS\n',encoding='utf-8')
        launch_path=WS/APP/'_ide/launch.json'
        launch=json.loads(launch_path.read_text())
        p=json.loads((ROOT/'firmware/r5/ax02a/launch_first_wait.json').read_text())['configurations'][0]
        p['name']=LAUNCH
        p['targetSetup']['zuInitialization']['usingFSBL']['fsblFile']='${workspaceFolder}/'+PLATFORM+'/export/'+PLATFORM+'/sw/boot/fsbl.elf'
        p['targetSetup']['downloadElf'][0]['elfFile']='${workspaceFolder}/'+APP+'/build/'+APP+'.elf'
        launch['configurations']=[p]
        launch_path.write_text(json.dumps(launch,indent=2)+'\n',encoding='utf-8')
        (WS/'startup_validation.json').write_text(json.dumps(check_startup(),indent=2)+'\n',encoding='utf-8')
    finally:vitis.dispose()

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--resume',action='store_true')
    parser.add_argument('--check-startup',action='store_true')
    args=parser.parse_args()
    if args.check_startup:print(json.dumps(check_startup(),indent=2))
    else:build(args.resume);print('PWM_ADC_R5_BUILD_PASS')
