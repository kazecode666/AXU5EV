/* Precommitted TEST references and observation only. No outer loop/alignment. */
#include "xil_io.h"
#include "xil_printf.h"
#include "xil_cache.h"
#include "encoder_feedback_hw.h"
#include "encoder_test_scale.h"
#include "encoder_position_speed.h"
#include "encoder_position_speed_initialize.h"
#include "numeric_adapter.h"
#include <stdint.h>
#include <stdio.h>

volatile const uint32_t motor_control_application_id=0x4d435401u;
volatile const uint32_t motor_control_mmio_base=ENCODER_FEEDBACK_BASEADDR;
extern char inbyte(void);
enum { WORDS=80, RECORDS=128 };
typedef struct {
 uint32_T seq,p[WORDS],status;double position,speed;
 long long continuous;unsigned char history;bool pv,sv;
} record_t;
static record_t records[RECORDS];
static unsigned recorded;
static uint32_t command_version,encoder_version;
static uint32_t iq=1677722u,omega,encoder_run;
static uint32_t rd(uint32_t off){return Xil_In32(ENCODER_FEEDBACK_BASEADDR+off);}
static void wr(uint32_t off,uint32_t v){Xil_Out32(ENCODER_FEEDBACK_BASEADDR+off,v);}
static int snapshot(record_t *r){
 r->seq=rd(0);r->p[0]=rd(12);r->p[1]=rd(16);
 if(r->p[0]!=0x4d435431u || r->p[1]!=3u)return 0;
 for(unsigned i=2;i<WORDS;i++)r->p[i]=rd(12+4*i);
 return r->p[39]==ENCODER_COUNTS_PER_PERIOD && r->p[40]==ENCODER_NM_PER_COUNT &&
   r->p[42]==r->p[3] && r->p[43]==r->p[4] && r->p[44]==r->p[5];
}
static void reference(unsigned arm){
 wr(0x180,0);wr(0x184,iq);wr(0x188,omega);wr(0x18c,0);
 wr(0x190,48u<<24);wr(0x194,0);wr(0x198,++command_version);
 wr(0x19c,arm);wr(0x1a0,1);
 xil_printf("MC requested ref=%lu iqQ24=%lu omegaQ24=%lu arm=%lu; wait captured version\r\n",
  (unsigned long)command_version,(unsigned long)iq,(unsigned long)omega,(unsigned long)arm);
}
static void encoder(void){
 wr(0x140,0);wr(0x144,0);wr(0x148,0);wr(0x14c,++encoder_version);
 wr(0x150,1u|(encoder_run<<1));
}
static void calibrate(void){
 wr(0x1a4,1); /* Immediate disarm, not a controller global reset. */
 wr(0x100,0);wr(0x104,0);wr(0x108,65536);wr(0x10c,65536);
 wr(0x110,4);wr(0x114,1);wr(0x118,5);
 xil_printf("MC digital TEST calibration N16/gain65536 requested; not physical current calibration\r\n");
}
static void capture(void){
 uint32_T last=0;unsigned attempts=0;int have=0;recorded=0;
 while(recorded<RECORDS && attempts++<1000000u){
  record_t *r=&records[recorded];
  if(!snapshot(r)){xil_printf("MC schema/scale absent; stopped\r\n");break;}
  if(have && last==r->seq)continue;
  have=1;last=r->seq;
  encoder_feedback_numeric(r->p,&r->position,&r->speed,&r->pv,&r->sv,
    &r->history,&r->status,&r->continuous);
  ++recorded;
 }
 xil_printf("MC capture stopped records=%lu attempts=%lu; p prints now\r\n",(unsigned long)recorded,(unsigned long)attempts);
}
static void print_records(void){
 xil_printf("sample,tickLo,count,quality,refVersion,focSample,offered,applied,dutyU,dutyV,dutyW,cmpU,cmpV,cmpW,flags,position_mm,speed_mm_s,pv,sv,history\r\n");
 for(unsigned i=0;i<recorded;i++){
  const record_t *r=&records[i];
  printf("%lu,%lu,%08lx,%08lx,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%08lx,%.9f,%.9f,%u,%u,%u\r\n",
   (unsigned long)r->p[3],(unsigned long)r->p[4],(unsigned long)r->p[16],(unsigned long)r->p[2],
   (unsigned long)r->p[45],(unsigned long)r->p[42],(unsigned long)r->p[63],(unsigned long)r->p[64],
   (unsigned long)r->p[57],(unsigned long)r->p[58],(unsigned long)r->p[59],
   (unsigned long)r->p[60],(unsigned long)r->p[61],(unsigned long)r->p[62],(unsigned long)r->p[41],
   r->position,r->speed,(unsigned)r->pv,(unsigned)r->sv,(unsigned)r->history);
 }
}
int main(void){
 Xil_DCacheDisable();Xil_ICacheEnable();encoder_position_speed_initialize();
 xil_printf("MOTOR_CONTROL 4d435401 WAIT; physical_link_verified=0; no automatic arm\r\n");
 xil_printf("c=TEST cal t=stationary precommit/arm j=iq.2step m=moving TEST/omega20.943951 d=disarm r=capture p=print s=status\r\n");
 for(;;){switch(inbyte()){
  case 'c':calibrate();break;
  case 't':encoder_run=0;omega=0;iq=1677722u;encoder();reference(1);break;
  case 'j':iq=3355443u;reference(1);break;
  case 'm':encoder_run=1;omega=351381190u;encoder();reference(1);break;
  case 'd':wr(0x1a4,1);break;
  case 'r':capture();break;
  case 'p':print_records();break;
  case 's':{record_t r;if(snapshot(&r))xil_printf("MC sample=%lu ref=%lu applied=%lu flags=%08lx physical=0\r\n",
   (unsigned long)r.p[3],(unsigned long)r.p[45],(unsigned long)r.p[64],(unsigned long)r.p[41]);break;}
  default:break;
 }}
}
