function ax00_run_case(kind,backend)
% 每次由独立 -batch 进程运行；不保存模型或用户会话。
root=fileparts(fileparts(mfilename('fullpath')));
restoredefaultpath;
if strcmp(kind,'frozen'),active=fullfile(root,'baselines/pr53_p3/source');else,active=fullfile(root,'simulink模型');end
addpath(active,fullfile(root,'scripts'));
runtime=fullfile(root,'.runtime','ax00',[kind '_' num2str(backend)]);
if ~isfolder(runtime),mkdir(runtime);end
cd(runtime);
Simulink.fileGenControl('set','CacheFolder',fullfile(runtime,'cache'),'CodeGenFolder',fullfile(runtime,'codegen'),'createDir',true);
evalin('base','init_PMLSM_PI_FOC_Float_Baseline;');
evalin('base',sprintf('Host_Target_mm=1;M1A_StopTime_s=1.2;Host_Traj_Vmax=5;Host_Traj_Amax=50;FOC_Impl_Select=%d;',backend));
m='PMLSM_PI_FOC_Float_Baseline';
in=Simulink.SimulationInput(m);in=in.setModelParameter('StopTime','1.2');
out=sim(in);
names=out.logsout.getElementNames;
signals=struct;
for k=1:numel(names)
 v=out.logsout.get(names{k}).Values;
 if isa(v,'timeseries'),signals.(matlab.lang.makeValidName(names{k}))=struct('time',v.Time,'data',v.Data);end
end
loaded=find_system('type','block_diagram');files=cell(size(loaded));
for k=1:numel(loaded)
 files{k}=get_param(loaded{k},'FileName');
 assert(isempty(files{k})||startsWith(files{k},root,'IgnoreCase',true)||startsWith(files{k},matlabroot,'IgnoreCase',true),'AX00:DEPENDENCY','Unexpected loaded model: %s',files{k});
end
deps={'init_PMLSM_PI_FOC_Float_Baseline','m1a_require_float_init','design_PMLSM_three_loop','pmlsm_foc_fixed_config','pmlsm_point_move_step','pmlsm_scurve_profile','PMLSM_PI_FOC_Float_Baseline','PMLSM_FOC_FixedPoint'};
resolved=struct;
for k=1:numel(deps)
 p=which(deps{k},'-all');resolved.(deps{k})=p;
 if ischar(p),p={p};end
 for j=1:numel(p),assert(startsWith(p{j},active,'IgnoreCase',true),'AX00:SHADOW','Unexpected path: %s',p{j});end
end
assert(~contains(lower(path),'fpga_xc7a200t'));
audit=struct('kind',kind,'backend',backend,'version',version,'process',feature('getpid'),'active',active,'loaded_files',{files},'resolved',resolved,'signal_names',{names},'path',path,'status','PASS');
save(fullfile(runtime,'signals.mat'),'signals','audit','-v7.3');
f=fopen(fullfile(root,'coordination','reports',['path_' kind '_' num2str(backend) '.json']),'w');fprintf(f,'%s',jsonencode(audit,PrettyPrint=true));fclose(f);
fprintf('AX00_CASE_PASS %s backend=%d signals=%d\n',kind,backend,numel(names));
end
