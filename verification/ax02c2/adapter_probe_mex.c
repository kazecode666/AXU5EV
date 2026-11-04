#include "mex.h"
#include "ax02c2_adapter_api.h"
/* Verification-only bulk call into the exact generated adapter/word wrapper. */
void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    double u[20],y[41],f[5];uint32_t words[11];
    if(nrhs!=3 || nlhs!=1)mexErrMsgIdAndTxt("AX02C2:args","Expected input20,Runtime41,feedback5 and one output.");
    mwSize rows=mxGetM(prhs[0]);
    const double *pu=mxGetDoubles(prhs[0]),*py=mxGetDoubles(prhs[1]),*pf=mxGetDoubles(prhs[2]);
    plhs[0]=mxCreateNumericMatrix(rows,11,mxUINT32_CLASS,mxREAL);
    uint32_t *p=mxGetUint32s(plhs[0]);ax02c2_adapter_init();
    for(mwSize r=0;r<rows;r++) {
        for(mwSize k=0;k<20;k++)u[k]=pu[r+rows*k];
        for(mwSize k=0;k<41;k++)y[k]=py[r+rows*k];
        for(mwSize k=0;k<5;k++)f[k]=pf[r+rows*k];
        ax02c2_adapter_pack(u,y,f,words);
        for(mwSize k=0;k<11;k++)p[r+rows*k]=words[k];
    }
}
