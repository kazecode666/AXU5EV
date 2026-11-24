/* Share the real R5 application and existing simulated PL feedback. */
#undef MOTOR_CONTROL_ETHERNET
#include "../verification/experiment/ax04b/test_r5_runtime.c"

#include "motor_control_ethernet.h"

#if defined(_WIN32)
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

static void observe(void)
{
    set_observation(pl.feedback.id, pl.feedback.tick);
    observation_seq = pl.feedback.sequence;
    observation[77] = AX05A_DQ_IDENT;
    observation[73] = 0x00080000u;
    observation[74] = 0xfff80000u;
    observation[75] = 0x00800000u;
    observation[76] = 0xff600000u;
    if (ax04b_build_mode == AX04B_REAL) {
        observation[41] = 0u; /* Inhibited REAL has no qualified FOC capture. */
    }
}

EXPORT void fixture_boot(void)
{
    boot();
    qualified_history();
    observe();
    motor_control_net_identity(ax04b_application_id, ax04b_build_mode, 1000);
}

EXPORT void fixture_advance(unsigned frames, uint32_t now_ms)
{
    for (unsigned i = 0; i < frames; ++i) {
        frame(true);
    }
    observe();
    motor_control_record_poll(now_ms);
}

#ifdef AX04B_TIMING
EXPORT void fixture_reject_late(void)
{
    pl.reject_next = AX04B_COMMIT_LATE;
}

EXPORT void fixture_check_timing_math(void)
{
    (void)timing_mask_start; /* The host copy substitutes IRQ primitives. */
    TimingWindow w = {0};
    ax04b_timing_start(&w, 1, 1, false);
    assert(!ax04b_timing_collect(&w, UINT64_MAX - 49999u));
    assert(ax04b_timing_collect(&w, 0u));
    TimingFrame first = {
        .id = {.seq = UINT32_MAX, .sample_id = UINT32_MAX - 499u,
            .version = UINT32_MAX, .target = 0u, .entry_phase = 79,
            .rate = TIMING_POSITION},
        .valid = true, .entry = UINT32_MAX - 10u, .read_done = 1, .model_done = 2,
        .accept_done = 6, .ack_begin = 7, .ack_done = 10, .irq_end = 12,
        .before_phase = 4900, .after_phase = 4987,
        .before_id = UINT32_MAX - 499u, .after_id = UINT32_MAX - 499u
    };
    ax04b_timing_observe(&w, &first, true);
    ax04b_timing_irq_end(&w, &first);
    TimingRange *range = w.ranges[TIMING_POSITION];
    assert(range[TIMING_READ].max == 12 && range[TIMING_IRQ].max == 23);
    assert(range[TIMING_UPPER].max == 4908 && range[TIMING_LOWER].max == 4825);
    TimingFrame next = {.id = {.pl_tick = 5000}, .applied_version = UINT32_MAX,
        .applied_coherent = true, .events = TIMING_INVALID};
    ax04b_timing_observe(&w, &next, true);
    assert(w.applied == 1 && w.receipt_errors == 0 && w.valid == 1 && w.invalid == 1);
    assert(w.ranges[TIMING_BASE][TIMING_MODEL].count == 0);
    TimingFrame late = {.id = {.pl_tick = 15000, .seq = 2, .sample_id = 1000,
        .result = AX04B_COMMIT_LATE}, .attempted = true, .overrun_delta = 1};
    ax04b_timing_observe(&w, &late, true);
    assert(w.missing == 1 && w.discontinuities == 1 && w.rejects == 1 && w.overruns == 1);
    next.id = (TimingIdentity){.seq = 3, .pl_tick = 20000, .sample_id = 1500,
        .version = 0u, .target = 2000};
    next.valid = true;
    ax04b_timing_observe(&w, &next, true);
    assert(w.unbracketed == 1);
    ax04b_timing_freeze(&w);
    assert(w.receipt_unresolved == 1 && !w.active);
}
#endif
