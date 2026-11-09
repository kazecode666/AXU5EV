/* Minimal offline observation app. No Runtime/FOC/interrupt scheduling. */
#include "xil_io.h"
#include "xil_printf.h"
#include "xil_cache.h"
#include "xparameters.h"
#include "pwm_adc_hw.h"
#include <stdint.h>

volatile const uint32_t pwm_adc_application_id=0x50574101u;
volatile const uint32_t pwm_adc_mmio_base=PWM_ADC_BASEADDR;
static uint32_t sequence;
extern char inbyte(void);
static uint32_t rd(uint32_t off){return Xil_In32(PWM_ADC_BASEADDR+off);}
static void wr(uint32_t off,uint32_t v){Xil_Out32(PWM_ADC_BASEADDR+off,v);}
static void status(void){
 xil_printf("PWM status=%08lx received=%lu adopted=%lu permit=%02lx cancel=%lu reject=%lu C=%lu,%lu,%lu\r\n",
 (unsigned long)rd(4),(unsigned long)rd(8),(unsigned long)rd(12),(unsigned long)rd(0x24),
 (unsigned long)rd(0x28),(unsigned long)rd(0x2c),(unsigned long)rd(0x30),
 (unsigned long)rd(0x34),(unsigned long)rd(0x38));
}
static void commit(uint32_t a,uint32_t b,uint32_t c){
 uint32_t s=rd(4);
 if((s&3u)!=1u){xil_printf("PWM not ready or busy; no commit\r\n");return;}
 wr(0x10,a);wr(0x14,b);wr(0x18,c);wr(0x1c,++sequence);wr(0x20,1);
 xil_printf("PWM requested seq=%lu (adoption is at a later valley)\r\n",(unsigned long)sequence);
}
static void adc_snapshot(void){
 uint32_t p[32];
 (void)Xil_In32(ADC_OBSERVER_BASEADDR);
 for(unsigned i=0;i<32;i++)p[i]=Xil_In32(ADC_OBSERVER_BASEADDR+12+4*i);
 xil_printf("ADC id=%lu tick50=%08lx:%08lx raw=%lu,%lu quality=%08lx count=%lu,%lu (no calibration commanded here)\r\n",
 (unsigned long)p[3],(unsigned long)p[5],(unsigned long)p[4],(unsigned long)p[6],
 (unsigned long)p[7],(unsigned long)p[2],(unsigned long)p[13],(unsigned long)p[14]);
}
static void permit(uint32_t mask){
 if(!(rd(4)&1u)){xil_printf("PWM offline: outputs disabled; permission not written\r\n");return;}
 wr(0x24,mask);
}
int main(void){
 Xil_DCacheDisable();Xil_ICacheEnable();
 xil_printf("PWM_ADC 50574101 WAIT. Internal observation only; no external gate pins.\r\n");
 xil_printf("s=status a=ADC snapshot p=25/50/75 t=75/25/50 e=enable d=disable h=upper only l=lower only\r\n");
 for(;;){
  char c=inbyte();
  if(c!='s'&&c!='a'&&c!='p'&&c!='t'&&c!='e'&&c!='d'&&c!='h'&&c!='l')continue;
  if(rd(0)!=0x50574d01u){xil_printf("Wrong/missing PWM PL identity\r\n");continue;}
  switch(c){
   case 'p':commit(1250,2500,3750);break;
   case 't':commit(3750,1250,2500);break;
   case 'e':permit(0x7f);break;
   case 'd':permit(0);break;
   case 'h':permit(0x47);break;
   case 'l':permit(0x78);break;
   case 'a':adc_snapshot();break;
   default:break;
  }
  status();
 }
}
