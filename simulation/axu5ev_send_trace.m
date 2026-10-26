function events=axu5ev_send_trace(out)
% 用实际100 us快照/提交逐拍复算Host；区分未采集、未Ready与不允许。
%% 原参数与实际记录
names={'Ts_ACR','Ts_POS','Host_Start_s','Host_Traj_Vmax','Host_Traj_Amax', ...
    'Host_Traj_Jmax','Host_Speed_Ramp_s','Pos_deadband','Host_Ready_Ticks','Host_AutoStart_EN'};
cfg=zeros(1,numel(names));
for k=1:numel(names),cfg(k)=evalin('base',names{k});end
u=axu5ev_matrix(out.r5_snapshot);c=axu5ev_matrix(out.r5_commit);
t=out.r5_commit.Time;
assert(isequal(size(u,1),size(c,1))&&max(abs(out.r5_snapshot.Time-t))<1e-12);
s=zeros(1,22);rows=zeros(0,18);
%% 发送变化前后同拍检查；probe只读副本，不改变控制状态
for k=1:numel(t)
    mode=u(k,6)~=0&&u(k,7)~=0&&u(k,4)==0;
    pwm=u(k,8);reset=u(k,9);
    if u(k,10)~=0,pwm=u(k,13);reset=u(k,14);end
    allowed=mode&&pwm~=0&&reset==0&&c(k,10)~=0;
    changed=k>1&&~isequaln(u(k,11),u(k-1,11));
    software_t=(k-1)*cfg(1);
    if changed
        [probe,~,~]=pmlsm_point_move_step(s,software_t,u(k,20),u(k,1), ...
            s(2),mode,pwm,reset,u(k,16),c(k,10),cfg);
    end
    [s,~,obs]=pmlsm_point_move_step(s,software_t,u(k,20),u(k,1), ...
        u(k,11),mode,pwm,reset,u(k,16),c(k,10),cfg);
    assert(max(abs(obs-c(k,24:36)))<1e-10, ...
        'AXU5EV:SEND_TRACE','Host复算与实际提交不一致，帧%d。',k);
    if changed
        assert(abs(c(k,35)-software_t)<1e-12,'AXU5EV:SEND_NOT_SEEN','发送变化未被当拍采集。');
        rows(end+1,:)=[t(k) u(k,11) u(k,1) c(k-1,31) probe(21) allowed ...
            probe(6) c(k,31) c(k,25) c(k,27) c(k,32:35) ...
            u(k,20)-probe(4) mod(k-1,round(cfg(2)/cfg(1)))==round(cfg(2)/cfg(1))-1 ...
            c(k,24) c(k,36)]; %#ok<AGROW>
    end
end
events=array2table(rows,'VariableNames',{'sample_s','send_bit','draft_mm', ...
    'Ready_previous_frame','Ready_at_decision','allowed_at_decision', ...
    'Busy_at_decision','Ready_after','Busy_after','status','accepted','rejected', ...
    'segment_id','received_s','position_error_before_mm','position_event', ...
    'accepted_target_mm','interrupted'});
end
