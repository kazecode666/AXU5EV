
`timescale 1ns/1ps

module InversePark
          import FOC_DUT_pkg::* ;
          (  input logic clk,
             input logic reset,
             input logic enb,
             input logic enb_1_5000_1,
             input logic enb_1_5000_0,
             input logic signed [63:0] A,
             input logic signed [63:0] B,
             input logic signed [39:0] C,
             output logic signed [63:0] O1,
             output logic signed [63:0] O2);


  logic [15:0] Offset_out1;
  logic switch_compare_1;
  logic signed [79:0] convert_pu_out1;
  logic signed [39:0] convert_pu_out1_1;
  logic Compare_To_Zero_out1;
  logic [15:0] Data_Type_Conversion_out1;
  logic If_out1;
  logic If_out1_1;
  logic If_out2;
  logic If_out2_1;
  logic If_out2_2;
  logic signed [15:0] Convert_uint16_out1;
  logic signed [39:0] Convert_back_out1;
  logic signed [39:0] Sum_out1;
  logic signed [39:0] Sum_out1_bypass;
  logic signed [39:0] Sum_out1_last_value;
  logic signed [39:0] If_Action_Subsystem1_Out1;
  logic If_out1_2;
  logic signed [39:0] If_Action_Subsystem1_Out1_1;
  logic signed [15:0] Convert_uint16_out1_1;
  logic signed [39:0] Convert_back_out1_1;
  logic signed [39:0] Sum_out1_1;
  logic signed [39:0] Sum_out1_bypass_1;
  logic signed [39:0] Sum_out1_last_value_1;
  logic signed [39:0] If_Action_Subsystem_Out1;
  logic signed [39:0] If_Action_Subsystem_Out1_1;
  logic signed [39:0] Merge_out1;
  logic signed [39:0] Merge_out1_1;
  logic signed [39:0] Merge_delay_bypass_reg;
  logic signed [39:0] Merge_out1_2;
  logic signed [39:0] Merge_out1_prev;
  logic signed [39:0] Merge_out1_prev_1;
  logic signed [39:0] Merge_out1_next_2;
  logic signed [39:0] WrapUp_Out1;
  logic signed [79:0] indexing_out1;
  logic signed [39:0] indexing_out1_1;
  logic signed [39:0] indexing_out1_2;
  logic [15:0] Get_Integer_out1;
  vector_of_signed_logic_16 offset_out1_1 [0:3];
  logic [31:0] Sum_u;
  vector_of_unsigned_logic_32 Sum_3 [0:3];
  vector_of_unsigned_logic_32 Sum_out1_2 [0:3];
  vector_of_unsigned_logic_32 Sum_out1_3 [0:3];
  logic [31:0] Sum_out1_2_1;
  vector_of_signed_logic_40 sine_table_values_out1 [0:1001];
  logic signed [31:0] Lookup_idx;
  logic [32:0] Lookup_add_temp;
  logic [32:0] Lookup_1;
  logic signed [39:0] Lookup_out1_2;
  logic [31:0] Sum_out1_3_1;
  logic signed [31:0] Lookup_idx_1;
  logic [32:0] Lookup_add_temp_1;
  logic [32:0] Lookup_3;
  logic signed [39:0] Lookup_out1_3;
  logic signed [39:0] Sum5_out1;
  logic signed [39:0] Sum5_out1_1;
  logic signed [39:0] indexing_out1_3;
  logic signed [39:0] Data_Type_Conversion1_out1;
  logic signed [39:0] Data_Type_Conversion1_out1_1;
  logic signed [39:0] Sum2_sub_temp;
  logic signed [39:0] Sum2_out1;
  logic signed [39:0] In2;
  logic signed [79:0] Product1_out1;
  logic signed [39:0] Product1_out1_1;
  logic signed [39:0] Product1_out1_2;
  vector_of_signed_logic_40 rd_6_reg [0:1];
  logic signed [39:0] In1_3;
  logic signed [39:0] Sum6_out1;
  vector_of_signed_logic_40 rd_0_reg [0:182];
  logic signed [39:0] cos;
  logic signed [103:0] dcos_out1;
  logic [31:0] Sum_out1_0;
  logic signed [31:0] Lookup_idx_2;
  logic [32:0] Lookup_add_temp_2;
  logic [32:0] Lookup_5;
  logic signed [39:0] Lookup_out1_0;
  logic [31:0] Sum_out1_1_1;
  logic signed [31:0] Lookup_idx_3;
  logic [32:0] Lookup_add_temp_3;
  logic [32:0] Lookup_7;
  logic signed [39:0] Lookup_out1_1;
  logic signed [39:0] Sum3_out1;
  logic signed [39:0] Sum3_out1_1;
  logic signed [79:0] Product_out1;
  logic signed [39:0] Product_out1_1;
  logic signed [39:0] Product_out1_2;
  vector_of_signed_logic_40 rd_3_reg [0:1];
  logic signed [39:0] In1_1;
  logic signed [39:0] Sum4_out1;
  vector_of_signed_logic_40 rd_1_reg [0:182];
  logic signed [39:0] sin;
  logic signed [103:0] qsin_out1;
  logic signed [103:0] dcos_out1_1;
  logic signed [63:0] dcos_out1_2;
  logic signed [103:0] qsin_out1_1;
  logic signed [63:0] qsin_out1_2;
  logic signed [63:0] sum_alpha_out1;
  logic signed [63:0] A_1;
  logic signed [103:0] qcos_out1;
  logic signed [103:0] dsin_out1;
  logic signed [103:0] qcos_out1_1;
  logic signed [63:0] qcos_out1_2;
  logic signed [103:0] dsin_out1_1;
  logic signed [63:0] dsin_out1_2;
  logic signed [63:0] sum_beta_out1;
  logic signed [63:0] B_1;
  vector_of_signed_logic_64 D_axis_aligned_out1 [0:1];
  logic signed [64:0] Unary_Minus_cast;
  logic signed [64:0] Unary_Minus_cast_1;
  logic signed [63:0] Unary_Minus_out1;
  vector_of_signed_logic_64 Q_axis_aligned_out1 [0:1];
  vector_of_signed_logic_64 Switch_out1 [0:1];


  assign Offset_out1 = 16'b0000000000000000;
  assign switch_compare_1 = Offset_out1 > 16'b0000000000000001;

  assign convert_pu_out1 = 40'sh517CC1B727 * C;
  assign convert_pu_out1_1 = {convert_pu_out1[79], convert_pu_out1[79:41]};

  assign Compare_To_Zero_out1 = convert_pu_out1_1 < 40'sh0000000000;
  assign Data_Type_Conversion_out1 = {15'b0, Compare_To_Zero_out1};
  assign If_out1 = Data_Type_Conversion_out1 > 16'b0000000000000000;
  assign If_out1_1 = If_out1;

  assign If_out2 =  ~ If_out1;
  assign If_out2_1 = If_out2;

  always_ff @(posedge clk)
    begin : rd_2_process
      if (reset == 1'b1) begin
        If_out2_2 <= 1'b0;
      end
      else begin
        if (enb) begin
          If_out2_2 <= If_out2_1;
        end
      end
    end

  assign Convert_uint16_out1 = {{8{convert_pu_out1_1[39]}}, convert_pu_out1_1[39:32]};
  assign Convert_back_out1 = {Convert_uint16_out1[7:0], 32'b00000000000000000000000000000000};
  assign Sum_out1 = convert_pu_out1_1 - Convert_back_out1;
  always_ff @(posedge clk)
    begin : Out1_bypass_process
      if (reset == 1'b1) begin
        Sum_out1_last_value <= 40'sh0000000000;
      end
      else begin
        if (enb_1_5000_0) begin
          Sum_out1_last_value <= Sum_out1_bypass;
        end
      end
    end

  assign Sum_out1_bypass = (If_out2 == 1'b0 ? Sum_out1_last_value :
              Sum_out1);
  assign If_Action_Subsystem1_Out1 = Sum_out1_bypass;

  always_ff @(posedge clk)
    begin : rd_3_process
      if (reset == 1'b1) begin
        If_out1_2 <= 1'b0;
      end
      else begin
        if (enb) begin
          If_out1_2 <= If_out1_1;
        end
      end
    end

  always_ff @(posedge clk)
    begin : rd_1_process
      if (reset == 1'b1) begin
        If_Action_Subsystem1_Out1_1 <= 40'sh0000000000;
      end
      else begin
        if (enb) begin
          If_Action_Subsystem1_Out1_1 <= If_Action_Subsystem1_Out1;
        end
      end
    end

  assign Convert_uint16_out1_1 = {{8{convert_pu_out1_1[39]}}, convert_pu_out1_1[39:32]};
  assign Convert_back_out1_1 = {Convert_uint16_out1_1[7:0], 32'b00000000000000000000000000000000};
  assign Sum_out1_1 = convert_pu_out1_1 - Convert_back_out1_1;
  always_ff @(posedge clk)
    begin : Out1_bypass_1_process
      if (reset == 1'b1) begin
        Sum_out1_last_value_1 <= 40'sh0000000000;
      end
      else begin
        if (enb_1_5000_0) begin
          Sum_out1_last_value_1 <= Sum_out1_bypass_1;
        end
      end
    end

  assign Sum_out1_bypass_1 = (If_out1 == 1'b0 ? Sum_out1_last_value_1 :
              Sum_out1_1);
  assign If_Action_Subsystem_Out1 = Sum_out1_bypass_1;

  always_ff @(posedge clk)
    begin : rd_0_process
      if (reset == 1'b1) begin
        If_Action_Subsystem_Out1_1 <= 40'sh0000000000;
      end
      else begin
        if (enb) begin
          If_Action_Subsystem_Out1_1 <= If_Action_Subsystem_Out1;
        end
      end
    end

  always_ff @(posedge clk)
    begin : crp_out_delay_process
      if (reset == 1'b1) begin
        Merge_out1_1 <= 40'sh0000000000;
      end
      else begin
        if (enb) begin
          Merge_out1_1 <= Merge_out1;
        end
      end
    end

  always_ff @(posedge clk)
    begin : Merge_delay_bypass_process
      if (reset == 1'b1) begin
        Merge_delay_bypass_reg <= 40'sh0000000000;
      end
      else begin
        if (enb_1_5000_1) begin
          Merge_delay_bypass_reg <= Merge_out1_1;
        end
      end
    end

  assign Merge_out1_2 = (enb_1_5000_1 == 1'b1 ? Merge_out1_1 :
              Merge_delay_bypass_reg);

  assign Merge_out1_prev = Merge_out1_2;

  always_ff @(posedge clk)
    begin : rd_4_process
      if (reset == 1'b1) begin
        Merge_out1_prev_1 <= 40'sh0000000000;
      end
      else begin
        if (enb) begin
          Merge_out1_prev_1 <= Merge_out1_prev;
        end
      end
    end

  assign Merge_out1_next_2 = (If_out2_2 == 1'b0 ? Merge_out1_prev_1 :
              If_Action_Subsystem1_Out1_1);
  assign Merge_out1 = (If_out1_2 == 1'b0 ? Merge_out1_next_2 :
              If_Action_Subsystem_Out1_1);
  always_ff @(posedge clk)
    begin : rd_0_1_process
      if (reset == 1'b1) begin
        WrapUp_Out1 <= 40'sh0000000000;
      end
      else begin
        if (enb) begin
          WrapUp_Out1 <= Merge_out1;
        end
      end
    end

  assign indexing_out1 = 40'sh6400000000 * WrapUp_Out1;
  assign indexing_out1_1 = indexing_out1[71:32];

  always_ff @(posedge clk)
    begin : rd_1_1_process
      if (reset == 1'b1) begin
        indexing_out1_2 <= 40'sh0000000000;
      end
      else begin
        if (enb) begin
          indexing_out1_2 <= indexing_out1_1;
        end
      end
    end

  assign Get_Integer_out1 = {{5{indexing_out1_2[39]}}, indexing_out1_2[39:29]};
  assign offset_out1_1[0] = 16'sb0000000000000001;
  assign offset_out1_1[1] = 16'sb0000000000000000;
  assign offset_out1_1[2] = 16'sb0000000011001001;
  assign offset_out1_1[3] = 16'sb0000000011001000;
  assign Sum_u = {16'b0, Get_Integer_out1};

  genvar t_0;
  generate
    for(t_0 = 32'sd0; t_0 <= 32'sd3; t_0 = t_0 + 32'sd1) begin:Sum_out1_2_gen
      assign Sum_3[t_0] = {{16{offset_out1_1[t_0][15]}}, offset_out1_1[t_0]};
      assign Sum_out1_2[t_0] = Sum_u + Sum_3[t_0];
    end
  endgenerate
  always_ff @(posedge clk)
    begin : rd_2_1_process
      if (reset == 1'b1) begin
        Sum_out1_3 <= '{default :32'b00000000000000000000000000000000};
      end
      else begin
        if (enb) begin
          Sum_out1_3 <= Sum_out1_2;
        end
      end
    end

  assign Sum_out1_2_1 = Sum_out1_3[2];

  assign sine_table_values_out1[0] = 40'sh0000000000;
  assign sine_table_values_out1[1] = 40'sh000202B697;
  assign sine_table_values_out1[2] = 40'sh000405650E;
  assign sine_table_values_out1[3] = 40'sh0006080343;
  assign sine_table_values_out1[4] = 40'sh00080A8917;
  assign sine_table_values_out1[5] = 40'sh000A0CEE69;
  assign sine_table_values_out1[6] = 40'sh000C0F2B19;
  assign sine_table_values_out1[7] = 40'sh000E11370A;
  assign sine_table_values_out1[8] = 40'sh0010130A1C;
  assign sine_table_values_out1[9] = 40'sh0012149C33;
  assign sine_table_values_out1[10] = 40'sh001415E532;
  assign sine_table_values_out1[11] = 40'sh001616DCFF;
  assign sine_table_values_out1[12] = 40'sh0018177B80;
  assign sine_table_values_out1[13] = 40'sh001A17B89C;
  assign sine_table_values_out1[14] = 40'sh001C178C3D;
  assign sine_table_values_out1[15] = 40'sh001E16EE4E;
  assign sine_table_values_out1[16] = 40'sh002015D6BB;
  assign sine_table_values_out1[17] = 40'sh0022143D73;
  assign sine_table_values_out1[18] = 40'sh0024121A67;
  assign sine_table_values_out1[19] = 40'sh00260F6589;
  assign sine_table_values_out1[20] = 40'sh00280C16CF;
  assign sine_table_values_out1[21] = 40'sh002A082630;
  assign sine_table_values_out1[22] = 40'sh002C038BA7;
  assign sine_table_values_out1[23] = 40'sh002DFE3F30;
  assign sine_table_values_out1[24] = 40'sh002FF838CA;
  assign sine_table_values_out1[25] = 40'sh0031F17079;
  assign sine_table_values_out1[26] = 40'sh0033E9DE42;
  assign sine_table_values_out1[27] = 40'sh0035E17A2D;
  assign sine_table_values_out1[28] = 40'sh0037D83C48;
  assign sine_table_values_out1[29] = 40'sh0039CE1CA1;
  assign sine_table_values_out1[30] = 40'sh003BC3134B;
  assign sine_table_values_out1[31] = 40'sh003DB7185E;
  assign sine_table_values_out1[32] = 40'sh003FAA23F4;
  assign sine_table_values_out1[33] = 40'sh00419C2E2C;
  assign sine_table_values_out1[34] = 40'sh00438D2F28;
  assign sine_table_values_out1[35] = 40'sh00457D1F0F;
  assign sine_table_values_out1[36] = 40'sh00476BF60C;
  assign sine_table_values_out1[37] = 40'sh004959AC4F;
  assign sine_table_values_out1[38] = 40'sh004B463A0D;
  assign sine_table_values_out1[39] = 40'sh004D31977C;
  assign sine_table_values_out1[40] = 40'sh004F1BBCDD;
  assign sine_table_values_out1[41] = 40'sh005104A270;
  assign sine_table_values_out1[42] = 40'sh0052EC407E;
  assign sine_table_values_out1[43] = 40'sh0054D28F53;
  assign sine_table_values_out1[44] = 40'sh0056B78741;
  assign sine_table_values_out1[45] = 40'sh00589B20A1;
  assign sine_table_values_out1[46] = 40'sh005A7D53CE;
  assign sine_table_values_out1[47] = 40'sh005C5E192C;
  assign sine_table_values_out1[48] = 40'sh005E3D6923;
  assign sine_table_values_out1[49] = 40'sh00601B3C21;
  assign sine_table_values_out1[50] = 40'sh0061F78A9B;
  assign sine_table_values_out1[51] = 40'sh0063D24D0B;
  assign sine_table_values_out1[52] = 40'sh0065AB7BF2;
  assign sine_table_values_out1[53] = 40'sh0067830FD7;
  assign sine_table_values_out1[54] = 40'sh0069590148;
  assign sine_table_values_out1[55] = 40'sh006B2D48D9;
  assign sine_table_values_out1[56] = 40'sh006CFFDF25;
  assign sine_table_values_out1[57] = 40'sh006ED0BCCD;
  assign sine_table_values_out1[58] = 40'sh00709FDA7B;
  assign sine_table_values_out1[59] = 40'sh00726D30DE;
  assign sine_table_values_out1[60] = 40'sh007438B8AD;
  assign sine_table_values_out1[61] = 40'sh0076026AA7;
  assign sine_table_values_out1[62] = 40'sh0077CA3F91;
  assign sine_table_values_out1[63] = 40'sh0079903039;
  assign sine_table_values_out1[64] = 40'sh007B543573;
  assign sine_table_values_out1[65] = 40'sh007D16481C;
  assign sine_table_values_out1[66] = 40'sh007ED66119;
  assign sine_table_values_out1[67] = 40'sh0080947957;
  assign sine_table_values_out1[68] = 40'sh00825089C9;
  assign sine_table_values_out1[69] = 40'sh00840A8B6D;
  assign sine_table_values_out1[70] = 40'sh0085C27748;
  assign sine_table_values_out1[71] = 40'sh0087784667;
  assign sine_table_values_out1[72] = 40'sh00892BF1E1;
  assign sine_table_values_out1[73] = 40'sh008ADD72D4;
  assign sine_table_values_out1[74] = 40'sh008C8CC268;
  assign sine_table_values_out1[75] = 40'sh008E39D9CD;
  assign sine_table_values_out1[76] = 40'sh008FE4B23E;
  assign sine_table_values_out1[77] = 40'sh00918D44FB;
  assign sine_table_values_out1[78] = 40'sh0093338B51;
  assign sine_table_values_out1[79] = 40'sh0094D77E94;
  assign sine_table_values_out1[80] = 40'sh0096791824;
  assign sine_table_values_out1[81] = 40'sh0098185167;
  assign sine_table_values_out1[82] = 40'sh0099B523D0;
  assign sine_table_values_out1[83] = 40'sh009B4F88D9;
  assign sine_table_values_out1[84] = 40'sh009CE77A07;
  assign sine_table_values_out1[85] = 40'sh009E7CF0E9;
  assign sine_table_values_out1[86] = 40'sh00A00FE719;
  assign sine_table_values_out1[87] = 40'sh00A1A05639;
  assign sine_table_values_out1[88] = 40'sh00A32E37F6;
  assign sine_table_values_out1[89] = 40'sh00A4B98607;
  assign sine_table_values_out1[90] = 40'sh00A6423A30;
  assign sine_table_values_out1[91] = 40'sh00A7C84E3C;
  assign sine_table_values_out1[92] = 40'sh00A94BBC02;
  assign sine_table_values_out1[93] = 40'sh00AACC7D64;
  assign sine_table_values_out1[94] = 40'sh00AC4A8C4F;
  assign sine_table_values_out1[95] = 40'sh00ADC5E2BB;
  assign sine_table_values_out1[96] = 40'sh00AF3E7AA9;
  assign sine_table_values_out1[97] = 40'sh00B0B44E27;
  assign sine_table_values_out1[98] = 40'sh00B227574E;
  assign sine_table_values_out1[99] = 40'sh00B3979043;
  assign sine_table_values_out1[100] = 40'sh00B504F334;
  assign sine_table_values_out1[101] = 40'sh00B66F7A5D;
  assign sine_table_values_out1[102] = 40'sh00B7D72003;
  assign sine_table_values_out1[103] = 40'sh00B93BDE7A;
  assign sine_table_values_out1[104] = 40'sh00BA9DB01F;
  assign sine_table_values_out1[105] = 40'sh00BBFC8F5B;
  assign sine_table_values_out1[106] = 40'sh00BD5876A4;
  assign sine_table_values_out1[107] = 40'sh00BEB1607C;
  assign sine_table_values_out1[108] = 40'sh00C0074770;
  assign sine_table_values_out1[109] = 40'sh00C15A261B;
  assign sine_table_values_out1[110] = 40'sh00C2A9F722;
  assign sine_table_values_out1[111] = 40'sh00C3F6B538;
  assign sine_table_values_out1[112] = 40'sh00C5405B1B;
  assign sine_table_values_out1[113] = 40'sh00C686E397;
  assign sine_table_values_out1[114] = 40'sh00C7CA4984;
  assign sine_table_values_out1[115] = 40'sh00C90A87C7;
  assign sine_table_values_out1[116] = 40'sh00CA479951;
  assign sine_table_values_out1[117] = 40'sh00CB817920;
  assign sine_table_values_out1[118] = 40'sh00CCB8223F;
  assign sine_table_values_out1[119] = 40'sh00CDEB8FC7;
  assign sine_table_values_out1[120] = 40'sh00CF1BBCDD;
  assign sine_table_values_out1[121] = 40'sh00D048A4B2;
  assign sine_table_values_out1[122] = 40'sh00D1724288;
  assign sine_table_values_out1[123] = 40'sh00D29891A9;
  assign sine_table_values_out1[124] = 40'sh00D3BB8D72;
  assign sine_table_values_out1[125] = 40'sh00D4DB3148;
  assign sine_table_values_out1[126] = 40'sh00D5F778A3;
  assign sine_table_values_out1[127] = 40'sh00D7105F04;
  assign sine_table_values_out1[128] = 40'sh00D825DFFB;
  assign sine_table_values_out1[129] = 40'sh00D937F728;
  assign sine_table_values_out1[130] = 40'sh00DA46A035;
  assign sine_table_values_out1[131] = 40'sh00DB51D6DD;
  assign sine_table_values_out1[132] = 40'sh00DC5996E8;
  assign sine_table_values_out1[133] = 40'sh00DD5DDC2B;
  assign sine_table_values_out1[134] = 40'sh00DE5EA28B;
  assign sine_table_values_out1[135] = 40'sh00DF5BE5F8;
  assign sine_table_values_out1[136] = 40'sh00E055A274;
  assign sine_table_values_out1[137] = 40'sh00E14BD40D;
  assign sine_table_values_out1[138] = 40'sh00E23E76DF;
  assign sine_table_values_out1[139] = 40'sh00E32D8715;
  assign sine_table_values_out1[140] = 40'sh00E41900EA;
  assign sine_table_values_out1[141] = 40'sh00E500E0A5;
  assign sine_table_values_out1[142] = 40'sh00E5E5229D;
  assign sine_table_values_out1[143] = 40'sh00E6C5C337;
  assign sine_table_values_out1[144] = 40'sh00E7A2BEE7;
  assign sine_table_values_out1[145] = 40'sh00E87C1230;
  assign sine_table_values_out1[146] = 40'sh00E951B9A3;
  assign sine_table_values_out1[147] = 40'sh00EA23B1E0;
  assign sine_table_values_out1[148] = 40'sh00EAF1F797;
  assign sine_table_values_out1[149] = 40'sh00EBBC8786;
  assign sine_table_values_out1[150] = 40'sh00EC835E7A;
  assign sine_table_values_out1[151] = 40'sh00ED46794E;
  assign sine_table_values_out1[152] = 40'sh00EE05D4EF;
  assign sine_table_values_out1[153] = 40'sh00EEC16E57;
  assign sine_table_values_out1[154] = 40'sh00EF794290;
  assign sine_table_values_out1[155] = 40'sh00F02D4EB1;
  assign sine_table_values_out1[156] = 40'sh00F0DD8FE4;
  assign sine_table_values_out1[157] = 40'sh00F18A0360;
  assign sine_table_values_out1[158] = 40'sh00F232A66B;
  assign sine_table_values_out1[159] = 40'sh00F2D7765D;
  assign sine_table_values_out1[160] = 40'sh00F378709A;
  assign sine_table_values_out1[161] = 40'sh00F4159298;
  assign sine_table_values_out1[162] = 40'sh00F4AED9DC;
  assign sine_table_values_out1[163] = 40'sh00F54443FA;
  assign sine_table_values_out1[164] = 40'sh00F5D5CE97;
  assign sine_table_values_out1[165] = 40'sh00F6637764;
  assign sine_table_values_out1[166] = 40'sh00F6ED3C27;
  assign sine_table_values_out1[167] = 40'sh00F7731AB2;
  assign sine_table_values_out1[168] = 40'sh00F7F510E9;
  assign sine_table_values_out1[169] = 40'sh00F8731CBC;
  assign sine_table_values_out1[170] = 40'sh00F8ED3C30;
  assign sine_table_values_out1[171] = 40'sh00F9636D56;
  assign sine_table_values_out1[172] = 40'sh00F9D5AE50;
  assign sine_table_values_out1[173] = 40'sh00FA43FD51;
  assign sine_table_values_out1[174] = 40'sh00FAAE589B;
  assign sine_table_values_out1[175] = 40'sh00FB14BE80;
  assign sine_table_values_out1[176] = 40'sh00FB772D61;
  assign sine_table_values_out1[177] = 40'sh00FBD5A3B1;
  assign sine_table_values_out1[178] = 40'sh00FC301FF3;
  assign sine_table_values_out1[179] = 40'sh00FC86A0B7;
  assign sine_table_values_out1[180] = 40'sh00FCD924A1;
  assign sine_table_values_out1[181] = 40'sh00FD27AA64;
  assign sine_table_values_out1[182] = 40'sh00FD7230C0;
  assign sine_table_values_out1[183] = 40'sh00FDB8B68A;
  assign sine_table_values_out1[184] = 40'sh00FDFB3AA4;
  assign sine_table_values_out1[185] = 40'sh00FE39BC01;
  assign sine_table_values_out1[186] = 40'sh00FE7439A5;
  assign sine_table_values_out1[187] = 40'sh00FEAAB2A3;
  assign sine_table_values_out1[188] = 40'sh00FEDD261F;
  assign sine_table_values_out1[189] = 40'sh00FF0B934D;
  assign sine_table_values_out1[190] = 40'sh00FF35F971;
  assign sine_table_values_out1[191] = 40'sh00FF5C57E0;
  assign sine_table_values_out1[192] = 40'sh00FF7EADFF;
  assign sine_table_values_out1[193] = 40'sh00FF9CFB43;
  assign sine_table_values_out1[194] = 40'sh00FFB73F31;
  assign sine_table_values_out1[195] = 40'sh00FFCD7960;
  assign sine_table_values_out1[196] = 40'sh00FFDFA975;
  assign sine_table_values_out1[197] = 40'sh00FFEDCF27;
  assign sine_table_values_out1[198] = 40'sh00FFF7EA3D;
  assign sine_table_values_out1[199] = 40'sh00FFFDFA8D;
  assign sine_table_values_out1[200] = 40'sh0100000000;
  assign sine_table_values_out1[201] = 40'sh00FFFDFA8D;
  assign sine_table_values_out1[202] = 40'sh00FFF7EA3D;
  assign sine_table_values_out1[203] = 40'sh00FFEDCF27;
  assign sine_table_values_out1[204] = 40'sh00FFDFA975;
  assign sine_table_values_out1[205] = 40'sh00FFCD7960;
  assign sine_table_values_out1[206] = 40'sh00FFB73F31;
  assign sine_table_values_out1[207] = 40'sh00FF9CFB43;
  assign sine_table_values_out1[208] = 40'sh00FF7EADFF;
  assign sine_table_values_out1[209] = 40'sh00FF5C57E0;
  assign sine_table_values_out1[210] = 40'sh00FF35F971;
  assign sine_table_values_out1[211] = 40'sh00FF0B934D;
  assign sine_table_values_out1[212] = 40'sh00FEDD261F;
  assign sine_table_values_out1[213] = 40'sh00FEAAB2A3;
  assign sine_table_values_out1[214] = 40'sh00FE7439A5;
  assign sine_table_values_out1[215] = 40'sh00FE39BC01;
  assign sine_table_values_out1[216] = 40'sh00FDFB3AA4;
  assign sine_table_values_out1[217] = 40'sh00FDB8B68A;
  assign sine_table_values_out1[218] = 40'sh00FD7230C0;
  assign sine_table_values_out1[219] = 40'sh00FD27AA64;
  assign sine_table_values_out1[220] = 40'sh00FCD924A1;
  assign sine_table_values_out1[221] = 40'sh00FC86A0B7;
  assign sine_table_values_out1[222] = 40'sh00FC301FF3;
  assign sine_table_values_out1[223] = 40'sh00FBD5A3B1;
  assign sine_table_values_out1[224] = 40'sh00FB772D61;
  assign sine_table_values_out1[225] = 40'sh00FB14BE80;
  assign sine_table_values_out1[226] = 40'sh00FAAE589B;
  assign sine_table_values_out1[227] = 40'sh00FA43FD51;
  assign sine_table_values_out1[228] = 40'sh00F9D5AE50;
  assign sine_table_values_out1[229] = 40'sh00F9636D56;
  assign sine_table_values_out1[230] = 40'sh00F8ED3C30;
  assign sine_table_values_out1[231] = 40'sh00F8731CBC;
  assign sine_table_values_out1[232] = 40'sh00F7F510E9;
  assign sine_table_values_out1[233] = 40'sh00F7731AB2;
  assign sine_table_values_out1[234] = 40'sh00F6ED3C27;
  assign sine_table_values_out1[235] = 40'sh00F6637764;
  assign sine_table_values_out1[236] = 40'sh00F5D5CE97;
  assign sine_table_values_out1[237] = 40'sh00F54443FA;
  assign sine_table_values_out1[238] = 40'sh00F4AED9DC;
  assign sine_table_values_out1[239] = 40'sh00F4159298;
  assign sine_table_values_out1[240] = 40'sh00F378709A;
  assign sine_table_values_out1[241] = 40'sh00F2D7765D;
  assign sine_table_values_out1[242] = 40'sh00F232A66B;
  assign sine_table_values_out1[243] = 40'sh00F18A0360;
  assign sine_table_values_out1[244] = 40'sh00F0DD8FE4;
  assign sine_table_values_out1[245] = 40'sh00F02D4EB1;
  assign sine_table_values_out1[246] = 40'sh00EF794290;
  assign sine_table_values_out1[247] = 40'sh00EEC16E57;
  assign sine_table_values_out1[248] = 40'sh00EE05D4EF;
  assign sine_table_values_out1[249] = 40'sh00ED46794E;
  assign sine_table_values_out1[250] = 40'sh00EC835E7A;
  assign sine_table_values_out1[251] = 40'sh00EBBC8786;
  assign sine_table_values_out1[252] = 40'sh00EAF1F797;
  assign sine_table_values_out1[253] = 40'sh00EA23B1E0;
  assign sine_table_values_out1[254] = 40'sh00E951B9A3;
  assign sine_table_values_out1[255] = 40'sh00E87C1230;
  assign sine_table_values_out1[256] = 40'sh00E7A2BEE7;
  assign sine_table_values_out1[257] = 40'sh00E6C5C337;
  assign sine_table_values_out1[258] = 40'sh00E5E5229D;
  assign sine_table_values_out1[259] = 40'sh00E500E0A5;
  assign sine_table_values_out1[260] = 40'sh00E41900EA;
  assign sine_table_values_out1[261] = 40'sh00E32D8715;
  assign sine_table_values_out1[262] = 40'sh00E23E76DF;
  assign sine_table_values_out1[263] = 40'sh00E14BD40D;
  assign sine_table_values_out1[264] = 40'sh00E055A274;
  assign sine_table_values_out1[265] = 40'sh00DF5BE5F8;
  assign sine_table_values_out1[266] = 40'sh00DE5EA28B;
  assign sine_table_values_out1[267] = 40'sh00DD5DDC2B;
  assign sine_table_values_out1[268] = 40'sh00DC5996E8;
  assign sine_table_values_out1[269] = 40'sh00DB51D6DD;
  assign sine_table_values_out1[270] = 40'sh00DA46A035;
  assign sine_table_values_out1[271] = 40'sh00D937F728;
  assign sine_table_values_out1[272] = 40'sh00D825DFFB;
  assign sine_table_values_out1[273] = 40'sh00D7105F04;
  assign sine_table_values_out1[274] = 40'sh00D5F778A3;
  assign sine_table_values_out1[275] = 40'sh00D4DB3148;
  assign sine_table_values_out1[276] = 40'sh00D3BB8D72;
  assign sine_table_values_out1[277] = 40'sh00D29891A9;
  assign sine_table_values_out1[278] = 40'sh00D1724288;
  assign sine_table_values_out1[279] = 40'sh00D048A4B2;
  assign sine_table_values_out1[280] = 40'sh00CF1BBCDD;
  assign sine_table_values_out1[281] = 40'sh00CDEB8FC7;
  assign sine_table_values_out1[282] = 40'sh00CCB8223F;
  assign sine_table_values_out1[283] = 40'sh00CB817920;
  assign sine_table_values_out1[284] = 40'sh00CA479951;
  assign sine_table_values_out1[285] = 40'sh00C90A87C7;
  assign sine_table_values_out1[286] = 40'sh00C7CA4984;
  assign sine_table_values_out1[287] = 40'sh00C686E397;
  assign sine_table_values_out1[288] = 40'sh00C5405B1B;
  assign sine_table_values_out1[289] = 40'sh00C3F6B538;
  assign sine_table_values_out1[290] = 40'sh00C2A9F722;
  assign sine_table_values_out1[291] = 40'sh00C15A261B;
  assign sine_table_values_out1[292] = 40'sh00C0074770;
  assign sine_table_values_out1[293] = 40'sh00BEB1607C;
  assign sine_table_values_out1[294] = 40'sh00BD5876A4;
  assign sine_table_values_out1[295] = 40'sh00BBFC8F5B;
  assign sine_table_values_out1[296] = 40'sh00BA9DB01F;
  assign sine_table_values_out1[297] = 40'sh00B93BDE7A;
  assign sine_table_values_out1[298] = 40'sh00B7D72003;
  assign sine_table_values_out1[299] = 40'sh00B66F7A5D;
  assign sine_table_values_out1[300] = 40'sh00B504F334;
  assign sine_table_values_out1[301] = 40'sh00B3979043;
  assign sine_table_values_out1[302] = 40'sh00B227574E;
  assign sine_table_values_out1[303] = 40'sh00B0B44E27;
  assign sine_table_values_out1[304] = 40'sh00AF3E7AA9;
  assign sine_table_values_out1[305] = 40'sh00ADC5E2BB;
  assign sine_table_values_out1[306] = 40'sh00AC4A8C4F;
  assign sine_table_values_out1[307] = 40'sh00AACC7D64;
  assign sine_table_values_out1[308] = 40'sh00A94BBC02;
  assign sine_table_values_out1[309] = 40'sh00A7C84E3C;
  assign sine_table_values_out1[310] = 40'sh00A6423A30;
  assign sine_table_values_out1[311] = 40'sh00A4B98607;
  assign sine_table_values_out1[312] = 40'sh00A32E37F6;
  assign sine_table_values_out1[313] = 40'sh00A1A05639;
  assign sine_table_values_out1[314] = 40'sh00A00FE719;
  assign sine_table_values_out1[315] = 40'sh009E7CF0E9;
  assign sine_table_values_out1[316] = 40'sh009CE77A07;
  assign sine_table_values_out1[317] = 40'sh009B4F88D9;
  assign sine_table_values_out1[318] = 40'sh0099B523D0;
  assign sine_table_values_out1[319] = 40'sh0098185167;
  assign sine_table_values_out1[320] = 40'sh0096791824;
  assign sine_table_values_out1[321] = 40'sh0094D77E94;
  assign sine_table_values_out1[322] = 40'sh0093338B51;
  assign sine_table_values_out1[323] = 40'sh00918D44FB;
  assign sine_table_values_out1[324] = 40'sh008FE4B23E;
  assign sine_table_values_out1[325] = 40'sh008E39D9CD;
  assign sine_table_values_out1[326] = 40'sh008C8CC268;
  assign sine_table_values_out1[327] = 40'sh008ADD72D4;
  assign sine_table_values_out1[328] = 40'sh00892BF1E1;
  assign sine_table_values_out1[329] = 40'sh0087784667;
  assign sine_table_values_out1[330] = 40'sh0085C27748;
  assign sine_table_values_out1[331] = 40'sh00840A8B6D;
  assign sine_table_values_out1[332] = 40'sh00825089C9;
  assign sine_table_values_out1[333] = 40'sh0080947957;
  assign sine_table_values_out1[334] = 40'sh007ED66119;
  assign sine_table_values_out1[335] = 40'sh007D16481C;
  assign sine_table_values_out1[336] = 40'sh007B543573;
  assign sine_table_values_out1[337] = 40'sh0079903039;
  assign sine_table_values_out1[338] = 40'sh0077CA3F91;
  assign sine_table_values_out1[339] = 40'sh0076026AA7;
  assign sine_table_values_out1[340] = 40'sh007438B8AD;
  assign sine_table_values_out1[341] = 40'sh00726D30DE;
  assign sine_table_values_out1[342] = 40'sh00709FDA7B;
  assign sine_table_values_out1[343] = 40'sh006ED0BCCD;
  assign sine_table_values_out1[344] = 40'sh006CFFDF25;
  assign sine_table_values_out1[345] = 40'sh006B2D48D9;
  assign sine_table_values_out1[346] = 40'sh0069590148;
  assign sine_table_values_out1[347] = 40'sh0067830FD7;
  assign sine_table_values_out1[348] = 40'sh0065AB7BF2;
  assign sine_table_values_out1[349] = 40'sh0063D24D0B;
  assign sine_table_values_out1[350] = 40'sh0061F78A9B;
  assign sine_table_values_out1[351] = 40'sh00601B3C21;
  assign sine_table_values_out1[352] = 40'sh005E3D6923;
  assign sine_table_values_out1[353] = 40'sh005C5E192C;
  assign sine_table_values_out1[354] = 40'sh005A7D53CE;
  assign sine_table_values_out1[355] = 40'sh00589B20A1;
  assign sine_table_values_out1[356] = 40'sh0056B78741;
  assign sine_table_values_out1[357] = 40'sh0054D28F53;
  assign sine_table_values_out1[358] = 40'sh0052EC407E;
  assign sine_table_values_out1[359] = 40'sh005104A270;
  assign sine_table_values_out1[360] = 40'sh004F1BBCDD;
  assign sine_table_values_out1[361] = 40'sh004D31977C;
  assign sine_table_values_out1[362] = 40'sh004B463A0D;
  assign sine_table_values_out1[363] = 40'sh004959AC4F;
  assign sine_table_values_out1[364] = 40'sh00476BF60C;
  assign sine_table_values_out1[365] = 40'sh00457D1F0F;
  assign sine_table_values_out1[366] = 40'sh00438D2F28;
  assign sine_table_values_out1[367] = 40'sh00419C2E2C;
  assign sine_table_values_out1[368] = 40'sh003FAA23F4;
  assign sine_table_values_out1[369] = 40'sh003DB7185E;
  assign sine_table_values_out1[370] = 40'sh003BC3134B;
  assign sine_table_values_out1[371] = 40'sh0039CE1CA1;
  assign sine_table_values_out1[372] = 40'sh0037D83C48;
  assign sine_table_values_out1[373] = 40'sh0035E17A2D;
  assign sine_table_values_out1[374] = 40'sh0033E9DE42;
  assign sine_table_values_out1[375] = 40'sh0031F17079;
  assign sine_table_values_out1[376] = 40'sh002FF838CA;
  assign sine_table_values_out1[377] = 40'sh002DFE3F30;
  assign sine_table_values_out1[378] = 40'sh002C038BA7;
  assign sine_table_values_out1[379] = 40'sh002A082630;
  assign sine_table_values_out1[380] = 40'sh00280C16CF;
  assign sine_table_values_out1[381] = 40'sh00260F6589;
  assign sine_table_values_out1[382] = 40'sh0024121A67;
  assign sine_table_values_out1[383] = 40'sh0022143D73;
  assign sine_table_values_out1[384] = 40'sh002015D6BB;
  assign sine_table_values_out1[385] = 40'sh001E16EE4E;
  assign sine_table_values_out1[386] = 40'sh001C178C3D;
  assign sine_table_values_out1[387] = 40'sh001A17B89C;
  assign sine_table_values_out1[388] = 40'sh0018177B80;
  assign sine_table_values_out1[389] = 40'sh001616DCFF;
  assign sine_table_values_out1[390] = 40'sh001415E532;
  assign sine_table_values_out1[391] = 40'sh0012149C33;
  assign sine_table_values_out1[392] = 40'sh0010130A1C;
  assign sine_table_values_out1[393] = 40'sh000E11370A;
  assign sine_table_values_out1[394] = 40'sh000C0F2B19;
  assign sine_table_values_out1[395] = 40'sh000A0CEE69;
  assign sine_table_values_out1[396] = 40'sh00080A8917;
  assign sine_table_values_out1[397] = 40'sh0006080343;
  assign sine_table_values_out1[398] = 40'sh000405650E;
  assign sine_table_values_out1[399] = 40'sh000202B697;
  assign sine_table_values_out1[400] = 40'sh0000000000;
  assign sine_table_values_out1[401] = 40'shFFFDFD4969;
  assign sine_table_values_out1[402] = 40'shFFFBFA9AF2;
  assign sine_table_values_out1[403] = 40'shFFF9F7FCBD;
  assign sine_table_values_out1[404] = 40'shFFF7F576E9;
  assign sine_table_values_out1[405] = 40'shFFF5F31197;
  assign sine_table_values_out1[406] = 40'shFFF3F0D4E7;
  assign sine_table_values_out1[407] = 40'shFFF1EEC8F6;
  assign sine_table_values_out1[408] = 40'shFFEFECF5E4;
  assign sine_table_values_out1[409] = 40'shFFEDEB63CD;
  assign sine_table_values_out1[410] = 40'shFFEBEA1ACE;
  assign sine_table_values_out1[411] = 40'shFFE9E92301;
  assign sine_table_values_out1[412] = 40'shFFE7E88480;
  assign sine_table_values_out1[413] = 40'shFFE5E84764;
  assign sine_table_values_out1[414] = 40'shFFE3E873C3;
  assign sine_table_values_out1[415] = 40'shFFE1E911B2;
  assign sine_table_values_out1[416] = 40'shFFDFEA2945;
  assign sine_table_values_out1[417] = 40'shFFDDEBC28D;
  assign sine_table_values_out1[418] = 40'shFFDBEDE599;
  assign sine_table_values_out1[419] = 40'shFFD9F09A77;
  assign sine_table_values_out1[420] = 40'shFFD7F3E931;
  assign sine_table_values_out1[421] = 40'shFFD5F7D9D0;
  assign sine_table_values_out1[422] = 40'shFFD3FC7459;
  assign sine_table_values_out1[423] = 40'shFFD201C0D0;
  assign sine_table_values_out1[424] = 40'shFFD007C736;
  assign sine_table_values_out1[425] = 40'shFFCE0E8F87;
  assign sine_table_values_out1[426] = 40'shFFCC1621BE;
  assign sine_table_values_out1[427] = 40'shFFCA1E85D3;
  assign sine_table_values_out1[428] = 40'shFFC827C3B8;
  assign sine_table_values_out1[429] = 40'shFFC631E35F;
  assign sine_table_values_out1[430] = 40'shFFC43CECB5;
  assign sine_table_values_out1[431] = 40'shFFC248E7A2;
  assign sine_table_values_out1[432] = 40'shFFC055DC0C;
  assign sine_table_values_out1[433] = 40'shFFBE63D1D4;
  assign sine_table_values_out1[434] = 40'shFFBC72D0D8;
  assign sine_table_values_out1[435] = 40'shFFBA82E0F1;
  assign sine_table_values_out1[436] = 40'shFFB89409F4;
  assign sine_table_values_out1[437] = 40'shFFB6A653B1;
  assign sine_table_values_out1[438] = 40'shFFB4B9C5F3;
  assign sine_table_values_out1[439] = 40'shFFB2CE6884;
  assign sine_table_values_out1[440] = 40'shFFB0E44323;
  assign sine_table_values_out1[441] = 40'shFFAEFB5D90;
  assign sine_table_values_out1[442] = 40'shFFAD13BF82;
  assign sine_table_values_out1[443] = 40'shFFAB2D70AD;
  assign sine_table_values_out1[444] = 40'shFFA94878BF;
  assign sine_table_values_out1[445] = 40'shFFA764DF5F;
  assign sine_table_values_out1[446] = 40'shFFA582AC32;
  assign sine_table_values_out1[447] = 40'shFFA3A1E6D4;
  assign sine_table_values_out1[448] = 40'shFFA1C296DD;
  assign sine_table_values_out1[449] = 40'shFF9FE4C3DF;
  assign sine_table_values_out1[450] = 40'shFF9E087565;
  assign sine_table_values_out1[451] = 40'shFF9C2DB2F5;
  assign sine_table_values_out1[452] = 40'shFF9A54840E;
  assign sine_table_values_out1[453] = 40'shFF987CF029;
  assign sine_table_values_out1[454] = 40'shFF96A6FEB8;
  assign sine_table_values_out1[455] = 40'shFF94D2B727;
  assign sine_table_values_out1[456] = 40'shFF930020DB;
  assign sine_table_values_out1[457] = 40'shFF912F4333;
  assign sine_table_values_out1[458] = 40'shFF8F602585;
  assign sine_table_values_out1[459] = 40'shFF8D92CF22;
  assign sine_table_values_out1[460] = 40'shFF8BC74753;
  assign sine_table_values_out1[461] = 40'shFF89FD9559;
  assign sine_table_values_out1[462] = 40'shFF8835C06F;
  assign sine_table_values_out1[463] = 40'shFF866FCFC7;
  assign sine_table_values_out1[464] = 40'shFF84ABCA8D;
  assign sine_table_values_out1[465] = 40'shFF82E9B7E4;
  assign sine_table_values_out1[466] = 40'shFF81299EE7;
  assign sine_table_values_out1[467] = 40'shFF7F6B86A9;
  assign sine_table_values_out1[468] = 40'shFF7DAF7637;
  assign sine_table_values_out1[469] = 40'shFF7BF57493;
  assign sine_table_values_out1[470] = 40'shFF7A3D88B8;
  assign sine_table_values_out1[471] = 40'shFF7887B999;
  assign sine_table_values_out1[472] = 40'shFF76D40E1F;
  assign sine_table_values_out1[473] = 40'shFF75228D2C;
  assign sine_table_values_out1[474] = 40'shFF73733D98;
  assign sine_table_values_out1[475] = 40'shFF71C62633;
  assign sine_table_values_out1[476] = 40'shFF701B4DC2;
  assign sine_table_values_out1[477] = 40'shFF6E72BB05;
  assign sine_table_values_out1[478] = 40'shFF6CCC74AF;
  assign sine_table_values_out1[479] = 40'shFF6B28816C;
  assign sine_table_values_out1[480] = 40'shFF6986E7DC;
  assign sine_table_values_out1[481] = 40'shFF67E7AE99;
  assign sine_table_values_out1[482] = 40'shFF664ADC30;
  assign sine_table_values_out1[483] = 40'shFF64B07727;
  assign sine_table_values_out1[484] = 40'shFF631885F9;
  assign sine_table_values_out1[485] = 40'shFF61830F17;
  assign sine_table_values_out1[486] = 40'shFF5FF018E7;
  assign sine_table_values_out1[487] = 40'shFF5E5FA9C7;
  assign sine_table_values_out1[488] = 40'shFF5CD1C80A;
  assign sine_table_values_out1[489] = 40'shFF5B4679F9;
  assign sine_table_values_out1[490] = 40'shFF59BDC5D0;
  assign sine_table_values_out1[491] = 40'shFF5837B1C4;
  assign sine_table_values_out1[492] = 40'shFF56B443FE;
  assign sine_table_values_out1[493] = 40'shFF5533829C;
  assign sine_table_values_out1[494] = 40'shFF53B573B1;
  assign sine_table_values_out1[495] = 40'shFF523A1D45;
  assign sine_table_values_out1[496] = 40'shFF50C18557;
  assign sine_table_values_out1[497] = 40'shFF4F4BB1D9;
  assign sine_table_values_out1[498] = 40'shFF4DD8A8B2;
  assign sine_table_values_out1[499] = 40'shFF4C686FBD;
  assign sine_table_values_out1[500] = 40'shFF4AFB0CCC;
  assign sine_table_values_out1[501] = 40'shFF499085A3;
  assign sine_table_values_out1[502] = 40'shFF4828DFFD;
  assign sine_table_values_out1[503] = 40'shFF46C42186;
  assign sine_table_values_out1[504] = 40'shFF45624FE1;
  assign sine_table_values_out1[505] = 40'shFF440370A5;
  assign sine_table_values_out1[506] = 40'shFF42A7895C;
  assign sine_table_values_out1[507] = 40'shFF414E9F84;
  assign sine_table_values_out1[508] = 40'shFF3FF8B890;
  assign sine_table_values_out1[509] = 40'shFF3EA5D9E5;
  assign sine_table_values_out1[510] = 40'shFF3D5608DE;
  assign sine_table_values_out1[511] = 40'shFF3C094AC8;
  assign sine_table_values_out1[512] = 40'shFF3ABFA4E5;
  assign sine_table_values_out1[513] = 40'shFF39791C69;
  assign sine_table_values_out1[514] = 40'shFF3835B67C;
  assign sine_table_values_out1[515] = 40'shFF36F57839;
  assign sine_table_values_out1[516] = 40'shFF35B866AF;
  assign sine_table_values_out1[517] = 40'shFF347E86E0;
  assign sine_table_values_out1[518] = 40'shFF3347DDC1;
  assign sine_table_values_out1[519] = 40'shFF32147039;
  assign sine_table_values_out1[520] = 40'shFF30E44323;
  assign sine_table_values_out1[521] = 40'shFF2FB75B4E;
  assign sine_table_values_out1[522] = 40'shFF2E8DBD78;
  assign sine_table_values_out1[523] = 40'shFF2D676E57;
  assign sine_table_values_out1[524] = 40'shFF2C44728E;
  assign sine_table_values_out1[525] = 40'shFF2B24CEB8;
  assign sine_table_values_out1[526] = 40'shFF2A08875D;
  assign sine_table_values_out1[527] = 40'shFF28EFA0FC;
  assign sine_table_values_out1[528] = 40'shFF27DA2005;
  assign sine_table_values_out1[529] = 40'shFF26C808D8;
  assign sine_table_values_out1[530] = 40'shFF25B95FCB;
  assign sine_table_values_out1[531] = 40'shFF24AE2923;
  assign sine_table_values_out1[532] = 40'shFF23A66918;
  assign sine_table_values_out1[533] = 40'shFF22A223D5;
  assign sine_table_values_out1[534] = 40'shFF21A15D75;
  assign sine_table_values_out1[535] = 40'shFF20A41A08;
  assign sine_table_values_out1[536] = 40'shFF1FAA5D8C;
  assign sine_table_values_out1[537] = 40'shFF1EB42BF3;
  assign sine_table_values_out1[538] = 40'shFF1DC18921;
  assign sine_table_values_out1[539] = 40'shFF1CD278EB;
  assign sine_table_values_out1[540] = 40'shFF1BE6FF16;
  assign sine_table_values_out1[541] = 40'shFF1AFF1F5B;
  assign sine_table_values_out1[542] = 40'shFF1A1ADD63;
  assign sine_table_values_out1[543] = 40'shFF193A3CC9;
  assign sine_table_values_out1[544] = 40'shFF185D4119;
  assign sine_table_values_out1[545] = 40'shFF1783EDD0;
  assign sine_table_values_out1[546] = 40'shFF16AE465D;
  assign sine_table_values_out1[547] = 40'shFF15DC4E20;
  assign sine_table_values_out1[548] = 40'shFF150E0869;
  assign sine_table_values_out1[549] = 40'shFF1443787A;
  assign sine_table_values_out1[550] = 40'shFF137CA186;
  assign sine_table_values_out1[551] = 40'shFF12B986B2;
  assign sine_table_values_out1[552] = 40'shFF11FA2B11;
  assign sine_table_values_out1[553] = 40'shFF113E91A9;
  assign sine_table_values_out1[554] = 40'shFF1086BD70;
  assign sine_table_values_out1[555] = 40'shFF0FD2B14F;
  assign sine_table_values_out1[556] = 40'shFF0F22701C;
  assign sine_table_values_out1[557] = 40'shFF0E75FCA0;
  assign sine_table_values_out1[558] = 40'shFF0DCD5995;
  assign sine_table_values_out1[559] = 40'shFF0D2889A3;
  assign sine_table_values_out1[560] = 40'shFF0C878F66;
  assign sine_table_values_out1[561] = 40'shFF0BEA6D68;
  assign sine_table_values_out1[562] = 40'shFF0B512624;
  assign sine_table_values_out1[563] = 40'shFF0ABBBC06;
  assign sine_table_values_out1[564] = 40'shFF0A2A3169;
  assign sine_table_values_out1[565] = 40'shFF099C889C;
  assign sine_table_values_out1[566] = 40'shFF0912C3D9;
  assign sine_table_values_out1[567] = 40'shFF088CE54E;
  assign sine_table_values_out1[568] = 40'shFF080AEF17;
  assign sine_table_values_out1[569] = 40'shFF078CE344;
  assign sine_table_values_out1[570] = 40'shFF0712C3D0;
  assign sine_table_values_out1[571] = 40'shFF069C92AA;
  assign sine_table_values_out1[572] = 40'shFF062A51B0;
  assign sine_table_values_out1[573] = 40'shFF05BC02AF;
  assign sine_table_values_out1[574] = 40'shFF0551A765;
  assign sine_table_values_out1[575] = 40'shFF04EB4180;
  assign sine_table_values_out1[576] = 40'shFF0488D29F;
  assign sine_table_values_out1[577] = 40'shFF042A5C4F;
  assign sine_table_values_out1[578] = 40'shFF03CFE00D;
  assign sine_table_values_out1[579] = 40'shFF03795F49;
  assign sine_table_values_out1[580] = 40'shFF0326DB5F;
  assign sine_table_values_out1[581] = 40'shFF02D8559C;
  assign sine_table_values_out1[582] = 40'shFF028DCF40;
  assign sine_table_values_out1[583] = 40'shFF02474976;
  assign sine_table_values_out1[584] = 40'shFF0204C55C;
  assign sine_table_values_out1[585] = 40'shFF01C643FF;
  assign sine_table_values_out1[586] = 40'shFF018BC65B;
  assign sine_table_values_out1[587] = 40'shFF01554D5D;
  assign sine_table_values_out1[588] = 40'shFF0122D9E1;
  assign sine_table_values_out1[589] = 40'shFF00F46CB3;
  assign sine_table_values_out1[590] = 40'shFF00CA068F;
  assign sine_table_values_out1[591] = 40'shFF00A3A820;
  assign sine_table_values_out1[592] = 40'shFF00815201;
  assign sine_table_values_out1[593] = 40'shFF006304BD;
  assign sine_table_values_out1[594] = 40'shFF0048C0CF;
  assign sine_table_values_out1[595] = 40'shFF003286A0;
  assign sine_table_values_out1[596] = 40'shFF0020568B;
  assign sine_table_values_out1[597] = 40'shFF001230D9;
  assign sine_table_values_out1[598] = 40'shFF000815C3;
  assign sine_table_values_out1[599] = 40'shFF00020573;
  assign sine_table_values_out1[600] = 40'shFF00000000;
  assign sine_table_values_out1[601] = 40'shFF00020573;
  assign sine_table_values_out1[602] = 40'shFF000815C3;
  assign sine_table_values_out1[603] = 40'shFF001230D9;
  assign sine_table_values_out1[604] = 40'shFF0020568B;
  assign sine_table_values_out1[605] = 40'shFF003286A0;
  assign sine_table_values_out1[606] = 40'shFF0048C0CF;
  assign sine_table_values_out1[607] = 40'shFF006304BD;
  assign sine_table_values_out1[608] = 40'shFF00815201;
  assign sine_table_values_out1[609] = 40'shFF00A3A820;
  assign sine_table_values_out1[610] = 40'shFF00CA068F;
  assign sine_table_values_out1[611] = 40'shFF00F46CB3;
  assign sine_table_values_out1[612] = 40'shFF0122D9E1;
  assign sine_table_values_out1[613] = 40'shFF01554D5D;
  assign sine_table_values_out1[614] = 40'shFF018BC65B;
  assign sine_table_values_out1[615] = 40'shFF01C643FF;
  assign sine_table_values_out1[616] = 40'shFF0204C55C;
  assign sine_table_values_out1[617] = 40'shFF02474976;
  assign sine_table_values_out1[618] = 40'shFF028DCF40;
  assign sine_table_values_out1[619] = 40'shFF02D8559C;
  assign sine_table_values_out1[620] = 40'shFF0326DB5F;
  assign sine_table_values_out1[621] = 40'shFF03795F49;
  assign sine_table_values_out1[622] = 40'shFF03CFE00D;
  assign sine_table_values_out1[623] = 40'shFF042A5C4F;
  assign sine_table_values_out1[624] = 40'shFF0488D29F;
  assign sine_table_values_out1[625] = 40'shFF04EB4180;
  assign sine_table_values_out1[626] = 40'shFF0551A765;
  assign sine_table_values_out1[627] = 40'shFF05BC02AF;
  assign sine_table_values_out1[628] = 40'shFF062A51B0;
  assign sine_table_values_out1[629] = 40'shFF069C92AA;
  assign sine_table_values_out1[630] = 40'shFF0712C3D0;
  assign sine_table_values_out1[631] = 40'shFF078CE344;
  assign sine_table_values_out1[632] = 40'shFF080AEF17;
  assign sine_table_values_out1[633] = 40'shFF088CE54E;
  assign sine_table_values_out1[634] = 40'shFF0912C3D9;
  assign sine_table_values_out1[635] = 40'shFF099C889C;
  assign sine_table_values_out1[636] = 40'shFF0A2A3169;
  assign sine_table_values_out1[637] = 40'shFF0ABBBC06;
  assign sine_table_values_out1[638] = 40'shFF0B512624;
  assign sine_table_values_out1[639] = 40'shFF0BEA6D68;
  assign sine_table_values_out1[640] = 40'shFF0C878F66;
  assign sine_table_values_out1[641] = 40'shFF0D2889A3;
  assign sine_table_values_out1[642] = 40'shFF0DCD5995;
  assign sine_table_values_out1[643] = 40'shFF0E75FCA0;
  assign sine_table_values_out1[644] = 40'shFF0F22701C;
  assign sine_table_values_out1[645] = 40'shFF0FD2B14F;
  assign sine_table_values_out1[646] = 40'shFF1086BD70;
  assign sine_table_values_out1[647] = 40'shFF113E91A9;
  assign sine_table_values_out1[648] = 40'shFF11FA2B11;
  assign sine_table_values_out1[649] = 40'shFF12B986B2;
  assign sine_table_values_out1[650] = 40'shFF137CA186;
  assign sine_table_values_out1[651] = 40'shFF1443787A;
  assign sine_table_values_out1[652] = 40'shFF150E0869;
  assign sine_table_values_out1[653] = 40'shFF15DC4E20;
  assign sine_table_values_out1[654] = 40'shFF16AE465D;
  assign sine_table_values_out1[655] = 40'shFF1783EDD0;
  assign sine_table_values_out1[656] = 40'shFF185D4119;
  assign sine_table_values_out1[657] = 40'shFF193A3CC9;
  assign sine_table_values_out1[658] = 40'shFF1A1ADD63;
  assign sine_table_values_out1[659] = 40'shFF1AFF1F5B;
  assign sine_table_values_out1[660] = 40'shFF1BE6FF16;
  assign sine_table_values_out1[661] = 40'shFF1CD278EB;
  assign sine_table_values_out1[662] = 40'shFF1DC18921;
  assign sine_table_values_out1[663] = 40'shFF1EB42BF3;
  assign sine_table_values_out1[664] = 40'shFF1FAA5D8C;
  assign sine_table_values_out1[665] = 40'shFF20A41A08;
  assign sine_table_values_out1[666] = 40'shFF21A15D75;
  assign sine_table_values_out1[667] = 40'shFF22A223D5;
  assign sine_table_values_out1[668] = 40'shFF23A66918;
  assign sine_table_values_out1[669] = 40'shFF24AE2923;
  assign sine_table_values_out1[670] = 40'shFF25B95FCB;
  assign sine_table_values_out1[671] = 40'shFF26C808D8;
  assign sine_table_values_out1[672] = 40'shFF27DA2005;
  assign sine_table_values_out1[673] = 40'shFF28EFA0FC;
  assign sine_table_values_out1[674] = 40'shFF2A08875D;
  assign sine_table_values_out1[675] = 40'shFF2B24CEB8;
  assign sine_table_values_out1[676] = 40'shFF2C44728E;
  assign sine_table_values_out1[677] = 40'shFF2D676E57;
  assign sine_table_values_out1[678] = 40'shFF2E8DBD78;
  assign sine_table_values_out1[679] = 40'shFF2FB75B4E;
  assign sine_table_values_out1[680] = 40'shFF30E44323;
  assign sine_table_values_out1[681] = 40'shFF32147039;
  assign sine_table_values_out1[682] = 40'shFF3347DDC1;
  assign sine_table_values_out1[683] = 40'shFF347E86E0;
  assign sine_table_values_out1[684] = 40'shFF35B866AF;
  assign sine_table_values_out1[685] = 40'shFF36F57839;
  assign sine_table_values_out1[686] = 40'shFF3835B67C;
  assign sine_table_values_out1[687] = 40'shFF39791C69;
  assign sine_table_values_out1[688] = 40'shFF3ABFA4E5;
  assign sine_table_values_out1[689] = 40'shFF3C094AC8;
  assign sine_table_values_out1[690] = 40'shFF3D5608DE;
  assign sine_table_values_out1[691] = 40'shFF3EA5D9E5;
  assign sine_table_values_out1[692] = 40'shFF3FF8B890;
  assign sine_table_values_out1[693] = 40'shFF414E9F84;
  assign sine_table_values_out1[694] = 40'shFF42A7895C;
  assign sine_table_values_out1[695] = 40'shFF440370A5;
  assign sine_table_values_out1[696] = 40'shFF45624FE1;
  assign sine_table_values_out1[697] = 40'shFF46C42186;
  assign sine_table_values_out1[698] = 40'shFF4828DFFD;
  assign sine_table_values_out1[699] = 40'shFF499085A3;
  assign sine_table_values_out1[700] = 40'shFF4AFB0CCC;
  assign sine_table_values_out1[701] = 40'shFF4C686FBD;
  assign sine_table_values_out1[702] = 40'shFF4DD8A8B2;
  assign sine_table_values_out1[703] = 40'shFF4F4BB1D9;
  assign sine_table_values_out1[704] = 40'shFF50C18557;
  assign sine_table_values_out1[705] = 40'shFF523A1D45;
  assign sine_table_values_out1[706] = 40'shFF53B573B1;
  assign sine_table_values_out1[707] = 40'shFF5533829C;
  assign sine_table_values_out1[708] = 40'shFF56B443FE;
  assign sine_table_values_out1[709] = 40'shFF5837B1C4;
  assign sine_table_values_out1[710] = 40'shFF59BDC5D0;
  assign sine_table_values_out1[711] = 40'shFF5B4679F9;
  assign sine_table_values_out1[712] = 40'shFF5CD1C80A;
  assign sine_table_values_out1[713] = 40'shFF5E5FA9C7;
  assign sine_table_values_out1[714] = 40'shFF5FF018E7;
  assign sine_table_values_out1[715] = 40'shFF61830F17;
  assign sine_table_values_out1[716] = 40'shFF631885F9;
  assign sine_table_values_out1[717] = 40'shFF64B07727;
  assign sine_table_values_out1[718] = 40'shFF664ADC30;
  assign sine_table_values_out1[719] = 40'shFF67E7AE99;
  assign sine_table_values_out1[720] = 40'shFF6986E7DC;
  assign sine_table_values_out1[721] = 40'shFF6B28816C;
  assign sine_table_values_out1[722] = 40'shFF6CCC74AF;
  assign sine_table_values_out1[723] = 40'shFF6E72BB05;
  assign sine_table_values_out1[724] = 40'shFF701B4DC2;
  assign sine_table_values_out1[725] = 40'shFF71C62633;
  assign sine_table_values_out1[726] = 40'shFF73733D98;
  assign sine_table_values_out1[727] = 40'shFF75228D2C;
  assign sine_table_values_out1[728] = 40'shFF76D40E1F;
  assign sine_table_values_out1[729] = 40'shFF7887B999;
  assign sine_table_values_out1[730] = 40'shFF7A3D88B8;
  assign sine_table_values_out1[731] = 40'shFF7BF57493;
  assign sine_table_values_out1[732] = 40'shFF7DAF7637;
  assign sine_table_values_out1[733] = 40'shFF7F6B86A9;
  assign sine_table_values_out1[734] = 40'shFF81299EE7;
  assign sine_table_values_out1[735] = 40'shFF82E9B7E4;
  assign sine_table_values_out1[736] = 40'shFF84ABCA8D;
  assign sine_table_values_out1[737] = 40'shFF866FCFC7;
  assign sine_table_values_out1[738] = 40'shFF8835C06F;
  assign sine_table_values_out1[739] = 40'shFF89FD9559;
  assign sine_table_values_out1[740] = 40'shFF8BC74753;
  assign sine_table_values_out1[741] = 40'shFF8D92CF22;
  assign sine_table_values_out1[742] = 40'shFF8F602585;
  assign sine_table_values_out1[743] = 40'shFF912F4333;
  assign sine_table_values_out1[744] = 40'shFF930020DB;
  assign sine_table_values_out1[745] = 40'shFF94D2B727;
  assign sine_table_values_out1[746] = 40'shFF96A6FEB8;
  assign sine_table_values_out1[747] = 40'shFF987CF029;
  assign sine_table_values_out1[748] = 40'shFF9A54840E;
  assign sine_table_values_out1[749] = 40'shFF9C2DB2F5;
  assign sine_table_values_out1[750] = 40'shFF9E087565;
  assign sine_table_values_out1[751] = 40'shFF9FE4C3DF;
  assign sine_table_values_out1[752] = 40'shFFA1C296DD;
  assign sine_table_values_out1[753] = 40'shFFA3A1E6D4;
  assign sine_table_values_out1[754] = 40'shFFA582AC32;
  assign sine_table_values_out1[755] = 40'shFFA764DF5F;
  assign sine_table_values_out1[756] = 40'shFFA94878BF;
  assign sine_table_values_out1[757] = 40'shFFAB2D70AD;
  assign sine_table_values_out1[758] = 40'shFFAD13BF82;
  assign sine_table_values_out1[759] = 40'shFFAEFB5D90;
  assign sine_table_values_out1[760] = 40'shFFB0E44323;
  assign sine_table_values_out1[761] = 40'shFFB2CE6884;
  assign sine_table_values_out1[762] = 40'shFFB4B9C5F3;
  assign sine_table_values_out1[763] = 40'shFFB6A653B1;
  assign sine_table_values_out1[764] = 40'shFFB89409F4;
  assign sine_table_values_out1[765] = 40'shFFBA82E0F1;
  assign sine_table_values_out1[766] = 40'shFFBC72D0D8;
  assign sine_table_values_out1[767] = 40'shFFBE63D1D4;
  assign sine_table_values_out1[768] = 40'shFFC055DC0C;
  assign sine_table_values_out1[769] = 40'shFFC248E7A2;
  assign sine_table_values_out1[770] = 40'shFFC43CECB5;
  assign sine_table_values_out1[771] = 40'shFFC631E35F;
  assign sine_table_values_out1[772] = 40'shFFC827C3B8;
  assign sine_table_values_out1[773] = 40'shFFCA1E85D3;
  assign sine_table_values_out1[774] = 40'shFFCC1621BE;
  assign sine_table_values_out1[775] = 40'shFFCE0E8F87;
  assign sine_table_values_out1[776] = 40'shFFD007C736;
  assign sine_table_values_out1[777] = 40'shFFD201C0D0;
  assign sine_table_values_out1[778] = 40'shFFD3FC7459;
  assign sine_table_values_out1[779] = 40'shFFD5F7D9D0;
  assign sine_table_values_out1[780] = 40'shFFD7F3E931;
  assign sine_table_values_out1[781] = 40'shFFD9F09A77;
  assign sine_table_values_out1[782] = 40'shFFDBEDE599;
  assign sine_table_values_out1[783] = 40'shFFDDEBC28D;
  assign sine_table_values_out1[784] = 40'shFFDFEA2945;
  assign sine_table_values_out1[785] = 40'shFFE1E911B2;
  assign sine_table_values_out1[786] = 40'shFFE3E873C3;
  assign sine_table_values_out1[787] = 40'shFFE5E84764;
  assign sine_table_values_out1[788] = 40'shFFE7E88480;
  assign sine_table_values_out1[789] = 40'shFFE9E92301;
  assign sine_table_values_out1[790] = 40'shFFEBEA1ACE;
  assign sine_table_values_out1[791] = 40'shFFEDEB63CD;
  assign sine_table_values_out1[792] = 40'shFFEFECF5E4;
  assign sine_table_values_out1[793] = 40'shFFF1EEC8F6;
  assign sine_table_values_out1[794] = 40'shFFF3F0D4E7;
  assign sine_table_values_out1[795] = 40'shFFF5F31197;
  assign sine_table_values_out1[796] = 40'shFFF7F576E9;
  assign sine_table_values_out1[797] = 40'shFFF9F7FCBD;
  assign sine_table_values_out1[798] = 40'shFFFBFA9AF2;
  assign sine_table_values_out1[799] = 40'shFFFDFD4969;
  assign sine_table_values_out1[800] = 40'sh0000000000;
  assign sine_table_values_out1[801] = 40'sh000202B697;
  assign sine_table_values_out1[802] = 40'sh000405650E;
  assign sine_table_values_out1[803] = 40'sh0006080343;
  assign sine_table_values_out1[804] = 40'sh00080A8917;
  assign sine_table_values_out1[805] = 40'sh000A0CEE69;
  assign sine_table_values_out1[806] = 40'sh000C0F2B19;
  assign sine_table_values_out1[807] = 40'sh000E11370A;
  assign sine_table_values_out1[808] = 40'sh0010130A1C;
  assign sine_table_values_out1[809] = 40'sh0012149C33;
  assign sine_table_values_out1[810] = 40'sh001415E532;
  assign sine_table_values_out1[811] = 40'sh001616DCFF;
  assign sine_table_values_out1[812] = 40'sh0018177B80;
  assign sine_table_values_out1[813] = 40'sh001A17B89C;
  assign sine_table_values_out1[814] = 40'sh001C178C3D;
  assign sine_table_values_out1[815] = 40'sh001E16EE4E;
  assign sine_table_values_out1[816] = 40'sh002015D6BB;
  assign sine_table_values_out1[817] = 40'sh0022143D73;
  assign sine_table_values_out1[818] = 40'sh0024121A67;
  assign sine_table_values_out1[819] = 40'sh00260F6589;
  assign sine_table_values_out1[820] = 40'sh00280C16CF;
  assign sine_table_values_out1[821] = 40'sh002A082630;
  assign sine_table_values_out1[822] = 40'sh002C038BA7;
  assign sine_table_values_out1[823] = 40'sh002DFE3F30;
  assign sine_table_values_out1[824] = 40'sh002FF838CA;
  assign sine_table_values_out1[825] = 40'sh0031F17079;
  assign sine_table_values_out1[826] = 40'sh0033E9DE42;
  assign sine_table_values_out1[827] = 40'sh0035E17A2D;
  assign sine_table_values_out1[828] = 40'sh0037D83C48;
  assign sine_table_values_out1[829] = 40'sh0039CE1CA1;
  assign sine_table_values_out1[830] = 40'sh003BC3134B;
  assign sine_table_values_out1[831] = 40'sh003DB7185E;
  assign sine_table_values_out1[832] = 40'sh003FAA23F4;
  assign sine_table_values_out1[833] = 40'sh00419C2E2C;
  assign sine_table_values_out1[834] = 40'sh00438D2F28;
  assign sine_table_values_out1[835] = 40'sh00457D1F0F;
  assign sine_table_values_out1[836] = 40'sh00476BF60C;
  assign sine_table_values_out1[837] = 40'sh004959AC4F;
  assign sine_table_values_out1[838] = 40'sh004B463A0D;
  assign sine_table_values_out1[839] = 40'sh004D31977C;
  assign sine_table_values_out1[840] = 40'sh004F1BBCDD;
  assign sine_table_values_out1[841] = 40'sh005104A270;
  assign sine_table_values_out1[842] = 40'sh0052EC407E;
  assign sine_table_values_out1[843] = 40'sh0054D28F53;
  assign sine_table_values_out1[844] = 40'sh0056B78741;
  assign sine_table_values_out1[845] = 40'sh00589B20A1;
  assign sine_table_values_out1[846] = 40'sh005A7D53CE;
  assign sine_table_values_out1[847] = 40'sh005C5E192C;
  assign sine_table_values_out1[848] = 40'sh005E3D6923;
  assign sine_table_values_out1[849] = 40'sh00601B3C21;
  assign sine_table_values_out1[850] = 40'sh0061F78A9B;
  assign sine_table_values_out1[851] = 40'sh0063D24D0B;
  assign sine_table_values_out1[852] = 40'sh0065AB7BF2;
  assign sine_table_values_out1[853] = 40'sh0067830FD7;
  assign sine_table_values_out1[854] = 40'sh0069590148;
  assign sine_table_values_out1[855] = 40'sh006B2D48D9;
  assign sine_table_values_out1[856] = 40'sh006CFFDF25;
  assign sine_table_values_out1[857] = 40'sh006ED0BCCD;
  assign sine_table_values_out1[858] = 40'sh00709FDA7B;
  assign sine_table_values_out1[859] = 40'sh00726D30DE;
  assign sine_table_values_out1[860] = 40'sh007438B8AD;
  assign sine_table_values_out1[861] = 40'sh0076026AA7;
  assign sine_table_values_out1[862] = 40'sh0077CA3F91;
  assign sine_table_values_out1[863] = 40'sh0079903039;
  assign sine_table_values_out1[864] = 40'sh007B543573;
  assign sine_table_values_out1[865] = 40'sh007D16481C;
  assign sine_table_values_out1[866] = 40'sh007ED66119;
  assign sine_table_values_out1[867] = 40'sh0080947957;
  assign sine_table_values_out1[868] = 40'sh00825089C9;
  assign sine_table_values_out1[869] = 40'sh00840A8B6D;
  assign sine_table_values_out1[870] = 40'sh0085C27748;
  assign sine_table_values_out1[871] = 40'sh0087784667;
  assign sine_table_values_out1[872] = 40'sh00892BF1E1;
  assign sine_table_values_out1[873] = 40'sh008ADD72D4;
  assign sine_table_values_out1[874] = 40'sh008C8CC268;
  assign sine_table_values_out1[875] = 40'sh008E39D9CD;
  assign sine_table_values_out1[876] = 40'sh008FE4B23E;
  assign sine_table_values_out1[877] = 40'sh00918D44FB;
  assign sine_table_values_out1[878] = 40'sh0093338B51;
  assign sine_table_values_out1[879] = 40'sh0094D77E94;
  assign sine_table_values_out1[880] = 40'sh0096791824;
  assign sine_table_values_out1[881] = 40'sh0098185167;
  assign sine_table_values_out1[882] = 40'sh0099B523D0;
  assign sine_table_values_out1[883] = 40'sh009B4F88D9;
  assign sine_table_values_out1[884] = 40'sh009CE77A07;
  assign sine_table_values_out1[885] = 40'sh009E7CF0E9;
  assign sine_table_values_out1[886] = 40'sh00A00FE719;
  assign sine_table_values_out1[887] = 40'sh00A1A05639;
  assign sine_table_values_out1[888] = 40'sh00A32E37F6;
  assign sine_table_values_out1[889] = 40'sh00A4B98607;
  assign sine_table_values_out1[890] = 40'sh00A6423A30;
  assign sine_table_values_out1[891] = 40'sh00A7C84E3C;
  assign sine_table_values_out1[892] = 40'sh00A94BBC02;
  assign sine_table_values_out1[893] = 40'sh00AACC7D64;
  assign sine_table_values_out1[894] = 40'sh00AC4A8C4F;
  assign sine_table_values_out1[895] = 40'sh00ADC5E2BB;
  assign sine_table_values_out1[896] = 40'sh00AF3E7AA9;
  assign sine_table_values_out1[897] = 40'sh00B0B44E27;
  assign sine_table_values_out1[898] = 40'sh00B227574E;
  assign sine_table_values_out1[899] = 40'sh00B3979043;
  assign sine_table_values_out1[900] = 40'sh00B504F334;
  assign sine_table_values_out1[901] = 40'sh00B66F7A5D;
  assign sine_table_values_out1[902] = 40'sh00B7D72003;
  assign sine_table_values_out1[903] = 40'sh00B93BDE7A;
  assign sine_table_values_out1[904] = 40'sh00BA9DB01F;
  assign sine_table_values_out1[905] = 40'sh00BBFC8F5B;
  assign sine_table_values_out1[906] = 40'sh00BD5876A4;
  assign sine_table_values_out1[907] = 40'sh00BEB1607C;
  assign sine_table_values_out1[908] = 40'sh00C0074770;
  assign sine_table_values_out1[909] = 40'sh00C15A261B;
  assign sine_table_values_out1[910] = 40'sh00C2A9F722;
  assign sine_table_values_out1[911] = 40'sh00C3F6B538;
  assign sine_table_values_out1[912] = 40'sh00C5405B1B;
  assign sine_table_values_out1[913] = 40'sh00C686E397;
  assign sine_table_values_out1[914] = 40'sh00C7CA4984;
  assign sine_table_values_out1[915] = 40'sh00C90A87C7;
  assign sine_table_values_out1[916] = 40'sh00CA479951;
  assign sine_table_values_out1[917] = 40'sh00CB817920;
  assign sine_table_values_out1[918] = 40'sh00CCB8223F;
  assign sine_table_values_out1[919] = 40'sh00CDEB8FC7;
  assign sine_table_values_out1[920] = 40'sh00CF1BBCDD;
  assign sine_table_values_out1[921] = 40'sh00D048A4B2;
  assign sine_table_values_out1[922] = 40'sh00D1724288;
  assign sine_table_values_out1[923] = 40'sh00D29891A9;
  assign sine_table_values_out1[924] = 40'sh00D3BB8D72;
  assign sine_table_values_out1[925] = 40'sh00D4DB3148;
  assign sine_table_values_out1[926] = 40'sh00D5F778A3;
  assign sine_table_values_out1[927] = 40'sh00D7105F04;
  assign sine_table_values_out1[928] = 40'sh00D825DFFB;
  assign sine_table_values_out1[929] = 40'sh00D937F728;
  assign sine_table_values_out1[930] = 40'sh00DA46A035;
  assign sine_table_values_out1[931] = 40'sh00DB51D6DD;
  assign sine_table_values_out1[932] = 40'sh00DC5996E8;
  assign sine_table_values_out1[933] = 40'sh00DD5DDC2B;
  assign sine_table_values_out1[934] = 40'sh00DE5EA28B;
  assign sine_table_values_out1[935] = 40'sh00DF5BE5F8;
  assign sine_table_values_out1[936] = 40'sh00E055A274;
  assign sine_table_values_out1[937] = 40'sh00E14BD40D;
  assign sine_table_values_out1[938] = 40'sh00E23E76DF;
  assign sine_table_values_out1[939] = 40'sh00E32D8715;
  assign sine_table_values_out1[940] = 40'sh00E41900EA;
  assign sine_table_values_out1[941] = 40'sh00E500E0A5;
  assign sine_table_values_out1[942] = 40'sh00E5E5229D;
  assign sine_table_values_out1[943] = 40'sh00E6C5C337;
  assign sine_table_values_out1[944] = 40'sh00E7A2BEE7;
  assign sine_table_values_out1[945] = 40'sh00E87C1230;
  assign sine_table_values_out1[946] = 40'sh00E951B9A3;
  assign sine_table_values_out1[947] = 40'sh00EA23B1E0;
  assign sine_table_values_out1[948] = 40'sh00EAF1F797;
  assign sine_table_values_out1[949] = 40'sh00EBBC8786;
  assign sine_table_values_out1[950] = 40'sh00EC835E7A;
  assign sine_table_values_out1[951] = 40'sh00ED46794E;
  assign sine_table_values_out1[952] = 40'sh00EE05D4EF;
  assign sine_table_values_out1[953] = 40'sh00EEC16E57;
  assign sine_table_values_out1[954] = 40'sh00EF794290;
  assign sine_table_values_out1[955] = 40'sh00F02D4EB1;
  assign sine_table_values_out1[956] = 40'sh00F0DD8FE4;
  assign sine_table_values_out1[957] = 40'sh00F18A0360;
  assign sine_table_values_out1[958] = 40'sh00F232A66B;
  assign sine_table_values_out1[959] = 40'sh00F2D7765D;
  assign sine_table_values_out1[960] = 40'sh00F378709A;
  assign sine_table_values_out1[961] = 40'sh00F4159298;
  assign sine_table_values_out1[962] = 40'sh00F4AED9DC;
  assign sine_table_values_out1[963] = 40'sh00F54443FA;
  assign sine_table_values_out1[964] = 40'sh00F5D5CE97;
  assign sine_table_values_out1[965] = 40'sh00F6637764;
  assign sine_table_values_out1[966] = 40'sh00F6ED3C27;
  assign sine_table_values_out1[967] = 40'sh00F7731AB2;
  assign sine_table_values_out1[968] = 40'sh00F7F510E9;
  assign sine_table_values_out1[969] = 40'sh00F8731CBC;
  assign sine_table_values_out1[970] = 40'sh00F8ED3C30;
  assign sine_table_values_out1[971] = 40'sh00F9636D56;
  assign sine_table_values_out1[972] = 40'sh00F9D5AE50;
  assign sine_table_values_out1[973] = 40'sh00FA43FD51;
  assign sine_table_values_out1[974] = 40'sh00FAAE589B;
  assign sine_table_values_out1[975] = 40'sh00FB14BE80;
  assign sine_table_values_out1[976] = 40'sh00FB772D61;
  assign sine_table_values_out1[977] = 40'sh00FBD5A3B1;
  assign sine_table_values_out1[978] = 40'sh00FC301FF3;
  assign sine_table_values_out1[979] = 40'sh00FC86A0B7;
  assign sine_table_values_out1[980] = 40'sh00FCD924A1;
  assign sine_table_values_out1[981] = 40'sh00FD27AA64;
  assign sine_table_values_out1[982] = 40'sh00FD7230C0;
  assign sine_table_values_out1[983] = 40'sh00FDB8B68A;
  assign sine_table_values_out1[984] = 40'sh00FDFB3AA4;
  assign sine_table_values_out1[985] = 40'sh00FE39BC01;
  assign sine_table_values_out1[986] = 40'sh00FE7439A5;
  assign sine_table_values_out1[987] = 40'sh00FEAAB2A3;
  assign sine_table_values_out1[988] = 40'sh00FEDD261F;
  assign sine_table_values_out1[989] = 40'sh00FF0B934D;
  assign sine_table_values_out1[990] = 40'sh00FF35F971;
  assign sine_table_values_out1[991] = 40'sh00FF5C57E0;
  assign sine_table_values_out1[992] = 40'sh00FF7EADFF;
  assign sine_table_values_out1[993] = 40'sh00FF9CFB43;
  assign sine_table_values_out1[994] = 40'sh00FFB73F31;
  assign sine_table_values_out1[995] = 40'sh00FFCD7960;
  assign sine_table_values_out1[996] = 40'sh00FFDFA975;
  assign sine_table_values_out1[997] = 40'sh00FFEDCF27;
  assign sine_table_values_out1[998] = 40'sh00FFF7EA3D;
  assign sine_table_values_out1[999] = 40'sh00FFFDFA8D;
  assign sine_table_values_out1[1000] = 40'sh0100000000;
  assign sine_table_values_out1[1001] = 40'sh00FFFDFA8D;
  assign Lookup_1 = {1'b0, Sum_out1_2_1};
  assign Lookup_add_temp = Lookup_1 + 33'h000000001;
  assign Lookup_idx = (Lookup_add_temp[32:31] != 2'b00 ? 32'sb01111111111111111111111111111111 :
              $signed(Lookup_add_temp[31:0]));
  assign Lookup_out1_2 = (Lookup_idx <= 32'sd1002 ? sine_table_values_out1[Lookup_idx - 32'sd1] :
              sine_table_values_out1[1001]);

  assign Sum_out1_3_1 = Sum_out1_3[3];

  assign Lookup_3 = {1'b0, Sum_out1_3_1};
  assign Lookup_add_temp_1 = Lookup_3 + 33'h000000001;
  assign Lookup_idx_1 = (Lookup_add_temp_1[32:31] != 2'b00 ? 32'sb01111111111111111111111111111111 :
              $signed(Lookup_add_temp_1[31:0]));
  assign Lookup_out1_3 = (Lookup_idx_1 <= 32'sd1002 ? sine_table_values_out1[Lookup_idx_1 - 32'sd1] :
              sine_table_values_out1[1001]);
  assign Sum5_out1 = Lookup_out1_2 - Lookup_out1_3;
  always_ff @(posedge clk)
    begin : rd_4_1_process
      if (reset == 1'b1) begin
        Sum5_out1_1 <= 40'sh0000000000;
      end
      else begin
        if (enb) begin
          Sum5_out1_1 <= Sum5_out1;
        end
      end
    end

  always_ff @(posedge clk)
    begin : rd_3_1_process
      if (reset == 1'b1) begin
        indexing_out1_3 <= 40'sh0000000000;
      end
      else begin
        if (enb) begin
          indexing_out1_3 <= indexing_out1_2;
        end
      end
    end

  assign Data_Type_Conversion1_out1 = $signed({Get_Integer_out1[10:0], 29'b00000000000000000000000000000});
  always_ff @(posedge clk)
    begin : rd_4_2_process
      if (reset == 1'b1) begin
        Data_Type_Conversion1_out1_1 <= 40'sh0000000000;
      end
      else begin
        if (enb) begin
          Data_Type_Conversion1_out1_1 <= Data_Type_Conversion1_out1;
        end
      end
    end

  assign Sum2_sub_temp = indexing_out1_3 - Data_Type_Conversion1_out1_1;
  assign Sum2_out1 = {Sum2_sub_temp[36:0], 3'b000};
  always_ff @(posedge clk)
    begin : rd_1_2_process
      if (reset == 1'b1) begin
        In2 <= 40'sh0000000000;
      end
      else begin
        if (enb) begin
          In2 <= Sum2_out1;
        end
      end
    end

  assign Product1_out1 = Sum5_out1_1 * In2;
  assign Product1_out1_1 = Product1_out1[71:32];

  always_ff @(posedge clk)
    begin : rd_5_process
      if (reset == 1'b1) begin
        Product1_out1_2 <= 40'sh0000000000;
      end
      else begin
        if (enb) begin
          Product1_out1_2 <= Product1_out1_1;
        end
      end
    end

  always_ff @(posedge clk)
    begin : rd_6_process
      if (reset == 1'b1) begin
        rd_6_reg <= '{default :40'sh0000000000};
      end
      else begin
        if (enb) begin
          rd_6_reg[0] <= Lookup_out1_3;
          rd_6_reg[1] <= rd_6_reg[0];
        end
      end
    end

  assign In1_3 = rd_6_reg[1];

  assign Sum6_out1 = Product1_out1_2 + In1_3;
  always_ff @(posedge clk)
    begin : rd_0_2_process
      if (reset == 1'b1) begin
        rd_0_reg <= '{default :40'sh0000000000};
      end
      else begin
        if (enb) begin
          rd_0_reg[0] <= Sum6_out1;
          rd_0_reg[32'sd1:32'sd182] <= rd_0_reg[32'sd0:32'sd181];
        end
      end
    end

  assign cos = rd_0_reg[182];

  assign dcos_out1 = A * cos;
  assign Sum_out1_0 = Sum_out1_3[0];

  assign Lookup_5 = {1'b0, Sum_out1_0};
  assign Lookup_add_temp_2 = Lookup_5 + 33'h000000001;
  assign Lookup_idx_2 = (Lookup_add_temp_2[32:31] != 2'b00 ? 32'sb01111111111111111111111111111111 :
              $signed(Lookup_add_temp_2[31:0]));
  assign Lookup_out1_0 = (Lookup_idx_2 <= 32'sd1002 ? sine_table_values_out1[Lookup_idx_2 - 32'sd1] :
              sine_table_values_out1[1001]);
  assign Sum_out1_1_1 = Sum_out1_3[1];

  assign Lookup_7 = {1'b0, Sum_out1_1_1};
  assign Lookup_add_temp_3 = Lookup_7 + 33'h000000001;
  assign Lookup_idx_3 = (Lookup_add_temp_3[32:31] != 2'b00 ? 32'sb01111111111111111111111111111111 :
              $signed(Lookup_add_temp_3[31:0]));
  assign Lookup_out1_1 = (Lookup_idx_3 <= 32'sd1002 ? sine_table_values_out1[Lookup_idx_3 - 32'sd1] :
              sine_table_values_out1[1001]);

  assign Sum3_out1 = Lookup_out1_0 - Lookup_out1_1;
  always_ff @(posedge clk)
    begin : rd_0_3_process
      if (reset == 1'b1) begin
        Sum3_out1_1 <= 40'sh0000000000;
      end
      else begin
        if (enb) begin
          Sum3_out1_1 <= Sum3_out1;
        end
      end
    end

  assign Product_out1 = Sum3_out1_1 * In2;
  assign Product_out1_1 = Product_out1[71:32];

  always_ff @(posedge clk)
    begin : rd_2_2_process
      if (reset == 1'b1) begin
        Product_out1_2 <= 40'sh0000000000;
      end
      else begin
        if (enb) begin
          Product_out1_2 <= Product_out1_1;
        end
      end
    end

  always_ff @(posedge clk)
    begin : rd_3_2_process
      if (reset == 1'b1) begin
        rd_3_reg <= '{default :40'sh0000000000};
      end
      else begin
        if (enb) begin
          rd_3_reg[0] <= Lookup_out1_1;
          rd_3_reg[1] <= rd_3_reg[0];
        end
      end
    end

  assign In1_1 = rd_3_reg[1];

  assign Sum4_out1 = Product_out1_2 + In1_1;
  always_ff @(posedge clk)
    begin : rd_1_3_process
      if (reset == 1'b1) begin
        rd_1_reg <= '{default :40'sh0000000000};
      end
      else begin
        if (enb) begin
          rd_1_reg[0] <= Sum4_out1;
          rd_1_reg[32'sd1:32'sd182] <= rd_1_reg[32'sd0:32'sd181];
        end
      end
    end

  assign sin = rd_1_reg[182];

  assign qsin_out1 = B * sin;
  always_ff @(posedge clk)
    begin : rd_2_3_process
      if (reset == 1'b1) begin
        dcos_out1_1 <= 104'sh00000000000000000000000000;
      end
      else begin
        if (enb) begin
          dcos_out1_1 <= dcos_out1;
        end
      end
    end

  assign dcos_out1_2 = dcos_out1_1[95:32];

  always_ff @(posedge clk)
    begin : rd_3_3_process
      if (reset == 1'b1) begin
        qsin_out1_1 <= 104'sh00000000000000000000000000;
      end
      else begin
        if (enb) begin
          qsin_out1_1 <= qsin_out1;
        end
      end
    end

  assign qsin_out1_2 = qsin_out1_1[95:32];

  assign sum_alpha_out1 = dcos_out1_2 - qsin_out1_2;
  always_ff @(posedge clk)
    begin : delayMatch_process
      if (reset == 1'b1) begin
        A_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          A_1 <= sum_alpha_out1;
        end
      end
    end

  assign qcos_out1 = B * cos;
  assign dsin_out1 = A * sin;
  always_ff @(posedge clk)
    begin : rd_4_3_process
      if (reset == 1'b1) begin
        qcos_out1_1 <= 104'sh00000000000000000000000000;
      end
      else begin
        if (enb) begin
          qcos_out1_1 <= qcos_out1;
        end
      end
    end

  assign qcos_out1_2 = qcos_out1_1[95:32];

  always_ff @(posedge clk)
    begin : rd_5_1_process
      if (reset == 1'b1) begin
        dsin_out1_1 <= 104'sh00000000000000000000000000;
      end
      else begin
        if (enb) begin
          dsin_out1_1 <= dsin_out1;
        end
      end
    end

  assign dsin_out1_2 = dsin_out1_1[95:32];

  assign sum_beta_out1 = qcos_out1_2 + dsin_out1_2;
  always_ff @(posedge clk)
    begin : delayMatch1_process
      if (reset == 1'b1) begin
        B_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          B_1 <= sum_beta_out1;
        end
      end
    end

  assign D_axis_aligned_out1[0] = A_1;
  assign D_axis_aligned_out1[1] = B_1;
  assign Unary_Minus_cast = {A_1[63], A_1};
  assign Unary_Minus_cast_1 =  - (Unary_Minus_cast);
  assign Unary_Minus_out1 = Unary_Minus_cast_1[63:0];
  assign Q_axis_aligned_out1[0] = B_1;
  assign Q_axis_aligned_out1[1] = Unary_Minus_out1;
  assign Switch_out1 = (switch_compare_1 == 1'b0 ? D_axis_aligned_out1 :
              Q_axis_aligned_out1);
  assign O1 = Switch_out1[0];
  assign O2 = Switch_out1[1];

endmodule   
