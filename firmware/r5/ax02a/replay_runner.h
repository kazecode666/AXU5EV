#ifndef AX02A_REPLAY_RUNNER_H
#define AX02A_REPLAY_RUNNER_H
#include <stdint.h>

typedef struct {
    uint64_t frame, release_sequence, expected, released, started;
    uint64_t step_begin, step_end, completed;
} Ax02aTick; /* serialized explicitly as eight little-endian uint64 values */

typedef struct {
    void *context;
    uint64_t period_ticks;
    uint64_t (*now)(void *);
    int (*start)(void *,uint64_t *);
    int (*wait_release)(void *,uint32_t,uint32_t *,uint64_t *);
    void (*stop)(void *);
} Ax02aClock;

enum { AX02A_OK=0, AX02A_RELEASE_ERROR=1, AX02A_DEADLINE_ERROR=2,
       AX02A_CLOCK_ERROR=3, AX02A_INPUT_ERROR=4 };
typedef struct { uint32_t status, completed_frames, failed_frame; } Ax02aResult;

/* clock=NULL: unpaced numeric replay. One init per call, never per frame. */
Ax02aResult ax02a_replay(const double *input,double *output,Ax02aTick *ticks,
                        uint32_t frames,Ax02aClock *clock);
#endif
