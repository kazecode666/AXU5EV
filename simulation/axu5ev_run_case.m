function result=axu5ev_run_case(mode,scene)
% 先运行START_HERE；本函数只复验指定工况，不恢复默认参数。
%% 后端与面板绑定入口
if nargin<1,mode=evalin('base','AXU5EV_Backend');end
if nargin<2,scene='default';end
m=axu5ev_prepare(mode);root=fileparts(fileparts(mfilename('fullpath')));
in=Simulink.SimulationInput(m);
events={};
if strcmp(scene,'default')
    out=sim(in); % 与普通Run相同参数；不覆盖10mm目标或5s停止时间
else
    if strcmp(scene,'continuous'),in=in.setModelParameter('StopTime','8');end
    if strcmp(scene,'reset_release')
        in=in.setBlockParameter(block(1989),'Value','1');
    end
    if strcmp(scene,'restart_short'),in=in.setModelParameter('StopTime','0.3');end
    s=simulation(in);initialize(s);cleanup=onCleanup(@()finish(s));
    switch scene
        case 'continuous'
            advance(.2);setBlockParameter(s,block(1981),'Value','11');
            advance(.25);setBlockParameter(s,block(2063),'Value','1');
            advance(.26);waitReady(); % Busy请求拒绝，不排队
            setBlockParameter(s,block(1981),'Value','0');
            setBlockParameter(s,block(2063),'Value','0');advance(s.Time+.01);
            waitReady();setBlockParameter(s,block(1981),'Value','-2');
            setBlockParameter(s,block(2063),'Value','1');advance(s.Time+.01);
            waitReady();
        case 'reset_release'
            advance(.2);setBlockParameter(s,block(1989),'Value','0');advance(.6);
        case 'reset_moving'
            advance(.3);setBlockParameter(s,block(1989),'Value','1');
            advance(.35);setBlockParameter(s,block(1989),'Value','0');advance(1);
        case 'restart_short'
            advance(.3);
        otherwise
            error('AXU5EV:CASE','未知工况%s。',scene);
    end
    finish(s);out=s.SimulationOutput;
end
%% 必要的行为检查与保存
result=axu5ev_run_summary(out);result.mode=mode;result.scene=scene;
assert(max(abs([result.min_x_mm result.max_x_mm]))<12,'AXU5EV:TRAVEL','默认点位数量级异常。');
if strcmp(scene,'default')||strcmp(scene,'continuous')
    assert(result.Ready==1&&result.Busy==0, ...
        'AXU5EV:READY','未恢复原到位条件。');
end
if strcmp(scene,'continuous')
    assert(result.accepted==3&&result.rejected==1&&result.segment_id==3&&result.accepted_target_mm==-2);
end
if strcmp(scene,'reset_release')
    assert(max(abs([result.min_x_mm result.max_x_mm]))<.1,'AXU5EV:RESET_RELEASE','初始复位释放后出现异常运动。');
end
if strcmp(scene,'restart_short')
    x=out.logsout.get('x_mm').Values;
    assert(x.Data(1)==0&&result.accepted==1&&result.segment_id==1);
end
axu5ev_verify_run(out,strcmp(mode,'c_rtl')); % 0.02mm窗口核对原位置事件，非任意停止时刻
save(fullfile(root,'.runtime','issue8',[mode '_' scene '.mat']),'out','result','events','-v7.3');
disp(result);

function p=block(sid)
    p=Simulink.ID.getFullName([m ':' num2str(sid)]);
end
function advance(t)
    step(s,PauseTime=t);
    if strcmp(mode,'model_fixed'),sid=2367;else,sid=2368;end
    r=get_param(block(sid),'RuntimeObject');c=reshape(r.OutputPort(1).Data,1,[]);
    events{end+1}=struct('t',s.Time,'target',c(24),'Ready',c(31), ...
        'status',c(27),'accepted',c(32),'rejected',c(33),'segment',c(34));
end
function waitReady()
    while true
        if strcmp(mode,'model_fixed'),sid=2367;else,sid=2368;end
        r=get_param(block(sid),'RuntimeObject');c=reshape(r.OutputPort(1).Data,1,[]);
        if c(31)>0,return;end
        assert(s.Time<7.8,'AXU5EV:READY_TIMEOUT','8秒内未恢复Ready。');
        advance(s.Time+.05);
    end
end
end
function finish(s)
if ~strcmp(s.Status,'inactive'),terminate(s);end
end
