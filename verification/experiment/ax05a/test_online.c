/* Included by the AX-04B host harness to reuse its MMIO and IRQ model. */
static Ax05aRequest request(Ax05aAction action, Ax05aMode mode, uint32_t revision)
{
    static uint32_t id;
    return (Ax05aRequest){
        .schema = AX05A_SCHEMA, .request_id = ++id, .action = action,
        .mode = mode, .selected_revision = revision
    };
}

static Ax05aReply send(Ax05aAction action, Ax05aMode mode, uint32_t revision,
    Ax05aDecision expected)
{
    const Ax05aRequest command = request(action, mode, revision);
    const Ax05aReply reply = ax05a_submit(&command);
    if (reply.decision != expected) {
        fprintf(stderr, "action=%u mode=%u revision=%u expected=%u actual=%u\n",
            action, mode, revision, expected, reply.decision);
    }
    assert(reply.request_id == command.request_id && reply.decision == expected);
    return reply;
}

static uint32_t prepare(Ax05aMode mode)
{
    const uint32_t revision = send(AX05A_SELECT, mode, 0u, AX05A_ACCEPTED).accepted_revision;
    send(AX05A_CONFIRM, mode, revision + 1u, AX05A_NOT_READY);
    send(AX05A_CONFIRM, mode, revision, AX05A_ACCEPTED);
    send(AX05A_CLEAR, mode, 0u, AX05A_ACCEPTED);
    frame(true);
    assert(ax05a_control_status().clear_confirmed);
    send(AX05A_ARM, mode, revision, AX05A_ACCEPTED);
    frame(true);
    assert(pl.offered_id == 0u && pl.offered_iq == 0u && (pl.offered_flags & OUTPUT_BITS) == 0u);
    return revision;
}

static void test_commands(void)
{
    send(AX05A_START, AX05A_CURRENT, 0u, AX05A_NOT_READY);
    Ax05aRequest invalid = request(AX05A_SELECT, AX05A_CURRENT, 0u);
    invalid.schema = 2u;
    assert(ax05a_submit(&invalid).decision == AX05A_BAD_REQUEST);
    Ax05aRequest bounded = request(AX05A_SELECT, AX05A_CURRENT, 0u);
    bounded.id_a = NAN;
    assert(ax05a_submit(&bounded).decision == AX05A_BAD_REQUEST);
    bounded = request(AX05A_SELECT, AX05A_CURRENT, 0u);
    bounded.id_a = 0.51;
    assert(ax05a_submit(&bounded).decision == AX05A_OUT_OF_RANGE);

    uint32_t revision = send(AX05A_SELECT, AX05A_CURRENT, 0u, AX05A_ACCEPTED).accepted_revision;
    Ax05aRequest fine = request(AX05A_FINE_PHASE, AX05A_CURRENT, revision);
    fine.fine_phase_rad = -0.25;
    revision = ax05a_submit(&fine).accepted_revision;
    assert(revision != 0u);
    send(AX05A_CONFIRM, AX05A_CURRENT, revision, AX05A_ACCEPTED);
    send(AX05A_ARM, AX05A_CURRENT, revision, AX05A_PL_DENIED);
    send(AX05A_CLEAR, AX05A_CURRENT, 0u, AX05A_ACCEPTED);
    frame(true);
    send(AX05A_ARM, AX05A_CURRENT, revision, AX05A_ACCEPTED);
    send(AX05A_SELECT, AX05A_SPEED, 0u, AX05A_STOP_FIRST);
    send(AX05A_FINE_PHASE, AX05A_CURRENT, revision, AX05A_STOP_FIRST);
    send(AX05A_DRIVER_RESET, AX05A_IDLE, 0u, AX05A_STOP_FIRST);
    send(AX05A_CALIBRATE, AX05A_IDLE, 0u, AX05A_STOP_FIRST);
    send(AX05A_START, AX05A_CURRENT, revision, AX05A_ACCEPTED);
    Ax05aRequest set = request(AX05A_SETPOINT, AX05A_CURRENT, revision);
    set.id_a = -0.25;
    set.iq_a = 0.125;
    const Ax05aReply reply = ax05a_submit(&set);
    assert(reply.decision == AX05A_ACCEPTED);
    assert(ax05a_submit(&set).decision == AX05A_BAD_REQUEST);
    frame(true);
    assert(pl.offered_id == UINT32_C(0xffc00000) && pl.offered_iq == UINT32_C(0x00200000));
    assert(ax04b_join_words(pl.shadow[4], pl.shadow[5]) == UINT64_C(25912333585));
    assert(ps_history[(ps_next + PS_HISTORY - 1u) % PS_HISTORY].command_revision ==
        reply.accepted_revision);
    send(AX05A_PI_RESET, AX05A_IDLE, 0u, AX05A_ACCEPTED);
    send(AX05A_PI_RESET, AX05A_IDLE, 0u, AX05A_PENDING);
    frame(true);
    assert((pl.offered_flags & AX04B_PI_RESET) != 0u);
    frame(true);
    assert((pl.offered_flags & AX04B_PI_RESET) == 0u);
    send(AX05A_STOP, AX05A_IDLE, 0u, AX05A_ACCEPTED);
    send(AX05A_START, AX05A_CURRENT, revision, AX05A_NOT_READY);
    frame(true);
    assert(!ax05a_control_status().selection_confirmed && !(pl.status & AX04B_ARMED));

    revision = prepare(AX05A_SPEED);
    send(AX05A_START, AX05A_SPEED, revision, AX05A_ACCEPTED);
    set = request(AX05A_SETPOINT, AX05A_SPEED, revision);
    set.speed_mm_s = 5.0;
    assert(ax05a_submit(&set).decision == AX05A_ACCEPTED);
    frame(true);
    assert(AXU5EV_Motor_Control_System_U.CommandFrame[AX04B_CMD_SPEED] == 5.0);
    assert(AXU5EV_Motor_Control_System_U.CommandFrame[AX04B_CMD_SPEED_LOOP] == 1.0);
}

static void test_position(void)
{
    uint32_t revision = prepare(AX05A_POSITION);
    send(AX05A_START, AX05A_POSITION, revision, AX05A_ACCEPTED);
    Ax05aRequest move = request(AX05A_SETPOINT, AX05A_POSITION, revision);
    move.position_mm = 2.0;
    assert(ax05a_submit(&move).decision == AX05A_NOT_READY);
    for (unsigned i = 0u; i < 650u; ++i) frame(true);
    const Ax05aPsFrame previous_ready = ps_history[(ps_next + PS_HISTORY - 1u) % PS_HISTORY];
    assert(previous_ready.host_ready && previous_ready.mode == AX05A_POSITION);

    send(AX05A_STOP, AX05A_IDLE, 0u, AX05A_ACCEPTED);
    revision = prepare(AX05A_POSITION);
    const uint32_t start_revision =
        send(AX05A_START, AX05A_POSITION, revision, AX05A_ACCEPTED).accepted_revision;
    assert(previous_ready.command_revision != start_revision);
    send(AX05A_SETPOINT, AX05A_POSITION, revision, AX05A_NOT_READY);

    /* Exercise a retained Ready observation from the previous POSITION run
     * before the restarted command has produced a new PS record. */
    ps_history[(ps_next + PS_HISTORY - 1u) % PS_HISTORY] = previous_ready;
    const double move_level = command_slots[active_command].frame[AX04B_CMD_MOVE];
    send(AX05A_SETPOINT, AX05A_POSITION, revision, AX05A_NOT_READY);
    assert(command_slots[active_command].online_revision == start_revision &&
        command_slots[active_command].frame[AX04B_CMD_MOVE] == move_level &&
        move_pending_revision == 0u);

    for (unsigned i = 0u; i < 650u; ++i) frame(true);
    move = request(AX05A_SETPOINT, AX05A_POSITION, revision);
    move.position_mm = 2.0;
    const Ax05aReply reply = ax05a_submit(&move);
    assert(reply.decision == AX05A_ACCEPTED);
    send(AX05A_SETPOINT, AX05A_POSITION, revision, AX05A_PENDING);
    frame(true);
    assert(host_receipt_revision == reply.accepted_revision && host_receipt_status == 2u);
    assert(AXU5EV_Motor_Control_System_Y.runtime_frame[23] == 2.0);
}

static void test_alignment(void)
{
    const uint32_t revision = prepare(AX05A_ALIGNMENT);
    send(AX05A_START, AX05A_ALIGNMENT, revision, AX05A_NOT_READY);
    send(AX05A_ALIGN_START, AX05A_ALIGNMENT, revision, AX05A_ACCEPTED);
    frame(true);
    assert(alignment_state() == ALIGN_RAMP && latest.start_delivered);
    send(AX05A_STOP, AX05A_IDLE, 0u, AX05A_ACCEPTED);
    frame(true);
    assert(alignment_state() == ALIGN_IDLE);
    send(AX05A_ALIGN_RESET, AX05A_IDLE, 0u, AX05A_ACCEPTED);
    frame(true);
    send(AX05A_DRIVER_RESET, AX05A_IDLE, 0u, AX05A_ACCEPTED);
    frame(true);
    assert((pl.offered_flags & (OUTPUT_BITS | AX04B_F_RESET)) == AX04B_F_RESET);
    assert(!ax05a_control_status().armed);
    send(AX05A_CALIBRATE, AX05A_IDLE, 0u, AX05A_ACCEPTED);
}

static void set_observation(uint32_t id, uint64_t tick)
{
    ++observation_seq;
    observation[0] = 0x4d435431u;
    observation[1] = 3u;
    observation[2] = 0xe7u;
    observation[3] = observation[42] = id;
    observation[4] = observation[43] = (uint32_t)tick;
    observation[5] = observation[44] = (uint32_t)(tick >> 32);
    observation[8] = 0xff000000u;
    observation[9] = observation[10] = 0x00800000u;
    observation[11] = 0x08008000u;
    observation[12] = 0x08200000u;
    observation[2] |= 1u << 11;
    observation[32] = 0x40000000u;
    observation[41] = 3u;
    observation[45] = pl.applied_version;
    observation[49] = 0x00400000u;
    observation[50] = 0xffe00000u;
    observation[51] = 0x80000000u;
    observation[52] = 1u;
}

static void test_snapshot(void)
{
    set_observation(pl.feedback.id, pl.feedback.tick);
    Ax05aSample sample;
    const uint32_t old_ack = pl.acknowledgments;
    const uint32_t old_commit = pl.commits;
    assert(ax05a_read_sample(&sample));
    assert(sample.groups == (AX05A_ADC | AX05A_FOC_REF | AX05A_PS));
    assert(sample.ia_a == -1.0 && sample.ib_a == 0.5 && sample.ic_a == 0.5);
    assert(sample.current_valid && sample.offset_a_counts == 2048.5 && sample.offset_b_counts == 2080.0);
    assert(sample.id_ref_a == 0.25 && sample.iq_ref_a == -0.125 && sample.electrical_angle_rad == 1.5);
    assert(sample.encoder_angle_valid && sample.encoder_angle_rad == 0.25);
    assert(sample.ps.position_mm == 1.0 && sample.ps.tick == sample.tick && sample.ps.p0_valid);
    observation[77] = AX05A_DQ_IDENT;
    observation[73] = 0x00080000u;
    observation[74] = 0xfff80000u;
    observation[75] = 0x00800000u;
    observation[76] = 0xff600000u;
    assert(ax05a_read_sample(&sample) && sample.groups == AX05A_ALL);
    assert(sample.id_a == 0.5 && sample.iq_a == -0.5 && sample.ud_v == 8.0 && sample.uq_v == -10.0);
    observation[44] ^= 1u;
    observation[2] |= 8u;
    assert(ax05a_read_sample(&sample) && sample.groups == (AX05A_ADC | AX05A_PS));
    assert(!sample.current_valid);
    observation[1] = 2u;
    assert(!ax05a_read_sample(&sample) && !frozen);
    set_observation(pl.feedback.id - 10000u, pl.feedback.tick - 100000u);
    assert(ax05a_read_sample(&sample) && !(sample.groups & AX05A_PS));
    Ax05aDiagnostics diagnostics;
    assert(ax05a_read_diagnostics(&diagnostics));
    assert(diagnostics.pwm_receipt_coherent && diagnostics.pwm_adopted_sequence == 500u &&
        diagnostics.pwm_compare[2] == 4000u && diagnostics.pwm_period == 5000u);
    assert(diagnostics.exact_ack_count == old_ack && diagnostic_finishes == 6u);
    assert(pl.acknowledgments == old_ack && pl.commits == old_commit && !frozen);
}

static void test_trace(void)
{
    assert(!ax05a_trace_start(0u));
    assert(ax05a_trace_start(AX05A_ADC));
    assert(!ax05a_trace_start(AX05A_ADC));
    const uint32_t id = ax05a_trace_info().capture_id;
    set_observation(pl.feedback.id, pl.feedback.tick);
    assert(ax05a_trace_poll());
    assert(!ax05a_trace_poll());
    for (unsigned i = 0u; i < 3u; ++i) frame(true);
    observation_seq += 2u;
    set_observation(pl.feedback.id, pl.feedback.tick);
    assert(ax05a_trace_poll());
    Ax05aSample sample;
    assert(!ax05a_trace_read(id, 0u, &sample));
    ax05a_trace_stop();
    assert(ax05a_trace_read(id, 1u, &sample) && sample.groups == AX05A_ADC);
    assert(!ax05a_trace_read(id + 1u, 0u, &sample));
    const Ax05aTraceInfo info = ax05a_trace_info();
    assert(info.count == 2u && info.duplicates == 1u && info.missed == 2u && !info.discontinuous);
    assert((info.first_groups & AX05A_FOC_REF) != 0u && info.first_id_ref_a == 0.25 &&
        info.first_iq_ref_a == -0.125 && info.first_offset_a_counts == 2048.5);
    assert(ax05a_trace_start(AX05A_ADC));
    assert(ax05a_trace_poll());
    set_observation(pl.feedback.id, pl.feedback.tick + 1u);
    assert(!ax05a_trace_poll() && ax05a_trace_info().discontinuous);
    assert(ax05a_trace_start(AX05A_ADC));
    for (unsigned i = 0u; i < AX05A_TRACE_CAPACITY; ++i) {
        frame(true);
        set_observation(pl.feedback.id, pl.feedback.tick);
        assert(ax05a_trace_poll());
    }
    assert(ax05a_trace_info().full && !ax05a_trace_info().active &&
        ax05a_trace_info().count == AX05A_TRACE_CAPACITY);
}

static void test_real(void)
{
    send(AX05A_ARM, AX05A_IDLE, 0u, AX05A_REAL_INHIBITED);
    send(AX05A_START, AX05A_CURRENT, 0u, AX05A_REAL_INHIBITED);
    send(AX05A_ALIGN_START, AX05A_ALIGNMENT, 0u, AX05A_REAL_INHIBITED);
    send(AX05A_SETPOINT, AX05A_SPEED, 0u, AX05A_REAL_INHIBITED);
    send(AX05A_DRIVER_RESET, AX05A_IDLE, 0u, AX05A_REAL_INHIBITED);
    send(AX05A_CALIBRATE, AX05A_IDLE, 0u, AX05A_NOT_READY);
    read_real_gains();
    send(AX05A_CALIBRATE, AX05A_IDLE, 0u, AX05A_ACCEPTED);
    frame(true);
    assert(pl.arms == 0u && (pl.offered_flags & (OUTPUT_BITS | AX04B_F_RESET)) == 0u);
}

int main(int argc, char **argv)
{
    assert(argc == 2);
    boot();
    qualified_history();
    const char *scenario = argv[1];
    if (strcmp(scenario, "commands") == 0) test_commands();
    else if (strcmp(scenario, "position") == 0) test_position();
    else if (strcmp(scenario, "alignment") == 0) test_alignment();
    else if (strcmp(scenario, "snapshot") == 0) test_snapshot();
    else if (strcmp(scenario, "trace") == 0) test_trace();
    else if (strcmp(scenario, "real") == 0) test_real();
    else assert(!"unknown AX-05A scenario");
    printf("AX05A_SCENARIO PASS %s\n", scenario);
    return 0;
}
