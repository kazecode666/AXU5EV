function result=ax04_validate_travel_control(output_dir)
% Travel checks through the complete experiment-generated C entry point.
% Count fixtures are bit-preserving signed-count interpretations of uint32.
assert(~isfile(fullfile(output_dir,'travel_control_frames.csv')) && ...
    ~isfile(fullfile(output_dir,'travel_control_result.json')), ...
    'Choose a new travel-verification directory.');
if ~isfolder(output_dir)
    mkdir(output_dir);
end
rows=zeros(0,68);
cases=cell(1,6);
case_id=0;
frame=0;
command=zeros(20,1);
raw=uint32(0);
sample_id=uint32(0);
tick=uint64(0);
clear_fault=false;
try
    % Positive/negative soft-boundary positions, outward and inward commands.
    fixture_counts=int32([110001 110001 -110001 -110001]);
    fixture_speed=[0.5 -0.5 -0.5 0.5];
    expected_speed=[0 -0.5 0 0.5];
    for case_id=1:4
        reset_fixture(fixture_counts(case_id),fixture_speed(case_id));
        tail=zeros(20,1);
        for frame=0:1299
            observation=irq();
            if frame>=1280
                tail(frame-1279)=observation.runtime_frame(3);
            end
            advance();
        end
        assert(observation.position_valid && observation.speed_valid && ...
            abs(observation.position_mm-double(fixture_counts(case_id))*0.001)<1e-9, ...
            'AX04:TravelFeedback','Soft-limit fixture feedback is invalid.');
        assert(all(abs(tail-expected_speed(case_id))<1e-10), ...
            'AX04:TravelSoft','Soft-limit case %d has v_safe=%g, expected %g.', ...
            case_id,tail(end),expected_speed(case_id));
        assert(observation.reference_commit(8)==1, ...
            'AX04:TravelSoftFault','Soft travel limiting unexpectedly latched a fault.');
        cases{case_id}=struct('kind','soft','position_count',fixture_counts(case_id), ...
            'request_mm_s',fixture_speed(case_id),'expected_safe_mm_s',expected_speed(case_id), ...
            'actual_safe_mm_s',tail(end),'status','PASS');
    end

    % The inclusive hard boundaries latch, regardless of PI/alignment resets.
    fixture_counts=int32([120000 -120000]);
    for hard_index=1:2
        case_id=hard_index+4;
        reset_fixture(fixture_counts(hard_index),0);
        for frame=0:69
            observation=irq();
            advance();
        end
        assert_inhibited(observation,'Hard-boundary fault was not latched.');
        clear_fault=true;
        command(8)=0;
        observation=irq();
        assert_inhibited(observation,'A clear request at the hard boundary was accepted.');
        clear_fault=false;

        % Return inside both travel bands, retaining the same measurement state.
        returned_count=int32(100000);
        if fixture_counts(hard_index)<0
            returned_count=-returned_count;
        end
        raw=typecast(returned_count,'uint32');
        for frame=70:139
            advance();
            observation=irq();
        end
        assert(observation.position_valid && observation.speed_valid && ...
            abs(observation.speed_mm_s)<1e-10,'AX04:TravelReturn', ...
            'The returned in-range fixture did not regain stable feedback.');
        command(9)=1;
        advance();observation=irq();
        assert_inhibited(observation,'PI reset cleared the hard-travel fault.');
        command(9)=0;
        command(18)=1;
        advance();observation=irq();
        assert_inhibited(observation,'Init_Reset cleared the hard-travel fault.');
        command(18)=0;
        clear_fault=true;
        advance();observation=irq();
        assert(all(observation.drive_outputs(1:2)) && ~observation.drive_outputs(4), ...
            'AX04:TravelClear','Healthy in-range explicit fault clear did not restore drive requests.');
        assert(observation.reference_commit(8)==1 && observation.reference_commit(6)==0, ...
            'AX04:TravelClearReference','Explicit fault clear did not restore a valid PWM-off reference.');
        clear_fault=false;
        command(8)=1;
        advance();observation=irq();
        assert(observation.reference_commit(8)==1 && observation.reference_commit(6)==1, ...
            'AX04:TravelRecovery','Explicit clear did not release the copied Runtime travel latch.');
        cases{case_id}=struct('kind','hard','position_count',fixture_counts(hard_index), ...
            'returned_count',returned_count,'pi_reset_kept_fault',true, ...
            'init_reset_kept_fault',true,'explicit_clear_recovered',true,'status','PASS');
    end
    result=struct('status','PASS','cases',{cases},'irq_calls',size(rows,1), ...
        'source','Exact experiment-generated C normal entry', ...
        'soft_direction_threshold_mm_s',0,'hardware','HW_BINDING_PENDING','board','BOARD_NOT_RUN');
catch err
    result=struct('status','FAIL','case_id',case_id,'frame',frame, ...
        'completed_cases',{cases},'irq_calls',size(rows,1), ...
        'error_id',err.identifier,'error',err.message, ...
        'source','Exact experiment-generated C normal entry', ...
        'hardware','HW_BINDING_PENDING','board','BOARD_NOT_RUN');
    write_evidence();
    rethrow(err);
end
write_evidence();
disp(result);

    function reset_fixture(position_count,speed_request)
        initial=ax04_control_mex('initialize');
        assert(isequal(initial.reference_commit,[0;0;0;0;0;0;1;0]) && ...
            isequal(initial.drive_outputs,logical([0;0;0;1;0])), ...
            'AX04:TravelInitialize','A new travel fixture did not start with inhibited outputs.');
        assert(~initial.position_valid && ~initial.speed_valid && ...
            initial.continuous_count==int64(0) && initial.reference_version==uint32(0), ...
            'AX04:TravelInitializeState','Generated initialization retained an earlier fixture state.');
        command=zeros(20,1);
        command(2)=speed_request;
        command(6)=0;
        command(7)=1;
        command(8)=1;
        raw=typecast(position_count,'uint32');
        sample_id=uint32(0);
        tick=uint64(0);
        clear_fault=false;
    end

    function advance()
        sample_id=sample_id+uint32(500);
        tick=tick+uint64(5000);
    end

    function value=irq()
        value=ax04_control_mex('irq',command,raw,sample_id,tick,true,uint32(0), ...
            true,true,true,clear_fault,true,true,false,false);
        rows(end+1,:)=[case_id,frame,double(raw),double(sample_id),double(tick), ...
            value.position_mm,value.speed_mm_s,value.position_valid,value.speed_valid, ...
            double(value.history_count),double(value.feedback_status), ...
            value.runtime_frame(:)',value.reference_commit(:)',double(value.drive_outputs(:)'), ...
            double(value.continuous_count),double(value.commit_sample_id),double(value.reference_version)];
    end

    function assert_inhibited(value,message)
        assert(~any(value.drive_outputs(1:2)) && value.drive_outputs(4) && ...
            value.reference_commit(6)==0 && value.reference_commit(8)==0, ...
            'AX04:TravelHard','%s',message);
    end

    function write_evidence()
        writematrix(rows,fullfile(output_dir,'travel_control_frames.csv'));
        file=fopen(fullfile(output_dir,'travel_control_result.json'),'w');
        assert(file>=0,'Cannot create travel-control evidence.');
        cleanup=onCleanup(@()fclose(file)); %#ok<NASGU>
        fprintf(file,'%s\n',jsonencode(result,PrettyPrint=true));
    end
end
