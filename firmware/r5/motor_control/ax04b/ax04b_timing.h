#pragma once

#include <stdbool.h>
#include <stdint.h>

enum {
    AX04B_IRQ_PHASE = 76, AX04B_DEADLINE_PHASE = 4984,
    AX04B_FRAME_CYCLES = 5000, AX04B_PL_HZ = 50000000
};

enum TimingRate { TIMING_BASE, TIMING_SPEED, TIMING_POSITION, TIMING_RATES };
enum TimingMetric {
    TIMING_ENTRY, TIMING_READ, TIMING_MODEL, TIMING_SUBMIT, TIMING_ACK,
    TIMING_IRQ, TIMING_LOWER, TIMING_UPPER, TIMING_METRICS
};
enum TimingEvent {
    TIMING_GAP = 1u, TIMING_RECEIPT = 2u, TIMING_INVALID = 4u,
    TIMING_REJECT = 8u, TIMING_UNBRACKETED = 16u, TIMING_SPURIOUS = 32u,
    TIMING_TRANSITION = 64u, TIMING_OVERRUN = 128u, TIMING_SNAPSHOT = 256u
};

typedef struct {
    uint64_t pl_tick;
    uint32_t seq, sample_id, version, target, entry_phase, mode;
    uint32_t result, stop_reason, rate;
} TimingIdentity;

typedef struct {
    TimingIdentity id;
    uint32_t entry, read_done, model_done, accept_done, ack_begin, ack_done, irq_end;
    uint32_t before_phase, after_phase, before_id, after_id;
    uint32_t applied_version, applied_target, overrun_delta;
    uint32_t events;
    bool valid, model_ran, safety_reentry, attempted, accepted, applied_coherent;
} TimingFrame;

typedef struct {
    TimingIdentity peak;
    uint64_t sum;
    uint32_t count, min, max;
} TimingRange;

typedef struct {
    TimingRange ranges[TIMING_RATES][TIMING_METRICS];
    TimingIdentity first, last, first_event, expected, last_checked, receipt_frame;
    uint64_t start_tick;
    uint32_t capture_id, delay_ms, duration_ms, frames, valid, missing, discontinuities;
    uint32_t rejects, late_or_target, overruns, invalid, transitions, unbracketed;
    uint32_t applied, receipt_errors, receipt_unresolved, spurious, bad_snapshots;
    uint32_t first_events, max_foreground_mask;
    uint32_t receipt_version, receipt_target;
    bool active, anchored, detailed, have_expected, receipt_coherent;
} TimingWindow;

enum TimingRate ax04b_timing_rate(bool advanced, bool speed, bool position);
void ax04b_timing_start(TimingWindow *w, uint32_t delay_ms, uint32_t duration_ms, bool detailed);
void ax04b_timing_freeze(TimingWindow *w);
bool ax04b_timing_collect(TimingWindow *w, uint64_t tick);
void ax04b_timing_event(TimingWindow *w, const TimingIdentity *id, uint32_t events);
void ax04b_timing_observe(TimingWindow *w, TimingFrame *frame, bool collect);
void ax04b_timing_irq_end(TimingWindow *w, const TimingFrame *frame);

bool motor_control_timing_start(uint32_t delay_ms, uint32_t duration_ms, bool detailed);
void motor_control_timing_freeze(void);
bool motor_control_timing_info(uint32_t *capture_id, uint32_t *count);
const TimingWindow *motor_control_timing_summary(void);
const TimingFrame *motor_control_timing_read(uint32_t capture_id, uint32_t index);
uint32_t motor_control_timing_clock(uint32_t *divisor);
