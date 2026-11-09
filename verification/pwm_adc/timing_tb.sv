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
 reg [11:0] raw_a=0,raw_b=0;
 wire [2:0] h=pwm_debug[2:0],l=pwm_debug[5:3];
 reg [39:0] pa=0,pra=0;reg [31:0] pd=0;reg pav=0,pwv=0,prv=0;
 wire par=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_awready,pwr=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_wready,pbv=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_bvalid;
 wire [1:0] pbr=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_bresp,prresp=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_rresp;
 wire prar=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_arready,prvalid=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_rvalid;
 wire [31:0] prd=dut.design_1_i.zynq_ultra_ps_e_0.maxigp2_rdata;
 motor_routed dut(.adc_data_a_i(raw_a),.adc_data_b_i(raw_b),
 .adc_otr_a_i(1'b0),.adc_otr_b_i(1'b0),.adc_clk_a_o(adc_clock),.adc_clk_b_o(adc_clock_b));
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
    #4;if(conversion>=7)begin raw_a=1900+(conversion-7)%64;raw_b=2100+(2*(conversion-7))%64;end
   end
  join
  conversion++;
 end
 task pwrite(input [11:0] a,input [31:0] d);begin
  writes++;if(writes<=5)$display("SDF_WRITE_BEGIN off=%h data=%h t=%0t",a,d,$time);
  // AW/W requests are independent. SmartConnect may wait for WVALID before
  // accepting AW; the master must not wait for AWREADY to offer write data.
  @(negedge clk);pa=40'h0080001000+a;pd=d;pav=1;pwv=1;
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
 initial begin
  for(integer i=0;i<3;i++)begin off_h[i]=-10000;off_l[i]=-10000;end
  #500;@(negedge clk);rstn=1;#200;monitoring=1;
  wait(lock_ip);$display("SDF_LOCK t=%0t",$time);wait(pwm_debug[22]);$display("SDF_STARTED t=%0t",$time);#500;
  pread(0);check(value==32'h50574d01,"routed identity");
  group(1250,2500,3750,1);pwrite('h24,127);adopted(1);
  #200000;group(3750,1250,2500,2);adopted(2);
  #10000;pwrite('h24,0);#100;check({h,l}==0,"SDF disable closes without valley");
  pwrite('h24,127);#200000;
  aread(0);aread('h18);id=value;aread('h1c);tick=value;aread('h24);ra=value;aread('h28);rb=value;
  check(id%500==0 && tick==id*10,"routed sample ID/tick");
  check(ra==1900+id%64 && rb==2100+(2*id)%64,"routed seven-event raw");
  group(2500,2500,2500,3);#1000;kill_lock=1;#20;check({h,l}==0,"SDF lock-loss reset closes");
  #500;kill_lock=0;wait(pwm_debug[22]);#500;pread('h24);check(value==0,"SDF recovery stays disabled");
  pread('h28);check(value==1,"SDF pending cancellation");
  group(1250,2500,3750,4);adopted(4);pwrite('h24,127);#150000;
  check(sample_checks>=7 && edge_checks>=25 && periods>=5,"SDF scenario coverage");
  $display("PWM_SDF_PASS checks=%0d samples=%0d edges=%0d min_dead_ns=%0.3f max_switch_dead_ns=%0.3f periods=%0d adc_minus_peak_ns=[%0.3f,%0.3f]",checks,sample_checks,edge_checks,min_gap,max_gap,periods,min_phase_delta,max_phase_delta);$finish;
 end
 initial begin #10000;$display("SDF_BOUNDARY clk=%b resetn=%b lock=%b adcclk=%b phase=%0d",dut.design_1_i.adc_observer_0.s_axi_aclk,dut.design_1_i.adc_observer_0.s_axi_aresetn,lock_ip,adc_clock,pwm_debug[19:6]);end
 initial begin #3000000;$fatal(1,"SDF watchdog");end
endmodule
