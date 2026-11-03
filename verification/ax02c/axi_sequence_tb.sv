`timescale 1ns/1ps
// The single C1 short sequence: actual AXI transactions, actual p3 arithmetic.
module ax02c_axi_sequence_tb;
 logic s_axi_aclk=0,s_axi_aresetn=0;
 always #10 s_axi_aclk=~s_axi_aclk;
 logic [7:0] s_axi_awaddr=0,s_axi_araddr=0;
 logic [2:0] s_axi_awprot=0,s_axi_arprot=0;
 logic s_axi_awvalid=0,s_axi_wvalid=0,s_axi_arvalid=0;
 logic s_axi_bready=1,s_axi_rready=1;
 logic [31:0] s_axi_wdata=0;
 logic [3:0] s_axi_wstrb=4'hf;
 wire s_axi_awready,s_axi_wready,s_axi_bvalid,s_axi_arready,s_axi_rvalid;
 wire [1:0] s_axi_bresp,s_axi_rresp;
 wire [31:0] s_axi_rdata;
 axu5ev_foc_axi dut(.*);
 logic [656:0] vectors[0:16];
 logic [31:0] sid,ia,ib,ic,iq,id,vd,eu,ev,ew;
 logic [39:0] theta,omega;
 logic pi_reset;
 logic [63:0] xd,xq,ad,aq;
 logic [31:0] value,f0,f1,seq,ru,rv,rw;
 logic [272:0] held;
 integer checks=0,run_clocks=0,captures=0,duty_checks=0;
 string path;
 task automatic require(input bit condition,input string message);
  checks++;
  if(!condition)$fatal(1,"AX02C_AXI_FAIL %s",message);
 endtask
 task automatic wr(input [7:0] addr,input [31:0] data);
  // Legal independent address then data channels, not a combined write strobe.
  @(negedge s_axi_aclk);s_axi_awaddr=addr;s_axi_awvalid=1;
  do @(posedge s_axi_aclk);while(!s_axi_awready);
  @(negedge s_axi_aclk);s_axi_awvalid=0;s_axi_wdata=data;s_axi_wvalid=1;
  do @(posedge s_axi_aclk);while(!s_axi_wready);
  @(negedge s_axi_aclk);s_axi_wvalid=0;
  do @(posedge s_axi_aclk);while(!s_axi_bvalid);
  require(s_axi_bresp==0,"AXI write response");
  @(negedge s_axi_aclk);
 endtask
 task automatic rd(input [7:0] addr,output [31:0] data);
  @(negedge s_axi_aclk);s_axi_araddr=addr;s_axi_arvalid=1;
  do @(posedge s_axi_aclk);while(!s_axi_arready);
  @(negedge s_axi_aclk);s_axi_arvalid=0;
  do @(posedge s_axi_aclk);while(!s_axi_rvalid);
  require(s_axi_rresp==0,"AXI read response");data=s_axi_rdata;
  @(negedge s_axi_aclk);
 endtask
 task automatic submit(input integer row);
  {sid,ia,ib,ic,theta,omega,iq,id,pi_reset,vd,eu,ev,ew,xd,xq,ad,aq}=vectors[row];
  wr('h40,ia);wr('h44,ib);wr('h48,ic);
  wr('h4c,theta[31:0]);wr('h50,{24'b0,theta[39:32]});
  wr('h54,omega[31:0]);wr('h58,{24'b0,omega[39:32]});
  wr('h5c,iq);wr('h60,id);wr('h64,{31'b0,pi_reset});wr('h68,vd);
  wr('h08,row+1);
 endtask
 // The thin wrapper's boundary must remain aligned with the accepted frame top.
 always @(posedge s_axi_aclk)begin
  if(s_axi_aresetn && dut.running)begin
   run_clocks++;
   if(dut.phase==0)begin
    #1;held=dut.frame_core.held_inputs;
   end else #1;
   require(dut.phase===dut.frame_core.phase,"continuous original 5000-clock phase");
   require(dut.frame_core.held_inputs===held,"atomic nine-field hold for whole frame");
   require(dut.frame_core.core.clk_enable===1'b1,"FOC continues after edge315");
   if(dut.frame_core.phase==315)begin
    captures++;
    require(dut.core_frame==captures && dut.capture_edge==315,"one capture per continuous frame");
   end
  end
 end
 initial begin
  if(!$value$plusargs("vectors=%s",path))$fatal(1,"missing vectors");
  $readmemh(path,vectors);
  repeat(4)@(negedge s_axi_aclk);s_axi_aresetn=1;
  rd('h00,value);require(value==32'h43314301,"module identity");
  wr('h04,1);submit(0);
  rd('h24,value);require((value&7)==2,"first data committed before start");
  require(run_clocks==0,"no hidden calculation frames before START");
  wr('h04,2);
  for(integer row=0;row<17;row++)begin
   do rd('h14,f0);while(f0==row);
   require(f0==row+1,"no skipped or repeated vector frames");
   rd('h10,seq);rd('h18,ru);rd('h1c,rv);rd('h20,rw);rd('h14,f1);
   require(f1==f0 && seq==row+1,"coherent triple with command/frame provenance");
   require(ru===eu,"duty U integer bits");duty_checks++;
   require(rv===ev,"duty V integer bits");duty_checks++;
   require(rw===ew,"duty W integer bits");duty_checks++;
   rd('h0c,value);require(value==row+1,"adopted command matches result");
   rd('h2c,value);require(value==315,"actual core capture phase");
   rd('h24,value);require((value&'h17)==5,"running valid, no pending or hold error");
   if(row<16)begin
    submit(row+1);
    rd('h0c,value);require(value==row+1,"commit cannot change the current frame");
   end
  end
  wr('h04,4);
  do rd('h24,value);while(value[0]);
  require(!value[4],"hold status retained through STOP");
  rd('h28,value);require(value==17,"last full frame completes before stopping");
  rd('h14,value);require(value==17,"last result retained after STOP");
  require(run_clocks==85000 && captures==17 && duty_checks==51,"exact short-sequence comparison window");
  $display("AX02C_AXI_PASS frames=%0d duty_checks=%0d run_clocks=%0d checks=%0d",captures,duty_checks,run_clocks,checks);
  $finish;
 end
 initial begin #3000000;$fatal(1,"AX02C_AXI_FAIL sequence timeout");end
endmodule
