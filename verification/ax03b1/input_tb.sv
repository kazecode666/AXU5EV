`timescale 1ns/1ps

// Test-only peripheral, never part of deployment: each conversion returns on
// the seventh later sample event, independently of the receiver's metadata.
module ax03b1_input_adc_model(
    input wire clk,rst,sample_ce,
    output wire [11:0] raw_a,raw_b,
    output wire va,vb,oa,ob
);
    reg [11:0] a_pipe[0:6],b_pipe[0:6];
    reg [6:0] va_pipe,vb_pipe,oa_pipe,ob_pipe;
    integer n,i;
    assign raw_a=a_pipe[6]; assign raw_b=b_pipe[6];
    assign va=va_pipe[6]; assign vb=vb_pipe[6];
    assign oa=oa_pipe[6]; assign ob=ob_pipe[6];
    always @(posedge clk) begin
        if(rst) begin
            n<=0; va_pipe<=0;vb_pipe<=0;oa_pipe<=0;ob_pipe<=0;
            for(i=0;i<7;i=i+1) begin a_pipe[i]<=0;b_pipe[i]<=0;end
        end else if(sample_ce) begin
            for(i=6;i>0;i=i-1) begin
                a_pipe[i]<=a_pipe[i-1];b_pipe[i]<=b_pipe[i-1];
                va_pipe[i]<=va_pipe[i-1];vb_pipe[i]<=vb_pipe[i-1];
                oa_pipe[i]<=oa_pipe[i-1];ob_pipe[i]<=ob_pipe[i-1];
            end
            a_pipe[0]<=(11+73*n)&4095;
            b_pipe[0]<=(3011-37*n)&4095;
            va_pipe[0]<=(n!=2);vb_pipe[0]<=(n!=4);
            oa_pipe[0]<=(n==1 || n==12);ob_pipe[0]<=(n==3);
            n<=n+1;
        end
    end
endmodule

module ax03b1_input_tb;
    reg clk=0;
    always #10 clk=~clk;
    reg rst=1;
    reg [63:0] tick=0;
    always @(posedge clk) if(rst) tick<=0;else tick<=tick+1;
    reg a_async=1,b_async=1,z_async=1;
    wire [31:0] q_count,illegal_count,z_count;
    wire [63:0] z_tick;
    wire ab_ready,z_seen;
    wire [31:0] wrap_count,slow_count;
    ax03b1_abz_receiver #(.FILTER_CYCLES(2)) abz(
        .clk(clk),.rst(rst),.tick(tick),.a_async(a_async),.b_async(b_async),.z_async(z_async),
        .q_count(q_count),.ab_ready(ab_ready),.illegal_count(illegal_count),
        .z_seen(z_seen),.z_count(z_count),.z_tick(z_tick));
    ax03b1_abz_receiver #(.FILTER_CYCLES(2),.INITIAL_COUNT(32'hfffffffe)) wrap_abz(
        .clk(clk),.rst(rst),.tick(tick),.a_async(a_async),.b_async(b_async),.z_async(z_async),
        .q_count(wrap_count),.ab_ready(),.illegal_count(),.z_seen(),.z_count(),.z_tick());
    ax03b1_abz_receiver #(.FILTER_CYCLES(3)) slow_abz(
        .clk(clk),.rst(rst),.tick(tick),.a_async(a_async),.b_async(b_async),.z_async(z_async),
        .q_count(slow_count),.ab_ready(),.illegal_count(),.z_seen(),.z_count(),.z_tick());

    reg [40:1] header_i=0;
    wire [11:0] mapped_a,mapped_b;
    wire mapped_oa,mapped_ob;
    ax03b1_an9238_pinmap pinmap(.header_i(header_i),.raw_a(mapped_a),.raw_b(mapped_b),
        .otr_a(mapped_oa),.otr_b(mapped_ob));

    reg sample_ce=0,observe_select=0;
    wire [11:0] raw_a,raw_b;
    wire va,vb,oa,ob;
    ax03b1_input_adc_model peripheral(.clk(clk),.rst(rst),.sample_ce(sample_ce),
        .raw_a(raw_a),.raw_b(raw_b),.va(va),.vb(vb),.oa(oa),.ob(ob));
    wire [447:0] sample_meta={222'h18abcdef,ab_ready,z_seen,illegal_count,z_tick,z_count,q_count,tick};
    wire pair_strobe,pair_complete,pair_valid_a,pair_valid_b;
    wire [11:0] pair_a,pair_b;
    wire [1:0] pair_otr;
    wire [31:0] pair_id;
    wire [447:0] pair_meta;
    ax03b1_adc_receiver receiver(.clk(clk),.rst(rst),.sample_ce(sample_ce),
        .observe_select(observe_select),.raw_a(raw_a),.raw_b(raw_b),.valid_a(va),.valid_b(vb),
        .otr_a(oa),.otr_b(ob),.sample_meta(sample_meta),.pair_strobe(pair_strobe),
        .pair_complete(pair_complete),.pair_valid_a(pair_valid_a),.pair_valid_b(pair_valid_b),
        .pair_a(pair_a),.pair_b(pair_b),.pair_otr(pair_otr),.pair_id(pair_id),.pair_meta(pair_meta));

    integer checks=0,returns=0,invalid_returns=0,otr_returns=0,moved_position_returns=0,coincident_edges=0;
    integer events=0,source_index=0,i,p,j,fd;
    reg [447:0] meta_history[0:255];
    reg select_history[0:255];
    reg [11:0] expected_a,expected_b;
    reg old_strobe;
    reg [31:0] pre_q;
    reg [63:0] old_z_tick;
    task check(input bit condition,input string label);
        begin
            checks=checks+1;
            if(!condition) $fatal(1,"B1_INPUT_FAIL check=%0d time=%0t %s",checks,$time,label);
        end
    endtask
    task clocks(input integer count);
        begin repeat(count) begin @(posedge clk);#2;end end
    endtask
    task set_ab(input [1:0] state,input [31:0] expected);
        begin
            @(negedge clk);{a_async,b_async}=state;
            clocks(10);
            check(q_count===expected,"AB legal/illegal transition count");
            check(wrap_count===(expected+32'hfffffffe),"AB modulo wrap companion");
            check(slow_count===expected,"configurable three-cycle filter");
        end
    endtask
    task reset_inputs;
        begin
            @(negedge clk);rst=1;sample_ce=0;observe_select=0;
            clocks(3);
            check(pair_strobe===0 && pair_complete===0,"reset clears pair eligibility");
            check(z_seen===0 && illegal_count===0,"reset clears observer events");
            @(negedge clk);rst=0;
        end
    endtask
    task conversion(input integer seq);
        begin
            @(negedge clk);
            // Legal positive quadrature movement overlaps conversion activity.
            case(seq%4)
                0:{a_async,b_async}=2'b00;
                1:{a_async,b_async}=2'b01;
                2:{a_async,b_async}=2'b11;
                3:{a_async,b_async}=2'b10;
            endcase
            sample_ce=1;observe_select=(seq%8!=6);
            @(negedge clk);sample_ce=0;
            clocks(9);
        end
    endtask

    // Expected association uses an event-indexed test oracle, not DUT state.
    // Meta is captured pre-edge; this explicitly checks the ADC/ABZ same-edge
    // rule even when the ABZ registered state changes at that very edge.
    always @(posedge clk) begin
        if(rst) events=0;
        else if(sample_ce) begin
            meta_history[events]=sample_meta;
            select_history[events]=observe_select;
            pre_q=q_count;
            #1;
            if(q_count!=pre_q) coincident_edges=coincident_edges+1;
            if(events<7) check(pair_strobe===0,"first seven conversion events invalid");
            else if(select_history[events-7]) begin
                source_index=events-7;
                check(pair_strobe===1,"selected metadata return emits strobe");
                check(pair_id===source_index,"event ID follows seven-conversion association");
                check(pair_meta===meta_history[source_index],"sample-time metadata, not arrival-time state");
                check(pair_a===((11+73*source_index)&4095),"independent peripheral A pipeline");
                check(pair_b===((3011-37*source_index)&4095),"independent peripheral B pipeline");
                check(pair_valid_a===(source_index!=2),"A validity retained");
                check(pair_valid_b===(source_index!=4),"B validity retained");
                check(pair_complete===((source_index!=2)&&(source_index!=4)),"pair completeness distinct from OTR");
                check(pair_otr==={1'(source_index==3),1'(source_index==1 || source_index==12)},"OTR belongs to returned conversion");
                returns=returns+1;
                if(!pair_complete) invalid_returns=invalid_returns+1;
                if(pair_otr!=0) begin
                    check(pair_complete===1,"OTR does not masquerade as missing digital channel");
                    otr_returns=otr_returns+1;
                end
                if(pair_meta[95:64]!=pre_q) moved_position_returns=moved_position_returns+1;
            end else check(pair_strobe===0,"unselected conversion not published");
            events=events+1;
        end else begin
            #1;check(pair_strobe===0,"no conversion CE means no pair strobe");
        end
    end

    initial begin
        // Exhaustive one-hot physical header position test, including ignored
        // clock/power/NC pins, separate from peripheral/metadata verification.
        for(p=1;p<=40;p=p+1) begin
            header_i=0;header_i[p]=1;
            expected_a=0;expected_b=0;
            case(p)
                20:expected_a=12'h001;19:expected_a=12'h002;
                22:expected_a=12'h004;21:expected_a=12'h008;
                24:expected_a=12'h010;23:expected_a=12'h020;
                26:expected_a=12'h040;25:expected_a=12'h080;
                28:expected_a=12'h100;27:expected_a=12'h200;
                30:expected_a=12'h400;29:expected_a=12'h800;
            endcase
            if(p>=4 && p<=15) expected_b=1<<(p-4);
            #2;
            check(mapped_a===expected_a,"CH1 nonascending bit order; unused pins ignored");
            check(mapped_b===expected_b,"CH2 ascending data order");
            check(mapped_oa===(p==32) && mapped_ob===(p==16),"separate OTR pins");
        end
        reset_inputs();clocks(10);
        check(ab_ready===1 && q_count===0 && slow_count===0,"nonzero startup AB establishes baseline without count");
        check(z_seen===0,"initial high Z is not an observed rising edge");
        @(negedge clk);z_async=0;clocks(10);
        set_ab(2'b10,1);set_ab(2'b00,2);set_ab(2'b01,3);set_ab(2'b11,4);
        set_ab(2'b01,3);set_ab(2'b00,2);set_ab(2'b10,1);set_ab(2'b11,0);
        set_ab(2'b00,0);check(illegal_count===1,"double-bit jump recorded without guessing direction");
        @(negedge clk);a_async=0;b_async=1;z_async=1;
        clocks(10);
        check(q_count===1 && z_seen===1 && z_count===1,"same accepted AB/Z edge latches updated count, never clears it");
        check(z_tick>0 && z_tick<tick,"Z event has acceptance timestamp");
        old_z_tick=z_tick;
        @(negedge clk);a_async=1;z_async=0;
        @(negedge clk);a_async=0;z_async=1;
        clocks(10);
        check(q_count===1 && illegal_count===1,"one-clock AB glitch rejected");
        check(z_tick===old_z_tick,"one-clock Z glitch rejected");
        set_ab(2'b11,2);set_ab(2'b10,3);check(wrap_count===1,"upper 32-bit count rollover");
        set_ab(2'b11,2);set_ab(2'b01,1);set_ab(2'b00,0);set_ab(2'b10,32'hffffffff);
        check(q_count===32'hffffffff,"lower 32-bit count rollover");
        clocks(20);check(q_count===32'hffffffff,"stationary AB preserves count without false loss declaration");

        reset_inputs();clocks(10);
        // Current AB is 10. At the fourth edge after changing to 00, the
        // two-FF/two-stable filter accepts the step. Issue ADC at that edge.
        @(negedge clk);a_async=0;b_async=0;
        clocks(3);
        @(negedge clk);sample_ce=1;observe_select=1;
        @(negedge clk);sample_ce=0;
        clocks(8);
        check(coincident_edges==1,"same PL edge AB acceptance and ADC metadata sampling exercised");
        for(i=0;i<40;i=i+1) conversion(i);
        check(returns>=20 && invalid_returns==2 && otr_returns>=3,"required return/fault cases actually exercised");
        check(moved_position_returns>0,"position changed between sample and digital arrival");
        // Flush a partly filled pipeline, then prove fresh ID/startup again.
        reset_inputs();
        for(i=0;i<5;i=i+1) conversion(i);
        reset_inputs();
        for(i=0;i<16;i=i+1) conversion(i);
        check(events==16,"post-reset event progression");
        fd=$fopen("input_result.json","w");
        $fdisplay(fd,"{\"status\":\"PASS\",\"checks\":%0d,\"selected_returns\":%0d,\"invalid_returns\":%0d,\"otr_returns\":%0d,\"position_history_returns\":%0d,\"coincident_edges\":%0d,\"hardware\":\"NOT_RUN\",\"physical_capture_timing\":\"NOT_RUN\"}",checks,returns,invalid_returns,otr_returns,moved_position_returns,coincident_edges);
        $fclose(fd);
        $display("TEST_PASS AX03B1_INPUT checks=%0d returns=%0d",checks,returns);
        $finish;
    end
    initial begin #2000000;$fatal(1,"B1_INPUT_TIMEOUT");end
endmodule
