#include "eth_service.h"
#include "eth_model_if.h"
#ifdef ETH02_RUNTIME
#include "eth02_runtime.h"
#endif
#include <string.h>
static uint8_t rx[8192],tx[ETH_HEADER+ETH_PAYLOAD],reply[ETH_PAYLOAD];
static size_t used,txsize,txsent,credit;
static uint8_t *bulk;
static uint32_t build_id,link_speed,transfer,lastseq,total,written,bulk_tid;
static int session,sealed;
void EthSessionReset(void){
 used=txsize=txsent=credit=0;transfer=lastseq=total=written=bulk_tid=0;session=sealed=0;
#ifdef ETH02_RUNTIME
 Eth02TransferReset();
#else
 EthModelDisconnect();
#endif
}
void EthSessionInit(uint8_t *data,uint32_t build,uint32_t speed){
 bulk=data;build_id=build;link_speed=speed;
#ifdef ETH02_RUNTIME
 Eth02Init(build,speed);
#else
 EthModelInit();
#endif
 EthSessionReset();
}
int EthRxTryPush(const uint8_t *p,size_t len){
 if(len>sizeof(rx)-used)return ETH_FULL;
 memcpy(rx+used,p,len);used+=len;return ETH_OK;
}
const uint8_t *EthTxPeek(size_t *n){*n=txsize-txsent;return tx+txsent;}
void EthTxConsume(size_t n){if(n<=txsize-txsent){txsent+=n;if(txsent==txsize)txsent=txsize=0;}}
size_t EthRxTakeCredit(void){size_t n=credit;credit=0;return n;}
size_t EthRxBuffered(void){return used;}
int EthNetService(void){
 EthFrame f;int rc;
#ifndef ETH02_RUNTIME
 uint32_t count,seq;uint16_t n;uint8_t b[256];
#endif
 if(txsize)return 0;
 rc=EthDecode(rx,used,&f);if(rc<=0)return rc;
 if(!f.transfer || !f.seq || (session && (f.transfer!=transfer || f.seq<=lastseq)))return -1;
#ifndef ETH02_RUNTIME
 if(!session)EthModelConnect();
#endif
 session=1;transfer=f.transfer;lastseq=f.seq;
 const uint8_t *payload=rx+ETH_HEADER;
 uint8_t kind=f.kind;
 uint32_t length=0,error=0;
#ifdef ETH02_RUNTIME
 error=Eth02Request(&f,payload,reply,&length);
#else
 if((kind==1 || kind==2 || kind==7) && (f.total || f.offset))return -1;
 switch(kind){
 case 1:
  if(f.len>256){error=1;break;}
  memcpy(reply,payload,f.len);length=f.len;break;
 case 2:
  if(f.len>256){error=1;break;}
  if(EthModelRxTryPush(payload,(uint16_t)f.len,f.seq)!=ETH_OK){error=2;break;}
  EthModelService(1);
  if(EthModelTxTryPop(b,&n,&seq,&count)!=ETH_OK || seq!=f.seq){error=3;break;}
  EthPut32(reply,count);memcpy(reply+4,b,n);length=n+4;break;
 case 3:
  if(f.len || f.offset || !f.total || f.total>ETH_BULK){error=4;break;}
  total=f.total;written=0;sealed=0;bulk_tid=f.transfer;break;
 case 4:
  if(sealed || !total || f.transfer!=bulk_tid || f.total!=total || f.offset!=written || !f.len || f.len>total-written){error=5;break;}
  memcpy(bulk+written,payload,f.len);written+=f.len;break;
 case 6:
  if(f.len!=4 || !total || written!=total || f.total!=total || f.offset){error=6;break;}
  count=EthCrc(bulk,total);
  if(count!=EthGet32(payload)){error=7;break;}
  sealed=1;EthPut32(reply,count);length=4;break;
 case 5:
  if(!sealed || f.len || f.total!=total || f.offset>=total){error=8;break;}
  length=total-f.offset;if(length>ETH_PAYLOAD)length=ETH_PAYLOAD;
  memcpy(reply,bulk+f.offset,length);break;
 case 7:
  if(f.len){error=9;break;}
  EthPut32(reply,build_id);EthPut32(reply+4,link_speed);EthPut32(reply+8,1); /* I ON / D OFF */
  EthPut32(reply+12,EthModelGetCount());length=16;break;
 default:error=10;
 }
#endif
 if(error){f.kind=255;EthPut32(reply,error);length=4;}
 else f.kind=kind|128;
 credit+=ETH_HEADER+f.len;
 used-=ETH_HEADER+f.len;memmove(rx,rx+ETH_HEADER+f.len,used);
 f.len=length;txsize=EthEncode(tx,&f,reply);txsent=0;
 return 1;
}
