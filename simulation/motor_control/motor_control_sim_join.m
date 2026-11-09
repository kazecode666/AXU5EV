function [ia_f,ib_f,ic_f,theta_f,iq_f,id_f,omega_f,vdc_f,pi_f,frame_id,ref_version,valid,new_frame] = motor_control_sim_join(ce,sample_id,ref,iq,id,omega,vdc,ia,ib,ic,current_valid,current_event,theta,angle_valid,angle_event)
%#codegen
% SIM_ONLY join mirrors the RTL association, not electrical timing.
persistent si rv iqh idh oh vh ah bh ch cv have_current out
if isempty(si)
 si=uint32(0);rv=uint32(0);iqh=int32(0);idh=int32(0);oh=int64(0);vh=uint32(805306368);
 ah=int32(0);bh=int32(0);ch=int32(0);cv=false;have_current=false;
 out=zeros(1,12);out(8)=48;out(9)=1;out(10)=-1;
end
if ce,si=sample_id;rv=ref;iqh=iq;idh=id;oh=omega;vh=vdc;have_current=false;end
if current_event,ah=ia;bh=ib;ch=ic;cv=current_valid;have_current=true;end
new_frame=false;
if angle_event && have_current
 good=cv&&angle_valid;
 out=[double(ah)/2^24 double(bh)/2^24 double(ch)/2^24 double(theta)/2^32 ...
  double(iqh)/2^24 double(idh)/2^24 double(oh)/2^24 double(vh)/2^24 double(~good) double(si) double(rv) double(good)];
 if ~good
  % Match the deployed capture policy: invalid frames still advance a complete
  % FOC frame, using zero current/reference/angle/speed, TEST48V and PI reset.
  out(1:7)=0;out(8)=48;out(9)=1;
 end
 new_frame=true;
end
ia_f=out(1);ib_f=out(2);ic_f=out(3);theta_f=out(4);iq_f=out(5);id_f=out(6);omega_f=out(7);vdc_f=out(8);pi_f=out(9)>0;
frame_id=out(10);ref_version=out(11);valid=out(12)>0;
end
