function [d,raw] = study_l1_fixed_reference(v,mode,p)
% Independent scalar fi reference. No Simulink graph or runtime state reused.
t=study_l1_types(mode);
F=fimath('RoundingMethod','Convergent','OverflowAction','Saturate', ...
    'ProductMode','FullPrecision','SumMode','FullPrecision');
kp=q(p.Kp_ASR,t.coeff); ki=q(p.Ki_ASR*p.Ts_ASR,t.coeff); kaw=q(p.Kaw_s,t.coeff);
x=q(0,t.state); previous=q(0,t.work);
fields={'iq_ref','iq_unlimited','integrator','saturation','integrator_next', ...
    'previous_excess','excess_next','hard_reset','int_reset','iq_limited','error','P','KiTs','AW'};
for k=1:numel(fields)
    d.(fields{k})=zeros(numel(v.time),1);
    raw.(fields{k})=zeros(numel(v.time),1);
end
for n=1:numel(v.time)
    if v.tick(n)~=0
        ref=q(v.v_ref(n),t.input); meas=q(v.v_meas(n),t.input);
        e=q(ref-meas,t.error); proportional=q(e*kp,t.work);
        inc=q(e*ki,t.work); aw=q(previous*kaw,t.work);
        unlimited=q(proportional+x,t.sum);
        limited=q(max(-p.Speed_loop_Iq_Limit,min(p.Speed_loop_Iq_Limit,double(unlimited))),t.sum);
        excess=q(unlimited-limited,t.work);
        candidate=q(x+inc-aw,t.acc);
        candidate=q(max(-p.Iq_int_limit,min(p.Iq_int_limit,double(candidate))),t.state);
        hard=logical(v.angle_init(n) || v.reset(n) || v.test_mode(n) || ~v.enable(n));
        over=abs(double(ref))>p.v_ff_eps && sign(double(ref))*double(e)<-p.v_over_eps;
        intreset=hard || abs(double(ref))<p.v_ref_zero_eps || over;
        iq=q(double(limited)*(~hard),t.output);
        next=q(double(candidate)*(~intreset),t.state);
        values={iq,unlimited,x,unlimited~=limited,next,previous,excess,hard,intreset,limited,e,proportional,inc,aw};
        for k=1:numel(fields)
            d.(fields{k})(n)=double(values{k});
            if isfi(values{k}), raw.(fields{k})(n)=double(storedInteger(values{k}));
            else, raw.(fields{k})(n)=double(values{k}); end
        end
        x=next; previous=excess;
    elseif n>1
        for k=1:numel(fields)
            d.(fields{k})(n)=d.(fields{k})(n-1);
            raw.(fields{k})(n)=raw.(fields{k})(n-1);
        end
    end
end
    function value=q(value,format)
        type=sscanf(format,'fixdt(%d,%d,%d)');
        assert(numel(type)==3);
        value=fi(value,type(1),type(2),type(3),F);
    end
end
