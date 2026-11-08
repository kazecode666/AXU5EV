// Port/clock adapter ONLY. All current arithmetic/calibration is generated
// from AXU5EV_RealIO_NoPower/Current_Preprocess, not reimplemented here.
// Contract: 1 registered clk latency, clk_enable permanently enabled.
module ax03b1_current_adapter(
 input wire clk,rst,sample_strobe,
 input wire [15:0] raw_a,raw_b,
 input wire capture_valid_a,capture_valid_b,otr_a,otr_b,cal_en,cal_restart,config_apply,
 input wire [31:0] config_version,
 input wire signed [31:0] offset_seed_a_q16,offset_seed_b_q16,
 input wire manual_valid_a,manual_valid_b,
 input wire signed [31:0] gain_a_q24,gain_b_q24,
 input wire [7:0] cal_log2_n,
 output wire signed [31:0] ia_q24,ib_q24,ic_q24,offset_a_q16,offset_b_q16,
 output wire [15:0] cal_count_a,cal_count_b,
 output wire cal_done_a,cal_done_b,
 output wire [31:0] cal_version,
 output wire valid,clip,
 output wire [15:0] error,
 output wire result_strobe
);
 wire ce_unused;
 Current_Preprocess generated_current(.clk(clk),.reset(rst),.clk_enable(1'b1),
 .sample_strobe(sample_strobe),.raw_a(raw_a),.raw_b(raw_b),
 .capture_valid_a(capture_valid_a),.capture_valid_b(capture_valid_b),.otr_a(otr_a),.otr_b(otr_b),
 .cal_en(cal_en),.cal_restart(cal_restart),.config_apply(config_apply),.config_version(config_version),
 .offset_seed_a_q16(offset_seed_a_q16),.offset_seed_b_q16(offset_seed_b_q16),
 .manual_valid_a(manual_valid_a),.manual_valid_b(manual_valid_b),.gain_a_q24(gain_a_q24),
 .gain_b_q24(gain_b_q24),.cal_log2_N(cal_log2_n),.ce_out(ce_unused),
 .ia_q24(ia_q24),.ib_q24(ib_q24),.ic_q24(ic_q24),.offset_a_q16(offset_a_q16),.offset_b_q16(offset_b_q16),
 .cal_count_a(cal_count_a),.cal_count_b(cal_count_b),.cal_done_a(cal_done_a),.cal_done_b(cal_done_b),
 .cal_version(cal_version),.valid(valid),.clip(clip),.error(error),.result_strobe(result_strobe));
endmodule
