/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: encoder_position_speed.h
 *
 * MATLAB Coder version            : 26.2
 * C/C++ source code generated on  : 2026-11-09 12:02:50
 */

#ifndef ENCODER_POSITION_SPEED_H
#define ENCODER_POSITION_SPEED_H

/* Include Files */
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
extern void encoder_position_speed(
    unsigned int raw_count, unsigned int sample_id,
    unsigned long long sample_tick, bool encoder_ready,
    unsigned int illegal_count, unsigned int zero_count, bool reverse,
    unsigned int config_version, unsigned int nm_per_count, bool reset,
    double *position_mm, double *speed_mm_s, bool *position_valid,
    bool *speed_valid, unsigned char *history_count, unsigned int *status,
    long long *continuous_count);

void encoder_position_speed_init(void);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for encoder_position_speed.h
 *
 * [EOF]
 */
