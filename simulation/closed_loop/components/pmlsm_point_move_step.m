function [s,x_ref,obs]=pmlsm_point_move_step(s,t,x,requested,request_bit,mode_ok,pwm,pi_reset,align_enabled,align_ready,cfg)
%#codegen
% 无隐藏状态：调用者保存s；只接收静止到静止绝对点位。
% cfg: Ts_ACR,Ts_POS,Start,V,A,J,minRamp,deadband,ReadyTicks,AutoStart。
% s: init,lastreq,x0,target,t0,busy,done,inpos,count,status,accepted,rejected,
% interrupted,lasttick,lastref,alignready,unused,duration,received,segment,ready,unused。
if s(1)==0
 s(1)=1;s(2)=request_bit;s(3)=x;s(4)=x;s(5)=t;s(7)=1;s(14)=-1;s(15)=x;s(16)=align_ready;
 if cfg(10)~=0 && align_enabled==0
  s(3)=0;s(4)=requested;s(5)=cfg(3);s(6)=1;s(7)=0;s(10)=1;s(11)=1;s(20)=1;
 end
end
allowed=mode_ok~=0 && pwm~=0 && pi_reset==0 && align_ready~=0;
tick=floor(t/cfg(1)+1e-7);
new_tick=tick~=s(14);
if new_tick
 s(14)=tick;
 if align_enabled~=0 && align_ready~=0 && s(16)==0
  s(3)=x;s(4)=x;s(5)=t;s(6)=0;s(7)=1;s(8)=0;s(9)=0;s(13)=0;s(15)=x;
 end
 s(16)=align_ready;
 if s(6)~=0 && (pwm==0 || pi_reset~=0)
  s(6)=0;s(7)=0;s(8)=0;s(9)=0;s(13)=1;s(10)=7;
 end
end
if s(13)~=0
 x_ref=s(15);
else
 [dx,~,duration]=pmlsm_scurve_profile(t-s(5),s(4)-s(3),cfg(4),cfg(5),cfg(6),cfg(7));
 x_ref=s(3)+dx;s(18)=duration;s(7)=double(t-s(5)>=duration);
end
% 位置事件与原调度首拍9.9ms对齐；不以速度纹波作为严格零速条件。
if mod(tick,round(cfg(2)/cfg(1)))==round(cfg(2)/cfg(1))-1 && s(22)~=tick+1
 s(22)=tick+1;
 if allowed && s(7)~=0 && s(13)==0 && abs(x-s(4))<=cfg(8)+1e-9
  s(9)=min(s(9)+1,cfg(9));
 else
  s(9)=0;
 end
 s(8)=double(s(9)>=cfg(9));if s(8)~=0,s(6)=0;end
end
s(21)=double(allowed && s(8)~=0 && s(6)==0 && s(13)==0);
if new_tick && ~isequaln(request_bit,s(2))
 s(2)=request_bit;s(19)=t;
 if ~isfinite(requested) || ~isfinite(request_bit) || (request_bit~=0 && request_bit~=1)
  s(10)=4;s(12)=s(12)+1;
 elseif ~allowed
  s(10)=6;s(12)=s(12)+1;
 elseif s(21)==0
  s(10)=3;s(12)=s(12)+1;
 elseif abs(requested-s(4))<=1e-12
  s(10)=5;
 else
  s(3)=s(4);s(4)=requested;s(5)=t;s(6)=1;s(7)=0;s(8)=0;s(9)=0;s(10)=2;s(11)=s(11)+1;s(19)=t;s(20)=s(20)+1;s(21)=0;
  x_ref=s(3);
 end
end
s(15)=x_ref;
obs=[s(4) s(6) s(8) s(10) s(3) s(5) s(7) s(21) s(11) s(12) s(20) s(19) s(13)];
end
