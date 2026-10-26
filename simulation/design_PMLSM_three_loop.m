function g=design_PMLSM_three_loop(Rs,L,M,Kf,Ts_i,Ts_v,Ts_p,xi,h,separation)
% Physical-unit PI gains; speed feedback is mm/s, current is A peak.
% Current PI follows the original xi family. Speed PI follows the original h family.
assert(all([Rs L M Kf Ts_i Ts_v Ts_p xi h separation]>0));
g.Kp_ACR=L/(4*xi^2*Ts_i);
g.Ki_ACR=g.Kp_ACR*Rs/L;
g.omega_i=g.Kp_ACR/L;
g.Kaw_d=min(0.2,Ts_i*Rs/L);g.Kaw_q=g.Kaw_d;
g.Kv=1000*Kf/M;
% Conservative lag budget: current closed-loop lag, half-PWM delay,
% and a full speed sample for the held reference/discrete implementation.
g.Tsum_v=1/g.omega_i+Ts_i/2+Ts_v;
g.Ti_v=h*g.Tsum_v;
g.Kp_ASR=(h+1)/(2*h*g.Tsum_v*g.Kv);
g.Ki_ASR=g.Kp_ASR/g.Ti_v;
g.Kaw_s=min(0.2,Ts_v/g.Ti_v);
g.omega_v_nominal=g.Kp_ASR*g.Kv;
% Position P pole with an ideal inner speed loop; also cap Kp*Ts_pos.
g.Kp_pos=min(g.omega_v_nominal/separation,0.25/Ts_p);
g.xi=xi;g.h=h;g.separation=separation;
end
