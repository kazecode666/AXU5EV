#ifndef AX02A_TIMING_H
#define AX02A_TIMING_H
#include "replay_runner.h"
typedef struct {
    uint32_t clock_hz, interval, prescaler, period_ticks;
    uint32_t timestamp_read_min_ticks, timestamp_read_max_ticks;
    uint32_t start_window_ticks;
} Ax02aTimerInfo;
/* SDT BSP only; two TTC channels selected from the generated config table. */
int ax02a_timing_prepare(Ax02aClock *clock,Ax02aTimerInfo *info,uint32_t frames);
#endif
