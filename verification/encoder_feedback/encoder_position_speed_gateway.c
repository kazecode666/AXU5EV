/* Test-only MEX transport adapter to the exact R5 generated C sources.
 * No numeric implementation lives here. */
#include "mex.h"
#include <stdbool.h>
#include <string.h>
/* Match the native64 generated ABI without including rtwtypes.h in the MEX
 * translation unit: MATLAB's tmwtypes and target rtwtypes define boolean_T
 * differently. The numeric .c translation units retain their own headers. */
extern void encoder_position_speed(unsigned int,unsigned int,unsigned long long,
 bool,unsigned int,unsigned int,bool,unsigned int,unsigned int,bool,
 double*,double*,bool*,bool*,unsigned char*,unsigned int*,long long*);
void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
 unsigned long long tick;long long count;double position,speed;
 bool pv,sv;unsigned char history;unsigned int status;
 if(nrhs!=10 || nlhs>7)mexErrMsgIdAndTxt("ENCF:Gateway","Expected 10 inputs and at most 7 outputs");
 if(!mxIsUint32(prhs[0])||!mxIsUint32(prhs[1])||!mxIsUint64(prhs[2])||
    !mxIsUint32(prhs[4])||!mxIsUint32(prhs[5])||!mxIsUint32(prhs[7])||!mxIsUint32(prhs[8]))
  mexErrMsgIdAndTxt("ENCF:Gateway","Integer input types differ from generated signature");
 for(int i=0;i<10;i++)if(mxGetNumberOfElements(prhs[i])!=1)mexErrMsgIdAndTxt("ENCF:Gateway","Inputs must be scalar");
 memcpy(&tick,mxGetData(prhs[2]),sizeof(tick));
 encoder_position_speed(*(const unsigned int*)mxGetData(prhs[0]),*(const unsigned int*)mxGetData(prhs[1]),tick,
  mxIsLogicalScalarTrue(prhs[3]),*(const unsigned int*)mxGetData(prhs[4]),*(const unsigned int*)mxGetData(prhs[5]),
  mxIsLogicalScalarTrue(prhs[6]),*(const unsigned int*)mxGetData(prhs[7]),*(const unsigned int*)mxGetData(prhs[8]),
  mxIsLogicalScalarTrue(prhs[9]),&position,&speed,&pv,&sv,&history,&status,&count);
 if(nlhs>0)plhs[0]=mxCreateDoubleScalar(position);
 if(nlhs>1)plhs[1]=mxCreateDoubleScalar(speed);
 if(nlhs>2)plhs[2]=mxCreateLogicalScalar(pv);
 if(nlhs>3)plhs[3]=mxCreateLogicalScalar(sv);
 if(nlhs>4){plhs[4]=mxCreateNumericMatrix(1,1,mxUINT8_CLASS,mxREAL);memcpy(mxGetData(plhs[4]),&history,sizeof(history));}
 if(nlhs>5){plhs[5]=mxCreateNumericMatrix(1,1,mxUINT32_CLASS,mxREAL);memcpy(mxGetData(plhs[5]),&status,sizeof(status));}
 if(nlhs>6){plhs[6]=mxCreateNumericMatrix(1,1,mxINT64_CLASS,mxREAL);memcpy(mxGetData(plhs[6]),&count,sizeof(count));}
}
