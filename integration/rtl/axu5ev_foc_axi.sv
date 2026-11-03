`timescale 1ns/1ps
// One pending command, one continuous 5000-clock frame stream. No CDC here:
// the PS/standard AXI interconnect delivers this interface in the PL clock domain.
module axu5ev_foc_axi (
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 s_axi_aclk CLK", X_INTERFACE_PARAMETER="ASSOCIATED_BUSIF s_axi, ASSOCIATED_RESET s_axi_aresetn" *)
 input wire s_axi_aclk,
 (* X_INTERFACE_INFO="xilinx.com:signal:reset:1.0 s_axi_aresetn RST", X_INTERFACE_PARAMETER="POLARITY ACTIVE_LOW" *)
 input wire s_axi_aresetn,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi AWADDR", X_INTERFACE_PARAMETER="PROTOCOL AXI4LITE, DATA_WIDTH 32, ADDR_WIDTH 8, READ_WRITE_MODE READ_WRITE" *)
 input wire [7:0] s_axi_awaddr,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi AWPROT" *) input wire [2:0] s_axi_awprot,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi AWVALID" *) input wire s_axi_awvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi AWREADY" *) output wire s_axi_awready,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi WDATA" *) input wire [31:0] s_axi_wdata,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi WSTRB" *) input wire [3:0] s_axi_wstrb,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi WVALID" *) input wire s_axi_wvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi WREADY" *) output wire s_axi_wready,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi BRESP" *) output logic [1:0] s_axi_bresp,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi BVALID" *) output logic s_axi_bvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi BREADY" *) input wire s_axi_bready,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi ARADDR" *) input wire [7:0] s_axi_araddr,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi ARPROT" *) input wire [2:0] s_axi_arprot,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi ARVALID" *) input wire s_axi_arvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi ARREADY" *) output wire s_axi_arready,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi RDATA" *) output logic [31:0] s_axi_rdata,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi RRESP" *) output logic [1:0] s_axi_rresp,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi RVALID" *) output logic s_axi_rvalid,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 s_axi RREADY" *) input wire s_axi_rready
);
 logic aw_pending,w_pending;
 logic [7:0] awaddr;
 logic [31:0] wdata;
 logic [3:0] wstrb;
 wire write_fire=aw_pending && w_pending && !s_axi_bvalid;
 assign s_axi_awready=!aw_pending && !s_axi_bvalid;
 assign s_axi_wready=!w_pending && !s_axi_bvalid;
 assign s_axi_arready=!s_axi_rvalid;
 wire control_write=write_fire && awaddr==8'h04 && wstrb[0];
 wire initialize=control_write && wdata[0];
 logic [31:0] stage[0:10];
 logic [272:0] pending_data,active_data;
 logic [31:0] pending_seq,adopted_seq,result_seq,result_frame,completed_frames;
 logic pending_valid,running,stop_requested,valid,hold_error;
 logic [12:0] result_capture_edge;
 logic [12:0] phase;
 logic [31:0] result_u,result_v,result_w,seen_frame;
 wire [31:0] du,dv,dw,core_frame;
 wire [12:0] capture_edge;
 wire core_valid,hold_violation;
 wire [272:0] stage_data={stage[0],stage[1],stage[2],stage[4][7:0],stage[3],
   stage[6][7:0],stage[5],stage[7],stage[8],stage[9][0],stage[10]};
 wire signed [31:0] ia,ib,ic,iq_ref,id_ref;
 wire signed [39:0] theta_e,omega_e;
 wire integrator_clear;
 wire [31:0] vdc;
 assign {ia,ib,ic,theta_e,omega_e,iq_ref,id_ref,integrator_clear,vdc}=active_data;
 wire core_reset=!s_axi_aresetn || initialize || !running;
 axu5ev_foc_frame_top frame_core(
   .clk(s_axi_aclk),.global_reset(core_reset),.timing_restart(1'b0),
   .ia(ia),.ib(ib),.ic(ic),.iq_ref(iq_ref),.id_ref(id_ref),
   .theta_e(theta_e),.omega_e(omega_e),.integrator_clear(integrator_clear),.vdc(vdc),
   .duty_u(du),.duty_v(dv),.duty_w(dw),.frame_id(core_frame),
   .capture_edge(capture_edge),.result_valid(core_valid),.hold_violation(hold_violation));

 function automatic [31:0] merge_bytes(input [31:0] old_value,new_value,input [3:0] strobes);
   for(integer b=0;b<4;b++) merge_bytes[b*8+:8]=strobes[b]?new_value[b*8+:8]:old_value[b*8+:8];
 endfunction
 function automatic [31:0] read_word(input [7:0] addr);
   case(addr)
    8'h00:read_word=32'h43314301;
    8'h0c:read_word=adopted_seq;
    8'h10:read_word=result_seq;
    8'h14:read_word=result_frame;
    8'h18:read_word=result_u;
    8'h1c:read_word=result_v;
    8'h20:read_word=result_w;
    8'h24:read_word={27'b0,hold_error,stop_requested,valid,pending_valid,running};
    8'h28:read_word=completed_frames;
    // Preserve the actual capture phase after stopping/resetting the core.
    8'h2c:read_word={19'b0,result_capture_edge};
    default: begin
      if(addr>=8'h40 && addr<=8'h68 && addr[1:0]==0)read_word=stage[(addr-8'h40)>>2];
      else read_word=0;
    end
   endcase
 endfunction

 // AW and W are independent; each is held until both are available.
 always @(posedge s_axi_aclk) begin
  if(!s_axi_aresetn)begin
    aw_pending<=0;w_pending<=0;awaddr<=0;wdata<=0;wstrb<=0;
    s_axi_bvalid<=0;s_axi_bresp<=0;s_axi_rvalid<=0;s_axi_rdata<=0;s_axi_rresp<=0;
  end else begin
    if(s_axi_awvalid && s_axi_awready)begin aw_pending<=1;awaddr<=s_axi_awaddr;end
    if(s_axi_wvalid && s_axi_wready)begin w_pending<=1;wdata<=s_axi_wdata;wstrb<=s_axi_wstrb;end
    if(write_fire)begin
      aw_pending<=0;w_pending<=0;s_axi_bvalid<=1;s_axi_bresp<=0;
    end else if(s_axi_bvalid && s_axi_bready)s_axi_bvalid<=0;
    if(s_axi_arvalid && s_axi_arready)begin
      s_axi_rvalid<=1;s_axi_rdata<=read_word(s_axi_araddr);s_axi_rresp<=0;
    end else if(s_axi_rvalid && s_axi_rready)s_axi_rvalid<=0;
  end
 end

 always @(posedge s_axi_aclk) begin
  if(!s_axi_aresetn || initialize)begin
    for(integer i=0;i<11;i++)stage[i]<=0;
    pending_data<=0;active_data<=0;pending_seq<=0;adopted_seq<=0;
    result_seq<=0;result_frame<=0;completed_frames<=0;seen_frame<=0;
    pending_valid<=0;running<=0;stop_requested<=0;valid<=0;phase<=0;
    hold_error<=0;result_capture_edge<=0;
    result_u<=32'h20000000;result_v<=32'h20000000;result_w<=32'h20000000;
  end else begin
    // Same reset/start and clock as the original frame counter. No core CE gate.
    if(running)begin
      phase<=phase==4999?0:phase+1;
      if(hold_violation)hold_error<=1;
      if(core_valid && core_frame!=seen_frame)begin
        result_u<=du;result_v<=dv;result_w<=dw;
        result_frame<=core_frame;seen_frame<=core_frame;result_seq<=adopted_seq;valid<=1;
        result_capture_edge<=capture_edge;
      end
      if(phase==4999)begin
        completed_frames<=completed_frames+1;
        if(stop_requested)running<=0;
        else if(pending_valid)begin
          active_data<=pending_data;adopted_seq<=pending_seq;pending_valid<=0;
        end
      end
    end else phase<=0;
    if(write_fire)begin
      if(awaddr>=8'h40 && awaddr<=8'h68 && awaddr[1:0]==0)
        stage[(awaddr-8'h40)>>2]<=merge_bytes(stage[(awaddr-8'h40)>>2],wdata,wstrb);
      if(awaddr==8'h08)begin
        pending_data<=stage_data;pending_seq<=merge_bytes(0,wdata,wstrb);pending_valid<=1;
      end
      if(control_write)begin
        if(wdata[1] && !running && pending_valid)begin
          active_data<=pending_data;adopted_seq<=pending_seq;pending_valid<=0;running<=1;
        end
        if(wdata[2] && running)stop_requested<=1;
      end
    end
  end
 end
endmodule
