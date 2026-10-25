
`timescale 1ns/1ps

module SVPWMG
          import FOC_DUT_pkg::* ;
          (  input logic clk,
             input logic reset,
             input logic enb,
             input logic signed [63:0] Valpha,
             input logic signed [63:0] Vbeta,
             input logic [31:0] Vdc_V,
             output logic signed [63:0] duty_u_cmd,
             output logic signed [63:0] duty_v_cmd,
             output logic signed [63:0] duty_w_cmd);


  logic [7:0] Sector_Caculate_N;
  logic signed [63:0] XYZ_Calculate_X;
  logic signed [63:0] XYZ_Calculate_Y;
  logic signed [63:0] XYZ_Calculate_Z;
  logic signed [63:0] T1T2_Calculate_T1;
  logic signed [63:0] T1T2_Calculate_T2;
  logic signed [63:0] Duty_Calculate_Duty_U;
  logic signed [63:0] Duty_Calculate_Duty_V;
  logic signed [63:0] Duty_Calculate_Duty_W;


  Sector_Caculate u_Sector_Caculate (.clk(clk),
                                     .reset(reset),
                                     .enb(enb),
                                     .Ualpha(Valpha),
                                     .Ubeta(Vbeta),
                                     .N_1(Sector_Caculate_N)
                                     );
  XYZ_Calculate u_XYZ_Calculate (.clk(clk),
                                 .reset(reset),
                                 .enb(enb),
                                 .Ualpha(Valpha),
                                 .Ubeta(Vbeta),
                                 .Udc(Vdc_V),
                                 .X(XYZ_Calculate_X),
                                 .Y(XYZ_Calculate_Y),
                                 .Z(XYZ_Calculate_Z)
                                 );
  T1T2_Calculate u_T1T2_Calculate (.clk(clk),
                                   .reset(reset),
                                   .enb(enb),
                                   .N(Sector_Caculate_N),
                                   .X(XYZ_Calculate_X),
                                   .Y(XYZ_Calculate_Y),
                                   .Z(XYZ_Calculate_Z),
                                   .T1(T1T2_Calculate_T1),
                                   .T2(T1T2_Calculate_T2)
                                   );
  Duty_Calculate u_Duty_Calculate (.clk(clk),
                                   .reset(reset),
                                   .enb(enb),
                                   .N(Sector_Caculate_N),
                                   .T1(T1T2_Calculate_T1),
                                   .T2(T1T2_Calculate_T2),
                                   .Duty_U(Duty_Calculate_Duty_U),
                                   .Duty_V(Duty_Calculate_Duty_V),
                                   .Duty_W(Duty_Calculate_Duty_W)
                                   );
  assign duty_u_cmd = Duty_Calculate_Duty_U;

  assign duty_v_cmd = Duty_Calculate_Duty_V;

  assign duty_w_cmd = Duty_Calculate_Duty_W;

endmodule   
