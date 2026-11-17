function result=ax04_validate_entries(mode,output_dir)
% Focused AX-04 entry checks. Run in a fresh MATLAB -batch process.
arguments
    mode (1,:) char {mustBeMember(mode,{'pure','isolation'})}
    output_dir (1,:) char
end
assert(batchStartupOptionUsed,'AX04:Batch', ...
    'Run this check in a separate MATLAB -batch process.');
root=axu5ev_project_root(mfilename('fullpath'));
assert(isfile(fullfile(root,'AGENTS.md')),'AX04:Root','Repository root was not resolved.');
output_dir=char(System.IO.Path.GetFullPath(output_dir));
assert(~isfolder(output_dir),'AX04:Output','Choose a new evidence directory.');
mkdir(output_dir);
result=struct('mode',mode,'status','RUNNING','matlab',version, ...
    'process',matlabProcessID,'output_dir',output_dir);
try
    addpath(fullfile(root,'simulation'));
    axu5ev_simulation_paths(root);
    if strcmp(mode,'pure')
        result.pure=validate_pure(root);
    else
        result.isolation=validate_isolation(root,output_dir);
    end
    result.status='PASS';
    write_json(fullfile(output_dir,'entries.json'),result);
    fprintf('AX04_%s_ENTRY_PASS\n',upper(mode));
catch err
    result.status='FAIL';
    result.error_id=err.identifier;
    result.error=err.message;
    result.error_report=getReport(err,'extended','hyperlinks','off');
    write_json(fullfile(output_dir,'entries.json'),result);
    rethrow(err);
end
end

function result=validate_isolation(root,output_dir)
pure='AXU5EV_Hybrid_ClosedLoop';
experiment='AXU5EV_Motor_Control_System';
assert(~bdIsLoaded(pure) && ~bdIsLoaded(experiment), ...
    'AX04:FreshModel','Use a fresh batch process.');
entry_pure=fullfile(root,'simulation','START_SIMULATION.m');
entry_experiment=fullfile(root,'simulation','START_EXPERIMENT.m');
orders={{entry_pure,entry_experiment},{entry_experiment,entry_pure}};
cases=cell(1,2);
original_folder=pwd;
folder_cleanup=onCleanup(@()cd(original_folder)); %#ok<NASGU>
execution_folder=fullfile(output_dir,'working_folder');
mkdir(execution_folder);
cd(execution_folder);
for k=1:numel(orders)
    evalin('base','init_AXU5EV;AXU5EV_Backend=''model_fixed'';');
    % Deliberate collisions are confined to this disposable batch workspace.
    evalin('base','Tau_e_mm=61.25;Kp_ACR=999;Udc=17;Host_Target_mm=1.234;');
    signal_names=alignment_signal_names();
    for signal_index=1:numel(signal_names)
        signal=evalin('base',signal_names{signal_index});
        signal.InitialValue='17';
        assignin('base',signal_names{signal_index},signal);
    end
    before=parameter_snapshot;
    base_signals_before=alignment_signal_snapshot('base');
    for j=1:2
        evalin('base',sprintf('run(''%s'');',strrep(orders{k}{j},'''','''''')));
    end
    after=parameter_snapshot;
    assert(isequaln(before,after),'AX04:BaseIsolation', ...
        'Opening the entries changed existing base parameters.');
    assert(isequaln(base_signals_before,alignment_signal_snapshot('base')), ...
        'AX04:BaseSignals','Opening the entries changed existing base signal objects.');
    resolved_sources=source_resolution(root);
    expected_file=fullfile(root,'simulation','experiment',[experiment '.slx']);
    assert(strcmpi(get_param(experiment,'FileName'),expected_file), ...
        'AX04:ExperimentSource','Unexpected experiment model source.');
    p=axu5ev_experiment_parameters;
    mw=get_param(experiment,'ModelWorkspace');
    names=fieldnames(p);
    for j=1:numel(names)
        assert(mw.hasVariable(names{j}) && ...
            isequaln(mw.getVariable(names{j}),p.(names{j})), ...
            'AX04:ExperimentIsolation','Experiment workspace parameter differs from its source.');
    end
    assert(mw.getVariable('Tau_e_mm')==30 && mw.getVariable('Udc')==48);
    assert(mw.getVariable('Kp_ACR')~=evalin('base','Kp_ACR'));
    assert(strcmp(mw.DataSource,'Model File'),'AX04:WorkspaceSource', ...
        'Experiment parameters must persist in the model file.');
    alignment_before_close=alignment_signal_snapshot(mw);
    assert_alignment_definitions(alignment_before_close);
    assert(strcmp(get_param(experiment,'Dirty'),'off'),'AX04:SavedSnapshot', ...
        'The saved experiment snapshot required edits while opening.');
    close_system(experiment,0);
    load_system(expected_file);
    mw=get_param(experiment,'ModelWorkspace');
    alignment_after_reload=alignment_signal_snapshot(mw);
    assert(isequaln(alignment_before_close,alignment_after_reload), ...
        'AX04:SignalPersistence','Alignment signal objects differ after reloading the saved model.');
    assert(strcmp(mw.DataSource,'Model File'));
    for j=1:numel(names)
        assert(mw.hasVariable(names{j}) && isequaln(mw.getVariable(names{j}),p.(names{j})), ...
            'AX04:ParameterPersistence','Experiment parameters differ after reloading the saved model.');
    end
    assert(isequaln(before,parameter_snapshot) && ...
        isequaln(base_signals_before,alignment_signal_snapshot('base')), ...
        'AX04:ReloadIsolation','Reloading the saved experiment model changed base parameters or signals.');
    foc='AXU5EV_Experiment_FOC';
    assert(strcmpi(get_param(foc,'FileName'), ...
        fullfile(root,'simulation','experiment','pl',[foc '.slx'])));
    foc_workspace=get_param(foc,'ModelWorkspace');
    for j=1:numel(names)
        assert(foc_workspace.hasVariable(names{j}) && ...
            isequaln(foc_workspace.getVariable(names{j}),p.(names{j})), ...
            'AX04:FOCIsolation','FOC workspace parameter differs from its source.');
    end
    cases{k}=struct('status','PASS','open_order',{orders{k}}, ...
        'base_before_open',before,'base_after_open',after, ...
        'base_preserved',true,'experiment_model_file',get_param(experiment,'FileName'), ...
        'experiment_parameter_source',which('axu5ev_experiment_parameters'), ...
        'resolved_sources',{resolved_sources},'execution_folder',execution_folder, ...
        'workspace_fields_checked',numel(names), ...
        'model_workspace_source',mw.DataSource, ...
        'base_alignment_signals',base_signals_before, ...
        'alignment_signals_before_close',alignment_before_close, ...
        'alignment_signals_after_reload',alignment_after_reload, ...
        'experiment_values',struct('Tau_e_mm',mw.getVariable('Tau_e_mm'), ...
            'Kp_ACR',mw.getVariable('Kp_ACR'),'Udc',mw.getVariable('Udc')), ...
        'foc_values',struct('Tau_e_mm',foc_workspace.getVariable('Tau_e_mm'), ...
            'Kp_ACR',foc_workspace.getVariable('Kp_ACR'),'Udc',foc_workspace.getVariable('Udc')));
    close_system(experiment,0);
    close_system(foc,0);
    close_system(pure,0);
end
result=struct('status','PASS','execution_folder',execution_folder,'orders',{cases});
end

function records=source_resolution(root)
sources={ ...
    'init_AXU5EV','closed_loop/parameters/init_AXU5EV.m'; ...
    'axu5ev_prepare','closed_loop/scripts/axu5ev_prepare.m'; ...
    'AXU5EV_Hybrid_ClosedLoop.slx','closed_loop/AXU5EV_Hybrid_ClosedLoop.slx'; ...
    'AXU5EV_R5_Runtime.slx','closed_loop/components/AXU5EV_R5_Runtime.slx'; ...
    'axu5ev_experiment','experiment/scripts/axu5ev_experiment.m'; ...
    'axu5ev_experiment_parameters','experiment/parameters/axu5ev_experiment_parameters.m'; ...
    'axu5ev_experiment_point_move_step','experiment/r5/axu5ev_experiment_point_move_step.m'; ...
    'axu5ev_experiment_scurve_profile','experiment/r5/axu5ev_experiment_scurve_profile.m'; ...
    'axu5ev_experiment_encoder_guard','experiment/r5/axu5ev_experiment_encoder_guard.m'; ...
    'axu5ev_experiment_bind_runtime_input','experiment/r5/axu5ev_experiment_bind_runtime_input.m'; ...
    'axu5ev_experiment_frame_guard','experiment/r5/axu5ev_experiment_frame_guard.m'; ...
    'axu5ev_experiment_reference_commit','experiment/r5/axu5ev_experiment_reference_commit.m'; ...
    'axu5ev_experiment_telemetry','experiment/r5/axu5ev_experiment_telemetry.m'; ...
    'axu5ev_experiment_encoder_phase_serial','experiment/pl/axu5ev_experiment_encoder_phase_serial.m'; ...
    'axu5ev_experiment_duty_to_compare','experiment/pl/axu5ev_experiment_duty_to_compare.m'; ...
    'axu5ev_experiment_foc_fixed_config','experiment/pl/axu5ev_experiment_foc_fixed_config.m'; ...
    'AXU5EV_Motor_Control_System.slx','experiment/AXU5EV_Motor_Control_System.slx'; ...
    'AXU5EV_Experiment_R5_Algorithms.slx','experiment/r5/AXU5EV_Experiment_R5_Algorithms.slx'; ...
    'AXU5EV_Experiment_PL_Algorithms.slx','experiment/pl/AXU5EV_Experiment_PL_Algorithms.slx'; ...
    'AXU5EV_Experiment_Encoder_Components.slx','experiment/pl/AXU5EV_Experiment_Encoder_Components.slx'; ...
    'AXU5EV_Experiment_Current_HDL.slx','experiment/pl/AXU5EV_Experiment_Current_HDL.slx'; ...
    'AXU5EV_Experiment_Angle_HDL.slx','experiment/pl/AXU5EV_Experiment_Angle_HDL.slx'; ...
    'AXU5EV_Experiment_Duty_HDL.slx','experiment/pl/AXU5EV_Experiment_Duty_HDL.slx'; ...
    'AXU5EV_Experiment_FOC.slx','experiment/pl/AXU5EV_Experiment_FOC.slx'};
records=cell(size(sources,1),1);
for index=1:size(sources,1)
    name=sources{index,1};
    expected=char(System.IO.Path.GetFullPath(fullfile(root,'simulation',sources{index,2})));
    resolved=which(name,'-all');
    assert(~isempty(resolved),'AX04:Resolution','Expected source was not found: %s',name);
    if ischar(resolved) || isstring(resolved),resolved=cellstr(resolved);end
    for match_index=1:numel(resolved)
        resolved{match_index}=char(System.IO.Path.GetFullPath(resolved{match_index}));
        assert(strcmpi(resolved{match_index},expected),'AX04:Resolution', ...
            'Source resolves outside its expected independent directory: %s',name);
    end
    records{index}=struct('name',name,'expected',expected,'which_all',{resolved});
end
end

function names=alignment_signal_names()
names={'Init_Done';'Init_State_Num';'id_init_ref';'Angle_Init_EN'; ...
    'Theta_Offset_auto';'x_align_mm_latch'};
end

function records=alignment_signal_snapshot(workspace)
names=alignment_signal_names();
records=struct;
for index=1:numel(names)
    name=names{index};
    if ischar(workspace)
        signal=evalin('base',name);
    else
        assert(workspace.hasVariable(name),'AX04:AlignmentSignal', ...
            'Alignment signal is absent from the saved ModelWorkspace: %s',name);
        signal=workspace.getVariable(name);
    end
    assert(isa(signal,'Simulink.Signal'),'AX04:AlignmentSignal', ...
        'Alignment workspace variable is not a Simulink.Signal: %s',name);
    records.(name)=struct('class',class(signal),'data_type',signal.DataType, ...
        'initial_value',signal.InitialValue);
end
end

function assert_alignment_definitions(records)
names=alignment_signal_names();
for index=1:numel(names)
    signal=records.(names{index});
    assert(strcmp(signal.class,'Simulink.Signal') && ...
        strcmp(signal.data_type,'double') && strcmp(signal.initial_value,'0'), ...
        'AX04:AlignmentSignal','Experiment alignment signal definition differs from its source.');
end
end

function result=validate_pure(root)
model='AXU5EV_Hybrid_ClosedLoop';
assert(~bdIsLoaded(model),'AX04:FreshModel','Use a fresh batch process.');
evalin('base','init_AXU5EV;');
initialized=parameter_snapshot;
evalin('base','AXU5EV_Backend=''model_fixed'';Host_Target_mm=1.234;');
before_open=parameter_snapshot;
entry=fullfile(root,'simulation','START_SIMULATION.m');
evalin('base',sprintf('run(''%s'');',strrep(entry,'''','''''')));
after_open=parameter_snapshot;
assert(isequaln(before_open,after_open),'AX04:Reinit', ...
    'Opening the pure entry replaced existing base parameters.');
assert(strcmp(evalin('base','AXU5EV_Backend'),'model_fixed'));
assert(evalin('base','AX01B_Use_C==0 && AX01B_Use_RTL==0'));
expected=fullfile(root,'simulation','closed_loop',[model '.slx']);
actual=get_param(model,'FileName');
assert(strcmpi(actual,expected),'AX04:ModelSource','Unexpected pure model source.');
cache=Simulink.fileGenControl('getConfig');
work=evalin('base','AXU5EV_ClosedLoop_Work');
assert(startsWith(cache.CacheFolder,work,'IgnoreCase',true));
assert(startsWith(cache.CodeGenFolder,work,'IgnoreCase',true));
in=Simulink.SimulationInput(model);
in=in.setModelParameter('StopTime','0.02','SimulationMode','normal', ...
    'EnablePacing','off','ReturnWorkspaceOutputs','on');
started=tic;
out=sim(in);
elapsed=toc(started);
summary=axu5ev_run_summary(out);
checks=axu5ev_verify_run(out,false);
commit=axu5ev_matrix(out.r5_commit);
duty=axu5ev_matrix(out.duty_result);
assert(size(commit,1)>1 && size(duty,1)>1,'AX04:Samples', ...
    'The short pure simulation did not produce control samples.');
assert(all(isfinite(duty),'all'),'AX04:FiniteDuty','Nonfinite duty values.');
assert(abs(out.r5_commit.Time(end)-0.02)<=1e-4+1e-12, ...
    'AX04:StopTime','The simulation did not reach the requested short stop time.');
result=struct('status','PASS','entry',entry,'root_model_file',actual, ...
    'model_dirty_after_simulation',get_param(model,'Dirty'), ...
    'backend','model_fixed','backend_use_c',0,'backend_use_rtl',0, ...
    'explicit_build_requested',false,'work_dir',work, ...
    'cache_dir',cache.CacheFolder,'codegen_dir',cache.CodeGenFolder, ...
    'resolved_init',which('init_AXU5EV'), ...
    'resolved_prepare',which('axu5ev_prepare'), ...
    'initialized_parameters',initialized,'parameters_before_open',before_open, ...
    'parameters_after_open',after_open,'existing_base_parameters_preserved',true, ...
    'stop_time_s',0.02,'wall_time_s',elapsed, ...
    'commit_samples',size(commit,1),'duty_samples',size(duty,1), ...
    'duty_min',min(duty,[],'all'),'duty_max',max(duty,[],'all'), ...
    'run_summary',summary,'targeted_checks',checks);
close_system(model,0);
end

function value=parameter_snapshot
names={'PMLSM_M1A_InitVersion','Host_Target_mm','Host_AutoStart_EN', ...
    'Host_Start_s','T_pwm','Ts_ACR','Ts_ASR','Ts_POS','Ts_Plant', ...
    'Udc','Tau_e_mm','Kp_ACR','Ki_ACR','Kp_ASR','Ki_ASR','Kp_pos', ...
    'PMLSM_deadtime_s','PMLSM_Rs_ohm','PMLSM_Ld_H'};
value=struct;
for k=1:numel(names)
    value.(names{k})=evalin('base',names{k});
end
end

function write_json(file,value)
f=fopen(file,'w');
assert(f~=-1,'AX04:Output','Could not create evidence JSON.');
cleanup=onCleanup(@()fclose(f)); %#ok<NASGU>
fprintf(f,'%s\n',jsonencode(value,PrettyPrint=true));
end
