`timescale 1ns/1ps
// Independent arithmetic/state expectations for MODEL-GENERATED current RTL.
// Integer exact vectors exercise the Q24 ABI; no motor/PI/FOC participates.
module ax03b1_current_tb;
 reg clk=0;always #10 clk=~clk;
 reg rst=1,sample=0,va=1,vb=1,oa=0,ob=0,en=0,restart=0,apply=0;
 reg [15:0] ra=0,rb=0;
 reg [31:0] version=0;
 reg signed [31:0] seed_a=0,seed_b=0,ga=0,gb=0;
 reg ma=0,mb=0;
 reg [7:0] lg=0;
 wire signed [31:0] ia,ib,ic,offset_a,offset_b;
 wire [15:0] count_a,count_b,error;
 wire [31:0] cal_version;
 wire done_a,done_b,valid,clip,result_strobe;
 integer checks=0;
 ax03b1_current_adapter dut(.clk(clk),.rst(rst),.sample_strobe(sample),.raw_a(ra),.raw_b(rb),
 .capture_valid_a(va),.capture_valid_b(vb),.otr_a(oa),.otr_b(ob),.cal_en(en),.cal_restart(restart),
 .config_apply(apply),.config_version(version),.offset_seed_a_q16(seed_a),.offset_seed_b_q16(seed_b),
 .manual_valid_a(ma),.manual_valid_b(mb),.gain_a_q24(ga),.gain_b_q24(gb),.cal_log2_n(lg),
 .ia_q24(ia),.ib_q24(ib),.ic_q24(ic),.offset_a_q16(offset_a),.offset_b_q16(offset_b),
 .cal_count_a(count_a),.cal_count_b(count_b),.cal_done_a(done_a),.cal_done_b(done_b),
 .cal_version(cal_version),.valid(valid),.clip(clip),.error(error),.result_strobe(result_strobe));
 task check(input bit condition,input string label);
 begin checks=checks+1;if(!condition)begin
  $display("CURRENT_DIAGNOSTIC sample=%b apply=%b strobe=%b valid=%b clip=%b error=%h currents=%0d/%0d/%0d done=%b%b offsets=%0d/%0d version=%h",sample,apply,result_strobe,valid,clip,error,ia,ib,ic,done_a,done_b,offset_a,offset_b,cal_version);
  $fatal(1,"AX03B1_CURRENT_FAIL %s",label);
 end end endtask
 task tick;begin @(posedge clk);#1;end endtask
 task configure_inputs(input signed [31:0] sa,input signed [31:0] sb,input signed [31:0] gaina,
             input signed [31:0] gainb,input bit manual,input [7:0] logn,input [31:0] ver);
 begin
  @(negedge clk);sample=0;restart=0;apply=1;seed_a=sa;seed_b=sb;ga=gaina;gb=gainb;
  ma=manual;mb=manual;lg=logn;version=ver;va=1;vb=1;oa=0;ob=0;en=0;
  tick();@(negedge clk);apply=0;
 end endtask
 task observe(input [15:0] a,input [15:0] b,input bit avalid,input bit bvalid,input bit aotr,input bit botr);
 begin @(negedge clk);ra=a;rb=b;va=avalid;vb=bvalid;oa=aotr;ob=botr;sample=1;tick();end endtask
 initial begin
  repeat(4)tick();@(negedge clk);rst=0;
  configure_inputs(32'sd65552384,32'sd131104768,32'sd4194304,-32'sd8388608,1,2,11);
  check(done_a && done_b && cal_version==11,"manual seeds independent and explicitly versioned");
  observe(1001,2002,1,1,0,0);
  check(result_strobe && valid && !clip,"one-cycle aligned result strobe and validity");
  check(ia==32'sd3145728 && ib==-32'sd12582912 && ic==32'sd9437184,"fractional offsets and different signed gains");
  observe(1001,2002,0,1,0,0);check(result_strobe && !valid && error[0] && ia==0 && ib==0 && ic==0,"single bad capture is observable invalid");
  observe(1001,2002,1,1,0,1);check(result_strobe && !valid && error[3],"OTR distinct from capture qualification");
  observe(4096,2002,1,1,0,0);check(!valid && error[0],"out-of-12-bit input rejected");
  configure_inputs(32'sd32768,0,1,1,1,0,12);
  observe(1,0,1,1,0,0);check(valid && ia==0 && ic==0,"positive half tie rounds even zero");
  observe(2,0,1,1,0,0);check(valid && ia==2 && ic==-2,"positive odd half tie rounds even two");
  configure_inputs(32'sd98304,0,1,1,1,0,13);
  observe(1,0,1,1,0,0);check(valid && ia==0,"negative half tie rounds even zero");
  observe(0,0,1,1,0,0);check(valid && ia==-2 && ic==2,"negative odd half tie symmetric");
  configure_inputs(0,0,-32'sd2147483648,-32'sd2147483648,1,0,14);
  observe(1,1,1,1,0,0);
  check(clip && !valid && error[7],"C reconstruction overflow reported");
  check(ia==32'sh80000000 && ib==32'sh80000000 && ic==32'sh7fffffff,"C uses at least 34 signed bits before saturation");
  configure_inputs(0,0,32'sd2147483647,32'sd2147483647,1,0,15);
  observe(4095,4095,1,1,0,0);check(clip && !valid && ia==32'sh7fffffff && ic==32'sh80000000,"extreme products clamp without wrap");
  configure_inputs(0,0,32'sd4194304,-32'sd8388608,0,1,32'hffffffff);
  en=1;observe(1000,2000,1,1,0,0);check(count_a==1 && count_b==1 && !valid,"independent cal accumulators");
  en=0;observe(1100,2200,1,1,0,0);check(count_a==1 && count_b==1,"calibration pause holds both sums/counts");
  en=1;observe(1002,2002,1,1,0,1);check(done_a && !done_b && count_a==2 && count_b==1 && cal_version==0,"independent qualification and version wrap");
  observe(1004,2004,1,1,0,0);check(done_a && done_b && !valid && cal_version==1,"finishing sample invalid, per-channel commit versioned");
  check(offset_a==1001*65536 && offset_b==2002*65536,"independent two-sample offsets");
  observe(1002,2003,1,1,0,0);check(valid && ia==4194304 && ib==-8388608 && ic==4194304,"first post-calibrated pair");
  @(negedge clk);restart=1;sample=1;tick();
  check(result_strobe && !valid && error[8] && !done_a && !done_b && cal_version==2,"restart collision published invalid with new cal epoch");
  @(negedge clk);restart=0;sample=0;apply=1;ma=1;mb=1;seed_a=0;seed_b=0;version=99;tick();
  @(negedge clk);sample=1;tick();check(result_strobe && !valid && error[8],"configuration collision does not silently drop raw frame");
  configure_inputs(-1,0,1,1,1,0,100);observe(1,1,1,1,0,0);check(result_strobe && !valid && error[6],"bad seed configuration cannot qualify numeric results");
  configure_inputs(0,0,32'sd4194304,-32'sd8388608,0,10,1000);en=1;
  repeat(1024)observe(4095,0,1,1,0,0);
  check(done_a && done_b && count_a==1024 && count_b==1024 && !valid,"nominal 1024-sample window and finishing edge");
  check(offset_a==32'sd268369920 && offset_b==0 && cal_version==1002,"maximum calibration sum and independent zero channel");
  observe(4094,1,1,1,0,0);check(valid && ia==-4194304 && ib==-8388608 && ic==12582912,"constant calibration codes are not treated as disconnected");
  $display("AX03B1_CURRENT_PASS checks=%0d",checks);$finish;
 end
 initial begin #2000000;$fatal(1,"current test timeout");end
endmodule
