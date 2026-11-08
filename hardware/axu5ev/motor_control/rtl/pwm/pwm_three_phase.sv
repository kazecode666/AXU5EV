`timescale 1ns/1ps
// Integer compare C / 5000, 10000 clocks/period. Requests contain exactly
// 2*C high intervals. Dead times are clock counts, fixed for this build.
module pwm_three_phase #(
 parameter integer DEAD_HIGH=100, parameter integer DEAD_LOW=100
)(
 input wire clk, input wire resetn, input wire fast_inhibit,
 input wire anchor, input wire request,
 input wire [38:0] request_compare, input wire [31:0] request_seq,
 input wire [6:0] permission,
 output reg accepted, output reg applied,
 output reg [31:0] active_seq, output reg [38:0] active_compare,
 output reg pending, output wire started, output wire [13:0] phase,
 output wire valley, output wire peak,
 output reg [2:0] high_o, output reg [2:0] low_o,
 output wire [2:0] high_request
);
 wire [13:0] next_phase;
 pwm_timebase timebase(.clk(clk),.resetn(resetn),.anchor(anchor),
 .started(started),.phase(phase),.next_phase(next_phase),.valley(valley),.peak(peak));
 reg [38:0] pending_compare;reg [31:0] pending_seq;
 wire output_resetn=resetn && !fast_inhibit;
 // A request received on this valley is not eligible until the next valley.
 always @(posedge clk or negedge output_resetn) begin
  if(!output_resetn) begin
   accepted<=0;applied<=0;pending<=0;pending_compare<=0;pending_seq<=0;
   active_compare<=0;active_seq<=0;
  end else begin
   if(!request) begin accepted<=0;applied<=0;end
   if(request && !accepted && !pending && started) begin
    pending_compare<=request_compare;pending_seq<=request_seq;
    pending<=1;accepted<=1;
   end
   if(valley && pending) begin
    active_compare<=pending_compare;active_seq<=pending_seq;pending<=0;applied<=1;
   end
  end
 end
 // Falling permissions act immediately in this domain; rising permissions
 // wait for a valley. Reallowing starts a fresh dead-time, never an old timer.
 reg [6:0] enabled;
 wire [6:0] use_permission=valley ? permission : (enabled & permission);
 wire [38:0] use_compare=(valley && pending) ? pending_compare : active_compare;
 genvar g;
 generate for(g=0;g<3;g=g+1) begin: leg
  wire [12:0] c=use_compare[g*13+:13];
  wire req=(c==5000) || ((c!=0) && ((next_phase<c) || (next_phase>=10000-c)));
  wire want_h=started && use_permission[6] && use_permission[g] && req;
  wire want_l=started && use_permission[6] && use_permission[g+3] && !req;
  reg last_h,last_l;
  reg [15:0] wait_h,wait_l;
  assign high_request[g]=req;
  always @(posedge clk or negedge output_resetn) begin
   if(!output_resetn) begin
    high_o[g]<=0;low_o[g]<=0;last_h<=0;last_l<=0;wait_h<=0;wait_l<=0;
   end else begin
    last_h<=want_h;last_l<=want_l;
    if(!want_h) begin high_o[g]<=0;wait_h<=0;end
    else if(!last_h) begin high_o[g]<=(DEAD_HIGH==0);wait_h<=DEAD_HIGH;end
    else if(wait_h>1) wait_h<=wait_h-1'b1;
    else if(wait_h==1) begin wait_h<=0;high_o[g]<=1;end
    if(!want_l) begin low_o[g]<=0;wait_l<=0;end
    else if(!last_l) begin low_o[g]<=(DEAD_LOW==0);wait_l<=DEAD_LOW;end
    else if(wait_l>1) wait_l<=wait_l-1'b1;
    else if(wait_l==1) begin wait_l<=0;low_o[g]<=1;end
   end
  end
 end endgenerate
 always @(posedge clk or negedge output_resetn) begin
  if(!output_resetn) enabled<=0;
  else enabled<=use_permission;
 end
endmodule
