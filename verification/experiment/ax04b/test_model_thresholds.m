function result=test_model_thresholds(mex_directory)
% Exercise the actual generated Reference_Manager and PI_Reset command path.
original_path=path;
cleanup=onCleanup(@()path(original_path)); %#ok<NASGU>
clear ax04_control_mex;
addpath(mex_directory,'-begin');
assert(strcmpi(string(fileparts(which('ax04_control_mex'))),string(mex_directory)), ...
    'Resolve the MEX from this generation only.');

switch_values=[0 0.5 1];
iq_A=zeros(size(switch_values));
for i=1:numel(switch_values)
    command=zeros(20,1);
    command(4)=switch_values(i);
    command(5)=0.125;
    command(8)=1;
    observation=run_command(command);
    assert(observation.speed_valid && observation.reference_commit(6)==1);
    iq_A(i)=observation.runtime_frame(2);
end
assert(isequal(iq_A,[0 0 0.125]),'Strict >0.5 Iq Test Mode boundary changed.');

reset_values=[0 0.25 -1];
model_reset=zeros(size(reset_values));
pl_reset=zeros(size(reset_values));
for i=1:numel(reset_values)
    command=zeros(20,1);
    command(8)=1;
    command(9)=reset_values(i);
    observation=run_command(command);
    assert(observation.speed_valid && observation.runtime_frame(5)==0);
    model_reset(i)=observation.runtime_frame(23);
    pl_reset(i)=observation.reference_commit(7);
end
assert(isequal(model_reset,[0 1 1]) && isequal(pl_reset,[0 1 1]), ...
    'Every nonzero raw PI_Reset command must reset both reference interfaces.');
result=struct('status','PASS','switch_values',switch_values,'iq_A',iq_A, ...
    'reset_values',reset_values,'model_reset',model_reset,'pl_reset',pl_reset);
end

function observation=run_command(command)
ax04_control_mex('initialize');
for frame=0:59
    observation=ax04_control_mex('irq',command,uint32(0),uint32(500*frame), ...
        uint64(5000*frame),true,uint32(0),true,true,true,false,true,true,false,false);
end
end
