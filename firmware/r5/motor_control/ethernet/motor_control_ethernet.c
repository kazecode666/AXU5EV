#include "motor_control_ethernet.h"
#include "ax04b_registers.h"
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

static const char *dispatch(Response *response, const char *verb, const char *args)
{
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
