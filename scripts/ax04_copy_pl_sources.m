function plan=ax04_copy_pl_sources(configure_parameters)
% One-time source copy for AX-04. Model edits are returned for model_edit.
% The resulting experiment sources have their own names and workspaces.
root=fileparts(fileparts(mfilename('fullpath')));
if nargin<1,configure_parameters=false;end
pl=fullfile(root,'simulation','experiment','pl');
parameters=fullfile(root,'simulation','experiment','parameters');
if ~isfolder(pl),mkdir(pl);end
oldpath=path;
cleanup=onCleanup(@()path(oldpath)); %#ok<NASGU>
addpath(pl,parameters,fullfile(root,'simulation','experiment','scripts'));

copies={ ...
    'simulation/closed_loop/components/AXU5EV_PL_Algorithm_Library.slx', 'AXU5EV_Experiment_PL_Algorithms'; ...
    'simulation/tests/encoder/AXU5EV_Encoder_Components.slx', 'AXU5EV_Experiment_Encoder_Components'; ...
    'simulation/tests/adc/AXU5EV_ADC_HDL.slx', 'AXU5EV_Experiment_Current_HDL'; ...
    'simulation/tests/encoder/AXU5EV_Encoder_Angle_HDL.slx', 'AXU5EV_Experiment_Angle_HDL'; ...
    'simulation/tests/digital_chain/AXU5EV_Duty_Adapter_HDL.slx', 'AXU5EV_Experiment_Duty_HDL'; ...
    'simulation/closed_loop/components/PMLSM_FOC_FixedPoint.slx', 'AXU5EV_Experiment_FOC'};
functions={ ...
    'simulation/tests/encoder/task1_encoder_phase_serial.m', 'task1_encoder_phase_serial', 'axu5ev_experiment_encoder_phase_serial', pl; ...
    'simulation/tests/encoder/task1_encoder_guard.m', 'task1_encoder_guard', 'axu5ev_experiment_encoder_guard', fullfile(root,'simulation','experiment','r5'); ...
    'simulation/tests/digital_chain/duty_to_compare.m', 'duty_to_compare', 'axu5ev_experiment_duty_to_compare', pl};
for index=1:size(functions,1)
    if ~isfolder(functions{index,4}),mkdir(functions{index,4});end
    target=fullfile(functions{index,4},[functions{index,3} '.m']);
    assert(~isfile(target),'Experiment function already exists: %s',target);
    text=fileread(fullfile(root,functions{index,1}));
    text=strrep(text,functions{index,2},functions{index,3});
    file=fopen(target,'w');assert(file>=0);
    closer=onCleanup(@()fclose(file));fprintf(file,'%s',text);clear closer;
end

plan=struct('copies',{copies},'scoped_edits',{{}},'script_edits',{{}}, ...
    'parameters','axu5ev_experiment_parameters', ...
    'hardware','HW_BINDING_PENDING','board','BOARD_NOT_RUN');
prefixes={ ...
    'AXU5EV_PL_Algorithm_Library/', 'AXU5EV_Experiment_PL_Algorithms/'; ...
    'AXU5EV_Encoder_Components/', 'AXU5EV_Experiment_Encoder_Components/'};
for index=1:size(copies,1)
    model=copies{index,2};
    target=fullfile(pl,[model '.slx']);
    assert(~isfile(target),'Experiment model already exists: %s',target);
    copyfile(fullfile(root,copies{index,1}),target);
    open_system(target);
    if configure_parameters && strcmp(model,'AXU5EV_Experiment_FOC')
        p=axu5ev_experiment_parameters();
        axu5ev_experiment_initialize_model(model,p);
    end
    save_system(model);

    if strcmp(model,'AXU5EV_Experiment_Encoder_Components')
        % The R5 library owns the one active measurement component.
        measurement=find_system(model,'SearchDepth',1,'Name','Caculate_measurement');
        assert(numel(measurement)==1);
        operation=struct('op','delete','target',['blk_' get_param(measurement{1},'SID')]);
        plan.scoped_edits{end+1}=scoped_edit(model,model,operation);
    end
    operation=struct('op','configure','target',['config:' model], ...
        'params',struct('PreLoadFcn','','PostLoadFcn','','InitFcn','','StartFcn','','StopFcn',''));
    plan.scoped_edits{end+1}=scoped_edit(model,model,operation);

    blocks=find_system(model,'LookUnderMasks','all','FollowLinks','off','Type','block');
    for block_index=1:numel(blocks)
        block=blocks{block_index};
        if strcmp(block,model),continue;end
        reference=get_param(block,'ReferenceBlock');
        for prefix_index=1:size(prefixes,1)
            if startsWith(reference,prefixes{prefix_index,1})
                replacement=strrep(reference,prefixes{prefix_index,1},prefixes{prefix_index,2});
                operation=struct('op','replace_block','target',['blk_' get_param(block,'SID')], ...
                    'type',replacement);
                plan.scoped_edits{end+1}=scoped_edit(model,get_param(block,'Parent'),operation); %#ok<AGROW>
            end
        end
    end
    charts=find(sfroot,'-isa','Stateflow.EMChart');
    for chart_index=1:numel(charts)
        chart=charts(chart_index);
        if ~startsWith(chart.Path,[model '/']),continue;end
        if startsWith(chart.Path,[model '/Caculate_measurement/']),continue;end
        script=chart.Script;
        for function_index=1:size(functions,1)
            script=strrep(script,functions{function_index,2},functions{function_index,3});
        end
        if ~strcmp(script,chart.Script)
            plan.script_edits{end+1}=struct('model',model, ...
                'sid',get_param(chart.Path,'SID'),'script',script); %#ok<AGROW>
        end
    end
    if strcmp(model,'AXU5EV_Experiment_FOC')
        ports=find_system(model,'SearchDepth',1,'BlockType','Inport');
        for port_index=1:numel(ports)
            operation=struct('op','configure','target',['blk_' get_param(ports{port_index},'SID')], ...
                'params',struct('SampleTime','Ts_ACR','Interpolate','off'));
            plan.scoped_edits{end+1}=scoped_edit(model,model,operation); %#ok<AGROW>
        end
        operation=struct('op','configure','target',['config:' model], ...
            'params',struct('FixedStep','Ts_ACR','SampleTimeConstraint','Unconstrained', ...
            'DataTypeOverride','Off','SimulationMode','normal'));
        plan.scoped_edits{end+1}=scoped_edit(model,model,operation);
    end
end
end

function edit=scoped_edit(model,parent,operation)
scope='root';
if ~strcmp(model,parent),scope=['blk_' get_param(parent,'SID')];end
edit=struct('model',model,'scope',scope,'operation',operation);
end
