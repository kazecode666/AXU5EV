"""Create a workspace-local AMD lwIP 2.2.0 overlay; installation stays read-only."""
from pathlib import Path
import shutil
import re

VENDOR=Path('E:/AMDDesignTools/2026.1/Vitis/data/embeddedsw/ThirdParty/sw_services/lwip220_v1_4')

def replace_body(source, signature, body):
    start=source.index(signature); opening=source.index('{',start); level=1; end=opening+1
    while level:
        level+=(source[end]=='{')-(source[end]=='}'); end+=1
    return source[:opening]+'{\n'+body+'\n}'+source[end:]

def prepare(root,out):
    repo=out/'sw_repo_r2'; lib=repo/'ThirdParty/sw_services/lwip220'
    if lib.exists() and (repo/'overlay_ready_v2.txt').exists():
        phy=lib/'src/lwip-2.2.0/contrib/ports/xilinx/netif/xemacpsif_physpeed.c'
        if (root/'firmware/r5/ethernet/jl2121.inc').read_text(encoding='utf-8') not in phy.read_text(encoding='utf-8'):
            raise ValueError('stale PHY overlay preserved; create a new candidate overlay/output')
        return repo
    if not lib.exists(): shutil.copytree(VENDOR,lib)
    y=lib/'data/lwip220.yaml'; text=(VENDOR/'data/lwip220.yaml').read_text(encoding='utf-8-sig')
    # 2026.1 validator treats the old depends dict as all-required. This GEM-only
    # library deliberately requires emacps, not absent PL axiethernet/emaclite.
    text=re.sub(r'    axiethernet:\n.*?(?=examples:)', '',text,flags=re.S)
    y.chmod(0o666); y.write_text(text,encoding='utf-8')
    path=lib/'src/lwip-2.2.0/contrib/ports/xilinx/netif/xemacpsif_physpeed.c'
    text=(VENDOR/'src/lwip-2.2.0/contrib/ports/xilinx/netif/xemacpsif_physpeed.c').read_text(encoding='utf-8-sig')
    text=replace_body(text,'void detect_phy(XEmacPs *xemacpsp)',
        '    (void)xemacpsp; memset(phymapemac0,0,sizeof(phymapemac0));\n    memset(phymapemac1,0,sizeof(phymapemac1));\n    phymapemac0[1]=TRUE; phymapemac1[1]=TRUE;')
    text=replace_body(text,'u32_t phy_setup_emacps (XEmacPs *xemacpsp, u32_t phy_addr)',
        '    return eth_jl_setup(xemacpsp, phy_addr);')
    marker='s32_t speed __attribute__((unused)));'
    pos=text.index(marker)+len(marker)
    text=text[:pos]+(root/'firmware/r5/ethernet/jl2121.inc').read_text(encoding='utf-8')+'\n'+text[pos:]
    path.chmod(0o666); path.write_text('#include <string.h>\n'+text,encoding='utf-8')
    (repo/'overlay_ready_v2.txt').write_text('AMD lwIP220 v1_4 + GEM-only schema + ETH01 JL2121\n',encoding='utf-8')
    return repo
