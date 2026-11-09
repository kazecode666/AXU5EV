#ifndef ENCODER_FEEDBACK_NUMERIC_ADAPTER_H
#define ENCODER_FEEDBACK_NUMERIC_ADAPTER_H
#include <stdbool.h>
/* Transport field map only. Every numerical operation remains generated. */
void encoder_feedback_numeric(const unsigned int p[41],double *position,double *speed,
 bool *position_valid,bool *speed_valid,unsigned char *history,unsigned int *status,long long *continuous);
#endif
