#ifndef ETH_CALLER_H
#define ETH_CALLER_H
#include <stdint.h>
void Eth01Rx(uint8_t permit, uint8_t bytes[256], uint16_t *len, uint8_t *valid, uint32_t *seq, uint8_t *ready);
uint8_t Eth01Tx(const uint8_t bytes[256],uint16_t len,uint8_t valid,uint32_t seq,uint32_t count,uint8_t ready);
void EthQueueInit(void);
#endif
