function result=encoder_generate_c(output_dir)
% Generate the shared visible DSP measurement graph for ARM Cortex-R.
% The temporary target configuration and file-generation folders are restored.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin<1,output_dir=fullfile(root,'.runtime','dsp_reuse','feedback_c_01');end
assert(~isfolder(output_dir),'Choose a new output directory.');
oldpath=path;folders=Simulink.fileGenControl('getConfig');
path_cleanup=onCleanup(@()path(oldpath)); %#ok<NASGU>
addpath(fullfile(root,'simulation','encoder'));
model='AXU5EV_Encoder_Feedback';
if ~bdIsLoaded(model)
    open_system(fullfile(root,'simulation','encoder',[model '.slx']));
end
assert(strcmp(get_param(model,'Dirty'),'off'),'Review unsaved feedback model edits before generation.');
assert(strcmp(get_param(model,'SimulationStatus'),'stopped'));
component=[model '/Caculate_measurement'];
assert(strcmp(get_param(component,'LinkStatus'),'resolved'));
assert(strcmp(get_param(component,'ReferenceBlock'), ...
    'AXU5EV_Encoder_Components/Caculate_measurement'));
scale=jsondecode(fileread(fullfile(root,'simulation','encoder','encoder_test_scale.json')));
assert(scale.tick_hz==50000000 && scale.sample_tick_step==5000 && ...
    scale.sample_id_step==500 && scale.speed_intervals==50 && scale.history_entries==51, ...
    'Qualified-frame contract differs from the visible 50-interval graph.');

original=getActiveConfigSet(model);original_name=original.Name;
original_dirty=get_param(model,'Dirty');
temporary=copy(original);temporary.Name='Task1_Cortex_R_temporary';
set_param(temporary,'SystemTargetFile','ert.tlc','TargetLang','C', ...
    'ProdHWDeviceType','ARM Compatible->ARM Cortex-R','ProdEqTarget','on', ...
    'ProdEndianess','LittleEndian','ProdLongLongMode','on', ...
    'CodeInterfacePackaging','Nonreusable function', ...
    'GenCodeOnly','on','GenerateReport','off');
assert(isempty(get_param(temporary,'PostCodeGenCommand')));
mkdir(output_dir);
attachConfigSet(model,temporary);
configuration_cleanup=onCleanup(@()restore_configuration( ...
    model,original_name,temporary.Name,folders,original_dirty)); %#ok<NASGU>
setActiveConfigSet(model,temporary.Name);
code_folder=fullfile(output_dir,'codegen');
Simulink.fileGenControl('set','CacheFolder',fullfile(output_dir,'cache'), ...
    'CodeGenFolder',code_folder,'createDir',true);
slbuild(model);
target=fullfile(code_folder,[model '_ert_rtw']);
assert(isfile(fullfile(target,[model '.c'])),'Expected model-generated C was not produced.');

% Include only this new target and its generated shared utilities.
files=[dir(fullfile(target,'*.c'));dir(fullfile(target,'*.h'))];
shared=fullfile(code_folder,'slprj','ert','_sharedutils');
if isfolder(shared)
    files=[files;dir(fullfile(shared,'*.c'));dir(fullfile(shared,'*.h'))];
end
files=files(~strcmp({files.name},'ert_main.c'));
names=string({files.name});
assert(numel(unique(lower(names)))==numel(names),'Generated source filenames collide.');
sources=files(endsWith(names,'.c'));
source_paths=arrayfun(@(file)fullfile(file.folder,file.name),sources,UniformOutput=false);
include_paths={['-I' target]};
if isfolder(shared),include_paths{end+1}=['-I' shared];end
clear task1_encoder_model_mex;
mex('-R2018a',include_paths{:},'-outdir',output_dir,'-output','task1_encoder_model_mex', ...
    fullfile(root,'verification','dsp_reuse','task1_encoder_gateway.c'), ...
    fullfile(root,'verification','dsp_reuse','task1_encoder_transport.c'),source_paths{:});
addpath(output_dir);
result=task1_validate_encoder_c(output_dir);
assert(strcmp(result.status,'PASS'));

active=fullfile(root,'generated','dsp_reuse','feedback_c');
if ~isfolder(active),mkdir(active);end
for file_index=1:numel(files)
    copyfile(fullfile(files(file_index).folder,files(file_index).name), ...
        fullfile(active,files(file_index).name));
end
result.model=model;result.component=get_param(component,'ReferenceBlock');
result.active_c=active;result.generated_target=target;
result.production=get_param(temporary,'ProdHWDeviceType');
result.byte_order=get_param(temporary,'ProdEndianess');
result.board='NOT_RUN';
file=fopen(fullfile(output_dir,'software_result.json'),'w');
assert(file>=0,'Cannot create software generation report.');
file_cleanup=onCleanup(@()fclose(file)); %#ok<NASGU>
fprintf(file,'%s\n',jsonencode(result,PrettyPrint=true));
disp(result);
end

function restore_configuration(model,original_name,temporary_name,folders,original_dirty)
setActiveConfigSet(model,original_name);
detachConfigSet(model,temporary_name);
Simulink.fileGenControl('setConfig','config',folders);
set_param(model,'Dirty',original_dirty);
end
