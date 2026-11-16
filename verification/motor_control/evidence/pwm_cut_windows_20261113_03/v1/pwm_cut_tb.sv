`timescale 1ns/1ps
// Local routed PWM cut only. Annotate /pwm_cut_tb/dut externally with real SDF.
// No RTL surrogate, no internal force; upstream FOC/late-deadline not claimed.
module pwm_cut_tb;
 reg aclk=0,pclk=0;
 always #10 aclk=~aclk;
 // Explicit LOCAL CUT stimulus model, not extracted cross-cut timing coverage.
 // Preserve related, same-rising-edge 2:1 clocks: aclk 10+20n ns,
 // pclk 10+10n ns. Cut-internal clock relationships are not rephased.
 // Source Q changes 0.2ns AFTER the shared edge, never directly on it.
 // The anchor is sampled on the next PWM rise, 9.8ns after source Q;
 // three further rises reach phase5000, 39.8ns after source Q.
 // Source register clock-to-Q is an illustrative 0.2ns, NOT measured routing.
 // anchor and automatic valid/payload/inhibit are source-register outputs.
 // Task requests change at aclk falling edge +0.2ns; outputs update only
 // at aclk rising edge +0.2ns. Async rstn/locked stimulus uses the former
 // safe phase (0.2ns after a PWM rise). Neither drive phase coincides
 // with a PWM rise/fall. The 0.2ns value is a local boundary assumption,
 // NOT the extracted source CQ or full physical path delay. Full-design
 // source/route/clock-tree timing belongs to STA; no cross-cut SDF claim.
 // Keep old #4ns settled observation window.
 localparam realtime SOURCE_CQ=0.2;
 initial begin #5;forever #5 pclk=~pclk;end
 reg anchor_request=0;
 realtime source_rise=0,anchor_rise=0;
 integer anchor_pulses=0,start_checks=0,peak_checks=0,start_cycle=0;
 reg pre_started;
 reg rstn=0,locked=0,fast_inhibit=0,inhibit=1,anchor=0,valid=0;
 reg [38:0] compare=0; reg [31:0] seq=0;
 reg inhibit_request=1;
 // Tasks publish mailbox only at negedge+CQ; driver alone owns valid.
 integer offer_request=0,offer_claimed=0,offer_done=0;
 reg poison_pending=0,source_handshake=0;
 integer trace_tail=0;
 reg [38:0] compare_request=0;reg [31:0] seq_request=0;
 wire [96:0] dbg;
 wire started,pending,accepted,ready,online;
 wire [31:0] adopted_seq;
 // Explicitly terminate every actual cut output (rresp is optimized to 1 bit).
 wire [0:0] axi_rresp,axi_bresp;
 wire [31:0] axi_rdata;
 wire axi_rvalid,axi_bvalid,axi_awready,axi_wready,axi_arready;
 pwm_cut dut(.s_axi_rresp(axi_rresp),.s_axi_rdata(axi_rdata),
 .s_axi_rvalid_reg_0(axi_rvalid),.s_axi_bvalid_reg_0(axi_bvalid),
 .s_axi_bresp(axi_bresp),.s_axi_awready(axi_awready),
 .s_axi_wready(axi_wready),.s_axi_arready(axi_arready),.s_axi_aclk(aclk),.pwm_clk(pclk),.s_axi_aresetn(rstn),
 .\peripheral_aresetn[0]_bufg_place (rstn),
 .\peripheral_aresetn[0]_bufg_place_replica (rstn),
 .locked(locked),.fast_inhibit(fast_inhibit),.adc_anchor(anchor),
 .auto_valid_i(valid),.auto_compare_i(compare),.auto_seq_i(seq),.auto_inhibit_i(inhibit),
 .auto_ready_o(ready),.auto_online_o(online),.auto_applied_seq_o(adopted_seq),
 .started_reg(started),.pending_reg(pending),.accepted_reg(accepted),.debug_o(dbg),
 .s_axi_awaddr(12'd0),.s_axi_awvalid(1'b0),.s_axi_wvalid(1'b0),.s_axi_wstrb(4'hf),
 .s_axi_bready(1'b1),.s_axi_araddr(12'd0),.s_axi_arvalid(1'b0),.s_axi_rready(1'b1));
 // pins.tsv mapping, NOT the original 128-bit RTL debug packing.
 wire [2:0] h=dbg[2:0],l=dbg[5:3],req=dbg[25:23];
 wire [13:0] phase=dbg[19:6];
 wire [31:0] active_seq=dbg[57:26];
 wire [38:0] active_compare=dbg[96:58];
 wire safe=rstn && locked && !inhibit;
 integer checks=0,offers=0,accepts=0,adoptions=0,acks=0,periods=0;
 integer h_edges=0,l_edges=0,zero_checks=0,full_checks=0,cancel_checks=0,rearms=0;
 integer q_events=0,release_checks=0,cycle=0,falls=0,first_fall=0;
 integer target_cycle[0:63];
 reg seen[0:63],banned[0:63];reg [38:0] offered[0:63];
 integer live_id=0;
 reg monitor=0,old_pending=0;reg [31:0] old_seq=0;reg [38:0] old_compare=0;
 reg [2:0] old_h=0,old_l=0;
 realtime off_h[0:2],off_l[0:2],last_rise=0,last_fall=0,last_zero=0;
 realtime last_q=0,min_gap=1e9,max_q=0;
 reg [13:0] pre_phase;
 reg pre_pending;
 task check(input bit good,input string why);
 begin checks++;if(!good)$fatal(1,"PWM_CUT_FAIL %s t=%0t phase=%0d seq=%0d",why,$time,phase,active_seq);end
 endtask
 always @(posedge aclk)begin
  source_rise=$realtime;
  anchor<=#(SOURCE_CQ) anchor_request;
  // OLD boundary values match the bridge and real FOC producer.
  source_handshake=(valid===1 && ready===1 && inhibit===0);
  if(monitor && ((offer_request>0 && seq_request==1 && offer_done==0) || trace_tail>0))begin
   $display("PWM_CUT_FIRST_EDGE t_ns=%0.3f valid=%b ready=%b inhibit=%b seq=%0d pending=%b accepted=%b busy=%b capture_ce=%b dut_request=%b request=%0d claimed=%0d done=%0d handshake=%b",$realtime,valid,ready,inhibit,seq,pending,accepted,dut.busy,dut.frozen_compare0,dut.request_reg_n_0,offer_request,offer_claimed,offer_done,source_handshake);
   if(trace_tail>0)trace_tail--;
  end
  if(!rstn || !locked || inhibit_request)begin
   valid<=#(SOURCE_CQ) 0;poison_pending=0;
  end else if(source_handshake)begin
   // Retire on THIS edge's CQ, never on the next edge.
   valid<=#(SOURCE_CQ) 0;offer_done=offer_claimed;poison_pending=1;
   if(seq==1)begin
    trace_tail=4;
    $display("PWM_CUT_FIRST_HANDSHAKE t_ns=%0.3f seq=%0d retire_due_ns=%0.3f",$realtime,seq,$realtime+SOURCE_CQ);
   end
  end else if(valid)begin
   // Retain valid AND both payload fields through backpressure.
  end else if(poison_pending)begin
   // Deliberately pollute live payload one edge AFTER retirement.
   compare<=#(SOURCE_CQ) {13'd17,13'd31,13'd47};
   seq<=#(SOURCE_CQ) 63;poison_pending=0;
  end else if(offer_request!=offer_claimed)begin
   offer_claimed=offer_request;
   compare<=#(SOURCE_CQ) compare_request;seq<=#(SOURCE_CQ) seq_request;
   valid<=#(SOURCE_CQ) 1;
  end
  inhibit<=#(SOURCE_CQ) inhibit_request;
 end
 // Actual retirement timestamp; read-only observer, never another driver.
 always @(negedge valid)if(monitor && seq==1)
  $display("PWM_CUT_FIRST_RETIRE t_ns=%0.3f valid=%b ready=%b inhibit=%b seq=%0d pending=%b accepted=%b busy=%b capture_ce=%b dut_request=%b",$realtime,valid,ready,inhibit,seq,pending,accepted,dut.busy,dut.frozen_compare0,dut.request_reg_n_0);
 // Check actual boundary transitions, not merely task request scheduling.
 always @(valid or compare or seq or inhibit)if(monitor)begin
  check($realtime-source_rise>=SOURCE_CQ-0.001 &&
        $realtime-source_rise<=SOURCE_CQ+0.001,"automatic boundary changes only at source rising-edge Q");
 end
 // A source pulse is exactly one registered 50MHz cycle (20ns).
 always @(anchor)if(monitor)begin
  check($realtime-source_rise>=SOURCE_CQ-0.001 &&
        $realtime-source_rise<=SOURCE_CQ+0.001,"anchor changes only at source rising-edge Q");
  if(anchor)begin anchor_rise=$realtime;end
  else begin
   check($realtime-anchor_rise>=19.999 && $realtime-anchor_rise<=20.001,"anchor source pulse exactly 20ns");
   anchor_pulses++;
   $display("PWM_CUT_ANCHOR t_ns=%0.3f width_ns=%0.3f pulses=%0d",$realtime,$realtime-anchor_rise,anchor_pulses);
  end
 end
 always @(posedge aclk)if(monitor && safe && valid && ready)begin
  check(seq>0 && seq<64,"bounded offer identity");
  check(!seen[seq],"unique source offer");
  seen[seq]=1;offered[seq]=compare;live_id=seq;offers++;
 end
 always @(h or l)if(monitor)begin
  check(!$isunknown({h,l}) && (h&l)==0,"continuous six-output known/exclusive");
  for(integer g=0;g<3;g++)begin
   if(old_h[g]&&!h[g])off_h[g]=$realtime;
   if(old_l[g]&&!l[g])off_l[g]=$realtime;
   if(h[g]&&!old_h[g])begin
    check($realtime-off_l[g]>=990.0,"H deadtime >=990ns");h_edges++;
    if($realtime-off_l[g]<min_gap)min_gap=$realtime-off_l[g];
   end
   if(l[g]&&!old_l[g])begin
    check($realtime-off_h[g]>=990.0,"L deadtime >=990ns");l_edges++;
    if($realtime-off_h[g]<min_gap)min_gap=$realtime-off_h[g];
   end
  end
  old_h=h;old_l=l;
 end
 // Actual Q changes: distinguish a skewed bank bus from separate adoptions.
 always @(active_seq or active_compare)if(monitor && safe && active_seq!=0)begin
  check($realtime-last_rise>=0 && $realtime-last_rise<4,"bank Q inside real PWM clock event");
  last_q=$realtime;q_events++;
  if($realtime-last_rise>max_q)max_q=$realtime-last_rise;
 end
 always @(negedge pclk)begin falls++;last_fall=$realtime;end
 // Read-only actual exported release nets; do not force any internal state.
 always @(posedge dut.auto_release[0])if(monitor)first_fall=falls;
 always @(posedge dut.auto_release[1])if(monitor)begin
  check(falls==first_fall+1,"two falling-edge release stages");
  check($realtime-last_fall>=0 && $realtime-last_fall<4,"release Q follows PWM falling edge");
  release_checks++;
 end
 always @(posedge pclk)begin
  cycle++;last_rise=$realtime;pre_phase=phase;pre_pending=pending;pre_started=started;
  #4;
  if(monitor)begin
   check(!$isunknown({dbg,started,pending,accepted,ready,online}),"known settled cut ports");
   if(!pre_started && started)begin
    check(phase==4997,"fresh anchor starts phase4997");
    check(last_rise-anchor_rise>=9.799 && last_rise-anchor_rise<=9.801,"start is first safe PWM edge after source Q");
    start_cycle=cycle;start_checks++;
    $display("PWM_CUT_START t_ns=%0.3f cycle=%0d phase=%0d anchor_to_edge_ns=%0.3f",$realtime,cycle,phase,last_rise-anchor_rise);
   end
   if(started && start_cycle>0 && cycle>start_cycle && cycle<=start_cycle+3)begin
    check(phase==4997+(cycle-start_cycle),"startup 4997 to peak5000 consecutive alignment");
    if(cycle==start_cycle+3)begin
     check(last_rise-anchor_rise>=39.799 && last_rise-anchor_rise<=39.801,"peak aligned three PWM edges after startup in local model");
     peak_checks++;
     $display("PWM_CUT_PEAK t_ns=%0.3f cycle=%0d phase=%0d",$realtime,cycle,phase);
    end
   end
   if(!started)last_zero=0;
   else if(phase==0)begin
    if(last_zero!=0)begin check($realtime-last_zero>=99999 && $realtime-last_zero<=100001,"100us carrier");periods++;end
    last_zero=$realtime;
   end
   if(safe && pending && !old_pending)begin
    check(live_id>0 && seen[live_id],"pending has source handshake");
    // A just-received request on valley is ineligible on that same valley.
    // Post-edge phase p: the NEXT valley is exactly (10000-p) edges
    // away, including p==0 where same-edge acceptance is ineligible.
    target_cycle[live_id]=cycle+(10000-phase);accepts++;
   end
   if(safe && active_seq!=0 && (active_seq!=old_seq || active_compare!=old_compare))begin
    check(pre_phase==9999 && phase==0 && pre_pending,"bank changes on eligible valley only");
    check(active_seq<64,"bounded adopted sequence");
    check(seen[active_seq] && !banned[active_seq],"source offer exists and cancelled sequence never revives");
    check(cycle==target_cycle[active_seq],"first eligible valley after pending acceptance");
    check(active_compare===offered[active_seq],"atomic frozen three-phase bank");
    check(last_q>=last_rise && last_q-last_rise<4,"real Q event observed before settled check");
    adoptions++;
    $display("PWM_CUT_ADOPT seq=%0d cycle=%0d abc=%0d/%0d/%0d",active_seq,cycle,active_compare[12:0],active_compare[25:13],active_compare[38:26]);
   end
   if(safe && active_seq>0)begin
    check(active_seq<64 && !banned[active_seq],"no resurrection at any subsequent cycle");
    for(integer g=0;g<3;g++)begin
     if(active_compare[g*13+:13]==0)begin
      check(req[g]===0 && h[g]===0,"C=0 has no high request/output");
      if(phase>=200)check(l[g]===1,"C=0 low output on after fresh deadtime");zero_checks++;
     end
     if(active_compare[g*13+:13]==5000)begin
      check(req[g]===1 && l[g]===0,"C=5000 has no low request/output");
      if(phase>=200)check(h[g]===1,"C=5000 high output on after fresh deadtime");full_checks++;
     end
    end
   end
   old_seq=active_seq;old_compare=active_compare;old_pending=pending;
  end
 end
 task pulse_anchor;
 begin
  $display("PWM_CUT_SCENARIO anchor/restart t_ns=%0.3f",$realtime);
  @(negedge aclk);#(SOURCE_CQ);anchor_request=0;
  repeat(3)@(negedge aclk);#(SOURCE_CQ);anchor_request=1;
  @(negedge aclk);#(SOURCE_CQ);anchor_request=0;
  while(online!==1)begin @(posedge aclk);#4;end
  @(negedge aclk);#(SOURCE_CQ);
 end endtask
 task offer(input integer id,input integer a,input integer b,input integer c);
 begin
  @(negedge aclk);#(SOURCE_CQ);
  while(ready!==1 || inhibit!==0 || offer_request!=offer_done)begin
   @(negedge aclk);#(SOURCE_CQ);
  end
  $display("PWM_CUT_SCENARIO offer t_ns=%0.3f seq=%0d abc=%0d/%0d/%0d",$realtime,id,a,b,c);
  seq_request=id;compare_request={13'(c),13'(b),13'(a)};offer_request++;
  // Only a sampled real handshake can issue this completion token.
  do begin @(negedge aclk);#(SOURCE_CQ);end while(offer_done!=offer_request);
 end endtask
 task finish_offer(input integer id);
 begin
  // Clock polling avoids fixed-task-argument wait sensitivity warnings.
  while(active_seq!=id)begin @(posedge aclk);#4;end
  @(negedge aclk);#(SOURCE_CQ);
  while(adopted_seq!=id)begin @(posedge aclk);#4;end
  acks++;
  while(ready!==1)begin @(posedge aclk);#4;end
  @(negedge aclk);#(SOURCE_CQ);
 end endtask
 task hold_cycles(input integer n);
 begin repeat(n)begin @(posedge pclk);#4;end @(negedge aclk);#(SOURCE_CQ);end endtask
 task cancellation(input integer id,input integer mode);
 begin
  $display("PWM_CUT_SCENARIO cancellation t_ns=%0.3f seq=%0d mode=%0d",$realtime,id,mode);
  // Start sufficiently far before the next valley.
  do begin @(posedge pclk);#4;end while(phase<1000 || phase>2000);
  offer(id,1200,2300,3400);
  while(pending!==1)begin @(posedge pclk);#4;end
  #4;
  check(active_seq!=id,"cancellation really before pending adoption");banned[id]=1;
  @(negedge aclk);#(SOURCE_CQ);
  case(mode)
   0:inhibit_request=1;
   1:locked=0; // Prove loss of LOCKED shuts outputs without an inhibit shortcut.
   2:rstn=0; // Prove global reset independently of inhibit.
  endcase
  #100;
  check({h,l}===0 && pending===0 && active_seq===0,"cancel clears actual pending/bank/outputs");
  if(mode!=0)check(started===0,"clock/global reset clears timebase");
  else check(started===1,"automatic inhibit preserves timebase");
  cancel_checks++;
  // Sticky upstream disarm is an explicit environment assumption only after
  // the independent lock/reset shutdown has already been observed.
  @(negedge aclk);#(SOURCE_CQ);
  if(mode!=0)inhibit_request=1;
  @(negedge aclk);#(SOURCE_CQ);rstn=1;locked=1;
  if(mode!=0)pulse_anchor();
  // Keep upstream disarmed through more than one full frame after recovery.
  hold_cycles(11000);check({h,l}===0 && active_seq===0,"restored clock cannot revive cancelled mailbox");
  @(negedge aclk);#(SOURCE_CQ);inhibit_request=0;
  hold_cycles(11000);check(active_seq===0,"release without fresh request cannot revive old bank");
  offer(id+1,1800,2900,4100);finish_offer(id+1);
  hold_cycles(11000);check(active_seq==id+1,"fresh request rearms only new group");rearms++;
 end endtask
 initial begin
  for(integer i=0;i<64;i++)begin seen[i]=0;banned[i]=0;offered[i]=0;target_cycle[i]=0;end
  for(integer i=0;i<3;i++)begin off_h[i]=-10000;off_l[i]=-10000;end
  // Let glbl GSR and the actual reset trees settle before enabling monitors.
  #500;@(negedge aclk);#(SOURCE_CQ);rstn=1;locked=1;
  #200;monitor=1;
  pulse_anchor();@(negedge aclk);#(SOURCE_CQ);inhibit_request=0;
  offer(1,1000,2500,4000);finish_offer(1);hold_cycles(21000);
  offer(2,1300,2700,4300);finish_offer(2);hold_cycles(11000);
  // Boundary triplets rotate 0/5000 across every phase, not only phase A.
  offer(3,0,5000,2500);finish_offer(3);hold_cycles(11000);
  offer(4,5000,2500,0);finish_offer(4);hold_cycles(11000);
  offer(5,2500,0,5000);finish_offer(5);hold_cycles(11000);
  cancellation(10,0);cancellation(20,1);cancellation(30,2);
  @(negedge aclk);#(SOURCE_CQ);inhibit_request=1;#100;check({h,l}===0,"final inhibit");
  // fast_inhibit is a dangling optimized input in this native cut: no coverage claimed.
  @(negedge aclk);#(SOURCE_CQ);fast_inhibit=1;
  repeat(5)@(negedge aclk);#(SOURCE_CQ);fast_inhibit=0;
  @(negedge aclk);#(SOURCE_CQ);rstn=0;#100;check({h,l}===0 && started===0,"final global reset");
  check(offers==11 && accepts==11 && adoptions==8 && acks==8,"exact offer/accept/adopt/ack coverage");
  check(cancel_checks==3 && rearms==3,"inhibit lock reset cancellation plus fresh rearm coverage");
  check(periods>=10 && h_edges>=9 && l_edges>=9,"nonvacuous carrier and both deadtime directions");
  check(zero_checks>=30000 && full_checks>=30000,"all boundary scenarios exercised");
  check(anchor_pulses==3 && start_checks==3 && peak_checks==3,"nonempty registered anchor and startup peak coverage");
  check(q_events>0 && release_checks>=4,"real routed Q and release events observed");
  $display("PWM_CUT_SOURCE_COVERAGE anchor_pulses=%0d starts=%0d peaks=%0d",anchor_pulses,start_checks,peak_checks);
  $display("PWM_CUT_SDF_PASS checks=%0d offers=%0d accepts=%0d adoptions=%0d acks=%0d periods=%0d h_edges=%0d l_edges=%0d zero=%0d full=%0d cancels=%0d rearms=%0d q_events=%0d releases=%0d min_gap_ns=%0.3f max_q_ns=%0.3f",checks,offers,accepts,adoptions,acks,periods,h_edges,l_edges,zero_checks,full_checks,cancel_checks,rearms,q_events,release_checks,min_gap,max_q);
  $finish;
 end
 // Periodic progress is independent of blocked task waits; no stimulus mutation.
 initial forever begin
  #100000;
  $display("PWM_CUT_PROGRESS t_ns=%0.3f cycle=%0d phase=%0d offers=%0d accepts=%0d adoptions=%0d acks=%0d starts=%0d peaks=%0d",$realtime,cycle,phase,offers,accepts,adoptions,acks,start_checks,peak_checks);
 end
 initial begin #5000000;$fatal(1,"PWM_CUT_FAIL 5ms hard watchdog");end
endmodule
