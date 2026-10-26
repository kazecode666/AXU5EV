#define S_FUNCTION_NAME ax01b_foc_xsi_sfun
#define S_FUNCTION_LEVEL 2
#include "simstruc.h"
#include "xsi.h"
#include <windows.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

/* Public Vivado XSI interface. This wrapper only transfers fields and time. */
typedef struct {
    HMODULE kernel,design;
    xsiHandle handle;
    t_fp_xsi_run run;
    t_fp_xsi_close close;
    t_fp_xsi_get_port_number port;
    t_fp_xsi_put_value put;
    t_fp_xsi_get_value get;
    t_fp_xsi_get_status status;
    t_fp_xsi_get_int info;
    int input[9],output[7],last_us;
    double ticks_per_us;
} Bridge;

static void putbits(Bridge *b,int port,uint64_t value)
{
    s_xsi_vlog_logicval v[2]={{(uint32_t)value,0},{(uint32_t)(value>>32),0}};
    b->put(b->handle,port,v);
}
static uint32_t getbits(Bridge *b,int port)
{
    s_xsi_vlog_logicval v[2]={{0,0},{0,0}};
    b->get(b->handle,port,v);
    return v[0].aVal;
}
static void mdlInitializeSizes(SimStruct *S)
{
    ssSetNumSFcnParams(S,2);
    if(ssGetNumSFcnParams(S)!=ssGetSFcnParamsCount(S))return;
    ssSetSFcnParamTunable(S,0,0);ssSetSFcnParamTunable(S,1,0);
    if(!ssSetNumInputPorts(S,1))return;
    ssSetInputPortWidth(S,0,9);ssSetInputPortDirectFeedThrough(S,0,1);
    ssSetInputPortRequiredContiguous(S,0,1);
    if(!ssSetNumOutputPorts(S,2))return;
    ssSetOutputPortWidth(S,0,3);ssSetOutputPortWidth(S,1,4);
    ssSetNumSampleTimes(S,1);ssSetNumPWork(S,1);
}
static void mdlInitializeSampleTimes(SimStruct *S)
{ssSetSampleTime(S,0,1e-4);ssSetOffsetTime(S,0,0);}

#define MDL_START
static void mdlStart(SimStruct *S)
{
    Bridge *b=(Bridge*)calloc(1,sizeof(Bridge));
    char *work=mxArrayToString(ssGetSFcnParam(S,0));
    char *vivado=mxArrayToString(ssGetSFcnParam(S,1));
    char file[2048],old[2048],simdir[2048];
    s_xsi_setup_info setup;
    t_fp_xsi_open open_design;
    const char *inputs[]={"ia","ib","ic","theta_e","omega_e","iq_ref","id_ref","integrator_clear","vdc"};
    const char *outputs[]={"duty_u","duty_v","duty_w","frame_id","capture_edge","result_valid","hold_violation"};
    ssSetPWorkValue(S,0,b);
    snprintf(file,sizeof(file),"%s/lib/win64.o/xv_simulator_kernel.dll",vivado);
    b->kernel=LoadLibraryExA(file,NULL,LOAD_WITH_ALTERED_SEARCH_PATH);
    snprintf(file,sizeof(file),"%s/xsim.dir/ax01b_p3/xsimk.dll",work);
    b->design=LoadLibraryExA(file,NULL,LOAD_WITH_ALTERED_SEARCH_PATH);
    if(!b->kernel||!b->design){ssSetErrorStatus(S,"Cannot load p3 XSI DLL; run ax01b_prepare_hybrid('c_rtl').");goto finish;}
#define RESOLVE(member,name,type) b->member=(type)GetProcAddress(b->kernel,name)
    RESOLVE(run,"xsi_run",t_fp_xsi_run);RESOLVE(close,"xsi_close",t_fp_xsi_close);
    RESOLVE(port,"xsi_get_port_number",t_fp_xsi_get_port_number);
    RESOLVE(put,"xsi_put_value",t_fp_xsi_put_value);RESOLVE(get,"xsi_get_value",t_fp_xsi_get_value);
    RESOLVE(status,"xsi_get_status",t_fp_xsi_get_status);RESOLVE(info,"xsi_get_int",t_fp_xsi_get_int);
#undef RESOLVE
    open_design=(t_fp_xsi_open)GetProcAddress(b->design,"xsi_open");
    if(!open_design||!b->run||!b->close||!b->port||!b->put||!b->get||!b->status||!b->info){ssSetErrorStatus(S,"Incomplete public XSI entry points.");goto finish;}
    memset(&setup,0,sizeof(setup));
    snprintf(simdir,sizeof(simdir),"%s/xsim.dir",work);setup.xsimDir=simdir;
    GetCurrentDirectoryA(sizeof(old),old);SetCurrentDirectoryA(work);
    b->handle=open_design(&setup);SetCurrentDirectoryA(old);
    if(!b->handle){ssSetErrorStatus(S,"p3 XSI initialization failed.");goto finish;}
    b->ticks_per_us=pow(10.0,-6-b->info(b->handle,xsiTimePrecisionKernel));
    for(int i=0;i<9;i++)b->input[i]=b->port(b->handle,inputs[i]);
    for(int i=0;i<7;i++)b->output[i]=b->port(b->handle,outputs[i]);
    /* Two reset edges at 10/30ns; stop at 35ns before the first input latch. */
    b->run(b->handle,(XSI_INT64)llround(0.035*b->ticks_per_us));
    b->last_us=-1;
finish:
    mxFree(work);mxFree(vivado);
}
static void mdlOutputs(SimStruct *S,int_T tid)
{
    Bridge *b=(Bridge*)ssGetPWorkValue(S,0);
    const real_T *u=ssGetInputPortRealSignal(S,0);
    real_T *y=ssGetOutputPortRealSignal(S,0),*meta=ssGetOutputPortRealSignal(S,1);
    const int frac[]={24,24,24,32,24,24,24,0,24};
    int now=(int)floor(ssGetT(S)/1e-4+0.5);
    (void)tid;
    if(!b||!b->handle)return;
    if(now!=b->last_us){
        for(int i=0;i<9;i++)putbits(b,b->input[i],(uint64_t)(int64_t)llround(ldexp(u[i],frac[i])));
        /* Inputs are held for all 5000 cycles, including the PI/AW last edge.
         * The shared Simulink application event still applies this frame at +50us.
         * No future plant sample is read while the XSI frame executes in bulk. */
        b->run(b->handle,(XSI_INT64)llround(100*b->ticks_per_us));
        b->last_us=now;
    }
    if(b->status(b->handle)!=xsiNormal){ssSetErrorStatus(S,"p3 XSI reported a simulation error.");return;}
    for(int i=0;i<3;i++)y[i]=ldexp((double)getbits(b,b->output[i]),-30);
    for(int i=0;i<4;i++)meta[i]=(double)getbits(b,b->output[i+3]);
    if(now%100==0)mexPrintf("AX01B_RTL_PROGRESS t=%.4f frame=%.0f capture=%.0f hold=%.0f\n",ssGetT(S),meta[0],meta[1],meta[3]);
}
static void mdlTerminate(SimStruct *S)
{
    Bridge *b=(Bridge*)ssGetPWorkValue(S,0);
    if(!b)return;
    if(b->handle)b->close(b->handle);
    if(b->design)FreeLibrary(b->design);
    if(b->kernel)FreeLibrary(b->kernel);
    free(b);ssSetPWorkValue(S,0,NULL);
}
#ifdef MATLAB_MEX_FILE
#include "simulink.c"
#else
#include "cg_sfun.h"
#endif
