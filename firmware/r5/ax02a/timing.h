#ifndef AX02A_TIMING_H
#define AX02A_TIMING_H
#include "replay_runner.h"
typedef struct {
    uint32_t clock_hz, interval, prescaler, period_ticks;
    uint32_t timestamp_read_min_ticks, timestamp_read_max_ticks;
    uint32_t start_window_ticks;
} Ax02aTimerInfo;
/* Pre-start readback only, separate from the existing timer mailbox ABI.
   No ISR/periodic-loop work and no clear-on-read status registers. */
typedef struct {
    uint32_t valid,periodic_base,timestamp_base,periodic_hz,timestamp_hz;
    uint32_t hardware_interval,logical_period_ticks;
    uint32_t periodic_clock,timestamp_clock,periodic_control,timestamp_control;
    uint32_t periodic_ier,timestamp_ier;
} Ax02aTtcSnapshot;
extern volatile Ax02aTtcSnapshot ax02a_ttc_snapshot;
/* SDT BSP only; two TTC channels selected from the generated config table. */
int ax02a_timing_prepare(Ax02aClock *clock,Ax02aTimerInfo *info,uint32_t frames);
/* Integration may return to its data service after a prepare failure. */
void ax02a_timing_cancel(void);
#endif
