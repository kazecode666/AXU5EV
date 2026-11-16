function result=motor_control_compare_foc(trace_path,output_dir)
% Independent, stateful original fixed-point Simulink FOC on the RTL frame table.
assert(batchStartupOptionUsed,'Run through motor_control_run in an isolated process.');
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
deps=fullfile(output_dir,'dependencies');
addpath(deps,fullfile(root,'simulation','motor_control'),'-begin');
evalin('base','init_PMLSM_PI_FOC_Float_Baseline;');
f=fopen(trace_path);cl=onCleanup(@()fclose(f));rows=textscan(f,repmat('%s ',1,15),'CommentStyle','#');
n=numel(rows{1});assert(n>0,'Empty FOC trace');v=zeros(n,15);
for c=1:15,for k=1:n,v(k,c)=hex2dec(rows{c}{k});end,end
% Trace: sample_id,tick,refver, ia ib ic idref iqref theta omega vdc PIreset, du dv dw.
columns=[4 5 6 9 10 8 7 12 11];sign=[1 1 1 1 1 1 1 0 0];width=[32 32 32 40 40 32 32 1 32];frac=[24 24 24 32 24 24 24 0 24];
names={'ia','ib','ic','theta_e','omega_e','iq_ref','id_ref','PI_Reset_EN','Vdc_V'};
t=(0:n-1)'*1e-4;ds=Simulink.SimulationData.Dataset;
for c=1:9
 if c==8,data=logical(v(:,columns(c)));
 else,data=reinterpretcast(fi(v(:,columns(c)),0,width(c),0),numerictype(sign(c),width(c),frac(c)));end
 ds=ds.addElement(timeseries(data,t),names{c});
end
m='PMLSM_FOC_FixedPoint';open_system(fullfile(deps,[m '.slx']));
in=Simulink.SimulationInput(m);in=in.setExternalInput(ds);
% The frozen model's inherited root-port rates otherwise leave auto solver
% selection underconstrained. Bind the test harness ports to the accepted
% 100us contract; this does not change any FOC_DUT arithmetic or state.
for sid=224:232
 port=Simulink.ID.getFullName(sprintf('%s:%d',m,sid));
 in=in.setBlockParameter(port,'SampleTime','1e-4');
 in=in.setBlockParameter(port,'Interpolate','off');
end
in=in.setModelParameter('SaveOutput','on','OutputSaveName','yout','SaveFormat','Dataset', ...
 'StopTime',sprintf('%.12g',t(end)),'SampleTimeConstraint','Unconstrained', ...
 'SolverType','Fixed-step','Solver','FixedStepDiscrete','FixedStep','1e-4','Decimation','1', ...
 'OutputOption','SpecifiedOutputTimes','OutputTimes',mat2str(t.',17));
out=sim(in);save(fullfile(output_dir,'raw_foc_model.mat'),'out','v');actual=zeros(n,3);
for c=1:3
 assert(isequal(size(out.yout{c}.Values.Time),size(t)) && all(abs(out.yout{c}.Values.Time-t)<1e-14),'FOC output logging time grid mismatch');
 actual(:,c)=double(squeeze(out.yout{c}.Values.Data))*2^30;
end
writematrix([v actual],fullfile(output_dir,'foc_model_trace_comparison.csv'));
assert(isequal(actual,v(:,13:15)),'Original FOC model and exact RTL frame duty bits differ');
% Use the same sole mapper authority rather than reimplementing its rounding.
comp=zeros(n,3);
for k=1:n
 [u,w1,w2]=duty_to_compare(true,uint32(actual(k,1)),uint32(actual(k,2)),uint32(actual(k,3)));
 comp(k,:)=double([u w1 w2]);
end
writematrix([v(:,1:3) actual comp],fullfile(output_dir,'foc_model_results.csv'));
result=struct('status','PASS','frames',n,'duty_words_compared',n*3,'source','baselines/pr53_p3/source/PMLSM_FOC_FixedPoint.slx', ...
 'trace',trace_path,'stateful_single_run',true,'board','NOT_RUN');
f2=fopen(fullfile(output_dir,'foc_model_result.json'),'w');cl2=onCleanup(@()fclose(f2));fprintf(f2,'%s\n',jsonencode(result,PrettyPrint=true));disp(result);
end
