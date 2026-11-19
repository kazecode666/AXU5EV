"""Offline motor-control R5 build against an explicit matching XSA. Never connects.

vitis.bat -s scripts/motor_control_build.py
python scripts/motor_control_build.py --check-startup
MOTOR_CONTROL_CONFIG selects a SELFTEST/REAL candidate or a legacy workspace.
"""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import zipfile
from xml.etree import ElementTree
from ax02a_build_r5 import check_startup as passive_startup
from ax03b3_build import initialized_word
from ax02a_build_ttc_characterize import symbols

ROOT=Path(__file__).resolve().parents[1]
C=json.loads(Path(os.environ.get('MOTOR_CONTROL_CONFIG',ROOT/'firmware/r5/motor_control/build_config.json')).read_text(encoding='utf-8-sig'))
WS=(ROOT/C['workspace']).resolve()
XSA=(ROOT/C['xsa']).resolve()
PROFILE=C.get('profile','Legacy')
if PROFILE not in ('Legacy','SELFTEST','REAL'):
    raise ValueError('Motor-control profile must be Legacy, SELFTEST or REAL')
AX04B=PROFILE!='Legacy'
APP='ax04b_realtime' if AX04B else 'motor_control_observer'
PLATFORM='ax04b_platform' if AX04B else 'motor_control_platform'
LAUNCH='ax04b_realtime_manual' if AX04B else 'motor_control_manual'
APP_ID=int(C['application_id'],0) if AX04B else None
RTL_MODE={'SELFTEST':1,'REAL':2}
IRQ_STACK_BYTES=0x4000
GENERATED_R5=(ROOT/C['generated_r5']).resolve() if AX04B else None
MODEL_VERSION=C['model_version'] if AX04B else None


def ax04b_reused_hardware(files,prepare):
    """Copy only the explicitly selected PL bundle into the new candidate."""
    source=(ROOT/C['hardware_source']).resolve()
    if not source.is_relative_to(ROOT/'.runtime/experiment/ax04b') or source==XSA.parent:
        raise ValueError('The reused hardware must be in its original AX04B candidate')
    for dest in files:
        original=source/dest.name
        if not original.is_file():
            raise ValueError('Missing original PL artifact: '+str(original))
        if prepare and not dest.exists():
            dest.parent.mkdir(parents=True,exist_ok=True)
            with original.open('rb') as inp, dest.open('xb') as out:
                shutil.copyfileobj(inp,out)
        if dest.read_bytes()!=original.read_bytes():
            raise ValueError('Candidate PL artifact differs from its source: '+dest.name)
    return source


def ax04b_hardware_set(prepare=False):
    """Require one Vivado candidate and compare the actual embedded bit."""
    bit=(ROOT/C['bitstream']).resolve()
    ltx=(ROOT/C['ltx']).resolve()
    stem=f'ax04b_{PROFILE.lower()}'
    base=ROOT/'.runtime/experiment/ax04b'
    if not XSA.is_relative_to(base.resolve()) or WS.parent!=XSA.parent.parent:
        raise ValueError('AX04B hardware and workspace must share one isolated candidate directory')
    if (XSA.name,bit.name,ltx.name)!=(stem+'.xsa',stem+'.bit',stem+'.ltx'):
        raise ValueError('Requested Vivado bundle does not match the chosen profile')
    if bit.parent!=XSA.parent or ltx.parent!=XSA.parent:
        raise ValueError('The XSA, bit and ltx must be from the same Vivado build')
    marker=XSA.parent/'ax04b_build_profile.txt'
    source=ax04b_reused_hardware((XSA,bit,ltx,marker),prepare)
    if marker.read_text().strip()!=PROFILE:
        raise ValueError('Vivado integrated another profile')
    debug=json.loads(ltx.read_text(encoding='utf-8'))['ltx_root']['ltx_data']
    ila={core['name'].rsplit('/',1)[-1]:core
         for probe_set in debug for core in probe_set['debug_cores'] if core['type']=='ILA_V3'}
    if set(ila)!={'realtime_ila'}:
        raise ValueError('Expected one combined realtime and PWM probe core')
    pins={pin['name']:pin for pin in ila['realtime_ila']['pins']}
    widths={'probe0':6,'probe1':32,'probe2':32,'probe3':128}
    if pins.keys()!=widths.keys():
        raise ValueError('Routed LTX probe set differs from the AX04B profile')
    for name,width in widths.items():
        pin=pins[name]
        if sorted((int(pin['leftIndex']),int(pin['rightIndex'])))!=[0,width-1]:
            raise ValueError('Routed LTX has an unexpected AX04B observation bus width: '+name)
    with zipfile.ZipFile(XSA) as archive:
        bits=[name for name in archive.namelist() if name.endswith('.bit')]
        if len(bits)!=1 or archive.read(bits[0])!=bit.read_bytes():
            raise ValueError('XSA embedded bit differs from the selected bitstream')
        sysdef=ElementTree.fromstring(archive.read('sysdef.xml'))
        if sysdef.find('SYSTEMINFO').get('PART')!='xczu5ev-sfvc784-2-i':
            raise ValueError('Unexpected FPGA part in XSA')
        hwh=ElementTree.fromstring(archive.read('design_1.hwh'))
        peripherals=hwh.findall(".//MODULE[@INSTANCE='ax04b_realtime_0']")
        if len(peripherals)!=1:
            raise ValueError('The XSA lacks the realtime AXI slave')
        irq=peripherals[0].find("./PORTS/PORT[@NAME='irq_o']")
        if irq is None or irq.get('SIGIS')!='INTERRUPT' or irq.get('SENSITIVITY')!='LEVEL_HIGH':
            raise ValueError('XSA realtime IRQ must be declared active-high level')
        modules={module.get('INSTANCE'):module for module in hwh.findall('.//MODULE')}
        test=str(int(PROFILE=='SELFTEST'))
        settings={'ax04b_realtime_0':{'SELFTEST':test},
                  'adc_observer_0':{'TEST_INPUT':test,'TEST_ABZ':test},
                  'realtime_ila':{'C_DATA_DEPTH':'8192','C_NUM_OF_PROBES':str(len(widths))}}
        for instance,expected in settings.items():
            observed={param.get('NAME'):param.get('VALUE')
                      for param in modules[instance].findall('./PARAMETERS/PARAMETER')}
            if any(observed.get(name)!=value for name,value in expected.items()):
                raise ValueError('XSA parameters disagree with the chosen profile: '+instance)
    return bit,ltx,source


def ax04b_bsp():
    """Validate the BSP's address and the R5 domain's interrupt mapping."""
    platform=WS/PLATFORM
    p=(platform/'export'/PLATFORM/'sw/r5_standalone/include/xparameters.h').read_text()

    def unique_macro(component,field):
        matches=re.findall(rf'^#define\s+(XPAR_{component}\w*_{field})\s+(0x[0-9a-fA-F]+)',p,re.M)
        values={int(value,16) for _,value in matches}
        if len(values)!=1:
            raise ValueError(f'Expected one actual BSP {component} {field} value')
        return values.pop(),matches[0][0]

    base,base_macro=unique_macro('AX04B_REALTIME','BASEADDR')
    diag_base,diag_macro=unique_macro('ADC_OBSERVER','BASEADDR')
    gic_base,_=unique_macro('XSCUGIC','BASEADDR')
    # Vitis emits only address macros for this generic RTL module. The R5
    # BSP's pruned device tree resolves the XSA fabric IRQ through its GIC.
    dts=platform/'psu_cortexr5_0/r5_standalone/bsp/hw_artifacts/psu_cortexr5_0_baremetal.dts'
    tree=dts.read_text(encoding='utf-8')

    nodes=dict(re.findall(r'(?m)^\s*([A-Za-z0-9_]+):[^\n{}]+\{([^{}]+)\};',tree))

    def named_node(name):
        key=f'xlnx,name = "{name}";'
        labels=[label for label,body in nodes.items() if key in body]
        if len(labels)!=1:
            raise ValueError('Missing unique R5 domain device tree node '+name)
        return labels[0]

    def cells(label,property_name):
        match=re.search(rf'^\s*{re.escape(property_name)}\s*=\s*<([^>]+)>;',nodes[label],re.M)
        if not match:
            raise ValueError(f'Missing R5 device tree property {label}/{property_name}')
        return match[1].split()

    peripheral=named_node('ax04b_realtime_0')
    kind,index,trigger=map(lambda item:int(item,0),cells(peripheral,'interrupts'))
    parent=cells(peripheral,'interrupt-parent')
    table=[int(item,0) for item in cells(peripheral,'reg')]
    test_source=[int(item,0) for item in cells(peripheral,'xlnx,selftest')]
    gic=named_node('psu_rcpu_gic')
    gic_table=[int(item,0) for item in cells(gic,'reg')]
    if len(parent)==1 and 'compatible = "interrupt-multiplex";' in nodes[parent[0].lstrip('&')]:
        parent=cells(parent[0].lstrip('&'),'interrupt-parent')
    if (kind,trigger)!=(0,4) or parent!=['&'+gic] or gic_table[1]!=gic_base:
        raise ValueError('AX04B IRQ is not an active-high SPI at the R5 GIC')
    if table!=[0,base,0,0x1000] or test_source!=[int(PROFILE=='SELFTEST')]:
        raise ValueError('R5 device tree address or test source differs from AX04B profile')
    # A GIC SPI device-tree index excludes the 32 SGI and PPI IDs.
    irq=index+32
    if base!=0x80002000 or diag_base!=0x80000000 or not 32<=irq<=1019:
        raise ValueError('BSP map disagrees with the AX04B register contract')
    return dict(base=base,base_macro=base_macro,diag_base=diag_base,diag_macro=diag_macro,
                irq=irq,irq_sdt=(trigger<<12)|index,irq_source=dts.as_posix(),
                gic_base=gic_base,irq_trigger='high_level')


def ax04b_sources():
    """Use the five actual compilation units from the selected model export."""
    model='AXU5EV_Motor_Control_System'
    names=[model+'.c',model+'_data.c','rtGetInf.c','rtGetNaN.c','rt_nonfinite.c']
    if not GENERATED_R5.is_relative_to(ROOT/'generated/experiment'):
        raise ValueError('Expected a versioned experiment model export')
    sources=[GENERATED_R5/name for name in names]
    sources+=sorted(GENERATED_R5.glob('*.h'))
    header=(GENERATED_R5/(model+'.h')).read_text(encoding='utf-8')
    version=re.search(r'^ \* Model version\s+: (\d+\.\d+)\s*$',header,re.M)
    if (not version or version[1]!=MODEL_VERSION or f"model '{model}'" not in header
            or 'ARM Compatible->ARM Cortex-R' not in header or 'ert.tlc' not in header):
        raise ValueError(f'Expected Cortex-R ERT export of {model} v{MODEL_VERSION}')
    app_sources=ROOT/'firmware/r5/motor_control/ax04b'
    sources+=sorted(p for p in app_sources.glob('*') if p.suffix in ('.c','.h'))
    if not all(s.is_file() for s in sources) or not any(s.parent==app_sources and s.suffix=='.c' for s in sources):
        raise ValueError('Missing AX04B model or R5 binding source')
    if len({s.name for s in sources})!=len(sources):
        raise ValueError('AX04B import contains duplicate source names')
    return sources


def ax04b_check_startup():
    bit,ltx,hardware_source=ax04b_hardware_set()
    r=passive_startup(WS,0,PLATFORM,APP,LAUNCH)
    bsp=ax04b_bsp()
    elf=WS/APP/'build'/(APP+'.elf')
    mapping=elf.with_suffix('.map')
    platform=WS/PLATFORM
    if 'export=SUCCESS' not in (platform/'export/.buildstatus').read_text():
        raise ValueError('Vitis platform export is incomplete')
    exported_xsa=platform/'export'/PLATFORM/'hw'/XSA.name
    if exported_xsa.read_bytes()!=XSA.read_bytes():
        raise ValueError('Vitis exported platform XSA differs from the selected Vivado build')
    for key,value in {'application_id':APP_ID,'mmio_base':bsp['base'],'diag_base':bsp['diag_base'],
                      'fabric_irq':bsp['irq'],'build_mode':RTL_MODE[PROFILE]}.items():
        if initialized_word(elf,'ax04b_'+key)!=value:
            raise ValueError('ELF identity/binding mismatch: '+key)
    linked=symbols(elf)
    required={'PL_Frame_IRQ','Service_Request','AXU5EV_Motor_Control_System_initialize',
              'XScuGic_InterruptHandler','_irq_stack_end','__irq_stack'}
    if not required.issubset(linked):
        raise ValueError('ELF missing model, IRQ or IRQ stack symbols: '+str(sorted(required-linked.keys())))
    irq_stack=linked['__irq_stack']['address']-linked['_irq_stack_end']['address']
    if irq_stack!=IRQ_STACK_BYTES or not mapping.is_file():
        raise ValueError('Expected 16 KiB IRQ stack and a matching linker map')
    sources=ax04b_sources()
    loaded_objects=set(re.findall(r'^LOAD[^\n]*[\\/]([^\\/\s]+\.obj)\s*$',
                                  mapping.read_text(),re.M))
    for source in sources:
        imported=WS/APP/source.name
        if not imported.is_file() or imported.read_bytes()!=source.read_bytes():
            raise ValueError('Vitis imported source differs from selected source: '+source.name)
        if source.suffix=='.c' and source.name+'.obj' not in loaded_objects:
            raise ValueError('Selected translation unit is absent from linker map: '+source.name)
    psu_init=platform/'hw/sdt/psu_init.tcl'
    psu=psu_init.read_text()
    for name in ('psu_ps_pl_isolation_removal','psu_ps_pl_reset_config'):
        if f'proc {name} {{}}' not in psu:
            raise ValueError('Missing matching PS initialization procedure: '+name)
    r.update(profile=PROFILE,application_id=f'0x{APP_ID:08x}',build_mode=RTL_MODE[PROFILE],
             model_version=MODEL_VERSION,generated_r5=GENERATED_R5.relative_to(ROOT).as_posix(),
             sources_match=True,linked_sources=[s.name for s in sources if s.suffix=='.c'],
             workspace=WS.as_posix(),elf=elf.as_posix(),map=mapping.as_posix(),
             bitstream=bit.as_posix(),ltx=ltx.as_posix(),xsa=XSA.as_posix(),
             hardware_source=hardware_source.as_posix(),matching_reused_hardware=True,
             exported_xsa=exported_xsa.as_posix(),
             psu_init=psu_init.as_posix(),matching_embedded_bit=True,
             bsp=bsp,irq_stack_bytes=irq_stack,arm_execution='NOT_RUN',
             board_selftest='NOT_RUN',real_io='NOT_RUN',power_motion='NOT_RUN',
             irq_commit_latency_measurement='NOT_RUN')
    return r


def ax04b_irq_stack():
    linker=WS/APP/'src/lscript.ld'
    text=linker.read_text()
    text,count=re.subn(r'^(_IRQ_STACK_SIZE\s*=\s*DEFINED\(_IRQ_STACK_SIZE\)\s*\?\s*_IRQ_STACK_SIZE\s*:\s*)\w+;',
                       rf'\g<1>0x{IRQ_STACK_BYTES:x};',text,flags=re.M)
    if count!=1:
        raise ValueError('Unexpected Vitis IRQ-stack linker symbol')
    linker.write_text(text,encoding='utf-8')

def bsp_address():
    p=(WS/PLATFORM/'export'/PLATFORM/'sw/r5_standalone/include/xparameters.h').read_text()
    matches=re.findall(r'^#define\s+(XPAR_\w*(?:ADC_OBSERVER|AX03B3)\w*_BASEADDR)\s+(0x[0-9a-fA-F]+)',p,re.M)
    values={int(v,16) for _,v in matches}
    if len(values)!=1:raise ValueError('Expected one actual BSP observer base')
    return values.pop(),matches[0][0]

def check_startup():
    if AX04B:
        return ax04b_check_startup()
    r=passive_startup(WS,0,PLATFORM,APP,LAUNCH)
    base,macro=bsp_address()
    elf=WS/APP/'build'/(APP+'.elf')
    if initialized_word(elf,'motor_control_application_id')!=0x4d435401:raise ValueError('Application ID')
    if initialized_word(elf,'motor_control_mmio_base')!=base:raise ValueError('BSP address mismatch')
    with zipfile.ZipFile(XSA) as z:
        if len([n for n in z.namelist() if n.endswith('.bit')])!=1:raise ValueError('Missing included bit')
    for key in ['bitstream','ltx']:
        if not (ROOT/C[key]).is_file():raise ValueError('Missing '+key)
    r.update(workspace=WS.as_posix(),xsa=XSA.as_posix(),elf=elf.as_posix(),
             observer_base=f'0x{base:08x}',observer_macro=macro,board='NOT_RUN',
             sample_service_timing='NOT_RUN',physical_link_verified=0)
    return r

def build(resume):
    if (WS/'startup_validation.json').exists():raise ValueError('Completed workspace preserved')
    if WS.exists() and not resume:raise ValueError('Use a new workspace; --resume only for this unfinished build')
    if AX04B:
        sources=ax04b_sources()
        ax04b_hardware_set(prepare=True)
    else:
        sources=[ROOT/'firmware/r5/motor_control/main.c']+[ROOT/'firmware/r5/encoder_feedback'/n for n in ('numeric_adapter.c','numeric_adapter.h')]
        sources.append(ROOT/'generated/encoder/encoder_test_scale.h')
        sources+=sorted(p for p in (ROOT/'generated/encoder/feedback_c').glob('*') if p.suffix in ('.h','.c'))
        if not any(p.name=='encoder_position_speed.c' for p in sources):raise ValueError('Generate the software numerical C first')
    import vitis
    client=vitis.create_client()
    try:
        client.set_workspace(str(WS))
        if resume:platform=client.get_component(name=PLATFORM)
        else:platform=client.create_platform_component(name=PLATFORM,hw_design=str(XSA),
            cpu='psu_cortexr5_0',os='standalone',domain_name='r5_standalone',
            no_boot_bsp=False,fsbl_target='psu_cortexa53_0',generate_dtb=False,compiler='gcc')
        if platform.build()!=0:raise RuntimeError('Platform build failed')
        inputs=WS/'inputs';inputs.mkdir(exist_ok=True)
        if AX04B:
            bsp=ax04b_bsp()
            header=inputs/'ax04b_bsp.h'
            header.write_text('#pragma once\n#include "xparameters.h"\n'
                              f'#define AX04B_MMIO_BASE {bsp["base_macro"]}\n'
                              f'#define AX04B_DIAG_BASE {bsp["diag_macro"]}\n'
                              f'#define AX04B_FABRIC_IRQ_SDT 0x{bsp["irq_sdt"]:x}U\n'
                              f'#define AX04B_FABRIC_IRQ {bsp["irq"]}U\n'
                              f'#define AX04B_APPLICATION_ID 0x{APP_ID:08x}U\n'
                              f'#define AX04B_BUILD_MODE {RTL_MODE[PROFILE]}U\n',encoding='utf-8')
        else:
            _,macro=bsp_address()
            header=inputs/'encoder_feedback_hw.h'
            header.write_text('#include "xparameters.h"\n#define ENCODER_FEEDBACK_BASEADDR '+macro+'\n',encoding='utf-8')
        sources.append(header)
        if (WS/APP).exists():
            app=client.get_component(name=APP)
            for s in sources:shutil.copyfile(s,WS/APP/s.name)
        else:
            xpfm=WS/PLATFORM/'export'/PLATFORM/(PLATFORM+'.xpfm')
            app=client.create_app_component(name=APP,platform=str(xpfm),domain='r5_standalone',template='empty_application')
            for s in sources:app.import_files(from_loc=str(s.parent),files=[s.name])
        app.set_app_config(key='USER_COMPILE_OPTIMIZATION_LEVEL',values='-O2')
        flags='-mcpu=cortex-r5 -mfpu=vfpv3-d16 -mfloat-abi=hard'
        if AX04B:
            flags+=' -fno-fast-math -ffp-contract=off -fstack-usage'
            app.set_app_config(key='USER_LINK_LIBRARIES',values=['m'])
        app.set_app_config(key='USER_COMPILE_OTHER_FLAGS',values=flags)
        app.set_app_config(key='USER_LINK_OTHER_FLAGS',values=f'-Wl,-Map={APP}.map')
        ld=app.get_ld_script();ld.set_stack_size('0x10000');ld.set_heap_size('0x4000')
        if AX04B:
            ax04b_irq_stack()
        if app.build()!=0:raise RuntimeError('Motor-control R5 build failed')
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
    else:build(args.resume);print('MOTOR_CONTROL_R5_BUILD_PASS')
