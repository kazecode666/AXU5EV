function result=motor_control_system_batch(output_dir)
% Controlled numerical system run, isolated from user base workspace/models.
assert(batchStartupOptionUsed,'Use motor_control_run.');
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));deps=fullfile(output_dir,'dependencies');
addpath(deps,fullfile(root,'simulation','motor_control'),fullfile(root,'simulation','real_io'),fullfile(root,'simulation','encoder'),'-begin');
addpath(deps,'-begin'); % Explicitly prefer the accepted single-source snapshots.
evalin('base','init_PMLSM_PI_FOC_Float_Baseline;');
Simulink.fileGenControl('set','CacheFolder',fullfile(output_dir,'cache'), ...
 'CodeGenFolder',fullfile(output_dir,'code'),'createDir',true);
m='AXU5EV_Motor_Control_System';open_system(fullfile(root,'simulation','motor_control',[m '.slx']));
assert(strcmp(get_param(m,'Dirty'),'off'));
in=Simulink.SimulationInput(m);in=in.setModelParameter('StopTime','.0054','OutputOption','RefineOutputTimes','Refine','1','Decimation','1');out=sim(in);
save(fullfile(output_dir,'raw_system_model.mat'),'out');
% yout ports are explicitly ordered and remain dataset logs at the 20ns base rate.
names={'sample_id','reference_version','ia_A','theta_rad','feedback_valid', ...
 'duty_u','duty_v','duty_w','compare_u','compare_v','compare_w', ...
 'applied_u','applied_v','applied_w','position_mm','speed_mm_s','position_valid','speed_valid'};
data=cell(1,numel(names));
for k=1:numel(names),data{k}=out.yout{k}.Values;end
assert(any(data{5}.Data),'No calibrated same-frame feedback reached FOC');
assert(any(double(data{3}.Data)~=0) && any(double(data{4}.Data)~=0),'Current/angle chain remained empty');
assert(any(double(data{7}.Data)~=0.5),'FOC output did not respond to precommitted IQ step');
assert(any(double(data{10}.Data)~=2500 & double(data{10}.Data)>0),'Generated duty compare path did not execute');
assert(any(double(data{13}.Data)>0),'SIM_ONLY valley hold never adopted generated values');
assert(any(data{17}.Data),'Generated-software position source did not execute');
assert(any(data{18}.Data),'50-interval speed history never became valid');
% Export one row per logical FOC frame; electrical pin timing belongs to RTL/SDF.
t=(0:54)'*1e-4;frames=zeros(numel(t),numel(names));
for k=1:numel(names)
 % The registered mapper output is a one-clock event; sample its active clock,
 % not the next (cleared) clock. All other channels are held over this interval.
 frames(:,k)=interp1(data{k}.Time,double(squeeze(data{k}.Data)),min(t+2.0001e-8,data{k}.Time(end)),'previous');
end
writetable(array2table(frames,'VariableNames',names),fullfile(output_dir,'system_frames.csv'));
result=struct('status','PASS','model',m,'frames',size(frames,1), ...
 'physical_timing','SIM_ONLY logical reference is shifted one frame; RTL uses P128 capture/target valley', ...
 'source_relation','dependencies/source_relation.json','r5_history_entries',51,'board','NOT_RUN');
f=fopen(fullfile(output_dir,'system_result.json'),'w');cl=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(result,PrettyPrint=true));disp(result);
end
