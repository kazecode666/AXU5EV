#include "AXU5EV_R5_Runtime.h"
#include "ax01b_r5_bridge.h"
#include <string.h>
void ax01b_runtime_init(void)
{
    /* A new Simulink Run is a fresh generated-program instance. Pause is not. */
    memset(&AXU5EV_R5_Runtime_DW,0,sizeof(AXU5EV_R5_Runtime_DW));
    memset(&AXU5EV_R5_Runtime_PrevZCX,0,sizeof(AXU5EV_R5_Runtime_PrevZCX));
    memset(&AXU5EV_R5_Runtime_U,0,sizeof(AXU5EV_R5_Runtime_U));
    memset(&AXU5EV_R5_Runtime_Y,0,sizeof(AXU5EV_R5_Runtime_Y));
    AXU5EV_R5_Runtime_initialize();
}
void ax01b_runtime_step(const double *u)
{
    memcpy(AXU5EV_R5_Runtime_U.runtime_u,u,20*sizeof(double));
    AXU5EV_R5_Runtime_step();
}
void ax01b_runtime_output(double *y)
{
    memcpy(y,AXU5EV_R5_Runtime_Y.runtime_y,41*sizeof(double));
}
void ax01b_runtime_end(void) { AXU5EV_R5_Runtime_terminate(); }
