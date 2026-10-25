
`timescale 1ns/1ps

module Fcn_block
          import FOC_DUT_pkg::* ;
          (  input logic clk,
             input logic reset,
             input logic enb,
             input vector_of_signed_logic_64 Vector[0:2],
             output logic signed [63:0] Value);


  logic signed [63:0] Vector_2;
  logic signed [63:0] Vector_1;
  logic signed [64:0] Combination_stage2_sub_cast;
  logic signed [64:0] Combination_stage2_sub_cast_1;
  logic signed [64:0] Combination_stage2_sub_temp;
  logic signed [63:0] Combination_op_stage1;
  logic signed [63:0] Combination_op_stage1_1;
  logic signed [63:0] Vector_0;
  logic signed [63:0] Vector_0_1;
  logic signed [64:0] Combination_stage3_sub_cast;
  logic signed [64:0] Combination_stage3_sub_cast_1;
  logic signed [64:0] Combination_stage3_sub_temp;
  logic signed [63:0] Combination_out1;


  assign Vector_2 = Vector[2];

  assign Vector_1 = Vector[1];

  assign Combination_stage2_sub_cast = {Vector_2[63], Vector_2};
  assign Combination_stage2_sub_cast_1 = {Vector_1[63], Vector_1};
  assign Combination_stage2_sub_temp = Combination_stage2_sub_cast - Combination_stage2_sub_cast_1;
  assign Combination_op_stage1 = ((Combination_stage2_sub_temp[64] == 1'b0) && (Combination_stage2_sub_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Combination_stage2_sub_temp[64] == 1'b1) && (Combination_stage2_sub_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Combination_stage2_sub_temp[63:0])));

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

  assign Vector_0 = Vector[0];
  always_ff @(posedge clk)
    begin : rd_1_process
      if (reset == 1'b1) begin
        Vector_0_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Vector_0_1 <= Vector_0;
        end
      end
    end

  assign Combination_stage3_sub_cast = {Combination_op_stage1_1[63], Combination_op_stage1_1};
  assign Combination_stage3_sub_cast_1 = {Vector_0_1[63], Vector_0_1};
  assign Combination_stage3_sub_temp = Combination_stage3_sub_cast - Combination_stage3_sub_cast_1;
  assign Combination_out1 = ((Combination_stage3_sub_temp[64] == 1'b0) && (Combination_stage3_sub_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Combination_stage3_sub_temp[64] == 1'b1) && (Combination_stage3_sub_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Combination_stage3_sub_temp[63:0])));
  assign Value = Combination_out1;

endmodule   
