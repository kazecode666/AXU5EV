function [applied_u,applied_v,applied_w] = motor_control_sim_pwm(cu,cv,cw,event,valid)
%#codegen
% SIM_ONLY atomic valley hold. No complementary-edge/dead-time physical claim.
persistent k pending active
if isempty(k),k=uint32(0);pending=zeros(1,3,'uint16');active=pending;end
if event,pending=[cu cv cw];end
if mod(k,uint32(5000))==2500
 if valid,active=pending;else,active(:)=uint16(0);end
end
applied_u=active(1);applied_v=active(2);applied_w=active(3);k=k+uint32(1);
end
