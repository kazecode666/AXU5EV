`timescale 1ns/1ps
module ax03b1_observer_tb #(parameter integer OBS_TICKS=20);
 reg clk=0;always #10 clk=~clk;
 reg rst=1,va=0,vb=0,a=0,b=0,z=0,apply=0;
 reg [40:1] header=0;
 reg [11:0] araddr=0;
 reg arvalid=0,rready=0;
 wire arready,rvalid,sample_event,observe_select,publish;
 wire [31:0] rdata;
 wire [1:0] rresp;
 wire [5:0] pwm;
 wire encon,relcon,freset,permission;
 integer checks=0,publications=0,invalid_publications=0,n=0,ticks=0;
 reg [1023:0] history[0:1023];
 reg [255:0] expected_meta[0:4095];
 integer bitpins[0:11];
 ax03b1_observer #(.SAMPLE_DIV(2),.OBSERVE_DIV(OBS_TICKS),.FILTER_CYCLES(2)) dut(
  .clk(clk),.rst(rst),.an9238_header_i(header),.capture_valid_a_i(va),.capture_valid_b_i(vb),
  .a_async_i(a),.b_async_i(b),.z_async_i(z),.cal_en_i(1'b0),.cal_restart_i(1'b0),
  .config_apply_i(apply),.config_version_i(32'd11),.session_epoch_i(32'hb1000001),
  .offset_seed_a_q16_i(32'sd65536000),.offset_seed_b_q16_i(32'sd131072000),
  .manual_valid_a_i(1'b1),.manual_valid_b_i(1'b1),
  .gain_a_q24_i(32'sd4194304),.gain_b_q24_i(-32'sd8388608),.cal_log2_n_i(8'd2),
  .s_axi_araddr(araddr),.s_axi_arvalid(arvalid),.s_axi_arready(arready),
  .s_axi_rdata(rdata),.s_axi_rresp(rresp),.s_axi_rvalid(rvalid),.s_axi_rready(rready),
  .sample_event_o(sample_event),.observe_select_o(observe_select),.publish_o(publish),
  .gate_pwm_o(pwm),.encon_o(encon),.relcon_o(relcon),.fault_reset_o(freset),.run_permission_o(permission));
 function integer code_a(input integer tag);code_a=1000+(tag%17)-8;endfunction
 function integer code_b(input integer tag);code_b=2000+(tag%11)-5;endfunction
 task check(input bit condition,input string label);
   begin checks=checks+1;if(!condition)$fatal(1,"B1_OBSERVER_FAIL %s",label);end
 endtask
 task drive_header(input integer ca,input integer cb,input bit oa,input bit ob);
   begin
    header=0;
    for(integer j=0;j<12;j=j+1)begin header[bitpins[j]]=(ca>>j)&1;header[4+j]=(cb>>j)&1;end
    header[32]=oa;header[16]=ob;
   end
 endtask
 // Test-only peripheral: output words are tagged exactly seven conversion
 // events earlier. No deployment module depends on this source.
 always @(negedge clk) begin
   if(rst) begin n=0;ticks=0;header=0;va=0;vb=0;a=0;b=0;z=0;end
   else begin
    ticks=ticks+1;
    case((ticks/9)%4)0:{a,b}=2'b00;1:{a,b}=2'b01;2:{a,b}=2'b11;3:{a,b}=2'b10;endcase
    z=((ticks/45)%2)!=0;
    if(sample_event)begin
      expected_meta[n]=dut.sample_meta;
      if(n>=7)begin
       drive_header(code_a(n-7),code_b(n-7),1'b0,(n-7)==40);
       va=(n-7)!=20;vb=1;
      end else begin drive_header(4095,0,1,1);va=0;vb=0;end
      n=n+1;
    end
   end
 end
 // Capture the exact atomic publish boundary used by the snapshot peripheral.
 always @(posedge clk)begin: monitor
   integer tag,ca,cb;
   reg expected_valid;
   reg signed [63:0] ea,eb,ec;
   check({pwm,encon,relcon,freset,permission}===10'b0,"no power outputs in any state");
   if(!rst && publish)begin
    tag=dut.payload[3*32+:32];ca=code_a(tag);cb=code_b(tag);
    check(tag<4096,"bounded reference index");
    check(tag%(OBS_TICKS/2)==0,"only selected conversion is observed");
    check(dut.pair_meta===expected_meta[tag],"position/tick history at sample, not return");
    check(dut.payload[6*32+:32]==ca && dut.payload[7*32+:32]==cb,"dual code and pipeline ID association");
    check(dut.payload[16*32+:32]===expected_meta[tag][95:64],"position count association");
    check(dut.payload[18*32+:64]===expected_meta[tag][191:128],"Z timestamp association");
    check(dut.payload[2*32+16] && !dut.payload[2*32+17],"simulation/physical verification flags distinct");
    expected_valid=(tag!=20 && tag!=40);
    check(dut.payload[2*32+7]===expected_valid,"numeric validity separated from logical pair");
    if(expected_valid)begin
      ea=(ca-1000)*64'sd4194304;eb=(cb-2000)*(-64'sd8388608);ec=-(ea+eb);
      check($signed(dut.payload[8*32+:32])==ea,"generated current A with independent coefficient");
      check($signed(dut.payload[9*32+:32])==eb,"generated current B reversed sign");
      check($signed(dut.payload[10*32+:32])==ec,"same-pair reconstructed C");
    end else begin
      invalid_publications=invalid_publications+1;
      check(dut.payload[8*32+:96]===96'b0,"bad frame observable with invalid zero numeric values");
    end
    publications=publications+1;
    history[publications]=dut.payload;
   end
 end
 task read_word(input [11:0] address,input integer stall,output [31:0] value,output [1:0] response);
  integer timeout;
  reg [31:0] held;
  begin
   @(negedge clk);araddr=address;arvalid=1;rready=0;timeout=0;
   @(posedge clk);
   while(!arready)begin timeout=timeout+1;if(timeout>100)$fatal(1,"AR timeout");@(posedge clk);end
   @(negedge clk);arvalid=0;timeout=0;
   while(!rvalid)begin timeout=timeout+1;if(timeout>100)$fatal(1,"R timeout");@(negedge clk);end
   held=rdata;
   repeat(stall)begin @(negedge clk);check(rvalid && rdata===held,"R backpressure stability");end
   value=rdata;response=rresp;rready=1;
   @(posedge clk);@(negedge clk);rready=0;
  end
 endtask
 reg [31:0] seq_read,word;
 reg [1:0] response;
 reg [1023:0] frozen;
 initial begin
  bitpins[0]=20;bitpins[1]=19;bitpins[2]=22;bitpins[3]=21;bitpins[4]=24;bitpins[5]=23;
  bitpins[6]=26;bitpins[7]=25;bitpins[8]=28;bitpins[9]=27;bitpins[10]=30;bitpins[11]=29;
  repeat(4)@(posedge clk);#1;rst=0;apply=1;
  repeat(2)@(posedge clk);#1;apply=0;
  wait(publications>=6);
  read_word(12'h000,4,seq_read,response);check(response==0,"BEGIN after valid and invalid publications");
  check(seq_read>0 && seq_read<=publications,"snapshot seq_read names a published packet");
  frozen=history[seq_read];
  read_word(12'h004,1,word,response);check(response==0 && word==32'hb1000001,"session epoch frozen");
  for(integer w=0;w<32;w=w+1)begin
    read_word(12'h00c+4*w,w%4,word,response);
    check(response==0 && word===frozen[w*32+:32],"all words from one frozen publication across updates");
  end
  check(publications>seq_read+3,"multiword read deliberately spans newer publications");
  check(invalid_publications==2,"capture-invalid and OTR frame both published");
  read_word(12'h00c,0,word,response);check(response==2'b10,"terminal response released read session");
  $display("AX03B1_OBSERVER_PASS checks=%0d publications=%0d invalid=%0d",checks,publications,invalid_publications);
  $finish;
 end
 initial begin #2000000;$fatal(1,"B1 observer test timeout");end
endmodule

module ax03b1_observer_fast_tb;
 ax03b1_observer_tb #(.OBS_TICKS(8)) minimum_interval();
endmodule
