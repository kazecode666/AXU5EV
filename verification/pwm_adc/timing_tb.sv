`timescale 1ns/1ps
// Actual routed ADC, MMCM and PWM cells. PS/AXI fabric/ILA are outside this
// bounded simulation boundary and remain in full-design STA. All three cells
// receive their matching process-corner SDF through xelab -sdfmax/-sdfmin.
module timing_tb;
 reg clk=0;always #10 clk=~clk;
 reg rstn=0;wire pwm_clk,lock_ip;reg kill_lock=0;
 wire locked=lock_ip && !kill_lock;
 wire adc_clock,anchor;wire [63:0] adc_debug;wire [127:0] pwm_debug;
 reg [11:0] raw_a=0,raw_b=0;
 wire [2:0] h,l;
 reg [11:0] pa=0;reg [31:0] pd=0;reg pav=0,pwv=0;
 wire par,pwr,pbv;wire [1:0] pbr;
 reg [11:0] pra=0;reg prv=0;wire prar,prvalid;wire [31:0] prd;wire [1:0] prresp;
 reg [11:0] ara=0;reg arv=0;wire arready,arvalid;wire [31:0] ard;wire [1:0] arresp;
 clock_routed clock_dut(.clk_in1(clk),.resetn(rstn),.locked(lock_ip),.clk_out1(pwm_clk));
 adc_routed adc_dut(.s_axi_aclk(clk),.s_axi_aresetn(rstn),.adc_data_a_i(raw_a),.adc_data_b_i(raw_b),
 .adc_otr_a_i(1'b0),.adc_otr_b_i(1'b0),.adc_clk_a_o(adc_clock),.debug_o(adc_debug),.pwm_anchor_o(anchor),
 .s_axi_awaddr(12'd0),.s_axi_awprot(3'd0),.s_axi_awvalid(1'b0),
 .s_axi_wdata(32'd0),.s_axi_wstrb(4'hf),.s_axi_wvalid(1'b0),.s_axi_bready(1'b1),
 .s_axi_araddr(ara),.s_axi_arprot(3'd0),.s_axi_arvalid(arv),.s_axi_arready(arready),
 .s_axi_rdata(ard),.s_axi_rresp(arresp),.s_axi_rvalid(arvalid),.s_axi_rready(1'b1));
 pwm_routed pwm_dut(.s_axi_aclk(clk),.s_axi_aresetn(rstn),.pwm_clk(pwm_clk),
 .locked(locked),.fast_inhibit(1'b0),.adc_anchor(anchor),.high_o(h),.low_o(l),.debug_o(pwm_debug),
 .s_axi_awaddr(pa),.s_axi_awprot(3'd0),.s_axi_awvalid(pav),.s_axi_awready(par),
 .s_axi_wdata(pd),.s_axi_wstrb(4'hf),.s_axi_wvalid(pwv),.s_axi_wready(pwr),
 .s_axi_bvalid(pbv),.s_axi_bready(1'b1),.s_axi_bresp(pbr),
 .s_axi_araddr(pra),.s_axi_arprot(3'd0),.s_axi_arvalid(prv),.s_axi_arready(prar),
 .s_axi_rdata(prd),.s_axi_rresp(prresp),.s_axi_rvalid(prvalid),.s_axi_rready(1'b1));
 integer checks=0,conversion=0,sample_checks=0,edge_checks=0,periods=0;
 realtime off_h[3],off_l[3],min_gap=1.0e9,max_gap=0,last_zero=0;
 reg [2:0] old_h=0,old_l=0;reg monitoring=0;reg [31:0] value,id,tick,ra,rb;
 task check(input bit good,input string why);begin checks++;if(!good)$fatal(1,"%s t=%0t",why,$time);end endtask
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
 always @(posedge adc_clock)begin
  if(conversion%500==0)begin
   // Observe after routed register propagation, before next 100MHz edge.
   #5;
   if(pwm_debug[22] && !kill_lock)begin
    check(pwm_debug[19:6]==5000,"routed selected sample / peak relation");sample_checks++;
   end
  end
  #4;if(conversion>=7)begin raw_a=1900+(conversion-7)%64;raw_b=2100+(2*(conversion-7))%64;end
  conversion++;
 end
 task pwrite(input [11:0] a,input [31:0] d);begin
  @(negedge clk);check(par,"SDF AW ready before request");pa=a;pd=d;pav=1;
  @(negedge clk);pav=0;pwv=1;
  @(negedge clk);pwv=0;wait(pbv);#1;check(pbr==0,"SDF AXI write response");@(negedge clk);
 end endtask
 task pread(input [11:0] a);begin
  @(negedge clk);pra=a;prv=1;@(negedge clk);prv=0;
  wait(prvalid);#1;check(prresp==0,"SDF AXI read response");value=prd;@(negedge clk);
 end endtask
 task aread(input [11:0] a);begin
  @(negedge clk);ara=a;arv=1;@(negedge clk);arv=0;
  wait(arvalid);#1;check(arresp==0,"SDF ADC snapshot response");value=ard;@(negedge clk);
 end endtask
 task group(input integer a,b,c,s);begin
  pwrite('h10,a);pwrite('h14,b);pwrite('h18,c);pwrite('h1c,s);pwrite('h20,1);
 end endtask
 task adopted(input integer s);begin
  value=0;while(value!=s)begin #1000;pread('h0c);end
  pread(4);while(value[1])begin #200;pread(4);end
 end endtask
 initial begin
  for(integer i=0;i<3;i++)begin off_h[i]=-10000;off_l[i]=-10000;end
  #500;@(negedge clk);rstn=1;#200;monitoring=1;
  wait(lock_ip);wait(pwm_debug[22]);#500;
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
  check(sample_checks>=7 && edge_checks>=25,"SDF scenario coverage");
  $display("PWM_SDF_PASS checks=%0d samples=%0d edges=%0d min_dead_ns=%0.3f max_switch_dead_ns=%0.3f",checks,sample_checks,edge_checks,min_gap,max_gap);$finish;
 end
 initial begin #3000000;$fatal(1,"SDF watchdog");end
endmodule
