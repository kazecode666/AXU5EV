function result = axu5ev_build_pl_target(runDir)
%AXU5EV_BUILD_PL_TARGET Isolated p3 -> 5EV generation, in a dedicated batch process.
% Invoke through MATLAB MCP; no board access, synthesis or user-model saves.
arguments
    runDir (1,:) char
end
assert(batchStartupOptionUsed,'AX02B:Batch','Use a separate MATLAB -batch process to preserve the interactive base workspace.');
root=fileparts(fileparts(mfilename('fullpath')));
assert(~isfolder(runDir),'AX02B:Exists','Select an unoccupied candidate directory.');
mkdir(runDir); modelDir=fullfile(runDir,'model');mkdir(modelDir);
source=fullfile(root,'baselines','pr53_p3','source');
files=dir(fullfile(source,'*.m'));
for k=1:numel(files),copyfile(fullfile(source,files(k).name),modelDir);end
m='AX02B_P3_5EV';
copyfile(fullfile(source,'PMLSM_FOC_FixedPoint.slx'),fullfile(modelDir,[m '.slx']));
oldpwd=pwd;oldpath=path;oldgen=Simulink.fileGenControl('getConfig');
cleanup=onCleanup(@()restore(m,oldpwd,oldpath,oldgen)); %#ok<NASGU>
cd(modelDir);addpath(modelDir,'-begin');
Simulink.fileGenControl('set','CacheFolder',fullfile(runDir,'cache'),'CodeGenFolder',fullfile(runDir,'code'),'createDir',true);
evalin('base','init_PMLSM_PI_FOC_Float_Baseline;');
load_system(fullfile(modelDir,[m '.slx']));
set_param(m,'FixedStep','Ts_ACR','SampleTimeConstraint','Unconstrained','DataTypeOverride','Off','SimulationMode','normal');
inputs=find_system(m,'SearchDepth',1,'BlockType','Inport');
for k=1:numel(inputs),set_param(inputs{k},'SampleTime','Ts_ACR','Interpolate','off');end
base=jsondecode(fileread(fullfile(root,'baselines','pr53_p3','codegen','hdl_config_readback.json')));
names=fieldnames(base);readback=struct;
for k=1:numel(names)
    name=names{k};if startsWith(name,'candidate_'),continue;end
    value=base.(name);
    if strcmp(name,'ResetType'),value='sync';end
    if strcmp(name,'ResetAssertedLevel'),value='active-high';end
    hdlset_param(m,name,value);
end
% Read the installed tool's supported list, not a guessed family enum.
xml=fullfile(matlabroot,'toolbox','hdlcoder','downstreamtools','vivado','+downstreamtools','+XilinxVivado_2025_1','device_list.xml');
doc=xmlread(xml);families=doc.getElementsByTagName('Family');family='';
for k=0:families.getLength-1
    f=families.item(k);devices=f.getElementsByTagName('Device');
    for j=0:devices.getLength-1
        if strcmp(char(devices.item(j).getAttribute('name')),'xczu5ev-sfvc784-2-i'),family=char(f.getAttribute('name'));end
    end
end
assert(~isempty(family),'AX02B:Device','5EV part absent from installed support list.');
hdlset_param(m,'SynthesisToolChipFamily',family,'SynthesisToolDeviceName','xczu5ev', ...
    'SynthesisToolPackageName','sfvc784','SynthesisToolSpeedValue','-2','TargetFrequency',50);
candidate=jsondecode(fileread(fullfile(root,'baselines','pr53_p3','codegen','candidate.json')));
for k=1:numel(candidate.settings)
    s=candidate.settings(k);p=Simulink.ID.getFullName(sprintf('%s:%d',m,s.SID));
    hdlset_param(p,s.property,s.value);
    assert(strcmpi(string(hdlget_param(p,s.property)),string(s.value)));
end
for k=1:numel(names)
    if ~startsWith(names{k},'candidate_'),readback.(names{k})=hdlget_param(m,names{k});end
end
readback.candidate_settings=candidate.settings;
writejson(fullfile(runDir,'hdl_config_readback.json'),readback);
checks=checkhdl([m '/FOC_DUT']);writejson(fullfile(runDir,'checkhdl.json'),checks);
assert(~any(strcmpi({checks.level},'Error')),'AX02B:HDL','HDL compatibility failure.');
save_system(m,fullfile(modelDir,[m '.slx']));
makehdl([m '/FOC_DUT'],'TargetDirectory',fullfile(runDir,'rtl'));
result=struct('status','GENERATE_PASS','source','baselines/pr53_p3/source', ...
    'model',m,'run_dir',runDir,'matlab',version,'supported_device_list',xml, ...
    'part','xczu5ev-sfvc784-2-i','frame_cycles',5000,'clock_mhz',50);
writejson(fullfile(runDir,'generation.json'),result);
disp('AX02B_GENERATE_PASS');
end
function restore(m,oldpwd,oldpath,oldgen)
if bdIsLoaded(m),close_system(m,0);end
cd(oldpwd);path(oldpath);Simulink.fileGenControl('setConfig','config',oldgen);
end
function writejson(p,value)
f=fopen(p,'w');c=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(value,PrettyPrint=true));
end
