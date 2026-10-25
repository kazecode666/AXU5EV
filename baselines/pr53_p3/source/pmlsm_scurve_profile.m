function [x,v,T,Ta,Tc] = pmlsm_scurve_profile(t,target,Vmax,Amax,Jmax,minRamp)
%#codegen
% Smooth velocity ramps with a constant-speed middle segment (mm, seconds).
% Short moves reduce peak velocity; acceleration and jerk remain bounded.
assert(Vmax>0 && Amax>0 && Jmax>0 && minRamp>0);
D=abs(target);x=0;v=0;T=0;Ta=0;Tc=0;
if D==0,return;end
C=10/sqrt(3);
V=min([Vmax,D/minRamp,sqrt(D*Amax/1.875),(D^2*Jmax/C)^(1/3)]);
Ta=max([minRamp,1.875*V/Amax,sqrt(C*V/Jmax)]);
Tc=max(0,D/V-Ta);T=2*Ta+Tc;
if t<=0
 return
elseif t<Ta
 s=t/Ta;
 x=V*Ta*(2.5*s^4-3*s^5+s^6);
 v=V*(10*s^3-15*s^4+6*s^5);
elseif t<Ta+Tc
 x=V*Ta/2+V*(t-Ta);v=V;
elseif t<T
 s=(t-Ta-Tc)/Ta;
 x=V*Ta/2+V*Tc+V*Ta*(s-2.5*s^4+3*s^5-s^6);
 v=V*(1-10*s^3+15*s^4-6*s^5);
else
 x=D;v=0;
end
x=sign(target)*x;v=sign(target)*v;
end
