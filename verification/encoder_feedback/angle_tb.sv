`timescale 1ns/1ps
module angle_tb;
 reg clk=0;always #10 clk=~clk;
 reg reset=1,sample_strobe=0,ready=0,direction=0;
 reg [31:0] count=0,zero_count=0,config_version=0;
 reg [15:0] phase_offset_count=0;
 wire signed[63:0] theta_q32;wire[15:0]phase_count;
 wire valid,result_strobe,ce_out;wire[31:0]version;
 Encoder_Angle dut(.*,.clk_enable(1'b1));
 integer file,rc,checks=0,frames=0,latency;
 reg[31:0] vcount,vzero,vversion;integer vready,voffset,vdir,vvalid,vphase;
 reg signed[63:0]vtheta;
 reg[2047:0]vector_path;
 initial begin
  if(!$value$plusargs("VECTORS=%s",vector_path))$fatal(1,"Missing VECTORS path");
  file=$fopen(vector_path,"r");if(file==0)$fatal(1,"Cannot open angle vectors");
  repeat(4)@(negedge clk);reset=0;
  while(!$feof(file))begin
   rc=$fscanf(file,"%d %d %d %d %d %d %d %d %d\n",vcount,vready,vzero,voffset,vdir,vversion,vtheta,vphase,vvalid);
   if(rc!=9)$fatal(1,"Vector parse %0d",rc);
   @(negedge clk);sample_strobe=1;count=vcount;ready=vready;
   zero_count=vzero;phase_offset_count=voffset;direction=vdir;config_version=vversion;
   @(posedge clk);#1;
   if(result_strobe!==0)$fatal(1,"Unexpected immediate result");
   @(negedge clk);sample_strobe=0;latency=0;
   while(result_strobe!==1 && latency<45)begin @(posedge clk);#1;latency=latency+1;end
   if(latency!=33)$fatal(1,"Latency frame%0d got%0d",frames,latency);
   if(theta_q32!==vtheta || phase_count!==vphase || valid!==vvalid[0] || version!==vversion)
    $fatal(1,"Angle frame%0d raw%h theta%0d exp%0d phase%0d exp%0d valid%b exp%0d ver%0d",frames,vcount,theta_q32,vtheta,phase_count,vphase,valid,vvalid,version);
   checks=checks+5;frames=frames+1;
   repeat(5)begin @(posedge clk);#1;if(result_strobe!==0)$fatal(1,"Duplicate angle result");checks=checks+1;end
  end
  $fclose(file);if(frames!=46)$fatal(1,"Missing angle cases");
  $display("ANGLE_PASS vectors=%0d checks=%0d latency=33",frames,checks);$finish;
 end
 initial begin #1000000;$fatal(1,"Angle watchdog");end
endmodule
