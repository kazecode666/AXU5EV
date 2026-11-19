/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: AXU5EV_Motor_Control_System_private.h
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

#ifndef AXU5EV_Motor_Control_System_private_h_
#define AXU5EV_Motor_Control_System_private_h_
#include <stdbool.h>
#include <stdint.h>
#include "complex_types.h"
#include "zero_crossing_types.h"
#include "AXU5EV_Motor_Control_System_types.h"
#include "AXU5EV_Motor_Control_System.h"

extern double rt_powd_snf(double u0, double u1);
extern void mul_wide_u64(uint64_t in0, uint64_t in1, uint64_t *ptrOutBitsHi,
  uint64_t *ptrOutBitsLo);
extern uint64_t mul_u64_sat(uint64_t a, uint64_t b);

#endif                              /* AXU5EV_Motor_Control_System_private_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
