#include "ax04b_adapter.h"
#include "ax04b_registers.h"

#include "AXU5EV_Motor_Control_System.h"
#include <float.h>
#include <limits.h>
#include <math.h>
#include <string.h>

_Static_assert(sizeof(double) == 8 && DBL_MANT_DIG == 53,
    "AX04B ERT requires IEEE binary64");
_Static_assert(sizeof(int64_t) == 8 && sizeof(uint64_t) == 8,
    "AX04B transports full-width signed Q values and uint64 timestamps");
_Static_assert(sizeof(AXU5EV_Motor_Control_System_U.CommandFrame) ==
    sizeof(((Ax04bCommand *)0)->frame), "ERT command interface mismatch");
_Static_assert(sizeof(AXU5EV_Motor_Control_System_Y.reference_commit) ==
    sizeof(((Ax04bModelResult *)0)->value), "ERT reference interface mismatch");
_Static_assert(sizeof(AXU5EV_Motor_Control_System_Y.telemetry) ==
    AX04B_TELEMETRY_WORDS * sizeof(double), "ERT service interface mismatch");

uint64_t ax04b_join_words(uint32_t low, uint32_t high)
{
    return ((uint64_t)high << 32) | low;
}

bool ax04b_current_qualified(const Ax04bFeedback *feedback)
{
    const uint32_t required = AX04B_CURRENT_VALID | AX04B_CAL_DONE_A |
        AX04B_CAL_DONE_B | AX04B_CAPTURE_A | AX04B_CAPTURE_B | AX04B_PAIR_COMPLETE;
    return (feedback->quality & (required | AX04B_CLIP)) == required;
}

bool ax04b_feedback_contract(const Ax04bFeedback *feedback, unsigned mode)
{
    const bool test = (feedback->quality & AX04B_TEST_SOURCE) != 0u;
    /* The PR46 ERT instance has its encoder direction set to forward. */
    return (mode == AX04B_SELFTEST || mode == AX04B_REAL) &&
        test == (mode == AX04B_SELFTEST) &&
        (feedback->quality & AX04B_ENCODER_REVERSE) == 0u;
}

Ax04bDispatch ax04b_dispatch(const Ax04bFeedback *previous,
    const Ax04bFeedback *feedback, bool safety_request)
{
    if (previous == NULL || feedback->id != previous->id ||
        feedback->tick != previous->tick) {
        return AX04B_NEW_FRAME;
    }
    if (safety_request || feedback->quality != previous->quality ||
        feedback->fault != previous->fault || feedback->raw_count != previous->raw_count ||
        feedback->illegal_count != previous->illegal_count ||
        feedback->calibration_version != previous->calibration_version ||
        feedback->config_version != previous->config_version) {
        return AX04B_SAFETY_DUPLICATE;
    }
    return AX04B_DUPLICATE;
}

/* Explicit nearest/even rounding, with saturation before a narrowing cast.
 * The 32-bit currents and 40-bit signed quantities fit exactly in a binary64
 * integer significand. No dependency on the current FPU rounding-mode flags. */
static int64_t signed_fixed(double value, double scale, int64_t minimum, int64_t maximum)
{
    const double scaled = value * scale;
    if (scaled <= (double)minimum) {
        return minimum;
    }
    if (scaled >= (double)maximum) {
        return maximum;
    }
    const double magnitude = fabs(scaled);
    int64_t result = (int64_t)magnitude;
    const double fraction = magnitude - (double)result;
    if (fraction > 0.5 || (fraction == 0.5 && (result & INT64_C(1)) != 0)) {
        ++result;
    }
    return scaled < 0.0 ? -result : result;
}

static void split_signed(int64_t value, uint32_t words[2])
{
    const uint64_t bits = (uint64_t)value;
    words[0] = (uint32_t)bits;
    words[1] = (uint32_t)(bits >> 32);
}

static int64_t phase_bias_q32(double radians)
{
    const double turn = 0x1.921fb54442d18p+2;
    const int64_t turn_q32 = INT64_C(26986075409);
    /* The generated Stateflow offset is already in this interval. Normalize
     * other finite inputs and fold a value that rounds to the upper bound. */
    if (radians < 0.0 || radians >= turn) {
        radians = fmod(radians, turn);
        if (radians < 0.0) {
            radians += turn;
        }
    }
    const int64_t rounded = signed_fixed(radians, 0x1p32, 0, turn_q32);
    return rounded == turn_q32 ? 0 : rounded;
}

void ax04b_safe_reference(uint32_t feedback_id, uint32_t version,
    Ax04bReference *reference)
{
    memset(reference, 0, sizeof(*reference));
    reference->target = feedback_id + AX04B_ID_STEP;
    reference->word[6] = AX04B_PI_RESET | AX04B_OE_DISABLE;
    reference->word[7] = version;
}

bool ax04b_encode_reference(const Ax04bModelResult *model, uint32_t feedback_id,
    uint32_t version, bool allow_drive, Ax04bReference *reference)
{
    const double *const value = model->value;
    ax04b_safe_reference(feedback_id, version, reference);
    for (unsigned i = 0u; i < 4u; ++i) {
        if (!isfinite(value[i])) {
            return false;
        }
    }
    for (unsigned i = 4u; i < AX04B_MODEL_REF_WORDS; ++i) {
        if (value[i] != 0.0 && value[i] != 1.0) {
            return false;
        }
    }
    if (model->drives[2]) {
        if (allow_drive) {
            reference->word[6] = AX04B_PI_RESET | AX04B_F_RESET |
                (model->drives[3] ? AX04B_OE_DISABLE : 0u);
        }
        return true;
    }
    if (value[7] == 0.0 || model->model_sample != feedback_id) {
        return true;
    }

    /* Current limits are owned by the ERT model. Reject unexpected upstream
     * outputs instead of sending an otherwise valid high-current packet. */
    if (fabs(value[0]) > 0.50 || fabs(value[1]) > 0.30) {
        return false;
    }
    const int64_t minimum_40 = -INT64_C(549755813888);
    const int64_t maximum_40 = INT64_C(549755813887);
    reference->word[0] = (uint32_t)signed_fixed(value[0], 0x1p24, INT32_MIN, INT32_MAX);
    reference->word[1] = (uint32_t)signed_fixed(value[1], 0x1p24, INT32_MIN, INT32_MAX);
    /* Phase offset normalization is a wire-format rule. The generated PL
     * selector still wraps encoder angle plus bias and chooses fixed angle. */
    const bool fixed_angle = value[4] != 0.0;
    split_signed(signed_fixed(fixed_angle ? 0.0 : value[2], 0x1p24,
        minimum_40, maximum_40), &reference->word[2]);
    split_signed(phase_bias_q32(value[3]), &reference->word[4]);
    reference->word[6] = AX04B_REF_VALID |
        (fixed_angle ? AX04B_FIXED_ANGLE : 0u) |
        ((value[6] != 0.0 || !allow_drive) ? AX04B_PI_RESET : 0u) |
        ((allow_drive && value[5] != 0.0) ? AX04B_PWM_ENABLE : 0u) |
        ((allow_drive && model->drives[0]) ? AX04B_RELCON : 0u) |
        ((allow_drive && model->drives[1]) ? AX04B_ENCON : 0u) |
        ((!allow_drive || model->drives[3]) ? AX04B_OE_DISABLE : 0u);
    return true;
}

void ax04b_model_initialize(void)
{
    AXU5EV_Motor_Control_System_initialize();
}

void ax04b_model_run(const Ax04bFeedback *feedback, const Ax04bCommand *command,
    bool transport_invalid, bool clear, bool start, bool init_reset, bool driver_reset,
    Ax04bModelResult *result)
{
    ExtU_AXU5EV_Motor_Control_Sys_T *const u = &AXU5EV_Motor_Control_System_U;
    const ExtY_AXU5EV_Motor_Control_Sys_T *const y = &AXU5EV_Motor_Control_System_Y;
    memcpy(u->CommandFrame, command->frame, sizeof(u->CommandFrame));
    u->CommandFrame[AX04B_CMD_ALIGN_START] = start ? 1.0 : 0.0;
    u->CommandFrame[AX04B_CMD_ALIGN_RESET] = init_reset ? 1.0 : 0.0;
    u->raw_count = feedback->raw_count;
    u->sample_id = feedback->id;
    u->sample_tick = feedback->tick;
    u->illegal_count = feedback->illegal_count;
    u->encoder_ready = !transport_invalid &&
        (feedback->quality & AX04B_ENCODER_READY) != 0u;
    u->current_valid = !transport_invalid && ax04b_current_qualified(feedback);
    u->ERRI_n = (feedback->fault & AX04B_ERRI) == 0u;
    u->ERRU_n = (feedback->fault & AX04B_ERRU) == 0u;
    u->clear_fault = clear;
    u->request_relcon = command->relcon;
    u->request_encon = command->encon;
    u->request_freset = driver_reset;
    u->request_oe_disable = command->oe_disable;
    PL_Frame_IRQ();
    memcpy(result->value, y->reference_commit, sizeof(result->value));
    memcpy(result->drives, y->drive_outputs, sizeof(result->drives));
    result->model_sample = y->commit_sample_id;
    result->model_version = y->reference_version;
    result->feedback_status = y->feedback_status;
    result->position_valid = y->position_valid;
    result->speed_valid = y->speed_valid;
}

uint32_t ax04b_model_service(double telemetry[AX04B_TELEMETRY_WORDS])
{
    Service_Request();
    memcpy(telemetry, AXU5EV_Motor_Control_System_Y.telemetry,
        sizeof(AXU5EV_Motor_Control_System_Y.telemetry));
    return AXU5EV_Motor_Control_System_Y.service_count;
}
