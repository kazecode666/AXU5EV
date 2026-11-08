`timescale 1ns/1ps
// AX-03B1 observation-only AXI4-Lite READ CHANNEL. No writes, board base address,
// control permission or PWM path. All producer/AXI signals share clk; this is
// NOT a CDC primitive. payload_i word n is [32*n +: 32].
//
// Byte offsets (relative to this independent interface):
//   0x00 BEGIN: freeze the complete latest published bank, return uint32 seq.
//   0x04 frozen caller-supplied uint32 epoch/session label.
//   0x08 frozen flags: [0] observation exists (NOT ADC/current quality),
//                     [1] first publication after reset, [2] seq has wrapped.
//   0x0c + 4*n: frozen payload word n, n=0..SNAP_WORDS-1.
// The LAST payload response releases the bank on RVALID && RREADY. Read it last
// to retain the bank. Intermediate words may be repeated or read out of order.
// A new BEGIN explicitly replaces a bank, including an incompletely read bank.
// Any read without BEGIN (except BEGIN), no-latest BEGIN, unaligned or unknown
// offset returns RRESP=SLVERR/RDATA=0 and does not change a frozen bank.
//
// One response outstanding; ARREADY stays low until the pending R response is
// consumed. RDATA/RRESP/RVALID stay stable under R backpressure. No AR acceptance
// on the same edge that consumes a previous R response (one-cycle bubble).
// Publish and BEGIN on the same edge: BEGIN sees the complete PREVIOUS latest
// bank. If none existed, BEGIN returns SLVERR and the caller retries.
//
// Synchronous active-low reset aborts any R response, invalidates latest/frozen
// banks, resets sequence to SEQ_RESET and clears wrap history. First publish is
// SEQ_RESET+1 modulo 2^32. epoch_i is captured WITH EACH PUBLICATION, never read
// live. Caller must change its session label for resets it wants distinguishable;
// no resettable RTL register can supply a persistent boot counter by itself.
module ax03b1_snapshot_axi #(
  parameter integer SNAP_WORDS = 32,
  parameter integer ADDR_WIDTH = 12,
  parameter [31:0] SEQ_RESET = 32'd0
) (
  input  wire clk,
  input  wire rst_n,
  input  wire publish_i,
  input  wire [SNAP_WORDS*32-1:0] payload_i,
  input  wire [31:0] epoch_i,
  input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
  input  wire s_axi_arvalid,
  output wire s_axi_arready,
  output reg [31:0] s_axi_rdata,
  output reg [1:0] s_axi_rresp,
  output reg s_axi_rvalid,
  input  wire s_axi_rready
);
  localparam integer LAST_ADDR = 12 + 4*(SNAP_WORDS-1);
  localparam [1:0] OKAY = 2'b00, SLVERR = 2'b10;
  reg [SNAP_WORDS*32-1:0] latest_payload, frozen_payload;
  reg [31:0] latest_seq, latest_epoch, latest_flags;
  reg [31:0] frozen_epoch, frozen_flags;
  reg latest_valid, frozen_valid, first_pending, wrap_seen;
  reg release_on_response;

  assign s_axi_arready = rst_n && !s_axi_rvalid;

  // Parameter guards are elaboration-time checks, not runtime control logic.
  initial begin
    if (SNAP_WORDS < 1 || ADDR_WIDTH < 4 || ADDR_WIDTH > 30 ||
        LAST_ADDR >= (2**ADDR_WIDTH))
      $fatal(1, "ax03b1_snapshot_axi: payload does not fit address width");
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      latest_payload <= 0;
      frozen_payload <= 0;
      latest_seq <= SEQ_RESET;
      latest_epoch <= 0;
      latest_flags <= 0;
      frozen_epoch <= 0;
      frozen_flags <= 0;
      latest_valid <= 0;
      frozen_valid <= 0;
      first_pending <= 1;
      wrap_seen <= 0;
      release_on_response <= 0;
      s_axi_rdata <= 0;
      s_axi_rresp <= OKAY;
      s_axi_rvalid <= 0;
    end else begin
      // Invalid sensor/calibration frames are still valid OBSERVATIONS. Their
      // quality bits belong in payload, not in this transport availability flag.
      if (publish_i) begin
        latest_payload <= payload_i;
        latest_epoch <= epoch_i;
        latest_seq <= latest_seq + 32'd1;
        latest_flags <= {29'd0, (wrap_seen || (&latest_seq)), first_pending, 1'b1};
        latest_valid <= 1;
        first_pending <= 0;
        if (&latest_seq) wrap_seen <= 1;
      end

      if (s_axi_rvalid && s_axi_rready) begin
        s_axi_rvalid <= 0;
        release_on_response <= 0;
        if (release_on_response) frozen_valid <= 0;
      end

      if (s_axi_arvalid && s_axi_arready) begin
        s_axi_rvalid <= 1;
        s_axi_rdata <= 0;
        s_axi_rresp <= SLVERR;
        release_on_response <= 0;
        if (s_axi_araddr == 0) begin
          if (latest_valid) begin
            frozen_payload <= latest_payload;
            frozen_epoch <= latest_epoch;
            frozen_flags <= latest_flags;
            frozen_valid <= 1;
            s_axi_rdata <= latest_seq;
            s_axi_rresp <= OKAY;
          end
        end else if (frozen_valid && s_axi_araddr[1:0] == 0) begin
          if (s_axi_araddr == 4) begin
            s_axi_rdata <= frozen_epoch;
            s_axi_rresp <= OKAY;
          end else if (s_axi_araddr == 8) begin
            s_axi_rdata <= frozen_flags;
            s_axi_rresp <= OKAY;
          end else if (s_axi_araddr >= 12 && s_axi_araddr <= LAST_ADDR) begin
            s_axi_rdata <= frozen_payload[((s_axi_araddr-12)>>2)*32+:32];
            s_axi_rresp <= OKAY;
            if (s_axi_araddr == LAST_ADDR) release_on_response <= 1;
          end
        end
      end
    end
  end
endmodule
