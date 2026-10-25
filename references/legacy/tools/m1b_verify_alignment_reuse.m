function result=m1b_verify_alignment_reuse(stage)
% 原MIL chart逐拍对照；闭环物理结果单独列出。
if nargin==0,stage='all';end
root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'simulink模型'));evalin('base','init_PMLSM_PI_FOC_Float_Baseline;');
source='PMLSM_ControlCore_Block/PMLSM_ControlCore/Angle_Init';m='PMLSM_PI_FOC_Float_Baseline';target=[m '/Alignment_Task_10kHz/Enabled_Original_MIL/Angle_Init'];
load_system(fullfile(root,'simulink模型/PMLSM_ControlCore_Block.slx'));if ~bdIsLoaded(m),open_system(fullfile(root,'simulink模型',[m '.slx']));end
r=sfroot;a=r.find('-isa','Stateflow.Chart','Path',source);b=r.find('-isa','Stateflow.Chart','Path',target);assert(isequal(labels(a),labels(b)),'M1B:CHART_CHANGED','源状态动作或转移优先级变化。');
folder=fullfile(root,'docs/reports/m1b_repeat_moves_alignment');cases={'normal','no_start','reset','fault','reset_after_done'};rows=struct([]);
for k=1:numel(cases)
 old=chart_case(source,cases{k},k,0);fresh=chart_case(target,cases{k},k,1);maximum=0;assert(numel(old{1}.Time)==70001,'M1B:CHART_CAPTURE','逐拍对照必须保留全部70001点，不可只保留尾部。');
 for j=1:6,assert(isequal(old{j}.Time,fresh{j}.Time));err=max(abs(double(old{j}.Data)-double(fresh{j}.Data)));assert(err<1e-12);maximum=max(maximum,err);end
 if strcmp(cases{k},'reset_after_done'),mask=old{1}.Time>4.9 & old{1}.Time<5;assert(all(old{1}.Data(mask)==0)&&all(abs(old{5}.Data(mask))>0.1));end
 row=struct('case',cases{k},'samples',numel(old{1}.Time),'max_error',maximum,'state_time_exact',true,'done_seen',any(old{1}.Data==1));if k==1,rows=row;else,rows(k)=row;end
 fprintf('M1B_CHART_PAIR_PASS %s\n',cases{k});
end
result=struct('chart_pass',true,'source_sid','128','cases',rows,'parameters',struct('Ramp_Ticks',10000,'Hold_Ticks',30000,'Release_Ticks',2000,'Id_Target_A',.5),'UI_mouse_clicked',false);
if strcmp(stage,'chart'),f=fopen(fullfile(folder,'alignment_chart_acceptance.json'),'w');fprintf(f,'%s',jsonencode(result,PrettyPrint=true));fclose(f);disp('M1B_ALIGNMENT_CHART_FULL_PASS');return;end
% Actual DSP saved chart is a cross-check, never the copied implementation.
load_system(fullfile(root,'simulink模型/PMSLM_Close_Loop_MBDL4.slx'));d=r.find('-isa','Stateflow.Chart','Path','PMSLM_Close_Loop_MBDL4/FOC_3Close_Loop_Control/Angle_Init');result.DSP_states={d.find('-isa','Stateflow.State').Name};
% Closed-loop nominal source scene has zero physical position/angle. No invented offset.
evalin('base','init_PMLSM_PI_FOC_Float_Baseline;Alignment_Enable=1;Init_Start=1;Host_AutoStart_EN=0;M1A_StopTime_s=4.5;');out=sim(m);v=out.logsout.get('Init_State_Num').Values;transitionTimes=zeros(1,4);for s=1:4,j=find(v.Data==s,1);assert(~isempty(j));transitionTimes(s)=v.Time(j);end
assert(max(abs(diff(transitionTimes)-[1 3 .2]))<1e-12);
id=out.logsout.get('id_controller').Values;iq=out.logsout.get('iq_controller').Values;ta=out.logsout.get('theta_control_rad').Values;tb=out.logsout.get('theta_true_rad').Values;
% Uniform100us snapshot for physical comparisons, no event shifts.
[~,ii,jj]=intersect(round(ta.Time*1e9),round(tb.Time*1e9));phase=atan2(sin(ta.Data(ii)-tb.Data(jj)),cos(ta.Data(ii)-tb.Data(jj)));
mask=id.Time>1.2 & id.Time<3.9;maxIdError=max(abs(id.Data(mask)-.5));maxIq=max(abs(iq.Data(iq.Time>1.2 & iq.Time<3.9)));angleError=max(abs(phase));
result.integration=struct('states_seen',unique(v.Data)','transition_times_s',transitionTimes,'holding_id_error_A',maxIdError,'holding_abs_iq_A',maxIq,'max_periodic_angle_error_rad',angleError,'physical_pass',maxIdError<.05 && maxIq<.05 && angleError<.02,'source_scene','MIL nominal zero position/true angle; source static-current branch also explicitly freezes zero','nonzero_unknown_offset_proven',false);
save(fullfile(root,'.runtime/m1b_20261024/alignment_nominal.mat'),'out','-v7.3');
assert(result.integration.physical_pass,'M1B:ALIGNMENT_PHYSICAL','名义物理工况不满足已冻结判据，不能只依据DONE宣称成功。');
fid=fopen(fullfile(folder,'alignment_acceptance.json'),'w');fprintf(fid,'%s',jsonencode(result,PrettyPrint=true));fclose(fid);fprintf('M1B_ALIGNMENT_PASS\n');
result.post_alignment_moves=m1b_verify_point_commands('aligned-live');
end
function data=chart_case(path,kind,index,which)
name=sprintf('M1B_Chart_%d_%d_%d',matlabProcessID,index,which);new_system(name);cleanup=onCleanup(@()close_system(name,0));set_param(name,'SolverType','Fixed-step','Solver','FixedStepDiscrete','FixedStep','0.0001','StopTime','7','ReturnWorkspaceOutputs','on');
block=add_block(path,[name '/Chart']);input=struct;input.start=[0 0;.1 1;7 1];input.reset=[0 0;7 0];input.fault=[0 0;7 0];input.x=[0 4;7 4];
if strcmp(kind,'no_start'),input.start=[0 0;7 0];end
if strcmp(kind,'reset'),input.reset=[0 0;2 1;2.01 0;7 0];end
if strcmp(kind,'fault'),input.fault=[0 0;2 1;2.01 0;7 0];end
if strcmp(kind,'reset_after_done'),input.reset=[0 0;4.8 1;4.81 0;7 0];end
fields={'start','reset','fault','x'};
for j=1:4,v=input.(fields{j});var=sprintf('M1B_ChartInput_%d',j);assignin('base',var,timeseries(v(:,2),v(:,1)));s=add_block('built-in/FromWorkspace',[name '/' fields{j}],'VariableName',var,'SampleTime','0.0001','Interpolate','off','OutputAfterFinalValue','Holding final value');wire(name,s,1,block,j);end
for j=1:6,s=add_block('built-in/ToWorkspace',sprintf('%s/Out%d',name,j),'VariableName',sprintf('y%d',j),'SaveFormat','Timeseries','MaxDataPoints','inf');wire(name,block,j,s,1);end
out=sim(name);data=cell(1,6);for j=1:6,data{j}=out.get(sprintf('y%d',j));end
end
function s=labels(c)
a=c.find('-isa','Stateflow.State');s.states=sort({a.LabelString});a=c.find('-isa','Stateflow.Transition');v=cell(1,numel(a));for k=1:numel(a),if isempty(a(k).Source),source='default';else,source=a(k).Source.Name;end;v{k}=sprintf('%s->%s:%d:%s',source,a(k).Destination.Name,a(k).ExecutionOrder,a(k).LabelString);end;s.transitions=sort(v);
end
function wire(m,a,ai,b,bi),p=get_param(a,'PortHandles');q=get_param(b,'PortHandles');add_line(m,p.Outport(ai),q.Inport(bi));end
