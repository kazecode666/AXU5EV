/* Test-only transport to the exact model-generated ARM-target numerical C. */
#include <stdbool.h>
#include "AXU5EV_Encoder_Feedback.h"

void task1_encoder_step(unsigned int raw_count, unsigned int sample_id,
    unsigned long long sample_tick, bool encoder_ready,
    unsigned int illegal_count, unsigned int zero_count, bool reverse,
    unsigned int config_version, unsigned int nm_per_count, bool reset,
    double *position, double *speed, bool *position_valid, bool *speed_valid,
    unsigned char *history_count, unsigned int *status, long long *continuous_count)
{
    static bool initialized = false;
    if (!initialized) {
        AXU5EV_Encoder_Feedback_initialize();
        initialized = true;
    }
    AXU5EV_Encoder_Feedback_U.raw_count = raw_count;
    AXU5EV_Encoder_Feedback_U.sample_id = sample_id;
    AXU5EV_Encoder_Feedback_U.sample_tick = sample_tick;
    AXU5EV_Encoder_Feedback_U.encoder_ready = encoder_ready;
    AXU5EV_Encoder_Feedback_U.illegal_count = illegal_count;
    AXU5EV_Encoder_Feedback_U.zero_count = zero_count;
    AXU5EV_Encoder_Feedback_U.reverse = reverse;
    AXU5EV_Encoder_Feedback_U.config_version = config_version;
    AXU5EV_Encoder_Feedback_U.nm_per_count = nm_per_count;
    AXU5EV_Encoder_Feedback_U.reset = reset;
    AXU5EV_Encoder_Feedback_step();
    *position = AXU5EV_Encoder_Feedback_Y.position_mm;
    *speed = AXU5EV_Encoder_Feedback_Y.speed_mm_s;
    *position_valid = AXU5EV_Encoder_Feedback_Y.position_valid;
    *speed_valid = AXU5EV_Encoder_Feedback_Y.speed_valid;
    *history_count = AXU5EV_Encoder_Feedback_Y.history_count;
    *status = AXU5EV_Encoder_Feedback_Y.status;
    *continuous_count = AXU5EV_Encoder_Feedback_Y.continuous_count;
}
