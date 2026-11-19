module j16_level_test (
    output wire PWM1, PWM2, PWM3, PWM4, PWM5, PWM6,
    output wire RELCON, ENCON, F_Reset, PWM_EN, CTRL_EN,
    input wire QEPA, QEPB, QEPZ, ERRI, ERRU
);
    wire pl_clk0;
    design_1_wrapper ps_clock (.pl_clk0(pl_clk0));

    // Each reserved feedback line is asynchronous to the PS clock.
    (* ASYNC_REG = "TRUE" *) reg [4:0] feedback_meta;
    (* ASYNC_REG = "TRUE" *) reg [4:0] feedback_sync;
    always @(posedge pl_clk0) begin
        feedback_meta <= {ERRU, ERRI, QEPZ, QEPB, QEPA};
        feedback_sync <= feedback_meta;
    end

    (* KEEP = "TRUE" *) wire QEPA_sync, QEPB_sync, QEPZ_sync, ERRI_sync, ERRU_sync;
    assign {ERRU_sync, ERRI_sync, QEPZ_sync, QEPB_sync, QEPA_sync} = feedback_sync;

    j16_vio vio_j16 (
        .clk(pl_clk0),
        .probe_out0(PWM1), .probe_out1(PWM2), .probe_out2(PWM3),
        .probe_out3(PWM4), .probe_out4(PWM5), .probe_out5(PWM6),
        .probe_out6(RELCON), .probe_out7(ENCON), .probe_out8(F_Reset),
        .probe_out9(PWM_EN), .probe_out10(CTRL_EN),
        .probe_in0(QEPA_sync), .probe_in1(QEPB_sync), .probe_in2(QEPZ_sync),
        .probe_in3(ERRI_sync), .probe_in4(ERRU_sync)
    );
endmodule
