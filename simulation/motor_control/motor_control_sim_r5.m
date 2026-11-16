function [position_mm,speed_mm_s,position_valid,speed_valid] = motor_control_sim_r5(count,sample_id,tick,encoder_valid,new_frame)
%#codegen
% R5 numerical boundary: reuse the sole generated-software source, no outer loop.
persistent x v pv vv
if isempty(x),x=0.0;v=0.0;pv=false;vv=false;end
if new_frame
 [x,v,pv,vv]=encoder_position_speed(count,sample_id,tick,encoder_valid,uint32(0),uint32(0),false,uint32(1),uint32(1000),false);
end
position_mm=x;speed_mm_s=v;position_valid=pv;speed_valid=vv;
end
