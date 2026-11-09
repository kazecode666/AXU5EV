`timescale 1ns/1ps
// Event-based checks for the adopted routed candidate. MC_TIMING_RTL is only
// a short functional preflight of this same stimulus/scoreboard, never SDF.
// Routed mode substitutes PS/AXI stimulus, LOCKED loss, and the documented
// shared ready interface for a late-offer test. No compare/active is forced.
module timing_tb;
 reg clk=0;always #10 clk=~clk;
 reg rstn=0,kill_lock=0,stall_ready=0;
 wire pwm_clk,lock_ip,adc_clock,adc_clock_b;
 wire [127:0] pwm_debug;
 reg [11:0] raw_a=0,raw_b=0;reg otr_a=0;
 wire [2:0] h=pwm_debug[2:0],l=pwm_debug[5:3];
 reg [39:0] pa=0,pra=0;reg [31:0] pd=0;reg pav=0,pwv=0,prv=0;
 wire par,pwr,pbv,prar,prvalid;
 wire [1:0] pbr,prresp;
 wire [31:0] prd;
`ifdef MC_TIMING_RTL
 `define MC_ADC adc
 `define MC_PWM bridge
 `define MC_READY auto_ready
 `define MC_PHASE adc.adc_phase
 `define MC_DISARM adc.manual_disarm
 `define MC_VALID auto_valid
 `define MC_INHIBIT auto_inhibit
 `define MC_SEQ auto_seq
 `define MC_COMPARE auto_compare
 reg pclk=0,rtl_locked=0;
 initial begin #5;forever #5 pclk=~pclk;end
 initial begin wait(rstn);#80;rtl_locked=1;end
 assign pwm_clk=pclk;assign lock_ip=rtl_locked && !kill_lock;
 wire auto_valid,auto_ready,auto_inhibit,auto_online,anchor;
 wire [38:0] auto_compare;wire [31:0] auto_seq,applied_seq;
 wire aar,awr,abv,arr,arv,bar,bwr,bbv,barr,brv;
 wire [1:0] abr,arrsp,bbr,brrsp;wire [31:0] ard,brd;
 assign par=pa[12]?bar:aar;assign pwr=pa[12]?bwr:awr;
 assign pbv=abv||bbv;assign pbr=bbv?bbr:abr;
 assign prar=pra[12]?barr:arr;assign prvalid=arv||brv;
 assign prresp=brv?brrsp:arrsp;assign prd=brv?brd:ard;
 ax03b3_adc_observer #(.ENCODER_FEEDBACK(1),.TEST_ABZ(1),.AUTO_CONTROL(1)) adc(
 .s_axi_aclk(clk),.s_axi_aresetn(rstn),.adc_data_a_i(raw_a),.adc_data_b_i(raw_b),
 .abz_a_i(1'b0),.abz_b_i(1'b0),.abz_z_i(1'b0),.adc_otr_a_i(otr_a),.adc_otr_b_i(1'b0),
 .adc_clk_a_o(adc_clock),.adc_clk_b_o(adc_clock_b),.pwm_anchor_o(anchor),
 .auto_valid_o(auto_valid),.auto_compare_o(auto_compare),.auto_seq_o(auto_seq),
 .auto_inhibit_o(auto_inhibit),.auto_ready_i(auto_ready),
 .auto_applied_seq_i(applied_seq),.auto_online_i(auto_online),
 .s_axi_awaddr(pa[11:0]),.s_axi_awprot(3'd0),.s_axi_awvalid(pav&&!pa[12]),.s_axi_awready(aar),
 .s_axi_wdata(pd),.s_axi_wstrb(4'hf),.s_axi_wvalid(pwv&&!pa[12]),.s_axi_wready(awr),
 .s_axi_bvalid(abv),.s_axi_bready(1'b1),.s_axi_bresp(abr),
 .s_axi_araddr(pra[11:0]),.s_axi_arprot(3'd0),.s_axi_arvalid(prv&&!pra[12]),.s_axi_arready(arr),
 .s_axi_rdata(ard),.s_axi_rresp(arrsp),.s_axi_rvalid(arv),.s_axi_rready(1'b1));
 pwm_config_bridge #(.AUTO_FOC(1)) bridge(
 .s_axi_aclk(clk),.s_axi_aresetn(rstn),.pwm_clk(pclk),.locked(lock_ip),.fast_inhibit(1'b0),.adc_anchor(anchor),
 .auto_valid_i(auto_valid),.auto_compare_i(auto_compare),.auto_seq_i(auto_seq),.auto_inhibit_i(auto_inhibit),
 .auto_ready_o(auto_ready),.auto_online_o(auto_online),.auto_applied_seq_o(applied_seq),
 .high_o(),.low_o(),.debug_o(pwm_debug),
 .s_axi_awaddr(pa[11:0]),.s_axi_awprot(3'd0),.s_axi_awvalid(pav&&pa[12]),.s_axi_awready(bar),
 .s_axi_wdata(pd),.s_axi_wstrb(4'hf),.s_axi_wvalid(pwv&&pa[12]),.s_axi_wready(bwr),
 .s_axi_bvalid(bbv),.s_axi_bready(1'b1),.s_axi_bresp(bbr),
 .s_axi_araddr(pra[11:0]),.s_axi_arprot(3'd0),.s_axi_arvalid(prv&&pra[12]),.s_axi_arready(barr),
 .s_axi_rdata(brd),.s_axi_rresp(brrsp),.s_axi_rvalid(brv),.s_axi_rready(1'b1));
`else
 `define MC_ADC dut.design_1_i.adc_observer_0.inst
 `define MC_PWM dut.design_1_i.pwm_control_0.inst
 `define MC_READY dut.design_1_i.pwm_control_0_auto_ready_o
 `define MC_PHASE `MC_ADC.adc_phase_reg
 `define MC_DISARM `MC_ADC.manual_disarm_reg_n_0
 `define MC_VALID dut.design_1_i.adc_observer_0_auto_valid_o
 `define MC_INHIBIT dut.design_1_i.adc_observer_0_auto_inhibit_o
 `define MC_SEQ dut.design_1_i.adc_observer_0_auto_seq_o
 `define MC_COMPARE dut.design_1_i.adc_observer_0_auto_compare_o
 assign pwm_clk=dut.design_1_i.pwm_clock.clk_out1;
 assign lock_ip=dut.design_1_i.pwm_clock.locked;
 assign pwm_debug=dut.design_1_i.pwm_control_0.debug_o;
 assign par=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_awready;
 assign pwr=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_wready;
 assign pbv=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_bvalid;
 assign pbr=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_bresp;
 assign prresp=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_rresp;
 assign prar=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_arready;
 assign prvalid=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_rvalid;
 assign prd=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_rdata;
 motor_routed dut(.adc_data_a_i(raw_a),.adc_data_b_i(raw_b),
 .adc_otr_a_i(otr_a),.adc_otr_b_i(1'b0),.adc_clk_a_o(adc_clock),.adc_clk_b_o(adc_clock_b));
 // Replace PS outputs, retaining SmartConnect and every routed PL connection.
 initial begin
  force dut.design_1_i.zynq_ultra_ps_e_0.inst.PS8_i.PLCLK={3'b000,clk};
  force dut.design_1_i.zynq_ultra_ps_e_0.pl_resetn0=rstn;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_awaddr=pa;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_awvalid=pav;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_wdata=pd;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_wstrb=4'hf;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_wvalid=pwv;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_wlast=1'b1;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_bready=1'b1;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_araddr=pra;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_arvalid=prv;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_rready=1'b1;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_awid=16'd0;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_awlen=8'd0;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_awsize=3'd2;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_awburst=2'd1;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_awcache=4'd0;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_awlock=1'b0;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_awprot=3'd0;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_awqos=4'd0;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_awuser=16'd0;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_arid=16'd0;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_arlen=8'd0;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_arsize=3'd2;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_arburst=2'd1;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_arcache=4'd0;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_arlock=1'b0;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_arprot=3'd0;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_arqos=4'd0;
  force dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_aruser=16'd0;
 end
 initial forever begin
  wait(kill_lock);force dut.design_1_i.pwm_clock.inst.mmcme4_adv_inst.LOCKED=0;
  wait(!kill_lock);release dut.design_1_i.pwm_clock.inst.mmcme4_adv_inst.LOCKED;
 end
`endif
`ifdef MC_TIMING_RTL
 wire [31:0] published_seq=adc.snapshot.latest_seq;
`else
 wire [31:0] published_seq=`MC_ADC.snapshot.latest_seq_reg;
`endif
 wire [31:0] active_seq=pwm_debug[67:36];
 wire [38:0] active_compare=pwm_debug[106:68];
 initial forever begin
  wait(stall_ready);force `MC_READY=0;
  wait(!stall_ready);release `MC_READY;
 end
 integer writes=0,invalid_conversion=-1;
 integer checks=0,conversion=0,sample_checks=0,edge_checks=0,periods=0;
 realtime off_h[3],off_l[3],min_gap=1.0e9,max_gap=0,last_zero=0;
 realtime last_peak=0,sample_at=0,phase_delta,min_phase_delta=1.0e9,max_phase_delta=-1.0e9;
 realtime publication_delay,min_publication=1.0e9,max_publication=0,previous_publication=0;
 integer publication_checks=0;
 integer pwm_cycles=0,fall_cycles=0,release_first_fall=0;
 integer adoption_checks=0,active_change_events=0,offer_checks=0,distinct_triplets=0,asymmetric_triplets=0;
 integer late_checks=0,lock_checks=0,rearm_checks=0,disarm_checks=0,p0_handshakes=0,release_checks=0,snapshot_checks=0;
 reg exact_p0_transaction=0;
 realtime last_pwm_rise=0,last_pwm_fall=0,last_active_q_change=0,min_q_delay=1e9,max_q_delay=0;
 reg [13:0] pre_pwm_phase;
 reg [31:0] old_active_seq=0,last_read_seq=0,last_packet_id=0;
 reg [38:0] old_active_compare=0,last_offer_compare=0;
 reg offer_seen[0:19999],banned_seq[0:19999];
 reg [38:0] offered_compare[0:19999];
 integer peak_cycle[0:19999];realtime sampled_at[0:19999];
 bit bad_expectation;
 reg [2:0] old_h=0,old_l=0;reg monitoring=0;reg [31:0] value,id,tick,ra,rb;
 task check(input bit good,input string why);begin checks++;if(!good)$fatal(1,"%s t=%0t phase=%0d",why,$time,pwm_debug[19:6]);end endtask
 always @(h or l)if(monitoring)begin
  check(!$isunknown({h,l}) && (h&l)==0,"continuous six-output known/mutually exclusive");
  for(integer i=0;i<3;i++)begin
   if(old_h[i]&&!h[i])off_h[i]=$realtime;
   if(old_l[i]&&!l[i])off_l[i]=$realtime;
   if(h[i]&&!old_h[i])begin
    check($realtime-off_l[i]>=990.0,"routed H dead-time >=990ns internal budget");
    if($realtime-off_l[i]<min_gap)min_gap=$realtime-off_l[i];
    if($realtime-off_l[i]<1100 && $realtime-off_l[i]>max_gap)max_gap=$realtime-off_l[i];edge_checks++;
   end
   if(l[i]&&!old_l[i])begin
    check($realtime-off_h[i]>=990.0,"routed L dead-time >=990ns internal budget");
    if($realtime-off_h[i]<min_gap)min_gap=$realtime-off_h[i];
    if($realtime-off_h[i]<1100 && $realtime-off_h[i]>max_gap)max_gap=$realtime-off_h[i];edge_checks++;
   end
  end
  old_h=h;old_l=l;
 end
 always @(pwm_debug[19:6])if(pwm_debug[22] && pwm_debug[19:6]==5000)last_peak=$realtime;
 // Observe the actual routed snapshot sequence flop, not its combinational
 // enable. Bit0 toggles once per atomic publication without binary-bus skew.
 always @(published_seq[0])if(monitoring && !$isunknown(published_seq[0]) && sample_at>0)begin
  publication_delay=$realtime-sample_at;
  check(publication_delay>=50150 && publication_delay<=50350,"routed same-frame FOC result and applied status published after target valley");
  if(previous_publication>0)check($realtime-previous_publication>=99999 && $realtime-previous_publication<=100001,"one routed complete publication per 100us frame");
  if(pwm_debug[22] && !`MC_INHIBIT)check(pwm_debug[19:6]>=15 && pwm_debug[19:6]<=35,"whole-control publication follows its same-frame adoption valley");
  if(publication_delay<min_publication)min_publication=publication_delay;
  if(publication_delay>max_publication)max_publication=publication_delay;
  previous_publication=$realtime;publication_checks++;
 end
 always @(posedge pwm_clk)begin
  pwm_cycles++;last_pwm_rise=$realtime;pre_pwm_phase=pwm_debug[19:6];
  #4;
  if(!pwm_debug[22])last_zero=0;
  else if(pwm_debug[19:6]==0)begin
   if(last_zero!=0)begin check($realtime-last_zero>=99999 && $realtime-last_zero<=100001,"routed 100us carrier period");periods++;end
   last_zero=$realtime;
  end
  if(monitoring && rstn && !kill_lock && !`MC_INHIBIT && active_seq!=0 &&
     (active_seq!=old_active_seq || active_compare!=old_active_compare))begin
   check(pre_pwm_phase==9999 && pwm_debug[19:6]==0,"actual active bank changes only on the target valley clock event");
   check(active_seq<20000 && offer_seen[active_seq],"actual adoption has a frozen source offer");
   check(!banned_seq[active_seq],"cancelled sample never revives at a later valley");
   check(pwm_cycles==peak_cycle[active_seq]+5000,"actual adoption belongs to this sample plus 2500 ADC clocks");
   check(active_compare===offered_compare[active_seq],"ACTIVE_TRIPLET_MISMATCH: all phases adopt the same frozen group");
   check(last_active_q_change>=last_pwm_rise && last_active_q_change-last_pwm_rise<4,"actual Q changes were observed at this clock event");
   $display("MOTOR_ACTUAL_ADOPT id=%0d pwm_event=%0d peak_event=%0d pad_to_settled_ns=%0.3f compare=%0d/%0d/%0d",active_seq,pwm_cycles,peak_cycle[active_seq],$realtime-sampled_at[active_seq],active_compare[12:0],active_compare[25:13],active_compare[38:26]);
   adoption_checks++;
  end
  old_active_seq=active_seq;old_active_compare=active_compare;
 end
 // Record real Q propagation separately from the settled logical event.
 // Bus-bit skew within one event is not mistaken for separate adoptions.
 always @(active_seq or active_compare)if(monitoring && rstn && !kill_lock && !`MC_INHIBIT && active_seq!=0)begin
  check($realtime-last_pwm_rise>=0 && $realtime-last_pwm_rise<4,"active register Q transition stays inside its actual clock event");
  last_active_q_change=$realtime;active_change_events++;
  if($realtime-last_pwm_rise<min_q_delay)min_q_delay=$realtime-last_pwm_rise;
  if($realtime-last_pwm_rise>max_q_delay)max_q_delay=$realtime-last_pwm_rise;
 end
 always @(negedge pwm_clk)begin fall_cycles++;last_pwm_fall=$realtime;end
 always @(posedge `MC_PWM.auto_release[0])if(monitoring)release_first_fall=fall_cycles;
 always @(posedge `MC_PWM.auto_release[1])if(monitoring)begin
  check(fall_cycles==release_first_fall+1,"automatic permission traverses both falling-edge release registers");
  check($realtime-last_pwm_fall>=0 && $realtime-last_pwm_fall<4,"release Q changes after an actual falling PWM edge");
  release_checks++;
 end
 always @(posedge `MC_ADC.s_axi_aclk)if(rstn)begin
  if(`MC_VALID && `MC_READY && !`MC_INHIBIT)begin
   check(`MC_SEQ<20000,"bounded offer identity");
   offer_seen[`MC_SEQ]=1;
   offered_compare[`MC_SEQ]=`MC_COMPARE;
   if(bad_expectation)offered_compare[`MC_SEQ][0]=!offered_compare[`MC_SEQ][0];
   if(offer_checks!=0 && `MC_COMPARE!=last_offer_compare)distinct_triplets++;
   if(!(`MC_COMPARE[12:0]==`MC_COMPARE[25:13] && `MC_COMPARE[25:13]==`MC_COMPARE[38:26]))asymmetric_triplets++;
   last_offer_compare=`MC_COMPARE;offer_checks++;
  end
  if(exact_p0_transaction && `MC_ADC.s_axi_awvalid && `MC_ADC.s_axi_awready && `MC_ADC.s_axi_wvalid && `MC_ADC.s_axi_wready)begin
   check(`MC_PHASE==0 && `MC_ADC.observe_phase==0,"injected slave AW/W really handshake at selected P0");p0_handshakes++;
  end
 end
 always @(posedge adc_clock)begin
  fork
   begin
    if(conversion%500==0)begin
     sample_at=$realtime;
     sampled_at[conversion]=$realtime;
     // Observe after routed register propagation, before the next PWM edge.
     #5;
     peak_cycle[conversion]=pwm_cycles;
     if(pwm_debug[22] && !kill_lock)begin
      check(pwm_debug[19:6]==5000,"routed selected sample / peak relation");sample_checks++;
      phase_delta=sample_at-last_peak;
      check(phase_delta>-5 && phase_delta<5,"ADC pad / internal peak propagation budget");
      if(phase_delta<min_phase_delta)min_phase_delta=phase_delta;
      if(phase_delta>max_phase_delta)max_phase_delta=phase_delta;
     end
    end
   end
   begin
    #4;if(conversion>=7)begin raw_a=2000+((conversion-7)>=1000?1:0);raw_b=2100-((conversion-7)>=1000?1:0);otr_a=((conversion-7)==invalid_conversion);end
   end
  join
  conversion++;
 end
 task write_target(input bit adc_target,input [11:0] a,input [31:0] d);begin
  writes++;if(writes<=5)$display("SDF_WRITE_BEGIN off=%h data=%h t=%0t",a,d,$time);
  // AW/W requests are independent. SmartConnect may wait for WVALID before
  // accepting AW; the master must not wait for AWREADY to offer write data.
  @(negedge clk);pa=(adc_target?40'h0080000000:40'h0080001000)+a;pd=d;pav=1;pwv=1;
  fork
   begin
    @(posedge clk);while(!par)@(posedge clk);
    @(negedge clk);pav=0;if(writes<=5)$display("SDF_AW_DONE t=%0t",$time);
   end
   begin
    @(posedge clk);while(!pwr)@(posedge clk);
    @(negedge clk);pwv=0;if(writes<=5)$display("SDF_W_DONE t=%0t",$time);
   end
  join
  wait(pbv);@(negedge clk);check(pbr==0,"SDF AXI write response");
 end endtask
 task pwrite(input [11:0] a,input [31:0] d);begin write_target(0,a,d);end endtask
 task awrite(input [11:0] a,input [31:0] d);begin write_target(1,a,d);end endtask
 task read_word(input [39:0] a,input [1:0] expected_response=0);begin
  @(negedge clk);pra=a;prv=1;
  @(posedge clk);while(!prar)@(posedge clk);
  @(negedge clk);prv=0;wait(prvalid);@(negedge clk);
  check(prresp==expected_response,"AXI read response including released snapshot");check(!$isunknown(prd),"known AXI read data");value=prd;
 end endtask
 task pread(input [11:0] a);begin read_word(40'h0080001000+a);end endtask
 task aread(input [11:0] a);begin read_word(40'h0080000000+a);end endtask
 task group(input integer a,b,c,s);begin
  pwrite('h10,a);pwrite('h14,b);pwrite('h18,c);pwrite('h1c,s);pwrite('h20,1);
 end endtask
 task adopted(input integer s);begin
  value=0;while(value!=s)begin #1000;pread('h0c);end
  check(value==s,"SDF adopted sequence");
  pread(4);while(value[1])begin #200;pread(4);end
  $display("SDF_ADOPT seq=%0d t=%0t",s,$time);
 end endtask
 reg [31:0] packet[0:79];integer captured=0,valid_frames=0,invalid_frames=0,trace_fd,packet_fd;
 reg [31:0] late_id;
 function automatic [12:0] comparison(input [31:0] duty);
  reg [63:0] scaled;begin
   if(duty>=32'h40000000)comparison=5000;
   else begin scaled=64'(duty)*5000+64'd536870912;comparison=scaled>>30;end
  end
 endfunction
 task refs(input [31:0] iq,input [31:0] version);begin
  awrite('h180,0);awrite('h184,iq);awrite('h188,0);awrite('h18c,0);
  awrite('h190,32'h30000000);awrite('h194,0);awrite('h198,version);awrite('h19c,1);awrite('h1a0,1);
 end endtask
 task snapshot(input bit expected_valid,input [31:0] expected_version,input bit expected_blocked=0,input bit expected_late=0,input bit expected_lock=0);begin
  aread(0);last_read_seq=value;
  for(integer i=0;i<80;i++)begin aread(12'h00c+4*i);packet[i]=value;end
  check(packet[0]==32'h4d435431 && packet[1]==3,"routed unified MCT1 schema3");
  check(packet[3]%500==0 && (captured==0 || packet[3]>last_packet_id) && {packet[5],packet[4]}==packet[3]*64'd10,"monotonic selected sample identities and 50MHz ticks");
  check(packet[42]==packet[3] && {packet[44],packet[43]}=={packet[5],packet[4]},"routed FOC/current/angle same frozen sample identity");
  check(packet[45]==expected_version,"frozen reference version follows only explicit commit");
  check(packet[41][1]==expected_valid,"event scenario has the declared capture validity");
  check(packet[41][4]==(!expected_valid || expected_blocked) && packet[41][6]==expected_late && packet[41][5]==expected_lock,"inhibit/late/lock status matches the injected event");
  check(packet[6]==2000+(packet[3]>=1000?1:0) && packet[7]==2100-(packet[3]>=1000?1:0),"routed pre-receiver ADC data correspondence");
  check(packet[69]==315 && !packet[41][2],"original FOC capture edge315, held inputs never violate");
  check(packet[68]==packet[3]/500+1 && packet[72]==packet[68],"original FOC runs every frame without per-frame reset");
  check(packet[57]<=32'h40000000 && packet[58]<=32'h40000000 && packet[59]<=32'h40000000,"routed original unsigned Q30 duty range");
  check(packet[60]==comparison(packet[57]) && packet[61]==comparison(packet[58]) && packet[62]==comparison(packet[59]),"routed model-generated three-phase comparison mapping");
  check({packet[71],packet[70]}=={packet[5],packet[4]}+64'd2500,"routed declared target valley belongs to this sample");
  if(packet[41][1])begin
   if(!expected_blocked)check(packet[64]==packet[3] && !packet[41][4],"current frame adopted at target valley before status publication");
   check(packet[2][7] && packet[2][9] && packet[2][11],"valid FOC input requires valid current and angle");
   check(packet[46]==packet[8] && packet[47]==packet[9] && packet[48]==packet[10],"routed FOC frozen currents equal this feedback frame");
   check({packet[52],packet[51]}=={packet[33],packet[32]},"routed FOC frozen angle equals this feedback frame");
   check(packet[49]==0 && packet[50]==(expected_version==2?32'd3355443:32'd1677722) && packet[55]==32'h30000000 && packet[56]==0,"frozen reference/Vdc/PI group matches the explicit transaction");
   check({packet[52][7:0],packet[51]}==40'h01921fb544 && packet[53]==0 && packet[54]==0,"routed stationary QEP quarter phase and explicit zero rad/s");
   valid_frames++;
  end else begin
   check({packet[46],packet[47],packet[48],packet[49],packet[50],packet[51],packet[52],packet[53],packet[54]}==0 && packet[55]==32'h30000000 && packet[56]==1,"routed invalid frame supplies zero numerical inputs,48V,and PI_Reset");
   check(packet[56]==1 && packet[41][4] && {h,l}==0,"invalid/calibrating frame supplies PI_Reset and inhibits all six outputs");invalid_frames++;
  end
  if(expected_late)check(packet[66]>0 && packet[64]!=packet[3],"injected late group is counted and not claimed as applied");
  if(expected_blocked)check({h,l}==0,"cancelled or lock-blocked frame keeps all outputs off");
  check(!packet[2][17] && packet[2][18],"digital TEST source stays distinct from physical link verification");
  $fwrite(trace_fd,"%08x %016x %08x %08x %08x %08x %08x %08x %010x %010x %08x %01x %08x %08x %08x\n",
   packet[42],{packet[44],packet[43]},packet[45],packet[46],packet[47],packet[48],packet[49],packet[50],
   {packet[52][7:0],packet[51]},{packet[54][7:0],packet[53]},packet[55],packet[56],packet[57],packet[58],packet[59]);
  for(integer i=0;i<80;i++)$fwrite(packet_fd,"%08x ",packet[i]);$fwrite(packet_fd,"\n");
  $fflush(trace_fd);$fflush(packet_fd);
  // Payload is unavailable again only after word79's read response.
  read_word(40'h008000000c,2);snapshot_checks++;
  $display("MOTOR_TIMING_FRAME event=%0d id=%0d ref=%0d valid=%0d inhibit=%0d late=%0d applied=%0d t=%0t",captured+1,packet[3],packet[45],packet[41][1],packet[41][4],packet[41][6],packet[64],$time);
  last_packet_id=packet[3];captured++;
 end endtask
 task next_snapshot(input bit v,input [31:0] version,input bit blocked=0,input bit late_event=0,input bit lock_event=0);begin
  while(published_seq==last_read_seq)@(negedge clk);
  #200;snapshot(v,version,blocked,late_event,lock_event);
 end endtask
 // This one transaction is driven at the actual slave interface, with the
 // PS master idle. It tests phase8 consumption when AW/W handshake at P0;
 // it is not a test of SmartConnect latency. All other transactions use PS.
 task disarm_at_selected_p0;begin
  do @(negedge `MC_ADC.s_axi_aclk);while(!(`MC_PHASE==0 && `MC_ADC.observe_phase==0));
  exact_p0_transaction=1;
  force `MC_ADC.s_axi_awaddr=12'h1a4;force `MC_ADC.s_axi_awvalid=1;
  force `MC_ADC.s_axi_wdata=32'd1;force `MC_ADC.s_axi_wstrb=4'hf;force `MC_ADC.s_axi_wvalid=1;
  force `MC_ADC.s_axi_bready=1;
  @(posedge `MC_ADC.s_axi_aclk);@(negedge `MC_ADC.s_axi_aclk);
  release `MC_ADC.s_axi_awvalid;release `MC_ADC.s_axi_wvalid;
  wait(`MC_ADC.s_axi_bvalid);@(negedge `MC_ADC.s_axi_aclk);
  check(`MC_ADC.s_axi_bresp==0 && `MC_DISARM && !`MC_ADC.ref_pending,"P0-handshake disarm consumed at phase8 and cancels pending arm");
  release `MC_ADC.s_axi_awaddr;release `MC_ADC.s_axi_wdata;release `MC_ADC.s_axi_wstrb;release `MC_ADC.s_axi_bready;
  exact_p0_transaction=0;
 end endtask
 initial begin
  trace_fd=$fopen("foc_frames.txt","w");packet_fd=$fopen("motor_frames.txt","w");
  if(!trace_fd || !packet_fd)$fatal(1,"Cannot open routed numerical trace");
  bad_expectation=$test$plusargs("BAD_ADOPT_EXPECTATION");
  for(integer i=0;i<20000;i++)begin offer_seen[i]=0;banned_seq[i]=0;offered_compare[i]=0;peak_cycle[i]=0;sampled_at[i]=0;end
  for(integer i=0;i<3;i++)begin off_h[i]=-10000;off_l[i]=-10000;end
  #500;@(negedge clk);rstn=1;#200;monitoring=1;
  wait(lock_ip);
  awrite('h100,0);awrite('h104,0);awrite('h108,65536);awrite('h10c,65536);
  awrite('h110,0);awrite('h114,1);awrite('h118,5);
  awrite('h140,0);awrite('h144,7500);awrite('h148,0);awrite('h14c,1);awrite('h150,1);
  refs(32'd1677722,1);
  next_snapshot(0,0);
  check(packet[45]==0,"initial reference is pending before its next selected P0");
  awrite('h1a4,1); // Cancel that pending arm, preserving command phase8.
  next_snapshot(0,0);
  check(packet[45]==0 && packet[41][4],"consumed disarm prevents pending version1 revival across selected P0");
  check(!`MC_ADC.ref_pending && `MC_DISARM,"pre-P0 disarm cancelled pending arm");disarm_checks++;
  refs(32'd1677722,1); // Only this fresh explicit commit may arm the path.
  next_snapshot(1,1);refs(32'd3355443,2);
  // Uncommitted shadow changes cannot pollute the frozen reference bank.
  awrite('h184,32'd8388608);next_snapshot(1,2);
  invalid_conversion=(conversion/500+1)*500;
  next_snapshot(0,2);next_snapshot(1,2);
  // One documented ready-interface fault, not a force of compare/active.
  stall_ready=1;next_snapshot(1,2,1,1);late_id=packet[3];banned_seq[late_id]=1;
  check(packet[66]==1 && !`MC_VALID,"late offer cancelled at the unchanged P2400 deadline");
  awrite('h1a4,1);stall_ready=0;
  next_snapshot(0,2);check(active_seq!=late_id && {h,l}==0,"late cancellation survives the following P0 and valley");late_checks++;
  refs(32'd1677722,3);next_snapshot(1,3);
  // Lose actual LOCKED with a group pending before its target valley.
  do @(posedge `MC_ADC.s_axi_aclk);while(!(`MC_PHASE==0 && `MC_ADC.observe_phase==0));
  #20000;check(pwm_debug[25],"clock-loss injection really hits a pending group");
  kill_lock=1;#100;check({h,l}==0 && `MC_INHIBIT,"LOCKED loss cancels outputs through the actual inhibit path");
  kill_lock=0;wait(lock_ip);
  next_snapshot(1,3,1,0,1);next_snapshot(0,3,1,0,1);
  check(pwm_debug[22] && {h,l}==0 && packet[41][5],"restored clock and a later P0/valley do not restore held arm");lock_checks++;
  refs(32'd1677722,4);next_snapshot(1,4);rearm_checks++;
  refs(32'd1677722,5);disarm_at_selected_p0;
  next_snapshot(0,5);next_snapshot(0,5);
  check(!`MC_ADC.ref_pending && `MC_DISARM && {h,l}==0,"P0-handshake disarm remains off through subsequent P0 and valley");disarm_checks++;
  refs(32'd1677722,6);next_snapshot(1,6);rearm_checks++;
  check(adoption_checks>=2 && active_change_events>0 && distinct_triplets>0 && asymmetric_triplets>=2,"distinct asymmetric groups were observed at actual adoption edges");
  check(sample_checks>0 && edge_checks>0 && periods>0 && publication_checks>0 && snapshot_checks>0,"sample/carrier/deadtime/80word scenarios really ran");
  check(late_checks==1 && lock_checks==1 && rearm_checks==2 && disarm_checks==2 && p0_handshakes==1 && release_checks>0,"all new cancellation/recovery scenarios have nonzero event coverage");
  awrite('h1a4,1);#100;check({h,l}==0,"manual disarm after routed automatic operation");
  monitoring=0;rstn=0;#100;check({h,l}==0,"global reset clears six outputs");
  $fclose(trace_fd);$fclose(packet_fd);
`ifdef MC_TIMING_RTL
  $write("MOTOR_TIMING_RTL_PASS ");
`else
  $write("PWM_SDF_PASS ");
`endif
  $display("checks=%0d samples=%0d edges=%0d periods=%0d frames=%0d valid=%0d invalid=%0d publications=%0d adoptions=%0d q_events=%0d offers=%0d distinct=%0d late=%0d lock=%0d rearm=%0d disarm=%0d p0=%0d release=%0d snapshots=%0d min_dead_ns=%0.3f max_switch_dead_ns=%0.3f q_delay_ns=[%0.3f,%0.3f] sample_to_publish_ns=[%0.3f,%0.3f] adc_minus_peak_ns=[%0.3f,%0.3f]",checks,sample_checks,edge_checks,periods,captured,valid_frames,invalid_frames,publication_checks,adoption_checks,active_change_events,offer_checks,distinct_triplets,late_checks,lock_checks,rearm_checks,disarm_checks,p0_handshakes,release_checks,snapshot_checks,min_gap,max_gap,min_q_delay,max_q_delay,min_publication,max_publication,min_phase_delta,max_phase_delta);$finish;
 end
 initial begin #2500000;$fatal(1,"MOTOR timing test watchdog");end
 `undef MC_ADC
 `undef MC_PWM
 `undef MC_READY
 `undef MC_PHASE
 `undef MC_DISARM
 `undef MC_VALID
 `undef MC_INHIBIT
 `undef MC_SEQ
 `undef MC_COMPARE
endmodule
