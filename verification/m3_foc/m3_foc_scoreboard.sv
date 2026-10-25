`timescale 1ns/1ps

// Independent file-driven checker for unmodified HDL Coder FOC_DUT.
// ce_out is a fast clock enable, NOT a control-frame valid signal.
// The checker owns a fixed accepted-clock schedule: 5000 clocks/frame,
// duty phase comes from the manifest-bound generated schedule; baseline274.
module m3_foc_scoreboard;
  localparam integer FRAME_CLOCKS = 5000;
  integer OUTPUT_PHASE = 274;
  localparam integer DEADLINE_CLOCKS = 2500;
  localparam integer RECORD_BITS = 657;
  localparam integer MAX_FRAMES = 8192;

  logic clk = 1'b0;
  logic reset = 1'b1;
  logic clk_enable = 1'b0;
  logic signed [31:0] ia, ib, ic;
  logic signed [39:0] theta_e, omega_e;
  logic signed [31:0] iq_ref, id_ref;
  logic PI_Reset_EN;
  logic [31:0] Vdc_V;
  wire ce_out;
  wire [31:0] duty_u_cmd, duty_v_cmd, duty_w_cmd;

  FOC_DUT dut (
    .clk(clk), .reset(reset), .reset_FOC_DUT_tc(1'b0),
    .clk_enable(clk_enable), .ia(ia), .ib(ib), .ic(ic),
    .theta_e(theta_e), .omega_e(omega_e), .iq_ref(iq_ref),
    .id_ref(id_ref), .PI_Reset_EN(PI_Reset_EN), .Vdc_V(Vdc_V),
    .ce_out(ce_out), .duty_u_cmd(duty_u_cmd),
    .duty_v_cmd(duty_v_cmd), .duty_w_cmd(duty_w_cmd)
  );

  logic [RECORD_BITS-1:0] vectors [0:MAX_FRAMES-1];
  string vector_path, result_path, case_name, mode;
  integer frames;
  integer negative_sample = 0;
  integer early_checks = 0;
  integer early_mismatch = 0;
  integer physical_cycle = 0;
  integer active_cycle = 0;
  integer observed_frames = 0;
  integer expected_frames = 0;
  integer state_rows = 0;
  integer state_values = 0;
  integer state_commit_checks = 0;
  integer bit_mismatch = 0;
  integer state_mismatch = 0;
  integer xz_count = 0;
  integer protocol_errors = 0;
  integer deadline_errors = 0;
  integer ce_disabled_cycles = 0;
  integer reset_cycles = 0;
  integer cancelled_frames = 0;
  integer epoch = 0;
  integer first_output_cycle = -1;
  integer last_output_cycle = -1;
  integer max_wall_latency = 0;
  integer frame_start_cycle = 0;
  integer pi_commits = 0;
  integer aw_commits = 0;
  integer oracle_count = 1;
  logic oracle_phase0 = 1'b0;
  logic oracle_phase1 = 1'b1;
  string first_error = "";
  integer result_fd;

  always #10 clk = ~clk;

  task automatic fail(input string detail);
    begin
      if (first_error == "") first_error = detail;
      if ((bit_mismatch + state_mismatch + xz_count + protocol_errors + deadline_errors) <= 20)
        $display("M3_ERROR case=%s mode=%s physical=%0d active=%0d epoch=%0d %s",
                 case_name, mode, physical_cycle, active_cycle, epoch, detail);
    end
  endtask

  task automatic unpack_record(
      input integer row,
      output logic [31:0] sample_id,
      output logic [31:0] in_ia, in_ib, in_ic,
      output logic [39:0] in_theta, in_omega,
      output logic [31:0] in_iq, in_id,
      output logic in_pi_reset,
      output logic [31:0] in_vdc,
      output logic [31:0] exp_u, exp_v, exp_w,
      output logic [63:0] exp_xd, exp_xq, exp_awd, exp_awq);
    begin
      {sample_id, in_ia, in_ib, in_ic, in_theta, in_omega,
       in_iq, in_id, in_pi_reset, in_vdc, exp_u, exp_v, exp_w,
       exp_xd, exp_xq, exp_awd, exp_awq} = vectors[row];
    end
  endtask

  task automatic compare_state(input string label_text,
                               input logic [63:0] observed,
                               input logic [63:0] expected);
    begin
      state_values = state_values + 1;
      if ($isunknown(observed)) begin
        xz_count = xz_count + 1;
        fail($sformatf("X/Z state %s", label_text));
      end else if (observed !== expected) begin
        state_mismatch = state_mismatch + 1;
        fail($sformatf("state %s expected=%016h observed=%016h", label_text, expected, observed));
      end
    end
  endtask

  // A tick samples pre-edge state after input/CE setup and checks post-edge
  // registers after NBA updates. Source old state is checked at the PI
  // consuming event, before the final edge of that row's 5000-clock frame.
  task automatic tick(input logic rst_value, input logic ce_value,
                      input integer row, input integer frame_phase,
                      input logic compare_data);
    logic [31:0] sid, a, b, c, iqr, idr, vdc;
    logic [39:0] theta, omega;
    logic pir;
    logic [31:0] eu, ev, ew;
    logic [63:0] xd, xq, awd, awq;
    logic [63:0] pre_xd, pre_xq, pre_awd, pre_awq;
    logic [63:0] next_xd, next_xq, next_awd, next_awq;
    logic pre_pi_enable, pre_aw_enable;
    logic [31:0] next_sid, na, nb, nc, niq, nid, nvdc;
    logic [39:0] nt, nw;
    logic npr;
    logic [31:0] neu, nev, new_;
    logic [63:0] nxd, nxq, nawd, nawq;
    integer wall_latency;
    begin
      unpack_record(row, sid, a, b, c, theta, omega, iqr, idr, pir,
                    vdc, eu, ev, ew, xd, xq, awd, awq);
      @(negedge clk);
      reset = rst_value;
      clk_enable = ce_value;
      ia = a; ib = b; ic = c; theta_e = theta; omega_e = omega;
      iq_ref = iqr; id_ref = idr; PI_Reset_EN = pir; Vdc_V = vdc;
      #1;
      pre_xd = dut.u_Id.x_d_z_out1;
      pre_xq = dut.u_Iq.x_q_z_out1;
      pre_awd = dut.u_dq_voltage_limiter.Unit_Delay_bypass_reg;
      pre_awq = dut.u_dq_voltage_limiter.Unit_Delay1_bypass_reg;
`ifdef M3_PI_COMMIT_NEXT_FRAME
      // Qualified one-fast-register boundary after the original state bypass.
      next_xd = dut.u_Id.x_d_z_out1_1;
      next_xq = dut.u_Iq.x_q_z_out1_1;
      pre_pi_enable = oracle_phase1 & ce_value;
`else
      next_xd = dut.u_Id.Reset_Integral_out1;
      next_xq = dut.u_Iq.Reset_Integral_out1;
      pre_pi_enable = oracle_phase0 & ce_value;
`endif
      next_awd = dut.u_dq_voltage_limiter.Subtract_out1_1;
      next_awq = dut.u_dq_voltage_limiter.Subtract1_out1_1;
      pre_aw_enable = oracle_phase1 & ce_value;

      if (compare_data && !rst_value && ce_value && frame_phase == FRAME_CLOCKS) begin
        if (oracle_count != 0 || oracle_phase0 !== 1'b1) begin
          protocol_errors = protocol_errors + 1;
          fail("old-state event is not the fixed PI commit boundary");
        end
        state_rows = state_rows + 1;
        compare_state("x_d_old@PI-pre-edge", pre_xd, xd);
        compare_state("x_q_old@PI-pre-edge", pre_xq, xq);
        compare_state("aw_d_old@PI-consumer", dut.dq_voltage_limiter_du_d_z, awd);
        compare_state("aw_q_old@PI-consumer", dut.dq_voltage_limiter_du_q_z, awq);
      end

      @(posedge clk);
      #1;
      physical_cycle = physical_cycle + 1;
      if (rst_value) begin
        reset_cycles = reset_cycles + 1;
        oracle_count = 1; oracle_phase0 = 1'b0; oracle_phase1 = 1'b1;
        if ({dut.u_Id.x_d_z_out1, dut.u_Iq.x_q_z_out1,
             dut.u_dq_voltage_limiter.Unit_Delay_bypass_reg,
             dut.u_dq_voltage_limiter.Unit_Delay1_bypass_reg} !== 256'b0) begin
          protocol_errors = protocol_errors + 1;
          fail("global synchronous reset did not clear PI/AW, including when CE=0");
        end
      end else if (ce_value) begin
        active_cycle = active_cycle + 1;
        oracle_phase0 = (oracle_count == FRAME_CLOCKS - 1);
        oracle_phase1 = (oracle_count == 0);
        if (oracle_count >= FRAME_CLOCKS - 1) oracle_count = 0;
        else oracle_count = oracle_count + 1;
        state_commit_checks = state_commit_checks + 4;
        if (dut.u_Id.x_d_z_out1 !== (pre_pi_enable ? next_xd : pre_xd) ||
            dut.u_Iq.x_q_z_out1 !== (pre_pi_enable ? next_xq : pre_xq)) begin
          protocol_errors = protocol_errors + 1;
          fail("PI registers changed outside their fixed commit, or committed wrong next signal");
        end
        if (dut.u_dq_voltage_limiter.Unit_Delay_bypass_reg !== (pre_aw_enable ? next_awd : pre_awd) ||
            dut.u_dq_voltage_limiter.Unit_Delay1_bypass_reg !== (pre_aw_enable ? next_awq : pre_awq)) begin
          protocol_errors = protocol_errors + 1;
          fail("AW registers changed outside their fixed commit, or committed wrong next signal");
        end
        if (pre_pi_enable) pi_commits = pi_commits + 1;
        if (pre_aw_enable) aw_commits = aw_commits + 1;
      end else begin
        ce_disabled_cycles = ce_disabled_cycles + 1;
        if ({dut.u_Id.x_d_z_out1, dut.u_Iq.x_q_z_out1,
             dut.u_dq_voltage_limiter.Unit_Delay_bypass_reg,
             dut.u_dq_voltage_limiter.Unit_Delay1_bypass_reg} !==
            {pre_xd, pre_xq, pre_awd, pre_awq}) begin
          protocol_errors = protocol_errors + 1;
          fail("PI/AW changed on a CE-disabled physical edge");
        end
      end

      if (dut.u_FOC_DUT_tc.count5000 !== oracle_count[12:0] ||
          dut.u_FOC_DUT_tc.phase_0 !== oracle_phase0 ||
          dut.u_FOC_DUT_tc.phase_1 !== oracle_phase1) begin
        protocol_errors = protocol_errors + 1;
        fail("timing controller disagrees with fixed independent counter/phase equations");
      end
      if (ce_out !== ce_value) begin
        protocol_errors = protocol_errors + 1;
        fail("ce_out must be the fast clock enable, not frame-valid");
      end

      if (compare_data && !rst_value && ce_value) begin
        if (frame_phase == 1 && row > 0) begin
          compare_state("aw_d_commit@next-frame-phase1", dut.u_dq_voltage_limiter.Unit_Delay_bypass_reg, awd);
          compare_state("aw_q_commit@next-frame-phase1", dut.u_dq_voltage_limiter.Unit_Delay1_bypass_reg, awq);
`ifdef M3_PI_COMMIT_NEXT_FRAME
          compare_state("x_d_commit@next-frame-phase1=source-old", dut.u_Id.x_d_z_out1, xd);
          compare_state("x_q_commit@next-frame-phase1=source-old", dut.u_Iq.x_q_z_out1, xq);
`endif
        end
        if (frame_phase == FRAME_CLOCKS && row + 1 < frames) begin
          unpack_record(row + 1, next_sid, na, nb, nc, nt, nw, niq,
                        nid, npr, nvdc, neu, nev, new_, nxd, nxq, nawd, nawq);
`ifndef M3_PI_COMMIT_NEXT_FRAME
          compare_state("x_d_commit=next-source-old", dut.u_Id.x_d_z_out1, nxd);
          compare_state("x_q_commit=next-source-old", dut.u_Iq.x_q_z_out1, nxq);
`endif
        end
        if (mode == "cycle_negative" && row == negative_sample && frame_phase == OUTPUT_PHASE - 1) begin
          // A real one-clock-early observation of changed data, not a
          // comparison between two copies of a phase configuration value.
          early_checks = early_checks + 3;
          $display("M3_EARLY_SAMPLE sample=%0d phase=%0d expected=%08h/%08h/%08h observed=%08h/%08h/%08h",
                   sid, frame_phase, eu, ev, ew, duty_u_cmd, duty_v_cmd, duty_w_cmd);
          if ($isunknown({duty_u_cmd, duty_v_cmd, duty_w_cmd})) begin
            xz_count = xz_count + 1;
            early_mismatch = early_mismatch + 1;
            fail($sformatf("X/Z one-clock-early output sample=%0d", sid));
          end else if ({duty_u_cmd, duty_v_cmd, duty_w_cmd} !== {eu, ev, ew}) begin
            bit_mismatch = bit_mismatch + 1;
            early_mismatch = early_mismatch + 1;
            fail($sformatf("one-clock-early output rejected sample=%0d expected=%08h/%08h/%08h observed=%08h/%08h/%08h",
                           sid, eu, ev, ew, duty_u_cmd, duty_v_cmd, duty_w_cmd));
          end
        end
        if (frame_phase == OUTPUT_PHASE) begin
          observed_frames = observed_frames + 1;
          if (first_output_cycle < 0) first_output_cycle = physical_cycle;
          last_output_cycle = physical_cycle;
          if (mode == "bit_negative" && observed_frames == 1) eu = eu ^ 32'h1;
          if ($isunknown({duty_u_cmd, duty_v_cmd, duty_w_cmd})) begin
            xz_count = xz_count + 1;
            fail($sformatf("X/Z valid duty sample=%0d", sid));
          end else if ({duty_u_cmd, duty_v_cmd, duty_w_cmd} !== {eu, ev, ew}) begin
            bit_mismatch = bit_mismatch + 1;
            fail($sformatf("duty sample=%0d expected=%08h/%08h/%08h observed=%08h/%08h/%08h",
                           sid, eu, ev, ew, duty_u_cmd, duty_v_cmd, duty_w_cmd));
          end
          wall_latency = physical_cycle - frame_start_cycle + 1;
          if (wall_latency > max_wall_latency) max_wall_latency = wall_latency;
          if (wall_latency > DEADLINE_CLOCKS) begin
            deadline_errors = deadline_errors + 1;
            fail($sformatf("deadline sample=%0d latency_clocks=%0d deadline=%0d", sid, wall_latency, DEADLINE_CLOCKS));
          end
        end
      end
    end
  endtask

  task automatic run_frame(input integer row, input integer last_phase,
                           input logic allow_pauses);
    integer phase;
    integer pause_length;
    integer p;
    begin
      frame_start_cycle = physical_cycle + 1;
      for (phase = 1; phase <= last_phase; phase = phase + 1) begin
        pause_length = 0;
        if (allow_pauses && row == 0 && phase == 100) pause_length = 7;
        if (allow_pauses && row == 1 && phase == 4999) pause_length = 3;
        if (allow_pauses && row == 2 && phase == 1) pause_length = 11;
        // When stalled before the next frame's first accepted edge, retain
        // the preceding input row until CE resumes, then establish new input.
        for (p = 0; p < pause_length; p = p + 1)
          tick(1'b0, 1'b0, (phase == 1 && row > 0) ? row - 1 : row, phase, 1'b0);
        tick(1'b0, 1'b1, row, phase, 1'b1);
      end
    end
  endtask

  task automatic write_result;
    integer errors;
    integer checks;
    begin
      errors = bit_mismatch + state_mismatch + xz_count + protocol_errors + deadline_errors;
      checks = 3 * observed_frames + state_values + state_commit_checks + early_checks;
      result_fd = $fopen(result_path, "w");
      if (!result_fd) $fatal(1, "Cannot write result %s", result_path);
      $fwrite(result_fd, "{\n  \"case\": \"%s\",\n  \"mode\": \"%s\",\n", case_name, mode);
      $fwrite(result_fd, "  \"status\": \"%s\",\n", errors == 0 ? "PASS" : "FAIL");
      $fwrite(result_fd, "  \"expected_frames\": %0d,\n  \"observed_frames\": %0d,\n", expected_frames, observed_frames);
      $fwrite(result_fd, "  \"state_rows\": %0d,\n  \"state_values\": %0d,\n  \"state_commit_checks\": %0d,\n", state_rows, state_values, state_commit_checks);
      $fwrite(result_fd, "  \"checks\": %0d,\n", checks);
      $fwrite(result_fd, "  \"negative_sample\": %0d,\n  \"early_checks\": %0d,\n  \"early_mismatch\": %0d,\n", negative_sample, early_checks, early_mismatch);
      $fwrite(result_fd, "  \"bit_mismatch\": %0d,\n  \"state_mismatch\": %0d,\n  \"xz_count\": %0d,\n", bit_mismatch, state_mismatch, xz_count);
      $fwrite(result_fd, "  \"protocol_errors\": %0d,\n  \"deadline_errors\": %0d,\n", protocol_errors, deadline_errors);
      $fwrite(result_fd, "  \"first_output_cycle\": %0d,\n  \"last_output_cycle\": %0d,\n", first_output_cycle, last_output_cycle);
      $fwrite(result_fd, "  \"physical_cycles\": %0d,\n  \"accepted_clocks\": %0d,\n", physical_cycle, active_cycle);
      $fwrite(result_fd, "  \"ce_disabled_cycles\": %0d,\n  \"reset_cycles\": %0d,\n  \"cancelled_frames\": %0d,\n", ce_disabled_cycles, reset_cycles, cancelled_frames);
      $fwrite(result_fd, "  \"pi_commits\": %0d,\n  \"aw_commits\": %0d,\n", pi_commits, aw_commits);
      $fwrite(result_fd, "  \"frame_clocks\": %0d,\n  \"output_phase\": %0d,\n  \"old_state_pre_edge_phase\": %0d,\n", FRAME_CLOCKS, OUTPUT_PHASE, FRAME_CLOCKS);
      $fwrite(result_fd, "  \"max_wall_latency_clocks\": %0d,\n  \"deadline_clocks\": %0d,\n", max_wall_latency, DEADLINE_CLOCKS);
      $fwrite(result_fd, "  \"validity_source\": \"fixed external test contract; ce_out is fast CE\",\n");
      $fwrite(result_fd, "  \"first_error\": \"%s\"\n}\n", first_error);
      $fclose(result_fd);
      $display("M3_RESULT case=%s mode=%s status=%s expected=%0d observed=%0d bit=%0d state=%0d xz=%0d protocol=%0d deadline=%0d",
               case_name, mode, errors == 0 ? "PASS" : "FAIL", expected_frames,
               observed_frames, bit_mismatch, state_mismatch, xz_count, protocol_errors, deadline_errors);
      if (errors != 0) begin
        $display("M3_RTL_FAIL frames=%0d checks=%0d bit_mismatch=%0d protocol_errors=%0d deadline_errors=%0d",
                 observed_frames, checks, bit_mismatch + state_mismatch + xz_count,
                 protocol_errors, deadline_errors);
        $fatal(1, "M3 independent scoreboard rejected this run");
      end
      if (mode == "cycle_negative" && early_mismatch == 0)
        $display("M3_NEGATIVE_NOT_REJECTED one-clock-early data already matched; caller must reject ineffective negative coverage");
      $display("M3_RTL_PASS frames=%0d checks=%0d bit_mismatch=0 protocol_errors=0 deadline_errors=0",
               observed_frames, checks);
      $finish;
    end
  endtask

  initial begin : run
    integer row;
    integer fd;
    logic [31:0] sid, a, b, c, iqr, idr, vdc, eu, ev, ew;
    logic [39:0] theta, omega;
    logic pir;
    logic [63:0] xd, xq, awd, awq;
    if (!$value$plusargs("vectors=%s", vector_path) ||
        !$value$plusargs("frames=%d", frames) ||
        !$value$plusargs("result=%s", result_path))
      $fatal(1, "Required plusargs: vectors, frames, result");
    if (!$value$plusargs("case_name=%s", case_name)) case_name = "unnamed";
    if (!$value$plusargs("mode=%s", mode)) mode = "normal";
    if (!$value$plusargs("negative_sample=%d", negative_sample)) negative_sample = 0;
    if (!$value$plusargs("output_phase=%d", OUTPUT_PHASE)) OUTPUT_PHASE = 274;
    if (OUTPUT_PHASE < 1 || OUTPUT_PHASE + 2 > DEADLINE_CLOCKS) $fatal(1,"M3_INVALID_PHASE");
    if (!(mode == "normal" || mode == "ce" || mode == "reset" ||
          mode == "bit_negative" || mode == "cycle_negative"))
      $fatal(1, "Unknown mode %s", mode);
    if (frames < 1 || frames > MAX_FRAMES) $fatal(1, "Invalid frame count %0d", frames);
    if (negative_sample < 0 || negative_sample >= frames) $fatal(1, "Invalid negative sample %0d", negative_sample);
    if ((mode == "ce" || mode == "reset") && frames < 3)
      $fatal(1, "Directed CE/reset checks require at least three frames");
    fd = $fopen(vector_path, "r");
    if (!fd) $fatal(1, "Cannot read vectors %s", vector_path);
    $fclose(fd);
    $readmemh(vector_path, vectors, 0, frames - 1);
    for (row = 0; row < frames; row = row + 1) begin
      if ($isunknown(vectors[row])) $fatal(1, "Missing or unknown vector row %0d", row);
      unpack_record(row, sid, a, b, c, theta, omega, iqr, idr, pir,
                    vdc, eu, ev, ew, xd, xq, awd, awq);
      if (sid !== row[31:0]) $fatal(1, "sample_id must be consecutive from zero, row %0d", row);
    end
    expected_frames = frames;
    // Reset is asserted on real rising edges with CE disabled, demonstrating
    // reset priority rather than mistaking clock-enable for a reset control.
    tick(1'b1, 1'b0, 0, 0, 1'b0);
    tick(1'b1, 1'b0, 0, 0, 1'b0);
    if (mode == "reset") begin
      // Two complete frames are accepted; row 2 is cancelled at phase 100,
      // before its fixed output phase 274. This cancellation is predeclared.
      run_frame(0, FRAME_CLOCKS, 1'b0);
      run_frame(1, FRAME_CLOCKS, 1'b0);
      run_frame(2, 100, 1'b0);
      cancelled_frames = 1;
      tick(1'b1, 1'b1, 2, 0, 1'b0);
      tick(1'b1, 1'b0, 2, 0, 1'b0);
      epoch = 1;
      expected_frames = frames + 2;
      // Restart the explicitly known zero-state source/gm prefix. Do not
      // advance or reset expected rows in response to observed DUT outputs.
    end
    for (row = 0; row < frames; row = row + 1)
      run_frame(row, FRAME_CLOCKS, mode == "ce");
    if (observed_frames != expected_frames || observed_frames == 0) begin
      protocol_errors = protocol_errors + 1;
      fail("missing, duplicated, or zero valid frame count");
    end
    write_result();
  end

  initial begin
    #1000000000;
    $fatal(1, "M3 scoreboard simulation timeout; no passing result");
  end
endmodule
