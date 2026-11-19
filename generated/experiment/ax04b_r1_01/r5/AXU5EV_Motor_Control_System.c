/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: AXU5EV_Motor_Control_System.c
 *
 * Code generated for Simulink model 'AXU5EV_Motor_Control_System'.
 *
 * Model version                  : 1.173
 * Simulink Coder version         : 26.2 (R2026b) 22-May-2026
 * C/C++ source code generated on : Thu Nov 19 16:47:08 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: ARM Compatible->ARM Cortex-R
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "AXU5EV_Motor_Control_System.h"
#include <stdint.h>
#include "rt_nonfinite.h"
#include <string.h>
#include <math.h>
#include "AXU5EV_Motor_Control_System_private.h"
#include <stdbool.h>
#include "zero_crossing_types.h"

/* Named constants for Chart: '<S19>/Angle_Init' */
#define AXU5EV_Motor_Co_IN_RAMP_DOWN_ID ((uint8_t)4U)
#define AXU5EV_Motor_Cont_IN_HOLD_ALIGN ((uint8_t)2U)
#define AXU5EV_Motor_Control_IN_RAMP_ID ((uint8_t)5U)
#define AXU5EV_Motor_Control_Sy_IN_DONE ((uint8_t)1U)
#define AXU5EV_Motor_Control_Sy_IN_IDLE ((uint8_t)3U)
#define AXU5EV_Motor_IN_NO_ACTIVE_CHILD ((uint8_t)0U)

/* Block signals and states (default storage) */
DW_AXU5EV_Motor_Control_Syste_T AXU5EV_Motor_Control_System_DW;

/* Previous zero-crossings (trigger) states */
PrevZCX_AXU5EV_Motor_Control__T AXU5EV_Motor_Control_Sy_PrevZCX;

/* External inputs (root inport signals with default storage) */
ExtU_AXU5EV_Motor_Control_Sys_T AXU5EV_Motor_Control_System_U;

/* External outputs (root outports fed by signals with default storage) */
ExtY_AXU5EV_Motor_Control_Sys_T AXU5EV_Motor_Control_System_Y;

/* Real-time model */
static RT_MODEL_AXU5EV_Motor_Control_T AXU5EV_Motor_Control_System_M_;
RT_MODEL_AXU5EV_Motor_Control_T *const AXU5EV_Motor_Control_System_M =
  &AXU5EV_Motor_Control_System_M_;

/* Forward declaration for local functions */
static double AXU5EV_Motor_Control_Sy_minimum(const double x[4]);
static double AXU5EV_Motor_Control_Sy_maximum(const double x[3]);
static double AXU5EV_Motor_Control_System_mod(double x, double y);
void mul_wide_u64(uint64_t in0, uint64_t in1, uint64_t *ptrOutBitsHi, uint64_t
                  *ptrOutBitsLo)
{
  uint64_t in0Hi;
  uint64_t in0Lo;
  uint64_t in1Hi;
  uint64_t in1Lo;
  uint64_t outBitsLo;
  uint64_t productHiLo;
  uint64_t productLoHi;
  in0Hi = in0 >> UINT64_C(32);
  in0Lo = in0 & UINT64_C(4294967295);
  in1Hi = in1 >> UINT64_C(32);
  in1Lo = in1 & UINT64_C(4294967295);
  productHiLo = in0Hi * in1Lo;
  productLoHi = in0Lo * in1Hi;
  in0Lo *= in1Lo;
  in1Lo = UINT64_C(0);
  outBitsLo = (productLoHi << /*MW:OvBitwiseOk*/ UINT64_C(32)) +
    /*MW:OvCarryOk*/ in0Lo;
  if (outBitsLo < in0Lo) {
    in1Lo = UINT64_C(1);
  }

  in0Lo = outBitsLo;
  outBitsLo += /*MW:OvCarryOk*/ productHiLo << /*MW:OvBitwiseOk*/ UINT64_C(32);
  if (outBitsLo < in0Lo) {
    in1Lo++;
  }

  *ptrOutBitsHi = (((productLoHi >> UINT64_C(32)) + (productHiLo >> UINT64_C(32)))
                   + in0Hi * in1Hi) + in1Lo;
  *ptrOutBitsLo = outBitsLo;
}

uint64_t mul_u64_sat(uint64_t a, uint64_t b)
{
  uint64_t result;
  uint64_t u64_chi;
  mul_wide_u64(a, b, &u64_chi, &result);
  if (u64_chi) {
    result = UINT64_MAX;
  }

  return result;
}

double rt_powd_snf(double u0, double u1)
{
  double y;
  if (rtIsNaN(u0) || rtIsNaN(u1)) {
    y = (rtNaN);
  } else {
    double tmp;
    double tmp_0;
    tmp = fabs(u0);
    tmp_0 = fabs(u1);
    if (rtIsInf(u1)) {
      if (tmp == 1.0) {
        y = 1.0;
      } else if (tmp > 1.0) {
        if (u1 > 0.0) {
          y = (rtInf);
        } else {
          y = 0.0;
        }
      } else if (u1 > 0.0) {
        y = 0.0;
      } else {
        y = (rtInf);
      }
    } else if (tmp_0 == 0.0) {
      y = 1.0;
    } else if (tmp_0 == 1.0) {
      if (u1 > 0.0) {
        y = u0;
      } else {
        y = 1.0 / u0;
      }
    } else if (u1 == 2.0) {
      y = u0 * u0;
    } else if ((u1 == 0.5) && (u0 >= 0.0)) {
      y = sqrt(u0);
    } else if ((u0 < 0.0) && (u1 > floor(u1))) {
      y = (rtNaN);
    } else {
      y = pow(u0, u1);
    }
  }

  return y;
}

/* Function for MATLAB Function: '<S17>/Host_Core' */
static double AXU5EV_Motor_Control_Sy_minimum(const double x[4])
{
  double ex;
  int32_t idx;
  int32_t k;
  if (!rtIsNaN(x[0])) {
    idx = 1;
  } else {
    idx = 0;
    k = 2;
    while (k < 5) {
      if (!rtIsNaN(x[k - 1])) {
        idx = k;
        break;
      } else {
        k++;
      }
    }
  }

  if (idx == 0) {
    ex = x[0];
  } else {
    ex = x[idx - 1];
    for (k = idx + 1; k < 5; k++) {
      double x_0;
      x_0 = x[k - 1];
      if (ex > x_0) {
        ex = x_0;
      }
    }
  }

  return ex;
}

/* Function for MATLAB Function: '<S17>/Host_Core' */
static double AXU5EV_Motor_Control_Sy_maximum(const double x[3])
{
  double ex;
  int32_t idx;
  int32_t k;
  if (!rtIsNaN(x[0])) {
    idx = 1;
  } else {
    idx = 0;
    k = 2;
    while (k < 4) {
      if (!rtIsNaN(x[k - 1])) {
        idx = k;
        break;
      } else {
        k++;
      }
    }
  }

  if (idx == 0) {
    ex = x[0];
  } else {
    ex = x[idx - 1];
    for (k = idx + 1; k < 4; k++) {
      double x_0;
      x_0 = x[k - 1];
      if (ex < x_0) {
        ex = x_0;
      }
    }
  }

  return ex;
}

/* Function for MATLAB Function: '<S17>/Host_Core' */
static double AXU5EV_Motor_Control_System_mod(double x, double y)
{
  double r;
  if (y == 0.0) {
    r = x;
    if (x == 0.0) {
      r = y;
    }
  } else if (rtIsNaN(x)) {
    r = (rtNaN);
  } else if (rtIsNaN(y)) {
    r = (rtNaN);
  } else if (rtIsInf(x)) {
    r = (rtNaN);
  } else if (rtIsInf(y)) {
    if (y > 0.0) {
      if (x > 0.0) {
        r = x;
      } else if (x < 0.0) {
        r = y;
      } else {
        r = 0.0;
      }
    } else if (x > 0.0) {
      r = y;
    } else if (x < 0.0) {
      r = x;
    } else {
      r = -0.0;
    }
  } else {
    if (y > floor(y)) {
      double q;
      q = fabs(x / y);
      if (fabs(q - floor(q + 0.5)) > 2.220446049250313E-16 * q) {
        r = fmod(x, y);
      } else {
        r = 0.0;
      }
    } else {
      r = fmod(x, y);
    }

    if (r == 0.0) {
      r = y * 0.0;
    } else if (r < 0.0) {
      if (y > 0.0) {
        r += y;
      }
    } else if ((r > 0.0) && (y < 0.0)) {
      r += y;
    }
  }

  return r;
}

/* Model step function */
void PL_Frame_IRQ(void)
{
  double rtb_clean[20];
  double rtb_TmpSignalConversionAtSFunct[11];
  double cfg[4];
  double cfg_0[3];
  double D;
  double Ta;
  double Tc;
  double V;
  double q;
  double rtb_Sum1;
  double rtb_iq_lim_ASR;
  double s;
  double t;
  double tick;
  int64_t delta;
  uint64_t id_delta;
  uint64_t qY;
  uint64_t tick_delta;
  int32_t i;
  uint32_t duplicate_tmp;
  bool b_0[41];
  bool c_0[41];
  bool b[20];
  bool c[20];
  bool LogicalOperator;
  bool advance;
  bool clear_allowed;
  bool clear_allowed_tmp;
  bool clear_allowed_tmp_0;
  bool clear_allowed_tmp_1;
  bool command_valid;
  bool fault_tmp;
  bool guard1;
  bool guard2;
  bool guard3;
  bool guard4;
  bool hard_fault;
  bool new_tick;
  bool permit_tmp;
  bool raw_fault;
  bool rtb_Alignment_Fault_Active_g;
  bool rtb_Alignment_Ready_p;
  bool rtb_Compare;
  bool rtb_Control_Fault;
  bool rtb_LogicalOperator;
  bool rtb_LogicalOperator3;
  bool rtb_Software_Alignment_Permit;
  bool rtb_System_Fault_Not;
  bool rtb_restart_history;

  /* RootInportFunctionCallGenerator generated from: '<Root>/PL_Frame_IRQ' incorporates:
   *  SubSystem: '<Root>/Motor_Control_ISR'
   *
   * Block description for RootInportFunctionCallGenerator generated from '<Root>/PL_Frame_IRQ':
   *  External function-call entry at each accepted 100us ADC/QEP feedback
   *  frame. HW_BINDING_PENDING: physical PL IRQ/GIC registration and atomic
   *  driver binding.
   */
  /* MATLAB Function: '<S5>/Finite_Command' incorporates:
   *  Inport: '<Root>/CommandFrame'
   *
   * Block description for '<Root>/CommandFrame':
   *  Interface version 1, 20 double internal fields. Binder overrides
   *  measured speed/position/fault and disables replay. See AX04 report for
   *  exact field groups.
   */
  for (i = 0; i < 20; i++) {
    rtb_clean[i] = AXU5EV_Motor_Control_System_U.CommandFrame[i];
    b[i] = !rtIsInf(AXU5EV_Motor_Control_System_U.CommandFrame[i]);
    c[i] = !rtIsNaN(AXU5EV_Motor_Control_System_U.CommandFrame[i]);
  }

  advance = true;
  i = 0;
  while (i < 20) {
    if (!b[i] || !c[i]) {
      advance = false;
      break;
    } else {
      i++;
    }
  }

  if (!advance) {
    memset(&rtb_clean[0], 0, 20U * sizeof(double));
  }

  /* Outport: '<Root>/continuous_count' incorporates:
   *  MATLAB Function: '<S8>/Frame_And_Count_Guard'
   */
  AXU5EV_Motor_Control_System_Y.continuous_count =
    AXU5EV_Motor_Control_System_DW.total;

  /* MATLAB Function: '<S8>/Frame_And_Count_Guard' */
  advance = false;
  rtb_restart_history = false;

  /* Outport: '<Root>/position_valid' incorporates:
   *  MATLAB Function: '<S8>/Frame_And_Count_Guard'
   */
  AXU5EV_Motor_Control_System_Y.position_valid = false;

  /* Outport: '<Root>/speed_valid' incorporates:
   *  MATLAB Function: '<S8>/Frame_And_Count_Guard'
   */
  AXU5EV_Motor_Control_System_Y.speed_valid = false;

  /* MATLAB Function: '<S8>/Frame_And_Count_Guard' incorporates:
   *  Constant: '<S2>/Encoder_Config_Version'
   *  Constant: '<S2>/Encoder_Forward'
   *  Constant: '<S2>/Encoder_Nanometres_Per_Count'
   *  Constant: '<S2>/Mechanical_Zero_Count'
   *  Inport: '<Root>/encoder_ready'
   *  Inport: '<Root>/illegal_count'
   *  Inport: '<Root>/raw_count'
   *  Inport: '<Root>/sample_id'
   *  Inport: '<Root>/sample_tick'
   *
   * Block description for '<Root>/sample_tick':
   *  uint64 timestamp in the existing 50MHz feedback clock domain, tick
   *  unit 20ns. Belongs to the same frozen frame as sample_id/raw_count.
   */
  AXU5EV_Motor_Control_System_Y.feedback_status = 0U;
  if (!AXU5EV_Motor_Control_System_U.encoder_ready) {
    AXU5EV_Motor_Control_System_DW.initialized = false;
    AXU5EV_Motor_Control_System_DW.filled = 0U;

    /* Outport: '<Root>/history_count' */
    AXU5EV_Motor_Control_System_Y.history_count = 0U;
    rtb_restart_history = true;
    AXU5EV_Motor_Control_System_Y.feedback_status = 16U;
  } else {
    guard1 = false;
    guard2 = false;
    guard3 = false;
    guard4 = false;
    if (AXU5EV_Motor_Control_System_DW.initialized) {
      if (AXU5EV_Motor_Control_System_U.sample_id >=
          AXU5EV_Motor_Control_System_DW.last_id_f) {
        id_delta = (uint64_t)AXU5EV_Motor_Control_System_U.sample_id -
          /*MW:operator MISRA2012:D4.1 CERT-C:INT30-C 'Justifying MISRA C rule violation'*/
          /*MW:OvSatOk*/ AXU5EV_Motor_Control_System_DW.last_id_f;
        if (id_delta > AXU5EV_Motor_Control_System_U.sample_id) {
          id_delta = UINT64_C(0);
        }
      } else {
        id_delta = ((uint64_t)AXU5EV_Motor_Control_System_U.sample_id -
                    AXU5EV_Motor_Control_System_DW.last_id_f) + UINT64_C
          (4294967296);
      }

      if (AXU5EV_Motor_Control_System_U.sample_tick >=
          AXU5EV_Motor_Control_System_DW.last_tick) {
        tick_delta = AXU5EV_Motor_Control_System_U.sample_tick -
          /*MW:operator MISRA2012:D4.1 CERT-C:INT30-C 'Justifying MISRA C rule violation'*/
          /*MW:OvSatOk*/ AXU5EV_Motor_Control_System_DW.last_tick;
        if (tick_delta > AXU5EV_Motor_Control_System_U.sample_tick) {
          tick_delta = UINT64_C(0);
        }
      } else {
        qY = (AXU5EV_Motor_Control_System_U.sample_tick -
              AXU5EV_Motor_Control_System_DW.last_tick) + UINT64_MAX;
        if (qY < UINT64_MAX - AXU5EV_Motor_Control_System_DW.last_tick) {
          qY = UINT64_MAX;
        }

        tick_delta = qY + /*MW:OvSatOk*/ UINT64_C(1);
        if (qY + UINT64_C(1) < qY) {
          tick_delta = UINT64_MAX;
        }
      }

      if ((id_delta == UINT64_C(0)) && (tick_delta == UINT64_C(0))) {
        AXU5EV_Motor_Control_System_Y.feedback_status = 2U;

        /* Outport: '<Root>/position_valid' */
        AXU5EV_Motor_Control_System_Y.position_valid = true;
        if ((AXU5EV_Motor_Control_System_U.raw_count !=
             AXU5EV_Motor_Control_System_DW.last_raw) ||
            (AXU5EV_Motor_Control_System_U.illegal_count !=
             AXU5EV_Motor_Control_System_DW.last_bad)) {
          AXU5EV_Motor_Control_System_DW.initialized = false;
          AXU5EV_Motor_Control_System_DW.filled = 0U;

          /* Outport: '<Root>/position_valid' */
          AXU5EV_Motor_Control_System_Y.position_valid = false;
          rtb_restart_history = true;
          AXU5EV_Motor_Control_System_Y.feedback_status = 82U;
        }

        /* Outport: '<Root>/history_count' incorporates:
         *  Inport: '<Root>/illegal_count'
         *  Inport: '<Root>/raw_count'
         */
        AXU5EV_Motor_Control_System_Y.history_count =
          AXU5EV_Motor_Control_System_DW.filled;
      } else if (AXU5EV_Motor_Control_System_U.illegal_count !=
                 AXU5EV_Motor_Control_System_DW.last_bad) {
        AXU5EV_Motor_Control_System_DW.initialized = false;
        AXU5EV_Motor_Control_System_DW.filled = 0U;

        /* Outport: '<Root>/history_count' */
        AXU5EV_Motor_Control_System_Y.history_count = 0U;
        rtb_restart_history = true;
        AXU5EV_Motor_Control_System_Y.feedback_status = 16U;
      } else if ((id_delta != UINT64_C(500)) || (tick_delta != UINT64_C(5000)))
      {
        if ((id_delta == UINT64_C(0)) || (id_delta > UINT64_C(2147483647)) ||
            (id_delta - id_delta / UINT64_C(500) * UINT64_C(500) != UINT64_C(0))
            || (tick_delta != mul_u64_sat(id_delta, UINT64_C(10)))) {
          AXU5EV_Motor_Control_System_DW.initialized = false;
          AXU5EV_Motor_Control_System_DW.filled = 0U;

          /* Outport: '<Root>/history_count' */
          AXU5EV_Motor_Control_System_Y.history_count = 0U;
          rtb_restart_history = true;
          AXU5EV_Motor_Control_System_Y.feedback_status = 80U;
        } else {
          AXU5EV_Motor_Control_System_DW.filled = 0U;
          rtb_restart_history = true;
          AXU5EV_Motor_Control_System_Y.feedback_status = 4U;
          guard4 = true;
        }
      } else {
        guard4 = true;
      }
    } else {
      AXU5EV_Motor_Control_System_DW.total =
        AXU5EV_Motor_Control_System_U.raw_count;
      if ((uint32_t)AXU5EV_Motor_Control_System_DW.total > 2147483647U) {
        AXU5EV_Motor_Control_System_DW.total -= INT64_C(4294967296);
      }

      AXU5EV_Motor_Control_System_Y.feedback_status = 1U;
      AXU5EV_Motor_Control_System_DW.filled = 0U;
      rtb_restart_history = true;
      guard3 = true;
    }

    if (guard4) {
      delta = (int64_t)AXU5EV_Motor_Control_System_U.raw_count -
        AXU5EV_Motor_Control_System_DW.last_raw;
      if (delta > INT64_C(2147483647)) {
        delta -= INT64_C(4294967296);
      } else if (delta < -INT64_C(2147483648)) {
        delta += INT64_C(4294967296);
      }

      if ((int32_t)delta == INT32_MIN) {
        AXU5EV_Motor_Control_System_DW.initialized = false;
        AXU5EV_Motor_Control_System_DW.filled = 0U;

        /* Outport: '<Root>/history_count' */
        AXU5EV_Motor_Control_System_Y.history_count = 0U;
        rtb_restart_history = true;
        AXU5EV_Motor_Control_System_Y.feedback_status = 48U;
      } else {
        if ((AXU5EV_Motor_Control_System_DW.total < INT64_C(0)) && (delta <
             INT64_MIN - AXU5EV_Motor_Control_System_DW.total)) {
          AXU5EV_Motor_Control_System_DW.total = INT64_MIN;
        } else if ((AXU5EV_Motor_Control_System_DW.total > INT64_C(0)) && (delta
                    > INT64_MAX - AXU5EV_Motor_Control_System_DW.total)) {
          AXU5EV_Motor_Control_System_DW.total = INT64_MAX;
        } else {
          AXU5EV_Motor_Control_System_DW.total += delta;
        }

        guard3 = true;
      }
    }

    if (guard3) {
      clear_allowed_tmp = (!AXU5EV_Motor_Control_System_DW.initialized ||
                           (AXU5EV_Motor_Control_System_DW.old_zero != 0U));
      if (clear_allowed_tmp || AXU5EV_Motor_Control_System_DW.old_reverse ||
          (AXU5EV_Motor_Control_System_DW.old_version != 1U) ||
          (AXU5EV_Motor_Control_System_DW.old_scale != 1000U)) {
        if (clear_allowed_tmp) {
          delta = AXU5EV_Motor_Control_System_U.raw_count;
          if (AXU5EV_Motor_Control_System_U.raw_count > 2147483647U) {
            delta = AXU5EV_Motor_Control_System_U.raw_count - INT64_C(4294967296);
          }

          if ((int32_t)delta == INT32_MIN) {
            AXU5EV_Motor_Control_System_DW.initialized = false;
            AXU5EV_Motor_Control_System_DW.filled = 0U;

            /* Outport: '<Root>/history_count' */
            AXU5EV_Motor_Control_System_Y.history_count = 0U;
            rtb_restart_history = true;
            AXU5EV_Motor_Control_System_Y.feedback_status = 48U;
          } else {
            if ((AXU5EV_Motor_Control_System_DW.total >= INT64_C(0)) && (delta <
                 AXU5EV_Motor_Control_System_DW.total - INT64_MAX)) {
              AXU5EV_Motor_Control_System_DW.origin = INT64_MAX;
            } else if ((AXU5EV_Motor_Control_System_DW.total < INT64_C(0)) &&
                       (delta > AXU5EV_Motor_Control_System_DW.total - INT64_MIN))
            {
              AXU5EV_Motor_Control_System_DW.origin = INT64_MIN;
            } else {
              AXU5EV_Motor_Control_System_DW.origin =
                AXU5EV_Motor_Control_System_DW.total - delta;
            }

            guard2 = true;
          }
        } else {
          guard2 = true;
        }
      } else {
        guard1 = true;
      }
    }

    if (guard2) {
      if (AXU5EV_Motor_Control_System_DW.initialized) {
        AXU5EV_Motor_Control_System_Y.feedback_status |= 8U;
      }

      AXU5EV_Motor_Control_System_DW.filled = 0U;
      rtb_restart_history = true;
      guard1 = true;
    }

    if (guard1) {
      AXU5EV_Motor_Control_System_DW.initialized = true;
      AXU5EV_Motor_Control_System_DW.last_raw =
        AXU5EV_Motor_Control_System_U.raw_count;
      AXU5EV_Motor_Control_System_DW.last_id_f =
        AXU5EV_Motor_Control_System_U.sample_id;
      AXU5EV_Motor_Control_System_DW.last_tick =
        AXU5EV_Motor_Control_System_U.sample_tick;
      AXU5EV_Motor_Control_System_DW.last_bad =
        AXU5EV_Motor_Control_System_U.illegal_count;
      AXU5EV_Motor_Control_System_DW.old_zero = 0U;
      AXU5EV_Motor_Control_System_DW.old_reverse = false;
      AXU5EV_Motor_Control_System_DW.old_version = 1U;
      AXU5EV_Motor_Control_System_DW.old_scale = 1000U;
      if (AXU5EV_Motor_Control_System_DW.filled < 51) {
        AXU5EV_Motor_Control_System_DW.filled++;
      }

      /* Outport: '<Root>/continuous_count' incorporates:
       *  Constant: '<S2>/Encoder_Config_Version'
       *  Constant: '<S2>/Encoder_Forward'
       *  Constant: '<S2>/Encoder_Nanometres_Per_Count'
       *  Constant: '<S2>/Mechanical_Zero_Count'
       *  Inport: '<Root>/illegal_count'
       *  Inport: '<Root>/raw_count'
       *  Inport: '<Root>/sample_id'
       *  Inport: '<Root>/sample_tick'
       *
       * Block description for '<Root>/sample_tick':
       *  uint64 timestamp in the existing 50MHz feedback clock domain, tick
       *  unit 20ns. Belongs to the same frozen frame as sample_id/raw_count.
       */
      AXU5EV_Motor_Control_System_Y.continuous_count =
        AXU5EV_Motor_Control_System_DW.total;
      advance = true;

      /* Outport: '<Root>/position_valid' */
      AXU5EV_Motor_Control_System_Y.position_valid = true;

      /* Outport: '<Root>/speed_valid' */
      AXU5EV_Motor_Control_System_Y.speed_valid =
        (AXU5EV_Motor_Control_System_DW.filled == 51);

      /* Outport: '<Root>/history_count' */
      AXU5EV_Motor_Control_System_Y.history_count =
        AXU5EV_Motor_Control_System_DW.filled;
    }
  }

  /* Sum: '<S8>/Continuous_Position_Count' incorporates:
   *  Outport: '<Root>/continuous_count'
   */
  delta = AXU5EV_Motor_Control_System_Y.continuous_count -
    AXU5EV_Motor_Control_System_DW.origin;

  /* Switch: '<S8>/New_Frame_Position' */
  if (advance) {
    /* Outport: '<Root>/position_mm' incorporates:
     *  DataTypeConversion: '<S8>/Position_Count_To_Double'
     *  Product: '<S8>/Position_Millimetres'
     *  Sum: '<S8>/Continuous_Position_Count'
     */
    AXU5EV_Motor_Control_System_Y.position_mm = (double)delta *
      AXU5EV_Motor_Control_Sys_ConstB.Nanometres_To_Millimetres *
      AXU5EV_Motor_Control_Sys_ConstB.Mechanical_Direction;
  } else {
    /* Outport: '<Root>/position_mm' incorporates:
     *  UnitDelay: '<S8>/Position_Hold'
     */
    AXU5EV_Motor_Control_System_Y.position_mm =
      AXU5EV_Motor_Control_System_DW.Position_Hold_DSTATE;
  }

  /* End of Switch: '<S8>/New_Frame_Position' */

  /* MATLAB Function: '<S2>/Frame_And_Fault_Qualification' incorporates:
   *  Constant: '<S2>/Hard_Travel_Max_mm'
   *  Constant: '<S2>/Hard_Travel_Min_mm'
   *  DataStoreRead: '<S2>/Controller_Initialized'
   *  Inport: '<Root>/CommandFrame'
   *  Inport: '<Root>/ERRI_n'
   *  Inport: '<Root>/ERRU_n'
   *  Inport: '<Root>/clear_fault'
   *  Inport: '<Root>/current_valid'
   *  Logic: '<S13>/Clear_Only_When_Raw_Healthy'
   *  MATLAB Function: '<S18>/Travel_Safety_Manager'
   *  MATLAB Function: '<S2>/Alignment_Permit'
   *  Outport: '<Root>/feedback_status'
   *  Outport: '<Root>/position_mm'
   *  Outport: '<Root>/position_valid'
   *
   * Block description for '<S2>/Controller_Initialized':
   *  Initialized records software initialization only. Physical feedback,
   *  current establishment and hardware binding are separate.
   *
   * Block description for '<Root>/CommandFrame':
   *  Interface version 1, 20 double internal fields. Binder overrides
   *  measured speed/position/fault and disables replay. See AX04 report for
   *  exact field groups.
   *
   * Block description for '<S18>/Travel_Safety_Manager':
   *  Soft +/-110 mm acts on the final speed reference before Speed_Loop and
   *  permits inward motion. Direct Iq test does not share this soft-speed
   *  limiting path. Hard +/-120 mm inclusive latches until qualified
   *  explicit clear. Mechanical encoder origin is independent of the
   *  electrical alignment offset.
   *
   * Block description for '<Root>/feedback_status':
   *  PS feedback diagnostics. uint32 bits 0 startup, 1 duplicate, 2 missing
   *  frame, 3 configuration/history reset, 4 invalid encoder, 5 ambiguous
   *  half-wrap, 6 resynchronize.
   */
  duplicate_tmp = AXU5EV_Motor_Control_System_Y.feedback_status & 2U;
  rtb_Control_Fault = (!AXU5EV_Motor_Control_System_Y.position_valid ||
                       !AXU5EV_Motor_Control_System_U.current_valid ||
                       ((AXU5EV_Motor_Control_System_Y.feedback_status & 116U)
                        != 0U));
  rtb_System_Fault_Not = !AXU5EV_Motor_Control_System_U.ERRI_n;
  LogicalOperator = !AXU5EV_Motor_Control_System_U.ERRU_n;
  raw_fault = (rtb_System_Fault_Not || LogicalOperator);

  /* Outputs for Enabled SubSystem: '<S2>/Qualified_Runtime' incorporates:
   *  EnablePort: '<S10>/Qualified_Frame_Enable'
   */
  /* Outputs for Enabled SubSystem: '<S10>/Motion_Control' incorporates:
   *  EnablePort: '<S18>/New_Frame_Only'
   */
  rtb_LogicalOperator3 = ((AXU5EV_Motor_Control_System_Y.position_mm >= 120.0) ||
    (AXU5EV_Motor_Control_System_Y.position_mm <= -120.0));

  /* End of Outputs for SubSystem: '<S10>/Motion_Control' */
  /* End of Outputs for SubSystem: '<S2>/Qualified_Runtime' */
  hard_fault = (AXU5EV_Motor_Control_System_Y.position_valid &&
                rtb_LogicalOperator3);
  command_valid = true;
  i = 0;
  while (i < 20) {
    if (!b[i] || !c[i]) {
      command_valid = false;
      break;
    } else {
      i++;
    }
  }

  clear_allowed_tmp = (AXU5EV_Motor_Control_System_DW.Initialized &&
                       AXU5EV_Motor_Control_System_Y.position_valid &&
                       (duplicate_tmp == 0U));
  clear_allowed_tmp_0 = !raw_fault;
  clear_allowed_tmp_1 = !hard_fault;
  clear_allowed = (clear_allowed_tmp &&
                   AXU5EV_Motor_Control_System_U.clear_fault &&
                   clear_allowed_tmp_0 && clear_allowed_tmp_1 &&
                   !rtb_Control_Fault && command_valid &&
                   (AXU5EV_Motor_Control_System_U.CommandFrame[7] == 0.0));
  fault_tmp = !clear_allowed;
  AXU5EV_Motor_Control_System_DW.fault = (fault_tmp && (raw_fault || hard_fault ||
    rtb_Control_Fault || !command_valid || AXU5EV_Motor_Control_System_DW.fault));

  /* Logic: '<S13>/External_Fault_Latch_OR' incorporates:
   *  Logic: '<S13>/Clear_Only_When_Raw_Healthy'
   *  Logic: '<S13>/External_Fault_OR'
   *  Logic: '<S13>/Retain_Unless_Safe_Clear'
   *  Logic: '<S13>/Retained_External_Fault'
   *  UnitDelay: '<S13>/External_Fault_Latch_Z'
   */
  AXU5EV_Motor_Control_System_DW.External_Fault_Latch_Z_DSTATE = (raw_fault ||
    (AXU5EV_Motor_Control_System_DW.External_Fault_Latch_Z_DSTATE && (fault_tmp ||
    rtb_System_Fault_Not || LogicalOperator)));

  /* Logic: '<S2>/Control_Fault' incorporates:
   *  MATLAB Function: '<S2>/Frame_And_Fault_Qualification'
   */
  rtb_Control_Fault = (AXU5EV_Motor_Control_System_DW.fault ||
                       AXU5EV_Motor_Control_System_DW.External_Fault_Latch_Z_DSTATE);

  /* Delay: '<S8>/Speed_Window_Delay' incorporates:
   *  Sum: '<S8>/Continuous_Position_Count'
   */
  if (advance) {
    AXU5EV_Motor_Control_System_DW.icLoad = (rtb_restart_history ||
      AXU5EV_Motor_Control_System_DW.icLoad);
    if (AXU5EV_Motor_Control_System_DW.icLoad) {
      for (i = 0; i < 50; i++) {
        AXU5EV_Motor_Control_System_DW.Speed_Window_Delay_DSTATE[i] = delta;
      }
    }

    /* Delay: '<S8>/Speed_Window_Delay' incorporates:
     *  Sum: '<S8>/Continuous_Position_Count'
     */
    AXU5EV_Motor_Control_System_DW.Speed_Window_Delay =
      AXU5EV_Motor_Control_System_DW.Speed_Window_Delay_DSTATE[0];
  }

  /* End of Delay: '<S8>/Speed_Window_Delay' */

  /* Switch: '<S8>/Qualified_Speed' incorporates:
   *  Outport: '<Root>/speed_valid'
   */
  if (AXU5EV_Motor_Control_System_Y.speed_valid) {
    /* Outport: '<Root>/speed_mm_s' incorporates:
     *  DataTypeConversion: '<S8>/Difference_To_Double'
     *  Delay: '<S8>/Speed_Window_Delay'
     *  Gain: '<S8>/Speed_From_Feedback_Window'
     *  Product: '<S8>/Displacement_Millimetres'
     *  Sum: '<S8>/Continuous_Position_Count'
     *  Sum: '<S8>/Count_Difference_Over_Speed_Window'
     */
    AXU5EV_Motor_Control_System_Y.speed_mm_s = (double)(delta -
      AXU5EV_Motor_Control_System_DW.Speed_Window_Delay) *
      AXU5EV_Motor_Control_Sys_ConstB.Nanometres_To_Millimetres *
      AXU5EV_Motor_Control_Sys_ConstB.Mechanical_Direction * 200.0;
  } else {
    /* Outport: '<Root>/speed_mm_s' incorporates:
     *  Constant: '<S8>/Unqualified_Speed_Zero'
     */
    AXU5EV_Motor_Control_System_Y.speed_mm_s = 0.0;
  }

  /* End of Switch: '<S8>/Qualified_Speed' */

  /* SignalConversion generated from: '<S2>/request_freset' incorporates:
   *  Inport: '<Root>/request_freset'
   *  Logic: '<S7>/Outside_Driver_Reset'
   *  MATLAB Function: '<S2>/Alignment_Permit'
   *  MATLAB Function: '<S2>/Frame_And_Fault_Qualification'
   */
  raw_fault = !AXU5EV_Motor_Control_System_U.request_freset;

  /* Logic: '<S7>/Reset_Or_System_Inhibit' incorporates:
   *  MATLAB Function: '<S2>/Frame_And_Fault_Qualification'
   */
  hard_fault = !AXU5EV_Motor_Control_System_DW.fault;

  /* Logic: '<S7>/System_Fault_Not' incorporates:
   *  Logic: '<S7>/Reset_Or_System_Inhibit'
   *  SignalConversion generated from: '<S2>/request_freset'
   */
  rtb_System_Fault_Not = (hard_fault && raw_fault);

  /* Logic: '<S7>/RELCON_Safe_Enable' incorporates:
   *  Inport: '<Root>/request_relcon'
   */
  rtb_restart_history = (AXU5EV_Motor_Control_System_U.request_relcon &&
    rtb_System_Fault_Not);

  /* Logic: '<S7>/ENCON_Safe_Enable' incorporates:
   *  Inport: '<Root>/request_encon'
   */
  rtb_System_Fault_Not = (AXU5EV_Motor_Control_System_U.request_encon &&
    rtb_System_Fault_Not);

  /* Logic: '<S7>/Logical Operator' incorporates:
   *  Inport: '<Root>/request_oe_disable'
   *  Logic: '<S7>/Fault_OE_Inhibit_Outside_Reset'
   *  MATLAB Function: '<S2>/Frame_And_Fault_Qualification'
   */
  LogicalOperator = (AXU5EV_Motor_Control_System_U.request_oe_disable ||
                     (AXU5EV_Motor_Control_System_DW.fault && raw_fault));

  /* MATLAB Function: '<S2>/Alignment_Permit' incorporates:
   *  DataStoreRead: '<S2>/Controller_Initialized'
   *  Inport: '<Root>/CommandFrame'
   *  Inport: '<Root>/current_valid'
   *  MATLAB Function: '<S2>/Reference_Commit'
   *  Outport: '<Root>/history_count'
   *  Outport: '<Root>/position_valid'
   *  Outport: '<Root>/speed_valid'
   *
   * Block description for '<S2>/Controller_Initialized':
   *  Initialized records software initialization only. Physical feedback,
   *  current establishment and hardware binding are separate.
   *
   * Block description for '<Root>/CommandFrame':
   *  Interface version 1, 20 double internal fields. Binder overrides
   *  measured speed/position/fault and disables replay. See AX04 report for
   *  exact field groups.
   *
   * Block description for '<S2>/Reference_Commit':
   *  Packages Id[A], Iq[A], omega[rad/s], offset[rad], alignment angle
   *  selection, PWM permit, PI reset and reference valid plus
   *  frame/version. HW_BINDING_PENDING for atomic AXI submission.
   */
  fault_tmp = (rtb_restart_history && rtb_System_Fault_Not && !LogicalOperator);
  permit_tmp = !(AXU5EV_Motor_Control_System_U.CommandFrame[17] > 0.5);
  rtb_Software_Alignment_Permit = (AXU5EV_Motor_Control_System_DW.Initialized &&
    (AXU5EV_Motor_Control_System_Y.position_valid &&
     AXU5EV_Motor_Control_System_U.current_valid &&
     (AXU5EV_Motor_Control_System_Y.speed_valid || ((duplicate_tmp != 0U) &&
    (AXU5EV_Motor_Control_System_Y.history_count >= 51)))) && !rtb_Control_Fault
    && ((AXU5EV_Motor_Control_System_U.CommandFrame[7] > 0.5) &&
        ((AXU5EV_Motor_Control_System_U.CommandFrame[15] > 0.5) && (fault_tmp &&
    raw_fault && permit_tmp && !(AXU5EV_Motor_Control_System_U.CommandFrame[8]
    != 0.0)))));

  /* Outputs for Enabled SubSystem: '<S2>/Qualified_Runtime' incorporates:
   *  EnablePort: '<S10>/Qualified_Frame_Enable'
   */
  /* Logic: '<S2>/Runtime_Advance_Or_Safety' incorporates:
   *  DataStoreRead: '<S2>/Controller_Initialized'
   *  MATLAB Function: '<S2>/Alignment_Permit'
   *
   * Block description for '<S2>/Controller_Initialized':
   *  Initialized records software initialization only. Physical feedback,
   *  current establishment and hardware binding are separate.
   */
  if (clear_allowed_tmp || (AXU5EV_Motor_Control_System_DW.Initialized &&
       !rtb_Software_Alignment_Permit)) {
    /* Logic: '<S10>/Alignment_Fault_Active' incorporates:
     *  DataTypeConversion: '<S5>/Fault_Double'
     */
    rtb_Alignment_Fault_Active_g = ((rtb_clean[15] != 0.0) && rtb_Control_Fault);

    /* Logic: '<S16>/Software_Alignment_Permit' */
    rtb_Software_Alignment_Permit = ((rtb_clean[15] != 0.0) &&
      rtb_Software_Alignment_Permit);

    /* Chart: '<S19>/Angle_Init' incorporates:
     *  DataTypeConversion: '<S5>/Fault_Double'
     *  Outport: '<Root>/position_mm'
     */
    if (AXU5EV_Motor_Control_System_DW.temporalCounter_i1 < UINT32_MAX) {
      AXU5EV_Motor_Control_System_DW.temporalCounter_i1++;
    }

    if (AXU5EV_Motor_Control_System_DW.is_active_c3_AXU5EV_Motor_Contr == 0) {
      AXU5EV_Motor_Control_System_DW.is_active_c3_AXU5EV_Motor_Contr = 1U;
      AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
        AXU5EV_Motor_Control_Sy_IN_IDLE;
      AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 0.0;
      AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
      AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
      AXU5EV_Motor_Control_System_DW.Init_State_Num = 0.0;
      AXU5EV_Motor_Control_System_DW.Start_Armed = (rtb_clean[16] < 0.5);
    } else {
      switch (AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst) {
       case AXU5EV_Motor_Control_Sy_IN_DONE:
        if ((rtb_clean[17] > 0.5) || ((double)rtb_Control_Fault > 0.5)) {
          AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
            AXU5EV_Motor_Control_Sy_IN_IDLE;
          AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 0.0;
          AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
          AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
          AXU5EV_Motor_Control_System_DW.Init_State_Num = 0.0;
          AXU5EV_Motor_Control_System_DW.Start_Armed = (rtb_clean[16] < 0.5);
        } else {
          AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 0.0;
          AXU5EV_Motor_Control_System_DW.Init_Done = 1.0;
          AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
          AXU5EV_Motor_Control_System_DW.Init_State_Num = 4.0;
          AXU5EV_Motor_Control_System_DW.Theta_Offset_auto =
            AXU5EV_Motor_Control_System_DW.theta_offset_mem;
        }
        break;

       case AXU5EV_Motor_Cont_IN_HOLD_ALIGN:
        if ((rtb_clean[17] > 0.5) || ((double)rtb_Control_Fault > 0.5) ||
            !rtb_Software_Alignment_Permit) {
          AXU5EV_Motor_Control_System_DW.theta_offset_mem = 0.0;
          AXU5EV_Motor_Control_System_DW.Theta_Offset_auto = 0.0;
          AXU5EV_Motor_Control_System_DW.x_align_mm_latch = 0.0;
          AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
            AXU5EV_Motor_Control_Sy_IN_IDLE;
          AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 0.0;
          AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
          AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
          AXU5EV_Motor_Control_System_DW.Init_State_Num = 0.0;
          AXU5EV_Motor_Control_System_DW.Start_Armed = (rtb_clean[16] < 0.5);
        } else if (AXU5EV_Motor_Control_System_DW.temporalCounter_i1 >= 30000U)
        {
          AXU5EV_Motor_Control_System_DW.x_align_mm_latch =
            AXU5EV_Motor_Control_System_Y.position_mm;
          rtb_Sum1 = 0.0 - 6.283185307179586 *
            AXU5EV_Motor_Control_System_DW.x_align_mm_latch / 30.0;
          if (rtIsNaN(rtb_Sum1)) {
            AXU5EV_Motor_Control_System_DW.theta_offset_mem = (rtNaN);
          } else if (rtIsInf(rtb_Sum1)) {
            AXU5EV_Motor_Control_System_DW.theta_offset_mem = (rtNaN);
          } else {
            q = fabs(rtb_Sum1 / 6.283185307179586);
            if (fabs(q - floor(q + 0.5)) > 2.220446049250313E-16 * q) {
              AXU5EV_Motor_Control_System_DW.theta_offset_mem = fmod(rtb_Sum1,
                6.283185307179586);
            } else {
              AXU5EV_Motor_Control_System_DW.theta_offset_mem = 0.0;
            }

            if (AXU5EV_Motor_Control_System_DW.theta_offset_mem == 0.0) {
              AXU5EV_Motor_Control_System_DW.theta_offset_mem = 0.0;
            } else if (AXU5EV_Motor_Control_System_DW.theta_offset_mem < 0.0) {
              AXU5EV_Motor_Control_System_DW.theta_offset_mem +=
                6.283185307179586;
            }
          }

          AXU5EV_Motor_Control_System_DW.Theta_Offset_auto =
            AXU5EV_Motor_Control_System_DW.theta_offset_mem;
          AXU5EV_Motor_Control_System_DW.temporalCounter_i1 = 0U;
          AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
            AXU5EV_Motor_Co_IN_RAMP_DOWN_ID;
          AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 1.0;
          AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
          AXU5EV_Motor_Control_System_DW.id_init_ref = 0.5;
          AXU5EV_Motor_Control_System_DW.Init_State_Num = 3.0;
        } else {
          AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 1.0;
          AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
          AXU5EV_Motor_Control_System_DW.id_init_ref = 0.5;
        }
        break;

       case AXU5EV_Motor_Control_Sy_IN_IDLE:
        if (AXU5EV_Motor_Control_System_DW.Start_Armed && (rtb_clean[16] > 0.5) &&
            rtb_Software_Alignment_Permit && (rtb_clean[17] < 0.5) && ((double)
             rtb_Control_Fault < 0.5)) {
          AXU5EV_Motor_Control_System_DW.Start_Armed = false;
          AXU5EV_Motor_Control_System_DW.temporalCounter_i1 = 0U;
          AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
            AXU5EV_Motor_Control_IN_RAMP_ID;
          AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 1.0;
          AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
          AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
          AXU5EV_Motor_Control_System_DW.Init_State_Num = 1.0;
        } else {
          AXU5EV_Motor_Control_System_DW.Start_Armed = (rtb_clean[16] < 0.5);
        }
        break;

       case AXU5EV_Motor_Co_IN_RAMP_DOWN_ID:
        if ((rtb_clean[17] > 0.5) || ((double)rtb_Control_Fault > 0.5) ||
            !rtb_Software_Alignment_Permit) {
          AXU5EV_Motor_Control_System_DW.theta_offset_mem = 0.0;
          AXU5EV_Motor_Control_System_DW.Theta_Offset_auto = 0.0;
          AXU5EV_Motor_Control_System_DW.x_align_mm_latch = 0.0;
          AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
            AXU5EV_Motor_Control_Sy_IN_IDLE;
          AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 0.0;
          AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
          AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
          AXU5EV_Motor_Control_System_DW.Init_State_Num = 0.0;
          AXU5EV_Motor_Control_System_DW.Start_Armed = (rtb_clean[16] < 0.5);
        } else if (AXU5EV_Motor_Control_System_DW.temporalCounter_i1 >= 2000U) {
          AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
            AXU5EV_Motor_Control_Sy_IN_DONE;
          AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 0.0;
          AXU5EV_Motor_Control_System_DW.Init_Done = 1.0;
          AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
          AXU5EV_Motor_Control_System_DW.Init_State_Num = 4.0;
        } else {
          AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 1.0;
          AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
          AXU5EV_Motor_Control_System_DW.id_init_ref -= 0.00025;
          if (AXU5EV_Motor_Control_System_DW.id_init_ref < 0.0) {
            AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
          }

          AXU5EV_Motor_Control_System_DW.Theta_Offset_auto =
            AXU5EV_Motor_Control_System_DW.theta_offset_mem;
        }
        break;

       default:
        /* case IN_RAMP_ID: */
        if ((rtb_clean[17] > 0.5) || ((double)rtb_Control_Fault > 0.5) ||
            !rtb_Software_Alignment_Permit) {
          AXU5EV_Motor_Control_System_DW.theta_offset_mem = 0.0;
          AXU5EV_Motor_Control_System_DW.Theta_Offset_auto = 0.0;
          AXU5EV_Motor_Control_System_DW.x_align_mm_latch = 0.0;
          AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
            AXU5EV_Motor_Control_Sy_IN_IDLE;
          AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 0.0;
          AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
          AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
          AXU5EV_Motor_Control_System_DW.Init_State_Num = 0.0;
          AXU5EV_Motor_Control_System_DW.Start_Armed = (rtb_clean[16] < 0.5);
        } else if (AXU5EV_Motor_Control_System_DW.temporalCounter_i1 >= 10000U)
        {
          AXU5EV_Motor_Control_System_DW.temporalCounter_i1 = 0U;
          AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
            AXU5EV_Motor_Cont_IN_HOLD_ALIGN;
          AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 1.0;
          AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
          AXU5EV_Motor_Control_System_DW.id_init_ref = 0.5;
          AXU5EV_Motor_Control_System_DW.Init_State_Num = 2.0;
        } else {
          AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 1.0;
          AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
          AXU5EV_Motor_Control_System_DW.id_init_ref += 5.0E-5;
          if (AXU5EV_Motor_Control_System_DW.id_init_ref > 0.5) {
            AXU5EV_Motor_Control_System_DW.id_init_ref = 0.5;
          }
        }
        break;
      }
    }

    /* End of Chart: '<S19>/Angle_Init' */

    /* Logic: '<S10>/Not_Alignment_Enable' incorporates:
     *  Logic: '<S10>/Alignment_Reset_Active'
     */
    rtb_Alignment_Ready_p = !(rtb_clean[15] != 0.0);

    /* Logic: '<S10>/Init_Done_Or_Bypass' incorporates:
     *  Logic: '<S10>/Not_Alignment_Enable'
     */
    rtb_Software_Alignment_Permit = (rtb_Alignment_Ready_p ||
      (AXU5EV_Motor_Control_System_DW.Init_Done != 0.0));

    /* Logic: '<S10>/Alignment_Ready' incorporates:
     *  Logic: '<S10>/Alignment_Reset_Active'
     *  Logic: '<S10>/Not_Alignment_Fault'
     *  Logic: '<S10>/Not_Alignment_Reset'
     */
    rtb_Alignment_Ready_p = (!rtb_Alignment_Fault_Active_g &&
      rtb_Software_Alignment_Permit && (rtb_Alignment_Ready_p || !(rtb_clean[17]
      != 0.0)));

    /* Outputs for Enabled SubSystem: '<S10>/Motion_Control' incorporates:
     *  EnablePort: '<S18>/New_Frame_Only'
     */
    /* Outputs for Enabled SubSystem: '<S10>/Host_New_Frame' incorporates:
     *  EnablePort: '<S17>/New_Frame_Only'
     */
    if (clear_allowed_tmp) {
      /* Gain: '<S17>/Software_Time_s' incorporates:
       *  UnitDelay: '<S17>/Software_Tick'
       */
      q = 0.0001 * AXU5EV_Motor_Control_System_DW.Software_Tick_DSTATE;
      for (i = 0; i < 7; i++) {
        /* SignalConversion generated from: '<S21>/ SFunction ' incorporates:
         *  MATLAB Function: '<S17>/Host_Core'
         */
        rtb_TmpSignalConversionAtSFunct[i] = rtb_clean[i];
      }

      /* MATLAB Function: '<S17>/Host_Core' */
      AXU5EV_Motor_Control_System_DW.vdc = 48.0;
      AXU5EV_Motor_Control_System_DW.load_N = 0.0;
      AXU5EV_Motor_Control_System_DW.v_ref_cmd =
        rtb_TmpSignalConversionAtSFunct[1];
      AXU5EV_Motor_Control_System_DW.id_ref_cmd =
        rtb_TmpSignalConversionAtSFunct[2];
      AXU5EV_Motor_Control_System_DW.iq_test_mode =
        rtb_TmpSignalConversionAtSFunct[3];
      AXU5EV_Motor_Control_System_DW.iq_test_ref =
        rtb_TmpSignalConversionAtSFunct[4];
      AXU5EV_Motor_Control_System_DW.Position_Loop_EN =
        rtb_TmpSignalConversionAtSFunct[5];
      AXU5EV_Motor_Control_System_DW.Close_Loop_EN =
        rtb_TmpSignalConversionAtSFunct[6];

      /* Switch: '<S5>/Fault_Disables_PWM_Request' */
      if (rtb_Control_Fault) {
        /* MATLAB Function: '<S17>/Host_Core' incorporates:
         *  Constant: '<S5>/Fault_PWM_Off'
         */
        AXU5EV_Motor_Control_System_DW.PWM_EN = 0.0;
      } else {
        /* MATLAB Function: '<S17>/Host_Core' */
        AXU5EV_Motor_Control_System_DW.PWM_EN = rtb_clean[7];
      }

      /* End of Switch: '<S5>/Fault_Disables_PWM_Request' */

      /* MATLAB Function: '<S17>/Host_Core' incorporates:
       *  Inport: '<Root>/CommandFrame'
       *  Logic: '<S5>/Effective_PI_Reset'
       *  Logic: '<S5>/Speed_Not_Qualified'
       *  MATLAB Function: '<S5>/Finite_Command'
       *  Outport: '<Root>/position_mm'
       *  Outport: '<Root>/speed_valid'
       *  SignalConversion generated from: '<S21>/ SFunction '
       *
       * Block description for '<Root>/CommandFrame':
       *  Interface version 1, 20 double internal fields. Binder overrides
       *  measured speed/position/fault and disables replay. See AX04 report for
       *  exact field groups.
       */
      i = ((AXU5EV_Motor_Control_System_U.CommandFrame[8] != 0.0) ||
           rtb_Control_Fault || !AXU5EV_Motor_Control_System_Y.speed_valid);
      if (AXU5EV_Motor_Control_System_DW.move_state[0] == 0.0) {
        AXU5EV_Motor_Control_System_DW.move_state[0] = 1.0;
        AXU5EV_Motor_Control_System_DW.move_state[1] = rtb_clean[10];
        AXU5EV_Motor_Control_System_DW.move_state[2] =
          AXU5EV_Motor_Control_System_Y.position_mm;
        AXU5EV_Motor_Control_System_DW.move_state[3] =
          AXU5EV_Motor_Control_System_Y.position_mm;
        AXU5EV_Motor_Control_System_DW.move_state[4] = q;
        AXU5EV_Motor_Control_System_DW.move_state[6] = 1.0;
        AXU5EV_Motor_Control_System_DW.move_state[13] = -1.0;
        AXU5EV_Motor_Control_System_DW.move_state[14] =
          AXU5EV_Motor_Control_System_Y.position_mm;
        AXU5EV_Motor_Control_System_DW.move_state[15] = rtb_Alignment_Ready_p;
      }

      rtb_Compare = ((rtb_TmpSignalConversionAtSFunct[5] != 0.0) &&
                     ((rtb_TmpSignalConversionAtSFunct[6] != 0.0) &&
                      (rtb_TmpSignalConversionAtSFunct[3] == 0.0)) &&
                     (AXU5EV_Motor_Control_System_DW.PWM_EN != 0.0) && (i == 0) &&
                     rtb_Alignment_Ready_p);
      tick = floor(q / 0.0001 + 1.0E-7);
      new_tick = (tick != AXU5EV_Motor_Control_System_DW.move_state[13]);
      if (new_tick) {
        AXU5EV_Motor_Control_System_DW.move_state[13] = tick;
        if ((rtb_clean[15] != 0.0) && rtb_Alignment_Ready_p &&
            (AXU5EV_Motor_Control_System_DW.move_state[15] == 0.0)) {
          AXU5EV_Motor_Control_System_DW.move_state[2] =
            AXU5EV_Motor_Control_System_Y.position_mm;
          AXU5EV_Motor_Control_System_DW.move_state[3] =
            AXU5EV_Motor_Control_System_Y.position_mm;
          AXU5EV_Motor_Control_System_DW.move_state[4] = q;
          AXU5EV_Motor_Control_System_DW.move_state[5] = 0.0;
          AXU5EV_Motor_Control_System_DW.move_state[6] = 1.0;
          AXU5EV_Motor_Control_System_DW.move_state[7] = 0.0;
          AXU5EV_Motor_Control_System_DW.move_state[8] = 0.0;
          AXU5EV_Motor_Control_System_DW.move_state[12] = 0.0;
          AXU5EV_Motor_Control_System_DW.move_state[14] =
            AXU5EV_Motor_Control_System_Y.position_mm;
        }

        AXU5EV_Motor_Control_System_DW.move_state[15] = rtb_Alignment_Ready_p;
        if ((AXU5EV_Motor_Control_System_DW.move_state[5] != 0.0) &&
            ((AXU5EV_Motor_Control_System_DW.PWM_EN == 0.0) || (i != 0))) {
          AXU5EV_Motor_Control_System_DW.move_state[5] = 0.0;
          AXU5EV_Motor_Control_System_DW.move_state[6] = 0.0;
          AXU5EV_Motor_Control_System_DW.move_state[7] = 0.0;
          AXU5EV_Motor_Control_System_DW.move_state[8] = 0.0;
          AXU5EV_Motor_Control_System_DW.move_state[12] = 1.0;
          AXU5EV_Motor_Control_System_DW.move_state[9] = 7.0;
        }
      }

      if (AXU5EV_Motor_Control_System_DW.move_state[12] != 0.0) {
        AXU5EV_Motor_Control_System_DW.x_ref_mm =
          AXU5EV_Motor_Control_System_DW.move_state[14];
      } else {
        t = q - AXU5EV_Motor_Control_System_DW.move_state[4];
        rtb_Sum1 = AXU5EV_Motor_Control_System_DW.move_state[3] -
          AXU5EV_Motor_Control_System_DW.move_state[2];
        D = fabs(rtb_Sum1);
        s = 0.0;
        rtb_iq_lim_ASR = 0.0;
        if (!(D == 0.0)) {
          cfg[0] = 20.0;
          cfg[1] = D / 0.2;
          cfg[2] = sqrt(D * 200.0 / 1.875);
          cfg[3] = rt_powd_snf(D * D * 1000.0 / 5.773502691896258,
                               0.3333333333333333);
          V = AXU5EV_Motor_Control_Sy_minimum(cfg);
          cfg_0[0] = 0.2;
          cfg_0[1] = 1.875 * V / 200.0;
          cfg_0[2] = sqrt(5.773502691896258 * V / 1000.0);
          Ta = AXU5EV_Motor_Control_Sy_maximum(cfg_0);
          Tc = fmax(0.0, D / V - Ta);
          rtb_iq_lim_ASR = 2.0 * Ta + Tc;
          if (!(t <= 0.0)) {
            if (t < Ta) {
              s = t / Ta;
              s = ((2.5 * rt_powd_snf(s, 4.0) - 3.0 * rt_powd_snf(s, 5.0)) +
                   rt_powd_snf(s, 6.0)) * (V * Ta);
            } else if (t < Ta + Tc) {
              s = V * Ta / 2.0 + (t - Ta) * V;
            } else if (t < rtb_iq_lim_ASR) {
              s = ((t - Ta) - Tc) / Ta;
              Ta *= V;
              s = (((s - 2.5 * rt_powd_snf(s, 4.0)) + 3.0 * rt_powd_snf(s, 5.0))
                   - rt_powd_snf(s, 6.0)) * Ta + (Ta / 2.0 + V * Tc);
            } else {
              s = D;
            }

            if (rtIsNaN(rtb_Sum1)) {
              rtb_Sum1 = (rtNaN);
            } else if (rtb_Sum1 < 0.0) {
              rtb_Sum1 = -1.0;
            } else {
              rtb_Sum1 = (rtb_Sum1 > 0.0);
            }

            s *= rtb_Sum1;
          }
        }

        AXU5EV_Motor_Control_System_DW.x_ref_mm =
          AXU5EV_Motor_Control_System_DW.move_state[2] + s;
        AXU5EV_Motor_Control_System_DW.move_state[17] = rtb_iq_lim_ASR;
        AXU5EV_Motor_Control_System_DW.move_state[6] = (q -
          AXU5EV_Motor_Control_System_DW.move_state[4] >= rtb_iq_lim_ASR);
      }

      if ((AXU5EV_Motor_Control_System_mod(tick, 100.0) == 99.0) && (tick + 1.0
           != AXU5EV_Motor_Control_System_DW.move_state[21])) {
        AXU5EV_Motor_Control_System_DW.move_state[21] = tick + 1.0;
        if (rtb_Compare) {
          if (AXU5EV_Motor_Control_System_DW.move_state[6] != 0.0) {
            if (AXU5EV_Motor_Control_System_DW.move_state[12] == 0.0) {
              if (fabs(AXU5EV_Motor_Control_System_Y.position_mm -
                       AXU5EV_Motor_Control_System_DW.move_state[3]) <=
                  0.020000001) {
                AXU5EV_Motor_Control_System_DW.move_state[8] = fmin
                  (AXU5EV_Motor_Control_System_DW.move_state[8] + 1.0, 5.0);
              } else {
                AXU5EV_Motor_Control_System_DW.move_state[8] = 0.0;
              }
            } else {
              AXU5EV_Motor_Control_System_DW.move_state[8] = 0.0;
            }
          } else {
            AXU5EV_Motor_Control_System_DW.move_state[8] = 0.0;
          }
        } else {
          AXU5EV_Motor_Control_System_DW.move_state[8] = 0.0;
        }

        AXU5EV_Motor_Control_System_DW.move_state[7] =
          (AXU5EV_Motor_Control_System_DW.move_state[8] >= 5.0);
        if (AXU5EV_Motor_Control_System_DW.move_state[7] != 0.0) {
          AXU5EV_Motor_Control_System_DW.move_state[5] = 0.0;
        }
      }

      rtb_LogicalOperator = (rtb_Compare &&
        ((AXU5EV_Motor_Control_System_DW.move_state[7] != 0.0) &&
         ((AXU5EV_Motor_Control_System_DW.move_state[5] == 0.0) &&
          (AXU5EV_Motor_Control_System_DW.move_state[12] == 0.0))));
      AXU5EV_Motor_Control_System_DW.move_state[20] = rtb_LogicalOperator;
      if (new_tick && (!(AXU5EV_Motor_Control_System_DW.move_state[1] ==
                         rtb_clean[10]) && (!rtIsNaN(rtb_clean[10]) || !rtIsNaN
            (AXU5EV_Motor_Control_System_DW.move_state[1])))) {
        AXU5EV_Motor_Control_System_DW.move_state[1] = rtb_clean[10];
        AXU5EV_Motor_Control_System_DW.move_state[18] = q;
        if (rtIsInf(rtb_TmpSignalConversionAtSFunct[0]) || rtIsNaN
            (rtb_TmpSignalConversionAtSFunct[0]) || (rtIsInf(rtb_clean[10]) ||
             rtIsNaN(rtb_clean[10])) || ((rtb_clean[10] != 0.0) && (rtb_clean[10]
              != 1.0))) {
          AXU5EV_Motor_Control_System_DW.move_state[9] = 4.0;
          AXU5EV_Motor_Control_System_DW.move_state[11]++;
        } else if (!rtb_Compare) {
          AXU5EV_Motor_Control_System_DW.move_state[9] = 6.0;
          AXU5EV_Motor_Control_System_DW.move_state[11]++;
        } else if (!rtb_LogicalOperator) {
          AXU5EV_Motor_Control_System_DW.move_state[9] = 3.0;
          AXU5EV_Motor_Control_System_DW.move_state[11]++;
        } else if (fabs(rtb_TmpSignalConversionAtSFunct[0] -
                        AXU5EV_Motor_Control_System_DW.move_state[3]) <= 1.0E-12)
        {
          AXU5EV_Motor_Control_System_DW.move_state[9] = 5.0;
        } else {
          AXU5EV_Motor_Control_System_DW.move_state[2] =
            AXU5EV_Motor_Control_System_DW.move_state[3];
          AXU5EV_Motor_Control_System_DW.move_state[3] =
            rtb_TmpSignalConversionAtSFunct[0];
          AXU5EV_Motor_Control_System_DW.move_state[4] = q;
          AXU5EV_Motor_Control_System_DW.move_state[5] = 1.0;
          AXU5EV_Motor_Control_System_DW.move_state[6] = 0.0;
          AXU5EV_Motor_Control_System_DW.move_state[7] = 0.0;
          AXU5EV_Motor_Control_System_DW.move_state[8] = 0.0;
          AXU5EV_Motor_Control_System_DW.move_state[9] = 2.0;
          AXU5EV_Motor_Control_System_DW.move_state[10]++;
          AXU5EV_Motor_Control_System_DW.move_state[18] = q;
          AXU5EV_Motor_Control_System_DW.move_state[19]++;
          AXU5EV_Motor_Control_System_DW.move_state[20] = 0.0;
          AXU5EV_Motor_Control_System_DW.x_ref_mm =
            AXU5EV_Motor_Control_System_DW.move_state[2];
        }
      }

      AXU5EV_Motor_Control_System_DW.move_state[14] =
        AXU5EV_Motor_Control_System_DW.x_ref_mm;
      AXU5EV_Motor_Control_System_DW.target_accepted_mm =
        AXU5EV_Motor_Control_System_DW.move_state[3];
      AXU5EV_Motor_Control_System_DW.move_busy =
        AXU5EV_Motor_Control_System_DW.move_state[5];
      AXU5EV_Motor_Control_System_DW.in_position =
        AXU5EV_Motor_Control_System_DW.move_state[7];
      AXU5EV_Motor_Control_System_DW.command_status =
        AXU5EV_Motor_Control_System_DW.move_state[9];
      AXU5EV_Motor_Control_System_DW.segment_start_mm =
        AXU5EV_Motor_Control_System_DW.move_state[2];
      AXU5EV_Motor_Control_System_DW.segment_start_s =
        AXU5EV_Motor_Control_System_DW.move_state[4];
      AXU5EV_Motor_Control_System_DW.trajectory_done =
        AXU5EV_Motor_Control_System_DW.move_state[6];
      AXU5EV_Motor_Control_System_DW.move_ready =
        AXU5EV_Motor_Control_System_DW.move_state[20];
      AXU5EV_Motor_Control_System_DW.accepted_count =
        AXU5EV_Motor_Control_System_DW.move_state[10];
      AXU5EV_Motor_Control_System_DW.rejected_count =
        AXU5EV_Motor_Control_System_DW.move_state[11];
      AXU5EV_Motor_Control_System_DW.segment_id =
        AXU5EV_Motor_Control_System_DW.move_state[19];
      AXU5EV_Motor_Control_System_DW.command_received_s =
        AXU5EV_Motor_Control_System_DW.move_state[18];
      AXU5EV_Motor_Control_System_DW.move_interrupted =
        AXU5EV_Motor_Control_System_DW.move_state[12];
      if ((rtb_clean[15] != 0.0) && !rtb_Alignment_Ready_p) {
        AXU5EV_Motor_Control_System_DW.Position_Loop_EN = 0.0;
        AXU5EV_Motor_Control_System_DW.Close_Loop_EN = 0.0;
        AXU5EV_Motor_Control_System_DW.iq_test_mode = 1.0;
        AXU5EV_Motor_Control_System_DW.iq_test_ref = 0.0;
      }

      AXU5EV_Motor_Control_System_DW.trajectory_config[0] = 20.0;
      AXU5EV_Motor_Control_System_DW.trajectory_config[1] = 200.0;
      AXU5EV_Motor_Control_System_DW.trajectory_config[2] = 1000.0;
      AXU5EV_Motor_Control_System_DW.trajectory_config[3] = 0.2;
      AXU5EV_Motor_Control_System_DW.trajectory_config[4] = 0.0001;
      AXU5EV_Motor_Control_System_DW.PI_Reset_EN = i;

      /* Sum: '<S17>/Next_Tick' incorporates:
       *  Constant: '<S17>/One_Tick'
       *  UnitDelay: '<S17>/Software_Tick'
       */
      AXU5EV_Motor_Control_System_DW.Software_Tick_DSTATE++;

      /* RelationalOperator: '<S29>/Compare' incorporates:
       *  Constant: '<S24>/Constant1'
       *  Constant: '<S29>/Constant'
       *  Sum: '<S24>/Add1'
       *  UnitDelay: '<S24>/spd_cnt_z'
       */
      rtb_Compare = (AXU5EV_Motor_Control_System_DW.spd_cnt_z_DSTATE + 1.0 >=
                     10.0);

      /* RelationalOperator: '<S28>/Compare' incorporates:
       *  Constant: '<S24>/Constant3'
       *  Constant: '<S28>/Constant'
       *  Sum: '<S24>/Add2'
       *  UnitDelay: '<S24>/pos_cnt_z'
       */
      new_tick = (AXU5EV_Motor_Control_System_DW.pos_cnt_z_DSTATE + 1.0 >= 10.0);

      /* Logic: '<S24>/Logical Operator' */
      rtb_LogicalOperator = (rtb_Compare && new_tick);

      /* Outputs for Triggered SubSystem: '<S18>/Position_Loop' incorporates:
       *  TriggerPort: '<S22>/Trigger'
       */
      if (rtb_LogicalOperator &&
          (AXU5EV_Motor_Control_Sy_PrevZCX.Position_Loop_Trig_ZCE != POS_ZCSIG))
      {
        /* Sum: '<S22>/Sum' incorporates:
         *  Outport: '<Root>/position_mm'
         */
        rtb_Sum1 = AXU5EV_Motor_Control_System_DW.x_ref_mm -
          AXU5EV_Motor_Control_System_Y.position_mm;

        /* DeadZone: '<S22>/Dead Zone' */
        if (rtb_Sum1 > 0.02) {
          rtb_Sum1 -= 0.02;
        } else if (rtb_Sum1 >= -0.02) {
          rtb_Sum1 = 0.0;
        } else {
          rtb_Sum1 -= -0.02;
        }

        /* Gain: '<S22>/Gain' incorporates:
         *  DeadZone: '<S22>/Dead Zone'
         */
        AXU5EV_Motor_Control_System_DW.obs_v_ref_pos = 5.0 * rtb_Sum1;

        /* Saturate: '<S22>/Saturation' */
        if (AXU5EV_Motor_Control_System_DW.obs_v_ref_pos > 20.0) {
          /* Gain: '<S22>/Gain' incorporates:
           *  Saturate: '<S22>/Saturation'
           */
          AXU5EV_Motor_Control_System_DW.obs_v_ref_pos = 20.0;
        } else if (AXU5EV_Motor_Control_System_DW.obs_v_ref_pos < -20.0) {
          /* Gain: '<S22>/Gain' incorporates:
           *  Saturate: '<S22>/Saturation'
           */
          AXU5EV_Motor_Control_System_DW.obs_v_ref_pos = -20.0;
        }

        /* End of Saturate: '<S22>/Saturation' */
      }

      AXU5EV_Motor_Control_Sy_PrevZCX.Position_Loop_Trig_ZCE =
        rtb_LogicalOperator;

      /* End of Outputs for SubSystem: '<S18>/Position_Loop' */

      /* Switch: '<S23>/v_ref_closed_sel' */
      if (AXU5EV_Motor_Control_System_DW.Position_Loop_EN > 0.5) {
        rtb_Sum1 = AXU5EV_Motor_Control_System_DW.obs_v_ref_pos;
      } else {
        rtb_Sum1 = AXU5EV_Motor_Control_System_DW.v_ref_cmd;
      }

      /* Sum: '<S27>/Subtract' incorporates:
       *  Switch: '<S23>/v_ref_closed_sel'
       *  UnitDelay: '<S27>/v_ref_set_lim_z'
       */
      rtb_Sum1 -= AXU5EV_Motor_Control_System_DW.v_ref_set_lim_z_DSTATE;

      /* Saturate: '<S27>/Saturation' */
      if (rtb_Sum1 > 0.01) {
        rtb_Sum1 = 0.01;
      } else if (rtb_Sum1 < -0.01) {
        rtb_Sum1 = -0.01;
      }

      /* Sum: '<S27>/Add' incorporates:
       *  Saturate: '<S27>/Saturation'
       *  UnitDelay: '<S27>/v_ref_set_lim_z'
       */
      AXU5EV_Motor_Control_System_DW.v_ref_set_lim_z_DSTATE += rtb_Sum1;

      /* Switch: '<S18>/MIL_Init_Done_Vref_Gate' */
      if (rtb_Software_Alignment_Permit) {
        /* Switch: '<S23>/Switch9' */
        if (AXU5EV_Motor_Control_System_DW.Close_Loop_EN > 0.5) {
          /* Saturate: '<S23>/Saturation' incorporates:
           *  UnitDelay: '<S27>/v_ref_set_lim_z'
           */
          if (AXU5EV_Motor_Control_System_DW.v_ref_set_lim_z_DSTATE > 20.0) {
            /* Switch: '<S18>/MIL_Init_Done_Vref_Gate' */
            AXU5EV_Motor_Control_System_DW.v_ref_safe = 20.0;
          } else if (AXU5EV_Motor_Control_System_DW.v_ref_set_lim_z_DSTATE <
                     -20.0) {
            /* Switch: '<S18>/MIL_Init_Done_Vref_Gate' */
            AXU5EV_Motor_Control_System_DW.v_ref_safe = -20.0;
          } else {
            /* Switch: '<S18>/MIL_Init_Done_Vref_Gate' */
            AXU5EV_Motor_Control_System_DW.v_ref_safe =
              AXU5EV_Motor_Control_System_DW.v_ref_set_lim_z_DSTATE;
          }

          /* End of Saturate: '<S23>/Saturation' */
        } else {
          /* Switch: '<S18>/MIL_Init_Done_Vref_Gate' incorporates:
           *  Constant: '<S23>/Constant15'
           */
          AXU5EV_Motor_Control_System_DW.v_ref_safe = 0.0;
        }

        /* End of Switch: '<S23>/Switch9' */
      } else {
        /* Switch: '<S18>/MIL_Init_Done_Vref_Gate' incorporates:
         *  Constant: '<S18>/Alignment_Speed_Zero'
         */
        AXU5EV_Motor_Control_System_DW.v_ref_safe = 0.0;
      }

      /* End of Switch: '<S18>/MIL_Init_Done_Vref_Gate' */

      /* Switch: '<S18>/Explicit_Travel_Fault_Clear' incorporates:
       *  Constant: '<S18>/Cleared_Travel_Fault'
       *  MATLAB Function: '<S2>/Frame_And_Fault_Qualification'
       */
      if (clear_allowed) {
        AXU5EV_Motor_Control_System_DW.Travel_Fault_State_DSTATE = 0.0;
      }

      /* MATLAB Function: '<S18>/Travel_Safety_Manager' incorporates:
       *  Constant: '<S18>/X_max_soft'
       *  Constant: '<S18>/X_min_soft'
       *  Outport: '<Root>/position_mm'
       *  Switch: '<S18>/Explicit_Travel_Fault_Clear'
       *
       * Block description for '<S18>/Travel_Safety_Manager':
       *  Soft +/-110 mm acts on the final speed reference before Speed_Loop and
       *  permits inward motion. Direct Iq test does not share this soft-speed
       *  limiting path. Hard +/-120 mm inclusive latches until qualified
       *  explicit clear. Mechanical encoder origin is independent of the
       *  electrical alignment offset.
       */
      rtb_LogicalOperator3 =
        ((AXU5EV_Motor_Control_System_DW.Travel_Fault_State_DSTATE > 0.5) ||
         rtb_LogicalOperator3);
      if (rtb_LogicalOperator3) {
        /* Switch: '<S18>/MIL_Init_Done_Vref_Gate' */
        AXU5EV_Motor_Control_System_DW.v_ref_safe = 0.0;
      } else if (((AXU5EV_Motor_Control_System_Y.position_mm >= 110.0) &&
                  (AXU5EV_Motor_Control_System_DW.v_ref_safe > 0.0)) ||
                 ((AXU5EV_Motor_Control_System_Y.position_mm <= -110.0) &&
                  (AXU5EV_Motor_Control_System_DW.v_ref_safe < -0.0))) {
        /* Switch: '<S18>/MIL_Init_Done_Vref_Gate' */
        AXU5EV_Motor_Control_System_DW.v_ref_safe = 0.0;
      }

      /* Switch: '<S18>/Explicit_Travel_Fault_Clear' incorporates:
       *  MATLAB Function: '<S18>/Travel_Safety_Manager'
       *  UnitDelay: '<S18>/Travel_Fault_State'
       *
       * Block description for '<S18>/Travel_Safety_Manager':
       *  Soft +/-110 mm acts on the final speed reference before Speed_Loop and
       *  permits inward motion. Direct Iq test does not share this soft-speed
       *  limiting path. Hard +/-120 mm inclusive latches until qualified
       *  explicit clear. Mechanical encoder origin is independent of the
       *  electrical alignment offset.
       */
      AXU5EV_Motor_Control_System_DW.Travel_Fault_State_DSTATE =
        rtb_LogicalOperator3;

      /* Outputs for Triggered SubSystem: '<S18>/Speed_Loop' incorporates:
       *  TriggerPort: '<S25>/Trigger'
       */
      if (rtb_Compare && (AXU5EV_Motor_Control_Sy_PrevZCX.Speed_Loop_Trig_ZCE !=
                          POS_ZCSIG)) {
        /* Sum: '<S25>/Sum' incorporates:
         *  Outport: '<Root>/speed_mm_s'
         */
        q = AXU5EV_Motor_Control_System_DW.v_ref_safe -
          AXU5EV_Motor_Control_System_Y.speed_mm_s;

        /* Sum: '<S25>/Add1' incorporates:
         *  Gain: '<S25>/  '
         *  UnitDelay: '<S25>/x_s_z'
         */
        rtb_Sum1 = 0.03 * q + AXU5EV_Motor_Control_System_DW.x_s_z_DSTATE;

        /* UnitDelay: '<S25>/Unit Delay' */
        tick = AXU5EV_Motor_Control_System_DW.UnitDelay_DSTATE;

        /* Logic: '<S30>/Logical Operator3' incorporates:
         *  DataStoreWrite: '<S18>/Set_Close_Loop_EN_cmd'
         *  DataStoreWrite: '<S18>/Set_Iq_Test_Mode_cmd'
         *  Logic: '<S10>/Effective_PI_Reset'
         *  Logic: '<S10>/PWM_Not_Requested'
         *  Logic: '<S30>/Logical Operator2'
         */
        rtb_LogicalOperator3 = ((AXU5EV_Motor_Control_System_DW.Angle_Init_EN !=
          0.0) || ((AXU5EV_Motor_Control_System_DW.PI_Reset_EN != 0.0) ||
                   !(AXU5EV_Motor_Control_System_DW.PWM_EN != 0.0) ||
                   rtb_Alignment_Fault_Active_g) ||
          (AXU5EV_Motor_Control_System_DW.iq_test_mode != 0.0) ||
          !(AXU5EV_Motor_Control_System_DW.Close_Loop_EN != 0.0));

        /* Saturate: '<S25>/Saturation1' */
        if (rtb_Sum1 > 0.3) {
          rtb_iq_lim_ASR = 0.3;
        } else if (rtb_Sum1 < -0.3) {
          rtb_iq_lim_ASR = -0.3;
        } else {
          rtb_iq_lim_ASR = rtb_Sum1;
        }

        /* End of Saturate: '<S25>/Saturation1' */

        /* Switch: '<S25>/PI_Reset_Output' */
        if (rtb_LogicalOperator3) {
          /* Switch: '<S25>/PI_Reset_Output' incorporates:
           *  Constant: '<S25>/Constant4'
           */
          AXU5EV_Motor_Control_System_DW.PI_Reset_Output = 0.0;
        } else {
          /* Switch: '<S25>/PI_Reset_Output' */
          AXU5EV_Motor_Control_System_DW.PI_Reset_Output = rtb_iq_lim_ASR;
        }

        /* End of Switch: '<S25>/PI_Reset_Output' */

        /* Sum: '<S25>/Subtract' incorporates:
         *  UnitDelay: '<S25>/Unit Delay'
         */
        AXU5EV_Motor_Control_System_DW.UnitDelay_DSTATE = rtb_Sum1 -
          rtb_iq_lim_ASR;

        /* Signum: '<S30>/Sign' */
        if (rtIsNaN(AXU5EV_Motor_Control_System_DW.v_ref_safe)) {
          rtb_Sum1 = (rtNaN);
        } else if (AXU5EV_Motor_Control_System_DW.v_ref_safe < 0.0) {
          rtb_Sum1 = -1.0;
        } else {
          rtb_Sum1 = (AXU5EV_Motor_Control_System_DW.v_ref_safe > 0.0);
        }

        /* Switch: '<S25>/Switch1' incorporates:
         *  Abs: '<S25>/Abs'
         *  Constant: '<S31>/Constant'
         *  Constant: '<S33>/Constant'
         *  Logic: '<S30>/Logical Operator'
         *  Logic: '<S30>/Logical Operator1'
         *  Product: '<S30>/Product2'
         *  RelationalOperator: '<S31>/Compare'
         *  RelationalOperator: '<S33>/Compare'
         *  Signum: '<S30>/Sign'
         */
        if (rtb_LogicalOperator3 || ((fabs
              (AXU5EV_Motor_Control_System_DW.v_ref_safe) > 0.5) && (rtb_Sum1 *
              q < -3.0))) {
          /* Sum: '<S25>/Add2' incorporates:
           *  Constant: '<S25>/Constant1'
           *  UnitDelay: '<S25>/x_s_z'
           */
          AXU5EV_Motor_Control_System_DW.x_s_z_DSTATE = 0.0;
        } else {
          /* Sum: '<S25>/Add2' incorporates:
           *  Gain: '<S25>/ '
           *  Gain: '<S25>/Gain'
           *  UnitDelay: '<S25>/x_s_z'
           */
          AXU5EV_Motor_Control_System_DW.x_s_z_DSTATE = (5.0E-5 * q +
            AXU5EV_Motor_Control_System_DW.x_s_z_DSTATE) - 0.4 * tick;

          /* Saturate: '<S25>/Saturation' */
          if (AXU5EV_Motor_Control_System_DW.x_s_z_DSTATE > 0.2) {
            /* Sum: '<S25>/Add2' */
            AXU5EV_Motor_Control_System_DW.x_s_z_DSTATE = 0.2;
          } else if (AXU5EV_Motor_Control_System_DW.x_s_z_DSTATE < -0.2) {
            /* Sum: '<S25>/Add2' */
            AXU5EV_Motor_Control_System_DW.x_s_z_DSTATE = -0.2;
          }

          /* End of Saturate: '<S25>/Saturation' */
        }

        /* End of Switch: '<S25>/Switch1' */
      }

      AXU5EV_Motor_Control_Sy_PrevZCX.Speed_Loop_Trig_ZCE = rtb_Compare;

      /* End of Outputs for SubSystem: '<S18>/Speed_Loop' */

      /* Switch: '<S18>/MIL_Fault_Id_Zero' incorporates:
       *  Switch: '<S18>/MIL_Align_Id_Select'
       *  Switch: '<S18>/MIL_Align_Iq_Zero'
       *  Switch: '<S18>/MIL_Fault_Iq_Zero'
       */
      if (rtb_Alignment_Fault_Active_g) {
        /* Switch: '<S18>/MIL_Fault_Id_Zero' incorporates:
         *  Constant: '<S18>/Fault_Id_Zero_Value'
         */
        AXU5EV_Motor_Control_System_DW.MIL_Fault_Id_Zero = 0.0;

        /* Switch: '<S18>/MIL_Fault_Iq_Zero' incorporates:
         *  Constant: '<S18>/Fault_Iq_Zero_Value'
         */
        AXU5EV_Motor_Control_System_DW.MIL_Fault_Iq_Zero = 0.0;
      } else if (AXU5EV_Motor_Control_System_DW.Angle_Init_EN > 0.5) {
        /* Switch: '<S18>/MIL_Align_Id_Select' incorporates:
         *  Switch: '<S18>/MIL_Fault_Id_Zero'
         */
        AXU5EV_Motor_Control_System_DW.MIL_Fault_Id_Zero =
          AXU5EV_Motor_Control_System_DW.id_init_ref;

        /* Switch: '<S18>/MIL_Fault_Iq_Zero' incorporates:
         *  Constant: '<S18>/Alignment_Iq_Zero'
         *  Switch: '<S18>/MIL_Align_Iq_Zero'
         */
        AXU5EV_Motor_Control_System_DW.MIL_Fault_Iq_Zero = 0.0;
      } else {
        /* Switch: '<S18>/MIL_Fault_Id_Zero' incorporates:
         *  Switch: '<S18>/MIL_Align_Id_Select'
         */
        AXU5EV_Motor_Control_System_DW.MIL_Fault_Id_Zero =
          AXU5EV_Motor_Control_System_DW.id_ref_cmd;

        /* Switch: '<S23>/Switch' incorporates:
         *  Switch: '<S18>/MIL_Align_Iq_Zero'
         */
        if (AXU5EV_Motor_Control_System_DW.iq_test_mode > 0.5) {
          /* Switch: '<S18>/MIL_Fault_Iq_Zero' */
          AXU5EV_Motor_Control_System_DW.MIL_Fault_Iq_Zero =
            AXU5EV_Motor_Control_System_DW.iq_test_ref;
        } else {
          /* Switch: '<S18>/MIL_Fault_Iq_Zero' */
          AXU5EV_Motor_Control_System_DW.MIL_Fault_Iq_Zero =
            AXU5EV_Motor_Control_System_DW.PI_Reset_Output;
        }

        /* End of Switch: '<S23>/Switch' */
      }

      /* End of Switch: '<S18>/MIL_Fault_Id_Zero' */

      /* Switch: '<S24>/pos_cnt_hold_sel' incorporates:
       *  Constant: '<S24>/Constant1'
       *  Constant: '<S24>/Constant2'
       *  Sum: '<S24>/Add1'
       *  Switch: '<S24>/spd_cnt_next_sel'
       *  UnitDelay: '<S24>/spd_cnt_z'
       */
      if (rtb_Compare) {
        /* Switch: '<S24>/pos_cnt_update_sel' incorporates:
         *  Constant: '<S24>/Constant3'
         *  Constant: '<S24>/Constant4'
         *  Sum: '<S24>/Add2'
         *  UnitDelay: '<S24>/pos_cnt_z'
         */
        if (new_tick) {
          AXU5EV_Motor_Control_System_DW.pos_cnt_z_DSTATE = 0.0;
        } else {
          AXU5EV_Motor_Control_System_DW.pos_cnt_z_DSTATE++;
        }

        /* End of Switch: '<S24>/pos_cnt_update_sel' */
        AXU5EV_Motor_Control_System_DW.spd_cnt_z_DSTATE = 0.0;
      } else {
        AXU5EV_Motor_Control_System_DW.spd_cnt_z_DSTATE++;
      }

      /* End of Switch: '<S24>/pos_cnt_hold_sel' */
    }

    /* End of Outputs for SubSystem: '<S10>/Host_New_Frame' */
    /* End of Outputs for SubSystem: '<S10>/Motion_Control' */

    /* Outport: '<Root>/runtime_frame' incorporates:
     *  DataTypeConversion: '<S10>/Status_Double_10'
     *  DataTypeConversion: '<S10>/Status_Double_11'
     *  DataTypeConversion: '<S10>/Status_Double_12'
     *  SignalConversion generated from: '<S10>/runtime_y'
     */
    AXU5EV_Motor_Control_System_Y.runtime_frame[0] =
      AXU5EV_Motor_Control_System_DW.MIL_Fault_Id_Zero;
    AXU5EV_Motor_Control_System_Y.runtime_frame[1] =
      AXU5EV_Motor_Control_System_DW.MIL_Fault_Iq_Zero;
    AXU5EV_Motor_Control_System_Y.runtime_frame[2] =
      AXU5EV_Motor_Control_System_DW.v_ref_safe;
    AXU5EV_Motor_Control_System_Y.runtime_frame[3] =
      AXU5EV_Motor_Control_System_DW.Init_Done;
    AXU5EV_Motor_Control_System_Y.runtime_frame[4] =
      AXU5EV_Motor_Control_System_DW.Init_State_Num;
    AXU5EV_Motor_Control_System_Y.runtime_frame[5] =
      AXU5EV_Motor_Control_System_DW.id_init_ref;
    AXU5EV_Motor_Control_System_Y.runtime_frame[6] =
      AXU5EV_Motor_Control_System_DW.Angle_Init_EN;
    AXU5EV_Motor_Control_System_Y.runtime_frame[7] =
      AXU5EV_Motor_Control_System_DW.Theta_Offset_auto;
    AXU5EV_Motor_Control_System_Y.runtime_frame[8] =
      AXU5EV_Motor_Control_System_DW.x_align_mm_latch;
    AXU5EV_Motor_Control_System_Y.runtime_frame[9] = rtb_Alignment_Ready_p;
    AXU5EV_Motor_Control_System_Y.runtime_frame[10] =
      rtb_Software_Alignment_Permit;
    AXU5EV_Motor_Control_System_Y.runtime_frame[11] =
      rtb_Alignment_Fault_Active_g;
    AXU5EV_Motor_Control_System_Y.runtime_frame[12] =
      AXU5EV_Motor_Control_System_DW.x_ref_mm;
    AXU5EV_Motor_Control_System_Y.runtime_frame[13] =
      AXU5EV_Motor_Control_System_DW.vdc;
    AXU5EV_Motor_Control_System_Y.runtime_frame[14] =
      AXU5EV_Motor_Control_System_DW.load_N;
    AXU5EV_Motor_Control_System_Y.runtime_frame[15] =
      AXU5EV_Motor_Control_System_DW.Close_Loop_EN;
    AXU5EV_Motor_Control_System_Y.runtime_frame[16] =
      AXU5EV_Motor_Control_System_DW.Position_Loop_EN;
    AXU5EV_Motor_Control_System_Y.runtime_frame[17] =
      AXU5EV_Motor_Control_System_DW.PWM_EN;
    AXU5EV_Motor_Control_System_Y.runtime_frame[18] =
      AXU5EV_Motor_Control_System_DW.v_ref_cmd;
    AXU5EV_Motor_Control_System_Y.runtime_frame[19] =
      AXU5EV_Motor_Control_System_DW.id_ref_cmd;
    AXU5EV_Motor_Control_System_Y.runtime_frame[20] =
      AXU5EV_Motor_Control_System_DW.iq_test_mode;
    AXU5EV_Motor_Control_System_Y.runtime_frame[21] =
      AXU5EV_Motor_Control_System_DW.iq_test_ref;
    AXU5EV_Motor_Control_System_Y.runtime_frame[22] =
      AXU5EV_Motor_Control_System_DW.PI_Reset_EN;
    AXU5EV_Motor_Control_System_Y.runtime_frame[23] =
      AXU5EV_Motor_Control_System_DW.target_accepted_mm;
    AXU5EV_Motor_Control_System_Y.runtime_frame[24] =
      AXU5EV_Motor_Control_System_DW.move_busy;
    AXU5EV_Motor_Control_System_Y.runtime_frame[25] =
      AXU5EV_Motor_Control_System_DW.in_position;
    AXU5EV_Motor_Control_System_Y.runtime_frame[26] =
      AXU5EV_Motor_Control_System_DW.command_status;
    AXU5EV_Motor_Control_System_Y.runtime_frame[27] =
      AXU5EV_Motor_Control_System_DW.segment_start_mm;
    AXU5EV_Motor_Control_System_Y.runtime_frame[28] =
      AXU5EV_Motor_Control_System_DW.segment_start_s;
    AXU5EV_Motor_Control_System_Y.runtime_frame[29] =
      AXU5EV_Motor_Control_System_DW.trajectory_done;
    AXU5EV_Motor_Control_System_Y.runtime_frame[30] =
      AXU5EV_Motor_Control_System_DW.move_ready;
    AXU5EV_Motor_Control_System_Y.runtime_frame[31] =
      AXU5EV_Motor_Control_System_DW.accepted_count;
    AXU5EV_Motor_Control_System_Y.runtime_frame[32] =
      AXU5EV_Motor_Control_System_DW.rejected_count;
    AXU5EV_Motor_Control_System_Y.runtime_frame[33] =
      AXU5EV_Motor_Control_System_DW.segment_id;
    AXU5EV_Motor_Control_System_Y.runtime_frame[34] =
      AXU5EV_Motor_Control_System_DW.command_received_s;
    AXU5EV_Motor_Control_System_Y.runtime_frame[35] =
      AXU5EV_Motor_Control_System_DW.move_interrupted;
    for (i = 0; i < 5; i++) {
      AXU5EV_Motor_Control_System_Y.runtime_frame[i + 36] =
        AXU5EV_Motor_Control_System_DW.trajectory_config[i];
    }
  }

  /* End of Logic: '<S2>/Runtime_Advance_Or_Safety' */
  /* End of Outputs for SubSystem: '<S2>/Qualified_Runtime' */

  /* MATLAB Function: '<S2>/Reference_Commit' incorporates:
   *  Inport: '<Root>/current_valid'
   *  Inport: '<Root>/sample_id'
   *  MATLAB Function: '<S2>/Alignment_Permit'
   *  MATLAB Function: '<S2>/Frame_And_Fault_Qualification'
   *  Outport: '<Root>/runtime_frame'
   *  Outport: '<Root>/speed_valid'
   *  UnitDelay: '<S18>/Travel_Fault_State'
   *
   * Block description for '<S2>/Reference_Commit':
   *  Packages Id[A], Iq[A], omega[rad/s], offset[rad], alignment angle
   *  selection, PWM permit, PI reset and reference valid plus
   *  frame/version. HW_BINDING_PENDING for atomic AXI submission.
   */
  if (clear_allowed_tmp) {
    if (AXU5EV_Motor_Control_System_DW.version == UINT32_MAX) {
      AXU5EV_Motor_Control_System_DW.version = 0U;
    } else {
      AXU5EV_Motor_Control_System_DW.version++;
    }

    AXU5EV_Motor_Control_System_DW.last_id =
      AXU5EV_Motor_Control_System_U.sample_id;
  }

  for (i = 0; i < 41; i++) {
    b_0[i] = !rtIsInf(AXU5EV_Motor_Control_System_Y.runtime_frame[i]);
    c_0[i] = !rtIsNaN(AXU5EV_Motor_Control_System_Y.runtime_frame[i]);
  }

  rtb_LogicalOperator3 = true;
  i = 0;
  while (i < 41) {
    if (!b_0[i] || !c_0[i]) {
      rtb_LogicalOperator3 = false;
      break;
    } else {
      i++;
    }
  }

  command_valid = (clear_allowed_tmp && (clear_allowed_tmp && hard_fault &&
    clear_allowed_tmp_0 && clear_allowed_tmp_1 &&
    AXU5EV_Motor_Control_System_U.current_valid && command_valid && raw_fault) &&
                   AXU5EV_Motor_Control_System_Y.speed_valid &&
                   !AXU5EV_Motor_Control_System_DW.External_Fault_Latch_Z_DSTATE
                   && (AXU5EV_Motor_Control_System_DW.Travel_Fault_State_DSTATE <=
                       0.5) && rtb_LogicalOperator3);
  clear_allowed_tmp_0 = (command_valid &&
    ((AXU5EV_Motor_Control_System_Y.runtime_frame[17] != 0.0) && (fault_tmp &&
    (raw_fault && permit_tmp))));

  /* Outport: '<Root>/reference_commit' incorporates:
   *  Constant: '<S2>/Alignment_Id_Limit_A'
   *  Constant: '<S2>/Debug_Iq_Limit_A'
   *  MATLAB Function: '<S2>/Reference_Commit'
   *  Outport: '<Root>/runtime_frame'
   *
   * Block description for '<Root>/reference_commit':
   *  PL command contract v1, 8 doubles. Id[A], Iq[A], omega[rad/s],
   *  offset[rad], alignment-angle bool, PWM permit bool, PI reset bool,
   *  valid bool.
   *
   * Block description for '<S2>/Reference_Commit':
   *  Packages Id[A], Iq[A], omega[rad/s], offset[rad], alignment angle
   *  selection, PWM permit, PI reset and reference valid plus
   *  frame/version. HW_BINDING_PENDING for atomic AXI submission.
   */
  AXU5EV_Motor_Control_System_Y.reference_commit[0] = fmin(0.5, fmax(-0.5,
    AXU5EV_Motor_Control_System_Y.runtime_frame[0]));
  AXU5EV_Motor_Control_System_Y.reference_commit[1] = fmin(0.3, fmax(-0.3,
    AXU5EV_Motor_Control_System_Y.runtime_frame[1]));

  /* MATLAB Function: '<S2>/Reference_Commit' incorporates:
   *  Constant: '<S2>/Electrical_Period_mm'
   *  Outport: '<Root>/speed_mm_s'
   *  Outport: '<Root>/speed_valid'
   *
   * Block description for '<S2>/Reference_Commit':
   *  Packages Id[A], Iq[A], omega[rad/s], offset[rad], alignment angle
   *  selection, PWM permit, PI reset and reference valid plus
   *  frame/version. HW_BINDING_PENDING for atomic AXI submission.
   */
  clear_allowed_tmp = !command_valid;
  if (clear_allowed_tmp) {
    /* Outport: '<Root>/reference_commit'
     *
     * Block description for '<Root>/reference_commit':
     *  PL command contract v1, 8 doubles. Id[A], Iq[A], omega[rad/s],
     *  offset[rad], alignment-angle bool, PWM permit bool, PI reset bool,
     *  valid bool.
     */
    AXU5EV_Motor_Control_System_Y.reference_commit[0] = 0.0;
    AXU5EV_Motor_Control_System_Y.reference_commit[1] = 0.0;
  }

  rtb_Sum1 = AXU5EV_Motor_Control_System_Y.speed_mm_s * 0.20943951023931953;
  if (!AXU5EV_Motor_Control_System_Y.speed_valid) {
    rtb_Sum1 = 0.0;
  } else if (rtIsInf(rtb_Sum1) || rtIsNaN(rtb_Sum1)) {
    rtb_Sum1 = 0.0;
  }

  /* Outport: '<Root>/reference_commit' incorporates:
   *  MATLAB Function: '<S2>/Reference_Commit'
   *  Outport: '<Root>/runtime_frame'
   *
   * Block description for '<Root>/reference_commit':
   *  PL command contract v1, 8 doubles. Id[A], Iq[A], omega[rad/s],
   *  offset[rad], alignment-angle bool, PWM permit bool, PI reset bool,
   *  valid bool.
   *
   * Block description for '<S2>/Reference_Commit':
   *  Packages Id[A], Iq[A], omega[rad/s], offset[rad], alignment angle
   *  selection, PWM permit, PI reset and reference valid plus
   *  frame/version. HW_BINDING_PENDING for atomic AXI submission.
   */
  AXU5EV_Motor_Control_System_Y.reference_commit[3] =
    AXU5EV_Motor_Control_System_Y.runtime_frame[7];
  AXU5EV_Motor_Control_System_Y.reference_commit[4] =
    AXU5EV_Motor_Control_System_Y.runtime_frame[6];

  /* MATLAB Function: '<S2>/Reference_Commit'
   *
   * Block description for '<S2>/Reference_Commit':
   *  Packages Id[A], Iq[A], omega[rad/s], offset[rad], alignment angle
   *  selection, PWM permit, PI reset and reference valid plus
   *  frame/version. HW_BINDING_PENDING for atomic AXI submission.
   */
  if (!rtb_LogicalOperator3) {
    /* Outport: '<Root>/reference_commit'
     *
     * Block description for '<Root>/reference_commit':
     *  PL command contract v1, 8 doubles. Id[A], Iq[A], omega[rad/s],
     *  offset[rad], alignment-angle bool, PWM permit bool, PI reset bool,
     *  valid bool.
     */
    AXU5EV_Motor_Control_System_Y.reference_commit[3] = 0.0;
    AXU5EV_Motor_Control_System_Y.reference_commit[4] = 0.0;
  }

  /* Outport: '<Root>/reference_commit' incorporates:
   *  MATLAB Function: '<S2>/Reference_Commit'
   *  Outport: '<Root>/runtime_frame'
   *
   * Block description for '<Root>/reference_commit':
   *  PL command contract v1, 8 doubles. Id[A], Iq[A], omega[rad/s],
   *  offset[rad], alignment-angle bool, PWM permit bool, PI reset bool,
   *  valid bool.
   *
   * Block description for '<S2>/Reference_Commit':
   *  Packages Id[A], Iq[A], omega[rad/s], offset[rad], alignment angle
   *  selection, PWM permit, PI reset and reference valid plus
   *  frame/version. HW_BINDING_PENDING for atomic AXI submission.
   */
  AXU5EV_Motor_Control_System_Y.reference_commit[2] = rtb_Sum1;
  AXU5EV_Motor_Control_System_Y.reference_commit[5] = clear_allowed_tmp_0;
  AXU5EV_Motor_Control_System_Y.reference_commit[6] =
    ((AXU5EV_Motor_Control_System_Y.runtime_frame[22] != 0.0) ||
     (!clear_allowed_tmp_0 || clear_allowed_tmp));
  AXU5EV_Motor_Control_System_Y.reference_commit[7] = command_valid;

  /* Outport: '<Root>/commit_sample_id' incorporates:
   *  MATLAB Function: '<S2>/Reference_Commit'
   *
   * Block description for '<S2>/Reference_Commit':
   *  Packages Id[A], Iq[A], omega[rad/s], offset[rad], alignment angle
   *  selection, PWM permit, PI reset and reference valid plus
   *  frame/version. HW_BINDING_PENDING for atomic AXI submission.
   */
  AXU5EV_Motor_Control_System_Y.commit_sample_id =
    AXU5EV_Motor_Control_System_DW.last_id;

  /* Outport: '<Root>/reference_version' incorporates:
   *  MATLAB Function: '<S2>/Reference_Commit'
   *
   * Block description for '<S2>/Reference_Commit':
   *  Packages Id[A], Iq[A], omega[rad/s], offset[rad], alignment angle
   *  selection, PWM permit, PI reset and reference valid plus
   *  frame/version. HW_BINDING_PENDING for atomic AXI submission.
   */
  AXU5EV_Motor_Control_System_Y.reference_version =
    AXU5EV_Motor_Control_System_DW.version;

  /* MATLAB Function: '<S2>/Capture_Latest_Observation' incorporates:
   *  DataStoreWrite: '<S2>/Store_Latest_Telemetry'
   *  Inport: '<Root>/sample_id'
   *  Outport: '<Root>/position_mm'
   *  Outport: '<Root>/reference_commit'
   *  Outport: '<Root>/reference_version'
   *  Outport: '<Root>/runtime_frame'
   *  Outport: '<Root>/speed_mm_s'
   *
   * Block description for '<Root>/reference_commit':
   *  PL command contract v1, 8 doubles. Id[A], Iq[A], omega[rad/s],
   *  offset[rad], alignment-angle bool, PWM permit bool, PI reset bool,
   *  valid bool.
   */
  AXU5EV_Motor_Control_System_DW.LatestTelemetry[0] =
    AXU5EV_Motor_Control_System_U.sample_id;
  AXU5EV_Motor_Control_System_DW.LatestTelemetry[1] =
    AXU5EV_Motor_Control_System_Y.reference_version;
  AXU5EV_Motor_Control_System_DW.LatestTelemetry[2] =
    AXU5EV_Motor_Control_System_Y.position_mm;
  AXU5EV_Motor_Control_System_DW.LatestTelemetry[3] =
    AXU5EV_Motor_Control_System_Y.speed_mm_s;
  AXU5EV_Motor_Control_System_DW.LatestTelemetry[4] =
    AXU5EV_Motor_Control_System_Y.runtime_frame[4];
  AXU5EV_Motor_Control_System_DW.LatestTelemetry[5] =
    AXU5EV_Motor_Control_System_Y.reference_commit[0];
  AXU5EV_Motor_Control_System_DW.LatestTelemetry[6] =
    AXU5EV_Motor_Control_System_Y.reference_commit[1];
  AXU5EV_Motor_Control_System_DW.LatestTelemetry[7] =
    AXU5EV_Motor_Control_System_Y.reference_commit[2];
  AXU5EV_Motor_Control_System_DW.LatestTelemetry[8] =
    AXU5EV_Motor_Control_System_Y.reference_commit[3];
  AXU5EV_Motor_Control_System_DW.LatestTelemetry[9] =
    AXU5EV_Motor_Control_System_Y.reference_commit[5];
  AXU5EV_Motor_Control_System_DW.LatestTelemetry[10] =
    AXU5EV_Motor_Control_System_Y.reference_commit[7];
  AXU5EV_Motor_Control_System_DW.LatestTelemetry[11] = rtb_Control_Fault;

  /* Update for UnitDelay: '<S8>/Position_Hold' incorporates:
   *  Outport: '<Root>/position_mm'
   */
  AXU5EV_Motor_Control_System_DW.Position_Hold_DSTATE =
    AXU5EV_Motor_Control_System_Y.position_mm;

  /* Update for Delay: '<S8>/Speed_Window_Delay' incorporates:
   *  Sum: '<S8>/Continuous_Position_Count'
   */
  if (advance) {
    AXU5EV_Motor_Control_System_DW.icLoad = false;
    for (i = 0; i < 49; i++) {
      AXU5EV_Motor_Control_System_DW.Speed_Window_Delay_DSTATE[i] =
        AXU5EV_Motor_Control_System_DW.Speed_Window_Delay_DSTATE[i + 1];
    }

    AXU5EV_Motor_Control_System_DW.Speed_Window_Delay_DSTATE[49] = delta;
  }

  /* End of Update for Delay: '<S8>/Speed_Window_Delay' */

  /* End of Outputs for RootInportFunctionCallGenerator generated from: '<Root>/PL_Frame_IRQ' */

  /* Outport: '<Root>/drive_outputs' incorporates:
   *  Inport: '<Root>/request_freset'
   *
   * Block description for '<Root>/drive_outputs':
   *  PL/driver command contract v1, 5 bools. RELCON, ENCON, F_Reset,
   *  OE_disable, external fault latch. true OE_disable prohibits physical
   *  output. Hardware drivers pending.
   */
  AXU5EV_Motor_Control_System_Y.drive_outputs[0] = rtb_restart_history;
  AXU5EV_Motor_Control_System_Y.drive_outputs[1] = rtb_System_Fault_Not;
  AXU5EV_Motor_Control_System_Y.drive_outputs[2] =
    AXU5EV_Motor_Control_System_U.request_freset;
  AXU5EV_Motor_Control_System_Y.drive_outputs[3] = LogicalOperator;
  AXU5EV_Motor_Control_System_Y.drive_outputs[4] =
    AXU5EV_Motor_Control_System_DW.External_Fault_Latch_Z_DSTATE;
}

/* Model step function */
void Service_Request(void)
{
  /* RootInportFunctionCallGenerator generated from: '<Root>/Service_Request' incorporates:
   *  SubSystem: '<Root>/NonRealtime_Service'
   *
   * Block description for RootInportFunctionCallGenerator generated from '<Root>/Service_Request':
   *  Externally scheduled non-real-time service. Copies latest 12-field
   *  telemetry and counts calls. IRQ preemption-consistent
   *  snapshot/communications binding pending in delivery B.
   *
   * Block description for '<Root>/NonRealtime_Service':
   *  Service_Request copies the latest 12-value telemetry and increments a
   *  software counter. Communication, long recording and
   *  preemption-consistent snapshots are HW_BINDING_PENDING.
   */
  /* Outport: '<Root>/telemetry' incorporates:
   *  DataStoreRead: '<S3>/Read_Latest_Telemetry'
   */
  memcpy(&AXU5EV_Motor_Control_System_Y.telemetry[0],
         &AXU5EV_Motor_Control_System_DW.LatestTelemetry[0], 12U * sizeof(double));

  /* MATLAB Function: '<S3>/Count_Service_Call' incorporates:
   *  UnitDelay: '<S3>/Service_Count_State'
   */
  if (AXU5EV_Motor_Control_System_DW.Service_Count_State_DSTATE == UINT32_MAX) {
    /* Outport: '<Root>/service_count' */
    AXU5EV_Motor_Control_System_Y.service_count = 0U;
  } else {
    /* Outport: '<Root>/service_count' */
    AXU5EV_Motor_Control_System_Y.service_count =
      AXU5EV_Motor_Control_System_DW.Service_Count_State_DSTATE + /*MW:OvSatOk*/
      1U;
  }

  /* End of MATLAB Function: '<S3>/Count_Service_Call' */

  /* Update for UnitDelay: '<S3>/Service_Count_State' incorporates:
   *  Outport: '<Root>/service_count'
   */
  AXU5EV_Motor_Control_System_DW.Service_Count_State_DSTATE =
    AXU5EV_Motor_Control_System_Y.service_count;

  /* End of Outputs for RootInportFunctionCallGenerator generated from: '<Root>/Service_Request' */
}

/* Model initialize function */
void AXU5EV_Motor_Control_System_initialize(void)
{
  /* Registration code */

  /* initialize error status */
  rtmSetErrorStatus(AXU5EV_Motor_Control_System_M, (NULL));

  /* states (dwork) */
  (void) memset((void *)&AXU5EV_Motor_Control_System_DW, 0,
                sizeof(DW_AXU5EV_Motor_Control_Syste_T));

  {
    AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
    AXU5EV_Motor_Control_System_DW.Init_State_Num = 0.0;
    AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
    AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 0.0;
    AXU5EV_Motor_Control_System_DW.Theta_Offset_auto = 0.0;
    AXU5EV_Motor_Control_System_DW.x_align_mm_latch = 0.0;
  }

  /* external inputs */
  (void)memset(&AXU5EV_Motor_Control_System_U, 0, sizeof
               (ExtU_AXU5EV_Motor_Control_Sys_T));

  /* external outputs */
  (void)memset(&AXU5EV_Motor_Control_System_Y, 0, sizeof
               (ExtY_AXU5EV_Motor_Control_Sys_T));
  AXU5EV_Motor_Control_Sy_PrevZCX.Position_Loop_Trig_ZCE = POS_ZCSIG;
  AXU5EV_Motor_Control_Sy_PrevZCX.Speed_Loop_Trig_ZCE = POS_ZCSIG;

  /* SystemInitialize for RootInportFunctionCallGenerator generated from: '<Root>/PL_Frame_IRQ' incorporates:
   *  SubSystem: '<Root>/Motor_Control_ISR'
   *
   * Block description for RootInportFunctionCallGenerator generated from '<Root>/PL_Frame_IRQ':
   *  External function-call entry at each accepted 100us ADC/QEP feedback
   *  frame. HW_BINDING_PENDING: physical PL IRQ/GIC registration and atomic
   *  driver binding.
   */
  /* Start for Delay: '<S8>/Speed_Window_Delay' */
  AXU5EV_Motor_Control_System_DW.Speed_Window_Delay = INT64_C(0);

  /* InitializeConditions for Delay: '<S8>/Speed_Window_Delay' */
  AXU5EV_Motor_Control_System_DW.icLoad = true;

  /* SystemInitialize for MATLAB Function: '<S8>/Frame_And_Count_Guard' */
  AXU5EV_Motor_Control_System_DW.initialized = false;
  AXU5EV_Motor_Control_System_DW.last_raw = 0U;
  AXU5EV_Motor_Control_System_DW.last_id_f = 0U;
  AXU5EV_Motor_Control_System_DW.last_tick = UINT64_C(0);
  AXU5EV_Motor_Control_System_DW.last_bad = 0U;
  AXU5EV_Motor_Control_System_DW.total = INT64_C(0);
  AXU5EV_Motor_Control_System_DW.origin = INT64_C(0);
  AXU5EV_Motor_Control_System_DW.old_zero = 0U;
  AXU5EV_Motor_Control_System_DW.old_reverse = false;
  AXU5EV_Motor_Control_System_DW.old_version = 0U;
  AXU5EV_Motor_Control_System_DW.old_scale = 0U;
  AXU5EV_Motor_Control_System_DW.filled = 0U;

  /* SystemInitialize for MATLAB Function: '<S2>/Frame_And_Fault_Qualification' */
  AXU5EV_Motor_Control_System_DW.fault = false;

  /* SystemInitialize for Enabled SubSystem: '<S2>/Qualified_Runtime' */
  /* SystemInitialize for Chart: '<S19>/Angle_Init' */
  AXU5EV_Motor_Control_System_DW.temporalCounter_i1 = 0U;
  AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
  AXU5EV_Motor_Control_System_DW.Init_State_Num = 0.0;
  AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
  AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 0.0;
  AXU5EV_Motor_Control_System_DW.Theta_Offset_auto = 0.0;
  AXU5EV_Motor_Control_System_DW.x_align_mm_latch = 0.0;
  AXU5EV_Motor_Control_System_DW.theta_offset_mem = 0.0;
  AXU5EV_Motor_Control_System_DW.Start_Armed = false;
  AXU5EV_Motor_Control_System_DW.is_active_c3_AXU5EV_Motor_Contr = 0U;
  AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
    AXU5EV_Motor_IN_NO_ACTIVE_CHILD;

  /* SystemInitialize for Enabled SubSystem: '<S10>/Host_New_Frame' */
  /* SystemInitialize for MATLAB Function: '<S17>/Host_Core' */
  memset(&AXU5EV_Motor_Control_System_DW.move_state[0], 0, 22U * sizeof(double));

  /* End of SystemInitialize for SubSystem: '<S10>/Host_New_Frame' */
  /* End of SystemInitialize for SubSystem: '<S2>/Qualified_Runtime' */

  /* SystemInitialize for MATLAB Function: '<S2>/Reference_Commit'
   *
   * Block description for '<S2>/Reference_Commit':
   *  Packages Id[A], Iq[A], omega[rad/s], offset[rad], alignment angle
   *  selection, PWM permit, PI reset and reference valid plus
   *  frame/version. HW_BINDING_PENDING for atomic AXI submission.
   */
  AXU5EV_Motor_Control_System_DW.version = 0U;
  AXU5EV_Motor_Control_System_DW.last_id = 0U;

  /* SystemInitialize for Outport: '<Root>/reference_commit' incorporates:
   *  Outport: '<S2>/reference_commit'
   *
   * Block description for '<Root>/reference_commit':
   *  PL command contract v1, 8 doubles. Id[A], Iq[A], omega[rad/s],
   *  offset[rad], alignment-angle bool, PWM permit bool, PI reset bool,
   *  valid bool.
   */
  memcpy(&AXU5EV_Motor_Control_System_Y.reference_commit[0],
         &AXU5EV_Motor_Control_Sys_ConstP.reference_commit_Y0[0], sizeof(double)
         << 3U);

  /* SystemInitialize for Outport: '<Root>/drive_outputs' incorporates:
   *  Outport: '<S2>/drive_outputs'
   *
   * Block description for '<Root>/drive_outputs':
   *  PL/driver command contract v1, 5 bools. RELCON, ENCON, F_Reset,
   *  OE_disable, external fault latch. true OE_disable prohibits physical
   *  output. Hardware drivers pending.
   */
  AXU5EV_Motor_Control_System_Y.drive_outputs[0] = false;
  AXU5EV_Motor_Control_System_Y.drive_outputs[1] = false;
  AXU5EV_Motor_Control_System_Y.drive_outputs[2] = false;
  AXU5EV_Motor_Control_System_Y.drive_outputs[3] = true;
  AXU5EV_Motor_Control_System_Y.drive_outputs[4] = false;

  /* End of SystemInitialize for RootInportFunctionCallGenerator generated from: '<Root>/PL_Frame_IRQ' */

  /* Outputs for Atomic SubSystem: '<Root>/Initialize_Controller' */
  /* DataStoreWrite: '<S1>/Set_Controller_Initialized' incorporates:
   *  Constant: '<S1>/Initialization_Complete'
   */
  AXU5EV_Motor_Control_System_DW.Initialized = true;

  /* End of Outputs for SubSystem: '<Root>/Initialize_Controller' */
}

/* Model terminate function */
void AXU5EV_Motor_Control_System_terminate(void)
{
  /* (no terminate code required) */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
