`timescale 1ns/1ps
// One targeted check using the actual generated reset-IP functional netlist.
// Demonstrate the original tied-low reset, then the corrected tied-high path
// and first AXI ID read. No replay of the historical FOC sequence.
module aux_reset_id_tb;
 logic s_axi_aclk=0;
 always #10 s_axi_aclk=~s_axi_aclk;
 wire bad_resetn,bad_bus_resetn,s_axi_aresetn,good_bus_resetn;
 design_1_rst_pl0_0 original_reset(.slowest_sync_clk(s_axi_aclk),
  .ext_reset_in(1'b1),.aux_reset_in(1'b0),.mb_debug_sys_rst(1'b0),.dcm_locked(1'b1),
  .peripheral_aresetn(bad_resetn),.interconnect_aresetn(bad_bus_resetn));
 design_1_rst_pl0_0 fixed_reset(.slowest_sync_clk(s_axi_aclk),
  .ext_reset_in(1'b1),.aux_reset_in(1'b1),.mb_debug_sys_rst(1'b0),.dcm_locked(1'b1),
  .peripheral_aresetn(s_axi_aresetn),.interconnect_aresetn(good_bus_resetn));
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
 initial begin
  repeat(200)@(negedge s_axi_aclk);
  if({bad_resetn,bad_bus_resetn}!==2'b00)$fatal(1,"original AUX=0 did not hold reset");
  if({s_axi_aresetn,good_bus_resetn}!==2'b11)$fatal(1,"fixed AUX=1 failed to release reset");
  s_axi_arvalid=1;
  do @(posedge s_axi_aclk);while(!s_axi_arready);
  @(negedge s_axi_aclk);s_axi_arvalid=0;
  do @(posedge s_axi_aclk);while(!s_axi_rvalid);
  if(s_axi_rresp!==0 || s_axi_rdata!==32'h43314301)$fatal(1,"fixed first AXI ID read failed");
  $display("AUX_RESET_ID_PASS original_resetn=0 fixed_resetn=1 id=%08x checks=3",s_axi_rdata);
  $finish;
 end
 initial begin #10000;$fatal(1,"reset/first ID timeout");end
endmodule
