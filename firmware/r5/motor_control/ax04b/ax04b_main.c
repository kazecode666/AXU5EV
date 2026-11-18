#include "ax04b_adapter.h"
#include "ax04b_bsp.h"
#include "ax04b_registers.h"

#include <ctype.h>
#include <errno.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "xil_cache.h"
#include "xil_exception.h"
#include "xil_io.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xscugic.h"

_Static_assert(AX04B_BUILD_MODE == AX04B_SELFTEST || AX04B_BUILD_MODE == AX04B_REAL,
    "Select a validated hardware candidate");
/* ZynqMP Cortex-R5 BSP maps this PL aperture strongly ordered. */
_Static_assert(AX04B_MMIO_BASE >= UINT32_C(0x80000000) &&
    AX04B_MMIO_BASE < UINT32_C(0xc0000000) && (AX04B_MMIO_BASE & 0xfffu) == 0,
    "Realtime AXI slave must be in the Cortex-R5 PL aperture");
_Static_assert(AX04B_DIAG_BASE >= UINT32_C(0x80000000) &&
    AX04B_DIAG_BASE < UINT32_C(0xc0000000) && (AX04B_DIAG_BASE & 0xfffu) == 0 &&
    AX04B_DIAG_BASE != AX04B_MMIO_BASE, "Diagnostic AXI mapping must be distinct");
_Static_assert(AX04B_FABRIC_IRQ >= 32 && AX04B_FABRIC_IRQ <= 159,
    "GIC input must be a ZynqMP SPI INTID");

volatile const uint32_t ax04b_application_id = AX04B_APPLICATION_ID;
volatile const uint32_t ax04b_mmio_base = AX04B_MMIO_BASE;
volatile const uint32_t ax04b_fabric_irq = AX04B_FABRIC_IRQ;
volatile const uint32_t ax04b_build_mode = AX04B_BUILD_MODE;
volatile const uint32_t ax04b_diag_base = AX04B_DIAG_BASE;

extern char inbyte(void);

enum {
    TRACE_CAPACITY = 256,
    DIAG_WORDS = 80,
    CAL_OFFSET_A = 0x100,
    CAL_OFFSET_B = 0x104,
    CAL_GAIN_A = 0x108,
    CAL_GAIN_B = 0x10c,
    CAL_LOG2 = 0x110,
    CAL_VERSION = 0x114,
    CAL_CONTROL = 0x118
};

typedef struct {
    uint64_t feedback_tick;
    uint32_t pending_sequence;
    uint32_t sample_id;
    uint32_t entry_phase;
    uint32_t quality;
    uint32_t fault;
    uint32_t calibration_version;
    uint32_t config_version;
    uint32_t model_version;
    uint32_t feedback_status;
    uint32_t target;
    uint32_t offered_version;
    uint32_t accepted_version;
    uint32_t accepted_target;
    uint32_t applied_version;
    uint32_t applied_target;
    uint32_t result;
    uint32_t flags;
    uint32_t entry_tick;
    uint32_t read_done_tick;
    uint32_t model_done_tick;
    uint32_t accept_done_tick;
    uint32_t ack_done_tick;
    bool position_valid;
    bool speed_valid;
    bool reference_valid;
    bool applied_coherent;
} FrameRecord;

typedef struct {
    uint32_t spurious;
    uint32_t frames;
    uint32_t duplicate;
    uint32_t safety_duplicate;
    uint32_t bad_snapshot;
    uint32_t overruns;
    uint32_t accepted;
    uint32_t rejected;
    uint32_t transport_stop;
    uint32_t max_read;
    uint32_t max_model;
    uint32_t max_submit;
    uint32_t max_irq_window;
    uint32_t max_service_mask;
} Counters;

static XScuGic interrupt_controller;
static Ax04bCommand command_slots[2];
static volatile unsigned active_command;
static Ax04bFeedback last_feedback;
static bool have_feedback;
static uint32_t previous_overrun;
static uint32_t transport_version;
static uint32_t consumed_clear, consumed_start, consumed_init_reset, consumed_freset;
static uint32_t calibration_request_version;
static uint32_t real_gain_a, real_gain_b;
static bool real_gains_supplied;
static volatile bool trace_on;
static volatile unsigned trace_count;
static FrameRecord trace[TRACE_CAPACITY];
static FrameRecord latest;
static Counters counters;

static inline void barrier(void)
{
    __asm__ volatile("dmb sy" ::: "memory");
}

static inline void completion_barrier(void)
{
    __asm__ volatile("dsb sy" ::: "memory");
}

static inline uint32_t pmu_tick(void)
{
    uint32_t value;
    __asm__ volatile("mrc p15, 0, %0, c9, c13, 0" : "=r"(value) :: "memory");
    return value;
}

static uint32_t pmu_divisor(void)
{
    uint32_t control;
    /* The BSP initializes the PMU. Report its actual divider, not a PL rate. */
    __asm__ volatile("mrc p15, 0, %0, c9, c12, 0" : "=r"(control));
    return (control & 8u) != 0u ? 64u : 1u;
}

static inline uint32_t irq_lock(void)
{
    uint32_t cpsr;
    __asm__ volatile("mrs %0, cpsr\n\tcpsid i" : "=r"(cpsr) :: "memory");
    return cpsr;
}

static inline void irq_unlock(uint32_t cpsr)
{
    barrier();
    if ((cpsr & 0x80u) == 0u) {
        __asm__ volatile("cpsie i" ::: "memory");
    }
}

static inline uint32_t read_rt(uint32_t offset)
{
    return Xil_In32((UINTPTR)ax04b_mmio_base + offset);
}

static inline void write_rt(uint32_t offset, uint32_t value)
{
    Xil_Out32((UINTPTR)ax04b_mmio_base + offset, value);
}

static inline uint32_t read_diag(uint32_t offset)
{
    return Xil_In32((UINTPTR)ax04b_diag_base + offset);
}

static inline void write_diag(uint32_t offset, uint32_t value)
{
    Xil_Out32((UINTPTR)ax04b_diag_base + offset, value);
}

static inline void stop_pl(void)
{
    write_rt(AX04B_CONTROL, AX04B_STOP);
    completion_barrier();
}

static Ax04bCommand stopped_command(void)
{
    Ax04bCommand command = {0};
    /* Keep ticket identities across stop/reconfiguration. */
    command.clear_ticket = command_slots[active_command].clear_ticket;
    command.start_ticket = command_slots[active_command].start_ticket;
    command.init_reset_ticket = command_slots[active_command].init_reset_ticket;
    command.freset_ticket = command_slots[active_command].freset_ticket;
    command.frame[AX04B_CMD_PI_RESET] = 1.0;
    command.oe_disable = true;
    return command;
}

static void publish_command(const Ax04bCommand *command)
{
    /* Single foreground writer, IRQ reader. While the inactive slot is being
     * copied the IRQ can see only the old slot. No allocation or retry. */
    unsigned next = active_command ^ 1u;
    command_slots[next] = *command;
    barrier();
    active_command = next;
}

static void maximum(uint32_t *counter, uint32_t value)
{
    if (*counter < value) {
        *counter = value;
    }
}

static Ax04bFeedback read_feedback(void)
{
    Ax04bFeedback feedback;
    feedback.sequence = read_rt(AX04B_PENDING_SEQ);
    feedback.id = read_rt(AX04B_FB_ID);
    const uint32_t tick_low = read_rt(AX04B_FB_TICK_LO);
    feedback.tick = ax04b_join_words(tick_low, read_rt(AX04B_FB_TICK_HI));
    feedback.raw_count = read_rt(AX04B_FB_COUNT);
    feedback.illegal_count = read_rt(AX04B_FB_ILLEGAL);
    feedback.quality = read_rt(AX04B_FB_QUALITY);
    feedback.calibration_version = read_rt(AX04B_FB_CAL_VERSION);
    feedback.config_version = read_rt(AX04B_FB_CFG_VERSION);
    feedback.fault = read_rt(AX04B_FB_FAULT);
    return feedback;
}

static bool submit(const Ax04bReference *reference, FrameRecord *record)
{
    write_rt(AX04B_TARGET, reference->target);
    for (unsigned i = 0u; i < AX04B_REF_WORDS; ++i) {
        write_rt(AX04B_SHADOW + 4u * i, reference->word[i]);
    }
    barrier();
    write_rt(AX04B_COMMIT, AX04B_COMMIT_KEY);
    /* A bus response is not a receipt. Read the PL result and exact identities
     * while this IRQ is the only software writer of the commit registers. */
    completion_barrier();
    record->result = read_rt(AX04B_RESULT);
    record->accepted_version = read_rt(AX04B_ACCEPTED_VERSION);
    record->accepted_target = read_rt(AX04B_ACCEPTED_TARGET);
    record->accept_done_tick = pmu_tick();
    return record->result == AX04B_COMMIT_ACCEPTED &&
        record->accepted_version == reference->word[7] &&
        record->accepted_target == reference->target;
}

static void read_applied(FrameRecord *record)
{
    /* A P0 between these reads must not be reported as a coherent adoption.
     * The version changes per accepted packet, including across uint32 wrap. */
    const uint32_t before = read_rt(AX04B_APPLIED_VERSION);
    const uint32_t target = read_rt(AX04B_APPLIED_TARGET);
    const uint32_t after = read_rt(AX04B_APPLIED_VERSION);
    record->applied_coherent = before == after;
    if (record->applied_coherent) {
        record->applied_version = after;
        record->applied_target = target;
    }
}

static void frame_interrupt(void *unused)
{
    (void)unused;
    /* The BSP IRQ vector preserves the volatile FP bank and FPSCR. Normal IRQ
     * remains masked throughout this handler, including the generated call. */
    FrameRecord record = {0};
    record.entry_tick = pmu_tick();
    uint32_t status = read_rt(AX04B_STATUS);
    if ((status & AX04B_PENDING) == 0u) {
        ++counters.spurious;
        return;
    }

    record.entry_phase = read_rt(AX04B_PHASE);
    Ax04bFeedback feedback = read_feedback();
    const uint32_t check_status = read_rt(AX04B_STATUS);
    if ((check_status & AX04B_PENDING) == 0u ||
        read_rt(AX04B_PENDING_SEQ) != feedback.sequence) {
        /* External/reset race. Do not ACK an identity we did not process.
         * Mask the level interrupt so a bad pending record cannot livelock. */
        ++counters.bad_snapshot;
        ++counters.transport_stop;
        stop_pl();
        XScuGic_Disable(&interrupt_controller, ax04b_fabric_irq);
        return;
    }
    status = check_status;
    const uint32_t overruns = read_rt(AX04B_OVERRUN_COUNT);
    const bool new_overrun = overruns != previous_overrun;
    previous_overrun = overruns;
    const bool contract_ok = ax04b_feedback_contract(&feedback, ax04b_build_mode);
    const bool live_invalid = (status & AX04B_LIVE_INVALID) != 0u;
    const bool transport_invalid = !contract_ok || new_overrun ||
        (live_invalid && feedback.fault == 0u);

    barrier();
    const Ax04bCommand *const command = &command_slots[active_command];
    const bool start = command->start_ticket != consumed_start;
    const bool init_reset = command->init_reset_ticket != consumed_init_reset;
    const bool driver_reset = command->freset_ticket != consumed_freset;
    const Ax04bDispatch dispatch = ax04b_dispatch(have_feedback ? &last_feedback : NULL,
        &feedback, transport_invalid || init_reset || driver_reset);
    record.read_done_tick = pmu_tick();
    ++counters.frames;
    record.feedback_tick = feedback.tick;
    record.pending_sequence = feedback.sequence;
    record.sample_id = feedback.id;
    record.quality = feedback.quality;
    record.fault = feedback.fault;
    record.calibration_version = feedback.calibration_version;
    record.config_version = feedback.config_version;
    record.model_done_tick = record.read_done_tick;
    record.accept_done_tick = record.read_done_tick;

    if (!contract_ok) {
        ++counters.bad_snapshot;
    }
    if (new_overrun) {
        ++counters.overruns;
    }
    if (dispatch == AX04B_DUPLICATE) {
        ++counters.duplicate;
    } else {
        const bool new_frame = dispatch == AX04B_NEW_FRAME;
        const bool clear = new_frame && !transport_invalid &&
            command->clear_ticket != consumed_clear;
        Ax04bModelResult result;
        ax04b_model_run(&feedback, command, transport_invalid, clear,
            new_frame && start, init_reset, driver_reset, &result);
        record.model_done_tick = pmu_tick();
        record.model_version = result.model_version;
        record.feedback_status = result.feedback_status;
        record.position_valid = result.position_valid;
        record.speed_valid = result.speed_valid;
        record.reference_valid = result.value[7] != 0.0;
        if (new_frame && start) {
            consumed_start = command->start_ticket;
        }
        if (init_reset) {
            consumed_init_reset = command->init_reset_ticket;
        }
        if (driver_reset) {
            consumed_freset = command->freset_ticket;
        }
        if (clear) {
            consumed_clear = command->clear_ticket;
            if (record.reference_valid && !result.drives[4] &&
                command->frame[AX04B_CMD_PWM] == 0.0) {
                write_rt(AX04B_CONTROL, AX04B_CLEAR);
            }
        }

        if (!new_frame || !contract_ok || new_overrun) {
            /* A duplicate carrying a fault/reset always reaches model safety
             * logic. It never schedules another allowed reference. */
            counters.safety_duplicate += !new_frame;
            ++counters.transport_stop;
            stop_pl();
        } else {
            Ax04bReference reference;
            const bool allow_drive = ax04b_build_mode == AX04B_SELFTEST &&
                (status & AX04B_ARMED) != 0u;
            const bool encoded = ax04b_encode_reference(&result, feedback.id,
                ++transport_version, allow_drive, &reference);
            if (!encoded) {
                ++counters.transport_stop;
                stop_pl();
            } else {
                record.target = reference.target;
                record.offered_version = reference.word[7];
                record.flags = reference.word[6];
                if (submit(&reference, &record)) {
                    ++counters.accepted;
                } else {
                    ++counters.rejected;
                    ++counters.transport_stop;
                    stop_pl();
                }
            }
        }
    }

    last_feedback = feedback;
    have_feedback = true;
    /* These can legitimately describe an earlier P0. Record both identities.
     * The hardware applies the queued packet at the next P0, not during ACK. */
    if ((status & AX04B_APPLIED_SEEN) != 0u) {
        read_applied(&record);
    }
    barrier();
    write_rt(AX04B_ACK, feedback.sequence);
    completion_barrier();
    record.ack_done_tick = pmu_tick();
    maximum(&counters.max_read, record.read_done_tick - record.entry_tick);
    maximum(&counters.max_model, record.model_done_tick - record.read_done_tick);
    if (record.result != AX04B_COMMIT_NONE) {
        maximum(&counters.max_submit, record.accept_done_tick - record.model_done_tick);
    }
    latest = record;
    if (trace_on && trace_count < TRACE_CAPACITY) {
        trace[trace_count] = record;
        ++trace_count;
    }
    maximum(&counters.max_irq_window, pmu_tick() - record.entry_tick);
}

static bool setup_interrupt(void)
{
    XScuGic_Config *config = XScuGic_LookupConfig((UINTPTR)XPAR_XSCUGIC_0_BASEADDR);
    if (config == NULL ||
        XScuGic_CfgInitialize(&interrupt_controller, config, config->CpuBaseAddress) != XST_SUCCESS ||
        XScuGic_Connect(&interrupt_controller, ax04b_fabric_irq,
            frame_interrupt, NULL) != XST_SUCCESS) {
        return false;
    }
    XScuGic_SetPriorityTriggerType(&interrupt_controller, ax04b_fabric_irq, 0x90u, 0x1u);
    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_IRQ_INT,
        (Xil_ExceptionHandler)XScuGic_InterruptHandler, &interrupt_controller);
    XScuGic_Enable(&interrupt_controller, ax04b_fabric_irq);
    Xil_ExceptionEnableMask(XIL_EXCEPTION_IRQ);
    return true;
}

static void disarm(void)
{
    const Ax04bCommand command = stopped_command();
    publish_command(&command);
    stop_pl();
}

static void configure_zero_current(void)
{
    if (ax04b_build_mode == AX04B_REAL && !real_gains_supplied) {
        xil_printf("AX04B CAL DENIED: supply measured REAL Q24 gains with g first\r\n");
        return;
    }
    disarm();
    const bool test = ax04b_build_mode == AX04B_SELFTEST;
    write_diag(CAL_OFFSET_A, 0u);
    write_diag(CAL_OFFSET_B, 0u);
    write_diag(CAL_GAIN_A, test ? UINT32_C(65536) : real_gain_a);
    write_diag(CAL_GAIN_B, test ? UINT32_C(65536) : real_gain_b);
    write_diag(CAL_LOG2, test ? 4u : 10u);
    write_diag(CAL_VERSION, ++calibration_request_version);
    barrier();
    write_diag(CAL_CONTROL, 5u); /* apply the staged bundle and enable automatic zero offset */
    completion_barrier();
    if (!test) {
        write_rt(AX04B_IO_CONTROL, 1u);
    }
    xil_printf("AX04B %s calibration requested, output disabled\r\n",
        test ? "synthetic" : "REAL provisional no-power");
}

static void read_real_gains(void)
{
    if (ax04b_build_mode != AX04B_REAL) {
        xil_printf("AX04B TEST gains fixed\r\n");
        return;
    }
    char line[80];
    char *end_a, *end_b;
    if (fgets(line, sizeof(line), stdin) == NULL) {
        return;
    }
    errno = 0;
    const intmax_t a = strtoimax(line, &end_a, 10);
    const intmax_t b = strtoimax(end_a, &end_b, 10);
    const bool parsed = errno == 0 && end_a != line && end_b != end_a;
    while (isspace((unsigned char)*end_b)) {
        ++end_b;
    }
    if (!parsed || *end_b != '\0' || a == 0 || b == 0 ||
        a < INT32_MIN || a > INT32_MAX || b < INT32_MIN || b > INT32_MAX) {
        xil_printf("AX04B expected g <signed_gain_a_q24> <signed_gain_b_q24>\r\n");
        return;
    }
    disarm();
    real_gain_a = (uint32_t)(int32_t)a;
    real_gain_b = (uint32_t)(int32_t)b;
    real_gains_supplied = true;
    xil_printf("AX04B REAL gain words staged in PS, use c with zero current\r\n");
}

static void arm_test(void)
{
    if (ax04b_build_mode != AX04B_SELFTEST) {
        xil_printf("AX04B REAL ARM DENIED: physical validation pending\r\n");
        return;
    }
    const uint32_t cpsr = irq_lock();
    const bool ready = latest.position_valid && latest.speed_valid &&
        latest.reference_valid;
    irq_unlock(cpsr);
    const uint32_t status = read_rt(AX04B_STATUS);
    if (!ready || (status & (AX04B_INHIBIT_LATCHED | AX04B_LIVE_INVALID)) != 0u) {
        xil_printf("AX04B ARM DENIED: wait for qualification and explicit clear\r\n");
        return;
    }
    write_rt(AX04B_CONTROL, AX04B_ARM);
    completion_barrier();
    if ((read_rt(AX04B_STATUS) & AX04B_ARMED) == 0u) {
        xil_printf("AX04B PL ARM rejected\r\n");
        return;
    }
    Ax04bCommand command = stopped_command();
    command.frame[AX04B_CMD_PWM] = 1.0;
    command.frame[AX04B_CMD_PI_RESET] = 0.0;
    command.relcon = true;
    command.encon = true;
    command.oe_disable = false;
    publish_command(&command);
    xil_printf("AX04B internal SELFTEST armed with zero current reference\r\n");
}

static void clear_request(void)
{
    Ax04bCommand command = command_slots[active_command];
    if (command.frame[AX04B_CMD_PWM] != 0.0) {
        xil_printf("AX04B CLEAR DENIED: stop first\r\n");
        return;
    }
    ++command.clear_ticket;
    publish_command(&command);
    xil_printf("AX04B clear requested on the next clean frame\r\n");
}

static void test_command(char key)
{
    if (ax04b_build_mode != AX04B_SELFTEST || (read_rt(AX04B_STATUS) & AX04B_ARMED) == 0u) {
        xil_printf("AX04B test reference denied\r\n");
        return;
    }
    Ax04bCommand command = command_slots[active_command];
    if (key == 'j') {
        command.frame[AX04B_CMD_ALIGN_ENABLE] = 0.0;
        command.frame[AX04B_CMD_IQ_TEST] = 1.0;
        command.frame[AX04B_CMD_IQ_TEST_REF] = 0.1;
    } else if (key == 'i') {
        command.frame[AX04B_CMD_IQ_TEST] = 0.0;
        command.frame[AX04B_CMD_IQ_TEST_REF] = 0.0;
        command.frame[AX04B_CMD_ALIGN_ENABLE] = 1.0;
        ++command.start_ticket;
    } else if (key == 'z') {
        ++command.init_reset_ticket;
    } else {
        ++command.freset_ticket;
    }
    publish_command(&command);
    xil_printf("AX04B internal SELFTEST command %c queued\r\n", key);
}

static void status_report(void)
{
    double values[AX04B_TELEMETRY_WORDS];
    const uint32_t cpsr = irq_lock();
    const uint32_t service_start = pmu_tick();
    const uint32_t services = ax04b_model_service(values);
    const FrameRecord record = latest;
    const Counters counts = counters;
    maximum(&counters.max_service_mask, pmu_tick() - service_start);
    irq_unlock(cpsr);

    printf("AX04B mode=%" PRIu32 " status=%08" PRIx32 " events=%" PRIu32
        " spur=%" PRIu32 " duplicate=%" PRIu32 " safety_dup=%" PRIu32
        " snapshot_error=%" PRIu32 " overrun=%" PRIu32 " receipt_ok=%" PRIu32
        " rejected=%" PRIu32 " stop=%" PRIu32 "\r\n",
        ax04b_build_mode, read_rt(AX04B_STATUS), counts.frames, counts.spurious,
        counts.duplicate, counts.safety_duplicate, counts.bad_snapshot,
        counts.overruns, counts.accepted, counts.rejected, counts.transport_stop);
    printf("sample=%" PRIu32 " tick=%" PRIu64 " source=%s quality=%08" PRIx32
        " cal=%" PRIu32 " config=%" PRIu32 " fault=%08" PRIx32
        " pos=%.6f speed=%.6f pv=%u sv=%u model_ver=%" PRIu32
        " receipt=%" PRIu32 ":%" PRIu32 " applied=%" PRIu32 ":%" PRIu32
        " applied_coherent=%u service=%" PRIu32 "\r\n", record.sample_id, record.feedback_tick,
        (record.quality & AX04B_TEST_SOURCE) != 0u ? "TEST" : "REAL",
        record.quality, record.calibration_version, record.config_version,
        record.fault, values[2], values[3], (unsigned)record.position_valid,
        (unsigned)record.speed_valid, record.model_version,
        record.accepted_version, record.accepted_target, record.applied_version,
        record.applied_target, (unsigned)record.applied_coherent, services);
    printf("PMU divider=%" PRIu32 " max_read=%" PRIu32 " max_model=%" PRIu32
        " max_submit=%" PRIu32 " max_irq_body=%" PRIu32
        " last_max_service_mask=%" PRIu32 "\r\n",
        pmu_divisor(), counts.max_read, counts.max_model, counts.max_submit,
        counts.max_irq_window, counts.max_service_mask);
}

static void trace_start(void)
{
    const uint32_t cpsr = irq_lock();
    trace_count = 0u;
    trace_on = true;
    irq_unlock(cpsr);
    xil_printf("AX04B recording up to 256 IRQ records\r\n");
}

static void trace_dump(void)
{
    const uint32_t cpsr = irq_lock();
    trace_on = false;
    const unsigned count = trace_count;
    irq_unlock(cpsr);
    printf("seq,id,tick,phase50MHz,quality,fault,cal_ver,cfg_ver,model_ver,fb_status,"
        "target,offer,accept_ver,accept_target,apply_ver,apply_target,result,flags,"
        "entry_pmu,read_pmu,model_pmu,accept_pmu,ack_pmu,pv,sv,rv,applied_coherent\r\n");
    for (unsigned i = 0u; i < count; ++i) {
        const FrameRecord *record = &trace[i];
        printf("%" PRIu32 ",%" PRIu32 ",%" PRIu64 ",%" PRIu32 ",%" PRIu32 ",%"
            PRIu32 ",%" PRIu32 ",%" PRIu32 ",%" PRIu32 ",%" PRIu32 ",%" PRIu32
            ",%" PRIu32 ",%" PRIu32 ",%" PRIu32 ",%" PRIu32 ",%" PRIu32 ",%"
            PRIu32 ",%" PRIu32 ",%" PRIu32 ",%" PRIu32 ",%" PRIu32 ",%" PRIu32
            ",%" PRIu32 ",%u,%u,%u,%u\r\n",
            record->pending_sequence, record->sample_id, record->feedback_tick,
            record->entry_phase, record->quality, record->fault, record->calibration_version,
            record->config_version, record->model_version, record->feedback_status,
            record->target, record->offered_version, record->accepted_version,
            record->accepted_target, record->applied_version, record->applied_target,
            record->result, record->flags, record->entry_tick, record->read_done_tick,
            record->model_done_tick, record->accept_done_tick, record->ack_done_tick,
            (unsigned)record->position_valid, (unsigned)record->speed_valid,
            (unsigned)record->reference_valid, (unsigned)record->applied_coherent);
    }
}

static void diagnostics_dump(void)
{
    if ((read_rt(AX04B_STATUS) & AX04B_APPLIED_SEEN) == 0u) {
        xil_printf("AX04B wait for first adopted frame before diagnostic snapshot\r\n");
        return;
    }
    uint32_t words[DIAG_WORDS];
    const uint32_t sequence = read_diag(0x0u);
    for (unsigned i = 0u; i < DIAG_WORDS; ++i) {
        words[i] = read_diag(0x0cu + i * 4u);
    }
    printf("AX04B legacy 80-word adopted-PWM diagnostic seq=%" PRIu32 "\r\n", sequence);
    for (unsigned i = 0u; i < DIAG_WORDS; ++i) {
        printf("%u,%08" PRIx32 "\r\n", i, words[i]);
    }
}

int main(void)
{
    Xil_ExceptionDisableMask(XIL_EXCEPTION_IRQ);
    Xil_ICacheEnable();
    Xil_DCacheEnable();
    /* PL reset independently inhibits output. Avoid writes to an address
     * mapped to a different bitstream until the read-only identity matches. */
    if (read_rt(AX04B_IDENT) != AX04B_INTERFACE_ID ||
        read_rt(AX04B_MODE) != ax04b_build_mode ||
        read_rt(AX04B_SCALE) != AX04B_NM_PER_COUNT) {
        xil_printf("AX04B IDENTITY MISMATCH: no IRQ or command writes\r\n");
        return 1;
    }
    stop_pl();
    const uint32_t status = read_rt(AX04B_STATUS);
    if ((status & AX04B_ACCEPTED_SEEN) != 0u) {
        transport_version = read_rt(AX04B_ACCEPTED_VERSION);
    }
    if ((status & AX04B_PENDING) != 0u) {
        write_rt(AX04B_ACK, read_rt(AX04B_PENDING_SEQ));
        completion_barrier();
    }
    previous_overrun = read_rt(AX04B_OVERRUN_COUNT);
    publish_command(&(Ax04bCommand){
        .frame = {[AX04B_CMD_PI_RESET] = 1.0},
        .oe_disable = true
    });
    ax04b_model_initialize();
    if (!setup_interrupt()) {
        stop_pl();
        xil_printf("AX04B GIC setup failed, stopped\r\n");
        return 2;
    }
    printf("AX04B WAIT app=%08" PRIx32 " mode=%" PRIu32 " base=%08" PRIx32
        " GIC_INTID=%" PRIu32 " feedback_nm_per_count=%u PMU_divider=%" PRIu32 "\r\n",
        ax04b_application_id, ax04b_build_mode, ax04b_mmio_base, ax04b_fabric_irq,
        AX04B_NM_PER_COUNT, pmu_divisor());
    xil_printf("c=calibrate g=REAL gains r=clear a=SELFTEST arm j=q-test i=align "
        "z=alignment-reset f=SELFTEST driver-reset x=stop s=status l=capture p=CSV d=PL snapshot\r\n");
    for (;;) {
        const char command = inbyte();
        switch (command) {
        case 'c': configure_zero_current(); break;
        case 'g': read_real_gains(); break;
        case 'r': clear_request(); break;
        case 'a': arm_test(); break;
        case 'j':
        case 'i':
        case 'z':
        case 'f': test_command(command); break;
        case 'x': disarm(); xil_printf("AX04B STOPPED\r\n"); break;
        case 's': status_report(); break;
        case 'l': trace_start(); break;
        case 'p': trace_dump(); break;
        case 'd': diagnostics_dump(); break;
        default: break;
        }
    }
}
