
`timescale 1ns/1ps

module reciprocal
          import FOC_DUT_pkg::* ;
          (  input logic clk,
             input logic reset,
             input logic enb,
             input logic [31:0] recip_in,
             output logic signed [63:0] recip_out);


  logic init_guard_true_1;
  logic [70:0] matching_delays_reg;
  logic init_guard_true_2;
  logic signed [63:0] recip_outinit_guard_default;
  logic trueFlag_1;
  logic initFlagDelayData;
  logic [67:0] delayMatch_reg;
  logic initFlagDelayData_1;
  logic [65:0] ConstantSignal_1;
  logic [31:0] Udc_reg;
  logic signed [68:0] d_ext;
  logic Rin_MSB;
  logic signed [69:0] Unary_Minus_in0;
  logic signed [69:0] Unary_Minus_1;
  logic signed [68:0] unary_minus_d;
  logic signed [68:0] corrected_d;
  logic signed [68:0] corrected_d_p_1;
  logic signed [68:0] d1_p;
  logic signed [68:0] d2_p;
  logic signed [68:0] d3_p;
  logic signed [68:0] d4_p;
  logic signed [68:0] d5_p;
  logic signed [68:0] d6_p;
  logic signed [68:0] d7_p;
  logic signed [68:0] d8_p;
  logic signed [68:0] d9_p;
  logic signed [68:0] d10_p;
  logic signed [68:0] d11_p;
  logic signed [68:0] d12_p;
  logic signed [68:0] d13_p;
  logic signed [68:0] d14_p;
  logic signed [68:0] d15_p;
  logic signed [68:0] d16_p;
  logic signed [68:0] d17_p;
  logic signed [68:0] d18_p;
  logic signed [68:0] d19_p;
  logic signed [68:0] d20_p;
  logic signed [68:0] d21_p;
  logic signed [68:0] d22_p;
  logic signed [68:0] d23_p;
  logic signed [68:0] d24_p;
  logic signed [68:0] d25_p;
  logic signed [68:0] d26_p;
  logic signed [68:0] d27_p;
  logic signed [68:0] d28_p;
  logic signed [68:0] d29_p;
  logic signed [68:0] d30_p;
  logic signed [68:0] d31_p;
  logic signed [68:0] d32_p;
  logic signed [68:0] d33_p;
  logic signed [68:0] d34_p;
  logic signed [68:0] d35_p;
  logic signed [68:0] d36_p;
  logic signed [68:0] d37_p;
  logic signed [68:0] d38_p;
  logic signed [68:0] d39_p;
  logic signed [68:0] d40_p;
  logic signed [68:0] d41_p;
  logic signed [68:0] d42_p;
  logic signed [68:0] d43_p;
  logic signed [68:0] d44_p;
  logic signed [68:0] d45_p;
  logic signed [68:0] d46_p;
  logic signed [68:0] d47_p;
  logic signed [68:0] d48_p;
  logic signed [68:0] d49_p;
  logic signed [68:0] d50_p;
  logic signed [68:0] d51_p;
  logic signed [68:0] d52_p;
  logic signed [68:0] d53_p;
  logic signed [68:0] d54_p;
  logic signed [68:0] d55_p;
  logic signed [68:0] d56_p;
  logic signed [68:0] d57_p;
  logic signed [68:0] d58_p;
  logic signed [68:0] d59_p;
  logic signed [68:0] d60_p;
  logic signed [68:0] d61_p;
  logic signed [68:0] d62_p;
  logic signed [68:0] d63_p;
  logic signed [68:0] d64_p;
  logic signed [68:0] d65_p;
  logic signed [68:0] d66_p;
  logic switch_compare_1;
  logic signed [65:0] constant_z_in;
  logic signed [133:0] constant_z;
  logic signed [133:0] corrected_z_p_1;
  logic [68:0] rMSBits;
  logic signed [68:0] x;
  logic signed [68:0] x_1;
  logic signed [69:0] d_neg_in0;
  logic signed [69:0] d_neg_1;
  logic signed [68:0] d_neg_2;
  logic signed [68:0] temp;
  logic [67:0] rMSBNextBits;
  logic [64:0] rLSBits;
  logic [64:0] rLSBits_1;
  logic tempSignBit;
  logic qBit;
  logic [133:0] rNextTemp;
  logic signed [133:0] r1;
  logic signed [133:0] r1_p;
  logic [68:0] rMSBits_1;
  logic signed [68:0] x_2;
  logic rMSBit;
  logic rMSBitneg;
  logic switch_compare_1_1;
  logic signed [69:0] d_neg_in0_1;
  logic signed [69:0] d_neg_4;
  logic signed [68:0] d_neg_5;
  logic signed [68:0] y_1;
  logic signed [68:0] temp_3;
  logic [67:0] rMSBNextBits_1;
  logic [64:0] rLSBits_2;
  logic tempSignBit_1;
  logic qBit_1;
  logic [133:0] rNextTemp_1;
  logic signed [133:0] r2;
  logic signed [133:0] r2_p;
  logic [68:0] rMSBits_2;
  logic signed [68:0] x_3;
  logic rMSBit_1;
  logic rMSBitneg_1;
  logic switch_compare_1_2;
  logic signed [69:0] d_neg_in0_2;
  logic signed [69:0] d_neg_7;
  logic signed [68:0] d_neg_8;
  logic signed [68:0] y_3;
  logic signed [68:0] temp_4;
  logic [67:0] rMSBNextBits_2;
  logic [64:0] rLSBits_3;
  logic tempSignBit_2;
  logic qBit_2;
  logic [133:0] rNextTemp_2;
  logic signed [133:0] r3;
  logic signed [133:0] r3_p;
  logic [68:0] rMSBits_3;
  logic signed [68:0] x_4;
  logic rMSBit_2;
  logic rMSBitneg_2;
  logic switch_compare_1_3;
  logic signed [69:0] d_neg_in0_3;
  logic signed [69:0] d_neg_10;
  logic signed [68:0] d_neg_11;
  logic signed [68:0] y_5;
  logic signed [68:0] temp_5;
  logic [67:0] rMSBNextBits_3;
  logic [64:0] rLSBits_4;
  logic tempSignBit_3;
  logic qBit_3;
  logic [133:0] rNextTemp_3;
  logic signed [133:0] r4;
  logic signed [133:0] r4_p;
  logic [68:0] rMSBits_4;
  logic signed [68:0] x_5;
  logic rMSBit_3;
  logic rMSBitneg_3;
  logic switch_compare_1_4;
  logic signed [69:0] d_neg_in0_4;
  logic signed [69:0] d_neg_13;
  logic signed [68:0] d_neg_14;
  logic signed [68:0] y_7;
  logic signed [68:0] temp_6;
  logic [67:0] rMSBNextBits_4;
  logic [64:0] rLSBits_5;
  logic tempSignBit_4;
  logic qBit_4;
  logic [133:0] rNextTemp_4;
  logic signed [133:0] r5;
  logic signed [133:0] r5_p;
  logic [68:0] rMSBits_5;
  logic signed [68:0] x_6;
  logic rMSBit_4;
  logic rMSBitneg_4;
  logic switch_compare_1_5;
  logic signed [69:0] d_neg_in0_5;
  logic signed [69:0] d_neg_16;
  logic signed [68:0] d_neg_17;
  logic signed [68:0] y_9;
  logic signed [68:0] temp_7;
  logic [67:0] rMSBNextBits_5;
  logic [64:0] rLSBits_6;
  logic tempSignBit_5;
  logic qBit_5;
  logic [133:0] rNextTemp_5;
  logic signed [133:0] r6;
  logic signed [133:0] r6_p;
  logic [68:0] rMSBits_6;
  logic signed [68:0] x_7;
  logic rMSBit_5;
  logic rMSBitneg_5;
  logic switch_compare_1_6;
  logic signed [69:0] d_neg_in0_6;
  logic signed [69:0] d_neg_19;
  logic signed [68:0] d_neg_20;
  logic signed [68:0] y_11;
  logic signed [68:0] temp_8;
  logic [67:0] rMSBNextBits_6;
  logic [64:0] rLSBits_7;
  logic tempSignBit_6;
  logic qBit_6;
  logic [133:0] rNextTemp_6;
  logic signed [133:0] r7;
  logic signed [133:0] r7_p;
  logic [68:0] rMSBits_7;
  logic signed [68:0] x_8;
  logic rMSBit_6;
  logic rMSBitneg_6;
  logic switch_compare_1_7;
  logic signed [69:0] d_neg_in0_7;
  logic signed [69:0] d_neg_22;
  logic signed [68:0] d_neg_23;
  logic signed [68:0] y_13;
  logic signed [68:0] temp_9;
  logic [67:0] rMSBNextBits_7;
  logic [64:0] rLSBits_8;
  logic tempSignBit_7;
  logic qBit_7;
  logic [133:0] rNextTemp_7;
  logic signed [133:0] r8;
  logic signed [133:0] r8_p;
  logic [68:0] rMSBits_8;
  logic signed [68:0] x_9;
  logic rMSBit_7;
  logic rMSBitneg_7;
  logic switch_compare_1_8;
  logic signed [69:0] d_neg_in0_8;
  logic signed [69:0] d_neg_25;
  logic signed [68:0] d_neg_26;
  logic signed [68:0] y_15;
  logic signed [68:0] temp_10;
  logic [67:0] rMSBNextBits_8;
  logic [64:0] rLSBits_9;
  logic tempSignBit_8;
  logic qBit_8;
  logic [133:0] rNextTemp_8;
  logic signed [133:0] r9;
  logic signed [133:0] r9_p;
  logic [68:0] rMSBits_9;
  logic signed [68:0] x_10;
  logic rMSBit_8;
  logic rMSBitneg_8;
  logic switch_compare_1_9;
  logic signed [69:0] d_neg_in0_9;
  logic signed [69:0] d_neg_28;
  logic signed [68:0] d_neg_29;
  logic signed [68:0] y_17;
  logic signed [68:0] temp_11;
  logic [67:0] rMSBNextBits_9;
  logic [64:0] rLSBits_10;
  logic tempSignBit_9;
  logic qBit_9;
  logic [133:0] rNextTemp_9;
  logic signed [133:0] r10;
  logic signed [133:0] r10_p;
  logic [68:0] rMSBits_10;
  logic signed [68:0] x_11;
  logic rMSBit_9;
  logic rMSBitneg_9;
  logic switch_compare_1_10;
  logic signed [69:0] d_neg_in0_10;
  logic signed [69:0] d_neg_31;
  logic signed [68:0] d_neg_32;
  logic signed [68:0] y_19;
  logic signed [68:0] temp_12;
  logic [67:0] rMSBNextBits_10;
  logic [64:0] rLSBits_11;
  logic tempSignBit_10;
  logic qBit_10;
  logic [133:0] rNextTemp_10;
  logic signed [133:0] r11;
  logic signed [133:0] r11_p;
  logic [68:0] rMSBits_11;
  logic signed [68:0] x_12;
  logic rMSBit_10;
  logic rMSBitneg_10;
  logic switch_compare_1_11;
  logic signed [69:0] d_neg_in0_11;
  logic signed [69:0] d_neg_34;
  logic signed [68:0] d_neg_35;
  logic signed [68:0] y_21;
  logic signed [68:0] temp_13;
  logic [67:0] rMSBNextBits_11;
  logic [64:0] rLSBits_12;
  logic tempSignBit_11;
  logic qBit_11;
  logic [133:0] rNextTemp_11;
  logic signed [133:0] r12;
  logic signed [133:0] r12_p;
  logic [68:0] rMSBits_12;
  logic signed [68:0] x_13;
  logic rMSBit_11;
  logic rMSBitneg_11;
  logic switch_compare_1_12;
  logic signed [69:0] d_neg_in0_12;
  logic signed [69:0] d_neg_37;
  logic signed [68:0] d_neg_38;
  logic signed [68:0] y_23;
  logic signed [68:0] temp_14;
  logic [67:0] rMSBNextBits_12;
  logic [64:0] rLSBits_13;
  logic tempSignBit_12;
  logic qBit_12;
  logic [133:0] rNextTemp_12;
  logic signed [133:0] r13;
  logic signed [133:0] r13_p;
  logic [68:0] rMSBits_13;
  logic signed [68:0] x_14;
  logic rMSBit_12;
  logic rMSBitneg_12;
  logic switch_compare_1_13;
  logic signed [69:0] d_neg_in0_13;
  logic signed [69:0] d_neg_40;
  logic signed [68:0] d_neg_41;
  logic signed [68:0] y_25;
  logic signed [68:0] temp_15;
  logic [67:0] rMSBNextBits_13;
  logic [64:0] rLSBits_14;
  logic tempSignBit_13;
  logic qBit_13;
  logic [133:0] rNextTemp_13;
  logic signed [133:0] r14;
  logic signed [133:0] r14_p;
  logic [68:0] rMSBits_14;
  logic signed [68:0] x_15;
  logic rMSBit_13;
  logic rMSBitneg_13;
  logic switch_compare_1_14;
  logic signed [69:0] d_neg_in0_14;
  logic signed [69:0] d_neg_43;
  logic signed [68:0] d_neg_44;
  logic signed [68:0] y_27;
  logic signed [68:0] temp_16;
  logic [67:0] rMSBNextBits_14;
  logic [64:0] rLSBits_15;
  logic tempSignBit_14;
  logic qBit_14;
  logic [133:0] rNextTemp_14;
  logic signed [133:0] r15;
  logic signed [133:0] r15_p;
  logic [68:0] rMSBits_15;
  logic signed [68:0] x_16;
  logic rMSBit_14;
  logic rMSBitneg_14;
  logic switch_compare_1_15;
  logic signed [69:0] d_neg_in0_15;
  logic signed [69:0] d_neg_46;
  logic signed [68:0] d_neg_47;
  logic signed [68:0] y_29;
  logic signed [68:0] temp_17;
  logic [67:0] rMSBNextBits_15;
  logic [64:0] rLSBits_16;
  logic tempSignBit_15;
  logic qBit_15;
  logic [133:0] rNextTemp_15;
  logic signed [133:0] r16;
  logic signed [133:0] r16_p;
  logic [68:0] rMSBits_16;
  logic signed [68:0] x_17;
  logic rMSBit_15;
  logic rMSBitneg_15;
  logic switch_compare_1_16;
  logic signed [69:0] d_neg_in0_16;
  logic signed [69:0] d_neg_49;
  logic signed [68:0] d_neg_50;
  logic signed [68:0] y_31;
  logic signed [68:0] temp_18;
  logic [67:0] rMSBNextBits_16;
  logic [64:0] rLSBits_17;
  logic tempSignBit_16;
  logic qBit_16;
  logic [133:0] rNextTemp_16;
  logic signed [133:0] r17;
  logic signed [133:0] r17_p;
  logic [68:0] rMSBits_17;
  logic signed [68:0] x_18;
  logic rMSBit_16;
  logic rMSBitneg_16;
  logic switch_compare_1_17;
  logic signed [69:0] d_neg_in0_17;
  logic signed [69:0] d_neg_52;
  logic signed [68:0] d_neg_53;
  logic signed [68:0] y_33;
  logic signed [68:0] temp_19;
  logic [67:0] rMSBNextBits_17;
  logic [64:0] rLSBits_18;
  logic tempSignBit_17;
  logic qBit_17;
  logic [133:0] rNextTemp_17;
  logic signed [133:0] r18;
  logic signed [133:0] r18_p;
  logic [68:0] rMSBits_18;
  logic signed [68:0] x_19;
  logic rMSBit_17;
  logic rMSBitneg_17;
  logic switch_compare_1_18;
  logic signed [69:0] d_neg_in0_18;
  logic signed [69:0] d_neg_55;
  logic signed [68:0] d_neg_56;
  logic signed [68:0] y_35;
  logic signed [68:0] temp_20;
  logic [67:0] rMSBNextBits_18;
  logic [64:0] rLSBits_19;
  logic tempSignBit_18;
  logic qBit_18;
  logic [133:0] rNextTemp_18;
  logic signed [133:0] r19;
  logic signed [133:0] r19_p;
  logic [68:0] rMSBits_19;
  logic signed [68:0] x_20;
  logic rMSBit_18;
  logic rMSBitneg_18;
  logic switch_compare_1_19;
  logic signed [69:0] d_neg_in0_19;
  logic signed [69:0] d_neg_58;
  logic signed [68:0] d_neg_59;
  logic signed [68:0] y_37;
  logic signed [68:0] temp_21;
  logic [67:0] rMSBNextBits_19;
  logic [64:0] rLSBits_20;
  logic tempSignBit_19;
  logic qBit_19;
  logic [133:0] rNextTemp_19;
  logic signed [133:0] r20;
  logic signed [133:0] r20_p;
  logic [68:0] rMSBits_20;
  logic signed [68:0] x_21;
  logic rMSBit_19;
  logic rMSBitneg_19;
  logic switch_compare_1_20;
  logic signed [69:0] d_neg_in0_20;
  logic signed [69:0] d_neg_61;
  logic signed [68:0] d_neg_62;
  logic signed [68:0] y_39;
  logic signed [68:0] temp_22;
  logic [67:0] rMSBNextBits_20;
  logic [64:0] rLSBits_21;
  logic tempSignBit_20;
  logic qBit_20;
  logic [133:0] rNextTemp_20;
  logic signed [133:0] r21;
  logic signed [133:0] r21_p;
  logic [68:0] rMSBits_21;
  logic signed [68:0] x_22;
  logic rMSBit_20;
  logic rMSBitneg_20;
  logic switch_compare_1_21;
  logic signed [69:0] d_neg_in0_21;
  logic signed [69:0] d_neg_64;
  logic signed [68:0] d_neg_65;
  logic signed [68:0] y_41;
  logic signed [68:0] temp_23;
  logic [67:0] rMSBNextBits_21;
  logic [64:0] rLSBits_22;
  logic tempSignBit_21;
  logic qBit_21;
  logic [133:0] rNextTemp_21;
  logic signed [133:0] r22;
  logic signed [133:0] r22_p;
  logic [68:0] rMSBits_22;
  logic signed [68:0] x_23;
  logic rMSBit_21;
  logic rMSBitneg_21;
  logic switch_compare_1_22;
  logic signed [69:0] d_neg_in0_22;
  logic signed [69:0] d_neg_67;
  logic signed [68:0] d_neg_68;
  logic signed [68:0] y_43;
  logic signed [68:0] temp_24;
  logic [67:0] rMSBNextBits_22;
  logic [64:0] rLSBits_23;
  logic tempSignBit_22;
  logic qBit_22;
  logic [133:0] rNextTemp_22;
  logic signed [133:0] r23;
  logic signed [133:0] r23_p;
  logic [68:0] rMSBits_23;
  logic signed [68:0] x_24;
  logic rMSBit_22;
  logic rMSBitneg_22;
  logic switch_compare_1_23;
  logic signed [69:0] d_neg_in0_23;
  logic signed [69:0] d_neg_70;
  logic signed [68:0] d_neg_71;
  logic signed [68:0] y_45;
  logic signed [68:0] temp_25;
  logic [67:0] rMSBNextBits_23;
  logic [64:0] rLSBits_24;
  logic tempSignBit_23;
  logic qBit_23;
  logic [133:0] rNextTemp_23;
  logic signed [133:0] r24;
  logic signed [133:0] r24_p;
  logic [68:0] rMSBits_24;
  logic signed [68:0] x_25;
  logic rMSBit_23;
  logic rMSBitneg_23;
  logic switch_compare_1_24;
  logic signed [69:0] d_neg_in0_24;
  logic signed [69:0] d_neg_73;
  logic signed [68:0] d_neg_74;
  logic signed [68:0] y_47;
  logic signed [68:0] temp_26;
  logic [67:0] rMSBNextBits_24;
  logic [64:0] rLSBits_25;
  logic tempSignBit_24;
  logic qBit_24;
  logic [133:0] rNextTemp_24;
  logic signed [133:0] r25;
  logic signed [133:0] r25_p;
  logic [68:0] rMSBits_25;
  logic signed [68:0] x_26;
  logic rMSBit_24;
  logic rMSBitneg_24;
  logic switch_compare_1_25;
  logic signed [69:0] d_neg_in0_25;
  logic signed [69:0] d_neg_76;
  logic signed [68:0] d_neg_77;
  logic signed [68:0] y_49;
  logic signed [68:0] temp_27;
  logic [67:0] rMSBNextBits_25;
  logic [64:0] rLSBits_26;
  logic tempSignBit_25;
  logic qBit_25;
  logic [133:0] rNextTemp_25;
  logic signed [133:0] r26;
  logic signed [133:0] r26_p;
  logic [68:0] rMSBits_26;
  logic signed [68:0] x_27;
  logic rMSBit_25;
  logic rMSBitneg_25;
  logic switch_compare_1_26;
  logic signed [69:0] d_neg_in0_26;
  logic signed [69:0] d_neg_79;
  logic signed [68:0] d_neg_80;
  logic signed [68:0] y_51;
  logic signed [68:0] temp_28;
  logic [67:0] rMSBNextBits_26;
  logic [64:0] rLSBits_27;
  logic tempSignBit_26;
  logic qBit_26;
  logic [133:0] rNextTemp_26;
  logic signed [133:0] r27;
  logic signed [133:0] r27_p;
  logic [68:0] rMSBits_27;
  logic signed [68:0] x_28;
  logic rMSBit_26;
  logic rMSBitneg_26;
  logic switch_compare_1_27;
  logic signed [69:0] d_neg_in0_27;
  logic signed [69:0] d_neg_82;
  logic signed [68:0] d_neg_83;
  logic signed [68:0] y_53;
  logic signed [68:0] temp_29;
  logic [67:0] rMSBNextBits_27;
  logic [64:0] rLSBits_28;
  logic tempSignBit_27;
  logic qBit_27;
  logic [133:0] rNextTemp_27;
  logic signed [133:0] r28;
  logic signed [133:0] r28_p;
  logic [68:0] rMSBits_28;
  logic signed [68:0] x_29;
  logic rMSBit_27;
  logic rMSBitneg_27;
  logic switch_compare_1_28;
  logic signed [69:0] d_neg_in0_28;
  logic signed [69:0] d_neg_85;
  logic signed [68:0] d_neg_86;
  logic signed [68:0] y_55;
  logic signed [68:0] temp_30;
  logic [67:0] rMSBNextBits_28;
  logic [64:0] rLSBits_29;
  logic tempSignBit_28;
  logic qBit_28;
  logic [133:0] rNextTemp_28;
  logic signed [133:0] r29;
  logic signed [133:0] r29_p;
  logic [68:0] rMSBits_29;
  logic signed [68:0] x_30;
  logic rMSBit_28;
  logic rMSBitneg_28;
  logic switch_compare_1_29;
  logic signed [69:0] d_neg_in0_29;
  logic signed [69:0] d_neg_88;
  logic signed [68:0] d_neg_89;
  logic signed [68:0] y_57;
  logic signed [68:0] temp_31;
  logic [67:0] rMSBNextBits_29;
  logic [64:0] rLSBits_30;
  logic tempSignBit_29;
  logic qBit_29;
  logic [133:0] rNextTemp_29;
  logic signed [133:0] r30;
  logic signed [133:0] r30_p;
  logic [68:0] rMSBits_30;
  logic signed [68:0] x_31;
  logic rMSBit_29;
  logic rMSBitneg_29;
  logic switch_compare_1_30;
  logic signed [69:0] d_neg_in0_30;
  logic signed [69:0] d_neg_91;
  logic signed [68:0] d_neg_92;
  logic signed [68:0] y_59;
  logic signed [68:0] temp_32;
  logic [67:0] rMSBNextBits_30;
  logic [64:0] rLSBits_31;
  logic tempSignBit_30;
  logic qBit_30;
  logic [133:0] rNextTemp_30;
  logic signed [133:0] r31;
  logic signed [133:0] r31_p;
  logic [68:0] rMSBits_31;
  logic signed [68:0] x_32;
  logic rMSBit_30;
  logic rMSBitneg_30;
  logic switch_compare_1_31;
  logic signed [69:0] d_neg_in0_31;
  logic signed [69:0] d_neg_94;
  logic signed [68:0] d_neg_95;
  logic signed [68:0] y_61;
  logic signed [68:0] temp_33;
  logic [67:0] rMSBNextBits_31;
  logic [64:0] rLSBits_32;
  logic tempSignBit_31;
  logic qBit_31;
  logic [133:0] rNextTemp_31;
  logic signed [133:0] r32;
  logic signed [133:0] r32_p;
  logic [68:0] rMSBits_32;
  logic signed [68:0] x_33;
  logic rMSBit_31;
  logic rMSBitneg_31;
  logic switch_compare_1_32;
  logic signed [69:0] d_neg_in0_32;
  logic signed [69:0] d_neg_97;
  logic signed [68:0] d_neg_98;
  logic signed [68:0] y_63;
  logic signed [68:0] temp_34;
  logic [67:0] rMSBNextBits_32;
  logic [64:0] rLSBits_33;
  logic tempSignBit_32;
  logic qBit_32;
  logic [133:0] rNextTemp_32;
  logic signed [133:0] r33;
  logic signed [133:0] r33_p;
  logic [68:0] rMSBits_33;
  logic signed [68:0] x_34;
  logic rMSBit_32;
  logic rMSBitneg_32;
  logic switch_compare_1_33;
  logic signed [69:0] d_neg_in0_33;
  logic signed [69:0] d_neg_100;
  logic signed [68:0] d_neg_101;
  logic signed [68:0] y_65;
  logic signed [68:0] temp_35;
  logic [67:0] rMSBNextBits_33;
  logic [64:0] rLSBits_34;
  logic tempSignBit_33;
  logic qBit_33;
  logic [133:0] rNextTemp_33;
  logic signed [133:0] r34;
  logic signed [133:0] r34_p;
  logic [68:0] rMSBits_34;
  logic signed [68:0] x_35;
  logic rMSBit_33;
  logic rMSBitneg_33;
  logic switch_compare_1_34;
  logic signed [69:0] d_neg_in0_34;
  logic signed [69:0] d_neg_103;
  logic signed [68:0] d_neg_104;
  logic signed [68:0] y_67;
  logic signed [68:0] temp_36;
  logic [67:0] rMSBNextBits_34;
  logic [64:0] rLSBits_35;
  logic tempSignBit_34;
  logic qBit_34;
  logic [133:0] rNextTemp_34;
  logic signed [133:0] r35;
  logic signed [133:0] r35_p;
  logic [68:0] rMSBits_35;
  logic signed [68:0] x_36;
  logic rMSBit_34;
  logic rMSBitneg_34;
  logic switch_compare_1_35;
  logic signed [69:0] d_neg_in0_35;
  logic signed [69:0] d_neg_106;
  logic signed [68:0] d_neg_107;
  logic signed [68:0] y_69;
  logic signed [68:0] temp_37;
  logic [67:0] rMSBNextBits_35;
  logic [64:0] rLSBits_36;
  logic tempSignBit_35;
  logic qBit_35;
  logic [133:0] rNextTemp_35;
  logic signed [133:0] r36;
  logic signed [133:0] r36_p;
  logic [68:0] rMSBits_36;
  logic signed [68:0] x_37;
  logic rMSBit_35;
  logic rMSBitneg_35;
  logic switch_compare_1_36;
  logic signed [69:0] d_neg_in0_36;
  logic signed [69:0] d_neg_109;
  logic signed [68:0] d_neg_110;
  logic signed [68:0] y_71;
  logic signed [68:0] temp_38;
  logic [67:0] rMSBNextBits_36;
  logic [64:0] rLSBits_37;
  logic tempSignBit_36;
  logic qBit_36;
  logic [133:0] rNextTemp_36;
  logic signed [133:0] r37;
  logic signed [133:0] r37_p;
  logic [68:0] rMSBits_37;
  logic signed [68:0] x_38;
  logic rMSBit_36;
  logic rMSBitneg_36;
  logic switch_compare_1_37;
  logic signed [69:0] d_neg_in0_37;
  logic signed [69:0] d_neg_112;
  logic signed [68:0] d_neg_113;
  logic signed [68:0] y_73;
  logic signed [68:0] temp_39;
  logic [67:0] rMSBNextBits_37;
  logic [64:0] rLSBits_38;
  logic tempSignBit_37;
  logic qBit_37;
  logic [133:0] rNextTemp_37;
  logic signed [133:0] r38;
  logic signed [133:0] r38_p;
  logic [68:0] rMSBits_38;
  logic signed [68:0] x_39;
  logic rMSBit_37;
  logic rMSBitneg_37;
  logic switch_compare_1_38;
  logic signed [69:0] d_neg_in0_38;
  logic signed [69:0] d_neg_115;
  logic signed [68:0] d_neg_116;
  logic signed [68:0] y_75;
  logic signed [68:0] temp_40;
  logic [67:0] rMSBNextBits_38;
  logic [64:0] rLSBits_39;
  logic tempSignBit_38;
  logic qBit_38;
  logic [133:0] rNextTemp_38;
  logic signed [133:0] r39;
  logic signed [133:0] r39_p;
  logic [68:0] rMSBits_39;
  logic signed [68:0] x_40;
  logic rMSBit_38;
  logic rMSBitneg_38;
  logic switch_compare_1_39;
  logic signed [69:0] d_neg_in0_39;
  logic signed [69:0] d_neg_118;
  logic signed [68:0] d_neg_119;
  logic signed [68:0] y_77;
  logic signed [68:0] temp_41;
  logic [67:0] rMSBNextBits_39;
  logic [64:0] rLSBits_40;
  logic tempSignBit_39;
  logic qBit_39;
  logic [133:0] rNextTemp_39;
  logic signed [133:0] r40;
  logic signed [133:0] r40_p;
  logic [68:0] rMSBits_40;
  logic signed [68:0] x_41;
  logic rMSBit_39;
  logic rMSBitneg_39;
  logic switch_compare_1_40;
  logic signed [69:0] d_neg_in0_40;
  logic signed [69:0] d_neg_121;
  logic signed [68:0] d_neg_122;
  logic signed [68:0] y_79;
  logic signed [68:0] temp_42;
  logic [67:0] rMSBNextBits_40;
  logic [64:0] rLSBits_41;
  logic tempSignBit_40;
  logic qBit_40;
  logic [133:0] rNextTemp_40;
  logic signed [133:0] r41;
  logic signed [133:0] r41_p;
  logic [68:0] rMSBits_41;
  logic signed [68:0] x_42;
  logic rMSBit_40;
  logic rMSBitneg_40;
  logic switch_compare_1_41;
  logic signed [69:0] d_neg_in0_41;
  logic signed [69:0] d_neg_124;
  logic signed [68:0] d_neg_125;
  logic signed [68:0] y_81;
  logic signed [68:0] temp_43;
  logic [67:0] rMSBNextBits_41;
  logic [64:0] rLSBits_42;
  logic tempSignBit_41;
  logic qBit_41;
  logic [133:0] rNextTemp_41;
  logic signed [133:0] r42;
  logic signed [133:0] r42_p;
  logic [68:0] rMSBits_42;
  logic signed [68:0] x_43;
  logic rMSBit_41;
  logic rMSBitneg_41;
  logic switch_compare_1_42;
  logic signed [69:0] d_neg_in0_42;
  logic signed [69:0] d_neg_127;
  logic signed [68:0] d_neg_128;
  logic signed [68:0] y_83;
  logic signed [68:0] temp_44;
  logic [67:0] rMSBNextBits_42;
  logic [64:0] rLSBits_43;
  logic tempSignBit_42;
  logic qBit_42;
  logic [133:0] rNextTemp_42;
  logic signed [133:0] r43;
  logic signed [133:0] r43_p;
  logic [68:0] rMSBits_43;
  logic signed [68:0] x_44;
  logic rMSBit_42;
  logic rMSBitneg_42;
  logic switch_compare_1_43;
  logic signed [69:0] d_neg_in0_43;
  logic signed [69:0] d_neg_130;
  logic signed [68:0] d_neg_131;
  logic signed [68:0] y_85;
  logic signed [68:0] temp_45;
  logic [67:0] rMSBNextBits_43;
  logic [64:0] rLSBits_44;
  logic tempSignBit_43;
  logic qBit_43;
  logic [133:0] rNextTemp_43;
  logic signed [133:0] r44;
  logic signed [133:0] r44_p;
  logic [68:0] rMSBits_44;
  logic signed [68:0] x_45;
  logic rMSBit_43;
  logic rMSBitneg_43;
  logic switch_compare_1_44;
  logic signed [69:0] d_neg_in0_44;
  logic signed [69:0] d_neg_133;
  logic signed [68:0] d_neg_134;
  logic signed [68:0] y_87;
  logic signed [68:0] temp_46;
  logic [67:0] rMSBNextBits_44;
  logic [64:0] rLSBits_45;
  logic tempSignBit_44;
  logic qBit_44;
  logic [133:0] rNextTemp_44;
  logic signed [133:0] r45;
  logic signed [133:0] r45_p;
  logic [68:0] rMSBits_45;
  logic signed [68:0] x_46;
  logic rMSBit_44;
  logic rMSBitneg_44;
  logic switch_compare_1_45;
  logic signed [69:0] d_neg_in0_45;
  logic signed [69:0] d_neg_136;
  logic signed [68:0] d_neg_137;
  logic signed [68:0] y_89;
  logic signed [68:0] temp_47;
  logic [67:0] rMSBNextBits_45;
  logic [64:0] rLSBits_46;
  logic tempSignBit_45;
  logic qBit_45;
  logic [133:0] rNextTemp_45;
  logic signed [133:0] r46;
  logic signed [133:0] r46_p;
  logic [68:0] rMSBits_46;
  logic signed [68:0] x_47;
  logic rMSBit_45;
  logic rMSBitneg_45;
  logic switch_compare_1_46;
  logic signed [69:0] d_neg_in0_46;
  logic signed [69:0] d_neg_139;
  logic signed [68:0] d_neg_140;
  logic signed [68:0] y_91;
  logic signed [68:0] temp_48;
  logic [67:0] rMSBNextBits_46;
  logic [64:0] rLSBits_47;
  logic tempSignBit_46;
  logic qBit_46;
  logic [133:0] rNextTemp_46;
  logic signed [133:0] r47;
  logic signed [133:0] r47_p;
  logic [68:0] rMSBits_47;
  logic signed [68:0] x_48;
  logic rMSBit_46;
  logic rMSBitneg_46;
  logic switch_compare_1_47;
  logic signed [69:0] d_neg_in0_47;
  logic signed [69:0] d_neg_142;
  logic signed [68:0] d_neg_143;
  logic signed [68:0] y_93;
  logic signed [68:0] temp_49;
  logic [67:0] rMSBNextBits_47;
  logic [64:0] rLSBits_48;
  logic tempSignBit_47;
  logic qBit_47;
  logic [133:0] rNextTemp_47;
  logic signed [133:0] r48;
  logic signed [133:0] r48_p;
  logic [68:0] rMSBits_48;
  logic signed [68:0] x_49;
  logic rMSBit_47;
  logic rMSBitneg_47;
  logic switch_compare_1_48;
  logic signed [69:0] d_neg_in0_48;
  logic signed [69:0] d_neg_145;
  logic signed [68:0] d_neg_146;
  logic signed [68:0] y_95;
  logic signed [68:0] temp_50;
  logic [67:0] rMSBNextBits_48;
  logic [64:0] rLSBits_49;
  logic tempSignBit_48;
  logic qBit_48;
  logic [133:0] rNextTemp_48;
  logic signed [133:0] r49;
  logic signed [133:0] r49_p;
  logic [68:0] rMSBits_49;
  logic signed [68:0] x_50;
  logic rMSBit_48;
  logic rMSBitneg_48;
  logic switch_compare_1_49;
  logic signed [69:0] d_neg_in0_49;
  logic signed [69:0] d_neg_148;
  logic signed [68:0] d_neg_149;
  logic signed [68:0] y_97;
  logic signed [68:0] temp_51;
  logic [67:0] rMSBNextBits_49;
  logic [64:0] rLSBits_50;
  logic tempSignBit_49;
  logic qBit_49;
  logic [133:0] rNextTemp_49;
  logic signed [133:0] r50;
  logic signed [133:0] r50_p;
  logic [68:0] rMSBits_50;
  logic signed [68:0] x_51;
  logic rMSBit_49;
  logic rMSBitneg_49;
  logic switch_compare_1_50;
  logic signed [69:0] d_neg_in0_50;
  logic signed [69:0] d_neg_151;
  logic signed [68:0] d_neg_152;
  logic signed [68:0] y_99;
  logic signed [68:0] temp_52;
  logic [67:0] rMSBNextBits_50;
  logic [64:0] rLSBits_51;
  logic tempSignBit_50;
  logic qBit_50;
  logic [133:0] rNextTemp_50;
  logic signed [133:0] r51;
  logic signed [133:0] r51_p;
  logic [68:0] rMSBits_51;
  logic signed [68:0] x_52;
  logic rMSBit_50;
  logic rMSBitneg_50;
  logic switch_compare_1_51;
  logic signed [69:0] d_neg_in0_51;
  logic signed [69:0] d_neg_154;
  logic signed [68:0] d_neg_155;
  logic signed [68:0] y_101;
  logic signed [68:0] temp_53;
  logic [67:0] rMSBNextBits_51;
  logic [64:0] rLSBits_52;
  logic tempSignBit_51;
  logic qBit_51;
  logic [133:0] rNextTemp_51;
  logic signed [133:0] r52;
  logic signed [133:0] r52_p;
  logic [68:0] rMSBits_52;
  logic signed [68:0] x_53;
  logic rMSBit_51;
  logic rMSBitneg_51;
  logic switch_compare_1_52;
  logic signed [69:0] d_neg_in0_52;
  logic signed [69:0] d_neg_157;
  logic signed [68:0] d_neg_158;
  logic signed [68:0] y_103;
  logic signed [68:0] temp_54;
  logic [67:0] rMSBNextBits_52;
  logic [64:0] rLSBits_53;
  logic tempSignBit_52;
  logic qBit_52;
  logic [133:0] rNextTemp_52;
  logic signed [133:0] r53;
  logic signed [133:0] r53_p;
  logic [68:0] rMSBits_53;
  logic signed [68:0] x_54;
  logic rMSBit_52;
  logic rMSBitneg_52;
  logic switch_compare_1_53;
  logic signed [69:0] d_neg_in0_53;
  logic signed [69:0] d_neg_160;
  logic signed [68:0] d_neg_161;
  logic signed [68:0] y_105;
  logic signed [68:0] temp_55;
  logic [67:0] rMSBNextBits_53;
  logic [64:0] rLSBits_54;
  logic tempSignBit_53;
  logic qBit_53;
  logic [133:0] rNextTemp_53;
  logic signed [133:0] r54;
  logic signed [133:0] r54_p;
  logic [68:0] rMSBits_54;
  logic signed [68:0] x_55;
  logic rMSBit_53;
  logic rMSBitneg_53;
  logic switch_compare_1_54;
  logic signed [69:0] d_neg_in0_54;
  logic signed [69:0] d_neg_163;
  logic signed [68:0] d_neg_164;
  logic signed [68:0] y_107;
  logic signed [68:0] temp_56;
  logic [67:0] rMSBNextBits_54;
  logic [64:0] rLSBits_55;
  logic tempSignBit_54;
  logic qBit_54;
  logic [133:0] rNextTemp_54;
  logic signed [133:0] r55;
  logic signed [133:0] r55_p;
  logic [68:0] rMSBits_55;
  logic signed [68:0] x_56;
  logic rMSBit_54;
  logic rMSBitneg_54;
  logic switch_compare_1_55;
  logic signed [69:0] d_neg_in0_55;
  logic signed [69:0] d_neg_166;
  logic signed [68:0] d_neg_167;
  logic signed [68:0] y_109;
  logic signed [68:0] temp_57;
  logic [67:0] rMSBNextBits_55;
  logic [64:0] rLSBits_56;
  logic tempSignBit_55;
  logic qBit_55;
  logic [133:0] rNextTemp_55;
  logic signed [133:0] r56;
  logic signed [133:0] r56_p;
  logic [68:0] rMSBits_56;
  logic signed [68:0] x_57;
  logic rMSBit_55;
  logic rMSBitneg_55;
  logic switch_compare_1_56;
  logic signed [69:0] d_neg_in0_56;
  logic signed [69:0] d_neg_169;
  logic signed [68:0] d_neg_170;
  logic signed [68:0] y_111;
  logic signed [68:0] temp_58;
  logic [67:0] rMSBNextBits_56;
  logic [64:0] rLSBits_57;
  logic tempSignBit_56;
  logic qBit_56;
  logic [133:0] rNextTemp_56;
  logic signed [133:0] r57;
  logic signed [133:0] r57_p;
  logic [68:0] rMSBits_57;
  logic signed [68:0] x_58;
  logic rMSBit_56;
  logic rMSBitneg_56;
  logic switch_compare_1_57;
  logic signed [69:0] d_neg_in0_57;
  logic signed [69:0] d_neg_172;
  logic signed [68:0] d_neg_173;
  logic signed [68:0] y_113;
  logic signed [68:0] temp_59;
  logic [67:0] rMSBNextBits_57;
  logic [64:0] rLSBits_58;
  logic tempSignBit_57;
  logic qBit_57;
  logic [133:0] rNextTemp_57;
  logic signed [133:0] r58;
  logic signed [133:0] r58_p;
  logic [68:0] rMSBits_58;
  logic signed [68:0] x_59;
  logic rMSBit_57;
  logic rMSBitneg_57;
  logic switch_compare_1_58;
  logic signed [69:0] d_neg_in0_58;
  logic signed [69:0] d_neg_175;
  logic signed [68:0] d_neg_176;
  logic signed [68:0] y_115;
  logic signed [68:0] temp_60;
  logic [67:0] rMSBNextBits_58;
  logic [64:0] rLSBits_59;
  logic tempSignBit_58;
  logic qBit_58;
  logic [133:0] rNextTemp_58;
  logic signed [133:0] r59;
  logic signed [133:0] r59_p;
  logic [68:0] rMSBits_59;
  logic signed [68:0] x_60;
  logic rMSBit_58;
  logic rMSBitneg_58;
  logic switch_compare_1_59;
  logic signed [69:0] d_neg_in0_59;
  logic signed [69:0] d_neg_178;
  logic signed [68:0] d_neg_179;
  logic signed [68:0] y_117;
  logic signed [68:0] temp_61;
  logic [67:0] rMSBNextBits_59;
  logic [64:0] rLSBits_60;
  logic tempSignBit_59;
  logic qBit_59;
  logic [133:0] rNextTemp_59;
  logic signed [133:0] r60;
  logic signed [133:0] r60_p;
  logic [68:0] rMSBits_60;
  logic signed [68:0] x_61;
  logic rMSBit_59;
  logic rMSBitneg_59;
  logic switch_compare_1_60;
  logic signed [69:0] d_neg_in0_60;
  logic signed [69:0] d_neg_181;
  logic signed [68:0] d_neg_182;
  logic signed [68:0] y_119;
  logic signed [68:0] temp_62;
  logic [67:0] rMSBNextBits_60;
  logic [64:0] rLSBits_61;
  logic tempSignBit_60;
  logic qBit_60;
  logic [133:0] rNextTemp_60;
  logic signed [133:0] r61;
  logic signed [133:0] r61_p;
  logic [68:0] rMSBits_61;
  logic signed [68:0] x_62;
  logic rMSBit_60;
  logic rMSBitneg_60;
  logic switch_compare_1_61;
  logic signed [69:0] d_neg_in0_61;
  logic signed [69:0] d_neg_184;
  logic signed [68:0] d_neg_185;
  logic signed [68:0] y_121;
  logic signed [68:0] temp_63;
  logic [67:0] rMSBNextBits_61;
  logic [64:0] rLSBits_62;
  logic tempSignBit_61;
  logic qBit_61;
  logic [133:0] rNextTemp_61;
  logic signed [133:0] r62;
  logic signed [133:0] r62_p;
  logic [68:0] rMSBits_62;
  logic signed [68:0] x_63;
  logic rMSBit_61;
  logic rMSBitneg_61;
  logic switch_compare_1_62;
  logic signed [69:0] d_neg_in0_62;
  logic signed [69:0] d_neg_187;
  logic signed [68:0] d_neg_188;
  logic signed [68:0] y_123;
  logic signed [68:0] temp_64;
  logic [67:0] rMSBNextBits_62;
  logic [64:0] rLSBits_63;
  logic tempSignBit_62;
  logic qBit_62;
  logic [133:0] rNextTemp_62;
  logic signed [133:0] r63;
  logic signed [133:0] r63_p;
  logic [68:0] rMSBits_63;
  logic signed [68:0] x_64;
  logic rMSBit_62;
  logic rMSBitneg_62;
  logic switch_compare_1_63;
  logic signed [69:0] d_neg_in0_63;
  logic signed [69:0] d_neg_190;
  logic signed [68:0] d_neg_191;
  logic signed [68:0] y_125;
  logic signed [68:0] temp_65;
  logic [67:0] rMSBNextBits_63;
  logic [64:0] rLSBits_64;
  logic tempSignBit_63;
  logic qBit_63;
  logic [133:0] rNextTemp_63;
  logic signed [133:0] r64;
  logic signed [133:0] r64_p;
  logic [68:0] rMSBits_64;
  logic signed [68:0] x_65;
  logic rMSBit_63;
  logic rMSBitneg_63;
  logic switch_compare_1_64;
  logic signed [69:0] d_neg_in0_64;
  logic signed [69:0] d_neg_193;
  logic signed [68:0] d_neg_194;
  logic signed [68:0] y_127;
  logic signed [68:0] temp_66;
  logic [67:0] rMSBNextBits_64;
  logic [64:0] rLSBits_65;
  logic tempSignBit_64;
  logic qBit_64;
  logic [133:0] rNextTemp_64;
  logic signed [133:0] r65;
  logic signed [133:0] r65_p;
  logic [68:0] rMSBits_65;
  logic signed [68:0] x_66;
  logic rMSBit_64;
  logic rMSBitneg_64;
  logic switch_compare_1_65;
  logic signed [69:0] d_neg_in0_65;
  logic signed [69:0] d_neg_196;
  logic signed [68:0] d_neg_197;
  logic signed [68:0] y_129;
  logic signed [68:0] temp_67;
  logic [67:0] rMSBNextBits_65;
  logic [64:0] rLSBits_66;
  logic tempSignBit_65;
  logic qBit_65;
  logic [133:0] rNextTemp_65;
  logic signed [133:0] r66;
  logic signed [133:0] r66_p;
  logic [65:0] qTemp;
  logic rMSBit_65;
  logic switch_compare_1_66;
  logic [67:0] rMSBits_66;
  logic signed [67:0] rMSBits_dtc;
  logic signed [68:0] x_67;
  logic signed [68:0] add_correct_out;
  logic signed [68:0] corrected_rem_1;
  logic switch_compare_1_67;
  logic qIsOdd;
  logic signed [69:0] scaled_rem;
  logic signed [69:0] nextRem;
  logic signed [69:0] d_p_dtc;
  logic istie;
  logic needsTiebreak;
  logic isgreater;
  logic needsRounding;
  logic [65:0] incQ;
  logic [65:0] qRounded;
  logic [65:0] qround_remNZ;
  logic [65:0] q_post_calc;
  logic [65:0] qtempExt_p_1;
  logic [65:0] qtempPost;
  logic [65:0] qtempPost_p;
  logic [65:0] qtempPost_1;
  logic signed [63:0] qoutDTC;
  logic signed [63:0] recip_out_1;


  assign init_guard_true_1 = 1'b1;

  always_ff @(posedge clk)
    begin : matching_delays_process
      if (reset == 1'b1) begin
        matching_delays_reg <= '{default :1'b0};
      end
      else begin
        if (enb) begin
          matching_delays_reg[0] <= init_guard_true_1;
          matching_delays_reg[32'sd70:32'sd1] <= matching_delays_reg[32'sd69:32'sd0];
        end
      end
    end

  assign init_guard_true_2 = matching_delays_reg[70];

  assign recip_outinit_guard_default = 64'sh0000000000000000;

  assign trueFlag_1 = 1'b1;
  always_ff @(posedge clk)
    begin : initFlagDelay_process
      if (reset == 1'b1) begin
        initFlagDelayData <= 1'b0;
      end
      else begin
        if (enb) begin
          initFlagDelayData <= trueFlag_1;
        end
      end
    end
  always_ff @(posedge clk)
    begin : delayMatch_process
      if (reset == 1'b1) begin
        delayMatch_reg <= '{default :1'b0};
      end
      else begin
        if (enb) begin
          delayMatch_reg[0] <= initFlagDelayData;
          delayMatch_reg[32'sd67:32'sd1] <= delayMatch_reg[32'sd66:32'sd0];
        end
      end
    end

  assign initFlagDelayData_1 = delayMatch_reg[67];

  assign ConstantSignal_1 = 66'h00000000000000000;
  always_ff @(posedge clk)
    begin : Rin_p_process
      if (reset == 1'b1) begin
        Udc_reg <= 32'b00000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          Udc_reg <= recip_in;
        end
      end
    end
  assign d_ext = {37'b0, Udc_reg};
  assign Rin_MSB = d_ext[66];
  assign Unary_Minus_1 = {d_ext[68], d_ext};
  assign Unary_Minus_in0 =  - (Unary_Minus_1);
  assign unary_minus_d = Unary_Minus_in0[68:0];
  assign corrected_d = (Rin_MSB == 1'b0 ? d_ext :
              unary_minus_d);
  always_ff @(posedge clk)
    begin : corrected_d_p_process
      if (reset == 1'b1) begin
        corrected_d_p_1 <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          corrected_d_p_1 <= corrected_d;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_process
      if (reset == 1'b1) begin
        d1_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d1_p <= corrected_d_p_1;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_1_process
      if (reset == 1'b1) begin
        d2_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d2_p <= d1_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_2_process
      if (reset == 1'b1) begin
        d3_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d3_p <= d2_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_3_process
      if (reset == 1'b1) begin
        d4_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d4_p <= d3_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_4_process
      if (reset == 1'b1) begin
        d5_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d5_p <= d4_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_5_process
      if (reset == 1'b1) begin
        d6_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d6_p <= d5_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_6_process
      if (reset == 1'b1) begin
        d7_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d7_p <= d6_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_7_process
      if (reset == 1'b1) begin
        d8_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d8_p <= d7_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_8_process
      if (reset == 1'b1) begin
        d9_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d9_p <= d8_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_9_process
      if (reset == 1'b1) begin
        d10_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d10_p <= d9_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_10_process
      if (reset == 1'b1) begin
        d11_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d11_p <= d10_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_11_process
      if (reset == 1'b1) begin
        d12_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d12_p <= d11_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_12_process
      if (reset == 1'b1) begin
        d13_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d13_p <= d12_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_13_process
      if (reset == 1'b1) begin
        d14_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d14_p <= d13_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_14_process
      if (reset == 1'b1) begin
        d15_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d15_p <= d14_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_15_process
      if (reset == 1'b1) begin
        d16_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d16_p <= d15_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_16_process
      if (reset == 1'b1) begin
        d17_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d17_p <= d16_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_17_process
      if (reset == 1'b1) begin
        d18_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d18_p <= d17_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_18_process
      if (reset == 1'b1) begin
        d19_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d19_p <= d18_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_19_process
      if (reset == 1'b1) begin
        d20_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d20_p <= d19_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_20_process
      if (reset == 1'b1) begin
        d21_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d21_p <= d20_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_21_process
      if (reset == 1'b1) begin
        d22_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d22_p <= d21_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_22_process
      if (reset == 1'b1) begin
        d23_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d23_p <= d22_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_23_process
      if (reset == 1'b1) begin
        d24_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d24_p <= d23_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_24_process
      if (reset == 1'b1) begin
        d25_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d25_p <= d24_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_25_process
      if (reset == 1'b1) begin
        d26_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d26_p <= d25_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_26_process
      if (reset == 1'b1) begin
        d27_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d27_p <= d26_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_27_process
      if (reset == 1'b1) begin
        d28_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d28_p <= d27_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_28_process
      if (reset == 1'b1) begin
        d29_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d29_p <= d28_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_29_process
      if (reset == 1'b1) begin
        d30_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d30_p <= d29_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_30_process
      if (reset == 1'b1) begin
        d31_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d31_p <= d30_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_31_process
      if (reset == 1'b1) begin
        d32_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d32_p <= d31_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_32_process
      if (reset == 1'b1) begin
        d33_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d33_p <= d32_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_33_process
      if (reset == 1'b1) begin
        d34_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d34_p <= d33_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_34_process
      if (reset == 1'b1) begin
        d35_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d35_p <= d34_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_35_process
      if (reset == 1'b1) begin
        d36_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d36_p <= d35_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_36_process
      if (reset == 1'b1) begin
        d37_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d37_p <= d36_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_37_process
      if (reset == 1'b1) begin
        d38_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d38_p <= d37_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_38_process
      if (reset == 1'b1) begin
        d39_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d39_p <= d38_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_39_process
      if (reset == 1'b1) begin
        d40_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d40_p <= d39_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_40_process
      if (reset == 1'b1) begin
        d41_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d41_p <= d40_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_41_process
      if (reset == 1'b1) begin
        d42_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d42_p <= d41_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_42_process
      if (reset == 1'b1) begin
        d43_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d43_p <= d42_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_43_process
      if (reset == 1'b1) begin
        d44_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d44_p <= d43_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_44_process
      if (reset == 1'b1) begin
        d45_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d45_p <= d44_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_45_process
      if (reset == 1'b1) begin
        d46_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d46_p <= d45_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_46_process
      if (reset == 1'b1) begin
        d47_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d47_p <= d46_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_47_process
      if (reset == 1'b1) begin
        d48_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d48_p <= d47_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_48_process
      if (reset == 1'b1) begin
        d49_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d49_p <= d48_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_49_process
      if (reset == 1'b1) begin
        d50_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d50_p <= d49_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_50_process
      if (reset == 1'b1) begin
        d51_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d51_p <= d50_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_51_process
      if (reset == 1'b1) begin
        d52_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d52_p <= d51_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_52_process
      if (reset == 1'b1) begin
        d53_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d53_p <= d52_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_53_process
      if (reset == 1'b1) begin
        d54_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d54_p <= d53_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_54_process
      if (reset == 1'b1) begin
        d55_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d55_p <= d54_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_55_process
      if (reset == 1'b1) begin
        d56_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d56_p <= d55_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_56_process
      if (reset == 1'b1) begin
        d57_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d57_p <= d56_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_57_process
      if (reset == 1'b1) begin
        d58_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d58_p <= d57_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_58_process
      if (reset == 1'b1) begin
        d59_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d59_p <= d58_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_59_process
      if (reset == 1'b1) begin
        d60_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d60_p <= d59_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_60_process
      if (reset == 1'b1) begin
        d61_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d61_p <= d60_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_61_process
      if (reset == 1'b1) begin
        d62_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d62_p <= d61_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_62_process
      if (reset == 1'b1) begin
        d63_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d63_p <= d62_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_63_process
      if (reset == 1'b1) begin
        d64_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d64_p <= d63_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_64_process
      if (reset == 1'b1) begin
        d65_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d65_p <= d64_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_65_process
      if (reset == 1'b1) begin
        d66_p <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          d66_p <= d65_p;
        end
      end
    end
  assign switch_compare_1 = d66_p != 69'sh000000000000000000;

  assign constant_z_in = 66'sh10000000000000000;
  assign constant_z = {{68{constant_z_in[65]}}, constant_z_in};
  always_ff @(posedge clk)
    begin : corrected_z_p_process
      if (reset == 1'b1) begin
        corrected_z_p_1 <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          corrected_z_p_1 <= constant_z;
        end
      end
    end
  assign rMSBits = corrected_z_p_1[133:65];
  assign x = rMSBits;
  always_ff @(posedge clk)
    begin : delayMatch_1_process
      if (reset == 1'b1) begin
        x_1 <= 69'sh000000000000000000;
      end
      else begin
        if (enb) begin
          x_1 <= x;
        end
      end
    end

  assign d_neg_1 = {corrected_d_p_1[68], corrected_d_p_1};
  assign d_neg_in0 =  - (d_neg_1);
  assign d_neg_2 = d_neg_in0[68:0];
  assign temp = x_1 + d_neg_2;
  assign rMSBNextBits = temp[67:0];
  assign rLSBits = corrected_z_p_1[64:0];
  always_ff @(posedge clk)
    begin : delayMatch_2_process
      if (reset == 1'b1) begin
        rLSBits_1 <= 65'h00000000000000000;
      end
      else begin
        if (enb) begin
          rLSBits_1 <= rLSBits;
        end
      end
    end

  assign tempSignBit = temp[67];
  assign qBit =  ~ tempSignBit;
  assign rNextTemp = {rMSBNextBits, rLSBits_1, qBit};
  assign r1 = rNextTemp;
  always_ff @(posedge clk)
    begin : r_reg_process
      if (reset == 1'b1) begin
        r1_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r1_p <= r1;
        end
      end
    end
  assign rMSBits_1 = r1_p[133:65];
  assign x_2 = rMSBits_1;
  assign rMSBit = r1_p[133];
  assign rMSBitneg =  ~ rMSBit;
  assign switch_compare_1_1 = rMSBitneg > 1'b0;

  assign d_neg_4 = {d1_p[68], d1_p};
  assign d_neg_in0_1 =  - (d_neg_4);
  assign d_neg_5 = d_neg_in0_1[68:0];
  assign y_1 = (switch_compare_1_1 == 1'b0 ? d1_p :
              d_neg_5);
  assign temp_3 = x_2 + y_1;
  assign rMSBNextBits_1 = temp_3[67:0];
  assign rLSBits_2 = r1_p[64:0];
  assign tempSignBit_1 = temp_3[67];
  assign qBit_1 =  ~ tempSignBit_1;
  assign rNextTemp_1 = {rMSBNextBits_1, rLSBits_2, qBit_1};
  assign r2 = rNextTemp_1;
  always_ff @(posedge clk)
    begin : r_reg_1_process
      if (reset == 1'b1) begin
        r2_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r2_p <= r2;
        end
      end
    end
  assign rMSBits_2 = r2_p[133:65];
  assign x_3 = rMSBits_2;
  assign rMSBit_1 = r2_p[133];
  assign rMSBitneg_1 =  ~ rMSBit_1;
  assign switch_compare_1_2 = rMSBitneg_1 > 1'b0;

  assign d_neg_7 = {d2_p[68], d2_p};
  assign d_neg_in0_2 =  - (d_neg_7);
  assign d_neg_8 = d_neg_in0_2[68:0];
  assign y_3 = (switch_compare_1_2 == 1'b0 ? d2_p :
              d_neg_8);
  assign temp_4 = x_3 + y_3;
  assign rMSBNextBits_2 = temp_4[67:0];
  assign rLSBits_3 = r2_p[64:0];
  assign tempSignBit_2 = temp_4[67];
  assign qBit_2 =  ~ tempSignBit_2;
  assign rNextTemp_2 = {rMSBNextBits_2, rLSBits_3, qBit_2};
  assign r3 = rNextTemp_2;
  always_ff @(posedge clk)
    begin : r_reg_2_process
      if (reset == 1'b1) begin
        r3_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r3_p <= r3;
        end
      end
    end
  assign rMSBits_3 = r3_p[133:65];
  assign x_4 = rMSBits_3;
  assign rMSBit_2 = r3_p[133];
  assign rMSBitneg_2 =  ~ rMSBit_2;
  assign switch_compare_1_3 = rMSBitneg_2 > 1'b0;

  assign d_neg_10 = {d3_p[68], d3_p};
  assign d_neg_in0_3 =  - (d_neg_10);
  assign d_neg_11 = d_neg_in0_3[68:0];
  assign y_5 = (switch_compare_1_3 == 1'b0 ? d3_p :
              d_neg_11);
  assign temp_5 = x_4 + y_5;
  assign rMSBNextBits_3 = temp_5[67:0];
  assign rLSBits_4 = r3_p[64:0];
  assign tempSignBit_3 = temp_5[67];
  assign qBit_3 =  ~ tempSignBit_3;
  assign rNextTemp_3 = {rMSBNextBits_3, rLSBits_4, qBit_3};
  assign r4 = rNextTemp_3;
  always_ff @(posedge clk)
    begin : r_reg_3_process
      if (reset == 1'b1) begin
        r4_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r4_p <= r4;
        end
      end
    end
  assign rMSBits_4 = r4_p[133:65];
  assign x_5 = rMSBits_4;
  assign rMSBit_3 = r4_p[133];
  assign rMSBitneg_3 =  ~ rMSBit_3;
  assign switch_compare_1_4 = rMSBitneg_3 > 1'b0;

  assign d_neg_13 = {d4_p[68], d4_p};
  assign d_neg_in0_4 =  - (d_neg_13);
  assign d_neg_14 = d_neg_in0_4[68:0];
  assign y_7 = (switch_compare_1_4 == 1'b0 ? d4_p :
              d_neg_14);
  assign temp_6 = x_5 + y_7;
  assign rMSBNextBits_4 = temp_6[67:0];
  assign rLSBits_5 = r4_p[64:0];
  assign tempSignBit_4 = temp_6[67];
  assign qBit_4 =  ~ tempSignBit_4;
  assign rNextTemp_4 = {rMSBNextBits_4, rLSBits_5, qBit_4};
  assign r5 = rNextTemp_4;
  always_ff @(posedge clk)
    begin : r_reg_4_process
      if (reset == 1'b1) begin
        r5_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r5_p <= r5;
        end
      end
    end
  assign rMSBits_5 = r5_p[133:65];
  assign x_6 = rMSBits_5;
  assign rMSBit_4 = r5_p[133];
  assign rMSBitneg_4 =  ~ rMSBit_4;
  assign switch_compare_1_5 = rMSBitneg_4 > 1'b0;

  assign d_neg_16 = {d5_p[68], d5_p};
  assign d_neg_in0_5 =  - (d_neg_16);
  assign d_neg_17 = d_neg_in0_5[68:0];
  assign y_9 = (switch_compare_1_5 == 1'b0 ? d5_p :
              d_neg_17);
  assign temp_7 = x_6 + y_9;
  assign rMSBNextBits_5 = temp_7[67:0];
  assign rLSBits_6 = r5_p[64:0];
  assign tempSignBit_5 = temp_7[67];
  assign qBit_5 =  ~ tempSignBit_5;
  assign rNextTemp_5 = {rMSBNextBits_5, rLSBits_6, qBit_5};
  assign r6 = rNextTemp_5;
  always_ff @(posedge clk)
    begin : r_reg_5_process
      if (reset == 1'b1) begin
        r6_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r6_p <= r6;
        end
      end
    end
  assign rMSBits_6 = r6_p[133:65];
  assign x_7 = rMSBits_6;
  assign rMSBit_5 = r6_p[133];
  assign rMSBitneg_5 =  ~ rMSBit_5;
  assign switch_compare_1_6 = rMSBitneg_5 > 1'b0;

  assign d_neg_19 = {d6_p[68], d6_p};
  assign d_neg_in0_6 =  - (d_neg_19);
  assign d_neg_20 = d_neg_in0_6[68:0];
  assign y_11 = (switch_compare_1_6 == 1'b0 ? d6_p :
              d_neg_20);
  assign temp_8 = x_7 + y_11;
  assign rMSBNextBits_6 = temp_8[67:0];
  assign rLSBits_7 = r6_p[64:0];
  assign tempSignBit_6 = temp_8[67];
  assign qBit_6 =  ~ tempSignBit_6;
  assign rNextTemp_6 = {rMSBNextBits_6, rLSBits_7, qBit_6};
  assign r7 = rNextTemp_6;
  always_ff @(posedge clk)
    begin : r_reg_6_process
      if (reset == 1'b1) begin
        r7_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r7_p <= r7;
        end
      end
    end
  assign rMSBits_7 = r7_p[133:65];
  assign x_8 = rMSBits_7;
  assign rMSBit_6 = r7_p[133];
  assign rMSBitneg_6 =  ~ rMSBit_6;
  assign switch_compare_1_7 = rMSBitneg_6 > 1'b0;

  assign d_neg_22 = {d7_p[68], d7_p};
  assign d_neg_in0_7 =  - (d_neg_22);
  assign d_neg_23 = d_neg_in0_7[68:0];
  assign y_13 = (switch_compare_1_7 == 1'b0 ? d7_p :
              d_neg_23);
  assign temp_9 = x_8 + y_13;
  assign rMSBNextBits_7 = temp_9[67:0];
  assign rLSBits_8 = r7_p[64:0];
  assign tempSignBit_7 = temp_9[67];
  assign qBit_7 =  ~ tempSignBit_7;
  assign rNextTemp_7 = {rMSBNextBits_7, rLSBits_8, qBit_7};
  assign r8 = rNextTemp_7;
  always_ff @(posedge clk)
    begin : r_reg_7_process
      if (reset == 1'b1) begin
        r8_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r8_p <= r8;
        end
      end
    end
  assign rMSBits_8 = r8_p[133:65];
  assign x_9 = rMSBits_8;
  assign rMSBit_7 = r8_p[133];
  assign rMSBitneg_7 =  ~ rMSBit_7;
  assign switch_compare_1_8 = rMSBitneg_7 > 1'b0;

  assign d_neg_25 = {d8_p[68], d8_p};
  assign d_neg_in0_8 =  - (d_neg_25);
  assign d_neg_26 = d_neg_in0_8[68:0];
  assign y_15 = (switch_compare_1_8 == 1'b0 ? d8_p :
              d_neg_26);
  assign temp_10 = x_9 + y_15;
  assign rMSBNextBits_8 = temp_10[67:0];
  assign rLSBits_9 = r8_p[64:0];
  assign tempSignBit_8 = temp_10[67];
  assign qBit_8 =  ~ tempSignBit_8;
  assign rNextTemp_8 = {rMSBNextBits_8, rLSBits_9, qBit_8};
  assign r9 = rNextTemp_8;
  always_ff @(posedge clk)
    begin : r_reg_8_process
      if (reset == 1'b1) begin
        r9_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r9_p <= r9;
        end
      end
    end
  assign rMSBits_9 = r9_p[133:65];
  assign x_10 = rMSBits_9;
  assign rMSBit_8 = r9_p[133];
  assign rMSBitneg_8 =  ~ rMSBit_8;
  assign switch_compare_1_9 = rMSBitneg_8 > 1'b0;

  assign d_neg_28 = {d9_p[68], d9_p};
  assign d_neg_in0_9 =  - (d_neg_28);
  assign d_neg_29 = d_neg_in0_9[68:0];
  assign y_17 = (switch_compare_1_9 == 1'b0 ? d9_p :
              d_neg_29);
  assign temp_11 = x_10 + y_17;
  assign rMSBNextBits_9 = temp_11[67:0];
  assign rLSBits_10 = r9_p[64:0];
  assign tempSignBit_9 = temp_11[67];
  assign qBit_9 =  ~ tempSignBit_9;
  assign rNextTemp_9 = {rMSBNextBits_9, rLSBits_10, qBit_9};
  assign r10 = rNextTemp_9;
  always_ff @(posedge clk)
    begin : r_reg_9_process
      if (reset == 1'b1) begin
        r10_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r10_p <= r10;
        end
      end
    end
  assign rMSBits_10 = r10_p[133:65];
  assign x_11 = rMSBits_10;
  assign rMSBit_9 = r10_p[133];
  assign rMSBitneg_9 =  ~ rMSBit_9;
  assign switch_compare_1_10 = rMSBitneg_9 > 1'b0;

  assign d_neg_31 = {d10_p[68], d10_p};
  assign d_neg_in0_10 =  - (d_neg_31);
  assign d_neg_32 = d_neg_in0_10[68:0];
  assign y_19 = (switch_compare_1_10 == 1'b0 ? d10_p :
              d_neg_32);
  assign temp_12 = x_11 + y_19;
  assign rMSBNextBits_10 = temp_12[67:0];
  assign rLSBits_11 = r10_p[64:0];
  assign tempSignBit_10 = temp_12[67];
  assign qBit_10 =  ~ tempSignBit_10;
  assign rNextTemp_10 = {rMSBNextBits_10, rLSBits_11, qBit_10};
  assign r11 = rNextTemp_10;
  always_ff @(posedge clk)
    begin : r_reg_10_process
      if (reset == 1'b1) begin
        r11_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r11_p <= r11;
        end
      end
    end
  assign rMSBits_11 = r11_p[133:65];
  assign x_12 = rMSBits_11;
  assign rMSBit_10 = r11_p[133];
  assign rMSBitneg_10 =  ~ rMSBit_10;
  assign switch_compare_1_11 = rMSBitneg_10 > 1'b0;

  assign d_neg_34 = {d11_p[68], d11_p};
  assign d_neg_in0_11 =  - (d_neg_34);
  assign d_neg_35 = d_neg_in0_11[68:0];
  assign y_21 = (switch_compare_1_11 == 1'b0 ? d11_p :
              d_neg_35);
  assign temp_13 = x_12 + y_21;
  assign rMSBNextBits_11 = temp_13[67:0];
  assign rLSBits_12 = r11_p[64:0];
  assign tempSignBit_11 = temp_13[67];
  assign qBit_11 =  ~ tempSignBit_11;
  assign rNextTemp_11 = {rMSBNextBits_11, rLSBits_12, qBit_11};
  assign r12 = rNextTemp_11;
  always_ff @(posedge clk)
    begin : r_reg_11_process
      if (reset == 1'b1) begin
        r12_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r12_p <= r12;
        end
      end
    end
  assign rMSBits_12 = r12_p[133:65];
  assign x_13 = rMSBits_12;
  assign rMSBit_11 = r12_p[133];
  assign rMSBitneg_11 =  ~ rMSBit_11;
  assign switch_compare_1_12 = rMSBitneg_11 > 1'b0;

  assign d_neg_37 = {d12_p[68], d12_p};
  assign d_neg_in0_12 =  - (d_neg_37);
  assign d_neg_38 = d_neg_in0_12[68:0];
  assign y_23 = (switch_compare_1_12 == 1'b0 ? d12_p :
              d_neg_38);
  assign temp_14 = x_13 + y_23;
  assign rMSBNextBits_12 = temp_14[67:0];
  assign rLSBits_13 = r12_p[64:0];
  assign tempSignBit_12 = temp_14[67];
  assign qBit_12 =  ~ tempSignBit_12;
  assign rNextTemp_12 = {rMSBNextBits_12, rLSBits_13, qBit_12};
  assign r13 = rNextTemp_12;
  always_ff @(posedge clk)
    begin : r_reg_12_process
      if (reset == 1'b1) begin
        r13_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r13_p <= r13;
        end
      end
    end
  assign rMSBits_13 = r13_p[133:65];
  assign x_14 = rMSBits_13;
  assign rMSBit_12 = r13_p[133];
  assign rMSBitneg_12 =  ~ rMSBit_12;
  assign switch_compare_1_13 = rMSBitneg_12 > 1'b0;

  assign d_neg_40 = {d13_p[68], d13_p};
  assign d_neg_in0_13 =  - (d_neg_40);
  assign d_neg_41 = d_neg_in0_13[68:0];
  assign y_25 = (switch_compare_1_13 == 1'b0 ? d13_p :
              d_neg_41);
  assign temp_15 = x_14 + y_25;
  assign rMSBNextBits_13 = temp_15[67:0];
  assign rLSBits_14 = r13_p[64:0];
  assign tempSignBit_13 = temp_15[67];
  assign qBit_13 =  ~ tempSignBit_13;
  assign rNextTemp_13 = {rMSBNextBits_13, rLSBits_14, qBit_13};
  assign r14 = rNextTemp_13;
  always_ff @(posedge clk)
    begin : r_reg_13_process
      if (reset == 1'b1) begin
        r14_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r14_p <= r14;
        end
      end
    end
  assign rMSBits_14 = r14_p[133:65];
  assign x_15 = rMSBits_14;
  assign rMSBit_13 = r14_p[133];
  assign rMSBitneg_13 =  ~ rMSBit_13;
  assign switch_compare_1_14 = rMSBitneg_13 > 1'b0;

  assign d_neg_43 = {d14_p[68], d14_p};
  assign d_neg_in0_14 =  - (d_neg_43);
  assign d_neg_44 = d_neg_in0_14[68:0];
  assign y_27 = (switch_compare_1_14 == 1'b0 ? d14_p :
              d_neg_44);
  assign temp_16 = x_15 + y_27;
  assign rMSBNextBits_14 = temp_16[67:0];
  assign rLSBits_15 = r14_p[64:0];
  assign tempSignBit_14 = temp_16[67];
  assign qBit_14 =  ~ tempSignBit_14;
  assign rNextTemp_14 = {rMSBNextBits_14, rLSBits_15, qBit_14};
  assign r15 = rNextTemp_14;
  always_ff @(posedge clk)
    begin : r_reg_14_process
      if (reset == 1'b1) begin
        r15_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r15_p <= r15;
        end
      end
    end
  assign rMSBits_15 = r15_p[133:65];
  assign x_16 = rMSBits_15;
  assign rMSBit_14 = r15_p[133];
  assign rMSBitneg_14 =  ~ rMSBit_14;
  assign switch_compare_1_15 = rMSBitneg_14 > 1'b0;

  assign d_neg_46 = {d15_p[68], d15_p};
  assign d_neg_in0_15 =  - (d_neg_46);
  assign d_neg_47 = d_neg_in0_15[68:0];
  assign y_29 = (switch_compare_1_15 == 1'b0 ? d15_p :
              d_neg_47);
  assign temp_17 = x_16 + y_29;
  assign rMSBNextBits_15 = temp_17[67:0];
  assign rLSBits_16 = r15_p[64:0];
  assign tempSignBit_15 = temp_17[67];
  assign qBit_15 =  ~ tempSignBit_15;
  assign rNextTemp_15 = {rMSBNextBits_15, rLSBits_16, qBit_15};
  assign r16 = rNextTemp_15;
  always_ff @(posedge clk)
    begin : r_reg_15_process
      if (reset == 1'b1) begin
        r16_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r16_p <= r16;
        end
      end
    end
  assign rMSBits_16 = r16_p[133:65];
  assign x_17 = rMSBits_16;
  assign rMSBit_15 = r16_p[133];
  assign rMSBitneg_15 =  ~ rMSBit_15;
  assign switch_compare_1_16 = rMSBitneg_15 > 1'b0;

  assign d_neg_49 = {d16_p[68], d16_p};
  assign d_neg_in0_16 =  - (d_neg_49);
  assign d_neg_50 = d_neg_in0_16[68:0];
  assign y_31 = (switch_compare_1_16 == 1'b0 ? d16_p :
              d_neg_50);
  assign temp_18 = x_17 + y_31;
  assign rMSBNextBits_16 = temp_18[67:0];
  assign rLSBits_17 = r16_p[64:0];
  assign tempSignBit_16 = temp_18[67];
  assign qBit_16 =  ~ tempSignBit_16;
  assign rNextTemp_16 = {rMSBNextBits_16, rLSBits_17, qBit_16};
  assign r17 = rNextTemp_16;
  always_ff @(posedge clk)
    begin : r_reg_16_process
      if (reset == 1'b1) begin
        r17_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r17_p <= r17;
        end
      end
    end
  assign rMSBits_17 = r17_p[133:65];
  assign x_18 = rMSBits_17;
  assign rMSBit_16 = r17_p[133];
  assign rMSBitneg_16 =  ~ rMSBit_16;
  assign switch_compare_1_17 = rMSBitneg_16 > 1'b0;

  assign d_neg_52 = {d17_p[68], d17_p};
  assign d_neg_in0_17 =  - (d_neg_52);
  assign d_neg_53 = d_neg_in0_17[68:0];
  assign y_33 = (switch_compare_1_17 == 1'b0 ? d17_p :
              d_neg_53);
  assign temp_19 = x_18 + y_33;
  assign rMSBNextBits_17 = temp_19[67:0];
  assign rLSBits_18 = r17_p[64:0];
  assign tempSignBit_17 = temp_19[67];
  assign qBit_17 =  ~ tempSignBit_17;
  assign rNextTemp_17 = {rMSBNextBits_17, rLSBits_18, qBit_17};
  assign r18 = rNextTemp_17;
  always_ff @(posedge clk)
    begin : r_reg_17_process
      if (reset == 1'b1) begin
        r18_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r18_p <= r18;
        end
      end
    end
  assign rMSBits_18 = r18_p[133:65];
  assign x_19 = rMSBits_18;
  assign rMSBit_17 = r18_p[133];
  assign rMSBitneg_17 =  ~ rMSBit_17;
  assign switch_compare_1_18 = rMSBitneg_17 > 1'b0;

  assign d_neg_55 = {d18_p[68], d18_p};
  assign d_neg_in0_18 =  - (d_neg_55);
  assign d_neg_56 = d_neg_in0_18[68:0];
  assign y_35 = (switch_compare_1_18 == 1'b0 ? d18_p :
              d_neg_56);
  assign temp_20 = x_19 + y_35;
  assign rMSBNextBits_18 = temp_20[67:0];
  assign rLSBits_19 = r18_p[64:0];
  assign tempSignBit_18 = temp_20[67];
  assign qBit_18 =  ~ tempSignBit_18;
  assign rNextTemp_18 = {rMSBNextBits_18, rLSBits_19, qBit_18};
  assign r19 = rNextTemp_18;
  always_ff @(posedge clk)
    begin : r_reg_18_process
      if (reset == 1'b1) begin
        r19_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r19_p <= r19;
        end
      end
    end
  assign rMSBits_19 = r19_p[133:65];
  assign x_20 = rMSBits_19;
  assign rMSBit_18 = r19_p[133];
  assign rMSBitneg_18 =  ~ rMSBit_18;
  assign switch_compare_1_19 = rMSBitneg_18 > 1'b0;

  assign d_neg_58 = {d19_p[68], d19_p};
  assign d_neg_in0_19 =  - (d_neg_58);
  assign d_neg_59 = d_neg_in0_19[68:0];
  assign y_37 = (switch_compare_1_19 == 1'b0 ? d19_p :
              d_neg_59);
  assign temp_21 = x_20 + y_37;
  assign rMSBNextBits_19 = temp_21[67:0];
  assign rLSBits_20 = r19_p[64:0];
  assign tempSignBit_19 = temp_21[67];
  assign qBit_19 =  ~ tempSignBit_19;
  assign rNextTemp_19 = {rMSBNextBits_19, rLSBits_20, qBit_19};
  assign r20 = rNextTemp_19;
  always_ff @(posedge clk)
    begin : r_reg_19_process
      if (reset == 1'b1) begin
        r20_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r20_p <= r20;
        end
      end
    end
  assign rMSBits_20 = r20_p[133:65];
  assign x_21 = rMSBits_20;
  assign rMSBit_19 = r20_p[133];
  assign rMSBitneg_19 =  ~ rMSBit_19;
  assign switch_compare_1_20 = rMSBitneg_19 > 1'b0;

  assign d_neg_61 = {d20_p[68], d20_p};
  assign d_neg_in0_20 =  - (d_neg_61);
  assign d_neg_62 = d_neg_in0_20[68:0];
  assign y_39 = (switch_compare_1_20 == 1'b0 ? d20_p :
              d_neg_62);
  assign temp_22 = x_21 + y_39;
  assign rMSBNextBits_20 = temp_22[67:0];
  assign rLSBits_21 = r20_p[64:0];
  assign tempSignBit_20 = temp_22[67];
  assign qBit_20 =  ~ tempSignBit_20;
  assign rNextTemp_20 = {rMSBNextBits_20, rLSBits_21, qBit_20};
  assign r21 = rNextTemp_20;
  always_ff @(posedge clk)
    begin : r_reg_20_process
      if (reset == 1'b1) begin
        r21_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r21_p <= r21;
        end
      end
    end
  assign rMSBits_21 = r21_p[133:65];
  assign x_22 = rMSBits_21;
  assign rMSBit_20 = r21_p[133];
  assign rMSBitneg_20 =  ~ rMSBit_20;
  assign switch_compare_1_21 = rMSBitneg_20 > 1'b0;

  assign d_neg_64 = {d21_p[68], d21_p};
  assign d_neg_in0_21 =  - (d_neg_64);
  assign d_neg_65 = d_neg_in0_21[68:0];
  assign y_41 = (switch_compare_1_21 == 1'b0 ? d21_p :
              d_neg_65);
  assign temp_23 = x_22 + y_41;
  assign rMSBNextBits_21 = temp_23[67:0];
  assign rLSBits_22 = r21_p[64:0];
  assign tempSignBit_21 = temp_23[67];
  assign qBit_21 =  ~ tempSignBit_21;
  assign rNextTemp_21 = {rMSBNextBits_21, rLSBits_22, qBit_21};
  assign r22 = rNextTemp_21;
  always_ff @(posedge clk)
    begin : r_reg_21_process
      if (reset == 1'b1) begin
        r22_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r22_p <= r22;
        end
      end
    end
  assign rMSBits_22 = r22_p[133:65];
  assign x_23 = rMSBits_22;
  assign rMSBit_21 = r22_p[133];
  assign rMSBitneg_21 =  ~ rMSBit_21;
  assign switch_compare_1_22 = rMSBitneg_21 > 1'b0;

  assign d_neg_67 = {d22_p[68], d22_p};
  assign d_neg_in0_22 =  - (d_neg_67);
  assign d_neg_68 = d_neg_in0_22[68:0];
  assign y_43 = (switch_compare_1_22 == 1'b0 ? d22_p :
              d_neg_68);
  assign temp_24 = x_23 + y_43;
  assign rMSBNextBits_22 = temp_24[67:0];
  assign rLSBits_23 = r22_p[64:0];
  assign tempSignBit_22 = temp_24[67];
  assign qBit_22 =  ~ tempSignBit_22;
  assign rNextTemp_22 = {rMSBNextBits_22, rLSBits_23, qBit_22};
  assign r23 = rNextTemp_22;
  always_ff @(posedge clk)
    begin : r_reg_22_process
      if (reset == 1'b1) begin
        r23_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r23_p <= r23;
        end
      end
    end
  assign rMSBits_23 = r23_p[133:65];
  assign x_24 = rMSBits_23;
  assign rMSBit_22 = r23_p[133];
  assign rMSBitneg_22 =  ~ rMSBit_22;
  assign switch_compare_1_23 = rMSBitneg_22 > 1'b0;

  assign d_neg_70 = {d23_p[68], d23_p};
  assign d_neg_in0_23 =  - (d_neg_70);
  assign d_neg_71 = d_neg_in0_23[68:0];
  assign y_45 = (switch_compare_1_23 == 1'b0 ? d23_p :
              d_neg_71);
  assign temp_25 = x_24 + y_45;
  assign rMSBNextBits_23 = temp_25[67:0];
  assign rLSBits_24 = r23_p[64:0];
  assign tempSignBit_23 = temp_25[67];
  assign qBit_23 =  ~ tempSignBit_23;
  assign rNextTemp_23 = {rMSBNextBits_23, rLSBits_24, qBit_23};
  assign r24 = rNextTemp_23;
  always_ff @(posedge clk)
    begin : r_reg_23_process
      if (reset == 1'b1) begin
        r24_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r24_p <= r24;
        end
      end
    end
  assign rMSBits_24 = r24_p[133:65];
  assign x_25 = rMSBits_24;
  assign rMSBit_23 = r24_p[133];
  assign rMSBitneg_23 =  ~ rMSBit_23;
  assign switch_compare_1_24 = rMSBitneg_23 > 1'b0;

  assign d_neg_73 = {d24_p[68], d24_p};
  assign d_neg_in0_24 =  - (d_neg_73);
  assign d_neg_74 = d_neg_in0_24[68:0];
  assign y_47 = (switch_compare_1_24 == 1'b0 ? d24_p :
              d_neg_74);
  assign temp_26 = x_25 + y_47;
  assign rMSBNextBits_24 = temp_26[67:0];
  assign rLSBits_25 = r24_p[64:0];
  assign tempSignBit_24 = temp_26[67];
  assign qBit_24 =  ~ tempSignBit_24;
  assign rNextTemp_24 = {rMSBNextBits_24, rLSBits_25, qBit_24};
  assign r25 = rNextTemp_24;
  always_ff @(posedge clk)
    begin : r_reg_24_process
      if (reset == 1'b1) begin
        r25_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r25_p <= r25;
        end
      end
    end
  assign rMSBits_25 = r25_p[133:65];
  assign x_26 = rMSBits_25;
  assign rMSBit_24 = r25_p[133];
  assign rMSBitneg_24 =  ~ rMSBit_24;
  assign switch_compare_1_25 = rMSBitneg_24 > 1'b0;

  assign d_neg_76 = {d25_p[68], d25_p};
  assign d_neg_in0_25 =  - (d_neg_76);
  assign d_neg_77 = d_neg_in0_25[68:0];
  assign y_49 = (switch_compare_1_25 == 1'b0 ? d25_p :
              d_neg_77);
  assign temp_27 = x_26 + y_49;
  assign rMSBNextBits_25 = temp_27[67:0];
  assign rLSBits_26 = r25_p[64:0];
  assign tempSignBit_25 = temp_27[67];
  assign qBit_25 =  ~ tempSignBit_25;
  assign rNextTemp_25 = {rMSBNextBits_25, rLSBits_26, qBit_25};
  assign r26 = rNextTemp_25;
  always_ff @(posedge clk)
    begin : r_reg_25_process
      if (reset == 1'b1) begin
        r26_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r26_p <= r26;
        end
      end
    end
  assign rMSBits_26 = r26_p[133:65];
  assign x_27 = rMSBits_26;
  assign rMSBit_25 = r26_p[133];
  assign rMSBitneg_25 =  ~ rMSBit_25;
  assign switch_compare_1_26 = rMSBitneg_25 > 1'b0;

  assign d_neg_79 = {d26_p[68], d26_p};
  assign d_neg_in0_26 =  - (d_neg_79);
  assign d_neg_80 = d_neg_in0_26[68:0];
  assign y_51 = (switch_compare_1_26 == 1'b0 ? d26_p :
              d_neg_80);
  assign temp_28 = x_27 + y_51;
  assign rMSBNextBits_26 = temp_28[67:0];
  assign rLSBits_27 = r26_p[64:0];
  assign tempSignBit_26 = temp_28[67];
  assign qBit_26 =  ~ tempSignBit_26;
  assign rNextTemp_26 = {rMSBNextBits_26, rLSBits_27, qBit_26};
  assign r27 = rNextTemp_26;
  always_ff @(posedge clk)
    begin : r_reg_26_process
      if (reset == 1'b1) begin
        r27_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r27_p <= r27;
        end
      end
    end
  assign rMSBits_27 = r27_p[133:65];
  assign x_28 = rMSBits_27;
  assign rMSBit_26 = r27_p[133];
  assign rMSBitneg_26 =  ~ rMSBit_26;
  assign switch_compare_1_27 = rMSBitneg_26 > 1'b0;

  assign d_neg_82 = {d27_p[68], d27_p};
  assign d_neg_in0_27 =  - (d_neg_82);
  assign d_neg_83 = d_neg_in0_27[68:0];
  assign y_53 = (switch_compare_1_27 == 1'b0 ? d27_p :
              d_neg_83);
  assign temp_29 = x_28 + y_53;
  assign rMSBNextBits_27 = temp_29[67:0];
  assign rLSBits_28 = r27_p[64:0];
  assign tempSignBit_27 = temp_29[67];
  assign qBit_27 =  ~ tempSignBit_27;
  assign rNextTemp_27 = {rMSBNextBits_27, rLSBits_28, qBit_27};
  assign r28 = rNextTemp_27;
  always_ff @(posedge clk)
    begin : r_reg_27_process
      if (reset == 1'b1) begin
        r28_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r28_p <= r28;
        end
      end
    end
  assign rMSBits_28 = r28_p[133:65];
  assign x_29 = rMSBits_28;
  assign rMSBit_27 = r28_p[133];
  assign rMSBitneg_27 =  ~ rMSBit_27;
  assign switch_compare_1_28 = rMSBitneg_27 > 1'b0;

  assign d_neg_85 = {d28_p[68], d28_p};
  assign d_neg_in0_28 =  - (d_neg_85);
  assign d_neg_86 = d_neg_in0_28[68:0];
  assign y_55 = (switch_compare_1_28 == 1'b0 ? d28_p :
              d_neg_86);
  assign temp_30 = x_29 + y_55;
  assign rMSBNextBits_28 = temp_30[67:0];
  assign rLSBits_29 = r28_p[64:0];
  assign tempSignBit_28 = temp_30[67];
  assign qBit_28 =  ~ tempSignBit_28;
  assign rNextTemp_28 = {rMSBNextBits_28, rLSBits_29, qBit_28};
  assign r29 = rNextTemp_28;
  always_ff @(posedge clk)
    begin : r_reg_28_process
      if (reset == 1'b1) begin
        r29_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r29_p <= r29;
        end
      end
    end
  assign rMSBits_29 = r29_p[133:65];
  assign x_30 = rMSBits_29;
  assign rMSBit_28 = r29_p[133];
  assign rMSBitneg_28 =  ~ rMSBit_28;
  assign switch_compare_1_29 = rMSBitneg_28 > 1'b0;

  assign d_neg_88 = {d29_p[68], d29_p};
  assign d_neg_in0_29 =  - (d_neg_88);
  assign d_neg_89 = d_neg_in0_29[68:0];
  assign y_57 = (switch_compare_1_29 == 1'b0 ? d29_p :
              d_neg_89);
  assign temp_31 = x_30 + y_57;
  assign rMSBNextBits_29 = temp_31[67:0];
  assign rLSBits_30 = r29_p[64:0];
  assign tempSignBit_29 = temp_31[67];
  assign qBit_29 =  ~ tempSignBit_29;
  assign rNextTemp_29 = {rMSBNextBits_29, rLSBits_30, qBit_29};
  assign r30 = rNextTemp_29;
  always_ff @(posedge clk)
    begin : r_reg_29_process
      if (reset == 1'b1) begin
        r30_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r30_p <= r30;
        end
      end
    end
  assign rMSBits_30 = r30_p[133:65];
  assign x_31 = rMSBits_30;
  assign rMSBit_29 = r30_p[133];
  assign rMSBitneg_29 =  ~ rMSBit_29;
  assign switch_compare_1_30 = rMSBitneg_29 > 1'b0;

  assign d_neg_91 = {d30_p[68], d30_p};
  assign d_neg_in0_30 =  - (d_neg_91);
  assign d_neg_92 = d_neg_in0_30[68:0];
  assign y_59 = (switch_compare_1_30 == 1'b0 ? d30_p :
              d_neg_92);
  assign temp_32 = x_31 + y_59;
  assign rMSBNextBits_30 = temp_32[67:0];
  assign rLSBits_31 = r30_p[64:0];
  assign tempSignBit_30 = temp_32[67];
  assign qBit_30 =  ~ tempSignBit_30;
  assign rNextTemp_30 = {rMSBNextBits_30, rLSBits_31, qBit_30};
  assign r31 = rNextTemp_30;
  always_ff @(posedge clk)
    begin : r_reg_30_process
      if (reset == 1'b1) begin
        r31_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r31_p <= r31;
        end
      end
    end
  assign rMSBits_31 = r31_p[133:65];
  assign x_32 = rMSBits_31;
  assign rMSBit_30 = r31_p[133];
  assign rMSBitneg_30 =  ~ rMSBit_30;
  assign switch_compare_1_31 = rMSBitneg_30 > 1'b0;

  assign d_neg_94 = {d31_p[68], d31_p};
  assign d_neg_in0_31 =  - (d_neg_94);
  assign d_neg_95 = d_neg_in0_31[68:0];
  assign y_61 = (switch_compare_1_31 == 1'b0 ? d31_p :
              d_neg_95);
  assign temp_33 = x_32 + y_61;
  assign rMSBNextBits_31 = temp_33[67:0];
  assign rLSBits_32 = r31_p[64:0];
  assign tempSignBit_31 = temp_33[67];
  assign qBit_31 =  ~ tempSignBit_31;
  assign rNextTemp_31 = {rMSBNextBits_31, rLSBits_32, qBit_31};
  assign r32 = rNextTemp_31;
  always_ff @(posedge clk)
    begin : r_reg_31_process
      if (reset == 1'b1) begin
        r32_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r32_p <= r32;
        end
      end
    end
  assign rMSBits_32 = r32_p[133:65];
  assign x_33 = rMSBits_32;
  assign rMSBit_31 = r32_p[133];
  assign rMSBitneg_31 =  ~ rMSBit_31;
  assign switch_compare_1_32 = rMSBitneg_31 > 1'b0;

  assign d_neg_97 = {d32_p[68], d32_p};
  assign d_neg_in0_32 =  - (d_neg_97);
  assign d_neg_98 = d_neg_in0_32[68:0];
  assign y_63 = (switch_compare_1_32 == 1'b0 ? d32_p :
              d_neg_98);
  assign temp_34 = x_33 + y_63;
  assign rMSBNextBits_32 = temp_34[67:0];
  assign rLSBits_33 = r32_p[64:0];
  assign tempSignBit_32 = temp_34[67];
  assign qBit_32 =  ~ tempSignBit_32;
  assign rNextTemp_32 = {rMSBNextBits_32, rLSBits_33, qBit_32};
  assign r33 = rNextTemp_32;
  always_ff @(posedge clk)
    begin : r_reg_32_process
      if (reset == 1'b1) begin
        r33_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r33_p <= r33;
        end
      end
    end
  assign rMSBits_33 = r33_p[133:65];
  assign x_34 = rMSBits_33;
  assign rMSBit_32 = r33_p[133];
  assign rMSBitneg_32 =  ~ rMSBit_32;
  assign switch_compare_1_33 = rMSBitneg_32 > 1'b0;

  assign d_neg_100 = {d33_p[68], d33_p};
  assign d_neg_in0_33 =  - (d_neg_100);
  assign d_neg_101 = d_neg_in0_33[68:0];
  assign y_65 = (switch_compare_1_33 == 1'b0 ? d33_p :
              d_neg_101);
  assign temp_35 = x_34 + y_65;
  assign rMSBNextBits_33 = temp_35[67:0];
  assign rLSBits_34 = r33_p[64:0];
  assign tempSignBit_33 = temp_35[67];
  assign qBit_33 =  ~ tempSignBit_33;
  assign rNextTemp_33 = {rMSBNextBits_33, rLSBits_34, qBit_33};
  assign r34 = rNextTemp_33;
  always_ff @(posedge clk)
    begin : r_reg_33_process
      if (reset == 1'b1) begin
        r34_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r34_p <= r34;
        end
      end
    end
  assign rMSBits_34 = r34_p[133:65];
  assign x_35 = rMSBits_34;
  assign rMSBit_33 = r34_p[133];
  assign rMSBitneg_33 =  ~ rMSBit_33;
  assign switch_compare_1_34 = rMSBitneg_33 > 1'b0;

  assign d_neg_103 = {d34_p[68], d34_p};
  assign d_neg_in0_34 =  - (d_neg_103);
  assign d_neg_104 = d_neg_in0_34[68:0];
  assign y_67 = (switch_compare_1_34 == 1'b0 ? d34_p :
              d_neg_104);
  assign temp_36 = x_35 + y_67;
  assign rMSBNextBits_34 = temp_36[67:0];
  assign rLSBits_35 = r34_p[64:0];
  assign tempSignBit_34 = temp_36[67];
  assign qBit_34 =  ~ tempSignBit_34;
  assign rNextTemp_34 = {rMSBNextBits_34, rLSBits_35, qBit_34};
  assign r35 = rNextTemp_34;
  always_ff @(posedge clk)
    begin : r_reg_34_process
      if (reset == 1'b1) begin
        r35_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r35_p <= r35;
        end
      end
    end
  assign rMSBits_35 = r35_p[133:65];
  assign x_36 = rMSBits_35;
  assign rMSBit_34 = r35_p[133];
  assign rMSBitneg_34 =  ~ rMSBit_34;
  assign switch_compare_1_35 = rMSBitneg_34 > 1'b0;

  assign d_neg_106 = {d35_p[68], d35_p};
  assign d_neg_in0_35 =  - (d_neg_106);
  assign d_neg_107 = d_neg_in0_35[68:0];
  assign y_69 = (switch_compare_1_35 == 1'b0 ? d35_p :
              d_neg_107);
  assign temp_37 = x_36 + y_69;
  assign rMSBNextBits_35 = temp_37[67:0];
  assign rLSBits_36 = r35_p[64:0];
  assign tempSignBit_35 = temp_37[67];
  assign qBit_35 =  ~ tempSignBit_35;
  assign rNextTemp_35 = {rMSBNextBits_35, rLSBits_36, qBit_35};
  assign r36 = rNextTemp_35;
  always_ff @(posedge clk)
    begin : r_reg_35_process
      if (reset == 1'b1) begin
        r36_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r36_p <= r36;
        end
      end
    end
  assign rMSBits_36 = r36_p[133:65];
  assign x_37 = rMSBits_36;
  assign rMSBit_35 = r36_p[133];
  assign rMSBitneg_35 =  ~ rMSBit_35;
  assign switch_compare_1_36 = rMSBitneg_35 > 1'b0;

  assign d_neg_109 = {d36_p[68], d36_p};
  assign d_neg_in0_36 =  - (d_neg_109);
  assign d_neg_110 = d_neg_in0_36[68:0];
  assign y_71 = (switch_compare_1_36 == 1'b0 ? d36_p :
              d_neg_110);
  assign temp_38 = x_37 + y_71;
  assign rMSBNextBits_36 = temp_38[67:0];
  assign rLSBits_37 = r36_p[64:0];
  assign tempSignBit_36 = temp_38[67];
  assign qBit_36 =  ~ tempSignBit_36;
  assign rNextTemp_36 = {rMSBNextBits_36, rLSBits_37, qBit_36};
  assign r37 = rNextTemp_36;
  always_ff @(posedge clk)
    begin : r_reg_36_process
      if (reset == 1'b1) begin
        r37_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r37_p <= r37;
        end
      end
    end
  assign rMSBits_37 = r37_p[133:65];
  assign x_38 = rMSBits_37;
  assign rMSBit_36 = r37_p[133];
  assign rMSBitneg_36 =  ~ rMSBit_36;
  assign switch_compare_1_37 = rMSBitneg_36 > 1'b0;

  assign d_neg_112 = {d37_p[68], d37_p};
  assign d_neg_in0_37 =  - (d_neg_112);
  assign d_neg_113 = d_neg_in0_37[68:0];
  assign y_73 = (switch_compare_1_37 == 1'b0 ? d37_p :
              d_neg_113);
  assign temp_39 = x_38 + y_73;
  assign rMSBNextBits_37 = temp_39[67:0];
  assign rLSBits_38 = r37_p[64:0];
  assign tempSignBit_37 = temp_39[67];
  assign qBit_37 =  ~ tempSignBit_37;
  assign rNextTemp_37 = {rMSBNextBits_37, rLSBits_38, qBit_37};
  assign r38 = rNextTemp_37;
  always_ff @(posedge clk)
    begin : r_reg_37_process
      if (reset == 1'b1) begin
        r38_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r38_p <= r38;
        end
      end
    end
  assign rMSBits_38 = r38_p[133:65];
  assign x_39 = rMSBits_38;
  assign rMSBit_37 = r38_p[133];
  assign rMSBitneg_37 =  ~ rMSBit_37;
  assign switch_compare_1_38 = rMSBitneg_37 > 1'b0;

  assign d_neg_115 = {d38_p[68], d38_p};
  assign d_neg_in0_38 =  - (d_neg_115);
  assign d_neg_116 = d_neg_in0_38[68:0];
  assign y_75 = (switch_compare_1_38 == 1'b0 ? d38_p :
              d_neg_116);
  assign temp_40 = x_39 + y_75;
  assign rMSBNextBits_38 = temp_40[67:0];
  assign rLSBits_39 = r38_p[64:0];
  assign tempSignBit_38 = temp_40[67];
  assign qBit_38 =  ~ tempSignBit_38;
  assign rNextTemp_38 = {rMSBNextBits_38, rLSBits_39, qBit_38};
  assign r39 = rNextTemp_38;
  always_ff @(posedge clk)
    begin : r_reg_38_process
      if (reset == 1'b1) begin
        r39_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r39_p <= r39;
        end
      end
    end
  assign rMSBits_39 = r39_p[133:65];
  assign x_40 = rMSBits_39;
  assign rMSBit_38 = r39_p[133];
  assign rMSBitneg_38 =  ~ rMSBit_38;
  assign switch_compare_1_39 = rMSBitneg_38 > 1'b0;

  assign d_neg_118 = {d39_p[68], d39_p};
  assign d_neg_in0_39 =  - (d_neg_118);
  assign d_neg_119 = d_neg_in0_39[68:0];
  assign y_77 = (switch_compare_1_39 == 1'b0 ? d39_p :
              d_neg_119);
  assign temp_41 = x_40 + y_77;
  assign rMSBNextBits_39 = temp_41[67:0];
  assign rLSBits_40 = r39_p[64:0];
  assign tempSignBit_39 = temp_41[67];
  assign qBit_39 =  ~ tempSignBit_39;
  assign rNextTemp_39 = {rMSBNextBits_39, rLSBits_40, qBit_39};
  assign r40 = rNextTemp_39;
  always_ff @(posedge clk)
    begin : r_reg_39_process
      if (reset == 1'b1) begin
        r40_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r40_p <= r40;
        end
      end
    end
  assign rMSBits_40 = r40_p[133:65];
  assign x_41 = rMSBits_40;
  assign rMSBit_39 = r40_p[133];
  assign rMSBitneg_39 =  ~ rMSBit_39;
  assign switch_compare_1_40 = rMSBitneg_39 > 1'b0;

  assign d_neg_121 = {d40_p[68], d40_p};
  assign d_neg_in0_40 =  - (d_neg_121);
  assign d_neg_122 = d_neg_in0_40[68:0];
  assign y_79 = (switch_compare_1_40 == 1'b0 ? d40_p :
              d_neg_122);
  assign temp_42 = x_41 + y_79;
  assign rMSBNextBits_40 = temp_42[67:0];
  assign rLSBits_41 = r40_p[64:0];
  assign tempSignBit_40 = temp_42[67];
  assign qBit_40 =  ~ tempSignBit_40;
  assign rNextTemp_40 = {rMSBNextBits_40, rLSBits_41, qBit_40};
  assign r41 = rNextTemp_40;
  always_ff @(posedge clk)
    begin : r_reg_40_process
      if (reset == 1'b1) begin
        r41_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r41_p <= r41;
        end
      end
    end
  assign rMSBits_41 = r41_p[133:65];
  assign x_42 = rMSBits_41;
  assign rMSBit_40 = r41_p[133];
  assign rMSBitneg_40 =  ~ rMSBit_40;
  assign switch_compare_1_41 = rMSBitneg_40 > 1'b0;

  assign d_neg_124 = {d41_p[68], d41_p};
  assign d_neg_in0_41 =  - (d_neg_124);
  assign d_neg_125 = d_neg_in0_41[68:0];
  assign y_81 = (switch_compare_1_41 == 1'b0 ? d41_p :
              d_neg_125);
  assign temp_43 = x_42 + y_81;
  assign rMSBNextBits_41 = temp_43[67:0];
  assign rLSBits_42 = r41_p[64:0];
  assign tempSignBit_41 = temp_43[67];
  assign qBit_41 =  ~ tempSignBit_41;
  assign rNextTemp_41 = {rMSBNextBits_41, rLSBits_42, qBit_41};
  assign r42 = rNextTemp_41;
  always_ff @(posedge clk)
    begin : r_reg_41_process
      if (reset == 1'b1) begin
        r42_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r42_p <= r42;
        end
      end
    end
  assign rMSBits_42 = r42_p[133:65];
  assign x_43 = rMSBits_42;
  assign rMSBit_41 = r42_p[133];
  assign rMSBitneg_41 =  ~ rMSBit_41;
  assign switch_compare_1_42 = rMSBitneg_41 > 1'b0;

  assign d_neg_127 = {d42_p[68], d42_p};
  assign d_neg_in0_42 =  - (d_neg_127);
  assign d_neg_128 = d_neg_in0_42[68:0];
  assign y_83 = (switch_compare_1_42 == 1'b0 ? d42_p :
              d_neg_128);
  assign temp_44 = x_43 + y_83;
  assign rMSBNextBits_42 = temp_44[67:0];
  assign rLSBits_43 = r42_p[64:0];
  assign tempSignBit_42 = temp_44[67];
  assign qBit_42 =  ~ tempSignBit_42;
  assign rNextTemp_42 = {rMSBNextBits_42, rLSBits_43, qBit_42};
  assign r43 = rNextTemp_42;
  always_ff @(posedge clk)
    begin : r_reg_42_process
      if (reset == 1'b1) begin
        r43_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r43_p <= r43;
        end
      end
    end
  assign rMSBits_43 = r43_p[133:65];
  assign x_44 = rMSBits_43;
  assign rMSBit_42 = r43_p[133];
  assign rMSBitneg_42 =  ~ rMSBit_42;
  assign switch_compare_1_43 = rMSBitneg_42 > 1'b0;

  assign d_neg_130 = {d43_p[68], d43_p};
  assign d_neg_in0_43 =  - (d_neg_130);
  assign d_neg_131 = d_neg_in0_43[68:0];
  assign y_85 = (switch_compare_1_43 == 1'b0 ? d43_p :
              d_neg_131);
  assign temp_45 = x_44 + y_85;
  assign rMSBNextBits_43 = temp_45[67:0];
  assign rLSBits_44 = r43_p[64:0];
  assign tempSignBit_43 = temp_45[67];
  assign qBit_43 =  ~ tempSignBit_43;
  assign rNextTemp_43 = {rMSBNextBits_43, rLSBits_44, qBit_43};
  assign r44 = rNextTemp_43;
  always_ff @(posedge clk)
    begin : r_reg_43_process
      if (reset == 1'b1) begin
        r44_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r44_p <= r44;
        end
      end
    end
  assign rMSBits_44 = r44_p[133:65];
  assign x_45 = rMSBits_44;
  assign rMSBit_43 = r44_p[133];
  assign rMSBitneg_43 =  ~ rMSBit_43;
  assign switch_compare_1_44 = rMSBitneg_43 > 1'b0;

  assign d_neg_133 = {d44_p[68], d44_p};
  assign d_neg_in0_44 =  - (d_neg_133);
  assign d_neg_134 = d_neg_in0_44[68:0];
  assign y_87 = (switch_compare_1_44 == 1'b0 ? d44_p :
              d_neg_134);
  assign temp_46 = x_45 + y_87;
  assign rMSBNextBits_44 = temp_46[67:0];
  assign rLSBits_45 = r44_p[64:0];
  assign tempSignBit_44 = temp_46[67];
  assign qBit_44 =  ~ tempSignBit_44;
  assign rNextTemp_44 = {rMSBNextBits_44, rLSBits_45, qBit_44};
  assign r45 = rNextTemp_44;
  always_ff @(posedge clk)
    begin : r_reg_44_process
      if (reset == 1'b1) begin
        r45_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r45_p <= r45;
        end
      end
    end
  assign rMSBits_45 = r45_p[133:65];
  assign x_46 = rMSBits_45;
  assign rMSBit_44 = r45_p[133];
  assign rMSBitneg_44 =  ~ rMSBit_44;
  assign switch_compare_1_45 = rMSBitneg_44 > 1'b0;

  assign d_neg_136 = {d45_p[68], d45_p};
  assign d_neg_in0_45 =  - (d_neg_136);
  assign d_neg_137 = d_neg_in0_45[68:0];
  assign y_89 = (switch_compare_1_45 == 1'b0 ? d45_p :
              d_neg_137);
  assign temp_47 = x_46 + y_89;
  assign rMSBNextBits_45 = temp_47[67:0];
  assign rLSBits_46 = r45_p[64:0];
  assign tempSignBit_45 = temp_47[67];
  assign qBit_45 =  ~ tempSignBit_45;
  assign rNextTemp_45 = {rMSBNextBits_45, rLSBits_46, qBit_45};
  assign r46 = rNextTemp_45;
  always_ff @(posedge clk)
    begin : r_reg_45_process
      if (reset == 1'b1) begin
        r46_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r46_p <= r46;
        end
      end
    end
  assign rMSBits_46 = r46_p[133:65];
  assign x_47 = rMSBits_46;
  assign rMSBit_45 = r46_p[133];
  assign rMSBitneg_45 =  ~ rMSBit_45;
  assign switch_compare_1_46 = rMSBitneg_45 > 1'b0;

  assign d_neg_139 = {d46_p[68], d46_p};
  assign d_neg_in0_46 =  - (d_neg_139);
  assign d_neg_140 = d_neg_in0_46[68:0];
  assign y_91 = (switch_compare_1_46 == 1'b0 ? d46_p :
              d_neg_140);
  assign temp_48 = x_47 + y_91;
  assign rMSBNextBits_46 = temp_48[67:0];
  assign rLSBits_47 = r46_p[64:0];
  assign tempSignBit_46 = temp_48[67];
  assign qBit_46 =  ~ tempSignBit_46;
  assign rNextTemp_46 = {rMSBNextBits_46, rLSBits_47, qBit_46};
  assign r47 = rNextTemp_46;
  always_ff @(posedge clk)
    begin : r_reg_46_process
      if (reset == 1'b1) begin
        r47_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r47_p <= r47;
        end
      end
    end
  assign rMSBits_47 = r47_p[133:65];
  assign x_48 = rMSBits_47;
  assign rMSBit_46 = r47_p[133];
  assign rMSBitneg_46 =  ~ rMSBit_46;
  assign switch_compare_1_47 = rMSBitneg_46 > 1'b0;

  assign d_neg_142 = {d47_p[68], d47_p};
  assign d_neg_in0_47 =  - (d_neg_142);
  assign d_neg_143 = d_neg_in0_47[68:0];
  assign y_93 = (switch_compare_1_47 == 1'b0 ? d47_p :
              d_neg_143);
  assign temp_49 = x_48 + y_93;
  assign rMSBNextBits_47 = temp_49[67:0];
  assign rLSBits_48 = r47_p[64:0];
  assign tempSignBit_47 = temp_49[67];
  assign qBit_47 =  ~ tempSignBit_47;
  assign rNextTemp_47 = {rMSBNextBits_47, rLSBits_48, qBit_47};
  assign r48 = rNextTemp_47;
  always_ff @(posedge clk)
    begin : r_reg_47_process
      if (reset == 1'b1) begin
        r48_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r48_p <= r48;
        end
      end
    end
  assign rMSBits_48 = r48_p[133:65];
  assign x_49 = rMSBits_48;
  assign rMSBit_47 = r48_p[133];
  assign rMSBitneg_47 =  ~ rMSBit_47;
  assign switch_compare_1_48 = rMSBitneg_47 > 1'b0;

  assign d_neg_145 = {d48_p[68], d48_p};
  assign d_neg_in0_48 =  - (d_neg_145);
  assign d_neg_146 = d_neg_in0_48[68:0];
  assign y_95 = (switch_compare_1_48 == 1'b0 ? d48_p :
              d_neg_146);
  assign temp_50 = x_49 + y_95;
  assign rMSBNextBits_48 = temp_50[67:0];
  assign rLSBits_49 = r48_p[64:0];
  assign tempSignBit_48 = temp_50[67];
  assign qBit_48 =  ~ tempSignBit_48;
  assign rNextTemp_48 = {rMSBNextBits_48, rLSBits_49, qBit_48};
  assign r49 = rNextTemp_48;
  always_ff @(posedge clk)
    begin : r_reg_48_process
      if (reset == 1'b1) begin
        r49_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r49_p <= r49;
        end
      end
    end
  assign rMSBits_49 = r49_p[133:65];
  assign x_50 = rMSBits_49;
  assign rMSBit_48 = r49_p[133];
  assign rMSBitneg_48 =  ~ rMSBit_48;
  assign switch_compare_1_49 = rMSBitneg_48 > 1'b0;

  assign d_neg_148 = {d49_p[68], d49_p};
  assign d_neg_in0_49 =  - (d_neg_148);
  assign d_neg_149 = d_neg_in0_49[68:0];
  assign y_97 = (switch_compare_1_49 == 1'b0 ? d49_p :
              d_neg_149);
  assign temp_51 = x_50 + y_97;
  assign rMSBNextBits_49 = temp_51[67:0];
  assign rLSBits_50 = r49_p[64:0];
  assign tempSignBit_49 = temp_51[67];
  assign qBit_49 =  ~ tempSignBit_49;
  assign rNextTemp_49 = {rMSBNextBits_49, rLSBits_50, qBit_49};
  assign r50 = rNextTemp_49;
  always_ff @(posedge clk)
    begin : r_reg_49_process
      if (reset == 1'b1) begin
        r50_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r50_p <= r50;
        end
      end
    end
  assign rMSBits_50 = r50_p[133:65];
  assign x_51 = rMSBits_50;
  assign rMSBit_49 = r50_p[133];
  assign rMSBitneg_49 =  ~ rMSBit_49;
  assign switch_compare_1_50 = rMSBitneg_49 > 1'b0;

  assign d_neg_151 = {d50_p[68], d50_p};
  assign d_neg_in0_50 =  - (d_neg_151);
  assign d_neg_152 = d_neg_in0_50[68:0];
  assign y_99 = (switch_compare_1_50 == 1'b0 ? d50_p :
              d_neg_152);
  assign temp_52 = x_51 + y_99;
  assign rMSBNextBits_50 = temp_52[67:0];
  assign rLSBits_51 = r50_p[64:0];
  assign tempSignBit_50 = temp_52[67];
  assign qBit_50 =  ~ tempSignBit_50;
  assign rNextTemp_50 = {rMSBNextBits_50, rLSBits_51, qBit_50};
  assign r51 = rNextTemp_50;
  always_ff @(posedge clk)
    begin : r_reg_50_process
      if (reset == 1'b1) begin
        r51_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r51_p <= r51;
        end
      end
    end
  assign rMSBits_51 = r51_p[133:65];
  assign x_52 = rMSBits_51;
  assign rMSBit_50 = r51_p[133];
  assign rMSBitneg_50 =  ~ rMSBit_50;
  assign switch_compare_1_51 = rMSBitneg_50 > 1'b0;

  assign d_neg_154 = {d51_p[68], d51_p};
  assign d_neg_in0_51 =  - (d_neg_154);
  assign d_neg_155 = d_neg_in0_51[68:0];
  assign y_101 = (switch_compare_1_51 == 1'b0 ? d51_p :
              d_neg_155);
  assign temp_53 = x_52 + y_101;
  assign rMSBNextBits_51 = temp_53[67:0];
  assign rLSBits_52 = r51_p[64:0];
  assign tempSignBit_51 = temp_53[67];
  assign qBit_51 =  ~ tempSignBit_51;
  assign rNextTemp_51 = {rMSBNextBits_51, rLSBits_52, qBit_51};
  assign r52 = rNextTemp_51;
  always_ff @(posedge clk)
    begin : r_reg_51_process
      if (reset == 1'b1) begin
        r52_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r52_p <= r52;
        end
      end
    end
  assign rMSBits_52 = r52_p[133:65];
  assign x_53 = rMSBits_52;
  assign rMSBit_51 = r52_p[133];
  assign rMSBitneg_51 =  ~ rMSBit_51;
  assign switch_compare_1_52 = rMSBitneg_51 > 1'b0;

  assign d_neg_157 = {d52_p[68], d52_p};
  assign d_neg_in0_52 =  - (d_neg_157);
  assign d_neg_158 = d_neg_in0_52[68:0];
  assign y_103 = (switch_compare_1_52 == 1'b0 ? d52_p :
              d_neg_158);
  assign temp_54 = x_53 + y_103;
  assign rMSBNextBits_52 = temp_54[67:0];
  assign rLSBits_53 = r52_p[64:0];
  assign tempSignBit_52 = temp_54[67];
  assign qBit_52 =  ~ tempSignBit_52;
  assign rNextTemp_52 = {rMSBNextBits_52, rLSBits_53, qBit_52};
  assign r53 = rNextTemp_52;
  always_ff @(posedge clk)
    begin : r_reg_52_process
      if (reset == 1'b1) begin
        r53_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r53_p <= r53;
        end
      end
    end
  assign rMSBits_53 = r53_p[133:65];
  assign x_54 = rMSBits_53;
  assign rMSBit_52 = r53_p[133];
  assign rMSBitneg_52 =  ~ rMSBit_52;
  assign switch_compare_1_53 = rMSBitneg_52 > 1'b0;

  assign d_neg_160 = {d53_p[68], d53_p};
  assign d_neg_in0_53 =  - (d_neg_160);
  assign d_neg_161 = d_neg_in0_53[68:0];
  assign y_105 = (switch_compare_1_53 == 1'b0 ? d53_p :
              d_neg_161);
  assign temp_55 = x_54 + y_105;
  assign rMSBNextBits_53 = temp_55[67:0];
  assign rLSBits_54 = r53_p[64:0];
  assign tempSignBit_53 = temp_55[67];
  assign qBit_53 =  ~ tempSignBit_53;
  assign rNextTemp_53 = {rMSBNextBits_53, rLSBits_54, qBit_53};
  assign r54 = rNextTemp_53;
  always_ff @(posedge clk)
    begin : r_reg_53_process
      if (reset == 1'b1) begin
        r54_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r54_p <= r54;
        end
      end
    end
  assign rMSBits_54 = r54_p[133:65];
  assign x_55 = rMSBits_54;
  assign rMSBit_53 = r54_p[133];
  assign rMSBitneg_53 =  ~ rMSBit_53;
  assign switch_compare_1_54 = rMSBitneg_53 > 1'b0;

  assign d_neg_163 = {d54_p[68], d54_p};
  assign d_neg_in0_54 =  - (d_neg_163);
  assign d_neg_164 = d_neg_in0_54[68:0];
  assign y_107 = (switch_compare_1_54 == 1'b0 ? d54_p :
              d_neg_164);
  assign temp_56 = x_55 + y_107;
  assign rMSBNextBits_54 = temp_56[67:0];
  assign rLSBits_55 = r54_p[64:0];
  assign tempSignBit_54 = temp_56[67];
  assign qBit_54 =  ~ tempSignBit_54;
  assign rNextTemp_54 = {rMSBNextBits_54, rLSBits_55, qBit_54};
  assign r55 = rNextTemp_54;
  always_ff @(posedge clk)
    begin : r_reg_54_process
      if (reset == 1'b1) begin
        r55_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r55_p <= r55;
        end
      end
    end
  assign rMSBits_55 = r55_p[133:65];
  assign x_56 = rMSBits_55;
  assign rMSBit_54 = r55_p[133];
  assign rMSBitneg_54 =  ~ rMSBit_54;
  assign switch_compare_1_55 = rMSBitneg_54 > 1'b0;

  assign d_neg_166 = {d55_p[68], d55_p};
  assign d_neg_in0_55 =  - (d_neg_166);
  assign d_neg_167 = d_neg_in0_55[68:0];
  assign y_109 = (switch_compare_1_55 == 1'b0 ? d55_p :
              d_neg_167);
  assign temp_57 = x_56 + y_109;
  assign rMSBNextBits_55 = temp_57[67:0];
  assign rLSBits_56 = r55_p[64:0];
  assign tempSignBit_55 = temp_57[67];
  assign qBit_55 =  ~ tempSignBit_55;
  assign rNextTemp_55 = {rMSBNextBits_55, rLSBits_56, qBit_55};
  assign r56 = rNextTemp_55;
  always_ff @(posedge clk)
    begin : r_reg_55_process
      if (reset == 1'b1) begin
        r56_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r56_p <= r56;
        end
      end
    end
  assign rMSBits_56 = r56_p[133:65];
  assign x_57 = rMSBits_56;
  assign rMSBit_55 = r56_p[133];
  assign rMSBitneg_55 =  ~ rMSBit_55;
  assign switch_compare_1_56 = rMSBitneg_55 > 1'b0;

  assign d_neg_169 = {d56_p[68], d56_p};
  assign d_neg_in0_56 =  - (d_neg_169);
  assign d_neg_170 = d_neg_in0_56[68:0];
  assign y_111 = (switch_compare_1_56 == 1'b0 ? d56_p :
              d_neg_170);
  assign temp_58 = x_57 + y_111;
  assign rMSBNextBits_56 = temp_58[67:0];
  assign rLSBits_57 = r56_p[64:0];
  assign tempSignBit_56 = temp_58[67];
  assign qBit_56 =  ~ tempSignBit_56;
  assign rNextTemp_56 = {rMSBNextBits_56, rLSBits_57, qBit_56};
  assign r57 = rNextTemp_56;
  always_ff @(posedge clk)
    begin : r_reg_56_process
      if (reset == 1'b1) begin
        r57_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r57_p <= r57;
        end
      end
    end
  assign rMSBits_57 = r57_p[133:65];
  assign x_58 = rMSBits_57;
  assign rMSBit_56 = r57_p[133];
  assign rMSBitneg_56 =  ~ rMSBit_56;
  assign switch_compare_1_57 = rMSBitneg_56 > 1'b0;

  assign d_neg_172 = {d57_p[68], d57_p};
  assign d_neg_in0_57 =  - (d_neg_172);
  assign d_neg_173 = d_neg_in0_57[68:0];
  assign y_113 = (switch_compare_1_57 == 1'b0 ? d57_p :
              d_neg_173);
  assign temp_59 = x_58 + y_113;
  assign rMSBNextBits_57 = temp_59[67:0];
  assign rLSBits_58 = r57_p[64:0];
  assign tempSignBit_57 = temp_59[67];
  assign qBit_57 =  ~ tempSignBit_57;
  assign rNextTemp_57 = {rMSBNextBits_57, rLSBits_58, qBit_57};
  assign r58 = rNextTemp_57;
  always_ff @(posedge clk)
    begin : r_reg_57_process
      if (reset == 1'b1) begin
        r58_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r58_p <= r58;
        end
      end
    end
  assign rMSBits_58 = r58_p[133:65];
  assign x_59 = rMSBits_58;
  assign rMSBit_57 = r58_p[133];
  assign rMSBitneg_57 =  ~ rMSBit_57;
  assign switch_compare_1_58 = rMSBitneg_57 > 1'b0;

  assign d_neg_175 = {d58_p[68], d58_p};
  assign d_neg_in0_58 =  - (d_neg_175);
  assign d_neg_176 = d_neg_in0_58[68:0];
  assign y_115 = (switch_compare_1_58 == 1'b0 ? d58_p :
              d_neg_176);
  assign temp_60 = x_59 + y_115;
  assign rMSBNextBits_58 = temp_60[67:0];
  assign rLSBits_59 = r58_p[64:0];
  assign tempSignBit_58 = temp_60[67];
  assign qBit_58 =  ~ tempSignBit_58;
  assign rNextTemp_58 = {rMSBNextBits_58, rLSBits_59, qBit_58};
  assign r59 = rNextTemp_58;
  always_ff @(posedge clk)
    begin : r_reg_58_process
      if (reset == 1'b1) begin
        r59_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r59_p <= r59;
        end
      end
    end
  assign rMSBits_59 = r59_p[133:65];
  assign x_60 = rMSBits_59;
  assign rMSBit_58 = r59_p[133];
  assign rMSBitneg_58 =  ~ rMSBit_58;
  assign switch_compare_1_59 = rMSBitneg_58 > 1'b0;

  assign d_neg_178 = {d59_p[68], d59_p};
  assign d_neg_in0_59 =  - (d_neg_178);
  assign d_neg_179 = d_neg_in0_59[68:0];
  assign y_117 = (switch_compare_1_59 == 1'b0 ? d59_p :
              d_neg_179);
  assign temp_61 = x_60 + y_117;
  assign rMSBNextBits_59 = temp_61[67:0];
  assign rLSBits_60 = r59_p[64:0];
  assign tempSignBit_59 = temp_61[67];
  assign qBit_59 =  ~ tempSignBit_59;
  assign rNextTemp_59 = {rMSBNextBits_59, rLSBits_60, qBit_59};
  assign r60 = rNextTemp_59;
  always_ff @(posedge clk)
    begin : r_reg_59_process
      if (reset == 1'b1) begin
        r60_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r60_p <= r60;
        end
      end
    end
  assign rMSBits_60 = r60_p[133:65];
  assign x_61 = rMSBits_60;
  assign rMSBit_59 = r60_p[133];
  assign rMSBitneg_59 =  ~ rMSBit_59;
  assign switch_compare_1_60 = rMSBitneg_59 > 1'b0;

  assign d_neg_181 = {d60_p[68], d60_p};
  assign d_neg_in0_60 =  - (d_neg_181);
  assign d_neg_182 = d_neg_in0_60[68:0];
  assign y_119 = (switch_compare_1_60 == 1'b0 ? d60_p :
              d_neg_182);
  assign temp_62 = x_61 + y_119;
  assign rMSBNextBits_60 = temp_62[67:0];
  assign rLSBits_61 = r60_p[64:0];
  assign tempSignBit_60 = temp_62[67];
  assign qBit_60 =  ~ tempSignBit_60;
  assign rNextTemp_60 = {rMSBNextBits_60, rLSBits_61, qBit_60};
  assign r61 = rNextTemp_60;
  always_ff @(posedge clk)
    begin : r_reg_60_process
      if (reset == 1'b1) begin
        r61_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r61_p <= r61;
        end
      end
    end
  assign rMSBits_61 = r61_p[133:65];
  assign x_62 = rMSBits_61;
  assign rMSBit_60 = r61_p[133];
  assign rMSBitneg_60 =  ~ rMSBit_60;
  assign switch_compare_1_61 = rMSBitneg_60 > 1'b0;

  assign d_neg_184 = {d61_p[68], d61_p};
  assign d_neg_in0_61 =  - (d_neg_184);
  assign d_neg_185 = d_neg_in0_61[68:0];
  assign y_121 = (switch_compare_1_61 == 1'b0 ? d61_p :
              d_neg_185);
  assign temp_63 = x_62 + y_121;
  assign rMSBNextBits_61 = temp_63[67:0];
  assign rLSBits_62 = r61_p[64:0];
  assign tempSignBit_61 = temp_63[67];
  assign qBit_61 =  ~ tempSignBit_61;
  assign rNextTemp_61 = {rMSBNextBits_61, rLSBits_62, qBit_61};
  assign r62 = rNextTemp_61;
  always_ff @(posedge clk)
    begin : r_reg_61_process
      if (reset == 1'b1) begin
        r62_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r62_p <= r62;
        end
      end
    end
  assign rMSBits_62 = r62_p[133:65];
  assign x_63 = rMSBits_62;
  assign rMSBit_61 = r62_p[133];
  assign rMSBitneg_61 =  ~ rMSBit_61;
  assign switch_compare_1_62 = rMSBitneg_61 > 1'b0;

  assign d_neg_187 = {d62_p[68], d62_p};
  assign d_neg_in0_62 =  - (d_neg_187);
  assign d_neg_188 = d_neg_in0_62[68:0];
  assign y_123 = (switch_compare_1_62 == 1'b0 ? d62_p :
              d_neg_188);
  assign temp_64 = x_63 + y_123;
  assign rMSBNextBits_62 = temp_64[67:0];
  assign rLSBits_63 = r62_p[64:0];
  assign tempSignBit_62 = temp_64[67];
  assign qBit_62 =  ~ tempSignBit_62;
  assign rNextTemp_62 = {rMSBNextBits_62, rLSBits_63, qBit_62};
  assign r63 = rNextTemp_62;
  always_ff @(posedge clk)
    begin : r_reg_62_process
      if (reset == 1'b1) begin
        r63_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r63_p <= r63;
        end
      end
    end
  assign rMSBits_63 = r63_p[133:65];
  assign x_64 = rMSBits_63;
  assign rMSBit_62 = r63_p[133];
  assign rMSBitneg_62 =  ~ rMSBit_62;
  assign switch_compare_1_63 = rMSBitneg_62 > 1'b0;

  assign d_neg_190 = {d63_p[68], d63_p};
  assign d_neg_in0_63 =  - (d_neg_190);
  assign d_neg_191 = d_neg_in0_63[68:0];
  assign y_125 = (switch_compare_1_63 == 1'b0 ? d63_p :
              d_neg_191);
  assign temp_65 = x_64 + y_125;
  assign rMSBNextBits_63 = temp_65[67:0];
  assign rLSBits_64 = r63_p[64:0];
  assign tempSignBit_63 = temp_65[67];
  assign qBit_63 =  ~ tempSignBit_63;
  assign rNextTemp_63 = {rMSBNextBits_63, rLSBits_64, qBit_63};
  assign r64 = rNextTemp_63;
  always_ff @(posedge clk)
    begin : r_reg_63_process
      if (reset == 1'b1) begin
        r64_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r64_p <= r64;
        end
      end
    end
  assign rMSBits_64 = r64_p[133:65];
  assign x_65 = rMSBits_64;
  assign rMSBit_63 = r64_p[133];
  assign rMSBitneg_63 =  ~ rMSBit_63;
  assign switch_compare_1_64 = rMSBitneg_63 > 1'b0;

  assign d_neg_193 = {d64_p[68], d64_p};
  assign d_neg_in0_64 =  - (d_neg_193);
  assign d_neg_194 = d_neg_in0_64[68:0];
  assign y_127 = (switch_compare_1_64 == 1'b0 ? d64_p :
              d_neg_194);
  assign temp_66 = x_65 + y_127;
  assign rMSBNextBits_64 = temp_66[67:0];
  assign rLSBits_65 = r64_p[64:0];
  assign tempSignBit_64 = temp_66[67];
  assign qBit_64 =  ~ tempSignBit_64;
  assign rNextTemp_64 = {rMSBNextBits_64, rLSBits_65, qBit_64};
  assign r65 = rNextTemp_64;
  always_ff @(posedge clk)
    begin : r_reg_64_process
      if (reset == 1'b1) begin
        r65_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r65_p <= r65;
        end
      end
    end
  assign rMSBits_65 = r65_p[133:65];
  assign x_66 = rMSBits_65;
  assign rMSBit_64 = r65_p[133];
  assign rMSBitneg_64 =  ~ rMSBit_64;
  assign switch_compare_1_65 = rMSBitneg_64 > 1'b0;

  assign d_neg_196 = {d65_p[68], d65_p};
  assign d_neg_in0_65 =  - (d_neg_196);
  assign d_neg_197 = d_neg_in0_65[68:0];
  assign y_129 = (switch_compare_1_65 == 1'b0 ? d65_p :
              d_neg_197);
  assign temp_67 = x_66 + y_129;
  assign rMSBNextBits_65 = temp_67[67:0];
  assign rLSBits_66 = r65_p[64:0];
  assign tempSignBit_65 = temp_67[67];
  assign qBit_65 =  ~ tempSignBit_65;
  assign rNextTemp_65 = {rMSBNextBits_65, rLSBits_66, qBit_65};
  assign r66 = rNextTemp_65;
  always_ff @(posedge clk)
    begin : r_reg_65_process
      if (reset == 1'b1) begin
        r66_p <= 134'sh0000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r66_p <= r66;
        end
      end
    end
  assign qTemp = r66_p[65:0];
  assign rMSBit_65 = r66_p[133];
  assign switch_compare_1_66 = rMSBit_65 > 1'b0;

  assign rMSBits_66 = r66_p[133:66];
  assign rMSBits_dtc = rMSBits_66;
  assign x_67 = {rMSBits_dtc[67], rMSBits_dtc};
  assign add_correct_out = x_67 + d66_p;
  assign corrected_rem_1 = (switch_compare_1_66 == 1'b0 ? x_67 :
              add_correct_out);
  assign switch_compare_1_67 = corrected_rem_1 != 69'sh000000000000000000;

  assign qIsOdd = qTemp[0];
  assign scaled_rem = {corrected_rem_1[68], corrected_rem_1};
  assign nextRem = scaled_rem <<< 8'd1;
  assign d_p_dtc = {d66_p[68], d66_p};
  assign istie = nextRem == d_p_dtc;
  assign needsTiebreak = qIsOdd & istie;
  assign isgreater = nextRem > d_p_dtc;
  assign needsRounding = needsTiebreak | isgreater;
  assign incQ = qTemp + 66'h00000000000000001;
  assign qRounded = (needsRounding == 1'b0 ? qTemp :
              incQ);
  assign qround_remNZ = (switch_compare_1_67 == 1'b0 ? qTemp :
              qRounded);
  assign q_post_calc = (switch_compare_1 == 1'b0 ? qTemp :
              qround_remNZ);
  always_ff @(posedge clk)
    begin : qtempExt_p_process
      if (reset == 1'b1) begin
        qtempExt_p_1 <= 66'h00000000000000000;
      end
      else begin
        if (enb) begin
          qtempExt_p_1 <= q_post_calc;
        end
      end
    end
  assign qtempPost = (initFlagDelayData_1 == 1'b0 ? ConstantSignal_1 :
              qtempExt_p_1);
  always_ff @(posedge clk)
    begin : qtempInit_p_process
      if (reset == 1'b1) begin
        qtempPost_p <= 66'h00000000000000000;
      end
      else begin
        if (enb) begin
          qtempPost_p <= qtempPost;
        end
      end
    end
  assign qtempPost_1 = qtempPost_p;
  assign qoutDTC = (qtempPost_1[65:63] != 3'b000 ? 64'sh7FFFFFFFFFFFFFFF :
              $signed(qtempPost_1[63:0]));
  always_ff @(posedge clk)
    begin : q_process
      if (reset == 1'b1) begin
        recip_out_1 <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          recip_out_1 <= qoutDTC;
        end
      end
    end
  assign recip_out = (init_guard_true_2 == 1'b0 ? recip_outinit_guard_default :
              recip_out_1);

endmodule   
