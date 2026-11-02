/* Standalone R5_0 replay application. It never accesses motor/PL registers. */
#include "replay_runner.h"
#include "timing.h"
#include "postprocess.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include <stdint.h>

/* Build script validates these reserved windows against XSA and ELF PT_LOAD. */
#define INPUT_ADDRESS  0x10000000U
#define OUTPUT_ADDRESS 0x11000000U
#define TIMING_ADDRESS 0x13000000U
#define START_COMMAND  0x41583241U
typedef struct {
    uint32_t command,mode,frames,state,experiment;
    Ax02aResult result;
    Ax02aTimerInfo timer;
} Ax02aControl;
volatile Ax02aControl ax02a_control;
volatile Ax02aPostControl ax02a_post_control; /* default disabled, separate mailbox */

/* Debugger may break here after completion and read results with caches off. */
__attribute__((noinline)) void ax02a_result_ready(void) {__asm__ volatile("" ::: "memory");}

int main(void)
{
    double *input=(double *)(uintptr_t)INPUT_ADDRESS;
    double *output=(double *)(uintptr_t)OUTPUT_ADDRESS;
    Ax02aTick *ticks=(Ax02aTick *)(uintptr_t)TIMING_ADDRESS;
    Ax02aPostReport *report=(Ax02aPostReport *)(uintptr_t)AX02A_REPORT_ADDRESS;
    /* JTAG input is loaded only while state=WAIT, never during replay.
       Entire D-cache is disabled, so debugger and R5 share uncached DDR bytes. */
    Xil_DCacheDisable();Xil_ICacheEnable();
    report->valid=0;
    xil_printf("AX02A R5_0 standalone replay; D-cache OFF; waiting for input\r\n");
    for(;;) {
        Ax02aClock clock;Ax02aTimerInfo info={0};
        Ax02aResult result;uint32_t frames,mode;
        Ax02aPostControl post;
        ax02a_control.state=1;
        while(ax02a_control.command!=START_COMMAND) {__asm__ volatile("nop");}
        __asm__ volatile("dmb sy" ::: "memory");
        frames=ax02a_control.frames;mode=ax02a_control.mode;
        post=ax02a_post_control;ax02a_post_control.enabled=0; /* one-shot opt-in */
        ax02a_post_control.state=0;report->valid=0;
        ax02a_control.command=0;ax02a_control.state=2;
        if(!frames||frames>65536||mode>1) {
            result=(Ax02aResult){AX02A_INPUT_ERROR,0,0};
        } else if(mode&&ax02a_timing_prepare(&clock,&info,frames)) {
            result=(Ax02aResult){AX02A_CLOCK_ERROR,0,0};
        } else {
            result=ax02a_replay(input,output,ticks,frames,mode?&clock:NULL);
        }
        ax02a_control.result=result;ax02a_control.timer=info;
        ax02a_control.experiment++;
        /* ax02a_replay has returned through clock->stop. All comparison and
           time summarization is outside the measured loop and the ISR. */
        if(post.enabled==1) {
            const Ax02aReferenceDescriptor *d=(const Ax02aReferenceDescriptor *)(uintptr_t)AX02A_DESCRIPTOR_ADDRESS;
            uint32_t valid=d->magic==AX02A_REFERENCE_MAGIC&&d->version==1&&d->fields==41&&
                d->source_start==0&&d->frames==frames&&frames<=65536&&
                d->reference_bytes==frames*41*8;
            Ax02aPostRequest q={valid?d->scenario:0,post.scenario,
                ax02a_control.experiment,post.expected_experiment,mode,post.expected_mode,
                frames,valid?d->frames:0,result.completed_frames,result.status,
                post.interrupted,info.clock_hz,info.period_ticks};
            ax02a_post_control.state=1;
            ax02a_postprocess(output,result.completed_frames*41,
                (const double *)(uintptr_t)AX02A_REFERENCE_ADDRESS,valid?d->frames*41:0,
                ticks,mode?result.completed_frames:0,&q,report);
            __asm__ volatile("dsb sy" ::: "memory");
            ax02a_post_control.state=2;
        }
        ax02a_control.state=result.status?4:3;
        __asm__ volatile("dsb sy" ::: "memory");
        xil_printf("AX02A result status=%lu completed=%lu experiment=%lu\r\n",
            (unsigned long)result.status,(unsigned long)result.completed_frames,
            (unsigned long)ax02a_control.experiment);
        ax02a_result_ready();
        /* Do not turn a failed periodic experiment into an automatic retry. */
        if(result.status)for(;;) {__asm__ volatile("nop");}
    }
}
