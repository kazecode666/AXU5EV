#include "replay.h"
#include "ax02c_registers.h"
#include "ax02c_hw.h"
#include "ax02c2_adapter_api.h"
#include "ax01b_r5_bridge.h"
#include "AXU5EV_R5_Runtime.h"
#include "xil_io.h"
#include "xiltimer.h"
#include <string.h>

const volatile uint32_t ax02c2_application_id=AX02C2_BUILD_ID;
const volatile uint32_t ax02c2_mmio_base=AX02C_FOC_BASEADDR;
_Static_assert(sizeof(Ax02c2PlResult)==32,"PL result row layout");
_Static_assert(sizeof(Ax02c2Tick)==64,"C2 PMU timing row layout");

static uint32_t rd(uint32_t offset) {return Xil_In32((UINTPTR)AX02C_FOC_BASEADDR+offset);}
static void wr(uint32_t offset,uint32_t value) {Xil_Out32((UINTPTR)AX02C_FOC_BASEADDR+offset,value);}
static uint32_t now(void) {XTime t;XTime_GetTime(&t);return (uint32_t)t;}
#define POLL_TIMEOUT ((uint32_t)(COUNTS_PER_SECOND/10U))

static uint32_t prepare(const double *input,const double *feedback,double *output,
    uint32_t record,Ax02c2Tick *tick)
{
    uint32_t words[11];
    memset(tick,0,sizeof(*tick));tick->record_index=record;tick->command_seq=record+1;
    tick->prepare_begin=now();
    memcpy(AXU5EV_R5_Runtime_U.runtime_u,input,20*sizeof(double));
    tick->step_begin=now();
    AXU5EV_R5_Runtime_step();
    tick->step_end=now();
    ax01b_runtime_output(output);
    /* The generated adapter consumes THIS R5 step's actual 41-field output,
     * never a PC reference row. All fixed-point conversion is generated.
     */
    ax02c2_adapter_pack(input,output,feedback,words);
    tick->adapt_end=now();
    if(rd(FOC_STATUS)&FOC_PENDING)return AX02C2_PENDING;
    for(uint32_t word=0;word<11;word++)wr(FOC_INPUT_FIRST+4U*word,words[word]);
    dmb();wr(FOC_COMMIT,record+1);dmb();
    tick->commit_end=now();
    return 0;
}

Ax02aResult ax02c2_replay(const double *input,const double *feedback,double *output,
    Ax02c2PlResult *pl,Ax02c2Tick *timing,uint32_t frames,Ax02c2Summary *summary)
{
    Ax02aResult result={0,0,0};uint32_t begin=now(),started=0;
    memset(summary,0,sizeof(*summary));summary->tick_hz=(uint32_t)COUNTS_PER_SECOND;
    summary->module_id=rd(FOC_ID);
    if(summary->module_id!=AX02C_ID) {result.status=AX02C2_ID;return result;}
    wr(FOC_CONTROL,FOC_INIT);dmb();
    ax01b_runtime_init();ax02c2_adapter_init();
    result.status=prepare(input,feedback,output,0,&timing[0]);
    if(result.status)goto finish;
    wr(FOC_CONTROL,FOC_START);dmb();started=1;
    for(uint32_t k=0;k<frames;k++) {
        Ax02c2Tick *t=&timing[k];Ax02c2PlResult *p=&pl[k];uint32_t frame;
        result.failed_frame=k;t->wait_begin=now();
        do {
            frame=rd(FOC_RESULT_FRAME);
            if((uint32_t)(now()-t->wait_begin)>POLL_TIMEOUT) {result.status=AX02C2_TIMEOUT;break;}
        } while(frame<k+1);
        if(result.status) {t->status=result.status;break;}
        t->read_begin=now();p->record_index=k;p->runtime_step=k;
        p->pl_frame=frame;p->command_seq=rd(FOC_RESULT_SEQ);
        p->duty[0]=rd(FOC_DUTY_U);p->duty[1]=rd(FOC_DUTY_V);p->duty[2]=rd(FOC_DUTY_W);
        p->adopted_seq=rd(FOC_ADOPTED_SEQ);dmb();
        t->pl_frame=frame;t->result_seq=p->command_seq;t->adopted_seq=p->adopted_seq;
        t->capture_edge=rd(FOC_CAPTURE_EDGE);
        if(rd(FOC_RESULT_FRAME)!=frame)result.status=AX02C2_SNAPSHOT;
        else if(frame!=k+1 || p->command_seq!=k+1 || p->adopted_seq!=k+1)result.status=AX02C2_SEQUENCE;
        else if(rd(FOC_STATUS)&FOC_HOLD_ERROR)result.status=AX02C2_HOLD;
        else if(t->capture_edge!=315)result.status=AX02C2_CAPTURE;
        t->read_end=now();t->status=result.status;
        if(result.status)break;
        result.completed_frames=k+1;summary->last_seq=p->command_seq;summary->last_frame=frame;
        /* Recorded feedback is known in advance: prepare the next logical
         * 100us Runtime step while this full PL frame still runs to 5000.
         * No TTC scheduling, timing restart, PI reset or skipped frame.
         */
        if(k+1<frames) {
            result.status=prepare(input+(uint64_t)(k+1)*20,
                feedback+(uint64_t)(k+1)*AX02C2_FEEDBACK_FIELDS,
                output+(uint64_t)(k+1)*41,k+1,&timing[k+1]);
            if(result.status) {result.failed_frame=k+1;timing[k+1].status=result.status;break;}
        }
    }
finish:
    if(started) {
        uint32_t stop_begin=now();
        wr(FOC_CONTROL,FOC_STOP_AFTER_FRAME);dmb();
        while(rd(FOC_STATUS)&FOC_RUNNING) {
            if((uint32_t)(now()-stop_begin)>POLL_TIMEOUT) {summary->stop_status=AX02C2_TIMEOUT;break;}
        }
        summary->complete_frames=rd(FOC_COMPLETED);
        summary->hold_error=(rd(FOC_STATUS)&FOC_HOLD_ERROR)!=0;
        if(!result.status && summary->stop_status)result.status=summary->stop_status;
        if(!result.status && summary->hold_error)result.status=AX02C2_HOLD;
        if(!result.status && summary->complete_frames!=frames)result.status=AX02C2_COMPLETE;
    }
    summary->elapsed_ticks=now()-begin;
    if(!result.status)result.failed_frame=0;
    ax01b_runtime_end();
    return result;
}
