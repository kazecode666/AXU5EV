function info=axu5ev_build_r5_target(outputDir)
% Independent ARM Cortex-R code generation; restore active PC config on all exits.
root=fileparts(fileparts(mfilename('fullpath')));
if nargin==0,outputDir=fullfile(root,'.runtime','ax02a','target');end
assert(~isfolder(outputDir),'Use a new output directory.');
assert(evalin('base','exist(''PMLSM_M1A_InitVersion'',''var'')==1'), ...
    'Load the current init_AXU5EV.m once before building.');
model='AXU5EV_R5_Runtime';
if ~bdIsLoaded(model),load_system(fullfile(root,'simulation',[model '.slx']));end
assert(strcmp(get_param(model,'SimulationStatus'),'stopped'));
original=getActiveConfigSet(model);originalName=original.Name;
originalDirty=get_param(model,'Dirty');folders=Simulink.fileGenControl('getConfig');
temporary=copy(original);temporary.Name='AX02A_Cortex_R_temporary';
% Confirm the installed release actually registers this production device.
processor=target.get('Processor','ARM Compatible-ARM Cortex-R');
assert(isscalar(processor)&&processor.IsValid);
set_param(temporary,'ProdHWDeviceType','ARM Compatible->ARM Cortex-R', ...
    'ProdEqTarget','on','ProdEndianess','LittleEndian', ...
    'SystemTargetFile','ert.tlc','GenCodeOnly','on','GenerateReport','off');
assert(strcmp(get_param(temporary,'TargetLang'),'C'));
assert(strcmp(get_param(temporary,'CodeInterfacePackaging'),'Nonreusable function'));
assert(isempty(get_param(temporary,'PostCodeGenCommand')));
mkdir(outputDir);
attachConfigSet(model,temporary);
cleanup=onCleanup(@()restore(model,originalName,temporary.Name,folders,originalDirty));
setActiveConfigSet(model,temporary.Name);
Simulink.fileGenControl('set','CacheFolder',fullfile(outputDir,'cache'), ...
    'CodeGenFolder',fullfile(outputDir,'codegen'),'createDir',true);
slbuild(model);
info=struct('matlab',version,'model',get_param(model,'FileName'), ...
    'generated',fullfile(outputDir,'codegen',[model '_ert_rtw']), ...
    'production',get_param(temporary,'ProdHWDeviceType'), ...
    'byte_order',get_param(temporary,'ProdEndianess'), ...
    'double_bits',64,'float_abi','determined by target compiler, not code generation');
keys={'ProdBitPerChar','ProdBitPerShort','ProdBitPerInt','ProdBitPerLong', ...
    'ProdBitPerLongLong','ProdWordSize','ProdIntDivRoundTo','ProdShiftRightIntArith'};
for j=1:numel(keys),info.(keys{j})=get_param(temporary,keys{j});end
parameters={'Ts_ACR','Ts_ASR','Ts_POS','Host_Traj_Vmax','Host_Traj_Amax', ...
    'Host_Traj_Jmax','v_ref_set_rate_up','v_ref_set_rate_dn','Kp_ASR','Ki_ASR', ...
    'Kp_pos','Ramp_Ticks','Hold_Ticks','Id_Release_Ramp_Ticks','Id_Init_Target'};
for j=1:numel(parameters),info.parameters.(parameters{j})=evalin('base',parameters{j});end
fid=fopen(fullfile(outputDir,'generation.json'),'w');
assert(fid>=0);fileCleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(info,PrettyPrint=true));
clear fileCleanup cleanup
assert(strcmp(get_param(model,'Dirty'),originalDirty));
assert(strcmp(get_param(model,'ProdHWDeviceType'),get_param(original,'ProdHWDeviceType')));
fprintf('CORTEX_R_CODEGEN_PASS; original config restored (%s).\n',originalName);

end

function restore(model,originalName,temporaryName,folders,originalDirty)
setActiveConfigSet(model,originalName);
detachConfigSet(model,temporaryName);
Simulink.fileGenControl('setConfig','config',folders);
set_param(model,'Dirty',originalDirty);
end
