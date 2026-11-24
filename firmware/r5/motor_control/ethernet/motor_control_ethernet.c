#include "motor_control_ethernet.h"
#include "ax04b_registers.h"
#ifdef AX04B_TIMING
#include "ax04b_timing.h"
#endif
#include <ctype.h>
#include <errno.h>
#include <inttypes.h>
#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum { PROTOCOL_VERSION = 1, LINE_SIZE = 192, TRACE_BATCH = 2, TRACE_INTERVAL_MS = 2 };

typedef struct {
    char *buffer;
    size_t capacity, used;
} Response;

static uint32_t app_id, hardware_profile, link_speed;

static void append(Response *response, const char *format, ...)
{
    if (response->used >= response->capacity) {
        return;
    }
    const size_t available = response->capacity - response->used;
    va_list args;
    va_start(args, format);
    const int result = vsnprintf(response->buffer + response->used, available, format, args);
    va_end(args);
    if (result < 0 || (size_t)result >= available) {
        response->used = response->capacity;
    } else {
        response->used += (size_t)result;
    }
}

static void number(Response *response, const char *name, double value)
{
    if (isfinite(value)) {
        append(response, ",\"%s\":%.17g", name, value);
    } else {
        append(response, ",\"%s\":null", name);
    }
}

#define UINT_FIELD(obj, field) append(response, ",\"" #field "\":%" PRIu32, (uint32_t)(obj)->field)
#define REAL_FIELD(obj, field) number(response, #field, (obj)->field)
#define BOOL_FIELD(obj, field) append(response, ",\"" #field "\":%s", (obj)->field ? "true" : "false")

static void write_status(Response *response, const Ax05aControlStatus *status)
{
    UINT_FIELD(status, selected_revision);
    UINT_FIELD(status, confirmed_revision);
    UINT_FIELD(status, dispatched_revision);
    UINT_FIELD(status, selected_mode);
    BOOL_FIELD(status, selection_confirmed);
    BOOL_FIELD(status, armed);
    BOOL_FIELD(status, clear_confirmed);
    BOOL_FIELD(status, stop_pending);
}

static void write_sample(Response *response, const Ax05aSample *sample)
{
    append(response, "{\"sample_id\":%" PRIu32 ",\"tick\":%" PRIu64,
        sample->sample_id, sample->tick);
    UINT_FIELD(sample, schema);
    UINT_FIELD(sample, groups);
    UINT_FIELD(sample, pl_sequence);
    UINT_FIELD(sample, dq_extension_id);
    UINT_FIELD(sample, adc_quality);
    UINT_FIELD(sample, adc_calibration_version);
    UINT_FIELD(sample, foc_reference_version);
    BOOL_FIELD(sample, current_valid);
    BOOL_FIELD(sample, calibration_done_a);
    BOOL_FIELD(sample, calibration_done_b);
    BOOL_FIELD(sample, encoder_angle_valid);
    REAL_FIELD(sample, ia_a);
    REAL_FIELD(sample, ib_a);
    REAL_FIELD(sample, ic_a);
    REAL_FIELD(sample, id_ref_a);
    REAL_FIELD(sample, iq_ref_a);
    REAL_FIELD(sample, id_a);
    REAL_FIELD(sample, iq_a);
    REAL_FIELD(sample, ud_v);
    REAL_FIELD(sample, uq_v);
    REAL_FIELD(sample, offset_a_counts);
    REAL_FIELD(sample, offset_b_counts);
    REAL_FIELD(sample, encoder_angle_rad);
    REAL_FIELD(sample, electrical_angle_rad);
    const Ax05aPsFrame *ps = &sample->ps;
    UINT_FIELD(ps, command_revision);
    UINT_FIELD(ps, mode);
    UINT_FIELD(ps, alignment_state);
    UINT_FIELD(ps, quality);
    UINT_FIELD(ps, fault);
    UINT_FIELD(ps, stop_reason);
    UINT_FIELD(ps, host_status);
    UINT_FIELD(ps, host_receipt_revision);
    UINT_FIELD(ps, commit_version);
    UINT_FIELD(ps, commit_target);
    UINT_FIELD(ps, commit_result);
    UINT_FIELD(ps, accepted_version);
    UINT_FIELD(ps, accepted_target);
    UINT_FIELD(ps, p0_version);
    UINT_FIELD(ps, p0_target);
    BOOL_FIELD(ps, position_valid);
    BOOL_FIELD(ps, speed_valid);
    BOOL_FIELD(ps, reference_permitted);
    BOOL_FIELD(ps, host_ready);
    BOOL_FIELD(ps, alignment_done);
    BOOL_FIELD(ps, commit_accepted);
    BOOL_FIELD(ps, p0_valid);
    REAL_FIELD(ps, position_mm);
    REAL_FIELD(ps, speed_mm_s);
    REAL_FIELD(ps, position_ref_mm);
    REAL_FIELD(ps, speed_ref_mm_s);
    REAL_FIELD(ps, position_loop_speed_ref_mm_s);
    REAL_FIELD(ps, fine_phase_rad);
    REAL_FIELD(ps, auto_phase_rad);
    append(response, "}");
}

static void write_diagnostics(Response *response, const Ax05aDiagnostics *diag)
{
    UINT_FIELD(diag, sequence);
    UINT_FIELD(diag, status);
    UINT_FIELD(diag, irq_frames);
    UINT_FIELD(diag, exact_ack_count);
    UINT_FIELD(diag, overruns);
    UINT_FIELD(diag, commits);
    UINT_FIELD(diag, rejects);
    UINT_FIELD(diag, stop_reason);
    UINT_FIELD(diag, rt_sample_id);
    append(response, ",\"rt_tick\":%" PRIu64, diag->rt_tick);
    UINT_FIELD(diag, rt_quality);
    UINT_FIELD(diag, rt_fault);
    UINT_FIELD(diag, rt_drive_flags);
    UINT_FIELD(diag, rt_ctrl_enable);
    UINT_FIELD(diag, pwm_status);
    UINT_FIELD(diag, pwm_adopted_sequence);
    UINT_FIELD(diag, pwm_period);
    UINT_FIELD(diag, pwm_deadtime);
    UINT_FIELD(diag, pwm_use_permission);
    BOOL_FIELD(diag, pwm_receipt_coherent);
    append(response, ",\"pwm_compare\":[%" PRIu32 ",%" PRIu32 ",%" PRIu32 "],\"words\":[",
        diag->pwm_compare[0], diag->pwm_compare[1], diag->pwm_compare[2]);
    for (size_t i = 0; i < sizeof(diag->words) / sizeof(diag->words[0]); ++i) {
        append(response, "%s%" PRIu32, i ? "," : "", diag->words[i]);
    }
    append(response, "]");
}

static void write_trace_info(Response *response, const Ax05aTraceInfo *info)
{
    UINT_FIELD(info, schema);
    UINT_FIELD(info, application_id);
    UINT_FIELD(info, pl_interface_id);
    UINT_FIELD(info, hardware_profile);
    UINT_FIELD(info, pl_ticks_hz);
    UINT_FIELD(info, dq_extension_id);
    UINT_FIELD(info, channel_mask);
    UINT_FIELD(info, capture_id);
    UINT_FIELD(info, count);
    UINT_FIELD(info, missed);
    UINT_FIELD(info, duplicates);
    UINT_FIELD(info, first_groups);
    UINT_FIELD(info, first_mode);
    UINT_FIELD(info, first_command_revision);
    UINT_FIELD(info, first_foc_reference_version);
    REAL_FIELD(info, first_id_ref_a);
    REAL_FIELD(info, first_iq_ref_a);
    REAL_FIELD(info, first_offset_a_counts);
    REAL_FIELD(info, first_offset_b_counts);
    BOOL_FIELD(info, active);
    BOOL_FIELD(info, full);
    BOOL_FIELD(info, discontinuous);
}

static const char *skip_space(const char *text)
{
    while (isspace((unsigned char)*text)) {
        ++text;
    }
    return text;
}

static bool uint_arg(const char **text, uint32_t *value)
{
    const char *begin = skip_space(*text);
    if (!isdigit((unsigned char)*begin)) {
        return false;
    }
    char *end;
    errno = 0;
    const uintmax_t result = strtoumax(begin, &end, 10);
    if (errno != 0 || result > UINT32_MAX || (*end && !isspace((unsigned char)*end))) {
        return false;
    }
    *text = skip_space(end);
    *value = (uint32_t)result;
    return true;
}

#ifdef AX04B_TIMING
static void write_timing_identity(Response *response, const TimingIdentity *id)
{
    append(response, "{\"pl_tick\":%" PRIu64, id->pl_tick);
    UINT_FIELD(id, seq);
    UINT_FIELD(id, sample_id);
    UINT_FIELD(id, version);
    UINT_FIELD(id, target);
    UINT_FIELD(id, entry_phase);
    UINT_FIELD(id, mode);
    UINT_FIELD(id, result);
    UINT_FIELD(id, stop_reason);
    UINT_FIELD(id, rate);
    append(response, "}");
}

static void write_timing_frame(Response *response, const TimingFrame *f)
{
    append(response, "{\"frame\":");
    write_timing_identity(response, &f->id);
    UINT_FIELD(f, events);
    BOOL_FIELD(f, valid);
    BOOL_FIELD(f, model_ran);
    BOOL_FIELD(f, safety_reentry);
    BOOL_FIELD(f, read_done_valid);
    BOOL_FIELD(f, ack_done_valid);
    BOOL_FIELD(f, attempted);
    BOOL_FIELD(f, accepted);
    UINT_FIELD(f, entry);
    UINT_FIELD(f, read_done);
    UINT_FIELD(f, model_done);
    UINT_FIELD(f, accept_done);
    UINT_FIELD(f, ack_begin);
    UINT_FIELD(f, ack_done);
    UINT_FIELD(f, irq_end);
    UINT_FIELD(f, safety_begin);
    UINT_FIELD(f, safety_done);
    UINT_FIELD(f, before_phase);
    UINT_FIELD(f, after_phase);
    UINT_FIELD(f, before_id);
    UINT_FIELD(f, after_id);
    UINT_FIELD(f, accepted_version);
    UINT_FIELD(f, accepted_target);
    UINT_FIELD(f, expected_version);
    UINT_FIELD(f, expected_target);
    UINT_FIELD(f, applied_version);
    UINT_FIELD(f, applied_target);
    UINT_FIELD(f, overrun_delta);
    UINT_FIELD(f, pl_status);
    UINT_FIELD(f, feedback_status);
    UINT_FIELD(f, quality);
    UINT_FIELD(f, fault);
    BOOL_FIELD(f, applied_coherent);
    append(response, "}");
}

static void write_timing_summary(Response *response, const TimingWindow *w)
{
    static const char *const ends[] = {"open", "not_started", "early_stop", "elapsed"};
    uint32_t divisor;
    const uint32_t cpu_hz = motor_control_timing_clock(&divisor);
    append(response, ",\"timing_schema\":%u,\"cpu_hz\":%" PRIu32 ",\"pmu_divisor\":%" PRIu32
        ",\"pl_hz\":%u,\"irq_phase\":%u,\"deadline_phase\":%u,\"start_tick\":%" PRIu64
        ",\"end_reason\":\"%s\"",
        AX04B_TIMING_SCHEMA, cpu_hz, divisor, AX04B_PL_HZ, AX04B_IRQ_PHASE,
        AX04B_DEADLINE_PHASE, w->start_tick, ends[w->end_reason]);
    UINT_FIELD(w, delay_ms);
    UINT_FIELD(w, duration_ms);
    UINT_FIELD(w, planned_frames);
    UINT_FIELD(w, frames);
    UINT_FIELD(w, valid);
    UINT_FIELD(w, missing);
    UINT_FIELD(w, discontinuities);
    UINT_FIELD(w, rejects);
    UINT_FIELD(w, late_or_target);
    UINT_FIELD(w, overruns);
    UINT_FIELD(w, invalid);
    UINT_FIELD(w, transitions);
    UINT_FIELD(w, unbracketed);
    UINT_FIELD(w, applied);
    UINT_FIELD(w, receipt_errors);
    UINT_FIELD(w, receipt_unresolved);
    UINT_FIELD(w, spurious);
    UINT_FIELD(w, bad_snapshots);
    append(response, ",\"first_events\":%" PRIu32, w->first_anomaly.events);
    UINT_FIELD(w, max_foreground_mask);
    BOOL_FIELD(w, detailed);
    append(response, ",\"first\":");
    write_timing_identity(response, &w->first);
    append(response, ",\"last\":");
    write_timing_identity(response, &w->last);
    append(response, ",\"first_event\":");
    write_timing_identity(response, &w->first_anomaly.id);
    if (w->applied != 0u || w->receipt_errors != 0u) {
        append(response, ",\"last_checked\":");
        write_timing_identity(response, &w->last_checked);
        append(response, ",\"receipt_frame\":");
        write_timing_identity(response, &w->receipt_frame);
        UINT_FIELD(w, receipt_version);
        UINT_FIELD(w, receipt_target);
        BOOL_FIELD(w, receipt_coherent);
    }
}

static void write_timing_evidence(Response *response, const char *key, const TimingFrame *f)
{
    append(response, ",\"%s\":", key);
    if (f->events == 0u) {
        append(response, "null");
    } else {
        write_timing_frame(response, f);
    }
}

static const char *timing_dispatch(Response *response, const char *verb, const char *args)
{
    if (strcmp(verb, "timing-start") == 0) {
        uint32_t delay, duration, detail;
        if (!uint_arg(&args, &delay) || !uint_arg(&args, &duration) ||
            !uint_arg(&args, &detail) || *args || duration == 0u ||
            duration > UINT32_MAX / AX04B_FRAMES_PER_MS || detail > 1u) {
            return "BAD_REQUEST";
        }
        if (!motor_control_timing_start(delay, duration, detail != 0u)) {
            return "TRACE_BUSY";
        }
    } else if (strcmp(verb, "timing-stop") == 0) {
        if (*args) {
            return "BAD_REQUEST";
        }
        motor_control_timing_freeze();
    }
    uint32_t id, count;
    const bool active = motor_control_timing_info(&id, &count);
    append(response, ",\"capture_id\":%" PRIu32 ",\"count\":%" PRIu32 ",\"active\":%s",
        id, count, active ? "true" : "false");
    const TimingWindow *w = active ? NULL : motor_control_timing_summary();
    if (strcmp(verb, "timing-rate") == 0 || strcmp(verb, "timing-read") == 0) {
        uint32_t requested, index;
        if (!uint_arg(&args, &requested) || !uint_arg(&args, &index) || *args) {
            return "BAD_REQUEST";
        }
        if (w == NULL || requested != id) {
            return "TRACE_UNAVAILABLE";
        }
        if (strcmp(verb, "timing-rate") == 0) {
            if (index >= TIMING_RATES) {
                return "BAD_REQUEST";
            }
            append(response, ",\"rate\":%" PRIu32 ",\"metrics\":[", index);
            for (unsigned i = 0; i < TIMING_METRICS; ++i) {
                const TimingRange *r = &w->ranges[index][i];
                append(response, "%s{\"sum\":%" PRIu64, i ? "," : "", r->sum);
                UINT_FIELD(r, count);
                UINT_FIELD(r, min);
                UINT_FIELD(r, max);
                append(response, ",\"peak\":");
                write_timing_identity(response, &r->peak);
                append(response, "}");
            }
        } else {
            if (index > count) {
                return "TRACE_UNAVAILABLE";
            }
            append(response, ",\"index\":%" PRIu32 ",\"records\":[", index);
            const uint32_t end = count - index < TRACE_BATCH ? count : index + TRACE_BATCH;
            for (uint32_t i = index; i < end; ++i) {
                if (i != index) {
                    append(response, ",");
                }
                write_timing_frame(response, motor_control_timing_read(id, i));
            }
            append(response, "],\"next_index\":%" PRIu32, end);
            return NULL;
        }
        append(response, "]");
    } else if (strcmp(verb, "timing-evidence") == 0) {
        uint32_t requested;
        if (!uint_arg(&args, &requested) || *args) {
            return "BAD_REQUEST";
        }
        if (w == NULL || requested != id) {
            return "TRACE_UNAVAILABLE";
        }
        write_timing_evidence(response, "first_anomaly", &w->first_anomaly);
        write_timing_evidence(response, "anomaly_peak", &w->anomaly_peak);
        write_timing_evidence(response, "transition_peak", &w->transition_peak);
    } else if (strcmp(verb, "timing-status") == 0) {
        if (*args) {
            return "BAD_REQUEST";
        }
        if (w != NULL) {
            write_timing_summary(response, w);
        }
    } else if (strcmp(verb, "timing-start") != 0 && strcmp(verb, "timing-stop") != 0) {
        return "BAD_REQUEST";
    }
    return NULL;
}
#endif

static const char *dispatch(Response *response, const char *verb, const char *args)
{
#ifdef AX04B_TIMING
    if (strncmp(verb, "timing-", 7) == 0) {
        return timing_dispatch(response, verb, args);
    }
#endif
    if (strcmp(verb, "calibration-gains") == 0) {
        if (!motor_control_stage_real_gains(args)) {
            return "BAD_GAINS";
        }
        append(response, ",\"staged\":true");
        return NULL;
    }
    if (strcmp(verb, "command") == 0) {
        Ax05aRequest request;
        if (!motor_control_parse_request(args, &request)) {
            return "BAD_REQUEST";
        }
        const Ax05aReply reply = motor_control_submit(request);
        const Ax05aControlStatus status = ax05a_control_status();
        append(response, ",\"firmware_request_id\":%" PRIu32, reply.request_id);
        UINT_FIELD(&reply, decision);
        UINT_FIELD(&reply, accepted_revision);
        write_status(response, &status);
        return NULL;
    }
    if (strcmp(verb, "trace-start") == 0) {
        uint32_t groups;
        if (!uint_arg(&args, &groups) || *args || !groups || (groups & ~AX05A_ALL)) {
            return "BAD_REQUEST";
        }
        if (!ax05a_trace_start(groups)) {
            return "TRACE_BUSY";
        }
        const Ax05aTraceInfo info = ax05a_trace_info();
        write_trace_info(response, &info);
        return NULL;
    }
    if (strcmp(verb, "trace-read") == 0) {
        uint32_t id, index;
        if (!uint_arg(&args, &id) || !uint_arg(&args, &index) || *args) {
            return "BAD_REQUEST";
        }
        const Ax05aTraceInfo info = ax05a_trace_info();
        if (info.schema != AX05A_SCHEMA || info.active || id != info.capture_id || index > info.count) {
            return "TRACE_UNAVAILABLE";
        }
        append(response, ",\"capture_id\":%" PRIu32 ",\"index\":%" PRIu32 ",\"records\":[", id, index);
        unsigned count = 0;
        while (index < info.count && count < TRACE_BATCH) {
            Ax05aSample sample;
            if (!ax05a_trace_read(id, index, &sample)) {
                return "TRACE_UNAVAILABLE";
            }
            if (count) {
                append(response, ",");
            }
            write_sample(response, &sample);
            ++count;
            ++index;
        }
        append(response, "],\"next_index\":%" PRIu32, index);
        return NULL;
    }
    if (*args) {
        return "BAD_REQUEST";
    }
    if (strcmp(verb, "version") == 0) {
        append(response, ",\"protocol\":%u,\"schema\":%u,\"application_id\":%" PRIu32
            ",\"hardware_profile\":%" PRIu32 ",\"pl_interface_id\":%" PRIu32
            ",\"dq_extension_id\":%" PRIu32 ",\"link_mbps\":%" PRIu32,
            PROTOCOL_VERSION, AX05A_SCHEMA, app_id, hardware_profile, AX04B_INTERFACE_ID,
            AX05A_DQ_IDENT, link_speed);
#ifdef AX04B_TIMING
        append(response, ",\"timing_schema\":%u", AX04B_TIMING_SCHEMA);
#endif
    } else if (strcmp(verb, "status") == 0) {
        const Ax05aControlStatus status = ax05a_control_status();
        write_status(response, &status);
    } else if (strcmp(verb, "sample") == 0) {
        Ax05aSample sample;
        if (!ax05a_read_sample(&sample)) {
            return "NO_SAMPLE";
        }
        append(response, ",\"sample\":");
        write_sample(response, &sample);
    } else if (strcmp(verb, "diagnostics") == 0) {
        Ax05aDiagnostics diag;
        if (!ax05a_read_diagnostics(&diag)) {
            return "NO_DIAGNOSTICS";
        }
        write_diagnostics(response, &diag);
    } else if (strcmp(verb, "trace-status") == 0 || strcmp(verb, "trace-stop") == 0) {
        if (strcmp(verb, "trace-stop") == 0) {
            ax05a_trace_stop();
        }
        const Ax05aTraceInfo info = ax05a_trace_info();
        write_trace_info(response, &info);
    } else {
        return "BAD_REQUEST";
    }
    return NULL;
}

size_t motor_control_reply(char *out, size_t capacity, const uint8_t *bytes, size_t length)
{
    uint32_t id = 0;
    const char *error = "BAD_REQUEST";
    Response reply = {out, capacity, 0};
    if (length < LINE_SIZE && memchr(bytes, '\0', length) == NULL) {
        char line[LINE_SIZE];
        memcpy(line, bytes, length);
        line[length] = '\0';
        const char *text = line;
        if (uint_arg(&text, &id) && id && *text) {
            char *verb = line + (text - line);
            char *end = verb;
            while (*end && !isspace((unsigned char)*end)) {
                ++end;
            }
            const char *args = skip_space(end);
            *end = '\0';
            append(&reply, "{\"id\":%" PRIu32, id);
            error = dispatch(&reply, verb, args);
        }
    }
    if (error) {
        reply.used = 0;
        append(&reply, "{\"id\":%" PRIu32 ",\"error\":\"%s\"", id, error);
    }
    append(&reply, "}\n");
    return reply.used < capacity ? reply.used : 0;
}

void motor_control_net_identity(uint32_t application, uint32_t profile, uint32_t link_mbps)
{
    app_id = application;
    hardware_profile = profile;
    link_speed = link_mbps;
}

void motor_control_record_poll(uint32_t now_ms)
{
    static uint32_t previous;
    if (now_ms - previous >= TRACE_INTERVAL_MS) {
        previous = now_ms;
        (void)ax05a_trace_poll();
    }
}
