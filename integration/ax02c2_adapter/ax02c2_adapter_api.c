#include "ax02c2_adapter_api.h"
#include "AX02C2_Adapter.h"
#include <string.h>

void ax02c2_adapter_init(void)
{
    memset(&AX02C2_Adapter_U,0,sizeof(AX02C2_Adapter_U));
    memset(&AX02C2_Adapter_Y,0,sizeof(AX02C2_Adapter_Y));
    AX02C2_Adapter_initialize();
}

void ax02c2_adapter_pack(const double input20[20],const double runtime41[41],
                        const double feedback5[5],uint32_t words11[11])
{
    uint64_t theta,omega;
    const double *q=AX02C2_Adapter_Y.frame_q;
    /* Copy the source model's control ports, not the unrelated command and
     * diagnostic fields. Keep Init_Reset/Init_Done even though the current
     * generated step folds them away. Selection and quantization stay in
     * the unchanged generated model C.
     */
    AX02C2_Adapter_U.runtime_u[15]=input20[15]; /* Alignment_Enable */
    AX02C2_Adapter_U.runtime_u[17]=input20[17]; /* Init_Reset */
    AX02C2_Adapter_U.runtime_u[18]=input20[18]; /* travel_fault_latch */
    AX02C2_Adapter_U.runtime_u[19]=input20[19]; /* x_mm */
    AX02C2_Adapter_U.runtime_y[0]=runtime41[0]; /* id_ref */
    AX02C2_Adapter_U.runtime_y[1]=runtime41[1]; /* iq_ref */
    AX02C2_Adapter_U.runtime_y[3]=runtime41[3]; /* Init_Done */
    AX02C2_Adapter_U.runtime_y[6]=runtime41[6]; /* Angle_Init_EN */
    AX02C2_Adapter_U.runtime_y[7]=runtime41[7]; /* Theta_Offset_auto */
    AX02C2_Adapter_U.runtime_y[13]=runtime41[13]; /* Vdc */
    AX02C2_Adapter_U.runtime_y[17]=runtime41[17]; /* PWM request */
    AX02C2_Adapter_U.runtime_y[22]=runtime41[22]; /* PI_Reset request */
    memcpy(AX02C2_Adapter_U.feedback,feedback5,5*sizeof(double));
    AX02C2_Adapter_step();
    /* q already passed the copied Convergent/Saturate model conversions.
     * Multiplication by powers of two and integer splitting are exact ABI
     * encoding, not a second implementation of selection/quantization.
     */
    words11[0]=(uint32_t)(int32_t)(q[0]*16777216.0);
    words11[1]=(uint32_t)(int32_t)(q[1]*16777216.0);
    words11[2]=(uint32_t)(int32_t)(q[2]*16777216.0);
    theta=(uint64_t)(int64_t)(q[3]*4294967296.0);
    omega=(uint64_t)(int64_t)(q[4]*16777216.0);
    words11[3]=(uint32_t)theta;words11[4]=(uint32_t)(theta>>32)&255U;
    words11[5]=(uint32_t)omega;words11[6]=(uint32_t)(omega>>32)&255U;
    words11[7]=(uint32_t)(int32_t)(q[5]*16777216.0);
    words11[8]=(uint32_t)(int32_t)(q[6]*16777216.0);
    words11[9]=(uint32_t)q[7];
    words11[10]=(uint32_t)(q[8]*16777216.0);
}
