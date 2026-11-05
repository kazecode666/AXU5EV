// SIM_ASSUMPTION: two independent offset-binary buses, abstract synchronous
// sample/capture event, seven conversion-event latency. No physical capture
// edge, CDC, tPD/setup/hold, ADC mode or external link-health signoff is implied.
// raw/valid/OTR on event E7 describe the external conversion from event E0.
module ax03b1_adc_receiver #(
    parameter integer META_WIDTH = 448,
    parameter integer PIPELINE_EVENTS = 7
) (
    input wire clk,
    input wire rst,
    input wire sample_ce,
    input wire observe_select,
    input wire [11:0] raw_a,
    input wire [11:0] raw_b,
    input wire valid_a,
    input wire valid_b,
    input wire otr_a,
    input wire otr_b,
    input wire [META_WIDTH-1:0] sample_meta,
    output reg pair_strobe,
    output reg pair_complete,
    output reg pair_valid_a,
    output reg pair_valid_b,
    output reg [11:0] pair_a,
    output reg [11:0] pair_b,
    output reg [1:0] pair_otr,
    output reg [31:0] pair_id,
    output reg [META_WIDTH-1:0] pair_meta
);
    reg [META_WIDTH-1:0] meta_pipe [0:PIPELINE_EVENTS-1];
    reg [31:0] id_pipe [0:PIPELINE_EVENTS-1];
    reg [PIPELINE_EVENTS-1:0] present_pipe;
    reg [PIPELINE_EVENTS-1:0] select_pipe;
    reg [31:0] next_id;
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            pair_strobe <= 1'b0;
            pair_complete <= 1'b0;
            pair_valid_a <= 1'b0;
            pair_valid_b <= 1'b0;
            pair_a <= 12'd0;
            pair_b <= 12'd0;
            pair_otr <= 2'd0;
            pair_id <= 32'd0;
            pair_meta <= {META_WIDTH{1'b0}};
            present_pipe <= {PIPELINE_EVENTS{1'b0}};
            select_pipe <= {PIPELINE_EVENTS{1'b0}};
            next_id <= 32'd0;
            for (i=0; i<PIPELINE_EVENTS; i=i+1) begin
                meta_pipe[i] <= {META_WIDTH{1'b0}};
                id_pipe[i] <= 32'd0;
            end
        end else begin
            pair_strobe <= 1'b0;
            if (sample_ce) begin
                // A selected but incomplete pair is still published. No code
                // or channel from an older event is substituted to fill it.
                if (present_pipe[PIPELINE_EVENTS-1] &&
                    select_pipe[PIPELINE_EVENTS-1]) begin
                    pair_strobe <= 1'b1;
                    pair_valid_a <= valid_a;
                    pair_valid_b <= valid_b;
                    pair_complete <= valid_a && valid_b;
                    pair_a <= raw_a;
                    pair_b <= raw_b;
                    pair_otr <= {otr_b,otr_a};
                    pair_id <= id_pipe[PIPELINE_EVENTS-1];
                    pair_meta <= meta_pipe[PIPELINE_EVENTS-1];
                end
                for (i=PIPELINE_EVENTS-1; i>0; i=i-1) begin
                    meta_pipe[i] <= meta_pipe[i-1];
                    id_pipe[i] <= id_pipe[i-1];
                    present_pipe[i] <= present_pipe[i-1];
                    select_pipe[i] <= select_pipe[i-1];
                end
                meta_pipe[0] <= sample_meta;
                id_pipe[0] <= next_id;
                present_pipe[0] <= 1'b1;
                select_pipe[0] <= observe_select;
                next_id <= next_id + 32'd1;
            end
        end
    end
endmodule
