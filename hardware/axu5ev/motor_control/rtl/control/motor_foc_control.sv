`timescale 1ns/1ps
// Connection/scheduling only. Arithmetic remains in the accepted generated
// FOC and the model-generated duty mapper. All enables run for full frames.
module motor_foc_control(
 input wire clk,rst,
 input wire sample_event,input wire [31:0] sample_id,input wire [63:0] sample_tick,
 input wire feedback_event,feedback_valid,
 input wire [31:0] feedback_id,input wire [63:0] feedback_tick,
 input wire signed [31:0] ia,ib,ic,input wire signed [39:0] theta_e,
 input wire signed [31:0] ref_id,ref_iq,input wire signed [39:0] ref_omega,
 input wire [31:0] ref_vdc,input wire ref_pi_reset,input wire [31:0] ref_version,
 input wire ref_arm,invalidate,
 input wire auto_ready,auto_online,input wire [31:0] auto_applied_seq,
 output reg auto_valid,output reg [38:0] auto_compare,output reg [31:0] auto_seq,
 output wire auto_inhibit,output reg status_strobe,output reg [1023:0] debug_o
);
 reg tracking,core_started;
 reg [12:0] sample_age;
 reg [31:0] frame_sample_id;
 reg [63:0] frame_sample_tick;
 reg feedback_seen,feedback_good,frame_cancelled;
 reg signed [31:0] feedback_ia,feedback_ib,feedback_ic;
 reg signed [39:0] feedback_theta;
 reg [31:0] capture_id,capture_ref_version;
 reg [63:0] capture_tick;
 reg capture_valid;
 reg signed [31:0] foc_ia,foc_ib,foc_ic,foc_id,foc_iq;
 reg signed [39:0] foc_theta,foc_omega;
 reg [31:0] foc_vdc;
 reg foc_pi;
 wire [31:0] core_du,core_dv,core_dw,core_frame_id;
 wire [12:0] core_capture_edge;
 wire core_result_valid,hold_violation;
 wire core_reset=rst || !core_started;
 axu5ev_foc_frame_top foc(.clk(clk),.global_reset(core_reset),.timing_restart(1'b0),
  .ia(foc_ia),.ib(foc_ib),.ic(foc_ic),.iq_ref(foc_iq),.id_ref(foc_id),
  .theta_e(foc_theta),.omega_e(foc_omega),.integrator_clear(foc_pi),.vdc(foc_vdc),
  .duty_u(core_du),.duty_v(core_dv),.duty_w(core_dw),.frame_id(core_frame_id),
  .capture_edge(core_capture_edge),.result_valid(core_result_valid),.hold_violation(hold_violation));
 reg [31:0] result_frame_seen;
 wire foc_result_pulse=core_result_valid && core_frame_id!=result_frame_seen;
 reg map_strobe;
 wire [15:0] mapped_u,mapped_v,mapped_w;
 wire mapped_strobe;
 Duty_To_Compare duty_mapper(.clk(clk),.reset(rst),.clk_enable(1'b1),
  .sample_strobe(map_strobe),.duty_u(core_du),.duty_v(core_dv),.duty_w(core_dw),
  .compare_u(mapped_u),.compare_v(mapped_v),.compare_w(mapped_w),
  .result_strobe(mapped_strobe),.ce_out());
 reg [31:0] duty_u,duty_v,duty_w;
 reg [12:0] compare_u,compare_v,compare_w;
 reg run_permitted,waiting_applied,frame_late;
 reg seen_online,lock_blocked,rearm_seen;
 reg [31:0] blocked_version;
 reg [31:0] offer_count,late_count,invalid_count,result_count;
 wire usable=feedback_seen && feedback_good && ref_arm && auto_online &&
             !frame_cancelled && !lock_blocked && !invalidate &&
             ref_vdc>=32'd201326592 && ref_vdc<=32'd1006632960;
 // A held arm never revives a cancelled command after clock loss. Re-arm is
 // an explicit new reference version or an observed arm-low/arm-high cycle.
 assign auto_inhibit=!run_permitted || !ref_arm || invalidate || lock_blocked || !auto_online;
 always @(posedge clk) begin
  if(rst) begin
   tracking<=0;core_started<=0;sample_age<=0;frame_sample_id<=0;frame_sample_tick<=0;
   feedback_seen<=0;feedback_good<=0;frame_cancelled<=0;
   feedback_ia<=0;feedback_ib<=0;feedback_ic<=0;feedback_theta<=0;
   capture_id<=0;capture_tick<=0;capture_ref_version<=0;capture_valid<=0;
   foc_ia<=0;foc_ib<=0;foc_ic<=0;foc_id<=0;foc_iq<=0;foc_theta<=0;foc_omega<=0;
   foc_vdc<=32'd805306368;foc_pi<=1;
   result_frame_seen<=0;map_strobe<=0;duty_u<=0;duty_v<=0;duty_w<=0;
   compare_u<=0;compare_v<=0;compare_w<=0;
   auto_valid<=0;auto_compare<=0;auto_seq<=0;run_permitted<=0;waiting_applied<=0;
   frame_late<=0;seen_online<=0;lock_blocked<=0;rearm_seen<=0;blocked_version<=0;
   offer_count<=0;late_count<=0;invalid_count<=0;result_count<=0;status_strobe<=0;
  end else begin
   map_strobe<=0;status_strobe<=0;
   if(sample_event) begin
    tracking<=1;sample_age<=0;frame_sample_id<=sample_id;frame_sample_tick<=sample_tick;
    feedback_seen<=0;feedback_good<=0;frame_cancelled<=0;frame_late<=0;
   end else if(tracking && sample_age<4999) sample_age<=sample_age+1'b1;
   if(!sample_event && feedback_event && feedback_id==frame_sample_id && feedback_tick==frame_sample_tick) begin
    feedback_seen<=1;feedback_good<=feedback_valid;
    feedback_ia<=ia;feedback_ib<=ib;feedback_ic<=ic;feedback_theta<=theta_e;
    if(!feedback_valid) begin run_permitted<=0;auto_valid<=0;waiting_applied<=0;frame_cancelled<=1;end
   end
   // P127 loads the nine fields. The original wrapper captures on the next
   // falling edge and consumes its first core edge at P128. No later resets.
   if(tracking && sample_age==126) begin
    core_started<=1;capture_id<=frame_sample_id;capture_tick<=frame_sample_tick;
    capture_ref_version<=ref_version;capture_valid<=usable;
    foc_ia<=usable ? feedback_ia : 0;foc_ib<=usable ? feedback_ib : 0;foc_ic<=usable ? feedback_ic : 0;
    foc_id<=usable ? ref_id : 0;foc_iq<=usable ? ref_iq : 0;
    foc_theta<=usable ? feedback_theta : 0;foc_omega<=usable ? ref_omega : 0;
    foc_vdc<=usable ? ref_vdc : 32'd805306368;
    foc_pi<=!usable || ref_pi_reset;
    if(!usable) begin
     invalid_count<=invalid_count+1'b1;run_permitted<=0;auto_valid<=0;waiting_applied<=0;
    end
   end
   if(foc_result_pulse) begin
    result_frame_seen<=core_frame_id;map_strobe<=1;
    duty_u<=core_du;duty_v<=core_dv;duty_w<=core_dw;
   end
   if(mapped_strobe) begin
    result_count<=result_count+1'b1;
    compare_u<=mapped_u[12:0];compare_v<=mapped_v[12:0];compare_w<=mapped_w[12:0];
    if(capture_valid && !frame_cancelled && ref_arm && !lock_blocked && !invalidate && auto_online) begin
     if(sample_age<2399) begin
      auto_compare<={mapped_w[12:0],mapped_v[12:0],mapped_u[12:0]};
      auto_seq<=capture_id;auto_valid<=1;run_permitted<=1;
     end else begin
      auto_valid<=0;run_permitted<=0;frame_late<=1;late_count<=late_count+1'b1;
     end
    end else begin auto_valid<=0;run_permitted<=0;end
   end
   if(auto_valid && auto_ready && !auto_inhibit) begin
    auto_valid<=0;waiting_applied<=1;offer_count<=offer_count+1'b1;
   end
   // Only the sample+50us valley is acceptable. The acknowledgement crosses
   // back through the existing related-clock handshake, hence the four clocks.
   if(waiting_applied && auto_applied_seq==capture_id) begin
    waiting_applied<=0;
    if(sample_age<2499 || sample_age>2503) begin
     run_permitted<=0;frame_late<=1;late_count<=late_count+1'b1;
    end
   end
   if(tracking && sample_age==2399 && auto_valid && !auto_ready) begin
    auto_valid<=0;run_permitted<=0;waiting_applied<=0;frame_late<=1;late_count<=late_count+1'b1;
   end
   if(tracking && sample_age==2503 && waiting_applied && auto_applied_seq!=capture_id) begin
    auto_valid<=0;run_permitted<=0;waiting_applied<=0;frame_late<=1;late_count<=late_count+1'b1;
   end
   if(tracking && sample_age==2507) status_strobe<=1;
   if(auto_online) seen_online<=1;
   if(!ref_arm) begin
    rearm_seen<=1;run_permitted<=0;auto_valid<=0;waiting_applied<=0;
    if(tracking && sample_age>126 && !sample_event) frame_cancelled<=1;
   end
   if(lock_blocked && auto_online && ref_arm && (ref_version!=blocked_version || rearm_seen)) begin
    lock_blocked<=0;rearm_seen<=0;
   end
   if(seen_online && !auto_online && !lock_blocked) begin
    lock_blocked<=1;blocked_version<=ref_version;rearm_seen<=0;
    run_permitted<=0;auto_valid<=0;waiting_applied<=0;
    if(!sample_event) frame_cancelled<=1;
   end
   if(invalidate || hold_violation) begin
    run_permitted<=0;auto_valid<=0;waiting_applied<=0;
    if(!sample_event || hold_violation) frame_cancelled<=1;
   end
  end
 end
 always @* begin
  debug_o=0;
  debug_o[0*32+:32]={24'd0,foc_pi,frame_late,lock_blocked,auto_inhibit,auto_valid,hold_violation,capture_valid,core_started};
  debug_o[1*32+:32]=capture_id;debug_o[2*32+:64]=capture_tick;
  debug_o[4*32+:32]=capture_ref_version;
  debug_o[5*32+:32]=foc_ia;debug_o[6*32+:32]=foc_ib;debug_o[7*32+:32]=foc_ic;
  debug_o[8*32+:32]=foc_id;debug_o[9*32+:32]=foc_iq;
  debug_o[10*32+:64]={{24{foc_theta[39]}},foc_theta};
  debug_o[12*32+:64]={{24{foc_omega[39]}},foc_omega};
  debug_o[14*32+:32]=foc_vdc;debug_o[15*32+:32]={31'd0,foc_pi};
  debug_o[16*32+:32]=duty_u;debug_o[17*32+:32]=duty_v;debug_o[18*32+:32]=duty_w;
  debug_o[19*32+:32]={19'd0,compare_u};debug_o[20*32+:32]={19'd0,compare_v};debug_o[21*32+:32]={19'd0,compare_w};
  debug_o[22*32+:32]=auto_seq;debug_o[23*32+:32]=auto_applied_seq;
  debug_o[24*32+:32]=offer_count;debug_o[25*32+:32]=late_count;debug_o[26*32+:32]=invalid_count;
  debug_o[27*32+:32]=core_frame_id;debug_o[28*32+:32]={19'd0,core_capture_edge};
  debug_o[29*32+:64]=capture_tick+64'd2500;debug_o[31*32+:32]=result_count;
 end
endmodule
