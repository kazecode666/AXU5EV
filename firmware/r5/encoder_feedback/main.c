/* Offline ENCF observer: no FOC/Runtime, alignment, IRQ or power permission. */
#include "xil_io.h"
#include "xil_printf.h"
#include "xil_cache.h"
#include "encoder_feedback_hw.h"
#include "encoder_test_scale.h"
#include "encoder_position_speed.h"
#include "encoder_position_speed_initialize.h"
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>

volatile const uint32_t encoder_feedback_application_id=0x45464301u;
volatile const uint32_t encoder_feedback_mmio_base=ENCODER_FEEDBACK_BASEADDR;
extern char inbyte(void);
enum { WORDS=41, RECORDS=128 };
typedef struct {
 uint32_t seq,p[WORDS],numeric_status;double position_mm,speed_mm_s;
 int64_t continuous;uint8_t history;boolean_T position_valid,speed_valid;
} record_t;
static record_t records[RECORDS];
static unsigned recorded;
static uint32_t version,zero_count,phase_count,reverse,test_enable;
static uint32_t rd(uint32_t off){return Xil_In32(ENCODER_FEEDBACK_BASEADDR+off);}
static void wr(uint32_t off,uint32_t value){Xil_Out32(ENCODER_FEEDBACK_BASEADDR+off,value);}
static int snapshot(record_t *r){
 r->seq=rd(0);
 for(unsigned i=0;i<WORDS;i++)r->p[i]=rd(12+4*i);
 /* Word40 at0xac is the new LAST release response. Never use old0x88. */
 return r->p[0]==0x454e4346u && r->p[1]==2u && r->p[39]==ENCODER_COUNTS_PER_PERIOD && r->p[40]==ENCODER_NM_PER_COUNT;
}
static void numeric(record_t *r){
 uint64_t tick=((uint64_t)r->p[5]<<32)|r->p[4];
 encoder_position_speed(r->p[16],r->p[3],tick,(r->p[2]&(1u<<9))!=0,
   r->p[20],r->p[35],r->p[37]!=0,r->p[34],r->p[40],false,
   &r->position_mm,&r->speed_mm_s,&r->position_valid,&r->speed_valid,
   &r->history,&r->numeric_status,&r->continuous);
}
static void configure(void){
 wr(0x140,zero_count);wr(0x144,phase_count);wr(0x148,reverse);
 wr(0x14c,++version);wr(0x150,1u|(test_enable<<1));
 xil_printf("ENCF requested cfg=%lu zero=%08lx phase_count=%lu reverse=%lu TEST=%lu; adoption is at selected sample\r\n",
  (unsigned long)version,(unsigned long)zero_count,(unsigned long)phase_count,
  (unsigned long)reverse,(unsigned long)test_enable);
}
static void capture(void){
 uint32_t last=0;int have_last=0;unsigned attempts=0;recorded=0;
 /* CPU polling observes PL identity. No PS timer substitutes for sampling.
  * A repeated bank is skipped. Missed sample identities are rejected by the
  * generated history function, not hidden by the transport sequence. */
 while(recorded<RECORDS && attempts++<1000000u){
  record_t *r=&records[recorded];
  if(!snapshot(r)){xil_printf("ENCF identity/schema/scale missing; capture stopped\r\n");break;}
  if(have_last && r->seq==last)continue;
  last=r->seq;have_last=1;numeric(r);++recorded;
 }
 xil_printf("ENCF capture stopped records=%lu attempts=%lu; p prints after acquisition.\r\n",
  (unsigned long)recorded,(unsigned long)attempts);
}
static void print_records(void){
 xil_printf("seq,id,tick_hi,tick_lo,count,quality,z_count,z_tick_hi,z_tick_lo,illegal,theta_hi,theta_lo,cfg,position_mm,speed_mm_s,pv,sv,history,numeric_status\r\n");
 for(unsigned i=0;i<recorded;i++){
  const record_t *r=&records[i];
  /* Printing happens only after acquisition; printf supports the generated
   * double outputs without narrowing continuous positions to a 32-bit long. */
  printf("%lu,%lu,%08lx,%08lx,%08lx,%08lx,%08lx,%08lx,%08lx,%lu,%08lx,%08lx,%lu,%.9f,%.9f,%lu,%lu,%lu,%08lx\r\n",
   (unsigned long)r->seq,(unsigned long)r->p[3],(unsigned long)r->p[5],(unsigned long)r->p[4],
   (unsigned long)r->p[16],(unsigned long)r->p[2],(unsigned long)r->p[17],(unsigned long)r->p[19],
   (unsigned long)r->p[18],(unsigned long)r->p[20],(unsigned long)r->p[33],(unsigned long)r->p[32],
   (unsigned long)r->p[34],r->position_mm,r->speed_mm_s,
   (unsigned long)r->position_valid,(unsigned long)r->speed_valid,(unsigned long)r->history,(unsigned long)r->numeric_status);
 }
}
int main(void){
 Xil_DCacheDisable();Xil_ICacheEnable();encoder_position_speed_initialize();
 xil_printf("ENCODER_FEEDBACK 45464301 WAIT. TEST scale1000nm/count,30000count/electrical period; physical_link_verified=0\r\n");
 xil_printf("t=commit TEST start u=commit TEST stop z=zero at current frame q=phase+quarter d=reverse r=capture128 p=print s=one raw status\r\n");
 for(;;){
  char c=inbyte();
  switch(c){
   case 't':test_enable=1;configure();break;
   case 'u':test_enable=0;configure();break;
   case 'z':{record_t r;if(snapshot(&r)){zero_count=r.p[16];configure();}break;}
   case 'q':phase_count=(phase_count+ENCODER_COUNTS_PER_PERIOD/4u)%ENCODER_COUNTS_PER_PERIOD;configure();break;
   case 'd':reverse^=1u;configure();break;
   case 'r':capture();break;
   case 'p':print_records();break;
   case 's':{record_t r;if(snapshot(&r))xil_printf("ENCF sample=%lu raw=%08lx quality=%08lx cfg=%lu TEST=%lu physical=0\r\n",
    (unsigned long)r.p[3],(unsigned long)r.p[16],(unsigned long)r.p[2],(unsigned long)r.p[34],(unsigned long)((r.p[2]>>18)&1u));break;}
   default:break;
  }
 }
}
