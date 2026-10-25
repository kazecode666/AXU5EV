function result=m1b_verify_point_commands(stage)
% M1B独立验收；baseline只采集一次，all不会覆盖修订前证据。
arguments
 stage (1,:) char {mustBeMember(stage,{'baseline','regression','live','aligned-live','all'})}
end
root=fileparts(fileparts(mfilename('fullpath')));runtime=fullfile(root,'.runtime','m1b_20261024');folder=fullfile(root,'docs','reports','m1b_repeat_moves_alignment');
addpath(fullfile(root,'simulink模型'));m='PMLSM_PI_FOC_Float_Baseline';
if strcmp(stage,'baseline')
 output=fullfile(runtime,'baseline');assert(~isfile(fullfile(folder,'baseline_behavior.json')),'M1B:BASELINE_EXISTS','修订前参考不得覆盖。');if ~isfolder(output),mkdir(output);end
 evalin('base','init_PMLSM_PI_FOC_Float_Baseline;');
 evalin('base','Host_Target_mm=1;M1A_StopTime_s=1.2;Host_Traj_Vmax=5;Host_Traj_Amax=50;');
 if ~bdIsLoaded(m),open_system(fullfile(root,'simulink模型',[m '.slx']));end
 if isfile(fullfile(output,'default_1mm_1p2s.mat')),saved=load(fullfile(output,'default_1mm_1p2s.mat'));out=saved.out;parameters=saved.parameters;else
 out=sim(m);parameters=evalin('base','struct(''Kp_ACR'',Kp_ACR,''Ki_ACR'',Ki_ACR,''Kaw_d'',Kaw_d,''Kp_ASR'',Kp_ASR,''Ki_ASR'',Ki_ASR,''Kaw_s'',Kaw_s,''Kp_pos'',Kp_pos,''deadtime'',PMLSM_deadtime_s,''Ts'',Ts_ACR)');
 save(fullfile(output,'default_1mm_1p2s.mat'),'out','parameters','-v7.3');end
 result=struct('version',version,'process',matlabProcessID,'default_x_mm',out.logsout.get('x_mm').Values.Data(end),'parameters',parameters);
 % Two live edits through the real bound Constant, one Run in each condition.
 cases=[0.4,10];events=struct([]);
 for k=1:2
  evalin('base','init_PMLSM_PI_FOC_Float_Baseline;Host_Target_mm=0.2;M1A_StopTime_s=1.4;Host_Traj_Vmax=5;Host_Traj_Amax=50;');
  if isfile(fullfile(output,sprintf('old_live_%d.mat',k))),saved=load(fullfile(output,sprintf('old_live_%d.mat',k)));out=saved.out;submitted=saved.submitted;else
  % Reduce only observation memory for sustained running, never plant step.
  decimate(m,100);set_param(m,'EnablePacing','on','PacingRate','0.25','SimulationCommand','start');
  started=tic;while get_param(m,'SimulationTime')<0.8&&toc(started)<90,drawnow;pause(0.02);end
  assert(strcmp(get_param(m,'SimulationStatus'),'running'),'M1B:LIVE_NOT_RUNNING','旧接口测试必须保持running。');
  submitted=get_param(m,'SimulationTime');bound=[m '/Simple_Host/Host_Target_mm'];set_param(bound,'Value',num2str(cases(k),17));
  while ~strcmp(get_param(m,'SimulationStatus'),'stopped')&&toc(started)<120,drawnow;pause(0.02);end
  assert(strcmp(get_param(m,'SimulationStatus'),'stopped'),'M1B:TIMEOUT','有限基线测试未结束。');
  out=evalin('base','out');save(fullfile(output,sprintf('old_live_%d.mat',k)),'out','submitted');
  end
  target=out.logsout.get('target_mm').Values;ref=out.logsout.get('x_ref_mm').Values;pos=out.logsout.get('x_mm').Values;
  j=find(target.Data>0.2+1e-9,1);assert(~isempty(j),'M1B:TARGET_NOT_RECEIVED','真实入口未收到新值');ri=find(ref.Time>0.7 & abs(ref.Data-0.2)>1e-8,1);time=ref.Time(ri);pii=find(pos.Time<time,1,'last');
  [~,~,duration]=pmlsm_scurve_profile(0,cases(k),5,50,1000,0.1);
  event=struct('requested_mm',cases(k),'call_time_s',submitted,'received_time_s',time,'prior_position_mm',pos.Data(pii),'prior_target_error_mm',abs(pos.Data(pii)-0.2),'reference_before_mm',ref.Data(max(1,ri-1)),'reference_after_mm',ref.Data(ri),'old_global_elapsed_s',time-.05,'new_target_duration_s',duration,'old_clock_past_new_duration',(time-.05)>duration,'correct_new_segment',abs(ref.Data(ri)-0.2)<1e-8);
  if k==1,events=event;else,events(k)=event;end
  set_param([m '/Simple_Host/Host_Target_mm'],'Value','Host_Target_mm');set_param(m,'EnablePacing','off');
 end
 result.old_live=events;result.complete_repeat_moves_supported=all([events.correct_new_segment]);
 fid=fopen(fullfile(folder,'baseline_behavior.json'),'w');fprintf(fid,'%s',jsonencode(result,PrettyPrint=true));fclose(fid);
 fprintf('M1B_BASELINE_CAPTURED repeat_supported=%d\n',result.complete_repeat_moves_supported);return
end
if strcmp(stage,'all')
 result=struct('regression',m1b_verify_point_commands('regression'),'live',m1b_verify_point_commands('live'));return
elseif strcmp(stage,'live')
 result=run_point_live(root,false);
elseif strcmp(stage,'aligned-live')
 result=run_point_live(root,true);
elseif strcmp(stage,'regression')
 result=test_point_helper;result.legacy=m1a_regress_float_baseline(fullfile(folder,'legacy_regression'));
else
 error('M1B:STAGE','未知阶段');
end
fid=fopen(fullfile(folder,['point_' stage '.json']),'w');fprintf(fid,'%s',jsonencode(result,PrettyPrint=true));fclose(fid);
fprintf('M1B_POINT_%s_PASS\n',upper(stage));
end
function decimate(m,value)
b=find_system(m,'LookUnderMasks','all','FollowLinks','off','Type','Block');
for k=1:numel(b),p=get_param(b{k},'PortHandles');for q=p.Outport,if strcmp(get_param(q,'DataLogging'),'on'),set_param(q,'DataLoggingDecimateData','on','DataLoggingDecimation',num2str(value));end;end;end
end

function result=run_point_live(root,alignment)
m='PMLSM_PI_FOC_Float_Baseline';evalin('base','init_PMLSM_PI_FOC_Float_Baseline;Host_Target_mm=0.1;M1A_StopTime_s=20;Host_Traj_Vmax=5;Host_Traj_Amax=50;');
if alignment,evalin('base','Alignment_Enable=1;Init_Start=1;Host_AutoStart_EN=0;');end
if ~bdIsLoaded(m),open_system(fullfile(root,'simulink模型',[m '.slx']));end
set_param(m,'EnablePacing','on','PacingRate','0.5');set_param(m,'SimulationCommand','start');startWall=tic;events=struct([]);bit=0;
% Busy/alignment request is consumed through the same physical Host submit inlet.
while get_param(m,'SimulationTime')<.12 && toc(startWall)<120,drawnow;pause(.01);end
set_param([m '/Simple_Host/Host_Target_mm'],'Value','10');bit=1;set_param([m '/Simple_Host/Host_Move_Request'],'Value','1');
if alignment,targets=[.1 -.1];else,targets=[.2 -.1 -.09];end
for k=1:numel(targets)
 wait_ready(m,1,startWall);assert(strcmp(get_param(m,'SimulationStatus'),'running'));
 set_param([m '/Simple_Host/Host_Target_mm'],'Value',num2str(targets(k),17));bit=1-bit;t0=get_param(m,'SimulationTime');set_param([m '/Simple_Host/Host_Move_Request'],'Value',num2str(bit));
 event=struct('target_mm',targets(k),'submit_sim_s',t0,'running',true,'request_bit',bit);if k==1,events=event;else,events(k)=event;end
 wait_ready(m,0,startWall);wait_ready(m,1,startWall);
 fprintf('M1B_LIVE_TARGET_DONE %.6g at %.9g\n',targets(k),get_param(m,'SimulationTime'));
end
% Draft edit alone does not submit. Repeat is ACK; nonfinite target is rejected.
set_param([m '/Simple_Host/Host_Target_mm'],'Value','99');advance(m,.02,startWall);
wait_ready(m,1,startWall);set_param([m '/Simple_Host/Host_Target_mm'],'Value',num2str(targets(end),17));bit=1-bit;repeatTime=get_param(m,'SimulationTime');set_param([m '/Simple_Host/Host_Move_Request'],'Value',num2str(bit));advance(m,.02,startWall);
set_param([m '/Simple_Host/Host_Target_mm'],'Value','NaN');bit=1-bit;set_param([m '/Simple_Host/Host_Move_Request'],'Value',num2str(bit));advance(m,.02,startWall);
set_param(m,'SimulationCommand','pause');while ~strcmp(get_param(m,'SimulationStatus'),'paused')&&toc(startWall)<600,drawnow;pause(.01);end;assert(strcmp(get_param(m,'SimulationStatus'),'paused'));pausedTime=get_param(m,'SimulationTime');pause(.05);assert(get_param(m,'SimulationTime')==pausedTime);set_param(m,'SimulationCommand','continue');advance(m,.02,startWall);
finishTime=get_param(m,'SimulationTime');assert(finishTime>events(end).submit_sim_s);set_param(m,'SimulationCommand','stop');
out=evalin('base','out');folder=fullfile(root,'.runtime','m1b_20261024');if alignment,name='aligned_live';else,name='point_live';end;save(fullfile(folder,[name '.mat']),'out','events','finishTime','-v7.3');
accepted=out.logsout.get('accepted_count').Values;expected=numel(targets)+double(~alignment);assert(max(accepted.Data)==expected);rejected=out.logsout.get('rejected_count').Values;status=out.logsout.get('command_status').Values;rd=out.logsout.get('move_ready').Values;jr=find(status.Time>=repeatTime & (status.Data==5|status.Data==3),1);assert(~isempty(jr));repeatStatus=status.Data(jr);assert((repeatStatus==5&&rd.Data(jr)==1)||(repeatStatus==3&&rd.Data(jr)==0));assert(max(rejected.Data)==2+double(repeatStatus==3));assert(any(status.Data==4));ta=out.logsout.get('target_accepted_mm').Values;assert(~any(ta.Data==10)&&~any(ta.Data==99));
latencies=zeros(size(events));acceptedTimes=[];
for k=1:numel(events)
 v=out.logsout.get('target_accepted_mm').Values;j=find(v.Time>=events(k).submit_sim_s & abs(v.Data-targets(k))<1e-10,1);assert(~isempty(j));latencies(k)=v.Time(j)-events(k).submit_sim_s;acceptedTimes(k)=v.Time(j);assert(latencies(k)>=-1e-9&&latencies(k)<=1e-4+1e-9);events(k).accepted_sim_s=v.Time(j);
 ss=out.logsout.get('segment_start_mm').Values;st=out.logsout.get('segment_start_s').Values;rd=out.logsout.get('move_ready').Values;dn=out.logsout.get('trajectory_done').Values;pos=out.logsout.get('x_mm').Values;
 events(k).segment_start_mm=ss.Data(j);events(k).segment_start_s=st.Data(j);jdone=find(dn.Time>=v.Time(j)&dn.Data==1,1);jready=find(rd.Time>=v.Time(j)&rd.Data==1,1);assert(~isempty(jdone)&&~isempty(jready));events(k).trajectory_done_s=dn.Time(jdone);events(k).ready_s=rd.Time(jready);events(k).error_at_ready_mm=abs(interp1(pos.Time,pos.Data,rd.Time(jready))-targets(k));assert(events(k).error_at_ready_mm<=.02+1e-9);
end
for n={'x_mm','x_ref_mm','segment_start_mm','segment_start_s','target_accepted_mm','move_ready'},v=out.logsout.get(n{1}).Values;assert(all(isfinite(v.Data(:))));end
% Formula check uses exactly logged segment time, not global simulation time.
xr=out.logsout.get('x_ref_mm').Values;ss=out.logsout.get('segment_start_mm').Values;tt=out.logsout.get('segment_start_s').Values;ta=out.logsout.get('target_accepted_mm').Values;
assert(isequal(xr.Time,ss.Time)&&isequal(xr.Time,tt.Time)&&isequal(xr.Time,ta.Time));maximum=0;
for j=1:10:numel(xr.Time),expected=ss.Data(j)+pmlsm_scurve_profile(xr.Time(j)-tt.Data(j),ta.Data(j)-ss.Data(j),5,50,1000,.1);maximum=max(maximum,abs(xr.Data(j)-expected));end
assert(maximum<1e-10);
result=struct('pass',true,'single_start_count',1,'process',matlabProcessID,'events',events,'accepted_times',acceptedTimes,'max_latency_s',max(latencies),'max_formula_error_mm',maximum,'finish_sim_s',finishTime,'UI_mouse_clicked',false,'draft_edit_only_ignored',true,'busy_or_alignment_consumed',true,'repeat_ack',repeatStatus==5,'repeat_at_event_status',repeatStatus,'repeat_at_event_ready',rd.Data(jr),'NaN_rejected',true,'pause_continue',true,'ready_observer','saved Host display-only DataStore at100us');
csvName='commands.csv';if alignment,csvName='aligned_commands.csv';end;writetable(struct2table(events),fullfile(root,'docs/reports/m1b_repeat_moves_alignment',csvName));
set_param([m '/Simple_Host/Host_Target_mm'],'Value','Host_Target_mm');set_param([m '/Simple_Host/Host_Move_Request'],'Value','Host_Move_Request');set_param(m,'EnablePacing','off');
end
function advance(m,delta,startWall)
t=get_param(m,'SimulationTime');while get_param(m,'SimulationTime')<t+delta&&toc(startWall)<600,drawnow;pause(.01);assert(strcmp(get_param(m,'SimulationStatus'),'running'));end
end
function wait_ready(m,wanted,startWall)
path=[m '/Simple_Host/Move_Ready_Live_State'];
while toc(startWall)<600
 drawnow;pause(.01);assert(strcmp(get_param(m,'SimulationStatus'),'running'),'M1B:LIVE_STOPPED','等待Ready时仿真提前停止。');
 r=get_param(path,'RuntimeObject');value=double(r.Dwork(1).Data);if value==wanted,return;end
end
error('M1B:LIVE_TIMEOUT','Ready等待超过有限600s，未宣称通过。');
end

function result=test_point_helper
cfg=[1e-4 .01 .05 5 50 1000 .1 .02 5 1];s=zeros(1,22);x=0;req=0;target=.1;events=[];phase=0;busySent=false;
for k=0:40000
 t=k*cfg(1);
 if t>=.12 && ~busySent,target=10;req=1;busySent=true;end
 if s(21)==1 && phase<5
  values=[.2 .2 NaN -.1 -.09];target=values(phase+1);req=1-req;phase=phase+1;
 end
 before=s;[s,ref,o]=pmlsm_point_move_step(s,t,x,target,req,1,1,0,0,1,cfg);x=ref;
 if s(11)>before(11),assert(abs(ref-before(4))<1e-12);events(end+1,:)=[t s(4) s(3) s(5) s(11)];end
 if busySent&&phase==0,expected=pmlsm_scurve_profile(t-.05,.1,5,50,1000,.1);assert(abs(ref-expected)<1e-12);end
end
assert(phase==5 && s(11)==4 && s(12)==2 && abs(ref+.09)<1e-12);
assert(size(events,1)==4);assert(s(21)==1);assert(s(10)==2);
% Repeated request bit does not resubmit; invalid draft never reaches reference.
assert(all(isfinite(events(:))));
[xx,v,~,~,~]=pmlsm_scurve_profile(.1,.2,5,50,1000,.1);assert(isfinite(xx)&&isfinite(v)); %#ok<ASGLU>
limits=[];for displacement=[.1 .2 -.3 .01],dt=1e-4;[~,~,T]=pmlsm_scurve_profile(0,displacement,5,50,1000,.1);tv=(0:dt:T+dt)';vel=zeros(size(tv));for j=1:numel(tv),[~,vel(j)]=pmlsm_scurve_profile(tv(j),displacement,5,50,1000,.1);end;acc=diff(vel)/dt;jerk=diff(acc)/dt;mv=max(abs(vel));ma=max(abs(acc));mj=max(abs(jerk));assert(mv<=5+1e-8&&ma<=50+1e-3&&mj<=1000+.1);limits(end+1,:)=[displacement mv ma mj];end
result=struct('limits',limits,'pass',true,'accepted',s(11),'rejected',s(12),'repeat_ack',true,'busy_consumed',true,'invalid_consumed',true,'absolute_end_mm',ref,'events',events);
fid=fopen('D:/Project/FPGA_XC7A200T/docs/reports/m1b_repeat_moves_alignment/helper_acceptance.json','w');fprintf(fid,'%s',jsonencode(result,PrettyPrint=true));fclose(fid);disp('M1B_HELPER_PASS');
end
