#include "replay_runner.h"
#include "ax01b_r5_bridge.h"
#include "AXU5EV_R5_Runtime.h"
#include <string.h>

Ax02aResult ax02a_replay(const double *input,double *output,Ax02aTick *ticks,
                        uint32_t frames,Ax02aClock *clock)
{
    Ax02aResult result={AX02A_OK,0,0};
    uint64_t epoch=0;
    uint32_t k;
    if (!input||!output||!frames||(clock&&(!ticks||!clock->period_ticks))) {
        result.status=AX02A_INPUT_ERROR;return result;
    }
    ax01b_runtime_init();
    if (clock&&clock->start(clock->context,&epoch)) {
        result.status=AX02A_CLOCK_ERROR;goto finish;
    }
    for (k=0;k<frames;k++) {
        uint32_t sequence=k;
        uint64_t released=epoch,expected=epoch,deadline=0;
        if (clock) {
            Ax02aTick *record=&ticks[k];
            expected=epoch+k*clock->period_ticks;
            deadline=expected+clock->period_ticks;
            if (k&&clock->wait_release(clock->context,k,&sequence,&released)) {
                result.status=AX02A_RELEASE_ERROR;result.failed_frame=k;break;
            }
            record->frame=k;record->release_sequence=sequence;
            record->expected=expected;record->released=released;
            record->started=clock->now(clock->context);
            if (sequence!=k||released<expected) {
                result.status=AX02A_RELEASE_ERROR;result.failed_frame=k;break;
            }
            if (record->started>=deadline) {
                result.status=AX02A_DEADLINE_ERROR;result.failed_frame=k;break;
            }
        }
        if (clock) {
            /* Separate the input copy from the pure generated Runtime timing. */
            memcpy(AXU5EV_R5_Runtime_U.runtime_u,input+(uint64_t)k*20,20*sizeof(double));
            ticks[k].step_begin=clock->now(clock->context);
            AXU5EV_R5_Runtime_step();
            ticks[k].step_end=clock->now(clock->context);
        } else {
            ax01b_runtime_step(input+(uint64_t)k*20);
        }
        ax01b_runtime_output(output+(uint64_t)k*41);
        if (clock) {
            ticks[k].completed=clock->now(clock->context);
            if (ticks[k].completed>=deadline) {
                result.status=AX02A_DEADLINE_ERROR;result.failed_frame=k;break;
            }
        }
        result.completed_frames=k+1;
    }
finish:
    if (clock) clock->stop(clock->context);
    ax01b_runtime_end();
    return result;
}
