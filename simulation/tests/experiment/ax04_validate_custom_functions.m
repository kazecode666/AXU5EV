function result=ax04_validate_custom_functions(output_dir)
% Directed equivalence check for the independently copied trajectory helpers.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
oldpath=path;
cleanup=onCleanup(@()path(oldpath)); %#ok<NASGU>
addpath(fullfile(root,'simulation','closed_loop','components'), ...
    fullfile(root,'simulation','experiment','r5'), ...
    fullfile(root,'simulation','experiment','pl'), ...
    fullfile(root,'simulation','experiment','parameters'));
assert(~isfolder(output_dir),'Choose a new verification directory.');
mkdir(output_dir);
[p,provenance]=axu5ev_experiment_parameters();
assert(p.PMLSM_Rs_ohm==1.45 && p.PMLSM_Ld_H==0.0118 && ...
    p.PMLSM_Lq_H==0.0118 && p.Tau_e_mm==30 && p.Udc==48);
assert(abs(p.Kp_ACR-59)<1e-10 && abs(p.Ki_ACR-7250)<1e-10);
assert(abs(p.Ki_ACR*p.Ts_ACR-0.725)<1e-12);
assert(p.Encoder_Nanometres_Per_Count==1000 && ...
    p.Encoder_Counts_Per_Electrical_Period==30000);
assert(~p.Total_Moving_Mass_Known && isnan(p.Total_Moving_Mass_kg));
assert(~p.Hardware_Binding_Complete && ~p.Physical_Calibration_Valid);
assert(p.Host_AutoStart_EN==0);
assert(p.Experiment_Id_Limit_A==0.5 && p.Id_Init_Target==0.5 && ...
    p.Experiment_Iq_Limit_A==0.3 && p.Speed_loop_Iq_Limit==0.3);

% Exercise the experiment-only adapters with exact units and fault semantics.
clear axu5ev_experiment_frame_guard axu5ev_experiment_reference_commit
command=zeros(20,1);
command(10)=1;
command(12:14)=1;
command(15)=999;
command(19:20)=999;
bound=axu5ev_experiment_bind_runtime_input(command,12,100,false,true);
assert(bound(15)==100 && bound(19)==0 && bound(20)==12);
assert(bound(10)==0 && all(bound(12:14)==0));
command(8)=1;
bound=axu5ev_experiment_bind_runtime_input(command,12,100,true,true);
assert(bound(8)==0 && bound(9)==1 && bound(19)==1);
command(1)=NaN;
bound=axu5ev_experiment_bind_runtime_input(command,12,100,true,true);
assert(all(isfinite(bound)) && bound(1)==0 && bound(8)==0 && bound(9)==1);
glue_checks=4;

command=zeros(20,1);
[new_frame,healthy,fault,clear_allowed]=axu5ev_experiment_frame_guard( ...
    true,true,true,true,true,uint32(0),0,command,false,false,120,-120);
assert(new_frame && healthy && ~fault && ~clear_allowed);
[new_frame,healthy,fault]=axu5ev_experiment_frame_guard( ...
    true,true,true,true,true,uint32(2),0,command,false,false,120,-120);
assert(~new_frame && ~healthy && ~fault);
[new_frame,healthy,fault]=axu5ev_experiment_frame_guard( ...
    true,true,true,true,true,uint32(4),0,command,false,false,120,-120);
assert(new_frame && ~healthy && fault);
[new_frame,healthy,fault,clear_allowed]=axu5ev_experiment_frame_guard( ...
    true,true,true,true,true,uint32(2),0,command,true,false,120,-120);
assert(~new_frame && ~healthy && fault && ~clear_allowed);
[~,healthy,fault,clear_allowed]=axu5ev_experiment_frame_guard( ...
    true,true,true,true,true,uint32(0),0,command,true,false,120,-120);
assert(healthy && ~fault && clear_allowed);
[~,healthy,fault,clear_allowed]=axu5ev_experiment_frame_guard( ...
    true,false,true,true,true,uint32(0),0,command,true,false,120,-120);
assert(~healthy && fault && ~clear_allowed);
glue_checks=glue_checks+6;

runtime=zeros(41,1);
runtime(1:2)=[0.8;-0.8];
runtime(7)=1;
runtime(8)=0.25;
runtime(18)=1;
[reference,commit_id,version]=axu5ev_experiment_reference_commit( ...
    runtime,true,true,100,uint32(500),true,false,true,true,false, ...
    false,0,p.Experiment_Id_Limit_A,p.Experiment_Iq_Limit_A,p.Tau_e_mm);
assert(isequal(reference(1:2),[0.5;-0.3]));
assert(abs(reference(3)-100*2*pi/30)<1e-12 && reference(4)==0.25);
assert(reference(5)==1 && reference(6)==1 && reference(7)==0 && reference(8)==1);
assert(commit_id==uint32(500) && version==uint32(1));
[reference,commit_id,version]=axu5ev_experiment_reference_commit( ...
    runtime,true,true,100,uint32(500),false,false,true,true,false, ...
    false,0,p.Experiment_Id_Limit_A,p.Experiment_Iq_Limit_A,p.Tau_e_mm);
assert(all(reference(1:2)==0) && reference(6)==0 && reference(7)==1 && reference(8)==0);
assert(commit_id==uint32(500) && version==uint32(1));
[reference,commit_id,version]=axu5ev_experiment_reference_commit( ...
    runtime,true,true,100,uint32(1000),true,true,true,true,false, ...
    false,0,p.Experiment_Id_Limit_A,p.Experiment_Iq_Limit_A,p.Tau_e_mm);
assert(reference(6)==0 && reference(7)==1);
assert(commit_id==uint32(1000) && version==uint32(2));
runtime(8)=NaN;
[reference,~,~]=axu5ev_experiment_reference_commit( ...
    runtime,false,true,100,uint32(1500),true,false,true,true,false, ...
    false,0,p.Experiment_Id_Limit_A,p.Experiment_Iq_Limit_A,p.Tau_e_mm);
assert(all(isfinite(reference)) && reference(6)==0 && reference(7)==1 && reference(8)==0);
glue_checks=glue_checks+4;

checks=0;
for target=[-1 0 1]
    for time=[-0.1 0 0.01 0.05 0.2 0.7 2]
        original=cell(1,5);copied=cell(1,5);
        [original{:}]=pmlsm_scurve_profile(time,target,10,100,1000,0.1);
        [copied{:}]=axu5ev_experiment_scurve_profile(time,target,10,100,1000,0.1);
        assert(isequaln(original,copied),'AX04:ScurveCopy','Independent S-curve copy differs.');
        checks=checks+1;
    end
end

original_state=zeros(1,22);copied_state=zeros(1,22);
position=0;request=0;target=0;
cfg=[p.Ts_ACR p.Ts_POS p.Host_Start_s p.Host_Traj_Vmax p.Host_Traj_Amax ...
    p.Host_Traj_Jmax p.Host_Speed_Ramp_s p.Pos_deadband p.Host_Ready_Ticks 0];
maximum_error=0;
for frame=0:1599
    if frame==600,request=1;target=0.5;end
    if frame==650,request=0;target=-0.1;end
    if frame==1000,request=1;target=0.1;end
    pi_reset=double(frame>=800 && frame<820);
    time=frame*p.Ts_ACR;
    [original_state,original_reference,original_observation]=pmlsm_point_move_step( ...
        original_state,time,position,target,request,true,true,pi_reset,false,true,cfg);
    [copied_state,copied_reference,copied_observation]=axu5ev_experiment_point_move_step( ...
        copied_state,time,position,target,request,true,true,pi_reset,false,true,cfg);
    error=max(abs([original_state-copied_state, ...
        original_reference-copied_reference,original_observation-copied_observation]));
    maximum_error=max(maximum_error,error);
    assert(error==0,'AX04:PointMoveCopy','Independent point-move copy differs at frame %d.',frame);
    position=original_reference;
    checks=checks+1;
end
assert(original_observation(9)==1 && original_observation(10)==2 && ...
    original_observation(13)==1,'AX04:FixtureCoverage','Expected accept/reject/interruption cases missing.');
result=struct('status','PASS','checks',checks+glue_checks, ...
    'glue_cases',glue_checks,'point_move_frames',1600, ...
    'maximum_error',maximum_error,'accepted_commands',original_observation(9), ...
    'rejected_commands',original_observation(10),'interrupted',original_observation(13), ...
    'parameters','AQM30-B2 experiment candidate', ...
    'mass','UNKNOWN','hardware',provenance.hardware);
file=fopen(fullfile(output_dir,'custom_function_result.json'),'w');
assert(file>=0,'Cannot create custom function result.');
file_cleanup=onCleanup(@()fclose(file)); %#ok<NASGU>
fprintf(file,'%s\n',jsonencode(result,PrettyPrint=true));
disp(result);
end
