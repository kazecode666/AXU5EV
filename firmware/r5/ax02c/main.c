/* AX-02C1: recorded integer inputs -> real AXI PL FOC -> RAM -> UART.
 * No software FOC, Runtime, network service or TTC scheduling is linked.
 */
#include "ax02c_registers.h"
#include "ax02c_vectors.h"
#include "ax02c_hw.h"
#include "xil_cache.h"
#include "xil_io.h"
#include "xil_printf.h"
#include "xiltimer.h"

/* Read these image markers for the WAIT line, retaining initialized ELF
 * words for the existing offline startup inspection even with section GC.
 */
const volatile uint32_t ax02c_application_id=AX02C_ID;
const volatile uint32_t ax02c_mmio_base=AX02C_FOC_BASEADDR;
typedef struct {
    uint32_t frame,sequence,adopted,duty[3];
    uint32_t submit_ticks,wait_ticks,read_ticks;
} Ax02cResult;
static Ax02cResult results[AX02C_FRAMES];
static uint32_t completed,fail_code,fail_frame,stop_completed,elapsed_ticks;

/* The R5 BSP startup MPU table marks 0x80000000..0xbfffffff (PL) as
 * Strongly Ordered. D-cache remains off. These are BSP MMIO accesses;
 * DMB orders stage writes before COMMIT/START and result snapshot reads.
 */
static uint32_t rd(uint32_t offset) {return Xil_In32((UINTPTR)AX02C_FOC_BASEADDR+offset);}
static void wr(uint32_t offset,uint32_t value) {Xil_Out32((UINTPTR)AX02C_FOC_BASEADDR+offset,value);}
static uint32_t ticks(void) {XTime value;XTime_GetTime(&value);return (uint32_t)value;}
#define POLL_TIMEOUT_TICKS ((uint32_t)(COUNTS_PER_SECOND/10U))

static int submit(uint32_t row)
{
    uint32_t begin=ticks();
    if(rd(FOC_STATUS)&FOC_PENDING)return 7;
    for(uint32_t word=0;word<11;word++)wr(FOC_INPUT_FIRST+4U*word,ax02c_vectors[row].words[word]);
    dmb();wr(FOC_COMMIT,row+1U);dmb();
    results[row].submit_ticks=ticks()-begin;
    return 0;
}

static int stop_at_end(void)
{
    uint32_t begin=ticks();
    wr(FOC_CONTROL,FOC_STOP_AFTER_FRAME);dmb();
    while(rd(FOC_STATUS)&FOC_RUNNING) {
        if((uint32_t)(ticks()-begin)>POLL_TIMEOUT_TICKS)return 1;
    }
    stop_completed=rd(FOC_COMPLETED);
    return 0;
}

static void experiment(void)
{
    uint32_t begin;
    if(rd(FOC_ID)!=AX02C_ID) {fail_code=6;return;}
    wr(FOC_CONTROL,FOC_INIT);dmb();
    fail_code=(uint32_t)submit(0);
    if(fail_code)return;
    begin=ticks();wr(FOC_CONTROL,FOC_START);dmb();
    for(uint32_t row=0;row<AX02C_FRAMES;row++) {
        uint32_t frame,read_begin,wait_begin=ticks();
        fail_frame=row+1U;
        do {
            frame=rd(FOC_RESULT_FRAME);
            if((uint32_t)(ticks()-wait_begin)>POLL_TIMEOUT_TICKS) {fail_code=1;break;}
        } while(frame<row+1U);
        results[row].wait_ticks=ticks()-wait_begin;
        if(fail_code)break;
        read_begin=ticks();
        results[row].frame=frame;
        results[row].sequence=rd(FOC_RESULT_SEQ);
        results[row].duty[0]=rd(FOC_DUTY_U);
        results[row].duty[1]=rd(FOC_DUTY_V);
        results[row].duty[2]=rd(FOC_DUTY_W);
        results[row].adopted=rd(FOC_ADOPTED_SEQ);
        dmb();
        if(rd(FOC_RESULT_FRAME)!=frame)fail_code=3;
        else if(frame!=row+1U || results[row].sequence!=row+1U || results[row].adopted!=row+1U)fail_code=2;
        else if(rd(FOC_STATUS)&FOC_HOLD_ERROR)fail_code=4;
        else if(rd(FOC_CAPTURE_EDGE)!=315U)fail_code=5;
        results[row].read_ticks=ticks()-read_begin;
        if(fail_code)break;
        completed++;
        /* Queue the next input immediately, while the current full frame
         * continues to edge5000. Never reset PI or restart timing here.
         */
        if(row+1U<AX02C_FRAMES) {
            fail_code=(uint32_t)submit(row+1U);
            if(fail_code)break;
        }
    }
    /* Even the last result at edge315 must run to the full frame boundary.
     * Failure also requests one bounded stop; there is no retry/recovery.
     */
    if(stop_at_end() && !fail_code)fail_code=1;
    elapsed_ticks=ticks()-begin;
    if(!fail_code && (rd(FOC_STATUS)&FOC_HOLD_ERROR))fail_code=4;
    if(!fail_code && stop_completed!=AX02C_FRAMES)fail_code=8;
}

int main(void)
{
    uint32_t mismatch=0;
    Xil_DCacheDisable();Xil_ICacheEnable();
    (void)ticks(); /* First BSP PMU read before the window; BSP boot initialized the counter. */
    xil_printf("AX02C1 WAIT build=%08lx base=%08lx I-cache=ON D-cache=OFF; send s once\r\n",
        (unsigned long)ax02c_application_id,(unsigned long)ax02c_mmio_base);
    /* No PL MMIO before this explicit user action. */
    while(inbyte()!='s') {}
    xil_printf("AX02C1 START frames=17; UART output follows full-frame stop\r\n");
    experiment();
    for(uint32_t row=0;row<completed;row++) {
        Ax02cResult *r=&results[row];
        uint32_t diff[3];
        for(uint32_t channel=0;channel<3;channel++) {
            diff[channel]=r->duty[channel]^ax02c_vectors[row].duty[channel];
            if(diff[channel])mismatch++;
        }
        xil_printf("AX02C1 ROW n=%lu frame=%lu seq=%lu adopted=%lu actual=%08lx,%08lx,%08lx expected=%08lx,%08lx,%08lx xor=%08lx,%08lx,%08lx submit=%lu wait=%lu read=%lu\r\n",
            (unsigned long)row,(unsigned long)r->frame,(unsigned long)r->sequence,(unsigned long)r->adopted,
            (unsigned long)r->duty[0],(unsigned long)r->duty[1],(unsigned long)r->duty[2],
            (unsigned long)ax02c_vectors[row].duty[0],(unsigned long)ax02c_vectors[row].duty[1],(unsigned long)ax02c_vectors[row].duty[2],
            (unsigned long)diff[0],(unsigned long)diff[1],(unsigned long)diff[2],
            (unsigned long)r->submit_ticks,(unsigned long)r->wait_ticks,(unsigned long)r->read_ticks);
    }
    if(!fail_code && mismatch)fail_code=9;
    xil_printf("AX02C1 %s code=%lu fail_frame=%lu frames=%lu complete_frames=%lu compared=%lu mismatch=%lu elapsed_ticks=%lu tick_hz=%lu\r\n",
        fail_code?"FAIL":"PASS",(unsigned long)fail_code,(unsigned long)(fail_code?fail_frame:0),
        (unsigned long)completed,(unsigned long)stop_completed,(unsigned long)(3U*completed),
        (unsigned long)mismatch,(unsigned long)elapsed_ticks,(unsigned long)COUNTS_PER_SECOND);
    for(;;) {__asm__ volatile("wfi");}
}
