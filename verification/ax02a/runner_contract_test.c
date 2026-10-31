/* Deterministic scheduler fault injection; links the real generated Runtime. */
#include "replay_runner.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

typedef struct { uint64_t tick; int lost; int slow; int stopped; } TestClock;
static uint32_t test_period=1000;
static uint64_t now(void *context) { TestClock *c=context; return c->tick++; }
static int start(void *context, uint64_t *epoch) {TestClock *c=context;c->tick=0;*epoch=0;return 0;}
static int wait_release(void *context,uint32_t k,uint32_t *seq,uint64_t *release)
{
    TestClock *c=context;
    *seq=k+(c->lost&&k==2);*release=(uint64_t)test_period*k;
    c->tick=*release+(c->slow&&k==2?test_period:0);
    return 0;
}
static void stop(void *context) {((TestClock *)context)->stopped++;}
int main(void)
{
    double input[120]={0},output[246];Ax02aTick records[6];
    TestClock c={0};Ax02aClock clock={&c,1000,now,start,wait_release,stop};
    Ax02aResult r=ax02a_replay(input,output,records,6,&clock);
    assert(r.status==AX02A_OK&&r.completed_frames==6&&c.stopped==1);
    assert(records[0].frame==0&&records[0].release_sequence==0&&records[0].expected==0);
    c.lost=1;c.stopped=0;r=ax02a_replay(input,output,records,6,&clock);
    assert(r.status==AX02A_RELEASE_ERROR&&r.completed_frames==2&&c.stopped==1);
    c.lost=0;c.slow=1;r=ax02a_replay(input,output,records,6,&clock);
    assert(r.status==AX02A_DEADLINE_ERROR&&r.completed_frames==2);
    test_period=10000;clock.period_ticks=10000;c=(TestClock){0};
    r=ax02a_replay(input,output,records,6,&clock);
    assert(r.status==AX02A_OK&&r.completed_frames==6&&records[1].expected==10000);
    c.lost=1;r=ax02a_replay(input,output,records,6,&clock);
    assert(r.status==AX02A_RELEASE_ERROR&&r.completed_frames==2);
    c.lost=0;c.slow=1;r=ax02a_replay(input,output,records,6,&clock);
    assert(r.status==AX02A_DEADLINE_ERROR&&r.completed_frames==2);
    puts("RUNNER_CONTRACT_PASS: k0 epoch, sequence loss, deadline stop");
    return 0;
}
