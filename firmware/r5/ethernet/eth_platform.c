#include "eth_service.h"
#include "eth_model_if.h"
#include "lwip/init.h"
#include "lwip/tcp.h"
#include "lwip/timeouts.h"
#include "netif/xadapter.h"
#include "xil_cache.h"
#include "xil_exception.h"
#include "xil_printf.h"
#include "xiltimer.h"
#include "xparameters.h"
#include <string.h>
#ifndef ETH_BUILD_ID
#define ETH_BUILD_ID 0x45303101U
#endif
#ifndef ETH_IP_LAST
#define ETH_IP_LAST 10
#endif
#ifndef ETH_TCP_PORT
#define ETH_TCP_PORT 5001
#endif
extern volatile unsigned eth_phy_error,eth_phy_speed,eth_phy_id;
static struct netif net;
static struct tcp_pcb *peer;
static int read_closed;
static uint8_t test_ddr[ETH_BULK] __attribute__((section(".eth_bulk"),aligned(64)));
static uint8_t packet[8192];
/* PMU free-running counter, no IRQ, no TTC ownership. Extend wrap in frequent
 * foreground calls; CP15 PMCR.D is set by BSP startup (CPU/64).
 */
u32_t sys_now(void){
 static XTime previous;static uint64_t ticks;XTime now;
 XTime_GetTime(&now);ticks+=(uint32_t)(now-previous);previous=now;
 return (u32_t)(ticks*1000U/(COUNTS_PER_SECOND));
}
void eth01_fail_stop(void){for(;;){__asm__ volatile("wfi");}}
static void disconnected(void *arg,err_t error){(void)arg;(void)error;peer=0;read_closed=0;EthSessionReset();}
static err_t received(void *arg,struct tcp_pcb *pcb,struct pbuf *p,err_t error){
 (void)arg;(void)error;
 if(!p){read_closed=1;return ERR_OK;} /* FIN is a half-close; drain accepted replies. */
 /* Atomic pbuf-chain copy. On ERR_MEM lwIP retains the complete pbuf for retry;
  * no parser/model side effects have happened. rx window is configured <=8192.
  */
 if(p->tot_len>sizeof(packet)){tcp_abort(pcb);peer=0;EthSessionReset();pbuf_free(p);return ERR_ABRT;}
 pbuf_copy_partial(p,packet,p->tot_len,0);
 if(EthRxTryPush(packet,p->tot_len)!=ETH_OK)return ERR_MEM;
 pbuf_free(p);return ERR_OK;
}
static err_t accepted(void *arg,struct tcp_pcb *pcb,err_t error){
 (void)arg;(void)error;
 if(peer){tcp_abort(pcb);return ERR_ABRT;}
 EthSessionReset();peer=pcb;read_closed=0;tcp_recv(pcb,received);tcp_err(pcb,disconnected);tcp_nagle_disable(pcb);return ERR_OK;
}
static void NetService(void){
 xemacif_input(&net);sys_check_timeouts();
 if(!peer)return;
 int progress=EthNetService();
 if(progress<0){struct tcp_pcb *p=peer;peer=0;tcp_abort(p);EthSessionReset();return;}
 /* Advertise credit only after parser consumption. The outstanding TCP window
  * then cannot exceed FIFO capacity, even for reassembled out-of-order chains.
  */
 size_t credit=EthRxTakeCredit();if(credit)tcp_recved(peer,(u16_t)credit);
 size_t length;const uint8_t *p=EthTxPeek(&length);
 if(length){
  u16_t n=tcp_sndbuf(peer);if(n>1460)n=1460;if(n>length)n=(u16_t)length;
  if(n){err_t e=tcp_write(peer,p,n,TCP_WRITE_FLAG_COPY);
   if(e==ERR_OK){EthTxConsume(n);tcp_output(peer);}
   else if(e!=ERR_MEM){struct tcp_pcb *q=peer;peer=0;tcp_abort(q);EthSessionReset();}
  }
 }
 if(peer && read_closed){
  (void)EthTxPeek(&length);
  if(!length && !progress){
   if(EthRxBuffered()){struct tcp_pcb *p=peer;peer=0;tcp_abort(p);EthSessionReset();return;}
   tcp_err(peer,0);
   if(tcp_close(peer)==ERR_OK){peer=0;EthSessionReset();}
   else tcp_err(peer,disconnected);
  }
 }
}
int main(void){
 ip_addr_t ip,mask,gw;struct tcp_pcb *listener;
 unsigned char mac[]={0x02,0x45,0x30,0x31,0x00,0x10};
 Xil_DCacheDisable();Xil_ICacheEnable();
 xil_printf("ETH01 R5_0 standalone build=%08x I-cache=ON D-cache=OFF GEM3=ff0e0000 PMU/64 no TTC\r\n",ETH_BUILD_ID);
 lwip_init();IP4_ADDR(&ip,192,168,50,ETH_IP_LAST);IP4_ADDR(&mask,255,255,255,0);IP4_ADDR(&gw,0,0,0,0);
 if(!xemac_add(&net,&ip,&mask,&gw,mac,0xff0e0000U) || eth_phy_error || !eth_phy_speed){
  xil_printf("ETH01 INIT_FAIL phy=%u id=%08x STOP\r\n",eth_phy_error,eth_phy_id);eth01_fail_stop();
 }
 /* SDT AMD init_dma -> XSetupInterruptSystem owns GIC + GEM IRQ setup once.
  * No second XScuGic_DeviceInitialize or TTC/example platform_setup_timer.
  */
 netif_set_default(&net);netif_set_up(&net);netif_set_link_up(&net);Xil_ExceptionEnable();
 EthSessionInit(test_ddr,ETH_BUILD_ID,eth_phy_speed);
 listener=tcp_new_ip_type(IPADDR_TYPE_V4);
 if(!listener || tcp_bind(listener,IP_ADDR_ANY,ETH_TCP_PORT)!=ERR_OK){xil_printf("ETH01 BIND_FAIL STOP\r\n");eth01_fail_stop();}
 listener=tcp_listen(listener);if(!listener)eth01_fail_stop();tcp_accept(listener,accepted);
 xil_printf("ETH01 TCP_READY 192.168.50.%u:%u MAC=02:45:30:31:00:10 DDR=10000000..11ffffff\r\n",ETH_IP_LAST,ETH_TCP_PORT);
 for(;;)NetService();
}
