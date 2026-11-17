function result=axu5ev_experiment_generate_control(output_dir,generated_dir,options)
% Generate experiment ERT C and verify that exact C through a transport MEX.
% The production target is Cortex-R. The numerical check executes on the host.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
if nargin<2 || isempty(generated_dir)
    generated_dir=fullfile(root,'generated','experiment','r5');
end
if nargin<3
    options=struct;
end
irq_override=isfield(options,'irq_function') && ~isempty(options.irq_function);
service_override=isfield(options,'service_function') && ~isempty(options.service_function);
if ~irq_override,options.irq_function='PL_Frame_IRQ';end
if ~service_override,options.service_function='Service_Request';end
options.irq_function=char(options.irq_function);
options.service_function=char(options.service_function);
if ~isfield(options,'run_validation'),options.run_validation=true;end
assert(~isfolder(output_dir) && ~isfile(output_dir),'Choose a new verification directory.');
assert(~isfolder(generated_dir) && ~isfile(generated_dir),'Choose a new generated-source version.');
assert(isvarname(options.irq_function) && isvarname(options.service_function), ...
    'Exported function names must be C identifiers.');

experiment=fullfile(root,'simulation','experiment');
model='AXU5EV_Motor_Control_System';
model_file=fullfile(experiment,[model '.slx']);
oldpath=path;
folders=Simulink.fileGenControl('getConfig');
environment_cleanup=onCleanup(@()restore_environment(oldpath,folders)); %#ok<NASGU>
addpath(experiment,fullfile(experiment,'r5'),fullfile(experiment,'pl'), ...
    fullfile(experiment,'parameters'),fullfile(root,'simulation','tests','experiment'));
if ~bdIsLoaded(model)
    open_system(model_file);
end
assert(strcmpi(canonical(get_param(model,'FileName')),canonical(model_file)), ...
    'The open control model resolves outside simulation/experiment.');
assert(strcmp(get_param(model,'SimulationStatus'),'stopped'));
assert(strcmp(get_param(model,'Dirty'),'off'), ...
    'Save the reviewed experiment source before generation.');
library='AXU5EV_Experiment_R5_Algorithms';
if bdIsLoaded(library)
    assert(strcmp(get_param(library,'Dirty'),'off'), ...
        'Save the reviewed independent R5 library before generation.');
end

% Work on a temporary configuration. Never save the open model from here.
original=getActiveConfigSet(model);
original_name=original.Name;
original_dirty=get_param(model,'Dirty');
temporary=copy(original);
temporary.Name='AX04_Experiment_C_Generation';
set_param(temporary,'SystemTargetFile','ert.tlc','TargetLang','C', ...
    'ProdHWDeviceType','ARM Compatible->ARM Cortex-R','ProdEqTarget','on', ...
    'ProdEndianess','LittleEndian','ProdLongLongMode','on', ...
    'CodeInterfacePackaging','Nonreusable function','GenCodeOnly','on', ...
    'GenerateReport','off','GenerateSampleERTMain','off', ...
    'ZeroInternalMemoryAtStartup','on','ZeroExternalMemoryAtStartup','on');
assert(isempty(get_param(temporary,'PostCodeGenCommand')), ...
    'The experiment generation configuration contains a post-generation command.');
attachConfigSet(model,temporary);
configuration_cleanup=onCleanup(@()restore_model( ...
    model,original_name,temporary.Name,original_dirty)); %#ok<NASGU>
setActiveConfigSet(model,temporary.Name);
mkdir(output_dir);
mkdir(generated_dir);
code_folder=fullfile(output_dir,'code');
Simulink.fileGenControl('set','CacheFolder',fullfile(output_dir,'cache'), ...
    'CodeGenFolder',code_folder,'createDir',true);
slbuild(model);

target=fullfile(code_folder,[model '_ert_rtw']);
assert(isfile(fullfile(target,[model '.c'])),'Expected model-generated C was not produced.');
header=fileread(fullfile(target,[model '.h']));
prototypes=regexp(header,'(?:^|\s)(?:extern\s+)?void\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(\s*void\s*\)\s*;', ...
    'tokens');
exported_names=cellfun(@(token)token{1},prototypes,UniformOutput=false);
options.irq_function=resolve_entry(exported_names,options.irq_function, ...
    'PL_Frame_IRQ',irq_override);
options.service_function=resolve_entry(exported_names,options.service_function, ...
    'Service_Request',service_override);
build_info_file=fullfile(target,'buildInfo.mat');
assert(isfile(build_info_file),'Generated RTW build information is missing.');
loaded=load(build_info_file,'buildInfo');
build_info=loaded.buildInfo;
sources=cellstr(string(build_info.getSourceFiles(true,true)));
sources=sources(:)';
for index=1:numel(sources)
    sources{index}=resolve_file(sources{index},target);
end
[~,names,extensions]=cellfun(@fileparts,sources,UniformOutput=false);
is_main=ismember(strcat(names,extensions),{'ert_main.c','rt_main.c','rt_malloc_main.c'});
sources=sources(~is_main);
assert(~isempty(sources) && all(isfile(sources)),'BuildInfo contains missing source files.');
assert(all(endsWith(sources,'.c','IgnoreCase',true)), ...
    'The experiment C target unexpectedly requires a non-C source.');
sources=unique(sources,'stable');

includes=cellstr(string(build_info.getIncludePaths(true)));
includes=[{target,fullfile(matlabroot,'simulink','include'), ...
    fullfile(root,'verification','experiment')} includes(:)'];
includes=unique(includes,'stable');
include_flags=cellfun(@(folder)['-I' folder],includes,UniformOutput=false);
defines=cellstr(string(build_info.getDefines()));
defines=defines(:)';
% RTW.BuildInfo.getDefines returns compiler options with their -D prefix.
assert(all(startsWith(defines,'-D')),'BuildInfo returned an unexpected macro format.');
entry_flags={['-DAX04_IRQ_FUNCTION=' options.irq_function], ...
    ['-DAX04_SERVICE_FUNCTION=' options.service_function]};
clear ax04_control_mex;
mex('-R2018a',include_flags{:},defines{:},entry_flags{:}, ...
    fullfile(root,'verification','experiment','ax04_control_gateway.c'), ...
    fullfile(root,'verification','experiment','ax04_control_transport.c'), ...
    sources{:},'-outdir',output_dir,'-output','ax04_control_mex');
addpath(output_dir,'-begin');

% Export only files from this fresh generation tree. Runtime/toolchain headers
% supplied by MATLAB remain tool dependencies, recorded by include paths.
headers=dir(fullfile(code_folder,'**','*.h'));
header_paths=arrayfun(@(file)fullfile(file.folder,file.name),headers,UniformOutput=false);
generated_sources=sources(cellfun(@(file)is_within(file,code_folder),sources));
export_files=unique([generated_sources header_paths(:)'],'stable');
[~,export_names,export_extensions]=cellfun(@fileparts,export_files,UniformOutput=false);
export_names=strcat(export_names,export_extensions);
assert(numel(unique(lower(string(export_names))))==numel(export_names), ...
    'Generated filenames collide in the standalone export.');
for index=1:numel(export_files)
    copyfile(export_files{index},fullfile(generated_dir,export_names{index}));
end

validation=struct('status','NOT_RUN');
if options.run_validation
    validation=ax04_validate_generated_control(output_dir);
    assert(strcmp(validation.status,'PASS'));
end
result=struct('status','PASS','model',model,'source',model_file, ...
    'generated_target',target,'generated_directory',generated_dir, ...
    'exported_files',{export_names},'build_info',build_info_file, ...
    'compiled_sources',{sources},'include_paths',{includes}, ...
    'irq_function',options.irq_function,'service_function',options.service_function, ...
    'initialization_function',[model '_initialize'], ...
    'production',get_param(temporary,'ProdHWDeviceType'), ...
    'byte_order',get_param(temporary,'ProdEndianess'), ...
    'zero_internal_memory_at_initialize',get_param(temporary,'ZeroInternalMemoryAtStartup'), ...
    'zero_external_memory_at_initialize',get_param(temporary,'ZeroExternalMemoryAtStartup'), ...
    'host_mex','PASS','numeric_validation',validation, ...
    'hardware','HW_BINDING_PENDING','arm_execution','NOT_RUN','board','BOARD_NOT_RUN');
write_json(fullfile(output_dir,'control_generation.json'),result);
disp(result);
end

function file=resolve_file(file,target)
if isfile(file)
    file=canonical(file);
else
    candidate=fullfile(target,file);
    assert(isfile(candidate),'BuildInfo source is missing: %s',file);
    file=canonical(candidate);
end
end

function name=resolve_entry(names,requested,label,explicit_override)
if any(strcmp(names,requested))
    name=requested;
    return;
end
candidates=names(endsWith(names,label));
assert(~explicit_override && numel(candidates)==1, ...
    'Cannot select exported %s function. Requested %s. Header functions: %s', ...
    label,requested,strjoin(names,', '));
name=candidates{1};
end

function value=canonical(value)
value=char(System.IO.Path.GetFullPath(char(value)));
end

function value=is_within(file,folder)
file=canonical(file);
folder=[canonical(folder) filesep];
value=startsWith(file,folder,'IgnoreCase',ispc);
end

function restore_model(model,original_name,temporary_name,original_dirty)
setActiveConfigSet(model,original_name);
detachConfigSet(model,temporary_name);
set_param(model,'Dirty',original_dirty);
end

function restore_environment(oldpath,folders)
path(oldpath);
Simulink.fileGenControl('setConfig','config',folders);
end

function write_json(file,value)
stream=fopen(file,'w');
assert(stream>=0,'Cannot create control generation result.');
cleanup=onCleanup(@()fclose(stream)); %#ok<NASGU>
fprintf(stream,'%s\n',jsonencode(value,PrettyPrint=true));
end
