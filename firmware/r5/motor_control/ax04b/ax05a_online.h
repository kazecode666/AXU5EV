#ifndef AX05A_ONLINE_H
#define AX05A_ONLINE_H

#include <stdbool.h>
#include <stdint.h>

#define AX05A_SCHEMA 1u
#define AX05A_TRACE_CAPACITY 256u
#define AX05A_DQ_IDENT UINT32_C(0x41583501)

typedef enum {
    AX05A_IDLE, AX05A_CURRENT, AX05A_SPEED, AX05A_POSITION, AX05A_ALIGNMENT
} Ax05aMode;

typedef enum {
    AX05A_SELECT, AX05A_SETPOINT, AX05A_CONFIRM, AX05A_START, AX05A_STOP,
    AX05A_ARM, AX05A_ALIGN_START, AX05A_ALIGN_RESET, AX05A_CALIBRATE,
    AX05A_FINE_PHASE, AX05A_PI_RESET, AX05A_CLEAR, AX05A_DRIVER_RESET
} Ax05aAction;

typedef enum {
    AX05A_ACCEPTED, AX05A_BAD_REQUEST, AX05A_OUT_OF_RANGE, AX05A_STOP_FIRST,
    AX05A_NOT_READY, AX05A_REAL_INHIBITED, AX05A_PENDING, AX05A_PL_DENIED
} Ax05aDecision;

typedef struct {
    uint32_t schema, request_id;
    Ax05aAction action;
    Ax05aMode mode;
    uint32_t selected_revision;
    double position_mm, speed_mm_s, id_a, iq_a, fine_phase_rad;
} Ax05aRequest;

typedef struct {
    uint32_t request_id, accepted_revision;
    Ax05aDecision decision;
} Ax05aReply;

typedef struct {
    uint32_t selected_revision, confirmed_revision, dispatched_revision;
    Ax05aMode selected_mode;
    bool selection_confirmed, armed, clear_confirmed, stop_pending;
} Ax05aControlStatus;

enum {
    AX05A_PS = 1u, AX05A_ADC = 2u, AX05A_FOC_REF = 4u, AX05A_DQ = 8u,
    AX05A_ALL = AX05A_PS | AX05A_ADC | AX05A_FOC_REF | AX05A_DQ
};

typedef struct {
    uint32_t sample_id;
    uint64_t tick;
    uint32_t command_revision, quality, fault, stop_reason, mode, alignment_state;
    uint32_t commit_version, commit_target, commit_result, accepted_version, accepted_target;
    uint32_t p0_version, p0_target, host_status, host_receipt_revision;
    double position_mm, speed_mm_s, position_ref_mm, speed_ref_mm_s, position_loop_speed_ref_mm_s;
    double selected_position_mm, selected_speed_mm_s, selected_id_a, selected_iq_a;
    double fine_phase_rad, auto_phase_rad;
    bool position_valid, speed_valid, reference_permitted, commit_accepted, p0_valid;
    bool host_ready, alignment_done;
} Ax05aPsFrame;

typedef struct {
    uint32_t schema, groups, pl_sequence, dq_extension_id;
    uint32_t sample_id;
    uint64_t tick;
    Ax05aPsFrame ps;
    uint32_t adc_quality, adc_calibration_version;
    bool current_valid, calibration_done_a, calibration_done_b, encoder_angle_valid;
    double ia_a, ib_a, ic_a, offset_a_counts, offset_b_counts;
    double encoder_angle_rad;
    uint32_t foc_reference_version;
    double id_ref_a, iq_ref_a, electrical_angle_rad;
    double id_a, iq_a, ud_v, uq_v;
} Ax05aSample;

typedef struct {
    uint32_t sequence, words[80];
    uint32_t status, irq_frames, exact_ack_count, overruns, commits, rejects, stop_reason;
    uint32_t rt_sample_id, rt_quality, rt_fault, rt_drive_flags, rt_ctrl_enable;
    uint64_t rt_tick;
    uint32_t pwm_status, pwm_adopted_sequence, pwm_compare[3], pwm_period, pwm_deadtime, pwm_use_permission;
    bool pwm_receipt_coherent;
} Ax05aDiagnostics;

typedef struct {
    uint32_t schema, application_id, pl_interface_id, hardware_profile;
    uint32_t pl_ticks_hz, channel_mask, capture_id, count, missed, duplicates, dq_extension_id;
    uint32_t first_groups, first_mode, first_command_revision, first_foc_reference_version;
    double first_id_ref_a, first_iq_ref_a, first_offset_a_counts, first_offset_b_counts;
    bool active, full, discontinuous;
} Ax05aTraceInfo;

/* All calls belong to one foreground owner. They are not wire structs. */
/* Keep callable entry points in the target ELF for the no-power debugger. */
#define AX05A_API __attribute__((noinline))
AX05A_API Ax05aReply ax05a_submit(const Ax05aRequest *request);
AX05A_API Ax05aControlStatus ax05a_control_status(void);
AX05A_API bool ax05a_read_sample(Ax05aSample *sample);
AX05A_API bool ax05a_read_diagnostics(Ax05aDiagnostics *diagnostics);
AX05A_API bool ax05a_trace_start(uint32_t groups);
AX05A_API bool ax05a_trace_poll(void);
AX05A_API void ax05a_trace_stop(void);
AX05A_API Ax05aTraceInfo ax05a_trace_info(void);
AX05A_API bool ax05a_trace_read(uint32_t capture_id, uint32_t index, Ax05aSample *sample);
#undef AX05A_API

#endif
