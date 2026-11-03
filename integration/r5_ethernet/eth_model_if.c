#include "eth_model_if.h"
#include "eth_caller.h"
#include "ETH01_Target.h"
void EthModelInit(void){EthQueueInit();ETH01_Target_initialize();}
uint32_t EthModelGetCount(void){return ETH01_Target_Y.Count;}
void EthModelService(int ready){
 if(EthModelGetStatus()==ETH_DISCONNECTED)return;
 ETH01_Target_U.TxReady=(uint8_t)(ready!=0);
 ETH01_Target_step();
}
void EthModelDisconnect(void){
 EthQueueDisconnect();ETH01_Target_DW.pending=0;
}
