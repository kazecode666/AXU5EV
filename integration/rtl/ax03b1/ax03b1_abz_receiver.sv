// Thin digital ABZ observer. FILTER_CYCLES >= 2 is a SIM_ASSUMPTION pending
// sensor-rate/latency review. Static AB is neither a link-good nor loss proof.
// Positive AB order: 00 -> 01 -> 11 -> 10 -> 00. Count is modulo 2^32.
// Z observes a filtered rising edge; never clears position.
module ax03b1_abz_receiver #(
    parameter integer FILTER_CYCLES = 2,
    parameter [31:0] INITIAL_COUNT = 32'd0
) (
    input wire clk,
    input wire rst,
    input wire [63:0] tick,
    input wire a_async,
    input wire b_async,
    input wire z_async,
    output reg [31:0] q_count,
    output reg ab_ready,
    output reg [31:0] illegal_count,
    output reg z_seen,
    output reg [31:0] z_count,
    output reg [63:0] z_tick
);
    localparam integer CW = $clog2(FILTER_CYCLES+1);
    (* ASYNC_REG = "TRUE" *) reg [2:0] sync1, sync2;
    reg [1:0] sync_primed;
    reg [1:0] ab_candidate, ab_filtered;
    reg [CW-1:0] ab_stable;
    reg z_candidate, z_filtered, z_ready;
    reg [CW-1:0] z_stable;
    reg [31:0] count_after_ab;
    wire ab_accept = sync_primed[1] &&
                     (sync2[2:1] == ab_candidate) &&
                     (ab_stable == FILTER_CYCLES-1);
    wire z_accept = sync_primed[1] &&
                    (sync2[0] == z_candidate) &&
                    (z_stable == FILTER_CYCLES-1);

    always @* begin
        count_after_ab = q_count;
        if (ab_ready && ab_accept && ab_candidate != ab_filtered) begin
            case ({ab_filtered,ab_candidate})
                4'b0001,4'b0111,4'b1110,4'b1000:
                    count_after_ab = q_count + 32'd1;
                4'b0010,4'b1011,4'b1101,4'b0100:
                    count_after_ab = q_count - 32'd1;
                default: count_after_ab = q_count;
            endcase
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            sync1 <= 3'd0;
            sync2 <= 3'd0;
            sync_primed <= 2'd0;
            ab_candidate <= 2'd0;
            ab_filtered <= 2'd0;
            ab_stable <= {CW{1'b0}};
            z_candidate <= 1'b0;
            z_filtered <= 1'b0;
            z_stable <= {CW{1'b0}};
            z_ready <= 1'b0;
            q_count <= INITIAL_COUNT;
            ab_ready <= 1'b0;
            illegal_count <= 32'd0;
            z_seen <= 1'b0;
            z_count <= 32'd0;
            z_tick <= 64'd0;
        end else begin
            sync1 <= {a_async,b_async,z_async};
            sync2 <= sync1;
            sync_primed <= {sync_primed[0],1'b1};
            if (sync_primed[1]) begin
                if (sync2[2:1] != ab_candidate) begin
                    ab_candidate <= sync2[2:1];
                    ab_stable <= 1;
                end else if (ab_stable < FILTER_CYCLES) begin
                    ab_stable <= ab_stable + 1'b1;
                end
                if (ab_accept) begin
                    // First qualified AB establishes phase without a step,
                    // even if power-up inputs are nonzero.
                    ab_ready <= 1'b1;
                    if (ab_ready && ab_candidate != ab_filtered &&
                        ((ab_candidate ^ ab_filtered) == 2'b11))
                        illegal_count <= illegal_count + 32'd1;
                    q_count <= count_after_ab;
                    ab_filtered <= ab_candidate;
                end
                if (sync2[0] != z_candidate) begin
                    z_candidate <= sync2[0];
                    z_stable <= 1;
                end else if (z_stable < FILTER_CYCLES) begin
                    z_stable <= z_stable + 1'b1;
                end
                if (z_accept) begin
                    if (z_ready && z_candidate && !z_filtered) begin
                        z_seen <= 1'b1;
                        // Simultaneously accepted AB precedes Z latch here.
                        z_count <= count_after_ab;
                        z_tick <= tick;
                    end
                    z_ready <= 1'b1;
                    z_filtered <= z_candidate;
                end
            end
        end
    end
endmodule
