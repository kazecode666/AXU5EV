`timescale 1ns/1ps
// AX-03B3 J15 current observer, using unchanged generated B1 arithmetic. A single 50 MHz logic domain forwards two
// in-phase 5 MHz clocks. The ADC samples on their rising edges; capture is
// four logic periods (80 ns) later, after the specified output tPD window.
// No motor, ABZ, control Runtime or power outputs. Calibration is explicit.
module ax03b3_adc_observer #(
    parameter integer TEST_INPUT = 0,
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
    // Registered look-ahead only; original ADC clocks/capture/selection unchanged.
    output reg pwm_anchor_o,
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
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BRESP" *) output reg [1:0] s_axi_bresp,
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
            pwm_anchor_o <= 0;
        end else begin
            pwm_anchor_o <= (adc_phase == 8 && observe_phase == 0);
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
    // Commit occurs between selected returns; AW/W are independently retained.
    reg [31:0] shadow [0:5];
    reg [11:0] awaddr;
    reg [31:0] wdata;
    reg [3:0] wstrb;
    reg cal_en,apply,restart;
    wire signed [31:0] ia,ib,ic,oa,ob;
    wire [15:0] ca,cb,error;
    wire [31:0] version;
    wire da,db,valid,clip,result_strobe;
    reg [31:0] test_index;
    // Alternating codes give independent fractional means (2000.5,2100.5).
    // Once calibrated, alternate positive/negative increments on both channels.
    wire [11:0] raw_a = TEST_INPUT ? (da ? (test_index[0]?12'd2010:12'd1990) : (12'd2000+test_index[0])) : pair_a;
    wire [11:0] raw_b = TEST_INPUT ? (db ? (test_index[0]?12'd2080:12'd2120) : (12'd2100+test_index[0])) : pair_b;
    wire [1:0] otr = TEST_INPUT ? 2'b0 : pair_otr;
    reg [11:0] aligned_a,aligned_b;
    always @(posedge s_axi_aclk) begin
      if (!s_axi_aresetn) begin test_index<=0;aligned_a<=0;aligned_b<=0;end
      else begin
        if (apply || restart) test_index<=0;
        else if(pair_strobe) test_index<=test_index+1;
        if(pair_strobe) begin aligned_a<=raw_a;aligned_b<=raw_b;end
      end
    end
    ax03b1_current_adapter current(
      .clk(s_axi_aclk),.rst(!s_axi_aresetn),.sample_strobe(pair_strobe),
      .raw_a({4'b0,raw_a}),.raw_b({4'b0,raw_b}),
      .capture_valid_a(pair_valid_a),.capture_valid_b(pair_valid_b),
      .otr_a(otr[0]),.otr_b(otr[1]),.cal_en(cal_en),.cal_restart(restart),
      .config_apply(apply),.config_version(shadow[5]),
      .offset_seed_a_q16(shadow[0]),.offset_seed_b_q16(shadow[1]),
      .manual_valid_a(1'b0),.manual_valid_b(1'b0),
      .gain_a_q24(shadow[2]),.gain_b_q24(shadow[3]),.cal_log2_n(shadow[4][7:0]),
      .ia_q24(ia),.ib_q24(ib),.ic_q24(ic),.offset_a_q16(oa),.offset_b_q16(ob),
      .cal_count_a(ca),.cal_count_b(cb),.cal_done_a(da),.cal_done_b(db),
      .cal_version(version),.valid(valid),.clip(clip),.error(error),.result_strobe(result_strobe));
    reg [1023:0] payload;
    reg [31:0] quality;
    always @* begin
        quality=0;
        quality[0]=pair_valid_a;quality[1]=pair_valid_b;quality[2]=pair_complete;
        quality[3]=otr[0];quality[4]=otr[1];
        quality[5]=da;quality[6]=db;quality[7]=valid;quality[8]=clip;quality[16]=TEST_INPUT;
        // ABZ ready/Z-seen remain zero. Physical link
        // is not verified by a bitstream or a changing code; bit 17 stays zero.
        payload=0;
        payload[0*32+:32]=32'h42334f42; // B3OB, schema 1
        payload[1*32+:32]=1;
        payload[2*32+:32]=quality;
        payload[3*32+:32]=pair_id;
        payload[4*32+:64]=pair_tick;
        payload[6*32+:32]={20'd0,aligned_a};payload[7*32+:32]={20'd0,aligned_b};
        payload[8*32+:32]=ia;payload[9*32+:32]=ib;payload[10*32+:32]=ic;
        payload[11*32+:32]=oa;payload[12*32+:32]=ob;
        payload[13*32+:32]={16'b0,ca};payload[14*32+:32]={16'b0,cb};
        payload[15*32+:32]=version;
        payload[21*32+:32]={16'b0,error}; // B1 OTR + uncalibrated bits
        payload[22*32+:32]=24;payload[23*32+:32]=16;
        payload[24*32+:32]=7;payload[25*32+:32]=10;
        payload[26*32+:32]=OBSERVE_CONVERSIONS*10;
        // word 27 filter_cycles=0 explicitly denotes ABZ not connected.
    end
    ax03b1_snapshot_axi #(.SNAP_WORDS(32),.ADDR_WIDTH(12)) snapshot (
        .clk(s_axi_aclk),.rst_n(s_axi_aresetn),.publish_i(result_strobe),
        .payload_i(payload),.epoch_i(32'h42330001),
        .s_axi_araddr(s_axi_araddr),.s_axi_arvalid(s_axi_arvalid),.s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),.s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),.s_axi_rready(s_axi_rready)
    );
    reg aw_seen,w_seen;
    integer i;
    assign s_axi_awready=s_axi_aresetn && !aw_seen && !s_axi_bvalid;
    assign s_axi_wready=s_axi_aresetn && !w_seen && !s_axi_bvalid;
    always @(posedge s_axi_aclk) begin
      if(!s_axi_aresetn) begin
        aw_seen<=0;w_seen<=0;s_axi_bvalid<=0;s_axi_bresp<=0;
        cal_en<=0;apply<=0;restart<=0;awaddr<=0;wdata<=0;wstrb<=0;
        for(i=0;i<6;i=i+1) shadow[i]<=0;
      end else begin
        apply<=0;restart<=0;
        if(s_axi_awvalid && s_axi_awready) begin aw_seen<=1;awaddr<=s_axi_awaddr;end
        if(s_axi_wvalid && s_axi_wready) begin w_seen<=1;wdata<=s_axi_wdata;wstrb<=s_axi_wstrb;end
        // phase 8 is safely after receiver/result publication (capture phase 4).
        // Apply is consumed on phase 9, never coinciding with selected sampling.
        if(aw_seen && w_seen && !s_axi_bvalid && adc_phase==8) begin
          s_axi_bvalid<=1;s_axi_bresp<=0;
          if(wstrb!=4'hf) s_axi_bresp<=2;
          else if(awaddr>=12'h100 && awaddr<=12'h114 && awaddr[1:0]==0)
            shadow[(awaddr-12'h100)>>2]<=wdata;
          else if(awaddr==12'h118) begin
            apply<=wdata[0];restart<=wdata[1] && !wdata[0];cal_en<=wdata[2];
          end else s_axi_bresp<=2;
        end
        if(s_axi_bvalid && s_axi_bready) begin s_axi_bvalid<=0;aw_seen<=0;w_seen<=0;end
      end
    end
    // ILA probe0: [11:0] rawA, [23:12] rawB, [25:24] OTR{B,A},
    // [26] capture, [27] selected capture, [28] publish, [60:29] sample_id.
    assign debug_o={3'd0,pair_id,result_strobe,observe_select,capture_event,
                    captured_otr,captured_b,captured_a};
endmodule
