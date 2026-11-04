#ifndef AX02C2_ADAPTER_H
#define AX02C2_ADAPTER_H
#include <stdint.h>
/* Frame fields are model-generated; this file only defines the call/word ABI. */
void ax02c2_adapter_init(void);
void ax02c2_adapter_pack(const double input20[20],const double runtime41[41],
                        const double feedback5[5],uint32_t words11[11]);
#endif
