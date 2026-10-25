
`timescale 1ns/1ps

module Duty_Calculate
          import FOC_DUT_pkg::* ;
          (  input logic clk,
             input logic reset,
             input logic enb,
             input logic [7:0] N,
             input logic signed [63:0] T1,
             input logic signed [63:0] T2,
             output logic signed [63:0] Duty_U,
             output logic signed [63:0] Duty_V,
             output logic signed [63:0] Duty_W);


  vector_of_unsigned_logic_8 rd_0_reg [0:115];
  logic [7:0] N_1;
  logic switch_compare_1;
  logic [7:0] non_zero_default;
  logic [7:0] N_zp;
  logic signed [63:0] Constant_out1;
  vector_of_signed_logic_64 Mux_out1 [0:2];
  logic signed [63:0] Fcn1_Value;
  logic signed [63:0] Fcn1_Value_1;
  logic signed [63:0] Fcn_Value;
  logic signed [63:0] Fcn_Value_1;
  logic signed [63:0] Fcn2_Value;
  logic signed [63:0] Fcn2_Value_1;
  logic signed [63:0] Multiport_Switch_out1;
  logic signed [127:0] DutyU;
  logic signed [127:0] DutyU_1;
  logic signed [63:0] DutyU_2;
  logic signed [63:0] Gain_UpperDuty_const_val_1;
  logic signed [64:0] Gain_UpperDuty_add_cast;
  logic signed [64:0] Gain_UpperDuty_add_cast_1;
  logic signed [64:0] Gain_UpperDuty_add_temp;
  logic signed [63:0] Gain_UpperDuty_out1;
  logic switch_compare_1_1;
  logic [7:0] non_zero_default_1;
  logic [7:0] N_zp_1;
  logic signed [63:0] Multiport_Switch1_out1;
  logic signed [127:0] DutyV;
  logic signed [127:0] DutyV_1;
  logic signed [63:0] DutyV_2;
  logic signed [63:0] Gain1_UpperDuty_const_val_1;
  logic signed [64:0] Gain1_UpperDuty_add_cast;
  logic signed [64:0] Gain1_UpperDuty_add_cast_1;
  logic signed [64:0] Gain1_UpperDuty_add_temp;
  logic signed [63:0] Gain1_UpperDuty_out1;
  logic switch_compare_1_2;
  logic [7:0] non_zero_default_2;
  logic [7:0] N_zp_2;
  logic signed [63:0] Multiport_Switch2_out1;
  logic signed [127:0] DutyW;
  logic signed [127:0] DutyW_1;
  logic signed [63:0] DutyW_2;
  logic signed [63:0] Gain2_UpperDuty_const_val_1;
  logic signed [64:0] Gain2_UpperDuty_add_cast;
  logic signed [64:0] Gain2_UpperDuty_add_cast_1;
  logic signed [64:0] Gain2_UpperDuty_add_temp;
  logic signed [63:0] Gain2_UpperDuty_out1;


  always_ff @(posedge clk)
    begin : rd_0_process
      if (reset == 1'b1) begin
        rd_0_reg <= '{default :8'b00000000};
      end
      else begin
        if (enb) begin
          rd_0_reg[0] <= N;
          rd_0_reg[32'sd1:32'sd115] <= rd_0_reg[32'sd0:32'sd114];
        end
      end
    end

  assign N_1 = rd_0_reg[115];

  assign switch_compare_1 = N_1 >= 8'b00000001;

  assign non_zero_default = 8'b00000001;

  assign N_zp = (switch_compare_1 == 1'b0 ? non_zero_default :
              N_1);

  assign Constant_out1 = 64'sh00000000068DB8BB;
  assign Mux_out1[0] = T1;
  assign Mux_out1[1] = T2;
  assign Mux_out1[2] = Constant_out1;
  Fcn1 u_Fcn1 (.clk(clk),
               .reset(reset),
               .enb(enb),
               .Vector(Mux_out1),
               .Value(Fcn1_Value)
               );
  always_ff @(posedge clk)
    begin : rd_1_process
      if (reset == 1'b1) begin
        Fcn1_Value_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Fcn1_Value_1 <= Fcn1_Value;
        end
      end
    end

  Fcn u_Fcn (.clk(clk),
             .reset(reset),
             .enb(enb),
             .Vector(Mux_out1),
             .Value(Fcn_Value)
             );
  always_ff @(posedge clk)
    begin : rd_2_process
      if (reset == 1'b1) begin
        Fcn_Value_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Fcn_Value_1 <= Fcn_Value;
        end
      end
    end

  Fcn2 u_Fcn2 (.clk(clk),
               .reset(reset),
               .enb(enb),
               .Vector(Mux_out1),
               .Value(Fcn2_Value)
               );
  always_ff @(posedge clk)
    begin : rd_3_process
      if (reset == 1'b1) begin
        Fcn2_Value_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Fcn2_Value_1 <= Fcn2_Value;
        end
      end
    end

  assign Multiport_Switch_out1 = (N_zp == 8'b00000001 ? Fcn1_Value_1 :
              (N_zp == 8'b00000010 ? Fcn_Value_1 :
              (N_zp == 8'b00000011 ? Fcn_Value_1 :
              (N_zp == 8'b00000100 ? Fcn2_Value_1 :
              (N_zp == 8'b00000101 ? Fcn2_Value_1 :
              Fcn1_Value_1)))));
  assign DutyU = 64'shFFB1E00000000000 * Multiport_Switch_out1;
  always_ff @(posedge clk)
    begin : rd_4_process
      if (reset == 1'b1) begin
        DutyU_1 <= 128'sh00000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          DutyU_1 <= DutyU;
        end
      end
    end

  assign DutyU_2 = (((DutyU_1[127] == 1'b0) && (DutyU_1[126:103] != 24'b000000000000000000000000)) || ((DutyU_1[127] == 1'b0) && (DutyU_1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((DutyU_1[127] == 1'b1) && (DutyU_1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(DutyU_1[103:40]) + $signed({1'b0, DutyU_1[39] & (DutyU_1[40] | (|DutyU_1[38:0]))})));

  assign Gain_UpperDuty_const_val_1 = 64'sh0000010000000000;

  assign Gain_UpperDuty_add_cast = {DutyU_2[63], DutyU_2};
  assign Gain_UpperDuty_add_cast_1 = {Gain_UpperDuty_const_val_1[63], Gain_UpperDuty_const_val_1};
  assign Gain_UpperDuty_add_temp = Gain_UpperDuty_add_cast + Gain_UpperDuty_add_cast_1;
  assign Gain_UpperDuty_out1 = ((Gain_UpperDuty_add_temp[64] == 1'b0) && (Gain_UpperDuty_add_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Gain_UpperDuty_add_temp[64] == 1'b1) && (Gain_UpperDuty_add_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Gain_UpperDuty_add_temp[63:0])));
  assign Duty_U = Gain_UpperDuty_out1;

  assign switch_compare_1_1 = N_1 >= 8'b00000001;

  assign non_zero_default_1 = 8'b00000001;

  assign N_zp_1 = (switch_compare_1_1 == 1'b0 ? non_zero_default_1 :
              N_1);

  assign Multiport_Switch1_out1 = (N_zp_1 == 8'b00000001 ? Fcn_Value_1 :
              (N_zp_1 == 8'b00000010 ? Fcn2_Value_1 :
              (N_zp_1 == 8'b00000011 ? Fcn1_Value_1 :
              (N_zp_1 == 8'b00000100 ? Fcn1_Value_1 :
              (N_zp_1 == 8'b00000101 ? Fcn_Value_1 :
              Fcn2_Value_1)))));
  assign DutyV = 64'shFFB1E00000000000 * Multiport_Switch1_out1;
  always_ff @(posedge clk)
    begin : rd_5_process
      if (reset == 1'b1) begin
        DutyV_1 <= 128'sh00000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          DutyV_1 <= DutyV;
        end
      end
    end

  assign DutyV_2 = (((DutyV_1[127] == 1'b0) && (DutyV_1[126:103] != 24'b000000000000000000000000)) || ((DutyV_1[127] == 1'b0) && (DutyV_1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((DutyV_1[127] == 1'b1) && (DutyV_1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(DutyV_1[103:40]) + $signed({1'b0, DutyV_1[39] & (DutyV_1[40] | (|DutyV_1[38:0]))})));

  assign Gain1_UpperDuty_const_val_1 = 64'sh0000010000000000;

  assign Gain1_UpperDuty_add_cast = {DutyV_2[63], DutyV_2};
  assign Gain1_UpperDuty_add_cast_1 = {Gain1_UpperDuty_const_val_1[63], Gain1_UpperDuty_const_val_1};
  assign Gain1_UpperDuty_add_temp = Gain1_UpperDuty_add_cast + Gain1_UpperDuty_add_cast_1;
  assign Gain1_UpperDuty_out1 = ((Gain1_UpperDuty_add_temp[64] == 1'b0) && (Gain1_UpperDuty_add_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Gain1_UpperDuty_add_temp[64] == 1'b1) && (Gain1_UpperDuty_add_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Gain1_UpperDuty_add_temp[63:0])));
  assign Duty_V = Gain1_UpperDuty_out1;

  assign switch_compare_1_2 = N_1 >= 8'b00000001;

  assign non_zero_default_2 = 8'b00000001;

  assign N_zp_2 = (switch_compare_1_2 == 1'b0 ? non_zero_default_2 :
              N_1);

  assign Multiport_Switch2_out1 = (N_zp_2 == 8'b00000001 ? Fcn2_Value_1 :
              (N_zp_2 == 8'b00000010 ? Fcn1_Value_1 :
              (N_zp_2 == 8'b00000011 ? Fcn2_Value_1 :
              (N_zp_2 == 8'b00000100 ? Fcn_Value_1 :
              (N_zp_2 == 8'b00000101 ? Fcn1_Value_1 :
              Fcn_Value_1)))));
  assign DutyW = 64'shFFB1E00000000000 * Multiport_Switch2_out1;
  always_ff @(posedge clk)
    begin : rd_6_process
      if (reset == 1'b1) begin
        DutyW_1 <= 128'sh00000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          DutyW_1 <= DutyW;
        end
      end
    end

  assign DutyW_2 = (((DutyW_1[127] == 1'b0) && (DutyW_1[126:103] != 24'b000000000000000000000000)) || ((DutyW_1[127] == 1'b0) && (DutyW_1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((DutyW_1[127] == 1'b1) && (DutyW_1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(DutyW_1[103:40]) + $signed({1'b0, DutyW_1[39] & (DutyW_1[40] | (|DutyW_1[38:0]))})));

  assign Gain2_UpperDuty_const_val_1 = 64'sh0000010000000000;

  assign Gain2_UpperDuty_add_cast = {DutyW_2[63], DutyW_2};
  assign Gain2_UpperDuty_add_cast_1 = {Gain2_UpperDuty_const_val_1[63], Gain2_UpperDuty_const_val_1};
  assign Gain2_UpperDuty_add_temp = Gain2_UpperDuty_add_cast + Gain2_UpperDuty_add_cast_1;
  assign Gain2_UpperDuty_out1 = ((Gain2_UpperDuty_add_temp[64] == 1'b0) && (Gain2_UpperDuty_add_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Gain2_UpperDuty_add_temp[64] == 1'b1) && (Gain2_UpperDuty_add_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Gain2_UpperDuty_add_temp[63:0])));
  assign Duty_W = Gain2_UpperDuty_out1;

endmodule   
