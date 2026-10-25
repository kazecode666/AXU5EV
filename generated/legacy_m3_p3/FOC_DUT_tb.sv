
`timescale 1ns/1ps

module FOC_DUT_tb;

  logic clk;
  logic reset;
  logic clk_enable;
  logic signed [31:0] rawData_ia;
  logic signed [31:0] rawData_ib;
  logic signed [31:0] rawData_ic;
  logic signed [39:0] rawData_theta_e;
  logic signed [39:0] rawData_omega_e;
  logic signed [31:0] rawData_iq_ref;
  logic signed [31:0] rawData_id_ref;
  logic [31:0] rawData_Vdc_V;
  logic duty_w_cmd_done;
  logic ce_out;
  logic duty_w_cmd_done_enb;
  logic [18:0] duty_u_cmd_addr;
  logic duty_w_cmd_lastAddr;
  logic resetn;
  logic check3_done;
  logic duty_v_cmd_done;
  logic duty_v_cmd_done_enb;
  logic duty_v_cmd_lastAddr;
  logic check2_done;
  logic duty_u_cmd_done;
  logic duty_u_cmd_done_enb;
  logic duty_u_cmd_active;
  logic [31:0] holdData_Vdc_V;
  logic phase_1;
  logic [31:0] Vdc_V_offset;
  logic [31:0] Vdc_V_1;
  logic [5:0] ia_addr;
  logic ia_active;
  logic tb_enb_delay;
  logic ia_enb;
  logic [5:0] PI_Reset_EN_addr_delay_1;
  logic tb_enb;
  logic signed [31:0] fp_PI_Reset_EN;
  logic snkDone;
  logic rawData_PI_Reset_EN;
  logic signed [31:0] status_PI_Reset_EN;
  logic holdData_PI_Reset_EN;
  logic PI_Reset_EN_offset;
  logic PI_Reset_EN;
  logic signed [31:0] holdData_id_ref;
  logic signed [31:0] id_ref_offset;
  logic signed [31:0] id_ref_1;
  logic signed [31:0] holdData_iq_ref;
  logic signed [31:0] iq_ref_offset;
  logic signed [31:0] iq_ref_1;
  logic signed [39:0] holdData_omega_e;
  logic signed [39:0] omega_e_offset;
  logic signed [39:0] omega_e_1;
  logic signed [39:0] holdData_theta_e;
  logic signed [39:0] theta_e_offset;
  logic signed [39:0] theta_e_1;
  logic signed [31:0] holdData_ic;
  logic signed [31:0] ic_offset;
  logic signed [31:0] ic_1;
  logic signed [31:0] holdData_ib;
  logic signed [31:0] ib_offset;
  logic signed [31:0] ib_1;
  logic [12:0] counter;
  logic phase_1_ctr;
  logic signed [31:0] holdData_ia;
  logic signed [31:0] ia_offset;
  logic signed [31:0] ia_2;
  logic snkDonen;
  logic notDone;
  logic reset_FOC_DUT_tc_1;
  logic [31:0] duty_u_cmd;
  logic [31:0] duty_v_cmd;
  logic [31:0] duty_w_cmd;
  logic duty_u_cmd_enb;
  logic duty_u_cmd_lastAddr;
  logic check1_done;
  logic [18:0] duty_u_cmd_addr_delay_1;
  logic signed [31:0] fp_duty_u_cmd_expected;
  logic [31:0] duty_u_cmd_expected;
  logic signed [31:0] status_duty_u_cmd_expected;
  logic [31:0] duty_u_cmd_ref_hold;
  logic [31:0] duty_u_cmd_refTmp;
  logic [31:0] duty_u_cmd_ref;
  logic duty_u_cmd_testFailure;
  logic [18:0] duty_v_cmd_addr_delay_1;
  logic signed [31:0] fp_duty_v_cmd_expected;
  logic [31:0] duty_v_cmd_expected;
  logic signed [31:0] status_duty_v_cmd_expected;
  logic [31:0] duty_v_cmd_ref_hold;
  logic [31:0] duty_v_cmd_refTmp;
  logic [31:0] duty_v_cmd_ref;
  logic duty_v_cmd_testFailure;
  logic [18:0] duty_w_cmd_addr_delay_1;
  logic signed [31:0] fp_duty_w_cmd_expected;
  logic [31:0] duty_w_cmd_expected;
  logic signed [31:0] status_duty_w_cmd_expected;
  logic [31:0] duty_w_cmd_ref_hold;
  logic [31:0] duty_w_cmd_refTmp;
  logic [31:0] duty_w_cmd_ref;
  logic duty_w_cmd_testFailure;
  logic testFailure;


     assign rawData_ia = 32'sb00000000000000000000000000000000;

     assign rawData_ib = 32'sb00000000000000000000000000000000;

     assign rawData_ic = 32'sb00000000000000000000000000000000;

     assign rawData_theta_e = 40'sh0000000000;

     assign rawData_omega_e = 40'sh0000000000;

     assign rawData_iq_ref = 32'sb00000000000000000000000000000000;

     assign rawData_id_ref = 32'sb00000000000000000000000000000000;

     assign rawData_Vdc_V = 32'b00110000000000000000000000000000;

  assign duty_w_cmd_done_enb = duty_w_cmd_done & ce_out;

  assign duty_w_cmd_lastAddr = duty_u_cmd_addr >= 19'b1001100111001111000;

  assign duty_w_cmd_done = duty_w_cmd_lastAddr & resetn;

     always @(posedge clk)
    begin : checkDone_3
      if (reset) begin
        check3_done <= 0;
      end
      else begin
        if (duty_w_cmd_done_enb) begin
          check3_done <= duty_w_cmd_done;
        end
      end
    end

  assign duty_v_cmd_done_enb = duty_v_cmd_done & ce_out;

  assign duty_v_cmd_lastAddr = duty_u_cmd_addr >= 19'b1001100111001111000;

  assign duty_v_cmd_done = duty_v_cmd_lastAddr & resetn;

     always @(posedge clk)
    begin : checkDone_2
      if (reset) begin
        check2_done <= 0;
      end
      else begin
        if (duty_v_cmd_done_enb) begin
          check2_done <= duty_v_cmd_done;
        end
      end
    end

  assign duty_u_cmd_done_enb = duty_u_cmd_done & ce_out;

  assign duty_u_cmd_active = duty_u_cmd_addr != 19'b1001100111001111000;

     always @(posedge clk)
    begin : stimuli_Vdc_V
      if (reset) begin
        holdData_Vdc_V <= 32'bx;
      end
      else begin
        holdData_Vdc_V <= rawData_Vdc_V;
      end
    end

  always @(rawData_Vdc_V or phase_1)
    begin : stimuli_Vdc_V_1
      if (phase_1 == 1'b0) begin
        Vdc_V_offset <= holdData_Vdc_V;
      end
      else begin
        Vdc_V_offset <= rawData_Vdc_V;
      end
    end

  assign #2 Vdc_V_1 = Vdc_V_offset;

  assign ia_active = ia_addr != 6'b111111;

  assign ia_enb = ia_active & (phase_1 & tb_enb_delay);

              always_ff @(posedge clk)
    begin : ia_1_process
      if (reset == 1'b1) begin
        ia_addr <= 6'b000000;
      end
      else begin
        if (ia_enb) begin
          ia_addr <= ia_addr + 6'b000001;
        end
      end
    end

  assign #1 PI_Reset_EN_addr_delay_1 = ia_addr;

     initial
    begin : PI_Reset_EN_fileread
      fp_PI_Reset_EN = $fopen("PI_Reset_EN.dat", "r");
      status_PI_Reset_EN = $rewind(fp_PI_Reset_EN);
    end

  always @(PI_Reset_EN_addr_delay_1, phase_1, tb_enb_delay)
    begin
      if (tb_enb_delay == 0) begin
        rawData_PI_Reset_EN <= 1'bx;
        if (snkDone == 1) begin
          $fclose(fp_PI_Reset_EN);
        end
      end
      else if (phase_1 == 1) begin
        status_PI_Reset_EN = $fscanf(fp_PI_Reset_EN, "%h", rawData_PI_Reset_EN);
      end
    end

     always @(posedge clk)
    begin : stimuli_PI_Reset_EN
      if (reset) begin
        holdData_PI_Reset_EN <= 1'bx;
      end
      else begin
        holdData_PI_Reset_EN <= rawData_PI_Reset_EN;
      end
    end

  always @(rawData_PI_Reset_EN or phase_1)
    begin : stimuli_PI_Reset_EN_1
      if (phase_1 == 1'b0) begin
        PI_Reset_EN_offset <= holdData_PI_Reset_EN;
      end
      else begin
        PI_Reset_EN_offset <= rawData_PI_Reset_EN;
      end
    end

  assign #2 PI_Reset_EN = PI_Reset_EN_offset;

     always @(posedge clk)
    begin : stimuli_id_ref
      if (reset) begin
        holdData_id_ref <= 32'bx;
      end
      else begin
        holdData_id_ref <= rawData_id_ref;
      end
    end

  always @(rawData_id_ref or phase_1)
    begin : stimuli_id_ref_1
      if (phase_1 == 1'b0) begin
        id_ref_offset <= holdData_id_ref;
      end
      else begin
        id_ref_offset <= rawData_id_ref;
      end
    end

  assign #2 id_ref_1 = id_ref_offset;

     always @(posedge clk)
    begin : stimuli_iq_ref
      if (reset) begin
        holdData_iq_ref <= 32'bx;
      end
      else begin
        holdData_iq_ref <= rawData_iq_ref;
      end
    end

  always @(rawData_iq_ref or phase_1)
    begin : stimuli_iq_ref_1
      if (phase_1 == 1'b0) begin
        iq_ref_offset <= holdData_iq_ref;
      end
      else begin
        iq_ref_offset <= rawData_iq_ref;
      end
    end

  assign #2 iq_ref_1 = iq_ref_offset;

     always @(posedge clk)
    begin : stimuli_omega_e
      if (reset) begin
        holdData_omega_e <= 40'bx;
      end
      else begin
        holdData_omega_e <= rawData_omega_e;
      end
    end

  always @(rawData_omega_e or phase_1)
    begin : stimuli_omega_e_1
      if (phase_1 == 1'b0) begin
        omega_e_offset <= holdData_omega_e;
      end
      else begin
        omega_e_offset <= rawData_omega_e;
      end
    end

  assign #2 omega_e_1 = omega_e_offset;

     always @(posedge clk)
    begin : stimuli_theta_e
      if (reset) begin
        holdData_theta_e <= 40'bx;
      end
      else begin
        holdData_theta_e <= rawData_theta_e;
      end
    end

  always @(rawData_theta_e or phase_1)
    begin : stimuli_theta_e_1
      if (phase_1 == 1'b0) begin
        theta_e_offset <= holdData_theta_e;
      end
      else begin
        theta_e_offset <= rawData_theta_e;
      end
    end

  assign #2 theta_e_1 = theta_e_offset;

     always @(posedge clk)
    begin : stimuli_ic
      if (reset) begin
        holdData_ic <= 32'bx;
      end
      else begin
        holdData_ic <= rawData_ic;
      end
    end

  always @(rawData_ic or phase_1)
    begin : stimuli_ic_1
      if (phase_1 == 1'b0) begin
        ic_offset <= holdData_ic;
      end
      else begin
        ic_offset <= rawData_ic;
      end
    end

  assign #2 ic_1 = ic_offset;

     always @(posedge clk)
    begin : stimuli_ib
      if (reset) begin
        holdData_ib <= 32'bx;
      end
      else begin
        holdData_ib <= rawData_ib;
      end
    end

  always @(rawData_ib or phase_1)
    begin : stimuli_ib_1
      if (phase_1 == 1'b0) begin
        ib_offset <= holdData_ib;
      end
      else begin
        ib_offset <= rawData_ib;
      end
    end

  assign #2 ib_1 = ib_offset;

              always_ff @(posedge clk)
    begin : slow_clock_enable_process
      if (reset == 1'b1) begin
        counter <= 13'b0000000000001;
      end
      else begin
        if (tb_enb_delay) begin
          if (counter >= 13'b1001110000111) begin
            counter <= 13'b0000000000000;
          end
          else begin
            counter <= counter + 13'b0000000000001;
          end
        end
      end
    end

  assign phase_1_ctr = counter == 13'b0000000000001;

  assign phase_1 = phase_1_ctr & tb_enb_delay;

     always @(posedge clk)
    begin : stimuli_ia
      if (reset) begin
        holdData_ia <= 32'bx;
      end
      else begin
        holdData_ia <= rawData_ia;
      end
    end

  always @(rawData_ia or phase_1)
    begin : stimuli_ia_1
      if (phase_1 == 1'b0) begin
        ia_offset <= holdData_ia;
      end
      else begin
        ia_offset <= rawData_ia;
      end
    end

  assign #2 ia_2 = ia_offset;

  assign snkDonen =  ~ snkDone;

  assign resetn =  ~ reset;

  assign tb_enb = resetn & snkDonen;

     always_ff @(posedge clk)
    begin : u_enable_delay_process
      if (reset == 1'b1) begin
        tb_enb_delay <= 1'b0;
      end
      else begin
        tb_enb_delay <= tb_enb;
      end
    end

  assign notDone = tb_enb_delay & snkDonen;

  assign #2 clk_enable = notDone;

  assign reset_FOC_DUT_tc_1 = reset;

  initial
    begin : reset_gen
      reset <= 1'b1;
      # (40);
      @ (posedge clk)
      # (2);
      reset <= 1'b0;
    end

  always 
    begin : clk_gen
      clk <= 1'b1;
      # (10);
      clk <= 1'b0;
      # (10);
      if (snkDone == 1'b1) begin
        clk <= 1'b1;
        # (10);
        clk <= 1'b0;
        # (10);
        $stop;
      end
    end

  FOC_DUT u_FOC_DUT (.clk(clk),
                     .reset(reset),
                     .reset_FOC_DUT_tc(reset_FOC_DUT_tc_1),
                     .clk_enable(clk_enable),
                     .ia(ia_2),
                     .ib(ib_1),
                     .ic(ic_1),
                     .theta_e(theta_e_1),
                     .omega_e(omega_e_1),
                     .iq_ref(iq_ref_1),
                     .id_ref(id_ref_1),
                     .PI_Reset_EN(PI_Reset_EN),
                     .Vdc_V(Vdc_V_1),
                     .ce_out(ce_out),
                     .duty_u_cmd(duty_u_cmd),
                     .duty_v_cmd(duty_v_cmd),
                     .duty_w_cmd(duty_w_cmd)
                     );

  assign duty_u_cmd_enb = ce_out & duty_u_cmd_active;

              always_ff @(posedge clk)
    begin : c_2_process
      if (reset == 1'b1) begin
        duty_u_cmd_addr <= 19'b0000000000000000000;
      end
      else begin
        if (duty_u_cmd_enb) begin
          if (duty_u_cmd_addr >= 19'b1001100111001111000) begin
            duty_u_cmd_addr <= 19'b0000000000000000000;
          end
          else begin
            duty_u_cmd_addr <= duty_u_cmd_addr + 19'b0000000000000000001;
          end
        end
      end
    end

  assign duty_u_cmd_lastAddr = duty_u_cmd_addr >= 19'b1001100111001111000;

  assign duty_u_cmd_done = duty_u_cmd_lastAddr & resetn;

     always @(posedge clk)
    begin : checkDone_1
      if (reset) begin
        check1_done <= 0;
      end
      else begin
        if (duty_u_cmd_done_enb) begin
          check1_done <= duty_u_cmd_done;
        end
      end
    end

  assign snkDone = check3_done & (check1_done & check2_done);

  assign #1 duty_u_cmd_addr_delay_1 = duty_u_cmd_addr;

     initial
    begin : duty_u_cmd_expected_fileread
      fp_duty_u_cmd_expected = $fopen("duty_u_cmd_expected.dat", "r");
      status_duty_u_cmd_expected = $rewind(fp_duty_u_cmd_expected);
    end

  always @(duty_u_cmd_addr_delay_1,  tb_enb_delay)
    begin
      if (tb_enb_delay == 0) begin
        duty_u_cmd_expected <= 32'bx;
        if (snkDone == 1) begin
          $fclose(fp_duty_u_cmd_expected);
        end
      end
      else  begin
        status_duty_u_cmd_expected = $fscanf(fp_duty_u_cmd_expected, "%h", duty_u_cmd_expected);
      end
    end

     always @(posedge clk)
    begin : DataHold_duty_u_cmd_ref
      if (reset) begin
        duty_u_cmd_ref_hold <= 0;
      end
      else begin
        if (ce_out) begin
          duty_u_cmd_ref_hold <= duty_u_cmd_expected;
        end
      end
    end

  assign duty_u_cmd_refTmp = duty_u_cmd_expected;

  assign duty_u_cmd_ref = (ce_out == 1'b0 ? duty_u_cmd_ref_hold :
              duty_u_cmd_refTmp);

  always @(posedge clk)
    begin : duty_u_cmd_checker
      if (reset == 1'b1) begin
        duty_u_cmd_testFailure <= 1'b0;
      end
      else begin
        if (ce_out == 1'b1 && duty_u_cmd !== duty_u_cmd_ref) begin
          duty_u_cmd_testFailure <= 1'b1;
          $display("ERROR in duty_u_cmd at time %t : Expected '%h' Actual '%h'", $time, duty_u_cmd_ref, duty_u_cmd);
        end
      end
    end

  assign #1 duty_v_cmd_addr_delay_1 = duty_u_cmd_addr;

     initial
    begin : duty_v_cmd_expected_fileread
      fp_duty_v_cmd_expected = $fopen("duty_v_cmd_expected.dat", "r");
      status_duty_v_cmd_expected = $rewind(fp_duty_v_cmd_expected);
    end

  always @(duty_v_cmd_addr_delay_1,  tb_enb_delay)
    begin
      if (tb_enb_delay == 0) begin
        duty_v_cmd_expected <= 32'bx;
        if (snkDone == 1) begin
          $fclose(fp_duty_v_cmd_expected);
        end
      end
      else  begin
        status_duty_v_cmd_expected = $fscanf(fp_duty_v_cmd_expected, "%h", duty_v_cmd_expected);
      end
    end

     always @(posedge clk)
    begin : DataHold_duty_v_cmd_ref
      if (reset) begin
        duty_v_cmd_ref_hold <= 0;
      end
      else begin
        if (ce_out) begin
          duty_v_cmd_ref_hold <= duty_v_cmd_expected;
        end
      end
    end

  assign duty_v_cmd_refTmp = duty_v_cmd_expected;

  assign duty_v_cmd_ref = (ce_out == 1'b0 ? duty_v_cmd_ref_hold :
              duty_v_cmd_refTmp);

  always @(posedge clk)
    begin : duty_v_cmd_checker
      if (reset == 1'b1) begin
        duty_v_cmd_testFailure <= 1'b0;
      end
      else begin
        if (ce_out == 1'b1 && duty_v_cmd !== duty_v_cmd_ref) begin
          duty_v_cmd_testFailure <= 1'b1;
          $display("ERROR in duty_v_cmd at time %t : Expected '%h' Actual '%h'", $time, duty_v_cmd_ref, duty_v_cmd);
        end
      end
    end

  assign #1 duty_w_cmd_addr_delay_1 = duty_u_cmd_addr;

     initial
    begin : duty_w_cmd_expected_fileread
      fp_duty_w_cmd_expected = $fopen("duty_w_cmd_expected.dat", "r");
      status_duty_w_cmd_expected = $rewind(fp_duty_w_cmd_expected);
    end

  always @(duty_w_cmd_addr_delay_1,  tb_enb_delay)
    begin
      if (tb_enb_delay == 0) begin
        duty_w_cmd_expected <= 32'bx;
        if (snkDone == 1) begin
          $fclose(fp_duty_w_cmd_expected);
        end
      end
      else  begin
        status_duty_w_cmd_expected = $fscanf(fp_duty_w_cmd_expected, "%h", duty_w_cmd_expected);
      end
    end

     always @(posedge clk)
    begin : DataHold_duty_w_cmd_ref
      if (reset) begin
        duty_w_cmd_ref_hold <= 0;
      end
      else begin
        if (ce_out) begin
          duty_w_cmd_ref_hold <= duty_w_cmd_expected;
        end
      end
    end

  assign duty_w_cmd_refTmp = duty_w_cmd_expected;

  assign duty_w_cmd_ref = (ce_out == 1'b0 ? duty_w_cmd_ref_hold :
              duty_w_cmd_refTmp);

  always @(posedge clk)
    begin : duty_w_cmd_checker
      if (reset == 1'b1) begin
        duty_w_cmd_testFailure <= 1'b0;
      end
      else begin
        if (ce_out == 1'b1 && duty_w_cmd !== duty_w_cmd_ref) begin
          duty_w_cmd_testFailure <= 1'b1;
          $display("ERROR in duty_w_cmd at time %t : Expected '%h' Actual '%h'", $time, duty_w_cmd_ref, duty_w_cmd);
        end
      end
    end

  assign testFailure = duty_w_cmd_testFailure | (duty_u_cmd_testFailure | duty_v_cmd_testFailure);

  always @(posedge clk)
    begin : completed_msg
      if (snkDone == 1'b1) begin
        if (testFailure == 1'b0) begin
          $display("**************TEST COMPLETED (PASSED)**************");
        end
        else begin
          $display("**************TEST COMPLETED (FAILED)**************");
        end
      end
    end

endmodule   
