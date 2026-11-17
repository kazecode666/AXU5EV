function result=axu5ev_experiment(action,output_dir,generated_dir)
% Open, explicitly refresh, or generate the independent experiment source.
if nargin<1,action='open';end
action=validatestring(action,{'open','parameters','check','generate','generate_r5','generate_pl'});
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
assert(isfile(fullfile(root,'AGENTS.md')),'AX04:Root','Repository root was not resolved.');
experiment=fullfile(root,'simulation','experiment');
addpath(experiment,fullfile(experiment,'parameters'), ...
    fullfile(experiment,'r5'),fullfile(experiment,'pl'),fullfile(experiment,'scripts'));
[parameters,provenance]=axu5ev_experiment_parameters();
parameter_models={'AXU5EV_Motor_Control_System','AXU5EV_Experiment_FOC'};

switch action
    case 'open'
        sources=load_sources(experiment,'open');
        workspaces=initialize_missing(parameter_models,parameters);
        open_system('AXU5EV_Motor_Control_System');
        result=struct('status','OPEN','model','AXU5EV_Motor_Control_System', ...
            'source',fullfile(experiment,'AXU5EV_Motor_Control_System.slx'), ...
            'sources',{sources},'workspaces',{workspaces}, ...
            'parameter_source',which('axu5ev_experiment_parameters'), ...
            'hardware','HW_BINDING_PENDING','board','BOARD_NOT_RUN');
    case 'parameters'
        load_sources(experiment,'parameters');
        assert_stopped(parameter_models);
        assert_clean(parameter_models);
        for index=1:numel(parameter_models)
            axu5ev_experiment_initialize_model(parameter_models{index},parameters);
        end
        result=struct('status','PARAMETERS_APPLIED_IN_MEMORY', ...
            'models',{parameter_models},'parameters',parameters, ...
            'provenance',provenance,'saved',false);
    case 'check'
        sources=load_sources(experiment,'open');
        assert_stopped(parameter_models);
        assert_complete(parameter_models,parameters);
        main='AXU5EV_Motor_Control_System';
        set_param(main,'SimulationCommand','update');
        boundaries=check_boundaries(main);
        result=struct('status','CHECK_PASS','sources',{sources}, ...
            'boundaries',boundaries,'parameter_source',which('axu5ev_experiment_parameters'), ...
            'hardware','HW_BINDING_PENDING','board','BOARD_NOT_RUN');
    case {'generate','generate_r5','generate_pl'}
        if nargin<2 || isempty(output_dir)
            output_dir=fullfile(root,'.runtime','experiment', ...
                ['session_' char(datetime('now',Format='yyyyMMdd_HHmmss_SSS'))]);
        end
        if nargin<3 || isempty(generated_dir)
            [~,name]=fileparts(output_dir);
            generated_dir=fullfile(root,'generated','experiment',name);
            if strcmp(action,'generate_r5'),generated_dir=fullfile(generated_dir,'r5');end
            if strcmp(action,'generate_pl'),generated_dir=fullfile(generated_dir,'pl');end
        end
        assert(~isfolder(output_dir) && ~isfile(output_dir), ...
            'AX04:Output','Choose a new generation work directory.');
        assert(~isfolder(generated_dir) && ~isfile(generated_dir), ...
            'AX04:Generated','Choose a new generated-source version.');
        sources=load_sources(experiment,action);
        assert_stopped({sources.model});
        assert_clean({sources.model});
        if strcmp(action,'generate_r5')
            assert_complete(parameter_models(1),parameters);
            result=axu5ev_experiment_generate_control(output_dir,generated_dir);
        elseif strcmp(action,'generate_pl')
            assert_complete(parameter_models(2),parameters);
            result=axu5ev_experiment_generate_pl(output_dir,generated_dir);
        else
            assert_complete(parameter_models,parameters);
            mkdir(output_dir);
            mkdir(generated_dir);
            control=axu5ev_experiment_generate_control(fullfile(output_dir,'control'), ...
                fullfile(generated_dir,'r5'));
            pl=axu5ev_experiment_generate_pl(fullfile(output_dir,'pl'), ...
                fullfile(generated_dir,'pl'));
            result=struct('status','GENERATE_PASS','work_directory',output_dir, ...
                'generated_directory',generated_dir,'control',control,'pl',pl, ...
                'parameter_version',parameters.Experiment_Parameter_Version, ...
                'hardware','HW_BINDING_PENDING','board','BOARD_NOT_RUN');
            write_json(fullfile(output_dir,'generation.json'),result);
        end
end
if nargout==0,disp(result);end
end

function sources=load_sources(experiment,selection)
models={ ...
    'r5','AXU5EV_Experiment_R5_Algorithms'; ...
    'pl','AXU5EV_Experiment_PL_Algorithms'; ...
    'pl','AXU5EV_Experiment_Encoder_Components'; ...
    'pl','AXU5EV_Experiment_Current_HDL'; ...
    'pl','AXU5EV_Experiment_Angle_HDL'; ...
    'pl','AXU5EV_Experiment_Duty_HDL'; ...
    'pl','AXU5EV_Experiment_FOC'; ...
    '','AXU5EV_Motor_Control_System'};
if strcmp(selection,'open')
    models=models([1 2 3 7 8],:);
elseif strcmp(selection,'parameters')
    models=models([7 8],:);
elseif strcmp(selection,'generate_r5')
    models=models([1 8],:);
elseif strcmp(selection,'generate_pl')
    models=models(2:7,:);
end
sources=struct('model',{},'file',{},'loaded_before',{},'dirty',{});
for index=1:size(models,1)
    model=models{index,2};
    file=fullfile(experiment,models{index,1},[model '.slx']);
    assert(isfile(file),'AX04:Source','Experiment source is absent: %s',file);
    loaded=bdIsLoaded(model);
    if ~loaded,load_system(file);end
    actual=char(System.IO.Path.GetFullPath(get_param(model,'FileName')));
    expected=char(System.IO.Path.GetFullPath(file));
    assert(strcmpi(actual,expected),'AX04:ModelSource', ...
        'An existing model with this name comes from another source: %s',model);
    sources(index)=struct('model',model,'file',actual, ...
        'loaded_before',loaded,'dirty',get_param(model,'Dirty')); %#ok<AGROW>
end
end

function records=initialize_missing(models,parameters)
names=fieldnames(parameters);
records=struct('model',{},'added_fields',{},'complete',{},'dirty',{});
for index=1:numel(models)
    model=models{index};
    workspace=get_param(model,'ModelWorkspace');
    present=cellfun(@(name)workspace.hasVariable(name),names);
    missing=names(~present);
    added={};
    if ~isempty(missing) && strcmp(get_param(model,'Dirty'),'off') && ...
            strcmp(get_param(model,'SimulationStatus'),'stopped')
        workspace.DataSource='Model File';
        for parameter_index=1:numel(missing)
            name=missing{parameter_index};
            assignin(workspace,name,parameters.(name));
        end
        added=missing;
    end
    complete=all(cellfun(@(name)workspace.hasVariable(name),names));
    records(index)=struct('model',model,'added_fields',{added}, ...
        'complete',complete,'dirty',get_param(model,'Dirty')); %#ok<AGROW>
end
end

function assert_stopped(models)
for index=1:numel(models)
    assert(strcmp(get_param(models{index},'SimulationStatus'),'stopped'), ...
        'AX04:StopFirst','Stop the related experiment model before this action: %s',models{index});
end
end

function result=check_boundaries(model)
blocks=find_system(model,'LookUnderMasks','all','FollowLinks','off','Type','block');
excluded={'SIM_ONLY','PMLSM_Plant','Inverter_DeadTime', ...
    'Generated_Runtime_Step','Actual_P3_XSI'};
for index=1:numel(excluded)
    assert(~any(contains(blocks,excluded{index})),'AX04:ExperimentBoundary', ...
        'The experiment model contains a simulation execution block: %s',excluded{index});
end
for index=1:numel(blocks)
    reference=get_param(blocks{index},'ReferenceBlock');
    if any(startsWith(reference,{'AXU5EV_','PMLSM_'}))
        assert(startsWith(reference,'AXU5EV_Experiment_'),'AX04:LibraryBoundary', ...
            'A library link resolves outside the independent experiment components: %s',reference);
    end
end
references=find_system(model,'LookUnderMasks','all','FollowLinks','off','BlockType','ModelReference');
for index=1:numel(references)
    reference=get_param(references{index},'ModelName');
    assert(startsWith(reference,'AXU5EV_Experiment_'),'AX04:ModelBoundary', ...
        'A model reference resolves outside the experiment components: %s',reference);
end
result=struct('checked_blocks',numel(blocks),'model_references',numel(references));
end

function assert_clean(models)
for index=1:numel(models)
    assert(strcmp(get_param(models{index},'Dirty'),'off'),'AX04:Unsaved', ...
        'Review and save the experiment source before this action: %s',models{index});
end
end

function assert_complete(models,parameters)
names=fieldnames(parameters);
for index=1:numel(models)
    workspace=get_param(models{index},'ModelWorkspace');
    assert(all(cellfun(@(name)workspace.hasVariable(name),names)), ...
        'AX04:Parameters','The saved experiment parameter snapshot is incomplete: %s',models{index});
    for parameter_index=1:numel(names)
        name=names{parameter_index};
        assert(isequaln(workspace.getVariable(name),parameters.(name)), ...
            'AX04:Parameters','Review and save the current experiment parameter source: %s/%s', ...
            models{index},name);
    end
end
end

function write_json(file,value)
stream=fopen(file,'w');
assert(stream>=0,'AX04:Output','Could not create generation JSON.');
cleanup=onCleanup(@()fclose(stream)); %#ok<NASGU>
fprintf(stream,'%s\n',jsonencode(value,PrettyPrint=true));
end
