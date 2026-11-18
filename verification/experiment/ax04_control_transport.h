#ifndef AX04_CONTROL_TRANSPORT_H
#define AX04_CONTROL_TRANSPORT_H

#include <stdbool.h>
#include <stdint.h>

typedef struct {
    double runtime_frame[41];
    double position_mm;
    double speed_mm_s;
    bool position_valid;
    bool speed_valid;
    uint8_t history_count;
    uint32_t feedback_status;
    int64_t continuous_count;
    double reference_commit[8];
    uint32_t commit_sample_id;
    uint32_t reference_version;
    bool drive_outputs[5];
    double telemetry[12];
    uint32_t service_count;
} ax04_control_observation;

void ax04_control_initialize(void);
void ax04_control_irq(const double command_frame[20], uint32_t raw_count,
    uint32_t sample_id, uint64_t sample_tick, bool encoder_ready,
    uint32_t illegal_count, bool current_valid, bool erri_n, bool erru_n,
    bool clear_fault, bool request_relcon, bool request_encon,
    bool request_freset, bool request_oe_disable);
void ax04_control_service(void);
void ax04_control_read(ax04_control_observation *observation);

#endif
