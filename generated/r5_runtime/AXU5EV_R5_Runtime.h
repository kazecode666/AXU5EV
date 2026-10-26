/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: AXU5EV_R5_Runtime.h
 *
 * Code generated for Simulink model 'AXU5EV_R5_Runtime'.
 *
 * Model version                  : 1.48
 * Simulink Coder version         : 26.2 (R2026b) 22-May-2026
 * C/C++ source code generated on : Mon Oct 26 17:02:00 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: Intel->x86-64 (Windows64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#ifndef AXU5EV_R5_Runtime_h_
#define AXU5EV_R5_Runtime_h_
#ifndef AXU5EV_R5_Runtime_COMMON_INCLUDES_
#define AXU5EV_R5_Runtime_COMMON_INCLUDES_
#include <stdbool.h>
#include <stdint.h>
#include "complex_types.h"
#include "rt_nonfinite.h"
#include "math.h"
#endif                                 /* AXU5EV_R5_Runtime_COMMON_INCLUDES_ */

#include "AXU5EV_R5_Runtime_types.h"
#include "rtGetInf.h"
#include "rtGetNaN.h"
#include "zero_crossing_types.h"

/* Macros for accessing real-time model data structure */
#ifndef rtmGetErrorStatus
#define rtmGetErrorStatus(rtm)         ((rtm)->errorStatus)
#endif

#ifndef rtmSetErrorStatus
#define rtmSetErrorStatus(rtm, val)    ((rtm)->errorStatus = (val))
#endif

/* Block signals and states (default storage) for system '<Root>' */
typedef struct {
  double move_state[22];               /* '<Root>/Host_Core' */
  double PI_Reset_Output;              /* '<S9>/PI_Reset_Output' */
  double obs_v_ref_pos;                /* '<S6>/Saturation' */
  double Init_Done;                    /* '<S4>/Angle_Init' */
  double Init_State_Num;               /* '<S4>/Angle_Init' */
  double id_init_ref;                  /* '<S4>/Angle_Init' */
  double Angle_Init_EN;                /* '<S4>/Angle_Init' */
  double Theta_Offset_auto;            /* '<S4>/Angle_Init' */
  double x_align_mm_latch;             /* '<S4>/Angle_Init' */
  double Init_Done_p;                  /* '<S4>/Angle_Init' */
  double Init_State_Num_a;             /* '<S4>/Angle_Init' */
  double id_init_ref_g;                /* '<S4>/Angle_Init' */
  double Angle_Init_EN_d;              /* '<S4>/Angle_Init' */
  double Theta_Offset_auto_h;          /* '<S4>/Angle_Init' */
  double x_align_mm_latch_b;           /* '<S4>/Angle_Init' */
  double Software_Tick_DSTATE;         /* '<Root>/Software_Tick' */
  double spd_cnt_z_DSTATE;             /* '<S8>/spd_cnt_z' */
  double pos_cnt_z_DSTATE;             /* '<S8>/pos_cnt_z' */
  double v_ref_set_lim_z_DSTATE;       /* '<S10>/v_ref_set_lim_z' */
  double x_s_z_DSTATE;                 /* '<S9>/x_s_z' */
  double UnitDelay_DSTATE;             /* '<S9>/Unit Delay' */
  double theta_offset_mem;             /* '<S4>/Angle_Init' */
  uint32_t temporalCounter_i1;         /* '<S4>/Angle_Init' */
  uint8_t is_active_c3_AXU5EV_R5_Runtime;/* '<S4>/Angle_Init' */
  uint8_t is_c3_AXU5EV_R5_Runtime;     /* '<S4>/Angle_Init' */
} DW_AXU5EV_R5_Runtime_T;

/* Zero-crossing (trigger) state */
typedef struct {
  ZCSigState Speed_Loop_Trig_ZCE;      /* '<S3>/Speed_Loop' */
  ZCSigState Position_Loop_Trig_ZCE;   /* '<S3>/Position_Loop' */
} PrevZCX_AXU5EV_R5_Runtime_T;

/* External inputs (root inport signals with default storage) */
typedef struct {
  double runtime_u[20];                /* '<Root>/runtime_u' */
} ExtU_AXU5EV_R5_Runtime_T;

/* External outputs (root outports fed by signals with default storage) */
typedef struct {
  double runtime_y[41];                /* '<Root>/runtime_y' */
} ExtY_AXU5EV_R5_Runtime_T;

/* Real-time Model Data Structure */
struct tag_RTM_AXU5EV_R5_Runtime_T {
  const char * volatile errorStatus;
};

/* Block signals and states (default storage) */
extern DW_AXU5EV_R5_Runtime_T AXU5EV_R5_Runtime_DW;

/* Zero-crossing (trigger) state */
extern PrevZCX_AXU5EV_R5_Runtime_T AXU5EV_R5_Runtime_PrevZCX;

/* External inputs (root inport signals with default storage) */
extern ExtU_AXU5EV_R5_Runtime_T AXU5EV_R5_Runtime_U;

/* External outputs (root outports fed by signals with default storage) */
extern ExtY_AXU5EV_R5_Runtime_T AXU5EV_R5_Runtime_Y;

/* Model entry point functions */
extern void AXU5EV_R5_Runtime_initialize(void);
extern void AXU5EV_R5_Runtime_step(void);
extern void AXU5EV_R5_Runtime_terminate(void);

/* Real-time Model object */
extern RT_MODEL_AXU5EV_R5_Runtime_T *const AXU5EV_R5_Runtime_M;

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
 * '<Root>' : 'AXU5EV_R5_Runtime'
 * '<S1>'   : 'AXU5EV_R5_Runtime/Alignment_Task'
 * '<S2>'   : 'AXU5EV_R5_Runtime/Host_Core'
 * '<S3>'   : 'AXU5EV_R5_Runtime/Motion_Control'
 * '<S4>'   : 'AXU5EV_R5_Runtime/Alignment_Task/Enabled_Original_MIL'
 * '<S5>'   : 'AXU5EV_R5_Runtime/Alignment_Task/Enabled_Original_MIL/Angle_Init'
 * '<S6>'   : 'AXU5EV_R5_Runtime/Motion_Control/Position_Loop'
 * '<S7>'   : 'AXU5EV_R5_Runtime/Motion_Control/Reference_Manager'
 * '<S8>'   : 'AXU5EV_R5_Runtime/Motion_Control/Scheduler_10k_1k_100'
 * '<S9>'   : 'AXU5EV_R5_Runtime/Motion_Control/Speed_Loop'
 * '<S10>'  : 'AXU5EV_R5_Runtime/Motion_Control/Reference_Manager/v_ref_set_slew_limiter'
 * '<S11>'  : 'AXU5EV_R5_Runtime/Motion_Control/Scheduler_10k_1k_100/pos_tc'
 * '<S12>'  : 'AXU5EV_R5_Runtime/Motion_Control/Scheduler_10k_1k_100/spd_tc'
 * '<S13>'  : 'AXU5EV_R5_Runtime/Motion_Control/Speed_Loop/pi_reset_manager'
 * '<S14>'  : 'AXU5EV_R5_Runtime/Motion_Control/Speed_Loop/pi_reset_manager/Compare To Constant1'
 * '<S15>'  : 'AXU5EV_R5_Runtime/Motion_Control/Speed_Loop/pi_reset_manager/Compare To Constant2'
 * '<S16>'  : 'AXU5EV_R5_Runtime/Motion_Control/Speed_Loop/pi_reset_manager/Compare To Constant4'
 */
#endif                                 /* AXU5EV_R5_Runtime_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
