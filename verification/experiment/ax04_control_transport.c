/* Test transport to the exact experiment-model generated C. */
#include <string.h>
#include "ax04_control_transport.h"
#include "AXU5EV_Motor_Control_System.h"

#ifndef AX04_IRQ_FUNCTION
#define AX04_IRQ_FUNCTION PL_Frame_IRQ
#endif

#ifndef AX04_SERVICE_FUNCTION
#define AX04_SERVICE_FUNCTION Service_Request
#endif

void ax04_control_initialize(void)
{
    AXU5EV_Motor_Control_System_initialize();
}

void ax04_control_irq(const double command_frame[20], uint32_t raw_count,
    uint32_t sample_id, uint64_t sample_tick, bool encoder_ready,
    uint32_t illegal_count, bool current_valid, bool erri_n, bool erru_n,
    bool clear_fault, bool request_relcon, bool request_encon,
    bool request_freset, bool request_oe_disable)
{
    memcpy(AXU5EV_Motor_Control_System_U.CommandFrame, command_frame,
        sizeof(AXU5EV_Motor_Control_System_U.CommandFrame));
    AXU5EV_Motor_Control_System_U.raw_count = raw_count;
    AXU5EV_Motor_Control_System_U.sample_id = sample_id;
    AXU5EV_Motor_Control_System_U.sample_tick = sample_tick;
    AXU5EV_Motor_Control_System_U.encoder_ready = encoder_ready;
    AXU5EV_Motor_Control_System_U.illegal_count = illegal_count;
    AXU5EV_Motor_Control_System_U.current_valid = current_valid;
    AXU5EV_Motor_Control_System_U.ERRI_n = erri_n;
    AXU5EV_Motor_Control_System_U.ERRU_n = erru_n;
    AXU5EV_Motor_Control_System_U.clear_fault = clear_fault;
    AXU5EV_Motor_Control_System_U.request_relcon = request_relcon;
    AXU5EV_Motor_Control_System_U.request_encon = request_encon;
    AXU5EV_Motor_Control_System_U.request_freset = request_freset;
    AXU5EV_Motor_Control_System_U.request_oe_disable = request_oe_disable;
    AX04_IRQ_FUNCTION();
}

void ax04_control_service(void)
{
    AX04_SERVICE_FUNCTION();
}

void ax04_control_read(ax04_control_observation *observation)
{
    memcpy(observation->runtime_frame, AXU5EV_Motor_Control_System_Y.runtime_frame,
        sizeof(observation->runtime_frame));
    observation->position_mm = AXU5EV_Motor_Control_System_Y.position_mm;
    observation->speed_mm_s = AXU5EV_Motor_Control_System_Y.speed_mm_s;
    observation->position_valid = AXU5EV_Motor_Control_System_Y.position_valid;
    observation->speed_valid = AXU5EV_Motor_Control_System_Y.speed_valid;
    observation->history_count = AXU5EV_Motor_Control_System_Y.history_count;
    observation->feedback_status = AXU5EV_Motor_Control_System_Y.feedback_status;
    observation->continuous_count = AXU5EV_Motor_Control_System_Y.continuous_count;
    memcpy(observation->reference_commit, AXU5EV_Motor_Control_System_Y.reference_commit,
        sizeof(observation->reference_commit));
    observation->commit_sample_id = AXU5EV_Motor_Control_System_Y.commit_sample_id;
    observation->reference_version = AXU5EV_Motor_Control_System_Y.reference_version;
    for (int index = 0; index < 5; ++index) {
        observation->drive_outputs[index] = AXU5EV_Motor_Control_System_Y.drive_outputs[index];
    }
    memcpy(observation->telemetry, AXU5EV_Motor_Control_System_Y.telemetry,
        sizeof(observation->telemetry));
    observation->service_count = AXU5EV_Motor_Control_System_Y.service_count;
}
