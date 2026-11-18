/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: AXU5EV_Encoder_Feedback.h
 *
 * Code generated for Simulink model 'AXU5EV_Encoder_Feedback'.
 *
 * Model version                  : 1.2
 * Simulink Coder version         : 26.2 (R2026b) 22-May-2026
 * C/C++ source code generated on : Tue Nov 17 12:07:54 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: ARM Compatible->ARM Cortex-R
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#ifndef AXU5EV_Encoder_Feedback_h_
#define AXU5EV_Encoder_Feedback_h_
#ifndef AXU5EV_Encoder_Feedback_COMMON_INCLUDES_
#define AXU5EV_Encoder_Feedback_COMMON_INCLUDES_
#include <stdbool.h>
#include <stdint.h>
#include "complex_types.h"
#include "math.h"
#endif                            /* AXU5EV_Encoder_Feedback_COMMON_INCLUDES_ */

#include "AXU5EV_Encoder_Feedback_types.h"

/* Macros for accessing real-time model data structure */
#ifndef rtmGetErrorStatus
#define rtmGetErrorStatus(rtm)         ((rtm)->errorStatus)
#endif

#ifndef rtmSetErrorStatus
#define rtmSetErrorStatus(rtm, val)    ((rtm)->errorStatus = (val))
#endif

/* Block signals and states (default storage) for system '<Root>' */
typedef struct {
  int64_t Delay_50_Intervals_DSTATE[50];/* '<S1>/Delay_50_Intervals' */
  int64_t Delay_50_Intervals;          /* '<S1>/Delay_50_Intervals' */
  int64_t total;                       /* '<S1>/Frame_And_Count_Guard' */
  int64_t origin;                      /* '<S1>/Frame_And_Count_Guard' */
  uint64_t last_tick;                  /* '<S1>/Frame_And_Count_Guard' */
  uint32_t last_raw;                   /* '<S1>/Frame_And_Count_Guard' */
  uint32_t last_id;                    /* '<S1>/Frame_And_Count_Guard' */
  uint32_t last_bad;                   /* '<S1>/Frame_And_Count_Guard' */
  uint32_t old_zero;                   /* '<S1>/Frame_And_Count_Guard' */
  uint32_t old_version;                /* '<S1>/Frame_And_Count_Guard' */
  uint32_t old_scale;                  /* '<S1>/Frame_And_Count_Guard' */
  uint8_t filled;                      /* '<S1>/Frame_And_Count_Guard' */
  bool icLoad;                         /* '<S1>/Delay_50_Intervals' */
  bool initialized;                    /* '<S1>/Frame_And_Count_Guard' */
  bool old_reverse;                    /* '<S1>/Frame_And_Count_Guard' */
} DW_AXU5EV_Encoder_Feedback_T;

/* External inputs (root inport signals with default storage) */
typedef struct {
  uint32_t raw_count;                  /* '<Root>/raw_count' */
  uint32_t sample_id;                  /* '<Root>/sample_id' */
  uint64_t sample_tick;                /* '<Root>/sample_tick' */
  bool encoder_ready;                  /* '<Root>/encoder_ready' */
  uint32_t illegal_count;              /* '<Root>/illegal_count' */
  uint32_t zero_count;                 /* '<Root>/zero_count' */
  bool reverse;                        /* '<Root>/reverse' */
  uint32_t config_version;             /* '<Root>/config_version' */
  uint32_t nm_per_count;               /* '<Root>/nm_per_count' */
  bool reset;                          /* '<Root>/reset' */
} ExtU_AXU5EV_Encoder_Feedback_T;

/* External outputs (root outports fed by signals with default storage) */
typedef struct {
  double position_mm;                  /* '<Root>/position_mm' */
  double speed_mm_s;                   /* '<Root>/speed_mm_s' */
  bool position_valid;                 /* '<Root>/position_valid' */
  bool speed_valid;                    /* '<Root>/speed_valid' */
  uint8_t history_count;               /* '<Root>/history_count' */
  uint32_t status;                     /* '<Root>/status' */
  int64_t continuous_count;            /* '<Root>/continuous_count' */
} ExtY_AXU5EV_Encoder_Feedback_T;

/* Real-time Model Data Structure */
struct tag_RTM_AXU5EV_Encoder_Feedba_T {
  const char * volatile errorStatus;
};

/* Block signals and states (default storage) */
extern DW_AXU5EV_Encoder_Feedback_T AXU5EV_Encoder_Feedback_DW;

/* External inputs (root inport signals with default storage) */
extern ExtU_AXU5EV_Encoder_Feedback_T AXU5EV_Encoder_Feedback_U;

/* External outputs (root outports fed by signals with default storage) */
extern ExtY_AXU5EV_Encoder_Feedback_T AXU5EV_Encoder_Feedback_Y;

/* Model entry point functions */
extern void AXU5EV_Encoder_Feedback_initialize(void);
extern void AXU5EV_Encoder_Feedback_step(void);
extern void AXU5EV_Encoder_Feedback_terminate(void);

/* Real-time Model object */
extern RT_MODEL_AXU5EV_Encoder_Feedb_T *const AXU5EV_Encoder_Feedback_M;

/*-
 * The generated code includes comments that allow you to trace directly
 * back to the appropriate location in the model.  The basic format
 * is <system>/block_name, where system is the system number (uniquely
 * assigned by Simulink) and block_name is the name of the block.
 *
 * Use the MATLAB hilite_system command to trace the generated code back
 * to the model.  For example,
 *
 * hilite_system('<S3>')    - opens system 3
 * hilite_system('<S3>/Kp') - opens and selects block Kp which resides in S3
 *
 * Here is the system hierarchy for this model
 *
 * '<Root>' : 'AXU5EV_Encoder_Feedback'
 * '<S1>'   : 'AXU5EV_Encoder_Feedback/Caculate_measurement'
 * '<S2>'   : 'AXU5EV_Encoder_Feedback/Caculate_measurement/Frame_And_Count_Guard'
 */
#endif                                 /* AXU5EV_Encoder_Feedback_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
