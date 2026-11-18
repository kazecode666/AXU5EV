function result=ax04_validate_alignment_control(output_dir,mode)
% Full copied five-state alignment through the experiment-generated C entry.
% Evidence keeps state boundaries and adjacent samples, with no long CSV.
if nargin<2,mode='verify';end
mode=validatestring(mode,{'verify','counterexample'});
if strcmp(mode,'counterexample')
    result=alignment_safety_cases(output_dir,mode);
    return;
end

file=fullfile(output_dir,'alignment_control_result.json');
assert(~isfile(file),'Choose a new alignment-verification directory.');
if ~isfolder(output_dir)
    mkdir(output_dir);
end
p=axu5ev_experiment_parameters();
assert(p.Tau_e_mm==30 && p.Id_Init_Target==0.5 && ...
    p.Experiment_Id_Limit_A==0.5 && p.Experiment_Iq_Limit_A==0.3);
assert(p.Ramp_Ticks==10000 && p.Hold_Ticks==30000 && ...
    p.Id_Release_Ramp_Ticks==2000);
initial=ax04_control_mex('initialize');
assert(isequal(initial.reference_commit,[0;0;0;0;0;0;1;0]) && ...
    isequal(initial.drive_outputs,logical([0;0;0;1;0])), ...
    'AX04:AlignmentInitialize','Alignment did not start with inhibited outputs.');
assert(~initial.position_valid && ~initial.speed_valid && ...
    initial.continuous_count==int64(0) && initial.reference_version==uint32(0), ...
    'AX04:AlignmentInitializeState','Generated initialization retained an earlier fixture state.');
command=zeros(20,1);
command(8)=1;
command(16)=1;
raw=uint32(12000);
sample_id=uint32(0);
tick=uint64(0);
frame=-51;
phase='warmup';
calls=0;
states_seen=false(1,5);
state_frames=zeros(1,5);
minimum_id=inf(1,5);
maximum_id=-inf(1,5);
maximum_iq=0;
transitions=struct('phase',{},'frame',{},'from',{},'to',{}, ...
    'before',{},'entry',{},'next',{});
previous=[];
observation=[];
last_observation=[];
try
    for frame=-51:-1
        observation=irq();
        assert(observation.runtime_frame(5)==0 && observation.runtime_frame(4)==0, ...
            'AX04:AlignmentManual','Alignment started before the manual Init_Start pulse.');
    end
    assert(observation.speed_valid && abs(observation.speed_mm_s)<1e-12);
    assert(observation.position_mm==12 && observation.continuous_count==int64(12000));

    phase='alignment';
    command(17)=1;
    frame=0;
    observation=irq();
    assert(observation.runtime_frame(5)==1 && observation.runtime_frame(6)==0, ...
        'AX04:AlignmentStart','The manual pulse did not enter RAMP_ID at zero Id.');
    command(17)=0;
    done_frame=p.Ramp_Ticks+p.Hold_Ticks+p.Id_Release_Ramp_Ticks;
    for frame=1:done_frame+5
        observation=irq();
    end
    assert(all(states_seen),'AX04:AlignmentStates','The complete five-state sequence was not observed.');
    alignment_events=transitions(strcmp({transitions.phase},'alignment'));
    assert(isequal([alignment_events.to],[1 2 3 4]), ...
        'AX04:AlignmentOrder','The alignment state order differs from the copied source.');
    assert(isequal([alignment_events.frame],[0 p.Ramp_Ticks ...
        p.Ramp_Ticks+p.Hold_Ticks done_frame]), ...
        'AX04:AlignmentTiming','The 100 us alignment state durations differ from the copied source.');
    assert(abs(alignment_events(2).entry.id_init_A-0.5)<1e-12 && ...
        abs(alignment_events(3).entry.id_init_A-0.5)<1e-12 && ...
        alignment_events(4).entry.id_init_A==0);
    assert(observation.runtime_frame(5)==4 && observation.runtime_frame(4)==1 && ...
        observation.runtime_frame(7)==0 && observation.reference_commit(1)==0, ...
        'AX04:AlignmentDone','DONE did not release Id and fixed-angle alignment.');
    expected_offset=mod(p.theta_align_const-2*pi*12/p.Tau_e_mm,2*pi);
    assert(abs(observation.runtime_frame(8)-expected_offset)<1e-12 && ...
        abs(observation.reference_commit(4)-expected_offset)<1e-12, ...
        'AX04:AlignmentOffset','The captured 12 mm/30 mm offset differs from the source formula.');
    assert(observation.runtime_frame(9)==12 && observation.position_mm==12 && ...
        observation.continuous_count==int64(12000), ...
        'AX04:AlignmentOrigin','Alignment changed measured position or continuous count.');
    done_snapshot=snapshot(observation);

    phase='post_alignment_motion';
    raw=raw+uint32(1000);
    for frame=done_frame+6:done_frame+65
        observation=irq();
        assert(observation.position_mm==13 && observation.continuous_count==int64(13000));
        assert(observation.runtime_frame(5)==4 && observation.runtime_frame(4)==1 && ...
            observation.runtime_frame(9)==12 && ...
            abs(observation.runtime_frame(8)-expected_offset)<1e-12 && ...
            abs(observation.reference_commit(4)-expected_offset)<1e-12, ...
            'AX04:AlignmentOnce','Completed alignment recaptured its offset while position changed.');
    end
    assert(observation.speed_valid && abs(observation.speed_mm_s)<1e-12);
    moved_snapshot=snapshot(observation);

    phase='init_reset';
    command(18)=1;
    frame=done_frame+66;
    observation=irq();
    assert(observation.runtime_frame(5)==0 && observation.runtime_frame(4)==0 && ...
        observation.reference_commit(1)==0 && observation.position_mm==13 && ...
        observation.continuous_count==int64(13000), ...
        'AX04:AlignmentReset','Init_Reset did not return only alignment to IDLE.');
    command(18)=0;
    phase='manual_restart_wait';
    for frame=done_frame+67:done_frame+76
        observation=irq();
        assert(observation.runtime_frame(5)==0 && observation.runtime_frame(4)==0 && ...
            observation.runtime_frame(9)==12 && ...
            abs(observation.runtime_frame(8)-expected_offset)<1e-12, ...
            'AX04:AlignmentAutoRestart','Alignment restarted or recaptured without Init_Start.');
    end
    phase='manual_restart';
    command(17)=1;
    frame=done_frame+77;
    observation=irq();
    assert(observation.runtime_frame(5)==1 && observation.runtime_frame(6)==0 && ...
        observation.runtime_frame(4)==0 && observation.position_mm==13 && ...
        observation.continuous_count==int64(13000), ...
        'AX04:AlignmentRestart','A second manual pulse did not enter a new RAMP_ID.');
    command(17)=0;
    frame=done_frame+78;
    observation=irq();
    assert(observation.runtime_frame(5)==1 && ...
        abs(observation.runtime_frame(6)-p.Id_Init_Step)<1e-12);
    result=struct('status','PASS','irq_calls',calls,'sample_period_s',p.Ts_ACR, ...
        'expected_transition_frames',[0 10000 40000 42000], ...
        'transitions',transitions,'state_frames',state_frames, ...
        'minimum_id_init_A',minimum_id,'maximum_id_init_A',maximum_id, ...
        'maximum_abs_iq_commit_A',maximum_iq,'id_limit_A',p.Experiment_Id_Limit_A, ...
        'iq_limit_A',p.Experiment_Iq_Limit_A,'expected_offset_rad',expected_offset, ...
        'done',done_snapshot,'moved_without_recapture',moved_snapshot, ...
        'init_reset_preserved_position',true,'manual_restart_verified',true, ...
        'second_capture','NOT_RUN; second manual RAMP entry verified', ...
        'source','Exact experiment-generated C normal entry', ...
        'hardware','HW_BINDING_PENDING','board','BOARD_NOT_RUN');
catch err
    result=struct('status','FAIL','phase',phase,'frame',frame,'irq_calls',calls, ...
        'states_seen',states_seen,'transitions',transitions, ...
        'state_frames',state_frames,'minimum_id_init_A',minimum_id, ...
        'maximum_id_init_A',maximum_id,'error_id',err.identifier,'error',err.message, ...
        'last_observation',snapshot(last_observation), ...
        'source','Exact experiment-generated C normal entry', ...
        'hardware','HW_BINDING_PENDING','board','BOARD_NOT_RUN');
    write_result();
    rethrow(err);
end
result.safety=alignment_safety_cases(output_dir,mode);
result.normal_flow_irq_calls=calls;
result.irq_calls=calls+result.safety.irq_calls;
write_result();
disp(result);

    function value=irq()
        value=ax04_control_mex('irq',command,raw,sample_id,tick,true,uint32(0), ...
            true,true,true,false,true,true,false,false);
        last_observation=value;
        calls=calls+1;
        current=snapshot(value);
        if ~isempty(transitions) && isempty(transitions(end).next)
            transitions(end).next=current;
        end
        state=value.runtime_frame(5);
        assert(state>=0 && state<=4 && state==fix(state), ...
            'AX04:AlignmentStateValue','Unexpected alignment state value.');
        states_seen(state+1)=true;
        state_frames(state+1)=state_frames(state+1)+1;
        minimum_id(state+1)=min(minimum_id(state+1),value.runtime_frame(6));
        maximum_id(state+1)=max(maximum_id(state+1),value.runtime_frame(6));
        maximum_iq=max(maximum_iq,abs(value.reference_commit(2)));
        if isempty(previous) || state~=previous.state
            from=-1;
            if ~isempty(previous),from=previous.state;end
            transitions(end+1)=struct('phase',phase,'frame',frame,'from',from,'to',state, ...
                'before',previous,'entry',current,'next',[]);
        end
        previous=current;
        assert(value.position_valid && value.speed_valid==(calls>=51), ...
            'AX04:AlignmentFeedback','Qualified feedback did not keep its 50-interval history.');
        assert(abs(value.reference_commit(1))<=p.Experiment_Id_Limit_A+1e-12 && ...
            abs(value.reference_commit(2))<=p.Experiment_Iq_Limit_A+1e-12, ...
            'AX04:AlignmentCurrentLimit','The committed debug current limits were exceeded.');
        if calls>=51
            assert(value.reference_commit(8)==1 && ...
                value.reference_commit(6)==double(command(18)==0), ...
                'AX04:AlignmentPermission','Healthy explicitly requested alignment lost PWM/reference permission.');
        end
        sample_id=sample_id+uint32(500);
        tick=tick+uint64(5000);
    end

    function value=snapshot(data)
        value=[];
        if ~isempty(data)
            value=struct('sample_id',data.commit_sample_id,'state',data.runtime_frame(5), ...
                'init_done',data.runtime_frame(4),'id_init_A',data.runtime_frame(6), ...
                'id_runtime_A',data.runtime_frame(1),'id_commit_A',data.reference_commit(1), ...
                'iq_commit_A',data.reference_commit(2),'offset_rad',data.runtime_frame(8), ...
                'x_align_mm',data.runtime_frame(9),'position_mm',data.position_mm, ...
                'continuous_count',data.continuous_count,'pwm_permit',data.reference_commit(6));
        end
    end

    function write_result()
        stream=fopen(file,'w');
        assert(stream>=0,'Cannot create alignment-control evidence.');
        cleanup=onCleanup(@()fclose(stream)); %#ok<NASGU>
        fprintf(stream,'%s\n',jsonencode(result,PrettyPrint=true));
    end
end

function result=alignment_safety_cases(output_dir,mode)
% Exercise the same external control entry for rejected and interrupted starts.
% Counterexample mode records the previous candidate's actual unsafe outputs.
strict=strcmp(mode,'verify');
if ~isfolder(output_dir),mkdir(output_dir);end
if strict
    file=fullfile(output_dir,'alignment_safety_result.json');
else
    file=fullfile(output_dir,'alignment_counterexamples.json');
end
assert(~isfile(file),'Choose a new alignment safety result directory.');
command=zeros(20,1);
raw=uint32(12000);sample_id=uint32(0);tick=uint64(0);
ready=true;erri=true;erru=true;clear_fault=false;
relcon=true;encon=true;freset=false;oe_disable=false;
trial_calls=0;total_calls=0;
cases=struct('name',{},'passed',{},'before',{},'event',{},'after',{});

% A denied level cannot become a later start when permission is restored.
for denied={'relcon','encon','oe_disable','pwm_request'}
    setup(denied{1});
    command(17)=1;
    before=call(true);
    for index=1:3,observation=call(true);end
    safe=aborted(observation);
    record(['start_denied_' denied{1}],safe,before,observation,[]);
    if strict
        restore_permit();
        for index=1:3,observation=call(true);end
        record(['held_start_after_' denied{1}],rejected(observation),[],observation,[]);
        command(17)=0;call(true);
        command(17)=1;observation=call(true);
        record(['new_start_after_' denied{1}],ramp_start(observation),[],observation,[]);
    end
end

% The final RAMP_DOWN sample must consume safety before normal completion.
for event={'init_reset','external_fault','permit_withdrawal'}
    setup('');
    command(17)=1;call(true);command(17)=0;
    for frame=1:41999,observation=call(true);end
    assert(observation.runtime_frame(5)==3,'AX04:SafetySetup', ...
        'The terminal-priority fixture did not reach the final RAMP_DOWN interval.');
    before=observation;
    switch event{1}
        case 'init_reset',command(18)=1;
        case 'external_fault',erri=false;
        case 'permit_withdrawal',relcon=false;
    end
    observation=call(true);
    command(18)=0;erri=true;relcon=true;
    after=call(true);
    record(['terminal_' event{1}],aborted(observation) && ...
        after.runtime_frame(4)==0 && after.runtime_frame(5)~=4, ...
        before,observation,after);
end

if strict
    active_frames=[10 10010 40010];
    active_names={'ramp_id','hold_align','ramp_down_id'};
    for active_index=1:numel(active_frames)
        for event={'f_reset','permit_withdrawal'}
            setup('');
            command(17)=1;
            for frame=0:active_frames(active_index),observation=call(true);end
            before=observation;
            if strcmp(event{1},'f_reset'),freset=true;else,encon=false;end
            observation=call(true);
            restore_permit();
            for index=1:3,after=call(true);end
            name=[active_names{active_index} '_' event{1}];
            record(['running_' name],aborted(observation) && ...
                rejected(after),before,observation,after);
            command(17)=0;call(true);command(17)=1;
            observation=call(true);
            record(['new_start_after_' name],ramp_start(observation),[],observation,[]);
        end
    end

    setup('');command(17)=1;call(true);command(17)=0;
    for index=1:10,observation=call(true);end
    before=observation;
    observation=call(false);
    record('ordinary_duplicate_hold', ...
        isequal(observation.runtime_frame,before.runtime_frame) && ...
        observation.continuous_count==before.continuous_count && ...
        observation.history_count==before.history_count && ...
        observation.reference_version==before.reference_version && ...
        bitand(observation.feedback_status,uint32(2))~=0, ...
        before,observation,[]);

    command(18)=1;observation=call(false);
    record('duplicate_init_reset',aborted(observation) && ...
        observation.continuous_count==before.continuous_count,before,observation,[]);
    command(18)=0;call(true);command(17)=1;call(true);
    for index=1:5,observation=call(true);end
    before=observation;relcon=false;observation=call(false);
    restore_permit();after=call(true);
    record('duplicate_permit_withdrawal',aborted(observation) && ...
        rejected(after),before,observation,after);
    command(17)=0;call(true);command(17)=1;observation=call(true);
    record('new_start_after_duplicate_abort',ramp_start(observation),[],observation,[]);

    for event={'init_reset','permit_withdrawal'}
        setup('');command(17)=1;call(true);
        for index=1:5,observation=call(true);end
        before=observation;ready=false;
        if strcmp(event{1},'init_reset'),command(18)=1;else,oe_disable=true;end
        observation=call(true);
        ready=true;command(18)=0;restore_permit();after=call(true);
        record(['invalid_frame_' event{1}],aborted(observation) && ...
            observation.continuous_count==before.continuous_count && ...
            after.runtime_frame(4)==0,before,observation,after);
    end

    % The established double command contract treats every nonzero PI request
    % as reset. The alignment permit must use that same boolean conversion.
    for reset_value=[0.25 -1]
        setup('');
        command(9)=reset_value;
        command(17)=1;
        for index=1:4,observation=call(true);end
        name=sprintf('nonzero_pi_reset_%g',reset_value);
        record(['start_denied_' name],rejected(observation) && ...
            observation.reference_commit(7)==1,[],observation,[]);
        command(9)=0;
        for index=1:3,observation=call(true);end
        record(['held_start_after_' name],rejected(observation),[],observation,[]);
        command(17)=0;call(true);
        command(17)=1;observation=call(true);
        record(['new_start_after_' name],ramp_start(observation),[],observation,[]);
    end

    setup('');command(17)=1;call(true);
    for index=1:10,observation=call(true);end
    before=observation;command(9)=0.25;observation=call(false);
    record('duplicate_nonzero_pi_reset',rejected(observation) && ...
        observation.reference_commit(7)==1 && ...
        observation.continuous_count==before.continuous_count,before,observation,[]);
    command(9)=0;after=call(true);
    record('held_start_after_duplicate_pi_reset',rejected(after),[],after,[]);
    command(17)=0;call(true);command(17)=1;observation=call(true);
    record('new_start_after_duplicate_pi_reset',ramp_start(observation),[],observation,[]);
end

failed={cases(~[cases.passed]).name};
if strict
    status='PASS';
    if ~isempty(failed),status='FAIL';end
else
    status='NO_COUNTEREXAMPLE';
    if any(startsWith(failed,'start_denied_')) && ...
            any(strcmp(failed,'terminal_init_reset'))
        status='COUNTEREXAMPLES_REPRODUCED';
    end
end
result=struct('status',status,'mode',mode,'cases',cases, ...
    'checks',numel(cases),'failed_cases',{failed},'irq_calls',total_calls, ...
    'source','Exact experiment-generated C external entry', ...
    'hardware','HW_BINDING_PENDING','board','BOARD_NOT_RUN');
stream=fopen(file,'w');assert(stream>=0,'Cannot create alignment safety evidence.');
cleanup=onCleanup(@()fclose(stream)); %#ok<NASGU>
fprintf(stream,'%s\n',jsonencode(result,PrettyPrint=true));
if strict
    assert(isempty(failed),'AX04:AlignmentSafety','Alignment safety failed: %s',strjoin(failed,', '));
end
disp(result);

    function setup(denied)
        ax04_control_mex('initialize');
        command=zeros(20,1);command(8)=1;command(16)=1;
        raw=uint32(12000);sample_id=uint32(0);tick=uint64(0);trial_calls=0;
        ready=true;erri=true;erru=true;clear_fault=false;
        restore_permit();
        switch denied
            case 'relcon',relcon=false;
            case 'encon',encon=false;
            case 'oe_disable',oe_disable=true;
            case 'pwm_request',command(8)=0;
        end
        for warmup=1:51,call(true);end
    end

    function restore_permit()
        relcon=true;encon=true;oe_disable=false;freset=false;command(8)=1;
    end

    function value=call(new_frame)
        if new_frame && trial_calls>0
            sample_id=sample_id+uint32(500);tick=tick+uint64(5000);
        end
        value=ax04_control_mex('irq',command,raw,sample_id,tick,ready,uint32(0), ...
            true,erri,erru,clear_fault,relcon,encon,freset,oe_disable);
        total_calls=total_calls+1;trial_calls=trial_calls+1;
        assert(value.continuous_count==int64(12000), ...
            'AX04:SafetyOrigin','Alignment safety changed the mechanical count.');
    end

    function value=rejected(data)
        value=data.runtime_frame(5)==0 && data.runtime_frame(4)==0 && ...
            data.runtime_frame(6)==0 && data.runtime_frame(7)==0 && ...
            data.reference_commit(1)==0;
    end

    function value=aborted(data)
        value=rejected(data) && data.reference_commit(6)==0 && ...
            abs(data.runtime_frame(8))<1e-12 && abs(data.runtime_frame(9))<1e-12;
    end

    function value=ramp_start(data)
        value=data.runtime_frame(5)==1 && data.runtime_frame(4)==0 && ...
            data.runtime_frame(6)==0;
    end

    function record(name,passed,before,event,after)
        cases(end+1)=struct('name',name,'passed',logical(passed), ...
            'before',brief(before),'event',brief(event),'after',brief(after));
    end
end

function value=brief(data)
value=[];
if ~isempty(data)
    value=struct('state',data.runtime_frame(5),'init_done',data.runtime_frame(4), ...
        'id_init_A',data.runtime_frame(6),'angle_init_enable',data.runtime_frame(7), ...
        'offset_rad',data.runtime_frame(8),'position_mm',data.position_mm, ...
        'continuous_count',data.continuous_count,'history_count',data.history_count, ...
        'feedback_status',data.feedback_status,'reference_version',data.reference_version, ...
        'id_commit_A',data.reference_commit(1),'pwm_permit',data.reference_commit(6), ...
        'reference_valid',data.reference_commit(8),'drive_outputs',data.drive_outputs);
end
end
