/* MEX input/output transport. Numerical state and execution are generated C. */
#include "mex.h"
#include <string.h>
#include "ax04_control_transport.h"

static bool initialized = false;

static uint32_t read_uint32(const mxArray *value)
{
    uint32_t result;
    memcpy(&result, mxGetData(value), sizeof(result));
    return result;
}

static mxArray *integer_value(const void *value, mxClassID data_type, size_t size)
{
    mxArray *result = mxCreateNumericMatrix(1, 1, data_type, mxREAL);
    memcpy(mxGetData(result), value, size);
    return result;
}

static mxArray *double_vector(const double *values, size_t count)
{
    mxArray *result = mxCreateDoubleMatrix(count, 1, mxREAL);
    memcpy(mxGetPr(result), values, count * sizeof(double));
    return result;
}

static mxArray *read_observation(void)
{
    const char *fields[] = {
        "runtime_frame", "position_mm", "speed_mm_s", "position_valid", "speed_valid",
        "history_count", "feedback_status", "continuous_count", "reference_commit",
        "commit_sample_id", "reference_version", "drive_outputs", "telemetry", "service_count"
    };
    ax04_control_observation observation;
    ax04_control_read(&observation);
    mxArray *result = mxCreateStructMatrix(1, 1, 14, fields);
    mxSetField(result, 0, "runtime_frame", double_vector(observation.runtime_frame, 41));
    mxSetField(result, 0, "position_mm", mxCreateDoubleScalar(observation.position_mm));
    mxSetField(result, 0, "speed_mm_s", mxCreateDoubleScalar(observation.speed_mm_s));
    mxSetField(result, 0, "position_valid", mxCreateLogicalScalar(observation.position_valid));
    mxSetField(result, 0, "speed_valid", mxCreateLogicalScalar(observation.speed_valid));
    mxSetField(result, 0, "history_count", integer_value(&observation.history_count, mxUINT8_CLASS, sizeof(uint8_t)));
    mxSetField(result, 0, "feedback_status", integer_value(&observation.feedback_status, mxUINT32_CLASS, sizeof(uint32_t)));
    mxSetField(result, 0, "continuous_count", integer_value(&observation.continuous_count, mxINT64_CLASS, sizeof(int64_t)));
    mxSetField(result, 0, "reference_commit", double_vector(observation.reference_commit, 8));
    mxSetField(result, 0, "commit_sample_id", integer_value(&observation.commit_sample_id, mxUINT32_CLASS, sizeof(uint32_t)));
    mxSetField(result, 0, "reference_version", integer_value(&observation.reference_version, mxUINT32_CLASS, sizeof(uint32_t)));
    mxArray *drive = mxCreateLogicalMatrix(5, 1);
    mxLogical *drive_data = mxGetLogicals(drive);
    for (int index = 0; index < 5; ++index) {
        drive_data[index] = observation.drive_outputs[index];
    }
    mxSetField(result, 0, "drive_outputs", drive);
    mxSetField(result, 0, "telemetry", double_vector(observation.telemetry, 12));
    mxSetField(result, 0, "service_count", integer_value(&observation.service_count, mxUINT32_CLASS, sizeof(uint32_t)));
    return result;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs < 1 || !mxIsChar(prhs[0]) || nlhs > 1) {
        mexErrMsgIdAndTxt("AX04:Gateway", "Use initialize, irq or service with at most one output.");
    }
    char *action = mxArrayToString(prhs[0]);
    if (action == NULL) {
        mexErrMsgIdAndTxt("AX04:Gateway", "Cannot decode action.");
    }
    if (strcmp(action, "initialize") == 0 && nrhs == 1) {
        ax04_control_initialize();
        initialized = true;
    } else if (strcmp(action, "service") == 0 && nrhs == 1) {
        if (!initialized) {
            mxFree(action);
            mexErrMsgIdAndTxt("AX04:Gateway", "Initialize before service.");
        }
        ax04_control_service();
    } else if (strcmp(action, "irq") == 0 && nrhs == 15) {
        if (!initialized) {
            mxFree(action);
            mexErrMsgIdAndTxt("AX04:Gateway", "Initialize before irq.");
        }
        if (!mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]) || mxIsSparse(prhs[1]) ||
            mxGetNumberOfElements(prhs[1]) != 20) {
            mxFree(action);
            mexErrMsgIdAndTxt("AX04:Gateway", "CommandFrame must contain 20 real doubles.");
        }
        for (int index = 2; index < 15; ++index) {
            if (mxGetNumberOfElements(prhs[index]) != 1) {
                mxFree(action);
                mexErrMsgIdAndTxt("AX04:Gateway", "Feedback and request inputs must be scalar.");
            }
        }
        if (!mxIsUint32(prhs[2]) || !mxIsUint32(prhs[3]) || !mxIsUint64(prhs[4]) ||
            !mxIsLogical(prhs[5]) || !mxIsUint32(prhs[6])) {
            mxFree(action);
            mexErrMsgIdAndTxt("AX04:Gateway", "Count/id/tick/ready/illegal input types differ from the model.");
        }
        for (int index = 7; index < 15; ++index) {
            if (!mxIsLogical(prhs[index])) {
                mxFree(action);
                mexErrMsgIdAndTxt("AX04:Gateway", "Validity, faults and drive requests must be logical.");
            }
        }
        uint64_t tick;
        memcpy(&tick, mxGetData(prhs[4]), sizeof(tick));
        ax04_control_irq(mxGetPr(prhs[1]), read_uint32(prhs[2]), read_uint32(prhs[3]),
            tick, mxIsLogicalScalarTrue(prhs[5]), read_uint32(prhs[6]),
            mxIsLogicalScalarTrue(prhs[7]), mxIsLogicalScalarTrue(prhs[8]),
            mxIsLogicalScalarTrue(prhs[9]), mxIsLogicalScalarTrue(prhs[10]),
            mxIsLogicalScalarTrue(prhs[11]), mxIsLogicalScalarTrue(prhs[12]),
            mxIsLogicalScalarTrue(prhs[13]), mxIsLogicalScalarTrue(prhs[14]));
    } else {
        mxFree(action);
        mexErrMsgIdAndTxt("AX04:Gateway", "Expected initialize/service, or irq plus fourteen data inputs.");
    }
    mxFree(action);
    if (nlhs == 1) {
        plhs[0] = read_observation();
    }
}
