/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: ETH01_Model.c
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

#include "ETH01_Model.h"
#include <string.h>
#include <stdint.h>

/* Block signals and states (default storage) */
DW_ETH01_Model_T ETH01_Model_DW;

/* External inputs (root inport signals with default storage) */
ExtU_ETH01_Model_T ETH01_Model_U;

/* External outputs (root outports fed by signals with default storage) */
ExtY_ETH01_Model_T ETH01_Model_Y;

/* Real-time model */
static RT_MODEL_ETH01_Model_T ETH01_Model_M_;
RT_MODEL_ETH01_Model_T *const ETH01_Model_M = &ETH01_Model_M_;

/* Model step function */
void ETH01_Model_step(void)
{
  int32_t k;
  uint32_t qY;
  uint8_t Bytes;

  /* Outport: '<Root>/Reply' incorporates:
   *  MATLAB Function: '<Root>/Process'
   */
  memcpy(&ETH01_Model_Y.Reply[0], &ETH01_Model_DW.saved[0], sizeof(uint8_t) <<
         8U);

  /* Outport: '<Root>/ReplyLen' incorporates:
   *  MATLAB Function: '<Root>/Process'
   */
  ETH01_Model_Y.ReplyLen = ETH01_Model_DW.savedLen;

  /* Outport: '<Root>/ReplySeq' incorporates:
   *  MATLAB Function: '<Root>/Process'
   */
  ETH01_Model_Y.ReplySeq = ETH01_Model_DW.savedSeq;

  /* Outport: '<Root>/ReplyValid' incorporates:
   *  MATLAB Function: '<Root>/Process'
   */
  ETH01_Model_Y.ReplyValid = false;

  /* Outport: '<Root>/Status' incorporates:
   *  MATLAB Function: '<Root>/Process'
   */
  ETH01_Model_Y.Status = 0U;

  /* MATLAB Function: '<Root>/Process' incorporates:
   *  Inport: '<Root>/Len'
   *  Inport: '<Root>/Seq'
   *  Inport: '<Root>/TxReady'
   *  Inport: '<Root>/Valid'
   */
  if (ETH01_Model_DW.pending) {
    /* Outport: '<Root>/ReplyValid' */
    ETH01_Model_Y.ReplyValid = true;

    /* Outport: '<Root>/Status' */
    ETH01_Model_Y.Status = 2U;
    ETH01_Model_DW.pending = !ETH01_Model_U.TxReady;
  } else if (ETH01_Model_U.Valid) {
    if (ETH01_Model_U.Len > 256) {
      /* Outport: '<Root>/Status' */
      ETH01_Model_Y.Status = 3U;
    } else {
      ETH01_Model_DW.savedLen = ETH01_Model_U.Len;
      ETH01_Model_DW.savedSeq = ETH01_Model_U.Seq;
      qY = ETH01_Model_DW.handled + /*MW:OvSatOk*/ 1U;
      if (ETH01_Model_DW.handled + 1U < ETH01_Model_DW.handled) {
        qY = UINT32_MAX;
      }

      ETH01_Model_DW.handled = qY;

      /* Outport: '<Root>/Reply' incorporates:
       *  Inport: '<Root>/Bytes'
       *  Inport: '<Root>/Seq'
       */
      for (k = 0; k < 256; k++) {
        Bytes = ETH01_Model_U.Bytes[k];
        ETH01_Model_DW.saved[k] = Bytes;
        if (k + 1 <= ETH01_Model_U.Len) {
          Bytes = (uint8_t)(Bytes ^ 90);
          ETH01_Model_DW.saved[k] = Bytes;
        }

        ETH01_Model_Y.Reply[k] = Bytes;
      }

      /* Outport: '<Root>/ReplyLen' */
      ETH01_Model_Y.ReplyLen = ETH01_Model_DW.savedLen;

      /* Outport: '<Root>/ReplySeq' */
      ETH01_Model_Y.ReplySeq = ETH01_Model_DW.savedSeq;

      /* Outport: '<Root>/ReplyValid' */
      ETH01_Model_Y.ReplyValid = true;

      /* Outport: '<Root>/Status' */
      ETH01_Model_Y.Status = 1U;
      ETH01_Model_DW.pending = !ETH01_Model_U.TxReady;
    }
  }

  /* Outport: '<Root>/Count' incorporates:
   *  MATLAB Function: '<Root>/Process'
   */
  ETH01_Model_Y.Count = ETH01_Model_DW.handled;
}

/* Model initialize function */
void ETH01_Model_initialize(void)
{
  /* (no initialization code required) */
}

/* Model terminate function */
void ETH01_Model_terminate(void)
{
  /* (no terminate code required) */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
