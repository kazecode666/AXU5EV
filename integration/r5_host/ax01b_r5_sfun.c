#define S_FUNCTION_NAME ax01b_r5_sfun
#define S_FUNCTION_LEVEL 2
#include "simstruc.h"
#include "ax01b_r5_bridge.h"
#include <math.h>

static void mdlInitializeSizes(SimStruct *S)
{
    ssSetNumSFcnParams(S,0);
    if (!ssSetNumInputPorts(S,1)) return;
    ssSetInputPortWidth(S,0,20);
    ssSetInputPortDirectFeedThrough(S,0,1);
    ssSetInputPortRequiredContiguous(S,0,1);
    if (!ssSetNumOutputPorts(S,1)) return;
    ssSetOutputPortWidth(S,0,41);
    ssSetNumSampleTimes(S,1);
    ssSetNumIWork(S,1);
    ssSetOptions(S,SS_OPTION_EXCEPTION_FREE_CODE);
}
static void mdlInitializeSampleTimes(SimStruct *S)
{
    ssSetSampleTime(S,0,1e-4);
    ssSetOffsetTime(S,0,0.0);
}
#define MDL_START
static void mdlStart(SimStruct *S)
{
    ax01b_runtime_init();
    ssSetIWorkValue(S,0,-1);
}
static void mdlOutputs(SimStruct *S,int_T tid)
{
    int_T tick=(int_T)floor(ssGetT(S)/1e-4+0.5);
    if (ssIsSampleHit(S,0,tid) && tick!=ssGetIWorkValue(S,0)) {
        ax01b_runtime_step(ssGetInputPortRealSignal(S,0));
        ssSetIWorkValue(S,0,tick);
    }
    ax01b_runtime_output(ssGetOutputPortRealSignal(S,0));
}
static void mdlTerminate(SimStruct *S)
{
    (void)S;
    ax01b_runtime_end();
}
#ifdef MATLAB_MEX_FILE
#include "simulink.c"
#else
#include "cg_sfun.h"
#endif
