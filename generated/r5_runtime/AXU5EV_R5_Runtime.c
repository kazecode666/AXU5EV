/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: AXU5EV_R5_Runtime.c
 *
 * Code generated for Simulink model 'AXU5EV_R5_Runtime'.
 *
 * Model version                  : 1.10
 * Simulink Coder version         : 26.2 (R2026b) 22-May-2026
 * C/C++ source code generated on : Mon Oct 26 03:42:13 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: Intel->x86-64 (Windows64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "AXU5EV_R5_Runtime.h"
#include <stdint.h>
#include "rt_nonfinite.h"
#include <math.h>
#include <emmintrin.h>
#include "AXU5EV_R5_Runtime_private.h"
#include <stdbool.h>
#include "zero_crossing_types.h"

/* Named constants for Chart: '<S4>/Angle_Init' */
#define AXU5EV_R5_Runti_IN_RAMP_DOWN_ID ((uint8_t)4U)
#define AXU5EV_R5_Runtime_IN_DONE      ((uint8_t)1U)
#define AXU5EV_R5_Runtime_IN_HOLD_ALIGN ((uint8_t)2U)
#define AXU5EV_R5_Runtime_IN_IDLE      ((uint8_t)3U)
#define AXU5EV_R5_Runtime_IN_RAMP_ID   ((uint8_t)5U)

/* Block signals and states (default storage) */
DW_AXU5EV_R5_Runtime_T AXU5EV_R5_Runtime_DW;

/* Previous zero-crossings (trigger) states */
PrevZCX_AXU5EV_R5_Runtime_T AXU5EV_R5_Runtime_PrevZCX;

/* External inputs (root inport signals with default storage) */
ExtU_AXU5EV_R5_Runtime_T AXU5EV_R5_Runtime_U;

/* External outputs (root outports fed by signals with default storage) */
ExtY_AXU5EV_R5_Runtime_T AXU5EV_R5_Runtime_Y;

/* Real-time model */
static RT_MODEL_AXU5EV_R5_Runtime_T AXU5EV_R5_Runtime_M_;
RT_MODEL_AXU5EV_R5_Runtime_T *const AXU5EV_R5_Runtime_M = &AXU5EV_R5_Runtime_M_;

/* Forward declaration for local functions */
static double AXU5EV_R5_Runtime_minimum(const double x[4]);
static double AXU5EV_R5_Runtime_maximum(const double x[3]);
static double AXU5EV_R5_Runtime_mod(double x, double y);
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

/* Function for MATLAB Function: '<Root>/Host_Core' */
static double AXU5EV_R5_Runtime_minimum(const double x[4])
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

/* Function for MATLAB Function: '<Root>/Host_Core' */
static double AXU5EV_R5_Runtime_maximum(const double x[3])
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

/* Function for MATLAB Function: '<Root>/Host_Core' */
static double AXU5EV_R5_Runtime_mod(double x, double y)
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
void AXU5EV_R5_Runtime_step(void)
{
  double cfg[4];
  double cfg_0[3];
  double tmp[2];
  double Close_Loop_EN;
  double D;
  double PI_Reset_EN;
  double PWM_EN;
  double Position_Loop_EN;
  double Ta;
  double Tc;
  double V;
  double q;
  double rtb_Software_Time_s;
  double rtb_UnitDelay;
  double rtb_iq_test_ref;
  double rtb_v_ref_cmd;
  double s;
  double tick;
  bool new_tick;
  bool rtb_Alignment_Fault_Active;
  bool rtb_Alignment_Ready;
  bool rtb_Compare;
  bool rtb_Init_Done_Or_Bypass;
  bool rtb_LogicalOperator;

  /* FunctionCallGenerator: '<Root>/Alignment_Tick_10kHz' incorporates:
   *  SubSystem: '<Root>/Alignment_Task'
   */
  /* Outputs for Enabled SubSystem: '<S1>/Enabled_Original_MIL' incorporates:
   *  EnablePort: '<S4>/Enable'
   */
  /* Inport: '<Root>/runtime_u' */
  if (AXU5EV_R5_Runtime_U.runtime_u[13] > 0.0) {
    /* Chart: '<S4>/Angle_Init' */
    if (AXU5EV_R5_Runtime_DW.temporalCounter_i1 < UINT32_MAX) {
      AXU5EV_R5_Runtime_DW.temporalCounter_i1++;
    }

    if (AXU5EV_R5_Runtime_DW.is_active_c3_AXU5EV_R5_Runtime == 0) {
      AXU5EV_R5_Runtime_DW.is_active_c3_AXU5EV_R5_Runtime = 1U;
      AXU5EV_R5_Runtime_DW.is_c3_AXU5EV_R5_Runtime = AXU5EV_R5_Runtime_IN_IDLE;
      AXU5EV_R5_Runtime_DW.Angle_Init_EN = 0.0;
      AXU5EV_R5_Runtime_DW.Init_Done = 0.0;
      AXU5EV_R5_Runtime_DW.id_init_ref = 0.0;
      AXU5EV_R5_Runtime_DW.Init_State_Num = 0.0;
    } else {
      switch (AXU5EV_R5_Runtime_DW.is_c3_AXU5EV_R5_Runtime) {
       case AXU5EV_R5_Runtime_IN_DONE:
        if ((AXU5EV_R5_Runtime_U.runtime_u[15] > 0.5) ||
            (AXU5EV_R5_Runtime_U.runtime_u[16] > 0.5)) {
          AXU5EV_R5_Runtime_DW.is_c3_AXU5EV_R5_Runtime =
            AXU5EV_R5_Runtime_IN_IDLE;
          AXU5EV_R5_Runtime_DW.Angle_Init_EN = 0.0;
          AXU5EV_R5_Runtime_DW.Init_Done = 0.0;
          AXU5EV_R5_Runtime_DW.id_init_ref = 0.0;
          AXU5EV_R5_Runtime_DW.Init_State_Num = 0.0;
        } else {
          AXU5EV_R5_Runtime_DW.Angle_Init_EN = 0.0;
          AXU5EV_R5_Runtime_DW.Init_Done = 1.0;
          AXU5EV_R5_Runtime_DW.id_init_ref = 0.0;
          AXU5EV_R5_Runtime_DW.Init_State_Num = 4.0;
          AXU5EV_R5_Runtime_DW.Theta_Offset_auto =
            AXU5EV_R5_Runtime_DW.theta_offset_mem;
        }
        break;

       case AXU5EV_R5_Runtime_IN_HOLD_ALIGN:
        if ((AXU5EV_R5_Runtime_U.runtime_u[15] > 0.5) ||
            (AXU5EV_R5_Runtime_U.runtime_u[16] > 0.5)) {
          AXU5EV_R5_Runtime_DW.is_c3_AXU5EV_R5_Runtime =
            AXU5EV_R5_Runtime_IN_IDLE;
          AXU5EV_R5_Runtime_DW.Angle_Init_EN = 0.0;
          AXU5EV_R5_Runtime_DW.Init_Done = 0.0;
          AXU5EV_R5_Runtime_DW.id_init_ref = 0.0;
          AXU5EV_R5_Runtime_DW.Init_State_Num = 0.0;
        } else if (AXU5EV_R5_Runtime_DW.temporalCounter_i1 >= 30000U) {
          AXU5EV_R5_Runtime_DW.x_align_mm_latch = AXU5EV_R5_Runtime_U.runtime_u
            [11];
          rtb_v_ref_cmd = 0.0 - 6.283185307179586 *
            AXU5EV_R5_Runtime_DW.x_align_mm_latch / 60.0;
          if (rtIsNaN(rtb_v_ref_cmd)) {
            AXU5EV_R5_Runtime_DW.theta_offset_mem = (rtNaN);
          } else if (rtIsInf(rtb_v_ref_cmd)) {
            AXU5EV_R5_Runtime_DW.theta_offset_mem = (rtNaN);
          } else {
            q = fabs(rtb_v_ref_cmd / 6.283185307179586);
            if (fabs(q - floor(q + 0.5)) > 2.220446049250313E-16 * q) {
              AXU5EV_R5_Runtime_DW.theta_offset_mem = fmod(rtb_v_ref_cmd,
                6.283185307179586);
            } else {
              AXU5EV_R5_Runtime_DW.theta_offset_mem = 0.0;
            }

            if (AXU5EV_R5_Runtime_DW.theta_offset_mem == 0.0) {
              AXU5EV_R5_Runtime_DW.theta_offset_mem = 0.0;
            } else if (AXU5EV_R5_Runtime_DW.theta_offset_mem < 0.0) {
              AXU5EV_R5_Runtime_DW.theta_offset_mem += 6.283185307179586;
            }
          }

          AXU5EV_R5_Runtime_DW.Theta_Offset_auto =
            AXU5EV_R5_Runtime_DW.theta_offset_mem;
          AXU5EV_R5_Runtime_DW.temporalCounter_i1 = 0U;
          AXU5EV_R5_Runtime_DW.is_c3_AXU5EV_R5_Runtime =
            AXU5EV_R5_Runti_IN_RAMP_DOWN_ID;
          AXU5EV_R5_Runtime_DW.Angle_Init_EN = 1.0;
          AXU5EV_R5_Runtime_DW.Init_Done = 0.0;
          AXU5EV_R5_Runtime_DW.id_init_ref = 0.5;
          AXU5EV_R5_Runtime_DW.Init_State_Num = 3.0;
        } else {
          AXU5EV_R5_Runtime_DW.Angle_Init_EN = 1.0;
          AXU5EV_R5_Runtime_DW.Init_Done = 0.0;
          AXU5EV_R5_Runtime_DW.id_init_ref = 0.5;
        }
        break;

       case AXU5EV_R5_Runtime_IN_IDLE:
        if ((AXU5EV_R5_Runtime_U.runtime_u[14] > 0.5) &&
            (AXU5EV_R5_Runtime_U.runtime_u[15] < 0.5) &&
            (AXU5EV_R5_Runtime_U.runtime_u[16] < 0.5)) {
          AXU5EV_R5_Runtime_DW.temporalCounter_i1 = 0U;
          AXU5EV_R5_Runtime_DW.is_c3_AXU5EV_R5_Runtime =
            AXU5EV_R5_Runtime_IN_RAMP_ID;
          AXU5EV_R5_Runtime_DW.Angle_Init_EN = 1.0;
          AXU5EV_R5_Runtime_DW.Init_Done = 0.0;
          AXU5EV_R5_Runtime_DW.id_init_ref = 0.0;
          AXU5EV_R5_Runtime_DW.Init_State_Num = 1.0;
        }
        break;

       case AXU5EV_R5_Runti_IN_RAMP_DOWN_ID:
        if (AXU5EV_R5_Runtime_DW.temporalCounter_i1 >= 2000U) {
          AXU5EV_R5_Runtime_DW.is_c3_AXU5EV_R5_Runtime =
            AXU5EV_R5_Runtime_IN_DONE;
          AXU5EV_R5_Runtime_DW.Angle_Init_EN = 0.0;
          AXU5EV_R5_Runtime_DW.Init_Done = 1.0;
          AXU5EV_R5_Runtime_DW.id_init_ref = 0.0;
          AXU5EV_R5_Runtime_DW.Init_State_Num = 4.0;
        } else if ((AXU5EV_R5_Runtime_U.runtime_u[15] > 0.5) ||
                   (AXU5EV_R5_Runtime_U.runtime_u[16] > 0.5)) {
          AXU5EV_R5_Runtime_DW.is_c3_AXU5EV_R5_Runtime =
            AXU5EV_R5_Runtime_IN_IDLE;
          AXU5EV_R5_Runtime_DW.Angle_Init_EN = 0.0;
          AXU5EV_R5_Runtime_DW.Init_Done = 0.0;
          AXU5EV_R5_Runtime_DW.id_init_ref = 0.0;
          AXU5EV_R5_Runtime_DW.Init_State_Num = 0.0;
        } else {
          AXU5EV_R5_Runtime_DW.Angle_Init_EN = 1.0;
          AXU5EV_R5_Runtime_DW.Init_Done = 0.0;
          AXU5EV_R5_Runtime_DW.id_init_ref -= 0.00025;
          if (AXU5EV_R5_Runtime_DW.id_init_ref < 0.0) {
            AXU5EV_R5_Runtime_DW.id_init_ref = 0.0;
          }

          AXU5EV_R5_Runtime_DW.Theta_Offset_auto =
            AXU5EV_R5_Runtime_DW.theta_offset_mem;
        }
        break;

       default:
        /* case IN_RAMP_ID: */
        if ((AXU5EV_R5_Runtime_U.runtime_u[15] > 0.5) ||
            (AXU5EV_R5_Runtime_U.runtime_u[16] > 0.5)) {
          AXU5EV_R5_Runtime_DW.is_c3_AXU5EV_R5_Runtime =
            AXU5EV_R5_Runtime_IN_IDLE;
          AXU5EV_R5_Runtime_DW.Angle_Init_EN = 0.0;
          AXU5EV_R5_Runtime_DW.Init_Done = 0.0;
          AXU5EV_R5_Runtime_DW.id_init_ref = 0.0;
          AXU5EV_R5_Runtime_DW.Init_State_Num = 0.0;
        } else if (AXU5EV_R5_Runtime_DW.temporalCounter_i1 >= 10000U) {
          AXU5EV_R5_Runtime_DW.temporalCounter_i1 = 0U;
          AXU5EV_R5_Runtime_DW.is_c3_AXU5EV_R5_Runtime =
            AXU5EV_R5_Runtime_IN_HOLD_ALIGN;
          AXU5EV_R5_Runtime_DW.Angle_Init_EN = 1.0;
          AXU5EV_R5_Runtime_DW.Init_Done = 0.0;
          AXU5EV_R5_Runtime_DW.id_init_ref = 0.5;
          AXU5EV_R5_Runtime_DW.Init_State_Num = 2.0;
        } else {
          AXU5EV_R5_Runtime_DW.Angle_Init_EN = 1.0;
          AXU5EV_R5_Runtime_DW.Init_Done = 0.0;
          AXU5EV_R5_Runtime_DW.id_init_ref += 5.0E-5;
          if (AXU5EV_R5_Runtime_DW.id_init_ref > 0.5) {
            AXU5EV_R5_Runtime_DW.id_init_ref = 0.5;
          }
        }
        break;
      }
    }

    /* SignalConversion generated from: '<S5>/ SFunction ' incorporates:
     *  Chart: '<S4>/Angle_Init'
     */
    AXU5EV_R5_Runtime_DW.Init_Done_p = AXU5EV_R5_Runtime_DW.Init_Done;

    /* SignalConversion generated from: '<S5>/ SFunction ' incorporates:
     *  Chart: '<S4>/Angle_Init'
     */
    AXU5EV_R5_Runtime_DW.Init_State_Num_a = AXU5EV_R5_Runtime_DW.Init_State_Num;

    /* SignalConversion generated from: '<S5>/ SFunction ' incorporates:
     *  Chart: '<S4>/Angle_Init'
     */
    AXU5EV_R5_Runtime_DW.id_init_ref_g = AXU5EV_R5_Runtime_DW.id_init_ref;

    /* SignalConversion generated from: '<S5>/ SFunction ' incorporates:
     *  Chart: '<S4>/Angle_Init'
     */
    AXU5EV_R5_Runtime_DW.Angle_Init_EN_d = AXU5EV_R5_Runtime_DW.Angle_Init_EN;

    /* SignalConversion generated from: '<S5>/ SFunction ' incorporates:
     *  Chart: '<S4>/Angle_Init'
     */
    AXU5EV_R5_Runtime_DW.Theta_Offset_auto_h =
      AXU5EV_R5_Runtime_DW.Theta_Offset_auto;

    /* SignalConversion generated from: '<S5>/ SFunction ' incorporates:
     *  Chart: '<S4>/Angle_Init'
     */
    AXU5EV_R5_Runtime_DW.x_align_mm_latch_b =
      AXU5EV_R5_Runtime_DW.x_align_mm_latch;
  }

  /* End of Outputs for SubSystem: '<S1>/Enabled_Original_MIL' */
  /* End of Outputs for FunctionCallGenerator: '<Root>/Alignment_Tick_10kHz' */

  /* Gain: '<Root>/Software_Time_s' incorporates:
   *  UnitDelay: '<Root>/Software_Tick'
   */
  rtb_Software_Time_s = 0.0001 * AXU5EV_R5_Runtime_DW.Software_Tick_DSTATE;

  /* Logic: '<Root>/Not_Alignment_Enable' incorporates:
   *  Inport: '<Root>/runtime_u'
   *  Logic: '<Root>/Alignment_Reset_Active'
   */
  rtb_Alignment_Ready = !(AXU5EV_R5_Runtime_U.runtime_u[13] != 0.0);

  /* Logic: '<Root>/Init_Done_Or_Bypass' incorporates:
   *  Logic: '<Root>/Not_Alignment_Enable'
   */
  rtb_Init_Done_Or_Bypass = (rtb_Alignment_Ready ||
    (AXU5EV_R5_Runtime_DW.Init_Done_p != 0.0));

  /* Logic: '<Root>/Alignment_Fault_Active' incorporates:
   *  Inport: '<Root>/runtime_u'
   */
  rtb_Alignment_Fault_Active = ((AXU5EV_R5_Runtime_U.runtime_u[13] != 0.0) &&
    (AXU5EV_R5_Runtime_U.runtime_u[16] != 0.0));

  /* Logic: '<Root>/Alignment_Ready' incorporates:
   *  Inport: '<Root>/runtime_u'
   *  Logic: '<Root>/Alignment_Reset_Active'
   *  Logic: '<Root>/Not_Alignment_Fault'
   *  Logic: '<Root>/Not_Alignment_Reset'
   */
  rtb_Alignment_Ready = (rtb_Init_Done_Or_Bypass && !rtb_Alignment_Fault_Active &&
    (rtb_Alignment_Ready || !(AXU5EV_R5_Runtime_U.runtime_u[15] != 0.0)));

  /* MATLAB Function: '<Root>/Host_Core' incorporates:
   *  Inport: '<Root>/runtime_u'
   */
  rtb_v_ref_cmd = AXU5EV_R5_Runtime_U.runtime_u[1];
  q = AXU5EV_R5_Runtime_U.runtime_u[3];
  rtb_iq_test_ref = AXU5EV_R5_Runtime_U.runtime_u[4];
  Position_Loop_EN = AXU5EV_R5_Runtime_U.runtime_u[5];
  Close_Loop_EN = AXU5EV_R5_Runtime_U.runtime_u[6];
  PWM_EN = AXU5EV_R5_Runtime_U.runtime_u[7];
  PI_Reset_EN = AXU5EV_R5_Runtime_U.runtime_u[8];
  if (AXU5EV_R5_Runtime_U.runtime_u[9] != 0.0) {
    rtb_v_ref_cmd = AXU5EV_R5_Runtime_U.runtime_u[17];
    PWM_EN = AXU5EV_R5_Runtime_U.runtime_u[18];
    PI_Reset_EN = AXU5EV_R5_Runtime_U.runtime_u[19];
  }

  if (AXU5EV_R5_Runtime_DW.move_state[0] == 0.0) {
    AXU5EV_R5_Runtime_DW.move_state[0] = 1.0;
    AXU5EV_R5_Runtime_DW.move_state[1] = AXU5EV_R5_Runtime_U.runtime_u[10];
    AXU5EV_R5_Runtime_DW.move_state[2] = AXU5EV_R5_Runtime_U.runtime_u[11];
    AXU5EV_R5_Runtime_DW.move_state[3] = AXU5EV_R5_Runtime_U.runtime_u[11];
    AXU5EV_R5_Runtime_DW.move_state[4] = rtb_Software_Time_s;
    AXU5EV_R5_Runtime_DW.move_state[6] = 1.0;
    AXU5EV_R5_Runtime_DW.move_state[13] = -1.0;
    AXU5EV_R5_Runtime_DW.move_state[14] = AXU5EV_R5_Runtime_U.runtime_u[11];
    AXU5EV_R5_Runtime_DW.move_state[15] = rtb_Alignment_Ready;
    if (AXU5EV_R5_Runtime_U.runtime_u[13] == 0.0) {
      AXU5EV_R5_Runtime_DW.move_state[2] = 0.0;
      AXU5EV_R5_Runtime_DW.move_state[3] = AXU5EV_R5_Runtime_U.runtime_u[0];
      AXU5EV_R5_Runtime_DW.move_state[4] = 0.05;
      AXU5EV_R5_Runtime_DW.move_state[5] = 1.0;
      AXU5EV_R5_Runtime_DW.move_state[6] = 0.0;
      AXU5EV_R5_Runtime_DW.move_state[9] = 1.0;
      AXU5EV_R5_Runtime_DW.move_state[10] = 1.0;
      AXU5EV_R5_Runtime_DW.move_state[19] = 1.0;
    }
  }

  rtb_Compare = ((AXU5EV_R5_Runtime_U.runtime_u[5] != 0.0) &&
                 ((AXU5EV_R5_Runtime_U.runtime_u[6] != 0.0) &&
                  (AXU5EV_R5_Runtime_U.runtime_u[3] == 0.0)) && (PWM_EN != 0.0) &&
                 (PI_Reset_EN == 0.0) && rtb_Alignment_Ready);
  tick = floor(rtb_Software_Time_s / 0.0001 + 1.0E-7);
  new_tick = (tick != AXU5EV_R5_Runtime_DW.move_state[13]);
  if (new_tick) {
    AXU5EV_R5_Runtime_DW.move_state[13] = tick;
    if ((AXU5EV_R5_Runtime_U.runtime_u[13] != 0.0) && rtb_Alignment_Ready &&
        (AXU5EV_R5_Runtime_DW.move_state[15] == 0.0)) {
      AXU5EV_R5_Runtime_DW.move_state[2] = AXU5EV_R5_Runtime_U.runtime_u[11];
      AXU5EV_R5_Runtime_DW.move_state[3] = AXU5EV_R5_Runtime_U.runtime_u[11];
      AXU5EV_R5_Runtime_DW.move_state[4] = rtb_Software_Time_s;
      AXU5EV_R5_Runtime_DW.move_state[5] = 0.0;
      AXU5EV_R5_Runtime_DW.move_state[6] = 1.0;
      AXU5EV_R5_Runtime_DW.move_state[7] = 0.0;
      AXU5EV_R5_Runtime_DW.move_state[8] = 0.0;
      AXU5EV_R5_Runtime_DW.move_state[12] = 0.0;
      AXU5EV_R5_Runtime_DW.move_state[14] = AXU5EV_R5_Runtime_U.runtime_u[11];
    }

    AXU5EV_R5_Runtime_DW.move_state[15] = rtb_Alignment_Ready;
    if ((AXU5EV_R5_Runtime_DW.move_state[5] != 0.0) && ((PWM_EN == 0.0) ||
         (PI_Reset_EN != 0.0))) {
      AXU5EV_R5_Runtime_DW.move_state[5] = 0.0;
      AXU5EV_R5_Runtime_DW.move_state[6] = 0.0;
      AXU5EV_R5_Runtime_DW.move_state[7] = 0.0;
      AXU5EV_R5_Runtime_DW.move_state[8] = 0.0;
      AXU5EV_R5_Runtime_DW.move_state[12] = 1.0;
      AXU5EV_R5_Runtime_DW.move_state[9] = 7.0;
    }
  }

  if (AXU5EV_R5_Runtime_DW.move_state[12] != 0.0) {
    V = AXU5EV_R5_Runtime_DW.move_state[14];
  } else {
    _mm_storeu_pd(&tmp[0], _mm_sub_pd(_mm_set_pd
      (AXU5EV_R5_Runtime_DW.move_state[3], rtb_Software_Time_s), _mm_set_pd
      (AXU5EV_R5_Runtime_DW.move_state[2], AXU5EV_R5_Runtime_DW.move_state[4])));
    D = fabs(tmp[1]);
    s = 0.0;
    rtb_UnitDelay = 0.0;
    if (!(D == 0.0)) {
      cfg[0] = 10.0;
      cfg[1] = D / 0.1;
      cfg[2] = sqrt(D * 100.0 / 1.875);
      cfg[3] = rt_powd_snf(D * D * 1000.0 / 5.773502691896258,
                           0.3333333333333333);
      V = AXU5EV_R5_Runtime_minimum(cfg);
      cfg_0[0] = 0.1;
      cfg_0[1] = 1.875 * V / 100.0;
      cfg_0[2] = sqrt(5.773502691896258 * V / 1000.0);
      Ta = AXU5EV_R5_Runtime_maximum(cfg_0);
      Tc = fmax(0.0, D / V - Ta);
      rtb_UnitDelay = 2.0 * Ta + Tc;
      if (!(tmp[0] <= 0.0)) {
        if (tmp[0] < Ta) {
          s = tmp[0] / Ta;
          s = ((2.5 * rt_powd_snf(s, 4.0) - 3.0 * rt_powd_snf(s, 5.0)) +
               rt_powd_snf(s, 6.0)) * (V * Ta);
        } else if (tmp[0] < Ta + Tc) {
          s = V * Ta / 2.0 + (tmp[0] - Ta) * V;
        } else if (tmp[0] < rtb_UnitDelay) {
          s = ((tmp[0] - Ta) - Tc) / Ta;
          Ta *= V;
          s = (((s - 2.5 * rt_powd_snf(s, 4.0)) + 3.0 * rt_powd_snf(s, 5.0)) -
               rt_powd_snf(s, 6.0)) * Ta + (Ta / 2.0 + V * Tc);
        } else {
          s = D;
        }

        if (rtIsNaN(tmp[1])) {
          Tc = (rtNaN);
        } else if (tmp[1] < 0.0) {
          Tc = -1.0;
        } else {
          Tc = (tmp[1] > 0.0);
        }

        s *= Tc;
      }
    }

    V = AXU5EV_R5_Runtime_DW.move_state[2] + s;
    AXU5EV_R5_Runtime_DW.move_state[17] = rtb_UnitDelay;
    AXU5EV_R5_Runtime_DW.move_state[6] = (rtb_Software_Time_s -
      AXU5EV_R5_Runtime_DW.move_state[4] >= rtb_UnitDelay);
  }

  if ((AXU5EV_R5_Runtime_mod(tick, 100.0) == 99.0) && (tick + 1.0 !=
       AXU5EV_R5_Runtime_DW.move_state[21])) {
    AXU5EV_R5_Runtime_DW.move_state[21] = tick + 1.0;
    if (rtb_Compare) {
      if (AXU5EV_R5_Runtime_DW.move_state[6] != 0.0) {
        if (AXU5EV_R5_Runtime_DW.move_state[12] == 0.0) {
          if (fabs(AXU5EV_R5_Runtime_U.runtime_u[11] -
                   AXU5EV_R5_Runtime_DW.move_state[3]) <= 0.020000001) {
            AXU5EV_R5_Runtime_DW.move_state[8] = fmin
              (AXU5EV_R5_Runtime_DW.move_state[8] + 1.0, 5.0);
          } else {
            AXU5EV_R5_Runtime_DW.move_state[8] = 0.0;
          }
        } else {
          AXU5EV_R5_Runtime_DW.move_state[8] = 0.0;
        }
      } else {
        AXU5EV_R5_Runtime_DW.move_state[8] = 0.0;
      }
    } else {
      AXU5EV_R5_Runtime_DW.move_state[8] = 0.0;
    }

    AXU5EV_R5_Runtime_DW.move_state[7] = (AXU5EV_R5_Runtime_DW.move_state[8] >=
      5.0);
    if (AXU5EV_R5_Runtime_DW.move_state[7] != 0.0) {
      AXU5EV_R5_Runtime_DW.move_state[5] = 0.0;
    }
  }

  rtb_LogicalOperator = (rtb_Compare && ((AXU5EV_R5_Runtime_DW.move_state[7] !=
    0.0) && ((AXU5EV_R5_Runtime_DW.move_state[5] == 0.0) &&
             (AXU5EV_R5_Runtime_DW.move_state[12] == 0.0))));
  AXU5EV_R5_Runtime_DW.move_state[20] = rtb_LogicalOperator;
  if (new_tick && (!(AXU5EV_R5_Runtime_DW.move_state[1] ==
                     AXU5EV_R5_Runtime_U.runtime_u[10]) && (!rtIsNaN
        (AXU5EV_R5_Runtime_U.runtime_u[10]) || !rtIsNaN
        (AXU5EV_R5_Runtime_DW.move_state[1])))) {
    AXU5EV_R5_Runtime_DW.move_state[1] = AXU5EV_R5_Runtime_U.runtime_u[10];
    AXU5EV_R5_Runtime_DW.move_state[18] = rtb_Software_Time_s;
    if (rtIsInf(AXU5EV_R5_Runtime_U.runtime_u[0]) || rtIsNaN
        (AXU5EV_R5_Runtime_U.runtime_u[0]) || (rtIsInf
         (AXU5EV_R5_Runtime_U.runtime_u[10]) || rtIsNaN
         (AXU5EV_R5_Runtime_U.runtime_u[10])) ||
        ((AXU5EV_R5_Runtime_U.runtime_u[10] != 0.0) &&
         (AXU5EV_R5_Runtime_U.runtime_u[10] != 1.0))) {
      AXU5EV_R5_Runtime_DW.move_state[9] = 4.0;
      AXU5EV_R5_Runtime_DW.move_state[11]++;
    } else if (!rtb_Compare) {
      AXU5EV_R5_Runtime_DW.move_state[9] = 6.0;
      AXU5EV_R5_Runtime_DW.move_state[11]++;
    } else if (!rtb_LogicalOperator) {
      AXU5EV_R5_Runtime_DW.move_state[9] = 3.0;
      AXU5EV_R5_Runtime_DW.move_state[11]++;
    } else if (fabs(AXU5EV_R5_Runtime_U.runtime_u[0] -
                    AXU5EV_R5_Runtime_DW.move_state[3]) <= 1.0E-12) {
      AXU5EV_R5_Runtime_DW.move_state[9] = 5.0;
    } else {
      AXU5EV_R5_Runtime_DW.move_state[2] = AXU5EV_R5_Runtime_DW.move_state[3];
      AXU5EV_R5_Runtime_DW.move_state[3] = AXU5EV_R5_Runtime_U.runtime_u[0];
      AXU5EV_R5_Runtime_DW.move_state[4] = rtb_Software_Time_s;
      AXU5EV_R5_Runtime_DW.move_state[5] = 1.0;
      AXU5EV_R5_Runtime_DW.move_state[6] = 0.0;
      AXU5EV_R5_Runtime_DW.move_state[7] = 0.0;
      AXU5EV_R5_Runtime_DW.move_state[8] = 0.0;
      AXU5EV_R5_Runtime_DW.move_state[9] = 2.0;
      AXU5EV_R5_Runtime_DW.move_state[10]++;
      AXU5EV_R5_Runtime_DW.move_state[18] = rtb_Software_Time_s;
      AXU5EV_R5_Runtime_DW.move_state[19]++;
      AXU5EV_R5_Runtime_DW.move_state[20] = 0.0;
      V = AXU5EV_R5_Runtime_DW.move_state[2];
    }
  }

  AXU5EV_R5_Runtime_DW.move_state[14] = V;
  if ((AXU5EV_R5_Runtime_U.runtime_u[13] != 0.0) && !rtb_Alignment_Ready) {
    Position_Loop_EN = 0.0;
    Close_Loop_EN = 0.0;
    q = 1.0;
    rtb_iq_test_ref = 0.0;
  }

  /* FunctionCallGenerator: '<Root>/Control_Tick_10kHz' incorporates:
   *  SubSystem: '<Root>/Motion_Control'
   */
  /* RelationalOperator: '<S12>/Compare' incorporates:
   *  Constant: '<S12>/Constant'
   *  Constant: '<S8>/Constant1'
   *  Sum: '<S8>/Add1'
   *  UnitDelay: '<S8>/spd_cnt_z'
   */
  rtb_Compare = (AXU5EV_R5_Runtime_DW.spd_cnt_z_DSTATE + 1.0 >= 10.0);

  /* RelationalOperator: '<S11>/Compare' incorporates:
   *  Constant: '<S11>/Constant'
   *  Constant: '<S8>/Constant3'
   *  Sum: '<S8>/Add2'
   *  UnitDelay: '<S8>/pos_cnt_z'
   */
  new_tick = (AXU5EV_R5_Runtime_DW.pos_cnt_z_DSTATE + 1.0 >= 10.0);

  /* Logic: '<S8>/Logical Operator' */
  rtb_LogicalOperator = (rtb_Compare && new_tick);

  /* Outputs for Triggered SubSystem: '<S3>/Position_Loop' incorporates:
   *  TriggerPort: '<S6>/Trigger'
   */
  if (rtb_LogicalOperator && (AXU5EV_R5_Runtime_PrevZCX.Position_Loop_Trig_ZCE
       != POS_ZCSIG)) {
    /* Sum: '<S6>/Sum' incorporates:
     *  Inport: '<Root>/runtime_u'
     *  MATLAB Function: '<Root>/Host_Core'
     */
    rtb_Software_Time_s = V - AXU5EV_R5_Runtime_U.runtime_u[11];

    /* DeadZone: '<S6>/Dead Zone' */
    if (rtb_Software_Time_s > 0.02) {
      Tc = rtb_Software_Time_s - 0.02;
    } else if (rtb_Software_Time_s >= -0.02) {
      Tc = 0.0;
    } else {
      Tc = rtb_Software_Time_s - -0.02;
    }

    /* Gain: '<S6>/Gain' incorporates:
     *  DeadZone: '<S6>/Dead Zone'
     */
    AXU5EV_R5_Runtime_DW.obs_v_ref_pos = 22.0 * Tc;

    /* Saturate: '<S6>/Saturation' */
    if (AXU5EV_R5_Runtime_DW.obs_v_ref_pos > 20.0) {
      /* Gain: '<S6>/Gain' incorporates:
       *  Saturate: '<S6>/Saturation'
       */
      AXU5EV_R5_Runtime_DW.obs_v_ref_pos = 20.0;
    } else if (AXU5EV_R5_Runtime_DW.obs_v_ref_pos < -20.0) {
      /* Gain: '<S6>/Gain' incorporates:
       *  Saturate: '<S6>/Saturation'
       */
      AXU5EV_R5_Runtime_DW.obs_v_ref_pos = -20.0;
    }

    /* End of Saturate: '<S6>/Saturation' */
  }

  AXU5EV_R5_Runtime_PrevZCX.Position_Loop_Trig_ZCE = rtb_LogicalOperator;

  /* End of Outputs for SubSystem: '<S3>/Position_Loop' */

  /* Switch: '<S7>/v_ref_closed_sel' incorporates:
   *  MATLAB Function: '<Root>/Host_Core'
   */
  if (Position_Loop_EN > 0.5) {
    Tc = AXU5EV_R5_Runtime_DW.obs_v_ref_pos;
  } else {
    Tc = rtb_v_ref_cmd;
  }

  /* Sum: '<S10>/Subtract' incorporates:
   *  Switch: '<S7>/v_ref_closed_sel'
   *  UnitDelay: '<S10>/v_ref_set_lim_z'
   */
  rtb_Software_Time_s = Tc - AXU5EV_R5_Runtime_DW.v_ref_set_lim_z_DSTATE;

  /* Saturate: '<S10>/Saturation' */
  if (rtb_Software_Time_s > 0.005) {
    rtb_Software_Time_s = 0.005;
  } else if (rtb_Software_Time_s < -0.005) {
    rtb_Software_Time_s = -0.005;
  }

  /* Sum: '<S10>/Add' incorporates:
   *  Saturate: '<S10>/Saturation'
   *  UnitDelay: '<S10>/v_ref_set_lim_z'
   */
  AXU5EV_R5_Runtime_DW.v_ref_set_lim_z_DSTATE += rtb_Software_Time_s;

  /* Switch: '<S3>/MIL_Init_Done_Vref_Gate' */
  if (rtb_Init_Done_Or_Bypass) {
    /* Switch: '<S7>/Switch9' incorporates:
     *  MATLAB Function: '<Root>/Host_Core'
     */
    if (Close_Loop_EN > 0.5) {
      /* Saturate: '<S7>/Saturation' incorporates:
       *  UnitDelay: '<S10>/v_ref_set_lim_z'
       */
      if (AXU5EV_R5_Runtime_DW.v_ref_set_lim_z_DSTATE > 20.0) {
        /* Switch: '<S3>/MIL_Init_Done_Vref_Gate' */
        rtb_Software_Time_s = 20.0;
      } else if (AXU5EV_R5_Runtime_DW.v_ref_set_lim_z_DSTATE < -20.0) {
        /* Switch: '<S3>/MIL_Init_Done_Vref_Gate' */
        rtb_Software_Time_s = -20.0;
      } else {
        /* Switch: '<S3>/MIL_Init_Done_Vref_Gate' */
        rtb_Software_Time_s = AXU5EV_R5_Runtime_DW.v_ref_set_lim_z_DSTATE;
      }
    } else {
      /* Switch: '<S3>/MIL_Init_Done_Vref_Gate' incorporates:
       *  Constant: '<S7>/Constant15'
       *  Saturate: '<S7>/Saturation'
       */
      rtb_Software_Time_s = 0.0;
    }
  } else {
    /* Switch: '<S3>/MIL_Init_Done_Vref_Gate' incorporates:
     *  Constant: '<S3>/Alignment_Zero'
     *  Saturate: '<S7>/Saturation'
     *  Switch: '<S7>/Switch9'
     */
    rtb_Software_Time_s = 0.0;
  }

  /* End of Switch: '<S3>/MIL_Init_Done_Vref_Gate' */

  /* Outputs for Triggered SubSystem: '<S3>/Speed_Loop' incorporates:
   *  TriggerPort: '<S9>/Trigger'
   */
  if (rtb_Compare && (AXU5EV_R5_Runtime_PrevZCX.Speed_Loop_Trig_ZCE != POS_ZCSIG))
  {
    /* Sum: '<S9>/Sum' incorporates:
     *  Inport: '<Root>/runtime_u'
     */
    tick = rtb_Software_Time_s - AXU5EV_R5_Runtime_U.runtime_u[12];

    /* Sum: '<S9>/Add1' incorporates:
     *  Gain: '<S9>/  '
     *  UnitDelay: '<S9>/x_s_z'
     */
    Tc = 0.018033474852681124 * tick + AXU5EV_R5_Runtime_DW.x_s_z_DSTATE;

    /* UnitDelay: '<S9>/Unit Delay' */
    rtb_UnitDelay = AXU5EV_R5_Runtime_DW.UnitDelay_DSTATE;

    /* Logic: '<S13>/Logical Operator3' incorporates:
     *  Logic: '<Root>/Effective_PI_Reset'
     *  Logic: '<Root>/PWM_Not_Requested'
     *  Logic: '<S13>/Logical Operator2'
     *  MATLAB Function: '<Root>/Host_Core'
     */
    rtb_LogicalOperator = ((AXU5EV_R5_Runtime_DW.Angle_Init_EN_d != 0.0) ||
      ((PI_Reset_EN != 0.0) || !(PWM_EN != 0.0) || rtb_Alignment_Fault_Active) ||
      (q != 0.0) || !(Close_Loop_EN != 0.0));

    /* Saturate: '<S9>/Saturation1' */
    if (Tc > 1.0) {
      s = 1.0;
    } else if (Tc < -1.0) {
      s = -1.0;
    } else {
      s = Tc;
    }

    /* End of Saturate: '<S9>/Saturation1' */

    /* Switch: '<S9>/PI_Reset_Output' */
    if (rtb_LogicalOperator) {
      /* Switch: '<S9>/PI_Reset_Output' incorporates:
       *  Constant: '<S9>/Constant4'
       */
      AXU5EV_R5_Runtime_DW.PI_Reset_Output = 0.0;
    } else {
      /* Switch: '<S9>/PI_Reset_Output' */
      AXU5EV_R5_Runtime_DW.PI_Reset_Output = s;
    }

    /* End of Switch: '<S9>/PI_Reset_Output' */

    /* Sum: '<S9>/Subtract' incorporates:
     *  UnitDelay: '<S9>/Unit Delay'
     */
    AXU5EV_R5_Runtime_DW.UnitDelay_DSTATE = Tc - s;

    /* Signum: '<S13>/Sign' */
    if (rtIsNaN(rtb_Software_Time_s)) {
      Tc = (rtNaN);
    } else if (rtb_Software_Time_s < 0.0) {
      Tc = -1.0;
    } else {
      Tc = (rtb_Software_Time_s > 0.0);
    }

    /* Switch: '<S9>/Switch1' incorporates:
     *  Abs: '<S9>/Abs'
     *  Constant: '<S14>/Constant'
     *  Constant: '<S16>/Constant'
     *  Logic: '<S13>/Logical Operator'
     *  Logic: '<S13>/Logical Operator1'
     *  Product: '<S13>/Product2'
     *  RelationalOperator: '<S14>/Compare'
     *  RelationalOperator: '<S16>/Compare'
     *  Signum: '<S13>/Sign'
     */
    if (rtb_LogicalOperator || ((fabs(rtb_Software_Time_s) > 0.5) && (Tc * tick <
          -3.0))) {
      /* Sum: '<S9>/Add2' incorporates:
       *  Constant: '<S9>/Constant1'
       *  UnitDelay: '<S9>/x_s_z'
       */
      AXU5EV_R5_Runtime_DW.x_s_z_DSTATE = 0.0;
    } else {
      /* Sum: '<S9>/Add2' incorporates:
       *  Gain: '<S9>/ '
       *  Gain: '<S9>/Gain'
       *  UnitDelay: '<S9>/x_s_z'
       */
      AXU5EV_R5_Runtime_DW.x_s_z_DSTATE = (0.00144267798821449 * tick +
        AXU5EV_R5_Runtime_DW.x_s_z_DSTATE) - 0.08 * rtb_UnitDelay;

      /* Saturate: '<S9>/Saturation' */
      if (AXU5EV_R5_Runtime_DW.x_s_z_DSTATE > 0.5) {
        /* Sum: '<S9>/Add2' */
        AXU5EV_R5_Runtime_DW.x_s_z_DSTATE = 0.5;
      } else if (AXU5EV_R5_Runtime_DW.x_s_z_DSTATE < -0.5) {
        /* Sum: '<S9>/Add2' */
        AXU5EV_R5_Runtime_DW.x_s_z_DSTATE = -0.5;
      }

      /* End of Saturate: '<S9>/Saturation' */
    }

    /* End of Switch: '<S9>/Switch1' */
  }

  AXU5EV_R5_Runtime_PrevZCX.Speed_Loop_Trig_ZCE = rtb_Compare;

  /* End of Outputs for SubSystem: '<S3>/Speed_Loop' */

  /* Switch: '<S3>/MIL_Fault_Id_Zero' incorporates:
   *  Switch: '<S3>/MIL_Align_Id_Select'
   *  Switch: '<S3>/MIL_Align_Iq_Zero'
   *  Switch: '<S3>/MIL_Fault_Iq_Zero'
   */
  if (rtb_Alignment_Fault_Active) {
    /* Outport: '<Root>/runtime_y' incorporates:
     *  Constant: '<S3>/Alignment_Zero'
     *  Switch: '<S3>/MIL_Fault_Id_Zero'
     *  Switch: '<S3>/MIL_Fault_Iq_Zero'
     */
    AXU5EV_R5_Runtime_Y.runtime_y[0] = 0.0;
    AXU5EV_R5_Runtime_Y.runtime_y[1] = 0.0;
  } else if (AXU5EV_R5_Runtime_DW.Angle_Init_EN_d > 0.5) {
    /* Outport: '<Root>/runtime_y' incorporates:
     *  Constant: '<S3>/Alignment_Zero'
     *  Switch: '<S3>/MIL_Align_Id_Select'
     *  Switch: '<S3>/MIL_Align_Iq_Zero'
     *  Switch: '<S3>/MIL_Fault_Id_Zero'
     *  Switch: '<S3>/MIL_Fault_Iq_Zero'
     */
    AXU5EV_R5_Runtime_Y.runtime_y[0] = AXU5EV_R5_Runtime_DW.id_init_ref_g;
    AXU5EV_R5_Runtime_Y.runtime_y[1] = 0.0;
  } else {
    /* Outport: '<Root>/runtime_y' incorporates:
     *  Inport: '<Root>/runtime_u'
     *  MATLAB Function: '<Root>/Host_Core'
     *  Switch: '<S3>/MIL_Fault_Id_Zero'
     */
    AXU5EV_R5_Runtime_Y.runtime_y[0] = AXU5EV_R5_Runtime_U.runtime_u[2];

    /* Switch: '<S7>/Switch' incorporates:
     *  MATLAB Function: '<Root>/Host_Core'
     *  Switch: '<S3>/MIL_Align_Iq_Zero'
     */
    if (q > 0.5) {
      /* Outport: '<Root>/runtime_y' incorporates:
       *  Switch: '<S3>/MIL_Fault_Iq_Zero'
       */
      AXU5EV_R5_Runtime_Y.runtime_y[1] = rtb_iq_test_ref;
    } else {
      /* Outport: '<Root>/runtime_y' incorporates:
       *  Switch: '<S3>/MIL_Fault_Iq_Zero'
       */
      AXU5EV_R5_Runtime_Y.runtime_y[1] = AXU5EV_R5_Runtime_DW.PI_Reset_Output;
    }

    /* End of Switch: '<S7>/Switch' */
  }

  /* End of Switch: '<S3>/MIL_Fault_Id_Zero' */

  /* Switch: '<S8>/pos_cnt_hold_sel' incorporates:
   *  Constant: '<S8>/Constant1'
   *  Constant: '<S8>/Constant2'
   *  Sum: '<S8>/Add1'
   *  Switch: '<S8>/spd_cnt_next_sel'
   *  UnitDelay: '<S8>/spd_cnt_z'
   */
  if (rtb_Compare) {
    /* Switch: '<S8>/pos_cnt_update_sel' incorporates:
     *  Constant: '<S8>/Constant3'
     *  Constant: '<S8>/Constant4'
     *  Sum: '<S8>/Add2'
     *  UnitDelay: '<S8>/pos_cnt_z'
     */
    if (new_tick) {
      AXU5EV_R5_Runtime_DW.pos_cnt_z_DSTATE = 0.0;
    } else {
      AXU5EV_R5_Runtime_DW.pos_cnt_z_DSTATE++;
    }

    /* End of Switch: '<S8>/pos_cnt_update_sel' */
    AXU5EV_R5_Runtime_DW.spd_cnt_z_DSTATE = 0.0;
  } else {
    AXU5EV_R5_Runtime_DW.spd_cnt_z_DSTATE++;
  }

  /* End of Switch: '<S8>/pos_cnt_hold_sel' */
  /* End of Outputs for FunctionCallGenerator: '<Root>/Control_Tick_10kHz' */

  /* Outport: '<Root>/runtime_y' incorporates:
   *  DataTypeConversion: '<Root>/Status_Double_10'
   *  DataTypeConversion: '<Root>/Status_Double_11'
   *  DataTypeConversion: '<Root>/Status_Double_12'
   *  Inport: '<Root>/runtime_u'
   *  MATLAB Function: '<Root>/Host_Core'
   */
  AXU5EV_R5_Runtime_Y.runtime_y[2] = rtb_Software_Time_s;
  AXU5EV_R5_Runtime_Y.runtime_y[3] = AXU5EV_R5_Runtime_DW.Init_Done_p;
  AXU5EV_R5_Runtime_Y.runtime_y[4] = AXU5EV_R5_Runtime_DW.Init_State_Num_a;
  AXU5EV_R5_Runtime_Y.runtime_y[5] = AXU5EV_R5_Runtime_DW.id_init_ref_g;
  AXU5EV_R5_Runtime_Y.runtime_y[6] = AXU5EV_R5_Runtime_DW.Angle_Init_EN_d;
  AXU5EV_R5_Runtime_Y.runtime_y[7] = AXU5EV_R5_Runtime_DW.Theta_Offset_auto_h;
  AXU5EV_R5_Runtime_Y.runtime_y[8] = AXU5EV_R5_Runtime_DW.x_align_mm_latch_b;
  AXU5EV_R5_Runtime_Y.runtime_y[9] = rtb_Alignment_Ready;
  AXU5EV_R5_Runtime_Y.runtime_y[10] = rtb_Init_Done_Or_Bypass;
  AXU5EV_R5_Runtime_Y.runtime_y[11] = rtb_Alignment_Fault_Active;
  AXU5EV_R5_Runtime_Y.runtime_y[12] = V;
  AXU5EV_R5_Runtime_Y.runtime_y[13] = 48.0;
  AXU5EV_R5_Runtime_Y.runtime_y[14] = 0.0;
  AXU5EV_R5_Runtime_Y.runtime_y[15] = Close_Loop_EN;
  AXU5EV_R5_Runtime_Y.runtime_y[16] = Position_Loop_EN;
  AXU5EV_R5_Runtime_Y.runtime_y[17] = PWM_EN;
  AXU5EV_R5_Runtime_Y.runtime_y[18] = rtb_v_ref_cmd;
  AXU5EV_R5_Runtime_Y.runtime_y[19] = AXU5EV_R5_Runtime_U.runtime_u[2];
  AXU5EV_R5_Runtime_Y.runtime_y[20] = q;
  AXU5EV_R5_Runtime_Y.runtime_y[21] = rtb_iq_test_ref;
  AXU5EV_R5_Runtime_Y.runtime_y[22] = PI_Reset_EN;
  AXU5EV_R5_Runtime_Y.runtime_y[23] = AXU5EV_R5_Runtime_DW.move_state[3];
  AXU5EV_R5_Runtime_Y.runtime_y[24] = AXU5EV_R5_Runtime_DW.move_state[5];
  AXU5EV_R5_Runtime_Y.runtime_y[25] = AXU5EV_R5_Runtime_DW.move_state[7];
  AXU5EV_R5_Runtime_Y.runtime_y[26] = AXU5EV_R5_Runtime_DW.move_state[9];
  AXU5EV_R5_Runtime_Y.runtime_y[27] = AXU5EV_R5_Runtime_DW.move_state[2];
  AXU5EV_R5_Runtime_Y.runtime_y[28] = AXU5EV_R5_Runtime_DW.move_state[4];
  AXU5EV_R5_Runtime_Y.runtime_y[29] = AXU5EV_R5_Runtime_DW.move_state[6];
  AXU5EV_R5_Runtime_Y.runtime_y[30] = AXU5EV_R5_Runtime_DW.move_state[20];
  AXU5EV_R5_Runtime_Y.runtime_y[31] = AXU5EV_R5_Runtime_DW.move_state[10];
  AXU5EV_R5_Runtime_Y.runtime_y[32] = AXU5EV_R5_Runtime_DW.move_state[11];
  AXU5EV_R5_Runtime_Y.runtime_y[33] = AXU5EV_R5_Runtime_DW.move_state[19];
  AXU5EV_R5_Runtime_Y.runtime_y[34] = AXU5EV_R5_Runtime_DW.move_state[18];
  AXU5EV_R5_Runtime_Y.runtime_y[35] = AXU5EV_R5_Runtime_DW.move_state[12];
  AXU5EV_R5_Runtime_Y.runtime_y[36] = 10.0;
  AXU5EV_R5_Runtime_Y.runtime_y[37] = 100.0;
  AXU5EV_R5_Runtime_Y.runtime_y[38] = 1000.0;
  AXU5EV_R5_Runtime_Y.runtime_y[39] = 0.1;
  AXU5EV_R5_Runtime_Y.runtime_y[40] = 0.0001;

  /* Sum: '<Root>/Next_Tick' incorporates:
   *  Constant: '<Root>/One_Tick'
   *  UnitDelay: '<Root>/Software_Tick'
   */
  AXU5EV_R5_Runtime_DW.Software_Tick_DSTATE++;
}

/* Model initialize function */
void AXU5EV_R5_Runtime_initialize(void)
{
  AXU5EV_R5_Runtime_PrevZCX.Position_Loop_Trig_ZCE = POS_ZCSIG;
  AXU5EV_R5_Runtime_PrevZCX.Speed_Loop_Trig_ZCE = POS_ZCSIG;
}

/* Model terminate function */
void AXU5EV_R5_Runtime_terminate(void)
{
  /* (no terminate code required) */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
