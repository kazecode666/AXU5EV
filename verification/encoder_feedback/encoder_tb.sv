`timescale 1ns/1ps
// Stimulus enters the ADC pads and original ABZ synchronizer/filter. The
// metadata oracle samples old registered ABZ at phase 0, never phase 4.
module encoder_tb #(
 parameter [31:0] INITIAL_COUNT=32'hfffffffe,
 parameter [31:0] CONFIG_ZERO=32'd25
);
 reg clk=0,pclk=0;always #10 clk=~clk;initial begin #5;forever #5 pclk=~pclk;end
 reg rstn=0,locked=0,a=1,b=1,z=1;
 reg [11:0] raw_a=0,raw_b=0;wire adc_clock,anchor;
 reg [11:0] aa=0,pa=0,ra=0;reg [31:0] ad=0,pd=0;
 reg av=0,wv=0,pav=0,pwv=0,rv=0,rr=0;
 wire ar,wr,bv,par,pwr,pbv,rar,rvalid;wire [1:0] br,pbr,rresp;
 wire [31:0] rdata;wire [2:0] h,l;wire [127:0] pwm_debug;
 ax03b3_adc_observer #(.ENCODER_FEEDBACK(1),.TEST_ABZ(0),.ENCODER_INITIAL_COUNT(INITIAL_COUNT)) adc(
 .s_axi_aclk(clk),.s_axi_aresetn(rstn),.adc_data_a_i(raw_a),.adc_data_b_i(raw_b),
 .abz_a_i(a),.abz_b_i(b),.abz_z_i(z),
 .adc_otr_a_i(1'b0),.adc_otr_b_i(1'b0),.adc_clk_a_o(adc_clock),.pwm_anchor_o(anchor),
 .s_axi_awaddr(aa),.s_axi_awprot(3'd0),.s_axi_awvalid(av),.s_axi_awready(ar),
 .s_axi_wdata(ad),.s_axi_wstrb(4'hf),.s_axi_wvalid(wv),.s_axi_wready(wr),
 .s_axi_bvalid(bv),.s_axi_bready(1'b1),.s_axi_bresp(br),
 .s_axi_araddr(ra),.s_axi_arprot(3'd0),.s_axi_arvalid(rv),.s_axi_arready(rar),
 .s_axi_rdata(rdata),.s_axi_rresp(rresp),.s_axi_rvalid(rvalid),.s_axi_rready(rr));
 pwm_config_bridge bridge(.s_axi_aclk(clk),.s_axi_aresetn(rstn),.pwm_clk(pclk),
 .locked(locked),.fast_inhibit(1'b0),.adc_anchor(anchor),.high_o(h),.low_o(l),.debug_o(pwm_debug),
 .s_axi_awaddr(pa),.s_axi_awprot(3'd0),.s_axi_awvalid(pav),.s_axi_awready(par),
 .s_axi_wdata(pd),.s_axi_wstrb(4'hf),.s_axi_wvalid(pwv),.s_axi_wready(pwr),
 .s_axi_bvalid(pbv),.s_axi_bready(1'b1),.s_axi_bresp(pbr),
 .s_axi_araddr(12'd0),.s_axi_arprot(3'd0),.s_axi_arvalid(1'b0),.s_axi_rready(1'b1));
 integer checks=0,conversions=0,publications=0,phases=0,valid_currents=0;
 integer frame_fd;
 integer coincident=0,phase4_changed=0,moved_returns=0,wrap_tests=0,frame_wraps=0;
 reg [225:0] meta[0:20000];reg [63:0] sample_ticks[0:20000];
 longint expected_theta[0:20000];reg expected_valid[0:20000];
 reg [31:0] expected_cfg[0:20000];reg [1311:0] history[0:63];
 reg expected_pending=0,angle_initialized=0;
 reg [31:0] cfg_zero=0,cfg_offset=0,cfg_version=0,previous_count=0;
 reg cfg_direction=0;longint phase_count=0;reg [31:0] pre_count;
 integer source_id=0;reg [31:0] word,snapshot_seq;reg [1:0] response;reg [1311:0] frozen;
 task check(input bit ok,input string why);begin checks++;if(!ok)$fatal(1,"ENCODER_FAIL %s t=%0t",why,$time);end endtask
 function automatic [11:0] code_a(input integer id);code_a=1900+id%64;endfunction
 function automatic [11:0] code_b(input integer id);code_b=2100+(2*id)%64;endfunction
 function automatic longint modulo_period(input longint value);
  longint v;begin v=value%30000;if(v<0)v=v+30000;modulo_period=v;end
 endfunction
 // Exactly seven complete converter events precede output data; tPD=4ns.
 always @(posedge adc_clock) begin
  if(conversions%500==0)begin
   #0.001;if(bridge.started)begin check(bridge.phase==5000,"selected ADC sample at PWM peak");phases++;end
  end
  #4;if(conversions>=7)begin raw_a=code_a(conversions-7);raw_b=code_b(conversions-7);end
  conversions++;
 end
 always @(posedge clk)if(rstn && adc.adc_phase==0)begin: sample_oracle
  longint delta,absolute_count,out_phase;
  meta[source_id]={adc.enc_ready,adc.enc_z_seen,adc.enc_illegal,adc.enc_z_tick,adc.enc_z_count,adc.enc_count};
  sample_ticks[source_id]=adc.tick;
  if(source_id%500==0)begin
   if(expected_pending)begin
    if(cfg_zero!=CONFIG_ZERO)angle_initialized=0;
    cfg_zero=CONFIG_ZERO;cfg_offset=7500;cfg_direction=1;cfg_version=7;expected_pending=0;
   end
   expected_cfg[source_id]=cfg_version;
   expected_valid[source_id]=adc.enc_ready;
   if(!adc.enc_ready)begin angle_initialized=0;expected_theta[source_id]=0;end
   else begin
    if(!angle_initialized)begin absolute_count=$signed(adc.enc_count-cfg_zero);phase_count=modulo_period(absolute_count);end
    else begin
     delta=$signed(adc.enc_count-previous_count);phase_count=modulo_period(phase_count+delta);
     if((previous_count>32'hfffffff0 && adc.enc_count<32'h00000010) ||
        (!previous_count[31] && adc.enc_count[31] && delta>0))frame_wraps++;
    end
    previous_count=adc.enc_count;angle_initialized=1;
    out_phase=modulo_period((cfg_direction?-phase_count:phase_count)+cfg_offset);
    expected_theta[source_id]=longint'($floor(out_phase*6.2831853071795864769*4294967296.0/30000.0+0.5));
   end
   pre_count=adc.enc_count;
   #0.001;if(adc.enc_count!=pre_count)coincident++;
  end
  source_id++;
 end
 always @(posedge clk)if(rstn && adc.adc_phase==4 && ((source_id-1)%500)==0)begin
  #0.001;if(adc.enc_count!=meta[source_id-1][31:0])phase4_changed++;
 end
 always @(posedge clk)if(rstn && adc.publish_strobe)begin: publish_oracle
  integer id;longint observed,difference;
  id=adc.payload[3*32+:32];
  check(id<20000 && id%500==0,"selected conversion identity");
  check(id==publications*500,"every selected frame publishes, including invalid startup");
  check(adc.payload[0+:32]==32'h454e4346 && adc.payload[32+:32]==2,"ENCF schema2 identity");
  check(adc.payload[4*32+:64]===sample_ticks[id] && sample_ticks[id]==id*10,"sample tick 50MHz / 500 conversion spacing");
  check(adc.tick-sample_ticks[id]==110,"sample-to-atomic-publication latency is 110 logic clocks");
  check(adc.payload[28*32+:32]==1 && adc.payload[29*32+:32]==34,"published numerical latency contract");
  check(adc.payload[6*32+:32]==code_a(id) && adc.payload[7*32+:32]==code_b(id),"ADC pad pipeline raw association");
  check(adc.payload[16*32+:32]===meta[id][31:0],"position from sample phase0, not data phase4");
  check(adc.payload[17*32+:32]===meta[id][63:32],"Z count belongs to same frame");
  check(adc.payload[18*32+:64]===meta[id][127:64],"Z timestamp belongs to same frame");
  check(adc.payload[20*32+:32]===meta[id][159:128],"illegal_count belongs to same frame");
  check(adc.payload[2*32+9]===meta[id][161] && adc.payload[2*32+10]===meta[id][160],"ready / Z quality belongs to frame");
  check(!adc.payload[2*32+17] && !adc.payload[2*32+18],"physical false and external ABZ test source distinct");
  check(adc.payload[34*32+:32]==expected_cfg[id],"configuration version chosen at selected sample");
  check(adc.payload[38*32+1]===expected_valid[id],"angle valid independent of current calibration");
  observed=$signed(adc.payload[32*32+:64]);difference=observed-expected_theta[id];
  check(!expected_valid[id] || (difference>=-1 && difference<=1),"Q32 rad independent mathematical quantization reference");
  check(adc.payload[39*32+:32]==30000 && adc.payload[40*32+:32]==1000,"single explicit test count scale");
  if(adc.payload[2*32+7])begin
   check($signed(adc.payload[8*32+:32])==$signed({1'b0,code_a(id)})*65536-$signed(adc.payload[11*32+:32]),"same-frame A formula unchanged");
   check($signed(adc.payload[9*32+:32])==$signed({1'b0,code_b(id)})*65536-$signed(adc.payload[12*32+:32]),"same-frame B formula unchanged");
   check($signed(adc.payload[10*32+:32])==-$signed(adc.payload[8*32+:32])-$signed(adc.payload[9*32+:32]),"same-frame C zero sum");valid_currents++;
  end
  if(adc.enc_count!=meta[id][31:0])moved_returns++;
  for(integer w=0;w<41;w++)$fwrite(frame_fd,"%08x ",adc.payload[w*32+:32]);
  $fwrite(frame_fd,"\n");
  publications++;history[publications]=adc.payload;
 end
 task awrite(input [11:0] address,input [31:0] data);begin
  @(negedge clk);aa=address;ad=data;av=1;wv=1;
  @(negedge clk);av=0;wv=0;wait(bv);check(br==0,"ADC/config AXI write");@(negedge clk);
 end endtask
 task pwrite(input [11:0] address,input [31:0] data);begin
  @(negedge clk);pa=address;pd=data;pav=1;pwv=1;
  @(negedge clk);pav=0;pwv=0;wait(pbv);check(pbr==0,"PWM AXI write");@(negedge clk);
 end endtask
 task read_word(input [11:0] address,input integer stall,output [31:0] value,output [1:0] resp);begin
  @(negedge clk);ra=address;rv=1;rr=0;@(posedge clk);while(!rar)@(posedge clk);
  @(negedge clk);rv=0;wait(rvalid);value=rdata;resp=rresp;
  repeat(stall)begin @(negedge clk);check(rvalid && rdata===value,"snapshot holds under backpressure");end
  rr=1;@(posedge clk);@(negedge clk);rr=0;
 end endtask
 task set_ab(input [1:0] state,input [31:0] expected);begin
  @(negedge clk);{a,b}=state;repeat(10)@(negedge clk);check(adc.enc_count===expected,"original decoder legal/illegal/count wrap");
 end endtask
 initial begin
  frame_fd=$fopen("encoder_frames.txt","w");if(!frame_fd)$fatal(1,"Cannot open frame replay output");
  repeat(8)@(negedge clk);rstn=1;locked=1;
  repeat(12)@(negedge clk);check(adc.enc_ready && adc.enc_count==INITIAL_COUNT && !adc.enc_z_seen,"nonzero startup phase and high Z only establish history");
  z=0;repeat(10)@(negedge clk);
  set_ab(2'b10,INITIAL_COUNT+1);set_ab(2'b00,INITIAL_COUNT+2);wrap_tests++;
  set_ab(2'b10,INITIAL_COUNT+1);set_ab(2'b11,INITIAL_COUNT);wrap_tests++;
  set_ab(2'b00,INITIAL_COUNT);check(adc.enc_illegal==1,"illegal double bit jump counted");
  @(negedge clk);b=1;z=1;@(negedge clk);b=0;z=0;
  repeat(12)@(negedge clk);check(adc.enc_count==INITIAL_COUNT && adc.enc_illegal==1 && !adc.enc_z_seen,"one-clock AB and Z glitches rejected");
  @(negedge clk);b=1;z=1;repeat(12)@(negedge clk);
  check(adc.enc_z_seen && adc.enc_z_count==INITIAL_COUNT+1 && adc.enc_count==INITIAL_COUNT+1,"coincident accepted Z latches after-AB count without clearing position");
  awrite('h100,0);awrite('h104,0);awrite('h108,65536);awrite('h10c,65536);
  awrite('h110,2);awrite('h114,1);awrite('h118,5);
  wait(bridge.online_pipe[1]);pwrite('h10,1250);pwrite('h14,2500);pwrite('h18,3750);pwrite('h1c,1);pwrite('h20,1);pwrite('h24,127);
  // A transition offered at phase7 is accepted at next phase0 (fourth edge).
  do @(negedge clk);while(!(adc.adc_phase==7 && conversions==1000));
  {a,b}=2'b11;
  do @(negedge clk);while(adc.adc_phase!=1);
  {a,b}=2'b10; // accepted at phase4: must not replace sample-time metadata.
  wait(publications>=4); // retain angle history through a sampled raw wrap before reconfiguration.
  awrite('h140,CONFIG_ZERO);awrite('h144,7500);awrite('h148,1);awrite('h14c,7);awrite('h150,1);expected_pending=1;
  awrite('h140,99); // pending frozen group must survive subsequent shadow writes.
  repeat(800)begin
   @(negedge clk);
   case({a,b})2'b00:{a,b}=2'b01;2'b01:{a,b}=2'b11;2'b11:{a,b}=2'b10;2'b10:{a,b}=2'b00;endcase
   repeat(12)@(negedge clk);
  end
  wait(publications>=7);read_word(0,2,snapshot_seq,response);check(response==0 && snapshot_seq<=publications,"freeze one complete new snapshot");frozen=history[snapshot_seq];
  read_word('h088,0,word,response);check(response==0 && word===frozen[31*32+:32],"old word31 is no longer terminal for schema2");
  repeat(6000)@(negedge clk); // force an intervening new publication while frozen.
  for(integer i=0;i<41;i++)begin read_word(12'h00c+4*i,i%3,word,response);check(response==0 && word===frozen[i*32+:32],"all 41 fields are one frozen frame");end
  read_word('h00c,0,word,response);check(response==2,"new last word40 response releases bank");
  check(coincident>0 && phase4_changed>0 && moved_returns>0,"sample-boundary hazards actually exercised");
  check(valid_currents>=3 && phases>=7 && wrap_tests==2,"current/PWM/wrap coverage reached");
  check(frame_wraps>=1,"sampled raw wrap exercises continuous electric phase");
  pwrite('h24,0);repeat(5)@(negedge pclk);check({h,l}==0,"unchanged PWM disable");
  $fclose(frame_fd);
  $display("ENCODER_PASS checks=%0d publications=%0d phases=%0d current=%0d coincident=%0d capture_changed=%0d wraps=%0d frame_wraps=%0d",checks,publications,phases,valid_currents,coincident,phase4_changed,wrap_tests,frame_wraps);$finish;
 end
 initial begin #3000000;$fatal(1,"ENCODER watchdog");end
endmodule

module encoder_signed_boundary_tb;
 encoder_tb #(.INITIAL_COUNT(32'h7ffffffe),.CONFIG_ZERO(0)) signed_boundary();
endmodule
