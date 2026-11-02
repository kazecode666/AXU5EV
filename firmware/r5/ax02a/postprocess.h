#ifndef AX02A_POSTPROCESS_H
#define AX02A_POSTPROCESS_H
#include <stdint.h>
#include "replay_runner.h"
#define AX02A_REPORT_MAGIC 0x31505841U
#define AX02A_REPORT_VALID 0x434f4d50U
#define AX02A_REPORT_BYTES 2400U
#define AX02A_REFERENCE_MAGIC 0x31464552U
#define AX02A_REFERENCE_ADDRESS 0x14000000U
#define AX02A_DESCRIPTOR_ADDRESS 0x12f00000U
#define AX02A_REPORT_ADDRESS 0x16000000U
enum {AX02A_POST_PASS=0,AX02A_POST_FAIL=1,AX02A_POST_NOT_RUN=2};
/* Scenario 1=current_motion frame-zero prefix; 2=full current_motion;
   3=full current_alignment_reset. Version 1 never accepts a middle slice. */
typedef struct {
    uint32_t magic,version,scenario,frames,fields,source_start,reference_bytes,reserved;
} Ax02aReferenceDescriptor;
typedef struct {
    uint32_t scenario,expected_scenario,experiment,expected_experiment,mode,expected_mode;
    uint32_t frames,reference_frames,completed,program_status,interrupted,clock_hz,period_ticks;
} Ax02aPostRequest;
typedef struct {
    uint32_t failures,max_frame,first_mismatch,reserved;
    double max_abs,rms;
} Ax02aFieldReport;
typedef struct {
    uint32_t samples,worst_frame;
    double mean,minimum,maximum;
} Ax02aMetricReport;
/* groups: all/ordinary/speed_due/position_due/command_event/alignment_transition.
   metrics: Runtime/task/response/jitter/slack in us. P99 NOT_COMPUTED in v1/v2. */
typedef struct {
    uint32_t magic,version,bytes,valid;
    uint32_t scenario,experiment,mode,requested,completed,program_status;
    uint32_t compare_status,timing_status,contract_errors,numeric_errors,timing_errors,p99_status;
    Ax02aFieldReport fields[41];
    Ax02aMetricReport metrics[6][5];
    /* v2 append-only diagnostic: 0=pass/no trend, 1=fail/trend, 2=not run/short.
       This screen does not identify physical counter-edge period or root cause. */
    uint32_t deadline_status,period_status,phase_samples,phase_reserved;
    double phase_slope,phase_intercept,phase_rms,phase_se,phase_threshold,mean_isr_interval;
} Ax02aPostReport;
typedef struct {
    uint32_t enabled,state,expected_experiment,expected_mode,scenario,interrupted;
} Ax02aPostControl; /* enabled defaults to 0; 1 means explicitly requested */
/* Pure post-run function: no timers, UART, target access, allocation or file I/O.
   Caller supplies real lengths; never invoke inside Runtime/ISR/timed replay. */
int ax02a_postprocess(const double *actual,uint32_t actual_values,
    const double *reference,uint32_t reference_values,const Ax02aTick *ticks,
    uint32_t tick_records,const Ax02aPostRequest *request,Ax02aPostReport *report);
#endif
