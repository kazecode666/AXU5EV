function result=ax04_validate_generated_control(output_dir)
% Exercise exact experiment-generated C through its test-only MEX transport.
% Calls are host verification events. Physical IRQ/driver binding is pending.
if ~isfolder(output_dir),mkdir(output_dir);end
initialization=ax04_control_mex('initialize');
assert(isequal(initialization.reference_commit,[0;0;0;0;0;0;1;0]), ...
    'AX04:InitializeReference','Initialization did not inhibit PWM and assert PI reset before the first IRQ.');
assert(isequal(initialization.drive_outputs,logical([0;0;0;1;0])), ...
    'AX04:InitializeDriver','Initialization did not disable the driver buffer before the first IRQ.');
assert(~initialization.position_valid && ~initialization.speed_valid && ...
    initialization.history_count==uint8(0) && initialization.continuous_count==int64(0) && ...
    initialization.reference_version==uint32(0) && initialization.service_count==uint32(0), ...
    'AX04:InitializeState','Initialization retained state from an earlier invocation.');
command=zeros(20,1);
command(9)=1;
raw=uint32(0);sample_id=uint32(0);tick=uint64(0);
erri=true;erru=true;clear_fault=false;
relcon=false;encon=false;freset=false;oe_disable=true;
rows=zeros(0,14);checks=3;

for frame=0:69
    if frame>0,advance();end
    observation=irq();
    assert(observation.position_valid);
    assert(abs(observation.position_mm-frame*0.01)<1e-12);
    assert(observation.continuous_count==int64(frame*10));
    assert(observation.speed_valid==(frame>=50));
    if frame>=50,assert(abs(observation.speed_mm_s-100)<1e-9);end
    assert(~any(observation.drive_outputs(1:3)) && observation.drive_outputs(4));
    assert(observation.reference_commit(6)==0);
    assert(abs(observation.runtime_frame(14)-48)<1e-12);
    checks=checks+1;
end

previous=observation;
observation=irq();
assert(observation.continuous_count==previous.continuous_count && ...
    observation.history_count==previous.history_count);
assert(abs(observation.position_mm-previous.position_mm)<1e-12);
assert(bitand(observation.feedback_status,uint32(2))~=0);
checks=checks+1;

% Missing an integral frame preserves count continuity and rebuilds history.
raw=raw+uint32(10);sample_id=sample_id+uint32(1000);tick=tick+uint64(10000);
observation=irq();
assert(observation.position_valid && ~observation.speed_valid && observation.history_count==1);
assert(bitand(observation.feedback_status,uint32(4))~=0);
checks=checks+1;
for frame=1:50
    advance();observation=irq();
end
assert(observation.speed_valid && abs(observation.speed_mm_s-100)<1e-9);
checks=checks+1;

% A low-active external fault is latched. Driver F_Reset is independent.
erri=false;advance();observation=irq();
assert(observation.drive_outputs(5) && ~any(observation.drive_outputs(1:2)));
assert(observation.reference_commit(6)==0);
checks=checks+1;
freset=true;advance();observation=irq();
assert(observation.drive_outputs(3) && observation.drive_outputs(5));
checks=checks+1;
freset=false;erri=true;advance();observation=irq();
assert(observation.drive_outputs(5));
checks=checks+1;

% A duplicate cannot clear only part of the guarded/Runtime fault state.
clear_fault=true;observation=irq();
assert(bitand(observation.feedback_status,uint32(2))~=0 && observation.drive_outputs(5));
checks=checks+1;

% Clear is denied while the raw fault is active, then explicitly accepted.
erri=false;clear_fault=true;advance();observation=irq();
assert(observation.drive_outputs(5));checks=checks+1;
erri=true;advance();observation=irq();
assert(~observation.drive_outputs(5));checks=checks+1;
clear_fault=false;

% PI reset does not clear raw-position continuity or the mechanical origin.
previous_count=observation.continuous_count;
command(9)=0;advance();observation=irq();
assert(observation.continuous_count==previous_count+int64(10));
command(9)=1;advance();observation=irq();
assert(observation.continuous_count==previous_count+int64(20));checks=checks+1;

% Explicit requests reach the copied driver. F_Reset inhibits REL/EN and PWM
% while retaining the requested active buffer for the reset pulse.
command(8)=0;relcon=true;encon=true;oe_disable=false;
advance();observation=irq();
assert(all(observation.drive_outputs(1:2)) && ...
    ~any(observation.drive_outputs(3:5)) && observation.reference_commit(6)==0);
checks=checks+1;
freset=true;advance();observation=irq();
assert(~any(observation.drive_outputs(1:2)) && observation.drive_outputs(3) && ...
    ~any(observation.drive_outputs(4:5)) && observation.reference_commit(6)==0);
checks=checks+1;
freset=false;advance();observation=irq();
assert(all(observation.drive_outputs(1:2)) && ~any(observation.drive_outputs(3:5)));
checks=checks+1;
relcon=false;encon=false;oe_disable=true;

% Manual alignment stays idle until Init_Start, and Init_Reset returns idle.
command(16)=1;command(17)=0;
for frame=1:3,advance();observation=irq();end
assert(observation.runtime_frame(5)==0);checks=checks+1;
command(17)=1;
for frame=1:3,advance();observation=irq();end
assert(observation.runtime_frame(5)==1);checks=checks+1;
command(17)=0;command(18)=1;
for frame=1:3,advance();observation=irq();end
assert(observation.runtime_frame(5)==0);checks=checks+1;

service_before=observation.service_count;
observation=ax04_control_mex('service');
assert(observation.service_count==service_before+uint32(1));checks=checks+1;
assert(all(isfinite(observation.telemetry)));
writematrix(rows,fullfile(output_dir,'generated_control_frames.csv'));
travel=ax04_validate_travel_control(output_dir);
alignment=ax04_validate_alignment_control(output_dir);
result=struct('status','PASS','checks',checks, ...
    'irq_calls',size(rows,1)+travel.irq_calls+alignment.irq_calls, ...
    'frame_cases_irq_calls',size(rows,1), ...
    'speed_history_entries',51,'speed_intervals',50,'speed_test_mm_s',100, ...
    'cases','normal frames, duplicate and duplicate-clear rejection, gap/reacquisition, active-low fault, REL/EN enable, F_Reset inhibit, explicit clear, PI reset, soft/hard travel, full five-state alignment and once-only offset, manual alignment start/reset, non-real-time service', ...
    'hardware','HW_BINDING_PENDING','board','BOARD_NOT_RUN', ...
    'source','Exact ARM Cortex-R generated C through transport-only MEX');
result.travel=travel;
result.alignment=alignment;
result.initialization=struct('status','PASS','before_first_irq',true, ...
    'reference_commit',initialization.reference_commit, ...
    'drive_outputs',initialization.drive_outputs,'reference_version',initialization.reference_version, ...
    'service_count',initialization.service_count);
file=fopen(fullfile(output_dir,'generated_control_result.json'),'w');
assert(file>=0,'Cannot create generated-control result.');
cleanup=onCleanup(@()fclose(file)); %#ok<NASGU>
fprintf(file,'%s\n',jsonencode(result,PrettyPrint=true));
disp(result);

    function advance()
        raw=raw+uint32(10);
        sample_id=sample_id+uint32(500);
        tick=tick+uint64(5000);
    end

    function value=irq()
        value=ax04_control_mex('irq',command,raw,sample_id,tick,true,uint32(0), ...
            true,erri,erru,clear_fault,relcon,encon,freset,oe_disable);
        rows(end+1,:)=[double(sample_id),double(raw),double(tick),value.position_mm, ...
            value.speed_mm_s,value.position_valid,value.speed_valid, ...
            double(value.history_count),double(value.feedback_status), ...
            double(value.continuous_count),double(value.reference_version), ...
            value.reference_commit(6),value.drive_outputs(3),value.drive_outputs(5)];
    end
end
