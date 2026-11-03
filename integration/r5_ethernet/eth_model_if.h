#ifndef ETH_MODEL_IF_H
#define ETH_MODEL_IF_H
#include <stdint.h>
enum {ETH_OK=0,ETH_EMPTY=1,ETH_FULL=2,ETH_RANGE=3,ETH_DISCONNECTED=4};
void EthModelInit(void);
int EthModelRxTryPush(const uint8_t bytes[256],uint16_t len,uint32_t seq);
int EthModelRxTryPop(uint8_t bytes[256],uint16_t *len,uint32_t *seq);
int EthModelTxTryPush(const uint8_t bytes[256],uint16_t len,uint32_t seq,uint32_t count);
int EthModelTxTryPop(uint8_t bytes[256],uint16_t *len,uint32_t *seq,uint32_t *count);
uint32_t EthModelGetStatus(void);
uint32_t EthModelGetCount(void);
void EthModelConnect(void);
void EthModelService(int txReady);
void EthModelDisconnect(void);
void EthQueueDisconnect(void);
#endif
