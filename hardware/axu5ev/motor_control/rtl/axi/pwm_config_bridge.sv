`timescale 1ns/1ps
// One frozen mailbox. Related clocks remain fully timed by STA.
// Request/accepted/applied use level handshakes; payload is stable until
// both acknowledgement levels return low. No per-bit synchronizer assembly.
module pwm_config_bridge(
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 s_axi_aclk CLK", X_INTERFACE_PARAMETER="XIL_INTERFACENAME s_axi_aclk, ASSOCIATED_BUSIF s_axi, ASSOCIATED_RESET s_axi_aresetn, FREQ_HZ 49999500" *) input wire s_axi_aclk,
 (* X_INTERFACE_INFO="xilinx.com:signal:reset:1.0 s_axi_aresetn RST", X_INTERFACE_PARAMETER="XIL_INTERFACENAME s_axi_aresetn, POLARITY ACTIVE_LOW" *) input wire s_axi_aresetn,
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 pwm_clk CLK", X_INTERFACE_PARAMETER="XIL_INTERFACENAME pwm_clk, FREQ_HZ 99999000" *) input wire pwm_clk,
 input wire locked, input wire fast_inhibit, input wire adc_anchor,
 output wire [2:0] high_o, output wire [2:0] low_o,
 output wire [127:0] debug_o,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi AWADDR", X_INTERFACE_PARAMETER="XIL_INTERFACENAME s_axi, PROTOCOL AXI4LITE, DATA_WIDTH 32, ADDR_WIDTH 12, READ_WRITE_MODE READ_WRITE, FREQ_HZ 49999500" *) input wire [11:0] s_axi_awaddr,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi AWPROT" *) input wire [2:0] s_axi_awprot,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi AWVALID" *) input wire s_axi_awvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi AWREADY" *) output wire s_axi_awready,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi WDATA" *) input wire [31:0] s_axi_wdata,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi WSTRB" *) input wire [3:0] s_axi_wstrb,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi WVALID" *) input wire s_axi_wvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi WREADY" *) output wire s_axi_wready,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi BRESP" *) output reg [1:0] s_axi_bresp,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi BVALID" *) output reg s_axi_bvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi BREADY" *) input wire s_axi_bready,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi ARADDR" *) input wire [11:0] s_axi_araddr,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi ARPROT" *) input wire [2:0] s_axi_arprot,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi ARVALID" *) input wire s_axi_arvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi ARREADY" *) output wire s_axi_arready,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi RDATA" *) output reg [31:0] s_axi_rdata,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi RRESP" *) output reg [1:0] s_axi_rresp,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi RVALID" *) output reg s_axi_rvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi RREADY" *) input wire s_axi_rready
);
 import pwm_parameters::*;
 wire clock_resetn=s_axi_aresetn && locked;
 wire mailbox_resetn=clock_resetn && !fast_inhibit;
 (* ASYNC_REG="TRUE" *) reg [1:0] reset_release;
 // Release on falling edges, leaving a half-cycle before positive-edge logic.
 always @(negedge pwm_clk or negedge clock_resetn)
  if(!clock_resetn) reset_release<=0;else reset_release<={reset_release[0],1'b1};
 wire pwm_resetn=reset_release[1];
 reg request;reg [38:0] frozen_compare;reg [31:0] frozen_seq;
 reg [6:0] permission;
 reg [1:0] accept_pipe,apply_pipe,online_pipe;
 reg [1:0] request_pipe;
 always @(posedge pwm_clk or negedge mailbox_resetn)
  if(!mailbox_resetn) request_pipe<=0;
  else request_pipe<={request_pipe[0],request && online_pipe[1]};
 wire accepted,applied,pending,started,valley,peak;
 wire [31:0] active_seq;wire [38:0] active_compare;wire [13:0] phase;
 wire [2:0] high_request;
 pwm_three_phase pwm(.clk(pwm_clk),.resetn(pwm_resetn),.fast_inhibit(fast_inhibit),
 .anchor(adc_anchor),.request(request_pipe[1]),.request_compare(frozen_compare),
 .request_seq(frozen_seq),.permission(permission),.accepted(accepted),.applied(applied),
 .pending(pending),.started(started),.phase(phase),.valley(valley),.peak(peak),
 .active_seq(active_seq),.active_compare(active_compare),.high_o(high_o),.low_o(low_o),.high_request(high_request));
 always @(posedge s_axi_aclk or negedge mailbox_resetn) begin
  if(!mailbox_resetn) begin accept_pipe<=0;apply_pipe<=0;online_pipe<=0;end
  else begin
   accept_pipe<={accept_pipe[0],accepted};apply_pipe<={apply_pipe[0],applied};
   online_pipe<={online_pipe[0],started && !fast_inhibit};
  end
 end
 reg [12:0] shadow_a,shadow_b,shadow_c;
 reg [31:0] shadow_seq,received_seq,adopted_seq,cancel_count,reject_count;
 reg [38:0] adopted_compare;
 reg busy,received,completed,cancelled;
 reg aw_seen,w_seen;reg [11:0] awaddr;reg [31:0] wdata;reg [3:0] wstrb;
 assign s_axi_awready=s_axi_aresetn && !aw_seen && !s_axi_bvalid;
 assign s_axi_wready=s_axi_aresetn && !w_seen && !s_axi_bvalid;
 assign s_axi_arready=s_axi_aresetn && !s_axi_rvalid;
 always @(posedge s_axi_aclk) begin
  if(!s_axi_aresetn) begin
   shadow_a<=0;shadow_b<=0;shadow_c<=0;shadow_seq<=0;frozen_compare<=0;frozen_seq<=0;
   received_seq<=0;adopted_seq<=0;adopted_compare<=0;cancel_count<=0;reject_count<=0;
   busy<=0;received<=0;completed<=0;cancelled<=0;request<=0;permission<=0;
   aw_seen<=0;w_seen<=0;awaddr<=0;wdata<=0;wstrb<=0;s_axi_bvalid<=0;s_axi_bresp<=0;
  end else begin
   if(s_axi_awvalid && s_axi_awready) begin aw_seen<=1;awaddr<=s_axi_awaddr;end
   if(s_axi_wvalid && s_axi_wready) begin w_seen<=1;wdata<=s_axi_wdata;wstrb<=s_axi_wstrb;end
   if(s_axi_bvalid && s_axi_bready) begin s_axi_bvalid<=0;aw_seen<=0;w_seen<=0;end
   if(busy && accept_pipe[1]) begin received<=1;received_seq<=frozen_seq;end
   if(busy && request && apply_pipe[1]) begin
    request<=0;completed<=1;adopted_seq<=frozen_seq;adopted_compare<=frozen_compare;
   end
   if(busy && !request && !accept_pipe[1] && !apply_pipe[1]) busy<=0;
   if(aw_seen && w_seen && !s_axi_bvalid) begin
    s_axi_bvalid<=1;s_axi_bresp<=0;
    if(wstrb!=4'hf) s_axi_bresp<=2;
    else case(awaddr)
     12'h010: if(wdata<=PEAK)shadow_a<=wdata[12:0];else s_axi_bresp<=2;
     12'h014: if(wdata<=PEAK)shadow_b<=wdata[12:0];else s_axi_bresp<=2;
     12'h018: if(wdata<=PEAK)shadow_c<=wdata[12:0];else s_axi_bresp<=2;
     12'h01c: shadow_seq<=wdata;
     12'h020: if(wdata==1 && !busy && online_pipe[1] && !fast_inhibit) begin
      frozen_compare<={shadow_c,shadow_b,shadow_a};frozen_seq<=shadow_seq;
      request<=1;busy<=1;received<=0;completed<=0;cancelled<=0;
     end else begin s_axi_bresp<=2;reject_count<=reject_count+1;end
     12'h024: if(online_pipe[1] && !fast_inhibit) permission<=wdata[6:0];else s_axi_bresp<=2;
     default:s_axi_bresp<=2;
    endcase
   end
   // Lock loss/reset cannot resurrect permissions or outstanding mailboxes.
   if(!online_pipe[1] || fast_inhibit) begin
    request<=0;permission<=0;
    if(busy) begin cancelled<=1;cancel_count<=cancel_count+1;end
    busy<=0;
   end
  end
 end
 always @(posedge s_axi_aclk) begin
  if(!s_axi_aresetn) begin s_axi_rvalid<=0;s_axi_rdata<=0;s_axi_rresp<=0;end
  else begin
   if(s_axi_rvalid && s_axi_rready)s_axi_rvalid<=0;
   if(s_axi_arvalid && s_axi_arready) begin
    s_axi_rvalid<=1;s_axi_rresp<=0;
    case(s_axi_araddr)
     12'h000:s_axi_rdata<=32'h50574d01;
     12'h004:s_axi_rdata<={27'd0,cancelled,completed,received,busy,online_pipe[1]};
     12'h008:s_axi_rdata<=received_seq;
     12'h00c:s_axi_rdata<=adopted_seq;
     12'h010:s_axi_rdata<={19'd0,shadow_a};
     12'h014:s_axi_rdata<={19'd0,shadow_b};
     12'h018:s_axi_rdata<={19'd0,shadow_c};
     12'h01c:s_axi_rdata<=shadow_seq;
     12'h024:s_axi_rdata<={25'd0,permission};
     12'h028:s_axi_rdata<=cancel_count;
     12'h02c:s_axi_rdata<=reject_count;
     12'h030:s_axi_rdata<={19'd0,adopted_compare[12:0]};
     12'h034:s_axi_rdata<={19'd0,adopted_compare[25:13]};
     12'h038:s_axi_rdata<={19'd0,adopted_compare[38:26]};
     12'h040:s_axi_rdata<=PERIOD;
     12'h044:s_axi_rdata<={DEAD_LOW[15:0],DEAD_HIGH[15:0]};
     default:begin s_axi_rdata<=0;s_axi_rresp<=2;end
    endcase
   end
  end
 end
 // Only sampled by PWM-clocked ILA, never as unhandshaken AXI status.
 assign debug_o={21'd0,active_compare,active_seq,permission,high_request,
                 pending,applied,accepted,started,peak,valley,phase,low_o,high_o};
endmodule
