#ifndef ETH02_RUNTIME_H
#define ETH02_RUNTIME_H
#include "eth_protocol.h"
#ifdef AX02C2_RUNTIME
#ifdef ETH_BUILD_ID
#define ETH02_BUILD_ID ETH_BUILD_ID
#else
#define ETH02_BUILD_ID 0x43324301U
#endif
#else
#define ETH02_BUILD_ID 0x45303201U
#endif
enum {ETH02_IDLE=0,ETH02_UPLOADING=1,ETH02_READY=2,ETH02_PENDING=3,
      ETH02_RUNNING=4,ETH02_RESULT_READY=5};
enum {ETH02_SCENE=0x10,ETH02_BEGIN=0x11,ETH02_WRITE=0x12,ETH02_SEAL=0x13,
      ETH02_START=0x14,ETH02_QUERY=0x15,ETH02_INFO=0x16,ETH02_READ=0x17};
enum {ETH02_INPUT=1,ETH02_REFERENCE=2,ETH02_DESCRIPTOR=3,ETH02_OUTPUT=4,
      ETH02_TIMING=5,ETH02_REPORT=6,ETH02_RUN=7,ETH02_PRE_BEGIN=8};
#ifdef AX02C2_RUNTIME
enum {ETH02_FEEDBACK=9,ETH02_PL_RESULT=10};
#endif
void Eth02Init(uint32_t build,uint32_t speed);
void Eth02TransferReset(void);
uint32_t Eth02Request(const EthFrame *f,const uint8_t *payload,uint8_t *reply,uint32_t *length);
int Eth02Pending(void);
void Eth02NetworkStopped(uint32_t control,uint32_t mask);
void Eth02Execute(void);
void Eth02ResultReady(void);
#endif
