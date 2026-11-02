/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: ETH01_Model.h
 *
 * Code generated for Simulink model 'ETH01_Model'.
 *
 * Model version                  : 1.2
 * Simulink Coder version         : 26.2 (R2026b) 22-May-2026
 * C/C++ source code generated on : Mon Nov  2 18:29:05 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: ARM Compatible->ARM Cortex-R
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#ifndef ETH01_Model_h_
#define ETH01_Model_h_
#ifndef ETH01_Model_COMMON_INCLUDES_
#define ETH01_Model_COMMON_INCLUDES_
#include <stdbool.h>
#include <stdint.h>
#include "complex_types.h"
#include "math.h"
#endif                                 /* ETH01_Model_COMMON_INCLUDES_ */

#include "ETH01_Model_types.h"

/* Macros for accessing real-time model data structure */
#ifndef rtmGetErrorStatus
#define rtmGetErrorStatus(rtm)         ((rtm)->errorStatus)
#endif

#ifndef rtmSetErrorStatus
#define rtmSetErrorStatus(rtm, val)    ((rtm)->errorStatus = (val))
#endif

/* Block signals and states (default storage) for system '<Root>' */
typedef struct {
  uint32_t savedSeq;                   /* '<Root>/Process' */
  uint32_t handled;                    /* '<Root>/Process' */
  uint16_t savedLen;                   /* '<Root>/Process' */
  uint8_t saved[256];                  /* '<Root>/Process' */
  bool pending;                        /* '<Root>/Process' */
} DW_ETH01_Model_T;

/* External inputs (root inport signals with default storage) */
typedef struct {
  uint8_t Bytes[256];                  /* '<Root>/Bytes' */
  uint16_t Len;                        /* '<Root>/Len' */
  bool Valid;                          /* '<Root>/Valid' */
  uint32_t Seq;                        /* '<Root>/Seq' */
  bool TxReady;                        /* '<Root>/TxReady' */
} ExtU_ETH01_Model_T;

/* External outputs (root outports fed by signals with default storage) */
typedef struct {
  uint8_t Reply[256];                  /* '<Root>/Reply' */
  uint16_t ReplyLen;                   /* '<Root>/ReplyLen' */
  bool ReplyValid;                     /* '<Root>/ReplyValid' */
  uint32_t ReplySeq;                   /* '<Root>/ReplySeq' */
  uint32_t Count;                      /* '<Root>/Count' */
  uint8_t Status;                      /* '<Root>/Status' */
} ExtY_ETH01_Model_T;

/* Real-time Model Data Structure */
struct tag_RTM_ETH01_Model_T {
  const char * volatile errorStatus;
};

/* Block signals and states (default storage) */
extern DW_ETH01_Model_T ETH01_Model_DW;

/* External inputs (root inport signals with default storage) */
extern ExtU_ETH01_Model_T ETH01_Model_U;

/* External outputs (root outports fed by signals with default storage) */
extern ExtY_ETH01_Model_T ETH01_Model_Y;

/* Model entry point functions */
extern void ETH01_Model_initialize(void);
extern void ETH01_Model_step(void);
extern void ETH01_Model_terminate(void);

/* Real-time Model object */
extern RT_MODEL_ETH01_Model_T *const ETH01_Model_M;

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
 * '<Root>' : 'ETH01_Model'
 * '<S1>'   : 'ETH01_Model/Process'
 */
#endif                                 /* ETH01_Model_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
