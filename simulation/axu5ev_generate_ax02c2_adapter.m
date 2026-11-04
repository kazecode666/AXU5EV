function result=axu5ev_generate_ax02c2_adapter(sourcePrepared,outputRoot)
% Regenerate only the thin adapter after a target-type correction; reuse data.
assert(batchStartupOptionUsed,'Use dedicated batch MATLAB via MCP.');
assert(~isfolder(outputRoot),'Use a new output directory.');
root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'simulation'));
evalin('base','init_AXU5EV;');
work=fullfile(outputRoot,'adapter_01');mkdir(work);
copyfile(fullfile(sourcePrepared,'adapter_01','AX02C2_Adapter.slx'),work);
m='AX02C2_Adapter';load_system(fullfile(work,[m '.slx']));
oldgen=Simulink.fileGenControl('getConfig');cleanup=onCleanup(@()restore(m,oldgen)); %#ok<NASGU>
Simulink.fileGenControl('set','CacheFolder',fullfile(work,'cache'),'CodeGenFolder',fullfile(work,'codegen'),'createDir',true);
set_param(m,'ProdLongLongMode','on');save_system(m,fullfile(work,[m '.slx']));slbuild(m);
result=struct('status','ADAPTER_NATIVE64_GENERATE_PASS','source_model',fullfile(sourcePrepared,'adapter_01',[m '.slx']), ...
 'generated',fullfile(work,'codegen',[m '_ert_rtw']),'target','ARM Compatible->ARM Cortex-R', ...
 'ProdLongLongMode',get_param(m,'ProdLongLongMode'),'algorithm_changes','none; model-derived thin adapter only');
f=fopen(fullfile(outputRoot,'generation.json'),'w');c=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(result,PrettyPrint=true));
disp(result);
end
function restore(m,oldgen)
if bdIsLoaded(m),close_system(m,0);end
Simulink.fileGenControl('setConfig','config',oldgen);
end
