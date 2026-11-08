`timescale 1ns/1ps
// Related 2:1 clocks. anchor is a 50 MHz register asserted 40 ns before
// the selected ADC rising edge. The first intervening 100 MHz edge starts
// phase 4997; three more PWM edges reach peak exactly at that sample edge.
module pwm_timebase(
 input wire clk, input wire resetn, input wire anchor,
 output reg started, output reg [13:0] phase,
 output wire [13:0] next_phase, output wire valley, output wire peak
);
 assign next_phase = phase==9999 ? 14'd0 : phase+14'd1;
 assign valley=started && phase==9999;
 assign peak=started && phase==4999;
 reg anchor_delayed;
 always @(posedge clk or negedge resetn) begin
  if(!resetn) begin started<=0;phase<=0;anchor_delayed<=1;end
  else begin
   anchor_delayed<=anchor;
   if(!started) begin
    // Ignore an anchor already high during reset release; use a fresh edge.
    if(anchor && !anchor_delayed) begin started<=1;phase<=4997;end
   end else phase<=next_phase;
  end
 end
endmodule
