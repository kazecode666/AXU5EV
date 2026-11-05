`timescale 1ns/1ps
// AX-03B1 logical observer only. No physical clock/capture edge or XDC claim.
// SIM_ASSUMPTION: common 50MHz domain, abstract dual parallel offset-binary
// return buses, seven conversion events. External stable-word qualification is
// explicit; IDs and constant codes do not prove that an external ADC is alive.
module ax03b1_observer #(
 parameter integer SAMPLE_DIV=10,
 parameter integer OBSERVE_DIV=5000,
 parameter integer FILTER_CYCLES=2,
 parameter [31:0] INITIAL_COUNT=32'd0
)(
 input wire clk, rst,
 input wire [40:1] an9238_header_i,
 input wire capture_valid_a_i, capture_valid_b_i,
 input wire a_async_i,b_async_i,z_async_i,
 input wire cal_en_i,cal_restart_i,config_apply_i,
 input wire [31:0] config_version_i,session_epoch_i,
 input wire signed [31:0] offset_seed_a_q16_i,offset_seed_b_q16_i,
 input wire manual_valid_a_i,manual_valid_b_i,
 input wire signed [31:0] gain_a_q24_i,gain_b_q24_i,
 input wire [7:0] cal_log2_n_i,
 input wire [11:0] s_axi_araddr,
 input wire s_axi_arvalid,s_axi_rready,
 output wire s_axi_arready,s_axi_rvalid,
 output wire [31:0] s_axi_rdata,
 output wire [1:0] s_axi_rresp,
 output wire sample_event_o,observe_select_o,publish_o,
 output wire [5:0] gate_pwm_o,
 output wire encon_o,relcon_o,fault_reset_o,run_permission_o
);
 // Locked to the generated adapter's one-cycle output group, plus the publish
 // edge. This guard and the minimum-interval integrated test must be revisited
 // if code-generation latency changes; metadata is not an arbitrary FIFO.
 localparam integer NUMERIC_LATENCY=1;
 initial begin
   if(SAMPLE_DIV<2 || OBSERVE_DIV<8 || OBSERVE_DIV<=NUMERIC_LATENCY+2 ||
      (OBSERVE_DIV%SAMPLE_DIV)!=0 || FILTER_CYCLES<2)
     $fatal(1,"B1 observer: invalid logical timing parameters");
 end
 // These are deliberately constant hardware outputs, not software promises.
 assign gate_pwm_o=6'b0;
 assign encon_o=1'b0;
 assign relcon_o=1'b0;
 assign fault_reset_o=1'b0;
 assign run_permission_o=1'b0;

 reg [63:0] tick;
 integer sample_phase,observe_phase;
 assign sample_event_o=!rst && sample_phase==0;
 assign observe_select_o=sample_event_o && observe_phase==0;
 always @(posedge clk) begin
   if(rst) begin tick<=0;sample_phase<=0;observe_phase<=0;end
   else begin
     tick<=tick+1'b1;
     sample_phase<=sample_phase==SAMPLE_DIV-1?0:sample_phase+1;
     observe_phase<=observe_phase==OBSERVE_DIV-1?0:observe_phase+1;
   end
 end
 // No forwarded physical ADC clock is assigned here. B2 must choose I/O
 // capture/forwarding and constraints after actual module-mode/timing review.
 wire [11:0] raw_a,raw_b;
 wire otr_a,otr_b;
 ax03b1_an9238_pinmap pinmap(.header_i(an9238_header_i),.raw_a(raw_a),
   .raw_b(raw_b),.otr_a(otr_a),.otr_b(otr_b));
 wire [31:0] q_count,illegal_count,z_count;
 wire [63:0] z_tick;
 wire ab_ready,z_seen;
 ax03b1_abz_receiver #(.FILTER_CYCLES(FILTER_CYCLES),.INITIAL_COUNT(INITIAL_COUNT)) abz(
   .clk(clk),.rst(rst),.tick(tick),.a_async(a_async_i),.b_async(b_async_i),.z_async(z_async_i),
   .q_count(q_count),.ab_ready(ab_ready),.illegal_count(illegal_count),
   .z_seen(z_seen),.z_count(z_count),.z_tick(z_tick));
 // Sampling and ABZ updates at the same clock read pre-edge registered ABZ
 // state. Synchronizer/filter latency is explicit and is not physical zero lag.
 wire [255:0] sample_meta={30'b0,ab_ready,z_seen,illegal_count,z_tick,z_count,q_count,tick};
 wire [255:0] pair_meta;
 wire [31:0] pair_id;
 wire [11:0] pair_a,pair_b;
 wire [1:0] pair_otr;
 wire pair_strobe,pair_complete,pair_valid_a,pair_valid_b;
 ax03b1_adc_receiver #(.META_WIDTH(256),.PIPELINE_EVENTS(7)) adc(
   .clk(clk),.rst(rst),.sample_ce(sample_event_o),.observe_select(observe_select_o),
   .raw_a(raw_a),.raw_b(raw_b),.valid_a(capture_valid_a_i),.valid_b(capture_valid_b_i),
   .otr_a(otr_a),.otr_b(otr_b),.sample_meta(sample_meta),
   .pair_strobe(pair_strobe),.pair_complete(pair_complete),.pair_a(pair_a),.pair_b(pair_b),
   .pair_valid_a(pair_valid_a),.pair_valid_b(pair_valid_b),.pair_otr(pair_otr),
   .pair_id(pair_id),.pair_meta(pair_meta));

 wire signed [31:0] ia,ib,ic,offset_a,offset_b;
 wire [15:0] count_a,count_b,error;
 wire [31:0] cal_version;
 wire cal_done_a,cal_done_b,numeric_valid,clip,result_strobe;
 ax03b1_current_adapter current(
   .clk(clk),.rst(rst),.sample_strobe(pair_strobe),.raw_a({4'b0,pair_a}),.raw_b({4'b0,pair_b}),
   .capture_valid_a(pair_valid_a),.capture_valid_b(pair_valid_b),
   .otr_a(pair_otr[0]),.otr_b(pair_otr[1]),.cal_en(cal_en_i),.cal_restart(cal_restart_i),
   .config_apply(config_apply_i),.config_version(config_version_i),
   .offset_seed_a_q16(offset_seed_a_q16_i),.offset_seed_b_q16(offset_seed_b_q16_i),
   .manual_valid_a(manual_valid_a_i),.manual_valid_b(manual_valid_b_i),
   .gain_a_q24(gain_a_q24_i),.gain_b_q24(gain_b_q24_i),.cal_log2_n(cal_log2_n_i),
   .ia_q24(ia),.ib_q24(ib),.ic_q24(ic),.offset_a_q16(offset_a),.offset_b_q16(offset_b),
   .cal_count_a(count_a),.cal_count_b(count_b),.cal_done_a(cal_done_a),.cal_done_b(cal_done_b),
   .cal_version(cal_version),.valid(numeric_valid),.clip(clip),.error(error),.result_strobe(result_strobe));
 // Receiver fields remain stable until the next selected return. The generated
 // numerical path has a documented bounded latency shorter than that interval.
 // The integrated test checks IDs/ticks/raw/current association, including bad
 // returns. B1 timing parameters must preserve that separation.
 reg [1023:0] payload;
 reg [31:0] quality;
 always @* begin
   quality=0;
   quality[0]=pair_valid_a; quality[1]=pair_valid_b; quality[2]=pair_complete;
   quality[3]=pair_otr[0];quality[4]=pair_otr[1];
   quality[5]=cal_done_a;quality[6]=cal_done_b;quality[7]=numeric_valid;
   quality[8]=clip;quality[9]=pair_meta[224];quality[10]=pair_meta[225];
   quality[16]=1'b1; // SIM_ASSUMPTION
   quality[17]=1'b0; // physical_link_verified: B1 never asserts this
   payload=0;
   payload[0*32+:32]=32'h42314f42; // B1OB schema identity
   payload[1*32+:32]=32'd1;
   payload[2*32+:32]=quality;
   payload[3*32+:32]=pair_id;
   payload[4*32+:64]=pair_meta[63:0];
   payload[6*32+:32]={20'b0,pair_a};payload[7*32+:32]={20'b0,pair_b};
   payload[8*32+:32]=ia;payload[9*32+:32]=ib;payload[10*32+:32]=ic;
   payload[11*32+:32]=offset_a;payload[12*32+:32]=offset_b;
   payload[13*32+:32]={16'b0,count_a};payload[14*32+:32]={16'b0,count_b};
   payload[15*32+:32]=cal_version;
   payload[16*32+:32]=pair_meta[95:64];payload[17*32+:32]=pair_meta[127:96];
   payload[18*32+:64]=pair_meta[191:128];payload[20*32+:32]=pair_meta[223:192];
   payload[21*32+:32]={16'b0,error};
   payload[22*32+:32]=24;payload[23*32+:32]=16;
   payload[24*32+:32]=7;payload[25*32+:32]=SAMPLE_DIV;
   payload[26*32+:32]=OBSERVE_DIV;payload[27*32+:32]=FILTER_CYCLES;
 end
 assign publish_o=result_strobe;
 ax03b1_snapshot_axi #(.SNAP_WORDS(32),.ADDR_WIDTH(12)) snapshot(
   .clk(clk),.rst_n(!rst),.publish_i(result_strobe),.payload_i(payload),.epoch_i(session_epoch_i),
   .s_axi_araddr(s_axi_araddr),.s_axi_arvalid(s_axi_arvalid),.s_axi_arready(s_axi_arready),
   .s_axi_rdata(s_axi_rdata),.s_axi_rresp(s_axi_rresp),.s_axi_rvalid(s_axi_rvalid),.s_axi_rready(s_axi_rready));
endmodule
