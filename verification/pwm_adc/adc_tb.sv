`timescale 1ns/1ps
module adc_tb;
 reg clk=0,pclk=0,clock_run=1;always #10 clk=~clk;initial begin #5;forever #5 if(clock_run)pclk=~pclk;end
 // Rising edges coincide at 10,30,... ns; intervening PWM edges at 20,40,...
 reg rstn=0,locked=0,inhibit=0;
 reg [11:0] raw_a=0,raw_b=0;wire adc_clock,anchor;
 reg [11:0] aa=0,pa=0;reg [31:0] ad=0,pd=0;
 reg av=0,wv=0,pav=0,pwv=0;wire ar,wr,bv,par,pwr,pbv;wire [1:0] br,pbr;
 wire [2:0] h,l;wire [127:0] debug_pwm;
 ax03b3_adc_observer #(.TEST_INPUT(0)) adc(
 .s_axi_aclk(clk),.s_axi_aresetn(rstn),.adc_data_a_i(raw_a),.adc_data_b_i(raw_b),
 .adc_otr_a_i(1'b0),.adc_otr_b_i(1'b0),.adc_clk_a_o(adc_clock),.pwm_anchor_o(anchor),
 .s_axi_awaddr(aa),.s_axi_awprot(3'd0),.s_axi_awvalid(av),.s_axi_awready(ar),
 .s_axi_wdata(ad),.s_axi_wstrb(4'hf),.s_axi_wvalid(wv),.s_axi_wready(wr),
 .s_axi_bvalid(bv),.s_axi_bready(1'b1),.s_axi_bresp(br),
 .s_axi_araddr(12'd0),.s_axi_arprot(3'd0),.s_axi_arvalid(1'b0),.s_axi_rready(1'b1));
 pwm_config_bridge bridge(.s_axi_aclk(clk),.s_axi_aresetn(rstn),.pwm_clk(pclk),
 .locked(locked),.fast_inhibit(inhibit),.adc_anchor(anchor),.high_o(h),.low_o(l),.debug_o(debug_pwm),
 .s_axi_awaddr(pa),.s_axi_awprot(3'd0),.s_axi_awvalid(pav),.s_axi_awready(par),
 .s_axi_wdata(pd),.s_axi_wstrb(4'hf),.s_axi_wvalid(pwv),.s_axi_wready(pwr),
 .s_axi_bvalid(pbv),.s_axi_bready(1'b1),.s_axi_bresp(pbr),
 .s_axi_araddr(12'd0),.s_axi_arprot(3'd0),.s_axi_arvalid(1'b0),.s_axi_rready(1'b1));
 integer checks=0,conversions=0,frames=0,phases=0,valid_frames=0,cancel_tests=0;
 integer last_sample=-1,before_conversion;time first_sample=0;time selected_at;
 task check(input bit ok,input string why);begin checks++;if(!ok)$fatal(1,"%s t=%0t phase=%d",why,$time,bridge.phase);end endtask
 function automatic [11:0] code_a(input integer id);code_a=1900+id%64;endfunction
 function automatic [11:0] code_b(input integer id);code_b=2100+(2*id)%64;endfunction
 // Model the converter BEFORE the receiver: seven complete conversion events,
 // tPD=4ns, original capture at +80ns. No TEST mux/hierarchical raw forcing.
 always @(posedge adc_clock) begin
  if(conversions==0)first_sample=$time;
  if(conversions%500==0)begin
   selected_at=$time;
   if(last_sample>=0)check(conversions-last_sample==500,"500 conversion cadence");
   last_sample=conversions;
   #0.001;
   if(bridge.started)begin check(bridge.phase==5000,"sample exactly PWM peak");phases++;end
  end
  #4;
  if(conversions>=7) begin raw_a=code_a(conversions-7);raw_b=code_b(conversions-7);end
  conversions++;
 end
 always @(negedge clk)if(rstn && adc.pair_strobe)begin
  check(adc.pair_id==frames*500,"selected sample_id");
  check(adc.pair_tick==adc.pair_id*10,"tick remains 50MHz");
  check(adc.pair_a==code_a(adc.pair_id) && adc.pair_b==code_b(adc.pair_id),"seven-event raw association");
  check($time-first_sample-adc.pair_tick*20==1490,"capture return latency");
  frames++;
 end
 always @(negedge clk)if(rstn && adc.result_strobe && adc.valid)begin
  check($signed(adc.ia)==($signed({1'b0,adc.aligned_a})-1930)*65536,"A result association");
  check($signed(adc.ib)==($signed({1'b0,adc.aligned_b})-2128)*65536,"B result association");
  check($signed(adc.ic)==-($signed(adc.ia)+$signed(adc.ib)),"current zero sum");
  check(adc.payload[2*32+17]==0 && adc.payload[2*32+16]==0,"REAL marker preserved");
  valid_frames++;
 end
 task awrite(input [11:0] a,input [31:0] d);begin
  @(negedge clk);aa=a;ad=d;av=1;wv=1;
  @(negedge clk);av=0;wv=0;wait(bv);check(br==0,"ADC write");@(negedge clk);
 end endtask
 task pwrite(input [11:0] a,input [31:0] d,input bit reject);begin
  @(negedge clk);pa=a;pd=d;pav=1;
  @(negedge clk);pav=0;pwv=1;
  @(negedge clk);pwv=0;wait(pbv);check(pbr==(reject?2:0),"PWM AXI response");@(negedge clk);
 end endtask
 task group(input integer a,b,c,s);begin
  pwrite('h10,a,0);pwrite('h14,b,0);pwrite('h18,c,0);pwrite('h1c,s,0);pwrite('h20,1,0);
 end endtask
 initial begin
  repeat(8)@(negedge clk);rstn=1;locked=1;
  awrite('h100,0);awrite('h104,0);awrite('h108,65536);awrite('h10c,65536);
  awrite('h110,2);awrite('h114,1);awrite('h118,5);
  wait(bridge.online_pipe[1]);group(1250,2500,3750,1);
  wait(bridge.received);check(bridge.busy && !bridge.completed,"received not adopted");
  pwrite('h20,1,1);pwrite('h10,4999,0);pwrite('h24,127,0);
  wait(bridge.completed);check(bridge.adopted_compare=={13'd3750,13'd2500,13'd1250},"frozen group");
  wait(!bridge.busy);check(bridge.adopted_seq==1,"adoption feedback");
  // Late and early arrivals remain full groups across the related clocks.
  group(3750,1250,2500,2);wait(!bridge.busy);check(bridge.adopted_seq==2,"second adoption");
  pwrite('h24,0,0);repeat(4)@(negedge pclk);check({h,l}==0,"disable crosses domain");
  // Loss of lock cancels pending request and asynchronously clears outputs,
  // including when PWM clock is unavailable (separate stopped-clock test below).
  group(2500,2500,2500,3);wait(bridge.accepted);#2;locked=0;#0.001;
  check({h,l}==0,"lock loss async outputs");repeat(8)@(negedge clk);
  check(bridge.cancelled && bridge.cancel_count==1 && bridge.permission==0,"cancelled not applied");cancel_tests++;
  locked=1;wait(bridge.online_pipe[1]);repeat(20)@(negedge clk);
  check(!bridge.busy && bridge.adopted_seq==2 && {h,l}==0,"no stale commit/re-enable");
  group(1250,2500,3750,4);wait(!bridge.busy);check(bridge.adopted_seq==4,"explicit post-loss request");
  pwrite('h24,127,0);wait(|h);@(negedge pclk);clock_run=0;before_conversion=conversions;
  #2;locked=0;#0.001;check({h,l}==0,"lock loss with stopped PWM clock");
  repeat(30)@(negedge clk);check(conversions>before_conversion,"ADC continues with stopped PWM");
  clock_run=1;locked=1;wait(bridge.online_pipe[1]);
  check(bridge.permission==0 && {h,l}==0,"stopped-clock recovery needs explicit enable");
  group(1250,2500,3750,5);wait(!bridge.busy);pwrite('h24,127,0);wait(|h);
  // A short inhibit cannot be missed by the 50 MHz permission latch.
  @(negedge clk);#2;inhibit=1;#0.001;check({h,l}==0,"fast inhibit asynchronous");#2;inhibit=0;
  repeat(15)@(negedge clk);check(bridge.permission==0 && {h,l}==0,"fast inhibit requires explicit re-enable");
  wait(valid_frames>=6);check(phases>=8 && frames>=10,"multi-frame sample phase coverage");
  $display("PWM_ADC_PASS checks=%0d frames=%0d phases=%0d valid=%0d cancellations=%0d",checks,frames,phases,valid_frames,cancel_tests);$finish;
 end
 initial begin #3000000;$fatal(1,"ADC PWM watchdog");end
endmodule
