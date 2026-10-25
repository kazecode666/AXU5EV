
`timescale 1ns/1ps

module T1T2_Calculate
          import FOC_DUT_pkg::* ;
          (  input logic clk,
             input logic reset,
             input logic enb,
             input logic [7:0] N,
             input logic signed [63:0] X,
             input logic signed [63:0] Y,
             input logic signed [63:0] Z,
             output logic signed [63:0] T1,
             output logic signed [63:0] T2);


  vector_of_unsigned_logic_8 rd_0_reg [0:1];
  logic [7:0] N_1;
  logic switch_compare_1;
  logic [7:0] non_zero_default;
  logic [7:0] N_zp;
  vector_of_signed_logic_64 rd_1_reg [0:1];
  logic signed [63:0] Z_1;
  logic signed [63:0] Z_2;
  vector_of_signed_logic_64 rd_3_reg [0:1];
  logic signed [63:0] Y_1;
  logic signed [63:0] Y_2;
  logic signed [64:0] Gain2_cast;
  logic signed [64:0] Gain2_cast_1;
  logic signed [127:0] Gain2_out1;
  logic signed [63:0] Gain2_out1_1;
  logic signed [63:0] Gain2_out1_2;
  vector_of_signed_logic_64 rd_6_reg [0:2];
  logic signed [63:0] X_1;
  logic signed [64:0] Gain_cast;
  logic signed [64:0] Gain_cast_1;
  logic signed [127:0] Gain_out1;
  logic signed [63:0] Gain_out1_1;
  logic signed [63:0] Gain_out1_2;
  logic signed [63:0] X_2;
  logic signed [64:0] Gain1_cast;
  logic signed [64:0] Gain1_cast_1;
  logic signed [127:0] Gain1_out1;
  logic signed [63:0] Gain1_out1_1;
  logic signed [63:0] Gain1_out1_2;
  logic signed [63:0] Multiport_Switch_out1;
  logic switch_compare_1_1;
  logic [7:0] non_zero_default_1;
  logic [7:0] N_zp_1;
  logic signed [63:0] Multiport_Switch1_out1;
  logic signed [63:0] Constant_out1;
  vector_of_signed_logic_64 Mux_out1 [0:2];
  logic signed [63:0] Fcn_Value;
  vector_of_signed_logic_64 rd_11_reg [0:110];
  logic signed [63:0] Fcn_Value_1;
  logic switch_compare_1_2;
  logic signed [63:0] Fcn1_Value;
  logic signed [63:0] Fcn1_Value_1;
  vector_of_signed_logic_64 rd_10_reg [0:111];
  logic signed [63:0] Multiport_Switch_out1_1;
  logic switch_compare_1_3;
  logic signed [63:0] Fcn2_Value;
  logic signed [63:0] Fcn2_Value_1;
  vector_of_signed_logic_64 rd_13_reg [0:111];
  logic signed [63:0] Multiport_Switch1_out1_1;


  always_ff @(posedge clk)
    begin : rd_0_process
      if (reset == 1'b1) begin
        rd_0_reg <= '{default :8'b00000000};
      end
      else begin
        if (enb) begin
          rd_0_reg[0] <= N;
          rd_0_reg[1] <= rd_0_reg[0];
        end
      end
    end

  assign N_1 = rd_0_reg[1];

  assign switch_compare_1 = N_1 >= 8'b00000001;

  assign non_zero_default = 8'b00000001;

  assign N_zp = (switch_compare_1 == 1'b0 ? non_zero_default :
              N_1);

  always_ff @(posedge clk)
    begin : rd_1_process
      if (reset == 1'b1) begin
        rd_1_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_1_reg[0] <= Z;
          rd_1_reg[1] <= rd_1_reg[0];
        end
      end
    end

  assign Z_1 = rd_1_reg[1];

  always_ff @(posedge clk)
    begin : rd_2_process
      if (reset == 1'b1) begin
        Z_2 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Z_2 <= Z_1;
        end
      end
    end

  always_ff @(posedge clk)
    begin : rd_3_process
      if (reset == 1'b1) begin
        rd_3_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_3_reg[0] <= Y;
          rd_3_reg[1] <= rd_3_reg[0];
        end
      end
    end

  assign Y_1 = rd_3_reg[1];

  always_ff @(posedge clk)
    begin : rd_4_process
      if (reset == 1'b1) begin
        Y_2 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Y_2 <= Y_1;
        end
      end
    end

  assign Gain2_cast = {Z_1[63], Z_1};
  assign Gain2_cast_1 =  - (Gain2_cast);
  assign Gain2_out1 = {{23{Gain2_cast_1[64]}}, {Gain2_cast_1, 40'b0000000000000000000000000000000000000000}};
  assign Gain2_out1_1 = (((Gain2_out1[127] == 1'b0) && (Gain2_out1[126:103] != 24'b000000000000000000000000)) || ((Gain2_out1[127] == 1'b0) && (Gain2_out1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Gain2_out1[127] == 1'b1) && (Gain2_out1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(Gain2_out1[103:40]) + $signed({1'b0, Gain2_out1[39] & (Gain2_out1[40] | (|Gain2_out1[38:0]))})));

  always_ff @(posedge clk)
    begin : rd_5_process
      if (reset == 1'b1) begin
        Gain2_out1_2 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Gain2_out1_2 <= Gain2_out1_1;
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
          rd_6_reg[0] <= X;
          rd_6_reg[32'sd1:32'sd2] <= rd_6_reg[32'sd0:32'sd1];
        end
      end
    end

  assign X_1 = rd_6_reg[2];

  assign Gain_cast = {X_1[63], X_1};
  assign Gain_cast_1 =  - (Gain_cast);
  assign Gain_out1 = {{23{Gain_cast_1[64]}}, {Gain_cast_1, 40'b0000000000000000000000000000000000000000}};
  assign Gain_out1_1 = (((Gain_out1[127] == 1'b0) && (Gain_out1[126:103] != 24'b000000000000000000000000)) || ((Gain_out1[127] == 1'b0) && (Gain_out1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Gain_out1[127] == 1'b1) && (Gain_out1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(Gain_out1[103:40]) + $signed({1'b0, Gain_out1[39] & (Gain_out1[40] | (|Gain_out1[38:0]))})));

  always_ff @(posedge clk)
    begin : rd_7_process
      if (reset == 1'b1) begin
        Gain_out1_2 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Gain_out1_2 <= Gain_out1_1;
        end
      end
    end

  always_ff @(posedge clk)
    begin : rd_8_process
      if (reset == 1'b1) begin
        X_2 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          X_2 <= X_1;
        end
      end
    end

  assign Gain1_cast = {Y_1[63], Y_1};
  assign Gain1_cast_1 =  - (Gain1_cast);
  assign Gain1_out1 = {{23{Gain1_cast_1[64]}}, {Gain1_cast_1, 40'b0000000000000000000000000000000000000000}};
  assign Gain1_out1_1 = (((Gain1_out1[127] == 1'b0) && (Gain1_out1[126:103] != 24'b000000000000000000000000)) || ((Gain1_out1[127] == 1'b0) && (Gain1_out1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Gain1_out1[127] == 1'b1) && (Gain1_out1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(Gain1_out1[103:40]) + $signed({1'b0, Gain1_out1[39] & (Gain1_out1[40] | (|Gain1_out1[38:0]))})));

  always_ff @(posedge clk)
    begin : rd_9_process
      if (reset == 1'b1) begin
        Gain1_out1_2 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Gain1_out1_2 <= Gain1_out1_1;
        end
      end
    end

  assign Multiport_Switch_out1 = (N_zp == 8'b00000001 ? Z_2 :
              (N_zp == 8'b00000010 ? Y_2 :
              (N_zp == 8'b00000011 ? Gain2_out1_2 :
              (N_zp == 8'b00000100 ? Gain_out1_2 :
              (N_zp == 8'b00000101 ? X_2 :
              Gain1_out1_2)))));
  assign switch_compare_1_1 = N_1 >= 8'b00000001;

  assign non_zero_default_1 = 8'b00000001;

  assign N_zp_1 = (switch_compare_1_1 == 1'b0 ? non_zero_default_1 :
              N_1);

  assign Multiport_Switch1_out1 = (N_zp_1 == 8'b00000001 ? Y_2 :
              (N_zp_1 == 8'b00000010 ? Gain_out1_2 :
              (N_zp_1 == 8'b00000011 ? X_2 :
              (N_zp_1 == 8'b00000100 ? Z_2 :
              (N_zp_1 == 8'b00000101 ? Gain1_out1_2 :
              Gain2_out1_2)))));
  assign Constant_out1 = 64'sh00000000068DB8BB;
  assign Mux_out1[0] = Multiport_Switch_out1;
  assign Mux_out1[1] = Multiport_Switch1_out1;
  assign Mux_out1[2] = Constant_out1;
  Fcn_block u_Fcn (.clk(clk),
                   .reset(reset),
                   .enb(enb),
                   .Vector(Mux_out1),
                   .Value(Fcn_Value)
                   );
  always_ff @(posedge clk)
    begin : rd_11_process
      if (reset == 1'b1) begin
        rd_11_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_11_reg[0] <= Fcn_Value;
          rd_11_reg[32'sd1:32'sd110] <= rd_11_reg[32'sd0:32'sd109];
        end
      end
    end

  assign Fcn_Value_1 = rd_11_reg[110];

  assign switch_compare_1_2 = Fcn_Value_1 >= 64'sh0000000000000000;

  Fcn1_block u_Fcn1 (.clk(clk),
                     .reset(reset),
                     .enb(enb),
                     .Vector(Mux_out1),
                     .Value(Fcn1_Value)
                     );
  always_ff @(posedge clk)
    begin : rd_12_process
      if (reset == 1'b1) begin
        Fcn1_Value_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Fcn1_Value_1 <= Fcn1_Value;
        end
      end
    end

  always_ff @(posedge clk)
    begin : rd_10_process
      if (reset == 1'b1) begin
        rd_10_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_10_reg[0] <= Multiport_Switch_out1;
          rd_10_reg[32'sd1:32'sd111] <= rd_10_reg[32'sd0:32'sd110];
        end
      end
    end

  assign Multiport_Switch_out1_1 = rd_10_reg[111];

  assign T1 = (switch_compare_1_2 == 1'b0 ? Fcn1_Value_1 :
              Multiport_Switch_out1_1);
  assign switch_compare_1_3 = Fcn_Value_1 > 64'sh0000000000000000;

  Fcn2_block u_Fcn2 (.clk(clk),
                     .reset(reset),
                     .enb(enb),
                     .Vector(Mux_out1),
                     .Value(Fcn2_Value)
                     );
  always_ff @(posedge clk)
    begin : rd_14_process
      if (reset == 1'b1) begin
        Fcn2_Value_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Fcn2_Value_1 <= Fcn2_Value;
        end
      end
    end

  always_ff @(posedge clk)
    begin : rd_13_process
      if (reset == 1'b1) begin
        rd_13_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_13_reg[0] <= Multiport_Switch1_out1;
          rd_13_reg[32'sd1:32'sd111] <= rd_13_reg[32'sd0:32'sd110];
        end
      end
    end

  assign Multiport_Switch1_out1_1 = rd_13_reg[111];

  assign T2 = (switch_compare_1_3 == 1'b0 ? Fcn2_Value_1 :
              Multiport_Switch1_out1_1);
endmodule   
