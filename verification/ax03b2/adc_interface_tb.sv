`timescale 1ns/1ps
module ax03b2_adc_interface_tb;
    reg clk=0;always #10 clk=~clk;
    reg rst_n=0;
    reg [11:0] data_a=0,data_b=0;
    reg otr_a=0,otr_b=0;
    wire adc_clk_a,adc_clk_b;
    wire [63:0] debug_bus;
    reg [11:0] araddr=0,awaddr=0;
    reg arvalid=0,rready=0,awvalid=0,wvalid=0,bready=0;
    wire arready,rvalid,awready,wready,bvalid;
    wire [31:0] rdata;
    wire [1:0] rresp,bresp;
    ax03b2_adc_observer dut (
        .s_axi_aclk(clk),.s_axi_aresetn(rst_n),
        .adc_data_a_i(data_a),.adc_data_b_i(data_b),
        .adc_otr_a_i(otr_a),.adc_otr_b_i(otr_b),
        .adc_clk_a_o(adc_clk_a),.adc_clk_b_o(adc_clk_b),.debug_o(debug_bus),
        .s_axi_awaddr(awaddr),.s_axi_awprot(3'd0),.s_axi_awvalid(awvalid),.s_axi_awready(awready),
        .s_axi_wdata(32'h12345678),.s_axi_wstrb(4'hf),.s_axi_wvalid(wvalid),.s_axi_wready(wready),
        .s_axi_bresp(bresp),.s_axi_bvalid(bvalid),.s_axi_bready(bready),
        .s_axi_araddr(araddr),.s_axi_arprot(3'd0),.s_axi_arvalid(arvalid),.s_axi_arready(arready),
        .s_axi_rdata(rdata),.s_axi_rresp(rresp),.s_axi_rvalid(rvalid),.s_axi_rready(rready)
    );
    integer checks=0,publications=0,captures=0,rises=0;
    integer conversion=-1,pipe_id[0:6],j;
    time last_rise=0,last_fall=0;
    integer expected_return;
    reg pre_capture;
    function automatic [11:0] code_a(input integer id);code_a=(id*37+17)&4095;endfunction
    function automatic [11:0] code_b(input integer id);code_b=(4095-id*53)&4095;endfunction
    function automatic a_otr(input integer id);a_otr=(id%11)==5;endfunction
    function automatic b_otr(input integer id);b_otr=(id%7)==0;endfunction
    task automatic check(input bit condition,input string label);
        begin checks=checks+1;if(!condition)$fatal(1,"AX03B2 %s at %0t",label,$time);end
    endtask

    // AD9238 behavioral timing model: sample on physical forwarded rising
    // edge, seven-conversion pipeline, data/OTR change after tPD+board delay.
    // Alternate the specified 2 ns lower bound and conservative 10 ns upper
    // external budget. This is stimulus timing, not STA or analog precision.
    initial for(j=0;j<7;j=j+1)pipe_id[j]=-1;
    always @(negedge rst_n) begin
        conversion=-1;last_rise=0;last_fall=0;
        for(j=0;j<7;j=j+1)pipe_id[j]=-1;
        data_a=0;data_b=0;otr_a=0;otr_b=0;
    end
    always @(posedge adc_clk_a) if(rst_n) begin
        if(last_rise!=0)check($time-last_rise==200,"5 MHz period");
        if(last_fall!=0)check($time-last_fall==100,"50 percent low width");
        last_rise=$time;rises=rises+1;
        conversion=conversion+1;expected_return=pipe_id[6];
        for(j=6;j>0;j=j-1)pipe_id[j]=pipe_id[j-1];
        pipe_id[0]=conversion;
        if((conversion%2)==0) #2;else #10;
        if(expected_return>=0) begin
            data_a=code_a(expected_return);data_b=code_b(expected_return);
            otr_a=a_otr(expected_return);otr_b=b_otr(expected_return);
        end else begin data_a=12'hbad;data_b=12'hbad;otr_a=0;otr_b=0;end
    end
    always @(negedge adc_clk_a) if(rst_n) begin
        check($time-last_rise==100,"50 percent high width");last_fall=$time;
    end
    always @(posedge clk) begin
        pre_capture=dut.capture_event;
        #1;
        check(adc_clk_a===adc_clk_b,"both forwarded clocks in phase");
        if(!rst_n)check(adc_clk_a===0 && adc_clk_b===0,"reset holds clocks low");
        if(rst_n && pre_capture) begin
            captures=captures+1;
            check($time-last_rise==81,"capture 80 ns after physical sample edge");
            if(conversion>=7) begin
                check(debug_bus[11:0]===code_a(conversion-7),"whole A captured after tPD");
                check(debug_bus[23:12]===code_b(conversion-7),"whole B captured after tPD");
                check(debug_bus[25:24]==={b_otr(conversion-7),a_otr(conversion-7)},"OTR captured with words");
            end
        end
        if(rst_n && dut.pair_strobe) begin
            publications=publications+1;
            check(dut.pair_id%500==0,"default selection every 500 conversions");
            check(dut.pair_tick==dut.pair_id*10,"timestamp is sample rise, not capture/return");
            check(conversion==dut.pair_id+7,"seven physical conversion association");
            check(dut.pair_a===code_a(dut.pair_id) && dut.pair_b===code_b(dut.pair_id),"selected return word identity");
            check(dut.pair_otr==={b_otr(dut.pair_id),a_otr(dut.pair_id)},"selected OTR identity");
        end
    end
    task automatic read_word(input [11:0] address,output [31:0] value,output [1:0] response);
        begin
            @(negedge clk);araddr=address;arvalid=1;
            do @(posedge clk);while(!arready);
            @(negedge clk);arvalid=0;rready=1;
            do @(posedge clk);while(!rvalid);
            value=rdata;response=rresp;
            @(negedge clk);rready=0;
        end
    endtask
    reg [31:0] bank[0:31],value,sequence_value;
    reg [1:0] response;
    integer n,first_publications;
    task automatic read_bank(input integer want_id);
        reg [31:0] want_quality;
        begin
            read_word(12'h004,value,response);check(response==0 && value==32'h42320001,"frozen B2 epoch");
            read_word(12'h008,value,response);check(response==0 && value[0],"observation available");
            for(n=0;n<32;n=n+1)begin
                read_word(12'h00c+n*4,bank[n],response);check(response==0,"payload read response");
            end
            want_quality=7 | (a_otr(want_id)<<3) | (b_otr(want_id)<<4);
            check(bank[0]==32'h42324f42 && bank[1]==1,"B2 identity with B1 schema");
            check(bank[2]==want_quality,"raw/OTR quality without false calibration/ABZ claims");
            check(bank[3]==want_id && {bank[5],bank[4]}==want_id*10,"frozen selected sample identity/time");
            check(bank[6]==code_a(want_id) && bank[7]==code_b(want_id),"frozen physical ADC raw words");
            for(n=8;n<=20;n=n+1)check(bank[n]==0,"uncalibrated/current/ABZ fields zero");
            check(bank[21]==(32'h30 | (a_otr(want_id)<<2) | (b_otr(want_id)<<3)) && bank[24]==7 && bank[25]==10 && bank[26]==5000 && bank[27]==0,"acquisition metadata and no ABZ filter");
            read_word(12'h018,value,response);check(response==2,"terminal payload handshake releases bank");
        end
    endtask
    initial begin
        repeat(5)@(negedge clk);rst_n=1;
        wait(publications==1);repeat(3)@(negedge clk);
        read_word(0,sequence_value,response);check(response==0 && sequence_value==1,"BEGIN first physical observation");
        // Keep the existing B1 bank frozen across the next actual conversion
        // publication; readout is not a claim of full-rate software logging.
        wait(publications==2);repeat(3)@(negedge clk);read_bank(0);
        read_word(0,sequence_value,response);check(response==0 && sequence_value==2,"BEGIN next observation");
        read_bank(500);
        // Complete the required otherwise-unused AXI write interface, with
        // independent AW/W arrival. It cannot modify the read-only observer.
        @(negedge clk);awvalid=1;
        do @(posedge clk);while(!awready);
        @(negedge clk);awvalid=0;
        repeat(2)@(negedge clk);wvalid=1;
        do @(posedge clk);while(!wready);
        @(negedge clk);wvalid=0;
        wait(bvalid);check(bresp==2,"read-only write SLVERR");
        repeat(3)@(negedge clk);check(bvalid,"write response remains until handshake");
        bready=1;@(negedge clk);bready=0;
        // Reset during a running conversion stream and observe a new warmup.
        @(negedge clk);rst_n=0;
        repeat(5)@(negedge clk);first_publications=publications;rst_n=1;
        repeat(70)@(negedge clk);check(publications==first_publications,"startup suppresses pre-pipeline returns");
        wait(publications==first_publications+1);repeat(3)@(negedge clk);
        read_word(0,sequence_value,response);check(response==0 && sequence_value==1,"reset restarts snapshot sequence");
        read_bank(0);
        check(rises>500 && captures>500 && publications==3,"short physical stream exercised");
        $display("AX03B2_ADC_INTERFACE_PASS checks=%0d captures=%0d publications=%0d",checks,captures,publications);
        $finish;
    end
    initial begin #500000;$fatal(1,"AX03B2 interface test timeout");end
endmodule
