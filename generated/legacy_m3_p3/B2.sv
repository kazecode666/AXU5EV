
`timescale 1ns/1ps

module B2
          import FOC_DUT_pkg::* ;
          (  input logic clk,
             input logic reset,
             input logic enb,
             input vector_of_signed_logic_64 Vector[0:1],
             output logic signed [63:0] Value);


  logic signed [63:0] Vector_0;
  logic signed [127:0] Alpha0866_out1;
  logic signed [63:0] Alpha0866_out1_1;
  logic signed [63:0] Alpha0866_out1_2;
  logic signed [63:0] Vector_1;
  logic signed [127:0] Beta05_cast;
  logic signed [63:0] Beta05_out1;
  logic signed [63:0] Beta05_out1_1;
  logic signed [64:0] Projection_cast;
  logic signed [64:0] Projection_cast_1;
  logic signed [63:0] Projection_sub_cast;
  logic signed [64:0] Projection_sub_cast_1;
  logic signed [64:0] Projection_sub_cast_2;
  logic signed [64:0] Projection_sub_temp;
  logic signed [63:0] Projection_out1;


  assign Vector_0 = Vector[0];
  assign Alpha0866_out1 = 64'sh000000DDB22D0E56 * Vector_0;
  assign Alpha0866_out1_1 = (((Alpha0866_out1[127] == 1'b0) && (Alpha0866_out1[126:103] != 24'b000000000000000000000000)) || ((Alpha0866_out1[127] == 1'b0) && (Alpha0866_out1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Alpha0866_out1[127] == 1'b1) && (Alpha0866_out1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(Alpha0866_out1[103:40]) + $signed({1'b0, Alpha0866_out1[39] & (Alpha0866_out1[40] | (|Alpha0866_out1[38:0]))})));

  always_ff @(posedge clk)
    begin : rd_0_process
      if (reset == 1'b1) begin
        Alpha0866_out1_2 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Alpha0866_out1_2 <= Alpha0866_out1_1;
        end
      end
    end

  assign Vector_1 = Vector[1];

  assign Beta05_cast = {{25{Vector_1[63]}}, {Vector_1, 39'b000000000000000000000000000000000000000}};
  assign Beta05_out1 = (((Beta05_cast[127] == 1'b0) && (Beta05_cast[126:103] != 24'b000000000000000000000000)) || ((Beta05_cast[127] == 1'b0) && (Beta05_cast[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Beta05_cast[127] == 1'b1) && (Beta05_cast[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(Beta05_cast[103:40]) + $signed({1'b0, Beta05_cast[39] & (Beta05_cast[40] | (|Beta05_cast[38:0]))})));
  always_ff @(posedge clk)
    begin : rd_1_process
      if (reset == 1'b1) begin
        Beta05_out1_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Beta05_out1_1 <= Beta05_out1;
        end
      end
    end

  assign Projection_cast = {Alpha0866_out1_2[63], Alpha0866_out1_2};
  assign Projection_cast_1 =  - (Projection_cast);
  assign Projection_sub_cast = ((Projection_cast_1[64] == 1'b0) && (Projection_cast_1[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Projection_cast_1[64] == 1'b1) && (Projection_cast_1[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Projection_cast_1[63:0])));
  assign Projection_sub_cast_1 = {Projection_sub_cast[63], Projection_sub_cast};
  assign Projection_sub_cast_2 = {Beta05_out1_1[63], Beta05_out1_1};
  assign Projection_sub_temp = Projection_sub_cast_1 - Projection_sub_cast_2;
  assign Projection_out1 = ((Projection_sub_temp[64] == 1'b0) && (Projection_sub_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Projection_sub_temp[64] == 1'b1) && (Projection_sub_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Projection_sub_temp[63:0])));
  assign Value = Projection_out1;

endmodule   
