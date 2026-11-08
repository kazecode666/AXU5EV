`timescale 1ns/1ps
module ax03b3_tb;
reg clk=0;always #10 clk=~clk;
reg rstn=0;reg [11:0] addr=0;reg [31:0] data=0;
reg av=0,wv=0;wire ar,wr,bv;wire [1:0] br;
ax03b3_adc_observer #(.TEST_INPUT(1),.OBSERVE_CONVERSIONS(2)) dut(
.s_axi_aclk(clk),.s_axi_aresetn(rstn),.adc_data_a_i(12'd0),.adc_data_b_i(12'd0),
.adc_otr_a_i(1'b0),.adc_otr_b_i(1'b0),
.s_axi_awaddr(addr),.s_axi_awprot(3'd0),.s_axi_awvalid(av),.s_axi_awready(ar),
.s_axi_wdata(data),.s_axi_wstrb(4'hf),.s_axi_wvalid(wv),.s_axi_wready(wr),
.s_axi_bvalid(bv),.s_axi_bready(1'b1),.s_axi_bresp(br),
.s_axi_araddr(12'd0),.s_axi_arprot(3'd0),.s_axi_arvalid(1'b0),.s_axi_rready(1'b1));
task write(input [11:0] a,input [31:0] d);
begin @(negedge clk);addr=a;data=d;av=1;wv=0;
@(posedge clk);while(!ar) @(posedge clk);
@(negedge clk);av=0;repeat(3) @(negedge clk);wv=1;
@(posedge clk);while(!wr) @(posedge clk);
@(negedge clk);wv=0;
wait(bv);if(br!=0)$fatal(1,"write rejected");@(negedge clk);end endtask
reg prior_done=0;
reg [1023:0] expected_bank;
always @(posedge clk) if(rstn && dut.result_strobe) begin
 expected_bank=dut.payload;
 #1;if(dut.snapshot.latest_payload!==expected_bank)$fatal(1,"publication alignment");
end
integer checks=0;integer rounds=0;integer valid_frames=0;
always @(negedge clk) begin
 if(rstn && dut.result_strobe && dut.cal_en) begin
  if(dut.ca>1024 || dut.cb>1024)$fatal(1,"count");
  if(dut.da && dut.db) begin
    if(!prior_done && dut.valid)$fatal(1,"completion must be invalid");
    if(dut.oa!=131104768 || dut.ob!=137658368)$fatal(1,"fractional mean %d %d",dut.oa,dut.ob);
    if(dut.valid) begin
      if($signed(dut.ia)!=($signed({1'b0,dut.aligned_a})*65536-131104768))$fatal(1,"A alignment");
      if($signed(dut.ib)!=($signed({1'b0,dut.aligned_b})*65536-137658368))$fatal(1,"B alignment");
      if($signed(dut.ic)!=-($signed(dut.ia)+$signed(dut.ib)))$fatal(1,"C reconstruction");
      valid_frames=valid_frames+1;
    end
  end
  prior_done=dut.da && dut.db;
  checks=checks+1;
 end
 if(dut.pair_strobe && (dut.apply || dut.restart))$fatal(1,"command collision");
end
initial begin
repeat(5) @(negedge clk);rstn=1;
write('h100,0);write('h104,0);write('h108,65536);write('h10c,65536);write('h110,10);write('h114,1);write('h118,5);
wait(valid_frames>=8);write('h118,6);wait(!dut.da);valid_frames=0;
wait(valid_frames>=8);$display("AX03B3_PASS checks=%0d",checks);$finish;
end
initial begin #2000000;$fatal(1,"timeout");end
endmodule
