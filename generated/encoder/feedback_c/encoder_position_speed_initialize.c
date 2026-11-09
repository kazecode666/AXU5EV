/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: encoder_position_speed_initialize.c
 *
 * MATLAB Coder version            : 26.2
 * C/C++ source code generated on  : 2026-11-09 12:02:50
 */

/* Include Files */
#include "encoder_position_speed_initialize.h"
#include "encoder_position_speed.h"
#include "encoder_position_speed_data.h"

/* Function Definitions */
/*
 * Arguments    : void
 * Return Type  : void
 */
void encoder_position_speed_initialize(void)
{
  encoder_position_speed_init();
  isInitialized_encoder_position_speed = true;
}

/*
 * File trailer for encoder_position_speed_initialize.c
 *
 * [EOF]
 */
