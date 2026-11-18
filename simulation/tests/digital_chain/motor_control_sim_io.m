function [ce,foc_ce,frame_id,tick,raw_a,raw_b,count,ready,apply,iq_ref,id_ref,omega,vdc,ref_version] = motor_control_sim_io()
%#codegen
% SIM_ONLY: already captured codes/count. Actual electrical receivers are RTL.
persistent k
if isempty(k),k=uint64(0);end
frame_id=uint32(idivide(k,uint64(5000))*uint64(500));
tick=idivide(k,uint64(5000))*uint64(5000); % Held ADC sample timestamp, not evaluation time.
ce=mod(k,uint64(5000))==0;foc_ce=ce;apply=k==0;
raw_a=uint16(2000);raw_b=uint16(2100);count=uint32(4);ready=k>0;
if k>=uint64(30000),raw_a=uint16(2010);raw_b=uint16(2090);end
iq_ref=int32(0);ref_version=uint32(1);
if k>=uint64(35000),iq_ref=int32(1677722);ref_version=uint32(2);end % TEST +0.1A
id_ref=int32(0);omega=int64(0);vdc=uint32(805306368); % Stationary, TEST48V Q24.
k=k+uint64(1);
end
