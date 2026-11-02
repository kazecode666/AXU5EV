#include "ttc_characterize.h"
#include <assert.h>
#include <stdio.h>
static uint32_t tick,mode,stops,starts;
int char_hw_prepare(uint32_t raw) {tick=0;ax02a_ttc_char_control.actual_raw=raw;return mode==3;}
void char_hw_start(void) {starts++;}
void char_hw_stop(void) {stops++;}
uint32_t char_hw_now(void) {if(mode!=2)tick+=1000;return tick;}
void char_hw_idle(void) {
    uint32_t i;if(mode!=0)return;
    for(i=0;i<7;i++) ax02a_ttc_char_irq(tick,100,tick+8);
}
int main(void) {
    unsigned i;uint32_t last=0;
    assert(sizeof(Ax02aTtcCharSample)*1000==16000);
    for(i=0;i<3;i++) {
        ax02a_ttc_char_control.case_id=i+1;
        ax02a_ttc_char_control.requested_raw=i==1?9999:10000;
        mode=0;ax02a_ttc_char_run();
        assert(ax02a_ttc_char_control.state==CHAR_COMPLETE);
        assert(ax02a_ttc_char_control.experiment==++last);
        assert(ax02a_ttc_char_control.completed_samples==1000);
        assert(ax02a_ttc_char_samples[999].sequence==999);
        ax02a_ttc_char_irq(0,0,0);assert(ax02a_ttc_char_samples[999].sequence==999);
    }
    for(mode=1;mode<=3;mode++) {
        ax02a_ttc_char_run();assert(ax02a_ttc_char_control.state==CHAR_ERROR);
        assert(ax02a_ttc_char_control.error==(mode==1?CHAR_TIMEOUT:mode==2?CHAR_COUNTER_STALLED:CHAR_CONFIG));
    }
    ax02a_ttc_char_control.requested_samples=999;ax02a_ttc_char_run();
    assert(ax02a_ttc_char_control.error==CHAR_PARAMETER);
    assert(stops==7 && starts==5);
    puts("TTC_HOST_CONTRACT_PASS: A-B-A, capacity, timeout, stalled clock, config, parameter, cleanup");
    return 0;
}
