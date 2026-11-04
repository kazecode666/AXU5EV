/* Experiment state belongs to the application, never to a TCP connection. */
#include "eth02_runtime.h"
#include "replay_runner.h"
#ifdef AX02C2_RUNTIME
#include "replay.h"
#define REQUIRED_UPLOADS 0x107U
#else
#include "timing.h"
#define REQUIRED_UPLOADS 7U
#endif
#include "postprocess.h"
#ifndef AX02C2_RUNTIME
#include "timer_mapping.h"
#endif
#include "xil_io.h"
#include "xil_printf.h"
#include <stdio.h>
#include <inttypes.h>
#include <string.h>

#define INPUT_ADDRESS 0x10000000U
#define OUTPUT_ADDRESS 0x11000000U
#define TIMING_ADDRESS 0x13000000U
const uint32_t eth02_application_id=ETH02_BUILD_ID;
static uint32_t phase,experiment,scenario,frames,uploaded,build_id,link_speed;
static uint32_t active_object,written,network_control,network_mask;
static uint32_t captured,report_bytes,prepared;
static Ax02aResult result;
#ifdef AX02C2_RUNTIME
static Ax02c2Summary pl_summary;
#else
static Ax02aTimerInfo timer;
#endif
static char conditions[193],run_json[8192],pre_json[1024];
static uint32_t run_bytes,pre_bytes;

static uint8_t *object(uint32_t id,uint32_t *bytes)
{
    *bytes=0;
    switch(id) {
    case ETH02_INPUT:*bytes=frames*20U*8U;return (uint8_t *)INPUT_ADDRESS;
    case ETH02_REFERENCE:*bytes=frames*41U*8U;return (uint8_t *)AX02A_REFERENCE_ADDRESS;
    case ETH02_DESCRIPTOR:*bytes=32;return (uint8_t *)AX02A_DESCRIPTOR_ADDRESS;
    case ETH02_OUTPUT:*bytes=captured*41U*8U;return (uint8_t *)OUTPUT_ADDRESS;
    case ETH02_TIMING:*bytes=captured*64U;return (uint8_t *)TIMING_ADDRESS;
    case ETH02_REPORT:*bytes=report_bytes;return (uint8_t *)AX02A_REPORT_ADDRESS;
    case ETH02_RUN:*bytes=run_bytes;return (uint8_t *)run_json;
    case ETH02_PRE_BEGIN:*bytes=pre_bytes;return (uint8_t *)pre_json;
#ifdef AX02C2_RUNTIME
    case ETH02_FEEDBACK:*bytes=frames*AX02C2_FEEDBACK_FIELDS*8U;return (uint8_t *)AX02C2_FEEDBACK_ADDRESS;
    case ETH02_PL_RESULT:*bytes=captured*sizeof(Ax02c2PlResult);return (uint8_t *)AX02C2_PL_ADDRESS;
#endif
    default:return NULL;
    }
}

void Eth02TransferReset(void){active_object=written=0;}
void Eth02Init(uint32_t build,uint32_t speed)
{
    build_id=build;link_speed=speed;phase=ETH02_IDLE;
    ((Ax02aPostReport *)AX02A_REPORT_ADDRESS)->valid=0;
}
int Eth02Pending(void){return phase==ETH02_PENDING;}
void Eth02NetworkStopped(uint32_t control,uint32_t mask)
{
    network_control=control;network_mask=mask;
}

static int descriptor_valid(void)
{
    const Ax02aReferenceDescriptor *d=(const Ax02aReferenceDescriptor *)AX02A_DESCRIPTOR_ADDRESS;
    return d->magic==AX02A_REFERENCE_MAGIC && d->version==1 && d->scenario==scenario &&
        d->frames==frames && d->fields==41 && !d->source_start &&
        d->reference_bytes==frames*41U*8U && !d->reserved;
}

uint32_t Eth02Request(const EthFrame *f,const uint8_t *p,uint8_t *reply,uint32_t *length)
{
    uint32_t id,size,crc,j;uint8_t *data;
    if(f->kind!=ETH02_BEGIN && f->kind!=ETH02_WRITE && f->kind!=ETH02_SEAL &&
       f->kind!=ETH02_READ && (f->total || f->offset))return 1;
    switch(f->kind) {
    case ETH02_SCENE:
        if((phase!=ETH02_IDLE && phase!=ETH02_RESULT_READY) || f->len<13 || f->len>204)return 2;
        id=EthGet32(p);size=EthGet32(p+4);
#ifdef AX02C2_RUNTIME
        if(id!=2 || size!=64536 || EthGet32(p+8)!=0)return 3;
#else
        if(!((id==2 && size==64536)||(id==3 && size==43100)) || EthGet32(p+8)!=1)return 3;
#endif
        /* The caller declares this run's physical conditions. Keep JSON text
         * plain ASCII, as in the existing manual readback interface. */
        for(j=12;j<f->len;j++)if(p[j]<32 || p[j]>126 || p[j]=='"' || p[j]=='\\')return 4;
        scenario=id;frames=size;memcpy(conditions,p+12,f->len-12);conditions[f->len-12]=0;
        uploaded=0;captured=report_bytes=run_bytes=pre_bytes=0;
        result=(Ax02aResult){0,0,0};phase=ETH02_UPLOADING;Eth02TransferReset();
        ((Ax02aPostReport *)AX02A_REPORT_ADDRESS)->valid=0;
        break;
    case ETH02_BEGIN:
        if((phase!=ETH02_UPLOADING && phase!=ETH02_READY) || f->len!=4 || f->offset)return 5;
        id=EthGet32(p);data=object(id,&size);
        if(!((id>=1 && id<=3)
#ifdef AX02C2_RUNTIME
             || id==ETH02_FEEDBACK
#endif
             ) || !data || f->total!=size)return 6;
        active_object=id;written=0;uploaded&=~(1U<<(id-1));phase=ETH02_UPLOADING;
        break;
    case ETH02_WRITE:
        data=object(active_object,&size);
        if(!active_object || !data || f->total!=size || f->offset!=written ||
           !f->len || f->len>size-written)return 7;
        memcpy(data+written,p,f->len);written+=f->len;
        break;
    case ETH02_SEAL:
        data=object(active_object,&size);
        if(!active_object || !data || f->len!=4 || f->offset || f->total!=size || written!=size)return 8;
        crc=EthCrc(data,size);if(crc!=EthGet32(p))return 9;
        if(active_object==ETH02_DESCRIPTOR && !descriptor_valid())return 10;
        uploaded|=1U<<(active_object-1);Eth02TransferReset();
        if(uploaded==REQUIRED_UPLOADS)phase=ETH02_READY;
        EthPut32(reply,crc);*length=4;
        break;
    case ETH02_START:
        if(phase!=ETH02_READY || uploaded!=REQUIRED_UPLOADS || f->len || !descriptor_valid())return 11;
        experiment++;phase=ETH02_PENDING;
        EthPut32(reply,experiment);*length=4;
        break;
    case ETH02_QUERY:
        if(f->len)return 12;
        {const uint32_t fields[]={build_id,phase,experiment,scenario,frames,uploaded,
            result.status,result.completed_frames,result.failed_frame,link_speed,1,
#ifdef AX02C2_RUNTIME
            0}; /* C2 PMU/PL records are not TTC mapping version1. */
#else
            AX02A_TIMER_MAPPING_VERSION};
#endif
         for(j=0;j<12;j++)EthPut32(reply+4*j,fields[j]);
         *length=48;}
        break;
    case ETH02_INFO:
    case ETH02_READ:
        if(phase!=ETH02_RESULT_READY || f->len!=4)return 13;
        id=EthGet32(p);data=object(id,&size);
        if(!((id>=4 && id<=8)
#ifdef AX02C2_RUNTIME
             || id==ETH02_PL_RESULT
#endif
             ) || !data)return 14;
        if(f->kind==ETH02_INFO){
            EthPut32(reply,size);EthPut32(reply+4,EthCrc(data,size));*length=8;
        } else {
            if(f->total!=size || f->offset>=size)return 15;
            *length=size-f->offset;if(*length>ETH_PAYLOAD)*length=ETH_PAYLOAD;
            memcpy(reply,data+f->offset,*length);
        }
        break;
    default:return 16;
    }
    return 0;
}

static void freeze_run(void)
{
#ifdef AX02C2_RUNTIME
    captured=result.completed_frames;
    run_bytes=(uint32_t)snprintf(run_json,sizeof(run_json),
        "{\"scenario\":\"current_motion\",\"state\":%" PRIu32 ",\"mode\":0,\"frames\":%" PRIu32 ","
        "\"experiment\":%" PRIu32 ",\"before_experiment\":%" PRIu32 ",\"interrupted\":false,\"conditions\":\"%s\","
        "\"application\":\"AX02C2\",\"build_id\":%" PRIu32 ",\"transport\":\"ethernet\","
        "\"candidate\":{\"application\":\"ax02c2_runtime\",\"build_id\":%" PRIu32 "},"
        "\"result\":{\"status\":%" PRIu32 ",\"completed_frames\":%" PRIu32 ",\"failed_frame\":%" PRIu32 "},"
        "\"timer\":{\"clock_hz\":%" PRIu32 ",\"period_ticks\":0,\"mapping_version\":0,\"candidate_id\":%" PRIu32 "},"
        "\"captured_records\":%" PRIu32 ",\"timer_snapshot_valid\":false,\"report_captured\":true,"
        "\"report_validity\":\"UNVALIDATED_REQUIRES_PC_CROSSCHECK\","
        "\"pl\":{\"module_id\":%" PRIu32 ",\"base\":2147483648,\"frame_clocks\":5000,"
        "\"clock_hz_metadata\":49999500,\"complete_frames\":%" PRIu32 ",\"last_frame\":%" PRIu32 ","
        "\"last_seq\":%" PRIu32 ",\"hold_error\":%" PRIu32 ",\"stop_status\":%" PRIu32 ",\"elapsed_ticks\":%" PRIu32 "},"
        "\"records\":{\"runtime_fields\":41,\"feedback_fields\":5,\"pl_bytes\":32,\"timing_bytes\":64,"
        "\"record_index_base\":0,\"runtime_step_base\":0,\"pl_frame_base\":1,\"command_seq_base\":1},"
        "\"measurement\":{\"network\":\"GEM DMA and GEM IRQ stopped; fixed cable\","
        "\"gem_stopped_nwctrl\":%" PRIu32 ",\"gem_stopped_imr\":%" PRIu32 ",\"cache\":\"I ON / D OFF\","
        "\"network_timebase\":\"PMU CPU/64\",\"runtime_timebase\":\"PL polling; PMU CPU/64 timestamps\","
        "\"timing_schema\":\"AX02C2_PMU16_V1\",\"output_log_placement\":\"after commit_end; before wait_begin\",\"ttc_irq\":false}}\n",
        (uint32_t)(result.status?4:3),frames,experiment,experiment-1,conditions,build_id,build_id,
        result.status,result.completed_frames,result.failed_frame,pl_summary.tick_hz,build_id,captured,
        pl_summary.module_id,pl_summary.complete_frames,pl_summary.last_frame,pl_summary.last_seq,
        pl_summary.hold_error,pl_summary.stop_status,pl_summary.elapsed_ticks,network_control,network_mask);
#else
    Ax02aTtcSnapshot s=ax02a_ttc_snapshot;
    const char *name=scenario==2?"current_motion":"current_alignment_reset";
    captured=prepared && result.status<=AX02A_DEADLINE_ERROR?result.completed_frames:0;
    run_bytes=(uint32_t)snprintf(run_json,sizeof(run_json),
        "{\"scenario\":\"%s\",\"state\":%" PRIu32 ",\"mode\":1,\"frames\":%" PRIu32 ",\"experiment\":%" PRIu32 ","
        "\"before_experiment\":%" PRIu32 ",\"interrupted\":false,\"conditions\":\"%s\","
        "\"application\":\"ETH02\",\"build_id\":%" PRIu32 ",\"transport\":\"ethernet\","
        "\"candidate\":{\"application\":\"eth02_runtime\",\"build_id\":%" PRIu32 "},"
        "\"result\":{\"status\":%" PRIu32 ",\"completed_frames\":%" PRIu32 ",\"failed_frame\":%" PRIu32 "},"
        "\"timer\":{\"clock_hz\":%" PRIu32 ",\"interval\":%" PRIu32 ",\"prescaler\":%" PRIu32 ",\"period_ticks\":%" PRIu32 ","
        "\"timestamp_read_min_ticks\":%" PRIu32 ",\"timestamp_read_max_ticks\":%" PRIu32 ",\"start_window_ticks\":%" PRIu32 ","
        "\"periodic_base\":%" PRIu32 ",\"timestamp_base\":%" PRIu32 ",\"periodic_clock\":%" PRIu32 ",\"timestamp_clock\":%" PRIu32 ","
        "\"mapping_version\":%" PRIu32 ",\"candidate_id\":%" PRIu32 "},"
        "\"ttc_snapshot\":{\"valid\":%" PRIu32 ",\"periodic_base\":%" PRIu32 ",\"timestamp_base\":%" PRIu32 ","
        "\"periodic_hz\":%" PRIu32 ",\"timestamp_hz\":%" PRIu32 ",\"hardware_interval\":%" PRIu32 ",\"logical_period_ticks\":%" PRIu32 ","
        "\"periodic_clock\":%" PRIu32 ",\"timestamp_clock\":%" PRIu32 ",\"periodic_control\":%" PRIu32 ",\"timestamp_control\":%" PRIu32 ","
        "\"periodic_ier\":%" PRIu32 ",\"timestamp_ier\":%" PRIu32 "},"
        "\"timer_snapshot_valid\":%s,\"captured_records\":%" PRIu32 ",\"report_captured\":true,"
        "\"report_validity\":\"UNVALIDATED_REQUIRES_PC_CROSSCHECK\","
        "\"measurement\":{\"network\":\"GEM DMA and GEM IRQ stopped; fixed cable\","
        "\"gem_stopped_nwctrl\":%" PRIu32 ",\"gem_stopped_imr\":%" PRIu32 ",\"cache\":\"I ON / D OFF\","
        "\"network_timebase\":\"PMU CPU/64\",\"runtime_timebase\":\"TTC0\"}}\n",
        name,(uint32_t)(result.status?4:3),frames,experiment,experiment-1,conditions,build_id,build_id,
        result.status,result.completed_frames,result.failed_frame,
        timer.clock_hz,timer.interval,timer.prescaler,timer.period_ticks,
        timer.timestamp_read_min_ticks,timer.timestamp_read_max_ticks,timer.start_window_ticks,
        s.periodic_base,s.timestamp_base,s.periodic_clock,s.timestamp_clock,
        (uint32_t)AX02A_TIMER_MAPPING_VERSION,build_id,
        s.valid,s.periodic_base,s.timestamp_base,s.periodic_hz,s.timestamp_hz,s.hardware_interval,
        s.logical_period_ticks,s.periodic_clock,s.timestamp_clock,s.periodic_control,s.timestamp_control,
        s.periodic_ier,s.timestamp_ier,prepared?"true":"false",captured,network_control,network_mask);
#endif
}

void Eth02Execute(void)
{
#ifdef AX02C2_RUNTIME
    Ax02aPostReport *report=(Ax02aPostReport *)AX02A_REPORT_ADDRESS;
    phase=ETH02_RUNNING;pre_bytes=prepared=0;report->valid=0;
    xil_printf("AX02C2 RUNNING experiment=%" PRIu32 " frames=%" PRIu32 " PL=polling network=STOPPED\r\n",experiment,frames);
    result=ax02c2_replay((const double *)INPUT_ADDRESS,(const double *)AX02C2_FEEDBACK_ADDRESS,
        (double *)OUTPUT_ADDRESS,(Ax02c2PlResult *)AX02C2_PL_ADDRESS,
        (Ax02c2Tick *)TIMING_ADDRESS,frames,&pl_summary);
    /* Reuse the original numeric checker only. C2 timing is its own PMU/PL
     * schema; old TTC phase/deadline analysis must not see these records.
     */
    {Ax02aPostRequest q={scenario,scenario,experiment,experiment,0,0,frames,frames,
        result.completed_frames,result.status,0,0,0};
     ax02a_postprocess((const double *)OUTPUT_ADDRESS,result.completed_frames*41U,
        (const double *)AX02A_REFERENCE_ADDRESS,frames*41U,NULL,0,&q,report);}
    report_bytes=AX02A_REPORT_BYTES;
    pre_bytes=(uint32_t)snprintf(pre_json,sizeof(pre_json),
        "{\"stage\":\"C2_configuration\",\"timebase\":\"PMU CPU/64\",\"tick_hz\":%" PRIu32 ","
        "\"pl_clock_hz_metadata\":49999500,\"frame_clocks\":5000,\"ttc_irq\":false}\n",pl_summary.tick_hz);
#else
    Ax02aClock clock;Ax02aPostReport *report=(Ax02aPostReport *)AX02A_REPORT_ADDRESS;
    phase=ETH02_RUNNING;timer=(Ax02aTimerInfo){0};pre_bytes=prepared=0;
    report->valid=0;
    xil_printf("ETH02 RUNNING experiment=%" PRIu32 " scenario=%" PRIu32 " frames=%" PRIu32 " network=STOPPED\r\n",experiment,scenario,frames);
    if(ax02a_timing_prepare(&clock,&timer,frames)) {
        result=(Ax02aResult){AX02A_CLOCK_ERROR,0,0};ax02a_timing_cancel();
    } else {
        prepared=1;
        /* Same non-clearing pre-begin configuration as read_ttc_config.tcl;
         * no debugger halt and no extra work in begin()/ISR/Runtime_step. */
        pre_bytes=(uint32_t)snprintf(pre_json,sizeof(pre_json),
            "{\"stage\":\"pre_begin\",\"registers\":{\"periodic_clock\":%" PRIu32 ",\"timestamp_clock\":%" PRIu32 ","
            "\"hardware_interval\":%" PRIu32 ",\"timestamp_interval\":%" PRIu32 ",\"periodic_ier\":%" PRIu32 ",\"timestamp_ier\":%" PRIu32 ","
            "\"ttc_apb_select\":%" PRIu32 ",\"lpd_lsbus_ctrl\":%" PRIu32 ",\"iopll_ctrl\":%" PRIu32 ","
            "\"periodic_control\":%" PRIu32 ",\"timestamp_control\":%" PRIu32 "}}\n",
            Xil_In32(0xff110000U),Xil_In32(0xff110004U),Xil_In32(0xff110024U),Xil_In32(0xff110028U),
            Xil_In32(0xff110060U),Xil_In32(0xff110064U),Xil_In32(0xff180380U),
            Xil_In32(0xff5e00acU),Xil_In32(0xff5e0020U),Xil_In32(0xff11000cU),Xil_In32(0xff110010U));
        result=ax02a_replay((const double *)INPUT_ADDRESS,(double *)OUTPUT_ADDRESS,
                            (Ax02aTick *)TIMING_ADDRESS,frames,&clock);
    }
    /* Replay returns only after clock->stop; comparison stays outside timing. */
    {Ax02aPostRequest q={scenario,scenario,experiment,experiment,1,1,frames,frames,
        result.completed_frames,result.status,0,timer.clock_hz,timer.period_ticks};
     ax02a_postprocess((const double *)OUTPUT_ADDRESS,result.completed_frames*41U,
        (const double *)AX02A_REFERENCE_ADDRESS,frames*41U,(const Ax02aTick *)TIMING_ADDRESS,
        result.completed_frames,&q,report);}
    report_bytes=AX02A_REPORT_BYTES;
#endif
    freeze_run();
    __asm__ volatile("dsb sy" ::: "memory");
}

void Eth02ResultReady(void)
{
    phase=ETH02_RESULT_READY;
#ifdef AX02C2_RUNTIME
    xil_printf("AX02C2 RESULT_READY experiment=%" PRIu32 " status=%" PRIu32 " completed=%" PRIu32 " network=RUNNING\r\n",
#else
    xil_printf("ETH02 RESULT_READY experiment=%" PRIu32 " status=%" PRIu32 " completed=%" PRIu32 " network=RUNNING\r\n",
#endif
               experiment,result.status,result.completed_frames);
}
