#include "eth_model_if.h"
#include "eth_caller.h"
#include <string.h>
static struct {uint8_t bytes[256];uint16_t len;uint32_t seq,count;int valid;} rx,tx;
static int connected,inflight;
void EthQueueInit(void){memset(&rx,0,sizeof(rx));memset(&tx,0,sizeof(tx));connected=1;inflight=0;}
void EthModelConnect(void){connected=1;}
uint32_t EthModelGetStatus(void){return !connected?ETH_DISCONNECTED:(rx.valid||tx.valid||inflight)?ETH_FULL:ETH_OK;}
int EthModelRxTryPush(const uint8_t b[256],uint16_t n,uint32_t s){
 if(n>256)return ETH_RANGE;
 if(!connected)return ETH_DISCONNECTED;
 if(rx.valid||tx.valid||inflight)return ETH_FULL;
 memset(rx.bytes,0,256);if(n)memcpy(rx.bytes,b,n);rx.len=n;rx.seq=s;rx.valid=1;return ETH_OK;
}
int EthModelRxTryPop(uint8_t b[256],uint16_t *n,uint32_t *s){
 if(!connected)return ETH_DISCONNECTED;
 if(!rx.valid)return ETH_EMPTY;
 memcpy(b,rx.bytes,256);*n=rx.len;*s=rx.seq;rx.valid=0;inflight=1;return ETH_OK;
}
int EthModelTxTryPush(const uint8_t b[256],uint16_t n,uint32_t s,uint32_t count){
 if(n>256)return ETH_RANGE;
 if(!connected)return ETH_DISCONNECTED;
 if(tx.valid)return ETH_FULL;
 memcpy(tx.bytes,b,256);tx.len=n;tx.seq=s;tx.count=count;tx.valid=1;inflight=0;return ETH_OK;
}
int EthModelTxTryPop(uint8_t b[256],uint16_t *n,uint32_t *s,uint32_t *count){
 if(!connected)return ETH_DISCONNECTED;
 if(!tx.valid)return ETH_EMPTY;
 memcpy(b,tx.bytes,256);*n=tx.len;*s=tx.seq;*count=tx.count;tx.valid=0;return ETH_OK;
}
void EthQueueDisconnect(void){rx.valid=tx.valid=inflight=0;connected=0;}
/* Fixed-capacity C Caller backend, shared by simulation/Host/ARM. */
void Eth01Rx(uint8_t permit,uint8_t bytes[256],uint16_t *len,uint8_t *valid,uint32_t *seq,uint8_t *ready){
 memset(bytes,0,256);*len=0;*seq=0;*valid=0;*ready=(uint8_t)(permit && connected && !tx.valid);
 if(connected && !inflight && !tx.valid)*valid=(uint8_t)(EthModelRxTryPop(bytes,len,seq)==ETH_OK);
}
uint8_t Eth01Tx(const uint8_t bytes[256],uint16_t len,uint8_t valid,uint32_t seq,uint32_t count,uint8_t ready){
 if(!valid || !ready)return ETH_EMPTY;
 return (uint8_t)EthModelTxTryPush(bytes,len,seq,count);
}
