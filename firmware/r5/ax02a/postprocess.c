#include "postprocess.h"
#include <math.h>
#include <stdatomic.h>
#include <string.h>
#include <stddef.h>
_Static_assert(sizeof(Ax02aPostReport)==2336,"report wire layout changed");
_Static_assert(offsetof(Ax02aPostReport,fields)==64,"report header layout changed");
static int exact(unsigned j)
{
    switch(j) {
    case 3:case 4:case 6:case 9:case 10:case 11:case 15:case 16:case 17:
    case 20:case 22:case 24:case 25:case 26:case 29:case 30:case 31:case 32:
    case 33:case 35:return 1;
    default:return 0;
    }
}
static void sample(Ax02aPostReport *r,unsigned group,uint32_t k,const double v[5])
{
    for(unsigned j=0;j<5;j++) {
        Ax02aMetricReport *m=&r->metrics[group][j];
        if(!m->samples) {m->minimum=m->maximum=v[j];m->worst_frame=k;}
        else {
            if(v[j]<m->minimum) {m->minimum=v[j];if(j==4)m->worst_frame=k;}
            if(v[j]>=m->maximum) {m->maximum=v[j];if(j!=4)m->worst_frame=k;}
        }
        m->samples++;m->mean+=v[j];
    }
}
int ax02a_postprocess(const double *a,uint32_t na,const double *ref,uint32_t nr,
    const Ax02aTick *ticks,uint32_t nt,const Ax02aPostRequest *q,Ax02aPostReport *r)
{
    if(!r||!q)return 1;
    memset(r,0,sizeof(*r));r->magic=AX02A_REPORT_MAGIC;r->version=1;r->bytes=sizeof(*r);
    r->scenario=q->scenario;r->experiment=q->experiment;r->mode=q->mode;
    r->requested=q->frames;r->completed=q->completed;r->program_status=q->program_status;
    r->compare_status=AX02A_POST_FAIL;
    r->timing_status=q->mode?AX02A_POST_FAIL:AX02A_POST_NOT_RUN;r->p99_status=AX02A_POST_NOT_RUN;
    for(unsigned j=0;j<41;j++)r->fields[j].first_mismatch=UINT32_MAX;
    if(!a||!ref||!q->frames||q->frames>65536||q->scenario<1||q->scenario>3||
        q->scenario!=q->expected_scenario||q->experiment!=q->expected_experiment||
        q->mode>1||q->mode!=q->expected_mode||q->reference_frames!=q->frames||
        q->completed!=q->frames||q->program_status||q->interrupted||
        na!=q->frames*41||nr!=q->frames*41) {r->contract_errors++;goto finish;}
    for(unsigned j=0;j<41;j++) {
        Ax02aFieldReport *f=&r->fields[j];double square=0;
        for(uint32_t k=0;k<q->frames;k++) {
            double x=a[(uint64_t)k*41+j],y=ref[(uint64_t)k*41+j];
            int finite=isfinite(x)&&isfinite(y);
            double delta=finite?fabs(x-y):INFINITY;
            if(delta>f->max_abs) {f->max_abs=delta;f->max_frame=k;}
            square+=delta*delta;
            if(!(finite&&(exact(j)?x==y:delta<=1e-9+1e-9*fabs(y)))) {
                if(!f->failures)f->first_mismatch=k;
                f->failures++;r->numeric_errors++;
            }
        }
        f->rms=sqrt(square/q->frames);
    }
    r->compare_status=r->numeric_errors?AX02A_POST_FAIL:AX02A_POST_PASS;
    if(q->mode) {
        if(!ticks||nt!=q->frames||!q->clock_hz||!q->period_ticks||
            fabs(q->period_ticks-q->clock_hz*.0001)>1.000000001) {r->timing_errors++;goto finish;}
        uint64_t epoch=ticks[0].expected;
        for(uint32_t k=0;k<q->frames;k++) {
            const Ax02aTick *t=&ticks[k];uint64_t scheduled=epoch+(uint64_t)k*q->period_ticks;
            uint64_t diff=t->expected>scheduled?t->expected-scheduled:scheduled-t->expected;
            if(t->frame!=k||t->release_sequence!=k||diff>1)r->timing_errors++;
            if(!(t->expected<=t->released&&t->released<=t->started&&t->started<=t->step_begin&&
                t->step_begin<=t->step_end&&t->step_end<=t->completed))r->timing_errors++;
            if(t->completed>=t->expected+q->period_ticks)r->timing_errors++;
            double scale=1e6/q->clock_hz;
            double v[5]={((double)t->step_end-t->step_begin)*scale,
                ((double)t->completed-t->started)*scale,((double)t->completed-t->expected)*scale,
                ((double)t->started-t->expected)*scale,((double)t->expected+q->period_ticks-t->completed)*scale};
            unsigned group=k%100==99?3:k%10==9?2:1;
            sample(r,0,k,v);sample(r,group,k,v);
            if(k&&(a[41*k+31]!=a[41*(k-1)+31]||a[41*k+32]!=a[41*(k-1)+32]||
                a[41*k+33]!=a[41*(k-1)+33]))sample(r,4,k,v);
            if(!k||a[41*k+4]!=a[41*(k-1)+4])sample(r,5,k,v);
        }
        for(unsigned g=0;g<6;g++)for(unsigned j=0;j<5;j++)
            if(r->metrics[g][j].samples)r->metrics[g][j].mean/=r->metrics[g][j].samples;
        r->timing_status=r->timing_errors?AX02A_POST_FAIL:AX02A_POST_PASS;
    }
finish:
    /* Final completion marker must be published after the entire report. */
    atomic_thread_fence(memory_order_release);r->valid=AX02A_REPORT_VALID;
    return r->contract_errors||r->numeric_errors||r->timing_errors?1:0;
}
