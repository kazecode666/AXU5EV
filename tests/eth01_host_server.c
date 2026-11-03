/* Host-only stdio transport for exercising the real service/generated model.
 * Python owns the explicit localhost socket. No target registers are used.
 */
#include "eth_service.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#endif
int main(void){
 uint8_t *bulk=malloc(ETH_BULK),h[ETH_HEADER],payload[ETH_PAYLOAD];EthFrame f;
 if(!bulk)return 2;
#ifdef _WIN32
 _setmode(_fileno(stdin),_O_BINARY);_setmode(_fileno(stdout),_O_BINARY);
#endif
 EthSessionInit(bulk,0x45303101,1000);
 while(fread(h,1,ETH_HEADER,stdin)==ETH_HEADER){
  if(EthGet32(h+24)>ETH_PAYLOAD)break;
  size_t n=EthGet32(h+24);
  if(fread(payload,1,n,stdin)!=n)break;
  if(EthRxTryPush(h,ETH_HEADER)||EthRxTryPush(payload,n)||EthNetService()<0)break;
  const uint8_t *p=EthTxPeek(&n);
  if(!n || fwrite(p,1,n,stdout)!=n)break;
  fflush(stdout);EthTxConsume(n);
  (void)f;
 }
 free(bulk);return 0;
}
