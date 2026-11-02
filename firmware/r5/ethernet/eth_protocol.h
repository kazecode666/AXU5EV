#ifndef ETH_PROTOCOL_H
#define ETH_PROTOCOL_H
#include <stdint.h>
#include <stddef.h>
#define ETH_HEADER 32U
#define ETH_PAYLOAD 4096U
#define ETH_BULK (32U*1024U*1024U)
typedef struct { uint8_t kind; uint32_t transfer,seq,total,offset,len,crc; } EthFrame;
uint32_t EthCrc(const uint8_t *p, size_t n);
uint32_t EthGet32(const uint8_t *p);
void EthPut32(uint8_t *p,uint32_t v);
int EthDecode(const uint8_t *p,size_t n,EthFrame *f);
size_t EthEncode(uint8_t *p,const EthFrame *f,const uint8_t *payload);
#endif
