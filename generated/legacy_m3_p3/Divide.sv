
`timescale 1ns/1ps

module Divide
          import FOC_DUT_pkg::* ;
          (  input logic clk,
             input logic reset,
             input logic enb,
             input logic signed [63:0] dividend_in,
             input logic signed [63:0] divisor_in,
             output logic [71:0] quotient);


  logic init_guard_true_1;
  logic [108:0] matching_delays_reg;
  logic init_guard_true_2;
  logic [71:0] quotientinit_guard_default;
  logic trueFlag_1;
  logic initFlagenable;
  logic [106:0] delayMatch_reg;
  logic initFlagenable_1;
  logic signed [105:0] ConstantSignal_1;
  logic signed [63:0] dividend_in_reg;
  logic signed [103:0] s;
  logic signed [103:0] dividend_inshift_reg;
  logic z_MSB;
  logic signed [63:0] divisor_in_reg;
  logic d_MSB;
  logic isSignsDiffer;
  logic [106:0] signFlag_p_reg;
  logic signFlag_p_1;
  logic switch_compare_1;
  logic switch_compare_1_1;
  logic signed [64:0] preCorrectionIn2_sig_dtc_1;
  logic signed [105:0] preCorrectionIn2_sig_dtc_dtc;
  logic signed [65:0] d_neg_in0;
  logic signed [65:0] d_neg_1;
  logic signed [64:0] d_neg_2;
  logic signed [105:0] d_neg_dtc;
  logic signed [105:0] corrected_d;
  logic signed [105:0] corrected_d_p_1;
  logic signed [105:0] d1_p;
  logic signed [105:0] d2_p;
  logic signed [105:0] d3_p;
  logic signed [105:0] d4_p;
  logic signed [105:0] d5_p;
  logic signed [105:0] d6_p;
  logic signed [105:0] d7_p;
  logic signed [105:0] d8_p;
  logic signed [105:0] d9_p;
  logic signed [105:0] d10_p;
  logic signed [105:0] d11_p;
  logic signed [105:0] d12_p;
  logic signed [105:0] d13_p;
  logic signed [105:0] d14_p;
  logic signed [105:0] d15_p;
  logic signed [105:0] d16_p;
  logic signed [105:0] d17_p;
  logic signed [105:0] d18_p;
  logic signed [105:0] d19_p;
  logic signed [105:0] d20_p;
  logic signed [105:0] d21_p;
  logic signed [105:0] d22_p;
  logic signed [105:0] d23_p;
  logic signed [105:0] d24_p;
  logic signed [105:0] d25_p;
  logic signed [105:0] d26_p;
  logic signed [105:0] d27_p;
  logic signed [105:0] d28_p;
  logic signed [105:0] d29_p;
  logic signed [105:0] d30_p;
  logic signed [105:0] d31_p;
  logic signed [105:0] d32_p;
  logic signed [105:0] d33_p;
  logic signed [105:0] d34_p;
  logic signed [105:0] d35_p;
  logic signed [105:0] d36_p;
  logic signed [105:0] d37_p;
  logic signed [105:0] d38_p;
  logic signed [105:0] d39_p;
  logic signed [105:0] d40_p;
  logic signed [105:0] d41_p;
  logic signed [105:0] d42_p;
  logic signed [105:0] d43_p;
  logic signed [105:0] d44_p;
  logic signed [105:0] d45_p;
  logic signed [105:0] d46_p;
  logic signed [105:0] d47_p;
  logic signed [105:0] d48_p;
  logic signed [105:0] d49_p;
  logic signed [105:0] d50_p;
  logic signed [105:0] d51_p;
  logic signed [105:0] d52_p;
  logic signed [105:0] d53_p;
  logic signed [105:0] d54_p;
  logic signed [105:0] d55_p;
  logic signed [105:0] d56_p;
  logic signed [105:0] d57_p;
  logic signed [105:0] d58_p;
  logic signed [105:0] d59_p;
  logic signed [105:0] d60_p;
  logic signed [105:0] d61_p;
  logic signed [105:0] d62_p;
  logic signed [105:0] d63_p;
  logic signed [105:0] d64_p;
  logic signed [105:0] d65_p;
  logic signed [105:0] d66_p;
  logic signed [105:0] d67_p;
  logic signed [105:0] d68_p;
  logic signed [105:0] d69_p;
  logic signed [105:0] d70_p;
  logic signed [105:0] d71_p;
  logic signed [105:0] d72_p;
  logic signed [105:0] d73_p;
  logic signed [105:0] d74_p;
  logic signed [105:0] d75_p;
  logic signed [105:0] d76_p;
  logic signed [105:0] d77_p;
  logic signed [105:0] d78_p;
  logic signed [105:0] d79_p;
  logic signed [105:0] d80_p;
  logic signed [105:0] d81_p;
  logic signed [105:0] d82_p;
  logic signed [105:0] d83_p;
  logic signed [105:0] d84_p;
  logic signed [105:0] d85_p;
  logic signed [105:0] d86_p;
  logic signed [105:0] d87_p;
  logic signed [105:0] d88_p;
  logic signed [105:0] d89_p;
  logic signed [105:0] d90_p;
  logic signed [105:0] d91_p;
  logic signed [105:0] d92_p;
  logic signed [105:0] d93_p;
  logic signed [105:0] d94_p;
  logic signed [105:0] d95_p;
  logic signed [105:0] d96_p;
  logic signed [105:0] d97_p;
  logic signed [105:0] d98_p;
  logic signed [105:0] d99_p;
  logic signed [105:0] d100_p;
  logic signed [105:0] d101_p;
  logic signed [105:0] d102_p;
  logic signed [105:0] d103_p;
  logic signed [105:0] d104_p;
  logic signed [105:0] d105_p;
  logic switch_compare_1_2;
  logic switch_compare_1_3;
  logic signed [104:0] preCorrectionIn1_sig_dtc_1;
  logic signed [209:0] preCorrectionIn1_sig_dtc_dtc;
  logic signed [105:0] z_neg_in0;
  logic signed [105:0] z_neg_1;
  logic signed [104:0] z_neg_2;
  logic signed [209:0] z_neg_dtc;
  logic signed [209:0] corrected_z;
  logic signed [209:0] corrected_z_p_1;
  logic [105:0] rMSBits;
  logic signed [105:0] x;
  logic signed [106:0] d_neg_in0_1;
  logic signed [106:0] d_neg_4;
  logic signed [105:0] d_neg_5;
  logic signed [105:0] temp;
  logic [104:0] rMSBNextBits;
  logic [103:0] rLSBits;
  logic tempSignBit;
  logic qBit;
  logic [209:0] rNextTemp;
  logic signed [209:0] r1;
  logic signed [209:0] r1_p;
  logic [105:0] rMSBits_1;
  logic signed [105:0] x_1;
  logic rMSBit;
  logic rMSBitneg;
  logic switch_compare_1_4;
  logic signed [106:0] d_neg_in0_2;
  logic signed [106:0] d_neg_7;
  logic signed [105:0] d_neg_8;
  logic signed [105:0] y_1;
  logic signed [105:0] temp_3;
  logic [104:0] rMSBNextBits_1;
  logic [103:0] rLSBits_1;
  logic tempSignBit_1;
  logic qBit_1;
  logic [209:0] rNextTemp_1;
  logic signed [209:0] r2;
  logic signed [209:0] r2_p;
  logic [105:0] rMSBits_2;
  logic signed [105:0] x_2;
  logic rMSBit_1;
  logic rMSBitneg_1;
  logic switch_compare_1_5;
  logic signed [106:0] d_neg_in0_3;
  logic signed [106:0] d_neg_10;
  logic signed [105:0] d_neg_11;
  logic signed [105:0] y_3;
  logic signed [105:0] temp_4;
  logic [104:0] rMSBNextBits_2;
  logic [103:0] rLSBits_2;
  logic tempSignBit_2;
  logic qBit_2;
  logic [209:0] rNextTemp_2;
  logic signed [209:0] r3;
  logic signed [209:0] r3_p;
  logic [105:0] rMSBits_3;
  logic signed [105:0] x_3;
  logic rMSBit_2;
  logic rMSBitneg_2;
  logic switch_compare_1_6;
  logic signed [106:0] d_neg_in0_4;
  logic signed [106:0] d_neg_13;
  logic signed [105:0] d_neg_14;
  logic signed [105:0] y_5;
  logic signed [105:0] temp_5;
  logic [104:0] rMSBNextBits_3;
  logic [103:0] rLSBits_3;
  logic tempSignBit_3;
  logic qBit_3;
  logic [209:0] rNextTemp_3;
  logic signed [209:0] r4;
  logic signed [209:0] r4_p;
  logic [105:0] rMSBits_4;
  logic signed [105:0] x_4;
  logic rMSBit_3;
  logic rMSBitneg_3;
  logic switch_compare_1_7;
  logic signed [106:0] d_neg_in0_5;
  logic signed [106:0] d_neg_16;
  logic signed [105:0] d_neg_17;
  logic signed [105:0] y_7;
  logic signed [105:0] temp_6;
  logic [104:0] rMSBNextBits_4;
  logic [103:0] rLSBits_4;
  logic tempSignBit_4;
  logic qBit_4;
  logic [209:0] rNextTemp_4;
  logic signed [209:0] r5;
  logic signed [209:0] r5_p;
  logic [105:0] rMSBits_5;
  logic signed [105:0] x_5;
  logic rMSBit_4;
  logic rMSBitneg_4;
  logic switch_compare_1_8;
  logic signed [106:0] d_neg_in0_6;
  logic signed [106:0] d_neg_19;
  logic signed [105:0] d_neg_20;
  logic signed [105:0] y_9;
  logic signed [105:0] temp_7;
  logic [104:0] rMSBNextBits_5;
  logic [103:0] rLSBits_5;
  logic tempSignBit_5;
  logic qBit_5;
  logic [209:0] rNextTemp_5;
  logic signed [209:0] r6;
  logic signed [209:0] r6_p;
  logic [105:0] rMSBits_6;
  logic signed [105:0] x_6;
  logic rMSBit_5;
  logic rMSBitneg_5;
  logic switch_compare_1_9;
  logic signed [106:0] d_neg_in0_7;
  logic signed [106:0] d_neg_22;
  logic signed [105:0] d_neg_23;
  logic signed [105:0] y_11;
  logic signed [105:0] temp_8;
  logic [104:0] rMSBNextBits_6;
  logic [103:0] rLSBits_6;
  logic tempSignBit_6;
  logic qBit_6;
  logic [209:0] rNextTemp_6;
  logic signed [209:0] r7;
  logic signed [209:0] r7_p;
  logic [105:0] rMSBits_7;
  logic signed [105:0] x_7;
  logic rMSBit_6;
  logic rMSBitneg_6;
  logic switch_compare_1_10;
  logic signed [106:0] d_neg_in0_8;
  logic signed [106:0] d_neg_25;
  logic signed [105:0] d_neg_26;
  logic signed [105:0] y_13;
  logic signed [105:0] temp_9;
  logic [104:0] rMSBNextBits_7;
  logic [103:0] rLSBits_7;
  logic tempSignBit_7;
  logic qBit_7;
  logic [209:0] rNextTemp_7;
  logic signed [209:0] r8;
  logic signed [209:0] r8_p;
  logic [105:0] rMSBits_8;
  logic signed [105:0] x_8;
  logic rMSBit_7;
  logic rMSBitneg_7;
  logic switch_compare_1_11;
  logic signed [106:0] d_neg_in0_9;
  logic signed [106:0] d_neg_28;
  logic signed [105:0] d_neg_29;
  logic signed [105:0] y_15;
  logic signed [105:0] temp_10;
  logic [104:0] rMSBNextBits_8;
  logic [103:0] rLSBits_8;
  logic tempSignBit_8;
  logic qBit_8;
  logic [209:0] rNextTemp_8;
  logic signed [209:0] r9;
  logic signed [209:0] r9_p;
  logic [105:0] rMSBits_9;
  logic signed [105:0] x_9;
  logic rMSBit_8;
  logic rMSBitneg_8;
  logic switch_compare_1_12;
  logic signed [106:0] d_neg_in0_10;
  logic signed [106:0] d_neg_31;
  logic signed [105:0] d_neg_32;
  logic signed [105:0] y_17;
  logic signed [105:0] temp_11;
  logic [104:0] rMSBNextBits_9;
  logic [103:0] rLSBits_9;
  logic tempSignBit_9;
  logic qBit_9;
  logic [209:0] rNextTemp_9;
  logic signed [209:0] r10;
  logic signed [209:0] r10_p;
  logic [105:0] rMSBits_10;
  logic signed [105:0] x_10;
  logic rMSBit_9;
  logic rMSBitneg_9;
  logic switch_compare_1_13;
  logic signed [106:0] d_neg_in0_11;
  logic signed [106:0] d_neg_34;
  logic signed [105:0] d_neg_35;
  logic signed [105:0] y_19;
  logic signed [105:0] temp_12;
  logic [104:0] rMSBNextBits_10;
  logic [103:0] rLSBits_10;
  logic tempSignBit_10;
  logic qBit_10;
  logic [209:0] rNextTemp_10;
  logic signed [209:0] r11;
  logic signed [209:0] r11_p;
  logic [105:0] rMSBits_11;
  logic signed [105:0] x_11;
  logic rMSBit_10;
  logic rMSBitneg_10;
  logic switch_compare_1_14;
  logic signed [106:0] d_neg_in0_12;
  logic signed [106:0] d_neg_37;
  logic signed [105:0] d_neg_38;
  logic signed [105:0] y_21;
  logic signed [105:0] temp_13;
  logic [104:0] rMSBNextBits_11;
  logic [103:0] rLSBits_11;
  logic tempSignBit_11;
  logic qBit_11;
  logic [209:0] rNextTemp_11;
  logic signed [209:0] r12;
  logic signed [209:0] r12_p;
  logic [105:0] rMSBits_12;
  logic signed [105:0] x_12;
  logic rMSBit_11;
  logic rMSBitneg_11;
  logic switch_compare_1_15;
  logic signed [106:0] d_neg_in0_13;
  logic signed [106:0] d_neg_40;
  logic signed [105:0] d_neg_41;
  logic signed [105:0] y_23;
  logic signed [105:0] temp_14;
  logic [104:0] rMSBNextBits_12;
  logic [103:0] rLSBits_12;
  logic tempSignBit_12;
  logic qBit_12;
  logic [209:0] rNextTemp_12;
  logic signed [209:0] r13;
  logic signed [209:0] r13_p;
  logic [105:0] rMSBits_13;
  logic signed [105:0] x_13;
  logic rMSBit_12;
  logic rMSBitneg_12;
  logic switch_compare_1_16;
  logic signed [106:0] d_neg_in0_14;
  logic signed [106:0] d_neg_43;
  logic signed [105:0] d_neg_44;
  logic signed [105:0] y_25;
  logic signed [105:0] temp_15;
  logic [104:0] rMSBNextBits_13;
  logic [103:0] rLSBits_13;
  logic tempSignBit_13;
  logic qBit_13;
  logic [209:0] rNextTemp_13;
  logic signed [209:0] r14;
  logic signed [209:0] r14_p;
  logic [105:0] rMSBits_14;
  logic signed [105:0] x_14;
  logic rMSBit_13;
  logic rMSBitneg_13;
  logic switch_compare_1_17;
  logic signed [106:0] d_neg_in0_15;
  logic signed [106:0] d_neg_46;
  logic signed [105:0] d_neg_47;
  logic signed [105:0] y_27;
  logic signed [105:0] temp_16;
  logic [104:0] rMSBNextBits_14;
  logic [103:0] rLSBits_14;
  logic tempSignBit_14;
  logic qBit_14;
  logic [209:0] rNextTemp_14;
  logic signed [209:0] r15;
  logic signed [209:0] r15_p;
  logic [105:0] rMSBits_15;
  logic signed [105:0] x_15;
  logic rMSBit_14;
  logic rMSBitneg_14;
  logic switch_compare_1_18;
  logic signed [106:0] d_neg_in0_16;
  logic signed [106:0] d_neg_49;
  logic signed [105:0] d_neg_50;
  logic signed [105:0] y_29;
  logic signed [105:0] temp_17;
  logic [104:0] rMSBNextBits_15;
  logic [103:0] rLSBits_15;
  logic tempSignBit_15;
  logic qBit_15;
  logic [209:0] rNextTemp_15;
  logic signed [209:0] r16;
  logic signed [209:0] r16_p;
  logic [105:0] rMSBits_16;
  logic signed [105:0] x_16;
  logic rMSBit_15;
  logic rMSBitneg_15;
  logic switch_compare_1_19;
  logic signed [106:0] d_neg_in0_17;
  logic signed [106:0] d_neg_52;
  logic signed [105:0] d_neg_53;
  logic signed [105:0] y_31;
  logic signed [105:0] temp_18;
  logic [104:0] rMSBNextBits_16;
  logic [103:0] rLSBits_16;
  logic tempSignBit_16;
  logic qBit_16;
  logic [209:0] rNextTemp_16;
  logic signed [209:0] r17;
  logic signed [209:0] r17_p;
  logic [105:0] rMSBits_17;
  logic signed [105:0] x_17;
  logic rMSBit_16;
  logic rMSBitneg_16;
  logic switch_compare_1_20;
  logic signed [106:0] d_neg_in0_18;
  logic signed [106:0] d_neg_55;
  logic signed [105:0] d_neg_56;
  logic signed [105:0] y_33;
  logic signed [105:0] temp_19;
  logic [104:0] rMSBNextBits_17;
  logic [103:0] rLSBits_17;
  logic tempSignBit_17;
  logic qBit_17;
  logic [209:0] rNextTemp_17;
  logic signed [209:0] r18;
  logic signed [209:0] r18_p;
  logic [105:0] rMSBits_18;
  logic signed [105:0] x_18;
  logic rMSBit_17;
  logic rMSBitneg_17;
  logic switch_compare_1_21;
  logic signed [106:0] d_neg_in0_19;
  logic signed [106:0] d_neg_58;
  logic signed [105:0] d_neg_59;
  logic signed [105:0] y_35;
  logic signed [105:0] temp_20;
  logic [104:0] rMSBNextBits_18;
  logic [103:0] rLSBits_18;
  logic tempSignBit_18;
  logic qBit_18;
  logic [209:0] rNextTemp_18;
  logic signed [209:0] r19;
  logic signed [209:0] r19_p;
  logic [105:0] rMSBits_19;
  logic signed [105:0] x_19;
  logic rMSBit_18;
  logic rMSBitneg_18;
  logic switch_compare_1_22;
  logic signed [106:0] d_neg_in0_20;
  logic signed [106:0] d_neg_61;
  logic signed [105:0] d_neg_62;
  logic signed [105:0] y_37;
  logic signed [105:0] temp_21;
  logic [104:0] rMSBNextBits_19;
  logic [103:0] rLSBits_19;
  logic tempSignBit_19;
  logic qBit_19;
  logic [209:0] rNextTemp_19;
  logic signed [209:0] r20;
  logic signed [209:0] r20_p;
  logic [105:0] rMSBits_20;
  logic signed [105:0] x_20;
  logic rMSBit_19;
  logic rMSBitneg_19;
  logic switch_compare_1_23;
  logic signed [106:0] d_neg_in0_21;
  logic signed [106:0] d_neg_64;
  logic signed [105:0] d_neg_65;
  logic signed [105:0] y_39;
  logic signed [105:0] temp_22;
  logic [104:0] rMSBNextBits_20;
  logic [103:0] rLSBits_20;
  logic tempSignBit_20;
  logic qBit_20;
  logic [209:0] rNextTemp_20;
  logic signed [209:0] r21;
  logic signed [209:0] r21_p;
  logic [105:0] rMSBits_21;
  logic signed [105:0] x_21;
  logic rMSBit_20;
  logic rMSBitneg_20;
  logic switch_compare_1_24;
  logic signed [106:0] d_neg_in0_22;
  logic signed [106:0] d_neg_67;
  logic signed [105:0] d_neg_68;
  logic signed [105:0] y_41;
  logic signed [105:0] temp_23;
  logic [104:0] rMSBNextBits_21;
  logic [103:0] rLSBits_21;
  logic tempSignBit_21;
  logic qBit_21;
  logic [209:0] rNextTemp_21;
  logic signed [209:0] r22;
  logic signed [209:0] r22_p;
  logic [105:0] rMSBits_22;
  logic signed [105:0] x_22;
  logic rMSBit_21;
  logic rMSBitneg_21;
  logic switch_compare_1_25;
  logic signed [106:0] d_neg_in0_23;
  logic signed [106:0] d_neg_70;
  logic signed [105:0] d_neg_71;
  logic signed [105:0] y_43;
  logic signed [105:0] temp_24;
  logic [104:0] rMSBNextBits_22;
  logic [103:0] rLSBits_22;
  logic tempSignBit_22;
  logic qBit_22;
  logic [209:0] rNextTemp_22;
  logic signed [209:0] r23;
  logic signed [209:0] r23_p;
  logic [105:0] rMSBits_23;
  logic signed [105:0] x_23;
  logic rMSBit_22;
  logic rMSBitneg_22;
  logic switch_compare_1_26;
  logic signed [106:0] d_neg_in0_24;
  logic signed [106:0] d_neg_73;
  logic signed [105:0] d_neg_74;
  logic signed [105:0] y_45;
  logic signed [105:0] temp_25;
  logic [104:0] rMSBNextBits_23;
  logic [103:0] rLSBits_23;
  logic tempSignBit_23;
  logic qBit_23;
  logic [209:0] rNextTemp_23;
  logic signed [209:0] r24;
  logic signed [209:0] r24_p;
  logic [105:0] rMSBits_24;
  logic signed [105:0] x_24;
  logic rMSBit_23;
  logic rMSBitneg_23;
  logic switch_compare_1_27;
  logic signed [106:0] d_neg_in0_25;
  logic signed [106:0] d_neg_76;
  logic signed [105:0] d_neg_77;
  logic signed [105:0] y_47;
  logic signed [105:0] temp_26;
  logic [104:0] rMSBNextBits_24;
  logic [103:0] rLSBits_24;
  logic tempSignBit_24;
  logic qBit_24;
  logic [209:0] rNextTemp_24;
  logic signed [209:0] r25;
  logic signed [209:0] r25_p;
  logic [105:0] rMSBits_25;
  logic signed [105:0] x_25;
  logic rMSBit_24;
  logic rMSBitneg_24;
  logic switch_compare_1_28;
  logic signed [106:0] d_neg_in0_26;
  logic signed [106:0] d_neg_79;
  logic signed [105:0] d_neg_80;
  logic signed [105:0] y_49;
  logic signed [105:0] temp_27;
  logic [104:0] rMSBNextBits_25;
  logic [103:0] rLSBits_25;
  logic tempSignBit_25;
  logic qBit_25;
  logic [209:0] rNextTemp_25;
  logic signed [209:0] r26;
  logic signed [209:0] r26_p;
  logic [105:0] rMSBits_26;
  logic signed [105:0] x_26;
  logic rMSBit_25;
  logic rMSBitneg_25;
  logic switch_compare_1_29;
  logic signed [106:0] d_neg_in0_27;
  logic signed [106:0] d_neg_82;
  logic signed [105:0] d_neg_83;
  logic signed [105:0] y_51;
  logic signed [105:0] temp_28;
  logic [104:0] rMSBNextBits_26;
  logic [103:0] rLSBits_26;
  logic tempSignBit_26;
  logic qBit_26;
  logic [209:0] rNextTemp_26;
  logic signed [209:0] r27;
  logic signed [209:0] r27_p;
  logic [105:0] rMSBits_27;
  logic signed [105:0] x_27;
  logic rMSBit_26;
  logic rMSBitneg_26;
  logic switch_compare_1_30;
  logic signed [106:0] d_neg_in0_28;
  logic signed [106:0] d_neg_85;
  logic signed [105:0] d_neg_86;
  logic signed [105:0] y_53;
  logic signed [105:0] temp_29;
  logic [104:0] rMSBNextBits_27;
  logic [103:0] rLSBits_27;
  logic tempSignBit_27;
  logic qBit_27;
  logic [209:0] rNextTemp_27;
  logic signed [209:0] r28;
  logic signed [209:0] r28_p;
  logic [105:0] rMSBits_28;
  logic signed [105:0] x_28;
  logic rMSBit_27;
  logic rMSBitneg_27;
  logic switch_compare_1_31;
  logic signed [106:0] d_neg_in0_29;
  logic signed [106:0] d_neg_88;
  logic signed [105:0] d_neg_89;
  logic signed [105:0] y_55;
  logic signed [105:0] temp_30;
  logic [104:0] rMSBNextBits_28;
  logic [103:0] rLSBits_28;
  logic tempSignBit_28;
  logic qBit_28;
  logic [209:0] rNextTemp_28;
  logic signed [209:0] r29;
  logic signed [209:0] r29_p;
  logic [105:0] rMSBits_29;
  logic signed [105:0] x_29;
  logic rMSBit_28;
  logic rMSBitneg_28;
  logic switch_compare_1_32;
  logic signed [106:0] d_neg_in0_30;
  logic signed [106:0] d_neg_91;
  logic signed [105:0] d_neg_92;
  logic signed [105:0] y_57;
  logic signed [105:0] temp_31;
  logic [104:0] rMSBNextBits_29;
  logic [103:0] rLSBits_29;
  logic tempSignBit_29;
  logic qBit_29;
  logic [209:0] rNextTemp_29;
  logic signed [209:0] r30;
  logic signed [209:0] r30_p;
  logic [105:0] rMSBits_30;
  logic signed [105:0] x_30;
  logic rMSBit_29;
  logic rMSBitneg_29;
  logic switch_compare_1_33;
  logic signed [106:0] d_neg_in0_31;
  logic signed [106:0] d_neg_94;
  logic signed [105:0] d_neg_95;
  logic signed [105:0] y_59;
  logic signed [105:0] temp_32;
  logic [104:0] rMSBNextBits_30;
  logic [103:0] rLSBits_30;
  logic tempSignBit_30;
  logic qBit_30;
  logic [209:0] rNextTemp_30;
  logic signed [209:0] r31;
  logic signed [209:0] r31_p;
  logic [105:0] rMSBits_31;
  logic signed [105:0] x_31;
  logic rMSBit_30;
  logic rMSBitneg_30;
  logic switch_compare_1_34;
  logic signed [106:0] d_neg_in0_32;
  logic signed [106:0] d_neg_97;
  logic signed [105:0] d_neg_98;
  logic signed [105:0] y_61;
  logic signed [105:0] temp_33;
  logic [104:0] rMSBNextBits_31;
  logic [103:0] rLSBits_31;
  logic tempSignBit_31;
  logic qBit_31;
  logic [209:0] rNextTemp_31;
  logic signed [209:0] r32;
  logic signed [209:0] r32_p;
  logic [105:0] rMSBits_32;
  logic signed [105:0] x_32;
  logic rMSBit_31;
  logic rMSBitneg_31;
  logic switch_compare_1_35;
  logic signed [106:0] d_neg_in0_33;
  logic signed [106:0] d_neg_100;
  logic signed [105:0] d_neg_101;
  logic signed [105:0] y_63;
  logic signed [105:0] temp_34;
  logic [104:0] rMSBNextBits_32;
  logic [103:0] rLSBits_32;
  logic tempSignBit_32;
  logic qBit_32;
  logic [209:0] rNextTemp_32;
  logic signed [209:0] r33;
  logic signed [209:0] r33_p;
  logic [105:0] rMSBits_33;
  logic signed [105:0] x_33;
  logic rMSBit_32;
  logic rMSBitneg_32;
  logic switch_compare_1_36;
  logic signed [106:0] d_neg_in0_34;
  logic signed [106:0] d_neg_103;
  logic signed [105:0] d_neg_104;
  logic signed [105:0] y_65;
  logic signed [105:0] temp_35;
  logic [104:0] rMSBNextBits_33;
  logic [103:0] rLSBits_33;
  logic tempSignBit_33;
  logic qBit_33;
  logic [209:0] rNextTemp_33;
  logic signed [209:0] r34;
  logic signed [209:0] r34_p;
  logic [105:0] rMSBits_34;
  logic signed [105:0] x_34;
  logic rMSBit_33;
  logic rMSBitneg_33;
  logic switch_compare_1_37;
  logic signed [106:0] d_neg_in0_35;
  logic signed [106:0] d_neg_106;
  logic signed [105:0] d_neg_107;
  logic signed [105:0] y_67;
  logic signed [105:0] temp_36;
  logic [104:0] rMSBNextBits_34;
  logic [103:0] rLSBits_34;
  logic tempSignBit_34;
  logic qBit_34;
  logic [209:0] rNextTemp_34;
  logic signed [209:0] r35;
  logic signed [209:0] r35_p;
  logic [105:0] rMSBits_35;
  logic signed [105:0] x_35;
  logic rMSBit_34;
  logic rMSBitneg_34;
  logic switch_compare_1_38;
  logic signed [106:0] d_neg_in0_36;
  logic signed [106:0] d_neg_109;
  logic signed [105:0] d_neg_110;
  logic signed [105:0] y_69;
  logic signed [105:0] temp_37;
  logic [104:0] rMSBNextBits_35;
  logic [103:0] rLSBits_35;
  logic tempSignBit_35;
  logic qBit_35;
  logic [209:0] rNextTemp_35;
  logic signed [209:0] r36;
  logic signed [209:0] r36_p;
  logic [105:0] rMSBits_36;
  logic signed [105:0] x_36;
  logic rMSBit_35;
  logic rMSBitneg_35;
  logic switch_compare_1_39;
  logic signed [106:0] d_neg_in0_37;
  logic signed [106:0] d_neg_112;
  logic signed [105:0] d_neg_113;
  logic signed [105:0] y_71;
  logic signed [105:0] temp_38;
  logic [104:0] rMSBNextBits_36;
  logic [103:0] rLSBits_36;
  logic tempSignBit_36;
  logic qBit_36;
  logic [209:0] rNextTemp_36;
  logic signed [209:0] r37;
  logic signed [209:0] r37_p;
  logic [105:0] rMSBits_37;
  logic signed [105:0] x_37;
  logic rMSBit_36;
  logic rMSBitneg_36;
  logic switch_compare_1_40;
  logic signed [106:0] d_neg_in0_38;
  logic signed [106:0] d_neg_115;
  logic signed [105:0] d_neg_116;
  logic signed [105:0] y_73;
  logic signed [105:0] temp_39;
  logic [104:0] rMSBNextBits_37;
  logic [103:0] rLSBits_37;
  logic tempSignBit_37;
  logic qBit_37;
  logic [209:0] rNextTemp_37;
  logic signed [209:0] r38;
  logic signed [209:0] r38_p;
  logic [105:0] rMSBits_38;
  logic signed [105:0] x_38;
  logic rMSBit_37;
  logic rMSBitneg_37;
  logic switch_compare_1_41;
  logic signed [106:0] d_neg_in0_39;
  logic signed [106:0] d_neg_118;
  logic signed [105:0] d_neg_119;
  logic signed [105:0] y_75;
  logic signed [105:0] temp_40;
  logic [104:0] rMSBNextBits_38;
  logic [103:0] rLSBits_38;
  logic tempSignBit_38;
  logic qBit_38;
  logic [209:0] rNextTemp_38;
  logic signed [209:0] r39;
  logic signed [209:0] r39_p;
  logic [105:0] rMSBits_39;
  logic signed [105:0] x_39;
  logic rMSBit_38;
  logic rMSBitneg_38;
  logic switch_compare_1_42;
  logic signed [106:0] d_neg_in0_40;
  logic signed [106:0] d_neg_121;
  logic signed [105:0] d_neg_122;
  logic signed [105:0] y_77;
  logic signed [105:0] temp_41;
  logic [104:0] rMSBNextBits_39;
  logic [103:0] rLSBits_39;
  logic tempSignBit_39;
  logic qBit_39;
  logic [209:0] rNextTemp_39;
  logic signed [209:0] r40;
  logic signed [209:0] r40_p;
  logic [105:0] rMSBits_40;
  logic signed [105:0] x_40;
  logic rMSBit_39;
  logic rMSBitneg_39;
  logic switch_compare_1_43;
  logic signed [106:0] d_neg_in0_41;
  logic signed [106:0] d_neg_124;
  logic signed [105:0] d_neg_125;
  logic signed [105:0] y_79;
  logic signed [105:0] temp_42;
  logic [104:0] rMSBNextBits_40;
  logic [103:0] rLSBits_40;
  logic tempSignBit_40;
  logic qBit_40;
  logic [209:0] rNextTemp_40;
  logic signed [209:0] r41;
  logic signed [209:0] r41_p;
  logic [105:0] rMSBits_41;
  logic signed [105:0] x_41;
  logic rMSBit_40;
  logic rMSBitneg_40;
  logic switch_compare_1_44;
  logic signed [106:0] d_neg_in0_42;
  logic signed [106:0] d_neg_127;
  logic signed [105:0] d_neg_128;
  logic signed [105:0] y_81;
  logic signed [105:0] temp_43;
  logic [104:0] rMSBNextBits_41;
  logic [103:0] rLSBits_41;
  logic tempSignBit_41;
  logic qBit_41;
  logic [209:0] rNextTemp_41;
  logic signed [209:0] r42;
  logic signed [209:0] r42_p;
  logic [105:0] rMSBits_42;
  logic signed [105:0] x_42;
  logic rMSBit_41;
  logic rMSBitneg_41;
  logic switch_compare_1_45;
  logic signed [106:0] d_neg_in0_43;
  logic signed [106:0] d_neg_130;
  logic signed [105:0] d_neg_131;
  logic signed [105:0] y_83;
  logic signed [105:0] temp_44;
  logic [104:0] rMSBNextBits_42;
  logic [103:0] rLSBits_42;
  logic tempSignBit_42;
  logic qBit_42;
  logic [209:0] rNextTemp_42;
  logic signed [209:0] r43;
  logic signed [209:0] r43_p;
  logic [105:0] rMSBits_43;
  logic signed [105:0] x_43;
  logic rMSBit_42;
  logic rMSBitneg_42;
  logic switch_compare_1_46;
  logic signed [106:0] d_neg_in0_44;
  logic signed [106:0] d_neg_133;
  logic signed [105:0] d_neg_134;
  logic signed [105:0] y_85;
  logic signed [105:0] temp_45;
  logic [104:0] rMSBNextBits_43;
  logic [103:0] rLSBits_43;
  logic tempSignBit_43;
  logic qBit_43;
  logic [209:0] rNextTemp_43;
  logic signed [209:0] r44;
  logic signed [209:0] r44_p;
  logic [105:0] rMSBits_44;
  logic signed [105:0] x_44;
  logic rMSBit_43;
  logic rMSBitneg_43;
  logic switch_compare_1_47;
  logic signed [106:0] d_neg_in0_45;
  logic signed [106:0] d_neg_136;
  logic signed [105:0] d_neg_137;
  logic signed [105:0] y_87;
  logic signed [105:0] temp_46;
  logic [104:0] rMSBNextBits_44;
  logic [103:0] rLSBits_44;
  logic tempSignBit_44;
  logic qBit_44;
  logic [209:0] rNextTemp_44;
  logic signed [209:0] r45;
  logic signed [209:0] r45_p;
  logic [105:0] rMSBits_45;
  logic signed [105:0] x_45;
  logic rMSBit_44;
  logic rMSBitneg_44;
  logic switch_compare_1_48;
  logic signed [106:0] d_neg_in0_46;
  logic signed [106:0] d_neg_139;
  logic signed [105:0] d_neg_140;
  logic signed [105:0] y_89;
  logic signed [105:0] temp_47;
  logic [104:0] rMSBNextBits_45;
  logic [103:0] rLSBits_45;
  logic tempSignBit_45;
  logic qBit_45;
  logic [209:0] rNextTemp_45;
  logic signed [209:0] r46;
  logic signed [209:0] r46_p;
  logic [105:0] rMSBits_46;
  logic signed [105:0] x_46;
  logic rMSBit_45;
  logic rMSBitneg_45;
  logic switch_compare_1_49;
  logic signed [106:0] d_neg_in0_47;
  logic signed [106:0] d_neg_142;
  logic signed [105:0] d_neg_143;
  logic signed [105:0] y_91;
  logic signed [105:0] temp_48;
  logic [104:0] rMSBNextBits_46;
  logic [103:0] rLSBits_46;
  logic tempSignBit_46;
  logic qBit_46;
  logic [209:0] rNextTemp_46;
  logic signed [209:0] r47;
  logic signed [209:0] r47_p;
  logic [105:0] rMSBits_47;
  logic signed [105:0] x_47;
  logic rMSBit_46;
  logic rMSBitneg_46;
  logic switch_compare_1_50;
  logic signed [106:0] d_neg_in0_48;
  logic signed [106:0] d_neg_145;
  logic signed [105:0] d_neg_146;
  logic signed [105:0] y_93;
  logic signed [105:0] temp_49;
  logic [104:0] rMSBNextBits_47;
  logic [103:0] rLSBits_47;
  logic tempSignBit_47;
  logic qBit_47;
  logic [209:0] rNextTemp_47;
  logic signed [209:0] r48;
  logic signed [209:0] r48_p;
  logic [105:0] rMSBits_48;
  logic signed [105:0] x_48;
  logic rMSBit_47;
  logic rMSBitneg_47;
  logic switch_compare_1_51;
  logic signed [106:0] d_neg_in0_49;
  logic signed [106:0] d_neg_148;
  logic signed [105:0] d_neg_149;
  logic signed [105:0] y_95;
  logic signed [105:0] temp_50;
  logic [104:0] rMSBNextBits_48;
  logic [103:0] rLSBits_48;
  logic tempSignBit_48;
  logic qBit_48;
  logic [209:0] rNextTemp_48;
  logic signed [209:0] r49;
  logic signed [209:0] r49_p;
  logic [105:0] rMSBits_49;
  logic signed [105:0] x_49;
  logic rMSBit_48;
  logic rMSBitneg_48;
  logic switch_compare_1_52;
  logic signed [106:0] d_neg_in0_50;
  logic signed [106:0] d_neg_151;
  logic signed [105:0] d_neg_152;
  logic signed [105:0] y_97;
  logic signed [105:0] temp_51;
  logic [104:0] rMSBNextBits_49;
  logic [103:0] rLSBits_49;
  logic tempSignBit_49;
  logic qBit_49;
  logic [209:0] rNextTemp_49;
  logic signed [209:0] r50;
  logic signed [209:0] r50_p;
  logic [105:0] rMSBits_50;
  logic signed [105:0] x_50;
  logic rMSBit_49;
  logic rMSBitneg_49;
  logic switch_compare_1_53;
  logic signed [106:0] d_neg_in0_51;
  logic signed [106:0] d_neg_154;
  logic signed [105:0] d_neg_155;
  logic signed [105:0] y_99;
  logic signed [105:0] temp_52;
  logic [104:0] rMSBNextBits_50;
  logic [103:0] rLSBits_50;
  logic tempSignBit_50;
  logic qBit_50;
  logic [209:0] rNextTemp_50;
  logic signed [209:0] r51;
  logic signed [209:0] r51_p;
  logic [105:0] rMSBits_51;
  logic signed [105:0] x_51;
  logic rMSBit_50;
  logic rMSBitneg_50;
  logic switch_compare_1_54;
  logic signed [106:0] d_neg_in0_52;
  logic signed [106:0] d_neg_157;
  logic signed [105:0] d_neg_158;
  logic signed [105:0] y_101;
  logic signed [105:0] temp_53;
  logic [104:0] rMSBNextBits_51;
  logic [103:0] rLSBits_51;
  logic tempSignBit_51;
  logic qBit_51;
  logic [209:0] rNextTemp_51;
  logic signed [209:0] r52;
  logic signed [209:0] r52_p;
  logic [105:0] rMSBits_52;
  logic signed [105:0] x_52;
  logic rMSBit_51;
  logic rMSBitneg_51;
  logic switch_compare_1_55;
  logic signed [106:0] d_neg_in0_53;
  logic signed [106:0] d_neg_160;
  logic signed [105:0] d_neg_161;
  logic signed [105:0] y_103;
  logic signed [105:0] temp_54;
  logic [104:0] rMSBNextBits_52;
  logic [103:0] rLSBits_52;
  logic tempSignBit_52;
  logic qBit_52;
  logic [209:0] rNextTemp_52;
  logic signed [209:0] r53;
  logic signed [209:0] r53_p;
  logic [105:0] rMSBits_53;
  logic signed [105:0] x_53;
  logic rMSBit_52;
  logic rMSBitneg_52;
  logic switch_compare_1_56;
  logic signed [106:0] d_neg_in0_54;
  logic signed [106:0] d_neg_163;
  logic signed [105:0] d_neg_164;
  logic signed [105:0] y_105;
  logic signed [105:0] temp_55;
  logic [104:0] rMSBNextBits_53;
  logic [103:0] rLSBits_53;
  logic tempSignBit_53;
  logic qBit_53;
  logic [209:0] rNextTemp_53;
  logic signed [209:0] r54;
  logic signed [209:0] r54_p;
  logic [105:0] rMSBits_54;
  logic signed [105:0] x_54;
  logic rMSBit_53;
  logic rMSBitneg_53;
  logic switch_compare_1_57;
  logic signed [106:0] d_neg_in0_55;
  logic signed [106:0] d_neg_166;
  logic signed [105:0] d_neg_167;
  logic signed [105:0] y_107;
  logic signed [105:0] temp_56;
  logic [104:0] rMSBNextBits_54;
  logic [103:0] rLSBits_54;
  logic tempSignBit_54;
  logic qBit_54;
  logic [209:0] rNextTemp_54;
  logic signed [209:0] r55;
  logic signed [209:0] r55_p;
  logic [105:0] rMSBits_55;
  logic signed [105:0] x_55;
  logic rMSBit_54;
  logic rMSBitneg_54;
  logic switch_compare_1_58;
  logic signed [106:0] d_neg_in0_56;
  logic signed [106:0] d_neg_169;
  logic signed [105:0] d_neg_170;
  logic signed [105:0] y_109;
  logic signed [105:0] temp_57;
  logic [104:0] rMSBNextBits_55;
  logic [103:0] rLSBits_55;
  logic tempSignBit_55;
  logic qBit_55;
  logic [209:0] rNextTemp_55;
  logic signed [209:0] r56;
  logic signed [209:0] r56_p;
  logic [105:0] rMSBits_56;
  logic signed [105:0] x_56;
  logic rMSBit_55;
  logic rMSBitneg_55;
  logic switch_compare_1_59;
  logic signed [106:0] d_neg_in0_57;
  logic signed [106:0] d_neg_172;
  logic signed [105:0] d_neg_173;
  logic signed [105:0] y_111;
  logic signed [105:0] temp_58;
  logic [104:0] rMSBNextBits_56;
  logic [103:0] rLSBits_56;
  logic tempSignBit_56;
  logic qBit_56;
  logic [209:0] rNextTemp_56;
  logic signed [209:0] r57;
  logic signed [209:0] r57_p;
  logic [105:0] rMSBits_57;
  logic signed [105:0] x_57;
  logic rMSBit_56;
  logic rMSBitneg_56;
  logic switch_compare_1_60;
  logic signed [106:0] d_neg_in0_58;
  logic signed [106:0] d_neg_175;
  logic signed [105:0] d_neg_176;
  logic signed [105:0] y_113;
  logic signed [105:0] temp_59;
  logic [104:0] rMSBNextBits_57;
  logic [103:0] rLSBits_57;
  logic tempSignBit_57;
  logic qBit_57;
  logic [209:0] rNextTemp_57;
  logic signed [209:0] r58;
  logic signed [209:0] r58_p;
  logic [105:0] rMSBits_58;
  logic signed [105:0] x_58;
  logic rMSBit_57;
  logic rMSBitneg_57;
  logic switch_compare_1_61;
  logic signed [106:0] d_neg_in0_59;
  logic signed [106:0] d_neg_178;
  logic signed [105:0] d_neg_179;
  logic signed [105:0] y_115;
  logic signed [105:0] temp_60;
  logic [104:0] rMSBNextBits_58;
  logic [103:0] rLSBits_58;
  logic tempSignBit_58;
  logic qBit_58;
  logic [209:0] rNextTemp_58;
  logic signed [209:0] r59;
  logic signed [209:0] r59_p;
  logic [105:0] rMSBits_59;
  logic signed [105:0] x_59;
  logic rMSBit_58;
  logic rMSBitneg_58;
  logic switch_compare_1_62;
  logic signed [106:0] d_neg_in0_60;
  logic signed [106:0] d_neg_181;
  logic signed [105:0] d_neg_182;
  logic signed [105:0] y_117;
  logic signed [105:0] temp_61;
  logic [104:0] rMSBNextBits_59;
  logic [103:0] rLSBits_59;
  logic tempSignBit_59;
  logic qBit_59;
  logic [209:0] rNextTemp_59;
  logic signed [209:0] r60;
  logic signed [209:0] r60_p;
  logic [105:0] rMSBits_60;
  logic signed [105:0] x_60;
  logic rMSBit_59;
  logic rMSBitneg_59;
  logic switch_compare_1_63;
  logic signed [106:0] d_neg_in0_61;
  logic signed [106:0] d_neg_184;
  logic signed [105:0] d_neg_185;
  logic signed [105:0] y_119;
  logic signed [105:0] temp_62;
  logic [104:0] rMSBNextBits_60;
  logic [103:0] rLSBits_60;
  logic tempSignBit_60;
  logic qBit_60;
  logic [209:0] rNextTemp_60;
  logic signed [209:0] r61;
  logic signed [209:0] r61_p;
  logic [105:0] rMSBits_61;
  logic signed [105:0] x_61;
  logic rMSBit_60;
  logic rMSBitneg_60;
  logic switch_compare_1_64;
  logic signed [106:0] d_neg_in0_62;
  logic signed [106:0] d_neg_187;
  logic signed [105:0] d_neg_188;
  logic signed [105:0] y_121;
  logic signed [105:0] temp_63;
  logic [104:0] rMSBNextBits_61;
  logic [103:0] rLSBits_61;
  logic tempSignBit_61;
  logic qBit_61;
  logic [209:0] rNextTemp_61;
  logic signed [209:0] r62;
  logic signed [209:0] r62_p;
  logic [105:0] rMSBits_62;
  logic signed [105:0] x_62;
  logic rMSBit_61;
  logic rMSBitneg_61;
  logic switch_compare_1_65;
  logic signed [106:0] d_neg_in0_63;
  logic signed [106:0] d_neg_190;
  logic signed [105:0] d_neg_191;
  logic signed [105:0] y_123;
  logic signed [105:0] temp_64;
  logic [104:0] rMSBNextBits_62;
  logic [103:0] rLSBits_62;
  logic tempSignBit_62;
  logic qBit_62;
  logic [209:0] rNextTemp_62;
  logic signed [209:0] r63;
  logic signed [209:0] r63_p;
  logic [105:0] rMSBits_63;
  logic signed [105:0] x_63;
  logic rMSBit_62;
  logic rMSBitneg_62;
  logic switch_compare_1_66;
  logic signed [106:0] d_neg_in0_64;
  logic signed [106:0] d_neg_193;
  logic signed [105:0] d_neg_194;
  logic signed [105:0] y_125;
  logic signed [105:0] temp_65;
  logic [104:0] rMSBNextBits_63;
  logic [103:0] rLSBits_63;
  logic tempSignBit_63;
  logic qBit_63;
  logic [209:0] rNextTemp_63;
  logic signed [209:0] r64;
  logic signed [209:0] r64_p;
  logic [105:0] rMSBits_64;
  logic signed [105:0] x_64;
  logic rMSBit_63;
  logic rMSBitneg_63;
  logic switch_compare_1_67;
  logic signed [106:0] d_neg_in0_65;
  logic signed [106:0] d_neg_196;
  logic signed [105:0] d_neg_197;
  logic signed [105:0] y_127;
  logic signed [105:0] temp_66;
  logic [104:0] rMSBNextBits_64;
  logic [103:0] rLSBits_64;
  logic tempSignBit_64;
  logic qBit_64;
  logic [209:0] rNextTemp_64;
  logic signed [209:0] r65;
  logic signed [209:0] r65_p;
  logic [105:0] rMSBits_65;
  logic signed [105:0] x_65;
  logic rMSBit_64;
  logic rMSBitneg_64;
  logic switch_compare_1_68;
  logic signed [106:0] d_neg_in0_66;
  logic signed [106:0] d_neg_199;
  logic signed [105:0] d_neg_200;
  logic signed [105:0] y_129;
  logic signed [105:0] temp_67;
  logic [104:0] rMSBNextBits_65;
  logic [103:0] rLSBits_65;
  logic tempSignBit_65;
  logic qBit_65;
  logic [209:0] rNextTemp_65;
  logic signed [209:0] r66;
  logic signed [209:0] r66_p;
  logic [105:0] rMSBits_66;
  logic signed [105:0] x_66;
  logic rMSBit_65;
  logic rMSBitneg_65;
  logic switch_compare_1_69;
  logic signed [106:0] d_neg_in0_67;
  logic signed [106:0] d_neg_202;
  logic signed [105:0] d_neg_203;
  logic signed [105:0] y_131;
  logic signed [105:0] temp_68;
  logic [104:0] rMSBNextBits_66;
  logic [103:0] rLSBits_66;
  logic tempSignBit_66;
  logic qBit_66;
  logic [209:0] rNextTemp_66;
  logic signed [209:0] r67;
  logic signed [209:0] r67_p;
  logic [105:0] rMSBits_67;
  logic signed [105:0] x_67;
  logic rMSBit_66;
  logic rMSBitneg_66;
  logic switch_compare_1_70;
  logic signed [106:0] d_neg_in0_68;
  logic signed [106:0] d_neg_205;
  logic signed [105:0] d_neg_206;
  logic signed [105:0] y_133;
  logic signed [105:0] temp_69;
  logic [104:0] rMSBNextBits_67;
  logic [103:0] rLSBits_67;
  logic tempSignBit_67;
  logic qBit_67;
  logic [209:0] rNextTemp_67;
  logic signed [209:0] r68;
  logic signed [209:0] r68_p;
  logic [105:0] rMSBits_68;
  logic signed [105:0] x_68;
  logic rMSBit_67;
  logic rMSBitneg_67;
  logic switch_compare_1_71;
  logic signed [106:0] d_neg_in0_69;
  logic signed [106:0] d_neg_208;
  logic signed [105:0] d_neg_209;
  logic signed [105:0] y_135;
  logic signed [105:0] temp_70;
  logic [104:0] rMSBNextBits_68;
  logic [103:0] rLSBits_68;
  logic tempSignBit_68;
  logic qBit_68;
  logic [209:0] rNextTemp_68;
  logic signed [209:0] r69;
  logic signed [209:0] r69_p;
  logic [105:0] rMSBits_69;
  logic signed [105:0] x_69;
  logic rMSBit_68;
  logic rMSBitneg_68;
  logic switch_compare_1_72;
  logic signed [106:0] d_neg_in0_70;
  logic signed [106:0] d_neg_211;
  logic signed [105:0] d_neg_212;
  logic signed [105:0] y_137;
  logic signed [105:0] temp_71;
  logic [104:0] rMSBNextBits_69;
  logic [103:0] rLSBits_69;
  logic tempSignBit_69;
  logic qBit_69;
  logic [209:0] rNextTemp_69;
  logic signed [209:0] r70;
  logic signed [209:0] r70_p;
  logic [105:0] rMSBits_70;
  logic signed [105:0] x_70;
  logic rMSBit_69;
  logic rMSBitneg_69;
  logic switch_compare_1_73;
  logic signed [106:0] d_neg_in0_71;
  logic signed [106:0] d_neg_214;
  logic signed [105:0] d_neg_215;
  logic signed [105:0] y_139;
  logic signed [105:0] temp_72;
  logic [104:0] rMSBNextBits_70;
  logic [103:0] rLSBits_70;
  logic tempSignBit_70;
  logic qBit_70;
  logic [209:0] rNextTemp_70;
  logic signed [209:0] r71;
  logic signed [209:0] r71_p;
  logic [105:0] rMSBits_71;
  logic signed [105:0] x_71;
  logic rMSBit_70;
  logic rMSBitneg_70;
  logic switch_compare_1_74;
  logic signed [106:0] d_neg_in0_72;
  logic signed [106:0] d_neg_217;
  logic signed [105:0] d_neg_218;
  logic signed [105:0] y_141;
  logic signed [105:0] temp_73;
  logic [104:0] rMSBNextBits_71;
  logic [103:0] rLSBits_71;
  logic tempSignBit_71;
  logic qBit_71;
  logic [209:0] rNextTemp_71;
  logic signed [209:0] r72;
  logic signed [209:0] r72_p;
  logic [105:0] rMSBits_72;
  logic signed [105:0] x_72;
  logic rMSBit_71;
  logic rMSBitneg_71;
  logic switch_compare_1_75;
  logic signed [106:0] d_neg_in0_73;
  logic signed [106:0] d_neg_220;
  logic signed [105:0] d_neg_221;
  logic signed [105:0] y_143;
  logic signed [105:0] temp_74;
  logic [104:0] rMSBNextBits_72;
  logic [103:0] rLSBits_72;
  logic tempSignBit_72;
  logic qBit_72;
  logic [209:0] rNextTemp_72;
  logic signed [209:0] r73;
  logic signed [209:0] r73_p;
  logic [105:0] rMSBits_73;
  logic signed [105:0] x_73;
  logic rMSBit_72;
  logic rMSBitneg_72;
  logic switch_compare_1_76;
  logic signed [106:0] d_neg_in0_74;
  logic signed [106:0] d_neg_223;
  logic signed [105:0] d_neg_224;
  logic signed [105:0] y_145;
  logic signed [105:0] temp_75;
  logic [104:0] rMSBNextBits_73;
  logic [103:0] rLSBits_73;
  logic tempSignBit_73;
  logic qBit_73;
  logic [209:0] rNextTemp_73;
  logic signed [209:0] r74;
  logic signed [209:0] r74_p;
  logic [105:0] rMSBits_74;
  logic signed [105:0] x_74;
  logic rMSBit_73;
  logic rMSBitneg_73;
  logic switch_compare_1_77;
  logic signed [106:0] d_neg_in0_75;
  logic signed [106:0] d_neg_226;
  logic signed [105:0] d_neg_227;
  logic signed [105:0] y_147;
  logic signed [105:0] temp_76;
  logic [104:0] rMSBNextBits_74;
  logic [103:0] rLSBits_74;
  logic tempSignBit_74;
  logic qBit_74;
  logic [209:0] rNextTemp_74;
  logic signed [209:0] r75;
  logic signed [209:0] r75_p;
  logic [105:0] rMSBits_75;
  logic signed [105:0] x_75;
  logic rMSBit_74;
  logic rMSBitneg_74;
  logic switch_compare_1_78;
  logic signed [106:0] d_neg_in0_76;
  logic signed [106:0] d_neg_229;
  logic signed [105:0] d_neg_230;
  logic signed [105:0] y_149;
  logic signed [105:0] temp_77;
  logic [104:0] rMSBNextBits_75;
  logic [103:0] rLSBits_75;
  logic tempSignBit_75;
  logic qBit_75;
  logic [209:0] rNextTemp_75;
  logic signed [209:0] r76;
  logic signed [209:0] r76_p;
  logic [105:0] rMSBits_76;
  logic signed [105:0] x_76;
  logic rMSBit_75;
  logic rMSBitneg_75;
  logic switch_compare_1_79;
  logic signed [106:0] d_neg_in0_77;
  logic signed [106:0] d_neg_232;
  logic signed [105:0] d_neg_233;
  logic signed [105:0] y_151;
  logic signed [105:0] temp_78;
  logic [104:0] rMSBNextBits_76;
  logic [103:0] rLSBits_76;
  logic tempSignBit_76;
  logic qBit_76;
  logic [209:0] rNextTemp_76;
  logic signed [209:0] r77;
  logic signed [209:0] r77_p;
  logic [105:0] rMSBits_77;
  logic signed [105:0] x_77;
  logic rMSBit_76;
  logic rMSBitneg_76;
  logic switch_compare_1_80;
  logic signed [106:0] d_neg_in0_78;
  logic signed [106:0] d_neg_235;
  logic signed [105:0] d_neg_236;
  logic signed [105:0] y_153;
  logic signed [105:0] temp_79;
  logic [104:0] rMSBNextBits_77;
  logic [103:0] rLSBits_77;
  logic tempSignBit_77;
  logic qBit_77;
  logic [209:0] rNextTemp_77;
  logic signed [209:0] r78;
  logic signed [209:0] r78_p;
  logic [105:0] rMSBits_78;
  logic signed [105:0] x_78;
  logic rMSBit_77;
  logic rMSBitneg_77;
  logic switch_compare_1_81;
  logic signed [106:0] d_neg_in0_79;
  logic signed [106:0] d_neg_238;
  logic signed [105:0] d_neg_239;
  logic signed [105:0] y_155;
  logic signed [105:0] temp_80;
  logic [104:0] rMSBNextBits_78;
  logic [103:0] rLSBits_78;
  logic tempSignBit_78;
  logic qBit_78;
  logic [209:0] rNextTemp_78;
  logic signed [209:0] r79;
  logic signed [209:0] r79_p;
  logic [105:0] rMSBits_79;
  logic signed [105:0] x_79;
  logic rMSBit_78;
  logic rMSBitneg_78;
  logic switch_compare_1_82;
  logic signed [106:0] d_neg_in0_80;
  logic signed [106:0] d_neg_241;
  logic signed [105:0] d_neg_242;
  logic signed [105:0] y_157;
  logic signed [105:0] temp_81;
  logic [104:0] rMSBNextBits_79;
  logic [103:0] rLSBits_79;
  logic tempSignBit_79;
  logic qBit_79;
  logic [209:0] rNextTemp_79;
  logic signed [209:0] r80;
  logic signed [209:0] r80_p;
  logic [105:0] rMSBits_80;
  logic signed [105:0] x_80;
  logic rMSBit_79;
  logic rMSBitneg_79;
  logic switch_compare_1_83;
  logic signed [106:0] d_neg_in0_81;
  logic signed [106:0] d_neg_244;
  logic signed [105:0] d_neg_245;
  logic signed [105:0] y_159;
  logic signed [105:0] temp_82;
  logic [104:0] rMSBNextBits_80;
  logic [103:0] rLSBits_80;
  logic tempSignBit_80;
  logic qBit_80;
  logic [209:0] rNextTemp_80;
  logic signed [209:0] r81;
  logic signed [209:0] r81_p;
  logic [105:0] rMSBits_81;
  logic signed [105:0] x_81;
  logic rMSBit_80;
  logic rMSBitneg_80;
  logic switch_compare_1_84;
  logic signed [106:0] d_neg_in0_82;
  logic signed [106:0] d_neg_247;
  logic signed [105:0] d_neg_248;
  logic signed [105:0] y_161;
  logic signed [105:0] temp_83;
  logic [104:0] rMSBNextBits_81;
  logic [103:0] rLSBits_81;
  logic tempSignBit_81;
  logic qBit_81;
  logic [209:0] rNextTemp_81;
  logic signed [209:0] r82;
  logic signed [209:0] r82_p;
  logic [105:0] rMSBits_82;
  logic signed [105:0] x_82;
  logic rMSBit_81;
  logic rMSBitneg_81;
  logic switch_compare_1_85;
  logic signed [106:0] d_neg_in0_83;
  logic signed [106:0] d_neg_250;
  logic signed [105:0] d_neg_251;
  logic signed [105:0] y_163;
  logic signed [105:0] temp_84;
  logic [104:0] rMSBNextBits_82;
  logic [103:0] rLSBits_82;
  logic tempSignBit_82;
  logic qBit_82;
  logic [209:0] rNextTemp_82;
  logic signed [209:0] r83;
  logic signed [209:0] r83_p;
  logic [105:0] rMSBits_83;
  logic signed [105:0] x_83;
  logic rMSBit_82;
  logic rMSBitneg_82;
  logic switch_compare_1_86;
  logic signed [106:0] d_neg_in0_84;
  logic signed [106:0] d_neg_253;
  logic signed [105:0] d_neg_254;
  logic signed [105:0] y_165;
  logic signed [105:0] temp_85;
  logic [104:0] rMSBNextBits_83;
  logic [103:0] rLSBits_83;
  logic tempSignBit_83;
  logic qBit_83;
  logic [209:0] rNextTemp_83;
  logic signed [209:0] r84;
  logic signed [209:0] r84_p;
  logic [105:0] rMSBits_84;
  logic signed [105:0] x_84;
  logic rMSBit_83;
  logic rMSBitneg_83;
  logic switch_compare_1_87;
  logic signed [106:0] d_neg_in0_85;
  logic signed [106:0] d_neg_256;
  logic signed [105:0] d_neg_257;
  logic signed [105:0] y_167;
  logic signed [105:0] temp_86;
  logic [104:0] rMSBNextBits_84;
  logic [103:0] rLSBits_84;
  logic tempSignBit_84;
  logic qBit_84;
  logic [209:0] rNextTemp_84;
  logic signed [209:0] r85;
  logic signed [209:0] r85_p;
  logic [105:0] rMSBits_85;
  logic signed [105:0] x_85;
  logic rMSBit_84;
  logic rMSBitneg_84;
  logic switch_compare_1_88;
  logic signed [106:0] d_neg_in0_86;
  logic signed [106:0] d_neg_259;
  logic signed [105:0] d_neg_260;
  logic signed [105:0] y_169;
  logic signed [105:0] temp_87;
  logic [104:0] rMSBNextBits_85;
  logic [103:0] rLSBits_85;
  logic tempSignBit_85;
  logic qBit_85;
  logic [209:0] rNextTemp_85;
  logic signed [209:0] r86;
  logic signed [209:0] r86_p;
  logic [105:0] rMSBits_86;
  logic signed [105:0] x_86;
  logic rMSBit_85;
  logic rMSBitneg_85;
  logic switch_compare_1_89;
  logic signed [106:0] d_neg_in0_87;
  logic signed [106:0] d_neg_262;
  logic signed [105:0] d_neg_263;
  logic signed [105:0] y_171;
  logic signed [105:0] temp_88;
  logic [104:0] rMSBNextBits_86;
  logic [103:0] rLSBits_86;
  logic tempSignBit_86;
  logic qBit_86;
  logic [209:0] rNextTemp_86;
  logic signed [209:0] r87;
  logic signed [209:0] r87_p;
  logic [105:0] rMSBits_87;
  logic signed [105:0] x_87;
  logic rMSBit_86;
  logic rMSBitneg_86;
  logic switch_compare_1_90;
  logic signed [106:0] d_neg_in0_88;
  logic signed [106:0] d_neg_265;
  logic signed [105:0] d_neg_266;
  logic signed [105:0] y_173;
  logic signed [105:0] temp_89;
  logic [104:0] rMSBNextBits_87;
  logic [103:0] rLSBits_87;
  logic tempSignBit_87;
  logic qBit_87;
  logic [209:0] rNextTemp_87;
  logic signed [209:0] r88;
  logic signed [209:0] r88_p;
  logic [105:0] rMSBits_88;
  logic signed [105:0] x_88;
  logic rMSBit_87;
  logic rMSBitneg_87;
  logic switch_compare_1_91;
  logic signed [106:0] d_neg_in0_89;
  logic signed [106:0] d_neg_268;
  logic signed [105:0] d_neg_269;
  logic signed [105:0] y_175;
  logic signed [105:0] temp_90;
  logic [104:0] rMSBNextBits_88;
  logic [103:0] rLSBits_88;
  logic tempSignBit_88;
  logic qBit_88;
  logic [209:0] rNextTemp_88;
  logic signed [209:0] r89;
  logic signed [209:0] r89_p;
  logic [105:0] rMSBits_89;
  logic signed [105:0] x_89;
  logic rMSBit_88;
  logic rMSBitneg_88;
  logic switch_compare_1_92;
  logic signed [106:0] d_neg_in0_90;
  logic signed [106:0] d_neg_271;
  logic signed [105:0] d_neg_272;
  logic signed [105:0] y_177;
  logic signed [105:0] temp_91;
  logic [104:0] rMSBNextBits_89;
  logic [103:0] rLSBits_89;
  logic tempSignBit_89;
  logic qBit_89;
  logic [209:0] rNextTemp_89;
  logic signed [209:0] r90;
  logic signed [209:0] r90_p;
  logic [105:0] rMSBits_90;
  logic signed [105:0] x_90;
  logic rMSBit_89;
  logic rMSBitneg_89;
  logic switch_compare_1_93;
  logic signed [106:0] d_neg_in0_91;
  logic signed [106:0] d_neg_274;
  logic signed [105:0] d_neg_275;
  logic signed [105:0] y_179;
  logic signed [105:0] temp_92;
  logic [104:0] rMSBNextBits_90;
  logic [103:0] rLSBits_90;
  logic tempSignBit_90;
  logic qBit_90;
  logic [209:0] rNextTemp_90;
  logic signed [209:0] r91;
  logic signed [209:0] r91_p;
  logic [105:0] rMSBits_91;
  logic signed [105:0] x_91;
  logic rMSBit_90;
  logic rMSBitneg_90;
  logic switch_compare_1_94;
  logic signed [106:0] d_neg_in0_92;
  logic signed [106:0] d_neg_277;
  logic signed [105:0] d_neg_278;
  logic signed [105:0] y_181;
  logic signed [105:0] temp_93;
  logic [104:0] rMSBNextBits_91;
  logic [103:0] rLSBits_91;
  logic tempSignBit_91;
  logic qBit_91;
  logic [209:0] rNextTemp_91;
  logic signed [209:0] r92;
  logic signed [209:0] r92_p;
  logic [105:0] rMSBits_92;
  logic signed [105:0] x_92;
  logic rMSBit_91;
  logic rMSBitneg_91;
  logic switch_compare_1_95;
  logic signed [106:0] d_neg_in0_93;
  logic signed [106:0] d_neg_280;
  logic signed [105:0] d_neg_281;
  logic signed [105:0] y_183;
  logic signed [105:0] temp_94;
  logic [104:0] rMSBNextBits_92;
  logic [103:0] rLSBits_92;
  logic tempSignBit_92;
  logic qBit_92;
  logic [209:0] rNextTemp_92;
  logic signed [209:0] r93;
  logic signed [209:0] r93_p;
  logic [105:0] rMSBits_93;
  logic signed [105:0] x_93;
  logic rMSBit_92;
  logic rMSBitneg_92;
  logic switch_compare_1_96;
  logic signed [106:0] d_neg_in0_94;
  logic signed [106:0] d_neg_283;
  logic signed [105:0] d_neg_284;
  logic signed [105:0] y_185;
  logic signed [105:0] temp_95;
  logic [104:0] rMSBNextBits_93;
  logic [103:0] rLSBits_93;
  logic tempSignBit_93;
  logic qBit_93;
  logic [209:0] rNextTemp_93;
  logic signed [209:0] r94;
  logic signed [209:0] r94_p;
  logic [105:0] rMSBits_94;
  logic signed [105:0] x_94;
  logic rMSBit_93;
  logic rMSBitneg_93;
  logic switch_compare_1_97;
  logic signed [106:0] d_neg_in0_95;
  logic signed [106:0] d_neg_286;
  logic signed [105:0] d_neg_287;
  logic signed [105:0] y_187;
  logic signed [105:0] temp_96;
  logic [104:0] rMSBNextBits_94;
  logic [103:0] rLSBits_94;
  logic tempSignBit_94;
  logic qBit_94;
  logic [209:0] rNextTemp_94;
  logic signed [209:0] r95;
  logic signed [209:0] r95_p;
  logic [105:0] rMSBits_95;
  logic signed [105:0] x_95;
  logic rMSBit_94;
  logic rMSBitneg_94;
  logic switch_compare_1_98;
  logic signed [106:0] d_neg_in0_96;
  logic signed [106:0] d_neg_289;
  logic signed [105:0] d_neg_290;
  logic signed [105:0] y_189;
  logic signed [105:0] temp_97;
  logic [104:0] rMSBNextBits_95;
  logic [103:0] rLSBits_95;
  logic tempSignBit_95;
  logic qBit_95;
  logic [209:0] rNextTemp_95;
  logic signed [209:0] r96;
  logic signed [209:0] r96_p;
  logic [105:0] rMSBits_96;
  logic signed [105:0] x_96;
  logic rMSBit_95;
  logic rMSBitneg_95;
  logic switch_compare_1_99;
  logic signed [106:0] d_neg_in0_97;
  logic signed [106:0] d_neg_292;
  logic signed [105:0] d_neg_293;
  logic signed [105:0] y_191;
  logic signed [105:0] temp_98;
  logic [104:0] rMSBNextBits_96;
  logic [103:0] rLSBits_96;
  logic tempSignBit_96;
  logic qBit_96;
  logic [209:0] rNextTemp_96;
  logic signed [209:0] r97;
  logic signed [209:0] r97_p;
  logic [105:0] rMSBits_97;
  logic signed [105:0] x_97;
  logic rMSBit_96;
  logic rMSBitneg_96;
  logic switch_compare_1_100;
  logic signed [106:0] d_neg_in0_98;
  logic signed [106:0] d_neg_295;
  logic signed [105:0] d_neg_296;
  logic signed [105:0] y_193;
  logic signed [105:0] temp_99;
  logic [104:0] rMSBNextBits_97;
  logic [103:0] rLSBits_97;
  logic tempSignBit_97;
  logic qBit_97;
  logic [209:0] rNextTemp_97;
  logic signed [209:0] r98;
  logic signed [209:0] r98_p;
  logic [105:0] rMSBits_98;
  logic signed [105:0] x_98;
  logic rMSBit_97;
  logic rMSBitneg_97;
  logic switch_compare_1_101;
  logic signed [106:0] d_neg_in0_99;
  logic signed [106:0] d_neg_298;
  logic signed [105:0] d_neg_299;
  logic signed [105:0] y_195;
  logic signed [105:0] temp_100;
  logic [104:0] rMSBNextBits_98;
  logic [103:0] rLSBits_98;
  logic tempSignBit_98;
  logic qBit_98;
  logic [209:0] rNextTemp_98;
  logic signed [209:0] r99;
  logic signed [209:0] r99_p;
  logic [105:0] rMSBits_99;
  logic signed [105:0] x_99;
  logic rMSBit_98;
  logic rMSBitneg_98;
  logic switch_compare_1_102;
  logic signed [106:0] d_neg_in0_100;
  logic signed [106:0] d_neg_301;
  logic signed [105:0] d_neg_302;
  logic signed [105:0] y_197;
  logic signed [105:0] temp_101;
  logic [104:0] rMSBNextBits_99;
  logic [103:0] rLSBits_99;
  logic tempSignBit_99;
  logic qBit_99;
  logic [209:0] rNextTemp_99;
  logic signed [209:0] r100;
  logic signed [209:0] r100_p;
  logic [105:0] rMSBits_100;
  logic signed [105:0] x_100;
  logic rMSBit_99;
  logic rMSBitneg_99;
  logic switch_compare_1_103;
  logic signed [106:0] d_neg_in0_101;
  logic signed [106:0] d_neg_304;
  logic signed [105:0] d_neg_305;
  logic signed [105:0] y_199;
  logic signed [105:0] temp_102;
  logic [104:0] rMSBNextBits_100;
  logic [103:0] rLSBits_100;
  logic tempSignBit_100;
  logic qBit_100;
  logic [209:0] rNextTemp_100;
  logic signed [209:0] r101;
  logic signed [209:0] r101_p;
  logic [105:0] rMSBits_101;
  logic signed [105:0] x_101;
  logic rMSBit_100;
  logic rMSBitneg_100;
  logic switch_compare_1_104;
  logic signed [106:0] d_neg_in0_102;
  logic signed [106:0] d_neg_307;
  logic signed [105:0] d_neg_308;
  logic signed [105:0] y_201;
  logic signed [105:0] temp_103;
  logic [104:0] rMSBNextBits_101;
  logic [103:0] rLSBits_101;
  logic tempSignBit_101;
  logic qBit_101;
  logic [209:0] rNextTemp_101;
  logic signed [209:0] r102;
  logic signed [209:0] r102_p;
  logic [105:0] rMSBits_102;
  logic signed [105:0] x_102;
  logic rMSBit_101;
  logic rMSBitneg_101;
  logic switch_compare_1_105;
  logic signed [106:0] d_neg_in0_103;
  logic signed [106:0] d_neg_310;
  logic signed [105:0] d_neg_311;
  logic signed [105:0] y_203;
  logic signed [105:0] temp_104;
  logic [104:0] rMSBNextBits_102;
  logic [103:0] rLSBits_102;
  logic tempSignBit_102;
  logic qBit_102;
  logic [209:0] rNextTemp_102;
  logic signed [209:0] r103;
  logic signed [209:0] r103_p;
  logic [105:0] rMSBits_103;
  logic signed [105:0] x_103;
  logic rMSBit_102;
  logic rMSBitneg_102;
  logic switch_compare_1_106;
  logic signed [106:0] d_neg_in0_104;
  logic signed [106:0] d_neg_313;
  logic signed [105:0] d_neg_314;
  logic signed [105:0] y_205;
  logic signed [105:0] temp_105;
  logic [104:0] rMSBNextBits_103;
  logic [103:0] rLSBits_103;
  logic tempSignBit_103;
  logic qBit_103;
  logic [209:0] rNextTemp_103;
  logic signed [209:0] r104;
  logic signed [209:0] r104_p;
  logic [105:0] rMSBits_104;
  logic signed [105:0] x_104;
  logic rMSBit_103;
  logic rMSBitneg_103;
  logic switch_compare_1_107;
  logic signed [106:0] d_neg_in0_105;
  logic signed [106:0] d_neg_316;
  logic signed [105:0] d_neg_317;
  logic signed [105:0] y_207;
  logic signed [105:0] temp_106;
  logic [104:0] rMSBNextBits_104;
  logic [103:0] rLSBits_104;
  logic tempSignBit_104;
  logic qBit_104;
  logic [209:0] rNextTemp_104;
  logic signed [209:0] r105;
  logic signed [209:0] r105_p;
  logic [104:0] qTemp;
  logic rMSBit_104;
  logic switch_compare_1_108;
  logic [104:0] rMSBits_105;
  logic signed [104:0] rMSBits_dtc;
  logic signed [105:0] x_105;
  logic signed [105:0] add_correct_out;
  logic signed [105:0] corrected_rem_1;
  logic switch_compare_1_109;
  logic qIsOdd;
  logic [105:0] scaled_rem;
  logic [105:0] nextRem;
  logic [105:0] d_p_dtc;
  logic istie;
  logic needsTiebreak;
  logic isgreater;
  logic needsRounding;
  logic [104:0] incQ;
  logic [104:0] qRounded;
  logic [104:0] qround_remNZ;
  logic [104:0] q_post_calc;
  logic signed [105:0] qtempExt;
  logic signed [105:0] qtempExt_p_1;
  logic signed [106:0] qin_neg_post_in0;
  logic signed [106:0] qin_neg_post_1;
  logic signed [105:0] qin_neg_post_2;
  logic signed [105:0] qtemp_post;
  logic sel1;
  logic sel0;
  logic [1:0] sel;
  logic signed [105:0] ConstantSignalMax_1;
  logic signed [105:0] ConstantSignalMin_1;
  logic signed [105:0] qtempPost;
  logic signed [105:0] qtempPost_1;
  logic signed [105:0] qtempPost_2;
  logic [71:0] qoutDTC;
  logic [71:0] quotient_1;


  assign init_guard_true_1 = 1'b1;

  always_ff @(posedge clk)
    begin : matching_delays_process
      if (reset == 1'b1) begin
        matching_delays_reg <= '{default :1'b0};
      end
      else begin
        if (enb) begin
          matching_delays_reg[0] <= init_guard_true_1;
          matching_delays_reg[32'sd108:32'sd1] <= matching_delays_reg[32'sd107:32'sd0];
        end
      end
    end

  assign init_guard_true_2 = matching_delays_reg[108];

  assign quotientinit_guard_default = 72'h000000000000000000;

  assign trueFlag_1 = 1'b1;
  always_ff @(posedge clk)
    begin : initFlagDelay_process
      if (reset == 1'b1) begin
        initFlagenable <= 1'b0;
      end
      else begin
        if (enb) begin
          initFlagenable <= trueFlag_1;
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
          delayMatch_reg[0] <= initFlagenable;
          delayMatch_reg[32'sd106:32'sd1] <= delayMatch_reg[32'sd105:32'sd0];
        end
      end
    end

  assign initFlagenable_1 = delayMatch_reg[106];

  assign ConstantSignal_1 = 106'sh000000000000000000000000000;
  always_ff @(posedge clk)
    begin : z_p_process
      if (reset == 1'b1) begin
        dividend_in_reg <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          dividend_in_reg <= dividend_in;
        end
      end
    end
  assign s = {{40{dividend_in_reg[63]}}, dividend_in_reg};
  assign dividend_inshift_reg = s <<< 8'd40;
  assign z_MSB = dividend_inshift_reg[103];
  always_ff @(posedge clk)
    begin : d_p_process
      if (reset == 1'b1) begin
        divisor_in_reg <= 64'sh0000000000000000;
      end
      else begin
        if (enb) begin
          divisor_in_reg <= divisor_in;
        end
      end
    end
  assign d_MSB = divisor_in_reg[63];
  assign isSignsDiffer = z_MSB ^ d_MSB;
  always_ff @(posedge clk)
    begin : signFlag_p_process
      if (reset == 1'b1) begin
        signFlag_p_reg <= '{default :1'b0};
      end
      else begin
        if (enb) begin
          signFlag_p_reg[0] <= isSignsDiffer;
          signFlag_p_reg[32'sd106:32'sd1] <= signFlag_p_reg[32'sd105:32'sd0];
        end
      end
    end

  assign signFlag_p_1 = signFlag_p_reg[106];
  assign switch_compare_1 = signFlag_p_1 > 1'b0;

  assign switch_compare_1_1 = d_MSB > 1'b0;

  assign preCorrectionIn2_sig_dtc_1 = {divisor_in_reg[63], divisor_in_reg};
  assign preCorrectionIn2_sig_dtc_dtc = {{41{preCorrectionIn2_sig_dtc_1[64]}}, preCorrectionIn2_sig_dtc_1};

  assign d_neg_1 = {preCorrectionIn2_sig_dtc_1[64], preCorrectionIn2_sig_dtc_1};
  assign d_neg_in0 =  - (d_neg_1);
  assign d_neg_2 = d_neg_in0[64:0];
  assign d_neg_dtc = {{41{d_neg_2[64]}}, d_neg_2};

  assign corrected_d = (switch_compare_1_1 == 1'b0 ? preCorrectionIn2_sig_dtc_dtc :
              d_neg_dtc);
  always_ff @(posedge clk)
    begin : corrected_d_p_process
      if (reset == 1'b1) begin
        corrected_d_p_1 <= 106'sh000000000000000000000000000;
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
        d1_p <= 106'sh000000000000000000000000000;
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
        d2_p <= 106'sh000000000000000000000000000;
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
        d3_p <= 106'sh000000000000000000000000000;
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
        d4_p <= 106'sh000000000000000000000000000;
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
        d5_p <= 106'sh000000000000000000000000000;
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
        d6_p <= 106'sh000000000000000000000000000;
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
        d7_p <= 106'sh000000000000000000000000000;
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
        d8_p <= 106'sh000000000000000000000000000;
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
        d9_p <= 106'sh000000000000000000000000000;
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
        d10_p <= 106'sh000000000000000000000000000;
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
        d11_p <= 106'sh000000000000000000000000000;
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
        d12_p <= 106'sh000000000000000000000000000;
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
        d13_p <= 106'sh000000000000000000000000000;
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
        d14_p <= 106'sh000000000000000000000000000;
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
        d15_p <= 106'sh000000000000000000000000000;
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
        d16_p <= 106'sh000000000000000000000000000;
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
        d17_p <= 106'sh000000000000000000000000000;
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
        d18_p <= 106'sh000000000000000000000000000;
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
        d19_p <= 106'sh000000000000000000000000000;
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
        d20_p <= 106'sh000000000000000000000000000;
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
        d21_p <= 106'sh000000000000000000000000000;
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
        d22_p <= 106'sh000000000000000000000000000;
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
        d23_p <= 106'sh000000000000000000000000000;
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
        d24_p <= 106'sh000000000000000000000000000;
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
        d25_p <= 106'sh000000000000000000000000000;
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
        d26_p <= 106'sh000000000000000000000000000;
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
        d27_p <= 106'sh000000000000000000000000000;
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
        d28_p <= 106'sh000000000000000000000000000;
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
        d29_p <= 106'sh000000000000000000000000000;
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
        d30_p <= 106'sh000000000000000000000000000;
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
        d31_p <= 106'sh000000000000000000000000000;
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
        d32_p <= 106'sh000000000000000000000000000;
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
        d33_p <= 106'sh000000000000000000000000000;
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
        d34_p <= 106'sh000000000000000000000000000;
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
        d35_p <= 106'sh000000000000000000000000000;
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
        d36_p <= 106'sh000000000000000000000000000;
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
        d37_p <= 106'sh000000000000000000000000000;
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
        d38_p <= 106'sh000000000000000000000000000;
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
        d39_p <= 106'sh000000000000000000000000000;
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
        d40_p <= 106'sh000000000000000000000000000;
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
        d41_p <= 106'sh000000000000000000000000000;
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
        d42_p <= 106'sh000000000000000000000000000;
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
        d43_p <= 106'sh000000000000000000000000000;
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
        d44_p <= 106'sh000000000000000000000000000;
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
        d45_p <= 106'sh000000000000000000000000000;
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
        d46_p <= 106'sh000000000000000000000000000;
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
        d47_p <= 106'sh000000000000000000000000000;
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
        d48_p <= 106'sh000000000000000000000000000;
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
        d49_p <= 106'sh000000000000000000000000000;
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
        d50_p <= 106'sh000000000000000000000000000;
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
        d51_p <= 106'sh000000000000000000000000000;
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
        d52_p <= 106'sh000000000000000000000000000;
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
        d53_p <= 106'sh000000000000000000000000000;
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
        d54_p <= 106'sh000000000000000000000000000;
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
        d55_p <= 106'sh000000000000000000000000000;
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
        d56_p <= 106'sh000000000000000000000000000;
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
        d57_p <= 106'sh000000000000000000000000000;
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
        d58_p <= 106'sh000000000000000000000000000;
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
        d59_p <= 106'sh000000000000000000000000000;
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
        d60_p <= 106'sh000000000000000000000000000;
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
        d61_p <= 106'sh000000000000000000000000000;
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
        d62_p <= 106'sh000000000000000000000000000;
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
        d63_p <= 106'sh000000000000000000000000000;
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
        d64_p <= 106'sh000000000000000000000000000;
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
        d65_p <= 106'sh000000000000000000000000000;
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
        d66_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d66_p <= d65_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_66_process
      if (reset == 1'b1) begin
        d67_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d67_p <= d66_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_67_process
      if (reset == 1'b1) begin
        d68_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d68_p <= d67_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_68_process
      if (reset == 1'b1) begin
        d69_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d69_p <= d68_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_69_process
      if (reset == 1'b1) begin
        d70_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d70_p <= d69_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_70_process
      if (reset == 1'b1) begin
        d71_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d71_p <= d70_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_71_process
      if (reset == 1'b1) begin
        d72_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d72_p <= d71_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_72_process
      if (reset == 1'b1) begin
        d73_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d73_p <= d72_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_73_process
      if (reset == 1'b1) begin
        d74_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d74_p <= d73_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_74_process
      if (reset == 1'b1) begin
        d75_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d75_p <= d74_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_75_process
      if (reset == 1'b1) begin
        d76_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d76_p <= d75_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_76_process
      if (reset == 1'b1) begin
        d77_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d77_p <= d76_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_77_process
      if (reset == 1'b1) begin
        d78_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d78_p <= d77_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_78_process
      if (reset == 1'b1) begin
        d79_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d79_p <= d78_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_79_process
      if (reset == 1'b1) begin
        d80_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d80_p <= d79_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_80_process
      if (reset == 1'b1) begin
        d81_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d81_p <= d80_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_81_process
      if (reset == 1'b1) begin
        d82_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d82_p <= d81_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_82_process
      if (reset == 1'b1) begin
        d83_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d83_p <= d82_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_83_process
      if (reset == 1'b1) begin
        d84_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d84_p <= d83_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_84_process
      if (reset == 1'b1) begin
        d85_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d85_p <= d84_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_85_process
      if (reset == 1'b1) begin
        d86_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d86_p <= d85_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_86_process
      if (reset == 1'b1) begin
        d87_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d87_p <= d86_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_87_process
      if (reset == 1'b1) begin
        d88_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d88_p <= d87_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_88_process
      if (reset == 1'b1) begin
        d89_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d89_p <= d88_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_89_process
      if (reset == 1'b1) begin
        d90_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d90_p <= d89_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_90_process
      if (reset == 1'b1) begin
        d91_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d91_p <= d90_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_91_process
      if (reset == 1'b1) begin
        d92_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d92_p <= d91_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_92_process
      if (reset == 1'b1) begin
        d93_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d93_p <= d92_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_93_process
      if (reset == 1'b1) begin
        d94_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d94_p <= d93_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_94_process
      if (reset == 1'b1) begin
        d95_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d95_p <= d94_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_95_process
      if (reset == 1'b1) begin
        d96_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d96_p <= d95_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_96_process
      if (reset == 1'b1) begin
        d97_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d97_p <= d96_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_97_process
      if (reset == 1'b1) begin
        d98_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d98_p <= d97_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_98_process
      if (reset == 1'b1) begin
        d99_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d99_p <= d98_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_99_process
      if (reset == 1'b1) begin
        d100_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d100_p <= d99_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_100_process
      if (reset == 1'b1) begin
        d101_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d101_p <= d100_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_101_process
      if (reset == 1'b1) begin
        d102_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d102_p <= d101_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_102_process
      if (reset == 1'b1) begin
        d103_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d103_p <= d102_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_103_process
      if (reset == 1'b1) begin
        d104_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d104_p <= d103_p;
        end
      end
    end
  always_ff @(posedge clk)
    begin : d_reg_104_process
      if (reset == 1'b1) begin
        d105_p <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          d105_p <= d104_p;
        end
      end
    end
  assign switch_compare_1_2 = d105_p != 106'sh000000000000000000000000000;

  assign switch_compare_1_3 = z_MSB > 1'b0;

  assign preCorrectionIn1_sig_dtc_1 = {dividend_inshift_reg[103], dividend_inshift_reg};
  assign preCorrectionIn1_sig_dtc_dtc = {{105{preCorrectionIn1_sig_dtc_1[104]}}, preCorrectionIn1_sig_dtc_1};

  assign z_neg_1 = {preCorrectionIn1_sig_dtc_1[104], preCorrectionIn1_sig_dtc_1};
  assign z_neg_in0 =  - (z_neg_1);
  assign z_neg_2 = z_neg_in0[104:0];
  assign z_neg_dtc = {{105{z_neg_2[104]}}, z_neg_2};

  assign corrected_z = (switch_compare_1_3 == 1'b0 ? preCorrectionIn1_sig_dtc_dtc :
              z_neg_dtc);
  always_ff @(posedge clk)
    begin : corrected_z_p_process
      if (reset == 1'b1) begin
        corrected_z_p_1 <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          corrected_z_p_1 <= corrected_z;
        end
      end
    end
  assign rMSBits = corrected_z_p_1[209:104];
  assign x = rMSBits;
  assign d_neg_4 = {corrected_d_p_1[105], corrected_d_p_1};
  assign d_neg_in0_1 =  - (d_neg_4);
  assign d_neg_5 = d_neg_in0_1[105:0];
  assign temp = x + d_neg_5;
  assign rMSBNextBits = temp[104:0];
  assign rLSBits = corrected_z_p_1[103:0];
  assign tempSignBit = temp[104];
  assign qBit =  ~ tempSignBit;
  assign rNextTemp = {rMSBNextBits, rLSBits, qBit};
  assign r1 = rNextTemp;
  always_ff @(posedge clk)
    begin : r_reg_process
      if (reset == 1'b1) begin
        r1_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r1_p <= r1;
        end
      end
    end
  assign rMSBits_1 = r1_p[209:104];
  assign x_1 = rMSBits_1;
  assign rMSBit = r1_p[209];
  assign rMSBitneg =  ~ rMSBit;
  assign switch_compare_1_4 = rMSBitneg > 1'b0;

  assign d_neg_7 = {d1_p[105], d1_p};
  assign d_neg_in0_2 =  - (d_neg_7);
  assign d_neg_8 = d_neg_in0_2[105:0];
  assign y_1 = (switch_compare_1_4 == 1'b0 ? d1_p :
              d_neg_8);
  assign temp_3 = x_1 + y_1;
  assign rMSBNextBits_1 = temp_3[104:0];
  assign rLSBits_1 = r1_p[103:0];
  assign tempSignBit_1 = temp_3[104];
  assign qBit_1 =  ~ tempSignBit_1;
  assign rNextTemp_1 = {rMSBNextBits_1, rLSBits_1, qBit_1};
  assign r2 = rNextTemp_1;
  always_ff @(posedge clk)
    begin : r_reg_1_process
      if (reset == 1'b1) begin
        r2_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r2_p <= r2;
        end
      end
    end
  assign rMSBits_2 = r2_p[209:104];
  assign x_2 = rMSBits_2;
  assign rMSBit_1 = r2_p[209];
  assign rMSBitneg_1 =  ~ rMSBit_1;
  assign switch_compare_1_5 = rMSBitneg_1 > 1'b0;

  assign d_neg_10 = {d2_p[105], d2_p};
  assign d_neg_in0_3 =  - (d_neg_10);
  assign d_neg_11 = d_neg_in0_3[105:0];
  assign y_3 = (switch_compare_1_5 == 1'b0 ? d2_p :
              d_neg_11);
  assign temp_4 = x_2 + y_3;
  assign rMSBNextBits_2 = temp_4[104:0];
  assign rLSBits_2 = r2_p[103:0];
  assign tempSignBit_2 = temp_4[104];
  assign qBit_2 =  ~ tempSignBit_2;
  assign rNextTemp_2 = {rMSBNextBits_2, rLSBits_2, qBit_2};
  assign r3 = rNextTemp_2;
  always_ff @(posedge clk)
    begin : r_reg_2_process
      if (reset == 1'b1) begin
        r3_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r3_p <= r3;
        end
      end
    end
  assign rMSBits_3 = r3_p[209:104];
  assign x_3 = rMSBits_3;
  assign rMSBit_2 = r3_p[209];
  assign rMSBitneg_2 =  ~ rMSBit_2;
  assign switch_compare_1_6 = rMSBitneg_2 > 1'b0;

  assign d_neg_13 = {d3_p[105], d3_p};
  assign d_neg_in0_4 =  - (d_neg_13);
  assign d_neg_14 = d_neg_in0_4[105:0];
  assign y_5 = (switch_compare_1_6 == 1'b0 ? d3_p :
              d_neg_14);
  assign temp_5 = x_3 + y_5;
  assign rMSBNextBits_3 = temp_5[104:0];
  assign rLSBits_3 = r3_p[103:0];
  assign tempSignBit_3 = temp_5[104];
  assign qBit_3 =  ~ tempSignBit_3;
  assign rNextTemp_3 = {rMSBNextBits_3, rLSBits_3, qBit_3};
  assign r4 = rNextTemp_3;
  always_ff @(posedge clk)
    begin : r_reg_3_process
      if (reset == 1'b1) begin
        r4_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r4_p <= r4;
        end
      end
    end
  assign rMSBits_4 = r4_p[209:104];
  assign x_4 = rMSBits_4;
  assign rMSBit_3 = r4_p[209];
  assign rMSBitneg_3 =  ~ rMSBit_3;
  assign switch_compare_1_7 = rMSBitneg_3 > 1'b0;

  assign d_neg_16 = {d4_p[105], d4_p};
  assign d_neg_in0_5 =  - (d_neg_16);
  assign d_neg_17 = d_neg_in0_5[105:0];
  assign y_7 = (switch_compare_1_7 == 1'b0 ? d4_p :
              d_neg_17);
  assign temp_6 = x_4 + y_7;
  assign rMSBNextBits_4 = temp_6[104:0];
  assign rLSBits_4 = r4_p[103:0];
  assign tempSignBit_4 = temp_6[104];
  assign qBit_4 =  ~ tempSignBit_4;
  assign rNextTemp_4 = {rMSBNextBits_4, rLSBits_4, qBit_4};
  assign r5 = rNextTemp_4;
  always_ff @(posedge clk)
    begin : r_reg_4_process
      if (reset == 1'b1) begin
        r5_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r5_p <= r5;
        end
      end
    end
  assign rMSBits_5 = r5_p[209:104];
  assign x_5 = rMSBits_5;
  assign rMSBit_4 = r5_p[209];
  assign rMSBitneg_4 =  ~ rMSBit_4;
  assign switch_compare_1_8 = rMSBitneg_4 > 1'b0;

  assign d_neg_19 = {d5_p[105], d5_p};
  assign d_neg_in0_6 =  - (d_neg_19);
  assign d_neg_20 = d_neg_in0_6[105:0];
  assign y_9 = (switch_compare_1_8 == 1'b0 ? d5_p :
              d_neg_20);
  assign temp_7 = x_5 + y_9;
  assign rMSBNextBits_5 = temp_7[104:0];
  assign rLSBits_5 = r5_p[103:0];
  assign tempSignBit_5 = temp_7[104];
  assign qBit_5 =  ~ tempSignBit_5;
  assign rNextTemp_5 = {rMSBNextBits_5, rLSBits_5, qBit_5};
  assign r6 = rNextTemp_5;
  always_ff @(posedge clk)
    begin : r_reg_5_process
      if (reset == 1'b1) begin
        r6_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r6_p <= r6;
        end
      end
    end
  assign rMSBits_6 = r6_p[209:104];
  assign x_6 = rMSBits_6;
  assign rMSBit_5 = r6_p[209];
  assign rMSBitneg_5 =  ~ rMSBit_5;
  assign switch_compare_1_9 = rMSBitneg_5 > 1'b0;

  assign d_neg_22 = {d6_p[105], d6_p};
  assign d_neg_in0_7 =  - (d_neg_22);
  assign d_neg_23 = d_neg_in0_7[105:0];
  assign y_11 = (switch_compare_1_9 == 1'b0 ? d6_p :
              d_neg_23);
  assign temp_8 = x_6 + y_11;
  assign rMSBNextBits_6 = temp_8[104:0];
  assign rLSBits_6 = r6_p[103:0];
  assign tempSignBit_6 = temp_8[104];
  assign qBit_6 =  ~ tempSignBit_6;
  assign rNextTemp_6 = {rMSBNextBits_6, rLSBits_6, qBit_6};
  assign r7 = rNextTemp_6;
  always_ff @(posedge clk)
    begin : r_reg_6_process
      if (reset == 1'b1) begin
        r7_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r7_p <= r7;
        end
      end
    end
  assign rMSBits_7 = r7_p[209:104];
  assign x_7 = rMSBits_7;
  assign rMSBit_6 = r7_p[209];
  assign rMSBitneg_6 =  ~ rMSBit_6;
  assign switch_compare_1_10 = rMSBitneg_6 > 1'b0;

  assign d_neg_25 = {d7_p[105], d7_p};
  assign d_neg_in0_8 =  - (d_neg_25);
  assign d_neg_26 = d_neg_in0_8[105:0];
  assign y_13 = (switch_compare_1_10 == 1'b0 ? d7_p :
              d_neg_26);
  assign temp_9 = x_7 + y_13;
  assign rMSBNextBits_7 = temp_9[104:0];
  assign rLSBits_7 = r7_p[103:0];
  assign tempSignBit_7 = temp_9[104];
  assign qBit_7 =  ~ tempSignBit_7;
  assign rNextTemp_7 = {rMSBNextBits_7, rLSBits_7, qBit_7};
  assign r8 = rNextTemp_7;
  always_ff @(posedge clk)
    begin : r_reg_7_process
      if (reset == 1'b1) begin
        r8_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r8_p <= r8;
        end
      end
    end
  assign rMSBits_8 = r8_p[209:104];
  assign x_8 = rMSBits_8;
  assign rMSBit_7 = r8_p[209];
  assign rMSBitneg_7 =  ~ rMSBit_7;
  assign switch_compare_1_11 = rMSBitneg_7 > 1'b0;

  assign d_neg_28 = {d8_p[105], d8_p};
  assign d_neg_in0_9 =  - (d_neg_28);
  assign d_neg_29 = d_neg_in0_9[105:0];
  assign y_15 = (switch_compare_1_11 == 1'b0 ? d8_p :
              d_neg_29);
  assign temp_10 = x_8 + y_15;
  assign rMSBNextBits_8 = temp_10[104:0];
  assign rLSBits_8 = r8_p[103:0];
  assign tempSignBit_8 = temp_10[104];
  assign qBit_8 =  ~ tempSignBit_8;
  assign rNextTemp_8 = {rMSBNextBits_8, rLSBits_8, qBit_8};
  assign r9 = rNextTemp_8;
  always_ff @(posedge clk)
    begin : r_reg_8_process
      if (reset == 1'b1) begin
        r9_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r9_p <= r9;
        end
      end
    end
  assign rMSBits_9 = r9_p[209:104];
  assign x_9 = rMSBits_9;
  assign rMSBit_8 = r9_p[209];
  assign rMSBitneg_8 =  ~ rMSBit_8;
  assign switch_compare_1_12 = rMSBitneg_8 > 1'b0;

  assign d_neg_31 = {d9_p[105], d9_p};
  assign d_neg_in0_10 =  - (d_neg_31);
  assign d_neg_32 = d_neg_in0_10[105:0];
  assign y_17 = (switch_compare_1_12 == 1'b0 ? d9_p :
              d_neg_32);
  assign temp_11 = x_9 + y_17;
  assign rMSBNextBits_9 = temp_11[104:0];
  assign rLSBits_9 = r9_p[103:0];
  assign tempSignBit_9 = temp_11[104];
  assign qBit_9 =  ~ tempSignBit_9;
  assign rNextTemp_9 = {rMSBNextBits_9, rLSBits_9, qBit_9};
  assign r10 = rNextTemp_9;
  always_ff @(posedge clk)
    begin : r_reg_9_process
      if (reset == 1'b1) begin
        r10_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r10_p <= r10;
        end
      end
    end
  assign rMSBits_10 = r10_p[209:104];
  assign x_10 = rMSBits_10;
  assign rMSBit_9 = r10_p[209];
  assign rMSBitneg_9 =  ~ rMSBit_9;
  assign switch_compare_1_13 = rMSBitneg_9 > 1'b0;

  assign d_neg_34 = {d10_p[105], d10_p};
  assign d_neg_in0_11 =  - (d_neg_34);
  assign d_neg_35 = d_neg_in0_11[105:0];
  assign y_19 = (switch_compare_1_13 == 1'b0 ? d10_p :
              d_neg_35);
  assign temp_12 = x_10 + y_19;
  assign rMSBNextBits_10 = temp_12[104:0];
  assign rLSBits_10 = r10_p[103:0];
  assign tempSignBit_10 = temp_12[104];
  assign qBit_10 =  ~ tempSignBit_10;
  assign rNextTemp_10 = {rMSBNextBits_10, rLSBits_10, qBit_10};
  assign r11 = rNextTemp_10;
  always_ff @(posedge clk)
    begin : r_reg_10_process
      if (reset == 1'b1) begin
        r11_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r11_p <= r11;
        end
      end
    end
  assign rMSBits_11 = r11_p[209:104];
  assign x_11 = rMSBits_11;
  assign rMSBit_10 = r11_p[209];
  assign rMSBitneg_10 =  ~ rMSBit_10;
  assign switch_compare_1_14 = rMSBitneg_10 > 1'b0;

  assign d_neg_37 = {d11_p[105], d11_p};
  assign d_neg_in0_12 =  - (d_neg_37);
  assign d_neg_38 = d_neg_in0_12[105:0];
  assign y_21 = (switch_compare_1_14 == 1'b0 ? d11_p :
              d_neg_38);
  assign temp_13 = x_11 + y_21;
  assign rMSBNextBits_11 = temp_13[104:0];
  assign rLSBits_11 = r11_p[103:0];
  assign tempSignBit_11 = temp_13[104];
  assign qBit_11 =  ~ tempSignBit_11;
  assign rNextTemp_11 = {rMSBNextBits_11, rLSBits_11, qBit_11};
  assign r12 = rNextTemp_11;
  always_ff @(posedge clk)
    begin : r_reg_11_process
      if (reset == 1'b1) begin
        r12_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r12_p <= r12;
        end
      end
    end
  assign rMSBits_12 = r12_p[209:104];
  assign x_12 = rMSBits_12;
  assign rMSBit_11 = r12_p[209];
  assign rMSBitneg_11 =  ~ rMSBit_11;
  assign switch_compare_1_15 = rMSBitneg_11 > 1'b0;

  assign d_neg_40 = {d12_p[105], d12_p};
  assign d_neg_in0_13 =  - (d_neg_40);
  assign d_neg_41 = d_neg_in0_13[105:0];
  assign y_23 = (switch_compare_1_15 == 1'b0 ? d12_p :
              d_neg_41);
  assign temp_14 = x_12 + y_23;
  assign rMSBNextBits_12 = temp_14[104:0];
  assign rLSBits_12 = r12_p[103:0];
  assign tempSignBit_12 = temp_14[104];
  assign qBit_12 =  ~ tempSignBit_12;
  assign rNextTemp_12 = {rMSBNextBits_12, rLSBits_12, qBit_12};
  assign r13 = rNextTemp_12;
  always_ff @(posedge clk)
    begin : r_reg_12_process
      if (reset == 1'b1) begin
        r13_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r13_p <= r13;
        end
      end
    end
  assign rMSBits_13 = r13_p[209:104];
  assign x_13 = rMSBits_13;
  assign rMSBit_12 = r13_p[209];
  assign rMSBitneg_12 =  ~ rMSBit_12;
  assign switch_compare_1_16 = rMSBitneg_12 > 1'b0;

  assign d_neg_43 = {d13_p[105], d13_p};
  assign d_neg_in0_14 =  - (d_neg_43);
  assign d_neg_44 = d_neg_in0_14[105:0];
  assign y_25 = (switch_compare_1_16 == 1'b0 ? d13_p :
              d_neg_44);
  assign temp_15 = x_13 + y_25;
  assign rMSBNextBits_13 = temp_15[104:0];
  assign rLSBits_13 = r13_p[103:0];
  assign tempSignBit_13 = temp_15[104];
  assign qBit_13 =  ~ tempSignBit_13;
  assign rNextTemp_13 = {rMSBNextBits_13, rLSBits_13, qBit_13};
  assign r14 = rNextTemp_13;
  always_ff @(posedge clk)
    begin : r_reg_13_process
      if (reset == 1'b1) begin
        r14_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r14_p <= r14;
        end
      end
    end
  assign rMSBits_14 = r14_p[209:104];
  assign x_14 = rMSBits_14;
  assign rMSBit_13 = r14_p[209];
  assign rMSBitneg_13 =  ~ rMSBit_13;
  assign switch_compare_1_17 = rMSBitneg_13 > 1'b0;

  assign d_neg_46 = {d14_p[105], d14_p};
  assign d_neg_in0_15 =  - (d_neg_46);
  assign d_neg_47 = d_neg_in0_15[105:0];
  assign y_27 = (switch_compare_1_17 == 1'b0 ? d14_p :
              d_neg_47);
  assign temp_16 = x_14 + y_27;
  assign rMSBNextBits_14 = temp_16[104:0];
  assign rLSBits_14 = r14_p[103:0];
  assign tempSignBit_14 = temp_16[104];
  assign qBit_14 =  ~ tempSignBit_14;
  assign rNextTemp_14 = {rMSBNextBits_14, rLSBits_14, qBit_14};
  assign r15 = rNextTemp_14;
  always_ff @(posedge clk)
    begin : r_reg_14_process
      if (reset == 1'b1) begin
        r15_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r15_p <= r15;
        end
      end
    end
  assign rMSBits_15 = r15_p[209:104];
  assign x_15 = rMSBits_15;
  assign rMSBit_14 = r15_p[209];
  assign rMSBitneg_14 =  ~ rMSBit_14;
  assign switch_compare_1_18 = rMSBitneg_14 > 1'b0;

  assign d_neg_49 = {d15_p[105], d15_p};
  assign d_neg_in0_16 =  - (d_neg_49);
  assign d_neg_50 = d_neg_in0_16[105:0];
  assign y_29 = (switch_compare_1_18 == 1'b0 ? d15_p :
              d_neg_50);
  assign temp_17 = x_15 + y_29;
  assign rMSBNextBits_15 = temp_17[104:0];
  assign rLSBits_15 = r15_p[103:0];
  assign tempSignBit_15 = temp_17[104];
  assign qBit_15 =  ~ tempSignBit_15;
  assign rNextTemp_15 = {rMSBNextBits_15, rLSBits_15, qBit_15};
  assign r16 = rNextTemp_15;
  always_ff @(posedge clk)
    begin : r_reg_15_process
      if (reset == 1'b1) begin
        r16_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r16_p <= r16;
        end
      end
    end
  assign rMSBits_16 = r16_p[209:104];
  assign x_16 = rMSBits_16;
  assign rMSBit_15 = r16_p[209];
  assign rMSBitneg_15 =  ~ rMSBit_15;
  assign switch_compare_1_19 = rMSBitneg_15 > 1'b0;

  assign d_neg_52 = {d16_p[105], d16_p};
  assign d_neg_in0_17 =  - (d_neg_52);
  assign d_neg_53 = d_neg_in0_17[105:0];
  assign y_31 = (switch_compare_1_19 == 1'b0 ? d16_p :
              d_neg_53);
  assign temp_18 = x_16 + y_31;
  assign rMSBNextBits_16 = temp_18[104:0];
  assign rLSBits_16 = r16_p[103:0];
  assign tempSignBit_16 = temp_18[104];
  assign qBit_16 =  ~ tempSignBit_16;
  assign rNextTemp_16 = {rMSBNextBits_16, rLSBits_16, qBit_16};
  assign r17 = rNextTemp_16;
  always_ff @(posedge clk)
    begin : r_reg_16_process
      if (reset == 1'b1) begin
        r17_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r17_p <= r17;
        end
      end
    end
  assign rMSBits_17 = r17_p[209:104];
  assign x_17 = rMSBits_17;
  assign rMSBit_16 = r17_p[209];
  assign rMSBitneg_16 =  ~ rMSBit_16;
  assign switch_compare_1_20 = rMSBitneg_16 > 1'b0;

  assign d_neg_55 = {d17_p[105], d17_p};
  assign d_neg_in0_18 =  - (d_neg_55);
  assign d_neg_56 = d_neg_in0_18[105:0];
  assign y_33 = (switch_compare_1_20 == 1'b0 ? d17_p :
              d_neg_56);
  assign temp_19 = x_17 + y_33;
  assign rMSBNextBits_17 = temp_19[104:0];
  assign rLSBits_17 = r17_p[103:0];
  assign tempSignBit_17 = temp_19[104];
  assign qBit_17 =  ~ tempSignBit_17;
  assign rNextTemp_17 = {rMSBNextBits_17, rLSBits_17, qBit_17};
  assign r18 = rNextTemp_17;
  always_ff @(posedge clk)
    begin : r_reg_17_process
      if (reset == 1'b1) begin
        r18_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r18_p <= r18;
        end
      end
    end
  assign rMSBits_18 = r18_p[209:104];
  assign x_18 = rMSBits_18;
  assign rMSBit_17 = r18_p[209];
  assign rMSBitneg_17 =  ~ rMSBit_17;
  assign switch_compare_1_21 = rMSBitneg_17 > 1'b0;

  assign d_neg_58 = {d18_p[105], d18_p};
  assign d_neg_in0_19 =  - (d_neg_58);
  assign d_neg_59 = d_neg_in0_19[105:0];
  assign y_35 = (switch_compare_1_21 == 1'b0 ? d18_p :
              d_neg_59);
  assign temp_20 = x_18 + y_35;
  assign rMSBNextBits_18 = temp_20[104:0];
  assign rLSBits_18 = r18_p[103:0];
  assign tempSignBit_18 = temp_20[104];
  assign qBit_18 =  ~ tempSignBit_18;
  assign rNextTemp_18 = {rMSBNextBits_18, rLSBits_18, qBit_18};
  assign r19 = rNextTemp_18;
  always_ff @(posedge clk)
    begin : r_reg_18_process
      if (reset == 1'b1) begin
        r19_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r19_p <= r19;
        end
      end
    end
  assign rMSBits_19 = r19_p[209:104];
  assign x_19 = rMSBits_19;
  assign rMSBit_18 = r19_p[209];
  assign rMSBitneg_18 =  ~ rMSBit_18;
  assign switch_compare_1_22 = rMSBitneg_18 > 1'b0;

  assign d_neg_61 = {d19_p[105], d19_p};
  assign d_neg_in0_20 =  - (d_neg_61);
  assign d_neg_62 = d_neg_in0_20[105:0];
  assign y_37 = (switch_compare_1_22 == 1'b0 ? d19_p :
              d_neg_62);
  assign temp_21 = x_19 + y_37;
  assign rMSBNextBits_19 = temp_21[104:0];
  assign rLSBits_19 = r19_p[103:0];
  assign tempSignBit_19 = temp_21[104];
  assign qBit_19 =  ~ tempSignBit_19;
  assign rNextTemp_19 = {rMSBNextBits_19, rLSBits_19, qBit_19};
  assign r20 = rNextTemp_19;
  always_ff @(posedge clk)
    begin : r_reg_19_process
      if (reset == 1'b1) begin
        r20_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r20_p <= r20;
        end
      end
    end
  assign rMSBits_20 = r20_p[209:104];
  assign x_20 = rMSBits_20;
  assign rMSBit_19 = r20_p[209];
  assign rMSBitneg_19 =  ~ rMSBit_19;
  assign switch_compare_1_23 = rMSBitneg_19 > 1'b0;

  assign d_neg_64 = {d20_p[105], d20_p};
  assign d_neg_in0_21 =  - (d_neg_64);
  assign d_neg_65 = d_neg_in0_21[105:0];
  assign y_39 = (switch_compare_1_23 == 1'b0 ? d20_p :
              d_neg_65);
  assign temp_22 = x_20 + y_39;
  assign rMSBNextBits_20 = temp_22[104:0];
  assign rLSBits_20 = r20_p[103:0];
  assign tempSignBit_20 = temp_22[104];
  assign qBit_20 =  ~ tempSignBit_20;
  assign rNextTemp_20 = {rMSBNextBits_20, rLSBits_20, qBit_20};
  assign r21 = rNextTemp_20;
  always_ff @(posedge clk)
    begin : r_reg_20_process
      if (reset == 1'b1) begin
        r21_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r21_p <= r21;
        end
      end
    end
  assign rMSBits_21 = r21_p[209:104];
  assign x_21 = rMSBits_21;
  assign rMSBit_20 = r21_p[209];
  assign rMSBitneg_20 =  ~ rMSBit_20;
  assign switch_compare_1_24 = rMSBitneg_20 > 1'b0;

  assign d_neg_67 = {d21_p[105], d21_p};
  assign d_neg_in0_22 =  - (d_neg_67);
  assign d_neg_68 = d_neg_in0_22[105:0];
  assign y_41 = (switch_compare_1_24 == 1'b0 ? d21_p :
              d_neg_68);
  assign temp_23 = x_21 + y_41;
  assign rMSBNextBits_21 = temp_23[104:0];
  assign rLSBits_21 = r21_p[103:0];
  assign tempSignBit_21 = temp_23[104];
  assign qBit_21 =  ~ tempSignBit_21;
  assign rNextTemp_21 = {rMSBNextBits_21, rLSBits_21, qBit_21};
  assign r22 = rNextTemp_21;
  always_ff @(posedge clk)
    begin : r_reg_21_process
      if (reset == 1'b1) begin
        r22_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r22_p <= r22;
        end
      end
    end
  assign rMSBits_22 = r22_p[209:104];
  assign x_22 = rMSBits_22;
  assign rMSBit_21 = r22_p[209];
  assign rMSBitneg_21 =  ~ rMSBit_21;
  assign switch_compare_1_25 = rMSBitneg_21 > 1'b0;

  assign d_neg_70 = {d22_p[105], d22_p};
  assign d_neg_in0_23 =  - (d_neg_70);
  assign d_neg_71 = d_neg_in0_23[105:0];
  assign y_43 = (switch_compare_1_25 == 1'b0 ? d22_p :
              d_neg_71);
  assign temp_24 = x_22 + y_43;
  assign rMSBNextBits_22 = temp_24[104:0];
  assign rLSBits_22 = r22_p[103:0];
  assign tempSignBit_22 = temp_24[104];
  assign qBit_22 =  ~ tempSignBit_22;
  assign rNextTemp_22 = {rMSBNextBits_22, rLSBits_22, qBit_22};
  assign r23 = rNextTemp_22;
  always_ff @(posedge clk)
    begin : r_reg_22_process
      if (reset == 1'b1) begin
        r23_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r23_p <= r23;
        end
      end
    end
  assign rMSBits_23 = r23_p[209:104];
  assign x_23 = rMSBits_23;
  assign rMSBit_22 = r23_p[209];
  assign rMSBitneg_22 =  ~ rMSBit_22;
  assign switch_compare_1_26 = rMSBitneg_22 > 1'b0;

  assign d_neg_73 = {d23_p[105], d23_p};
  assign d_neg_in0_24 =  - (d_neg_73);
  assign d_neg_74 = d_neg_in0_24[105:0];
  assign y_45 = (switch_compare_1_26 == 1'b0 ? d23_p :
              d_neg_74);
  assign temp_25 = x_23 + y_45;
  assign rMSBNextBits_23 = temp_25[104:0];
  assign rLSBits_23 = r23_p[103:0];
  assign tempSignBit_23 = temp_25[104];
  assign qBit_23 =  ~ tempSignBit_23;
  assign rNextTemp_23 = {rMSBNextBits_23, rLSBits_23, qBit_23};
  assign r24 = rNextTemp_23;
  always_ff @(posedge clk)
    begin : r_reg_23_process
      if (reset == 1'b1) begin
        r24_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r24_p <= r24;
        end
      end
    end
  assign rMSBits_24 = r24_p[209:104];
  assign x_24 = rMSBits_24;
  assign rMSBit_23 = r24_p[209];
  assign rMSBitneg_23 =  ~ rMSBit_23;
  assign switch_compare_1_27 = rMSBitneg_23 > 1'b0;

  assign d_neg_76 = {d24_p[105], d24_p};
  assign d_neg_in0_25 =  - (d_neg_76);
  assign d_neg_77 = d_neg_in0_25[105:0];
  assign y_47 = (switch_compare_1_27 == 1'b0 ? d24_p :
              d_neg_77);
  assign temp_26 = x_24 + y_47;
  assign rMSBNextBits_24 = temp_26[104:0];
  assign rLSBits_24 = r24_p[103:0];
  assign tempSignBit_24 = temp_26[104];
  assign qBit_24 =  ~ tempSignBit_24;
  assign rNextTemp_24 = {rMSBNextBits_24, rLSBits_24, qBit_24};
  assign r25 = rNextTemp_24;
  always_ff @(posedge clk)
    begin : r_reg_24_process
      if (reset == 1'b1) begin
        r25_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r25_p <= r25;
        end
      end
    end
  assign rMSBits_25 = r25_p[209:104];
  assign x_25 = rMSBits_25;
  assign rMSBit_24 = r25_p[209];
  assign rMSBitneg_24 =  ~ rMSBit_24;
  assign switch_compare_1_28 = rMSBitneg_24 > 1'b0;

  assign d_neg_79 = {d25_p[105], d25_p};
  assign d_neg_in0_26 =  - (d_neg_79);
  assign d_neg_80 = d_neg_in0_26[105:0];
  assign y_49 = (switch_compare_1_28 == 1'b0 ? d25_p :
              d_neg_80);
  assign temp_27 = x_25 + y_49;
  assign rMSBNextBits_25 = temp_27[104:0];
  assign rLSBits_25 = r25_p[103:0];
  assign tempSignBit_25 = temp_27[104];
  assign qBit_25 =  ~ tempSignBit_25;
  assign rNextTemp_25 = {rMSBNextBits_25, rLSBits_25, qBit_25};
  assign r26 = rNextTemp_25;
  always_ff @(posedge clk)
    begin : r_reg_25_process
      if (reset == 1'b1) begin
        r26_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r26_p <= r26;
        end
      end
    end
  assign rMSBits_26 = r26_p[209:104];
  assign x_26 = rMSBits_26;
  assign rMSBit_25 = r26_p[209];
  assign rMSBitneg_25 =  ~ rMSBit_25;
  assign switch_compare_1_29 = rMSBitneg_25 > 1'b0;

  assign d_neg_82 = {d26_p[105], d26_p};
  assign d_neg_in0_27 =  - (d_neg_82);
  assign d_neg_83 = d_neg_in0_27[105:0];
  assign y_51 = (switch_compare_1_29 == 1'b0 ? d26_p :
              d_neg_83);
  assign temp_28 = x_26 + y_51;
  assign rMSBNextBits_26 = temp_28[104:0];
  assign rLSBits_26 = r26_p[103:0];
  assign tempSignBit_26 = temp_28[104];
  assign qBit_26 =  ~ tempSignBit_26;
  assign rNextTemp_26 = {rMSBNextBits_26, rLSBits_26, qBit_26};
  assign r27 = rNextTemp_26;
  always_ff @(posedge clk)
    begin : r_reg_26_process
      if (reset == 1'b1) begin
        r27_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r27_p <= r27;
        end
      end
    end
  assign rMSBits_27 = r27_p[209:104];
  assign x_27 = rMSBits_27;
  assign rMSBit_26 = r27_p[209];
  assign rMSBitneg_26 =  ~ rMSBit_26;
  assign switch_compare_1_30 = rMSBitneg_26 > 1'b0;

  assign d_neg_85 = {d27_p[105], d27_p};
  assign d_neg_in0_28 =  - (d_neg_85);
  assign d_neg_86 = d_neg_in0_28[105:0];
  assign y_53 = (switch_compare_1_30 == 1'b0 ? d27_p :
              d_neg_86);
  assign temp_29 = x_27 + y_53;
  assign rMSBNextBits_27 = temp_29[104:0];
  assign rLSBits_27 = r27_p[103:0];
  assign tempSignBit_27 = temp_29[104];
  assign qBit_27 =  ~ tempSignBit_27;
  assign rNextTemp_27 = {rMSBNextBits_27, rLSBits_27, qBit_27};
  assign r28 = rNextTemp_27;
  always_ff @(posedge clk)
    begin : r_reg_27_process
      if (reset == 1'b1) begin
        r28_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r28_p <= r28;
        end
      end
    end
  assign rMSBits_28 = r28_p[209:104];
  assign x_28 = rMSBits_28;
  assign rMSBit_27 = r28_p[209];
  assign rMSBitneg_27 =  ~ rMSBit_27;
  assign switch_compare_1_31 = rMSBitneg_27 > 1'b0;

  assign d_neg_88 = {d28_p[105], d28_p};
  assign d_neg_in0_29 =  - (d_neg_88);
  assign d_neg_89 = d_neg_in0_29[105:0];
  assign y_55 = (switch_compare_1_31 == 1'b0 ? d28_p :
              d_neg_89);
  assign temp_30 = x_28 + y_55;
  assign rMSBNextBits_28 = temp_30[104:0];
  assign rLSBits_28 = r28_p[103:0];
  assign tempSignBit_28 = temp_30[104];
  assign qBit_28 =  ~ tempSignBit_28;
  assign rNextTemp_28 = {rMSBNextBits_28, rLSBits_28, qBit_28};
  assign r29 = rNextTemp_28;
  always_ff @(posedge clk)
    begin : r_reg_28_process
      if (reset == 1'b1) begin
        r29_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r29_p <= r29;
        end
      end
    end
  assign rMSBits_29 = r29_p[209:104];
  assign x_29 = rMSBits_29;
  assign rMSBit_28 = r29_p[209];
  assign rMSBitneg_28 =  ~ rMSBit_28;
  assign switch_compare_1_32 = rMSBitneg_28 > 1'b0;

  assign d_neg_91 = {d29_p[105], d29_p};
  assign d_neg_in0_30 =  - (d_neg_91);
  assign d_neg_92 = d_neg_in0_30[105:0];
  assign y_57 = (switch_compare_1_32 == 1'b0 ? d29_p :
              d_neg_92);
  assign temp_31 = x_29 + y_57;
  assign rMSBNextBits_29 = temp_31[104:0];
  assign rLSBits_29 = r29_p[103:0];
  assign tempSignBit_29 = temp_31[104];
  assign qBit_29 =  ~ tempSignBit_29;
  assign rNextTemp_29 = {rMSBNextBits_29, rLSBits_29, qBit_29};
  assign r30 = rNextTemp_29;
  always_ff @(posedge clk)
    begin : r_reg_29_process
      if (reset == 1'b1) begin
        r30_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r30_p <= r30;
        end
      end
    end
  assign rMSBits_30 = r30_p[209:104];
  assign x_30 = rMSBits_30;
  assign rMSBit_29 = r30_p[209];
  assign rMSBitneg_29 =  ~ rMSBit_29;
  assign switch_compare_1_33 = rMSBitneg_29 > 1'b0;

  assign d_neg_94 = {d30_p[105], d30_p};
  assign d_neg_in0_31 =  - (d_neg_94);
  assign d_neg_95 = d_neg_in0_31[105:0];
  assign y_59 = (switch_compare_1_33 == 1'b0 ? d30_p :
              d_neg_95);
  assign temp_32 = x_30 + y_59;
  assign rMSBNextBits_30 = temp_32[104:0];
  assign rLSBits_30 = r30_p[103:0];
  assign tempSignBit_30 = temp_32[104];
  assign qBit_30 =  ~ tempSignBit_30;
  assign rNextTemp_30 = {rMSBNextBits_30, rLSBits_30, qBit_30};
  assign r31 = rNextTemp_30;
  always_ff @(posedge clk)
    begin : r_reg_30_process
      if (reset == 1'b1) begin
        r31_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r31_p <= r31;
        end
      end
    end
  assign rMSBits_31 = r31_p[209:104];
  assign x_31 = rMSBits_31;
  assign rMSBit_30 = r31_p[209];
  assign rMSBitneg_30 =  ~ rMSBit_30;
  assign switch_compare_1_34 = rMSBitneg_30 > 1'b0;

  assign d_neg_97 = {d31_p[105], d31_p};
  assign d_neg_in0_32 =  - (d_neg_97);
  assign d_neg_98 = d_neg_in0_32[105:0];
  assign y_61 = (switch_compare_1_34 == 1'b0 ? d31_p :
              d_neg_98);
  assign temp_33 = x_31 + y_61;
  assign rMSBNextBits_31 = temp_33[104:0];
  assign rLSBits_31 = r31_p[103:0];
  assign tempSignBit_31 = temp_33[104];
  assign qBit_31 =  ~ tempSignBit_31;
  assign rNextTemp_31 = {rMSBNextBits_31, rLSBits_31, qBit_31};
  assign r32 = rNextTemp_31;
  always_ff @(posedge clk)
    begin : r_reg_31_process
      if (reset == 1'b1) begin
        r32_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r32_p <= r32;
        end
      end
    end
  assign rMSBits_32 = r32_p[209:104];
  assign x_32 = rMSBits_32;
  assign rMSBit_31 = r32_p[209];
  assign rMSBitneg_31 =  ~ rMSBit_31;
  assign switch_compare_1_35 = rMSBitneg_31 > 1'b0;

  assign d_neg_100 = {d32_p[105], d32_p};
  assign d_neg_in0_33 =  - (d_neg_100);
  assign d_neg_101 = d_neg_in0_33[105:0];
  assign y_63 = (switch_compare_1_35 == 1'b0 ? d32_p :
              d_neg_101);
  assign temp_34 = x_32 + y_63;
  assign rMSBNextBits_32 = temp_34[104:0];
  assign rLSBits_32 = r32_p[103:0];
  assign tempSignBit_32 = temp_34[104];
  assign qBit_32 =  ~ tempSignBit_32;
  assign rNextTemp_32 = {rMSBNextBits_32, rLSBits_32, qBit_32};
  assign r33 = rNextTemp_32;
  always_ff @(posedge clk)
    begin : r_reg_32_process
      if (reset == 1'b1) begin
        r33_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r33_p <= r33;
        end
      end
    end
  assign rMSBits_33 = r33_p[209:104];
  assign x_33 = rMSBits_33;
  assign rMSBit_32 = r33_p[209];
  assign rMSBitneg_32 =  ~ rMSBit_32;
  assign switch_compare_1_36 = rMSBitneg_32 > 1'b0;

  assign d_neg_103 = {d33_p[105], d33_p};
  assign d_neg_in0_34 =  - (d_neg_103);
  assign d_neg_104 = d_neg_in0_34[105:0];
  assign y_65 = (switch_compare_1_36 == 1'b0 ? d33_p :
              d_neg_104);
  assign temp_35 = x_33 + y_65;
  assign rMSBNextBits_33 = temp_35[104:0];
  assign rLSBits_33 = r33_p[103:0];
  assign tempSignBit_33 = temp_35[104];
  assign qBit_33 =  ~ tempSignBit_33;
  assign rNextTemp_33 = {rMSBNextBits_33, rLSBits_33, qBit_33};
  assign r34 = rNextTemp_33;
  always_ff @(posedge clk)
    begin : r_reg_33_process
      if (reset == 1'b1) begin
        r34_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r34_p <= r34;
        end
      end
    end
  assign rMSBits_34 = r34_p[209:104];
  assign x_34 = rMSBits_34;
  assign rMSBit_33 = r34_p[209];
  assign rMSBitneg_33 =  ~ rMSBit_33;
  assign switch_compare_1_37 = rMSBitneg_33 > 1'b0;

  assign d_neg_106 = {d34_p[105], d34_p};
  assign d_neg_in0_35 =  - (d_neg_106);
  assign d_neg_107 = d_neg_in0_35[105:0];
  assign y_67 = (switch_compare_1_37 == 1'b0 ? d34_p :
              d_neg_107);
  assign temp_36 = x_34 + y_67;
  assign rMSBNextBits_34 = temp_36[104:0];
  assign rLSBits_34 = r34_p[103:0];
  assign tempSignBit_34 = temp_36[104];
  assign qBit_34 =  ~ tempSignBit_34;
  assign rNextTemp_34 = {rMSBNextBits_34, rLSBits_34, qBit_34};
  assign r35 = rNextTemp_34;
  always_ff @(posedge clk)
    begin : r_reg_34_process
      if (reset == 1'b1) begin
        r35_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r35_p <= r35;
        end
      end
    end
  assign rMSBits_35 = r35_p[209:104];
  assign x_35 = rMSBits_35;
  assign rMSBit_34 = r35_p[209];
  assign rMSBitneg_34 =  ~ rMSBit_34;
  assign switch_compare_1_38 = rMSBitneg_34 > 1'b0;

  assign d_neg_109 = {d35_p[105], d35_p};
  assign d_neg_in0_36 =  - (d_neg_109);
  assign d_neg_110 = d_neg_in0_36[105:0];
  assign y_69 = (switch_compare_1_38 == 1'b0 ? d35_p :
              d_neg_110);
  assign temp_37 = x_35 + y_69;
  assign rMSBNextBits_35 = temp_37[104:0];
  assign rLSBits_35 = r35_p[103:0];
  assign tempSignBit_35 = temp_37[104];
  assign qBit_35 =  ~ tempSignBit_35;
  assign rNextTemp_35 = {rMSBNextBits_35, rLSBits_35, qBit_35};
  assign r36 = rNextTemp_35;
  always_ff @(posedge clk)
    begin : r_reg_35_process
      if (reset == 1'b1) begin
        r36_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r36_p <= r36;
        end
      end
    end
  assign rMSBits_36 = r36_p[209:104];
  assign x_36 = rMSBits_36;
  assign rMSBit_35 = r36_p[209];
  assign rMSBitneg_35 =  ~ rMSBit_35;
  assign switch_compare_1_39 = rMSBitneg_35 > 1'b0;

  assign d_neg_112 = {d36_p[105], d36_p};
  assign d_neg_in0_37 =  - (d_neg_112);
  assign d_neg_113 = d_neg_in0_37[105:0];
  assign y_71 = (switch_compare_1_39 == 1'b0 ? d36_p :
              d_neg_113);
  assign temp_38 = x_36 + y_71;
  assign rMSBNextBits_36 = temp_38[104:0];
  assign rLSBits_36 = r36_p[103:0];
  assign tempSignBit_36 = temp_38[104];
  assign qBit_36 =  ~ tempSignBit_36;
  assign rNextTemp_36 = {rMSBNextBits_36, rLSBits_36, qBit_36};
  assign r37 = rNextTemp_36;
  always_ff @(posedge clk)
    begin : r_reg_36_process
      if (reset == 1'b1) begin
        r37_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r37_p <= r37;
        end
      end
    end
  assign rMSBits_37 = r37_p[209:104];
  assign x_37 = rMSBits_37;
  assign rMSBit_36 = r37_p[209];
  assign rMSBitneg_36 =  ~ rMSBit_36;
  assign switch_compare_1_40 = rMSBitneg_36 > 1'b0;

  assign d_neg_115 = {d37_p[105], d37_p};
  assign d_neg_in0_38 =  - (d_neg_115);
  assign d_neg_116 = d_neg_in0_38[105:0];
  assign y_73 = (switch_compare_1_40 == 1'b0 ? d37_p :
              d_neg_116);
  assign temp_39 = x_37 + y_73;
  assign rMSBNextBits_37 = temp_39[104:0];
  assign rLSBits_37 = r37_p[103:0];
  assign tempSignBit_37 = temp_39[104];
  assign qBit_37 =  ~ tempSignBit_37;
  assign rNextTemp_37 = {rMSBNextBits_37, rLSBits_37, qBit_37};
  assign r38 = rNextTemp_37;
  always_ff @(posedge clk)
    begin : r_reg_37_process
      if (reset == 1'b1) begin
        r38_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r38_p <= r38;
        end
      end
    end
  assign rMSBits_38 = r38_p[209:104];
  assign x_38 = rMSBits_38;
  assign rMSBit_37 = r38_p[209];
  assign rMSBitneg_37 =  ~ rMSBit_37;
  assign switch_compare_1_41 = rMSBitneg_37 > 1'b0;

  assign d_neg_118 = {d38_p[105], d38_p};
  assign d_neg_in0_39 =  - (d_neg_118);
  assign d_neg_119 = d_neg_in0_39[105:0];
  assign y_75 = (switch_compare_1_41 == 1'b0 ? d38_p :
              d_neg_119);
  assign temp_40 = x_38 + y_75;
  assign rMSBNextBits_38 = temp_40[104:0];
  assign rLSBits_38 = r38_p[103:0];
  assign tempSignBit_38 = temp_40[104];
  assign qBit_38 =  ~ tempSignBit_38;
  assign rNextTemp_38 = {rMSBNextBits_38, rLSBits_38, qBit_38};
  assign r39 = rNextTemp_38;
  always_ff @(posedge clk)
    begin : r_reg_38_process
      if (reset == 1'b1) begin
        r39_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r39_p <= r39;
        end
      end
    end
  assign rMSBits_39 = r39_p[209:104];
  assign x_39 = rMSBits_39;
  assign rMSBit_38 = r39_p[209];
  assign rMSBitneg_38 =  ~ rMSBit_38;
  assign switch_compare_1_42 = rMSBitneg_38 > 1'b0;

  assign d_neg_121 = {d39_p[105], d39_p};
  assign d_neg_in0_40 =  - (d_neg_121);
  assign d_neg_122 = d_neg_in0_40[105:0];
  assign y_77 = (switch_compare_1_42 == 1'b0 ? d39_p :
              d_neg_122);
  assign temp_41 = x_39 + y_77;
  assign rMSBNextBits_39 = temp_41[104:0];
  assign rLSBits_39 = r39_p[103:0];
  assign tempSignBit_39 = temp_41[104];
  assign qBit_39 =  ~ tempSignBit_39;
  assign rNextTemp_39 = {rMSBNextBits_39, rLSBits_39, qBit_39};
  assign r40 = rNextTemp_39;
  always_ff @(posedge clk)
    begin : r_reg_39_process
      if (reset == 1'b1) begin
        r40_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r40_p <= r40;
        end
      end
    end
  assign rMSBits_40 = r40_p[209:104];
  assign x_40 = rMSBits_40;
  assign rMSBit_39 = r40_p[209];
  assign rMSBitneg_39 =  ~ rMSBit_39;
  assign switch_compare_1_43 = rMSBitneg_39 > 1'b0;

  assign d_neg_124 = {d40_p[105], d40_p};
  assign d_neg_in0_41 =  - (d_neg_124);
  assign d_neg_125 = d_neg_in0_41[105:0];
  assign y_79 = (switch_compare_1_43 == 1'b0 ? d40_p :
              d_neg_125);
  assign temp_42 = x_40 + y_79;
  assign rMSBNextBits_40 = temp_42[104:0];
  assign rLSBits_40 = r40_p[103:0];
  assign tempSignBit_40 = temp_42[104];
  assign qBit_40 =  ~ tempSignBit_40;
  assign rNextTemp_40 = {rMSBNextBits_40, rLSBits_40, qBit_40};
  assign r41 = rNextTemp_40;
  always_ff @(posedge clk)
    begin : r_reg_40_process
      if (reset == 1'b1) begin
        r41_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r41_p <= r41;
        end
      end
    end
  assign rMSBits_41 = r41_p[209:104];
  assign x_41 = rMSBits_41;
  assign rMSBit_40 = r41_p[209];
  assign rMSBitneg_40 =  ~ rMSBit_40;
  assign switch_compare_1_44 = rMSBitneg_40 > 1'b0;

  assign d_neg_127 = {d41_p[105], d41_p};
  assign d_neg_in0_42 =  - (d_neg_127);
  assign d_neg_128 = d_neg_in0_42[105:0];
  assign y_81 = (switch_compare_1_44 == 1'b0 ? d41_p :
              d_neg_128);
  assign temp_43 = x_41 + y_81;
  assign rMSBNextBits_41 = temp_43[104:0];
  assign rLSBits_41 = r41_p[103:0];
  assign tempSignBit_41 = temp_43[104];
  assign qBit_41 =  ~ tempSignBit_41;
  assign rNextTemp_41 = {rMSBNextBits_41, rLSBits_41, qBit_41};
  assign r42 = rNextTemp_41;
  always_ff @(posedge clk)
    begin : r_reg_41_process
      if (reset == 1'b1) begin
        r42_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r42_p <= r42;
        end
      end
    end
  assign rMSBits_42 = r42_p[209:104];
  assign x_42 = rMSBits_42;
  assign rMSBit_41 = r42_p[209];
  assign rMSBitneg_41 =  ~ rMSBit_41;
  assign switch_compare_1_45 = rMSBitneg_41 > 1'b0;

  assign d_neg_130 = {d42_p[105], d42_p};
  assign d_neg_in0_43 =  - (d_neg_130);
  assign d_neg_131 = d_neg_in0_43[105:0];
  assign y_83 = (switch_compare_1_45 == 1'b0 ? d42_p :
              d_neg_131);
  assign temp_44 = x_42 + y_83;
  assign rMSBNextBits_42 = temp_44[104:0];
  assign rLSBits_42 = r42_p[103:0];
  assign tempSignBit_42 = temp_44[104];
  assign qBit_42 =  ~ tempSignBit_42;
  assign rNextTemp_42 = {rMSBNextBits_42, rLSBits_42, qBit_42};
  assign r43 = rNextTemp_42;
  always_ff @(posedge clk)
    begin : r_reg_42_process
      if (reset == 1'b1) begin
        r43_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r43_p <= r43;
        end
      end
    end
  assign rMSBits_43 = r43_p[209:104];
  assign x_43 = rMSBits_43;
  assign rMSBit_42 = r43_p[209];
  assign rMSBitneg_42 =  ~ rMSBit_42;
  assign switch_compare_1_46 = rMSBitneg_42 > 1'b0;

  assign d_neg_133 = {d43_p[105], d43_p};
  assign d_neg_in0_44 =  - (d_neg_133);
  assign d_neg_134 = d_neg_in0_44[105:0];
  assign y_85 = (switch_compare_1_46 == 1'b0 ? d43_p :
              d_neg_134);
  assign temp_45 = x_43 + y_85;
  assign rMSBNextBits_43 = temp_45[104:0];
  assign rLSBits_43 = r43_p[103:0];
  assign tempSignBit_43 = temp_45[104];
  assign qBit_43 =  ~ tempSignBit_43;
  assign rNextTemp_43 = {rMSBNextBits_43, rLSBits_43, qBit_43};
  assign r44 = rNextTemp_43;
  always_ff @(posedge clk)
    begin : r_reg_43_process
      if (reset == 1'b1) begin
        r44_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r44_p <= r44;
        end
      end
    end
  assign rMSBits_44 = r44_p[209:104];
  assign x_44 = rMSBits_44;
  assign rMSBit_43 = r44_p[209];
  assign rMSBitneg_43 =  ~ rMSBit_43;
  assign switch_compare_1_47 = rMSBitneg_43 > 1'b0;

  assign d_neg_136 = {d44_p[105], d44_p};
  assign d_neg_in0_45 =  - (d_neg_136);
  assign d_neg_137 = d_neg_in0_45[105:0];
  assign y_87 = (switch_compare_1_47 == 1'b0 ? d44_p :
              d_neg_137);
  assign temp_46 = x_44 + y_87;
  assign rMSBNextBits_44 = temp_46[104:0];
  assign rLSBits_44 = r44_p[103:0];
  assign tempSignBit_44 = temp_46[104];
  assign qBit_44 =  ~ tempSignBit_44;
  assign rNextTemp_44 = {rMSBNextBits_44, rLSBits_44, qBit_44};
  assign r45 = rNextTemp_44;
  always_ff @(posedge clk)
    begin : r_reg_44_process
      if (reset == 1'b1) begin
        r45_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r45_p <= r45;
        end
      end
    end
  assign rMSBits_45 = r45_p[209:104];
  assign x_45 = rMSBits_45;
  assign rMSBit_44 = r45_p[209];
  assign rMSBitneg_44 =  ~ rMSBit_44;
  assign switch_compare_1_48 = rMSBitneg_44 > 1'b0;

  assign d_neg_139 = {d45_p[105], d45_p};
  assign d_neg_in0_46 =  - (d_neg_139);
  assign d_neg_140 = d_neg_in0_46[105:0];
  assign y_89 = (switch_compare_1_48 == 1'b0 ? d45_p :
              d_neg_140);
  assign temp_47 = x_45 + y_89;
  assign rMSBNextBits_45 = temp_47[104:0];
  assign rLSBits_45 = r45_p[103:0];
  assign tempSignBit_45 = temp_47[104];
  assign qBit_45 =  ~ tempSignBit_45;
  assign rNextTemp_45 = {rMSBNextBits_45, rLSBits_45, qBit_45};
  assign r46 = rNextTemp_45;
  always_ff @(posedge clk)
    begin : r_reg_45_process
      if (reset == 1'b1) begin
        r46_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r46_p <= r46;
        end
      end
    end
  assign rMSBits_46 = r46_p[209:104];
  assign x_46 = rMSBits_46;
  assign rMSBit_45 = r46_p[209];
  assign rMSBitneg_45 =  ~ rMSBit_45;
  assign switch_compare_1_49 = rMSBitneg_45 > 1'b0;

  assign d_neg_142 = {d46_p[105], d46_p};
  assign d_neg_in0_47 =  - (d_neg_142);
  assign d_neg_143 = d_neg_in0_47[105:0];
  assign y_91 = (switch_compare_1_49 == 1'b0 ? d46_p :
              d_neg_143);
  assign temp_48 = x_46 + y_91;
  assign rMSBNextBits_46 = temp_48[104:0];
  assign rLSBits_46 = r46_p[103:0];
  assign tempSignBit_46 = temp_48[104];
  assign qBit_46 =  ~ tempSignBit_46;
  assign rNextTemp_46 = {rMSBNextBits_46, rLSBits_46, qBit_46};
  assign r47 = rNextTemp_46;
  always_ff @(posedge clk)
    begin : r_reg_46_process
      if (reset == 1'b1) begin
        r47_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r47_p <= r47;
        end
      end
    end
  assign rMSBits_47 = r47_p[209:104];
  assign x_47 = rMSBits_47;
  assign rMSBit_46 = r47_p[209];
  assign rMSBitneg_46 =  ~ rMSBit_46;
  assign switch_compare_1_50 = rMSBitneg_46 > 1'b0;

  assign d_neg_145 = {d47_p[105], d47_p};
  assign d_neg_in0_48 =  - (d_neg_145);
  assign d_neg_146 = d_neg_in0_48[105:0];
  assign y_93 = (switch_compare_1_50 == 1'b0 ? d47_p :
              d_neg_146);
  assign temp_49 = x_47 + y_93;
  assign rMSBNextBits_47 = temp_49[104:0];
  assign rLSBits_47 = r47_p[103:0];
  assign tempSignBit_47 = temp_49[104];
  assign qBit_47 =  ~ tempSignBit_47;
  assign rNextTemp_47 = {rMSBNextBits_47, rLSBits_47, qBit_47};
  assign r48 = rNextTemp_47;
  always_ff @(posedge clk)
    begin : r_reg_47_process
      if (reset == 1'b1) begin
        r48_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r48_p <= r48;
        end
      end
    end
  assign rMSBits_48 = r48_p[209:104];
  assign x_48 = rMSBits_48;
  assign rMSBit_47 = r48_p[209];
  assign rMSBitneg_47 =  ~ rMSBit_47;
  assign switch_compare_1_51 = rMSBitneg_47 > 1'b0;

  assign d_neg_148 = {d48_p[105], d48_p};
  assign d_neg_in0_49 =  - (d_neg_148);
  assign d_neg_149 = d_neg_in0_49[105:0];
  assign y_95 = (switch_compare_1_51 == 1'b0 ? d48_p :
              d_neg_149);
  assign temp_50 = x_48 + y_95;
  assign rMSBNextBits_48 = temp_50[104:0];
  assign rLSBits_48 = r48_p[103:0];
  assign tempSignBit_48 = temp_50[104];
  assign qBit_48 =  ~ tempSignBit_48;
  assign rNextTemp_48 = {rMSBNextBits_48, rLSBits_48, qBit_48};
  assign r49 = rNextTemp_48;
  always_ff @(posedge clk)
    begin : r_reg_48_process
      if (reset == 1'b1) begin
        r49_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r49_p <= r49;
        end
      end
    end
  assign rMSBits_49 = r49_p[209:104];
  assign x_49 = rMSBits_49;
  assign rMSBit_48 = r49_p[209];
  assign rMSBitneg_48 =  ~ rMSBit_48;
  assign switch_compare_1_52 = rMSBitneg_48 > 1'b0;

  assign d_neg_151 = {d49_p[105], d49_p};
  assign d_neg_in0_50 =  - (d_neg_151);
  assign d_neg_152 = d_neg_in0_50[105:0];
  assign y_97 = (switch_compare_1_52 == 1'b0 ? d49_p :
              d_neg_152);
  assign temp_51 = x_49 + y_97;
  assign rMSBNextBits_49 = temp_51[104:0];
  assign rLSBits_49 = r49_p[103:0];
  assign tempSignBit_49 = temp_51[104];
  assign qBit_49 =  ~ tempSignBit_49;
  assign rNextTemp_49 = {rMSBNextBits_49, rLSBits_49, qBit_49};
  assign r50 = rNextTemp_49;
  always_ff @(posedge clk)
    begin : r_reg_49_process
      if (reset == 1'b1) begin
        r50_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r50_p <= r50;
        end
      end
    end
  assign rMSBits_50 = r50_p[209:104];
  assign x_50 = rMSBits_50;
  assign rMSBit_49 = r50_p[209];
  assign rMSBitneg_49 =  ~ rMSBit_49;
  assign switch_compare_1_53 = rMSBitneg_49 > 1'b0;

  assign d_neg_154 = {d50_p[105], d50_p};
  assign d_neg_in0_51 =  - (d_neg_154);
  assign d_neg_155 = d_neg_in0_51[105:0];
  assign y_99 = (switch_compare_1_53 == 1'b0 ? d50_p :
              d_neg_155);
  assign temp_52 = x_50 + y_99;
  assign rMSBNextBits_50 = temp_52[104:0];
  assign rLSBits_50 = r50_p[103:0];
  assign tempSignBit_50 = temp_52[104];
  assign qBit_50 =  ~ tempSignBit_50;
  assign rNextTemp_50 = {rMSBNextBits_50, rLSBits_50, qBit_50};
  assign r51 = rNextTemp_50;
  always_ff @(posedge clk)
    begin : r_reg_50_process
      if (reset == 1'b1) begin
        r51_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r51_p <= r51;
        end
      end
    end
  assign rMSBits_51 = r51_p[209:104];
  assign x_51 = rMSBits_51;
  assign rMSBit_50 = r51_p[209];
  assign rMSBitneg_50 =  ~ rMSBit_50;
  assign switch_compare_1_54 = rMSBitneg_50 > 1'b0;

  assign d_neg_157 = {d51_p[105], d51_p};
  assign d_neg_in0_52 =  - (d_neg_157);
  assign d_neg_158 = d_neg_in0_52[105:0];
  assign y_101 = (switch_compare_1_54 == 1'b0 ? d51_p :
              d_neg_158);
  assign temp_53 = x_51 + y_101;
  assign rMSBNextBits_51 = temp_53[104:0];
  assign rLSBits_51 = r51_p[103:0];
  assign tempSignBit_51 = temp_53[104];
  assign qBit_51 =  ~ tempSignBit_51;
  assign rNextTemp_51 = {rMSBNextBits_51, rLSBits_51, qBit_51};
  assign r52 = rNextTemp_51;
  always_ff @(posedge clk)
    begin : r_reg_51_process
      if (reset == 1'b1) begin
        r52_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r52_p <= r52;
        end
      end
    end
  assign rMSBits_52 = r52_p[209:104];
  assign x_52 = rMSBits_52;
  assign rMSBit_51 = r52_p[209];
  assign rMSBitneg_51 =  ~ rMSBit_51;
  assign switch_compare_1_55 = rMSBitneg_51 > 1'b0;

  assign d_neg_160 = {d52_p[105], d52_p};
  assign d_neg_in0_53 =  - (d_neg_160);
  assign d_neg_161 = d_neg_in0_53[105:0];
  assign y_103 = (switch_compare_1_55 == 1'b0 ? d52_p :
              d_neg_161);
  assign temp_54 = x_52 + y_103;
  assign rMSBNextBits_52 = temp_54[104:0];
  assign rLSBits_52 = r52_p[103:0];
  assign tempSignBit_52 = temp_54[104];
  assign qBit_52 =  ~ tempSignBit_52;
  assign rNextTemp_52 = {rMSBNextBits_52, rLSBits_52, qBit_52};
  assign r53 = rNextTemp_52;
  always_ff @(posedge clk)
    begin : r_reg_52_process
      if (reset == 1'b1) begin
        r53_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r53_p <= r53;
        end
      end
    end
  assign rMSBits_53 = r53_p[209:104];
  assign x_53 = rMSBits_53;
  assign rMSBit_52 = r53_p[209];
  assign rMSBitneg_52 =  ~ rMSBit_52;
  assign switch_compare_1_56 = rMSBitneg_52 > 1'b0;

  assign d_neg_163 = {d53_p[105], d53_p};
  assign d_neg_in0_54 =  - (d_neg_163);
  assign d_neg_164 = d_neg_in0_54[105:0];
  assign y_105 = (switch_compare_1_56 == 1'b0 ? d53_p :
              d_neg_164);
  assign temp_55 = x_53 + y_105;
  assign rMSBNextBits_53 = temp_55[104:0];
  assign rLSBits_53 = r53_p[103:0];
  assign tempSignBit_53 = temp_55[104];
  assign qBit_53 =  ~ tempSignBit_53;
  assign rNextTemp_53 = {rMSBNextBits_53, rLSBits_53, qBit_53};
  assign r54 = rNextTemp_53;
  always_ff @(posedge clk)
    begin : r_reg_53_process
      if (reset == 1'b1) begin
        r54_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r54_p <= r54;
        end
      end
    end
  assign rMSBits_54 = r54_p[209:104];
  assign x_54 = rMSBits_54;
  assign rMSBit_53 = r54_p[209];
  assign rMSBitneg_53 =  ~ rMSBit_53;
  assign switch_compare_1_57 = rMSBitneg_53 > 1'b0;

  assign d_neg_166 = {d54_p[105], d54_p};
  assign d_neg_in0_55 =  - (d_neg_166);
  assign d_neg_167 = d_neg_in0_55[105:0];
  assign y_107 = (switch_compare_1_57 == 1'b0 ? d54_p :
              d_neg_167);
  assign temp_56 = x_54 + y_107;
  assign rMSBNextBits_54 = temp_56[104:0];
  assign rLSBits_54 = r54_p[103:0];
  assign tempSignBit_54 = temp_56[104];
  assign qBit_54 =  ~ tempSignBit_54;
  assign rNextTemp_54 = {rMSBNextBits_54, rLSBits_54, qBit_54};
  assign r55 = rNextTemp_54;
  always_ff @(posedge clk)
    begin : r_reg_54_process
      if (reset == 1'b1) begin
        r55_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r55_p <= r55;
        end
      end
    end
  assign rMSBits_55 = r55_p[209:104];
  assign x_55 = rMSBits_55;
  assign rMSBit_54 = r55_p[209];
  assign rMSBitneg_54 =  ~ rMSBit_54;
  assign switch_compare_1_58 = rMSBitneg_54 > 1'b0;

  assign d_neg_169 = {d55_p[105], d55_p};
  assign d_neg_in0_56 =  - (d_neg_169);
  assign d_neg_170 = d_neg_in0_56[105:0];
  assign y_109 = (switch_compare_1_58 == 1'b0 ? d55_p :
              d_neg_170);
  assign temp_57 = x_55 + y_109;
  assign rMSBNextBits_55 = temp_57[104:0];
  assign rLSBits_55 = r55_p[103:0];
  assign tempSignBit_55 = temp_57[104];
  assign qBit_55 =  ~ tempSignBit_55;
  assign rNextTemp_55 = {rMSBNextBits_55, rLSBits_55, qBit_55};
  assign r56 = rNextTemp_55;
  always_ff @(posedge clk)
    begin : r_reg_55_process
      if (reset == 1'b1) begin
        r56_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r56_p <= r56;
        end
      end
    end
  assign rMSBits_56 = r56_p[209:104];
  assign x_56 = rMSBits_56;
  assign rMSBit_55 = r56_p[209];
  assign rMSBitneg_55 =  ~ rMSBit_55;
  assign switch_compare_1_59 = rMSBitneg_55 > 1'b0;

  assign d_neg_172 = {d56_p[105], d56_p};
  assign d_neg_in0_57 =  - (d_neg_172);
  assign d_neg_173 = d_neg_in0_57[105:0];
  assign y_111 = (switch_compare_1_59 == 1'b0 ? d56_p :
              d_neg_173);
  assign temp_58 = x_56 + y_111;
  assign rMSBNextBits_56 = temp_58[104:0];
  assign rLSBits_56 = r56_p[103:0];
  assign tempSignBit_56 = temp_58[104];
  assign qBit_56 =  ~ tempSignBit_56;
  assign rNextTemp_56 = {rMSBNextBits_56, rLSBits_56, qBit_56};
  assign r57 = rNextTemp_56;
  always_ff @(posedge clk)
    begin : r_reg_56_process
      if (reset == 1'b1) begin
        r57_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r57_p <= r57;
        end
      end
    end
  assign rMSBits_57 = r57_p[209:104];
  assign x_57 = rMSBits_57;
  assign rMSBit_56 = r57_p[209];
  assign rMSBitneg_56 =  ~ rMSBit_56;
  assign switch_compare_1_60 = rMSBitneg_56 > 1'b0;

  assign d_neg_175 = {d57_p[105], d57_p};
  assign d_neg_in0_58 =  - (d_neg_175);
  assign d_neg_176 = d_neg_in0_58[105:0];
  assign y_113 = (switch_compare_1_60 == 1'b0 ? d57_p :
              d_neg_176);
  assign temp_59 = x_57 + y_113;
  assign rMSBNextBits_57 = temp_59[104:0];
  assign rLSBits_57 = r57_p[103:0];
  assign tempSignBit_57 = temp_59[104];
  assign qBit_57 =  ~ tempSignBit_57;
  assign rNextTemp_57 = {rMSBNextBits_57, rLSBits_57, qBit_57};
  assign r58 = rNextTemp_57;
  always_ff @(posedge clk)
    begin : r_reg_57_process
      if (reset == 1'b1) begin
        r58_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r58_p <= r58;
        end
      end
    end
  assign rMSBits_58 = r58_p[209:104];
  assign x_58 = rMSBits_58;
  assign rMSBit_57 = r58_p[209];
  assign rMSBitneg_57 =  ~ rMSBit_57;
  assign switch_compare_1_61 = rMSBitneg_57 > 1'b0;

  assign d_neg_178 = {d58_p[105], d58_p};
  assign d_neg_in0_59 =  - (d_neg_178);
  assign d_neg_179 = d_neg_in0_59[105:0];
  assign y_115 = (switch_compare_1_61 == 1'b0 ? d58_p :
              d_neg_179);
  assign temp_60 = x_58 + y_115;
  assign rMSBNextBits_58 = temp_60[104:0];
  assign rLSBits_58 = r58_p[103:0];
  assign tempSignBit_58 = temp_60[104];
  assign qBit_58 =  ~ tempSignBit_58;
  assign rNextTemp_58 = {rMSBNextBits_58, rLSBits_58, qBit_58};
  assign r59 = rNextTemp_58;
  always_ff @(posedge clk)
    begin : r_reg_58_process
      if (reset == 1'b1) begin
        r59_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r59_p <= r59;
        end
      end
    end
  assign rMSBits_59 = r59_p[209:104];
  assign x_59 = rMSBits_59;
  assign rMSBit_58 = r59_p[209];
  assign rMSBitneg_58 =  ~ rMSBit_58;
  assign switch_compare_1_62 = rMSBitneg_58 > 1'b0;

  assign d_neg_181 = {d59_p[105], d59_p};
  assign d_neg_in0_60 =  - (d_neg_181);
  assign d_neg_182 = d_neg_in0_60[105:0];
  assign y_117 = (switch_compare_1_62 == 1'b0 ? d59_p :
              d_neg_182);
  assign temp_61 = x_59 + y_117;
  assign rMSBNextBits_59 = temp_61[104:0];
  assign rLSBits_59 = r59_p[103:0];
  assign tempSignBit_59 = temp_61[104];
  assign qBit_59 =  ~ tempSignBit_59;
  assign rNextTemp_59 = {rMSBNextBits_59, rLSBits_59, qBit_59};
  assign r60 = rNextTemp_59;
  always_ff @(posedge clk)
    begin : r_reg_59_process
      if (reset == 1'b1) begin
        r60_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r60_p <= r60;
        end
      end
    end
  assign rMSBits_60 = r60_p[209:104];
  assign x_60 = rMSBits_60;
  assign rMSBit_59 = r60_p[209];
  assign rMSBitneg_59 =  ~ rMSBit_59;
  assign switch_compare_1_63 = rMSBitneg_59 > 1'b0;

  assign d_neg_184 = {d60_p[105], d60_p};
  assign d_neg_in0_61 =  - (d_neg_184);
  assign d_neg_185 = d_neg_in0_61[105:0];
  assign y_119 = (switch_compare_1_63 == 1'b0 ? d60_p :
              d_neg_185);
  assign temp_62 = x_60 + y_119;
  assign rMSBNextBits_60 = temp_62[104:0];
  assign rLSBits_60 = r60_p[103:0];
  assign tempSignBit_60 = temp_62[104];
  assign qBit_60 =  ~ tempSignBit_60;
  assign rNextTemp_60 = {rMSBNextBits_60, rLSBits_60, qBit_60};
  assign r61 = rNextTemp_60;
  always_ff @(posedge clk)
    begin : r_reg_60_process
      if (reset == 1'b1) begin
        r61_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r61_p <= r61;
        end
      end
    end
  assign rMSBits_61 = r61_p[209:104];
  assign x_61 = rMSBits_61;
  assign rMSBit_60 = r61_p[209];
  assign rMSBitneg_60 =  ~ rMSBit_60;
  assign switch_compare_1_64 = rMSBitneg_60 > 1'b0;

  assign d_neg_187 = {d61_p[105], d61_p};
  assign d_neg_in0_62 =  - (d_neg_187);
  assign d_neg_188 = d_neg_in0_62[105:0];
  assign y_121 = (switch_compare_1_64 == 1'b0 ? d61_p :
              d_neg_188);
  assign temp_63 = x_61 + y_121;
  assign rMSBNextBits_61 = temp_63[104:0];
  assign rLSBits_61 = r61_p[103:0];
  assign tempSignBit_61 = temp_63[104];
  assign qBit_61 =  ~ tempSignBit_61;
  assign rNextTemp_61 = {rMSBNextBits_61, rLSBits_61, qBit_61};
  assign r62 = rNextTemp_61;
  always_ff @(posedge clk)
    begin : r_reg_61_process
      if (reset == 1'b1) begin
        r62_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r62_p <= r62;
        end
      end
    end
  assign rMSBits_62 = r62_p[209:104];
  assign x_62 = rMSBits_62;
  assign rMSBit_61 = r62_p[209];
  assign rMSBitneg_61 =  ~ rMSBit_61;
  assign switch_compare_1_65 = rMSBitneg_61 > 1'b0;

  assign d_neg_190 = {d62_p[105], d62_p};
  assign d_neg_in0_63 =  - (d_neg_190);
  assign d_neg_191 = d_neg_in0_63[105:0];
  assign y_123 = (switch_compare_1_65 == 1'b0 ? d62_p :
              d_neg_191);
  assign temp_64 = x_62 + y_123;
  assign rMSBNextBits_62 = temp_64[104:0];
  assign rLSBits_62 = r62_p[103:0];
  assign tempSignBit_62 = temp_64[104];
  assign qBit_62 =  ~ tempSignBit_62;
  assign rNextTemp_62 = {rMSBNextBits_62, rLSBits_62, qBit_62};
  assign r63 = rNextTemp_62;
  always_ff @(posedge clk)
    begin : r_reg_62_process
      if (reset == 1'b1) begin
        r63_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r63_p <= r63;
        end
      end
    end
  assign rMSBits_63 = r63_p[209:104];
  assign x_63 = rMSBits_63;
  assign rMSBit_62 = r63_p[209];
  assign rMSBitneg_62 =  ~ rMSBit_62;
  assign switch_compare_1_66 = rMSBitneg_62 > 1'b0;

  assign d_neg_193 = {d63_p[105], d63_p};
  assign d_neg_in0_64 =  - (d_neg_193);
  assign d_neg_194 = d_neg_in0_64[105:0];
  assign y_125 = (switch_compare_1_66 == 1'b0 ? d63_p :
              d_neg_194);
  assign temp_65 = x_63 + y_125;
  assign rMSBNextBits_63 = temp_65[104:0];
  assign rLSBits_63 = r63_p[103:0];
  assign tempSignBit_63 = temp_65[104];
  assign qBit_63 =  ~ tempSignBit_63;
  assign rNextTemp_63 = {rMSBNextBits_63, rLSBits_63, qBit_63};
  assign r64 = rNextTemp_63;
  always_ff @(posedge clk)
    begin : r_reg_63_process
      if (reset == 1'b1) begin
        r64_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r64_p <= r64;
        end
      end
    end
  assign rMSBits_64 = r64_p[209:104];
  assign x_64 = rMSBits_64;
  assign rMSBit_63 = r64_p[209];
  assign rMSBitneg_63 =  ~ rMSBit_63;
  assign switch_compare_1_67 = rMSBitneg_63 > 1'b0;

  assign d_neg_196 = {d64_p[105], d64_p};
  assign d_neg_in0_65 =  - (d_neg_196);
  assign d_neg_197 = d_neg_in0_65[105:0];
  assign y_127 = (switch_compare_1_67 == 1'b0 ? d64_p :
              d_neg_197);
  assign temp_66 = x_64 + y_127;
  assign rMSBNextBits_64 = temp_66[104:0];
  assign rLSBits_64 = r64_p[103:0];
  assign tempSignBit_64 = temp_66[104];
  assign qBit_64 =  ~ tempSignBit_64;
  assign rNextTemp_64 = {rMSBNextBits_64, rLSBits_64, qBit_64};
  assign r65 = rNextTemp_64;
  always_ff @(posedge clk)
    begin : r_reg_64_process
      if (reset == 1'b1) begin
        r65_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r65_p <= r65;
        end
      end
    end
  assign rMSBits_65 = r65_p[209:104];
  assign x_65 = rMSBits_65;
  assign rMSBit_64 = r65_p[209];
  assign rMSBitneg_64 =  ~ rMSBit_64;
  assign switch_compare_1_68 = rMSBitneg_64 > 1'b0;

  assign d_neg_199 = {d65_p[105], d65_p};
  assign d_neg_in0_66 =  - (d_neg_199);
  assign d_neg_200 = d_neg_in0_66[105:0];
  assign y_129 = (switch_compare_1_68 == 1'b0 ? d65_p :
              d_neg_200);
  assign temp_67 = x_65 + y_129;
  assign rMSBNextBits_65 = temp_67[104:0];
  assign rLSBits_65 = r65_p[103:0];
  assign tempSignBit_65 = temp_67[104];
  assign qBit_65 =  ~ tempSignBit_65;
  assign rNextTemp_65 = {rMSBNextBits_65, rLSBits_65, qBit_65};
  assign r66 = rNextTemp_65;
  always_ff @(posedge clk)
    begin : r_reg_65_process
      if (reset == 1'b1) begin
        r66_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r66_p <= r66;
        end
      end
    end
  assign rMSBits_66 = r66_p[209:104];
  assign x_66 = rMSBits_66;
  assign rMSBit_65 = r66_p[209];
  assign rMSBitneg_65 =  ~ rMSBit_65;
  assign switch_compare_1_69 = rMSBitneg_65 > 1'b0;

  assign d_neg_202 = {d66_p[105], d66_p};
  assign d_neg_in0_67 =  - (d_neg_202);
  assign d_neg_203 = d_neg_in0_67[105:0];
  assign y_131 = (switch_compare_1_69 == 1'b0 ? d66_p :
              d_neg_203);
  assign temp_68 = x_66 + y_131;
  assign rMSBNextBits_66 = temp_68[104:0];
  assign rLSBits_66 = r66_p[103:0];
  assign tempSignBit_66 = temp_68[104];
  assign qBit_66 =  ~ tempSignBit_66;
  assign rNextTemp_66 = {rMSBNextBits_66, rLSBits_66, qBit_66};
  assign r67 = rNextTemp_66;
  always_ff @(posedge clk)
    begin : r_reg_66_process
      if (reset == 1'b1) begin
        r67_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r67_p <= r67;
        end
      end
    end
  assign rMSBits_67 = r67_p[209:104];
  assign x_67 = rMSBits_67;
  assign rMSBit_66 = r67_p[209];
  assign rMSBitneg_66 =  ~ rMSBit_66;
  assign switch_compare_1_70 = rMSBitneg_66 > 1'b0;

  assign d_neg_205 = {d67_p[105], d67_p};
  assign d_neg_in0_68 =  - (d_neg_205);
  assign d_neg_206 = d_neg_in0_68[105:0];
  assign y_133 = (switch_compare_1_70 == 1'b0 ? d67_p :
              d_neg_206);
  assign temp_69 = x_67 + y_133;
  assign rMSBNextBits_67 = temp_69[104:0];
  assign rLSBits_67 = r67_p[103:0];
  assign tempSignBit_67 = temp_69[104];
  assign qBit_67 =  ~ tempSignBit_67;
  assign rNextTemp_67 = {rMSBNextBits_67, rLSBits_67, qBit_67};
  assign r68 = rNextTemp_67;
  always_ff @(posedge clk)
    begin : r_reg_67_process
      if (reset == 1'b1) begin
        r68_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r68_p <= r68;
        end
      end
    end
  assign rMSBits_68 = r68_p[209:104];
  assign x_68 = rMSBits_68;
  assign rMSBit_67 = r68_p[209];
  assign rMSBitneg_67 =  ~ rMSBit_67;
  assign switch_compare_1_71 = rMSBitneg_67 > 1'b0;

  assign d_neg_208 = {d68_p[105], d68_p};
  assign d_neg_in0_69 =  - (d_neg_208);
  assign d_neg_209 = d_neg_in0_69[105:0];
  assign y_135 = (switch_compare_1_71 == 1'b0 ? d68_p :
              d_neg_209);
  assign temp_70 = x_68 + y_135;
  assign rMSBNextBits_68 = temp_70[104:0];
  assign rLSBits_68 = r68_p[103:0];
  assign tempSignBit_68 = temp_70[104];
  assign qBit_68 =  ~ tempSignBit_68;
  assign rNextTemp_68 = {rMSBNextBits_68, rLSBits_68, qBit_68};
  assign r69 = rNextTemp_68;
  always_ff @(posedge clk)
    begin : r_reg_68_process
      if (reset == 1'b1) begin
        r69_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r69_p <= r69;
        end
      end
    end
  assign rMSBits_69 = r69_p[209:104];
  assign x_69 = rMSBits_69;
  assign rMSBit_68 = r69_p[209];
  assign rMSBitneg_68 =  ~ rMSBit_68;
  assign switch_compare_1_72 = rMSBitneg_68 > 1'b0;

  assign d_neg_211 = {d69_p[105], d69_p};
  assign d_neg_in0_70 =  - (d_neg_211);
  assign d_neg_212 = d_neg_in0_70[105:0];
  assign y_137 = (switch_compare_1_72 == 1'b0 ? d69_p :
              d_neg_212);
  assign temp_71 = x_69 + y_137;
  assign rMSBNextBits_69 = temp_71[104:0];
  assign rLSBits_69 = r69_p[103:0];
  assign tempSignBit_69 = temp_71[104];
  assign qBit_69 =  ~ tempSignBit_69;
  assign rNextTemp_69 = {rMSBNextBits_69, rLSBits_69, qBit_69};
  assign r70 = rNextTemp_69;
  always_ff @(posedge clk)
    begin : r_reg_69_process
      if (reset == 1'b1) begin
        r70_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r70_p <= r70;
        end
      end
    end
  assign rMSBits_70 = r70_p[209:104];
  assign x_70 = rMSBits_70;
  assign rMSBit_69 = r70_p[209];
  assign rMSBitneg_69 =  ~ rMSBit_69;
  assign switch_compare_1_73 = rMSBitneg_69 > 1'b0;

  assign d_neg_214 = {d70_p[105], d70_p};
  assign d_neg_in0_71 =  - (d_neg_214);
  assign d_neg_215 = d_neg_in0_71[105:0];
  assign y_139 = (switch_compare_1_73 == 1'b0 ? d70_p :
              d_neg_215);
  assign temp_72 = x_70 + y_139;
  assign rMSBNextBits_70 = temp_72[104:0];
  assign rLSBits_70 = r70_p[103:0];
  assign tempSignBit_70 = temp_72[104];
  assign qBit_70 =  ~ tempSignBit_70;
  assign rNextTemp_70 = {rMSBNextBits_70, rLSBits_70, qBit_70};
  assign r71 = rNextTemp_70;
  always_ff @(posedge clk)
    begin : r_reg_70_process
      if (reset == 1'b1) begin
        r71_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r71_p <= r71;
        end
      end
    end
  assign rMSBits_71 = r71_p[209:104];
  assign x_71 = rMSBits_71;
  assign rMSBit_70 = r71_p[209];
  assign rMSBitneg_70 =  ~ rMSBit_70;
  assign switch_compare_1_74 = rMSBitneg_70 > 1'b0;

  assign d_neg_217 = {d71_p[105], d71_p};
  assign d_neg_in0_72 =  - (d_neg_217);
  assign d_neg_218 = d_neg_in0_72[105:0];
  assign y_141 = (switch_compare_1_74 == 1'b0 ? d71_p :
              d_neg_218);
  assign temp_73 = x_71 + y_141;
  assign rMSBNextBits_71 = temp_73[104:0];
  assign rLSBits_71 = r71_p[103:0];
  assign tempSignBit_71 = temp_73[104];
  assign qBit_71 =  ~ tempSignBit_71;
  assign rNextTemp_71 = {rMSBNextBits_71, rLSBits_71, qBit_71};
  assign r72 = rNextTemp_71;
  always_ff @(posedge clk)
    begin : r_reg_71_process
      if (reset == 1'b1) begin
        r72_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r72_p <= r72;
        end
      end
    end
  assign rMSBits_72 = r72_p[209:104];
  assign x_72 = rMSBits_72;
  assign rMSBit_71 = r72_p[209];
  assign rMSBitneg_71 =  ~ rMSBit_71;
  assign switch_compare_1_75 = rMSBitneg_71 > 1'b0;

  assign d_neg_220 = {d72_p[105], d72_p};
  assign d_neg_in0_73 =  - (d_neg_220);
  assign d_neg_221 = d_neg_in0_73[105:0];
  assign y_143 = (switch_compare_1_75 == 1'b0 ? d72_p :
              d_neg_221);
  assign temp_74 = x_72 + y_143;
  assign rMSBNextBits_72 = temp_74[104:0];
  assign rLSBits_72 = r72_p[103:0];
  assign tempSignBit_72 = temp_74[104];
  assign qBit_72 =  ~ tempSignBit_72;
  assign rNextTemp_72 = {rMSBNextBits_72, rLSBits_72, qBit_72};
  assign r73 = rNextTemp_72;
  always_ff @(posedge clk)
    begin : r_reg_72_process
      if (reset == 1'b1) begin
        r73_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r73_p <= r73;
        end
      end
    end
  assign rMSBits_73 = r73_p[209:104];
  assign x_73 = rMSBits_73;
  assign rMSBit_72 = r73_p[209];
  assign rMSBitneg_72 =  ~ rMSBit_72;
  assign switch_compare_1_76 = rMSBitneg_72 > 1'b0;

  assign d_neg_223 = {d73_p[105], d73_p};
  assign d_neg_in0_74 =  - (d_neg_223);
  assign d_neg_224 = d_neg_in0_74[105:0];
  assign y_145 = (switch_compare_1_76 == 1'b0 ? d73_p :
              d_neg_224);
  assign temp_75 = x_73 + y_145;
  assign rMSBNextBits_73 = temp_75[104:0];
  assign rLSBits_73 = r73_p[103:0];
  assign tempSignBit_73 = temp_75[104];
  assign qBit_73 =  ~ tempSignBit_73;
  assign rNextTemp_73 = {rMSBNextBits_73, rLSBits_73, qBit_73};
  assign r74 = rNextTemp_73;
  always_ff @(posedge clk)
    begin : r_reg_73_process
      if (reset == 1'b1) begin
        r74_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r74_p <= r74;
        end
      end
    end
  assign rMSBits_74 = r74_p[209:104];
  assign x_74 = rMSBits_74;
  assign rMSBit_73 = r74_p[209];
  assign rMSBitneg_73 =  ~ rMSBit_73;
  assign switch_compare_1_77 = rMSBitneg_73 > 1'b0;

  assign d_neg_226 = {d74_p[105], d74_p};
  assign d_neg_in0_75 =  - (d_neg_226);
  assign d_neg_227 = d_neg_in0_75[105:0];
  assign y_147 = (switch_compare_1_77 == 1'b0 ? d74_p :
              d_neg_227);
  assign temp_76 = x_74 + y_147;
  assign rMSBNextBits_74 = temp_76[104:0];
  assign rLSBits_74 = r74_p[103:0];
  assign tempSignBit_74 = temp_76[104];
  assign qBit_74 =  ~ tempSignBit_74;
  assign rNextTemp_74 = {rMSBNextBits_74, rLSBits_74, qBit_74};
  assign r75 = rNextTemp_74;
  always_ff @(posedge clk)
    begin : r_reg_74_process
      if (reset == 1'b1) begin
        r75_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r75_p <= r75;
        end
      end
    end
  assign rMSBits_75 = r75_p[209:104];
  assign x_75 = rMSBits_75;
  assign rMSBit_74 = r75_p[209];
  assign rMSBitneg_74 =  ~ rMSBit_74;
  assign switch_compare_1_78 = rMSBitneg_74 > 1'b0;

  assign d_neg_229 = {d75_p[105], d75_p};
  assign d_neg_in0_76 =  - (d_neg_229);
  assign d_neg_230 = d_neg_in0_76[105:0];
  assign y_149 = (switch_compare_1_78 == 1'b0 ? d75_p :
              d_neg_230);
  assign temp_77 = x_75 + y_149;
  assign rMSBNextBits_75 = temp_77[104:0];
  assign rLSBits_75 = r75_p[103:0];
  assign tempSignBit_75 = temp_77[104];
  assign qBit_75 =  ~ tempSignBit_75;
  assign rNextTemp_75 = {rMSBNextBits_75, rLSBits_75, qBit_75};
  assign r76 = rNextTemp_75;
  always_ff @(posedge clk)
    begin : r_reg_75_process
      if (reset == 1'b1) begin
        r76_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r76_p <= r76;
        end
      end
    end
  assign rMSBits_76 = r76_p[209:104];
  assign x_76 = rMSBits_76;
  assign rMSBit_75 = r76_p[209];
  assign rMSBitneg_75 =  ~ rMSBit_75;
  assign switch_compare_1_79 = rMSBitneg_75 > 1'b0;

  assign d_neg_232 = {d76_p[105], d76_p};
  assign d_neg_in0_77 =  - (d_neg_232);
  assign d_neg_233 = d_neg_in0_77[105:0];
  assign y_151 = (switch_compare_1_79 == 1'b0 ? d76_p :
              d_neg_233);
  assign temp_78 = x_76 + y_151;
  assign rMSBNextBits_76 = temp_78[104:0];
  assign rLSBits_76 = r76_p[103:0];
  assign tempSignBit_76 = temp_78[104];
  assign qBit_76 =  ~ tempSignBit_76;
  assign rNextTemp_76 = {rMSBNextBits_76, rLSBits_76, qBit_76};
  assign r77 = rNextTemp_76;
  always_ff @(posedge clk)
    begin : r_reg_76_process
      if (reset == 1'b1) begin
        r77_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r77_p <= r77;
        end
      end
    end
  assign rMSBits_77 = r77_p[209:104];
  assign x_77 = rMSBits_77;
  assign rMSBit_76 = r77_p[209];
  assign rMSBitneg_76 =  ~ rMSBit_76;
  assign switch_compare_1_80 = rMSBitneg_76 > 1'b0;

  assign d_neg_235 = {d77_p[105], d77_p};
  assign d_neg_in0_78 =  - (d_neg_235);
  assign d_neg_236 = d_neg_in0_78[105:0];
  assign y_153 = (switch_compare_1_80 == 1'b0 ? d77_p :
              d_neg_236);
  assign temp_79 = x_77 + y_153;
  assign rMSBNextBits_77 = temp_79[104:0];
  assign rLSBits_77 = r77_p[103:0];
  assign tempSignBit_77 = temp_79[104];
  assign qBit_77 =  ~ tempSignBit_77;
  assign rNextTemp_77 = {rMSBNextBits_77, rLSBits_77, qBit_77};
  assign r78 = rNextTemp_77;
  always_ff @(posedge clk)
    begin : r_reg_77_process
      if (reset == 1'b1) begin
        r78_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r78_p <= r78;
        end
      end
    end
  assign rMSBits_78 = r78_p[209:104];
  assign x_78 = rMSBits_78;
  assign rMSBit_77 = r78_p[209];
  assign rMSBitneg_77 =  ~ rMSBit_77;
  assign switch_compare_1_81 = rMSBitneg_77 > 1'b0;

  assign d_neg_238 = {d78_p[105], d78_p};
  assign d_neg_in0_79 =  - (d_neg_238);
  assign d_neg_239 = d_neg_in0_79[105:0];
  assign y_155 = (switch_compare_1_81 == 1'b0 ? d78_p :
              d_neg_239);
  assign temp_80 = x_78 + y_155;
  assign rMSBNextBits_78 = temp_80[104:0];
  assign rLSBits_78 = r78_p[103:0];
  assign tempSignBit_78 = temp_80[104];
  assign qBit_78 =  ~ tempSignBit_78;
  assign rNextTemp_78 = {rMSBNextBits_78, rLSBits_78, qBit_78};
  assign r79 = rNextTemp_78;
  always_ff @(posedge clk)
    begin : r_reg_78_process
      if (reset == 1'b1) begin
        r79_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r79_p <= r79;
        end
      end
    end
  assign rMSBits_79 = r79_p[209:104];
  assign x_79 = rMSBits_79;
  assign rMSBit_78 = r79_p[209];
  assign rMSBitneg_78 =  ~ rMSBit_78;
  assign switch_compare_1_82 = rMSBitneg_78 > 1'b0;

  assign d_neg_241 = {d79_p[105], d79_p};
  assign d_neg_in0_80 =  - (d_neg_241);
  assign d_neg_242 = d_neg_in0_80[105:0];
  assign y_157 = (switch_compare_1_82 == 1'b0 ? d79_p :
              d_neg_242);
  assign temp_81 = x_79 + y_157;
  assign rMSBNextBits_79 = temp_81[104:0];
  assign rLSBits_79 = r79_p[103:0];
  assign tempSignBit_79 = temp_81[104];
  assign qBit_79 =  ~ tempSignBit_79;
  assign rNextTemp_79 = {rMSBNextBits_79, rLSBits_79, qBit_79};
  assign r80 = rNextTemp_79;
  always_ff @(posedge clk)
    begin : r_reg_79_process
      if (reset == 1'b1) begin
        r80_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r80_p <= r80;
        end
      end
    end
  assign rMSBits_80 = r80_p[209:104];
  assign x_80 = rMSBits_80;
  assign rMSBit_79 = r80_p[209];
  assign rMSBitneg_79 =  ~ rMSBit_79;
  assign switch_compare_1_83 = rMSBitneg_79 > 1'b0;

  assign d_neg_244 = {d80_p[105], d80_p};
  assign d_neg_in0_81 =  - (d_neg_244);
  assign d_neg_245 = d_neg_in0_81[105:0];
  assign y_159 = (switch_compare_1_83 == 1'b0 ? d80_p :
              d_neg_245);
  assign temp_82 = x_80 + y_159;
  assign rMSBNextBits_80 = temp_82[104:0];
  assign rLSBits_80 = r80_p[103:0];
  assign tempSignBit_80 = temp_82[104];
  assign qBit_80 =  ~ tempSignBit_80;
  assign rNextTemp_80 = {rMSBNextBits_80, rLSBits_80, qBit_80};
  assign r81 = rNextTemp_80;
  always_ff @(posedge clk)
    begin : r_reg_80_process
      if (reset == 1'b1) begin
        r81_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r81_p <= r81;
        end
      end
    end
  assign rMSBits_81 = r81_p[209:104];
  assign x_81 = rMSBits_81;
  assign rMSBit_80 = r81_p[209];
  assign rMSBitneg_80 =  ~ rMSBit_80;
  assign switch_compare_1_84 = rMSBitneg_80 > 1'b0;

  assign d_neg_247 = {d81_p[105], d81_p};
  assign d_neg_in0_82 =  - (d_neg_247);
  assign d_neg_248 = d_neg_in0_82[105:0];
  assign y_161 = (switch_compare_1_84 == 1'b0 ? d81_p :
              d_neg_248);
  assign temp_83 = x_81 + y_161;
  assign rMSBNextBits_81 = temp_83[104:0];
  assign rLSBits_81 = r81_p[103:0];
  assign tempSignBit_81 = temp_83[104];
  assign qBit_81 =  ~ tempSignBit_81;
  assign rNextTemp_81 = {rMSBNextBits_81, rLSBits_81, qBit_81};
  assign r82 = rNextTemp_81;
  always_ff @(posedge clk)
    begin : r_reg_81_process
      if (reset == 1'b1) begin
        r82_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r82_p <= r82;
        end
      end
    end
  assign rMSBits_82 = r82_p[209:104];
  assign x_82 = rMSBits_82;
  assign rMSBit_81 = r82_p[209];
  assign rMSBitneg_81 =  ~ rMSBit_81;
  assign switch_compare_1_85 = rMSBitneg_81 > 1'b0;

  assign d_neg_250 = {d82_p[105], d82_p};
  assign d_neg_in0_83 =  - (d_neg_250);
  assign d_neg_251 = d_neg_in0_83[105:0];
  assign y_163 = (switch_compare_1_85 == 1'b0 ? d82_p :
              d_neg_251);
  assign temp_84 = x_82 + y_163;
  assign rMSBNextBits_82 = temp_84[104:0];
  assign rLSBits_82 = r82_p[103:0];
  assign tempSignBit_82 = temp_84[104];
  assign qBit_82 =  ~ tempSignBit_82;
  assign rNextTemp_82 = {rMSBNextBits_82, rLSBits_82, qBit_82};
  assign r83 = rNextTemp_82;
  always_ff @(posedge clk)
    begin : r_reg_82_process
      if (reset == 1'b1) begin
        r83_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r83_p <= r83;
        end
      end
    end
  assign rMSBits_83 = r83_p[209:104];
  assign x_83 = rMSBits_83;
  assign rMSBit_82 = r83_p[209];
  assign rMSBitneg_82 =  ~ rMSBit_82;
  assign switch_compare_1_86 = rMSBitneg_82 > 1'b0;

  assign d_neg_253 = {d83_p[105], d83_p};
  assign d_neg_in0_84 =  - (d_neg_253);
  assign d_neg_254 = d_neg_in0_84[105:0];
  assign y_165 = (switch_compare_1_86 == 1'b0 ? d83_p :
              d_neg_254);
  assign temp_85 = x_83 + y_165;
  assign rMSBNextBits_83 = temp_85[104:0];
  assign rLSBits_83 = r83_p[103:0];
  assign tempSignBit_83 = temp_85[104];
  assign qBit_83 =  ~ tempSignBit_83;
  assign rNextTemp_83 = {rMSBNextBits_83, rLSBits_83, qBit_83};
  assign r84 = rNextTemp_83;
  always_ff @(posedge clk)
    begin : r_reg_83_process
      if (reset == 1'b1) begin
        r84_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r84_p <= r84;
        end
      end
    end
  assign rMSBits_84 = r84_p[209:104];
  assign x_84 = rMSBits_84;
  assign rMSBit_83 = r84_p[209];
  assign rMSBitneg_83 =  ~ rMSBit_83;
  assign switch_compare_1_87 = rMSBitneg_83 > 1'b0;

  assign d_neg_256 = {d84_p[105], d84_p};
  assign d_neg_in0_85 =  - (d_neg_256);
  assign d_neg_257 = d_neg_in0_85[105:0];
  assign y_167 = (switch_compare_1_87 == 1'b0 ? d84_p :
              d_neg_257);
  assign temp_86 = x_84 + y_167;
  assign rMSBNextBits_84 = temp_86[104:0];
  assign rLSBits_84 = r84_p[103:0];
  assign tempSignBit_84 = temp_86[104];
  assign qBit_84 =  ~ tempSignBit_84;
  assign rNextTemp_84 = {rMSBNextBits_84, rLSBits_84, qBit_84};
  assign r85 = rNextTemp_84;
  always_ff @(posedge clk)
    begin : r_reg_84_process
      if (reset == 1'b1) begin
        r85_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r85_p <= r85;
        end
      end
    end
  assign rMSBits_85 = r85_p[209:104];
  assign x_85 = rMSBits_85;
  assign rMSBit_84 = r85_p[209];
  assign rMSBitneg_84 =  ~ rMSBit_84;
  assign switch_compare_1_88 = rMSBitneg_84 > 1'b0;

  assign d_neg_259 = {d85_p[105], d85_p};
  assign d_neg_in0_86 =  - (d_neg_259);
  assign d_neg_260 = d_neg_in0_86[105:0];
  assign y_169 = (switch_compare_1_88 == 1'b0 ? d85_p :
              d_neg_260);
  assign temp_87 = x_85 + y_169;
  assign rMSBNextBits_85 = temp_87[104:0];
  assign rLSBits_85 = r85_p[103:0];
  assign tempSignBit_85 = temp_87[104];
  assign qBit_85 =  ~ tempSignBit_85;
  assign rNextTemp_85 = {rMSBNextBits_85, rLSBits_85, qBit_85};
  assign r86 = rNextTemp_85;
  always_ff @(posedge clk)
    begin : r_reg_85_process
      if (reset == 1'b1) begin
        r86_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r86_p <= r86;
        end
      end
    end
  assign rMSBits_86 = r86_p[209:104];
  assign x_86 = rMSBits_86;
  assign rMSBit_85 = r86_p[209];
  assign rMSBitneg_85 =  ~ rMSBit_85;
  assign switch_compare_1_89 = rMSBitneg_85 > 1'b0;

  assign d_neg_262 = {d86_p[105], d86_p};
  assign d_neg_in0_87 =  - (d_neg_262);
  assign d_neg_263 = d_neg_in0_87[105:0];
  assign y_171 = (switch_compare_1_89 == 1'b0 ? d86_p :
              d_neg_263);
  assign temp_88 = x_86 + y_171;
  assign rMSBNextBits_86 = temp_88[104:0];
  assign rLSBits_86 = r86_p[103:0];
  assign tempSignBit_86 = temp_88[104];
  assign qBit_86 =  ~ tempSignBit_86;
  assign rNextTemp_86 = {rMSBNextBits_86, rLSBits_86, qBit_86};
  assign r87 = rNextTemp_86;
  always_ff @(posedge clk)
    begin : r_reg_86_process
      if (reset == 1'b1) begin
        r87_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r87_p <= r87;
        end
      end
    end
  assign rMSBits_87 = r87_p[209:104];
  assign x_87 = rMSBits_87;
  assign rMSBit_86 = r87_p[209];
  assign rMSBitneg_86 =  ~ rMSBit_86;
  assign switch_compare_1_90 = rMSBitneg_86 > 1'b0;

  assign d_neg_265 = {d87_p[105], d87_p};
  assign d_neg_in0_88 =  - (d_neg_265);
  assign d_neg_266 = d_neg_in0_88[105:0];
  assign y_173 = (switch_compare_1_90 == 1'b0 ? d87_p :
              d_neg_266);
  assign temp_89 = x_87 + y_173;
  assign rMSBNextBits_87 = temp_89[104:0];
  assign rLSBits_87 = r87_p[103:0];
  assign tempSignBit_87 = temp_89[104];
  assign qBit_87 =  ~ tempSignBit_87;
  assign rNextTemp_87 = {rMSBNextBits_87, rLSBits_87, qBit_87};
  assign r88 = rNextTemp_87;
  always_ff @(posedge clk)
    begin : r_reg_87_process
      if (reset == 1'b1) begin
        r88_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r88_p <= r88;
        end
      end
    end
  assign rMSBits_88 = r88_p[209:104];
  assign x_88 = rMSBits_88;
  assign rMSBit_87 = r88_p[209];
  assign rMSBitneg_87 =  ~ rMSBit_87;
  assign switch_compare_1_91 = rMSBitneg_87 > 1'b0;

  assign d_neg_268 = {d88_p[105], d88_p};
  assign d_neg_in0_89 =  - (d_neg_268);
  assign d_neg_269 = d_neg_in0_89[105:0];
  assign y_175 = (switch_compare_1_91 == 1'b0 ? d88_p :
              d_neg_269);
  assign temp_90 = x_88 + y_175;
  assign rMSBNextBits_88 = temp_90[104:0];
  assign rLSBits_88 = r88_p[103:0];
  assign tempSignBit_88 = temp_90[104];
  assign qBit_88 =  ~ tempSignBit_88;
  assign rNextTemp_88 = {rMSBNextBits_88, rLSBits_88, qBit_88};
  assign r89 = rNextTemp_88;
  always_ff @(posedge clk)
    begin : r_reg_88_process
      if (reset == 1'b1) begin
        r89_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r89_p <= r89;
        end
      end
    end
  assign rMSBits_89 = r89_p[209:104];
  assign x_89 = rMSBits_89;
  assign rMSBit_88 = r89_p[209];
  assign rMSBitneg_88 =  ~ rMSBit_88;
  assign switch_compare_1_92 = rMSBitneg_88 > 1'b0;

  assign d_neg_271 = {d89_p[105], d89_p};
  assign d_neg_in0_90 =  - (d_neg_271);
  assign d_neg_272 = d_neg_in0_90[105:0];
  assign y_177 = (switch_compare_1_92 == 1'b0 ? d89_p :
              d_neg_272);
  assign temp_91 = x_89 + y_177;
  assign rMSBNextBits_89 = temp_91[104:0];
  assign rLSBits_89 = r89_p[103:0];
  assign tempSignBit_89 = temp_91[104];
  assign qBit_89 =  ~ tempSignBit_89;
  assign rNextTemp_89 = {rMSBNextBits_89, rLSBits_89, qBit_89};
  assign r90 = rNextTemp_89;
  always_ff @(posedge clk)
    begin : r_reg_89_process
      if (reset == 1'b1) begin
        r90_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r90_p <= r90;
        end
      end
    end
  assign rMSBits_90 = r90_p[209:104];
  assign x_90 = rMSBits_90;
  assign rMSBit_89 = r90_p[209];
  assign rMSBitneg_89 =  ~ rMSBit_89;
  assign switch_compare_1_93 = rMSBitneg_89 > 1'b0;

  assign d_neg_274 = {d90_p[105], d90_p};
  assign d_neg_in0_91 =  - (d_neg_274);
  assign d_neg_275 = d_neg_in0_91[105:0];
  assign y_179 = (switch_compare_1_93 == 1'b0 ? d90_p :
              d_neg_275);
  assign temp_92 = x_90 + y_179;
  assign rMSBNextBits_90 = temp_92[104:0];
  assign rLSBits_90 = r90_p[103:0];
  assign tempSignBit_90 = temp_92[104];
  assign qBit_90 =  ~ tempSignBit_90;
  assign rNextTemp_90 = {rMSBNextBits_90, rLSBits_90, qBit_90};
  assign r91 = rNextTemp_90;
  always_ff @(posedge clk)
    begin : r_reg_90_process
      if (reset == 1'b1) begin
        r91_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r91_p <= r91;
        end
      end
    end
  assign rMSBits_91 = r91_p[209:104];
  assign x_91 = rMSBits_91;
  assign rMSBit_90 = r91_p[209];
  assign rMSBitneg_90 =  ~ rMSBit_90;
  assign switch_compare_1_94 = rMSBitneg_90 > 1'b0;

  assign d_neg_277 = {d91_p[105], d91_p};
  assign d_neg_in0_92 =  - (d_neg_277);
  assign d_neg_278 = d_neg_in0_92[105:0];
  assign y_181 = (switch_compare_1_94 == 1'b0 ? d91_p :
              d_neg_278);
  assign temp_93 = x_91 + y_181;
  assign rMSBNextBits_91 = temp_93[104:0];
  assign rLSBits_91 = r91_p[103:0];
  assign tempSignBit_91 = temp_93[104];
  assign qBit_91 =  ~ tempSignBit_91;
  assign rNextTemp_91 = {rMSBNextBits_91, rLSBits_91, qBit_91};
  assign r92 = rNextTemp_91;
  always_ff @(posedge clk)
    begin : r_reg_91_process
      if (reset == 1'b1) begin
        r92_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r92_p <= r92;
        end
      end
    end
  assign rMSBits_92 = r92_p[209:104];
  assign x_92 = rMSBits_92;
  assign rMSBit_91 = r92_p[209];
  assign rMSBitneg_91 =  ~ rMSBit_91;
  assign switch_compare_1_95 = rMSBitneg_91 > 1'b0;

  assign d_neg_280 = {d92_p[105], d92_p};
  assign d_neg_in0_93 =  - (d_neg_280);
  assign d_neg_281 = d_neg_in0_93[105:0];
  assign y_183 = (switch_compare_1_95 == 1'b0 ? d92_p :
              d_neg_281);
  assign temp_94 = x_92 + y_183;
  assign rMSBNextBits_92 = temp_94[104:0];
  assign rLSBits_92 = r92_p[103:0];
  assign tempSignBit_92 = temp_94[104];
  assign qBit_92 =  ~ tempSignBit_92;
  assign rNextTemp_92 = {rMSBNextBits_92, rLSBits_92, qBit_92};
  assign r93 = rNextTemp_92;
  always_ff @(posedge clk)
    begin : r_reg_92_process
      if (reset == 1'b1) begin
        r93_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r93_p <= r93;
        end
      end
    end
  assign rMSBits_93 = r93_p[209:104];
  assign x_93 = rMSBits_93;
  assign rMSBit_92 = r93_p[209];
  assign rMSBitneg_92 =  ~ rMSBit_92;
  assign switch_compare_1_96 = rMSBitneg_92 > 1'b0;

  assign d_neg_283 = {d93_p[105], d93_p};
  assign d_neg_in0_94 =  - (d_neg_283);
  assign d_neg_284 = d_neg_in0_94[105:0];
  assign y_185 = (switch_compare_1_96 == 1'b0 ? d93_p :
              d_neg_284);
  assign temp_95 = x_93 + y_185;
  assign rMSBNextBits_93 = temp_95[104:0];
  assign rLSBits_93 = r93_p[103:0];
  assign tempSignBit_93 = temp_95[104];
  assign qBit_93 =  ~ tempSignBit_93;
  assign rNextTemp_93 = {rMSBNextBits_93, rLSBits_93, qBit_93};
  assign r94 = rNextTemp_93;
  always_ff @(posedge clk)
    begin : r_reg_93_process
      if (reset == 1'b1) begin
        r94_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r94_p <= r94;
        end
      end
    end
  assign rMSBits_94 = r94_p[209:104];
  assign x_94 = rMSBits_94;
  assign rMSBit_93 = r94_p[209];
  assign rMSBitneg_93 =  ~ rMSBit_93;
  assign switch_compare_1_97 = rMSBitneg_93 > 1'b0;

  assign d_neg_286 = {d94_p[105], d94_p};
  assign d_neg_in0_95 =  - (d_neg_286);
  assign d_neg_287 = d_neg_in0_95[105:0];
  assign y_187 = (switch_compare_1_97 == 1'b0 ? d94_p :
              d_neg_287);
  assign temp_96 = x_94 + y_187;
  assign rMSBNextBits_94 = temp_96[104:0];
  assign rLSBits_94 = r94_p[103:0];
  assign tempSignBit_94 = temp_96[104];
  assign qBit_94 =  ~ tempSignBit_94;
  assign rNextTemp_94 = {rMSBNextBits_94, rLSBits_94, qBit_94};
  assign r95 = rNextTemp_94;
  always_ff @(posedge clk)
    begin : r_reg_94_process
      if (reset == 1'b1) begin
        r95_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r95_p <= r95;
        end
      end
    end
  assign rMSBits_95 = r95_p[209:104];
  assign x_95 = rMSBits_95;
  assign rMSBit_94 = r95_p[209];
  assign rMSBitneg_94 =  ~ rMSBit_94;
  assign switch_compare_1_98 = rMSBitneg_94 > 1'b0;

  assign d_neg_289 = {d95_p[105], d95_p};
  assign d_neg_in0_96 =  - (d_neg_289);
  assign d_neg_290 = d_neg_in0_96[105:0];
  assign y_189 = (switch_compare_1_98 == 1'b0 ? d95_p :
              d_neg_290);
  assign temp_97 = x_95 + y_189;
  assign rMSBNextBits_95 = temp_97[104:0];
  assign rLSBits_95 = r95_p[103:0];
  assign tempSignBit_95 = temp_97[104];
  assign qBit_95 =  ~ tempSignBit_95;
  assign rNextTemp_95 = {rMSBNextBits_95, rLSBits_95, qBit_95};
  assign r96 = rNextTemp_95;
  always_ff @(posedge clk)
    begin : r_reg_95_process
      if (reset == 1'b1) begin
        r96_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r96_p <= r96;
        end
      end
    end
  assign rMSBits_96 = r96_p[209:104];
  assign x_96 = rMSBits_96;
  assign rMSBit_95 = r96_p[209];
  assign rMSBitneg_95 =  ~ rMSBit_95;
  assign switch_compare_1_99 = rMSBitneg_95 > 1'b0;

  assign d_neg_292 = {d96_p[105], d96_p};
  assign d_neg_in0_97 =  - (d_neg_292);
  assign d_neg_293 = d_neg_in0_97[105:0];
  assign y_191 = (switch_compare_1_99 == 1'b0 ? d96_p :
              d_neg_293);
  assign temp_98 = x_96 + y_191;
  assign rMSBNextBits_96 = temp_98[104:0];
  assign rLSBits_96 = r96_p[103:0];
  assign tempSignBit_96 = temp_98[104];
  assign qBit_96 =  ~ tempSignBit_96;
  assign rNextTemp_96 = {rMSBNextBits_96, rLSBits_96, qBit_96};
  assign r97 = rNextTemp_96;
  always_ff @(posedge clk)
    begin : r_reg_96_process
      if (reset == 1'b1) begin
        r97_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r97_p <= r97;
        end
      end
    end
  assign rMSBits_97 = r97_p[209:104];
  assign x_97 = rMSBits_97;
  assign rMSBit_96 = r97_p[209];
  assign rMSBitneg_96 =  ~ rMSBit_96;
  assign switch_compare_1_100 = rMSBitneg_96 > 1'b0;

  assign d_neg_295 = {d97_p[105], d97_p};
  assign d_neg_in0_98 =  - (d_neg_295);
  assign d_neg_296 = d_neg_in0_98[105:0];
  assign y_193 = (switch_compare_1_100 == 1'b0 ? d97_p :
              d_neg_296);
  assign temp_99 = x_97 + y_193;
  assign rMSBNextBits_97 = temp_99[104:0];
  assign rLSBits_97 = r97_p[103:0];
  assign tempSignBit_97 = temp_99[104];
  assign qBit_97 =  ~ tempSignBit_97;
  assign rNextTemp_97 = {rMSBNextBits_97, rLSBits_97, qBit_97};
  assign r98 = rNextTemp_97;
  always_ff @(posedge clk)
    begin : r_reg_97_process
      if (reset == 1'b1) begin
        r98_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r98_p <= r98;
        end
      end
    end
  assign rMSBits_98 = r98_p[209:104];
  assign x_98 = rMSBits_98;
  assign rMSBit_97 = r98_p[209];
  assign rMSBitneg_97 =  ~ rMSBit_97;
  assign switch_compare_1_101 = rMSBitneg_97 > 1'b0;

  assign d_neg_298 = {d98_p[105], d98_p};
  assign d_neg_in0_99 =  - (d_neg_298);
  assign d_neg_299 = d_neg_in0_99[105:0];
  assign y_195 = (switch_compare_1_101 == 1'b0 ? d98_p :
              d_neg_299);
  assign temp_100 = x_98 + y_195;
  assign rMSBNextBits_98 = temp_100[104:0];
  assign rLSBits_98 = r98_p[103:0];
  assign tempSignBit_98 = temp_100[104];
  assign qBit_98 =  ~ tempSignBit_98;
  assign rNextTemp_98 = {rMSBNextBits_98, rLSBits_98, qBit_98};
  assign r99 = rNextTemp_98;
  always_ff @(posedge clk)
    begin : r_reg_98_process
      if (reset == 1'b1) begin
        r99_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r99_p <= r99;
        end
      end
    end
  assign rMSBits_99 = r99_p[209:104];
  assign x_99 = rMSBits_99;
  assign rMSBit_98 = r99_p[209];
  assign rMSBitneg_98 =  ~ rMSBit_98;
  assign switch_compare_1_102 = rMSBitneg_98 > 1'b0;

  assign d_neg_301 = {d99_p[105], d99_p};
  assign d_neg_in0_100 =  - (d_neg_301);
  assign d_neg_302 = d_neg_in0_100[105:0];
  assign y_197 = (switch_compare_1_102 == 1'b0 ? d99_p :
              d_neg_302);
  assign temp_101 = x_99 + y_197;
  assign rMSBNextBits_99 = temp_101[104:0];
  assign rLSBits_99 = r99_p[103:0];
  assign tempSignBit_99 = temp_101[104];
  assign qBit_99 =  ~ tempSignBit_99;
  assign rNextTemp_99 = {rMSBNextBits_99, rLSBits_99, qBit_99};
  assign r100 = rNextTemp_99;
  always_ff @(posedge clk)
    begin : r_reg_99_process
      if (reset == 1'b1) begin
        r100_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r100_p <= r100;
        end
      end
    end
  assign rMSBits_100 = r100_p[209:104];
  assign x_100 = rMSBits_100;
  assign rMSBit_99 = r100_p[209];
  assign rMSBitneg_99 =  ~ rMSBit_99;
  assign switch_compare_1_103 = rMSBitneg_99 > 1'b0;

  assign d_neg_304 = {d100_p[105], d100_p};
  assign d_neg_in0_101 =  - (d_neg_304);
  assign d_neg_305 = d_neg_in0_101[105:0];
  assign y_199 = (switch_compare_1_103 == 1'b0 ? d100_p :
              d_neg_305);
  assign temp_102 = x_100 + y_199;
  assign rMSBNextBits_100 = temp_102[104:0];
  assign rLSBits_100 = r100_p[103:0];
  assign tempSignBit_100 = temp_102[104];
  assign qBit_100 =  ~ tempSignBit_100;
  assign rNextTemp_100 = {rMSBNextBits_100, rLSBits_100, qBit_100};
  assign r101 = rNextTemp_100;
  always_ff @(posedge clk)
    begin : r_reg_100_process
      if (reset == 1'b1) begin
        r101_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r101_p <= r101;
        end
      end
    end
  assign rMSBits_101 = r101_p[209:104];
  assign x_101 = rMSBits_101;
  assign rMSBit_100 = r101_p[209];
  assign rMSBitneg_100 =  ~ rMSBit_100;
  assign switch_compare_1_104 = rMSBitneg_100 > 1'b0;

  assign d_neg_307 = {d101_p[105], d101_p};
  assign d_neg_in0_102 =  - (d_neg_307);
  assign d_neg_308 = d_neg_in0_102[105:0];
  assign y_201 = (switch_compare_1_104 == 1'b0 ? d101_p :
              d_neg_308);
  assign temp_103 = x_101 + y_201;
  assign rMSBNextBits_101 = temp_103[104:0];
  assign rLSBits_101 = r101_p[103:0];
  assign tempSignBit_101 = temp_103[104];
  assign qBit_101 =  ~ tempSignBit_101;
  assign rNextTemp_101 = {rMSBNextBits_101, rLSBits_101, qBit_101};
  assign r102 = rNextTemp_101;
  always_ff @(posedge clk)
    begin : r_reg_101_process
      if (reset == 1'b1) begin
        r102_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r102_p <= r102;
        end
      end
    end
  assign rMSBits_102 = r102_p[209:104];
  assign x_102 = rMSBits_102;
  assign rMSBit_101 = r102_p[209];
  assign rMSBitneg_101 =  ~ rMSBit_101;
  assign switch_compare_1_105 = rMSBitneg_101 > 1'b0;

  assign d_neg_310 = {d102_p[105], d102_p};
  assign d_neg_in0_103 =  - (d_neg_310);
  assign d_neg_311 = d_neg_in0_103[105:0];
  assign y_203 = (switch_compare_1_105 == 1'b0 ? d102_p :
              d_neg_311);
  assign temp_104 = x_102 + y_203;
  assign rMSBNextBits_102 = temp_104[104:0];
  assign rLSBits_102 = r102_p[103:0];
  assign tempSignBit_102 = temp_104[104];
  assign qBit_102 =  ~ tempSignBit_102;
  assign rNextTemp_102 = {rMSBNextBits_102, rLSBits_102, qBit_102};
  assign r103 = rNextTemp_102;
  always_ff @(posedge clk)
    begin : r_reg_102_process
      if (reset == 1'b1) begin
        r103_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r103_p <= r103;
        end
      end
    end
  assign rMSBits_103 = r103_p[209:104];
  assign x_103 = rMSBits_103;
  assign rMSBit_102 = r103_p[209];
  assign rMSBitneg_102 =  ~ rMSBit_102;
  assign switch_compare_1_106 = rMSBitneg_102 > 1'b0;

  assign d_neg_313 = {d103_p[105], d103_p};
  assign d_neg_in0_104 =  - (d_neg_313);
  assign d_neg_314 = d_neg_in0_104[105:0];
  assign y_205 = (switch_compare_1_106 == 1'b0 ? d103_p :
              d_neg_314);
  assign temp_105 = x_103 + y_205;
  assign rMSBNextBits_103 = temp_105[104:0];
  assign rLSBits_103 = r103_p[103:0];
  assign tempSignBit_103 = temp_105[104];
  assign qBit_103 =  ~ tempSignBit_103;
  assign rNextTemp_103 = {rMSBNextBits_103, rLSBits_103, qBit_103};
  assign r104 = rNextTemp_103;
  always_ff @(posedge clk)
    begin : r_reg_103_process
      if (reset == 1'b1) begin
        r104_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r104_p <= r104;
        end
      end
    end
  assign rMSBits_104 = r104_p[209:104];
  assign x_104 = rMSBits_104;
  assign rMSBit_103 = r104_p[209];
  assign rMSBitneg_103 =  ~ rMSBit_103;
  assign switch_compare_1_107 = rMSBitneg_103 > 1'b0;

  assign d_neg_316 = {d104_p[105], d104_p};
  assign d_neg_in0_105 =  - (d_neg_316);
  assign d_neg_317 = d_neg_in0_105[105:0];
  assign y_207 = (switch_compare_1_107 == 1'b0 ? d104_p :
              d_neg_317);
  assign temp_106 = x_104 + y_207;
  assign rMSBNextBits_104 = temp_106[104:0];
  assign rLSBits_104 = r104_p[103:0];
  assign tempSignBit_104 = temp_106[104];
  assign qBit_104 =  ~ tempSignBit_104;
  assign rNextTemp_104 = {rMSBNextBits_104, rLSBits_104, qBit_104};
  assign r105 = rNextTemp_104;
  always_ff @(posedge clk)
    begin : r_reg_104_process
      if (reset == 1'b1) begin
        r105_p <= 210'sh00000000000000000000000000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          r105_p <= r105;
        end
      end
    end
  assign qTemp = r105_p[104:0];
  assign rMSBit_104 = r105_p[209];
  assign switch_compare_1_108 = rMSBit_104 > 1'b0;

  assign rMSBits_105 = r105_p[209:105];
  assign rMSBits_dtc = rMSBits_105;
  assign x_105 = {rMSBits_dtc[104], rMSBits_dtc};
  assign add_correct_out = x_105 + d105_p;
  assign corrected_rem_1 = (switch_compare_1_108 == 1'b0 ? x_105 :
              add_correct_out);
  assign switch_compare_1_109 = corrected_rem_1 != 106'sh000000000000000000000000000;

  assign qIsOdd = qTemp[0];
  assign scaled_rem = corrected_rem_1;
  assign nextRem = scaled_rem <<< 8'd1;
  assign d_p_dtc = d105_p;
  assign istie = nextRem == d_p_dtc;
  assign needsTiebreak = qIsOdd & istie;
  assign isgreater = nextRem > d_p_dtc;
  assign needsRounding = needsTiebreak | isgreater;
  assign incQ = qTemp + 105'h000000000000000000000000001;
  assign qRounded = (needsRounding == 1'b0 ? qTemp :
              incQ);
  assign qround_remNZ = (switch_compare_1_109 == 1'b0 ? qTemp :
              qRounded);
  assign q_post_calc = (switch_compare_1_2 == 1'b0 ? qTemp :
              qround_remNZ);
  assign qtempExt = {1'b0, q_post_calc};
  always_ff @(posedge clk)
    begin : qtempExt_p_process
      if (reset == 1'b1) begin
        qtempExt_p_1 <= 106'sh000000000000000000000000000;
      end
      else begin
        if (enb) begin
          qtempExt_p_1 <= qtempExt;
        end
      end
    end
  assign qin_neg_post_1 = {qtempExt_p_1[105], qtempExt_p_1};
  assign qin_neg_post_in0 =  - (qin_neg_post_1);
  assign qin_neg_post_2 = qin_neg_post_in0[105:0];
  assign qtemp_post = (switch_compare_1 == 1'b0 ? qtempExt_p_1 :
              qin_neg_post_2);
  assign sel1 = qtemp_post[105];
  assign sel0 = qtemp_post[104];
  assign sel = {sel1, sel0};
  assign ConstantSignalMax_1 = 106'sh1FFFFFFFFFFFFFFFFFFFFFFFFFF;
  assign ConstantSignalMin_1 = 106'sh000000000000000000000000000;
  always_comb begin
    case ( sel)
      2'b00 :
        begin
          qtempPost = qtemp_post;
        end
      2'b01 :
        begin
          qtempPost = ConstantSignalMax_1;
        end
      2'b10 :
        begin
          qtempPost = ConstantSignalMin_1;
        end
      default :
        begin
          qtempPost = qtemp_post;
        end
    endcase
  end
  assign qtempPost_1 = (initFlagenable_1 == 1'b0 ? ConstantSignal_1 :
              qtempPost);
  assign qtempPost_2 = qtempPost_1;
  assign qoutDTC = ((qtempPost_2[105] == 1'b0) && (qtempPost_2[104:72] != 33'h000000000) ? 72'hFFFFFFFFFFFFFFFFFF :
              (qtempPost_2[105] == 1'b1 ? 72'h000000000000000000 :
              qtempPost_2[71:0]));
  always_ff @(posedge clk)
    begin : q_process
      if (reset == 1'b1) begin
        quotient_1 <= 72'h000000000000000000;
      end
      else begin
        if (enb) begin
          quotient_1 <= qoutDTC;
        end
      end
    end
  assign quotient = (init_guard_true_2 == 1'b0 ? quotientinit_guard_default :
              quotient_1);

endmodule   
