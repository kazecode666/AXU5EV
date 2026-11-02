/* Included before extracted, unmodified production received()/NetService().
 * Stubs model only lwIP callback ownership/window/write results, not GEM.
 */
#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "eth_service.h"
#include "eth_model_if.h"
typedef int err_t;typedef uint16_t u16_t;
enum {ERR_OK=0,ERR_MEM=-1,ERR_ABRT=-2,TCP_WRITE_FLAG_COPY=1};
struct tcp_pcb {int unused;};
struct pbuf {struct pbuf *next;uint16_t len,tot_len;const uint8_t *payload;};
static int net,read_closed,blocked,freed,aborted,closed;
static struct tcp_pcb pcb,*peer;
static uint8_t packet[8192],wire[65536];
static size_t wirelen,credits;
static void pbuf_copy_partial(struct pbuf *p,void *to,unsigned n,unsigned off){
 unsigned copied=0;(void)off;
 for(;p && copied<n;p=p->next){unsigned k=p->len;if(k>n-copied)k=n-copied;memcpy((uint8_t*)to+copied,p->payload,k);copied+=k;}
 assert(copied==n);
}
static void pbuf_free(struct pbuf *p){(void)p;freed++;}
static void tcp_abort(struct tcp_pcb *p){(void)p;aborted++;}
static void tcp_recved(struct tcp_pcb *p,u16_t n){(void)p;credits+=n;}
static void xemacif_input(void *p){(void)p;}
static void sys_check_timeouts(void){}
static u16_t tcp_sndbuf(struct tcp_pcb *p){(void)p;return 8192;}
static err_t tcp_write(struct tcp_pcb *p,const void *data,u16_t n,int flags){
 (void)p;assert(flags==TCP_WRITE_FLAG_COPY);if(blocked)return ERR_MEM;
 assert(wirelen+n<=sizeof(wire));memcpy(wire+wirelen,data,n);wirelen+=n;return ERR_OK;
}
static void tcp_output(struct tcp_pcb *p){(void)p;}
static err_t tcp_close(struct tcp_pcb *p){(void)p;closed++;return ERR_OK;}
static void tcp_err(struct tcp_pcb *p,void(*fn)(void*,err_t)){(void)p;(void)fn;}
static void disconnected(void *p,err_t e){(void)p;(void)e;peer=0;EthSessionReset();}

/* PRODUCTION_FUNCTIONS */

int main(void){
 uint8_t *bulk=malloc(ETH_BULK);uint8_t frame[4128],stream[8250];EthFrame f={2,8,1,0,0,2,0},r;
 assert(bulk);EthSessionInit(bulk,1,1000);peer=&pcb;
 size_t n=EthEncode(frame,&f,(const uint8_t*)"ab");
 struct pbuf tail={0,(uint16_t)(n-7),(uint16_t)(n-7),frame+7};
 struct pbuf head={&tail,7,(uint16_t)n,frame};
 assert(received(0,peer,&head,ERR_OK)==ERR_OK && freed==1 && credits==0);
 blocked=1;NetService();assert(wirelen==0 && credits==n && EthModelGetCount()==1);
 NetService();NetService();assert(EthModelGetCount()==1);
 blocked=0;NetService();assert(EthDecode(wire,wirelen,&r)==1 && r.len==6);
 assert(EthGet32(wire+32)==1 && wire[36]==('a'^90) && wire[37]==('b'^90));
 /* A valid request followed by FIN in the same input iteration is serviced. */
 wirelen=0;f.seq=2;n=EthEncode(frame,&f,(const uint8_t*)"ab");head.next=0;head.len=head.tot_len=n;head.payload=frame;
 assert(received(0,peer,&head,0)==0);assert(received(0,peer,0,0)==0);
 NetService();assert(wirelen==38 && EthModelGetCount()==2 && !aborted);
 NetService();assert(closed==1 && !peer && !aborted);
 /* Reassembled TCP data is bounded by the UNACKED 8192-byte receive window.
  * The old immediate-ACK implementation credited the first byte and allowed
  * an 8192 chain behind it, which could never fit. No credit is now issued.
  */
 EthSessionInit(bulk,1,1000);peer=&pcb;read_closed=0;credits=wirelen=0;size_t used=0;
 f.kind=1;f.len=1;
 for(unsigned i=1;used+33<=sizeof(stream);i++){f.seq=i;used+=EthEncode(stream+used,&f,(const uint8_t*)"x");}
 head.payload=stream;head.len=head.tot_len=1;received(0,peer,&head,0);
 assert(credits==0);head.payload=stream+1;head.len=head.tot_len=8191;
 assert(received(0,peer,&head,0)==0);blocked=1;NetService();assert(credits==33);
 assert(EthRxBuffered()==8192-33);blocked=0;NetService();assert(wirelen==33);
 free(bulk);return 0;
}
