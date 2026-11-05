`timescale 1ns/1ps
// AX-03B2 J15 raw-ADC observer. A single 50 MHz logic domain forwards two
// in-phase 5 MHz clocks. The ADC samples on their rising edges; capture is
// four logic periods (80 ns) later, after the specified output tPD window.
// No motor, ABZ, current calibration, control Runtime or power outputs.
module ax03b2_adc_observer #(
    parameter integer OBSERVE_CONVERSIONS = 500
) (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK",
       X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axi_aclk, ASSOCIATED_BUSIF s_axi, ASSOCIATED_RESET s_axi_aresetn, FREQ_HZ 49999500" *)
    input wire s_axi_aclk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST",
       X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axi_aresetn, POLARITY ACTIVE_LOW" *)
    input wire s_axi_aresetn,
    input wire [11:0] adc_data_a_i,
    input wire [11:0] adc_data_b_i,
    input wire adc_otr_a_i,
    input wire adc_otr_b_i,
    (* IOB = "TRUE", DONT_TOUCH = "TRUE" *) output reg adc_clk_a_o,
    (* IOB = "TRUE", DONT_TOUCH = "TRUE" *) output reg adc_clk_b_o,
    output wire [63:0] debug_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWADDR",
       X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axi, PROTOCOL AXI4LITE, DATA_WIDTH 32, ADDR_WIDTH 12, READ_WRITE_MODE READ_WRITE, FREQ_HZ 49999500" *)
    input wire [11:0] s_axi_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWPROT" *) input wire [2:0] s_axi_awprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWVALID" *) input wire s_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWREADY" *) output wire s_axi_awready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WDATA" *) input wire [31:0] s_axi_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WSTRB" *) input wire [3:0] s_axi_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WVALID" *) input wire s_axi_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WREADY" *) output wire s_axi_wready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BRESP" *) output wire [1:0] s_axi_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BVALID" *) output reg s_axi_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BREADY" *) input wire s_axi_bready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARADDR" *) input wire [11:0] s_axi_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARPROT" *) input wire [2:0] s_axi_arprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARVALID" *) input wire s_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARREADY" *) output wire s_axi_arready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RDATA" *) output wire [31:0] s_axi_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RRESP" *) output wire [1:0] s_axi_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RVALID" *) output wire s_axi_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RREADY" *) input wire s_axi_rready
);
    reg [3:0] adc_phase;
    reg [63:0] tick, sample_tick;
    integer observe_phase;
    wire capture_event = s_axi_aresetn && adc_phase == 4;
    wire observe_select = capture_event && observe_phase == 0;
    reg [11:0] captured_a, captured_b;
    reg [1:0] captured_otr;

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            adc_phase <= 0;tick <= 0;sample_tick <= 0;observe_phase <= 0;
            adc_clk_a_o <= 0;adc_clk_b_o <= 0;
            captured_a <= 0;captured_b <= 0;captured_otr <= 0;
        end else begin
            tick <= tick + 1'b1;
            adc_phase <= adc_phase == 9 ? 0 : adc_phase + 1'b1;
            if (adc_phase == 0) begin
                adc_clk_a_o <= 1;adc_clk_b_o <= 1;sample_tick <= tick;
            end else if (adc_phase == 5) begin
                adc_clk_a_o <= 0;adc_clk_b_o <= 0;
            end
            if (capture_event) begin
                captured_a <= adc_data_a_i;captured_b <= adc_data_b_i;
                captured_otr <= {adc_otr_b_i,adc_otr_a_i};
                observe_phase <= observe_phase == OBSERVE_CONVERSIONS-1 ? 0 : observe_phase + 1;
            end
        end
    end

    wire pair_strobe,pair_complete,pair_valid_a,pair_valid_b;
    wire [11:0] pair_a,pair_b;
    wire [1:0] pair_otr;
    wire [31:0] pair_id;
    wire [63:0] pair_tick;
    ax03b1_adc_receiver #(.META_WIDTH(64),.PIPELINE_EVENTS(7)) receiver (
        .clk(s_axi_aclk),.rst(!s_axi_aresetn),.sample_ce(capture_event),
        .observe_select(observe_select),.raw_a(adc_data_a_i),.raw_b(adc_data_b_i),
        .valid_a(1'b1),.valid_b(1'b1),.otr_a(adc_otr_a_i),.otr_b(adc_otr_b_i),
        .sample_meta(sample_tick),.pair_strobe(pair_strobe),.pair_complete(pair_complete),
        .pair_valid_a(pair_valid_a),.pair_valid_b(pair_valid_b),.pair_a(pair_a),.pair_b(pair_b),
        .pair_otr(pair_otr),.pair_id(pair_id),.pair_meta(pair_tick)
    );
    // Same 32-word B1 snapshot schema and offsets. Raw acquisition is complete
    // even while current/ABZ fields are deliberately uncalibrated/unconnected.
    reg [1023:0] payload;
    reg [31:0] quality;
    always @* begin
        quality=0;
        quality[0]=pair_valid_a;quality[1]=pair_valid_b;quality[2]=pair_complete;
        quality[3]=pair_otr[0];quality[4]=pair_otr[1];
        // Current done/valid and ABZ ready/Z-seen remain zero. Physical link
        // is not verified by a bitstream or a changing code; bit 17 stays zero.
        payload=0;
        payload[0*32+:32]=32'h42324f42; // B2OB, schema 1
        payload[1*32+:32]=1;
        payload[2*32+:32]=quality;
        payload[3*32+:32]=pair_id;
        payload[4*32+:64]=pair_tick;
        payload[6*32+:32]={20'd0,pair_a};payload[7*32+:32]={20'd0,pair_b};
        payload[21*32+:32]=32'h30 | {28'd0,pair_otr,2'd0}; // B1 OTR + uncalibrated bits
        payload[22*32+:32]=24;payload[23*32+:32]=16;
        payload[24*32+:32]=7;payload[25*32+:32]=10;
        payload[26*32+:32]=OBSERVE_CONVERSIONS*10;
        // word 27 filter_cycles=0 explicitly denotes ABZ not connected.
    end
    ax03b1_snapshot_axi #(.SNAP_WORDS(32),.ADDR_WIDTH(12)) snapshot (
        .clk(s_axi_aclk),.rst_n(s_axi_aresetn),.publish_i(pair_strobe),
        .payload_i(payload),.epoch_i(32'h42320001),
        .s_axi_araddr(s_axi_araddr),.s_axi_arvalid(s_axi_arvalid),.s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),.s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),.s_axi_rready(s_axi_rready)
    );
    // The hardware wrapper provides the AXI write channels required by BD.
    // This peripheral is read-only: consume one independent AW and W beat,
    // then acknowledge SLVERR. There is no writeable state or control path.
    reg aw_seen,w_seen;
    assign s_axi_awready=s_axi_aresetn && !aw_seen && !s_axi_bvalid;
    assign s_axi_wready=s_axi_aresetn && !w_seen && !s_axi_bvalid;
    assign s_axi_bresp=2'b10;
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin aw_seen<=0;w_seen<=0;s_axi_bvalid<=0;end
        else begin
            if (s_axi_awvalid && s_axi_awready) aw_seen<=1;
            if (s_axi_wvalid && s_axi_wready) w_seen<=1;
            if (aw_seen && w_seen && !s_axi_bvalid) s_axi_bvalid<=1;
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid<=0;aw_seen<=0;w_seen<=0;
            end
        end
    end
    // ILA probe0: [11:0] rawA, [23:12] rawB, [25:24] OTR{B,A},
    // [26] capture, [27] selected capture, [28] publish, [60:29] sample_id.
    assign debug_o={3'd0,pair_id,pair_strobe,observe_select,capture_event,
                    captured_otr,captured_b,captured_a};
endmodule
