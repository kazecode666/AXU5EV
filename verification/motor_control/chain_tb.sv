`timescale 1ns/1ps
// Actual ADC buses and ABZ pads enter their existing receivers. FOC inputs,
// model-derived comparison values and target-valley adoption are observed.
module chain_tb;
 reg clk=0,pclk=0;always #10 clk=~clk;
 initial begin #5;forever #5 pclk=~pclk;end
 reg rstn=0,locked=0,a=0,b=0,z=0,otr_a=0;
 reg [11:0] raw_a=0,raw_b=0;
 wire adc_clock,anchor;
 reg [11:0] aa=0,pa=0,ra=0;reg [31:0] ad=0,pd=0;
 reg av=0,wv=0,pav=0,pwv=0,rv=0,rr=0;
 wire ar,wr,bv,par,pwr,pbv,rar,rvalid;wire [1:0] br,pbr,rresp;
 wire [31:0] rdata;wire [2:0] h,l;wire [127:0] pwm_debug;
 wire auto_valid,auto_ready,auto_inhibit,auto_online;
 wire [38:0] auto_compare;wire [31:0] auto_seq,applied_seq;
 ax03b3_adc_observer #(.ENCODER_FEEDBACK(1),.TEST_ABZ(0),.AUTO_CONTROL(1)) adc(
 .s_axi_aclk(clk),.s_axi_aresetn(rstn),.adc_data_a_i(raw_a),.adc_data_b_i(raw_b),
 .abz_a_i(a),.abz_b_i(b),.abz_z_i(z),.adc_otr_a_i(otr_a),.adc_otr_b_i(1'b0),
 .adc_clk_a_o(adc_clock),.pwm_anchor_o(anchor),
 .auto_valid_o(auto_valid),.auto_compare_o(auto_compare),.auto_seq_o(auto_seq),
 .auto_inhibit_o(auto_inhibit),.auto_ready_i(auto_ready),
 .auto_applied_seq_i(applied_seq),.auto_online_i(auto_online),
 .s_axi_awaddr(aa),.s_axi_awprot(3'd0),.s_axi_awvalid(av),.s_axi_awready(ar),
 .s_axi_wdata(ad),.s_axi_wstrb(4'hf),.s_axi_wvalid(wv),.s_axi_wready(wr),
 .s_axi_bvalid(bv),.s_axi_bready(1'b1),.s_axi_bresp(br),
 .s_axi_araddr(ra),.s_axi_arprot(3'd0),.s_axi_arvalid(rv),.s_axi_arready(rar),
 .s_axi_rdata(rdata),.s_axi_rresp(rresp),.s_axi_rvalid(rvalid),.s_axi_rready(rr));
 pwm_config_bridge #(.AUTO_FOC(1)) bridge(
 .s_axi_aclk(clk),.s_axi_aresetn(rstn),.pwm_clk(pclk),
 .locked(locked),.fast_inhibit(1'b0),.adc_anchor(anchor),
 .auto_valid_i(auto_valid),.auto_compare_i(auto_compare),.auto_seq_i(auto_seq),
 .auto_inhibit_i(auto_inhibit),.auto_ready_o(auto_ready),
 .auto_applied_seq_o(applied_seq),.auto_online_o(auto_online),
 .high_o(h),.low_o(l),.debug_o(pwm_debug),
 .s_axi_awaddr(pa),.s_axi_awprot(3'd0),.s_axi_awvalid(pav),.s_axi_awready(par),
 .s_axi_wdata(pd),.s_axi_wstrb(4'hf),.s_axi_wvalid(pwv),.s_axi_wready(pwr),
 .s_axi_bvalid(pbv),.s_axi_bready(1'b1),.s_axi_bresp(pbr),
 .s_axi_araddr(12'd0),.s_axi_arprot(3'd0),.s_axi_arvalid(1'b0),.s_axi_rready(1'b1));
 `define CONTROL adc.auto_path.controller
 integer checks=0,conversions=0,publications=0,foc_frames=0,adoptions=0,invalid_frames=0;
 integer trace_fd,packet_fd,current_fd,angle_fd,phase_checks=0,triplet_checks=0;
 bit reset_logged=0;
 reg [31:0] angle_count,angle_zero,angle_version;
 reg angle_ready,angle_reverse;reg [15:0] angle_offset;
 integer ce_checks=0,previous_tc=0,last_result_cycle=-1,logic_cycles=0;
 bit core_seen=0,late_test=0;integer late_tests=0,clock_tests=0;
 reg [31:0] previous_active=0;
 reg [38:0] offered_compare[0:20000];reg offered[0:20000];
 reg [63:0] sampled_tick[0:20000];realtime sampled_at[0:20000];
 reg [31:0] sampled_count[0:20000];reg [79:0] sampled_z[0:20000];
 reg [2559:0] packets[0:63];
 reg [31:0] word,snapshot_seq;reg [1:0] response;reg [2559:0] frozen;
 integer invalid_conversion=-1;
 task check(input bit ok,input string why);begin checks++;if(!ok)$fatal(1,"MOTOR_CHAIN_FAIL %s t=%0t",why,$time);end endtask
 always @(posedge clk)begin
  if(!rstn)begin
   if(!reset_logged)begin $fwrite(current_fd,"R\n");$fwrite(angle_fd,"R\n");reset_logged=1;end
  end else begin
   reset_logged=0;
   if(adc.current.sample_strobe || adc.current.config_apply || adc.current.cal_restart)begin
    // Exact original function argument order, BEFORE this consuming edge.
    $fwrite(current_fd,"%0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d ",
     adc.current.sample_strobe,adc.current.raw_a,adc.current.raw_b,adc.current.capture_valid_a,adc.current.capture_valid_b,
     adc.current.otr_a,adc.current.otr_b,adc.current.cal_en,adc.current.cal_restart,adc.current.config_apply,
     adc.current.config_version,adc.current.offset_seed_a_q16,adc.current.offset_seed_b_q16,
     adc.current.manual_valid_a,adc.current.manual_valid_b,adc.current.gain_a_q24,adc.current.gain_b_q24,adc.current.cal_log2_n);
    #0.001;
    $fwrite(current_fd,"%0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d\n",
     adc.ia,adc.ib,adc.ic,adc.oa,adc.ob,adc.ca,adc.cb,adc.da,adc.db,adc.version,adc.valid,adc.clip,adc.error,adc.result_strobe);
   end
  end
 end
 always @(posedge clk)if(rstn && adc.pair_strobe)begin
  angle_count=adc.frame_count;angle_ready=adc.frame_ready;angle_zero=adc.frame_zero;
  angle_offset=adc.frame_phase[15:0];angle_reverse=adc.frame_direction;angle_version=adc.frame_version;
 end
 always @(negedge clk)if(rstn && adc.angle_strobe)begin
  // One accepted input followed by registered output from the same frame.
  $fwrite(angle_fd,"1 %0d %0d %0d %0d %0d %0d %0d %0d %0d\n",
   angle_count,angle_ready,angle_zero,angle_offset,angle_reverse,angle_version,
   adc.theta_q32,adc.angle_valid,adc.angle_version);
 end
 function automatic [11:0] code_a(input integer id);code_a=2000+(id>=1500?(id/500)%3-1:0);endfunction
 function automatic [11:0] code_b(input integer id);code_b=2100+(id>=1500?1-(id/500)%3:0);endfunction
 function automatic [12:0] comparison(input [31:0] duty);
  reg [63:0] scaled;begin
   if(duty>=32'h40000000)comparison=5000;
   else begin scaled=64'(duty)*5000+64'd536870912;comparison=scaled>>30;end
  end
 endfunction
 // Seven physical conversion events and 4ns tPD, before the receiver.
 always @(posedge adc_clock)begin
  if(conversions%500==0)begin
   sampled_at[conversions]=$realtime;
   #0.001;
   if(bridge.started)begin check(bridge.phase==5000,"actual selected ADC sampling at PWM peak");phase_checks++;end
  end
  #4;
  if(conversions>=7)begin
   raw_a=code_a(conversions-7);raw_b=code_b(conversions-7);
   otr_a=((conversions-7)==invalid_conversion);
  end
  conversions++;
 end
 always @(posedge clk)if(rstn && adc.adc_phase==0 && adc.observe_phase==0)begin
  sampled_tick[conversions]=adc.tick;sampled_count[conversions]=adc.enc_count;
 end
 // Every frozen numerical frame is exported, including invalid PI-reset
 // frames. The independent original FOC model consumes this exact table.
 always @(negedge clk)if(rstn && `CONTROL.foc_result_pulse)begin
  $fwrite(trace_fd,"%08x %016x %08x %08x %08x %08x %08x %08x %010x %010x %08x %01x %08x %08x %08x\n",
   `CONTROL.capture_id,`CONTROL.capture_tick,`CONTROL.capture_ref_version,
   `CONTROL.foc_ia,`CONTROL.foc_ib,`CONTROL.foc_ic,`CONTROL.foc_id,`CONTROL.foc_iq,
   `CONTROL.foc_theta,`CONTROL.foc_omega,`CONTROL.foc_vdc,`CONTROL.foc_pi,
   `CONTROL.core_du,`CONTROL.core_dv,`CONTROL.core_dw);
  check(`CONTROL.capture_tick===sampled_tick[`CONTROL.capture_id],"FOC retains actual ADC sample tick");
  check(`CONTROL.foc.hold_violation==0,"nine FOC input fields hold throughout complete frame");
  if(last_result_cycle>=0)check(logic_cycles-last_result_cycle==5000,"new FOC result event exactly once per full 5000 enables");
  last_result_cycle=logic_cycles;
  if(`CONTROL.capture_valid)begin
   check(`CONTROL.foc_theta>40'sh0100000000 && `CONTROL.foc_omega==0,"nonzero stopped QEP exercises 40bit rad angle, explicit zero electrical speed");
   if(`CONTROL.capture_ref_version==2)check(`CONTROL.foc_iq==3355443,"next sampled reference step adopted as one version");
   else check(`CONTROL.foc_iq==1677722,"pending shadow writes do not corrupt frozen reference");
  end
  if(!`CONTROL.capture_valid)begin check(`CONTROL.foc_pi,"invalid feedback requests PI reset as data");invalid_frames++;end
  foc_frames++;
 end
 always @(negedge clk)begin
  logic_cycles++;
  if(!rstn)begin core_seen=0;last_result_cycle=-1;end
  else if(`CONTROL.core_started)begin
   check(!`CONTROL.core_reset && !`CONTROL.foc.timing_restart && `CONTROL.foc.core.clk_enable,"core continuously enabled after its single startup alignment");
   if(core_seen)check(`CONTROL.foc.core.u_FOC_DUT_tc.count5000==(previous_tc==4999?0:previous_tc+1),"timing controller advances through all 5000 cycles after output capture");
   previous_tc=`CONTROL.foc.core.u_FOC_DUT_tc.count5000;core_seen=1;ce_checks++;
  end
 end
 always @(posedge clk)if(rstn && auto_valid && auto_ready)begin
  check(auto_seq<20000,"automatic source sample identity in test range");
  check(auto_compare[12:0]==comparison(`CONTROL.core_du) &&
        auto_compare[25:13]==comparison(`CONTROL.core_dv) &&
        auto_compare[38:26]==comparison(`CONTROL.core_dw),"generated Q30 mapping matches independent count oracle");
  offered[auto_seq]=1;offered_compare[auto_seq]=auto_compare;triplet_checks++;
 end
 always @(posedge pclk)begin
  #0.001;
  if(rstn && !auto_inhibit && bridge.active_seq!=previous_active)begin
   check(bridge.phase==0,"FOC triplet adopted only at carrier valley");
   check(offered[bridge.active_seq],"adoption came from automatic FOC offer");
   check(bridge.active_compare===offered_compare[bridge.active_seq],"three phases are adopted as one frozen group");
   check($realtime-sampled_at[bridge.active_seq]>=49999.99 && $realtime-sampled_at[bridge.active_seq]<=50000.01,"sample k applied at its +50us target valley");
   adoptions++;previous_active=bridge.active_seq;
  end
  if(!rstn || auto_inhibit)begin previous_active=0;#0.1;check({h,l}==0,"reset or invalid/disabled automatic path keeps all six outputs off");end
  else check(!$isunknown({h,l}) && (h&l)==0,"six registered outputs known and complementary");
 end
 always @(posedge clk)if(rstn && adc.snapshot_strobe)begin
  check(adc.snapshot_payload[0+:32]==32'h4d435431 && adc.snapshot_payload[32+:32]==3,"MCT1 schema3 unified identity");
  check(adc.snapshot_payload[3*32+:32]<20000,"sample identifier survives complete chain");
  publications++;packets[publications]=adc.snapshot_payload;
  for(integer w=0;w<80;w++)$fwrite(packet_fd,"%08x ",adc.snapshot_payload[w*32+:32]);
  $fwrite(packet_fd,"\n");
 end
 task awrite(input [11:0] address,input [31:0] data);begin
  @(negedge clk);aa=address;ad=data;av=1;wv=1;
  @(negedge clk);av=0;wv=0;wait(bv);check(br==0,"ADC/reference AXI write accepted");@(negedge clk);
 end endtask
 task pwrite(input [11:0] address,input [31:0] data,input [1:0] expected);begin
  @(negedge clk);pa=address;pd=data;pav=1;pwv=1;
  @(negedge clk);pav=0;pwv=0;wait(pbv);check(pbr==expected,"static automatic/manual source selection");@(negedge clk);
 end endtask
 task reference(input [31:0] iq,input [31:0] version,input bit arm);begin
  awrite('h180,0);awrite('h184,iq);awrite('h188,0);awrite('h18c,0);
  awrite('h190,32'h30000000);awrite('h194,0);awrite('h198,version);awrite('h19c,arm);awrite('h1a0,1);
 end endtask
 task read_word(input [11:0] address,input integer stall,output [31:0] value,output [1:0] resp);begin
  @(negedge clk);ra=address;rv=1;rr=0;@(posedge clk);while(!rar)@(posedge clk);
  @(negedge clk);rv=0;wait(rvalid);value=rdata;resp=rresp;
  repeat(stall)begin @(negedge clk);check(rvalid && rdata===value,"80word snapshot stable under backpressure");end
  rr=1;@(posedge clk);@(negedge clk);rr=0;
 end endtask
 initial begin
  trace_fd=$fopen("foc_frames.txt","w");packet_fd=$fopen("motor_frames.txt","w");
  current_fd=$fopen("current_events.txt","w");angle_fd=$fopen("angle_events.txt","w");
  if(!trace_fd || !packet_fd || !current_fd || !angle_fd)$fatal(1,"Cannot open numerical frame tables");
  for(integer i=0;i<20000;i++)begin offered[i]=0;offered_compare[i]=0;end
  repeat(8)@(negedge clk);rstn=1;locked=1;
  // Calibration and references are submitted before the first usable sample.
  awrite('h100,0);awrite('h104,0);awrite('h108,65536);awrite('h10c,65536);
  awrite('h110,1);awrite('h114,1);awrite('h118,5);
  awrite('h140,0);awrite('h144,7500);awrite('h148,0);awrite('h14c,1);awrite('h150,1);
  // Reposition through four real, qualified AB edges and stop well before
  // the first 100us feedback. All sampled usable vectors are stationary,
  // so omega=0 is explicit and consistent. Quarter phase exercises bit32+.
  {a,b}=2'b01;repeat(30)@(negedge clk);
  {a,b}=2'b11;repeat(30)@(negedge clk);
  {a,b}=2'b10;repeat(30)@(negedge clk);
  {a,b}=2'b00;z=1;repeat(30)@(negedge clk);
  check(adc.enc_count==4 && adc.enc_z_seen,"existing QEP pad receiver supplies stopped nonzero position and Z");
  reference(32'd1677722,1,1); // +0.1A q reference, staticQEP and omega=0.
  pwrite('h020,1,2); // static AUTO_FOC forbids the manual-duty commit source.
  wait(foc_frames>=4);
  // Mid-frame changes must not alter the currently frozen FOC transaction.
  #10000;reference(32'd3355443,2,1);
  awrite('h184,32'd8388608); // shadow only, no commit: must never enter FOC.
  wait(adoptions>=3);
  #1000;awrite('h1a4,1);#100;check({h,l}==0,"explicit disarm closes outputs without waiting for valley");
  wait(foc_frames>=7);reference(32'd1677722,3,1);
  // An invalid actual ADC event reaches the same current/FOC/pwm chain.
  invalid_conversion=4500;
  wait(foc_frames>=11);
  read_word(0,1,snapshot_seq,response);check(response==0,"freeze whole control observation");frozen=packets[snapshot_seq];
  read_word('h0ac,0,word,response);check(response==0,"ENC41 old finalword is not terminal in schema3");
  for(integer i=0;i<80;i++)begin read_word(12'h00c+4*i,i%2,word,response);check(response==0 && word===frozen[i*32+:32],"all 80words from one frozen frame");end
  read_word('h00c,0,word,response);check(response==2,"word79 response releases unified observation");
  check(phase_checks>=10 && foc_frames>=11 && invalid_frames>=3 && adoptions>=4 && triplet_checks>=4,"calibration/state/reference/automatic-adoption coverage reached");
  // Fault injection only at the documented mailbox ready interface. Sensor
  // and numerical inputs still traverse the actual chain unchanged.
  force auto_ready=0;
  wait(`CONTROL.capture_id==5500);wait(`CONTROL.frame_late);
  #100;check(auto_inhibit && `CONTROL.late_count==1 && !auto_valid,"late transaction explicitly invalidates/cancels pending offer");
  #3000;check(bridge.active_seq!=5500 && {h,l}==0,"late frame cannot slip into the next valley");late_tests++;
  release auto_ready;reference(32'd1677722,4,1);
  wait(bridge.active_seq==6000);#1000;locked=0;#100;
  check(auto_inhibit && {h,l}==0,"clock loss clears automatic output and pending state");
  locked=1;wait(auto_online);#1000;
  check(`CONTROL.lock_blocked && auto_inhibit && {h,l}==0,"held arm cannot revive output after clock recovery");clock_tests++;
  reference(32'd1677722,5,1);wait(bridge.active_seq==7000);
  awrite('h1a4,1);#100;check({h,l}==0,"final internal output stop");
  rstn=0;repeat(3)@(negedge clk);check({h,l}==0 && !`CONTROL.core_started,"explicit global reset clears scheduler/state/output at run end");
  $fclose(trace_fd);$fclose(packet_fd);$fclose(current_fd);$fclose(angle_fd);
  $display("MOTOR_CHAIN_PASS checks=%0d foc_frames=%0d publications=%0d adoptions=%0d invalid_frames=%0d phases=%0d triplets=%0d ce_clocks=%0d late=%0d clock_rearm=%0d",checks,foc_frames,publications,adoptions,invalid_frames,phase_checks,triplet_checks,ce_checks,late_tests,clock_tests);$finish;
 end
 initial begin #2000000;$fatal(1,"MOTOR chain watchdog");end
endmodule
