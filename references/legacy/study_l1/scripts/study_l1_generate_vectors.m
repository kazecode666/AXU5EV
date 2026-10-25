function v = study_l1_generate_vectors(p)
% Input rows at 100 us. Real scheduler first tick is at row 10 (0.9 ms).
threshold=p.Speed_loop_Iq_Limit/p.Kp_ASR;
commands=[zeros(1,4),2*ones(1,12),-2*ones(1,12), ...
    2*threshold*ones(1,40),zeros(1,10), ...
    -2*threshold*ones(1,40),2*threshold*ones(1,30), ...
    -2*threshold*ones(1,30),zeros(1,15),2*ones(1,65)];
n=numel(commands)*10;
v.time=(0:n-1)'*p.Ts;
v.v_ref=repelem(commands(:),10);
v.v_meas=zeros(n,1);
v.enable=ones(n,1); v.reset=zeros(n,1);
v.angle_init=zeros(n,1); v.test_mode=zeros(n,1);
v.tick=double(mod((1:n)',10)==0);
% Saturated reset/disable must preserve excess even while iq_ref becomes zero.
v.reset(450)=1; v.enable(501:520)=0;
% Int-reset without hard-reset: |vref|>.5 AND sign(vref)*error < -3.
v.v_ref(1951:1980)=5; v.v_meas(1951:1980)=10;
% Unaligned reset one step before tick, on tick, one step after tick,
% reset wholly between ticks (must have NO effect), and disable/re-enable.
v.reset(2059:2061)=1;
v.reset(2101:2103)=1;
v.reset(2140)=1;
v.enable(2181:2240)=0;
v.angle_init(2270)=1; v.test_mode(2300)=1;
% Small fractional errors with nonzero measurement (both input quantizers).
v.v_ref(2311:end)=.12345; v.v_meas(2311:end)=-.23456;
% Strict reset predicate boundaries (not <= / >= substitutions).
v.v_ref(2401:2440)=.5; v.v_meas(2401:2440)=10;
v.v_ref(2441:2480)=5; v.v_meas(2441:2480)=8;
v.v_ref(2481:2510)=5; v.v_meas(2481:2510)=8.0001;
end
