`timescale 1ns/1ps
// Standalone protocol verification: opaque payloads include deliberately invalid
// observation frames. No ADC/FOC/PWM or board-address assumption is made here.
module snapshot_tb #(parameter integer WORDS = 32);
  localparam integer LAST = 12 + 4*(WORDS-1);
  reg clk = 0;
  always #5 clk = !clk;
  reg rst_n = 0, publish_i = 0;
  reg [WORDS*32-1:0] payload_i = 0;
  reg [31:0] epoch_i = 32'h1001;
  reg [11:0] s_axi_araddr = 0;
  reg s_axi_arvalid = 0, s_axi_rready = 0;
  wire s_axi_arready, s_axi_rvalid;
  wire [31:0] s_axi_rdata;
  wire [1:0] s_axi_rresp;
  integer checks = 0;
  reg [31:0] data;
  reg [1:0] resp;

  // Start two publications before modulo wrap without forcing internal state.
  ax03b1_snapshot_axi #(.SNAP_WORDS(WORDS), .ADDR_WIDTH(12),
    .SEQ_RESET(32'hffff_fffd)) dut (.*);

  function automatic [31:0] pattern(input [31:0] tag, input integer word_no);
    pattern = tag ^ (32'h1020_4081 * word_no);
  endfunction

  task automatic check(input bit condition, input string description);
    begin
      checks = checks + 1;
      if (!condition) $fatal(1, "FAIL %s check=%0d t=%0t", description, checks, $time);
    end
  endtask

  task automatic publish(input [31:0] tag, input [31:0] epoch);
    begin
      @(negedge clk);
      for (integer w=0; w<WORDS; w=w+1) payload_i[w*32+:32] = pattern(tag,w);
      epoch_i = epoch;
      publish_i = 1;
      @(negedge clk);
      publish_i = 0;
    end
  endtask

  task automatic address(input [11:0] addr);
    begin
      @(negedge clk);
      s_axi_araddr = addr;
      s_axi_arvalid = 1;
      do @(posedge clk); while (!s_axi_arready);
      @(negedge clk);
      s_axi_arvalid = 0;
    end
  endtask

  task automatic response(output [31:0] value, output [1:0] result);
    begin
      while (!s_axi_rvalid) @(negedge clk);
      value = s_axi_rdata;
      result = s_axi_rresp;
      s_axi_rready = 1;
      @(negedge clk);
      s_axi_rready = 0;
    end
  endtask

  task automatic read_expect(input [11:0] addr, input [31:0] expected,
                             input [1:0] expected_resp, input string description);
    begin
      address(addr);
      response(data,resp);
      check(data === expected && resp === expected_resp, description);
    end
  endtask

  initial begin
    #100000;
    $fatal(1, "FAIL watchdog (test or slave did not make progress)");
  end

  initial begin
    repeat (3) @(negedge clk);
    check(!s_axi_arready && !s_axi_rvalid, "reset suppresses read acceptance/response");
    rst_n = 1;
    read_expect(0, 0, 2'b10, "BEGIN without publication explicitly fails");
    read_expect(12, 0, 2'b10, "payload without successful BEGIN fails");
    read_expect(4, 0, 2'b10, "metadata without successful BEGIN fails");

    publish(32'haaaa_0000, 32'h1001);
    read_expect(0, 32'hffff_fffe, 0, "first publication sequence");
    read_expect(4, 32'h1001, 0, "epoch frozen from publication");
    read_expect(8, 32'h3, 0, "header valid and first-after-reset flags");
    read_expect(12+4*9, pattern(32'haaaa_0000,9), 0, "out of order payload");
    publish(32'hbbbb_0000, 32'h1002);
    epoch_i = 32'hdead_beef;
    for (integer w=WORDS-2; w>=0; w=w-1)
      read_expect(12+4*w, pattern(32'haaaa_0000,w), 0, "frozen payload spans publication");
    read_expect(4, 32'h1001, 0, "frozen epoch ignores changed live input");
    read_expect(12+4*9, pattern(32'haaaa_0000,9), 0, "duplicate payload read stable");
    read_expect(13, 0, 2'b10, "misaligned read explicitly fails");
    read_expect(12+4*WORDS, 0, 2'b10, "out of range read explicitly fails");
    read_expect(8, 32'h3, 0, "illegal reads preserve freeze");

    // An unconsumed R response blocks all AR requests. Update the producer while
    // holding both RREADY low and a second ARVALID high; it must not re-BEGIN.
    address(12+4*3);
    check(s_axi_rvalid && s_axi_rdata === pattern(32'haaaa_0000,3), "response available");
    s_axi_araddr = 0;
    s_axi_arvalid = 1;
    for (integer n=0; n<8; n=n+1) begin
      @(negedge clk);
      check(!s_axi_arready && s_axi_rvalid && s_axi_rresp == 0 &&
            s_axi_rdata === pattern(32'haaaa_0000,3), "R backpressure stable; AR not accepted");
      for (integer w=0; w<WORDS; w=w+1) payload_i[w*32+:32] = pattern(32'hcccc_0000,w);
      publish_i = (n==1);
    end
    publish_i = 0;
    // Handshake R while AR stays asserted. This cycle still cannot accept AR.
    s_axi_rready = 1;
    @(posedge clk);
    check(!s_axi_arready, "no concurrent AR acceptance on old R handshake");
    @(negedge clk);
    s_axi_rready = 0;
    do @(posedge clk); while (!s_axi_arready);
    @(negedge clk);
    s_axi_arvalid = 0;
    response(data,resp);
    check(data === 0 && resp == 0, "held BEGIN accepted exactly once after stall; seq wraps");
    read_expect(4, 32'hdead_beef, 0, "captured epoch at wrapped publication");
    read_expect(8, 32'h5, 0, "wrap sticky flag; not first-after-reset");
    read_expect(12, 32'hcccc_0000, 0, "new BEGIN replaces old bank");

    // Last word releases only on RVALID/RREADY handshake, not on AR acceptance.
    address(LAST);
    for (integer n=0; n<4; n=n+1) begin
      @(negedge clk);
      check(s_axi_rvalid && !s_axi_arready &&
            s_axi_rdata === pattern(32'hcccc_0000,WORDS-1), "terminal response stalls stably");
    end
    response(data,resp);
    check(data === pattern(32'hcccc_0000,WORDS-1) && resp == 0, "terminal response content");
    read_expect(12, 0, 2'b10, "terminal response released bank");
    read_expect(LAST, 0, 2'b10, "duplicate terminal without BEGIN fails");

    // Same-edge BEGIN/publication is ordered before publication: no torn bank.
    @(negedge clk);
    for (integer w=0; w<WORDS; w=w+1) payload_i[w*32+:32] = pattern(32'hdddd_0000,w);
    epoch_i = 32'h1004;
    publish_i = 1;
    s_axi_araddr = 0;
    s_axi_arvalid = 1;
    @(posedge clk);
    check(s_axi_arready, "simultaneous publish and BEGIN accepted");
    @(negedge clk);
    publish_i = 0;
    s_axi_arvalid = 0;
    response(data,resp);
    check(data === 0 && resp == 0, "simultaneous BEGIN returns preceding publication");
    read_expect(12, 32'hcccc_0000, 0, "simultaneous BEGIN freezes preceding payload");
    read_expect(0, 1, 0, "repeat BEGIN refreshes latest");
    read_expect(12, 32'hdddd_0000, 0, "repeat BEGIN refreshes payload");

    // Quality is opaque: an invalid sensor/calibration payload must still publish.
    publish(0, 32'h1005);
    read_expect(0, 2, 0, "invalid-quality observation still has a snapshot");
    read_expect(8, 5, 0, "header valid is availability only, wrap flag stays sticky");
    read_expect(12, 0, 0, "zero/invalid-quality payload transported unchanged");

    // Reset cancels a stalled reply and frozen bank; new epoch is a caller label.
    address(12+4*1);
    @(negedge clk);
    rst_n = 0;
    repeat (2) @(negedge clk);
    check(!s_axi_rvalid && !s_axi_arready, "reset cancels stalled response");
    rst_n = 1;
    epoch_i = 32'h2001;
    read_expect(12, 0, 2'b10, "reset invalidates previously frozen bank");
    read_expect(0, 0, 2'b10, "reset invalidates latest observation");
    publish(32'h1111_2222,32'h2001);
    read_expect(0, 32'hffff_fffe, 0, "sequence reset is explicit, not persistent");
    read_expect(4, 32'h2001, 0, "new session epoch distinguishes sequence reuse");
    read_expect(8, 3, 0, "reset starts first flag and clears wrap history");
    read_expect(LAST, pattern(32'h1111_2222,WORDS-1), 0, "early terminal read intentionally releases");
    read_expect(4, 0, 2'b10, "metadata after early release fails");
    $display("SNAPSHOT_PASS checks=%0d words=%0d", checks, WORDS);
    $finish;
  end
endmodule
