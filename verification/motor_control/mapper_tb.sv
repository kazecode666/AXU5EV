`timescale 1ns/1ps
module mapper_tb;
 reg clk=0,reset=1,strobe=0;always #10 clk=~clk;
 reg [31:0] duty_u=0,duty_v=0,duty_w=0;
 wire [15:0] compare_u,compare_v,compare_w;wire result_strobe;
 integer fd,parsed,cu,cv,cw,rows=0,checks=0;
 Duty_To_Compare dut(.clk(clk),.reset(reset),.clk_enable(1'b1),.sample_strobe(strobe),
 .duty_u(duty_u),.duty_v(duty_v),.duty_w(duty_w),.compare_u(compare_u),
 .compare_v(compare_v),.compare_w(compare_w),.result_strobe(result_strobe),.ce_out());
 task check(input bit ok,input string why);begin checks++;if(!ok)$fatal(1,"MAPPER %s row=%0d",why,rows);end endtask
 initial begin
  fd=$fopen("duty_vectors.txt","r");if(!fd)$fatal(1,"Missing model duty vectors");
  repeat(3)@(negedge clk);reset=0;
  while(!$feof(fd))begin
   @(negedge clk);parsed=$fscanf(fd,"%d %d %d %d %d %d\n",duty_u,duty_v,duty_w,cu,cv,cw);
   if(parsed==6)begin
    strobe=1;@(posedge clk);#0.001;
    check(result_strobe,"one-clock generated result pulse");
    check(compare_u==cu && compare_v==cv && compare_w==cw,"all three model count outputs");
    check(compare_u<=5000 && compare_v<=5000 && compare_w<=5000,"endpoints and saturation stay in 0..5000");
    @(negedge clk);strobe=0;@(posedge clk);#0.001;check(!result_strobe,"strobe does not persist");rows++;
   end else if(parsed>0)$fatal(1,"Incomplete model vector");
  end
  check(rows==31,"published endpoint/rounding vector count");$fclose(fd);
  $display("MOTOR_MAPPER_PASS vectors=%0d checks=%0d",rows,checks);$finish;
 end
 initial begin #1000000;$fatal(1,"Mapper watchdog");end
endmodule
