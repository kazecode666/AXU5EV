/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: AXU5EV_Motor_Control_System.c
 *
 * Code generated for Simulink model 'AXU5EV_Motor_Control_System'.
 *
 * Model version                  : 1.70
 * Simulink Coder version         : 26.2 (R2026b) 22-May-2026
 * C/C++ source code generated on : Tue Nov 17 17:40:56 2026
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

/* Named constants for Chart: '<S17>/Angle_Init' */
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

/* Function for MATLAB Function: '<S9>/Host_Core' */
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

/* Function for MATLAB Function: '<S9>/Host_Core' */
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

/* Function for MATLAB Function: '<S9>/Host_Core' */
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
  double rtb_u_h[20];
  double cfg[4];
  double cfg_0[3];
  double Close_Loop_EN;
  double D;
  double Position_Loop_EN;
  double Ta;
  double Tc;
  double V;
  double omega;
  double q;
  double rtb_Software_Time_s;
  double rtb_UnitDelay;
  double s;
  double t;
  double target;
  double tick;
  int64_t delta;
  uint64_t id_delta;
  uint64_t qY;
  uint64_t tick_delta;
  int32_t i;
  bool b_0[41];
  bool c_0[41];
  bool b[20];
  bool c[20];
  bool advance;
  bool clear_allowed_tmp;
  bool clear_allowed_tmp_0;
  bool command_valid;
  bool guard1;
  bool guard2;
  bool guard3;
  bool guard4;
  bool new_tick;
  bool rtb_Alignment_Fault_Active;
  bool rtb_Alignment_Ready;
  bool rtb_Compare;
  bool rtb_Control_Fault;
  bool rtb_Init_Done_Or_Bypass;
  bool rtb_LogicalOperator;
  bool rtb_LogicalOperator3;
  bool rtb_System_Fault_Not;
  bool rtb_restart_history;

  /* RootInportFunctionCallGenerator generated from: '<Root>/PL_Frame_IRQ' incorporates:
   *  SubSystem: '<Root>/Motor_Control_ISR'
   */
  /* Outport: '<Root>/continuous_count' incorporates:
   *  MATLAB Function: '<S7>/Frame_And_Count_Guard'
   */
  AXU5EV_Motor_Control_System_Y.continuous_count =
    AXU5EV_Motor_Control_System_DW.total;

  /* MATLAB Function: '<S7>/Frame_And_Count_Guard' */
  advance = false;
  rtb_restart_history = false;

  /* Outport: '<Root>/position_valid' incorporates:
   *  MATLAB Function: '<S7>/Frame_And_Count_Guard'
   */
  AXU5EV_Motor_Control_System_Y.position_valid = false;

  /* Outport: '<Root>/speed_valid' incorporates:
   *  MATLAB Function: '<S7>/Frame_And_Count_Guard'
   */
  AXU5EV_Motor_Control_System_Y.speed_valid = false;

  /* MATLAB Function: '<S7>/Frame_And_Count_Guard' incorporates:
   *  Constant: '<S2>/Encoder_Config_Version'
   *  Constant: '<S2>/Encoder_Forward'
   *  Constant: '<S2>/Encoder_Nanometres_Per_Count'
   *  Constant: '<S2>/Mechanical_Zero_Count'
   *  Inport: '<Root>/encoder_ready'
   *  Inport: '<Root>/illegal_count'
   *  Inport: '<Root>/raw_count'
   *  Inport: '<Root>/sample_id'
   *  Inport: '<Root>/sample_tick'
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
          AXU5EV_Motor_Control_System_DW.last_id_l) {
        id_delta = (uint64_t)AXU5EV_Motor_Control_System_U.sample_id -
          /*MW:operator MISRA2012:D4.1 CERT-C:INT30-C 'Justifying MISRA C rule violation'*/
          /*MW:OvSatOk*/ AXU5EV_Motor_Control_System_DW.last_id_l;
        if (id_delta > AXU5EV_Motor_Control_System_U.sample_id) {
          id_delta = UINT64_C(0);
        }
      } else {
        id_delta = ((uint64_t)AXU5EV_Motor_Control_System_U.sample_id -
                    AXU5EV_Motor_Control_System_DW.last_id_l) + UINT64_C
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
            || (id_delta * UINT64_C(10) != tick_delta)) {
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
      command_valid = (!AXU5EV_Motor_Control_System_DW.initialized ||
                       (AXU5EV_Motor_Control_System_DW.old_zero != 0U));
      if (command_valid || AXU5EV_Motor_Control_System_DW.old_reverse ||
          (AXU5EV_Motor_Control_System_DW.old_version != 1U) ||
          (AXU5EV_Motor_Control_System_DW.old_scale != 1000U)) {
        if (command_valid) {
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
      AXU5EV_Motor_Control_System_DW.last_id_l =
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

  /* Sum: '<S7>/Continuous_Position_Count' incorporates:
   *  Outport: '<Root>/continuous_count'
   */
  delta = AXU5EV_Motor_Control_System_Y.continuous_count -
    AXU5EV_Motor_Control_System_DW.origin;

  /* Switch: '<S7>/New_Frame_Position' incorporates:
   *  Delay: '<S7>/Delay_50_Intervals'
   *  Sum: '<S7>/Continuous_Position_Count'
   */
  if (advance) {
    /* Outport: '<Root>/position_mm' incorporates:
     *  DataTypeConversion: '<S7>/Position_Count_To_Double'
     *  Product: '<S7>/Position_Millimetres'
     *  Sum: '<S7>/Continuous_Position_Count'
     */
    AXU5EV_Motor_Control_System_Y.position_mm = (double)delta *
      AXU5EV_Motor_Control_Sys_ConstB.Nanometres_To_Millimetres *
      AXU5EV_Motor_Control_Sys_ConstB.Mechanical_Direction;
    AXU5EV_Motor_Control_System_DW.icLoad = (rtb_restart_history ||
      AXU5EV_Motor_Control_System_DW.icLoad);
    if (AXU5EV_Motor_Control_System_DW.icLoad) {
      for (i = 0; i < 50; i++) {
        AXU5EV_Motor_Control_System_DW.Delay_50_Intervals_DSTATE[i] = delta;
      }
    }

    /* Delay: '<S7>/Delay_50_Intervals' incorporates:
     *  Sum: '<S7>/Continuous_Position_Count'
     */
    AXU5EV_Motor_Control_System_DW.Delay_50_Intervals =
      AXU5EV_Motor_Control_System_DW.Delay_50_Intervals_DSTATE[0];
  } else {
    /* Outport: '<Root>/position_mm' incorporates:
     *  UnitDelay: '<S7>/Position_Hold'
     */
    AXU5EV_Motor_Control_System_Y.position_mm =
      AXU5EV_Motor_Control_System_DW.Position_Hold_DSTATE;
  }

  /* End of Switch: '<S7>/New_Frame_Position' */

  /* Switch: '<S7>/Qualified_Speed' incorporates:
   *  Outport: '<Root>/speed_valid'
   */
  if (AXU5EV_Motor_Control_System_Y.speed_valid) {
    /* Outport: '<Root>/speed_mm_s' incorporates:
     *  DataTypeConversion: '<S7>/Difference_To_Double'
     *  Delay: '<S7>/Delay_50_Intervals'
     *  Gain: '<S7>/Five_Millisecond_Speed'
     *  Product: '<S7>/Displacement_Millimetres'
     *  Sum: '<S7>/Continuous_Position_Count'
     *  Sum: '<S7>/Count_Difference_50_Intervals'
     */
    AXU5EV_Motor_Control_System_Y.speed_mm_s = (double)(delta -
      AXU5EV_Motor_Control_System_DW.Delay_50_Intervals) *
      AXU5EV_Motor_Control_Sys_ConstB.Nanometres_To_Millimetres *
      AXU5EV_Motor_Control_Sys_ConstB.Mechanical_Direction * 200.0;
  } else {
    /* Outport: '<Root>/speed_mm_s' incorporates:
     *  Constant: '<S7>/Zero'
     */
    AXU5EV_Motor_Control_System_Y.speed_mm_s = 0.0;
  }

  /* End of Switch: '<S7>/Qualified_Speed' */

  /* MATLAB Function: '<S2>/Frame_And_Fault_Qualification' incorporates:
   *  Constant: '<S2>/Hard_Travel_Max_mm'
   *  Constant: '<S2>/Hard_Travel_Min_mm'
   *  DataStoreRead: '<S2>/Controller_Initialized'
   *  Inport: '<Root>/CommandFrame'
   *  Inport: '<Root>/ERRI_n'
   *  Inport: '<Root>/ERRU_n'
   *  Inport: '<Root>/clear_fault'
   *  Inport: '<Root>/current_valid'
   *  Logic: '<S11>/Clear_Only_When_Raw_Healthy'
   *  MATLAB Function: '<S16>/Travel_Safety_Manager'
   *  Outport: '<Root>/feedback_status'
   *  Outport: '<Root>/position_mm'
   *  Outport: '<Root>/position_valid'
   */
  rtb_Control_Fault = (!AXU5EV_Motor_Control_System_Y.position_valid ||
                       !AXU5EV_Motor_Control_System_U.current_valid ||
                       ((AXU5EV_Motor_Control_System_Y.feedback_status & 116U)
                        != 0U));
  rtb_Alignment_Fault_Active = !AXU5EV_Motor_Control_System_U.ERRI_n;
  rtb_Init_Done_Or_Bypass = !AXU5EV_Motor_Control_System_U.ERRU_n;
  rtb_Alignment_Ready = (rtb_Alignment_Fault_Active || rtb_Init_Done_Or_Bypass);

  /* Outputs for Enabled SubSystem: '<S2>/Qualified_Runtime' incorporates:
   *  EnablePort: '<S9>/Qualified_Frame_Enable'
   */
  rtb_LogicalOperator3 = ((AXU5EV_Motor_Control_System_Y.position_mm >= 120.0) ||
    (AXU5EV_Motor_Control_System_Y.position_mm <= -120.0));

  /* End of Outputs for SubSystem: '<S2>/Qualified_Runtime' */
  rtb_Compare = (AXU5EV_Motor_Control_System_Y.position_valid &&
                 rtb_LogicalOperator3);
  for (i = 0; i < 20; i++) {
    b[i] = !rtIsInf(AXU5EV_Motor_Control_System_U.CommandFrame[i]);
    c[i] = !rtIsNaN(AXU5EV_Motor_Control_System_U.CommandFrame[i]);
  }

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

  rtb_restart_history = (AXU5EV_Motor_Control_System_DW.Initialized &&
    AXU5EV_Motor_Control_System_Y.position_valid &&
    ((AXU5EV_Motor_Control_System_Y.feedback_status & 2U) == 0U));
  clear_allowed_tmp = !rtb_Alignment_Ready;
  clear_allowed_tmp_0 = !rtb_Compare;
  rtb_System_Fault_Not = (rtb_restart_history &&
    AXU5EV_Motor_Control_System_U.clear_fault && clear_allowed_tmp &&
    clear_allowed_tmp_0 && !rtb_Control_Fault && command_valid &&
    (AXU5EV_Motor_Control_System_U.CommandFrame[7] == 0.0));
  new_tick = !rtb_System_Fault_Not;
  AXU5EV_Motor_Control_System_DW.fault = (new_tick && (rtb_Alignment_Ready ||
    rtb_Compare || rtb_Control_Fault || !command_valid ||
    AXU5EV_Motor_Control_System_DW.fault));

  /* Logic: '<S11>/External_Fault_Latch_OR' incorporates:
   *  Logic: '<S11>/Clear_Only_When_Raw_Healthy'
   *  Logic: '<S11>/External_Fault_OR'
   *  Logic: '<S11>/Retain_Unless_Safe_Clear'
   *  Logic: '<S11>/Retained_External_Fault'
   *  UnitDelay: '<S11>/External_Fault_Latch_Z'
   */
  AXU5EV_Motor_Control_System_DW.External_Fault_Latch_Z_DSTATE =
    (rtb_Alignment_Ready ||
     (AXU5EV_Motor_Control_System_DW.External_Fault_Latch_Z_DSTATE && (new_tick ||
       rtb_Alignment_Fault_Active || rtb_Init_Done_Or_Bypass)));

  /* Logic: '<S2>/Control_Fault' incorporates:
   *  MATLAB Function: '<S2>/Frame_And_Fault_Qualification'
   */
  rtb_Control_Fault = (AXU5EV_Motor_Control_System_DW.fault ||
                       AXU5EV_Motor_Control_System_DW.External_Fault_Latch_Z_DSTATE);

  /* MATLAB Function: '<S2>/Bind_Real_Feedback' incorporates:
   *  Inport: '<Root>/CommandFrame'
   */
  memcpy(&rtb_u_h[0], &AXU5EV_Motor_Control_System_U.CommandFrame[0], 20U *
         sizeof(double));
  rtb_Alignment_Fault_Active = true;
  i = 0;
  while (i < 20) {
    if (!b[i] || !c[i]) {
      rtb_Alignment_Fault_Active = false;
      break;
    } else {
      i++;
    }
  }

  if (!rtb_Alignment_Fault_Active) {
    memset(&rtb_u_h[0], 0, 20U * sizeof(double));
  }

  if (rtb_Control_Fault) {
    rtb_u_h[7] = 0.0;
  }

  /* Outputs for Enabled SubSystem: '<S2>/Qualified_Runtime' incorporates:
   *  EnablePort: '<S9>/Qualified_Frame_Enable'
   */
  /* MATLAB Function: '<S2>/Reference_Commit' incorporates:
   *  Inport: '<Root>/sample_id'
   */
  if (rtb_restart_history) {
    /* Gain: '<S9>/Software_Time_s' incorporates:
     *  UnitDelay: '<S9>/Software_Tick'
     */
    rtb_Software_Time_s = 0.0001 *
      AXU5EV_Motor_Control_System_DW.Software_Tick_DSTATE;

    /* Logic: '<S9>/Alignment_Fault_Active' incorporates:
     *  MATLAB Function: '<S2>/Bind_Real_Feedback'
     */
    rtb_Alignment_Fault_Active = ((rtb_u_h[15] != 0.0) && rtb_Control_Fault);

    /* Outputs for Enabled SubSystem: '<S14>/Enabled_Original_MIL' incorporates:
     *  EnablePort: '<S17>/Enable'
     */
    if (rtb_u_h[15] > 0.0) {
      /* Chart: '<S17>/Angle_Init' incorporates:
       *  MATLAB Function: '<S2>/Bind_Real_Feedback'
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
      } else {
        switch (AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst)
    {
         case AXU5EV_Motor_Control_Sy_IN_DONE:
          if ((rtb_u_h[17] > 0.5) || ((double)rtb_Control_Fault > 0.5)) {
            AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
              AXU5EV_Motor_Control_Sy_IN_IDLE;
            AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 0.0;
            AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
            AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
            AXU5EV_Motor_Control_System_DW.Init_State_Num = 0.0;
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
          if ((rtb_u_h[17] > 0.5) || ((double)rtb_Control_Fault > 0.5)) {
            AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
              AXU5EV_Motor_Control_Sy_IN_IDLE;
            AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 0.0;
            AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
            AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
            AXU5EV_Motor_Control_System_DW.Init_State_Num = 0.0;
          } else if (AXU5EV_Motor_Control_System_DW.temporalCounter_i1 >= 30000U)
          {
            AXU5EV_Motor_Control_System_DW.x_align_mm_latch =
              AXU5EV_Motor_Control_System_Y.position_mm;
            omega = 0.0 - 6.283185307179586 *
              AXU5EV_Motor_Control_System_DW.x_align_mm_latch / 30.0;
            if (rtIsNaN(omega)) {
              AXU5EV_Motor_Control_System_DW.theta_offset_mem = (rtNaN);
            } else if (rtIsInf(omega)) {
              AXU5EV_Motor_Control_System_DW.theta_offset_mem = (rtNaN);
            } else {
              q = fabs(omega / 6.283185307179586);
              if (fabs(q - floor(q + 0.5)) > 2.220446049250313E-16 * q) {
                AXU5EV_Motor_Control_System_DW.theta_offset_mem = fmod(omega,
                  6.283185307179586);
              } else {
                AXU5EV_Motor_Control_System_DW.theta_offset_mem = 0.0;
              }

              if (AXU5EV_Motor_Control_System_DW.theta_offset_mem == 0.0) {
                AXU5EV_Motor_Control_System_DW.theta_offset_mem = 0.0;
              } else if (AXU5EV_Motor_Control_System_DW.theta_offset_mem < 0.0)
              {
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
          if ((rtb_u_h[16] > 0.5) && (rtb_u_h[17] < 0.5) && ((double)
               rtb_Control_Fault < 0.5)) {
            AXU5EV_Motor_Control_System_DW.temporalCounter_i1 = 0U;
            AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
              AXU5EV_Motor_Control_IN_RAMP_ID;
            AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 1.0;
            AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
            AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
            AXU5EV_Motor_Control_System_DW.Init_State_Num = 1.0;
          }
          break;

         case AXU5EV_Motor_Co_IN_RAMP_DOWN_ID:
          if (AXU5EV_Motor_Control_System_DW.temporalCounter_i1 >= 2000U) {
            AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
              AXU5EV_Motor_Control_Sy_IN_DONE;
            AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 0.0;
            AXU5EV_Motor_Control_System_DW.Init_Done = 1.0;
            AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
            AXU5EV_Motor_Control_System_DW.Init_State_Num = 4.0;
          } else if ((rtb_u_h[17] > 0.5) || ((double)rtb_Control_Fault > 0.5)) {
            AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
              AXU5EV_Motor_Control_Sy_IN_IDLE;
            AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 0.0;
            AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
            AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
            AXU5EV_Motor_Control_System_DW.Init_State_Num = 0.0;
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
          if ((rtb_u_h[17] > 0.5) || ((double)rtb_Control_Fault > 0.5)) {
            AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
              AXU5EV_Motor_Control_Sy_IN_IDLE;
            AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 0.0;
            AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
            AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
            AXU5EV_Motor_Control_System_DW.Init_State_Num = 0.0;
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

      /* SignalConversion generated from: '<S18>/ SFunction ' incorporates:
       *  Chart: '<S17>/Angle_Init'
       */
      AXU5EV_Motor_Control_System_DW.Init_Done_p =
        AXU5EV_Motor_Control_System_DW.Init_Done;

      /* SignalConversion generated from: '<S18>/ SFunction ' incorporates:
       *  Chart: '<S17>/Angle_Init'
       */
      AXU5EV_Motor_Control_System_DW.Init_State_Num_a =
        AXU5EV_Motor_Control_System_DW.Init_State_Num;

      /* SignalConversion generated from: '<S18>/ SFunction ' incorporates:
       *  Chart: '<S17>/Angle_Init'
       */
      AXU5EV_Motor_Control_System_DW.id_init_ref_g =
        AXU5EV_Motor_Control_System_DW.id_init_ref;

      /* SignalConversion generated from: '<S18>/ SFunction ' incorporates:
       *  Chart: '<S17>/Angle_Init'
       */
      AXU5EV_Motor_Control_System_DW.Angle_Init_EN_d =
        AXU5EV_Motor_Control_System_DW.Angle_Init_EN;

      /* SignalConversion generated from: '<S18>/ SFunction ' incorporates:
       *  Chart: '<S17>/Angle_Init'
       */
      AXU5EV_Motor_Control_System_DW.Theta_Offset_auto_h =
        AXU5EV_Motor_Control_System_DW.Theta_Offset_auto;

      /* SignalConversion generated from: '<S18>/ SFunction ' incorporates:
       *  Chart: '<S17>/Angle_Init'
       */
      AXU5EV_Motor_Control_System_DW.x_align_mm_latch_b =
        AXU5EV_Motor_Control_System_DW.x_align_mm_latch;
    }

    /* End of Outputs for SubSystem: '<S14>/Enabled_Original_MIL' */

    /* Logic: '<S9>/Not_Alignment_Enable' incorporates:
     *  Logic: '<S9>/Alignment_Reset_Active'
     */
    rtb_Alignment_Ready = !(rtb_u_h[15] != 0.0);

    /* Logic: '<S9>/Init_Done_Or_Bypass' incorporates:
     *  Logic: '<S9>/Not_Alignment_Enable'
     */
    rtb_Init_Done_Or_Bypass = (rtb_Alignment_Ready ||
      (AXU5EV_Motor_Control_System_DW.Init_Done_p != 0.0));

    /* Logic: '<S9>/Alignment_Ready' incorporates:
     *  Logic: '<S9>/Alignment_Reset_Active'
     *  Logic: '<S9>/Not_Alignment_Fault'
     *  Logic: '<S9>/Not_Alignment_Reset'
     */
    rtb_Alignment_Ready = (!rtb_Alignment_Fault_Active &&
      rtb_Init_Done_Or_Bypass && (rtb_Alignment_Ready || !(rtb_u_h[17] != 0.0)));

    /* MATLAB Function: '<S9>/Host_Core' incorporates:
     *  Inport: '<Root>/CommandFrame'
     *  MATLAB Function: '<S2>/Bind_Real_Feedback'
     *  Outport: '<Root>/position_mm'
     *  Outport: '<Root>/speed_valid'
     */
    omega = rtb_u_h[3];
    q = rtb_u_h[4];
    Position_Loop_EN = rtb_u_h[5];
    Close_Loop_EN = rtb_u_h[6];
    i = ((AXU5EV_Motor_Control_System_U.CommandFrame[8] != 0.0) ||
         (rtb_Control_Fault || !AXU5EV_Motor_Control_System_Y.speed_valid));
    if (AXU5EV_Motor_Control_System_DW.move_state[0] == 0.0) {
      AXU5EV_Motor_Control_System_DW.move_state[0] = 1.0;
      AXU5EV_Motor_Control_System_DW.move_state[1] = rtb_u_h[10];
      AXU5EV_Motor_Control_System_DW.move_state[2] =
        AXU5EV_Motor_Control_System_Y.position_mm;
      AXU5EV_Motor_Control_System_DW.move_state[3] =
        AXU5EV_Motor_Control_System_Y.position_mm;
      AXU5EV_Motor_Control_System_DW.move_state[4] = rtb_Software_Time_s;
      AXU5EV_Motor_Control_System_DW.move_state[6] = 1.0;
      AXU5EV_Motor_Control_System_DW.move_state[13] = -1.0;
      AXU5EV_Motor_Control_System_DW.move_state[14] =
        AXU5EV_Motor_Control_System_Y.position_mm;
      AXU5EV_Motor_Control_System_DW.move_state[15] = rtb_Alignment_Ready;
    }

    rtb_Compare = ((rtb_u_h[5] != 0.0) && ((rtb_u_h[6] != 0.0) && (rtb_u_h[3] ==
      0.0)) && (rtb_u_h[7] != 0.0) && (i == 0) && rtb_Alignment_Ready);
    tick = floor(rtb_Software_Time_s / 0.0001 + 1.0E-7);
    new_tick = (tick != AXU5EV_Motor_Control_System_DW.move_state[13]);
    if (new_tick) {
      AXU5EV_Motor_Control_System_DW.move_state[13] = tick;
      if ((rtb_u_h[15] != 0.0) && rtb_Alignment_Ready &&
          (AXU5EV_Motor_Control_System_DW.move_state[15] == 0.0)) {
        AXU5EV_Motor_Control_System_DW.move_state[2] =
          AXU5EV_Motor_Control_System_Y.position_mm;
        AXU5EV_Motor_Control_System_DW.move_state[3] =
          AXU5EV_Motor_Control_System_Y.position_mm;
        AXU5EV_Motor_Control_System_DW.move_state[4] = rtb_Software_Time_s;
        AXU5EV_Motor_Control_System_DW.move_state[5] = 0.0;
        AXU5EV_Motor_Control_System_DW.move_state[6] = 1.0;
        AXU5EV_Motor_Control_System_DW.move_state[7] = 0.0;
        AXU5EV_Motor_Control_System_DW.move_state[8] = 0.0;
        AXU5EV_Motor_Control_System_DW.move_state[12] = 0.0;
        AXU5EV_Motor_Control_System_DW.move_state[14] =
          AXU5EV_Motor_Control_System_Y.position_mm;
      }

      AXU5EV_Motor_Control_System_DW.move_state[15] = rtb_Alignment_Ready;
      if ((AXU5EV_Motor_Control_System_DW.move_state[5] != 0.0) && ((rtb_u_h[7] ==
            0.0) || (i != 0))) {
        AXU5EV_Motor_Control_System_DW.move_state[5] = 0.0;
        AXU5EV_Motor_Control_System_DW.move_state[6] = 0.0;
        AXU5EV_Motor_Control_System_DW.move_state[7] = 0.0;
        AXU5EV_Motor_Control_System_DW.move_state[8] = 0.0;
        AXU5EV_Motor_Control_System_DW.move_state[12] = 1.0;
        AXU5EV_Motor_Control_System_DW.move_state[9] = 7.0;
      }
    }

    if (AXU5EV_Motor_Control_System_DW.move_state[12] != 0.0) {
      target = AXU5EV_Motor_Control_System_DW.move_state[14];
    } else {
      t = rtb_Software_Time_s - AXU5EV_Motor_Control_System_DW.move_state[4];
      target = AXU5EV_Motor_Control_System_DW.move_state[3] -
        AXU5EV_Motor_Control_System_DW.move_state[2];
      D = fabs(target);
      s = 0.0;
      rtb_UnitDelay = 0.0;
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
        rtb_UnitDelay = 2.0 * Ta + Tc;
        if (!(t <= 0.0)) {
          if (t < Ta) {
            s = t / Ta;
            s = ((2.5 * rt_powd_snf(s, 4.0) - 3.0 * rt_powd_snf(s, 5.0)) +
                 rt_powd_snf(s, 6.0)) * (V * Ta);
          } else if (t < Ta + Tc) {
            s = V * Ta / 2.0 + (t - Ta) * V;
          } else if (t < rtb_UnitDelay) {
            s = ((t - Ta) - Tc) / Ta;
            Ta *= V;
            s = (((s - 2.5 * rt_powd_snf(s, 4.0)) + 3.0 * rt_powd_snf(s, 5.0)) -
                 rt_powd_snf(s, 6.0)) * Ta + (Ta / 2.0 + V * Tc);
          } else {
            s = D;
          }

          if (rtIsNaN(target)) {
            V = (rtNaN);
          } else if (target < 0.0) {
            V = -1.0;
          } else {
            V = (target > 0.0);
          }

          s *= V;
        }
      }

      target = AXU5EV_Motor_Control_System_DW.move_state[2] + s;
      AXU5EV_Motor_Control_System_DW.move_state[17] = rtb_UnitDelay;
      AXU5EV_Motor_Control_System_DW.move_state[6] = (rtb_Software_Time_s -
        AXU5EV_Motor_Control_System_DW.move_state[4] >= rtb_UnitDelay);
    }

    if ((AXU5EV_Motor_Control_System_mod(tick, 100.0) == 99.0) && (tick + 1.0 !=
         AXU5EV_Motor_Control_System_DW.move_state[21])) {
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
    if (new_tick && (!(AXU5EV_Motor_Control_System_DW.move_state[1] == rtb_u_h
                       [10]) && (!rtIsNaN(rtb_u_h[10]) || !rtIsNaN
          (AXU5EV_Motor_Control_System_DW.move_state[1])))) {
      AXU5EV_Motor_Control_System_DW.move_state[1] = rtb_u_h[10];
      AXU5EV_Motor_Control_System_DW.move_state[18] = rtb_Software_Time_s;
      if (rtIsInf(rtb_u_h[0]) || rtIsNaN(rtb_u_h[0]) || (rtIsInf(rtb_u_h[10]) ||
           rtIsNaN(rtb_u_h[10])) || ((rtb_u_h[10] != 0.0) && (rtb_u_h[10] != 1.0)))
      {
        AXU5EV_Motor_Control_System_DW.move_state[9] = 4.0;
        AXU5EV_Motor_Control_System_DW.move_state[11]++;
      } else if (!rtb_Compare) {
        AXU5EV_Motor_Control_System_DW.move_state[9] = 6.0;
        AXU5EV_Motor_Control_System_DW.move_state[11]++;
      } else if (!rtb_LogicalOperator) {
        AXU5EV_Motor_Control_System_DW.move_state[9] = 3.0;
        AXU5EV_Motor_Control_System_DW.move_state[11]++;
      } else if (fabs(rtb_u_h[0] - AXU5EV_Motor_Control_System_DW.move_state[3])
                 <= 1.0E-12) {
        AXU5EV_Motor_Control_System_DW.move_state[9] = 5.0;
      } else {
        AXU5EV_Motor_Control_System_DW.move_state[2] =
          AXU5EV_Motor_Control_System_DW.move_state[3];
        AXU5EV_Motor_Control_System_DW.move_state[3] = rtb_u_h[0];
        AXU5EV_Motor_Control_System_DW.move_state[4] = rtb_Software_Time_s;
        AXU5EV_Motor_Control_System_DW.move_state[5] = 1.0;
        AXU5EV_Motor_Control_System_DW.move_state[6] = 0.0;
        AXU5EV_Motor_Control_System_DW.move_state[7] = 0.0;
        AXU5EV_Motor_Control_System_DW.move_state[8] = 0.0;
        AXU5EV_Motor_Control_System_DW.move_state[9] = 2.0;
        AXU5EV_Motor_Control_System_DW.move_state[10]++;
        AXU5EV_Motor_Control_System_DW.move_state[18] = rtb_Software_Time_s;
        AXU5EV_Motor_Control_System_DW.move_state[19]++;
        AXU5EV_Motor_Control_System_DW.move_state[20] = 0.0;
        target = AXU5EV_Motor_Control_System_DW.move_state[2];
      }
    }

    AXU5EV_Motor_Control_System_DW.move_state[14] = target;
    if ((rtb_u_h[15] != 0.0) && !rtb_Alignment_Ready) {
      Position_Loop_EN = 0.0;
      Close_Loop_EN = 0.0;
      omega = 1.0;
      q = 0.0;
    }

    /* RelationalOperator: '<S26>/Compare' incorporates:
     *  Constant: '<S21>/Constant1'
     *  Constant: '<S26>/Constant'
     *  Sum: '<S21>/Add1'
     *  UnitDelay: '<S21>/spd_cnt_z'
     */
    rtb_Compare = (AXU5EV_Motor_Control_System_DW.spd_cnt_z_DSTATE + 1.0 >= 10.0);

    /* RelationalOperator: '<S25>/Compare' incorporates:
     *  Constant: '<S21>/Constant3'
     *  Constant: '<S25>/Constant'
     *  Sum: '<S21>/Add2'
     *  UnitDelay: '<S21>/pos_cnt_z'
     */
    new_tick = (AXU5EV_Motor_Control_System_DW.pos_cnt_z_DSTATE + 1.0 >= 10.0);

    /* Logic: '<S21>/Logical Operator' */
    rtb_LogicalOperator = (rtb_Compare && new_tick);

    /* Outputs for Triggered SubSystem: '<S16>/Position_Loop' incorporates:
     *  TriggerPort: '<S19>/Trigger'
     */
    if (rtb_LogicalOperator &&
        (AXU5EV_Motor_Control_Sy_PrevZCX.Position_Loop_Trig_ZCE != POS_ZCSIG)) {
      /* Sum: '<S19>/Sum' incorporates:
       *  MATLAB Function: '<S2>/Bind_Real_Feedback'
       *  MATLAB Function: '<S9>/Host_Core'
       *  Outport: '<Root>/position_mm'
       */
      rtb_Software_Time_s = target - AXU5EV_Motor_Control_System_Y.position_mm;

      /* DeadZone: '<S19>/Dead Zone' */
      if (rtb_Software_Time_s > 0.02) {
        V = rtb_Software_Time_s - 0.02;
      } else if (rtb_Software_Time_s >= -0.02) {
        V = 0.0;
      } else {
        V = rtb_Software_Time_s - -0.02;
      }

      /* Gain: '<S19>/Gain' incorporates:
       *  DeadZone: '<S19>/Dead Zone'
       */
      AXU5EV_Motor_Control_System_DW.obs_v_ref_pos = 5.0 * V;

      /* Saturate: '<S19>/Saturation' */
      if (AXU5EV_Motor_Control_System_DW.obs_v_ref_pos > 20.0) {
        /* Gain: '<S19>/Gain' incorporates:
         *  Saturate: '<S19>/Saturation'
         */
        AXU5EV_Motor_Control_System_DW.obs_v_ref_pos = 20.0;
      } else if (AXU5EV_Motor_Control_System_DW.obs_v_ref_pos < -20.0) {
        /* Gain: '<S19>/Gain' incorporates:
         *  Saturate: '<S19>/Saturation'
         */
        AXU5EV_Motor_Control_System_DW.obs_v_ref_pos = -20.0;
      }

      /* End of Saturate: '<S19>/Saturation' */
    }

    AXU5EV_Motor_Control_Sy_PrevZCX.Position_Loop_Trig_ZCE = rtb_LogicalOperator;

    /* End of Outputs for SubSystem: '<S16>/Position_Loop' */

    /* Switch: '<S20>/v_ref_closed_sel' incorporates:
     *  MATLAB Function: '<S9>/Host_Core'
     */
    if (Position_Loop_EN > 0.5) {
      V = AXU5EV_Motor_Control_System_DW.obs_v_ref_pos;
    } else {
      V = rtb_u_h[1];
    }

    /* Sum: '<S24>/Subtract' incorporates:
     *  Switch: '<S20>/v_ref_closed_sel'
     *  UnitDelay: '<S24>/v_ref_set_lim_z'
     */
    rtb_Software_Time_s = V -
      AXU5EV_Motor_Control_System_DW.v_ref_set_lim_z_DSTATE;

    /* Saturate: '<S24>/Saturation' */
    if (rtb_Software_Time_s > 0.01) {
      rtb_Software_Time_s = 0.01;
    } else if (rtb_Software_Time_s < -0.01) {
      rtb_Software_Time_s = -0.01;
    }

    /* Sum: '<S24>/Add' incorporates:
     *  Saturate: '<S24>/Saturation'
     *  UnitDelay: '<S24>/v_ref_set_lim_z'
     */
    AXU5EV_Motor_Control_System_DW.v_ref_set_lim_z_DSTATE += rtb_Software_Time_s;

    /* Switch: '<S16>/MIL_Init_Done_Vref_Gate' incorporates:
     *  Constant: '<S16>/Alignment_Zero'
     */
    if (rtb_Init_Done_Or_Bypass) {
      /* Switch: '<S20>/Switch9' incorporates:
       *  Constant: '<S20>/Constant15'
       *  MATLAB Function: '<S9>/Host_Core'
       */
      if (Close_Loop_EN > 0.5) {
        /* Saturate: '<S20>/Saturation' incorporates:
         *  UnitDelay: '<S24>/v_ref_set_lim_z'
         */
        if (AXU5EV_Motor_Control_System_DW.v_ref_set_lim_z_DSTATE > 20.0) {
          rtb_Software_Time_s = 20.0;
        } else if (AXU5EV_Motor_Control_System_DW.v_ref_set_lim_z_DSTATE < -20.0)
        {
          rtb_Software_Time_s = -20.0;
        } else {
          rtb_Software_Time_s =
            AXU5EV_Motor_Control_System_DW.v_ref_set_lim_z_DSTATE;
        }

        /* End of Saturate: '<S20>/Saturation' */
      } else {
        rtb_Software_Time_s = 0.0;
      }

      /* End of Switch: '<S20>/Switch9' */
    } else {
      rtb_Software_Time_s = 0.0;
    }

    /* End of Switch: '<S16>/MIL_Init_Done_Vref_Gate' */

    /* Switch: '<S16>/Explicit_Travel_Fault_Clear' incorporates:
     *  Constant: '<S16>/Cleared_Travel_Fault'
     *  MATLAB Function: '<S2>/Frame_And_Fault_Qualification'
     */
    if (rtb_System_Fault_Not) {
      AXU5EV_Motor_Control_System_DW.Travel_Fault_State_DSTATE = 0.0;
    }

    /* MATLAB Function: '<S16>/Travel_Safety_Manager' incorporates:
     *  Constant: '<S16>/X_max_soft'
     *  Constant: '<S16>/X_min_soft'
     *  MATLAB Function: '<S2>/Bind_Real_Feedback'
     *  Outport: '<Root>/position_mm'
     *  Switch: '<S16>/Explicit_Travel_Fault_Clear'
     */
    rtb_LogicalOperator3 =
      ((AXU5EV_Motor_Control_System_DW.Travel_Fault_State_DSTATE > 0.5) ||
       rtb_LogicalOperator3);
    if (rtb_LogicalOperator3) {
      rtb_Software_Time_s = 0.0;
    } else if (((AXU5EV_Motor_Control_System_Y.position_mm >= 110.0) &&
                (rtb_Software_Time_s > 0.0)) ||
               ((AXU5EV_Motor_Control_System_Y.position_mm <= -110.0) &&
                (rtb_Software_Time_s < -0.0))) {
      rtb_Software_Time_s = 0.0;
    }

    /* Switch: '<S16>/Explicit_Travel_Fault_Clear' incorporates:
     *  MATLAB Function: '<S16>/Travel_Safety_Manager'
     *  UnitDelay: '<S16>/Travel_Fault_State'
     */
    AXU5EV_Motor_Control_System_DW.Travel_Fault_State_DSTATE =
      rtb_LogicalOperator3;

    /* Outputs for Triggered SubSystem: '<S16>/Speed_Loop' incorporates:
     *  TriggerPort: '<S22>/Trigger'
     */
    if (rtb_Compare && (AXU5EV_Motor_Control_Sy_PrevZCX.Speed_Loop_Trig_ZCE !=
                        POS_ZCSIG)) {
      /* Sum: '<S22>/Sum' incorporates:
       *  MATLAB Function: '<S2>/Bind_Real_Feedback'
       *  Outport: '<Root>/speed_mm_s'
       */
      tick = rtb_Software_Time_s - AXU5EV_Motor_Control_System_Y.speed_mm_s;

      /* Sum: '<S22>/Add1' incorporates:
       *  Gain: '<S22>/  '
       *  UnitDelay: '<S22>/x_s_z'
       */
      V = 0.03 * tick + AXU5EV_Motor_Control_System_DW.x_s_z_DSTATE;

      /* UnitDelay: '<S22>/Unit Delay' */
      rtb_UnitDelay = AXU5EV_Motor_Control_System_DW.UnitDelay_DSTATE;

      /* Logic: '<S27>/Logical Operator3' incorporates:
       *  Logic: '<S27>/Logical Operator2'
       *  Logic: '<S9>/Effective_PI_Reset'
       *  Logic: '<S9>/PWM_Not_Requested'
       *  MATLAB Function: '<S9>/Host_Core'
       */
      rtb_LogicalOperator3 = ((AXU5EV_Motor_Control_System_DW.Angle_Init_EN_d !=
        0.0) || ((i != 0) || !(rtb_u_h[7] != 0.0) || rtb_Alignment_Fault_Active)
        || (omega != 0.0) || !(Close_Loop_EN != 0.0));

      /* Saturate: '<S22>/Saturation1' */
      if (V > 0.3) {
        Tc = 0.3;
      } else if (V < -0.3) {
        Tc = -0.3;
      } else {
        Tc = V;
      }

      /* End of Saturate: '<S22>/Saturation1' */

      /* Switch: '<S22>/PI_Reset_Output' */
      if (rtb_LogicalOperator3) {
        /* Switch: '<S22>/PI_Reset_Output' incorporates:
         *  Constant: '<S22>/Constant4'
         */
        AXU5EV_Motor_Control_System_DW.PI_Reset_Output = 0.0;
      } else {
        /* Switch: '<S22>/PI_Reset_Output' */
        AXU5EV_Motor_Control_System_DW.PI_Reset_Output = Tc;
      }

      /* End of Switch: '<S22>/PI_Reset_Output' */

      /* Sum: '<S22>/Subtract' incorporates:
       *  UnitDelay: '<S22>/Unit Delay'
       */
      AXU5EV_Motor_Control_System_DW.UnitDelay_DSTATE = V - Tc;

      /* Signum: '<S27>/Sign' */
      if (rtIsNaN(rtb_Software_Time_s)) {
        V = (rtNaN);
      } else if (rtb_Software_Time_s < 0.0) {
        V = -1.0;
      } else {
        V = (rtb_Software_Time_s > 0.0);
      }

      /* Switch: '<S22>/Switch1' incorporates:
       *  Abs: '<S22>/Abs'
       *  Constant: '<S28>/Constant'
       *  Constant: '<S30>/Constant'
       *  Logic: '<S27>/Logical Operator'
       *  Logic: '<S27>/Logical Operator1'
       *  Product: '<S27>/Product2'
       *  RelationalOperator: '<S28>/Compare'
       *  RelationalOperator: '<S30>/Compare'
       *  Signum: '<S27>/Sign'
       */
      if (rtb_LogicalOperator3 || ((fabs(rtb_Software_Time_s) > 0.5) && (V *
            tick < -3.0))) {
        /* Sum: '<S22>/Add2' incorporates:
         *  Constant: '<S22>/Constant1'
         *  UnitDelay: '<S22>/x_s_z'
         */
        AXU5EV_Motor_Control_System_DW.x_s_z_DSTATE = 0.0;
      } else {
        /* Sum: '<S22>/Add2' incorporates:
         *  Gain: '<S22>/ '
         *  Gain: '<S22>/Gain'
         *  UnitDelay: '<S22>/x_s_z'
         */
        AXU5EV_Motor_Control_System_DW.x_s_z_DSTATE = (5.0E-5 * tick +
          AXU5EV_Motor_Control_System_DW.x_s_z_DSTATE) - 0.4 * rtb_UnitDelay;

        /* Saturate: '<S22>/Saturation' */
        if (AXU5EV_Motor_Control_System_DW.x_s_z_DSTATE > 0.2) {
          /* Sum: '<S22>/Add2' */
          AXU5EV_Motor_Control_System_DW.x_s_z_DSTATE = 0.2;
        } else if (AXU5EV_Motor_Control_System_DW.x_s_z_DSTATE < -0.2) {
          /* Sum: '<S22>/Add2' */
          AXU5EV_Motor_Control_System_DW.x_s_z_DSTATE = -0.2;
        }

        /* End of Saturate: '<S22>/Saturation' */
      }

      /* End of Switch: '<S22>/Switch1' */
    }

    AXU5EV_Motor_Control_Sy_PrevZCX.Speed_Loop_Trig_ZCE = rtb_Compare;

    /* End of Outputs for SubSystem: '<S16>/Speed_Loop' */

    /* Switch: '<S16>/MIL_Fault_Id_Zero' incorporates:
     *  Switch: '<S16>/MIL_Align_Id_Select'
     *  Switch: '<S16>/MIL_Align_Iq_Zero'
     *  Switch: '<S16>/MIL_Fault_Iq_Zero'
     */
    if (rtb_Alignment_Fault_Active) {
      /* Outport: '<Root>/runtime_frame' incorporates:
       *  Constant: '<S16>/Alignment_Zero'
       */
      AXU5EV_Motor_Control_System_Y.runtime_frame[0] = 0.0;
      AXU5EV_Motor_Control_System_Y.runtime_frame[1] = 0.0;
    } else if (AXU5EV_Motor_Control_System_DW.Angle_Init_EN_d > 0.5) {
      /* Outport: '<Root>/runtime_frame' incorporates:
       *  Constant: '<S16>/Alignment_Zero'
       *  Switch: '<S16>/MIL_Align_Id_Select'
       *  Switch: '<S16>/MIL_Align_Iq_Zero'
       */
      AXU5EV_Motor_Control_System_Y.runtime_frame[0] =
        AXU5EV_Motor_Control_System_DW.id_init_ref_g;
      AXU5EV_Motor_Control_System_Y.runtime_frame[1] = 0.0;
    } else {
      /* Outport: '<Root>/runtime_frame' incorporates:
       *  MATLAB Function: '<S9>/Host_Core'
       */
      AXU5EV_Motor_Control_System_Y.runtime_frame[0] = rtb_u_h[2];

      /* Switch: '<S20>/Switch' incorporates:
       *  MATLAB Function: '<S9>/Host_Core'
       *  Switch: '<S16>/MIL_Align_Iq_Zero'
       */
      if (omega > 0.5) {
        /* Outport: '<Root>/runtime_frame' */
        AXU5EV_Motor_Control_System_Y.runtime_frame[1] = q;
      } else {
        /* Outport: '<Root>/runtime_frame' */
        AXU5EV_Motor_Control_System_Y.runtime_frame[1] =
          AXU5EV_Motor_Control_System_DW.PI_Reset_Output;
      }

      /* End of Switch: '<S20>/Switch' */
    }

    /* End of Switch: '<S16>/MIL_Fault_Id_Zero' */

    /* Switch: '<S21>/pos_cnt_hold_sel' incorporates:
     *  Constant: '<S21>/Constant1'
     *  Constant: '<S21>/Constant2'
     *  Sum: '<S21>/Add1'
     *  Switch: '<S21>/spd_cnt_next_sel'
     *  UnitDelay: '<S21>/spd_cnt_z'
     */
    if (rtb_Compare) {
      /* Switch: '<S21>/pos_cnt_update_sel' incorporates:
       *  Constant: '<S21>/Constant3'
       *  Constant: '<S21>/Constant4'
       *  Sum: '<S21>/Add2'
       *  UnitDelay: '<S21>/pos_cnt_z'
       */
      if (new_tick) {
        AXU5EV_Motor_Control_System_DW.pos_cnt_z_DSTATE = 0.0;
      } else {
        AXU5EV_Motor_Control_System_DW.pos_cnt_z_DSTATE++;
      }

      /* End of Switch: '<S21>/pos_cnt_update_sel' */
      AXU5EV_Motor_Control_System_DW.spd_cnt_z_DSTATE = 0.0;
    } else {
      AXU5EV_Motor_Control_System_DW.spd_cnt_z_DSTATE++;
    }

    /* End of Switch: '<S21>/pos_cnt_hold_sel' */

    /* Sum: '<S9>/Next_Tick' incorporates:
     *  Constant: '<S9>/One_Tick'
     *  UnitDelay: '<S9>/Software_Tick'
     */
    AXU5EV_Motor_Control_System_DW.Software_Tick_DSTATE++;

    /* Outport: '<Root>/runtime_frame' incorporates:
     *  DataTypeConversion: '<S9>/Status_Double_10'
     *  DataTypeConversion: '<S9>/Status_Double_11'
     *  DataTypeConversion: '<S9>/Status_Double_12'
     *  MATLAB Function: '<S9>/Host_Core'
     *  SignalConversion generated from: '<S9>/runtime_y'
     */
    AXU5EV_Motor_Control_System_Y.runtime_frame[2] = rtb_Software_Time_s;
    AXU5EV_Motor_Control_System_Y.runtime_frame[3] =
      AXU5EV_Motor_Control_System_DW.Init_Done_p;
    AXU5EV_Motor_Control_System_Y.runtime_frame[4] =
      AXU5EV_Motor_Control_System_DW.Init_State_Num_a;
    AXU5EV_Motor_Control_System_Y.runtime_frame[5] =
      AXU5EV_Motor_Control_System_DW.id_init_ref_g;
    AXU5EV_Motor_Control_System_Y.runtime_frame[6] =
      AXU5EV_Motor_Control_System_DW.Angle_Init_EN_d;
    AXU5EV_Motor_Control_System_Y.runtime_frame[7] =
      AXU5EV_Motor_Control_System_DW.Theta_Offset_auto_h;
    AXU5EV_Motor_Control_System_Y.runtime_frame[8] =
      AXU5EV_Motor_Control_System_DW.x_align_mm_latch_b;
    AXU5EV_Motor_Control_System_Y.runtime_frame[9] = rtb_Alignment_Ready;
    AXU5EV_Motor_Control_System_Y.runtime_frame[10] = rtb_Init_Done_Or_Bypass;
    AXU5EV_Motor_Control_System_Y.runtime_frame[11] = rtb_Alignment_Fault_Active;
    AXU5EV_Motor_Control_System_Y.runtime_frame[12] = target;
    AXU5EV_Motor_Control_System_Y.runtime_frame[13] = 48.0;
    AXU5EV_Motor_Control_System_Y.runtime_frame[14] = 0.0;
    AXU5EV_Motor_Control_System_Y.runtime_frame[15] = Close_Loop_EN;
    AXU5EV_Motor_Control_System_Y.runtime_frame[16] = Position_Loop_EN;
    AXU5EV_Motor_Control_System_Y.runtime_frame[17] = rtb_u_h[7];
    AXU5EV_Motor_Control_System_Y.runtime_frame[18] = rtb_u_h[1];
    AXU5EV_Motor_Control_System_Y.runtime_frame[19] = rtb_u_h[2];
    AXU5EV_Motor_Control_System_Y.runtime_frame[20] = omega;
    AXU5EV_Motor_Control_System_Y.runtime_frame[21] = q;
    AXU5EV_Motor_Control_System_Y.runtime_frame[22] = i;
    AXU5EV_Motor_Control_System_Y.runtime_frame[23] =
      AXU5EV_Motor_Control_System_DW.move_state[3];
    AXU5EV_Motor_Control_System_Y.runtime_frame[24] =
      AXU5EV_Motor_Control_System_DW.move_state[5];
    AXU5EV_Motor_Control_System_Y.runtime_frame[25] =
      AXU5EV_Motor_Control_System_DW.move_state[7];
    AXU5EV_Motor_Control_System_Y.runtime_frame[26] =
      AXU5EV_Motor_Control_System_DW.move_state[9];
    AXU5EV_Motor_Control_System_Y.runtime_frame[27] =
      AXU5EV_Motor_Control_System_DW.move_state[2];
    AXU5EV_Motor_Control_System_Y.runtime_frame[28] =
      AXU5EV_Motor_Control_System_DW.move_state[4];
    AXU5EV_Motor_Control_System_Y.runtime_frame[29] =
      AXU5EV_Motor_Control_System_DW.move_state[6];
    AXU5EV_Motor_Control_System_Y.runtime_frame[30] =
      AXU5EV_Motor_Control_System_DW.move_state[20];
    AXU5EV_Motor_Control_System_Y.runtime_frame[31] =
      AXU5EV_Motor_Control_System_DW.move_state[10];
    AXU5EV_Motor_Control_System_Y.runtime_frame[32] =
      AXU5EV_Motor_Control_System_DW.move_state[11];
    AXU5EV_Motor_Control_System_Y.runtime_frame[33] =
      AXU5EV_Motor_Control_System_DW.move_state[19];
    AXU5EV_Motor_Control_System_Y.runtime_frame[34] =
      AXU5EV_Motor_Control_System_DW.move_state[18];
    AXU5EV_Motor_Control_System_Y.runtime_frame[35] =
      AXU5EV_Motor_Control_System_DW.move_state[12];
    AXU5EV_Motor_Control_System_Y.runtime_frame[36] = 20.0;
    AXU5EV_Motor_Control_System_Y.runtime_frame[37] = 200.0;
    AXU5EV_Motor_Control_System_Y.runtime_frame[38] = 1000.0;
    AXU5EV_Motor_Control_System_Y.runtime_frame[39] = 0.2;
    AXU5EV_Motor_Control_System_Y.runtime_frame[40] = 0.0001;
    if (AXU5EV_Motor_Control_System_DW.version == UINT32_MAX) {
      AXU5EV_Motor_Control_System_DW.version = 0U;
    } else {
      AXU5EV_Motor_Control_System_DW.version++;
    }

    AXU5EV_Motor_Control_System_DW.last_id =
      AXU5EV_Motor_Control_System_U.sample_id;
  }

  /* End of Outputs for SubSystem: '<S2>/Qualified_Runtime' */

  /* SignalConversion generated from: '<S2>/request_freset' incorporates:
   *  Inport: '<Root>/request_freset'
   *  Logic: '<S6>/Outside_Driver_Reset'
   *  MATLAB Function: '<S2>/Frame_And_Fault_Qualification'
   *  MATLAB Function: '<S2>/Reference_Commit'
   */
  rtb_Alignment_Ready = !AXU5EV_Motor_Control_System_U.request_freset;

  /* Logic: '<S6>/Reset_Or_System_Inhibit' incorporates:
   *  MATLAB Function: '<S2>/Frame_And_Fault_Qualification'
   */
  rtb_Compare = !AXU5EV_Motor_Control_System_DW.fault;

  /* Logic: '<S6>/System_Fault_Not' incorporates:
   *  Logic: '<S6>/Reset_Or_System_Inhibit'
   *  SignalConversion generated from: '<S2>/request_freset'
   */
  rtb_System_Fault_Not = (rtb_Compare && rtb_Alignment_Ready);

  /* Logic: '<S6>/RELCON_Safe_Enable' incorporates:
   *  Inport: '<Root>/request_relcon'
   */
  rtb_LogicalOperator3 = (AXU5EV_Motor_Control_System_U.request_relcon &&
    rtb_System_Fault_Not);

  /* Logic: '<S6>/ENCON_Safe_Enable' incorporates:
   *  Inport: '<Root>/request_encon'
   */
  rtb_System_Fault_Not = (AXU5EV_Motor_Control_System_U.request_encon &&
    rtb_System_Fault_Not);

  /* Logic: '<S6>/Logical Operator' incorporates:
   *  Inport: '<Root>/request_oe_disable'
   *  Logic: '<S6>/Fault_OE_Inhibit_Outside_Reset'
   *  MATLAB Function: '<S2>/Frame_And_Fault_Qualification'
   */
  rtb_Alignment_Fault_Active = (AXU5EV_Motor_Control_System_U.request_oe_disable
    || (AXU5EV_Motor_Control_System_DW.fault && rtb_Alignment_Ready));

  /* MATLAB Function: '<S2>/Reference_Commit' incorporates:
   *  Inport: '<Root>/current_valid'
   *  MATLAB Function: '<S2>/Frame_And_Fault_Qualification'
   *  Outport: '<Root>/runtime_frame'
   *  Outport: '<Root>/speed_valid'
   *  UnitDelay: '<S16>/Travel_Fault_State'
   */
  for (i = 0; i < 41; i++) {
    b_0[i] = !rtIsInf(AXU5EV_Motor_Control_System_Y.runtime_frame[i]);
    c_0[i] = !rtIsNaN(AXU5EV_Motor_Control_System_Y.runtime_frame[i]);
  }

  rtb_Init_Done_Or_Bypass = true;
  i = 0;
  while (i < 41) {
    if (!b_0[i] || !c_0[i]) {
      rtb_Init_Done_Or_Bypass = false;
      break;
    } else {
      i++;
    }
  }

  rtb_restart_history = (rtb_restart_history && (rtb_restart_history &&
    rtb_Compare && clear_allowed_tmp && clear_allowed_tmp_0 &&
    AXU5EV_Motor_Control_System_U.current_valid && command_valid &&
    rtb_Alignment_Ready) && AXU5EV_Motor_Control_System_Y.speed_valid &&
    !AXU5EV_Motor_Control_System_DW.External_Fault_Latch_Z_DSTATE &&
    (AXU5EV_Motor_Control_System_DW.Travel_Fault_State_DSTATE <= 0.5) &&
    rtb_Init_Done_Or_Bypass);
  clear_allowed_tmp = (rtb_restart_history &&
                       ((AXU5EV_Motor_Control_System_Y.runtime_frame[17] != 0.0)
                        && (rtb_LogicalOperator3 && rtb_System_Fault_Not &&
    !rtb_Alignment_Fault_Active && rtb_Alignment_Ready)));

  /* Outport: '<Root>/reference_commit' incorporates:
   *  Constant: '<S2>/Alignment_Id_Limit_A'
   *  Constant: '<S2>/Debug_Iq_Limit_A'
   *  MATLAB Function: '<S2>/Reference_Commit'
   *  Outport: '<Root>/runtime_frame'
   */
  AXU5EV_Motor_Control_System_Y.reference_commit[0] = fmin(0.5, fmax(-0.5,
    AXU5EV_Motor_Control_System_Y.runtime_frame[0]));
  AXU5EV_Motor_Control_System_Y.reference_commit[1] = fmin(0.3, fmax(-0.3,
    AXU5EV_Motor_Control_System_Y.runtime_frame[1]));

  /* MATLAB Function: '<S2>/Reference_Commit' incorporates:
   *  Constant: '<S2>/Electrical_Period_mm'
   *  Outport: '<Root>/speed_mm_s'
   *  Outport: '<Root>/speed_valid'
   */
  command_valid = !rtb_restart_history;
  if (command_valid) {
    /* Outport: '<Root>/reference_commit' */
    AXU5EV_Motor_Control_System_Y.reference_commit[0] = 0.0;
    AXU5EV_Motor_Control_System_Y.reference_commit[1] = 0.0;
  }

  omega = AXU5EV_Motor_Control_System_Y.speed_mm_s * 0.20943951023931953;
  if (!AXU5EV_Motor_Control_System_Y.speed_valid) {
    omega = 0.0;
  } else if (rtIsInf(omega) || rtIsNaN(omega)) {
    omega = 0.0;
  }

  /* Outport: '<Root>/reference_commit' incorporates:
   *  MATLAB Function: '<S2>/Reference_Commit'
   *  Outport: '<Root>/runtime_frame'
   */
  AXU5EV_Motor_Control_System_Y.reference_commit[3] =
    AXU5EV_Motor_Control_System_Y.runtime_frame[7];
  AXU5EV_Motor_Control_System_Y.reference_commit[4] =
    AXU5EV_Motor_Control_System_Y.runtime_frame[6];

  /* MATLAB Function: '<S2>/Reference_Commit' */
  if (!rtb_Init_Done_Or_Bypass) {
    /* Outport: '<Root>/reference_commit' */
    AXU5EV_Motor_Control_System_Y.reference_commit[3] = 0.0;
    AXU5EV_Motor_Control_System_Y.reference_commit[4] = 0.0;
  }

  /* Outport: '<Root>/reference_commit' incorporates:
   *  MATLAB Function: '<S2>/Reference_Commit'
   *  Outport: '<Root>/runtime_frame'
   */
  AXU5EV_Motor_Control_System_Y.reference_commit[2] = omega;
  AXU5EV_Motor_Control_System_Y.reference_commit[5] = clear_allowed_tmp;
  AXU5EV_Motor_Control_System_Y.reference_commit[6] =
    ((AXU5EV_Motor_Control_System_Y.runtime_frame[22] != 0.0) ||
     (!clear_allowed_tmp || command_valid));
  AXU5EV_Motor_Control_System_Y.reference_commit[7] = rtb_restart_history;

  /* Outport: '<Root>/commit_sample_id' incorporates:
   *  MATLAB Function: '<S2>/Reference_Commit'
   */
  AXU5EV_Motor_Control_System_Y.commit_sample_id =
    AXU5EV_Motor_Control_System_DW.last_id;

  /* Outport: '<Root>/reference_version' incorporates:
   *  MATLAB Function: '<S2>/Reference_Commit'
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

  /* Update for UnitDelay: '<S7>/Position_Hold' incorporates:
   *  Outport: '<Root>/position_mm'
   */
  AXU5EV_Motor_Control_System_DW.Position_Hold_DSTATE =
    AXU5EV_Motor_Control_System_Y.position_mm;

  /* Update for Delay: '<S7>/Delay_50_Intervals' incorporates:
   *  Sum: '<S7>/Continuous_Position_Count'
   */
  if (advance) {
    AXU5EV_Motor_Control_System_DW.icLoad = false;
    for (i = 0; i < 49; i++) {
      AXU5EV_Motor_Control_System_DW.Delay_50_Intervals_DSTATE[i] =
        AXU5EV_Motor_Control_System_DW.Delay_50_Intervals_DSTATE[i + 1];
    }

    AXU5EV_Motor_Control_System_DW.Delay_50_Intervals_DSTATE[49] = delta;
  }

  /* End of Update for Delay: '<S7>/Delay_50_Intervals' */

  /* End of Outputs for RootInportFunctionCallGenerator generated from: '<Root>/PL_Frame_IRQ' */

  /* Outport: '<Root>/drive_outputs' incorporates:
   *  Inport: '<Root>/request_freset'
   */
  AXU5EV_Motor_Control_System_Y.drive_outputs[0] = rtb_LogicalOperator3;
  AXU5EV_Motor_Control_System_Y.drive_outputs[1] = rtb_System_Fault_Not;
  AXU5EV_Motor_Control_System_Y.drive_outputs[2] =
    AXU5EV_Motor_Control_System_U.request_freset;
  AXU5EV_Motor_Control_System_Y.drive_outputs[3] = rtb_Alignment_Fault_Active;
  AXU5EV_Motor_Control_System_Y.drive_outputs[4] =
    AXU5EV_Motor_Control_System_DW.External_Fault_Latch_Z_DSTATE;
}

/* Model step function */
void Service_Request(void)
{
  /* RootInportFunctionCallGenerator generated from: '<Root>/Service_Request' incorporates:
   *  SubSystem: '<Root>/NonRealtime_Service'
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
    AXU5EV_Motor_Control_System_DW.Init_Done_p = 0.0;
    AXU5EV_Motor_Control_System_DW.Init_State_Num_a = 0.0;
    AXU5EV_Motor_Control_System_DW.id_init_ref_g = 0.0;
    AXU5EV_Motor_Control_System_DW.Angle_Init_EN_d = 0.0;
    AXU5EV_Motor_Control_System_DW.Theta_Offset_auto_h = 0.0;
    AXU5EV_Motor_Control_System_DW.x_align_mm_latch_b = 0.0;
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
   */
  /* Start for Delay: '<S7>/Delay_50_Intervals' */
  AXU5EV_Motor_Control_System_DW.Delay_50_Intervals = INT64_C(0);

  /* InitializeConditions for Delay: '<S7>/Delay_50_Intervals' */
  AXU5EV_Motor_Control_System_DW.icLoad = true;

  /* SystemInitialize for MATLAB Function: '<S7>/Frame_And_Count_Guard' */
  AXU5EV_Motor_Control_System_DW.initialized = false;
  AXU5EV_Motor_Control_System_DW.last_raw = 0U;
  AXU5EV_Motor_Control_System_DW.last_id_l = 0U;
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
  /* SystemInitialize for Enabled SubSystem: '<S14>/Enabled_Original_MIL' */
  /* SystemInitialize for Chart: '<S17>/Angle_Init' */
  AXU5EV_Motor_Control_System_DW.temporalCounter_i1 = 0U;
  AXU5EV_Motor_Control_System_DW.Init_Done = 0.0;
  AXU5EV_Motor_Control_System_DW.Init_State_Num = 0.0;
  AXU5EV_Motor_Control_System_DW.id_init_ref = 0.0;
  AXU5EV_Motor_Control_System_DW.Angle_Init_EN = 0.0;
  AXU5EV_Motor_Control_System_DW.Theta_Offset_auto = 0.0;
  AXU5EV_Motor_Control_System_DW.x_align_mm_latch = 0.0;
  AXU5EV_Motor_Control_System_DW.theta_offset_mem = 0.0;
  AXU5EV_Motor_Control_System_DW.is_active_c3_AXU5EV_Motor_Contr = 0U;
  AXU5EV_Motor_Control_System_DW.is_c3_AXU5EV_Motor_Control_Syst =
    AXU5EV_Motor_IN_NO_ACTIVE_CHILD;

  /* End of SystemInitialize for SubSystem: '<S14>/Enabled_Original_MIL' */

  /* SystemInitialize for MATLAB Function: '<S9>/Host_Core' */
  memset(&AXU5EV_Motor_Control_System_DW.move_state[0], 0, 22U * sizeof(double));

  /* End of SystemInitialize for SubSystem: '<S2>/Qualified_Runtime' */

  /* SystemInitialize for MATLAB Function: '<S2>/Reference_Commit' */
  AXU5EV_Motor_Control_System_DW.version = 0U;
  AXU5EV_Motor_Control_System_DW.last_id = 0U;

  /* SystemInitialize for Outport: '<Root>/reference_commit' incorporates:
   *  Outport: '<S2>/reference_commit'
   */
  memcpy(&AXU5EV_Motor_Control_System_Y.reference_commit[0],
         &AXU5EV_Motor_Control_Sys_ConstP.reference_commit_Y0[0], sizeof(double)
         << 3U);

  /* SystemInitialize for Outport: '<Root>/drive_outputs' incorporates:
   *  Outport: '<S2>/drive_outputs'
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
