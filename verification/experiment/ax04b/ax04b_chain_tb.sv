`timescale 1ns/1ps
// Use the build's actual observer, experiment HDL, IRQ/AXI block and PWM bridge.
// AXI master transactions stand in for R5. No target execution is simulated.
module ax04b_chain_tb #(parameter integer SELFTEST = 1);
    localparam [31:0] START_COUNT = 27000;
    localparam signed [63:0] TURN_Q32 = 64'sh6487ed511;
    localparam signed [63:0] RAW_THETA_Q32 = (64'sd27000*64'sd943231700270+64'sd524288) >>> 20;
    localparam signed [39:0] EXPECTED_BIASED_THETA = RAW_THETA_Q32 + 64'sh1_0000_0000 - TURN_Q32;
    localparam [31:0] REFERENCE_ID = 32'd4194304, REFERENCE_IQ = -32'd1677722;
    localparam [31:0] OMEGA = 32'd2097152;
    reg clk=0, pwm_clk=0;
    always #10 clk=~clk;
    initial begin #5; forever #5 pwm_clk=~pwm_clk; end
    reg rst_n=0, locked=0, erri_n=1, erru_n=1;
    wire irq, p0, frame_publish, fast_fault, invalidate, inhibit, ref_valid, armed, ctrl_enable;
    wire [31:0] p0_id;
    wire [287:0] frame;
    wire [255:0] active_ref;
    wire pwm_stop, pwm_enable, drive_rel, drive_en, ctrl_pin, f_reset_n, adc_clock, anchor;
    wire auto_valid, auto_ready, auto_inhibit, auto_online;
    wire [38:0] auto_compare;
    wire [31:0] auto_seq, applied_seq;
    wire [2:0] high, low, j16_high, j16_low;

    reg [11:0] adc_addr=0, rt_addr=0, rt_read_addr=0;
    reg [31:0] adc_wdata=0, rt_wdata=0;
    reg adc_awvalid=0, adc_wvalid=0, rt_awvalid=0, rt_wvalid=0, rt_arvalid=0;
    wire adc_awready, adc_wready, adc_bvalid, rt_awready, rt_wready, rt_bvalid, rt_arready, rt_rvalid;
    wire [1:0] adc_bresp, rt_bresp, rt_rresp;
    wire [31:0] rt_rdata;

    ax03b3_adc_observer #(.ENCODER_FEEDBACK(1), .TEST_INPUT(SELFTEST), .TEST_ABZ(SELFTEST),
        .AUTO_CONTROL(1), .AX04B(1), .ENCODER_INITIAL_COUNT(START_COUNT)) adc (
        .s_axi_aclk(clk), .s_axi_aresetn(rst_n),
        .adc_data_a_i(12'd2000), .adc_data_b_i(12'd2100), .adc_otr_a_i(1'b0), .adc_otr_b_i(1'b0),
        .abz_a_i(1'b0), .abz_b_i(1'b0), .abz_z_i(1'b0), .adc_clk_a_o(adc_clock), .pwm_anchor_o(anchor),
        .auto_valid_o(auto_valid), .auto_compare_o(auto_compare), .auto_seq_o(auto_seq), .auto_inhibit_o(auto_inhibit),
        .auto_ready_i(auto_ready), .auto_online_i(auto_online), .auto_applied_seq_i(applied_seq),
        .ax04b_locked_i(locked), .ax04b_erri_n_i(erri_n), .ax04b_erru_n_i(erru_n),
        .ax04b_ctrl_enable_i(ctrl_enable), .ax04b_ref_valid_i(ref_valid), .ax04b_inhibit_i(inhibit),
        .ax04b_reference_i(active_ref), .ax04b_p0_o(p0), .ax04b_frame_o(frame_publish), .ax04b_fault_o(fast_fault),
        .ax04b_invalidate_o(invalidate), .ax04b_p0_id_o(p0_id), .ax04b_frame_data_o(frame),
        .ax04b_pwm_stop_o(pwm_stop), .ax04b_pwm_enable_o(pwm_enable), .ax04b_ctrl_enable_o(ctrl_pin),
        .ax04b_relcon_o(drive_rel), .ax04b_encon_o(drive_en), .ax04b_f_reset_n_o(f_reset_n),
        .s_axi_awaddr(adc_addr), .s_axi_awprot(3'd0), .s_axi_awvalid(adc_awvalid), .s_axi_awready(adc_awready),
        .s_axi_wdata(adc_wdata), .s_axi_wstrb(4'hf), .s_axi_wvalid(adc_wvalid), .s_axi_wready(adc_wready),
        .s_axi_bvalid(adc_bvalid), .s_axi_bready(1'b1), .s_axi_bresp(adc_bresp),
        .s_axi_araddr(12'd0), .s_axi_arprot(3'd0), .s_axi_arvalid(1'b0), .s_axi_rready(1'b1));

    ax04b_realtime_axi #(.SELFTEST(SELFTEST)) realtime_axi (
        .s_axi_aclk(clk), .s_axi_aresetn(rst_n),
        .frame_publish_i(frame_publish), .frame_data_i(frame), .p0_i(p0), .p0_sample_id_i(p0_id),
        .fast_fault_i(fast_fault), .invalidate_i(invalidate), .irq_o(irq), .active_reference_o(active_ref),
        .active_valid_o(ref_valid), .inhibit_o(inhibit), .armed_o(armed), .ctrl_enable_o(ctrl_enable),
        .s_axi_awaddr(rt_addr), .s_axi_awprot(3'd0), .s_axi_awvalid(rt_awvalid), .s_axi_awready(rt_awready),
        .s_axi_wdata(rt_wdata), .s_axi_wstrb(4'hf), .s_axi_wvalid(rt_wvalid), .s_axi_wready(rt_wready),
        .s_axi_bvalid(rt_bvalid), .s_axi_bready(1'b1), .s_axi_bresp(rt_bresp),
        .s_axi_araddr(rt_read_addr), .s_axi_arprot(3'd0), .s_axi_arvalid(rt_arvalid), .s_axi_arready(rt_arready),
        .s_axi_rdata(rt_rdata), .s_axi_rvalid(rt_rvalid), .s_axi_rresp(rt_rresp), .s_axi_rready(1'b1));

    pwm_config_bridge #(.AUTO_FOC(1)) bridge (
        .s_axi_aclk(clk), .s_axi_aresetn(rst_n), .pwm_clk(pwm_clk), .locked(locked), .adc_anchor(anchor),
        .fast_inhibit(pwm_stop), .j16_output_enable_i(pwm_enable), .j16_high_o(j16_high), .j16_low_o(j16_low),
        .auto_valid_i(auto_valid), .auto_compare_i(auto_compare), .auto_seq_i(auto_seq), .auto_inhibit_i(auto_inhibit),
        .auto_ready_o(auto_ready), .auto_applied_seq_o(applied_seq), .auto_online_o(auto_online), .high_o(high), .low_o(low),
        .s_axi_awaddr(12'd0), .s_axi_awprot(3'd0), .s_axi_awvalid(1'b0), .s_axi_wdata(32'd0),
        .s_axi_wstrb(4'hf), .s_axi_wvalid(1'b0), .s_axi_bready(1'b1),
        .s_axi_araddr(12'd0), .s_axi_arprot(3'd0), .s_axi_arvalid(1'b0), .s_axi_rready(1'b1));

    `define AX04B_FOC adc.auto_path.controller
    int checks=0, phase=0, initial_irqs=0, valid_irqs=0, fixed_captures=0, normal_captures=0, adoptions=0;
    int join_phase=-1, result_phase=-1, confirmation_phase=-1;
    string stage="reset";
    reg p0_seen=0;
    reg [31:0] sampled_id;
    reg [63:0] sampled_tick;
    reg [383:0] delivered;
    realtime sampled_at;

    task automatic check(input logic good, input string detail);
        if (good !== 1'b1) $fatal(1, "AX04B_CHAIN_FAIL %s t=%0t phase=%0d", detail, $time, phase);
        checks++;
    endtask

    function automatic [12:0] comparison(input logic [31:0] duty);
        logic [63:0] scaled;
        if(duty>=32'h40000000) return 13'd5000;
        scaled=64'(duty)*5000+64'd536870912;
        return scaled[42:30];
    endfunction

    always @(posedge clk) if (rst_n) begin
        if (p0) begin
            if (p0_seen) check(phase+1 == 5000 && p0_id-sampled_id == 500 && adc.tick-sampled_tick == 5000,
                "selected frame identities advance 500/5000");
            p0_seen=1; phase=0; sampled_id=p0_id; sampled_tick=adc.tick; sampled_at=$realtime;
        end else phase++;
        if (frame_publish) begin
            check(p0_seen && phase == 76, "early feedback register/IRQ at P76");
            check(frame[31:0] == sampled_id && frame[95:32] == sampled_tick && frame[127:96] == START_COUNT,
                "early bank carries same selected encoder count, id and 64-bit tick");
            check(frame[165] == (SELFTEST != 0), "TEST origin mode tags match");
            if (&frame[163:160]) valid_irqs++;
            else initial_irqs++;
            #0.001;
            check(irq, "RTL bank asserts level interrupt for valid AND invalid results");
        end
        if (adc.publish_strobe) begin
            if (join_phase < 0) join_phase=phase;
            check(phase > 76 && phase <= 127 && phase == join_phase, "stable angle/current join after early arrival");
        end
        if (`AX04B_FOC.tracking && `AX04B_FOC.sample_age == 126) begin
            check(phase == 127, "FOC packet frozen at P127");
            #0.001;
            if (`AX04B_FOC.capture_valid) begin
                check(`AX04B_FOC.capture_id == sampled_id && `AX04B_FOC.capture_tick == sampled_tick,
                    "FOC frame identity follows the paired sample");
                check(`AX04B_FOC.foc_id == REFERENCE_ID && `AX04B_FOC.foc_iq == REFERENCE_IQ &&
                    `AX04B_FOC.foc_vdc == 805306368, "exact A/Q24 reference and fixed voltage reach FOC");
                if (`AX04B_FOC.capture_ref_version == 1) begin
                    check(`AX04B_FOC.foc_theta == 0 && `AX04B_FOC.foc_omega == 0 && `AX04B_FOC.foc_pi,
                        "fixed angle and zero omega override live values; PI_Reset passes through");
                    fixed_captures++;
                end else if (`AX04B_FOC.capture_ref_version == 2) begin
                    check(`AX04B_FOC.foc_theta == EXPECTED_BIASED_THETA && `AX04B_FOC.foc_omega == OMEGA && !`AX04B_FOC.foc_pi,
                        "biased encoder angle wraps once, same packet carries measured omega and PI release");
                    normal_captures++;
                end else $fatal(1,"Unexpected usable reference version");
            end else check(`AX04B_FOC.foc_pi,"invalid sample cannot run FOC with PI release");
        end
        if (`AX04B_FOC.foc_result_pulse) begin
            if (result_phase < 0) result_phase=phase;
            check(phase >= 442 && phase <= 444 && phase == result_phase && !`AX04B_FOC.hold_violation,
                "continuous generated FOC results keep the frozen input phasing");
        end
        if (`AX04B_FOC.waiting_applied && applied_seq == sampled_id) begin
            confirmation_phase=phase;
            check(phase >= 2500 && phase <= 2504, "actual PWM adoption identity returns before timeout");
        end
    end

    reg previous_applied=0;
    always @(posedge pwm_clk) begin
        #0.001;
        if (rst_n) begin
            check({j16_high,j16_low,drive_rel,drive_en} == 0, "external outputs hard-disabled in the no-power profiles");
            check((high & low) == 0, "no same-leg overlap");
            if (bridge.applied && !previous_applied) begin
                check(bridge.phase == 0 && bridge.active_seq == sampled_id &&
                    ($realtime-sampled_at >= 49999.9) && ($realtime-sampled_at <= 50000.1),
                    "PWM applies this frame only on P2500 valley");
                check(bridge.active_compare == {comparison(`AX04B_FOC.core_dw), comparison(`AX04B_FOC.core_dv),
                    comparison(`AX04B_FOC.core_du)}, "same generated duty maps to all three actual compares");
                adoptions++;
            end
        end
        previous_applied=bridge.applied;
    end

    task automatic put(input logic rt, input logic [11:0] address, input logic [31:0] value);
        @(negedge clk);
        if (rt) begin
            check(rt_awready && rt_wready, "AXI realtime writer ready");
            rt_addr=address; rt_wdata=value; rt_awvalid=1; rt_wvalid=1;
        end else begin
            check(adc_awready && adc_wready, "AXI calibration writer ready");
            adc_addr=address; adc_wdata=value; adc_awvalid=1; adc_wvalid=1;
        end
        @(negedge clk);
        adc_awvalid=0; adc_wvalid=0; rt_awvalid=0; rt_wvalid=0;
        if (rt) begin wait(rt_bvalid); check(rt_bresp==0,"realtime AXI response"); end
        else begin wait(adc_bvalid); check(adc_bresp==0,"calibration AXI response"); end
        repeat(2) @(negedge clk);
    endtask

    task automatic read_rt(input logic [11:0] address, output logic [31:0] value);
        @(negedge clk);
        check(rt_arready,"AXI realtime read ready");
        rt_read_addr=address; rt_arvalid=1;
        @(negedge clk);
        rt_arvalid=0;
        check(rt_rvalid && rt_rresp==0,"AXI realtime read response");
        value=rt_rdata;
    endtask

    task automatic next_feedback(output logic [31:0] sequence_number, sample, quality);
        logic [31:0] tick_lo, tick_hi, count, adc_config;
        wait(irq);
        read_rt('h10, sequence_number); read_rt('h30, sample);
        read_rt('h34, tick_lo); read_rt('h38, tick_hi); read_rt('h3c, count);
        read_rt('h44, quality); read_rt('h4c, adc_config);
        check(sample == sampled_id && {tick_hi,tick_lo} == sampled_tick && count == START_COUNT,
            "complete early bank read through AXI");
        if (quality[1]) check(adc_config==7,"qualifying input belongs to explicitly applied ADC config");
    endtask

    task automatic submit(input logic [31:0] sample, version, flags);
        logic [31:0] receipt, applied_version, accepted_target;
        put(1,'h88,sample+500); put(1,'ha0,REFERENCE_ID); put(1,'ha4,REFERENCE_IQ);
        put(1,'ha8,OMEGA); put(1,'hac,0); put(1,'hb0,0); put(1,'hb4,1);
        put(1,'hb8,flags); put(1,'hbc,version); put(1,'h8c,32'h434f4d4d);
        read_rt('h28,receipt); read_rt('h18,applied_version); read_rt('h1c,accepted_target);
        check(receipt==1 && applied_version==version && accepted_target==sample+500,"accepted exact next-P0 packet");
    endtask

    reg [31:0] sequence_number, sample, quality, good_status;
    initial begin
        repeat(5) @(negedge clk);
        rst_n=1; locked=1;
        if (!SELFTEST) put(1,'h90,1);
        check(ctrl_pin == (SELFTEST == 0), "only REAL explicitly enables the input buffer");
        stage="first feedback";
        next_feedback(sequence_number,sample,quality);
        check(!quality[1],"unconfigured startup feedback is marked invalid before first scheduling interrupt");
        put(1,'h80,sequence_number);
        stage="calibration setup";
        put(0,'h100,0); put(0,'h104,0); put(0,'h108,65536); put(0,'h10c,65536);
        put(0,'h110,1); put(0,'h114,7); put(0,'h118,5);
        // Unapplied shadow state must not leak into accepted early frames.
        put(0,'h114,99);

        stage="wait for qualification";
        next_feedback(sequence_number,sample,quality);
        while (!(&quality[3:0])) begin
            put(1,'h80,sequence_number);
            next_feedback(sequence_number,sample,quality);
        end
        put(1,'h84,2); put(1,'h84,4);
        check(armed && !inhibit,"qualification allows explicit clear and arm");
        stage="fixed packet";
        submit(sample,1,32'h0f);
        put(1,'h80,sequence_number);
        next_feedback(sequence_number,sample,quality);
        check(ref_valid && active_ref[255:224]==1, "fixed packet actually adopted at P0");
        stage="normal packet";
        submit(sample,2,32'h0a);
        put(1,'h80,sequence_number);
        next_feedback(sequence_number,sample,quality);
        check(ref_valid && active_ref[255:224]==2, "normal packet actually adopted at P0");
        put(1,'h80,sequence_number);
        stage="PWM adoption";
        wait(applied_seq==sample && |{high,low});
        @(negedge clk);
        #2;
        if (SELFTEST) locked=0; else erri_n=0;
        #1;
        check(inhibit && pwm_stop && {high,low,j16_high,j16_low}==0, "fast inhibit acts before the next fabric clock");
        #1;
        if (SELFTEST) locked=1; else erri_n=1;
        repeat(5) @(negedge clk);
        check(!armed && inhibit && {high,low}==0, "removing fault cannot resurrect an old packet");
        read_rt('h0c,good_status);
        check(!good_status[5] && good_status[1], "checked transport remains no-overrun with latched fault");
        check(fixed_captures==1 && normal_captures==1 && adoptions==2 && initial_irqs>=2 && valid_irqs>=3,
            "both generated angle branches, phases and safety paths covered");
        $display("AX04B_CHAIN PASS mode=%0d checks=%0d invalid_irq=%0d valid_irq=%0d irq_phase=76 join=%0d result=%0d apply=2500 confirm=%0d fixed=%0d normal=%0d",
            SELFTEST,checks,initial_irqs,valid_irqs,join_phase,result_phase,confirmation_phase,fixed_captures,normal_captures);
        $finish;
    end
    initial begin
        #1_500_000;
        $fatal(1,"AX04B chain timeout %s checks=%0d early=%0d/%0d phase=%0d join=%0d result=%0d confirm=%0d captures=%0d/%0d adoptions=%0d irq=%b armed=%b online=%b applied=%0d frame_quality=%h",
            stage,checks,initial_irqs,valid_irqs,phase,join_phase,result_phase,confirmation_phase,
            fixed_captures,normal_captures,adoptions,irq,armed,auto_online,applied_seq,frame[191:160]);
    end
endmodule
