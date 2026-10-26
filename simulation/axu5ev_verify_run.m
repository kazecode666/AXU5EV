function summary=axu5ev_verify_run(out,rtl)
% 核对本次变更涉及的反馈字段、50us应用及可选RTL帧事件。
if nargin<2,rtl=false;end
%% 位置/速度快照必须来自同拍对象反馈
u=axu5ev_matrix(out.r5_snapshot);t=out.r5_snapshot.Time;
x=out.logsout.get('x_mm').Values;v=out.logsout.get('v_mmps').Values;
% 回到实际1us对象网格，避免同一端点的浮点时间差被插值判成越界。
x_same=interp1(round(x.Time/1e-6),double(x.Data(:)),round(t/1e-6),'previous');
v_same=interp1(round(v.Time/1e-6),double(v.Data(:)),round(t/1e-6),'previous');
assert(all(isfinite(x_same))&&all(isfinite(v_same)));
summary=struct('frames',numel(t),'position_snapshot_error_mm', ...
 max(abs(u(:,20)-x_same)), ...
 'speed_snapshot_error_mmps',max(abs(u(:,15)-v_same)));
assert(summary.position_snapshot_error_mm<1e-9&&summary.speed_snapshot_error_mmps<1e-9);
%% Ready使用连续5个位置事件；事件之间机械仍演化
c=axu5ev_matrix(out.r5_commit);summary.ready_window_error_mm=NaN;
if c(end,31)>0
    ix=find(mod(round(out.r5_commit.Time/1e-4),100)==99);
    assert(numel(ix)>=5);ix=ix(end-4:end);
    summary.ready_window_error_mm=max(abs(u(ix,20)-c(ix,24)));
    assert(summary.ready_window_error_mm<=.02+1e-9&&all(c(ix,30)>0));
end
%% 本帧duty仅在+50us应用一次
d=axu5ev_matrix(out.duty_result);summary.application_error_s=0;summary.duty_word_error=0;
names={'duty_u_applied','duty_v_applied','duty_w_applied'};
for k=1:3
    a=out.logsout.get(names{k}).Values;n=numel(a.Time);
    summary.application_error_s=max(summary.application_error_s,max(abs(a.Time-out.duty_result.Time(1:n)-50e-6)));
    summary.duty_word_error=max(summary.duty_word_error,max(abs(double(a.Data(:))-d(1:n,k)))*2^30);
end
assert(summary.application_error_s<1e-12&&summary.duty_word_error==0);
%% 真实RTL只声称实际执行的帧数
if rtl
    e=axu5ev_matrix(out.rtl_frame_events);
    assert(all(e(:,1)==(1:size(e,1))')&&all(e(:,2)==315)&&all(e(:,3)==1)&&all(e(:,4)==0));
    summary.rtl_frames=size(e,1);summary.capture_edge=315;summary.hold_errors=0;
end
disp(summary);
end
