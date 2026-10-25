`timescale 1ns/1ps
// 仅仿真：50MHz连续时钟与两拍整体复位；不作为板级时钟电路。
module axu5ev_foc_xsi_top(
 input logic signed [31:0] ia,ib,ic,iq_ref,id_ref,
 input logic signed [39:0] theta_e,omega_e,
 input logic integrator_clear,
 input logic [31:0] vdc,
 output wire [31:0] duty_u,duty_v,duty_w,frame_id,
 output wire [12:0] capture_edge,
 output wire result_valid,hold_violation
);
 logic clk=0,global_reset=1;
 always #10 clk=~clk;
 initial begin #35; global_reset=0; end
 axu5ev_foc_frame_top adapter(.clk(clk),.global_reset(global_reset),.timing_restart(1'b0),
  .ia(ia),.ib(ib),.ic(ic),.iq_ref(iq_ref),.id_ref(id_ref),.theta_e(theta_e),.omega_e(omega_e),
  .integrator_clear(integrator_clear),.vdc(vdc),.duty_u(duty_u),.duty_v(duty_v),.duty_w(duty_w),
  .frame_id(frame_id),.capture_edge(capture_edge),.result_valid(result_valid),.hold_violation(hold_violation));
endmodule
