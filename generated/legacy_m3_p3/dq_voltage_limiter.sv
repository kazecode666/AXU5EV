
`timescale 1ns/1ps

module dq_voltage_limiter
          import FOC_DUT_pkg::* ;
          (  input logic clk,
             input logic reset,
             input logic enb,
             input logic enb_1_5000_1,
             input logic enb_1_5000_0,
             input logic signed [63:0] ud_raw,
             input logic signed [63:0] uq_raw,
             input logic [31:0] Vdc_V,
             output logic signed [63:0] ud_lim,
             output logic signed [63:0] uq_lim,
             output logic signed [63:0] du_d_z,
             output logic signed [63:0] du_q_z);


  vector_of_signed_logic_64 rd_16_reg [0:3];
  logic signed [63:0] ud_raw_1;
  vector_of_signed_logic_64 rd_13_reg [0:5];
  logic signed [63:0] From10_out1;
  vector_of_signed_logic_64 rd_14_reg [0:163];
  logic signed [63:0] From10_out1_1;
  logic signed [32:0] Bus_over_sqrt3_cast;
  logic signed [96:0] Bus_over_sqrt3_mul_temp;
  logic signed [95:0] Bus_over_sqrt3_out1;
  logic signed [95:0] Bus_over_sqrt3_out1_1;
  logic signed [63:0] Bus_over_sqrt3_out1_2;
  logic signed [63:0] Bus_over_sqrt3_out1_3;
  logic signed [127:0] U_max;
  logic signed [127:0] U_max_1;
  logic signed [63:0] U_max_2;
  logic Sum_out1_timer;
  logic [76:0] delayMatch_reg;
  logic Sum_out1_timer_1;
  logic signed [127:0] Math_Function_out1;
  logic [63:0] Math_Function_out1_1;
  logic [63:0] Math_Function_out1_2;
  vector_of_signed_logic_64 rd_01_reg [0:2];
  logic signed [63:0] uq_raw_1;
  logic signed [127:0] Math_Function1_out1;
  logic [63:0] Math_Function1_out1_1;
  logic [63:0] Math_Function1_out1_2;
  logic [64:0] Add_add_cast;
  logic [64:0] Add_add_cast_1;
  logic [64:0] Add_add_temp;
  logic [63:0] Add_out1;
  logic [63:0] Add_out1_1;
  logic signed [63:0] U_raw;
  logic signed [63:0] U_raw_1;
  vector_of_signed_logic_64 rd_7_reg [0:72];
  logic signed [63:0] U_max_3;
  logic signed [63:0] Sum_out1_default;
  logic signed [63:0] Constant2_out1;
  logic signed [64:0] Sum_add_cast;
  logic signed [64:0] Sum_add_cast_1;
  logic signed [64:0] Sum_add_temp;
  logic signed [63:0] Sum_out1;
  logic signed [63:0] Sum_out1_zp;
  logic [71:0] Divide_out1;
  logic [71:0] Divide_out1_1;
  logic signed [72:0] MinMax_op_stage1;
  logic signed [63:0] Constant3_out1;
  logic signed [72:0] MinMax_op_stage2;
  logic signed [72:0] MinMax_stage1_val;
  logic signed [72:0] MinMax_stage1_val_1;
  logic signed [63:0] obs_s;
  logic signed [63:0] obs_s_1;
  logic signed [127:0] obs_ud_lim;
  logic signed [127:0] obs_ud_lim_1;
  logic signed [63:0] obs_ud_lim_2;
  vector_of_signed_logic_64 rd_10_reg [0:5];
  logic signed [63:0] From12_out1;
  vector_of_signed_logic_64 rd_11_reg [0:163];
  logic signed [63:0] From12_out1_1;
  logic signed [127:0] obs_uq_lim;
  logic signed [127:0] obs_uq_lim_1;
  logic signed [63:0] obs_uq_lim_2;
  logic stateControl;
  logic stateControl_1;
  logic signed [64:0] Subtract_sub_cast;
  logic signed [64:0] Subtract_sub_cast_1;
  logic signed [64:0] Subtract_sub_temp;
  logic signed [63:0] Subtract_out1;
  logic signed [63:0] Subtract_out1_1;
  logic signed [63:0] Unit_Delay_bypass_reg;
  logic signed [63:0] Subtract_out1_2;
  logic signed [63:0] Subtract_out1_3;
  logic signed [63:0] Subtract_out1_last_value;
  logic stateControl_3;
  logic stateControl_4;
  logic signed [64:0] Subtract1_sub_cast;
  logic signed [64:0] Subtract1_sub_cast_1;
  logic signed [64:0] Subtract1_sub_temp;
  logic signed [63:0] Subtract1_out1;
  logic signed [63:0] Subtract1_out1_1;
  logic signed [63:0] Unit_Delay1_bypass_reg;
  logic signed [63:0] Subtract1_out1_2;
  logic signed [63:0] Subtract1_out1_3;
  logic signed [63:0] Subtract1_out1_last_value;


  always_ff @(posedge clk)
    begin : rd_16_process
      if (reset == 1'b1) begin
        rd_16_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_16_reg[0] <= ud_raw;
          rd_16_reg[32'sd1:32'sd3] <= rd_16_reg[32'sd0:32'sd2];
        end
      end
    end

  assign ud_raw_1 = rd_16_reg[3];
  always_ff @(posedge clk)
    begin : rd_13_process
      if (reset == 1'b1) begin
        rd_13_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_13_reg[0] <= ud_raw_1;
          rd_13_reg[32'sd1:32'sd5] <= rd_13_reg[32'sd0:32'sd4];
        end
      end
    end

  assign From10_out1 = rd_13_reg[5];

  always_ff @(posedge clk)
    begin : rd_14_process
      if (reset == 1'b1) begin
        rd_14_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_14_reg[0] <= From10_out1;
          rd_14_reg[32'sd1:32'sd163] <= rd_14_reg[32'sd0:32'sd162];
        end
      end
    end

  assign From10_out1_1 = rd_14_reg[163];

  assign Bus_over_sqrt3_cast = {1'b0, Vdc_V};
  assign Bus_over_sqrt3_mul_temp = 64'sh00000093CD3A2C82 * Bus_over_sqrt3_cast;
  assign Bus_over_sqrt3_out1 = Bus_over_sqrt3_mul_temp[95:0];
  always_ff @(posedge clk)
    begin : rd_4_process
      if (reset == 1'b1) begin
        Bus_over_sqrt3_out1_1 <= 96'sh000000000000000000000000;
      end
      else begin
        if (enb) begin
          Bus_over_sqrt3_out1_1 <= Bus_over_sqrt3_out1;
        end
      end
    end

  assign Bus_over_sqrt3_out1_2 = (((Bus_over_sqrt3_out1_1[95] == 1'b0) && (Bus_over_sqrt3_out1_1[94:87] != 8'b00000000)) || ((Bus_over_sqrt3_out1_1[95] == 1'b0) && (Bus_over_sqrt3_out1_1[87:24] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Bus_over_sqrt3_out1_1[95] == 1'b1) && (Bus_over_sqrt3_out1_1[94:87] != 8'b11111111) ? 64'sh8000000000000000 :
              $signed(Bus_over_sqrt3_out1_1[87:24]) + $signed({1'b0, Bus_over_sqrt3_out1_1[23] & (Bus_over_sqrt3_out1_1[24] | (|Bus_over_sqrt3_out1_1[22:0]))})));

  always_ff @(posedge clk)
    begin : rd_5_process
      if (reset == 1'b1) begin
        Bus_over_sqrt3_out1_3 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Bus_over_sqrt3_out1_3 <= Bus_over_sqrt3_out1_2;
        end
      end
    end

  assign U_max = 64'sh000000E666666666 * Bus_over_sqrt3_out1_3;
  always_ff @(posedge clk)
    begin : rd_6_process
      if (reset == 1'b1) begin
        U_max_1 <= 128'sh00000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          U_max_1 <= U_max;
        end
      end
    end

  assign U_max_2 = (((U_max_1[127] == 1'b0) && (U_max_1[126:103] != 24'b000000000000000000000000)) || ((U_max_1[127] == 1'b0) && (U_max_1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((U_max_1[127] == 1'b1) && (U_max_1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(U_max_1[103:40]) + $signed({1'b0, U_max_1[39] & (U_max_1[40] | (|U_max_1[38:0]))})));

  assign Sum_out1_timer = 1'b1;

  always_ff @(posedge clk)
    begin : delayMatch_process
      if (reset == 1'b1) begin
        delayMatch_reg <= '{default :1'b0};
      end
      else begin
        if (enb) begin
          delayMatch_reg[0] <= Sum_out1_timer;
          delayMatch_reg[32'sd76:32'sd1] <= delayMatch_reg[32'sd75:32'sd0];
        end
      end
    end

  assign Sum_out1_timer_1 = delayMatch_reg[76];

  assign Math_Function_out1 = ud_raw_1 * ud_raw_1;
  assign Math_Function_out1_1 = (((Math_Function_out1[127] == 1'b0) && (Math_Function_out1[126:108] != 19'b0000000000000000000)) || ((Math_Function_out1[127] == 1'b0) && (Math_Function_out1[107:44] == 64'hFFFFFFFFFFFFFFFF)) ? 64'hFFFFFFFFFFFFFFFF :
              (Math_Function_out1[127] == 1'b1 ? 64'h0000000000000000 :
              Math_Function_out1[107:44] + (Math_Function_out1[43] & (Math_Function_out1[44] | (|Math_Function_out1[42:0])))));

  always_ff @(posedge clk)
    begin : rd_0_process
      if (reset == 1'b1) begin
        Math_Function_out1_2 <= 64'h0000000000000000;
      end
      else begin
        if (enb) begin
          Math_Function_out1_2 <= Math_Function_out1_1;
        end
      end
    end

  always_ff @(posedge clk)
    begin : rd_01_process
      if (reset == 1'b1) begin
        rd_01_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_01_reg[0] <= uq_raw;
          rd_01_reg[32'sd1:32'sd2] <= rd_01_reg[32'sd0:32'sd1];
        end
      end
    end

  assign uq_raw_1 = rd_01_reg[2];
  assign Math_Function1_out1 = uq_raw_1 * uq_raw_1;
  assign Math_Function1_out1_1 = (((Math_Function1_out1[127] == 1'b0) && (Math_Function1_out1[126:108] != 19'b0000000000000000000)) || ((Math_Function1_out1[127] == 1'b0) && (Math_Function1_out1[107:44] == 64'hFFFFFFFFFFFFFFFF)) ? 64'hFFFFFFFFFFFFFFFF :
              (Math_Function1_out1[127] == 1'b1 ? 64'h0000000000000000 :
              Math_Function1_out1[107:44] + (Math_Function1_out1[43] & (Math_Function1_out1[44] | (|Math_Function1_out1[42:0])))));

  always_ff @(posedge clk)
    begin : rd_1_process
      if (reset == 1'b1) begin
        Math_Function1_out1_2 <= 64'h0000000000000000;
      end
      else begin
        if (enb) begin
          Math_Function1_out1_2 <= Math_Function1_out1_1;
        end
      end
    end

  assign Add_add_cast = {1'b0, Math_Function_out1_2};
  assign Add_add_cast_1 = {1'b0, Math_Function1_out1_2};
  assign Add_add_temp = Add_add_cast + Add_add_cast_1;
  assign Add_out1 = (Add_add_temp[64] != 1'b0 ? 64'hFFFFFFFFFFFFFFFF :
              Add_add_temp[63:0]);
  always_ff @(posedge clk)
    begin : rd_2_process
      if (reset == 1'b1) begin
        Add_out1_1 <= 64'h0000000000000000;
      end
      else begin
        if (enb) begin
          Add_out1_1 <= Add_out1;
        end
      end
    end

  Sqrt u_Sqrt (.clk(clk),
               .reset(reset),
               .enb(enb),
               .din(Add_out1_1),
               .dout(U_raw)
               );
  always_ff @(posedge clk)
    begin : rd_3_process
      if (reset == 1'b1) begin
        U_raw_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          U_raw_1 <= U_raw;
        end
      end
    end

  always_ff @(posedge clk)
    begin : rd_7_process
      if (reset == 1'b1) begin
        rd_7_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_7_reg[0] <= U_max_2;
          rd_7_reg[32'sd1:32'sd72] <= rd_7_reg[32'sd0:32'sd71];
        end
      end
    end

  assign U_max_3 = rd_7_reg[72];

  assign Sum_out1_default = 64'sh0000010000000000;

  assign Constant2_out1 = 64'sh000000000010C6F8;
  assign Sum_add_cast = {U_raw_1[63], U_raw_1};
  assign Sum_add_cast_1 = {Constant2_out1[63], Constant2_out1};
  assign Sum_add_temp = Sum_add_cast + Sum_add_cast_1;
  assign Sum_out1 = ((Sum_add_temp[64] == 1'b0) && (Sum_add_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Sum_add_temp[64] == 1'b1) && (Sum_add_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Sum_add_temp[63:0])));
  assign Sum_out1_zp = (Sum_out1_timer_1 == 1'b0 ? Sum_out1_default :
              Sum_out1);

  Divide u_Divide (.clk(clk),
                   .reset(reset),
                   .enb(enb),
                   .dividend_in(U_max_3),
                   .divisor_in(Sum_out1_zp),
                   .quotient(Divide_out1)
                   );
  always_ff @(posedge clk)
    begin : rd_8_process
      if (reset == 1'b1) begin
        Divide_out1_1 <= 72'h000000000000000000;
      end
      else begin
        if (enb) begin
          Divide_out1_1 <= Divide_out1;
        end
      end
    end

  assign MinMax_op_stage1 = {1'b0, Divide_out1_1};
  assign Constant3_out1 = 64'sh0000010000000000;
  assign MinMax_op_stage2 = {{9{Constant3_out1[63]}}, Constant3_out1};
  assign MinMax_stage1_val = (MinMax_op_stage1 <= MinMax_op_stage2 ? MinMax_op_stage1 :
              MinMax_op_stage2);
  always_ff @(posedge clk)
    begin : rd_9_process
      if (reset == 1'b1) begin
        MinMax_stage1_val_1 <= 73'sh0000000000000000000;
      end
      else begin
        if (enb) begin
          MinMax_stage1_val_1 <= MinMax_stage1_val;
        end
      end
    end

  assign obs_s = ((MinMax_stage1_val_1[72] == 1'b0) && (MinMax_stage1_val_1[71:63] != 9'b000000000) ? 64'sh7FFFFFFFFFFFFFFF :
              ((MinMax_stage1_val_1[72] == 1'b1) && (MinMax_stage1_val_1[71:63] != 9'b111111111) ? 64'sh8000000000000000 :
              $signed(MinMax_stage1_val_1[63:0])));
  assign obs_s_1 = obs_s;
  assign obs_ud_lim = From10_out1_1 * obs_s_1;
  always_ff @(posedge clk)
    begin : rd_15_process
      if (reset == 1'b1) begin
        obs_ud_lim_1 <= 128'sh00000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          obs_ud_lim_1 <= obs_ud_lim;
        end
      end
    end

  assign obs_ud_lim_2 = (((obs_ud_lim_1[127] == 1'b0) && (obs_ud_lim_1[126:103] != 24'b000000000000000000000000)) || ((obs_ud_lim_1[127] == 1'b0) && (obs_ud_lim_1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((obs_ud_lim_1[127] == 1'b1) && (obs_ud_lim_1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(obs_ud_lim_1[103:40]) + $signed({1'b0, obs_ud_lim_1[39] & (obs_ud_lim_1[40] | (|obs_ud_lim_1[38:0]))})));

  assign ud_lim = obs_ud_lim_2;

  always_ff @(posedge clk)
    begin : rd_10_process
      if (reset == 1'b1) begin
        rd_10_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_10_reg[0] <= uq_raw_1;
          rd_10_reg[32'sd1:32'sd5] <= rd_10_reg[32'sd0:32'sd4];
        end
      end
    end

  assign From12_out1 = rd_10_reg[5];

  always_ff @(posedge clk)
    begin : rd_11_process
      if (reset == 1'b1) begin
        rd_11_reg <= '{default :64'sh0000000000000000};
      end
      else begin
        if (enb) begin
          rd_11_reg[0] <= From12_out1;
          rd_11_reg[32'sd1:32'sd163] <= rd_11_reg[32'sd0:32'sd162];
        end
      end
    end

  assign From12_out1_1 = rd_11_reg[163];

  assign obs_uq_lim = obs_s_1 * From12_out1_1;
  always_ff @(posedge clk)
    begin : rd_12_process
      if (reset == 1'b1) begin
        obs_uq_lim_1 <= 128'sh00000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          obs_uq_lim_1 <= obs_uq_lim;
        end
      end
    end

  assign obs_uq_lim_2 = (((obs_uq_lim_1[127] == 1'b0) && (obs_uq_lim_1[126:103] != 24'b000000000000000000000000)) || ((obs_uq_lim_1[127] == 1'b0) && (obs_uq_lim_1[103:40] == 64'sh7FFFFFFFFFFFFFFF)) ? 64'sh7FFFFFFFFFFFFFFF :
              ((obs_uq_lim_1[127] == 1'b1) && (obs_uq_lim_1[126:103] != 24'b111111111111111111111111) ? 64'sh8000000000000000 :
              $signed(obs_uq_lim_1[103:40]) + $signed({1'b0, obs_uq_lim_1[39] & (obs_uq_lim_1[40] | (|obs_uq_lim_1[38:0]))})));

  assign uq_lim = obs_uq_lim_2;

  assign stateControl = 1'b1;

  always_ff @(posedge clk)
    begin : delayMatch2_process
      if (reset == 1'b1) begin
        stateControl_1 <= 1'b0;
      end
      else begin
        if (enb_1_5000_0) begin
          stateControl_1 <= stateControl;
        end
      end
    end

  assign Subtract_sub_cast = {From10_out1[63], From10_out1};
  assign Subtract_sub_cast_1 = {obs_ud_lim_2[63], obs_ud_lim_2};
  assign Subtract_sub_temp = Subtract_sub_cast - Subtract_sub_cast_1;
  assign Subtract_out1 = ((Subtract_sub_temp[64] == 1'b0) && (Subtract_sub_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Subtract_sub_temp[64] == 1'b1) && (Subtract_sub_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Subtract_sub_temp[63:0])));
  always_ff @(posedge clk)
    begin : crp_out_delay1_process
      if (reset == 1'b1) begin
        Subtract_out1_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Subtract_out1_1 <= Subtract_out1;
        end
      end
    end

  always_ff @(posedge clk)
    begin : Unit_Delay_bypass_process
      if (reset == 1'b1) begin
        Unit_Delay_bypass_reg <= 64'sh0000000000000000;
      end
      else begin
        if (enb_1_5000_1) begin
          Unit_Delay_bypass_reg <= Subtract_out1_1;
        end
      end
    end

  assign Subtract_out1_2 = (enb_1_5000_1 == 1'b1 ? Subtract_out1_1 :
              Unit_Delay_bypass_reg);

  always_ff @(posedge clk)
    begin : out0_bypass1_process
      if (reset == 1'b1) begin
        Subtract_out1_last_value <= 64'sh0000000000000000;
      end
      else begin
        if (enb_1_5000_0) begin
          Subtract_out1_last_value <= Subtract_out1_3;
        end
      end
    end

  assign Subtract_out1_3 = (stateControl_1 == 1'b0 ? Subtract_out1_last_value :
              Subtract_out1_2);

  assign du_d_z = Subtract_out1_3;

  assign stateControl_3 = 1'b1;

  always_ff @(posedge clk)
    begin : delayMatch1_process
      if (reset == 1'b1) begin
        stateControl_4 <= 1'b0;
      end
      else begin
        if (enb_1_5000_0) begin
          stateControl_4 <= stateControl_3;
        end
      end
    end

  assign Subtract1_sub_cast = {From12_out1[63], From12_out1};
  assign Subtract1_sub_cast_1 = {obs_uq_lim_2[63], obs_uq_lim_2};
  assign Subtract1_sub_temp = Subtract1_sub_cast - Subtract1_sub_cast_1;
  assign Subtract1_out1 = ((Subtract1_sub_temp[64] == 1'b0) && (Subtract1_sub_temp[63] != 1'b0) ? 64'sh7FFFFFFFFFFFFFFF :
              ((Subtract1_sub_temp[64] == 1'b1) && (Subtract1_sub_temp[63] != 1'b1) ? 64'sh8000000000000000 :
              $signed(Subtract1_sub_temp[63:0])));
  always_ff @(posedge clk)
    begin : crp_out_delay_process
      if (reset == 1'b1) begin
        Subtract1_out1_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          Subtract1_out1_1 <= Subtract1_out1;
        end
      end
    end

  always_ff @(posedge clk)
    begin : Unit_Delay1_bypass_process
      if (reset == 1'b1) begin
        Unit_Delay1_bypass_reg <= 64'sh0000000000000000;
      end
      else begin
        if (enb_1_5000_1) begin
          Unit_Delay1_bypass_reg <= Subtract1_out1_1;
        end
      end
    end

  assign Subtract1_out1_2 = (enb_1_5000_1 == 1'b1 ? Subtract1_out1_1 :
              Unit_Delay1_bypass_reg);

  always_ff @(posedge clk)
    begin : out0_bypass_process
      if (reset == 1'b1) begin
        Subtract1_out1_last_value <= 64'sh0000000000000000;
      end
      else begin
        if (enb_1_5000_0) begin
          Subtract1_out1_last_value <= Subtract1_out1_3;
        end
      end
    end

  assign Subtract1_out1_3 = (stateControl_4 == 1'b0 ? Subtract1_out1_last_value :
              Subtract1_out1_2);

  assign du_q_z = Subtract1_out1_3;

endmodule   
