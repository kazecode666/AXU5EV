#ifndef AX04B_ADAPTER_H
#define AX04B_ADAPTER_H

#include <stdbool.h>
#include <stdint.h>

enum {
    AX04B_CMD_WORDS = 20,
    AX04B_MODEL_REF_WORDS = 8,
    AX04B_REF_WORDS = 8,
    AX04B_TELEMETRY_WORDS = 12,
    AX04B_CMD_IQ_TEST = 3,
    AX04B_CMD_IQ_TEST_REF = 4,
    AX04B_CMD_PWM = 7,
    AX04B_CMD_PI_RESET = 8,
    AX04B_CMD_ALIGN_ENABLE = 15,
    AX04B_CMD_ALIGN_START = 16,
    AX04B_CMD_ALIGN_RESET = 17
};

typedef struct {
    uint32_t sequence;
    uint32_t id;
    uint64_t tick;
    uint32_t raw_count;
    uint32_t illegal_count;
    uint32_t quality;
    uint32_t calibration_version;
    uint32_t config_version;
    uint32_t fault;
} Ax04bFeedback;

typedef struct {
    double frame[AX04B_CMD_WORDS];
    uint32_t clear_ticket;
    uint32_t start_ticket;
    uint32_t init_reset_ticket;
    uint32_t freset_ticket;
    bool relcon;
    bool encon;
    bool oe_disable;
} Ax04bCommand;

typedef struct {
    double value[AX04B_MODEL_REF_WORDS];
    uint32_t model_version;
    uint32_t model_sample;
    uint32_t feedback_status;
    uint32_t alignment_state;
    double alignment_id;
    bool alignment_done;
    bool position_valid;
    bool speed_valid;
    bool drives[5];
} Ax04bModelResult;

typedef struct {
    uint32_t word[AX04B_REF_WORDS];
    uint32_t target;
} Ax04bReference;

typedef enum {
    AX04B_NEW_FRAME,
    AX04B_DUPLICATE,
    AX04B_SAFETY_DUPLICATE
} Ax04bDispatch;

uint64_t ax04b_join_words(uint32_t low, uint32_t high);
bool ax04b_feedback_contract(const Ax04bFeedback *feedback, unsigned mode);
bool ax04b_current_qualified(const Ax04bFeedback *feedback);
Ax04bDispatch ax04b_dispatch(const Ax04bFeedback *previous,
    const Ax04bFeedback *feedback, bool safety_request);
void ax04b_safe_reference(uint32_t feedback_id, uint32_t version,
    Ax04bReference *reference);
bool ax04b_encode_reference(const Ax04bModelResult *model, uint32_t feedback_id,
    uint32_t version, bool allow_drive, Ax04bReference *reference);

void ax04b_model_initialize(void);
void ax04b_model_run(const Ax04bFeedback *feedback, const Ax04bCommand *command,
    bool transport_invalid, bool clear, bool start, bool init_reset, bool driver_reset,
    Ax04bModelResult *result);
uint32_t ax04b_model_service(double telemetry[AX04B_TELEMETRY_WORDS]);

#endif
