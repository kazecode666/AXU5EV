`timescale 1ns/1ps
module pwm_tb;
 reg clk=0;always #5 clk=~clk;
 reg resetn=0,inhibit=0,anchor=0,request=0;
 reg [38:0] cmp=0;reg [31:0] seq=0;reg [6:0] permission=0;
 wire accepted,applied,pending,started,valley,peak;
 wire [13:0] phase;wire [31:0] active_seq;wire [38:0] active_compare;
 wire [2:0] h,l,req;
 pwm_three_phase dut(.clk(clk),.resetn(resetn),.fast_inhibit(inhibit),.anchor(anchor),
 .request(request),.request_compare(cmp),.request_seq(seq),.permission(permission),
 .accepted(accepted),.applied(applied),.pending(pending),.started(started),.phase(phase),
 .valley(valley),.peak(peak),.active_seq(active_seq),.active_compare(active_compare),
 .high_o(h),.low_o(l),.high_request(req));
 integer checks=0,cycles=0,valleys=0,last_valley=-1;
 integer last_h_off[3],last_l_off[3];reg [2:0] old_h=0,old_l=0;
 task check(input bit good,input string why);begin checks++;if(!good)$fatal(1,"%s t=%0t phase=%d",why,$time,phase);end endtask
 always @(negedge clk) begin
  cycles++;
  if(resetn && started) begin
   check((h & l)==0,"mutual exclusion");check(!$isunknown({h,l}),"known outputs");
   for(integer i=0;i<3;i++)begin
    if(old_h[i]&&!h[i])last_h_off[i]=cycles;
    if(old_l[i]&&!l[i])last_l_off[i]=cycles;
    if(h[i]&&!old_h[i])check(cycles-last_l_off[i]>=100,"high dead time");
    if(l[i]&&!old_l[i])check(cycles-last_h_off[i]>=100,"low dead time");
   end
   if(phase==0) begin
    if(last_valley>=0)check(cycles-last_valley==10000,"period exactly 10000");
    last_valley=cycles;valleys++;
   end
  end
  old_h=h;old_l=l;
 end
 task start;begin
  @(negedge clk);resetn=1;repeat(3)@(negedge clk);anchor=1;@(negedge clk);anchor=0;
  wait(started);end endtask
 task commit(input integer a,b,c,input integer p);begin
  @(negedge clk);while(phase!=p)@(negedge clk);cmp={13'(c),13'(b),13'(a)};seq++;request=1;
  wait(accepted);@(negedge clk);cmp=0; // frozen pending must not be contaminated
  wait(applied);#1;check(active_seq==seq,"applied sequence");
  check(active_compare=={13'(c),13'(b),13'(a)},"whole group at valley");
  @(negedge clk);request=0;wait(!accepted);end endtask
 task count_period(input integer a,b,c);integer n[3],nh[3],nl[3],cv[3],eh,el;begin
  wait(phase==0);@(negedge clk);cv[0]=a;cv[1]=b;cv[2]=c;
  for(integer i=0;i<3;i++)begin n[i]=0;nh[i]=0;nl[i]=0;end
  repeat(10000)begin @(posedge clk);for(integer i=0;i<3;i++)begin n[i]+=req[i];nh[i]+=h[i];nl[i]+=l[i];end end
  check(n[0]==2*a && n[1]==2*b && n[2]==2*c,"2*C raw high intervals");
  for(integer i=0;i<3;i++)begin
   eh=cv[i]==5000?10000:((2*cv[i]>100)?2*cv[i]-100:0);
   el=cv[i]==0?10000:((10000-2*cv[i]>100)?9900-2*cv[i]:0);
   check(nh[i]==eh && nl[i]==el,"actual six-output pulse width after dead time");
  end
 end endtask
 initial begin
  for(integer i=0;i<3;i++)begin last_h_off[i]=-1000;last_l_off[i]=-1000;end
  repeat(5)@(negedge clk);
  anchor=1;resetn=1;repeat(5)@(negedge clk);
  check(!started,"reset release inside anchor must wait a fresh edge");
  anchor=0;repeat(3)@(negedge clk);anchor=1;@(negedge clk);anchor=0;
  check(started && phase==4997,"fresh anchor starts defined phase");permission=127;
  commit(1250,2500,3750,6000);count_period(1250,2500,3750);
  commit(3750,1250,2500,9994);count_period(3750,1250,2500);
  // Exactly on destination valley: must remain pending for a FULL period.
  @(negedge clk);while(phase!=9999)@(negedge clk);cmp={13'd5000,13'd50,13'd0};seq++;request=1;
  @(negedge clk);check(phase==0 && pending && active_seq!=seq,"same-edge receive deferred");
  wait(phase==9998);check(active_seq!=seq,"pending held until next valley");
  wait(applied);@(negedge clk);request=0;wait(!accepted);count_period(0,50,5000);
  // C=50 has 100 high-request clocks, exactly dead time: no delayed pulse.
  wait(phase==0);repeat(10000)begin @(negedge clk);check(h[0]==0 && h[1]==0,"zero/narrow high suppression");check(l[2]==0,"100 percent low suppressed");end
  commit(51,4949,2500,1);count_period(51,4949,2500);
  // Runtime disable not delayed to valley. All permission combinations
  // checked by a full period; only pre-existing PWM requests may be enabled.
  for(integer mask=0;mask<8;mask++)begin
   @(negedge clk);permission=0;@(negedge clk);check({h,l}==0,"disable next clock");
   permission={1'b1,3'(7-mask),3'(mask)};
   repeat(100)begin @(negedge clk);check({h,l}==0,"reenable waits valley");end
   wait(phase==0);repeat(10000)begin @(negedge clk);
    check((h & ~permission[2:0])==0 && (l & ~permission[5:3])==0,"permission masks");end
  end
  @(negedge clk);permission=127;wait(phase==1000);#2;inhibit=1;#0.001;check({h,l}==0,"asynchronous fast inhibit");
  repeat(5)@(negedge clk);permission=0;inhibit=0;
  repeat(200)begin @(negedge clk);check({h,l}==0,"no old timer revival");end
  #2;resetn=0;#0.001;check({h,l}==0,"async reset/lock loss shutdown");
  last_valley=-1;repeat(5)@(negedge clk);start();
  repeat(200)begin @(negedge clk);check({h,l}==0,"reset permission remains disabled");end
  check(valleys>=15,"coverage periods");
  $display("PWM_PASS checks=%0d valleys=%0d",checks,valleys);$finish;
 end
 initial begin #10000000;$fatal(1,"PWM watchdog");end
endmodule
