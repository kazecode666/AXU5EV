#ifndef ETH_SERVICE_H
#define ETH_SERVICE_H
#include "eth_protocol.h"
void EthSessionInit(uint8_t *bulk,uint32_t build,uint32_t speed);
void EthSessionReset(void);
int EthRxTryPush(const uint8_t *bytes,size_t len);
int EthNetService(void);
size_t EthRxTakeCredit(void);
size_t EthRxBuffered(void);
const uint8_t *EthTxPeek(size_t *len);
void EthTxConsume(size_t len);
#endif
