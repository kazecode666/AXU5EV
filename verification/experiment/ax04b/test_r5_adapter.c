/* Host-side transport checks with the exact PR46 final_03 generated C.
 * No target MMIO, GIC, executable, or board is invoked. */
#include "ax04b_adapter.h"
#include "ax04b_registers.h"
#include "AXU5EV_Motor_Control_System.h"

#include <assert.h>
#include <limits.h>
#include <math.h>
#include <stdio.h>

enum {
    HEALTHY = AX04B_ENCODER_READY | AX04B_CURRENT_VALID | AX04B_CAL_DONE_A |
        AX04B_CAL_DONE_B | AX04B_CAPTURE_A | AX04B_CAPTURE_B | AX04B_PAIR_COMPLETE |
        AX04B_TEST_SOURCE
};

static void quality_and_dispatch(void)
{
    Ax04bFeedback sample = {
        .id = UINT32_MAX - 249u,
        .tick = UINT64_MAX - 2499u,
        .raw_count = UINT32_MAX - 3u,
        .quality = HEALTHY
    };
    assert(ax04b_join_words(0x89abcdefu, 0xfedcba98u) == UINT64_C(0xfedcba9889abcdef));
    assert(ax04b_feedback_contract(&sample, AX04B_SELFTEST));
    assert(!ax04b_feedback_contract(&sample, AX04B_REAL));
    assert(ax04b_current_qualified(&sample));
    assert(ax04b_dispatch(NULL, &sample, false) == AX04B_NEW_FRAME);

    Ax04bFeedback next = sample;
    ++next.sequence;
    assert(ax04b_dispatch(&sample, &next, false) == AX04B_DUPLICATE);
    assert(ax04b_dispatch(&sample, &next, true) == AX04B_SAFETY_DUPLICATE);
    next.fault = AX04B_ERRU;
    assert(ax04b_dispatch(&sample, &next, false) == AX04B_SAFETY_DUPLICATE);
    next = sample;
    next.raw_count ^= 1u;
    assert(ax04b_dispatch(&sample, &next, false) == AX04B_SAFETY_DUPLICATE);
    next = sample;
    next.quality &= ~(uint32_t)AX04B_CAPTURE_B;
    assert(!ax04b_current_qualified(&next));
    assert(ax04b_dispatch(&sample, &next, false) == AX04B_SAFETY_DUPLICATE);
    next.quality = HEALTHY | AX04B_CLIP;
    assert(!ax04b_current_qualified(&next));
    next.quality = HEALTHY | AX04B_ENCODER_REVERSE;
    assert(!ax04b_feedback_contract(&next, AX04B_SELFTEST));

    next = sample;
    next.id += AX04B_ID_STEP;
    next.tick += AX04B_TICK_STEP;
    assert(next.id == 250u && next.tick == 2500u);
    assert(ax04b_dispatch(&sample, &next, false) == AX04B_NEW_FRAME);
}

static void reference_codec(void)
{
    Ax04bModelResult model = {
        .value = {0.25, -0.30, -300.25, -1.25, 0, 1, 0, 1},
        .model_sample = UINT32_MAX - 249u,
        .drives = {true, true, false, false, false}
    };
    Ax04bReference ref;
    assert(ax04b_encode_reference(&model, model.model_sample, UINT32_MAX, true, &ref));
    assert(ref.target == 250u && ref.word[7] == UINT32_MAX);
    assert(ref.word[0] == 4194304u && ref.word[1] == (uint32_t)-5033165);
    assert(ax04b_join_words(ref.word[2], ref.word[3]) == (uint64_t)-INT64_C(5037359104));
    assert(ax04b_join_words(ref.word[4], ref.word[5]) == UINT64_C(21617366289));
    assert(ref.word[6] == (AX04B_REF_VALID | AX04B_PWM_ENABLE | AX04B_RELCON | AX04B_ENCON));

    model.value[4] = 1.0;
    model.value[6] = 1.0;
    assert(ax04b_encode_reference(&model, model.model_sample, 0u, true, &ref));
    assert(ref.word[7] == 0u && ref.word[2] == 0u && ref.word[3] == 0u);
    assert((ref.word[6] & (AX04B_FIXED_ANGLE | AX04B_PI_RESET)) ==
        (AX04B_FIXED_ANGLE | AX04B_PI_RESET));

    model.value[0] = 2.5 / 0x1p24;
    model.value[1] = -3.5 / 0x1p24;
    assert(ax04b_encode_reference(&model, model.model_sample, 9u, false, &ref));
    assert(ref.word[0] == 2u && ref.word[1] == (uint32_t)-4);
    assert((ref.word[6] & (AX04B_PWM_ENABLE | AX04B_RELCON | AX04B_ENCON)) == 0u);
    assert((ref.word[6] & (AX04B_PI_RESET | AX04B_OE_DISABLE)) ==
        (AX04B_PI_RESET | AX04B_OE_DISABLE));

    model.value[4] = 0.0;
    model.value[2] = -40000.0;
    model.value[3] = 256.0;
    assert(ax04b_encode_reference(&model, model.model_sample, 9u, false, &ref));
    assert(ax04b_join_words(ref.word[2], ref.word[3]) == (uint64_t)-INT64_C(549755813888));
    assert(ax04b_join_words(ref.word[4], ref.word[5]) == UINT64_C(20068611414));

    const double turn = 0x1.921fb54442d18p+2;
    model.value[3] = nextafter(turn, 0.0);
    assert(ax04b_encode_reference(&model, model.model_sample, 9u, false, &ref));
    assert(ax04b_join_words(ref.word[4], ref.word[5]) == 0u);
    model.value[3] = -0x1p-36;
    assert(ax04b_encode_reference(&model, model.model_sample, 9u, false, &ref));
    assert(ax04b_join_words(ref.word[4], ref.word[5]) == 0u);
    model.value[3] = turn - 0x1p-32;
    assert(ax04b_encode_reference(&model, model.model_sample, 9u, false, &ref));
    assert(ax04b_join_words(ref.word[4], ref.word[5]) == UINT64_C(26986075408));

    model.drives[2] = true;
    assert(ax04b_encode_reference(&model, model.model_sample, 10u, true, &ref));
    assert(ref.word[6] == (AX04B_PI_RESET | AX04B_F_RESET));
    assert(ref.word[0] == 0u && ref.word[1] == 0u);
    model.drives[2] = false;
    assert(ax04b_encode_reference(&model, model.model_sample + 1u, 11u, true, &ref));
    assert(ref.word[6] == (AX04B_PI_RESET | AX04B_OE_DISABLE));

    model.value[2] = NAN;
    assert(!ax04b_encode_reference(&model, model.model_sample, 12u, true, &ref));
    assert(ref.word[6] == (AX04B_PI_RESET | AX04B_OE_DISABLE));
    model.value[2] = 0.0;
    model.value[5] = INFINITY;
    assert(!ax04b_encode_reference(&model, model.model_sample, 13u, true, &ref));
    assert(ref.word[6] == (AX04B_PI_RESET | AX04B_OE_DISABLE));
}

static void advance(Ax04bFeedback *feedback)
{
    ++feedback->sequence;
    feedback->id += AX04B_ID_STEP;
    feedback->tick += AX04B_TICK_STEP;
}

static void generated_model(void)
{
    Ax04bFeedback sample = {
        .id = UINT32_MAX - 249u,
        .tick = UINT64_MAX - 2499u,
        .quality = HEALTHY & ~(uint32_t)AX04B_CAL_DONE_A
    };
    Ax04bCommand command = {.oe_disable = true};
    Ax04bModelResult result;
    Ax04bReference reference;
    double telemetry[AX04B_TELEMETRY_WORDS];

    ax04b_model_initialize();
    ax04b_model_run(&sample, &command, false, false, false, false, false, &result);
    assert(!AXU5EV_Motor_Control_System_U.current_valid);
    assert(AXU5EV_Motor_Control_System_U.sample_tick == sample.tick);
    assert(result.value[5] == 0.0 && result.value[7] == 0.0);
    sample.quality = HEALTHY;
    for (unsigned i = 0u; i < 60u; ++i) {
        advance(&sample);
        ax04b_model_run(&sample, &command, false, false, false, false, false, &result);
    }
    assert(result.position_valid && result.speed_valid && result.value[7] == 0.0);
    advance(&sample);
    ax04b_model_run(&sample, &command, false, true, false, false, false, &result);
    assert(result.value[5] == 0.0 && result.value[7] == 1.0 && !result.drives[4]);
    assert(ax04b_model_service(telemetry) == 1u);
    assert(telemetry[0] == (double)sample.id && telemetry[1] == (double)result.model_version);

    command.oe_disable = false;
    command.relcon = true;
    command.encon = true;
    command.frame[AX04B_CMD_PWM] = 1.0;
    command.frame[AX04B_CMD_IQ_TEST] = 1.0;
    command.frame[AX04B_CMD_IQ_TEST_REF] = 0.10;
    advance(&sample);
    ax04b_model_run(&sample, &command, false, false, false, false, false, &result);
    assert(result.value[5] == 1.0 && result.value[6] == 0.0);
    assert(ax04b_encode_reference(&result, sample.id, 1u, true, &reference));
    assert(reference.word[1] == 1677722u);

    command.frame[AX04B_CMD_IQ_TEST] = 0.0;
    command.frame[AX04B_CMD_IQ_TEST_REF] = 0.0;
    command.frame[AX04B_CMD_ALIGN_ENABLE] = 1.0;
    advance(&sample);
    ax04b_model_run(&sample, &command, false, false, true, false, false, &result);
    assert(ax04b_encode_reference(&result, sample.id, 2u, true, &reference));
    assert((reference.word[6] & AX04B_FIXED_ANGLE) != 0u);

    /* Same frozen capture identity, updated raw safety cause. */
    const Ax04bFeedback previous = sample;
    sample.fault = AX04B_ERRI;
    assert(ax04b_dispatch(&previous, &sample, false) == AX04B_SAFETY_DUPLICATE);
    ax04b_model_run(&sample, &command, false, false, false, false, false, &result);
    assert(result.value[5] == 0.0 && result.value[6] == 1.0 && result.drives[4]);
    assert(ax04b_model_service(telemetry) == 2u && telemetry[11] == 1.0);
}

int main(void)
{
    quality_and_dispatch();
    reference_codec();
    generated_model();
    puts("AX04B_R5_ADAPTER PASS: quality/identity, duplicates, wraps, Q formats, "
        "safe packets, generated startup/clear/command/alignment/fault/service");
    return 0;
}
