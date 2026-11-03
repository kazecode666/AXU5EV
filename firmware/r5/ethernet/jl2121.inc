/* ETH01 JL2121-only adapter. Register facts: ALINX supplied lwip211_v1_2
 * get_phy_speed_JL2121; no KSZ9031/Marvell sequence or LED tuning copied.
 * Strapped RX/TX delay is preserved. User board operation is separate.
 */
volatile unsigned eth_phy_error, eth_phy_speed, eth_phy_id;
static u32_t eth_jl_setup(XEmacPs *mac, u32_t address) {
 u16 id1,id2,control,status; unsigned i;
 eth_phy_error=1;eth_phy_speed=0;
 if(address!=1)goto fail;
#define RD(r,v) if(XEmacPs_PhyRead(mac,1,(r),&(v))!=XST_SUCCESS){eth_phy_error=2;goto fail;}
#define WR(r,v) if(XEmacPs_PhyWrite(mac,1,(r),(v))!=XST_SUCCESS){eth_phy_error=2;goto fail;}
 WR(31,0); RD(2,id1);RD(3,id2);eth_phy_id=((unsigned)id1<<16)|id2;
 xil_printf("ETH01 PHY addr=1 id=%08x\r\n",eth_phy_id);
 /* JL21xx model + revision nibble, corroborated by upstream JLsemi submission.
  * JL2101 shares family ID: board BOM/user confirmation selects JL2121.
  */
 if((eth_phy_id&0xfffffff0U)!=0x937c4030U){eth_phy_error=3;goto fail;}
 /* Advertise only full duplex locally, then validate resolved PHYSR duplex.
  * This makes the resolved mode consistent with AMD's full-duplex MAC path.
  */
 RD(4,control);control=(control&~0x2a0U)|0x140U;WR(4,control);
 RD(9,control);control=(control&~0x100U)|0x200U;WR(9,control);
 RD(0,control);control|=0x1200;WR(0,control);
 for(i=0;i<300;i++){
  RD(1,status); RD(1,status);
  if((status&0x24)==0x24)break;
  usleep(100000);
 }
 if(i==300){eth_phy_error=4;goto fail;}
 WR(31,0xA43);RD(0x1A,status);WR(31,0);
 eth_phy_speed=(status&0x30)==0x20?1000:(status&0x30)==0x10?100:(status&0x30)==0?10:0;
 xil_printf("ETH01 PHYSR=0x%04x speed=%u Mbps duplex=%s\r\n",
            status,eth_phy_speed,(status&0x0008U)?"full":"half");
 if(!eth_phy_speed){eth_phy_error=5;goto fail;}
 /* JL21xx page 0xA43/reg 0x1A bit3 is the resolved duplex state.
  * Reject actual half duplex; partner advertisement is not resolved status.
  * Reference: lists.openwall.net/linux-kernel/2026/10/16/2293
  */
 if(!(status&0x0008U)){eth_phy_error=6;goto fail;}
 SetUpSLCRDivisors(mac,eth_phy_speed);
 eth_phy_error=0;
 xil_printf("ETH01 LINK %u Mbps full duplex (PHYSR validated)\r\n",eth_phy_speed);
 return eth_phy_speed;
fail:
 xil_printf("ETH01 PHY_FAIL code=%u id=%08x (STOP)\r\n",eth_phy_error,eth_phy_id);
 return XST_FAILURE;
#undef RD
#undef WR
}
