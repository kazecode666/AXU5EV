`timescale 1ns/1ps

// Duty-only reuse of m3_foc_scoreboard's accepted-clock frame schedule.
// ce_out is a fast clock enable. The external observation phase is fixed.
module ax04_foc_duty_tb;
  localparam integer FRAME_CLOCKS = 5000;
  localparam integer OUTPUT_PHASE = 314;
  localparam integer RECORD_BITS = 369;
  localparam integer MAX_FRAMES = 4096;
  logic clk = 0;
  logic reset = 1;
  logic clk_enable = 0;
  logic signed [31:0] ia, ib, ic, iq_ref, id_ref;
  logic signed [39:0] theta_e, omega_e;
  logic PI_Reset_EN;
  logic [31:0] Vdc;
  wire ce_out;
  wire [31:0] duty_u_cmd, duty_v_cmd, duty_w_cmd;
`ifdef AX05A_FOC_OBSERVATION
  wire signed [63:0] obs_id, obs_iq, obs_ud, obs_uq;
  logic [255:0] dq_vectors [0:MAX_FRAMES-1];
  integer dq_checks = 0;
`endif
  logic [RECORD_BITS-1:0] vectors [0:MAX_FRAMES-1];
  integer frames, row, fd;
  integer observed_frames = 0;
  integer checks = 0;
  integer bit_mismatch = 0;
  integer xz_count = 0;
  integer protocol_errors = 0;
  integer accepted_clocks = 0;
  string first_error = "";

  AX04_FOC_FOC_DUT dut (
    .clk(clk), .reset(reset), .reset_FOC_DUT_tc(1'b0),
    .clk_enable(clk_enable), .ia(ia), .ib(ib), .ic(ic),
    .theta_e(theta_e), .omega_e(omega_e), .iq_ref(iq_ref),
    .id_ref(id_ref), .PI_Reset_EN(PI_Reset_EN), .Vdc(Vdc),
    .ce_out(ce_out), .duty_u_cmd(duty_u_cmd),
    .duty_v_cmd(duty_v_cmd), .duty_w_cmd(duty_w_cmd)
`ifdef AX05A_FOC_OBSERVATION
    ,.obs_id(obs_id), .obs_iq(obs_iq), .obs_ud(obs_ud), .obs_uq(obs_uq)
`endif
  );
  always #10 clk = ~clk;

  task automatic compare_word(input integer frame, input string channel,
                              input logic [31:0] actual, expected);
    string detail;
    begin
      checks = checks + 1;
      detail = "";
      if ($isunknown(actual)) begin
        xz_count = xz_count + 1;
        detail = $sformatf("frame=%0d phase=%0d %s contains X/Z", frame, OUTPUT_PHASE, channel);
      end else if (actual !== expected) begin
        bit_mismatch = bit_mismatch + 1;
        detail = $sformatf("frame=%0d phase=%0d %s expected=%08h actual=%08h",
                           frame, OUTPUT_PHASE, channel, expected, actual);
      end
      if (detail != "" && first_error == "") begin
        first_error = detail;
        $display("AX04_FOC_FIRST_ERROR %s", detail);
      end
    end
  endtask

  task automatic run_frame(input integer frame);
    logic [31:0] expected_u, expected_v, expected_w;
    begin
      // Hold the row through all 5000 rising edges, using the same falling
      // edge setup and post-NBA phase314 observation as m3_foc_scoreboard.
      @(negedge clk);
      {ia, ib, ic, theta_e, omega_e, iq_ref, id_ref, PI_Reset_EN, Vdc,
       expected_u, expected_v, expected_w} = vectors[frame];
      reset = 0;
      clk_enable = 1;
      repeat (OUTPUT_PHASE) @(posedge clk);
      #1;
      observed_frames = observed_frames + 1;
      if (ce_out !== 1'b1) begin
        protocol_errors = protocol_errors + 1;
        if (first_error == "") first_error = $sformatf("frame=%0d fast clock enable absent at phase314", frame);
      end
      compare_word(frame, "u", duty_u_cmd, expected_u);
      compare_word(frame, "v", duty_v_cmd, expected_v);
      compare_word(frame, "w", duty_w_cmd, expected_w);
`ifdef AX05A_FOC_OBSERVATION
      if ($isunknown(dq_vectors[frame]) || {obs_id,obs_iq,obs_ud,obs_uq} !== dq_vectors[frame])
        $fatal(1, "AX05A_DQ_MISMATCH frame=%0d actual=%h expected=%h",
               frame, {obs_id,obs_iq,obs_ud,obs_uq}, dq_vectors[frame]);
      dq_checks += 4;
`endif
      repeat (FRAME_CLOCKS - OUTPUT_PHASE) @(posedge clk);
      #1;
      accepted_clocks = accepted_clocks + FRAME_CLOCKS;
      if ((frame + 1) % 100 == 0) begin
        $display("AX04_FOC_PROGRESS frames=%0d checks=%0d", frame + 1, checks);
        $fflush();
      end
    end
  endtask

  initial begin
    if (!$value$plusargs("frames=%d", frames)) $fatal(1, "Missing frame count");
    if (frames < 1 || frames > MAX_FRAMES) $fatal(1, "Invalid frame count");
    $readmemh("foc_vectors.hex", vectors, 0, frames - 1);
`ifdef AX05A_FOC_OBSERVATION
    $readmemh("foc_dq_vectors.hex", dq_vectors, 0, frames - 1);
`endif
    for (row = 0; row < frames; row = row + 1)
      if ($isunknown(vectors[row])) $fatal(1, "Missing vector frame %0d", row);
    // Match the existing accepted reset phase with CE disabled.
    repeat (2) begin
      @(negedge clk);
      {ia, ib, ic, theta_e, omega_e, iq_ref, id_ref, PI_Reset_EN, Vdc} = vectors[0][RECORD_BITS-1:96];
      reset = 1;
      clk_enable = 0;
      @(posedge clk);
      #1;
    end
    for (row = 0; row < frames; row = row + 1)
      run_frame(row);
`ifdef AX05A_FOC_OBSERVATION
    if(dq_checks != 4*frames) $fatal(1, "AX05A missing modeled dq observation");
    $display("AX05A_DQ_MODEL_PASS frames=%0d checks=%0d",frames,dq_checks);
`endif
    if (observed_frames != frames || checks != 3 * frames ||
        accepted_clocks != frames * FRAME_CLOCKS)
      protocol_errors = protocol_errors + 1;
    fd = $fopen("foc_rtl_result.json", "w");
    if (!fd) $fatal(1, "Cannot write result");
    $fwrite(fd, "{\n  \"status\": \"%s\",\n", (bit_mismatch + xz_count + protocol_errors) == 0 ? "PASS" : "FAIL");
    $fwrite(fd, "  \"frames\": %0d,\n  \"checks\": %0d,\n", observed_frames, checks);
    $fwrite(fd, "  \"bit_mismatch\": %0d,\n  \"xz_count\": %0d,\n", bit_mismatch, xz_count);
    $fwrite(fd, "  \"protocol_errors\": %0d,\n  \"accepted_clocks\": %0d,\n", protocol_errors, accepted_clocks);
    $fwrite(fd, "  \"frame_clocks\": 5000,\n  \"output_phase\": 314,\n");
    $fwrite(fd, "  \"first_error\": \"%s\"\n}\n", first_error);
    $fclose(fd);
    if (bit_mismatch + xz_count + protocol_errors != 0) $fatal(1, "AX04_FOC_RTL_FAIL");
    $display("AX04_FOC_RTL_PASS frames=%0d checks=%0d", observed_frames, checks);
    $finish;
  end

  initial begin
    #200000000;
    $fatal(1, "AX04 FOC testbench simulation timeout");
  end
endmodule
