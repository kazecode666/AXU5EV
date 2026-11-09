#include "numeric_adapter.h"
#include "encoder_position_speed.h"
void encoder_feedback_numeric(const unsigned int p[41],double *position,double *speed,
 bool *position_valid,bool *speed_valid,unsigned char *history,unsigned int *status,long long *continuous){
 unsigned long long tick=((unsigned long long)p[5]<<32)|p[4];
 encoder_position_speed(p[16],p[3],tick,(p[2]&(1u<<9))!=0,p[20],p[35],p[37]!=0,
  p[34],p[40],false,position,speed,position_valid,speed_valid,history,status,continuous);
}
