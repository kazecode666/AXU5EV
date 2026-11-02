/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: ETH01_Target.c
 *
 * Code generated for Simulink model 'ETH01_Target'.
 *
 * Model version                  : 1.2
 * Simulink Coder version         : 26.2 (R2026b) 22-May-2026
 * C/C++ source code generated on : Mon Nov  2 18:54:16 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: ARM Compatible->ARM Cortex-R
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "ETH01_Target.h"
#include <string.h>
#include <stdbool.h>
#include <stdint.h>

/* Block signals and states (default storage) */
DW_ETH01_Target_T ETH01_Target_DW;

/* External inputs (root inport signals with default storage) */
ExtU_ETH01_Target_T ETH01_Target_U;

/* External outputs (root outports fed by signals with default storage) */
ExtY_ETH01_Target_T ETH01_Target_Y;

/* Real-time model */
static RT_MODEL_ETH01_Target_T ETH01_Target_M_;
RT_MODEL_ETH01_Target_T *const ETH01_Target_M = &ETH01_Target_M_;

/* Model step function */
void ETH01_Target_step(void)
{
  int32_t k;
  uint32_t rtb_seqOut;
  uint16_t rtb_n;
  uint8_t rtb_reply[256];
  uint8_t saved;
  bool rtb_ReadyBool;
  bool rtb_ValidBool;
  bool rtb_valid;

  /* CCaller: '<Root>/RxTryPop' incorporates:
   *  Inport: '<Root>/TxReady'
   */
  Eth01Rx(ETH01_Target_U.TxReady, &ETH01_Target_DW.RxTryPop_o1[0],
          &ETH01_Target_DW.RxTryPop_o2, &ETH01_Target_DW.RxTryPop_o3,
          &ETH01_Target_DW.RxTryPop_o4, &ETH01_Target_DW.RxTryPop_o5);

  /* DataTypeConversion: '<Root>/ValidBool' */
  rtb_ValidBool = (ETH01_Target_DW.RxTryPop_o3 != 0);

  /* DataTypeConversion: '<Root>/ReadyBool' */
  rtb_ReadyBool = (ETH01_Target_DW.RxTryPop_o5 != 0);

  /* MATLAB Function: '<Root>/Process' */
  memcpy(&rtb_reply[0], &ETH01_Target_DW.saved[0], sizeof(uint8_t) << 8U);
  rtb_n = ETH01_Target_DW.savedLen;
  rtb_seqOut = ETH01_Target_DW.savedSeq;
  rtb_valid = false;

  /* Outport: '<Root>/Status' incorporates:
   *  MATLAB Function: '<Root>/Process'
   */
  ETH01_Target_Y.Status = 0U;

  /* MATLAB Function: '<Root>/Process' */
  if (ETH01_Target_DW.pending) {
    rtb_valid = true;

    /* Outport: '<Root>/Status' */
    ETH01_Target_Y.Status = 2U;
    ETH01_Target_DW.pending = (!rtb_ReadyBool && ETH01_Target_DW.pending);
  } else if (rtb_ValidBool) {
    if (ETH01_Target_DW.RxTryPop_o2 > 256) {
      /* Outport: '<Root>/Status' */
      ETH01_Target_Y.Status = 3U;
    } else {
      ETH01_Target_DW.savedLen = ETH01_Target_DW.RxTryPop_o2;
      ETH01_Target_DW.savedSeq = ETH01_Target_DW.RxTryPop_o4;
      rtb_seqOut = ETH01_Target_DW.handled + /*MW:OvSatOk*/ 1U;
      if (ETH01_Target_DW.handled + 1U < ETH01_Target_DW.handled) {
        rtb_seqOut = UINT32_MAX;
      }

      ETH01_Target_DW.handled = rtb_seqOut;
      ETH01_Target_DW.pending = true;
      for (k = 0; k < 256; k++) {
        saved = ETH01_Target_DW.RxTryPop_o1[k];
        ETH01_Target_DW.saved[k] = saved;
        if (k + 1 <= ETH01_Target_DW.RxTryPop_o2) {
          saved = (uint8_t)(ETH01_Target_DW.RxTryPop_o1[k] ^ 90);
          ETH01_Target_DW.saved[k] = saved;
        }

        rtb_reply[k] = saved;
      }

      rtb_n = ETH01_Target_DW.savedLen;
      rtb_seqOut = ETH01_Target_DW.savedSeq;
      rtb_valid = true;

      /* Outport: '<Root>/Status' */
      ETH01_Target_Y.Status = 1U;
      ETH01_Target_DW.pending = (!rtb_ReadyBool && ETH01_Target_DW.pending);
    }
  }

  /* Outport: '<Root>/Count' incorporates:
   *  MATLAB Function: '<Root>/Process'
   */
  ETH01_Target_Y.Count = ETH01_Target_DW.handled;

  /* Outport: '<Root>/TxStatus' incorporates:
   *  CCaller: '<Root>/TxTryPush'
   *  DataTypeConversion: '<Root>/ValidByte'
   *  MATLAB Function: '<Root>/Process'
   */
  ETH01_Target_Y.TxStatus = Eth01Tx(&rtb_reply[0], rtb_n, rtb_valid, rtb_seqOut,
    ETH01_Target_DW.handled, ETH01_Target_DW.RxTryPop_o5);
}

/* Model initialize function */
void ETH01_Target_initialize(void)
{
  /* (no initialization code required) */
}

/* Model terminate function */
void ETH01_Target_terminate(void)
{
  /* (no terminate code required) */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
