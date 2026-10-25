
`timescale 1ns/1ps

module FOC_DUT_tc
          (  input logic clk,
             input logic reset,
             input logic reset_FOC_DUT_tc,
             input logic clk_enable,
             output logic enb,
             output logic enb_1_1_1,
             output logic enb_1_5000_0,
             output logic enb_1_5000_1);


  logic reset_tc;
  logic [12:0] count5000;
  logic comp_0_tmp;
  logic phase_0_tmp;
  logic phase_0;
  logic enb_1_5000_0_1;
  logic comp_1_tmp;
  logic phase_1_tmp;
  logic phase_1;
  logic enb_1_5000_1_1;


  assign enb = clk_enable;

  assign enb_1_1_1 = clk_enable;

  assign reset_tc = reset | reset_FOC_DUT_tc;

              always_ff @(posedge clk)
    begin : counter_5000_process
      if (reset_tc == 1'b1) begin
        count5000 <= 13'b0000000000001;
      end
      else begin
        if (clk_enable) begin
          if (count5000 >= 13'b1001110000111) begin
            count5000 <= 13'b0000000000000;
          end
          else begin
            count5000 <= count5000 + 13'b0000000000001;
          end
        end
      end
    end

  assign comp_0_tmp = count5000 == 13'b1001110000111;

  assign phase_0_tmp = comp_0_tmp & clk_enable;

  always_ff @(posedge clk)
    begin : phase_delay_process
      if (reset_tc == 1'b1) begin
        phase_0 <= 1'b0;
      end
      else begin
        if (clk_enable) begin
          phase_0 <= phase_0_tmp;
        end
      end
    end

  assign enb_1_5000_0_1 = phase_0 & clk_enable;

  assign enb_1_5000_0 = enb_1_5000_0_1;

  assign comp_1_tmp = count5000 == 13'b0000000000000;

  assign phase_1_tmp = comp_1_tmp & clk_enable;

  always_ff @(posedge clk)
    begin : phase_delay_1_process
      if (reset_tc == 1'b1) begin
        phase_1 <= 1'b1;
      end
      else begin
        if (clk_enable) begin
          phase_1 <= phase_1_tmp;
        end
      end
    end

  assign enb_1_5000_1_1 = phase_1 & clk_enable;

  assign enb_1_5000_1 = enb_1_5000_1_1;

endmodule   
