function cfg=pmlsm_foc_fixed_config(p)
% 首版受限FOC类型；p只由现有唯一init的物理/PI/时基参数传入。
arguments
 p (1,1) struct
end
required={'Rs','Ld','Lq','psi','Kp_ACR','Ki_ACR','Kaw_d','Kaw_q','Ts_ACR','Udc'};
for k=1:numel(required),assert(isfield(p,required{k})&&isnumeric(p.(required{k}))&&isscalar(p.(required{k}))&&isfinite(p.(required{k}))&&p.(required{k})>0,'M2:CONFIG_INPUT','无效配置参数%s',required{k});end
assert(p.Ts_ACR==1e-4,'M2:PERIOD','首版仅验证100us。');assert(p.Kaw_d<=.25&&p.Kaw_q<=.25,'M2:STATE_BOUND','状态界仅适用于0<Kaw<=.25。');
cfg.Version=20261024;cfg.Parameters=p;cfg.Fimath=fimath('RoundingMethod','Convergent','OverflowAction','Saturate','ProductMode','FullPrecision','SumMode','FullPrecision');
defs={'Current',1,32,24;'Angle',1,40,32;'Omega',1,40,24;'Bus',0,32,24;'Work',1,64,40;'Square',0,64,36;'DivideWide',0,72,40;'Duty',0,32,30;'Coefficient',1,64,40;'Time',1,64,40};
cfg.Types=struct;cfg.TypeStrings=struct;for k=1:size(defs,1),n=defs{k,1};cfg.Types.(n)=numerictype(defs{k,2},defs{k,3},defs{k,4});cfg.TypeStrings.(n)=sprintf('fixdt(%d,%d,%d)',defs{k,2},defs{k,3},defs{k,4});end
cfg.Types.Reset='boolean';cfg.Types.Sector='uint8';cfg.TypeStrings.Reset='boolean';cfg.TypeStrings.Sector='uint8';
cfg.Ranges=struct('phase_current_A',2,'reference_A',2,'theta_abs_rad',8*pi,'omega_abs_radps',100,'Vdc_min_V',12,'Vdc_max_V',60,'verified_duration_s',60,'state_initial_V',0,'scope','engineering verification envelope, not motor/drive ratings');
axisBound=sqrt((8/3)^2+(4/sqrt(3))^2);e=2+axisBound;ff=100*(max(p.Ld,p.Lq)*axisBound+p.psi);u=.9*60/sqrt(3);kaw=min(p.Kaw_d,p.Kaw_q);
% x[k+1]=x[k]-Kaw*x[k-1]+bounded_forcing；根在(0,1)，脉冲响应非负且和1/Kaw。
cfg.Ranges.park_axis_bound_A=axisBound;cfg.Ranges.error_bound_A=e;cfg.Ranges.feedforward_bound_V=ff;unresetBound=p.Ki_ACR*p.Ts_ACR*e/kaw+p.Kp_ACR*e+ff+u;
% 复位仅清积分、不清前拍AW：每个复位后齐次响应最多a*S；保留1/(1-a)余量。
cfg.Ranges.integrator_bound_V=unresetBound/(1-max(p.Kaw_d,p.Kaw_q));cfg.Ranges.raw_voltage_bound_V=cfg.Ranges.integrator_bound_V+p.Kp_ACR*e+ff;cfg.Ranges.square_sum_bound_V2=2*cfg.Ranges.raw_voltage_bound_V^2;
values=struct('Kp',p.Kp_ACR,'KiTs',p.Ki_ACR*p.Ts_ACR,'Kaw_d',p.Kaw_d,'Kaw_q',p.Kaw_q,'Ld',p.Ld,'Lq',p.Lq,'psi',p.psi,'Ts',p.Ts_ACR,'InvSqrt3',1/sqrt(3),'TwoThird',2/3,'C0866',.866,'C17321',1.7321,'C09',.9,'C0999',.999,'Epsilon',1e-6,'DutyGain',-2/p.Ts_ACR);
cfg.Coefficients=struct;names=fieldnames(values);for k=1:numel(names),name=names{k};v=values.(name);q=fi(v,cfg.Types.Coefficient,cfg.Fimath);cfg.Coefficients.(name)=struct('original',v,'quantized',double(q),'error',double(q)-v);end
assert(cfg.Coefficients.Epsilon.quantized>0);assert(cfg.Ranges.square_sum_bound_V2<2^28,'M2:STATE_CAPACITY','范围推导超出首版平方类型。');
end
