#include <stdint.h>
#include "ax03b3_hw.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "sleep.h"
const volatile uint32_t ax03b3_application_id=0x42334101;
const volatile uint32_t ax03b3_mmio_base=AX03B3_ADC_BASEADDR;
static uint32_t rows[64][32];
static void wr(uint32_t a,uint32_t v){Xil_Out32((UINTPTR)AX03B3_ADC_BASEADDR+a,v);}
static uint32_t rd(uint32_t a){return Xil_In32((UINTPTR)AX03B3_ADC_BASEADDR+a);}
static void observe(void){
 for(unsigned r=0;r<64;r++){
  usleep(1000);(void)rd(0);
  for(unsigned w=0;w<32;w++)rows[r][w]=rd(12+4*w);
 }
 for(unsigned r=0;r<64;r++){
  uint32_t *p=rows[r];
  xil_printf("B3 %s id=%lu raw=%lu,%lu offset_q16=%ld,%ld count=%lu,%lu done=%lu,%lu i_q24=%ld,%ld,%ld valid=%lu error=%lx version=%lu\r\n",
   (p[2]&(1U<<16))?"TEST":"REAL",(unsigned long)p[3],(unsigned long)p[6],(unsigned long)p[7],
   (long)(int32_t)p[11],(long)(int32_t)p[12],(unsigned long)p[13],(unsigned long)p[14],
   (unsigned long)((p[2]>>5)&1),(unsigned long)((p[2]>>6)&1),
   (long)(int32_t)p[8],(long)(int32_t)p[9],(long)(int32_t)p[10],
   (unsigned long)((p[2]>>7)&1),(unsigned long)p[21],(unsigned long)p[15]);
 }
}
int main(void){
 Xil_DCacheDisable();Xil_ICacheEnable();
 xil_printf("B3 WAIT source=%s; c=config+cal, r=restart, p=pause, s=64 rows, q=end. Gains are DIGITAL TEST SCALE, not physical calibration.\r\n",AX03B3_SOURCE);
 for(;;){char c=inbyte();
  if(c=='c'){
   wr(0x100,0);wr(0x104,0);wr(0x108,65536);wr(0x10c,65536);wr(0x110,10);wr(0x114,1);wr(0x118,5);
   xil_printf("Calibration requested N=1024; zero-current condition is USER asserted, not verified\r\n");
  }else if(c=='r')wr(0x118,6);
  else if(c=='p')wr(0x118,0);
  else if(c=='s')observe();else if(c=='q')break;
 }
 for(;;){__asm__ volatile("wfi");}
}
