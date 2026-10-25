
`timescale 1ns/1ps

module Sector_Caculate
          import FOC_DUT_pkg::* ;
          (  input logic clk,
             input logic reset,
             input logic enb,
             input logic signed [63:0] Ualpha,
             input logic signed [63:0] Ubeta,
             output logic [7:0] N_1);


  vector_of_signed_logic_64 Mux_out1 [0:1];
  logic signed [63:0] B0_Value;
  logic switch_compare_1;
  logic [7:0] Constant1_out1;
  logic [7:0] Constant_out1;
  logic [7:0] Switch_out1;
  logic [7:0] Switch_out1_1;
  logic signed [63:0] B1_Value;
  logic switch_compare_1_1;
  logic [7:0] Switch1_out1;
  logic signed [63:0] B2_Value;
  logic switch_compare_1_2;
  logic [7:0] Switch2_out1;
  vector_of_unsigned_logic_8 Mux1_out1 [0:2];
  logic [7:0] N_Value;


  assign Mux_out1[0] = Ualpha;
  assign Mux_out1[1] = Ubeta;
  B0 u_B0 (.Vector(Mux_out1),
           .Value(B0_Value)
           );
  assign switch_compare_1 = B0_Value > 64'sh0000000000000000;

  assign Constant1_out1 = 8'b00000000;
  assign Constant_out1 = 8'b00000001;
  assign Switch_out1 = (switch_compare_1 == 1'b0 ? Constant1_out1 :
              Constant_out1);
  always_ff @(posedge clk)
    begin : rd_0_process
      if (reset == 1'b1) begin
        Switch_out1_1 <= 8'b00000000;
      end
      else begin
        if (enb) begin
          Switch_out1_1 <= Switch_out1;
        end
      end
    end

  B1 u_B1 (.clk(clk),
           .reset(reset),
           .enb(enb),
           .Vector(Mux_out1),
           .Value(B1_Value)
           );
  assign switch_compare_1_1 = B1_Value >= 64'sh0000000000000000;

  assign Switch1_out1 = (switch_compare_1_1 == 1'b0 ? Constant1_out1 :
              Constant_out1);
  B2 u_B2 (.clk(clk),
           .reset(reset),
           .enb(enb),
           .Vector(Mux_out1),
           .Value(B2_Value)
           );
  assign switch_compare_1_2 = B2_Value > 64'sh0000000000000000;

  assign Switch2_out1 = (switch_compare_1_2 == 1'b0 ? Constant1_out1 :
              Constant_out1);
  assign Mux1_out1[0] = Switch_out1_1;
  assign Mux1_out1[1] = Switch1_out1;
  assign Mux1_out1[2] = Switch2_out1;
  N u_N (.clk(clk),
         .reset(reset),
         .enb(enb),
         .Vector(Mux1_out1),
         .Value(N_Value)
         );
  assign N_1 = N_Value;

endmodule   
