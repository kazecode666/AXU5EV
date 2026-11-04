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
#ifdef ETH02_RUNTIME
#include "eth02_runtime.h"
#include "netif/xemacpsif.h"
#include "lwip/priv/tcp_priv.h"
#include "xinterrupt_wrap.h"
#ifdef AX02C2_RUNTIME
#include "replay.h"
extern const volatile uint32_t ax02c2_application_id,ax02c2_mmio_base;
#define ETH_LABEL "AX02C2"
#else
#define ETH_LABEL "ETH02"
#endif
#else
#define ETH_LABEL "ETH01"
#endif
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
#ifdef ETH02_RUNTIME
static int start_connection_closed;
#endif
#ifndef ETH02_RUNTIME
static uint8_t test_ddr[ETH_BULK] __attribute__((section(".eth_bulk"),aligned(64)));
#endif
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
static void disconnected(void *arg,err_t error){(void)arg;(void)error;peer=0;read_closed=0;
#ifdef ETH02_RUNTIME
 start_connection_closed=0;
#endif
 EthSessionReset();}
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
 if(peer
#ifdef ETH02_RUNTIME
    || Eth02Pending()
#endif
 ){tcp_abort(pcb);return ERR_ABRT;}
 EthSessionReset();peer=pcb;read_closed=0;
#ifdef ETH02_RUNTIME
 start_connection_closed=0;
#endif
 tcp_recv(pcb,received);tcp_err(pcb,disconnected);tcp_nagle_disable(pcb);return ERR_OK;
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
  if(!length && !progress
#ifdef ETH02_RUNTIME
     && !peer->unsent && !peer->unacked
#endif
  ){
   if(EthRxBuffered()){struct tcp_pcb *p=peer;peer=0;tcp_abort(p);EthSessionReset();return;}
   tcp_err(peer,0);
   if(tcp_close(peer)==ERR_OK){
#ifdef ETH02_RUNTIME
    if(Eth02Pending())start_connection_closed=1;
#endif
    peer=0;EthSessionReset();}
   else tcp_err(peer,disconnected);
  }
 }
}
#ifdef ETH02_RUNTIME
/* All TCP data and the passive FIN handshake have completed before this call.
 * AMD's multicast-update path uses the same Stop -> reset_dma -> Start flow.
 * Only the GEM interrupt is masked; TTC uses the same BSP GIC wrapper instance.
 */
static void RunExperiment(void){
 struct xemac_s *adapter=(struct xemac_s *)net.state;
 xemacpsif_s *mac=(xemacpsif_s *)adapter->state;
 if(!start_connection_closed || peer || tcp_active_pcbs || XEmacPs_GetTxRing(&mac->emacps).HwCnt)return;
 XDisableIntrId(mac->emacps.Config.IntrId,mac->emacps.Config.IntrParent);
 XEmacPs_Stop(&mac->emacps);
 __asm__ volatile("dsb sy" ::: "memory");
 Eth02NetworkStopped(XEmacPs_ReadReg(mac->emacps.Config.BaseAddress,XEMACPS_NWCTRL_OFFSET),
                     XEmacPs_ReadReg(mac->emacps.Config.BaseAddress,XEMACPS_IMR_OFFSET));
 Eth02Execute();
 reset_dma(adapter);
 XEmacPs_Start(&mac->emacps);
 XEnableIntrId(mac->emacps.Config.IntrId,mac->emacps.Config.IntrParent);
 /* Resume the foreground time service after the deliberate measurement gap,
  * without replaying a burst of expired lwIP maintenance callbacks. */
 sys_restart_timeouts();
 Eth02ResultReady();
}
#endif
int main(void){
 ip_addr_t ip,mask,gw;struct tcp_pcb *listener;
 unsigned char mac[]={0x02,0x45,0x30,0x31,0x00,0x10};
 Xil_DCacheDisable();Xil_ICacheEnable();
 xil_printf(ETH_LABEL " R5_0 standalone build=%08x I-cache=ON D-cache=OFF GEM3=ff0e0000 PMU/64"
#if defined(AX02C2_RUNTIME)
            " Runtime=PL_polling base=%08lx\r\n",
#elif defined(ETH02_RUNTIME)
            " Runtime=TTC0\r\n",
#else
            " no TTC\r\n",
#endif
#ifdef AX02C2_RUNTIME
            ax02c2_application_id,(unsigned long)ax02c2_mmio_base);
#else
            ETH_BUILD_ID);
#endif
 lwip_init();IP4_ADDR(&ip,192,168,50,ETH_IP_LAST);IP4_ADDR(&mask,255,255,255,0);IP4_ADDR(&gw,0,0,0,0);
 if(!xemac_add(&net,&ip,&mask,&gw,mac,0xff0e0000U) || eth_phy_error || !eth_phy_speed){
  xil_printf("ETH01 INIT_FAIL phy=%u id=%08x STOP\r\n",eth_phy_error,eth_phy_id);eth01_fail_stop();
 }
 /* SDT AMD init_dma -> XSetupInterruptSystem owns GIC + GEM IRQ setup once.
  * No second XScuGic_DeviceInitialize or TTC/example platform_setup_timer.
  */
 netif_set_default(&net);netif_set_up(&net);netif_set_link_up(&net);Xil_ExceptionEnable();
#ifdef ETH02_RUNTIME
 EthSessionInit(NULL,ETH_BUILD_ID,eth_phy_speed);
#else
 EthSessionInit(test_ddr,ETH_BUILD_ID,eth_phy_speed);
#endif
 listener=tcp_new_ip_type(IPADDR_TYPE_V4);
 if(!listener || tcp_bind(listener,IP_ADDR_ANY,ETH_TCP_PORT)!=ERR_OK){xil_printf("ETH01 BIND_FAIL STOP\r\n");eth01_fail_stop();}
 listener=tcp_listen(listener);if(!listener)eth01_fail_stop();tcp_accept(listener,accepted);
 xil_printf(ETH_LABEL " TCP_READY 192.168.50.%u:%u MAC=02:45:30:31:00:10"
#ifndef ETH02_RUNTIME
            " DDR=10000000..11ffffff"
#endif
            "\r\n",ETH_IP_LAST,ETH_TCP_PORT);
 for(;;){
  NetService();
#ifdef ETH02_RUNTIME
  if(Eth02Pending())RunExperiment();
#endif
 }
}
