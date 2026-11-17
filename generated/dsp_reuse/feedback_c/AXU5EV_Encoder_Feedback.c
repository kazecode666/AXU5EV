/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: AXU5EV_Encoder_Feedback.c
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

#include "AXU5EV_Encoder_Feedback.h"
#include <stdint.h>
#include <stdbool.h>

/* Block signals and states (default storage) */
DW_AXU5EV_Encoder_Feedback_T AXU5EV_Encoder_Feedback_DW;

/* External inputs (root inport signals with default storage) */
ExtU_AXU5EV_Encoder_Feedback_T AXU5EV_Encoder_Feedback_U;

/* External outputs (root outports fed by signals with default storage) */
ExtY_AXU5EV_Encoder_Feedback_T AXU5EV_Encoder_Feedback_Y;

/* Real-time model */
static RT_MODEL_AXU5EV_Encoder_Feedb_T AXU5EV_Encoder_Feedback_M_;
RT_MODEL_AXU5EV_Encoder_Feedb_T *const AXU5EV_Encoder_Feedback_M =
  &AXU5EV_Encoder_Feedback_M_;

/* Model step function */
void AXU5EV_Encoder_Feedback_step(void)
{
  double rtb_Nanometres_To_Millimetres;
  int64_t delta;
  int64_t rtb_origin_count;
  uint64_t id_delta;
  uint64_t qY;
  uint64_t tick_delta;
  int32_t i;
  int32_t rtb_Mechanical_Direction;
  bool advance;
  bool guard1;
  bool guard2;
  bool guard3;
  bool guard4;
  bool rtb_restart_history;
  bool tmp;

  /* MATLAB Function: '<S1>/Frame_And_Count_Guard' */
  AXU5EV_Encoder_Feedback_Y.continuous_count = AXU5EV_Encoder_Feedback_DW.total;
  rtb_origin_count = AXU5EV_Encoder_Feedback_DW.origin;
  advance = false;
  rtb_restart_history = false;

  /* Outport: '<Root>/position_valid' incorporates:
   *  MATLAB Function: '<S1>/Frame_And_Count_Guard'
   */
  AXU5EV_Encoder_Feedback_Y.position_valid = false;

  /* MATLAB Function: '<S1>/Frame_And_Count_Guard' incorporates:
   *  Inport: '<Root>/config_version'
   *  Inport: '<Root>/encoder_ready'
   *  Inport: '<Root>/illegal_count'
   *  Inport: '<Root>/nm_per_count'
   *  Inport: '<Root>/raw_count'
   *  Inport: '<Root>/reset'
   *  Inport: '<Root>/reverse'
   *  Inport: '<Root>/sample_id'
   *  Inport: '<Root>/sample_tick'
   *  Inport: '<Root>/zero_count'
   */
  AXU5EV_Encoder_Feedback_Y.speed_valid = false;
  AXU5EV_Encoder_Feedback_Y.status = 0U;
  if (AXU5EV_Encoder_Feedback_U.reset) {
    AXU5EV_Encoder_Feedback_DW.initialized = false;
    AXU5EV_Encoder_Feedback_DW.filled = 0U;
    AXU5EV_Encoder_Feedback_DW.total = INT64_C(0);
    AXU5EV_Encoder_Feedback_DW.origin = INT64_C(0);
    AXU5EV_Encoder_Feedback_Y.continuous_count = INT64_C(0);
    rtb_origin_count = INT64_C(0);

    /* Outport: '<Root>/history_count' */
    AXU5EV_Encoder_Feedback_Y.history_count = 0U;
    rtb_restart_history = true;
  } else if (!AXU5EV_Encoder_Feedback_U.encoder_ready ||
             (AXU5EV_Encoder_Feedback_U.nm_per_count == 0U)) {
    AXU5EV_Encoder_Feedback_DW.initialized = false;
    AXU5EV_Encoder_Feedback_DW.filled = 0U;

    /* Outport: '<Root>/history_count' */
    AXU5EV_Encoder_Feedback_Y.history_count = 0U;
    rtb_restart_history = true;
    AXU5EV_Encoder_Feedback_Y.status = 16U;
  } else {
    guard1 = false;
    guard2 = false;
    guard3 = false;
    guard4 = false;
    if (AXU5EV_Encoder_Feedback_DW.initialized) {
      if (AXU5EV_Encoder_Feedback_U.sample_id >=
          AXU5EV_Encoder_Feedback_DW.last_id) {
        id_delta = (uint64_t)AXU5EV_Encoder_Feedback_U.sample_id -
          /*MW:operator MISRA2012:D4.1 CERT-C:INT30-C 'Justifying MISRA C rule violation'*/
          /*MW:OvSatOk*/ AXU5EV_Encoder_Feedback_DW.last_id;
        if (id_delta > AXU5EV_Encoder_Feedback_U.sample_id) {
          id_delta = UINT64_C(0);
        }
      } else {
        id_delta = ((uint64_t)AXU5EV_Encoder_Feedback_U.sample_id -
                    AXU5EV_Encoder_Feedback_DW.last_id) + UINT64_C(4294967296);
      }

      if (AXU5EV_Encoder_Feedback_U.sample_tick >=
          AXU5EV_Encoder_Feedback_DW.last_tick) {
        tick_delta = AXU5EV_Encoder_Feedback_U.sample_tick -
          /*MW:operator MISRA2012:D4.1 CERT-C:INT30-C 'Justifying MISRA C rule violation'*/
          /*MW:OvSatOk*/ AXU5EV_Encoder_Feedback_DW.last_tick;
        if (tick_delta > AXU5EV_Encoder_Feedback_U.sample_tick) {
          tick_delta = UINT64_C(0);
        }
      } else {
        qY = (AXU5EV_Encoder_Feedback_U.sample_tick -
              AXU5EV_Encoder_Feedback_DW.last_tick) + UINT64_MAX;
        if (qY < UINT64_MAX - AXU5EV_Encoder_Feedback_DW.last_tick) {
          qY = UINT64_MAX;
        }

        tick_delta = qY + /*MW:OvSatOk*/ UINT64_C(1);
        if (qY + UINT64_C(1) < qY) {
          tick_delta = UINT64_MAX;
        }
      }

      if ((id_delta == UINT64_C(0)) && (tick_delta == UINT64_C(0))) {
        AXU5EV_Encoder_Feedback_Y.status = 2U;

        /* Outport: '<Root>/position_valid' */
        AXU5EV_Encoder_Feedback_Y.position_valid = true;
        if ((AXU5EV_Encoder_Feedback_U.raw_count !=
             AXU5EV_Encoder_Feedback_DW.last_raw) ||
            (AXU5EV_Encoder_Feedback_U.illegal_count !=
             AXU5EV_Encoder_Feedback_DW.last_bad)) {
          AXU5EV_Encoder_Feedback_DW.initialized = false;
          AXU5EV_Encoder_Feedback_DW.filled = 0U;

          /* Outport: '<Root>/position_valid' */
          AXU5EV_Encoder_Feedback_Y.position_valid = false;
          rtb_restart_history = true;
          AXU5EV_Encoder_Feedback_Y.status = 82U;
        }

        /* Outport: '<Root>/history_count' incorporates:
         *  Inport: '<Root>/illegal_count'
         *  Inport: '<Root>/raw_count'
         */
        AXU5EV_Encoder_Feedback_Y.history_count =
          AXU5EV_Encoder_Feedback_DW.filled;
      } else if (AXU5EV_Encoder_Feedback_U.illegal_count !=
                 AXU5EV_Encoder_Feedback_DW.last_bad) {
        AXU5EV_Encoder_Feedback_DW.initialized = false;
        AXU5EV_Encoder_Feedback_DW.filled = 0U;

        /* Outport: '<Root>/history_count' */
        AXU5EV_Encoder_Feedback_Y.history_count = 0U;
        rtb_restart_history = true;
        AXU5EV_Encoder_Feedback_Y.status = 16U;
      } else if ((id_delta != UINT64_C(500)) || (tick_delta != UINT64_C(5000)))
      {
        if ((id_delta == UINT64_C(0)) || (id_delta > UINT64_C(2147483647)) ||
            (id_delta - id_delta / UINT64_C(500) * UINT64_C(500) != UINT64_C(0))
            || (id_delta * UINT64_C(10) != tick_delta)) {
          AXU5EV_Encoder_Feedback_DW.initialized = false;
          AXU5EV_Encoder_Feedback_DW.filled = 0U;

          /* Outport: '<Root>/history_count' */
          AXU5EV_Encoder_Feedback_Y.history_count = 0U;
          rtb_restart_history = true;
          AXU5EV_Encoder_Feedback_Y.status = 80U;
        } else {
          AXU5EV_Encoder_Feedback_DW.filled = 0U;
          rtb_restart_history = true;
          AXU5EV_Encoder_Feedback_Y.status = 4U;
          guard4 = true;
        }
      } else {
        guard4 = true;
      }
    } else {
      AXU5EV_Encoder_Feedback_DW.total = AXU5EV_Encoder_Feedback_U.raw_count;
      if ((uint32_t)AXU5EV_Encoder_Feedback_DW.total > 2147483647U) {
        AXU5EV_Encoder_Feedback_DW.total -= INT64_C(4294967296);
      }

      AXU5EV_Encoder_Feedback_Y.status = 1U;
      AXU5EV_Encoder_Feedback_DW.filled = 0U;
      rtb_restart_history = true;
      guard3 = true;
    }

    if (guard4) {
      delta = (int64_t)AXU5EV_Encoder_Feedback_U.raw_count -
        AXU5EV_Encoder_Feedback_DW.last_raw;
      if (delta > INT64_C(2147483647)) {
        delta -= INT64_C(4294967296);
      } else if (delta < -INT64_C(2147483648)) {
        delta += INT64_C(4294967296);
      }

      if ((int32_t)delta == INT32_MIN) {
        AXU5EV_Encoder_Feedback_DW.initialized = false;
        AXU5EV_Encoder_Feedback_DW.filled = 0U;

        /* Outport: '<Root>/history_count' */
        AXU5EV_Encoder_Feedback_Y.history_count = 0U;
        rtb_restart_history = true;
        AXU5EV_Encoder_Feedback_Y.status = 48U;
      } else {
        if ((AXU5EV_Encoder_Feedback_DW.total < INT64_C(0)) && (delta <
             INT64_MIN - AXU5EV_Encoder_Feedback_DW.total)) {
          AXU5EV_Encoder_Feedback_DW.total = INT64_MIN;
        } else if ((AXU5EV_Encoder_Feedback_DW.total > INT64_C(0)) && (delta >
                    INT64_MAX - AXU5EV_Encoder_Feedback_DW.total)) {
          AXU5EV_Encoder_Feedback_DW.total = INT64_MAX;
        } else {
          AXU5EV_Encoder_Feedback_DW.total += delta;
        }

        guard3 = true;
      }
    }

    if (guard3) {
      tmp = (!AXU5EV_Encoder_Feedback_DW.initialized ||
             (AXU5EV_Encoder_Feedback_U.zero_count !=
              AXU5EV_Encoder_Feedback_DW.old_zero));
      if (tmp || (AXU5EV_Encoder_Feedback_U.reverse !=
                  AXU5EV_Encoder_Feedback_DW.old_reverse) ||
          (AXU5EV_Encoder_Feedback_U.config_version !=
           AXU5EV_Encoder_Feedback_DW.old_version) ||
          (AXU5EV_Encoder_Feedback_U.nm_per_count !=
           AXU5EV_Encoder_Feedback_DW.old_scale)) {
        if (tmp) {
          delta = (int64_t)AXU5EV_Encoder_Feedback_U.raw_count -
            AXU5EV_Encoder_Feedback_U.zero_count;
          if (delta > INT64_C(2147483647)) {
            delta -= INT64_C(4294967296);
          } else if (delta < -INT64_C(2147483648)) {
            delta += INT64_C(4294967296);
          }

          if ((int32_t)delta == INT32_MIN) {
            AXU5EV_Encoder_Feedback_DW.initialized = false;
            AXU5EV_Encoder_Feedback_DW.filled = 0U;

            /* Outport: '<Root>/history_count' */
            AXU5EV_Encoder_Feedback_Y.history_count = 0U;
            rtb_restart_history = true;
            AXU5EV_Encoder_Feedback_Y.status = 48U;
          } else {
            if ((AXU5EV_Encoder_Feedback_DW.total >= INT64_C(0)) && (delta <
                 AXU5EV_Encoder_Feedback_DW.total - INT64_MAX)) {
              AXU5EV_Encoder_Feedback_DW.origin = INT64_MAX;
            } else if ((AXU5EV_Encoder_Feedback_DW.total < INT64_C(0)) && (delta
                        > AXU5EV_Encoder_Feedback_DW.total - INT64_MIN)) {
              AXU5EV_Encoder_Feedback_DW.origin = INT64_MIN;
            } else {
              AXU5EV_Encoder_Feedback_DW.origin =
                AXU5EV_Encoder_Feedback_DW.total - delta;
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
      if (AXU5EV_Encoder_Feedback_DW.initialized) {
        AXU5EV_Encoder_Feedback_Y.status |= 8U;
      }

      AXU5EV_Encoder_Feedback_DW.filled = 0U;
      rtb_restart_history = true;
      guard1 = true;
    }

    if (guard1) {
      AXU5EV_Encoder_Feedback_DW.initialized = true;
      AXU5EV_Encoder_Feedback_DW.last_raw = AXU5EV_Encoder_Feedback_U.raw_count;
      AXU5EV_Encoder_Feedback_DW.last_id = AXU5EV_Encoder_Feedback_U.sample_id;
      AXU5EV_Encoder_Feedback_DW.last_tick =
        AXU5EV_Encoder_Feedback_U.sample_tick;
      AXU5EV_Encoder_Feedback_DW.last_bad =
        AXU5EV_Encoder_Feedback_U.illegal_count;
      AXU5EV_Encoder_Feedback_DW.old_zero = AXU5EV_Encoder_Feedback_U.zero_count;
      AXU5EV_Encoder_Feedback_DW.old_reverse = AXU5EV_Encoder_Feedback_U.reverse;
      AXU5EV_Encoder_Feedback_DW.old_version =
        AXU5EV_Encoder_Feedback_U.config_version;
      AXU5EV_Encoder_Feedback_DW.old_scale =
        AXU5EV_Encoder_Feedback_U.nm_per_count;
      if (AXU5EV_Encoder_Feedback_DW.filled < 51) {
        AXU5EV_Encoder_Feedback_DW.filled++;
      }

      AXU5EV_Encoder_Feedback_Y.continuous_count =
        AXU5EV_Encoder_Feedback_DW.total;
      rtb_origin_count = AXU5EV_Encoder_Feedback_DW.origin;
      advance = true;

      /* Outport: '<Root>/position_valid' incorporates:
       *  Inport: '<Root>/config_version'
       *  Inport: '<Root>/illegal_count'
       *  Inport: '<Root>/nm_per_count'
       *  Inport: '<Root>/raw_count'
       *  Inport: '<Root>/reverse'
       *  Inport: '<Root>/sample_id'
       *  Inport: '<Root>/sample_tick'
       *  Inport: '<Root>/zero_count'
       */
      AXU5EV_Encoder_Feedback_Y.position_valid = true;
      AXU5EV_Encoder_Feedback_Y.speed_valid = (AXU5EV_Encoder_Feedback_DW.filled
        == 51);

      /* Outport: '<Root>/history_count' */
      AXU5EV_Encoder_Feedback_Y.history_count =
        AXU5EV_Encoder_Feedback_DW.filled;
    }
  }

  /* Sum: '<S1>/Continuous_Position_Count' */
  rtb_origin_count = AXU5EV_Encoder_Feedback_Y.continuous_count -
    rtb_origin_count;

  /* Gain: '<S1>/Nanometres_To_Millimetres' incorporates:
   *  DataTypeConversion: '<S1>/Scale_To_Double'
   *  Inport: '<Root>/nm_per_count'
   */
  rtb_Nanometres_To_Millimetres = 1.0E-6 * (double)
    AXU5EV_Encoder_Feedback_U.nm_per_count;

  /* Switch: '<S1>/Mechanical_Direction' incorporates:
   *  Constant: '<S1>/Forward_Direction'
   *  Constant: '<S1>/Reverse_Direction'
   *  Inport: '<Root>/reverse'
   */
  if (AXU5EV_Encoder_Feedback_U.reverse) {
    rtb_Mechanical_Direction = -1;
  } else {
    rtb_Mechanical_Direction = 1;
  }

  /* End of Switch: '<S1>/Mechanical_Direction' */

  /* Switch: '<S1>/Reset_Position' incorporates:
   *  Constant: '<S1>/Zero'
   *  Inport: '<Root>/reset'
   *  Switch: '<S1>/New_Frame_Position'
   *  UnitDelay: '<S1>/Position_Hold'
   */
  if (AXU5EV_Encoder_Feedback_U.reset) {
    AXU5EV_Encoder_Feedback_Y.position_mm = 0.0;
  } else if (advance) {
    /* UnitDelay: '<S1>/Position_Hold' incorporates:
     *  DataTypeConversion: '<S1>/Position_Count_To_Double'
     *  Product: '<S1>/Position_Millimetres'
     *  Sum: '<S1>/Continuous_Position_Count'
     *  Switch: '<S1>/New_Frame_Position'
     */
    AXU5EV_Encoder_Feedback_Y.position_mm = (double)rtb_origin_count *
      rtb_Nanometres_To_Millimetres * (double)rtb_Mechanical_Direction;
  }

  /* End of Switch: '<S1>/Reset_Position' */

  /* Delay: '<S1>/Delay_50_Intervals' incorporates:
   *  Sum: '<S1>/Continuous_Position_Count'
   */
  if (advance) {
    AXU5EV_Encoder_Feedback_DW.icLoad = (rtb_restart_history ||
      AXU5EV_Encoder_Feedback_DW.icLoad);
    if (AXU5EV_Encoder_Feedback_DW.icLoad) {
      for (i = 0; i < 50; i++) {
        AXU5EV_Encoder_Feedback_DW.Delay_50_Intervals_DSTATE[i] =
          rtb_origin_count;
      }
    }

    /* Delay: '<S1>/Delay_50_Intervals' incorporates:
     *  Sum: '<S1>/Continuous_Position_Count'
     */
    AXU5EV_Encoder_Feedback_DW.Delay_50_Intervals =
      AXU5EV_Encoder_Feedback_DW.Delay_50_Intervals_DSTATE[0];
  }

  /* End of Delay: '<S1>/Delay_50_Intervals' */

  /* Switch: '<S1>/Qualified_Speed' */
  if (AXU5EV_Encoder_Feedback_Y.speed_valid) {
    /* Outport: '<Root>/speed_mm_s' incorporates:
     *  DataTypeConversion: '<S1>/Difference_To_Double'
     *  Delay: '<S1>/Delay_50_Intervals'
     *  Gain: '<S1>/Five_Millisecond_Speed'
     *  Product: '<S1>/Displacement_Millimetres'
     *  Sum: '<S1>/Continuous_Position_Count'
     *  Sum: '<S1>/Count_Difference_50_Intervals'
     */
    AXU5EV_Encoder_Feedback_Y.speed_mm_s = (double)(rtb_origin_count -
      AXU5EV_Encoder_Feedback_DW.Delay_50_Intervals) *
      rtb_Nanometres_To_Millimetres * (double)rtb_Mechanical_Direction * 200.0;
  } else {
    /* Outport: '<Root>/speed_mm_s' incorporates:
     *  Constant: '<S1>/Zero'
     */
    AXU5EV_Encoder_Feedback_Y.speed_mm_s = 0.0;
  }

  /* End of Switch: '<S1>/Qualified_Speed' */

  /* Update for Delay: '<S1>/Delay_50_Intervals' incorporates:
   *  Sum: '<S1>/Continuous_Position_Count'
   */
  if (advance) {
    AXU5EV_Encoder_Feedback_DW.icLoad = false;
    for (rtb_Mechanical_Direction = 0; rtb_Mechanical_Direction < 49;
         rtb_Mechanical_Direction++) {
      AXU5EV_Encoder_Feedback_DW.Delay_50_Intervals_DSTATE[rtb_Mechanical_Direction]
        =
        AXU5EV_Encoder_Feedback_DW.Delay_50_Intervals_DSTATE[rtb_Mechanical_Direction
        + 1];
    }

    AXU5EV_Encoder_Feedback_DW.Delay_50_Intervals_DSTATE[49] = rtb_origin_count;
  }

  /* End of Update for Delay: '<S1>/Delay_50_Intervals' */
}

/* Model initialize function */
void AXU5EV_Encoder_Feedback_initialize(void)
{
  /* InitializeConditions for Delay: '<S1>/Delay_50_Intervals' */
  AXU5EV_Encoder_Feedback_DW.icLoad = true;
}

/* Model terminate function */
void AXU5EV_Encoder_Feedback_terminate(void)
{
  /* (no terminate code required) */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
