#include "mex.h"
#include "ax01b_r5_bridge.h"
#include "ax02c2_adapter_api.h"
/* Keep generated types out of the MEX/SimStruct translation unit. */
extern const double *perf_runtime_current_output(void);

/* Host-only equivalence check. Two separately linked MEX modules use the
 * frozen Runtime/adapter algorithms and the old or candidate public bridge.
 * There is no AXI/PMU emulation and this does not measure target timing.
 */
void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    if(nrhs!=2 || nlhs!=2)mexErrMsgIdAndTxt("AX02C2:args","Expected input20,feedback5 and Runtime41,words11 outputs.");
    mwSize rows=mxGetM(prhs[0]);
    const double *input=mxGetDoubles(prhs[0]),*feedback=mxGetDoubles(prhs[1]);
    double u[20],f[5],y[41];uint32_t words[11];
    plhs[0]=mxCreateDoubleMatrix(rows,41,mxREAL);
    plhs[1]=mxCreateNumericMatrix(rows,11,mxUINT32_CLASS,mxREAL);
    double *output=mxGetDoubles(plhs[0]);uint32_t *packed=mxGetUint32s(plhs[1]);
    ax01b_runtime_init();ax02c2_adapter_init();
    for(mwSize r=0;r<rows;r++) {
        for(mwSize k=0;k<20;k++)u[k]=input[r+rows*k];
        for(mwSize k=0;k<5;k++)f[k]=feedback[r+rows*k];
        ax01b_runtime_step(u);
#ifdef PERF_BASELINE
        /* Original prepare: log all 41 outputs, then feed that same log row. */
        ax01b_runtime_output(y);
        ax02c2_adapter_pack(u,y,f,words);
#else
        /* Candidate prepare: consume this actual Runtime output directly.
         * The target commits these words before the following log copy;
         * the log is still copied before the next Runtime step.
         */
        ax02c2_adapter_pack(u,perf_runtime_current_output(),f,words);
        ax01b_runtime_output(y);
#endif
        for(mwSize k=0;k<41;k++)output[r+rows*k]=y[k];
        for(mwSize k=0;k<11;k++)packed[r+rows*k]=words[k];
    }
    ax01b_runtime_end();
}
