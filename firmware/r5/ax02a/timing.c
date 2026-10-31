#include "timing.h"
#include "timer_mapping.h"
#include "xttcps.h"
#include "xinterrupt_wrap.h"
#include "xil_exception.h"
#include <limits.h>

#ifndef SDT
#error AX02A requires the Vitis 2026.1 SDT-generated standalone BSP.
#endif
extern XTtcPs_Config XTtcPs_ConfigTable[];
static XTtcPs periodic,counter;
static volatile uint32_t release_sequence,release_tick;
static uint32_t epoch_tick;
static Ax02aTimerInfo *timer_info;
volatile Ax02aTtcSnapshot ax02a_ttc_snapshot;
const uint32_t ax02a_timer_mapping_version=AX02A_TIMER_MAPPING_VERSION;
const uint32_t ax02a_runtime_candidate_id=AX02A_RUNTIME_CANDIDATE_ID;

static uint64_t read_tick(void *unused)
{
    (void)unused;
    return XTtcPs_GetCounterValue(&counter);
}

/* Driver dispatcher acknowledges TTC status. No generated call/float/printing. */
static void released(const void *unused,uint32_t status)
{
    (void)unused;
    if(status&XTTCPS_IXR_INTERVAL_MASK) {
        release_tick=XTtcPs_GetCounterValue(&counter);
        __asm__ volatile ("dmb sy" ::: "memory");
        release_sequence++;
    }
}

static int begin(void *unused,uint64_t *epoch)
{
    uint32_t before,after;
    (void)unused;
    XTtcPs_Stop(&periodic);XTtcPs_Stop(&counter);
    XTtcPs_ResetCounterValue(&periodic);XTtcPs_ResetCounterValue(&counter);
    (void)XTtcPs_GetInterruptStatus(&periodic);
    release_sequence=0;release_tick=0;
    XTtcPs_Start(&counter);
    before=XTtcPs_GetCounterValue(&counter);
    XTtcPs_Start(&periodic);
    after=XTtcPs_GetCounterValue(&counter);
    *epoch=before;epoch_tick=before;timer_info->start_window_ticks=after-before;
    return 0;
}

static int await_release(void *unused,uint32_t expected,uint32_t *sequence,uint64_t *tick)
{
    uint32_t first,second,when;
    (void)unused;
    for(;;) {
        first=release_sequence;
        __asm__ volatile ("dmb sy" ::: "memory");
        when=release_tick;
        __asm__ volatile ("dmb sy" ::: "memory");
        second=release_sequence;
        if(first!=second)continue;
        if(first>=expected)break;
        /* Independent free-running time detects absent/merged IRQs, no hang. */
        if(read_tick(NULL)>=(uint64_t)epoch_tick+(uint64_t)(expected+1)*timer_info->period_ticks)
            return 1;
    }
    *sequence=first;*tick=when;
    return first!=expected;
}

static void end(void *unused)
{
    (void)unused;
    XTtcPs_Stop(&periodic);XTtcPs_DisableInterrupts(&periodic,XTTCPS_IXR_ALL_MASK);
    XTtcPs_Stop(&counter);
    (void)XTtcPs_Release(&periodic);(void)XTtcPs_Release(&counter);
}

int ax02a_timing_prepare(Ax02aClock *clock,Ax02aTimerInfo *info,uint32_t frames)
{
    XTtcPs_Config *a=&XTtcPs_ConfigTable[0],*b=&XTtcPs_ConfigTable[1];
    uint32_t hardware_interval,logical_interval,logical_period_ticks,prescaler,divisor,j,minimum=UINT_MAX,maximum=0;
    ax02a_ttc_snapshot.valid=0;
    if(!a->Name||!b->Name||a->InputClockHz!=b->InputClockHz)return 1;
    if(XTtcPs_CfgInitialize(&periodic,a,a->BaseAddress)!=XST_SUCCESS||
       XTtcPs_CfgInitialize(&counter,b,b->BaseAddress)!=XST_SUCCESS)return 1;
    XTtcPs_Stop(&periodic);XTtcPs_Stop(&counter);
    XTtcPs_SetOptions(&periodic,XTTCPS_OPTION_INTERVAL_MODE|XTTCPS_OPTION_WAVE_DISABLE);
    XTtcPs_SetOptions(&counter,XTTCPS_OPTION_WAVE_DISABLE);
    XTtcPs_SetPrescaler(&counter,16); /* no prescaler: independent 32-bit counter */
    {
        uint8_t p;
        XTtcPs_CalcIntervalFromFreq(&periodic,10000,&logical_interval,&p);prescaler=p;
    }
    if(!logical_interval||logical_interval==UINT_MAX||prescaler>16)return 1;
    divisor=prescaler<16?(1U<<(prescaler+1)):1;
    if((uint64_t)logical_interval*divisor>UINT_MAX)return 1;
    logical_period_ticks=logical_interval*divisor;
    if(((uint64_t)frames+2)*logical_period_ticks>=UINT_MAX)return 1;
    if(ax02a_timer_map((uint32_t)a->BaseAddress,(uint32_t)b->BaseAddress,
                      a->InputClockHz,prescaler,logical_period_ticks,&hardware_interval))return 1;
    /* Only this board's verified TTC0/unprescaled100MHz interval mapping.
       Schedule, deadline, release timeout and wrap budget remain logical10000. */
    XTtcPs_SetInterval(&periodic,hardware_interval);XTtcPs_SetPrescaler(&periodic,(uint8_t)prescaler);
    info->clock_hz=b->InputClockHz;info->interval=hardware_interval;info->prescaler=prescaler;
    info->period_ticks=logical_period_ticks;timer_info=info;
    /* Clock is restarted at each experiment. Bound above prevents any wrap. */
    XTtcPs_ResetCounterValue(&counter);XTtcPs_Start(&counter);
    for(j=0;j<1024;j++) {
        uint32_t t0=XTtcPs_GetCounterValue(&counter),t1=XTtcPs_GetCounterValue(&counter);
        uint32_t delta=t1-t0;if(delta<minimum)minimum=delta;if(delta>maximum)maximum=delta;
    }
    XTtcPs_Stop(&counter);
    info->timestamp_read_min_ticks=minimum;info->timestamp_read_max_ticks=maximum;
    XTtcPs_SetStatusHandler(&periodic,NULL,released);
    if(XSetupInterruptSystem(&periodic,(void *)XTtcPs_InterruptHandler,
            a->IntrId[0],a->IntrParent,XINTERRUPT_DEFAULT_PRIORITY)!=XST_SUCCESS)return 1;
    XTtcPs_EnableInterrupts(&periodic,XTTCPS_IXR_INTERVAL_MASK);
    /* Save actual register readback before begin() starts either counter.
       ISR remains unchanged. Status/ISR offsets are deliberately excluded. */
    ax02a_ttc_snapshot.periodic_base=(uint32_t)a->BaseAddress;
    ax02a_ttc_snapshot.timestamp_base=(uint32_t)b->BaseAddress;
    ax02a_ttc_snapshot.periodic_hz=a->InputClockHz;
    ax02a_ttc_snapshot.timestamp_hz=b->InputClockHz;
    ax02a_ttc_snapshot.hardware_interval=XTtcPs_GetInterval(&periodic);
    ax02a_ttc_snapshot.logical_period_ticks=logical_period_ticks;
    ax02a_ttc_snapshot.periodic_clock=XTtcPs_ReadReg(a->BaseAddress,XTTCPS_CLK_CNTRL_OFFSET);
    ax02a_ttc_snapshot.timestamp_clock=XTtcPs_ReadReg(b->BaseAddress,XTTCPS_CLK_CNTRL_OFFSET);
    ax02a_ttc_snapshot.periodic_control=XTtcPs_ReadReg(a->BaseAddress,XTTCPS_CNT_CNTRL_OFFSET);
    ax02a_ttc_snapshot.timestamp_control=XTtcPs_ReadReg(b->BaseAddress,XTTCPS_CNT_CNTRL_OFFSET);
    ax02a_ttc_snapshot.periodic_ier=XTtcPs_ReadReg(a->BaseAddress,XTTCPS_IER_OFFSET);
    ax02a_ttc_snapshot.timestamp_ier=XTtcPs_ReadReg(b->BaseAddress,XTTCPS_IER_OFFSET);
    __asm__ volatile("dmb sy" ::: "memory");ax02a_ttc_snapshot.valid=1;
    if(ax02a_ttc_snapshot.hardware_interval!=hardware_interval||
        (ax02a_ttc_snapshot.periodic_clock&0x3fU)!=0||
        (ax02a_ttc_snapshot.timestamp_clock&0x3fU)!=0||
        ax02a_ttc_snapshot.periodic_control!=0x23U||
        ax02a_ttc_snapshot.timestamp_control!=0x21U||
        ax02a_ttc_snapshot.periodic_ier!=1U||ax02a_ttc_snapshot.timestamp_ier!=0U)return 1;
    clock->context=NULL;clock->period_ticks=info->period_ticks;clock->now=read_tick;
    clock->start=begin;clock->wait_release=await_release;clock->stop=end;
    return 0;
}
