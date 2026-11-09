`timescale 1ns/1ps
// Routed candidate PL boundary with matching process-corner SDF.
// ILA/debug hub are unsupported-IP black boxes; full-design STA retains them.
// Only PS clock/reset and AXI transaction sources are substituted below.
module timing_tb;
 reg clk=0;always #10 clk=~clk;
 reg rstn=0,kill_lock=0;
 wire pwm_clk=dut.design_1_i.pwm_clock.clk_out1;
 wire lock_ip=dut.design_1_i.pwm_clock.locked;
 wire adc_clock,adc_clock_b;wire [127:0] pwm_debug=dut.design_1_i.pwm_control_0.debug_o;
 wire [31:0] published_seq=dut.design_1_i.adc_observer_0.inst.snapshot.latest_seq_reg;
 reg [11:0] raw_a=0,raw_b=0;reg otr_a=0;
 wire [2:0] h=pwm_debug[2:0],l=pwm_debug[5:3];
 reg [39:0] pa=0,pra=0;reg [31:0] pd=0;reg pav=0,pwv=0,prv=0;
 wire par=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_awready,pwr=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_wready,pbv=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_bvalid;
 wire [1:0] pbr=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_bresp,prresp=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_rresp;
 wire prar=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_arready,prvalid=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_rvalid;
 wire [31:0] prd=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_rdata;
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
 integer writes=0;
 integer checks=0,conversion=0,sample_checks=0,edge_checks=0,periods=0;
 realtime off_h[3],off_l[3],min_gap=1.0e9,max_gap=0,last_zero=0;
 realtime last_peak=0,sample_at=0,phase_delta,min_phase_delta=1.0e9,max_phase_delta=-1.0e9;
 realtime publication_delay,min_publication=1.0e9,max_publication=0,previous_publication=0;
 integer publication_checks=0;
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
  if(pwm_debug[22])check(pwm_debug[19:6]>=15 && pwm_debug[19:6]<=35,"whole-control publication follows its same-frame adoption valley");
  if(publication_delay<min_publication)min_publication=publication_delay;
  if(publication_delay>max_publication)max_publication=publication_delay;
  previous_publication=$realtime;publication_checks++;
 end
 always @(posedge pwm_clk)begin
  #4;
  if(!pwm_debug[22])last_zero=0;
  else if(pwm_debug[19:6]==0)begin
   if(last_zero!=0)begin check($realtime-last_zero>=99999 && $realtime-last_zero<=100001,"routed 100us carrier period");periods++;end
   last_zero=$realtime;
  end
 end
 always @(posedge adc_clock)begin
  fork
   begin
    if(conversion%500==0)begin
     sample_at=$realtime;
     // Observe after routed register propagation, before the next PWM edge.
     #5;
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
    #4;if(conversion>=7)begin raw_a=2000+((conversion-7)>=1000?1:0);raw_b=2100-((conversion-7)>=1000?1:0);otr_a=((conversion-7)==2000);end
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
 task read_word(input [39:0] a);begin
  @(negedge clk);pra=a;prv=1;
  @(posedge clk);while(!prar)@(posedge clk);
  @(negedge clk);prv=0;wait(prvalid);@(negedge clk);
  check(prresp==0,"SDF AXI read response");check(!$isunknown(prd),"known SDF AXI read data");value=prd;
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
 task snapshot;begin
  aread(0);
  for(integer i=0;i<80;i++)begin aread(12'h00c+4*i);packet[i]=value;end
  check(packet[0]==32'h4d435431 && packet[1]==3,"routed unified MCT1 schema3");
  check(packet[3]==captured*500 && {packet[5],packet[4]}==packet[3]*64'd10,"routed successive sample identities and 50MHz ticks");
  check(packet[42]==packet[3] && {packet[44],packet[43]}=={packet[5],packet[4]},"routed FOC/current/angle same frozen sample identity");
  check(packet[45]==(captured>=5?3:captured>=3?2:captured>=2?1:0),"routed frozen reference version follows only explicit commit");
  check(packet[41][1]==(captured==2 || captured==3 || captured==5),"routed calibration/disarm/invalid/recovery frame validity");
  check(packet[6]==2000+(packet[3]>=1000?1:0) && packet[7]==2100-(packet[3]>=1000?1:0),"routed pre-receiver ADC data correspondence");
  check(packet[69]==315 && !packet[41][2],"original FOC capture edge315, held inputs never violate");
  check(packet[68]==captured+1 && packet[72]==captured+1,"original stateful FOC runs all frames without per-frame reset");
  check(packet[57]<=32'h40000000 && packet[58]<=32'h40000000 && packet[59]<=32'h40000000,"routed original unsigned Q30 duty range");
  check(packet[60]==comparison(packet[57]) && packet[61]==comparison(packet[58]) && packet[62]==comparison(packet[59]),"routed model-generated three-phase comparison mapping");
  check({packet[71],packet[70]}=={packet[5],packet[4]}+64'd2500,"routed declared target valley belongs to this sample");
  if(packet[41][1])begin
   check(packet[64]==packet[3] && !packet[41][4],"routed current frame adopted at target valley before status publication");
   check(packet[2][7] && packet[2][9] && packet[2][11],"valid FOC input requires valid current and angle");
   check({packet[52][7:0],packet[51]}==40'h01921fb544 && packet[53]==0 && packet[54]==0,"routed stationary QEP quarter phase and explicit zero rad/s");
   valid_frames++;
  end else begin
   check(packet[56]==1 && packet[41][4] && {h,l}==0,"invalid/calibrating frame supplies PI_Reset and inhibits all six outputs");invalid_frames++;
  end
  check(packet[66]==0,"no relaxed late deadline in routed scenario");
  check(!packet[2][17] && packet[2][18],"digital TEST source stays distinct from physical link verification");
  $fwrite(trace_fd,"%08x %016x %08x %08x %08x %08x %08x %08x %010x %010x %08x %01x %08x %08x %08x\n",
   packet[42],{packet[44],packet[43]},packet[45],packet[46],packet[47],packet[48],packet[49],packet[50],
   {packet[52][7:0],packet[51]},{packet[54][7:0],packet[53]},packet[55],packet[56],packet[57],packet[58],packet[59]);
  for(integer i=0;i<80;i++)$fwrite(packet_fd,"%08x ",packet[i]);$fwrite(packet_fd,"\n");
  $display("MOTOR_SDF_FRAME id=%0d ref=%0d valid=%0d applied=%0d duty=%08x/%08x/%08x",packet[3],packet[45],packet[41][1],packet[64],packet[57],packet[58],packet[59]);
  captured++;
 end endtask
 initial begin
  trace_fd=$fopen("foc_frames.txt","w");packet_fd=$fopen("motor_frames.txt","w");
  if(!trace_fd || !packet_fd)$fatal(1,"Cannot open routed numerical trace");
  for(integer i=0;i<3;i++)begin off_h[i]=-10000;off_l[i]=-10000;end
  #500;@(negedge clk);rstn=1;#200;monitoring=1;
  wait(lock_ip);
  awrite('h100,0);awrite('h104,0);awrite('h108,65536);awrite('h10c,65536);
  awrite('h110,0);awrite('h114,1);awrite('h118,5);
  awrite('h140,0);awrite('h144,7500);awrite('h148,0);awrite('h14c,1);awrite('h150,1);
  refs(32'd1677722,1);
  #(60000-$realtime);snapshot;
  check(packet[45]==0,"initial reference is pending before its next selected P0");
  awrite('h1a4,1); // Cancel that pending arm, preserving command phase8.
  #(160000-$realtime);snapshot;
  check(packet[45]==0 && packet[41][4],"consumed disarm prevents pending version1 revival across selected P0");
  refs(32'd1677722,1); // Only this fresh explicit commit may arm the path.
  #(260000-$realtime);snapshot;refs(32'd3355443,2);
  #(360000-$realtime);snapshot;
  #(460000-$realtime);snapshot;refs(32'd1677722,3);
  #(560000-$realtime);snapshot;
  check(captured==6 && valid_frames==3 && invalid_frames==3,"routed startup/calibration/reference-step/invalid/recovery coverage");
  check(sample_checks>=5 && edge_checks>=10 && periods>=3 && publication_checks>=6,"routed sampling/carrier/output/publication coverage");
  awrite('h1a4,1);#100;check({h,l}==0,"manual disarm after routed automatic operation");
  monitoring=0;rstn=0;#100;check({h,l}==0,"global reset clears six outputs");
  $fclose(trace_fd);$fclose(packet_fd);
  $display("PWM_SDF_PASS checks=%0d samples=%0d edges=%0d periods=%0d frames=%0d valid=%0d invalid=%0d publications=%0d min_dead_ns=%0.3f max_switch_dead_ns=%0.3f sample_to_publish_ns=[%0.3f,%0.3f] adc_minus_peak_ns=[%0.3f,%0.3f]",checks,sample_checks,edge_checks,periods,captured,valid_frames,invalid_frames,publication_checks,min_gap,max_gap,min_publication,max_publication,min_phase_delta,max_phase_delta);$finish;
 end
 initial begin #1000000;$fatal(1,"MOTOR SDF watchdog");end
endmodule
