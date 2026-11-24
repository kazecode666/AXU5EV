#include "ax04b_timing.h"
#include "ax04b_registers.h"

enum TimingRate ax04b_timing_rate(bool advanced, bool speed, bool position)
{
    if (!advanced) {
        return TIMING_BASE;
    }
    return position ? TIMING_POSITION : (speed ? TIMING_SPEED : TIMING_BASE);
}

void ax04b_timing_start(TimingWindow *w, uint32_t delay_ms, uint32_t duration_ms, bool detailed)
{
    const uint32_t id = w->capture_id + 1u;
    *w = (TimingWindow){.capture_id = id, .delay_ms = delay_ms, .duration_ms = duration_ms,
        .detailed = detailed, .active = true};
}

void ax04b_timing_freeze(TimingWindow *w)
{
    if (w->have_expected) {
        ++w->receipt_unresolved;
        w->have_expected = false;
    }
    w->active = false;
}

bool ax04b_timing_collect(TimingWindow *w, uint64_t tick)
{
    if (!w->anchored) {
        w->anchored = true;
        w->start_tick = tick + (uint64_t)w->delay_ms * (AX04B_PL_HZ / 1000);
    }
    /* Unsigned offsets work across a 64-bit PL tick wrap. */
    return tick - w->start_tick < (uint64_t)w->duration_ms * (AX04B_PL_HZ / 1000);
}

void ax04b_timing_event(TimingWindow *w, const TimingIdentity *id, uint32_t events)
{
    if ((events & ~TIMING_TRANSITION) != 0u && w->first_events == 0u) {
        w->first_events = events;
        w->first_event = *id;
    }
    w->spurious += (events & TIMING_SPURIOUS) != 0u;
    w->bad_snapshots += (events & TIMING_SNAPSHOT) != 0u;
}

static void range(TimingWindow *w, const TimingIdentity *id, enum TimingMetric metric, uint32_t value)
{
    TimingRange *r = &w->ranges[id->rate][metric];
    if (r->count == 0u || value > r->max) {
        r->max = value;
        r->peak = *id;
    }
    if (r->count == 0u || value < r->min) {
        r->min = value;
    }
    ++r->count;
    r->sum += value;
}

void ax04b_timing_observe(TimingWindow *w, TimingFrame *f, bool collect)
{
    const TimingIdentity *id = &f->id;
    if (w->have_expected) {
        w->last_checked = w->expected;
        w->receipt_frame = *id;
        w->receipt_version = f->applied_version;
        w->receipt_target = f->applied_target;
        w->receipt_coherent = f->applied_coherent;
        if (id->seq - w->expected.seq == 1u && id->sample_id == w->expected.target &&
            id->pl_tick - w->expected.pl_tick == AX04B_TICK_STEP && f->applied_coherent &&
            f->applied_target == id->sample_id && f->applied_version == w->expected.version) {
            ++w->applied;
        } else {
            ++w->receipt_errors;
            f->events |= TIMING_RECEIPT;
            ax04b_timing_event(w, &w->expected, TIMING_RECEIPT);
        }
        w->have_expected = false;
    }
    if (!collect) {
        /* The first frame beyond the planned interval supplies the last P0 receipt. */
        if (id->pl_tick - w->start_tick < (UINT64_C(1) << 63)) {
            const uint64_t slots = (uint64_t)w->duration_ms * (AX04B_PL_HZ / 1000 / AX04B_FRAME_CYCLES);
            const uint64_t covered = w->frames != 0u ?
                (w->last.pl_tick - w->start_tick) / AX04B_TICK_STEP + 1u : 0u;
            if (slots > covered) {
                w->missing += (uint32_t)(slots - covered);
                ax04b_timing_event(w, id, TIMING_GAP);
            }
            ax04b_timing_freeze(w);
        }
        return;
    }
    if (w->frames == 0u) {
        w->first = *id;
        const uint64_t gap = id->pl_tick - w->start_tick;
        w->missing += (uint32_t)(gap / AX04B_TICK_STEP);
        if (gap >= AX04B_TICK_STEP) {
            f->events |= TIMING_GAP;
        }
    } else {
        const uint32_t step = id->seq - w->last.seq;
        if (step != 1u || id->sample_id - w->last.sample_id != AX04B_ID_STEP ||
            id->pl_tick - w->last.pl_tick != AX04B_TICK_STEP) {
            f->events |= TIMING_GAP;
            ++w->discontinuities;
            if (step > 1u && step < (UINT32_C(1) << 31)) {
                w->missing += step - 1u;
            }
        }
    }
    w->last = *id;
    ++w->frames;
    w->overruns += f->overrun_delta;
    w->transitions += (f->events & TIMING_TRANSITION) != 0u;
    w->invalid += (f->events & TIMING_INVALID) != 0u;
    if (f->attempted && !f->accepted) {
        f->events |= TIMING_REJECT;
        ++w->rejects;
        w->late_or_target += id->result == AX04B_COMMIT_LATE;
    }
    if (f->valid) {
        ++w->valid;
        range(w, id, TIMING_READ, f->read_done - f->entry);
        range(w, id, TIMING_MODEL, f->model_done - f->read_done);
        range(w, id, TIMING_SUBMIT, f->accept_done - f->model_done);
        range(w, id, TIMING_ACK, f->ack_done - f->ack_begin);
        w->expected = *id;
        w->have_expected = true;
        /* PHASE returns pre-edge p0_age. The AR sampling edge is age + 1.
         * P0_ID is read before the first and after the second PHASE read. */
        if (f->before_id == id->sample_id && f->after_id == id->sample_id &&
            id->entry_phase >= AX04B_IRQ_PHASE - 1 && id->entry_phase <= f->before_phase &&
            f->before_phase < AX04B_DEADLINE_PHASE &&
            f->before_phase <= f->after_phase && f->after_phase < AX04B_FRAME_CYCLES - 1) {
            range(w, id, TIMING_ENTRY, id->entry_phase + 1u - AX04B_IRQ_PHASE);
            range(w, id, TIMING_LOWER, f->before_phase + 1u - AX04B_IRQ_PHASE);
            const uint32_t upper = f->after_phase + 1u;
            range(w, id, TIMING_UPPER, (upper < AX04B_DEADLINE_PHASE ?
                upper : AX04B_DEADLINE_PHASE) - AX04B_IRQ_PHASE);
        } else {
            f->events |= TIMING_UNBRACKETED;
            ++w->unbracketed;
        }
    }
    ax04b_timing_event(w, id, f->events);
}

void ax04b_timing_irq_end(TimingWindow *w, const TimingFrame *f)
{
    if (f->valid) {
        range(w, &f->id, TIMING_IRQ, f->irq_end - f->entry);
    }
}
