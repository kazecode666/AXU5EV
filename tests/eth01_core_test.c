#include <assert.h>
#include <string.h>
#include "eth_protocol.h"
#include "eth_model_if.h"
#include "ETH01_Target.h"
int main(void) {
 uint8_t bytes[256]={0},out[256];uint16_t n;uint32_t seq,count;unsigned i;
 EthModelInit();
 for(i=0;i<5;i++) {
  unsigned lens[]={0,1,255,256,257};
  assert(EthModelRxTryPush(bytes,lens[i],i)==(i==4?ETH_RANGE:ETH_OK));
  EthModelService(0);
  if(i<4){
   assert(EthModelRxTryPush(bytes,1,77)==ETH_FULL);
   EthModelService(0);EthModelService(0);
   assert(EthModelTxTryPop(out,&n,&seq,&count)==ETH_EMPTY);
   EthModelService(1);
   assert(EthModelTxTryPop(out,&n,&seq,&count)==ETH_OK);
   assert(n==lens[i] && seq==i && count==i+1);
   if(n)assert(out[0]==90);
   assert(EthModelTxTryPop(out,&n,&seq,&count)==ETH_EMPTY);
  }
 }
 assert(ETH01_Target_Y.Count==4);
 assert(EthModelRxTryPush(bytes,1,8)==ETH_OK);EthModelService(0);
 EthModelDisconnect();assert(EthModelTxTryPop(out,&n,&seq,&count)==ETH_DISCONNECTED);
 assert(EthModelRxTryPush(bytes,1,9)==ETH_DISCONNECTED);
 EthModelConnect();
 assert(EthModelRxTryPush(bytes,1,9)==ETH_OK);EthModelService(1);
 assert(EthModelTxTryPop(out,&n,&seq,&count)==ETH_OK && seq==9 && count==6);
 return 0;
}
