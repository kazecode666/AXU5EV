`timescale 1ns/1ps
module axu5ev_foc_frame_top(
 input logic clk, global_reset, timing_restart,
 input logic signed [31:0] ia,ib,ic,iq_ref,id_ref,
 input logic signed [39:0] theta_e,omega_e,
 input logic integrator_clear,
 input logic [31:0] vdc,
 output logic [31:0] duty_u,duty_v,duty_w,frame_id,
 output logic [12:0] capture_edge,
 output logic result_valid,hold_violation
);
 logic [12:0] phase;
 logic signed [31:0] ia_h,ib_h,ic_h,iq_h,id_h;
 logic signed [39:0] theta_h,omega_h;
 logic pi_h;
 logic [31:0] vdc_h,du,dv,dw;
 logic ce_unused;
 logic [272:0] previous_inputs;
 wire [272:0] held_inputs={ia_h,ib_h,ic_h,theta_h,omega_h,iq_h,id_h,pi_h,vdc_h};
 // 首有效边沿前锁存；314拍之后仍运行完整5000拍。
 always @(negedge clk) begin
  if(global_reset || timing_restart) begin
   ia_h<=0;ib_h<=0;ic_h<=0;iq_h<=0;id_h<=0;theta_h<=0;omega_h<=0;pi_h<=1;vdc_h<=0;
  end else if(phase==0) begin
   ia_h<=ia;ib_h<=ib;ic_h<=ic;iq_h<=iq_ref;id_h<=id_ref;
   theta_h<=theta_e;omega_h<=omega_e;pi_h<=integrator_clear;vdc_h<=vdc;
  end
 end
 always @(posedge clk) begin
  if(global_reset || timing_restart) begin
   phase<=0;frame_id<=0;capture_edge<=0;result_valid<=0;hold_violation<=0;previous_inputs<=0;
   duty_u<=32'd536870912;duty_v<=32'd536870912;duty_w<=32'd536870912;
  end else begin
   phase <= phase==4999 ? 0 : phase+1;
   if(phase!=0 && held_inputs!==previous_inputs) hold_violation<=1;
   previous_inputs<=held_inputs;
   // pre-edge315看到核心post-edge314的三相值，同一边沿捕获。
   if(phase==314) begin
    duty_u<=du;duty_v<=dv;duty_w<=dw;frame_id<=frame_id+1;
    capture_edge<=phase+1;result_valid<=1;
   end
  end
 end
 FOC_DUT core(.clk(clk),.reset(global_reset),.reset_FOC_DUT_tc(timing_restart),.clk_enable(1'b1),
  .ia(ia_h),.ib(ib_h),.ic(ic_h),.theta_e(theta_h),.omega_e(omega_h),
  .iq_ref(iq_h),.id_ref(id_h),.PI_Reset_EN(pi_h),.Vdc_V(vdc_h),
  .ce_out(ce_unused),.duty_u_cmd(du),.duty_v_cmd(dv),.duty_w_cmd(dw));
endmodule
