`timescale 1ns/1ps
// Directed adapter check; reuses the accepted 17-row source/gm bit oracle.
module ax02b_frame_contract_tb;
 logic clk=0,global_reset=1,timing_restart=0;
 logic signed [31:0] ia,ib,ic,iq_ref,id_ref;
 logic signed [39:0] theta_e,omega_e;
 logic integrator_clear;
 logic [31:0] vdc;
 wire [31:0] duty_u,duty_v,duty_w,frame_id;
 wire [12:0] capture_edge;
 wire result_valid,hold_violation;
 axu5ev_foc_frame_top dut(.*);
 always #10 clk=~clk;
 logic [656:0] vectors[0:16];
 logic [31:0] sid,eu,ev,ew;
 logic [63:0] xd,xq,ad,aq,save_xd,save_xq,save_ad,save_aq;
 logic [272:0] held;
 logic [95:0] last_duty;
 integer frames=0,checks=0;
 string path;
 task automatic require(input bit condition,input string message);
  checks++;
  if(!condition)$fatal(1,"AX02B_FRAME_FAIL %s",message);
 endtask
 task automatic load(input integer row);
  {sid,ia,ib,ic,theta_e,omega_e,iq_ref,id_ref,integrator_clear,vdc,eu,ev,ew,xd,xq,ad,aq}=vectors[row];
 endtask
 task automatic frame(input integer row);
  integer edge_no;logic [31:0] prior_id;
  load(row);prior_id=frame_id;last_duty={duty_u,duty_v,duty_w};
  for(edge_no=1;edge_no<=5000;edge_no++)begin
   @(posedge clk);#1;
   if(edge_no==1)begin
    held={dut.ia_h,dut.ib_h,dut.ic_h,dut.theta_h,dut.omega_h,dut.iq_h,dut.id_h,dut.pi_h,dut.vdc_h};
    require(held==={ia,ib,ic,theta_e,omega_e,iq_ref,id_ref,integrator_clear,vdc},"all nine fields captured");
   end
   require(dut.held_inputs===held && !hold_violation,"5000-edge common input hold");
   require(dut.core.clk_enable===1'b1,"core CE must stay enabled after result");
   if(edge_no==314)require({dut.du,dut.dv,dut.dw}==={eu,ev,ew},"core post314 bits");
   if(edge_no==315)begin
    require({duty_u,duty_v,duty_w}==={eu,ev,ew},"edge315 duty bits");
    require(frame_id==prior_id+1 && result_valid && capture_edge==315,"one common result capture");
    last_duty={duty_u,duty_v,duty_w};frames++;
   end else begin
    require(frame_id==prior_id+(edge_no>315),"no early/duplicate frame id");
    require({duty_u,duty_v,duty_w}===last_duty,"output held between captures");
   end
   if(edge_no>315)require(result_valid,"result_valid is persistent, not a pulse");
   #1;
   // Disturb every external field after the latch: none may enter this frame.
   ia=~ia;ib=~ib;ic=~ic;theta_e=~theta_e;omega_e=~omega_e;
   iq_ref=~iq_ref;id_ref=~id_ref;integrator_clear=~integrator_clear;vdc=~vdc;
  end
 endtask
 task automatic reset_check;
  require({duty_u,duty_v,duty_w}==={3{32'h20000000}} && !result_valid && frame_id==0,"reset interface is 0.5/invalid");
 endtask
 initial begin
  if(!$value$plusargs("vectors=%s",path))$fatal(1,"missing vectors");
  $readmemh(path,vectors);
  repeat(2)begin @(posedge clk);#1;reset_check();end
  #1;global_reset=0;
  for(integer row=0;row<17;row++)frame(row);
  // Known zero-state replay then restart timing in the middle of a live frame.
  global_reset=1;repeat(2)@(posedge clk);#1;reset_check();#1;global_reset=0;
  frame(0);frame(1);frame(2);load(3);
  repeat(100)@(posedge clk);#2;
  // Observe storage, not the combinational AW bypass selected by timing phase.
  save_xd=dut.core.u_Id.x_d_z_bypass_reg;save_xq=dut.core.u_Iq.x_q_z_bypass_reg;
  save_ad=dut.core.u_dq_voltage_limiter.Unit_Delay_bypass_reg;
  save_aq=dut.core.u_dq_voltage_limiter.Unit_Delay1_bypass_reg;
  require((save_xd|save_xq)!=0,"restart probe has live PI state");
  timing_restart=1;@(posedge clk);#1;
  reset_check();
  // This is the first restart edge, not a promise of state-preserving resume:
  // restart also resets held inputs (pi_h=1) and rephases state-enable muxes.
  require(dut.core.u_Id.x_d_z_bypass_reg===save_xd && dut.core.u_Iq.x_q_z_bypass_reg===save_xq &&
    dut.core.u_dq_voltage_limiter.Unit_Delay_bypass_reg===save_ad &&
    dut.core.u_dq_voltage_limiter.Unit_Delay1_bypass_reg===save_aq,"timing_restart does not clear PI/AW storage");
  #1;timing_restart=0;global_reset=1;
  repeat(2)@(posedge clk);#1;reset_check();
  require(dut.core.u_Id.x_d_z_out1==0 && dut.core.u_Iq.x_q_z_out1==0 &&
    dut.core.dq_voltage_limiter_du_d_z==0 && dut.core.dq_voltage_limiter_du_q_z==0,"global reset clears PI/AW");
  #1;global_reset=0;frame(0);
  require(frames==21 && checks>100000,"nonzero complete comparison count");
  $display("AX02B_FRAME_PASS frames=%0d checks=%0d hold_violation=0 core_phase=314 capture_edge=315",frames,checks);
  $finish;
 end
 initial begin #10000000;$fatal(1,"frame contract timeout");end
endmodule
