/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: encoder_position_speed.c
 *
 * MATLAB Coder version            : 26.2
 * C/C++ source code generated on  : 2026-11-09 12:02:50
 */

/* Include Files */
#include "encoder_position_speed.h"
#include "encoder_position_speed_data.h"
#include "encoder_position_speed_initialize.h"
#include <string.h>

/* Variable Definitions */
static bool initialized;

static unsigned int last_raw;

static unsigned int last_id;

static unsigned long long last_tick;

static unsigned int last_bad;

static long long total;

static long long origin;

static unsigned int old_zero;

static bool old_reverse;

static unsigned int old_version;

static unsigned int old_scale;

static long long history[51];

static unsigned long long ticks[51];

static unsigned char head;

static unsigned char filled;

static double cached_position;

/* Function Definitions */
/*
 * ENCF software numeric source. No UART time, filter, PI or Runtime state.
 *  The physical scale is explicit: TEST 1000nm/count is 0.001mm/count once,
 *  with no extra quadrature multiplier. Tick=50MHz, selected IDs normally +500.
 *  Each received count displacement must be strictly within +/-2^31 counts.
 *  status bits: 0 startup, 1 duplicate, 2 gap, 3 config-history reset,
 *  4 invalid encoder/illegal transition, 5 ambiguous half-wrap, 6 restart.
 *
 * Arguments    : unsigned int raw_count
 *                unsigned int sample_id
 *                unsigned long long sample_tick
 *                bool encoder_ready
 *                unsigned int illegal_count
 *                unsigned int zero_count
 *                bool reverse
 *                unsigned int config_version
 *                unsigned int nm_per_count
 *                bool reset
 *                double *position_mm
 *                double *speed_mm_s
 *                bool *position_valid
 *                bool *speed_valid
 *                unsigned char *history_count
 *                unsigned int *status
 *                long long *continuous_count
 * Return Type  : void
 */
void encoder_position_speed(unsigned int raw_count, unsigned int sample_id,
                            unsigned long long sample_tick, bool encoder_ready,
                            unsigned int illegal_count, unsigned int zero_count,
                            bool reverse, unsigned int config_version,
                            unsigned int nm_per_count, bool reset,
                            double *position_mm, double *speed_mm_s,
                            bool *position_valid, bool *speed_valid,
                            unsigned char *history_count, unsigned int *status,
                            long long *continuous_count)
{
  if (!isInitialized_encoder_position_speed) {
    encoder_position_speed_initialize();
  }
  *position_mm = cached_position;
  *speed_mm_s = 0.0;
  *position_valid = false;
  *speed_valid = false;
  *status = 0U;
  *continuous_count = total;
  if (reset) {
    initialized = false;
    filled = 0U;
    head = 1U;
    cached_position = 0.0;
    total = 0LL;
    origin = 0LL;
    *position_mm = 0.0;
    *history_count = 0U;
    *continuous_count = 0LL;
  } else if (!encoder_ready || (nm_per_count == 0U)) {
    initialized = false;
    filled = 0U;
    head = 1U;
    *history_count = 0U;
    *status = 16U;
  } else {
    long long delta;
    unsigned long long id_delta;
    unsigned long long qY;
    unsigned long long qY_tmp;
    unsigned long long tick_delta;
    bool guard1;
    bool guard2;
    bool guard3;
    bool guard4;
    guard1 = false;
    guard2 = false;
    guard3 = false;
    guard4 = false;
    if (initialized) {
      qY_tmp = (unsigned long long)sample_id - last_id;
      id_delta = qY_tmp;
      if (qY_tmp > sample_id) {
        id_delta = 0ULL;
      }
      if (sample_id < last_id) {
        id_delta = qY_tmp + 4294967296ULL;
      }
      qY_tmp = sample_tick - last_tick;
      if (qY_tmp > sample_tick) {
        qY_tmp = 0ULL;
      }
      qY = (sample_tick - last_tick) + MAX_uint64_T;
      if (qY < MAX_uint64_T - last_tick) {
        qY = MAX_uint64_T;
      }
      tick_delta = qY + 1ULL;
      if (qY + 1ULL < qY) {
        tick_delta = MAX_uint64_T;
      }
      if (sample_tick >= last_tick) {
        tick_delta = qY_tmp;
      }
      if ((id_delta == 0ULL) && (tick_delta == 0ULL)) {
        *status = 2U;
        *position_valid = true;
        if ((raw_count != last_raw) || (illegal_count != last_bad)) {
          initialized = false;
          filled = 0U;
          head = 1U;
          *position_valid = false;
          *status = 82U;
        }
        *history_count = filled;
      } else if (illegal_count != last_bad) {
        initialized = false;
        filled = 0U;
        head = 1U;
        *history_count = 0U;
        *status = 16U;

        /*  Missing integral frames can preserve count continuity under the
         * delta bound, */
        /*  but cannot preserve the 50-consecutive-interval speed history. */
      } else if ((id_delta != 500ULL) || (tick_delta != 5000ULL)) {
        if ((id_delta == 0ULL) || (id_delta > 2147483647ULL) ||
            (id_delta - id_delta / 500ULL * 500ULL != 0ULL) ||
            (tick_delta != id_delta * 10ULL)) {
          initialized = false;
          filled = 0U;
          head = 1U;
          *history_count = 0U;
          *status = 80U;
        } else {
          filled = 0U;
          head = 1U;
          *status = 4U;
          guard4 = true;
        }
      } else {
        guard4 = true;
      }
    } else {
      total = raw_count;
      if ((unsigned int)total > 2147483647U) {
        total -= 4294967296LL;
      }
      *status = 1U;
      filled = 0U;
      head = 1U;
      guard3 = true;
    }
    if (guard4) {
      delta = (long long)raw_count - last_raw;
      if (delta > 2147483647LL) {
        delta -= 4294967296LL;
      } else if (delta < -2147483648LL) {
        delta += 4294967296LL;
      }
      if ((int)delta == MIN_int32_T) {
        initialized = false;
        filled = 0U;
        head = 1U;
        *history_count = 0U;
        *status = 48U;
      } else {
        if ((total < 0LL) && (delta < MIN_int64_T - total)) {
          total = MIN_int64_T;
        } else if ((total > 0LL) && (delta > MAX_int64_T - total)) {
          total = MAX_int64_T;
        } else {
          total += delta;
        }
        guard3 = true;
      }
    }
    if (guard3) {
      bool b;
      b = !initialized;
      if (b || (zero_count != old_zero) || (reverse != old_reverse) ||
          (config_version != old_version) || (nm_per_count != old_scale)) {
        if (b || (zero_count != old_zero)) {
          delta = (long long)raw_count - zero_count;
          if (delta > 2147483647LL) {
            delta -= 4294967296LL;
          } else if (delta < -2147483648LL) {
            delta += 4294967296LL;
          }
          if ((int)delta == MIN_int32_T) {
            initialized = false;
            filled = 0U;
            head = 1U;
            *history_count = 0U;
            *status = 48U;
          } else {
            /*  Only an explicit mechanical zero change remaps the nearest raw
             * reference. */
            /*  Electrical phase/version, direction and scale must preserve the
             * continuous */
            /*  origin even after one or more complete raw32 wraps. */
            if ((total >= 0LL) && (delta < total - MAX_int64_T)) {
              origin = MAX_int64_T;
            } else if ((total < 0LL) && (delta > total - MIN_int64_T)) {
              origin = MIN_int64_T;
            } else {
              origin = total - delta;
            }
            guard2 = true;
          }
        } else {
          guard2 = true;
        }
      } else {
        guard1 = true;
      }
    }
    if (guard2) {
      /*  Any configuration change clears affected speed history; no offset
       * impulse. */
      if (initialized) {
        *status |= 8U;
      }
      filled = 0U;
      head = 1U;
      guard1 = true;
    }
    if (guard1) {
      double scale;
      int direction;
      unsigned int u;
      initialized = true;
      last_raw = raw_count;
      last_id = sample_id;
      last_tick = sample_tick;
      last_bad = illegal_count;
      old_zero = zero_count;
      old_reverse = reverse;
      old_version = config_version;
      old_scale = nm_per_count;
      direction = 1;
      if (reverse) {
        direction = -1;
      }
      scale = (double)nm_per_count * 1.0E-6;
      /*  nanometres -> millimetres */
      if ((total >= 0LL) && (origin < total - MAX_int64_T)) {
        delta = MAX_int64_T;
      } else if ((total < 0LL) && (origin > total - MIN_int64_T)) {
        delta = MIN_int64_T;
      } else {
        delta = total - origin;
      }
      *position_mm = (double)delta * scale * (double)direction;
      cached_position = *position_mm;
      *position_valid = true;
      history[head - 1] = total;
      ticks[head - 1] = sample_tick;
      u = head + 1U;
      if (head + 1U > 255U) {
        u = 255U;
      }
      head = (unsigned char)u;
      if (head > 51) {
        head = 1U;
      }
      if (filled < 51) {
        filled++;
      }
      if (filled == 51) {
        /*  This is x[k]-x[k-50], not 50 samples and not a 1ms-speed-loop
         * history. */
        delta = history[head - 1];
        if ((total >= 0LL) && (delta < total - MAX_int64_T)) {
          delta = MAX_int64_T;
        } else if ((total < 0LL) && (delta > total - MIN_int64_T)) {
          delta = MIN_int64_T;
        } else {
          delta = total - delta;
        }
        qY_tmp = ticks[head - 1];
        qY = sample_tick - qY_tmp;
        if (qY > sample_tick) {
          qY = 0ULL;
        }
        tick_delta = (sample_tick - qY_tmp) + MAX_uint64_T;
        if (tick_delta < MAX_uint64_T - qY_tmp) {
          tick_delta = MAX_uint64_T;
        }
        id_delta = tick_delta + 1ULL;
        if (tick_delta + 1ULL < tick_delta) {
          id_delta = MAX_uint64_T;
        }
        if (sample_tick >= qY_tmp) {
          id_delta = qY;
        }
        *speed_mm_s = (double)delta * scale * (double)direction /
                      ((double)id_delta / 5.0E+7);
        *speed_valid = true;
      }
      *history_count = filled;
      *continuous_count = total;
    }
  }
}

/*
 * Arguments    : void
 * Return Type  : void
 */
void encoder_position_speed_init(void)
{
  initialized = false;
  last_raw = 0U;
  last_id = 0U;
  last_tick = 0ULL;
  last_bad = 0U;
  total = 0LL;
  origin = 0LL;
  old_zero = 0U;
  old_reverse = false;
  old_version = 0U;
  old_scale = 0U;
  memset(&history[0], 0, 51U * sizeof(long long));
  memset(&ticks[0], 0, 51U * sizeof(unsigned long long));
  head = 1U;
  filled = 0U;
  cached_position = 0.0;
}

/*
 * File trailer for encoder_position_speed.c
 *
 * [EOF]
 */
