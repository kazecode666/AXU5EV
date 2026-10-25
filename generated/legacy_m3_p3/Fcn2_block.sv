
`timescale 1ns/1ps

module Fcn2_block
          import FOC_DUT_pkg::* ;
          (  input logic clk,
             input logic reset,
             input logic enb,
             input vector_of_signed_logic_64 Vector[0:2],
             output logic signed [63:0] Value);


  logic signed [63:0] Vector_1;
  logic signed [63:0] Vector_2;
  logic signed [127:0] Numerator_out1;
  logic signed [127:0] Numerator_out1_1;
  logic signed [63:0] Numerator_out1_2;
  logic Safe_Denominator_out1_timer;
  logic [199:0] delayMatch_reg;
  logic Safe_Denominator_out1_timer_1;
  logic signed [63:0] Safe_Denominator_out1_default;
  logic signed [63:0] Vector_0;
  logic signed [64:0] Sum_Times_add_cast;
  logic signed [64:0] Sum_Times_add_cast_1;
  logic signed [64:0] Sum_Times_add_temp;
  logic signed [63:0] Sum_Times_out1;
  logic signed [63:0] Sum_Times_out1_1;
  logic Denominator_Nonzero_out1;
  logic signed [63:0] Defined_Fallback_out1;
  logic signed [63:0] Safe_Denominator_out1;
  logic signed [63:0] Numerator_out1_3;
  logic signed [63:0] Safe_Denominator_out1_1;
  logic signed [63:0] Safe_Denominator_out1_zp;
  logic signed [63:0] Defined_Quotient_out1;


  assign Vector_1 = Vector[1];

  assign Vector_2 = Vector[2];

  assign Numerator_out1 = Vector_1 * Vector_2;
  always_ff @(posedge clk)
    begin : rd_1_process
      if (reset == 1'b1) begin
        Numerator_out1_1 <= 128'sh00000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          Numerator_out1_1 <= Numerator_out1;
        end
      end
    end

  assign Numerator_out1_2 = (((Numerator_out1_1[127] == 1'b0) && (Numerator_out1_1[126:103] != 24'b000000000000000000000000)) || ((Numerator_out1_1[127] == 1'b0) && (Numerator_out1_1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Numerator_out1_1[127] == 1'b1) && (Numerator_out1_1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(Numerator_out1_1[103:40]) + $signed({1'b0, Numerator_out1_1[39] & (Numerator_out1_1[40] | (|Numerator_out1_1[38:0]))})));

  assign Safe_Denominator_out1_timer = 1'b1;

  always_ff @(posedge clk)
    begin : delayMatch_process
      if (reset == 1'b1) begin
        delayMatch_reg <= '{default :1'b0};
      end
      else begin
        if (enb) begin
          delayMatch_reg[0] <= Safe_Denominator_out1_timer;
          delayMatch_reg[32'sd199:32'sd1] <= delayMatch_reg[32'sd198:32'sd0];
        end
      end
    end

  assign Safe_Denominator_out1_timer_1 = delayMatch_reg[199];

  assign Safe_Denominator_out1_default = 64'sh0000010000000000;

  assign Vector_0 = Vector[0];
  assign Sum_Times_add_cast = {Vector_0[63], Vector_0};
  assign Sum_Times_add_cast_1 = {Vector_1[63], Vector_1};
  assign Sum_Times_add_temp = Sum_Times_add_cast + Sum_Times_add_cast_1;
  assign Sum_Times_out1 = ((Sum_Times_add_temp[64] == 1'b0) && (Sum_Times_add_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Sum_Times_add_temp[64] == 1'b1) && (Sum_Times_add_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Sum_Times_add_temp[63:0])));
  always_ff @(posedge clk)
    begin : rd_0_process
      if (reset == 1'b1) begin
        Sum_Times_out1_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Sum_Times_out1_1 <= Sum_Times_out1;
        end
      end
    end

  assign Denominator_Nonzero_out1 = Sum_Times_out1_1 != 64'sh0000000000000000;
  assign Defined_Fallback_out1 = 64'sh0000010000000000;
  assign Safe_Denominator_out1 = (Denominator_Nonzero_out1 == 1'b0 ? Defined_Fallback_out1 :
              Sum_Times_out1_1);
  always_ff @(posedge clk)
    begin : rd_2_process
      if (reset == 1'b1) begin
        Numerator_out1_3 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Numerator_out1_3 <= Numerator_out1_2;
        end
      end
    end

  always_ff @(posedge clk)
    begin : rd_3_process
      if (reset == 1'b1) begin
        Safe_Denominator_out1_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Safe_Denominator_out1_1 <= Safe_Denominator_out1;
        end
      end
    end

  assign Safe_Denominator_out1_zp = (Safe_Denominator_out1_timer_1 == 1'b0 ? Safe_Denominator_out1_default :
              Safe_Denominator_out1_1);

  Defined_Quotient_block u_Defined_Quotient (.clk(clk),
                                             .reset(reset),
                                             .enb(enb),
                                             .dividend_in(Numerator_out1_3),
                                             .divisor_in(Safe_Denominator_out1_zp),
                                             .quotient(Defined_Quotient_out1)
                                             );
  assign Value = Defined_Quotient_out1;

endmodule   
