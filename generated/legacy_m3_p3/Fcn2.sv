
`timescale 1ns/1ps

module Fcn2
          import FOC_DUT_pkg::* ;
          (  input logic clk,
             input logic reset,
             input logic enb,
             input vector_of_signed_logic_64 Vector[0:2],
             output logic signed [63:0] Value);


  logic signed [63:0] Vector_2;
  logic signed [63:0] T2;
  logic signed [64:0] Combination_stage2_add_cast;
  logic signed [64:0] Combination_stage2_add_cast_1;
  logic signed [64:0] Combination_stage2_add_temp;
  logic signed [63:0] Combination_op_stage1;
  logic signed [63:0] Combination_op_stage1_1;
  logic signed [63:0] T1;
  logic signed [63:0] T1_1;
  logic signed [64:0] Combination_stage3_add_cast;
  logic signed [64:0] Combination_stage3_add_cast_1;
  logic signed [64:0] Combination_stage3_add_temp;
  logic signed [63:0] Combination_out1;
  logic signed [127:0] Quarter_cast;
  logic signed [63:0] Quarter_out1;


  assign Vector_2 = Vector[2];

  assign T2 = Vector[1];

  assign Combination_stage2_add_cast = {Vector_2[63], Vector_2};
  assign Combination_stage2_add_cast_1 = {T2[63], T2};
  assign Combination_stage2_add_temp = Combination_stage2_add_cast + Combination_stage2_add_cast_1;
  assign Combination_op_stage1 = ((Combination_stage2_add_temp[64] == 1'b0) && (Combination_stage2_add_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Combination_stage2_add_temp[64] == 1'b1) && (Combination_stage2_add_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Combination_stage2_add_temp[63:0])));

  always_ff @(posedge clk)
    begin : rd_0_process
      if (reset == 1'b1) begin
        Combination_op_stage1_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Combination_op_stage1_1 <= Combination_op_stage1;
        end
      end
    end

  assign T1 = Vector[0];
  always_ff @(posedge clk)
    begin : rd_1_process
      if (reset == 1'b1) begin
        T1_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          T1_1 <= T1;
        end
      end
    end

  assign Combination_stage3_add_cast = {Combination_op_stage1_1[63], Combination_op_stage1_1};
  assign Combination_stage3_add_cast_1 = {T1_1[63], T1_1};
  assign Combination_stage3_add_temp = Combination_stage3_add_cast + Combination_stage3_add_cast_1;
  assign Combination_out1 = ((Combination_stage3_add_temp[64] == 1'b0) && (Combination_stage3_add_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Combination_stage3_add_temp[64] == 1'b1) && (Combination_stage3_add_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Combination_stage3_add_temp[63:0])));
  assign Quarter_cast = {{26{Combination_out1[63]}}, {Combination_out1, 38'b00000000000000000000000000000000000000}};
  assign Quarter_out1 = (((Quarter_cast[127] == 1'b0) && (Quarter_cast[126:103] != 24'b000000000000000000000000)) || ((Quarter_cast[127] == 1'b0) && (Quarter_cast[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Quarter_cast[127] == 1'b1) && (Quarter_cast[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(Quarter_cast[103:40]) + $signed({1'b0, Quarter_cast[39] & (Quarter_cast[40] | (|Quarter_cast[38:0]))})));
  assign Value = Quarter_out1;

endmodule   
