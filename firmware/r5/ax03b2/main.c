/* AX-03B2: observe the real ADC through the accepted B1 frozen snapshot.
 * No Runtime, control loop, automatic current calibration or power outputs.
 */
#include <stdint.h>
#include "ax03b2_hw.h"
#include "xil_cache.h"
#include "xil_io.h"
#include "xil_printf.h"
#include "sleep.h"

#define AX03B2_APPLICATION_ID 0x42324101U
#define OBSERVATIONS 64U
#define SNAP_WORDS 32U
#define BEGIN_OFFSET 0x00U
#define PAYLOAD_OFFSET 0x0cU

const volatile uint32_t ax03b2_application_id=AX03B2_APPLICATION_ID;
const volatile uint32_t ax03b2_mmio_base=AX03B2_ADC_BASEADDR;

typedef struct {
    uint32_t sequence,sample_id,quality,raw_a,raw_b;
    int32_t sma_a_uv_nominal,sma_b_uv_nominal;
} Ax03b2Sample;
/* A small retained raw observation window, also available in the debugger. */
Ax03b2Sample ax03b2_samples[OBSERVATIONS];
uint32_t ax03b2_completed;

static uint32_t rd(uint32_t offset)
{
    return Xil_In32((UINTPTR)AX03B2_ADC_BASEADDR+offset);
}

static int32_t sma_uv_nominal(uint32_t code)
{
    /* AN9238 UG: input divider 5.02, ADC 2 Vpp and offset binary.
     * SMA voltage = (code-2048)*10.04/4096 V, positive polarity.
     * Integer uV is rounded to nearest. This is NOT a measured calibration.
     */
    int64_t numerator=((int64_t)code-2048)*10040000;
    return (int32_t)((numerator+(numerator>=0?2048:-2048))/4096);
}

static void observe(void)
{
    uint32_t sum_a=0,sum_b=0,min_a=4095,min_b=4095,max_a=0,max_b=0;
    uint32_t otr_a=0,otr_b=0,identity=0,epoch=0,flags=0;
    ax03b2_completed=0;
    xil_printf("AX03B2 CAPTURE n=64 spacing_us_nominal=1000; UART rows follow capture\r\n");
    for(uint32_t row=0;row<OBSERVATIONS;row++) {
        uint32_t payload[SNAP_WORDS];
        Ax03b2Sample *s=&ax03b2_samples[row];
        /* PL converts continuously at 5 MHz and publishes at 10 kHz nominal.
         * This UART experiment samples latest snapshots at about 1 kHz;
         * skipped sample IDs are expected and are not full-speed logging.
         */
        usleep(1000U);
        s->sequence=rd(BEGIN_OFFSET); /* Freeze the complete latest bank. */
        epoch=rd(0x04U);flags=rd(0x08U);
        for(uint32_t word=0;word<SNAP_WORDS;word++)
            payload[word]=rd(PAYLOAD_OFFSET+4U*word);
        /* The final 0x88 response releases the bank, per the B1 protocol. */
        identity=payload[0];s->quality=payload[2];s->sample_id=payload[3];
        s->raw_a=payload[6];s->raw_b=payload[7];
        s->sma_a_uv_nominal=sma_uv_nominal(s->raw_a);
        s->sma_b_uv_nominal=sma_uv_nominal(s->raw_b);
        sum_a+=s->raw_a;sum_b+=s->raw_b;
        if(s->raw_a<min_a)min_a=s->raw_a;
        if(s->raw_a>max_a)max_a=s->raw_a;
        if(s->raw_b<min_b)min_b=s->raw_b;
        if(s->raw_b>max_b)max_b=s->raw_b;
        otr_a+=(s->quality>>3)&1U;otr_b+=(s->quality>>4)&1U;
        ax03b2_completed++;
    }
    for(uint32_t row=0;row<ax03b2_completed;row++) {
        Ax03b2Sample *s=&ax03b2_samples[row];
        xil_printf("AX03B2 ROW n=%lu seq=%lu sample_id=%lu raw_a=%lu raw_b=%lu OTR_a=%lu OTR_b=%lu SMA_a_uV_nom=%ld SMA_b_uV_nom=%ld quality=%08lx\r\n",
            (unsigned long)row,(unsigned long)s->sequence,(unsigned long)s->sample_id,
            (unsigned long)s->raw_a,(unsigned long)s->raw_b,
            (unsigned long)((s->quality>>3)&1U),(unsigned long)((s->quality>>4)&1U),
            (long)s->sma_a_uv_nominal,(long)s->sma_b_uv_nominal,(unsigned long)s->quality);
    }
    xil_printf("AX03B2 SUMMARY n=%lu id=%08lx epoch=%lu flags=%08lx raw_a_min=%lu raw_a_max=%lu raw_a_mean_x1000=%lu raw_b_min=%lu raw_b_max=%lu raw_b_mean_x1000=%lu OTR_a_count=%lu OTR_b_count=%lu\r\n",
        (unsigned long)ax03b2_completed,(unsigned long)identity,(unsigned long)epoch,(unsigned long)flags,
        (unsigned long)min_a,(unsigned long)max_a,(unsigned long)(sum_a*1000U/OBSERVATIONS),
        (unsigned long)min_b,(unsigned long)max_b,(unsigned long)(sum_b*1000U/OBSERVATIONS),
        (unsigned long)otr_a,(unsigned long)otr_b);
    xil_printf("AX03B2 DONE; voltage_nominal_only current_uncalibrated; send s for another window or q to end\r\n");
}

int main(void)
{
    Xil_DCacheDisable();Xil_ICacheEnable();
    xil_printf("AX03B2 WAIT build=%08lx base=%08lx; send s for 64 observations, q to end\r\n",
        (unsigned long)ax03b2_application_id,(unsigned long)ax03b2_mmio_base);
    /* No PL MMIO before the explicit user command. No automatic repeat. */
    for(;;) {
        char command=inbyte();
        if(command=='s')observe();
        else if(command=='q')break;
    }
    xil_printf("AX03B2 END; PL ADC clocks/conversion continue until reset or power-off\r\n");
    for(;;) {__asm__ volatile("wfi");}
}
