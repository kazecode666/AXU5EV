function result=ax01b_run_closedloop(mode,scene)
% 通过现有面板绑定的常数入口下发命令；不写下游轨迹或电流参考。
if nargin<1,mode='c_fixed';end
if nargin<2,scene='continuous';end
m=ax01b_prepare_hybrid(mode);
root=fileparts(fileparts(mfilename('fullpath')));
Simulink.fileGenControl('set','CacheFolder',fullfile(root,'.runtime','ax01b', ...
    ['cache_' mode '_' scene]),'createDir',true);
in=Simulink.SimulationInput(m);
in=in.setBlockParameter(block(m,1981),'Value','1');
stopTime=1.2;
if strcmp(scene,'continuous'),stopTime=4;end
if strcmp(scene,'alignment'),stopTime=4.9;in=in.setBlockParameter(block(m,2068),'Value','1');end
in=in.setModelParameter('StopTime',num2str(stopTime));
s=simulation(in);initialize(s);
cleanup=onCleanup(@()finish(s));
events={};
switch scene
 case 'point'
    step(s,PauseTime=stopTime);
 case 'continuous'
    advance(.25,'draft only');setBlockParameter(s,block(m,1981),'Value','0.9');
    advance(.30,'busy send');setBlockParameter(s,block(m,2063),'Value','1');
    waitReady();advance(s.Time+.001,'first new target');
    setBlockParameter(s,block(m,1981),'Value','0.2');
    setBlockParameter(s,block(m,2063),'Value','0');
    step(s,PauseTime=s.Time+.01);
    waitReady();advance(s.Time+.001,'second new target');
    setBlockParameter(s,block(m,1981),'Value','-0.1');
    setBlockParameter(s,block(m,2063),'Value','1');
    step(s,PauseTime=s.Time+.01);waitReady();
    advance(s.Time+.001,'repeat acknowledgement');
    setBlockParameter(s,block(m,2063),'Value','0');
    step(s,PauseTime=s.Time+.02);
 case 'alignment'
    advance(.002,'manual Start');setBlockParameter(s,block(m,2129),'Value','1');
    advance(.003,'release Start');setBlockParameter(s,block(m,2129),'Value','0');
    advance(4.35,'aligned move');setBlockParameter(s,block(m,1981),'Value','1');
    setBlockParameter(s,block(m,2063),'Value','1');
    step(s,PauseTime=stopTime);
 case 'stop_reset'
    advance(.15,'PWM off');setBlockParameter(s,block(m,1988),'Value','0');
    advance(.20,'PI reset');setBlockParameter(s,block(m,1989),'Value','1');
    advance(.23,'PI reset release');setBlockParameter(s,block(m,1989),'Value','0');
    advance(.26,'PWM reenable');setBlockParameter(s,block(m,1988),'Value','1');
    advance(.35,'Init reset only');setBlockParameter(s,block(m,2130),'Value','1');
    advance(.37,'Init reset release');setBlockParameter(s,block(m,2130),'Value','0');
    advance(.45,'existing travel fault');setBlockParameter(s,block(m,2068),'Value','1');
    setBlockParameter(s,block(m,2131),'Value','1');
    advance(.50,'manual fault clear');setBlockParameter(s,block(m,2131),'Value','0');
    step(s,PauseTime=stopTime);
 otherwise
    error('AX01B:SCENE','Unknown normal scene %s.',scene);
end
finish(s);out=s.SimulationOutput;
actualStop=out.r5_commit.Time(end);
commit=matrix(out.r5_commit);
position=out.logsout.get('x_mm').Values;
result=struct('mode',mode,'scene',scene,'stop_s',actualStop, ...
    'final_x_mm',double(position.Data(end)),'target_mm',commit(end,24), ...
    'accepted',commit(end,32),'rejected',commit(end,33), ...
    'ready',commit(end,31),'alignment_done',commit(end,4));
save(fullfile(root,'.runtime','ax01b',[mode '_' scene '.mat']),'out','events','result','-v7.3');
disp(result);

function waitReady()
    while true
        if strcmp(mode,'model_fixed'),sid=2367;else,sid=2368;end
        r=get_param(block(m,sid),'RuntimeObject');
        v=reshape(r.OutputPort(1).Data,1,[]);
        if v(31)>0,return;end
        assert(s.Time<stopTime-.1,'AX01B:READY','No Ready before this normal scene ended.');
        advance(s.Time+.05,'wait Ready');
    end
end

function advance(t,label)
    step(s,PauseTime=t);
    if strcmp(mode,'model_fixed'),sid=2367;else,sid=2368;end
    r=get_param(block(m,sid),'RuntimeObject');
    v=reshape(r.OutputPort(1).Data,1,[]);
    events{end+1}=struct('t',s.Time,'label',label,'target',v(24), ...
        'ready',v(31),'accepted',v(32),'status',v(27));
    fprintf('AX01B_EVENT %s %s t=%.6f target=%.6g ready=%g accepted=%g status=%g\n', ...
        mode,label,s.Time,v(24),v(31),v(32),v(27));
end
end
function p=block(m,sid)
p=Simulink.ID.getFullName([m ':' num2str(sid)]);
end
function finish(s)
if ~strcmp(s.Status,'inactive'),terminate(s);end
end
function d=matrix(ts)
d=ts.Data;
if size(d,1)~=numel(ts.Time),d=reshape(d,[],numel(ts.Time))';end
end
