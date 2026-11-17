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
        result.isolation=validate_isolation(root);
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

function result=validate_isolation(root)
pure='AXU5EV_Hybrid_ClosedLoop';
experiment='AXU5EV_Motor_Control_System';
assert(~bdIsLoaded(pure) && ~bdIsLoaded(experiment), ...
    'AX04:FreshModel','Use a fresh batch process.');
entry_pure=fullfile(root,'simulation','START_SIMULATION.m');
entry_experiment=fullfile(root,'simulation','START_EXPERIMENT.m');
orders={{entry_pure,entry_experiment},{entry_experiment,entry_pure}};
cases=cell(1,2);
for k=1:numel(orders)
    evalin('base','init_AXU5EV;AXU5EV_Backend=''model_fixed'';');
    % Deliberate collisions are confined to this disposable batch workspace.
    evalin('base','Tau_e_mm=61.25;Kp_ACR=999;Udc=17;Host_Target_mm=1.234;');
    before=parameter_snapshot;
    for j=1:2
        evalin('base',sprintf('run(''%s'');',strrep(orders{k}{j},'''','''''')));
    end
    after=parameter_snapshot;
    assert(isequaln(before,after),'AX04:BaseIsolation', ...
        'Opening the entries changed existing base parameters.');
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
        'workspace_fields_checked',numel(names), ...
        'experiment_values',struct('Tau_e_mm',mw.getVariable('Tau_e_mm'), ...
            'Kp_ACR',mw.getVariable('Kp_ACR'),'Udc',mw.getVariable('Udc')), ...
        'foc_values',struct('Tau_e_mm',foc_workspace.getVariable('Tau_e_mm'), ...
            'Kp_ACR',foc_workspace.getVariable('Kp_ACR'),'Udc',foc_workspace.getVariable('Udc')));
    close_system(experiment,0);
    close_system(foc,0);
    close_system(pure,0);
end
result=struct('status','PASS','orders',{cases});
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
