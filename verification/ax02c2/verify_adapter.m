function result=verify_adapter(prepared,adapterPrepared,checkName)
% Necessary generated-C comparison for this new model-derived adapter only.
assert(batchStartupOptionUsed,'Use dedicated batch MATLAB via MCP.');
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin<2,adapterPrepared=prepared;end
if nargin<3,checkName='adapter_check';end
addpath(fullfile(root,'simulation'));evalin('base','init_AXU5EV;');
saved=load(fullfile(prepared,'data','current_motion','reference.mat'));
reference=load(fullfile(root,'.runtime','ax02a','replay','current_motion','reference.mat'),'outputs');
generated=fullfile(adapterPrepared,'adapter_01','codegen','AX02C2_Adapter_ert_rtw');
out=fullfile(prepared,checkName);assert(~isfolder(out));mkdir(out);
sources=dir(fullfile(generated,'*.c'));sources=sources(~strcmp({sources.name},'ert_main.c'));
sources=fullfile(generated,{sources.name});
mex('-R2018a',['-I' generated],['-I' fullfile(root,'integration','ax02c2_adapter')], ...
 fullfile(root,'verification','ax02c2','adapter_probe_mex.c'), ...
 fullfile(root,'integration','ax02c2_adapter','ax02c2_adapter_api.c'),sources{:}, ...
 '-outdir',out,'-output','ax02c2_adapter_probe');
addpath(out);
actual=ax02c2_adapter_probe(saved.u,reference.outputs,saved.feedback);
expected=pack(saved.q);assert(isequal(actual,expected),'Generated adapter differs from copied model.');
u=repmat(saved.u(1,:),8,1);y=repmat(reference.outputs(1,:),8,1);feedback=repmat(saved.feedback(1,:),8,1);
u(:,16)=1;y(:,4)=1;y(:,18)=1;y(:,14)=48;
feedback(:,1:5)=repmat([.25 -.5 .125 .9 -2.2],8,1);
u(:,20)=-1.2;y(:,1)=.3;y(:,2)=-.4;y(:,8)=.125;
u(1,16)=0; % bypass
y(2,7)=1;y(2,4)=0; % active alignment / fixed angle, zero omega
y(3,8)=.7; % normal position angle + runtime offset
y(4,18)=0; % disabled PWM -> effective PI reset
y(5,23)=1; % requested PI reset
u(6,19)=1; % alignment fault prohibits PWM
u(7,18)=1; % Init_Reset takes original separate path
feedback(8,1:3)=[1.5*2^-24 -1.5*2^-24 128.1];
y(8,1)=-129;y(8,2)=129;y(8,14)=300; % copied numeric saturation
t=(0:7)'*1e-4;ds=Simulink.SimulationData.Dataset;names={'runtime_u','runtime_y','feedback'};values={u,y,feedback};
for k=1:3,ts=timeseries(values{k},t);ts=setinterpmethod(ts,'zoh');ds=ds.addElement(ts,names{k});end
m='AX02C2_Adapter';load_system(fullfile(adapterPrepared,'adapter_01',[m '.slx']));
in=Simulink.SimulationInput(m);in=in.setExternalInput(ds);in=in.setModelParameter( ...
 'StopTime',num2str(t(end),17),'SaveOutput','on','SaveFormat','Dataset','ReturnWorkspaceOutputs','on');
probe=sim(in);q=axu5ev_matrix(probe.yout{1}.Values);
actualProbe=ax02c2_adapter_probe(u,y,feedback);expectedProbe=pack(q);
assert(isequal(actualProbe,expectedProbe),'Generated C differs on necessary mode/reset/numeric branches.');
result=struct('status','ADAPTER_MODEL_C_PASS','current_motion_frames',size(actual,1), ...
 'current_motion_word_checks',numel(actual),'semantic_frames',8,'semantic_word_checks',numel(actualProbe), ...
 'mismatches',0,'comparison','exact uint32 words; generated C vs copied shared Alignment_Interface + Frame_Quantization', ...
 'modes',{{'bypass','active_alignment','runtime_offset','PWM_disabled','PI_Reset','travel_fault','Init_Reset','Convergent_Saturate'}}, ...
 'prepared',prepared,'application_adapter_generated',generated, ...
 'mex',fullfile(out,['ax02c2_adapter_probe.' mexext]),'board','NOT_RUN');
f=fopen(fullfile(out,'result.json'),'w');c=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(result,PrettyPrint=true));
save(fullfile(out,'semantic.mat'),'u','y','feedback','q','actualProbe','expectedProbe');
close_system(m,0);disp(result);
end
function words=pack(q)
words=zeros(size(q,1),11,'uint32');
for k=1:3,words(:,k)=reshape(typecast(int32(q(:,k)*2^24),'uint32'),[],1);end
theta=reshape(typecast(int64(q(:,4)*2^32),'uint64'),[],1);
omega=reshape(typecast(int64(q(:,5)*2^24),'uint64'),[],1);
words(:,4)=uint32(bitand(theta,uint64(4294967295)));words(:,5)=uint32(bitand(bitshift(theta,-32),uint64(255)));
words(:,6)=uint32(bitand(omega,uint64(4294967295)));words(:,7)=uint32(bitand(bitshift(omega,-32),uint64(255)));
words(:,8)=reshape(typecast(int32(q(:,6)*2^24),'uint32'),[],1);
words(:,9)=reshape(typecast(int32(q(:,7)*2^24),'uint32'),[],1);
words(:,10)=uint32(q(:,8));words(:,11)=uint32(q(:,9)*2^24);
end
