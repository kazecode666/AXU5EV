/* MEX I/O transport only. The numerical implementation is generated C. */
#include "mex.h"
#include <stdbool.h>
#include <string.h>

/* Keep MATLAB and ARM rtwtypes in separate translation units. */
extern void task1_encoder_step(unsigned int, unsigned int, unsigned long long,
    bool, unsigned int, unsigned int, bool, unsigned int, unsigned int, bool,
    double *, double *, bool *, bool *, unsigned char *, unsigned int *, long long *);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    unsigned long long tick;
    long long continuous;
    double position, speed;
    bool position_valid, speed_valid;
    unsigned char history;
    unsigned int status;
    if (nrhs != 10 || nlhs > 7) {
        mexErrMsgIdAndTxt("Task1:EncoderGateway", "Expected ten inputs and at most seven outputs.");
    }
    for (int index = 0; index < 10; ++index) {
        if (mxGetNumberOfElements(prhs[index]) != 1) {
            mexErrMsgIdAndTxt("Task1:EncoderGateway", "Every input must be scalar.");
        }
    }
    if (!mxIsUint32(prhs[0]) || !mxIsUint32(prhs[1]) || !mxIsUint64(prhs[2]) ||
        !mxIsLogical(prhs[3]) || !mxIsUint32(prhs[4]) || !mxIsUint32(prhs[5]) ||
        !mxIsLogical(prhs[6]) || !mxIsUint32(prhs[7]) || !mxIsUint32(prhs[8]) ||
        !mxIsLogical(prhs[9])) {
        mexErrMsgIdAndTxt("Task1:EncoderGateway", "Input types differ from the model interface.");
    }
    memcpy(&tick, mxGetData(prhs[2]), sizeof(tick));
    task1_encoder_step(*(const unsigned int *)mxGetData(prhs[0]),
        *(const unsigned int *)mxGetData(prhs[1]), tick,
        mxIsLogicalScalarTrue(prhs[3]), *(const unsigned int *)mxGetData(prhs[4]),
        *(const unsigned int *)mxGetData(prhs[5]), mxIsLogicalScalarTrue(prhs[6]),
        *(const unsigned int *)mxGetData(prhs[7]), *(const unsigned int *)mxGetData(prhs[8]),
        mxIsLogicalScalarTrue(prhs[9]), &position, &speed, &position_valid,
        &speed_valid, &history, &status, &continuous);
    if (nlhs > 0) plhs[0] = mxCreateDoubleScalar(position);
    if (nlhs > 1) plhs[1] = mxCreateDoubleScalar(speed);
    if (nlhs > 2) plhs[2] = mxCreateLogicalScalar(position_valid);
    if (nlhs > 3) plhs[3] = mxCreateLogicalScalar(speed_valid);
    if (nlhs > 4) {
        plhs[4] = mxCreateNumericMatrix(1, 1, mxUINT8_CLASS, mxREAL);
        memcpy(mxGetData(plhs[4]), &history, sizeof(history));
    }
    if (nlhs > 5) {
        plhs[5] = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
        memcpy(mxGetData(plhs[5]), &status, sizeof(status));
    }
    if (nlhs > 6) {
        plhs[6] = mxCreateNumericMatrix(1, 1, mxINT64_CLASS, mxREAL);
        memcpy(mxGetData(plhs[6]), &continuous, sizeof(continuous));
    }
}
