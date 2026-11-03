function result=axu5ev_prepare_ax02c2_data(outputRoot)
% Generate only the shared-model thin adapter and the matching fixed reference.
% Run in a dedicated MATLAB batch process through MATLAB MCP.
assert(batchStartupOptionUsed,'Use dedicated batch MATLAB; keep interactive parameters untouched.');
root=fileparts(fileparts(mfilename('fullpath')));
assert(~isfolder(outputRoot),'Use an unoccupied C2 output root.');mkdir(outputRoot);
oldpath=path;oldpwd=pwd;oldgen=Simulink.fileGenControl('getConfig');
cleanup=onCleanup(@()restore(oldpath,oldpwd,oldgen)); %#ok<NASGU>
addpath(fullfile(root,'simulation'));
evalin('base','init_AXU5EV;');
source='AXU5EV_Hybrid_ClosedLoop';load_system(fullfile(root,'simulation',[source '.slx']));
sourceDirty=get_param(source,'Dirty');
work=fullfile(outputRoot,'adapter_01');mkdir(work);cd(work);
Simulink.fileGenControl('set','CacheFolder',fullfile(work,'cache'),'CodeGenFolder',fullfile(work,'codegen'),'createDir',true);
m='AX02C2_Adapter';new_system(m);
set_param(m,'SolverType','Fixed-step','Solver','FixedStepDiscrete','FixedStep','0.0001', ...
 'SystemTargetFile','ert.tlc','GenCodeOnly','on','GenerateReport','off', ...
 'ProdHWDeviceType','ARM Compatible->ARM Cortex-R','ProdEndianess','LittleEndian', ...
 'CodeInterfacePackaging','Nonreusable function','TargetLang','C','ProdLongLongMode','on');
input(m,'runtime_u',20,1);input(m,'runtime_y',41,2);input(m,'feedback',5,3);
add_block([source '/Alignment_Interface'],[m '/Alignment_Interface']);
add_block([source '/Frame_Quantization'],[m '/Frame_Quantization']);
add_block([source '/Effective_PI_Reset'],[m '/Effective_PI_Reset']);
add_block([source '/PWM_Disabled'],[m '/PWM_Disabled']);
add_block([source '/PI_Reset_Field_Double'],[m '/PI_Reset_Field_Double']);
add_block('simulink/Signal Routing/Mux',[m '/FOC_Fields'],'Inputs','9');
add_block('simulink/Sinks/Out1',[m '/frame_q'],'Port','1');
% Source wiring: Runtime Y4/Y8/Y7, input20 Init_Reset/Alignment/Travel/x,
% recorded theta/omega, actual Runtime PWM request.
from={'runtime_y_fields/4','runtime_y_fields/8','runtime_y_fields/7', ...
 'runtime_u_fields/18','runtime_u_fields/16','feedback_fields/4', ...
 'runtime_u_fields/19','feedback_fields/5','runtime_u_fields/20','runtime_y_fields/18'};
for k=1:10,add_line(m,from{k},sprintf('Alignment_Interface/%d',k),'autorouting','on');end
add_line(m,'Alignment_Interface/3','PWM_Disabled/1');
add_line(m,'runtime_y_fields/23','Effective_PI_Reset/1');
add_line(m,'PWM_Disabled/1','Effective_PI_Reset/2');
add_line(m,'Effective_PI_Reset/1','PI_Reset_Field_Double/1');
from={'feedback_fields/1','feedback_fields/2','feedback_fields/3','Alignment_Interface/1', ...
 'Alignment_Interface/2','runtime_y_fields/2','runtime_y_fields/1', ...
 'PI_Reset_Field_Double/1','runtime_y_fields/14'};
for k=1:9,add_line(m,from{k},sprintf('FOC_Fields/%d',k),'autorouting','on');end
add_line(m,'FOC_Fields/1','Frame_Quantization/1');add_line(m,'Frame_Quantization/1','frame_q/1');
set_param(m,'SimulationCommand','update');
save_system(m,fullfile(work,[m '.slx']));slbuild(m);

old=load(fullfile(root,'.runtime','ax01c','c_fixed_continuous.mat'),'out');
u=axu5ev_matrix(old.out.r5_snapshot);t=old.out.r5_snapshot.Time(:);
current=load(fullfile(root,'.runtime','ax02a','replay','current_motion','reference.mat'));
assert(isequal(u,current.inputs)&&isequal(t,current.time)&&size(u,1)==64536);
assert(all(u(:,16)==0),'Recorded omega is valid as ideal feedback for this bypass scenario.');
feedback=zeros(size(u,1),5);
names={'ia','ib','ic','theta_true_rad'};
for k=1:4
 signal=old.out.logsout.get(names{k}).Values;
 assert(numel(signal.Time)==numel(t)&&max(abs(signal.Time(:)-t))<1e-12);
 feedback(:,k)=axu5ev_matrix(signal);
end
oldq=axu5ev_matrix(old.out.foc_frame);
feedback(:,5)=oldq(:,5); % same recorded angular feedback, already exact s40/24
assert(isequal(axu5ev_matrix(old.out.logsout.get('x_mm').Values),u(:,20)));
ds=Simulink.SimulationData.Dataset;inputNames={'runtime_u','runtime_y','feedback'};
for k=1:3
 value={u,current.outputs,feedback};ts=timeseries(value{k},t);ts=setinterpmethod(ts,'zoh');
 ds=ds.addElement(ts,inputNames{k});
end
in=Simulink.SimulationInput(m);in=in.setExternalInput(ds);
in=in.setModelParameter('StopTime',num2str(t(end),17),'SaveOutput','on','SaveFormat','Dataset','ReturnWorkspaceOutputs','on');
adapted=sim(in);q=axu5ev_matrix(adapted.yout{1}.Values);
assert(numel(adapted.yout{1}.Values.Time)==numel(t)&&max(abs(adapted.yout{1}.Values.Time(:)-t))<1e-12);
% Validate the adapter against the original same-record bypass path first.
ds=Simulink.SimulationData.Dataset;
value={u,axu5ev_matrix(old.out.r5_commit),feedback};
for k=1:3,ts=timeseries(value{k},t);ts=setinterpmethod(ts,'zoh');ds=ds.addElement(ts,inputNames{k});end
inOld=in.setExternalInput(ds);oldAdapted=sim(inOld);oldAdapterQ=axu5ev_matrix(oldAdapted.yout{1}.Values);
assert(isequal(oldAdapterQ,oldq),'Copied adapter differs from original recorded quantized frame.');

f='AX02C2_FOC_Reference';new_system(f);
set_param(f,'SolverType','Fixed-step','Solver','FixedStepDiscrete','FixedStep','0.0001');
add_block('simulink/Sources/In1',[f '/frame_q'],'PortDimensions','9','SampleTime','0.0001','OutDataTypeStr','double');
add_block([source '/FOC_Execution/Fixed_Reference'],[f '/Accepted_Fixed_Reference']);
add_block('simulink/Sinks/Out1',[f '/duty'],'Port','1');
add_line(f,'frame_q/1','Accepted_Fixed_Reference/1');add_line(f,'Accepted_Fixed_Reference/1','duty/1');
save_system(f,fullfile(work,[f '.slx']));
ts=timeseries(q,t);ts=setinterpmethod(ts,'zoh');ds=Simulink.SimulationData.Dataset;ds=ds.addElement(ts,'frame_q');
in=Simulink.SimulationInput(f);in=in.setExternalInput(ds);in=in.setModelParameter('StopTime',num2str(t(end),17), ...
 'SaveOutput','on','SaveFormat','Dataset','ReturnWorkspaceOutputs','on');
foc=sim(in);duty=axu5ev_matrix(foc.yout{1}.Values);
words=uint32(duty*2^30);assert(all(double(words)==duty*2^30,'all'));
data=fullfile(outputRoot,'data','current_motion');mkdir(data);
writebin(fullfile(data,'feedback.bin'),feedback,'double');writebin(fullfile(data,'foc_reference.bin'),words,'uint32');
copyfile(fullfile(root,'.runtime','ax02a','replay','current_motion','input.bin'),data);
copyfile(fullfile(root,'.runtime','ax02a','replay','current_motion','reference.bin'),data);
metadata=current.report;metadata.feedback_fields=5;metadata.feedback_names={'ia_A','ib_A','ic_A','theta_ideal_rad','omega_ideal_radps'};
metadata.feedback_source=fullfile(root,'.runtime','ax01c','c_fixed_continuous.mat');
metadata.omega_source='Original foc_frame field5, s40/24 physical angular feedback; current_motion Alignment_Enable=0 throughout.';
metadata.foc_reference_source='Same-record feedback + current_motion Runtime41 -> copied shared adapter -> accepted model_fixed FOC';
metadata.foc_reference_format='LE uint32 frame-major duty_u,duty_v,duty_w';metadata.foc_reference_fields=3;
metadata.adapter_generated=fullfile(work,'codegen',[m '_ert_rtw']);
metadata.adapter_recorded_frame_mismatches=nnz(oldAdapterQ~=oldq);
writejson(fullfile(data,'metadata.json'),metadata);
save(fullfile(data,'reference.mat'),'u','feedback','q','words','t','metadata','-v7.3');
result=struct('status','DATA_AND_ADAPTER_GENERATE_PASS','frames',size(u,1),'feedback_fields',5, ...
 'data',data,'adapter_generated',metadata.adapter_generated,'original_frame_matches',numel(oldq), ...
 'runtime_reference',fullfile(root,'.runtime','ax02a','replay','current_motion','reference.bin'));
writejson(fullfile(outputRoot,'generation.json'),result);
assert(strcmp(get_param(source,'Dirty'),sourceDirty));
close_system(m,0);close_system(f,0);close_system(source,0);
disp(result);
end
function input(m,name,width,port)
add_block('simulink/Sources/In1',[m '/' name],'Port',num2str(port),'PortDimensions',num2str(width),'SampleTime','0.0001');
add_block('simulink/Signal Routing/Demux',[m '/' name '_fields'],'Outputs',num2str(width));
add_line(m,[name '/1'],[name '_fields/1']);
end
function writebin(p,x,type)
f=fopen(p,'w','ieee-le');c=onCleanup(@()fclose(f));fwrite(f,x',type);
end
function writejson(p,value)
f=fopen(p,'w');c=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(value,PrettyPrint=true));
end
function restore(oldpath,oldpwd,oldgen)
for name={'AX02C2_Adapter','AX02C2_FOC_Reference','AXU5EV_Hybrid_ClosedLoop'}
 if bdIsLoaded(name{1}),close_system(name{1},0);end
end
path(oldpath);cd(oldpwd);Simulink.fileGenControl('setConfig','config',oldgen);
end
