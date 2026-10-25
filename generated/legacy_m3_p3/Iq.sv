
`timescale 1ns/1ps

module Iq
          import FOC_DUT_pkg::* ;
          (  input logic clk,
             input logic reset,
             input logic enb,
             input logic enb_1_5000_1,
             input logic signed [31:0] Iq_ref,
             input logic signed [63:0] id,
             input logic signed [63:0] iq_1,
             input logic signed [39:0] we,
             input logic signed [63:0] du_q_z,
             input logic PI_Reset_EN,
             output logic signed [63:0] uq_raw);


  logic [1:0] rd_0_reg;
  logic PI_Reset_EN_1;
  logic [12:0] rd_1_reg;
  logic PI_Reset_EN_2;
  logic signed [31:0] Iq_ref_1;
  vector_of_signed_logic_32 rd_2_reg [0:11];
  logic signed [31:0] Iq_ref_2;
  logic signed [63:0] Sum_sub_cast;
  logic signed [64:0] Sum_sub_cast_1;
  logic signed [64:0] Sum_sub_cast_2;
  logic signed [64:0] Sum_sub_temp;
  logic signed [63:0] e_q;
  logic signed [127:0] uq_p;
  logic signed [127:0] uq_p_1;
  logic signed [63:0] uq_p_2;
  logic signed [127:0] KiTs_q_e_q;
  logic signed [127:0] KiTs_q_e_q_1;
  logic signed [63:0] KiTs_q_e_q_2;
  vector_of_signed_logic_64 rd_12_reg [0:1];
  logic signed [63:0] KiTs_q_e_q_3;
  logic signed [127:0] u_q_aw;
  logic signed [63:0] u_q_aw_1;
  vector_of_signed_logic_64 rd_13_reg [0:2];
  logic signed [63:0] u_q_aw_2;
  logic signed [63:0] Reset_Zero_out1;
  logic signed [63:0] x_q_z_out1;
  logic signed [64:0] Add2_stage2_add_cast;
  logic signed [64:0] Add2_stage2_add_cast_1;
  logic signed [64:0] Add2_stage2_add_temp;
  logic signed [63:0] Add2_op_stage1;
  logic signed [64:0] Add2_stage3_sub_cast;
  logic signed [64:0] Add2_stage3_sub_cast_1;
  logic signed [64:0] Add2_stage3_sub_temp;
  logic signed [63:0] x_q_next;
  logic signed [63:0] x_q_next_1;
  logic signed [63:0] Reset_Integral_out1;
  logic signed [63:0] From2_out1;
  logic signed [63:0] x_q_z_bypass_reg;
  logic signed [63:0] From2_out1_1;
  logic signed [63:0] x_q_z_out1_1;
  vector_of_signed_logic_64 rd_6_reg [0:11];
  logic signed [63:0] x_q_z_out1_2;
  logic signed [64:0] Add1_add_cast;
  logic signed [64:0] Add1_add_cast_1;
  logic signed [64:0] Add1_add_temp;
  logic signed [63:0] Add1_out1;
  logic signed [63:0] Ld_out1;
  logic signed [127:0] Product_out1;
  logic signed [63:0] Product_out1_1;
  logic signed [63:0] Product_out1_2;
  logic signed [63:0] Constant_out1;
  logic signed [64:0] Add_add_cast;
  logic signed [64:0] Add_add_cast_1;
  logic signed [64:0] Add_add_temp;
  logic signed [63:0] Add_out1;
  vector_of_signed_logic_40 rd_8_reg [0:12];
  logic signed [39:0] we_1;
  logic signed [103:0] Ed;
  logic signed [63:0] Add1_out1_1;
  logic signed [103:0] Ed_1;
  logic signed [63:0] Ed_2;
  logic signed [64:0] Sum1_add_cast;
  logic signed [64:0] Sum1_add_cast_1;
  logic signed [64:0] Sum1_add_temp;
  logic signed [63:0] Sum1_out1;
  logic signed [63:0] Sum1_out1_1;
  logic signed [63:0] Reset_Output_out1;

      

  always_ff @(posedge clk)
    begin : rd_0_process
      if (reset == 1'b1) begin
        rd_0_reg <= '{default :1'b0};
      end
      else begin
        if (enb) begin
          rd_0_reg[0] <= PI_Reset_EN;
          rd_0_reg[1] <= rd_0_reg[0];
        end
      end
    end

  assign PI_Reset_EN_1 = rd_0_reg[1];

  always_ff @(posedge clk)
    begin : rd_1_process
      if (reset == 1'b1) begin
        rd_1_reg <= '{default :1'b0};
      end
      else begin
        if (enb) begin
          rd_1_reg[0] <= PI_Reset_EN_1;
          rd_1_reg[32'sd12:32'sd1] <= rd_1_reg[32'sd11:32'sd0];
        end
      end
    end

  assign PI_Reset_EN_2 = rd_1_reg[12];

  assign Iq_ref_1 = Iq_ref;

  always_ff @(posedge clk)
    begin : rd_2_process
      if (reset == 1'b1) begin
        rd_2_reg <= '{default :32'sb00000000000000000000000000000000};
      end
      else begin
        if (enb) begin
          rd_2_reg[0] <= Iq_ref_1;
          rd_2_reg[32'sd1:32'sd11] <= rd_2_reg[32'sd0:32'sd10];
        end
      end
    end

  assign Iq_ref_2 = rd_2_reg[11];

  assign Sum_sub_cast = {{16{Iq_ref_2[31]}}, {Iq_ref_2, 16'b0000000000000000}};
  assign Sum_sub_cast_1 = {Sum_sub_cast[63], Sum_sub_cast};
  assign Sum_sub_cast_2 = {iq_1[63], iq_1};
  assign Sum_sub_temp = Sum_sub_cast_1 - Sum_sub_cast_2;
  assign e_q = ((Sum_sub_temp[64] == 1'b0) && (Sum_sub_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Sum_sub_temp[64] == 1'b1) && (Sum_sub_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Sum_sub_temp[63:0])));
  assign uq_p = 64'sh000008B99999999A * e_q;
  always_ff @(posedge clk)
    begin : rd_5_process
      if (reset == 1'b1) begin
        uq_p_1 <= 128'sh00000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          uq_p_1 <= uq_p;
        end
      end
    end

  assign uq_p_2 = (((uq_p_1[127] == 1'b0) && (uq_p_1[126:103] != 24'b000000000000000000000000)) || ((uq_p_1[127] == 1'b0) && (uq_p_1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((uq_p_1[127] == 1'b1) && (uq_p_1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(uq_p_1[103:40]) + $signed({1'b0, uq_p_1[39] & (uq_p_1[40] | (|uq_p_1[38:0]))})));

  assign KiTs_q_e_q = 64'sh0000012F5C28F5C3 * e_q;
  always_ff @(posedge clk)
    begin : rd_11_process
      if (reset == 1'b1) begin
        KiTs_q_e_q_1 <= 128'sh00000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          KiTs_q_e_q_1 <= KiTs_q_e_q;
        end
      end
    end

  assign KiTs_q_e_q_2 = (((KiTs_q_e_q_1[127] == 1'b0) && (KiTs_q_e_q_1[126:103] != 24'b000000000000000000000000)) || ((KiTs_q_e_q_1[127] == 1'b0) && (KiTs_q_e_q_1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((KiTs_q_e_q_1[127] == 1'b1) && (KiTs_q_e_q_1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(KiTs_q_e_q_1[103:40]) + $signed({1'b0, KiTs_q_e_q_1[39] & (KiTs_q_e_q_1[40] | (|KiTs_q_e_q_1[38:0]))})));

  always_ff @(posedge clk)
    begin : rd_12_process
      if (reset == 1'b1) begin
        rd_12_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_12_reg[0] <= KiTs_q_e_q_2;
          rd_12_reg[1] <= rd_12_reg[0];
        end
      end
    end

  assign KiTs_q_e_q_3 = rd_12_reg[1];

  assign u_q_aw = 64'sh00000022C4E0C07A * du_q_z;
  assign u_q_aw_1 = (((u_q_aw[127] == 1'b0) && (u_q_aw[126:103] != 24'b000000000000000000000000)) || ((u_q_aw[127] == 1'b0) && (u_q_aw[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((u_q_aw[127] == 1'b1) && (u_q_aw[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(u_q_aw[103:40]) + $signed({1'b0, u_q_aw[39] & (u_q_aw[40] | (|u_q_aw[38:0]))})));

  always_ff @(posedge clk)
    begin : rd_13_process
      if (reset == 1'b1) begin
        rd_13_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_13_reg[0] <= u_q_aw_1;
          rd_13_reg[32'sd1:32'sd2] <= rd_13_reg[32'sd0:32'sd1];
        end
      end
    end

  assign u_q_aw_2 = rd_13_reg[2];

  assign Reset_Zero_out1 = 64'sh0000000000000000;
  assign Add2_stage2_add_cast = {x_q_z_out1[63], x_q_z_out1};
  assign Add2_stage2_add_cast_1 = {KiTs_q_e_q_3[63], KiTs_q_e_q_3};
  assign Add2_stage2_add_temp = Add2_stage2_add_cast + Add2_stage2_add_cast_1;
  assign Add2_op_stage1 = ((Add2_stage2_add_temp[64] == 1'b0) && (Add2_stage2_add_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Add2_stage2_add_temp[64] == 1'b1) && (Add2_stage2_add_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Add2_stage2_add_temp[63:0])));

  assign Add2_stage3_sub_cast = {Add2_op_stage1[63], Add2_op_stage1};
  assign Add2_stage3_sub_cast_1 = {u_q_aw_2[63], u_q_aw_2};
  assign Add2_stage3_sub_temp = Add2_stage3_sub_cast - Add2_stage3_sub_cast_1;
  assign x_q_next = ((Add2_stage3_sub_temp[64] == 1'b0) && (Add2_stage3_sub_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Add2_stage3_sub_temp[64] == 1'b1) && (Add2_stage3_sub_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Add2_stage3_sub_temp[63:0])));
  always_ff @(posedge clk)
    begin : rd_14_process
      if (reset == 1'b1) begin
        x_q_next_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          x_q_next_1 <= x_q_next;
        end
      end
    end

  assign Reset_Integral_out1 = (PI_Reset_EN_1 == 1'b0 ? x_q_next_1 :
              Reset_Zero_out1);
  always_ff @(posedge clk)
    begin : crp_out_delay_process
      if (reset == 1'b1) begin
        From2_out1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          From2_out1 <= Reset_Integral_out1;
        end
      end
    end

  always_ff @(posedge clk)
    begin : x_q_z_bypass_process
      if (reset == 1'b1) begin
        x_q_z_bypass_reg <= 64'sh0000000000000000;
      end
      else begin
        if (enb_1_5000_1) begin
          x_q_z_bypass_reg <= From2_out1;
        end
      end
    end

  assign From2_out1_1 = (enb_1_5000_1 == 1'b1 ? From2_out1 :
              x_q_z_bypass_reg);

  assign x_q_z_out1_1 = From2_out1_1;

  always_ff @(posedge clk)
    begin : rd_3_process
      if (reset == 1'b1) begin
        x_q_z_out1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          x_q_z_out1 <= x_q_z_out1_1;
        end
      end
    end

  always_ff @(posedge clk)
    begin : rd_6_process
      if (reset == 1'b1) begin
        rd_6_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_6_reg[0] <= x_q_z_out1;
          rd_6_reg[32'sd1:32'sd11] <= rd_6_reg[32'sd0:32'sd10];
        end
      end
    end

  assign x_q_z_out1_2 = rd_6_reg[11];

  assign Add1_add_cast = {uq_p_2[63], uq_p_2};
  assign Add1_add_cast_1 = {x_q_z_out1_2[63], x_q_z_out1_2};
  assign Add1_add_temp = Add1_add_cast + Add1_add_cast_1;
  assign Add1_out1 = ((Add1_add_temp[64] == 1'b0) && (Add1_add_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Add1_add_temp[64] == 1'b1) && (Add1_add_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Add1_add_temp[63:0])));
  assign Ld_out1 = 64'sh00000000725C3DEE;
  assign Product_out1 = id * Ld_out1;
  assign Product_out1_1 = (((Product_out1[127] == 1'b0) && (Product_out1[126:103] != 24'b000000000000000000000000)) || ((Product_out1[127] == 1'b0) && (Product_out1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Product_out1[127] == 1'b1) && (Product_out1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(Product_out1[103:40]) + $signed({1'b0, Product_out1[39] & (Product_out1[40] | (|Product_out1[38:0]))})));

  always_ff @(posedge clk)
    begin : rd_4_process
      if (reset == 1'b1) begin
        Product_out1_2 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Product_out1_2 <= Product_out1_1;
        end
      end
    end

  assign Constant_out1 = 64'sh00000024189374BC;
  assign Add_add_cast = {Product_out1_2[63], Product_out1_2};
  assign Add_add_cast_1 = {Constant_out1[63], Constant_out1};
  assign Add_add_temp = Add_add_cast + Add_add_cast_1;
  assign Add_out1 = ((Add_add_temp[64] == 1'b0) && (Add_add_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Add_add_temp[64] == 1'b1) && (Add_add_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Add_add_temp[63:0])));
  always_ff @(posedge clk)
    begin : rd_8_process
      if (reset == 1'b1) begin
        rd_8_reg <= '{default :40'sh0000000000};
      end
      else begin
        if (enb) begin
          rd_8_reg[0] <= we;
          rd_8_reg[32'sd1:32'sd12] <= rd_8_reg[32'sd0:32'sd11];
        end
      end
    end

  assign we_1 = rd_8_reg[12];

  assign Ed = Add_out1 * we_1;
  always_ff @(posedge clk)
    begin : rd_7_process
      if (reset == 1'b1) begin
        Add1_out1_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Add1_out1_1 <= Add1_out1;
        end
      end
    end

  always_ff @(posedge clk)
    begin : rd_9_process
      if (reset == 1'b1) begin
        Ed_1 <= 104'sh00000000000000000000000000;
      end
      else begin
        if (enb) begin
          Ed_1 <= Ed;
        end
      end
    end

  assign Ed_2 = (((Ed_1[103] == 1'b0) && (Ed_1[102:87] != 16'b0000000000000000)) || ((Ed_1[103] == 1'b0) && (Ed_1[87:24] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Ed_1[103] == 1'b1) && (Ed_1[102:87] != 16'b1111111111111111) ? 64'sh8000000000000000 :
              $signed(Ed_1[87:24]) + $signed({1'b0, Ed_1[23] & (Ed_1[24] | (|Ed_1[22:0]))})));

  assign Sum1_add_cast = {Add1_out1_1[63], Add1_out1_1};
  assign Sum1_add_cast_1 = {Ed_2[63], Ed_2};
  assign Sum1_add_temp = Sum1_add_cast + Sum1_add_cast_1;
  assign Sum1_out1 = ((Sum1_add_temp[64] == 1'b0) && (Sum1_add_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Sum1_add_temp[64] == 1'b1) && (Sum1_add_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Sum1_add_temp[63:0])));
  always_ff @(posedge clk)
    begin : rd_10_process
      if (reset == 1'b1) begin
        Sum1_out1_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Sum1_out1_1 <= Sum1_out1;
        end
      end
    end

  assign Reset_Output_out1 = (PI_Reset_EN_2 == 1'b0 ? Sum1_out1_1 :
              Reset_Zero_out1);
  assign uq_raw = Reset_Output_out1;

endmodule   
