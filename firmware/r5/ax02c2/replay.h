#ifndef AX02C2_REPLAY_H
#define AX02C2_REPLAY_H
#include "replay_runner.h"

#ifndef AX02C2_BUILD_ID
#define AX02C2_BUILD_ID 0x43324301U
#endif
#define AX02C2_FEEDBACK_ADDRESS 0x17000000U
#define AX02C2_PL_ADDRESS 0x18000000U
#define AX02C2_FEEDBACK_FIELDS 5U

/* Both wire records are little-endian uint32, distinct from old TTC ticks. */
typedef struct {
    uint32_t record_index,runtime_step,pl_frame,command_seq,adopted_seq;
    uint32_t duty[3];
} Ax02c2PlResult;
typedef struct {
    uint32_t record_index,command_seq,pl_frame,result_seq;
    uint32_t prepare_begin,step_begin,step_end,adapt_end,commit_end;
    uint32_t wait_begin,read_begin,read_end,adopted_seq,capture_edge,status,reserved;
} Ax02c2Tick;
typedef struct {
    uint32_t tick_hz,elapsed_ticks,complete_frames,last_seq,last_frame;
    uint32_t hold_error,module_id,stop_status;
} Ax02c2Summary;

enum {AX02C2_TIMEOUT=10,AX02C2_SEQUENCE=11,AX02C2_SNAPSHOT=12,
      AX02C2_HOLD=13,AX02C2_CAPTURE=14,AX02C2_ID=15,
      AX02C2_PENDING=16,AX02C2_COMPLETE=17};
Ax02aResult ax02c2_replay(const double *input,const double *feedback,double *output,
    Ax02c2PlResult *pl,Ax02c2Tick *timing,uint32_t frames,Ax02c2Summary *summary);
#endif
