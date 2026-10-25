
`timescale 1ns/1ps

module Id
          import FOC_DUT_pkg::* ;
          (  input logic clk,
             input logic reset,
             input logic enb,
             input logic enb_1_5000_1,
             input logic enb_1_5000_0,
             input logic signed [31:0] id_ref,
             input logic signed [63:0] id_1,
             input logic signed [63:0] iq,
             input logic signed [39:0] we,
             input logic signed [63:0] du_d_z,
             input logic PI_Reset_EN,
             output logic signed [63:0] ud_raw);


  logic [1:0] rd_0_reg;
  logic PI_Reset_EN_1;
  logic signed [31:0] id_ref_1;
  vector_of_signed_logic_32 rd_2_reg [0:11];
  logic signed [31:0] id_ref_2;
  logic signed [63:0] Sum_sub_cast;
  logic signed [64:0] Sum_sub_cast_1;
  logic signed [64:0] Sum_sub_cast_2;
  logic signed [64:0] Sum_sub_temp;
  logic signed [63:0] Sum_out1;
  logic signed [127:0] alpha_out1;
  logic signed [127:0] alpha_out1_1;
  logic signed [63:0] alpha_out1_2;
  logic stateControl_1;
  logic stateControl_2;
  logic signed [127:0] KiTs_q_e_d;
  logic signed [127:0] KiTs_q_e_d_1;
  logic signed [63:0] KiTs_q_e_d_2;
  vector_of_signed_logic_64 rd_11_reg [0:1];
  logic signed [63:0] KiTs_q_e_d_3;
  logic signed [127:0] u_d_aw;
  logic signed [63:0] u_d_aw_1;
  vector_of_signed_logic_64 rd_12_reg [0:2];
  logic signed [63:0] u_d_aw_2;
  logic signed [63:0] Reset_Zero_out1;
  logic signed [63:0] x_d_z_out1;
  logic signed [64:0] Add2_stage2_add_cast;
  logic signed [64:0] Add2_stage2_add_cast_1;
  logic signed [64:0] Add2_stage2_add_temp;
  logic signed [63:0] Add2_op_stage1;
  logic signed [64:0] Add2_stage3_sub_cast;
  logic signed [64:0] Add2_stage3_sub_cast_1;
  logic signed [64:0] Add2_stage3_sub_temp;
  logic signed [63:0] x_d_next;
  logic signed [63:0] x_d_next_1;
  logic signed [63:0] Reset_Integral_out1;
  logic signed [63:0] From2_out1;
  logic signed [63:0] x_d_z_bypass_reg;
  logic signed [63:0] From2_out1_1;
  logic signed [63:0] From2_out1_2;
  logic signed [63:0] From2_out1_last_value;
  logic signed [63:0] x_d_z_out1_1;
  vector_of_signed_logic_64 rd_6_reg [0:11];
  logic signed [63:0] x_d_z_out1_2;
  logic signed [64:0] Add1_add_cast;
  logic signed [64:0] Add1_add_cast_1;
  logic signed [64:0] Add1_add_temp;
  logic signed [63:0] Add1_out1;
  logic signed [63:0] Add1_out1_1;
  logic signed [63:0] Constant1_out1;
  logic signed [127:0] Product_out1;
  logic signed [63:0] Product_out1_1;
  logic signed [63:0] Product_out1_2;
  vector_of_signed_logic_40 rd_8_reg [0:12];
  logic signed [39:0] we_1;
  logic signed [103:0] not_ascii;
  logic signed [63:0] not_ascii_1;
  logic [11:0] rd_1_reg;
  logic PI_Reset_EN_2;
  logic signed [63:0] not_ascii_2;
  logic signed [64:0] Sum1_sub_cast;
  logic signed [64:0] Sum1_sub_cast_1;
  logic signed [64:0] Sum1_sub_temp;
  logic signed [63:0] Sum1_out1;
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

  assign id_ref_1 = id_ref;

  always_ff @(posedge clk)
    begin : rd_2_process
      if (reset == 1'b1) begin
        rd_2_reg <= '{default :32'sb00000000000000000000000000000000};
      end
      else begin
        if (enb) begin
          rd_2_reg[0] <= id_ref_1;
          rd_2_reg[32'sd1:32'sd11] <= rd_2_reg[32'sd0:32'sd10];
        end
      end
    end

  assign id_ref_2 = rd_2_reg[11];

  assign Sum_sub_cast = {{16{id_ref_2[31]}}, {id_ref_2, 16'b0000000000000000}};
  assign Sum_sub_cast_1 = {Sum_sub_cast[63], Sum_sub_cast};
  assign Sum_sub_cast_2 = {id_1[63], id_1};
  assign Sum_sub_temp = Sum_sub_cast_1 - Sum_sub_cast_2;
  assign Sum_out1 = ((Sum_sub_temp[64] == 1'b0) && (Sum_sub_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Sum_sub_temp[64] == 1'b1) && (Sum_sub_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Sum_sub_temp[63:0])));
  assign alpha_out1 = 64'sh000008B99999999A * Sum_out1;
  always_ff @(posedge clk)
    begin : rd_5_process
      if (reset == 1'b1) begin
        alpha_out1_1 <= 128'sh00000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          alpha_out1_1 <= alpha_out1;
        end
      end
    end

  assign alpha_out1_2 = (((alpha_out1_1[127] == 1'b0) && (alpha_out1_1[126:103] != 24'b000000000000000000000000)) || ((alpha_out1_1[127] == 1'b0) && (alpha_out1_1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((alpha_out1_1[127] == 1'b1) && (alpha_out1_1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(alpha_out1_1[103:40]) + $signed({1'b0, alpha_out1_1[39] & (alpha_out1_1[40] | (|alpha_out1_1[38:0]))})));

  assign stateControl_1 = 1'b1;

  always_ff @(posedge clk)
    begin : delayMatch_process
      if (reset == 1'b1) begin
        stateControl_2 <= 1'b0;
      end
      else begin
        if (enb_1_5000_0) begin
          stateControl_2 <= stateControl_1;
        end
      end
    end

  assign KiTs_q_e_d = 64'sh0000012F5C28F5C3 * Sum_out1;
  always_ff @(posedge clk)
    begin : rd_10_process
      if (reset == 1'b1) begin
        KiTs_q_e_d_1 <= 128'sh00000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          KiTs_q_e_d_1 <= KiTs_q_e_d;
        end
      end
    end

  assign KiTs_q_e_d_2 = (((KiTs_q_e_d_1[127] == 1'b0) && (KiTs_q_e_d_1[126:103] != 24'b000000000000000000000000)) || ((KiTs_q_e_d_1[127] == 1'b0) && (KiTs_q_e_d_1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((KiTs_q_e_d_1[127] == 1'b1) && (KiTs_q_e_d_1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(KiTs_q_e_d_1[103:40]) + $signed({1'b0, KiTs_q_e_d_1[39] & (KiTs_q_e_d_1[40] | (|KiTs_q_e_d_1[38:0]))})));

  always_ff @(posedge clk)
    begin : rd_11_process
      if (reset == 1'b1) begin
        rd_11_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_11_reg[0] <= KiTs_q_e_d_2;
          rd_11_reg[1] <= rd_11_reg[0];
        end
      end
    end

  assign KiTs_q_e_d_3 = rd_11_reg[1];

  assign u_d_aw = 64'sh00000022C4E0C07A * du_d_z;
  assign u_d_aw_1 = (((u_d_aw[127] == 1'b0) && (u_d_aw[126:103] != 24'b000000000000000000000000)) || ((u_d_aw[127] == 1'b0) && (u_d_aw[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((u_d_aw[127] == 1'b1) && (u_d_aw[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(u_d_aw[103:40]) + $signed({1'b0, u_d_aw[39] & (u_d_aw[40] | (|u_d_aw[38:0]))})));

  always_ff @(posedge clk)
    begin : rd_12_process
      if (reset == 1'b1) begin
        rd_12_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_12_reg[0] <= u_d_aw_1;
          rd_12_reg[32'sd1:32'sd2] <= rd_12_reg[32'sd0:32'sd1];
        end
      end
    end

  assign u_d_aw_2 = rd_12_reg[2];

  assign Reset_Zero_out1 = 64'sh0000000000000000;
  assign Add2_stage2_add_cast = {x_d_z_out1[63], x_d_z_out1};
  assign Add2_stage2_add_cast_1 = {KiTs_q_e_d_3[63], KiTs_q_e_d_3};
  assign Add2_stage2_add_temp = Add2_stage2_add_cast + Add2_stage2_add_cast_1;
  assign Add2_op_stage1 = ((Add2_stage2_add_temp[64] == 1'b0) && (Add2_stage2_add_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Add2_stage2_add_temp[64] == 1'b1) && (Add2_stage2_add_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Add2_stage2_add_temp[63:0])));

  assign Add2_stage3_sub_cast = {Add2_op_stage1[63], Add2_op_stage1};
  assign Add2_stage3_sub_cast_1 = {u_d_aw_2[63], u_d_aw_2};
  assign Add2_stage3_sub_temp = Add2_stage3_sub_cast - Add2_stage3_sub_cast_1;
  assign x_d_next = ((Add2_stage3_sub_temp[64] == 1'b0) && (Add2_stage3_sub_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Add2_stage3_sub_temp[64] == 1'b1) && (Add2_stage3_sub_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Add2_stage3_sub_temp[63:0])));
  always_ff @(posedge clk)
    begin : rd_13_process
      if (reset == 1'b1) begin
        x_d_next_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          x_d_next_1 <= x_d_next;
        end
      end
    end

  assign Reset_Integral_out1 = (PI_Reset_EN_1 == 1'b0 ? x_d_next_1 :
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
    begin : x_d_z_bypass_process
      if (reset == 1'b1) begin
        x_d_z_bypass_reg <= 64'sh0000000000000000;
      end
      else begin
        if (enb_1_5000_1) begin
          x_d_z_bypass_reg <= From2_out1;
        end
      end
    end

  assign From2_out1_1 = (enb_1_5000_1 == 1'b1 ? From2_out1 :
              x_d_z_bypass_reg);

  always_ff @(posedge clk)
    begin : out0_bypass_process
      if (reset == 1'b1) begin
        From2_out1_last_value <= 64'sh0000000000000000;
      end
      else begin
        if (enb_1_5000_0) begin
          From2_out1_last_value <= From2_out1_2;
        end
      end
    end

  assign From2_out1_2 = (stateControl_2 == 1'b0 ? From2_out1_last_value :
              From2_out1_1);

  assign x_d_z_out1_1 = From2_out1_2;

  always_ff @(posedge clk)
    begin : rd_3_process
      if (reset == 1'b1) begin
        x_d_z_out1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          x_d_z_out1 <= x_d_z_out1_1;
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
          rd_6_reg[0] <= x_d_z_out1;
          rd_6_reg[32'sd1:32'sd11] <= rd_6_reg[32'sd0:32'sd10];
        end
      end
    end

  assign x_d_z_out1_2 = rd_6_reg[11];

  assign Add1_add_cast = {alpha_out1_2[63], alpha_out1_2};
  assign Add1_add_cast_1 = {x_d_z_out1_2[63], x_d_z_out1_2};
  assign Add1_add_temp = Add1_add_cast + Add1_add_cast_1;
  assign Add1_out1 = ((Add1_add_temp[64] == 1'b0) && (Add1_add_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Add1_add_temp[64] == 1'b1) && (Add1_add_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Add1_add_temp[63:0])));
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

  assign Constant1_out1 = 64'sh00000000725C3DEE;
  assign Product_out1 = iq * Constant1_out1;
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

  assign not_ascii = Product_out1_2 * we_1;
  assign not_ascii_1 = (((not_ascii[103] == 1'b0) && (not_ascii[102:87] != 16'b0000000000000000)) || ((not_ascii[103] == 1'b0) && (not_ascii[87:24] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((not_ascii[103] == 1'b1) && (not_ascii[102:87] != 16'b1111111111111111) ? 64'sh8000000000000000 :
              $signed(not_ascii[87:24]) + $signed({1'b0, not_ascii[23] & (not_ascii[24] | (|not_ascii[22:0]))})));

  always_ff @(posedge clk)
    begin : rd_1_process
      if (reset == 1'b1) begin
        rd_1_reg <= '{default :1'b0};
      end
      else begin
        if (enb) begin
          rd_1_reg[0] <= PI_Reset_EN_1;
          rd_1_reg[32'sd11:32'sd1] <= rd_1_reg[32'sd10:32'sd0];
        end
      end
    end

  assign PI_Reset_EN_2 = rd_1_reg[11];

  always_ff @(posedge clk)
    begin : rd_9_process
      if (reset == 1'b1) begin
        not_ascii_2 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          not_ascii_2 <= not_ascii_1;
        end
      end
    end

  assign Sum1_sub_cast = {Add1_out1_1[63], Add1_out1_1};
  assign Sum1_sub_cast_1 = {not_ascii_2[63], not_ascii_2};
  assign Sum1_sub_temp = Sum1_sub_cast - Sum1_sub_cast_1;
  assign Sum1_out1 = ((Sum1_sub_temp[64] == 1'b0) && (Sum1_sub_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Sum1_sub_temp[64] == 1'b1) && (Sum1_sub_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Sum1_sub_temp[63:0])));
  assign Reset_Output_out1 = (PI_Reset_EN_2 == 1'b0 ? Sum1_out1 :
              Reset_Zero_out1);
  assign ud_raw = Reset_Output_out1;

endmodule   
