/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: AXU5EV_Motor_Control_System.h
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

#ifndef AXU5EV_Motor_Control_System_h_
#define AXU5EV_Motor_Control_System_h_
#ifndef AXU5EV_Motor_Control_System_COMMON_INCLUDES_
#define AXU5EV_Motor_Control_System_COMMON_INCLUDES_
#include <stdbool.h>
#include <stdint.h>
#include "complex_types.h"
#include "rt_nonfinite.h"
#include "math.h"
#endif                        /* AXU5EV_Motor_Control_System_COMMON_INCLUDES_ */

#include "AXU5EV_Motor_Control_System_types.h"
#include "rtGetInf.h"
#include "rtGetNaN.h"
#include <stddef.h>
#include <string.h>
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
  double LatestTelemetry[12];          /* '<Root>/LatestTelemetry' */
  double move_state[22];               /* '<S9>/Host_Core' */
  double PI_Reset_Output;              /* '<S22>/PI_Reset_Output' */
  double obs_v_ref_pos;                /* '<S19>/Saturation' */
  double Init_Done;                    /* '<S17>/Angle_Init' */
  double Init_State_Num;               /* '<S17>/Angle_Init' */
  double id_init_ref;                  /* '<S17>/Angle_Init' */
  double Angle_Init_EN;                /* '<S17>/Angle_Init' */
  double Theta_Offset_auto;            /* '<S17>/Angle_Init' */
  double x_align_mm_latch;             /* '<S17>/Angle_Init' */
  double Init_Done_p;                  /* '<S17>/Angle_Init' */
  double Init_State_Num_a;             /* '<S17>/Angle_Init' */
  double id_init_ref_g;                /* '<S17>/Angle_Init' */
  double Angle_Init_EN_d;              /* '<S17>/Angle_Init' */
  double Theta_Offset_auto_h;          /* '<S17>/Angle_Init' */
  double x_align_mm_latch_b;           /* '<S17>/Angle_Init' */
  double Position_Hold_DSTATE;         /* '<S7>/Position_Hold' */
  double Software_Tick_DSTATE;         /* '<S9>/Software_Tick' */
  double Travel_Fault_State_DSTATE;    /* '<S16>/Travel_Fault_State' */
  double spd_cnt_z_DSTATE;             /* '<S21>/spd_cnt_z' */
  double pos_cnt_z_DSTATE;             /* '<S21>/pos_cnt_z' */
  double v_ref_set_lim_z_DSTATE;       /* '<S24>/v_ref_set_lim_z' */
  double x_s_z_DSTATE;                 /* '<S22>/x_s_z' */
  double UnitDelay_DSTATE;             /* '<S22>/Unit Delay' */
  double theta_offset_mem;             /* '<S17>/Angle_Init' */
  int64_t Delay_50_Intervals_DSTATE[50];/* '<S7>/Delay_50_Intervals' */
  int64_t Delay_50_Intervals;          /* '<S7>/Delay_50_Intervals' */
  int64_t total;                       /* '<S7>/Frame_And_Count_Guard' */
  int64_t origin;                      /* '<S7>/Frame_And_Count_Guard' */
  uint64_t last_tick;                  /* '<S7>/Frame_And_Count_Guard' */
  uint32_t Service_Count_State_DSTATE; /* '<S3>/Service_Count_State' */
  uint32_t version;                    /* '<S2>/Reference_Commit' */
  uint32_t last_id;                    /* '<S2>/Reference_Commit' */
  uint32_t temporalCounter_i1;         /* '<S17>/Angle_Init' */
  uint32_t last_raw;                   /* '<S7>/Frame_And_Count_Guard' */
  uint32_t last_id_l;                  /* '<S7>/Frame_And_Count_Guard' */
  uint32_t last_bad;                   /* '<S7>/Frame_And_Count_Guard' */
  uint32_t old_zero;                   /* '<S7>/Frame_And_Count_Guard' */
  uint32_t old_version;                /* '<S7>/Frame_And_Count_Guard' */
  uint32_t old_scale;                  /* '<S7>/Frame_And_Count_Guard' */
  uint8_t is_active_c3_AXU5EV_Motor_Contr;/* '<S17>/Angle_Init' */
  uint8_t is_c3_AXU5EV_Motor_Control_Syst;/* '<S17>/Angle_Init' */
  uint8_t filled;                      /* '<S7>/Frame_And_Count_Guard' */
  bool External_Fault_Latch_Z_DSTATE;  /* '<S11>/External_Fault_Latch_Z' */
  bool Initialized;                    /* '<Root>/Initialized' */
  bool icLoad;                         /* '<S7>/Delay_50_Intervals' */
  bool fault;                         /* '<S2>/Frame_And_Fault_Qualification' */
  bool initialized;                    /* '<S7>/Frame_And_Count_Guard' */
  bool old_reverse;                    /* '<S7>/Frame_And_Count_Guard' */
} DW_AXU5EV_Motor_Control_Syste_T;

/* Zero-crossing (trigger) state */
typedef struct {
  ZCSigState Speed_Loop_Trig_ZCE;      /* '<S16>/Speed_Loop' */
  ZCSigState Position_Loop_Trig_ZCE;   /* '<S16>/Position_Loop' */
} PrevZCX_AXU5EV_Motor_Control__T;

/* Invariant block signals (default storage) */
typedef struct {
  const double Mechanical_Direction;   /* '<S7>/Mechanical_Direction' */
  const double Scale_To_Double;        /* '<S7>/Scale_To_Double' */
  const double Nanometres_To_Millimetres;/* '<S7>/Nanometres_To_Millimetres' */
} ConstB_AXU5EV_Motor_Control_S_T;

/* Constant parameters (default storage) */
typedef struct {
  /* Expression: [0;0;0;0;0;0;1;0]
   * Referenced by: '<S2>/reference_commit'
   */
  double reference_commit_Y0[8];
} ConstP_AXU5EV_Motor_Control_S_T;

/* External inputs (root inport signals with default storage) */
typedef struct {
  double CommandFrame[20];             /* '<Root>/CommandFrame' */
  uint32_t raw_count;                  /* '<Root>/raw_count' */
  uint32_t sample_id;                  /* '<Root>/sample_id' */
  uint64_t sample_tick;                /* '<Root>/sample_tick' */
  bool encoder_ready;                  /* '<Root>/encoder_ready' */
  uint32_t illegal_count;              /* '<Root>/illegal_count' */
  bool current_valid;                  /* '<Root>/current_valid' */
  bool ERRI_n;                         /* '<Root>/ERRI_n' */
  bool ERRU_n;                         /* '<Root>/ERRU_n' */
  bool clear_fault;                    /* '<Root>/clear_fault' */
  bool request_relcon;                 /* '<Root>/request_relcon' */
  bool request_encon;                  /* '<Root>/request_encon' */
  bool request_freset;                 /* '<Root>/request_freset' */
  bool request_oe_disable;             /* '<Root>/request_oe_disable' */
} ExtU_AXU5EV_Motor_Control_Sys_T;

/* External outputs (root outports fed by signals with default storage) */
typedef struct {
  double runtime_frame[41];            /* '<Root>/runtime_frame' */
  double position_mm;                  /* '<Root>/position_mm' */
  double speed_mm_s;                   /* '<Root>/speed_mm_s' */
  bool position_valid;                 /* '<Root>/position_valid' */
  bool speed_valid;                    /* '<Root>/speed_valid' */
  uint8_t history_count;               /* '<Root>/history_count' */
  uint32_t feedback_status;            /* '<Root>/feedback_status' */
  int64_t continuous_count;            /* '<Root>/continuous_count' */
  double reference_commit[8];          /* '<Root>/reference_commit' */
  uint32_t commit_sample_id;           /* '<Root>/commit_sample_id' */
  uint32_t reference_version;          /* '<Root>/reference_version' */
  bool drive_outputs[5];               /* '<Root>/drive_outputs' */
  double telemetry[12];                /* '<Root>/telemetry' */
  uint32_t service_count;              /* '<Root>/service_count' */
} ExtY_AXU5EV_Motor_Control_Sys_T;

/* Real-time Model Data Structure */
struct tag_RTM_AXU5EV_Motor_Control__T {
  const char * volatile errorStatus;
};

/* Block signals and states (default storage) */
extern DW_AXU5EV_Motor_Control_Syste_T AXU5EV_Motor_Control_System_DW;

/* Zero-crossing (trigger) state */
extern PrevZCX_AXU5EV_Motor_Control__T AXU5EV_Motor_Control_Sy_PrevZCX;

/* External inputs (root inport signals with default storage) */
extern ExtU_AXU5EV_Motor_Control_Sys_T AXU5EV_Motor_Control_System_U;

/* External outputs (root outports fed by signals with default storage) */
extern ExtY_AXU5EV_Motor_Control_Sys_T AXU5EV_Motor_Control_System_Y;
extern const ConstB_AXU5EV_Motor_Control_S_T AXU5EV_Motor_Control_Sys_ConstB;/* constant block i/o */

/* Constant parameters (default storage) */
extern const ConstP_AXU5EV_Motor_Control_S_T AXU5EV_Motor_Control_Sys_ConstP;

/* Model entry point functions */
extern void AXU5EV_Motor_Control_System_initialize(void);
extern void AXU5EV_Motor_Control_System_terminate(void);

/* Exported entry point function */
extern void PL_Frame_IRQ(void);

/* Exported entry point function */
extern void Service_Request(void);

/* Real-time Model object */
extern RT_MODEL_AXU5EV_Motor_Control_T *const AXU5EV_Motor_Control_System_M;

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
 * '<Root>' : 'AXU5EV_Motor_Control_System'
 * '<S1>'   : 'AXU5EV_Motor_Control_System/Initialize_Controller'
 * '<S2>'   : 'AXU5EV_Motor_Control_System/Motor_Control_ISR'
 * '<S3>'   : 'AXU5EV_Motor_Control_System/NonRealtime_Service'
 * '<S4>'   : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Bind_Real_Feedback'
 * '<S5>'   : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Capture_Latest_Observation'
 * '<S6>'   : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Controller_Driver_IO_Manager'
 * '<S7>'   : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Feedback_Measurement'
 * '<S8>'   : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Frame_And_Fault_Qualification'
 * '<S9>'   : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime'
 * '<S10>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Reference_Commit'
 * '<S11>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Controller_Driver_IO_Manager/External_Fault_Latch'
 * '<S12>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Controller_Driver_IO_Manager/System_Fault_Active'
 * '<S13>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Feedback_Measurement/Frame_And_Count_Guard'
 * '<S14>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Alignment_Task'
 * '<S15>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Host_Core'
 * '<S16>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Motion_Control'
 * '<S17>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Alignment_Task/Enabled_Original_MIL'
 * '<S18>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Alignment_Task/Enabled_Original_MIL/Angle_Init'
 * '<S19>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Motion_Control/Position_Loop'
 * '<S20>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Motion_Control/Reference_Manager'
 * '<S21>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Motion_Control/Scheduler_10k_1k_100'
 * '<S22>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Motion_Control/Speed_Loop'
 * '<S23>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Motion_Control/Travel_Safety_Manager'
 * '<S24>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Motion_Control/Reference_Manager/v_ref_set_slew_limiter'
 * '<S25>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Motion_Control/Scheduler_10k_1k_100/pos_tc'
 * '<S26>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Motion_Control/Scheduler_10k_1k_100/spd_tc'
 * '<S27>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Motion_Control/Speed_Loop/pi_reset_manager'
 * '<S28>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Motion_Control/Speed_Loop/pi_reset_manager/Compare To Constant1'
 * '<S29>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Motion_Control/Speed_Loop/pi_reset_manager/Compare To Constant2'
 * '<S30>'  : 'AXU5EV_Motor_Control_System/Motor_Control_ISR/Qualified_Runtime/Motion_Control/Speed_Loop/pi_reset_manager/Compare To Constant4'
 * '<S31>'  : 'AXU5EV_Motor_Control_System/NonRealtime_Service/Count_Service_Call'
 */
#endif                                 /* AXU5EV_Motor_Control_System_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
