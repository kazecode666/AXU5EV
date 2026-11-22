#include "ax04b_adapter.h"
#include "ax04b_bsp.h"
#include "ax04b_registers.h"
#ifdef AX05A_ONLINE
#include "ax05a_online.h"
#include <math.h>
#endif

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
#ifdef MOTOR_CONTROL_ETHERNET
#include "motor_control_ethernet.h"
#endif

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

#ifndef MOTOR_CONTROL_ETHERNET
extern char inbyte(void);
#endif

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

typedef enum {
    AX04B_STOP_NONE,
    AX04B_STOP_REQUEST,
    AX04B_STOP_SNAPSHOT,
    AX04B_STOP_CONTRACT,
    AX04B_STOP_OVERRUN,
    AX04B_STOP_ARM_LOST,
    AX04B_STOP_INHIBIT,
    AX04B_STOP_LIVE,
    AX04B_STOP_SAFETY_DUPLICATE,
    AX04B_STOP_ENCODE,
    AX04B_STOP_COMMIT
} StopReason;

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
    uint32_t pl_status;
    uint32_t stop_status;
    uint32_t start_ticket;
    uint32_t alignment_state;
    double alignment_id;
    StopReason stop_reason;
    bool position_valid;
    bool speed_valid;
    bool reference_valid;
    bool applied_coherent;
    bool drive_permitted;
    bool stop_pending;
    bool safety_pass;
    bool start_delivered;
    bool alignment_done;
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
    uint32_t safety_passes;
    uint32_t clear_confirmed;
    uint32_t clear_denied;
    uint32_t max_read;
    uint32_t max_model;
    uint32_t max_submit;
    uint32_t max_irq_window;
    uint32_t max_service_mask;
} Counters;

static XScuGic interrupt_controller;
#ifdef MOTOR_CONTROL_ETHERNET
enum { GEM_PRIORITY = 0xa0u };
#define GEM_IRQ ((XPAR_XEMACPS_0_INTERRUPTS & 0xfffu) + 32u)
static volatile bool gem_pending;
static Xil_InterruptHandler gem_handler;
static void *gem_device;
static bool startup_uart = true;

void __real_outbyte(char byte);
void __wrap_outbyte(char byte)
{
    /* Vendor DMA recovery can log from the foreground. Keep UART at startup. */
    if (startup_uart) {
        __real_outbyte(byte);
    }
}

static void gem_interrupt(void *unused)
{
    (void)unused;
    XScuGic_Disable(&interrupt_controller, GEM_IRQ);
    gem_pending = true;
}

int MotorControlGemConnect(void *device, Xil_InterruptHandler handler, uint32_t sdt_irq, UINTPTR parent)
{
    if (sdt_irq != XPAR_XEMACPS_0_INTERRUPTS || (sdt_irq >> 12) != 4u ||
        parent != XPAR_XSCUGIC_0_BASEADDR || GEM_IRQ == AX04B_FABRIC_IRQ) {
        return XST_FAILURE;
    }
    /* The vendor recovery path can reinitialize the same DMA rings. */
    if (gem_device == device) {
        return XST_SUCCESS;
    }
    if (XScuGic_Connect(&interrupt_controller, GEM_IRQ, gem_interrupt, NULL) != XST_SUCCESS) {
        return XST_FAILURE;
    }
    XScuGic_SetPriorityTriggerType(&interrupt_controller, GEM_IRQ, GEM_PRIORITY, 0x1u);
    gem_device = device;
    gem_handler = handler;
    return XST_SUCCESS;
}

void motor_control_gem_poll(void)
{
    if (gem_pending) {
        gem_pending = false;
        gem_handler(gem_device);
        XScuGic_Enable(&interrupt_controller, GEM_IRQ);
    }
}

#endif
static Ax04bCommand command_slots[2];
static volatile unsigned active_command;
static Ax04bFeedback last_feedback;
static bool have_feedback;
static uint32_t previous_overrun;
static uint32_t transport_version;
static uint32_t consumed_clear, consumed_start, consumed_init_reset, consumed_freset;
/* ISR and foreground both access this state. Foreground updates are made
 * with the IRQ masked; the command slots still have one foreground writer. */
static struct {
    bool armed;
    bool clear_confirmed;
    bool stop_pending;
    bool model_alignment_done;
    StopReason reason;
    uint32_t status;
} safety;
static uint32_t calibration_request_version;
static uint32_t real_gain_a, real_gain_b;
static bool real_gains_supplied;
static volatile bool trace_on;
static volatile unsigned trace_count;
#ifndef AX05A_ONLINE
static FrameRecord trace[TRACE_CAPACITY];
#else
/* The cooperative business recorder and IRQ timing trace share RAM, with
 * one capture owner. A new capture explicitly replaces the prior one. */
static union {
    FrameRecord irq[TRACE_CAPACITY];
    Ax05aSample online[AX05A_TRACE_CAPACITY];
} trace_storage;
#define trace trace_storage.irq
#define online_records trace_storage.online
#endif
static FrameRecord latest;
static Counters counters;

#ifdef AX05A_ONLINE
enum { PS_HISTORY = 4 };
static Ax05aPsFrame ps_history[PS_HISTORY];
static unsigned ps_count, ps_next;
static Ax04bCommand selected;
static uint32_t online_revision, confirmed_revision, last_request_id;
static uint32_t consumed_pi_reset, online_ack_count, move_pending_revision;
static uint32_t move_accept_baseline, move_reject_baseline, host_receipt_revision;
static uint32_t host_receipt_status;
static bool have_request, have_selection, selection_confirmed;
static Ax05aTraceInfo online_trace;
#endif

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

#ifndef MOTOR_CONTROL_ETHERNET
static uint32_t pmu_divisor(void)
{
    uint32_t control;
    /* The BSP initializes the PMU. Report its actual divider, not a PL rate. */
    __asm__ volatile("mrc p15, 0, %0, c9, c12, 0" : "=r"(control));
    return (control & 8u) != 0u ? 64u : 1u;
}
#endif

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
#ifdef AX05A_ONLINE
    command.pi_reset_ticket = command_slots[active_command].pi_reset_ticket;
    command.frame[AX04B_CMD_MOVE] = command_slots[active_command].frame[AX04B_CMD_MOVE];
#endif
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

static StopReason pl_stop_reason(uint32_t status)
{
    if ((status & AX04B_LIVE_INVALID) != 0u) {
        return AX04B_STOP_LIVE;
    }
    if ((status & AX04B_INHIBIT_LATCHED) != 0u) {
        return AX04B_STOP_INHIBIT;
    }
    return (status & AX04B_ARMED) == 0u ? AX04B_STOP_ARM_LOST : AX04B_STOP_NONE;
}

static void revoke_permission(StopReason reason, uint32_t status, const Ax04bCommand *command)
{
    stop_pl();
    safety.armed = false;
    safety.clear_confirmed = false;
    safety.stop_pending = true;
    safety.reason = reason;
    safety.status = status;
    /* A later STOP invalidates both earlier operator actions. Only tickets
     * newly published after this command snapshot may be processed. */
    consumed_clear = command->clear_ticket;
    consumed_start = command->start_ticket;
#ifdef AX05A_ONLINE
    if (move_pending_revision != 0u) {
        host_receipt_revision = move_pending_revision;
        host_receipt_status = 7u;
        move_pending_revision = 0u;
    }
    selection_confirmed = false;
#endif
    latest.drive_permitted = false;
    latest.stop_pending = true;
    latest.stop_reason = reason;
    latest.stop_status = status;
    ++counters.transport_stop;
}

static void observe_pl_permission(uint32_t status, const Ax04bCommand *command)
{
    const StopReason reason = pl_stop_reason(status);
    if (safety.armed && reason != AX04B_STOP_NONE) {
        revoke_permission(reason, status, command);
    }
}

static void deny_drive(Ax04bCommand *command)
{
    command->frame[AX04B_CMD_PWM] = 0.0;
    command->frame[AX04B_CMD_PI_RESET] = 1.0;
    command->relcon = false;
    command->encon = false;
    command->oe_disable = true;
}

static void record_alignment(FrameRecord *record, const Ax04bModelResult *result)
{
    record->alignment_state = result->alignment_state;
    record->alignment_done = result->alignment_done;
    record->alignment_id = result->alignment_id;
    record->reference_valid = result->value[7] != 0.0;
    safety.model_alignment_done = result->alignment_done;
}

static void clear_on_feedback(const Ax04bModelResult *result)
{
    safety.clear_confirmed = false;
    if (result->value[7] != 0.0 && !result->drives[4]) {
        write_rt(AX04B_CONTROL, AX04B_CLEAR);
        completion_barrier();
        const uint32_t after = read_rt(AX04B_STATUS);
        safety.clear_confirmed = (after & (AX04B_INHIBIT_LATCHED | AX04B_ARMED |
            AX04B_LIVE_INVALID | AX04B_OVERRUN)) == 0u;
    }
    if (safety.clear_confirmed) {
        ++counters.clear_confirmed;
    } else {
        ++counters.clear_denied;
    }
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
    barrier();
    const Ax04bCommand *const command = &command_slots[active_command];
    if ((check_status & AX04B_PENDING) == 0u ||
        read_rt(AX04B_PENDING_SEQ) != feedback.sequence) {
        /* External/reset race. Do not ACK an identity we did not process.
         * Mask the level interrupt so a bad pending record cannot livelock. */
        ++counters.bad_snapshot;
        revoke_permission(AX04B_STOP_SNAPSHOT, check_status, command);
        XScuGic_Disable(&interrupt_controller, ax04b_fabric_irq);
        return;
    }
    status = check_status;
    const uint32_t overruns = read_rt(AX04B_OVERRUN_COUNT);
    const bool new_overrun = overruns != previous_overrun;
    previous_overrun = overruns;
    const bool contract_ok = ax04b_feedback_contract(&feedback, ax04b_build_mode);
    const bool transport_invalid = !contract_ok || new_overrun;
    if (transport_invalid) {
        revoke_permission(!contract_ok ? AX04B_STOP_CONTRACT : AX04B_STOP_OVERRUN,
            status, command);
    } else {
        observe_pl_permission(status, command);
    }
    const bool init_reset = command->init_reset_ticket != consumed_init_reset;
    const bool driver_reset = command->freset_ticket != consumed_freset;
#ifdef AX05A_ONLINE
    const bool pi_reset = command->pi_reset_ticket != consumed_pi_reset;
    Ax04bCommand effective;
    bool ps_valid = false;
#endif
    const Ax04bDispatch dispatch = ax04b_dispatch(have_feedback ? &last_feedback : NULL,
        &feedback, safety.stop_pending || init_reset || driver_reset);
    if (dispatch == AX04B_SAFETY_DUPLICATE && safety.armed) {
        revoke_permission(AX04B_STOP_SAFETY_DUPLICATE, status, command);
    }
    record.read_done_tick = pmu_tick();
    ++counters.frames;
    record.feedback_tick = feedback.tick;
    record.pending_sequence = feedback.sequence;
    record.sample_id = feedback.id;
    record.quality = feedback.quality;
    record.fault = feedback.fault;
    record.calibration_version = feedback.calibration_version;
    record.config_version = feedback.config_version;
    record.pl_status = status;
    record.start_ticket = command->start_ticket;
    record.model_done_tick = record.read_done_tick;
    record.accept_done_tick = record.read_done_tick;

    if (!contract_ok) {
        ++counters.bad_snapshot;
    }
    if (new_overrun) {
        ++counters.overruns;
    }
    /* Set only when a pending stop needs the same frozen sample after the
     * ordinary call. This path runs after the exact ACK and never commits. */
    bool cancel_after_submit = false;
    bool discard_provisional_done = false;
    Ax04bModelResult result;
    if (dispatch == AX04B_DUPLICATE) {
        ++counters.duplicate;
        record.model_version = latest.model_version;
        record.feedback_status = latest.feedback_status;
        record.position_valid = latest.position_valid;
        record.speed_valid = latest.speed_valid;
        record.reference_valid = latest.reference_valid;
        record.alignment_done = latest.alignment_done;
        record.alignment_state = latest.alignment_state;
        record.alignment_id = latest.alignment_id;
        record.drive_permitted = safety.armed && latest.drive_permitted;
    } else {
        const bool new_frame = dispatch == AX04B_NEW_FRAME;
        const bool clear = new_frame && !safety.armed && !transport_invalid &&
            command->clear_ticket != consumed_clear;
        const bool allow_drive = ax04b_build_mode == AX04B_SELFTEST && safety.armed;
        const bool start = new_frame && command->start_ticket != consumed_start;
        const bool was_done = safety.model_alignment_done;
#ifdef AX05A_ONLINE
        effective = *command;
#else
        Ax04bCommand effective = *command;
#endif
        if (!allow_drive) {
            deny_drive(&effective);
        }
#ifdef AX05A_ONLINE
        if (pi_reset) {
            effective.frame[AX04B_CMD_PI_RESET] = 1.0;
        }
#endif
        record.start_delivered = allow_drive && !driver_reset && !init_reset && start;
        record.drive_permitted = allow_drive && !driver_reset &&
            effective.frame[AX04B_CMD_PWM] > 0.5 && effective.relcon &&
            effective.encon && !effective.oe_disable;
        ax04b_model_run(&feedback, &effective, transport_invalid, clear,
            record.start_delivered, init_reset, driver_reset, &result);
        record.model_done_tick = pmu_tick();
        record.model_version = result.model_version;
        record.feedback_status = result.feedback_status;
        record.position_valid = result.position_valid;
        record.speed_valid = result.speed_valid;
        record_alignment(&record, &result);
#ifdef AX05A_ONLINE
        ps_valid = new_frame && !transport_invalid && result.model_sample == feedback.id;
        if (new_frame && !transport_invalid) {
            consumed_pi_reset = command->pi_reset_ticket;
        }
#endif
        safety.stop_pending = false;
        if (start) {
            consumed_start = command->start_ticket;
        }
        if (init_reset) {
            consumed_init_reset = command->init_reset_ticket;
        }
        if (driver_reset && new_frame && !transport_invalid) {
            consumed_freset = command->freset_ticket;
        }
        if (clear) {
            consumed_clear = command->clear_ticket;
            clear_on_feedback(&result);
        }

        if (!new_frame) {
            /* A duplicate carrying a fault/reset always reaches model safety
             * logic. It never schedules another allowed reference. */
            ++counters.safety_duplicate;
            record.safety_pass = true;
        } else if (!transport_invalid) {
            Ax04bReference reference;
            /* The encoder's reset-only branch never adds PWM/REL/EN. It
             * can represent an explicit SELFTEST F_Reset even while stopped. */
            const bool allow_reset = ax04b_build_mode == AX04B_SELFTEST &&
                driver_reset && result.drives[2];
#ifdef AX05A_ONLINE
            const double auto_phase_rad = result.value[3];
            if (allow_drive && command->fine_phase_rad != 0.0) {
                result.value[3] += command->fine_phase_rad;
            }
#endif
            const bool encoded = ax04b_encode_reference(&result, feedback.id,
                ++transport_version, allow_drive || allow_reset, &reference);
#ifdef AX05A_ONLINE
            result.value[3] = auto_phase_rad;
#endif
            if (!encoded) {
                revoke_permission(AX04B_STOP_ENCODE, status, command);
            } else {
                record.target = reference.target;
                record.offered_version = reference.word[7];
                record.flags = reference.word[6];
                if (submit(&reference, &record)) {
                    ++counters.accepted;
                    if (allow_drive) {
                        /* AXI acceptance alone does not prove PL remained
                         * armed through the model invocation and transfer. */
                        const uint32_t after = read_rt(AX04B_STATUS);
                        observe_pl_permission(after, command);
                    }
                } else {
                    ++counters.rejected;
                    revoke_permission(AX04B_STOP_COMMIT, read_rt(AX04B_STATUS), command);
                }
            }
            if (safety.stop_pending) {
                /* Model already saw denied permission in standby. A stop
                 * after an allowed pass instead needs a safety re-entry. */
                cancel_after_submit = allow_drive;
                discard_provisional_done = !was_done && result.alignment_done;
                if (!cancel_after_submit) {
                    safety.stop_pending = false;
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
    if (cancel_after_submit) {
        Ax04bCommand stopped = *command;
        deny_drive(&stopped);
        Ax04bModelResult result;
        /* No extra normal step, Start delivery, clear, reference or ACK.
         * Init_Reset here rolls back only a newly reached DONE whose own
         * transaction failed. A previously established DONE is retained. */
        ax04b_model_run(&feedback, &stopped, false, false, false,
            discard_provisional_done, false, &result);
        record_alignment(&record, &result);
        record.safety_pass = true;
        safety.stop_pending = false;
    }
    if (record.safety_pass) {
        ++counters.safety_passes;
    }
    record.drive_permitted = record.drive_permitted && safety.armed;
    record.stop_reason = safety.reason;
    record.stop_status = safety.status;
    record.stop_pending = safety.stop_pending;
    maximum(&counters.max_read, record.read_done_tick - record.entry_tick);
    maximum(&counters.max_model, record.model_done_tick - record.read_done_tick);
    if (record.result != AX04B_COMMIT_NONE) {
        maximum(&counters.max_submit, record.accept_done_tick - record.model_done_tick);
    }
    latest = record;
#ifdef AX05A_ONLINE
    ++online_ack_count;
    if (ps_valid) {
        if (move_pending_revision != 0u &&
            (result.host_accept_count != move_accept_baseline ||
             result.host_reject_count != move_reject_baseline || result.host_status == 5u)) {
            host_receipt_revision = move_pending_revision;
            host_receipt_status = result.host_status;
            move_pending_revision = 0u;
        }
        Ax05aPsFrame ps_frame = {
            .sample_id = feedback.id, .tick = feedback.tick,
            .command_revision = command->online_revision, .mode = safety.armed ? command->online_mode : AX05A_IDLE,
            .quality = feedback.quality, .fault = feedback.fault,
            .host_status = host_receipt_status, .host_receipt_revision = host_receipt_revision,
            .position_mm = result.position_mm, .speed_mm_s = result.speed_mm_s,
            .position_ref_mm = result.position_ref_mm, .speed_ref_mm_s = result.speed_ref_mm_s,
            .position_loop_speed_ref_mm_s = result.position_loop_speed_ref_mm_s,
            .selected_position_mm = effective.frame[AX04B_CMD_POSITION],
            .selected_speed_mm_s = effective.frame[AX04B_CMD_SPEED],
            .selected_id_a = effective.frame[AX04B_CMD_ID_REF],
            .selected_iq_a = effective.frame[AX04B_CMD_IQ_TEST_REF],
            .fine_phase_rad = command->fine_phase_rad, .auto_phase_rad = result.value[3],
            .host_ready = result.host_ready,
            .position_valid = result.position_valid, .speed_valid = result.speed_valid
        };
        if (move_pending_revision == 0u) {
            move_accept_baseline = result.host_accept_count;
            move_reject_baseline = result.host_reject_count;
        }
        ps_frame.commit_version = record.offered_version;
        ps_frame.commit_target = record.target;
        ps_frame.commit_result = record.result;
        ps_frame.accepted_version = record.accepted_version;
        ps_frame.accepted_target = record.accepted_target;
        ps_frame.commit_accepted = record.result == AX04B_COMMIT_ACCEPTED &&
            record.accepted_target == record.target && record.accepted_version == record.offered_version;
        ps_frame.p0_version = record.applied_version;
        ps_frame.p0_target = record.applied_target;
        ps_frame.p0_valid = record.applied_coherent && record.applied_target == feedback.id;
        ps_frame.stop_reason = (uint32_t)record.stop_reason;
        ps_frame.alignment_state = record.alignment_state;
        ps_frame.alignment_done = record.alignment_done;
        ps_frame.reference_permitted = record.drive_permitted && record.reference_valid &&
            (record.flags & AX04B_PWM_ENABLE) != 0u;
        if (record.safety_pass) {
            ps_frame.host_ready = false;
        }
        ps_history[ps_next] = ps_frame;
        ps_next = (ps_next + 1u) % PS_HISTORY;
        if (ps_count < PS_HISTORY) {
            ++ps_count;
        }
    }
#endif
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
    const uint32_t cpsr = irq_lock();
    const Ax04bCommand command = stopped_command();
    revoke_permission(AX04B_STOP_REQUEST, read_rt(AX04B_STATUS), &command);
    publish_command(&command);
    irq_unlock(cpsr);
}

static bool configure_zero_current(void)
{
    if (ax04b_build_mode == AX04B_REAL && !real_gains_supplied) {
#ifndef MOTOR_CONTROL_ETHERNET
        xil_printf("AX04B CAL DENIED: supply measured REAL Q24 gains with g first\r\n");
#endif
        return false;
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
#ifndef MOTOR_CONTROL_ETHERNET
    xil_printf("AX04B %s calibration requested, output disabled\r\n",
        test ? "synthetic" : "REAL provisional no-power");
#endif
    return true;
}

bool motor_control_stage_real_gains(const char *line)
{
    if (ax04b_build_mode != AX04B_REAL) {
        return false;
    }
    char *end_a, *end_b;
    errno = 0;
    const intmax_t a = strtoimax(line, &end_a, 10);
    const intmax_t b = strtoimax(end_a, &end_b, 10);
    const bool parsed = errno == 0 && end_a != line &&
        isspace((unsigned char)*end_a) && end_b != end_a;
    while (isspace((unsigned char)*end_b)) {
        ++end_b;
    }
    if (!parsed || *end_b != '\0' || a == 0 || b == 0 ||
        a < INT32_MIN || a > INT32_MAX || b < INT32_MIN || b > INT32_MAX) {
        return false;
    }
    disarm();
    real_gain_a = (uint32_t)(int32_t)a;
    real_gain_b = (uint32_t)(int32_t)b;
    real_gains_supplied = true;
    return true;
}

#ifndef MOTOR_CONTROL_ETHERNET
static void read_real_gains(void)
{
    if (ax04b_build_mode != AX04B_REAL) {
        xil_printf("AX04B TEST gains fixed\r\n");
        return;
    }
    char line[80];
    if (fgets(line, sizeof(line), stdin) == NULL) {
        return;
    }
    if (!motor_control_stage_real_gains(line)) {
        xil_printf("AX04B expected g <signed_gain_a_q24> <signed_gain_b_q24>\r\n");
        return;
    }
#ifdef AX05A_ONLINE
    xil_printf("AX05A REAL gains staged, request CALIBRATE with zero current\r\n");
#else
    xil_printf("AX04B REAL gain words staged in PS, use c with zero current\r\n");
#endif
}
#endif

static bool arm_test(void)
{
    if (ax04b_build_mode != AX04B_SELFTEST) {
#ifndef MOTOR_CONTROL_ETHERNET
        xil_printf("AX04B REAL ARM DENIED: physical validation pending\r\n");
#endif
        return false;
    }
    const uint32_t cpsr = irq_lock();
    const uint32_t status = read_rt(AX04B_STATUS);
    const Ax04bCommand *const requested = &command_slots[active_command];
    observe_pl_permission(status, requested);
    const bool ready = latest.position_valid && latest.speed_valid &&
        latest.reference_valid && safety.clear_confirmed && !safety.stop_pending;
    if (!ready || safety.armed ||
        (status & (AX04B_ARMED | AX04B_INHIBIT_LATCHED | AX04B_LIVE_INVALID)) != 0u) {
        irq_unlock(cpsr);
#ifndef MOTOR_CONTROL_ETHERNET
        xil_printf("AX04B ARM DENIED: wait for qualification and explicit clear\r\n");
#endif
        return false;
    }
    write_rt(AX04B_CONTROL, AX04B_ARM);
    completion_barrier();
    const uint32_t after = read_rt(AX04B_STATUS);
    const StopReason stopped = pl_stop_reason(after);
    if (stopped != AX04B_STOP_NONE) {
        if (stopped != AX04B_STOP_ARM_LOST) {
            revoke_permission(stopped, after, requested);
        }
        irq_unlock(cpsr);
#ifndef MOTOR_CONTROL_ETHERNET
        xil_printf("AX04B PL ARM rejected\r\n");
#endif
        return false;
    }
    Ax04bCommand command = stopped_command();
#ifndef AX05A_ONLINE
    command.frame[AX04B_CMD_PWM] = 1.0;
    command.frame[AX04B_CMD_PI_RESET] = 0.0;
    command.relcon = true;
    command.encon = true;
    command.oe_disable = false;
#endif
    consumed_start = command.start_ticket;
    safety.armed = true;
    safety.clear_confirmed = false;
    publish_command(&command);
    irq_unlock(cpsr);
#ifndef MOTOR_CONTROL_ETHERNET
    xil_printf("AX04B internal SELFTEST armed\r\n");
#endif
    return true;
}

static bool clear_request(void)
{
    const uint32_t cpsr = irq_lock();
    Ax04bCommand command = command_slots[active_command];
    observe_pl_permission(read_rt(AX04B_STATUS), &command);
    if (safety.armed) {
        irq_unlock(cpsr);
#ifndef MOTOR_CONTROL_ETHERNET
        xil_printf("AX04B CLEAR DENIED: stop first\r\n");
#endif
        return false;
    }
    safety.clear_confirmed = false;
    ++command.clear_ticket;
    publish_command(&command);
    irq_unlock(cpsr);
#ifndef MOTOR_CONTROL_ETHERNET
    xil_printf("AX04B clear requested on the next clean frame\r\n");
#endif
    return true;
}

#ifndef AX05A_ONLINE
static void test_command(char key)
{
    const uint32_t cpsr = irq_lock();
    Ax04bCommand command = command_slots[active_command];
    const uint32_t status = read_rt(AX04B_STATUS);
    observe_pl_permission(status, &command);
    /* Init_Reset and a reset-only F_Reset packet remain available while
     * stopped. The independent REAL output policy continues to deny them. */
    if (ax04b_build_mode != AX04B_SELFTEST ||
        ((key == 'i' || key == 'j') && !safety.armed)) {
        irq_unlock(cpsr);
        xil_printf("AX04B test reference denied\r\n");
        return;
    }
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
    irq_unlock(cpsr);
    xil_printf("AX04B internal SELFTEST command %c queued\r\n", key);
}
#endif

#ifdef AX05A_ONLINE
static uint32_t next_revision(void)
{
    if (++online_revision == 0u) {
        ++online_revision;
    }
    return online_revision;
}

static Ax05aDecision validate_setpoints(const Ax05aRequest *request, Ax05aMode mode)
{
    if (!isfinite(request->position_mm) || !isfinite(request->speed_mm_s) ||
        !isfinite(request->id_a) || !isfinite(request->iq_a)) {
        return AX05A_BAD_REQUEST;
    }
    if (fabs(request->position_mm) > 110.0 || fabs(request->speed_mm_s) > 20.0 ||
        fabs(request->id_a) > 0.50 || fabs(request->iq_a) > 0.30) {
        return AX05A_OUT_OF_RANGE;
    }
    if ((mode != AX05A_POSITION && request->position_mm != 0.0) ||
        (mode != AX05A_SPEED && request->speed_mm_s != 0.0) ||
        (mode != AX05A_CURRENT && request->iq_a != 0.0) ||
        (mode == AX05A_ALIGNMENT && request->id_a != 0.0)) {
        return AX05A_BAD_REQUEST;
    }
    return AX05A_ACCEPTED;
}

static void setpoints(Ax04bCommand *command, const Ax05aRequest *request)
{
    command->frame[AX04B_CMD_POSITION] = request->position_mm;
    command->frame[AX04B_CMD_SPEED] = request->speed_mm_s;
    command->frame[AX04B_CMD_ID_REF] = request->id_a;
    command->frame[AX04B_CMD_IQ_TEST_REF] = request->iq_a;
}

static Ax05aDecision change_selection(const Ax05aRequest *request, uint32_t *revision)
{
    if (safety.armed) {
        return AX05A_STOP_FIRST;
    }
    if (request->action == AX05A_SELECT) {
        if (request->mode < AX05A_CURRENT || request->mode > AX05A_ALIGNMENT) {
            return AX05A_BAD_REQUEST;
        }
        const Ax05aDecision decision = validate_setpoints(request, request->mode);
        if (decision != AX05A_ACCEPTED) {
            return decision;
        }
        selected.online_mode = (uint32_t)request->mode;
        setpoints(&selected, request);
        have_selection = true;
    } else if (request->action == AX05A_FINE_PHASE) {
        if (!have_selection || request->selected_revision != selected.online_revision) {
            return AX05A_NOT_READY;
        }
        if (!isfinite(request->fine_phase_rad)) {
            return AX05A_BAD_REQUEST;
        }
        if (fabs(request->fine_phase_rad) > 0x1.921fb54442d18p+1) {
            return AX05A_OUT_OF_RANGE;
        }
        selected.fine_phase_rad = request->fine_phase_rad;
    } else {
        if (!have_selection || request->selected_revision != selected.online_revision) {
            return AX05A_NOT_READY;
        }
        confirmed_revision = selected.online_revision;
        selection_confirmed = true;
        *revision = confirmed_revision;
        return AX05A_ACCEPTED;
    }
    selected.online_revision = next_revision();
    selection_confirmed = false;
    *revision = selected.online_revision;
    return AX05A_ACCEPTED;
}

static Ax05aDecision apply_command(const Ax05aRequest *request, uint32_t *revision)
{
    Ax04bCommand command = command_slots[active_command];
    observe_pl_permission(read_rt(AX04B_STATUS), &command);
    switch (request->action) {
    case AX05A_SELECT:
    case AX05A_FINE_PHASE:
    case AX05A_CONFIRM:
        return change_selection(request, revision);
    case AX05A_START:
    case AX05A_ALIGN_START: {
        const bool align = request->action == AX05A_ALIGN_START;
        if (ax04b_build_mode == AX04B_REAL) {
            return AX05A_REAL_INHIBITED;
        }
        if (!safety.armed || safety.stop_pending || !selection_confirmed ||
            request->selected_revision != confirmed_revision ||
            command.online_mode != AX05A_IDLE ||
            align != (selected.online_mode == AX05A_ALIGNMENT)) {
            return AX05A_NOT_READY;
        }
        command.online_mode = selected.online_mode;
        command.fine_phase_rad = selected.fine_phase_rad;
        command.frame[AX04B_CMD_IQ_TEST] = command.online_mode == AX05A_CURRENT;
        command.frame[AX04B_CMD_POSITION_LOOP] = command.online_mode == AX05A_POSITION;
        command.frame[AX04B_CMD_SPEED_LOOP] = command.online_mode == AX05A_POSITION ||
            command.online_mode == AX05A_SPEED;
        command.frame[AX04B_CMD_ALIGN_ENABLE] = align;
        command.frame[AX04B_CMD_PWM] = 1.0;
        command.frame[AX04B_CMD_PI_RESET] = 0.0;
        command.relcon = true;
        command.encon = true;
        command.oe_disable = false;
        command.frame[AX04B_CMD_ID_REF] = selected.frame[AX04B_CMD_ID_REF];
        command.frame[AX04B_CMD_IQ_TEST_REF] = selected.frame[AX04B_CMD_IQ_TEST_REF];
        command.frame[AX04B_CMD_SPEED] = selected.frame[AX04B_CMD_SPEED];
        command.frame[AX04B_CMD_POSITION] = selected.frame[AX04B_CMD_POSITION];
        /* Ready is produced by the running Host; a position SEND is separate. */
        if (align) {
            ++command.start_ticket;
        }
        break;
    }
    case AX05A_SETPOINT: {
        if (ax04b_build_mode == AX04B_REAL) {
            return AX05A_REAL_INHIBITED;
        }
        const Ax05aMode mode = (Ax05aMode)command.online_mode;
        if (!safety.armed || mode == AX05A_IDLE || mode == AX05A_ALIGNMENT ||
            request->mode != mode || request->selected_revision != confirmed_revision) {
            return AX05A_NOT_READY;
        }
        const Ax05aDecision decision = validate_setpoints(request, mode);
        if (decision != AX05A_ACCEPTED) {
            return decision;
        }
        if (mode == AX05A_POSITION) {
            if (move_pending_revision != 0u) {
                return AX05A_PENDING;
            }
            if (ps_count == 0u) {
                return AX05A_NOT_READY;
            }
            /* Ready must come from a control frame that consumed this command. */
            const Ax05aPsFrame *ready_frame = &ps_history[(ps_next + PS_HISTORY - 1u) % PS_HISTORY];
            if (!ready_frame->host_ready || ready_frame->mode != AX05A_POSITION ||
                ready_frame->command_revision != command.online_revision) {
                return AX05A_NOT_READY;
            }
            command.frame[AX04B_CMD_MOVE] = 1.0 - command.frame[AX04B_CMD_MOVE];
        }
        setpoints(&command, request);
        break;
    }
    case AX05A_ALIGN_RESET:
    case AX05A_DRIVER_RESET:
        if (ax04b_build_mode == AX04B_REAL) {
            return AX05A_REAL_INHIBITED;
        }
        if (safety.armed) {
            return AX05A_STOP_FIRST;
        }
        if (request->action == AX05A_ALIGN_RESET) {
            if (command.init_reset_ticket != consumed_init_reset) {
                return AX05A_PENDING;
            }
            ++command.init_reset_ticket;
        } else {
            if (command.freset_ticket != consumed_freset) {
                return AX05A_PENDING;
            }
            ++command.freset_ticket;
        }
        break;
    case AX05A_PI_RESET:
        if (command.pi_reset_ticket != consumed_pi_reset) {
            return AX05A_PENDING;
        }
        ++command.pi_reset_ticket;
        break;
    default:
        return AX05A_BAD_REQUEST;
    }
    command.online_revision = next_revision();
    if (request->action == AX05A_SETPOINT && command.online_mode == AX05A_POSITION) {
        move_pending_revision = command.online_revision;
    }
    publish_command(&command);
    *revision = command.online_revision;
    return AX05A_ACCEPTED;
}

Ax05aReply ax05a_submit(const Ax05aRequest *request)
{
    Ax05aReply reply = {.decision = AX05A_BAD_REQUEST};
    if (request == NULL) {
        return reply;
    }
    reply.request_id = request->request_id;
    if (request->schema == AX05A_SCHEMA && request->action == AX05A_STOP) {
        disarm();
        reply.decision = AX05A_ACCEPTED;
        return reply;
    }
    const uint32_t distance = request->request_id - last_request_id;
    if (request->schema != AX05A_SCHEMA ||
        (have_request && (distance == 0u || distance >= UINT32_C(0x80000000)))) {
        return reply;
    }
    have_request = true;
    last_request_id = request->request_id;
    if (request->action == AX05A_ARM) {
        if (ax04b_build_mode == AX04B_REAL) {
            reply.decision = AX05A_REAL_INHIBITED;
        } else if (!selection_confirmed || request->selected_revision != confirmed_revision) {
            reply.decision = AX05A_NOT_READY;
        } else {
            reply.decision = arm_test() ? AX05A_ACCEPTED : AX05A_PL_DENIED;
        }
    } else if (request->action == AX05A_CLEAR) {
        reply.decision = clear_request() ? AX05A_ACCEPTED : AX05A_STOP_FIRST;
    } else if (request->action == AX05A_CALIBRATE) {
        if (ax05a_control_status().armed) {
            reply.decision = AX05A_STOP_FIRST;
        } else {
            reply.decision = configure_zero_current() ? AX05A_ACCEPTED : AX05A_NOT_READY;
        }
    } else {
        const uint32_t cpsr = irq_lock();
        reply.decision = apply_command(request, &reply.accepted_revision);
        irq_unlock(cpsr);
    }
    return reply;
}

Ax05aControlStatus ax05a_control_status(void)
{
    const uint32_t cpsr = irq_lock();
    const bool permission_lost = safety.armed &&
        pl_stop_reason(read_rt(AX04B_STATUS)) != AX04B_STOP_NONE;
    const Ax05aControlStatus control = {
        .selected_revision = selected.online_revision,
        .confirmed_revision = confirmed_revision,
        .dispatched_revision = command_slots[active_command].online_revision,
        .selected_mode = (Ax05aMode)selected.online_mode,
        .selection_confirmed = selection_confirmed && !permission_lost,
        .armed = safety.armed && !permission_lost,
        .clear_confirmed = safety.clear_confirmed,
        .stop_pending = safety.stop_pending || permission_lost
    };
    irq_unlock(cpsr);
    return control;
}
#endif

#ifndef MOTOR_CONTROL_ETHERNET
static void status_report(void)
{
    double values[AX04B_TELEMETRY_WORDS];
    const uint32_t cpsr = irq_lock();
    const uint32_t service_start = pmu_tick();
    const uint32_t status = read_rt(AX04B_STATUS);
    observe_pl_permission(status, &command_slots[active_command]);
    const uint32_t services = ax04b_model_service(values);
    const FrameRecord record = latest;
    const Counters counts = counters;
    const bool armed = safety.armed && !safety.stop_pending;
    maximum(&counters.max_service_mask, pmu_tick() - service_start);
    irq_unlock(cpsr);

    printf("AX04B mode=%" PRIu32 " status=%08" PRIx32 " events=%" PRIu32
        " spur=%" PRIu32 " duplicate=%" PRIu32 " safety_dup=%" PRIu32
        " snapshot_error=%" PRIu32 " overrun=%" PRIu32 " receipt_ok=%" PRIu32
        " rejected=%" PRIu32 " stop=%" PRIu32 "\r\n",
        ax04b_build_mode, status, counts.frames, counts.spurious,
        counts.duplicate, counts.safety_duplicate, counts.bad_snapshot,
        counts.overruns, counts.accepted, counts.rejected, counts.transport_stop);
    printf("armed=%u permit=%u stop_pending=%u stop_reason=%u stop_pl=%08" PRIx32
        " clear_ok=%" PRIu32 " clear_denied=%" PRIu32 " safety_calls=%" PRIu32
        " state=%" PRIu32 " done=%u align_id=%.6f start_ticket=%" PRIu32 "\r\n",
        (unsigned)armed, (unsigned)record.drive_permitted, (unsigned)record.stop_pending,
        (unsigned)record.stop_reason, record.stop_status, counts.clear_confirmed,
        counts.clear_denied, counts.safety_passes, record.alignment_state,
        (unsigned)record.alignment_done, record.alignment_id, record.start_ticket);
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
#ifdef AX05A_ONLINE
    if (online_trace.active) {
        irq_unlock(cpsr);
        return;
    }
    online_trace.count = 0u;
#endif
    trace_count = 0u;
    trace_on = true;
    irq_unlock(cpsr);
    xil_printf("AX04B recording up to 256 IRQ records\r\n");
}

static void print_irq_record(const FrameRecord *record)
{
    printf("%" PRIu32 ",%" PRIu32 ",%" PRIu64 ",%" PRIu32 ",%" PRIu32 ",%"
        PRIu32 ",%" PRIu32 ",%" PRIu32 ",%" PRIu32 ",%" PRIu32 ",%" PRIu32
        ",%" PRIu32 ",%" PRIu32 ",%" PRIu32 ",%" PRIu32 ",%" PRIu32 ",%"
        PRIu32 ",%" PRIu32 ",%" PRIu32 ",%" PRIu32 ",%" PRIu32 ",%" PRIu32
        ",%" PRIu32 ",%u,%u,%u,%u,%" PRIu32 ",%" PRIu32 ",%u,%u,%u,%u,"
        "%" PRIu32 ",%u,%" PRIu32 ",%u,%.9f\r\n",
        record->pending_sequence, record->sample_id, record->feedback_tick,
        record->entry_phase, record->quality, record->fault, record->calibration_version,
        record->config_version, record->model_version, record->feedback_status,
        record->target, record->offered_version, record->accepted_version,
        record->accepted_target, record->applied_version, record->applied_target,
        record->result, record->flags, record->entry_tick, record->read_done_tick,
        record->model_done_tick, record->accept_done_tick, record->ack_done_tick,
        (unsigned)record->position_valid, (unsigned)record->speed_valid,
        (unsigned)record->reference_valid, (unsigned)record->applied_coherent,
        record->pl_status, record->stop_status, (unsigned)record->stop_reason,
        (unsigned)record->stop_pending, (unsigned)record->drive_permitted,
        (unsigned)record->safety_pass, record->start_ticket, (unsigned)record->start_delivered,
        record->alignment_state, (unsigned)record->alignment_done, record->alignment_id);
}

static void trace_dump(void)
{
    const uint32_t cpsr = irq_lock();
    trace_on = false;
    const unsigned count = trace_count;
    irq_unlock(cpsr);
    printf("seq,id,tick,phase50MHz,quality,fault,cal_ver,cfg_ver,model_ver,fb_status,"
        "target,offer,accept_ver,accept_target,apply_ver,apply_target,result,flags,"
        "entry_pmu,read_pmu,model_pmu,accept_pmu,ack_pmu,pv,sv,rv,applied_coherent,"
        "pl_status,stop_pl,stop_reason,stop_pending,drive_permitted,safety_pass,"
        "start_ticket,start_delivered,alignment_state,alignment_done,alignment_id\r\n");
    for (unsigned i = 0u; i < count; ++i) {
        print_irq_record(&trace[i]);
    }
}

#endif

static bool diagnostic_begin(uint32_t *sequence)
{
    if ((read_rt(AX04B_STATUS) & AX04B_APPLIED_SEEN) == 0u) {
        return false;
    }
    *sequence = read_diag(0x0u);
    return true;
}

static uint32_t diagnostic_word(unsigned index)
{
    return read_diag(0x0cu + index * 4u);
}

#ifndef MOTOR_CONTROL_ETHERNET
static void diagnostics_dump(void)
{
#ifdef AX05A_ONLINE
    Ax05aDiagnostics diagnostics;
    if (!ax05a_read_diagnostics(&diagnostics)) {
        xil_printf("AX05A no diagnostic snapshot yet\r\n");
        return;
    }
    printf("AX05A diag seq=%" PRIu32 " rt_sample=%" PRIu32 " fault=%08" PRIx32
        " ack=%" PRIu32 " commit=%" PRIu32 " rejected=%" PRIu32
        " adopted_compare=%" PRIu32 ":%" PRIu32 ",%" PRIu32 ",%" PRIu32 " coherent=%u\r\n",
        diagnostics.sequence, diagnostics.rt_sample_id, diagnostics.rt_fault,
        diagnostics.exact_ack_count, diagnostics.commits, diagnostics.rejects,
        diagnostics.pwm_adopted_sequence, diagnostics.pwm_compare[0], diagnostics.pwm_compare[1],
        diagnostics.pwm_compare[2], (unsigned)diagnostics.pwm_receipt_coherent);
    for (unsigned i = 0u; i < DIAG_WORDS; ++i) {
        printf("%u,%08" PRIx32 "\r\n", i, diagnostics.words[i]);
    }
#else
    uint32_t words[DIAG_WORDS];
    uint32_t sequence;
    if (!diagnostic_begin(&sequence)) {
        xil_printf("AX04B wait for first adopted frame before diagnostic snapshot\r\n");
        return;
    }
    for (unsigned i = 0u; i < DIAG_WORDS; ++i) {
        words[i] = diagnostic_word(i);
    }
    printf("AX04B legacy 80-word adopted-PWM diagnostic seq=%" PRIu32 "\r\n", sequence);
    for (unsigned i = 0u; i < DIAG_WORDS; ++i) {
        printf("%u,%08" PRIx32 "\r\n", i, words[i]);
    }
#endif
}

#endif

#ifdef AX05A_ONLINE
static double diagnostic_fixed(uint32_t raw, double scale)
{
    const int64_t signed_raw = raw <= INT32_MAX ? raw : (int64_t)raw - INT64_C(4294967296);
    return (double)signed_raw * scale;
}

static bool matching_ps_frame(Ax05aSample *sample)
{
    const uint32_t cpsr = irq_lock();
    const uint32_t service_start = pmu_tick();
    bool found = false;
    for (unsigned i = 0u; i < ps_count; ++i) {
        const Ax05aPsFrame *frame = &ps_history[(ps_next + PS_HISTORY - 1u - i) % PS_HISTORY];
        if (frame->sample_id == sample->sample_id && frame->tick == sample->tick) {
            sample->ps = *frame;
            found = true;
            break;
        }
    }
    maximum(&counters.max_service_mask, pmu_tick() - service_start);
    irq_unlock(cpsr);
    return found;
}

bool ax05a_read_sample(Ax05aSample *sample)
{
    if (sample == NULL) {
        return false;
    }
    *sample = (Ax05aSample){.schema = AX05A_SCHEMA};
    if (!diagnostic_begin(&sample->pl_sequence)) {
        return false;
    }
    const uint32_t epoch = read_diag(0x04u);
    const uint32_t flags = read_diag(0x08u);
    const uint32_t ident = diagnostic_word(0);
    const uint32_t schema = diagnostic_word(1);
    sample->adc_quality = diagnostic_word(2);
    sample->sample_id = diagnostic_word(3);
    const uint32_t tick_lo = diagnostic_word(4);
    sample->tick = ax04b_join_words(tick_lo, diagnostic_word(5));
    sample->ia_a = diagnostic_fixed(diagnostic_word(8), 0x1p-24);
    sample->ib_a = diagnostic_fixed(diagnostic_word(9), 0x1p-24);
    sample->ic_a = diagnostic_fixed(diagnostic_word(10), 0x1p-24);
    sample->offset_a_counts = diagnostic_fixed(diagnostic_word(11), 0x1p-16);
    sample->offset_b_counts = diagnostic_fixed(diagnostic_word(12), 0x1p-16);
    sample->adc_calibration_version = diagnostic_word(15);
    const uint32_t encoder_angle_lo = diagnostic_word(32);
    sample->encoder_angle_rad = diagnostic_fixed(diagnostic_word(33), 1.0) +
        (double)encoder_angle_lo * 0x1p-32;
    const uint32_t foc_flags = diagnostic_word(41);
    const uint32_t foc_id = diagnostic_word(42);
    const uint32_t foc_tick_lo = diagnostic_word(43);
    const uint64_t foc_tick = ax04b_join_words(foc_tick_lo, diagnostic_word(44));
    sample->foc_reference_version = diagnostic_word(45);
    sample->id_ref_a = diagnostic_fixed(diagnostic_word(49), 0x1p-24);
    sample->iq_ref_a = diagnostic_fixed(diagnostic_word(50), 0x1p-24);
    const uint32_t theta_lo = diagnostic_word(51);
    const uint32_t theta_hi = diagnostic_word(52);
    sample->electrical_angle_rad = diagnostic_fixed(theta_hi, 1.0) + (double)theta_lo * 0x1p-32;
    const bool dq_extension = diagnostic_word(77) == AX05A_DQ_IDENT;
    if (dq_extension) {
        sample->dq_extension_id = AX05A_DQ_IDENT;
        sample->id_a = diagnostic_fixed(diagnostic_word(73), 0x1p-20);
        sample->iq_a = diagnostic_fixed(diagnostic_word(74), 0x1p-20);
        sample->ud_v = diagnostic_fixed(diagnostic_word(75), 0x1p-20);
        sample->uq_v = diagnostic_fixed(diagnostic_word(76), 0x1p-20);
    }
    (void)diagnostic_word(DIAG_WORDS - 1u); /* Always release, including invalid observations. */
    if (epoch != UINT32_C(0x4d430003) || ident != UINT32_C(0x4d435431) ||
        schema != 3u || (flags & 1u) == 0u) {
        return false;
    }
    sample->groups = AX05A_ADC;
    sample->calibration_done_a = (sample->adc_quality & (1u << 5)) != 0u;
    sample->calibration_done_b = (sample->adc_quality & (1u << 6)) != 0u;
    sample->current_valid = (sample->adc_quality & UINT32_C(0x1ff)) == UINT32_C(0xe7);
    sample->encoder_angle_valid = (sample->adc_quality & (1u << 11)) != 0u;
    if (matching_ps_frame(sample)) {
        sample->groups |= AX05A_PS;
    }
    if ((foc_flags & 6u) == 2u && foc_id == sample->sample_id && foc_tick == sample->tick) {
        sample->groups |= AX05A_FOC_REF;
        if (dq_extension && (foc_flags & 1u) != 0u) {
            sample->groups |= AX05A_DQ;
        }
    }
    return true;
}

static uint32_t read_pwm(uint32_t offset)
{
    return Xil_In32((UINTPTR)UINT32_C(0x80001000) + offset);
}

bool ax05a_read_diagnostics(Ax05aDiagnostics *diagnostics)
{
    if (diagnostics == NULL) {
        return false;
    }
    *diagnostics = (Ax05aDiagnostics){0};
    if (!diagnostic_begin(&diagnostics->sequence)) {
        return false;
    }
    for (unsigned i = 0u; i < DIAG_WORDS; ++i) {
        diagnostics->words[i] = diagnostic_word(i);
    }
    if (read_pwm(0) == UINT32_C(0x50574d01)) {
        diagnostics->pwm_status = read_pwm(0x04u);
        const uint32_t seq = read_pwm(0x0cu);
        for (unsigned i = 0u; i < 3u; ++i) {
            diagnostics->pwm_compare[i] = read_pwm(0x30u + i * 4u);
        }
        diagnostics->pwm_adopted_sequence = seq;
        diagnostics->pwm_receipt_coherent = (diagnostics->pwm_status & 8u) != 0u &&
            seq == read_pwm(0x0cu) && diagnostics->pwm_status == read_pwm(0x04u);
        diagnostics->pwm_period = read_pwm(0x40u);
        diagnostics->pwm_deadtime = read_pwm(0x44u);
        diagnostics->pwm_use_permission = read_pwm(0x24u);
    }
    const uint32_t cpsr = irq_lock();
    diagnostics->status = read_rt(AX04B_STATUS);
    diagnostics->irq_frames = counters.frames;
    diagnostics->exact_ack_count = online_ack_count;
    diagnostics->overruns = previous_overrun;
    diagnostics->commits = counters.accepted;
    diagnostics->rejects = counters.rejected;
    diagnostics->stop_reason = (uint32_t)safety.reason;
    diagnostics->rt_sample_id = latest.sample_id;
    diagnostics->rt_quality = latest.quality;
    diagnostics->rt_fault = latest.fault;
    diagnostics->rt_drive_flags = latest.flags;
    diagnostics->rt_tick = latest.feedback_tick;
    diagnostics->rt_ctrl_enable = read_rt(AX04B_IO_CONTROL);
    irq_unlock(cpsr);
    return true;
}

bool ax05a_trace_start(uint32_t groups)
{
    if (online_trace.active || groups == 0u || (groups & ~AX05A_ALL) != 0u) {
        return false;
    }
    const uint32_t capture_id = online_trace.capture_id + 1u;
    const uint32_t cpsr = irq_lock();
    if (trace_on) {
        irq_unlock(cpsr);
        return false;
    }
    trace_count = 0u;
    irq_unlock(cpsr);
    online_trace = (Ax05aTraceInfo){
        .schema = AX05A_SCHEMA, .application_id = ax04b_application_id,
        .pl_interface_id = AX04B_INTERFACE_ID, .hardware_profile = ax04b_build_mode,
        .pl_ticks_hz = 50000000u, .channel_mask = groups, .capture_id = capture_id, .active = true
    };
    return true;
}

bool ax05a_trace_poll(void)
{
    if (!online_trace.active) {
        return false;
    }
    Ax05aSample sample;
    if (!ax05a_read_sample(&sample)) {
        return false;
    }
    if (online_trace.count == 0u) {
        online_trace.first_groups = sample.groups;
        online_trace.first_mode = sample.ps.mode;
        online_trace.first_command_revision = sample.ps.command_revision;
        online_trace.first_foc_reference_version = sample.foc_reference_version;
        online_trace.first_id_ref_a = sample.id_ref_a;
        online_trace.first_iq_ref_a = sample.iq_ref_a;
        online_trace.first_offset_a_counts = sample.offset_a_counts;
        online_trace.first_offset_b_counts = sample.offset_b_counts;
    }
    if (online_trace.count != 0u) {
        const Ax05aSample *previous = &online_records[online_trace.count - 1u];
        const uint64_t delta = sample.tick - previous->tick;
        if (delta == 0u && sample.sample_id == previous->sample_id &&
            sample.pl_sequence == previous->pl_sequence &&
            sample.dq_extension_id == previous->dq_extension_id) {
            ++online_trace.duplicates;
            return false;
        }
        const uint64_t frames = delta / AX04B_TICK_STEP;
        if (sample.dq_extension_id != previous->dq_extension_id ||
            delta % AX04B_TICK_STEP != 0u || frames == 0u ||
            frames > UINT32_MAX || sample.sample_id - previous->sample_id !=
                (uint32_t)frames * AX04B_ID_STEP ||
            sample.pl_sequence - previous->pl_sequence != (uint32_t)frames) {
            online_trace.discontinuous = true;
            online_trace.active = false;
            return false;
        }
        const uint64_t missed = (uint64_t)online_trace.missed + frames - 1u;
        online_trace.missed = missed > UINT32_MAX ? UINT32_MAX : (uint32_t)missed;
    }
    sample.groups &= online_trace.channel_mask;
    online_trace.dq_extension_id = sample.dq_extension_id;
    online_records[online_trace.count++] = sample;
    if (online_trace.count == AX05A_TRACE_CAPACITY) {
        online_trace.full = true;
        online_trace.active = false;
    }
    return true;
}

void ax05a_trace_stop(void)
{
    online_trace.active = false;
}

Ax05aTraceInfo ax05a_trace_info(void)
{
    return online_trace;
}

bool ax05a_trace_read(uint32_t capture_id, uint32_t index, Ax05aSample *sample)
{
    if (sample == NULL || online_trace.active || capture_id != online_trace.capture_id ||
        index >= online_trace.count) {
        return false;
    }
    *sample = online_records[index];
    return true;
}

#ifndef MOTOR_CONTROL_ETHERNET
static void print_sample(const Ax05aSample *sample)
{
    printf("AX05A id=%" PRIu32 " tick=%" PRIu64 " groups=%x"
        " mode=%" PRIu32 " revision=%" PRIu32 " move=%" PRIu32 ":%" PRIu32
        " pos=%.6f/%.6f speed=%.6f/%.6f pos_valid=%u speed_valid=%u"
        " align=%" PRIu32 " fault=%08" PRIx32 " commit=%" PRIu32 ":%" PRIu32
        ":%" PRIu32 " p0=%" PRIu32 ":%" PRIu32 ":%u"
        " abc=%.6f,%.6f,%.6f current_valid=%u dq_ref=%.6f,%.6f theta=%.6f"
        " offset=%.4f,%.4f cal=%u,%u enc_theta=%.6f:%u"
        " dq=%.6f,%.6f uv=%.6f,%.6f\r\n",
        sample->sample_id, sample->tick, (unsigned)sample->groups,
        sample->ps.mode, sample->ps.command_revision,
        sample->ps.host_receipt_revision, sample->ps.host_status,
        sample->ps.position_mm, sample->ps.position_ref_mm, sample->ps.speed_mm_s,
        sample->ps.speed_ref_mm_s, (unsigned)sample->ps.position_valid,
        (unsigned)sample->ps.speed_valid, sample->ps.alignment_state, sample->ps.fault,
        sample->ps.commit_version, sample->ps.commit_target, sample->ps.commit_result,
        sample->ps.p0_version, sample->ps.p0_target, (unsigned)sample->ps.p0_valid,
        sample->ia_a, sample->ib_a, sample->ic_a, (unsigned)sample->current_valid,
        sample->id_ref_a, sample->iq_ref_a, sample->electrical_angle_rad,
        sample->offset_a_counts, sample->offset_b_counts,
        (unsigned)sample->calibration_done_a, (unsigned)sample->calibration_done_b,
        sample->encoder_angle_rad, (unsigned)sample->encoder_angle_valid,
        sample->id_a, sample->iq_a, sample->ud_v, sample->uq_v);
}

#endif

bool motor_control_parse_request(const char *line, Ax05aRequest *request)
{
    *request = (Ax05aRequest){.schema = AX05A_SCHEMA};
    unsigned header[3];
    double *const value[] = {
        &request->position_mm, &request->speed_mm_s, &request->id_a,
        &request->iq_a, &request->fine_phase_rad
    };
    const char *read_from = line;
    char *end;
    errno = 0;
    for (unsigned i = 0u; i < 3u; ++i) {
        const intmax_t parsed = strtoimax(read_from, &end, 10);
        if (end == read_from || errno != 0 || parsed < 0 || parsed > UINT32_MAX) {
            return false;
        }
        header[i] = (unsigned)parsed;
        read_from = end;
    }
    for (unsigned i = 0u; i < sizeof(value) / sizeof(*value); ++i) {
        *value[i] = strtod(read_from, &end);
        if (end == read_from || errno != 0 || !isfinite(*value[i])) {
            return false;
        }
        read_from = end;
    }
    while (isspace((unsigned char)*read_from)) {
        ++read_from;
    }
    if (*read_from != '\0' || header[0] > AX05A_DRIVER_RESET || header[1] > AX05A_ALIGNMENT) {
        return false;
    }
    request->action = (Ax05aAction)header[0];
    request->mode = (Ax05aMode)header[1];
    request->selected_revision = header[2];
    return true;
}

Ax05aReply motor_control_submit(Ax05aRequest request)
{
    static uint32_t transport_request_id;
    const uint32_t distance = last_request_id - transport_request_id;
    if (distance != 0u && distance < UINT32_C(0x80000000)) {
        transport_request_id = last_request_id;
    }
    request.request_id = ++transport_request_id;
    return ax05a_submit(&request);
}

#ifndef MOTOR_CONTROL_ETHERNET
static void online_uart_command(void)
{
    char input[192];
    if (fgets(input, sizeof(input), stdin) == NULL) {
        return;
    }
    if (strchr(input, '\n') == NULL) {
        int byte;
        do {
            byte = getchar();
        } while (byte != '\n' && byte != EOF);
        xil_printf("AX05A command line too long\r\n");
        return;
    }
    Ax05aRequest request;
    if (!motor_control_parse_request(input, &request)) {
        xil_printf("AX05A expected o <action> <mode> <selected_rev> <x> <v> <id> <iq> <fine>\r\n");
        return;
    }
    const Ax05aReply reply = motor_control_submit(request);
    const Ax05aControlStatus status = ax05a_control_status();
    printf("AX05A request=%" PRIu32 " decision=%u revision=%" PRIu32
        " selected=%" PRIu32 " confirmed=%" PRIu32 " valid=%u dispatched=%" PRIu32
        " armed=%u clear_confirmed=%u\r\n", reply.request_id, (unsigned)reply.decision,
        reply.accepted_revision, status.selected_revision, status.confirmed_revision,
        (unsigned)status.selection_confirmed, status.dispatched_revision,
        (unsigned)status.armed, (unsigned)status.clear_confirmed);
}

static void online_trace_dump(void)
{
    ax05a_trace_stop();
    const Ax05aTraceInfo info = ax05a_trace_info();
    printf("AX05A trace=%" PRIu32 " schema=%" PRIu32 " app=%08" PRIx32
        " pl=%08" PRIx32 " dq_schema=%08" PRIx32 " profile=%" PRIu32 " tick_hz=%" PRIu32
        " mask=%" PRIx32 " frames=%" PRIu32 " missed=%" PRIu32
        " duplicate=%" PRIu32 " full=%u discontinuous=%u\r\n",
        info.capture_id, info.schema, info.application_id, info.pl_interface_id,
        info.dq_extension_id, info.hardware_profile, info.pl_ticks_hz, info.channel_mask, info.count,
        info.missed, info.duplicates, (unsigned)info.full, (unsigned)info.discontinuous);
    for (uint32_t i = 0; i < info.count; ++i) {
        Ax05aSample sample;
        if (ax05a_trace_read(info.capture_id, i, &sample)) {
            print_sample(&sample);
        }
    }
}
#endif
#endif

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
#ifdef MOTOR_CONTROL_ETHERNET
    if (motor_control_net_start() && gem_device != NULL) {
        XScuGic_Enable(&interrupt_controller, GEM_IRQ);
    } else {
        xil_printf("GEM3 unavailable\r\n");
    }
    startup_uart = false;
    for (;;) {
        motor_control_net_poll();
    }
#else
    printf("AX04B WAIT app=%08" PRIx32 " mode=%" PRIu32 " base=%08" PRIx32
        " GIC_INTID=%" PRIu32 " feedback_nm_per_count=%u PMU_divider=%" PRIu32 "\r\n",
        ax04b_application_id, ax04b_build_mode, ax04b_mmio_base, ax04b_fabric_irq,
        AX04B_NM_PER_COUNT, pmu_divisor());
#ifdef AX05A_ONLINE
    xil_printf("o=AX05A command s=status g=REAL gains x=stop d=diagnostics n=sample "
        "L=trace start K=trace poll P=trace freeze/download l/p=IRQ trace\r\n");
#else
    xil_printf("c=calibrate g=REAL gains r=clear a=SELFTEST arm j=q-test i=align "
        "z=alignment-reset f=SELFTEST driver-reset x=stop s=status l=capture p=CSV d=PL snapshot\r\n");
#endif
    for (;;) {
        const char command = inbyte();
        switch (command) {
        case 'g': read_real_gains(); break;
#ifdef AX05A_ONLINE
        case 'o': online_uart_command(); break;
        case 'n': {
            Ax05aSample sample;
            if (ax05a_read_sample(&sample)) {
                print_sample(&sample);
            } else {
                xil_printf("AX05A no diagnostic snapshot yet\r\n");
            }
            break;
        }
        case 'L':
            if (ax05a_trace_start(AX05A_ALL)) {
                xil_printf("AX05A trace enabled, use K to sample\r\n");
            }
            break;
        case 'K': (void)ax05a_trace_poll(); break;
        case 'P': online_trace_dump(); break;
#else
        case 'c': configure_zero_current(); break;
        case 'r': clear_request(); break;
        case 'a': arm_test(); break;
        case 'j':
        case 'i':
        case 'z':
        case 'f': test_command(command); break;
#endif
        case 'x': disarm(); xil_printf("AX04B STOPPED\r\n"); break;
        case 's': status_report(); break;
        case 'l': trace_start(); break;
        case 'p': trace_dump(); break;
        case 'd': diagnostics_dump(); break;
        default: break;
        }
    }
#endif
}
