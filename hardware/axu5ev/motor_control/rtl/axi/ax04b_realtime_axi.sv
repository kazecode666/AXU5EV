`timescale 1ns/1ps
// Same-clock AXI4-Lite feedback and reference endpoint. The observer, selected
// P0 event, SmartConnect and this endpoint share s_axi_aclk. Raw fast fault is
// an immediate output veto. Its synchronized version is used by the state.
module ax04b_realtime_axi #(
    parameter integer SELFTEST = 1,
    parameter integer ADDR_WIDTH = 12,
    parameter integer FRAME_CYCLES = 5000,
    parameter integer DEADLINE_GUARD_CYCLES = 16,
    parameter integer WATCHDOG_CYCLES = 10000,
    parameter [31:0] SEQ_RESET = 0
) (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axi_aclk, ASSOCIATED_BUSIF s_axi, ASSOCIATED_RESET s_axi_aresetn, FREQ_HZ 49999500" *)
    input wire s_axi_aclk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axi_aresetn, POLARITY ACTIVE_LOW" *)
    input wire s_axi_aresetn,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWADDR",
       X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axi, PROTOCOL AXI4LITE, DATA_WIDTH 32, ADDR_WIDTH 12, READ_WRITE_MODE READ_WRITE, FREQ_HZ 49999500" *)
    input wire [ADDR_WIDTH-1:0] s_axi_awaddr,
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
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARADDR" *) input wire [ADDR_WIDTH-1:0] s_axi_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARPROT" *) input wire [2:0] s_axi_arprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARVALID" *) input wire s_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARREADY" *) output wire s_axi_arready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RDATA" *) output reg [31:0] s_axi_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RRESP" *) output reg [1:0] s_axi_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RVALID" *) output reg s_axi_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RREADY" *) input wire s_axi_rready,
    input wire frame_publish_i,
    input wire [287:0] frame_data_i,
    input wire p0_i,
    input wire [31:0] p0_sample_id_i,
    input wire fast_fault_i,
    input wire invalidate_i,
    (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 irq INTERRUPT" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME irq, SENSITIVITY LEVEL_HIGH" *)
    output wire irq_o,
    output reg [255:0] active_reference_o,
    output reg active_valid_o,
    output wire inhibit_o,
    output reg armed_o,
    output reg [31:0] active_target_o,
    output reg ctrl_enable_o
);
    localparam [1:0] OKAY = 2'b00, SLVERR = 2'b10;
    localparam [31:0] IDENTITY = 32'h41584201;
    localparam [31:0] COMMIT_KEY = 32'h434f4d4d;
    localparam [31:0] SAMPLE_ID_STEP = 32'd500;
    localparam signed [31:0] ID_LIMIT_Q24 = 32'sd8388608, IQ_LIMIT_Q24 = 32'sd5033165;
    localparam [63:0] ELECTRICAL_TURN_Q32 = 64'd26986075409;
    localparam [ADDR_WIDTH-1:0] FRAME_FIRST = 'h30, FRAME_LAST = 'h50,
        ACK = 'h80, CONTROL = 'h84, SHADOW_TARGET = 'h88, COMMIT = 'h8c,
        IO_CTRL = 'h90, REF_FIRST = 'ha0, REF_LAST = 'hbc;
    localparam [31:0] STOP = 1, CLEAR = 2, ARM = 4;
    localparam [2:0] ACCEPT = 1, LATE = 2, BUSY = 3, INCOMPLETE = 4,
        OLD_VERSION = 5, SAFETY = 6;
    localparam integer P0_AGE_WIDTH = $clog2(FRAME_CYCLES+1);
    localparam integer REF_AGE_WIDTH = $clog2(WATCHDOG_CYCLES+1);
    localparam [P0_AGE_WIDTH-1:0] FRAME_LIMIT = FRAME_CYCLES;
    localparam [P0_AGE_WIDTH-1:0] COMMIT_LIMIT = FRAME_CYCLES-DEADLINE_GUARD_CYCLES;
    localparam [REF_AGE_WIDTH-1:0] REF_LIMIT = WATCHDOG_CYCLES;

    reg aw_seen, w_seen;
    reg [ADDR_WIDTH-1:0] awaddr;
    reg [31:0] wdata;
    reg [3:0] wstrb;
    wire write_fire = aw_seen && w_seen && !s_axi_bvalid;
    wire word_write = write_fire && wstrb == 4'hf;
    assign s_axi_awready = s_axi_aresetn && !aw_seen && !s_axi_bvalid;
    assign s_axi_wready = s_axi_aresetn && !w_seen && !s_axi_bvalid;
    assign s_axi_arready = s_axi_aresetn && !s_axi_rvalid;

    reg [287:0] pending_frame;
    reg [31:0] pending_seq, event_seq, overrun_count;
    reg pending, overrun, frame_seen;
    reg [287:0] last_observed_frame;
    wire new_event = frame_publish_i && (!frame_seen || frame_data_i != last_observed_frame);
    wire exact_ack = word_write && awaddr == ACK && pending && wdata == pending_seq;
    wire overrun_now = new_event && pending && !exact_ack;

    reg [255:0] shadow_ref, queued_ref;
    reg [31:0] shadow_target, queued_target;
    reg [8:0] shadow_written;
    reg queued, accepted_seen, applied_seen;
    reg [31:0] accepted_version, accepted_target, applied_version;
    reg [2:0] commit_result;
    reg [31:0] p0_id;
    reg p0_seen;
    reg [P0_AGE_WIDTH-1:0] p0_age;
    reg [REF_AGE_WIDTH-1:0] ref_age;
    (* ASYNC_REG = "TRUE" *) reg fault_meta, fault_sync;
    reg inhibit_latched;

    function automatic logic hazardous(input [31:0] flags);
        hazardous = flags[1] || flags[4] || flags[5];
    endfunction

    function automatic logic qualified(input [31:0] quality, input [31:0] fault);
        qualified = (&quality[3:0]) && !quality[4] && !fault[0] && !fault[1];
    endfunction

    wire [31:0] ref_flags = shadow_ref[223:192];
    wire [31:0] ref_version = shadow_ref[255:224];
    wire signed [31:0] ref_id_q24 = shadow_ref[31:0], ref_iq_q24 = shadow_ref[63:32];
    wire [31:0] version_delta = ref_version - accepted_version;
    wire recent_version = !accepted_seen || (version_delta != 0 && !version_delta[31]);
    wire reference_shape_ok = ref_flags[31:8] == 0 &&
        shadow_ref[127:104] == {24{shadow_ref[103]}} &&
        shadow_ref[191:128] < ELECTRICAL_TURN_Q32 &&
        ref_id_q24 >= -ID_LIMIT_Q24 && ref_id_q24 <= ID_LIMIT_Q24 &&
        ref_iq_q24 >= -IQ_LIMIT_Q24 && ref_iq_q24 <= IQ_LIMIT_Q24 &&
        !(hazardous(ref_flags) && (ref_flags[6] || !ref_flags[3]));
    wire target_ok = p0_seen && !p0_i && p0_age < COMMIT_LIMIT && pending &&
        pending_frame[31:0] == p0_id && shadow_target == p0_id + SAMPLE_ID_STEP;
    wire current_fault = fault_sync;
    wire stop_write = word_write && awaddr == CONTROL && wdata == STOP;
    wire io_disabled = word_write && awaddr == IO_CTRL && wdata == 0 && ctrl_enable_o;
    wire invalid_feedback = new_event && !qualified(frame_data_i[191:160], frame_data_i[287:256]);
    wire hazard_blocked = current_fault || invalid_feedback;
    wire pending_qualified = qualified(pending_frame[191:160], pending_frame[287:256]);
    wire queued_for_p0 = queued && queued_target == p0_sample_id_i &&
        !(hazard_blocked && hazardous(queued_ref[223:192]));
    wire missed_armed_p0 = p0_i && p0_seen && armed_o && !queued_for_p0;
    wire watchdog = accepted_seen && ref_age == REF_LIMIT;
    wire commit_shape_ok = wstrb == 4'hf && wdata == COMMIT_KEY && (&shadow_written) && reference_shape_ok;
    wire invalid_commit = write_fire && awaddr == COMMIT && !commit_shape_ok;
    wire cancel_all = invalidate_i || stop_write || io_disabled || overrun_now || missed_armed_p0 || invalid_commit;
    wire may_clear = frame_seen && qualified(last_observed_frame[191:160], last_observed_frame[287:256]) &&
        p0_age < FRAME_LIMIT && !current_fault && !invalidate_i;
    wire accept_commit = write_fire && awaddr == COMMIT && commit_shape_ok &&
        !queued && target_ok && recent_version && !cancel_all &&
        !(hazardous(ref_flags) && (hazard_blocked || !pending_qualified));

    assign irq_o = s_axi_aresetn && pending;
    // The async path has only assertion authority. Deassertion additionally
    // requires the state machine to release its synchronized fault latch.
    assign inhibit_o = !s_axi_aresetn || fast_fault_i || current_fault || invalidate_i ||
        inhibit_latched || !armed_o;

    initial begin
        if (ADDR_WIDTH < 8 || FRAME_CYCLES < 8 || DEADLINE_GUARD_CYCLES < 1 ||
            DEADLINE_GUARD_CYCLES >= FRAME_CYCLES-2 || WATCHDOG_CYCLES <= FRAME_CYCLES)
            $fatal(1, "AX04B realtime parameters do not leave a valid frame window");
    end

    // Gate off even for a pulse shorter than one fabric period. Deassertion
    // passes through the two ASYNC_REG stages before software can clear.
    always @(posedge s_axi_aclk or posedge fast_fault_i) begin
        if (fast_fault_i) begin
            fault_meta <= 1;
            fault_sync <= 1;
        end else if (!s_axi_aresetn) begin
            fault_meta <= 0;
            fault_sync <= 0;
        end else begin
            fault_meta <= 0;
            fault_sync <= fault_meta;
        end
    end

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            aw_seen <= 0;
            w_seen <= 0;
            awaddr <= 0;
            wdata <= 0;
            wstrb <= 0;
            s_axi_bvalid <= 0;
            s_axi_bresp <= OKAY;
            s_axi_rvalid <= 0;
            s_axi_rresp <= OKAY;
            s_axi_rdata <= 0;
        end else begin
            if (s_axi_awready && s_axi_awvalid) begin
                aw_seen <= 1;
                awaddr <= s_axi_awaddr;
            end
            if (s_axi_wready && s_axi_wvalid) begin
                w_seen <= 1;
                wdata <= s_axi_wdata;
                wstrb <= s_axi_wstrb;
            end
            if (s_axi_bvalid && s_axi_bready) s_axi_bvalid <= 0;
            if (write_fire) begin
                aw_seen <= 0;
                w_seen <= 0;
                s_axi_bvalid <= 1;
                s_axi_bresp <= SLVERR;
                if (wstrb == 4'hf && (awaddr == ACK || awaddr == CONTROL || awaddr == COMMIT ||
                    awaddr == IO_CTRL || awaddr == SHADOW_TARGET ||
                    (awaddr >= REF_FIRST && awaddr <= REF_LAST && awaddr[1:0] == 0)))
                    s_axi_bresp <= OKAY;
            end
            if (s_axi_rvalid && s_axi_rready) s_axi_rvalid <= 0;
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1;
                s_axi_rresp <= OKAY;
                case (s_axi_araddr)
                    'h00: s_axi_rdata <= IDENTITY;
                    'h04: s_axi_rdata <= SELFTEST ? 32'd1 : 32'd2;
                    'h08: s_axi_rdata <= 32'd1000;
                    'h0c: s_axi_rdata <= {22'd0, applied_seen, accepted_seen,
                        current_fault || invalidate_i, frame_seen, overrun, active_valid_o,
                        queued, armed_o, inhibit_latched, pending};
                    'h10: s_axi_rdata <= pending_seq;
                    'h14: s_axi_rdata <= overrun_count;
                    'h18: s_axi_rdata <= accepted_version;
                    'h1c: s_axi_rdata <= accepted_target;
                    'h20: s_axi_rdata <= applied_version;
                    'h24: s_axi_rdata <= active_target_o;
                    'h28: s_axi_rdata <= {29'd0, commit_result};
                    'h2c: s_axi_rdata <= p0_id;
                    'h54: s_axi_rdata <= {{(32-P0_AGE_WIDTH){1'b0}},p0_age};
                    IO_CTRL: s_axi_rdata <= {31'd0, ctrl_enable_o};
                    default: begin
                        s_axi_rdata <= 0;
                        if (s_axi_araddr >= FRAME_FIRST && s_axi_araddr <= FRAME_LAST && s_axi_araddr[1:0] == 0) begin
                            if (pending)
                                s_axi_rdata <= pending_frame[((s_axi_araddr-FRAME_FIRST)>>2)*32 +: 32];
                        end else s_axi_rresp <= SLVERR;
                    end
                endcase
            end
        end
    end

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            pending_frame <= 0;
            pending_seq <= SEQ_RESET;
            event_seq <= SEQ_RESET;
            overrun_count <= 0;
            pending <= 0;
            overrun <= 0;
            frame_seen <= 0;
            last_observed_frame <= 0;
            shadow_ref <= 0;
            shadow_target <= 0;
            shadow_written <= 0;
            queued_ref <= 0;
            queued_target <= 0;
            queued <= 0;
            accepted_seen <= 0;
            accepted_version <= 0;
            accepted_target <= 0;
            applied_seen <= 0;
            applied_version <= 0;
            commit_result <= 0;
            active_target_o <= 0;
            active_reference_o <= 0;
            active_valid_o <= 0;
            p0_seen <= 0;
            p0_id <= 0;
            p0_age <= FRAME_LIMIT;
            ref_age <= REF_LIMIT;
            inhibit_latched <= 1;
            armed_o <= 0;
            ctrl_enable_o <= 0;
        end else begin
            // ACK and a new publication are legal in the same cycle. A stale
            // ACK is a no-op, including a stale ACK concurrent with a publish.
            if (exact_ack) pending <= 0;
            if (new_event) begin
                frame_seen <= 1;
                last_observed_frame <= frame_data_i;
                event_seq <= event_seq + 1'b1;
                if (!pending || exact_ack) begin
                    pending_frame <= frame_data_i;
                    pending_seq <= event_seq + 1'b1;
                    pending <= 1;
                end else begin
                    overrun <= 1;
                    overrun_count <= overrun_count + 1'b1;
                end
            end

            if (write_fire && awaddr >= REF_FIRST && awaddr <= REF_LAST && awaddr[1:0] == 0) begin
                if (word_write) shadow_ref[((awaddr-REF_FIRST)>>2)*32 +: 32] <= wdata;
                shadow_written[(awaddr-REF_FIRST)>>2] <= word_write;
            end
            if (write_fire && awaddr == SHADOW_TARGET) begin
                if (word_write) shadow_target <= wdata;
                shadow_written[8] <= word_write;
            end
            // Every attempt consumes the mask. A retry must rewrite every word.
            if (write_fire && awaddr == COMMIT) begin
                shadow_written <= 0;
                if (!commit_shape_ok) commit_result <= INCOMPLETE;
                else if (!target_ok) commit_result <= LATE;
                else if (queued) commit_result <= BUSY;
                else if (!recent_version) commit_result <= OLD_VERSION;
                else if (!accept_commit) commit_result <= SAFETY;
                else commit_result <= ACCEPT;
            end
            if (accept_commit) begin
                queued_ref <= shadow_ref;
                queued_target <= shadow_target;
                queued <= 1;
                accepted_seen <= 1;
                accepted_version <= ref_version;
                accepted_target <= shadow_target;
                ref_age <= 0;
            end else if (ref_age < REF_LIMIT) ref_age <= ref_age + 1'b1;

            if (p0_i) begin
                p0_seen <= 1;
                p0_id <= p0_sample_id_i;
                p0_age <= 0;
                queued <= 0;
                active_valid_o <= queued_for_p0;
                if (queued_for_p0 && !cancel_all) begin
                    active_reference_o <= queued_ref;
                    applied_seen <= 1;
                    applied_version <= queued_ref[255:224];
                    active_target_o <= queued_target;
                end else active_reference_o <= 0;
            end else if (p0_age < FRAME_LIMIT) p0_age <= p0_age + 1'b1;

            if (word_write && awaddr == IO_CTRL && wdata[31:1] == 0)
                ctrl_enable_o <= wdata[0];
            if (stop_write) ctrl_enable_o <= 0;
            if (word_write && awaddr == CONTROL && wdata == CLEAR && may_clear) begin
                inhibit_latched <= 0;
                overrun <= 0;
                armed_o <= 0;
            end
            if (word_write && awaddr == CONTROL && wdata == ARM && may_clear && !inhibit_latched && !watchdog)
                armed_o <= 1;

            if (cancel_all || current_fault || (invalid_feedback && armed_o) || (watchdog && !accept_commit)) begin
                inhibit_latched <= 1;
                armed_o <= 0;
            end
            if (cancel_all || (watchdog && !accept_commit)) begin
                queued <= 0;
                active_valid_o <= 0;
                active_reference_o <= 0;
                shadow_written <= 0;
            end else if (hazard_blocked) begin
                if (queued && hazardous(queued_ref[223:192])) queued <= 0;
                if (active_valid_o && hazardous(active_reference_o[223:192]) && !p0_i) begin
                    active_valid_o <= 0;
                    active_reference_o <= 0;
                end
            end
        end
    end
endmodule
