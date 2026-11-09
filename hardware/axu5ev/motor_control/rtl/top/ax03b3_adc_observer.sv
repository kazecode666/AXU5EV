`timescale 1ns/1ps
// AX-03B3 J15 current observer, using unchanged generated B1 arithmetic. A single 50 MHz logic domain forwards two
// in-phase 5 MHz clocks. The ADC samples on their rising edges; capture is
// four logic periods (80 ns) later, after the specified output tPD window.
// Optional encoder feedback uses the existing B1 receiver. No control Runtime
// or power outputs. Calibration and synthetic encoder motion are explicit.
module ax03b3_adc_observer #(
    parameter integer TEST_INPUT = 0,
    parameter integer OBSERVE_CONVERSIONS = 500,
    parameter integer ENCODER_FEEDBACK = 0,
    parameter integer TEST_ABZ = 0,
    parameter integer AUTO_CONTROL = 0,
    parameter [31:0] ENCODER_INITIAL_COUNT = 0
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
    input wire abz_a_i, abz_b_i, abz_z_i,
    (* IOB = "TRUE", DONT_TOUCH = "TRUE" *) output reg adc_clk_a_o,
    (* IOB = "TRUE", DONT_TOUCH = "TRUE" *) output reg adc_clk_b_o,
    output wire [63:0] debug_o,
    // Registered look-ahead only; original ADC clocks/capture/selection unchanged.
    output reg pwm_anchor_o,
    output wire auto_valid_o,
    output wire [38:0] auto_compare_o,
    output wire [31:0] auto_seq_o,
    output wire auto_inhibit_o,
    input wire auto_ready_i, auto_online_i,
    input wire [31:0] auto_applied_seq_i,
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
    import encoder_scale_pkg::*;
    reg [3:0] adc_phase;
    reg [63:0] tick, sample_tick;
    integer observe_phase;
    wire capture_event = s_axi_aresetn && adc_phase == 4;
    wire observe_select = capture_event && observe_phase == 0;
    reg [11:0] captured_a, captured_b;
    reg [1:0] captured_otr;
    localparam integer META_WIDTH = ENCODER_FEEDBACK ? 323 : 64;
    wire [31:0] enc_count, enc_illegal, enc_z_count;
    wire [63:0] enc_z_tick;
    wire enc_ready, enc_z_seen;
    reg [31:0] enc_shadow_zero, enc_shadow_phase, enc_shadow_version;
    reg enc_shadow_direction, enc_pending, test_abz_enable;
    reg [31:0] enc_frozen_zero, enc_frozen_phase, enc_frozen_version;
    reg enc_frozen_direction;
    reg [31:0] enc_active_zero, enc_active_phase, enc_active_version;
    reg enc_active_direction;
    reg [31:0] ref_shadow[0:7],ref_frozen[0:7],ref_active[0:7];
    reg ref_pending,manual_disarm;
    reg [258:0] sample_encoder;
    wire [31:0] selected_zero = enc_pending && observe_phase==0 ? enc_frozen_zero : enc_active_zero;
    wire [31:0] selected_phase = enc_pending && observe_phase==0 ? enc_frozen_phase : enc_active_phase;
    wire [31:0] selected_version = enc_pending && observe_phase==0 ? enc_frozen_version : enc_active_version;
    wire selected_direction = enc_pending && observe_phase==0 ? enc_frozen_direction : enc_active_direction;
    generate if(ENCODER_FEEDBACK) begin: encoder
      reg [8:0] test_div;
      reg [7:0] test_steps;
      always @(posedge s_axi_aclk) begin
        if(!s_axi_aresetn) begin test_div<=0;test_steps<=0;end
        else if(test_abz_enable) begin
          if(test_div==499) begin test_div<=0;test_steps<=test_steps+1'b1;end
          else test_div<=test_div+1'b1;
        end
      end
      wire [1:0] test_ab={test_steps[1],test_steps[1]^test_steps[0]};
      ax03b1_abz_receiver #(.FILTER_CYCLES(2),.INITIAL_COUNT(ENCODER_INITIAL_COUNT)) receiver(
        .clk(s_axi_aclk),.rst(!s_axi_aresetn),.tick(tick),
        .a_async(TEST_ABZ ? test_ab[1] : abz_a_i),
        .b_async(TEST_ABZ ? test_ab[0] : abz_b_i),
        .z_async(TEST_ABZ ? test_steps[5] : abz_z_i),
        .q_count(enc_count),.ab_ready(enc_ready),.illegal_count(enc_illegal),
        .z_seen(enc_z_seen),.z_count(enc_z_count),.z_tick(enc_z_tick));
    end else begin: no_encoder
      assign enc_count=0;assign enc_illegal=0;assign enc_z_count=0;
      assign enc_z_tick=0;assign enc_ready=0;assign enc_z_seen=0;
    end endgenerate

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            adc_phase <= 0;tick <= 0;sample_tick <= 0;observe_phase <= 0;
            adc_clk_a_o <= 0;adc_clk_b_o <= 0;
            captured_a <= 0;captured_b <= 0;captured_otr <= 0;
            pwm_anchor_o <= 0;
            sample_encoder <= 0;
        end else begin
            pwm_anchor_o <= (adc_phase == 8 && observe_phase == 0);
            tick <= tick + 1'b1;
            adc_phase <= adc_phase == 9 ? 0 : adc_phase + 1'b1;
            if (adc_phase == 0) begin
                adc_clk_a_o <= 1;adc_clk_b_o <= 1;sample_tick <= tick;
                // Same-edge AB/Z acceptance is deliberately observed BEFORE update.
                sample_encoder <= {selected_zero,selected_phase,selected_direction,selected_version,
                  enc_ready,enc_z_seen,enc_illegal,enc_z_tick,enc_z_count,enc_count};
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
    wire [31:0] next_sample_id;
    wire [63:0] pair_tick;
    wire [META_WIDTH-1:0] sample_meta, pair_meta;
    assign sample_meta = ENCODER_FEEDBACK ? {sample_encoder,sample_tick} : sample_tick;
    assign pair_tick=pair_meta[63:0];
    wire [258:0] pair_encoder=pair_meta >> 64;
    wire [31:0] frame_zero,frame_phase,frame_version,frame_count,frame_z_count,frame_illegal;
    wire frame_direction,frame_ready,frame_z_seen;
    wire [63:0] frame_z_tick;
    assign {frame_zero,frame_phase,frame_direction,frame_version,
      frame_ready,frame_z_seen,frame_illegal,frame_z_tick,frame_z_count,frame_count}=pair_encoder;
    ax03b1_adc_receiver #(.META_WIDTH(META_WIDTH),.PIPELINE_EVENTS(7)) receiver (
        .clk(s_axi_aclk),.rst(!s_axi_aresetn),.sample_ce(capture_event),
        .observe_select(observe_select),.raw_a(adc_data_a_i),.raw_b(adc_data_b_i),
        .valid_a(1'b1),.valid_b(1'b1),.otr_a(adc_otr_a_i),.otr_b(adc_otr_b_i),
        .sample_meta(sample_meta),.pair_strobe(pair_strobe),.pair_complete(pair_complete),
        .pair_valid_a(pair_valid_a),.pair_valid_b(pair_valid_b),.pair_a(pair_a),.pair_b(pair_b),
        .pair_otr(pair_otr),.pair_id(pair_id),.pair_meta(pair_meta),.next_sample_id_o(next_sample_id)
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
    reg [1023:0] base_payload;
    localparam integer SNAP_WORDS=AUTO_CONTROL ? 80 : (ENCODER_FEEDBACK ? 41 : 32);
    reg [SNAP_WORDS*32-1:0] payload;
    wire publish_strobe;
    wire signed [63:0] theta_q32;
    wire angle_valid,angle_strobe;
    wire [31:0] angle_version;
    generate if(ENCODER_FEEDBACK) begin: angle_path
      Encoder_Angle generated_angle(.clk(s_axi_aclk),.reset(!s_axi_aresetn),.clk_enable(1'b1),
        .sample_strobe(pair_strobe),.count(frame_count),.ready(frame_ready),
        .zero_count(frame_zero),.phase_offset_count(frame_phase[15:0]),
        .direction(frame_direction),.config_version(frame_version),
        .theta_q32(theta_q32),.valid(angle_valid),.result_strobe(angle_strobe),
        .version(angle_version),.phase_count(),.ce_out());
      reg [1023:0] current_frame;
      reg current_ready,theta_ready;
      reg signed [63:0] theta_frame;
      reg theta_valid_frame;
      reg [31:0] theta_version_frame;
      // One selected frame per 5000 clocks; join independent numerical paths.
      // Neither result event nor current calibration is an encoder validity gate.
      always @(posedge s_axi_aclk) begin
        if(!s_axi_aresetn) begin
          current_frame<=0;current_ready<=0;theta_ready<=0;
          theta_frame<=0;theta_valid_frame<=0;theta_version_frame<=0;
        end else begin
          if(result_strobe) begin current_frame<=base_payload;current_ready<=1;end
          if(angle_strobe) begin
            theta_frame<=theta_q32;theta_valid_frame<=angle_valid;
            theta_version_frame<=angle_version;theta_ready<=1;
          end
          if(publish_strobe) begin current_ready<=0;theta_ready<=0;end
        end
      end
      assign publish_strobe=current_ready && theta_ready;
      always @* begin
        payload=0;payload[1023:0]=current_frame;
        payload[0*32+:32]=32'h454e4346;payload[1*32+:32]=2;
        payload[2*32+9]=frame_ready;payload[2*32+10]=frame_z_seen;
        payload[2*32+11]=theta_valid_frame;payload[2*32+18]=TEST_ABZ;
        payload[16*32+:32]=frame_count;payload[17*32+:32]=frame_z_count;
        payload[18*32+:64]=frame_z_tick;payload[20*32+:32]=frame_illegal;
        payload[27*32+:32]=2;
        payload[28*32+:32]=1; // Current generated latency unchanged: one clock.
        payload[32*32+:64]=theta_frame;
        payload[34*32+:32]=theta_version_frame;
        payload[35*32+:32]=frame_zero;payload[36*32+:32]=frame_phase;
        payload[37*32+:32]={31'b0,frame_direction};
        payload[38*32+:32]={29'b0,1'b0,theta_valid_frame,frame_ready} | (TEST_ABZ ? 4:0);
        payload[29*32+:32]=34; // Encoder generated latency, measured by model/RTL.
        payload[39*32+:32]=ENCODER_COUNTS_PER_PERIOD;
        payload[40*32+:32]=ENCODER_NM_PER_COUNT;
      end
    end else begin: legacy_payload
      assign publish_strobe=result_strobe;
      assign theta_q32=0;assign angle_valid=0;assign angle_strobe=0;assign angle_version=0;
      always @* payload=base_payload;
    end endgenerate
    wire [1023:0] control_debug;
    wire control_status_strobe;
    wire [SNAP_WORDS*32-1:0] snapshot_payload;
    wire snapshot_strobe;
    generate if(AUTO_CONTROL) begin: auto_path
      reg [SNAP_WORDS*32-1:0] feedback_bank,control_bank;
      reg bank_strobe;
      // The feedback event remains P110. Publish schema3 after the controller's
      // fixed post-valley status event, joining the SAME captured feedback bank.
      always @(posedge s_axi_aclk) begin
        if(!s_axi_aresetn) begin feedback_bank<=0;control_bank<=0;bank_strobe<=0;end
        else begin
          bank_strobe<=control_status_strobe;
          if(publish_strobe) feedback_bank<=payload;
          if(control_status_strobe) begin
            control_bank<=feedback_bank;
            control_bank[0+:32]<=32'h4d435431;control_bank[32+:32]<=3;
            control_bank[41*32+:1024]<=control_debug;
          end
        end
      end
      motor_foc_control controller(.clk(s_axi_aclk),.rst(!s_axi_aresetn),
        .sample_event(adc_phase==0 && observe_phase==0),.sample_tick(tick),.sample_id(next_sample_id),
        .feedback_event(publish_strobe),
        .feedback_valid(payload[2*32+7] && payload[2*32+9] && payload[2*32+11] &&
          !payload[2*32+3] && !payload[2*32+4] && !payload[2*32+8] && frame_illegal==0),
        .feedback_id(payload[3*32+:32]),.feedback_tick(payload[4*32+:64]),
        .ia(payload[8*32+:32]),.ib(payload[9*32+:32]),.ic(payload[10*32+:32]),
        .theta_e(payload[32*32+:40]),
        .ref_id(ref_active[0]),.ref_iq(ref_active[1]),.ref_omega({ref_active[3][7:0],ref_active[2]}),
        .ref_vdc(ref_active[4]),.ref_pi_reset(ref_active[5][0]),.ref_version(ref_active[6]),.ref_arm(ref_active[7][0]),
        .invalidate(apply || restart || manual_disarm),
        .auto_ready(auto_ready_i),.auto_online(auto_online_i),.auto_applied_seq(auto_applied_seq_i),
        .auto_valid(auto_valid_o),.auto_compare(auto_compare_o),.auto_seq(auto_seq_o),.auto_inhibit(auto_inhibit_o),
        .debug_o(control_debug),.status_strobe(control_status_strobe));
      assign snapshot_payload=control_bank;assign snapshot_strobe=bank_strobe;
    end else begin: no_auto_control
      assign auto_valid_o=0;assign auto_compare_o=0;assign auto_seq_o=0;assign auto_inhibit_o=1;
      assign control_debug=0;assign control_status_strobe=0;
      assign snapshot_payload=payload;assign snapshot_strobe=publish_strobe;
    end endgenerate
    reg [31:0] quality;
    always @* begin
        quality=0;
        quality[0]=pair_valid_a;quality[1]=pair_valid_b;quality[2]=pair_complete;
        quality[3]=otr[0];quality[4]=otr[1];
        quality[5]=da;quality[6]=db;quality[7]=valid;quality[8]=clip;quality[16]=TEST_INPUT;
        // ABZ ready/Z-seen remain zero. Physical link
        // is not verified by a bitstream or a changing code; bit 17 stays zero.
        base_payload=0;
        base_payload[0*32+:32]=32'h42334f42; // B3OB, schema 1
        base_payload[1*32+:32]=1;
        base_payload[2*32+:32]=quality;
        base_payload[3*32+:32]=pair_id;
        base_payload[4*32+:64]=pair_tick;
        base_payload[6*32+:32]={20'd0,aligned_a};base_payload[7*32+:32]={20'd0,aligned_b};
        base_payload[8*32+:32]=ia;base_payload[9*32+:32]=ib;base_payload[10*32+:32]=ic;
        base_payload[11*32+:32]=oa;base_payload[12*32+:32]=ob;
        base_payload[13*32+:32]={16'b0,ca};base_payload[14*32+:32]={16'b0,cb};
        base_payload[15*32+:32]=version;
        base_payload[21*32+:32]={16'b0,error}; // B1 OTR + uncalibrated bits
        base_payload[22*32+:32]=24;base_payload[23*32+:32]=16;
        base_payload[24*32+:32]=7;base_payload[25*32+:32]=10;
        base_payload[26*32+:32]=OBSERVE_CONVERSIONS*10;
        // word 27 filter_cycles=0 explicitly denotes ABZ not connected.
    end
    ax03b1_snapshot_axi #(.SNAP_WORDS(SNAP_WORDS),.ADDR_WIDTH(12)) snapshot (
        .clk(s_axi_aclk),.rst_n(s_axi_aresetn),.publish_i(snapshot_strobe),
        .payload_i(snapshot_payload),.epoch_i(AUTO_CONTROL ? 32'h4d430003 : (ENCODER_FEEDBACK ? 32'h454e0002 : 32'h42330001)),
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
        enc_shadow_zero<=0;enc_shadow_phase<=0;enc_shadow_direction<=0;enc_shadow_version<=0;
        enc_frozen_zero<=0;enc_frozen_phase<=0;enc_frozen_direction<=0;enc_frozen_version<=0;
        enc_active_zero<=0;enc_active_phase<=0;enc_active_direction<=0;enc_active_version<=0;
        enc_pending<=0;test_abz_enable<=0;
        ref_pending<=0;manual_disarm<=1;
        for(i=0;i<8;i=i+1) begin ref_shadow[i]<=0;ref_frozen[i]<=0;ref_active[i]<=0;end
        ref_shadow[4]<=32'd805306368;ref_frozen[4]<=32'd805306368;ref_active[4]<=32'd805306368;
        ref_shadow[5]<=1;ref_frozen[5]<=1;ref_active[5]<=1;
        for(i=0;i<6;i=i+1) shadow[i]<=0;
      end else begin
        apply<=0;restart<=0;
        if(adc_phase==0 && observe_phase==0 && ref_pending) begin
          for(i=0;i<8;i=i+1) ref_active[i]<=ref_frozen[i];
          ref_pending<=0;manual_disarm<=!ref_frozen[7][0];
        end
        if(adc_phase==0 && observe_phase==0 && enc_pending) begin
          enc_active_zero<=enc_frozen_zero;enc_active_phase<=enc_frozen_phase;
          enc_active_direction<=enc_frozen_direction;enc_active_version<=enc_frozen_version;
          enc_pending<=0;
        end
        if(s_axi_awvalid && s_axi_awready) begin aw_seen<=1;awaddr<=s_axi_awaddr;end
        if(s_axi_wvalid && s_axi_wready) begin w_seen<=1;wdata<=s_axi_wdata;wstrb<=s_axi_wstrb;end
        // Preserve the original current command phase. Encoder configuration
        // is frozen separately and adopted on the next selected sample phase0.
        if(aw_seen && w_seen && !s_axi_bvalid && adc_phase==8) begin
          s_axi_bvalid<=1;s_axi_bresp<=0;
          if(wstrb!=4'hf) s_axi_bresp<=2;
          else if(awaddr>=12'h100 && awaddr<=12'h114 && awaddr[1:0]==0)
            shadow[(awaddr-12'h100)>>2]<=wdata;
          else if(awaddr==12'h118) begin
            apply<=wdata[0];restart<=wdata[1] && !wdata[0];cal_en<=wdata[2];
          end else if(ENCODER_FEEDBACK && awaddr==12'h140) enc_shadow_zero<=wdata;
          else if(ENCODER_FEEDBACK && awaddr==12'h144 && wdata<ENCODER_COUNTS_PER_PERIOD) enc_shadow_phase<=wdata;
          else if(ENCODER_FEEDBACK && awaddr==12'h148 && wdata<=1) enc_shadow_direction<=wdata[0];
          else if(ENCODER_FEEDBACK && awaddr==12'h14c) enc_shadow_version<=wdata;
          else if(ENCODER_FEEDBACK && awaddr==12'h150) begin
            if(wdata[0] && enc_pending) s_axi_bresp<=2;
            else begin
              test_abz_enable<=wdata[1];
              if(wdata[0]) begin
                enc_frozen_zero<=enc_shadow_zero;enc_frozen_phase<=enc_shadow_phase;
                enc_frozen_direction<=enc_shadow_direction;enc_frozen_version<=enc_shadow_version;
                enc_pending<=1;
              end
            end
          end else if(AUTO_CONTROL && awaddr>=12'h180 && awaddr<=12'h19c && awaddr[1:0]==0)
            ref_shadow[(awaddr-12'h180)>>2]<=wdata;
          else if(AUTO_CONTROL && awaddr==12'h1a0 && wdata==1) begin
            if(ref_pending) s_axi_bresp<=2;
            else begin
              for(i=0;i<8;i=i+1) ref_frozen[i]<=ref_shadow[i];
              ref_pending<=1;
            end
          end else if(AUTO_CONTROL && awaddr==12'h1a4 && wdata==1) begin
            manual_disarm<=1;
            ref_pending<=0; // A pre-disarm arm command must not revive at P0.
          end
          else s_axi_bresp<=2;
        end
        if(s_axi_bvalid && s_axi_bready) begin s_axi_bvalid<=0;aw_seen<=0;w_seen<=0;end
      end
    end
    // ILA probe0: [11:0] rawA, [23:12] rawB, [25:24] OTR{B,A},
    // [26] capture, [27] selected capture, [28] publish, [60:29] sample_id.
    assign debug_o={3'd0,pair_id,publish_strobe,observe_select,capture_event,
                    captured_otr,captured_b,captured_a};
endmodule
