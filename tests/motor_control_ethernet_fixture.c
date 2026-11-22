/* Share the real R5 application and existing simulated PL feedback. */
#undef MOTOR_CONTROL_ETHERNET
#include "../verification/experiment/ax04b/test_r5_runtime.c"

#include "motor_control_console.h"
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

EXPORT uint32_t fixture_uart(char byte)
{
    char command;
    const char *line;
    if (!motor_control_console_input(byte, &command, &line)) {
        return 0;
    }
    if (command == 'o') {
        Ax05aRequest request;
        assert(motor_control_parse_request(line, &request));
        const Ax05aReply reply = motor_control_submit(request);
        assert(reply.decision == AX05A_ACCEPTED);
        return reply.request_id;
    }
    return 0;
}
