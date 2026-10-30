"""Offline Vitis build; standard Python --check-startup is pure file inspection.

Config paths are repository-root relative, independent of current directory.
Vitis invocation uses AX02A_TTC_CONFIG if an alternate new workspace is needed.
"""
import argparse
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import struct
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from ax02a_build_r5 import inspect_elf,inspect_fsbl
APP='ax02a_ttc_characterize'
LAUNCH=APP+'_hw'
DEFAULT=ROOT/'firmware/r5/ax02a/build_config.ttc_characterize.json'


def load_config(path):
    path=Path(path)
    if not path.is_absolute():path=ROOT/path
    c=json.loads(path.read_text(encoding='utf-8-sig'))
    return {k:(ROOT/Path(c[k])).resolve() for k in ['xsa','workspace']}


def symbols(elf):
    """Read ELF32 symbol table without requiring a compiler in check mode."""
    data=Path(elf).read_bytes();h=struct.unpack_from('<16sHHIIIIIHHHHHH',data)
    sections=[struct.unpack_from('<10I',data,h[6]+i*h[11]) for i in range(h[12])]
    result={}
    for s in sections:
        if s[1]!=2:continue
        strings=sections[s[6]];names=data[strings[4]:strings[4]+strings[5]]
        for off in range(s[4],s[4]+s[5],s[9]):
            name,value,size,info,other,index=struct.unpack_from('<IIIBBH',data,off)
            label=names[name:names.find(b'\0',name)].decode('utf-8')
            if label:result[label]=dict(address=value,bytes=size)
    return result


def check_startup(c):
    ws=c['workspace'];platform=ws/'ax02a_platform';elf=ws/APP/'build'/f'{APP}.elf'
    domains=json.loads((platform/'vitis-comp.json').read_text())['configuration']['domains']
    for name,cpu in [('zynqmp_fsbl','psu_cortexa53_0'),('r5_standalone','psu_cortexr5_0')]:
        if len([d for d in domains if d['name']==name and d['processor']==cpu])!=1:raise ValueError('domain mismatch')
    fsbl=platform/'export/ax02a_platform/sw/boot/fsbl.elf';f=inspect_fsbl(fsbl);e=inspect_elf(elf)
    syms=symbols(elf)
    required=['ax02a_ttc_char_control','ax02a_ttc_char_samples','ax02a_ttc_char_prestart','ax02a_ttc_char_done','main','_stack','_heap']
    if any(k not in syms for k in required) or any('AXU5EV_R5_Runtime' in k for k in syms):raise ValueError('TTC-only symbol contract mismatch')
    if syms['ax02a_ttc_char_samples']['bytes']!=16000 or syms['ax02a_ttc_char_control']['bytes']!=100:raise ValueError('mailbox/array layout mismatch')
    buffers=[(syms[k]['address'],syms[k]['address']+syms[k]['bytes']) for k in required[:2]]
    for a,b in buffers:
        if a<0x100000 or not any(seg['address']<=a and seg['address']+seg['memory_bytes']>=b for seg in e['segments']):raise ValueError('global buffers outside checked DDR PT_LOAD')
    if max(buffers[0][0],buffers[1][0])<min(buffers[0][1],buffers[1][1]):raise ValueError('global buffers overlap')
    for name in ['_stack','_heap']:
        address=syms[name]['address']
        if address<max(b for a,b in buffers):raise ValueError('stack/heap overlaps global buffers')
    launch=json.loads((ws/APP/'_ide/launch.json').read_text())
    profiles=[v for v in launch['configurations'] if v['name']==LAUNCH]
    if len(profiles)!=1:raise ValueError('missing unique diagnostic launch')
    p=profiles[0];t=p['targetSetup'];z=t['zuInitialization'];apps=t['downloadElf']
    def local(s):return Path(s.replace('${workspaceFolder}',ws.as_posix())).resolve()
    if (p['type']!='tcf-debug' or p['debugType']!='baremetal-zu' or p['request']!='launch'
        or not t['resetSystem'] or not t['enableRPUSplitMode'] or t['programDevice'] or t['bitstreamFile']
        or not z['isFsbl'] or not z['usingFSBL']['initWithFSBL'] or z['usingFSBL']['fsblExitSymbol']!='XFsbl_Exit'
        or z['usingPsuInit']['runPsuInit'] or local(z['usingFSBL']['fsblFile'])!=fsbl.resolve()
        or len(apps)!=1 or apps[0]['core']!='psu_cortexr5_0' or not apps[0]['stopAtEntry']
        or not apps[0]['resetProcessor'] or local(apps[0]['elfFile'])!=elf.resolve()
        or t['zuTraceOptions']['isSelected'] or t['crossTriggerBreakpoints']['isSelected']):raise ValueError('diagnostic launch mismatch')
    candidate=json.loads((ws/'candidate.json').read_text())
    if not 0<candidate['build_id']<2**32:raise ValueError('invalid candidate nonce')
    # Initialized mailbox build_id must match this candidate, not just filenames.
    data=elf.read_bytes();h=struct.unpack_from('<16sHHIIIIIHHHHHH',data)
    address=syms['ax02a_ttc_char_control']['address']+96;actual=None
    for i in range(h[10]):
        kind,off,vaddr,paddr,filesz,memsz,flags,align=struct.unpack_from('<8I',data,h[5]+i*h[9])
        if kind==1 and vaddr<=address< vaddr+filesz:actual=struct.unpack_from('<I',data,off+address-vaddr)[0]
    if actual!=candidate['build_id']:raise ValueError('ELF build_id differs from provenance')
    return dict(status='OFFLINE_STARTUP_CHECK_PASS',workspace=str(ws),elf=str(elf),fsbl_path=str(fsbl),
                build_id=actual,application=e,fsbl=f,symbols={k:syms[k] for k in required},
                launch=LAUNCH,board='NOT_RUN',root_cause='UNCONFIRMED')


def build(c):
    ws=c['workspace']
    if ws.exists():raise ValueError('existing workspace preserved; choose an explicit new candidate')
    if not c['xsa'].is_file():raise ValueError('missing accepted PS-only XSA')
    compiler=shutil.which('armr5-none-eabi-gcc')
    if not compiler:raise ValueError('run offline build with Vitis 2026.1 embedded environment')
    # No debugger/XSDB imports or hw_server. Vitis client here is the software build service.
    import vitis
    client=vitis.create_client()
    try:
        client.set_workspace(str(ws))
        platform=client.create_platform_component(name='ax02a_platform',hw_design=str(c['xsa']),cpu='psu_cortexr5_0',
                os='standalone',domain_name='r5_standalone',no_boot_bsp=False,fsbl_target='psu_cortexa53_0',generate_dtb=False,compiler='gcc')
        platform.build()
        app=client.create_app_component(name=APP,platform=client.find_platform_in_repos('ax02a_platform'),domain='r5_standalone',template='empty_application')
        for name in ['ttc_characterize.c','ttc_characterize.h']:
            app.import_files(from_loc=str(ROOT/'firmware/r5/ax02a'),files=[name])
        build_id=secrets.randbelow(0xffffffff)+1
        (ws/'candidate.json').write_text(json.dumps(dict(build_id=build_id,xsa=str(c['xsa']),workspace=str(ws)),indent=2)+'\n')
        app.set_app_config(key='USER_COMPILE_OPTIMIZATION_LEVEL',values='-O2')
        app.set_app_config(key='USER_COMPILE_OTHER_FLAGS',values=f'-fno-fast-math -ffp-contract=off -mcpu=cortex-r5 -mfpu=vfpv3-d16 -mfloat-abi=hard -DAX02A_TTC_BUILD_ID={build_id}U')
        app.set_app_config(key='USER_LINK_OTHER_FLAGS',values=f'-Wl,-Map={APP}.map')
        ld=app.get_ld_script();ld.set_stack_size('0x4000');ld.set_heap_size('0x1000')
        app.build()
        launch_path=ws/APP/'_ide/launch.json';launch=json.loads(launch_path.read_text())
        profile=json.loads((ROOT/'firmware/r5/ax02a/launch_first_wait.json').read_text())['configurations'][0]
        profile['name']=LAUNCH
        profile['targetSetup']['downloadElf'][0]['elfFile']=f'${{workspaceFolder}}/{APP}/build/{APP}.elf'
        launch['configurations'].append(profile);launch_path.write_text(json.dumps(launch,indent=2)+'\n')
        result=check_startup(c)
        tool=Path(compiler).with_name('armr5-none-eabi-readelf.exe' if os.name=='nt' else 'armr5-none-eabi-readelf')
        dump=subprocess.check_output([str(tool),'-W','-h','-l','-A','-s',result['elf']],text=True)
        if not all(s in dump for s in ['Realtime','VFPv3-D16','VFP registers']):raise ValueError('R5/FP attributes missing')
        (ws/'elf_attributes.txt').write_text(dump)
        (ws/'startup_validation.json').write_text(json.dumps(result,indent=2)+'\n')
        prov=dict(build_id=result['build_id'],workspace=ws.as_posix(),elf=Path(result['elf']).as_posix(),samples_address=result['symbols']['ax02a_ttc_char_samples']['address'])
        if any(re.search(r'[{}\n\r]',str(v)) for v in prov.values()):raise ValueError('unsafe provenance path')
        (ws/'ttc_provenance.tcl').write_text('dict create '+' '.join(k+' {'+str(v)+'}' for k,v in prov.items())+'\n')
        print(json.dumps(result,indent=2))
    finally:vitis.dispose()


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--config',type=Path,default=Path(os.environ.get('AX02A_TTC_CONFIG',DEFAULT)))
    p.add_argument('--check-startup',action='store_true');a=p.parse_args();c=load_config(a.config)
    if a.check_startup:print(json.dumps(check_startup(c),indent=2))
    else:build(c)


if __name__=='__main__':
    try:main()
    except (OSError,ValueError,KeyError,struct.error,subprocess.CalledProcessError) as e:
        print('TTC_BUILD_FAIL:',e,file=sys.stderr);raise SystemExit(1)
