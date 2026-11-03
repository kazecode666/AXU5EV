#ifndef AX02A_TIMER_MAPPING_H
#define AX02A_TIMER_MAPPING_H
#include <stdint.h>
#define AX02A_TIMER_MAPPING_VERSION 1U
#ifndef AX02A_RUNTIME_CANDIDATE_ID
#define AX02A_RUNTIME_CANDIDATE_ID 0x52313031U
#endif
/* Board ABA evidence: task6541052405 / verification/ax02a/ttc_aba_01.
   Unsupported configurations fail closed; this is not a generic TTC rule. */
static inline int ax02a_timer_map(uint32_t periodic_base,uint32_t timestamp_base,
    uint32_t hz,uint32_t prescaler,uint32_t logical,uint32_t *raw)
{
    if(periodic_base!=0xff110000U||timestamp_base!=0xff110004U||
       hz!=100000000U||prescaler!=16U||logical!=10000U||!raw)return 1;
    *raw=logical-1U;
    return 0;
}
#endif
