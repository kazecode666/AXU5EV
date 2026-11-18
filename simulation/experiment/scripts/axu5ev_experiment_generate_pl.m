function result=axu5ev_experiment_generate_pl(output_dir,generated_dir)
% Generate the independent experiment HDL boundaries from their saved models.
% Hardware binding, implementation and board execution belong to AX-04 B.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
pl=fullfile(root,'simulation','experiment','pl');
parameters=fullfile(root,'simulation','experiment','parameters');
assert(~isfolder(output_dir),'Choose a new generation directory.');
if nargin<2
    [~,name]=fileparts(output_dir);
    generated_dir=fullfile(root,'generated','experiment',name,'pl');
end
assert(~isfolder(generated_dir),'Choose a new generated-source version.');
mkdir(output_dir);mkdir(generated_dir);
oldpath=path;folders=Simulink.fileGenControl('getConfig');
cleanup=onCleanup(@()restore(oldpath,folders)); %#ok<NASGU>
addpath(pl,parameters);
Simulink.fileGenControl('set','CacheFolder',fullfile(output_dir,'cache'), ...
    'CodeGenFolder',fullfile(output_dir,'code'),'createDir',true);
p=axu5ev_experiment_parameters();
family=installed_5ev_family();
assert(p.Encoder_Counts_Per_Electrical_Period==30000 && ...
    p.Encoder_Nanometres_Per_Count==1000 && p.Ts_ACR==1e-4);
assert(abs(p.Kp_ACR-59)<1e-10 && abs(p.Ki_ACR-7250)<1e-8);

models={ ...
    'AXU5EV_Experiment_Current_HDL','Current_Preprocess','numeric','AX04_Current_'; ...
    'AXU5EV_Experiment_Angle_HDL','Encoder_Angle','numeric','AX04_Angle_'; ...
    'AXU5EV_Experiment_Duty_HDL','Duty_To_Compare','numeric','AX04_Duty_'; ...
    'AXU5EV_Experiment_FOC','FOC_DUT','foc','AX04_FOC_'};
records=cell(1,size(models,1));
all_modules={};all_packages={};
for index=1:size(models,1)
    model=models{index,1};
    file=fullfile(pl,[model '.slx']);
    if ~bdIsLoaded(model),load_system(file);end
    assert(strcmp(get_param(model,'FileName'),file) || ...
        strcmp(strrep(get_param(model,'FileName'),'\','/'),strrep(file,'\','/')), ...
        'Model resolves outside experiment/pl: %s',model);
    assert(strcmp(get_param(model,'SimulationStatus'),'stopped'));
    assert(strcmp(get_param(model,'Dirty'),'off'),'Save reviewed experiment source before generation.');
    blocks=find_system(model,'SearchDepth',1,'Name',models{index,2});
    assert(numel(blocks)==1,'Expected exactly one %s boundary.',models{index,2});
    dut=blocks{1};
    original=getActiveConfigSet(model);original_name=original.Name;
    temporary=copy(original);temporary.Name='AX04_PL_Generation';
    original_dirty=get_param(model,'Dirty');
    original_hdl=snapshot_hdl(model);
    attachConfigSet(model,temporary);
    config_cleanup=onCleanup(@()restore_model( ...
        model,original_name,temporary.Name,original_dirty,original_hdl)); %#ok<NASGU>
    setActiveConfigSet(model,temporary.Name);
    hdlset_param(model,'TargetLanguage','SystemVerilog','ResetType','sync', ...
        'ResetAssertedLevel','active-high','ClockInputPort','clk', ...
        'ClockEnableInputPort','clk_enable','ResetInputPort','reset', ...
        'ClockEnableOutputPort','ce_out','GenerateModel','off', ...
        'GenerateValidationModel','off','Traceability','off','ResourceReport','off', ...
        'OptimizationReport','off','EnableComments','on','DateComment','off', ...
        'ModulePrefix',models{index,4});
    assert(strcmp(hdlget_param(model,'ModulePrefix'),models{index,4}));
    hdlset_param(model,'SynthesisTool','Xilinx Vivado', ...
        'SynthesisToolChipFamily',family,'SynthesisToolDeviceName','xczu5ev', ...
        'SynthesisToolPackageName','sfvc784','SynthesisToolSpeedValue','-2', ...
        'TargetFrequency',50);
    if strcmp(models{index,3},'foc')
        workspace=get_param(model,'ModelWorkspace');
        assert(hasVariable(workspace,'FOC_Fixed_Config') && ...
            hasVariable(workspace,'FOC_Fixed_Parameters') && hasVariable(workspace,'Ts_ACR'), ...
            'Save the independent B2 parameter snapshot in the FOC model before generation.');
        assert(isequaln(getVariable(workspace,'FOC_Fixed_Config'),p.FOC_Fixed_Config) && ...
            isequaln(getVariable(workspace,'FOC_Fixed_Parameters'),p.FOC_Fixed_Parameters) && ...
            isequaln(getVariable(workspace,'Ts_ACR'),p.Ts_ACR), ...
            'FOC workspace differs from experiment parameters. Update and save its reviewed parameter snapshot.');
        settings=configure_foc(model,root);
        pipeline_cleanup=onCleanup(@()restore_pipeline(settings)); %#ok<NASGU>
        for setting_index=1:numel(settings)
            setting=settings(setting_index);
            hdlset_param(setting.path,setting.property,setting.requested);
            assert(strcmpi(string(hdlget_param(setting.path,setting.property)), ...
                string(setting.requested)));
        end
    else
        hdlset_param(model,'Oversampling',1,'ClockRatePipelining','off');
        assert(strcmp(hdlget_param(dut,'DistributedPipelining'),'off'), ...
            'Numeric single-clock boundary unexpectedly enables distributed pipelining.');
        settings=struct([]);
    end
    checks=checkhdl(dut);
    if ~isempty(checks)
        assert(~any(strcmpi({checks.level},'Error')),'HDL compatibility failed for %s.',model);
    end
    makehdl(dut,'TargetDirectory',generated_dir);
    sources=dir(fullfile(generated_dir,model,'*.sv'));
    assert(~isempty(sources),'No generated HDL for %s.',model);
    packages=endsWith({sources.name},'_pkg.sv') | endsWith({sources.name},'_package.sv');
    sources=[sources(packages);sources(~packages)];
    [module_names,package_names]=check_declarations(sources,models{index,4});
    assert(~any(ismember(module_names,all_modules)), ...
        'Generated module names overlap another experiment boundary.');
    assert(~any(ismember(package_names,all_packages)), ...
        'Generated package names overlap another experiment boundary.');
    all_modules=[all_modules module_names]; %#ok<AGROW>
    all_packages=[all_packages package_names]; %#ok<AGROW>
    record=struct('model',model,'source',file,'dut',dut, ...
        'generated_directory',fullfile(generated_dir,model), ...
        'files',{arrayfun(@(x)x.name,sources,UniformOutput=false)}, ...
        'module_prefix',models{index,4},'module_names',{module_names}, ...
        'package_names',{package_names}, ...
        'checkhdl',checks,'pipeline_settings',settings);
    records{index}=record;
    if exist('pipeline_cleanup','var'),clear pipeline_cleanup;end
    clear config_cleanup;
end
result=struct('status','PASS','models',{records},'generated_directory',generated_dir, ...
    'unique_module_count',numel(all_modules),'unique_package_count',numel(all_packages), ...
    'part_reference','xczu5ev-sfvc784-2-i', ...
    'parameter_version',p.Experiment_Parameter_Version,'current_pi',[p.Kp_ACR p.Ki_ACR], ...
    'phase_rl',[p.PMLSM_Rs_ohm p.PMLSM_Ld_H p.PMLSM_Lq_H], ...
    'flux_Wb',p.PMLSM_psi_f_Wb,'hardware','HW_BINDING_PENDING','board','BOARD_NOT_RUN', ...
    'synthesis','NOT_RUN','implementation','NOT_RUN','sta_cdc_sdf','NOT_RUN');
write_json(fullfile(output_dir,'pl_generation.json'),result);
write_source_list(fullfile(output_dir,'generated_sources.list'),records,root);
disp(result);
end

function [modules,packages]=check_declarations(sources,prefix)
modules={};packages={};
for index=1:numel(sources)
    code=fileread(fullfile(sources(index).folder,sources(index).name));
    declarations=regexp(code, ...
        '(?m)^\s*module\s+(?:automatic\s+)?([A-Za-z_][A-Za-z0-9_$]*)','tokens');
    modules=[modules cellfun(@(entry)entry{1},declarations,UniformOutput=false)]; %#ok<AGROW>
    declarations=regexp(code, ...
        '(?m)^\s*package\s+(?:automatic\s+)?([A-Za-z_][A-Za-z0-9_$]*)','tokens');
    packages=[packages cellfun(@(entry)entry{1},declarations,UniformOutput=false)]; %#ok<AGROW>
end
assert(~isempty(modules),'No module declarations found in generated SystemVerilog.');
assert(all(startsWith(modules,prefix)), ...
    'Generated module declaration lacks its independent experiment boundary prefix.');
assert(all(startsWith(packages,prefix)), ...
    'Generated package declaration lacks its independent experiment boundary prefix.');
assert(numel(unique(modules))==numel(modules),'Duplicate generated module declaration.');
assert(numel(unique(packages))==numel(packages),'Duplicate generated package declaration.');
end

function family=installed_5ev_family()
file=fullfile(matlabroot,'toolbox','hdlcoder','downstreamtools','vivado', ...
    '+downstreamtools','+XilinxVivado_2025_1','device_list.xml');
assert(isfile(file),'Installed Vivado HDL target list is absent.');
families=regexp(fileread(file), ...
    '(?s)<Family\s+[^>]*name="([^"]+)"[^>]*>(.*?)</Family>','tokens');
family='';
for index=1:numel(families)
    candidate=families{index};
    if contains(candidate{2},'<Device name="xczu5ev-sfvc784-2-i">')
        assert(isempty(family),'5EV target occurs in multiple installed families.');
        family=candidate{1};
    end
end
assert(~isempty(family),'5EV software target is absent from the installed supported list.');
end

function settings=configure_foc(model,root)
% The stored relative paths verify each actual copied block before applying p3.
readback=jsondecode(fileread(fullfile(root,'simulation','experiment','pl', ...
    'axu5ev_experiment_foc_pipeline.json')));
assert(readback.frame_cycles==5000 && readback.clock_hz==50000000);
settings=readback.settings;
hdlset_param(model,'Oversampling',5000,'ClockRatePipelining','on', ...
    'ClockRatePipelineOutputPorts','on','BalanceClockRateOutputPorts','on', ...
    'TimingControllerArch','resettable','MinimizeClockEnables','off', ...
    'MinimizeGlobalResets','off','ShareMultipliers','off','ShareMultiplyAdds','off', ...
    'ShareAtomicSubsystems','off','ShareMATLABBlocks','off','MulticyclePathConstraints','off');
copied_blocks=find_system(model,'LookUnderMasks','all','FollowLinks','on','Type','block');
for index=1:numel(settings)
    relative=char(settings(index).path);
    expected=[model '/' relative];
    matches=copied_blocks(strcmp(copied_blocks,expected));
    assert(numel(matches)==1,'Copied p3 pipeline block is absent: %s',relative);
    block=matches{1};
    settings(index).before=hdlget_param(block,settings(index).property);
    settings(index).path=block;
    settings(index).SID=str2double(get_param(block,'SID'));
end
end

function restore_pipeline(settings)
for index=1:numel(settings)
    hdlset_param(settings(index).path,settings(index).property,settings(index).before);
end
end

function write_source_list(file,records,root)
stream=fopen(file,'w');assert(stream>=0);
cleanup=onCleanup(@()fclose(stream)); %#ok<NASGU>
for index=1:numel(records)
    record=records{index};
    for source_index=1:numel(record.files)
        path=fullfile(record.generated_directory,record.files{source_index});
        normalized=strrep(path,'\','/');
        prefix=[strrep(root,'\','/') '/'];
        relative=normalized;
        if startsWith(normalized,prefix),relative=normalized(numel(prefix)+1:end);end
        fprintf(stream,'generated|%s\n',relative);
    end
end
end

function values=snapshot_hdl(model)
names={'TargetLanguage','ResetType','ResetAssertedLevel','ClockInputPort', ...
    'ClockEnableInputPort','ResetInputPort','ClockEnableOutputPort','GenerateModel', ...
    'GenerateValidationModel','Traceability','ResourceReport','OptimizationReport', ...
    'EnableComments','DateComment','ModulePrefix','HDLSubsystem','TargetDirectory', ...
    'SynthesisTool','SynthesisToolChipFamily', ...
    'SynthesisToolDeviceName','SynthesisToolPackageName','SynthesisToolSpeedValue', ...
    'TargetFrequency','Oversampling','ClockRatePipelining','ClockRatePipelineOutputPorts', ...
    'BalanceClockRateOutputPorts','TimingControllerArch','MinimizeClockEnables', ...
    'MinimizeGlobalResets','ShareMultipliers','ShareMultiplyAdds','ShareAtomicSubsystems', ...
    'ShareMATLABBlocks','MulticyclePathConstraints'};
values=cell(1,2*numel(names));
for index=1:numel(names)
    values{2*index-1}=names{index};
    values{2*index}=hdlget_param(model,names{index});
end
end

function restore_model(model,original_name,temporary_name,original_dirty,original_hdl)
setActiveConfigSet(model,original_name);
detachConfigSet(model,temporary_name);
hdlset_param(model,original_hdl{:});
set_param(model,'Dirty',original_dirty);
end

function restore(oldpath,folders)
path(oldpath);
Simulink.fileGenControl('setConfig','config',folders);
end

function write_json(file,value)
stream=fopen(file,'w');assert(stream>=0);
cleanup=onCleanup(@()fclose(stream)); %#ok<NASGU>
fprintf(stream,'%s\n',jsonencode(value,PrettyPrint=true));
end
