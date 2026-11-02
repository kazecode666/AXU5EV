#include "eth_protocol.h"
#include <string.h>
uint32_t EthGet32(const uint8_t *p) {return ((uint32_t)p[0]<<24)|((uint32_t)p[1]<<16)|((uint32_t)p[2]<<8)|p[3];}
void EthPut32(uint8_t *p,uint32_t v) {p[0]=v>>24;p[1]=v>>16;p[2]=v>>8;p[3]=v;}
uint32_t EthCrc(const uint8_t *p,size_t n) {
 uint32_t c=~0U; size_t i; unsigned j;
 for(i=0;i<n;i++){c^=p[i];for(j=0;j<8;j++)c=(c>>1)^(0xedb88320U & (0U-(c&1U)));}return ~c;
}
int EthDecode(const uint8_t *p,size_t n,EthFrame *f) {
 if(n<ETH_HEADER)return 0;
 if(memcmp(p,"E01T",4)||p[4]!=1||p[6]||p[7])return -1;
 f->kind=p[5];f->transfer=EthGet32(p+8);f->seq=EthGet32(p+12);f->total=EthGet32(p+16);
 f->offset=EthGet32(p+20);f->len=EthGet32(p+24);f->crc=EthGet32(p+28);
 if(f->len>ETH_PAYLOAD)return -1;
 if(n<ETH_HEADER+f->len)return 0;
 return EthCrc(p+ETH_HEADER,f->len)==f->crc?1:-1;
}
size_t EthEncode(uint8_t *p,const EthFrame *f,const uint8_t *data) {
 if(f->len>ETH_PAYLOAD)return 0;
 memcpy(p,"E01T",4);p[4]=1;p[5]=f->kind;p[6]=p[7]=0;
 EthPut32(p+8,f->transfer);EthPut32(p+12,f->seq);EthPut32(p+16,f->total);EthPut32(p+20,f->offset);
 EthPut32(p+24,f->len);EthPut32(p+28,EthCrc(data,f->len));
 if(f->len)memcpy(p+ETH_HEADER,data,f->len);
 return ETH_HEADER+f->len;
}
