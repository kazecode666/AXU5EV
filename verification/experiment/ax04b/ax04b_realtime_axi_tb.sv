`timescale 1ns/1ps
module ax04b_realtime_axi_tb;
    localparam [31:0] COMMIT = 32'h434f4d4d;
    localparam integer FRAME = 512, GUARD = 16, TIMEOUT = 1024;
    logic clk = 0;
    always #5 clk = ~clk;
    logic rst_n, frame_publish, p0, fault, invalidate;
    logic [287:0] frame_data;
    logic [31:0] p0_id;
    logic [11:0] awaddr, araddr;
    logic awvalid, wvalid, bready, arvalid, rready;
    logic [31:0] wdata;
    logic [3:0] wstrb;
    wire awready, wready, bvalid, arready, rvalid;
    wire [1:0] bresp, rresp;
    wire [31:0] rdata, active_target;
    wire irq, inhibit, armed, active_valid, ctrl_enable;
    wire [255:0] active_ref;
    int checks = 0;

    ax04b_realtime_axi #(.FRAME_CYCLES(FRAME), .DEADLINE_GUARD_CYCLES(GUARD),
        .WATCHDOG_CYCLES(TIMEOUT), .SEQ_RESET(32'hffff_fffe)) dut (
        .s_axi_aclk(clk), .s_axi_aresetn(rst_n),
        .s_axi_awaddr(awaddr), .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_awprot(3'd0), .s_axi_arprot(3'd0),
        .s_axi_wdata(wdata), .s_axi_wstrb(wstrb), .s_axi_wvalid(wvalid), .s_axi_wready(wready),
        .s_axi_bvalid(bvalid), .s_axi_bready(bready), .s_axi_bresp(bresp),
        .s_axi_araddr(araddr), .s_axi_arvalid(arvalid), .s_axi_arready(arready),
        .s_axi_rdata(rdata), .s_axi_rresp(rresp), .s_axi_rvalid(rvalid), .s_axi_rready(rready),
        .frame_publish_i(frame_publish), .frame_data_i(frame_data), .p0_i(p0), .p0_sample_id_i(p0_id),
        .fast_fault_i(fault), .invalidate_i(invalidate), .irq_o(irq),
        .active_reference_o(active_ref), .active_valid_o(active_valid), .active_target_o(active_target),
        .inhibit_o(inhibit), .armed_o(armed), .ctrl_enable_o(ctrl_enable));

    task automatic check(input logic good, input string detail);
        if (good !== 1'b1) $fatal(1, "%s at %0t", detail, $time);
        checks++;
    endtask

    task automatic reset();
        @(negedge clk);
        rst_n = 0;
        awvalid = 0; wvalid = 0; bready = 0; arvalid = 0; rready = 0;
        awaddr = 0; araddr = 0; wdata = 0; wstrb = 0;
        frame_publish = 0; frame_data = 0; p0 = 0; p0_id = 0; fault = 0; invalidate = 0;
        repeat (3) @(negedge clk);
        rst_n = 1;
    endtask

    task automatic put(input logic [11:0] address, input logic [31:0] value,
        input logic [3:0] strobes = 4'hf, input logic [1:0] response = 0,
        input logic publish_during_write = 0);
        @(negedge clk);
        check(awready, "address ready");
        awaddr = address; awvalid = 1;
        @(negedge clk);
        awvalid = 0;
        check(!awready && wready && !bvalid, "separate AW and W storage");
        wdata = value; wstrb = strobes; wvalid = 1;
        @(negedge clk);
        wvalid = 0; frame_publish = publish_during_write;
        @(negedge clk);
        frame_publish = 0;
        check(bvalid && bresp == response, "write response");
        // A stalled response must not repeat a write or re-open AW/W.
        @(negedge clk);
        check(bvalid && bresp == response && !awready && !wready, "B channel stall stability");
        bready = 1;
        @(negedge clk);
        bready = 0;
    endtask

    task automatic expect_read(input logic [11:0] address, input logic [31:0] expected,
        input logic [31:0] mask = 32'hffff_ffff, input logic [1:0] response = 0);
        @(negedge clk);
        check(arready, "read ready");
        araddr = address; arvalid = 1;
        @(negedge clk);
        arvalid = 0;
        check(rvalid && !arready && rresp == response && (rdata & mask) == expected,
            $sformatf("read register %h expected %h observed %h", address, expected, rdata));
        repeat (2) @(negedge clk);
        check(rvalid && !arready && rresp == response && (rdata & mask) == expected,
            "R channel stall stability");
        rready = 1;
        @(negedge clk);
        rready = 0;
    endtask

    function automatic logic [287:0] frame(input logic [31:0] count, input logic [63:0] tick,
        input logic [31:0] quality = 15, input logic [31:0] errors = 0);
        return {errors, 32'd5, 32'd7, quality, 32'd11, count^32'h51a0, tick, count};
    endfunction

    task automatic publish(input logic [287:0] value);
        @(negedge clk);
        frame_data = value;
        frame_publish = 1;
        @(negedge clk);
        frame_publish = 0;
    endtask

    task automatic start_frame(input logic [31:0] sample);
        @(negedge clk);
        p0 = 1; p0_id = sample;
        @(negedge clk);
        p0 = 0;
    endtask

    task automatic shadow(input logic [31:0] target, input logic [31:0] version,
        input logic [31:0] flags, input logic [31:0] value = 8);
        put('h88, target);
        put('ha0, value);
        put('ha4, -32'd16);
        put('ha8, -32'd2);
        put('hac, '1);
        put('hb0, 32'h8000_0000);
        put('hb4, 0);
        put('hb8, flags);
        put('hbc, version);
    endtask

    initial begin
        reset();
        check(inhibit && !armed && !irq && !active_valid && !ctrl_enable, "safe reset");
        expect_read('h00, 32'h41584201);
        expect_read('h04, 1);
        expect_read('h08, 1000);
        expect_read('h30, 0);
        expect_read('h04+1, 0, '1, 2);
        put('h90, 1);
        check(ctrl_enable && inhibit, "CTRL_EN is independent of frame arm");
        put('h84, 1);
        check(!ctrl_enable && inhibit, "STOP disables buffer");

        // The first unqualified frame still schedules service. Block-by-block
        // reads see one old bank after new-event overrun and counter wrap.
        start_frame(32'hffff_fe0c);
        publish(frame(32'hffff_fe0c, 64'hffff_ffff_ffff_ec78, 32));
        check(irq, "invalid selected frame must assert IRQ");
        expect_read('h10, 32'hffff_ffff);
        publish(frame(32'hffff_fe0c, 64'hffff_ffff_ffff_ec78, 32));
        expect_read('h14, 0);
        put('h80, 0);
        check(irq, "stale ACK cannot clear interrupt");
        expect_read('h34, 32'hffff_ec78);
        expect_read('h38, 32'hffff_ffff);
        shadow(0, 0, 32'h0b);
        put('h8c, COMMIT);
        expect_read('h28, 6);
        check(!active_valid, "withheld feedback qualification blocks hazardous reference");
        frame_data = frame(0, 0);
        put('h80, 32'hffff_ffff, 4'hf, 0, 1);
        check(irq, "ACK and new publication on same edge retain interrupt");
        expect_read('h10, 0);
        expect_read('h30, 0);
        expect_read('h3c, 32'h51a0);
        expect_read('h44, 15);
        publish(frame(500, 5000));
        expect_read('h14, 1);
        expect_read('h0c, 32'h23, 32'h23);
        expect_read('h30, 0);
        expect_read('h34, 0);
        put('h80, 32'hffff_ffff);
        check(irq, "pre-wrap ACK cannot clear post-wrap pending");
        put('h80, 0);
        check(!irq, "exact ACK releases frozen bank");
        publish(frame(500, 5000, 0, 1));
        check(irq, "same identity changed to fault receives safety interrupt");
        expect_read('h50, 1);
        put('h80, 2);
        publish(frame(500, 5000, 0, 1) ^ (288'd1 << 128));
        check(irq, "same identity with a changed illegal count is visible to safety processing");
        expect_read('h40, 10);

        reset();
        start_frame(32'hffff_fe0c);
        publish(frame(32'hffff_fe0c, 64'hffff_ffff_ffff_ec78));
        put('h88, 0);
        put('ha0, 5, 4'h3, 2);
        put('h8c, COMMIT);
        expect_read('h28, 4);
        check(!active_valid && inhibit, "half-write cannot activate reference");
        shadow(0, 32'hffff_ffff, 32'h0b);
        put('h8c, COMMIT);
        expect_read('h28, 1);
        expect_read('h18, 32'hffff_ffff);
        expect_read('h1c, 0);
        check(!active_valid, "queue acceptance and P0 adoption are separate");
        shadow(0, 0, 32'h0b, 19);
        put('h8c, COMMIT);
        expect_read('h28, 3);
        expect_read('h18, 32'hffff_ffff);
        put('h80, 32'hffff_ffff);
        start_frame(0);
        check(active_valid && active_target == 0 && active_ref[255:224] == 32'hffff_ffff &&
            active_ref[31:0] == 8, "wrapped sample target adopts frozen original payload");
        expect_read('h20, 32'hffff_ffff);
        publish(frame(0, 0));
        shadow(500, 0, 32'h88);
        put('h8c, COMMIT);
        expect_read('h28, 1);
        put('h80, 0);
        start_frame(500);
        check(active_valid && active_target == 500 && active_ref[255:224] == 0,
            "transport version wrap is valid");
        publish(frame(500, 5000));
        shadow(1000, 0, 32'h88);
        put('h8c, COMMIT);
        expect_read('h28, 5);
        shadow(1000, 1, 32'h88);
        wait(dut.p0_age >= FRAME-GUARD);
        put('h8c, COMMIT);
        expect_read('h28, 2);
        put('h80, 1);
        start_frame(1000);
        check(!active_valid, "late packet cannot be applied on next P0");
        start_frame(1500);
        check(!active_valid, "late packet cannot slip to subsequent frame");

        reset();
        start_frame(0);
        publish(frame(0, 0));
        put('h84, 4);
        check(!armed && inhibit, "ARM requires explicit successful CLEAR");
        put('h84, 2);
        put('h84, 4);
        check(armed && !inhibit, "qualified CLEAR then explicit ARM");
        shadow(500, 1, 32'h0b);
        put('h8c, COMMIT);
        expect_read('h28, 1);
        put('h80, 32'hffff_ffff);
        start_frame(500);
        check(active_valid && armed && !inhibit, "authorized target adopted");
        #1 fault = 1;
        #1 check(inhibit, "asynchronous fast inhibit asserts before fabric edge");
        #1 fault = 0;
        repeat (4) @(negedge clk);
        check(!active_valid && !armed && inhibit, "sub-cycle fault remains latched after removal");
        put('h84, 4);
        check(!armed && inhibit, "re-arm attempt alone does not clear an independent fault");
        fault = 1;
        repeat (3) @(negedge clk);
        publish(frame(500, 5000, 0, 1));
        shadow(1000, 2, 32'h44);
        put('h8c, COMMIT);
        expect_read('h28, 1);
        start_frame(1000);
        check(active_valid && inhibit && active_ref[198] && !active_ref[193],
            "F_Reset-only reaches P0 while PWM stays independently inhibited");
        repeat (TIMEOUT+2) @(negedge clk);
        check(!active_valid && inhibit, "stopped P0 and stopped commits do not retain last packet");
        fault = 0;

        reset();
        start_frame(0);
        publish(frame(0, 0));
        put('h84, 2);
        put('h84, 4);
        check(armed && !inhibit, "prior to missing-packet P0");
        start_frame(500);
        check(!armed && inhibit && !active_valid, "missing next-P0 commit drops and latches arm");
        put('h80, 32'hffff_ffff);
        publish(frame(500, 5000));
        shadow(1000, 3, 32'h88);
        put('h8c, COMMIT);
        expect_read('h28, 1);
        start_frame(1100);
        check(!active_valid, "wrong boundary drops pending reference");
        start_frame(1000);
        check(!active_valid, "dropped packet never replays at its old timestamp");

        reset();
        start_frame(0);
        publish(frame(0, 0));
        shadow(500, 8, 32'h0b);
        put('h8c, COMMIT);
        expect_read('h28, 1);
        put('h8c, COMMIT);
        expect_read('h28, 4);
        start_frame(500);
        check(!active_valid && inhibit, "malformed commit cancels already frozen reference");

        reset();
        start_frame(0);
        publish(frame(0, 0));
        shadow(500, 8, 32'h0b);
        put('h8c, COMMIT);
        expect_read('h28, 1);
        invalidate = 1;
        start_frame(500);
        invalidate = 0;
        check(!active_valid && inhibit, "invalidation on adoption boundary vetoes queued reference");
        expect_read('h0c, 0, 32'h200);

        reset();
        start_frame(0);
        publish(frame(0, 0));
        shadow(500, 1, 32'h0b, 8388609);
        put('h8c, COMMIT);
        expect_read('h28, 4);
        shadow(500, 1, 32'h0b);
        put('ha4, -32'd5033166);
        put('h8c, COMMIT);
        expect_read('h28, 4);
        shadow(500, 1, 32'h0b);
        put('hb0, 32'h487ed511);
        put('hb4, 6);
        put('h8c, COMMIT);
        expect_read('h28, 4);
        shadow(500, 1, 32'h0b, 8388608);
        put('ha4, -32'd5033165);
        put('hb0, 32'h487ed510);
        put('hb4, 6);
        put('h8c, COMMIT);
        expect_read('h28, 1);

        $display("AX04B_REALTIME_AXI PASS checks=%0d", checks);
        $finish;
    end

    initial begin
        #100_000;
        $fatal(1, "test timed out");
    end
endmodule
