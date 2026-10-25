
`timescale 1ns/1ps

module XYZ_Calculate
          import FOC_DUT_pkg::* ;
          (  input logic clk,
             input logic reset,
             input logic enb,
             input logic signed [63:0] Ualpha,
             input logic signed [63:0] Ubeta,
             input logic [31:0] Udc,
             output logic signed [63:0] X,
             output logic signed [63:0] Y,
             output logic signed [63:0] Z);


  logic signed [127:0] Gain1_out1;
  logic signed [63:0] Gain1_out1_1;
  logic signed [63:0] Gain1_out1_2;
  logic signed [63:0] Constant1_out1;
  logic signed [63:0] Math_Function_out1;
  logic signed [63:0] Math_Function_out1_1;
  logic signed [127:0] Product_out1;
  logic signed [63:0] Product_out1_1;
  vector_of_signed_logic_64 rd_2_reg [0:121];
  logic signed [63:0] Product_out1_2;
  logic signed [127:0] X_1;
  logic signed [127:0] Gain2_out1;
  logic signed [63:0] Gain2_out1_1;
  logic signed [63:0] Gain2_out1_2;
  logic signed [127:0] Gain_out1;
  logic signed [63:0] Gain_out1_1;
  logic signed [63:0] Gain_out1_2;
  logic signed [64:0] Add_add_cast;
  logic signed [64:0] Add_add_cast_1;
  logic signed [64:0] Add_add_temp;
  logic signed [63:0] Add_out1;
  logic signed [127:0] Y_1;
  logic signed [127:0] Y_2;
  logic signed [64:0] Add1_sub_cast;
  logic signed [64:0] Add1_sub_cast_1;
  logic signed [64:0] Add1_sub_temp;
  logic signed [63:0] Add1_out1;
  logic signed [127:0] Z_1;
  logic signed [127:0] Z_2;


  assign Gain1_out1 = 64'sh000001BB6AE7D567 * Ubeta;
  assign Gain1_out1_1 = (((Gain1_out1[127] == 1'b0) && (Gain1_out1[126:103] != 24'b000000000000000000000000)) || ((Gain1_out1[127] == 1'b0) && (Gain1_out1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Gain1_out1[127] == 1'b1) && (Gain1_out1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(Gain1_out1[103:40]) + $signed({1'b0, Gain1_out1[39] & (Gain1_out1[40] | (|Gain1_out1[38:0]))})));

  always_ff @(posedge clk)
    begin : rd_0_process
      if (reset == 1'b1) begin
        Gain1_out1_2 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Gain1_out1_2 <= Gain1_out1_1;
        end
      end
    end

  assign Constant1_out1 = 64'sh00000000068DB8BB;
  reciprocal u_reciprocal (.clk(clk),
                           .reset(reset),
                           .enb(enb),
                           .recip_in(Udc),
                           .recip_out(Math_Function_out1)
                           );
  always_ff @(posedge clk)
    begin : rd_1_process
      if (reset == 1'b1) begin
        Math_Function_out1_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Math_Function_out1_1 <= Math_Function_out1;
        end
      end
    end

  assign Product_out1 = Constant1_out1 * Math_Function_out1_1;
  assign Product_out1_1 = (((Product_out1[127] == 1'b0) && (Product_out1[126:103] != 24'b000000000000000000000000)) || ((Product_out1[127] == 1'b0) && (Product_out1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Product_out1[127] == 1'b1) && (Product_out1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(Product_out1[103:40]) + $signed({1'b0, Product_out1[39] & (Product_out1[40] | (|Product_out1[38:0]))})));

  always_ff @(posedge clk)
    begin : rd_2_process
      if (reset == 1'b1) begin
        rd_2_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_2_reg[0] <= Product_out1_1;
          rd_2_reg[32'sd1:32'sd121] <= rd_2_reg[32'sd0:32'sd120];
        end
      end
    end

  assign Product_out1_2 = rd_2_reg[121];

  assign X_1 = Gain1_out1_2 * Product_out1_2;
  assign X = (((X_1[127] == 1'b0) && (X_1[126:103] != 24'b000000000000000000000000)) || ((X_1[127] == 1'b0) && (X_1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((X_1[127] == 1'b1) && (X_1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(X_1[103:40]) + $signed({1'b0, X_1[39] & (X_1[40] | (|X_1[38:0]))})));

  assign Gain2_out1 = 64'sh000000DDB22D0E56 * Ubeta;
  assign Gain2_out1_1 = (((Gain2_out1[127] == 1'b0) && (Gain2_out1[126:103] != 24'b000000000000000000000000)) || ((Gain2_out1[127] == 1'b0) && (Gain2_out1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Gain2_out1[127] == 1'b1) && (Gain2_out1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(Gain2_out1[103:40]) + $signed({1'b0, Gain2_out1[39] & (Gain2_out1[40] | (|Gain2_out1[38:0]))})));

  always_ff @(posedge clk)
    begin : rd_3_process
      if (reset == 1'b1) begin
        Gain2_out1_2 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Gain2_out1_2 <= Gain2_out1_1;
        end
      end
    end

  assign Gain_out1 = 64'sh0000018000000000 * Ualpha;
  assign Gain_out1_1 = (((Gain_out1[127] == 1'b0) && (Gain_out1[126:103] != 24'b000000000000000000000000)) || ((Gain_out1[127] == 1'b0) && (Gain_out1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Gain_out1[127] == 1'b1) && (Gain_out1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(Gain_out1[103:40]) + $signed({1'b0, Gain_out1[39] & (Gain_out1[40] | (|Gain_out1[38:0]))})));

  always_ff @(posedge clk)
    begin : rd_4_process
      if (reset == 1'b1) begin
        Gain_out1_2 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Gain_out1_2 <= Gain_out1_1;
        end
      end
    end

  assign Add_add_cast = {Gain2_out1_2[63], Gain2_out1_2};
  assign Add_add_cast_1 = {Gain_out1_2[63], Gain_out1_2};
  assign Add_add_temp = Add_add_cast + Add_add_cast_1;
  assign Add_out1 = ((Add_add_temp[64] == 1'b0) && (Add_add_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Add_add_temp[64] == 1'b1) && (Add_add_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Add_add_temp[63:0])));
  assign Y_1 = Add_out1 * Product_out1_2;
  always_ff @(posedge clk)
    begin : rd_5_process
      if (reset == 1'b1) begin
        Y_2 <= 128'sh00000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          Y_2 <= Y_1;
        end
      end
    end

  assign Y = (((Y_2[127] == 1'b0) && (Y_2[126:103] != 24'b000000000000000000000000)) || ((Y_2[127] == 1'b0) && (Y_2[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Y_2[127] == 1'b1) && (Y_2[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(Y_2[103:40]) + $signed({1'b0, Y_2[39] & (Y_2[40] | (|Y_2[38:0]))})));

  assign Add1_sub_cast = {Gain2_out1_2[63], Gain2_out1_2};
  assign Add1_sub_cast_1 = {Gain_out1_2[63], Gain_out1_2};
  assign Add1_sub_temp = Add1_sub_cast - Add1_sub_cast_1;
  assign Add1_out1 = ((Add1_sub_temp[64] == 1'b0) && (Add1_sub_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Add1_sub_temp[64] == 1'b1) && (Add1_sub_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Add1_sub_temp[63:0])));
  assign Z_1 = Add1_out1 * Product_out1_2;
  always_ff @(posedge clk)
    begin : rd_6_process
      if (reset == 1'b1) begin
        Z_2 <= 128'sh00000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          Z_2 <= Z_1;
        end
      end
    end

  assign Z = (((Z_2[127] == 1'b0) && (Z_2[126:103] != 24'b000000000000000000000000)) || ((Z_2[127] == 1'b0) && (Z_2[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Z_2[127] == 1'b1) && (Z_2[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(Z_2[103:40]) + $signed({1'b0, Z_2[39] & (Z_2[40] | (|Z_2[38:0]))})));

endmodule   
