#ifndef AX02A_TTC_CHARACTERIZE_H
#define AX02A_TTC_CHARACTERIZE_H
#include <stdint.h>
#define AX02A_TTC_CHAR_MAGIC 0x31435454U
#define AX02A_TTC_CHAR_CAPACITY 1000U
enum { CHAR_WAIT=1, CHAR_RUNNING=2, CHAR_COMPLETE=3, CHAR_ERROR=4 };
enum { CHAR_OK=0, CHAR_PARAMETER=1, CHAR_CONFIG=2, CHAR_TIMEOUT=3,
       CHAR_COUNTER_STALLED=4, CHAR_WRAP=5, CHAR_IRQ_STATUS=6 };
typedef struct { uint32_t sequence, f_before, p_count, f_after; } Ax02aTtcCharSample;
/* Little endian uint32 only; prestart snapshots describe stopped counters.
   case_id: 1=A1, 2=B, 3=A2, 4=C. command=1 starts exactly one acquisition. */
typedef struct {
    uint32_t magic, version, record_bytes, state, command, experiment;
    uint32_t case_id, requested_raw, actual_raw, nominal_period;
    uint32_t requested_samples, completed_samples, error, timeout_ticks;
    uint32_t periodic_hz, timestamp_hz, periodic_base, timestamp_base;
    uint32_t periodic_clock, timestamp_clock, periodic_control, timestamp_control;
    uint32_t periodic_ier, timestamp_ier, build_id;
} Ax02aTtcCharControl;
_Static_assert(sizeof(uint32_t)==4,"uint32 width");
_Static_assert(sizeof(Ax02aTtcCharSample)==16,"TTC record must be 16 bytes");
_Static_assert(sizeof(Ax02aTtcCharControl)==100,"mailbox protocol v1");
extern volatile Ax02aTtcCharControl ax02a_ttc_char_control;
extern volatile Ax02aTtcCharSample ax02a_ttc_char_samples[AX02A_TTC_CHAR_CAPACITY];
void ax02a_ttc_char_prestart(void);
void ax02a_ttc_char_done(void);
void ax02a_ttc_char_run(void);
void ax02a_ttc_char_irq(uint32_t before,uint32_t p,uint32_t after);
#endif
