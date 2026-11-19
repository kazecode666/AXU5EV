/* Host-only MMIO/CPU shim. The included code is actual firmware and the linked
 * model is the specified Cortex-R generation. Neither is reimplemented here. */
#include "ax04b_bsp.h"
#include "AXU5EV_Motor_Control_System.h"
#include <assert.h>
#include <setjmp.h>
#include <stdarg.h>

static uint32_t host_irq_lock(void);
static void host_irq_unlock(uint32_t state);
#define main ax04b_firmware_main
#include "ax04b_main_host.inc"
#undef main

enum {
    QUALIFIED = AX04B_ENCODER_READY | AX04B_CURRENT_VALID | AX04B_CAL_DONE_A |
        AX04B_CAL_DONE_B | AX04B_CAPTURE_A | AX04B_CAPTURE_B | AX04B_PAIR_COMPLETE,
    OUTPUT_BITS = AX04B_PWM_ENABLE | AX04B_RELCON | AX04B_ENCON,
    ALIGN_IDLE = 0,
    ALIGN_RAMP = 1,
    ALIGN_HOLD = 2,
    ALIGN_RELEASE = 3,
    ALIGN_DONE = 4
};

static struct {
    Ax04bFeedback feedback;
    uint32_t status, phase, result;
    uint32_t target, shadow[AX04B_REF_WORDS], mask;
    uint32_t version, accepted_target, applied_version, applied_target;
    uint32_t offered_flags, offered_id, offered_iq, reject_next;
    uint32_t acknowledgments, commits, stops, clears, arms, io_enable;
    bool reject_clear, reject_arm, drop_on_receipt, gic_enabled, irq_masked;
} pl;
static jmp_buf ready;
static Xil_ExceptionHandler irq_handler;
static void *irq_data;

typedef struct {
    double host_tick, speed_ticks, position_ticks, speed_integral;
    double move_state[22];
    int64_t delay[50], count;
    uint8_t history;
} ModelProgress;

static ModelProgress progress_before_receipt;

static ModelProgress model_progress(void)
{
    const DW_AXU5EV_Motor_Control_Syste_T *dw = &AXU5EV_Motor_Control_System_DW;
    ModelProgress result = {
        .host_tick = dw->Software_Tick_DSTATE,
        .speed_ticks = dw->spd_cnt_z_DSTATE,
        .position_ticks = dw->pos_cnt_z_DSTATE,
        .speed_integral = dw->x_s_z_DSTATE,
        .count = dw->total,
        .history = dw->filled
    };
    memcpy(result.move_state, dw->move_state, sizeof(result.move_state));
    memcpy(result.delay, dw->Speed_Window_Delay_DSTATE, sizeof(result.delay));
    return result;
}

static void assert_no_control_advance(const ModelProgress *before)
{
    const ModelProgress after = model_progress();
    assert(after.host_tick == before->host_tick && after.speed_ticks == before->speed_ticks &&
        after.position_ticks == before->position_ticks && after.count == before->count &&
        after.history == before->history);
    assert(memcmp(after.move_state, before->move_state, sizeof(after.move_state)) == 0);
    assert(memcmp(after.delay, before->delay, sizeof(after.delay)) == 0);
    assert(after.speed_integral == before->speed_integral || after.speed_integral == 0.0);
}

uint32_t Xil_In32(UINTPTR address)
{
    const UINTPTR offset = address - AX04B_MMIO_BASE;
    switch (offset) {
    case AX04B_IDENT: return AX04B_INTERFACE_ID;
    case AX04B_MODE: return AX04B_BUILD_MODE;
    case AX04B_SCALE: return AX04B_NM_PER_COUNT;
    case AX04B_STATUS: return pl.status;
    case AX04B_PENDING_SEQ: return pl.feedback.sequence;
    case AX04B_OVERRUN_COUNT: return 0u;
    case AX04B_ACCEPTED_VERSION: return pl.version;
    case AX04B_ACCEPTED_TARGET:
        if (pl.drop_on_receipt) {
            assert(pl.result == AX04B_COMMIT_ACCEPTED && (pl.status & AX04B_REF_QUEUED));
            assert(pl.status & AX04B_ARMED);
            progress_before_receipt = model_progress();
            pl.status |= AX04B_INHIBIT_LATCHED;
            pl.status &= ~(uint32_t)AX04B_ARMED;
            pl.drop_on_receipt = false;
        }
        return pl.accepted_target;
    case AX04B_APPLIED_VERSION: return pl.applied_version;
    case AX04B_APPLIED_TARGET: return pl.applied_target;
    case AX04B_RESULT: return pl.result;
    case AX04B_P0_ID:
    case AX04B_FB_ID: return pl.feedback.id;
    case AX04B_FB_TICK_LO: return (uint32_t)pl.feedback.tick;
    case AX04B_FB_TICK_HI: return (uint32_t)(pl.feedback.tick >> 32);
    case AX04B_FB_COUNT: return pl.feedback.raw_count;
    case AX04B_FB_ILLEGAL: return pl.feedback.illegal_count;
    case AX04B_FB_QUALITY: return pl.feedback.quality;
    case AX04B_FB_CAL_VERSION: return pl.feedback.calibration_version;
    case AX04B_FB_CFG_VERSION: return pl.feedback.config_version;
    case AX04B_FB_FAULT: return pl.feedback.fault;
    case AX04B_PHASE: return pl.phase;
    case AX04B_IO_CONTROL: return pl.io_enable;
    default: assert(!"unexpected register read"); return 0u;
    }
}

void Xil_Out32(UINTPTR address, uint32_t value)
{
    if (address >= AX04B_DIAG_BASE + CAL_OFFSET_A &&
        address <= AX04B_DIAG_BASE + CAL_CONTROL) {
        return; /* Legacy observer's calibration shadow is outside this test. */
    }
    const UINTPTR offset = address - AX04B_MMIO_BASE;
    switch (offset) {
    case AX04B_ACK:
        assert((pl.status & AX04B_PENDING) && value == pl.feedback.sequence);
        pl.status &= ~(uint32_t)AX04B_PENDING;
        ++pl.acknowledgments;
        return;
    case AX04B_CONTROL: {
        const bool may_clear = (pl.status & (AX04B_FRAME_SEEN | AX04B_LIVE_INVALID)) ==
            AX04B_FRAME_SEEN && (pl.feedback.quality & QUALIFIED) == QUALIFIED &&
            pl.feedback.fault == 0u;
        if (value == AX04B_STOP) {
            pl.status &= ~(uint32_t)(AX04B_ARMED | AX04B_REF_QUEUED | AX04B_ACTIVE_VALID);
            pl.status |= AX04B_INHIBIT_LATCHED;
            pl.io_enable = 0u;
            pl.mask = 0u;
            ++pl.stops;
        } else if (value == AX04B_CLEAR) {
            if (may_clear && !pl.reject_clear) {
                pl.status &= ~(uint32_t)(AX04B_INHIBIT_LATCHED | AX04B_ARMED);
            }
            ++pl.clears;
        } else {
            assert(value == AX04B_ARM);
            if (may_clear && !pl.reject_arm && !(pl.status & AX04B_INHIBIT_LATCHED)) {
                pl.status |= AX04B_ARMED;
            }
            ++pl.arms;
        }
        return;
    }
    case AX04B_IO_CONTROL:
        pl.io_enable = value;
        return;
    case AX04B_TARGET:
        assert((pl.status & AX04B_PENDING) && pl.mask == 0u);
        pl.target = value;
        pl.mask = UINT32_C(1) << AX04B_REF_WORDS;
        return;
    case AX04B_COMMIT:
        assert(value == AX04B_COMMIT_KEY && (pl.status & AX04B_PENDING));
        assert(pl.mask == (UINT32_C(1) << (AX04B_REF_WORDS + 1)) - 1u);
        assert(pl.target == pl.feedback.id + AX04B_ID_STEP);
        assert(!(pl.status & AX04B_REF_QUEUED));
        assert((pl.shadow[6] & OUTPUT_BITS) == 0u || AX04B_BUILD_MODE == AX04B_SELFTEST);
        assert(!(pl.status & AX04B_ACCEPTED_SEEN) ||
            (pl.shadow[7] != pl.version && (pl.shadow[7] - pl.version) < UINT32_C(0x80000000)));
        ++pl.commits;
        pl.mask = 0u;
        pl.offered_flags = pl.shadow[6];
        pl.offered_id = pl.shadow[0];
        pl.offered_iq = pl.shadow[1];
        if (pl.reject_next != AX04B_COMMIT_NONE) {
            progress_before_receipt = model_progress();
        }
        if (pl.reject_next == AX04B_COMMIT_LATE) {
            pl.phase = 4990u;
        }
        pl.result = pl.reject_next ? pl.reject_next : AX04B_COMMIT_ACCEPTED;
        pl.reject_next = 0u;
        if (pl.result == AX04B_COMMIT_ACCEPTED) {
            pl.version = pl.shadow[7];
            pl.accepted_target = pl.target;
            pl.status |= AX04B_ACCEPTED_SEEN | AX04B_REF_QUEUED;
        }
        return;
    default:
        assert(offset >= AX04B_SHADOW && offset < AX04B_SHADOW + 4u * AX04B_REF_WORDS);
        assert((offset & 3u) == 0u);
        const unsigned word = (unsigned)(offset - AX04B_SHADOW) / 4u;
        pl.shadow[word] = value;
        pl.mask |= UINT32_C(1) << word;
    }
}

/* Vendor CPU/GIC bindings only. */
XScuGic_Config *XScuGic_LookupConfig(UINTPTR address)
{
    static XScuGic_Config cfg;
    assert(address == XPAR_XSCUGIC_0_BASEADDR);
    cfg.CpuBaseAddress = address;
    return &cfg;
}

int XScuGic_CfgInitialize(XScuGic *gic, XScuGic_Config *cfg, UINTPTR address)
{
    assert(gic != NULL && cfg->CpuBaseAddress == address);
    return XST_SUCCESS;
}

int XScuGic_Connect(XScuGic *gic, uint32_t irq, Xil_ExceptionHandler handler, void *data)
{
    assert(gic != NULL && irq == AX04B_FABRIC_IRQ && handler != NULL);
    irq_handler = handler;
    irq_data = data;
    return XST_SUCCESS;
}

void XScuGic_Disable(XScuGic *gic, uint32_t irq)
{
    assert(gic != NULL && irq == AX04B_FABRIC_IRQ);
    pl.gic_enabled = false;
}

void XScuGic_Enable(XScuGic *gic, uint32_t irq)
{
    assert(gic != NULL && irq == AX04B_FABRIC_IRQ);
    pl.gic_enabled = true;
}

void XScuGic_SetPriorityTriggerType(XScuGic *gic, uint32_t irq, uint8_t priority, uint8_t level)
{
    assert(gic != NULL && irq == AX04B_FABRIC_IRQ && priority == 0x90u && level == 1u);
}

void XScuGic_InterruptHandler(void *data) { (void)data; assert(!"unexpected GIC exception"); }
void Xil_ExceptionRegisterHandler(int id, Xil_ExceptionHandler handler, void *data)
{
    assert(id == XIL_EXCEPTION_ID_IRQ_INT && handler == XScuGic_InterruptHandler && data != NULL);
}
void Xil_ExceptionEnableMask(int mask) { assert(mask == XIL_EXCEPTION_IRQ); pl.irq_masked = false; }
void Xil_ExceptionDisableMask(int mask) { assert(mask == XIL_EXCEPTION_IRQ); pl.irq_masked = true; }
void Xil_ExceptionInit(void) {}
void Xil_ICacheEnable(void) {}
void Xil_DCacheEnable(void) {}
static uint32_t host_irq_lock(void)
{
    const uint32_t was_masked = pl.irq_masked ? 0x80u : 0u;
    pl.irq_masked = true;
    return was_masked;
}
static void host_irq_unlock(uint32_t state) { pl.irq_masked = (state & 0x80u) != 0u; }
int xil_printf(const char *format, ...)
{
    va_list args;
    va_start(args, format);
    const int bytes = vprintf(format, args);
    va_end(args);
    return bytes;
}
char inbyte(void) { longjmp(ready, 1); }

static unsigned alignment_state(void)
{
    return (unsigned)AXU5EV_Motor_Control_System_Y.runtime_frame[4];
}

static bool alignment_done(void)
{
    return AXU5EV_Motor_Control_System_Y.runtime_frame[3] != 0.0;
}

static void print_frame(const char *case_name, const char *stage, uint32_t status_before)
{
    const ExtU_AXU5EV_Motor_Control_Sys_T *u = &AXU5EV_Motor_Control_System_U;
    const ExtY_AXU5EV_Motor_Control_Sys_T *y = &AXU5EV_Motor_Control_System_Y;
    printf("R1 case=%s stage=%s id=%" PRIu32 " tick=%" PRIu64 " seq=%" PRIu32
        " pl_before=%03" PRIx32 " pl_after=%03" PRIx32 " fault=%" PRIu32
        " encoder=%u current=%u pwm_in=%.1f rel_in=%u en_in=%u oe_in=%u"
        " start_in=%.1f ticket=%" PRIu32 " consumed=%" PRIu32
        " state=%u done=%u align_id=%.9f model_id=%.9f pos=%.6f"
        " model_pwm=%.1f rv=%.1f flags=%02" PRIx32 " result=%" PRIu32
        " transported_version=%" PRIu32 " commits=%" PRIu32 " acks=%" PRIu32 "\n",
        case_name, stage, pl.feedback.id, pl.feedback.tick, pl.feedback.sequence,
        status_before, pl.status, pl.feedback.fault,
        u->encoder_ready, u->current_valid, u->CommandFrame[AX04B_CMD_PWM],
        u->request_relcon, u->request_encon, u->request_oe_disable,
        u->CommandFrame[AX04B_CMD_ALIGN_START], command_slots[active_command].start_ticket,
        consumed_start, alignment_state(), alignment_done(), y->runtime_frame[5],
        y->reference_commit[0], y->position_mm, y->reference_commit[5], y->reference_commit[7],
        latest.flags, latest.result, latest.offered_version, pl.commits, pl.acknowledgments);
#if AX04B_TEST_FIXED
    printf("R1 safety case=%s stage=%s permit=%u pending=%u reason=%u pl_status=%03" PRIx32
        " safety_pass=%u start_delivered=%u\n", case_name, stage, latest.drive_permitted,
        latest.stop_pending, (unsigned)latest.stop_reason, latest.stop_status,
        latest.safety_pass, latest.start_delivered);
#endif
}

static uint32_t frame(bool new_identity)
{
    assert(pl.gic_enabled && !pl.irq_masked && !(pl.status & AX04B_PENDING));
    if (new_identity) {
        pl.feedback.id += AX04B_ID_STEP;
        pl.feedback.tick += AX04B_TICK_STEP;
        pl.status &= ~(uint32_t)AX04B_ACTIVE_VALID;
        if (pl.status & AX04B_REF_QUEUED) {
            assert(pl.accepted_target == pl.feedback.id);
            pl.applied_version = pl.version;
            pl.applied_target = pl.accepted_target;
            pl.status |= AX04B_APPLIED_SEEN | AX04B_ACTIVE_VALID;
            pl.status &= ~(uint32_t)AX04B_REF_QUEUED;
        }
    }
    ++pl.feedback.sequence;
    pl.status |= AX04B_PENDING | AX04B_FRAME_SEEN;
    pl.phase = 76u;
    const uint32_t before = pl.status;
    const uint32_t previous_acks = pl.acknowledgments;
    pl.irq_masked = true; /* BSP masks it throughout this callback. */
    irq_handler(irq_data);
    pl.irq_masked = false;
    assert(pl.acknowledgments == previous_acks + 1u && !(pl.status & AX04B_PENDING));
    return before;
}

static void boot(void)
{
    if (setjmp(ready) == 0) {
        const int failed = ax04b_firmware_main();
        (void)failed;
        assert(!"firmware initialization failed");
    }
    assert(irq_handler && pl.gic_enabled && !pl.irq_masked && pl.stops == 1u);
    assert((pl.status & (AX04B_ARMED | AX04B_INHIBIT_LATCHED)) == AX04B_INHIBIT_LATCHED);
    pl.feedback.raw_count = 1000u;
    pl.feedback.config_version = 1u;
    pl.feedback.calibration_version = 1u;
    pl.feedback.quality = QUALIFIED;
    if (AX04B_BUILD_MODE == AX04B_SELFTEST) {
        pl.feedback.quality |= AX04B_TEST_SOURCE;
    }
}

static void qualified_history(void)
{
    for (unsigned i = 0u; i < 51u; ++i) {
        frame(true);
        assert(latest.position_valid && AXU5EV_Motor_Control_System_Y.history_count == i + 1u);
        assert(latest.speed_valid == (i == 50u));
        assert((pl.offered_flags & OUTPUT_BITS) == 0u && !(pl.status & AX04B_ARMED));
    }
}

static void clear_ok(void)
{
    const uint32_t previous_clears = pl.clears;
    clear_request();
    frame(true);
    assert(pl.clears == previous_clears + 1u);
    assert((pl.status & (AX04B_ARMED | AX04B_INHIBIT_LATCHED)) == 0u);
}

static void start_alignment(void)
{
    test_command('i');
    frame(true);
    assert(alignment_state() == ALIGN_RAMP && !alignment_done());
}

static void normal_arm(void)
{
    arm_test();
    assert(pl.status & AX04B_ARMED);
    frame(true);
    assert(pl.offered_flags & AX04B_PWM_ENABLE);
    assert(alignment_state() == ALIGN_IDLE && !alignment_done());
}

static void old_counterexample(const char *scenario)
{
    qualified_history();
    clear_ok();
    normal_arm();
    start_alignment();
    const uint32_t before = frame(true);
    print_frame(scenario, "before", before);
    const double id_before = AXU5EV_Motor_Control_System_Y.runtime_frame[5];
    assert(id_before > 0.0);

    if (strcmp(scenario, "old-late") == 0) {
        pl.reject_next = AX04B_COMMIT_LATE;
    } else if (strcmp(scenario, "old-armed") == 0) {
        pl.status &= ~(uint32_t)AX04B_ARMED;
    } else {
        assert(strcmp(scenario, "old-inhibit") == 0);
        pl.status |= AX04B_INHIBIT_LATCHED;
    }
    const uint32_t failure = frame(true);
    print_frame(scenario, "failure", failure);
    if (strcmp(scenario, "old-late") == 0) {
        assert(latest.result == AX04B_COMMIT_LATE && !(pl.status & AX04B_ARMED));
    }
    assert(pl.feedback.fault == 0u && !(pl.status & AX04B_LIVE_INVALID));
    assert(alignment_state() == ALIGN_RAMP && !alignment_done());
    const double id_failure = AXU5EV_Motor_Control_System_Y.runtime_frame[5];
    assert(id_failure > id_before);

    const uint32_t after = frame(true);
    print_frame(scenario, "next_healthy", after);
    assert(latest.position_valid && latest.speed_valid && latest.feedback_status == 0u);
    assert(alignment_state() == ALIGN_RAMP && !alignment_done());
    assert(AXU5EV_Motor_Control_System_Y.runtime_frame[5] > id_failure);
    assert(AXU5EV_Motor_Control_System_U.CommandFrame[AX04B_CMD_PWM] == 1.0);
    assert(AXU5EV_Motor_Control_System_Y.reference_commit[5] == 1.0);
    puts("EXPECTED_OLD_COUNTEREXAMPLE");
}

static void begin_run(void)
{
    qualified_history();
    clear_ok();
    normal_arm();
    start_alignment();
    frame(true);
    assert(AXU5EV_Motor_Control_System_Y.runtime_frame[5] > 0.0);
}

static void must_be_stopped(bool done_was_accepted)
{
    const ExtU_AXU5EV_Motor_Control_Sys_T *u = &AXU5EV_Motor_Control_System_U;
    const ExtY_AXU5EV_Motor_Control_Sys_T *y = &AXU5EV_Motor_Control_System_Y;
    assert(u->encoder_ready && u->current_valid);
    assert(u->CommandFrame[AX04B_CMD_PWM] == 0.0 && u->CommandFrame[AX04B_CMD_ALIGN_START] == 0.0);
    assert(!u->request_relcon && !u->request_encon && u->request_oe_disable);
    assert(alignment_done() == done_was_accepted);
    assert(alignment_state() == (done_was_accepted ? ALIGN_DONE : ALIGN_IDLE));
    assert(y->runtime_frame[5] == 0.0 && y->reference_commit[5] == 0.0);
    assert(y->position_mm == 1.0 && y->history_count == 51u);
    assert((latest.flags & OUTPUT_BITS) == 0u || latest.result != AX04B_COMMIT_ACCEPTED ||
        !(pl.status & AX04B_REF_QUEUED));
#if AX04B_TEST_FIXED
    assert(!latest.drive_permitted && !latest.stop_pending && !safety.armed);
#endif
}

static void still_disarmed(const char *scenario)
{
    /* A hardware status change is not an explicit operator clear/rearm. */
    pl.status |= AX04B_ARMED;
    pl.status &= ~(uint32_t)AX04B_INHIBIT_LATCHED;
    const uint32_t restored = frame(true);
    print_frame(scenario, "hardware_restored_without_commands", restored);
    must_be_stopped(false);
}

static void recover(const char *scenario)
{
    const uint32_t old_ticket = command_slots[active_command].start_ticket;
    clear_ok();
    normal_arm();
    assert(command_slots[active_command].start_ticket == old_ticket);
    assert(AXU5EV_Motor_Control_System_U.CommandFrame[AX04B_CMD_ALIGN_START] == 0.0);
    print_frame(scenario, "rearmed_without_new_start", pl.status);
    start_alignment();
    assert(command_slots[active_command].start_ticket == old_ticket + 1u);
    print_frame(scenario, "new_start", pl.status);
}

static void lost_permission(const char *scenario)
{
    begin_run();
    print_frame(scenario, "before", pl.status);
    const unsigned prior_stops = pl.stops;
    const unsigned prior_commits = pl.commits;
    const bool rejected = strcmp(scenario, "late") == 0 || strcmp(scenario, "rejected") == 0;
    if (rejected) {
        pl.reject_next = strcmp(scenario, "late") == 0 ? AX04B_COMMIT_LATE : AX04B_COMMIT_SAFETY;
    } else if (strcmp(scenario, "armed") == 0) {
        pl.status &= ~(uint32_t)AX04B_ARMED;
    } else {
        assert(strcmp(scenario, "inhibit") == 0);
        pl.status |= AX04B_INHIBIT_LATCHED;
    }
    const uint32_t failure = frame(true);
    print_frame(scenario, "failure", failure);
    assert(pl.stops == prior_stops + 1u);
    assert(!(pl.status & AX04B_ARMED) && (pl.status & AX04B_INHIBIT_LATCHED));
    assert(pl.commits <= prior_commits + 1u);
    if (rejected) {
        assert(pl.commits == prior_commits + 1u &&
            latest.result == (strcmp(scenario, "late") == 0 ? AX04B_COMMIT_LATE : AX04B_COMMIT_SAFETY));
        assert_no_control_advance(&progress_before_receipt);
#if AX04B_TEST_FIXED
        assert(latest.safety_pass && latest.stop_reason == AX04B_STOP_COMMIT);
#endif
    }
    must_be_stopped(false);
    const uint32_t healthy = frame(true);
    print_frame(scenario, "next_healthy", healthy);
    must_be_stopped(false);
    assert(latest.position_valid && latest.speed_valid && latest.feedback_status == 0u);
    still_disarmed(scenario);
    recover(scenario);
}

static void stale_start(void)
{
    qualified_history();
    clear_ok();
    normal_arm();
    test_command('i'); /* Stop before the IRQ can consume this Start. */
    assert(command_slots[active_command].start_ticket != consumed_start);
    disarm();
    assert(!(pl.status & AX04B_ARMED) && (pl.status & AX04B_INHIBIT_LATCHED));
    const uint32_t prior_arms = pl.arms;
    arm_test();
    assert(pl.arms == prior_arms);
    const uint32_t stopped = frame(true);
    print_frame("stale", "first_frame_after_stop", stopped);
    must_be_stopped(false);
    still_disarmed("stale");
    recover("stale");
}

static void accepted_then_inhibited(void)
{
    begin_run();
    const uint32_t previous_stops = pl.stops, previous_commits = pl.commits;
    pl.drop_on_receipt = true;
    const uint32_t before = frame(true);
    print_frame("accepted-loss", "inhibit_during_exact_receipt", before);
    assert(!pl.drop_on_receipt);
    assert(latest.result == AX04B_COMMIT_ACCEPTED &&
        latest.accepted_version == latest.offered_version && latest.accepted_target == latest.target);
    assert(pl.commits == previous_commits + 1u && pl.stops == previous_stops + 1u);
    assert(!(pl.status & (AX04B_ARMED | AX04B_REF_QUEUED | AX04B_ACTIVE_VALID)));
#if AX04B_TEST_FIXED
    assert(latest.safety_pass && latest.stop_reason == AX04B_STOP_INHIBIT);
#endif
    must_be_stopped(false);
    assert_no_control_advance(&progress_before_receipt);
    frame(true);
    must_be_stopped(false);
}

static void duplicate(void)
{
    begin_run();
    const unsigned original = pl.commits;
    const unsigned original_stops = pl.stops;
    const uint32_t original_tick = AXU5EV_Motor_Control_System_Y.reference_version;
    const double original_id = AXU5EV_Motor_Control_System_Y.runtime_frame[5];
    const ModelProgress progress = model_progress();
    const uint32_t duplicates = counters.duplicate;
    uint32_t status = frame(false);
    print_frame("duplicate", "unchanged", status);
    assert(counters.duplicate == duplicates + 1u && pl.commits == original && pl.stops == original_stops);
    assert(AXU5EV_Motor_Control_System_Y.reference_version == original_tick);
    assert(AXU5EV_Motor_Control_System_Y.runtime_frame[5] == original_id);
    assert_no_control_advance(&progress);
    pl.status |= AX04B_INHIBIT_LATCHED;
    status = frame(false);
    print_frame("duplicate", "same_identity_permission_lost", status);
    assert(counters.safety_duplicate >= 1u && pl.commits == original && pl.stops == original_stops + 1u);
    must_be_stopped(false);
    assert_no_control_advance(&progress);
}

static void near_done(void)
{
    for (unsigned i = 0u; alignment_state() != ALIGN_RELEASE; ++i) {
        assert(i < 40020u && !alignment_done());
        frame(true);
    }
    for (unsigned i = 0u; i < 1999u; ++i) {
        frame(true);
        assert(alignment_state() == ALIGN_RELEASE && !alignment_done());
    }
}

static void boundary(bool late)
{
    begin_run();
    near_done();
    const char *scenario = late ? "boundary-late" : "boundary";
    print_frame(scenario, "last_release_frame", pl.status);
    if (late) {
        pl.reject_next = AX04B_COMMIT_LATE;
    } else {
        const uint32_t last_ack = pl.acknowledgments, last_commit = pl.commits;
        disarm();
        /* No new IRQ has occurred. Permission is already revoked while the
         * asynchronous model update is explicitly reported as pending. */
        assert((pl.status & (AX04B_ARMED | AX04B_INHIBIT_LATCHED)) == AX04B_INHIBIT_LATCHED);
        assert(pl.acknowledgments == last_ack && pl.commits == last_commit);
#if AX04B_TEST_FIXED
        assert(!latest.drive_permitted && latest.stop_pending && latest.stop_reason == AX04B_STOP_REQUEST);
        status_report();
        print_frame(scenario, "stop_without_new_frame", pl.status);
#endif
    }
    const uint32_t stopped = frame(true);
    print_frame(scenario, "at_done_boundary", stopped);
    must_be_stopped(false);
    if (late) {
        assert(latest.result == AX04B_COMMIT_LATE);
        assert_no_control_advance(&progress_before_receipt);
    }
    const uint32_t healthy = frame(true);
    print_frame(scenario, "next_healthy", healthy);
    must_be_stopped(false);
}

static void normal_cycle(void)
{
    begin_run();
    unsigned seen = 1u << ALIGN_IDLE;
    for (unsigned i = 0u; !alignment_done(); ++i) {
        assert(i < 42020u);
        assert(alignment_state() <= ALIGN_DONE);
        seen |= 1u << alignment_state();
        frame(true);
    }
    seen |= 1u << alignment_state();
    assert(alignment_state() == ALIGN_DONE && seen == 0x1fu);
    assert(pl.offered_flags & AX04B_PWM_ENABLE);
    print_frame("normal", "five_states_done", pl.status);
    test_command('j');
    const uint32_t q_status = frame(true);
    assert(pl.offered_iq == 1677722u && (pl.offered_flags & AX04B_PWM_ENABLE));
    print_frame("normal", "q_axis", q_status);
    disarm();
    const uint32_t stopped = frame(true);
    print_frame("normal", "stop_after_accepted_done", stopped);
    must_be_stopped(true);
}

static void clear_and_arm_receipts(void)
{
    qualified_history();
    pl.reject_clear = true;
    clear_request();
    frame(true);
    assert(pl.clears == 1u && (pl.status & AX04B_INHIBIT_LATCHED));
    arm_test();
    assert(pl.arms == 0u);
    /* A spurious readback without a successful explicit CLEAR is not enough. */
    pl.status &= ~(uint32_t)AX04B_INHIBIT_LATCHED;
    arm_test();
    assert(pl.arms == 0u);
    pl.status |= AX04B_INHIBIT_LATCHED;
    pl.reject_clear = false;
    clear_ok();
    pl.reject_arm = true;
    arm_test();
    assert(pl.arms == 1u && !(pl.status & AX04B_ARMED));
    assert(command_slots[active_command].frame[AX04B_CMD_PWM] == 0.0);
    pl.reject_arm = false;
    normal_arm();
    start_alignment();
    test_command('z');
    const uint32_t alignment_reset = frame(true);
    print_frame("clear", "separate_alignment_reset", alignment_reset);
    assert(alignment_state() == ALIGN_IDLE && AXU5EV_Motor_Control_System_U.CommandFrame[AX04B_CMD_ALIGN_RESET]);
    assert(!AXU5EV_Motor_Control_System_U.request_freset && !AXU5EV_Motor_Control_System_U.clear_fault);
    disarm();
    frame(true);
    test_command('f');
    const uint32_t driver_reset = frame(true);
    print_frame("clear", "separate_driver_reset_stopped", driver_reset);
    assert(AXU5EV_Motor_Control_System_U.request_freset);
    assert(!AXU5EV_Motor_Control_System_U.CommandFrame[AX04B_CMD_ALIGN_RESET] &&
        !AXU5EV_Motor_Control_System_U.clear_fault);
    assert((latest.flags & (OUTPUT_BITS | AX04B_F_RESET)) == AX04B_F_RESET);
}

static void real(void)
{
    /* The caller supplies bounded fixture gains to the actual UART parser. */
    read_real_gains();
    configure_zero_current();
    assert(pl.io_enable == 1u);
    pl.feedback.quality &= ~(uint32_t)AX04B_CAL_DONE_A;
    frame(true);
    assert(!AXU5EV_Motor_Control_System_U.current_valid && pl.io_enable == 1u);
    pl.feedback.quality |= AX04B_CAL_DONE_A;
    unsigned frames = 0u;
    while (!latest.speed_valid) {
        frame(true);
        assert(++frames <= 51u);
    }
    clear_ok();
    arm_test();
    test_command('i');
    test_command('j');
    const uint32_t valid = frame(true);
    print_frame("real", "input_and_diagnostics", valid);
    must_be_stopped(false);
    assert(pl.arms == 0u && pl.io_enable == 1u && latest.position_valid && latest.speed_valid);
    double values[AX04B_TELEMETRY_WORDS];
    assert(ax04b_model_service(values) == 1u && values[0] == pl.feedback.id && values[2] == 1.0);
}

int main(int argc, char **argv)
{
    assert(argc == 2);
    boot();
    const char *scenario = argv[1];
    if (strncmp(scenario, "old-", 4) == 0) {
        old_counterexample(scenario);
        return 0;
    } else if (strcmp(scenario, "late") == 0 || strcmp(scenario, "rejected") == 0 ||
        strcmp(scenario, "armed") == 0 || strcmp(scenario, "inhibit") == 0) {
        lost_permission(scenario);
    } else if (strcmp(scenario, "stale") == 0) {
        stale_start();
    } else if (strcmp(scenario, "accepted-loss") == 0) {
        accepted_then_inhibited();
    } else if (strcmp(scenario, "duplicate") == 0) {
        duplicate();
    } else if (strcmp(scenario, "boundary") == 0 || strcmp(scenario, "boundary-late") == 0) {
        boundary(strcmp(scenario, "boundary-late") == 0);
    } else if (strcmp(scenario, "normal") == 0) {
        normal_cycle();
    } else if (strcmp(scenario, "clear") == 0) {
        clear_and_arm_receipts();
    } else if (strcmp(scenario, "real") == 0) {
        real();
    } else {
        assert(!"unknown test scenario");
    }
    printf("AX04B_R1_SCENARIO PASS %s\n", scenario);
    return 0;
}
