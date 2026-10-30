/* TTC-only diagnostic. Does not link the Simulink Runtime or timing.c. */
#include "ttc_characterize.h"
#include <limits.h>

volatile Ax02aTtcCharControl ax02a_ttc_char_control={
    .magic=AX02A_TTC_CHAR_MAGIC,.version=1,.record_bytes=16,.state=CHAR_WAIT,
    .requested_raw=10000,.nominal_period=10000,.requested_samples=1000,.case_id=1
};
volatile Ax02aTtcCharSample ax02a_ttc_char_samples[AX02A_TTC_CHAR_CAPACITY];
static volatile uint32_t active;

#ifdef AX02A_TTC_HOST
extern int char_hw_prepare(uint32_t raw);
extern void char_hw_start(void),char_hw_stop(void),char_hw_idle(void);
extern uint32_t char_hw_now(void);
#define BARRIER() ((void)0)
#else
#include "xttcps.h"
#include "xinterrupt_wrap.h"
#include "xil_exception.h"
#include "xil_cache.h"
#include "xil_printf.h"
#ifndef SDT
#error SDT R5 BSP required
#endif
#define BARRIER() __asm__ volatile("dsb sy" ::: "memory")
extern XTtcPs_Config XTtcPs_ConfigTable[];
static XTtcPs periodic,counter;
static int p_ready,f_ready,irq_ready;

/* BSP dispatcher reads/acks clear-on-read status exactly once. We never read
   status here. Volatile Xil_In32/XTtcPs reads separated by R5 DSB+compiler
   barriers preserve F_before -> P -> F_after device access order. */
static void capture(const void *unused,uint32_t status)
{
    uint32_t before,p,after;(void)unused;
    if(status!=XTTCPS_IXR_INTERVAL_MASK) {
        ax02a_ttc_char_control.error=CHAR_IRQ_STATUS;return;
    }
    before=XTtcPs_GetCounterValue(&counter);BARRIER();
    p=XTtcPs_GetCounterValue(&periodic);BARRIER();
    after=XTtcPs_GetCounterValue(&counter);BARRIER();
    ax02a_ttc_char_irq(before,p,after);
}

static uint32_t char_hw_now(void) {return XTtcPs_GetCounterValue(&counter);}
static void char_hw_idle(void) {__asm__ volatile("nop");}
static void char_hw_start(void)
{
    XTtcPs_Start(&counter);BARRIER();XTtcPs_Start(&periodic);BARRIER();
}
static void char_hw_stop(void)
{
    Xil_ExceptionDisable();BARRIER();
    if(p_ready) {XTtcPs_Stop(&periodic);XTtcPs_DisableInterrupts(&periodic,XTTCPS_IXR_ALL_MASK);}
    if(f_ready) {XTtcPs_Stop(&counter);XTtcPs_DisableInterrupts(&counter,XTTCPS_IXR_ALL_MASK);}
    if(irq_ready) {XDisconnectInterruptCntrl(XTtcPs_ConfigTable[0].IntrId[0],XTtcPs_ConfigTable[0].IntrParent);irq_ready=0;}
    BARRIER();
}

static int char_hw_prepare(uint32_t raw)
{
    XTtcPs_Config *a=&XTtcPs_ConfigTable[0],*b=&XTtcPs_ConfigTable[1];
    volatile Ax02aTtcCharControl *c=&ax02a_ttc_char_control;
    p_ready=0;f_ready=0;irq_ready=0;
    if(!a->Name||!b->Name||a->InputClockHz!=100000000U||a->InputClockHz!=b->InputClockHz||
       a->BaseAddress!=0xff110000U||b->BaseAddress!=0xff110004U)return 1;
    if(XTtcPs_CfgInitialize(&periodic,a,a->BaseAddress)!=XST_SUCCESS)return 1;
    p_ready=1;
    if(XTtcPs_CfgInitialize(&counter,b,b->BaseAddress)!=XST_SUCCESS)return 1;
    f_ready=1;
    XTtcPs_Stop(&periodic);XTtcPs_Stop(&counter);
    XTtcPs_DisableInterrupts(&periodic,XTTCPS_IXR_ALL_MASK);
    XTtcPs_DisableInterrupts(&counter,XTTCPS_IXR_ALL_MASK);
    XTtcPs_SetOptions(&periodic,XTTCPS_OPTION_INTERVAL_MODE|XTTCPS_OPTION_WAVE_DISABLE);
    XTtcPs_SetOptions(&counter,XTTCPS_OPTION_WAVE_DISABLE);
    XTtcPs_SetPrescaler(&periodic,16);XTtcPs_SetPrescaler(&counter,16);
    XTtcPs_SetInterval(&periodic,raw);
    XTtcPs_ResetCounterValue(&periodic);XTtcPs_ResetCounterValue(&counter);
    (void)XTtcPs_GetInterruptStatus(&periodic); /* clear stale, stopped, once */
    (void)XTtcPs_GetInterruptStatus(&counter);
    XTtcPs_SetStatusHandler(&periodic,0,capture);
    if(XSetupInterruptSystem(&periodic,(void *)XTtcPs_InterruptHandler,a->IntrId[0],
                            a->IntrParent,XINTERRUPT_DEFAULT_PRIORITY)!=XST_SUCCESS)return 1;
    irq_ready=1;
    XTtcPs_EnableInterrupts(&periodic,XTTCPS_IXR_INTERVAL_MASK);
    c->periodic_hz=a->InputClockHz;c->timestamp_hz=b->InputClockHz;
    c->periodic_base=(uint32_t)a->BaseAddress;c->timestamp_base=(uint32_t)b->BaseAddress;
    c->actual_raw=XTtcPs_GetInterval(&periodic);
    c->periodic_clock=XTtcPs_ReadReg(a->BaseAddress,XTTCPS_CLK_CNTRL_OFFSET);
    c->timestamp_clock=XTtcPs_ReadReg(b->BaseAddress,XTTCPS_CLK_CNTRL_OFFSET);
    c->periodic_control=XTtcPs_ReadReg(a->BaseAddress,XTTCPS_CNT_CNTRL_OFFSET);
    c->timestamp_control=XTtcPs_ReadReg(b->BaseAddress,XTTCPS_CNT_CNTRL_OFFSET);
    c->periodic_ier=XTtcPs_ReadReg(a->BaseAddress,XTTCPS_IER_OFFSET);
    c->timestamp_ier=XTtcPs_ReadReg(b->BaseAddress,XTTCPS_IER_OFFSET);
    BARRIER();
    return c->actual_raw!=raw||c->periodic_clock!=0||c->timestamp_clock!=0||
        c->periodic_control!=0x23||c->timestamp_control!=0x21||c->periodic_ier!=1||c->timestamp_ier!=0;
}
#endif

__attribute__((noinline)) void ax02a_ttc_char_prestart(void) {BARRIER();}
__attribute__((noinline)) void ax02a_ttc_char_done(void) {BARRIER();}

void ax02a_ttc_char_irq(uint32_t before,uint32_t p,uint32_t after)
{
    volatile Ax02aTtcCharControl *c=&ax02a_ttc_char_control;
    uint32_t n=c->completed_samples;
    if(!active||n>=AX02A_TTC_CHAR_CAPACITY)return;
    ax02a_ttc_char_samples[n]=(Ax02aTtcCharSample){n,before,p,after};
    BARRIER();c->completed_samples=n+1;
}

void ax02a_ttc_char_run(void)
{
    volatile Ax02aTtcCharControl *c=&ax02a_ttc_char_control;
    uint32_t raw=c->requested_raw,n=c->requested_samples,case_id=c->case_id;
    uint32_t previous=0,stalled=0,now;uint64_t budget;
    c->command=0;c->state=CHAR_RUNNING;c->completed_samples=0;c->error=CHAR_OK;c->actual_raw=0;
    active=0;
    if(c->experiment==UINT32_MAX) {c->error=CHAR_PARAMETER;goto done;}
    c->experiment++;c->nominal_period=10000;
    /* Copy parameters once. GUI writes during RUNNING cannot change this run. */
    if(n!=1000||case_id<1||case_id>4||
       raw!=(case_id==2?9999U:case_id==4?10001U:10000U)) {c->error=CHAR_PARAMETER;goto done;}
    budget=(uint64_t)(n+100U)*(raw+1U)+100000U;
    if(budget>=20000000U) {c->error=CHAR_PARAMETER;goto done;}
    c->timeout_ticks=(uint32_t)budget;
    if(char_hw_prepare(raw)) {c->error=CHAR_CONFIG;goto done;}
    ax02a_ttc_char_prestart(); /* counters stopped; optional breakpoint */
    active=1;BARRIER();char_hw_start();
    while(c->completed_samples<n && c->error==CHAR_OK) {
        now=char_hw_now();
        if(now<previous) {c->error=CHAR_WRAP;break;}
        if(now>=c->timeout_ticks) {c->error=CHAR_TIMEOUT;break;}
        if(now==previous) {if(++stalled>=1000000U) {c->error=CHAR_COUNTER_STALLED;break;}}
        else stalled=0;
        previous=now;char_hw_idle();
    }
done:
    char_hw_stop();active=0;BARRIER();
    c->state=c->error==CHAR_OK?CHAR_COMPLETE:CHAR_ERROR;BARRIER();
    ax02a_ttc_char_done();
}

#ifndef AX02A_TTC_HOST
int main(void)
{
    Xil_ICacheEnable();Xil_DCacheDisable();
    xil_printf("AX02A TTC-only; I-cache ON; D-cache OFF; WAIT\r\n");
    for(;;) {
        ax02a_ttc_char_control.state=CHAR_WAIT;BARRIER();
        while(ax02a_ttc_char_control.command==0) {__asm__ volatile("nop");}
        if(ax02a_ttc_char_control.command!=1) {
            ax02a_ttc_char_control.command=0;ax02a_ttc_char_control.error=CHAR_PARAMETER;
            ax02a_ttc_char_control.state=CHAR_ERROR;ax02a_ttc_char_done();continue;
        }
        ax02a_ttc_char_run();
    }
}
#endif
