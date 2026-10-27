"""Vitis 2026.1 Python API entry; offline build only, never connects hardware.

Run with vitis -s scripts/ax02a_build_r5.py. Configuration defaults to
.runtime/ax02a/build_config_a53fsbl.json; AX02A_BUILD_CONFIG may select another JSON.
Standard Python supports --config and --preflight for explicit dependency checks.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import zipfile
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
EXPECTED_PART='xczu5ev-sfvc784-2-i'
WINDOW_START=0x10000000
WINDOW_END=0x14000000
FIRST_LAUNCH='ax02a_first_wait_a53fsbl'


def inspect_fsbl(elf):
    """The 2026.1 GUI initialization route runs this image on A53_0."""
    data=elf.read_bytes()
    if len(data)<64 or data[:7]!=b'\x7fELF\x02\x01\x01':
        raise ValueError('GUI A53_0 initialization requires ELF64 little-endian AArch64 FSBL')
    h=struct.unpack_from('<16sHHIQQQIHHHHHH',data)
    if h[1]!=2:
        raise ValueError('FSBL must be an executable ELF')
    if h[2]!=183:
        raise ValueError('GUI A53_0 initialization requires AArch64 (EM_AARCH64=183) FSBL')
    return dict(processor='psu_cortexa53_0',machine='AArch64',elf_class=64,
                byte_order='little',entry=h[4])


def check_startup(workspace):
    """Read files only: no debugger imports, target discovery or hardware access."""
    platform=workspace/'ax02a_platform'
    domains=json.loads((platform/'vitis-comp.json').read_text(encoding='utf-8'))['configuration']['domains']
    for name,cpu in [('zynqmp_fsbl','psu_cortexa53_0'),('r5_standalone','psu_cortexr5_0')]:
        matches=[d for d in domains if d['name']==name]
        if len(matches)!=1 or matches[0]['processor']!=cpu:
            raise ValueError(f'{name} must target {cpu}')
    fsbl=platform/'export/ax02a_platform/sw/boot/fsbl.elf'
    result=dict(fsbl=inspect_fsbl(fsbl))
    launch=json.loads((workspace/'ax02a_replay/_ide/launch.json').read_text(encoding='utf-8'))
    profiles=[c for c in launch['configurations'] if c['name']==FIRST_LAUNCH]
    if len(profiles)!=1:
        raise ValueError(f'expected one {FIRST_LAUNCH} launch configuration')
    c=profiles[0];s=c['targetSetup'];init=s['zuInitialization']
    if not (c['type']=='tcf-debug' and c['debugType']=='baremetal-zu' and c['request']=='launch'
            and s['resetSystem'] and s['enableRPUSplitMode'] and not s['programDevice']
            and not s['bitstreamFile'] and init['isFsbl'] and init['usingFSBL']['initWithFSBL']
            and init['usingFSBL']['fsblExitSymbol']=='XFsbl_Exit'
            and not init['usingPsuInit']['runPsuInit']):
        raise ValueError('first-wait launch initialization flags differ from the checked route')
    def local_path(value):
        return Path(value.replace('${workspaceFolder}',workspace.as_posix())).resolve()
    if local_path(init['usingFSBL']['fsblFile'])!=fsbl.resolve():
        raise ValueError('launch does not use this platform exported A53 FSBL')
    apps=s['downloadElf']
    if len(apps)!=1 or apps[0]['core']!='psu_cortexr5_0' or not apps[0]['stopAtEntry'] or not apps[0]['resetProcessor']:
        raise ValueError('launch must load only the R5_0 application and stop at entry')
    elf=workspace/'ax02a_replay/build/ax02a_replay.elf'
    if local_path(apps[0]['elfFile'])!=elf.resolve():
        raise ValueError('launch does not use this workspace R5 application')
    result['application']=inspect_elf(elf)
    result['application']['processor']='psu_cortexr5_0'
    result['launch']=FIRST_LAUNCH
    result['status']='OFFLINE_STARTUP_CHECK_PASS'
    return result


def source_files(generated):
    files=[ROOT/'firmware/r5/ax02a'/name for name in
           ['main.c','replay_runner.c','timing.c','replay_runner.h','timing.h']]
    files += [ROOT/'integration/r5_host'/name for name in ['ax01b_r5_bridge.c','ax01b_r5_bridge.h']]
    files += sorted(generated.glob('*.h'))
    files += sorted(f for f in generated.glob('*.c') if f.name!='ert_main.c')
    if not (generated/'AXU5EV_R5_Runtime.c').is_file():
        raise ValueError('missing independently generated Runtime C')
    header=(generated/'AXU5EV_R5_Runtime.h').read_text()
    if 'Embedded hardware selection: ARM Compatible->ARM Cortex-R' not in header:
        raise ValueError('Runtime is not generated for the Cortex-R type assumptions')
    return files


def inspect_elf(elf):
    data=elf.read_bytes()
    if data[:7]!=b'\x7fELF\x01\x01\x01':
        raise ValueError('expected ELF32 little endian')
    h=struct.unpack_from('<16sHHIIIIIHHHHHH',data)
    if h[1]!=2:
        raise ValueError('expected an executable ELF, not a relocatable Runtime object')
    if h[2]!=40:
        raise ValueError('expected EM_ARM (40), not A53 or x86')
    if not h[7]&0x400:
        raise ValueError('ELF does not declare the hard-float ABI')
    segments=[]
    for i in range(h[10]):
        item=struct.unpack_from('<8I',data,h[5]+i*h[9])
        kind,offset,vaddr,paddr,file_size,memory_size,flags,align=item
        if kind==1:
            if paddr<WINDOW_END and paddr+memory_size>WINDOW_START:
                raise ValueError('ELF PT_LOAD overlaps replay DDR windows')
            segments.append(dict(address=paddr,file_bytes=file_size,memory_bytes=memory_size,flags=flags))
    if not segments:raise ValueError('executable ELF has no PT_LOAD segments')
    return dict(machine='ARM',elf_class=32,byte_order='little',entry=h[4],flags=h[7],segments=segments)


def compile_runtime(generated,compiler,output):
    """Real ARM object build with an existing GNU toolchain; no invented BSP."""
    if output.exists():raise ValueError('use a new Runtime object output directory')
    output.mkdir(parents=True)
    flags=['-std=c11','-O2','-g','-fno-fast-math','-ffp-contract=off',
           '-mcpu=cortex-r5','-marm','-mlittle-endian','-mfpu=vfpv3-d16','-mfloat-abi=hard',
           '-I'+str(generated),'-I'+str(ROOT/'integration/r5_host'),'-I'+str(ROOT/'firmware/r5/ax02a')]
    sources=[ROOT/'firmware/r5/ax02a/replay_runner.c',ROOT/'integration/r5_host/ax01b_r5_bridge.c']
    sources += sorted(f for f in generated.glob('*.c') if f.name!='ert_main.c')
    objects=[]
    for source in sources:
        obj=output/(source.stem+'.o')
        subprocess.run([str(compiler),*flags,'-c',str(source),'-o',str(obj)],check=True)
        objects.append(obj)
    suffix='.exe' if os.name=='nt' else ''
    tools=compiler.parent
    library=output/'libax02a_runtime.a'
    subprocess.run([str(tools/('arm-none-eabi-ar'+suffix)),'rcs',str(library),*[str(o) for o in objects]],check=True)
    dump=subprocess.check_output([str(tools/('arm-none-eabi-readelf'+suffix)),'-W','-h','-A','-s',str(library)],text=True)
    if 'Realtime' not in dump or 'VFPv3-D16' not in dump or 'VFP registers' not in dump:
        raise ValueError('Runtime objects do not declare the expected R-profile/FP attributes')
    (output/'arm_attributes.txt').write_text(dump,encoding='utf-8',newline='\n')
    info=dict(status='ARM_RUNTIME_OBJECT_BUILD_PASS',standalone_elf='NOT_BUILT',
        compiler=subprocess.check_output([str(compiler),'--version'],text=True).splitlines()[0],
        flags=flags[:10],objects=[o.name for o in objects],library=str(library))
    (output/'runtime_build.json').write_text(json.dumps(info,indent=2),encoding='utf-8',newline='\n')
    print(json.dumps(info));return


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config',type=Path,default=Path(os.environ.get('AX02A_BUILD_CONFIG',ROOT/'.runtime/ax02a/build_config_a53fsbl.json')))
    parser.add_argument('--preflight',action='store_true')
    parser.add_argument('--check-startup',action='store_true',help='read existing workspace architecture/domain/launch only; no Vitis client or hardware')
    parser.add_argument('--runtime-only',action='store_true',help='cross-compile objects/archive; no platform or ELF claim')
    parser.add_argument('--compiler',type=Path,help='existing arm-none-eabi-gcc for --runtime-only')
    parser.add_argument('--output',type=Path,help='new output directory for --runtime-only')
    args=parser.parse_args()
    config=json.loads(args.config.read_text(encoding='utf-8-sig'))
    xsa=Path(config['xsa']).resolve();generated=Path(config['generated']).resolve()
    workspace=Path(config['workspace']).resolve()
    if args.check_startup:
        print(json.dumps(check_startup(workspace),indent=2));return
    files=source_files(generated)
    if args.runtime_only:
        if not args.compiler or not args.output:
            raise ValueError('--runtime-only requires --compiler and --output')
        compile_runtime(generated,args.compiler.resolve(),args.output.resolve());return
    if not xsa.is_file():
        raise ValueError(f'missing PS-only XSA: {xsa}; install device support and run the Vivado entry first')
    with zipfile.ZipFile(xsa) as archive:
        platform_json=json.loads(archive.read('xsa.json'))
        hwh=next(n for n in archive.namelist() if n.endswith('.hwh'))
        tree=ET.fromstring(archive.read(hwh))
        maps=[e.get('VALUE','') for e in tree.iter('PARAMETER') if e.get('NAME')=='PSU__PROTECTION__SLAVES']
        ddr_ranges=[]
        for text in maps:
            for record in text.split('|'):
                fields=record.split(';')
                if len(fields)==5 and fields[0]=='DDR' and fields[4]=='1':
                    ddr_ranges.append((int(fields[2],16),int(fields[3],16)+1))
        if not any(low<=WINDOW_START and high>=WINDOW_END for low,high in ddr_ranges):
            raise ValueError('XSA does not expose the complete reserved replay DDR window')
    part=platform_json['devices'][0]['part']
    actual=f"{part['device']}-{part['package']}{part['speedGrade']}-{part['tempGrade']}"
    if actual!=EXPECTED_PART:
        raise ValueError(f'XSA device {actual} differs from manual {EXPECTED_PART}')
    compiler=shutil.which('armr5-none-eabi-gcc')
    if compiler is None:
        raise ValueError('armr5-none-eabi-gcc is unavailable in this Vitis environment; embedded R5 compiler required')
    print(subprocess.check_output([compiler,'--version'],text=True).splitlines()[0])
    if args.preflight:
        print('R5_BUILD_PREFLIGHT_PASS');return
    if workspace.exists():
        raise ValueError('use a new workspace; existing work is never reset/deleted')
    import vitis
    client=vitis.create_client()
    try:
        client.set_workspace(str(workspace))
        platform=client.create_platform_component(name='ax02a_platform',hw_design=str(xsa),
            cpu='psu_cortexr5_0',os='standalone',domain_name='r5_standalone',
            no_boot_bsp=False,fsbl_target='psu_cortexa53_0',generate_dtb=False,compiler='gcc')
        platform.build()
        inspect_fsbl(workspace/'ax02a_platform/export/ax02a_platform/sw/boot/fsbl.elf')
        xpfm=client.find_platform_in_repos('ax02a_platform')
        app=client.create_app_component(name='ax02a_replay',platform=xpfm,
            domain='r5_standalone',template='empty_application')
        for file in files:
            app.import_files(from_loc=str(file.parent),files=[file.name])
        app.set_app_config(key='USER_COMPILE_OPTIMIZATION_LEVEL',values='-O2')
        app.set_app_config(key='USER_COMPILE_OTHER_FLAGS',
            values='-fno-fast-math -ffp-contract=off -mcpu=cortex-r5 -mfpu=vfpv3-d16 -mfloat-abi=hard')
        app.set_app_config(key='USER_LINK_LIBRARIES',values=['m'])
        app.set_app_config(key='USER_LINK_OTHER_FLAGS',values='-Wl,-Map=ax02a_replay.map')
        ld=app.get_ld_script();ld.set_stack_size('0x4000');ld.set_heap_size('0x1000')
        # Use BSP's generated TCM/default memory layout, then verify actual ELF.
        # Large buffers use reserved DDR addresses, never bss/TCM arrays.
        app.build()
        elfs=list((workspace/'ax02a_replay').rglob('*.elf'))
        if len(elfs)!=1:raise ValueError(f'expected one target ELF, found {len(elfs)}')
        elf=elfs[0];result=inspect_elf(elf)
        readelf=Path(compiler).with_name('armr5-none-eabi-readelf.exe' if os.name=='nt' else 'armr5-none-eabi-readelf')
        dump=subprocess.check_output([str(readelf),'-W','-h','-l','-A','-s',str(elf)],text=True)
        (workspace/'target_elf.txt').write_text(dump,encoding='utf-8')
        if 'Realtime' not in dump or 'VFPv3-D16' not in dump or 'VFP registers' not in dump:
            raise ValueError('ELF ARM attributes do not identify the expected R-profile and FP ABI')
        if 'AXU5EV_R5_Runtime_step' not in dump:
            raise ValueError('Runtime step symbol absent from target ELF')
        (workspace/'target_build.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
        launch_path=workspace/'ax02a_replay/_ide/launch.json'
        launch=json.loads(launch_path.read_text(encoding='utf-8'))
        manual=json.loads((ROOT/'firmware/r5/ax02a/launch_first_wait.json').read_text(encoding='utf-8'))['configurations'][0]
        if any(c['name']==FIRST_LAUNCH for c in launch['configurations']):
            raise ValueError('manual launch already exists; preserve it rather than overwrite')
        launch['configurations'].append(manual)
        launch_path.write_text(json.dumps(launch,indent=2)+'\n',encoding='utf-8')
        startup=check_startup(workspace)
        (workspace/'startup_validation.json').write_text(json.dumps(startup,indent=2)+'\n',encoding='utf-8')
        print('OFFLINE_STARTUP_CHECK_PASS: A53_0 FSBL -> R5_0 application; passive launch installed')
        print('TARGET_ELF_BUILD_PASS',elf)
        print('NOT_RUN: board boot, DDR window verification, RPU split launch, numeric replay, actual timing')
    finally:
        vitis.dispose()


if __name__=='__main__':
    try:main()
    except (OSError,ValueError,KeyError,struct.error,subprocess.CalledProcessError) as error:
        print(f'R5_BUILD_FAIL: {error}',file=sys.stderr);sys.exit(1)
