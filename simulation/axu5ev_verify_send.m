function events=axu5ev_verify_send(mode)
% 只验Issue8发送/到位边界；通过Dashboard绑定的变量调参，不替代鼠标实测。
%% 当前入口与实际绑定
if nargin<1,mode='model_fixed';end
assert(any(strcmp(mode,{'model_fixed','c_fixed'})), ...
    'AXU5EV:SEND_MODE','本复验只用于model_fixed或c_fixed。');
m=axu5ev_prepare(mode);root=fileparts(fileparts(mfilename('fullpath')));
send=get_param(block(2098),'Binding');draft=get_param(block(2028),'Binding');
assert(strcmp(send.VarName,'Host_Move_Request')&&strcmp(draft.VarName,'Host_Target_mm'));
assert(evalin('base','Host_Target_mm==10&&Host_Move_Request==0'), ...
    'AXU5EV:SEND_INIT','先用START_HERE加载默认10 mm和Send=0。');
in=Simulink.SimulationInput(m);in=in.setModelParameter('StopTime','8');
s=simulation(in);initialize(s);cleanup=onCleanup(@()finish(s));
%% Ready回落拍拒绝；之后反向翻转才接受，拒绝不排队
advance(1.97985);c=commit();assert(c(31)==1&&c(25)==0);
setVariable(s,draft.VarName,0);setVariable(s,send.VarName,1);
advance(1.9801);c=commit();assert(c(27)==3&&c(33)==1&&c(32)==1&&c(34)==1);
advance(2.09);c=commit();assert(c(31)==1&&c(24)==10&&c(32)==1); % 未自动补发
setVariable(s,send.VarName,0);advance(2.0902);
c=commit();assert(c(27)==2&&c(32)==2&&c(34)==2&&c(24)==0);
advance(2.1);setVariable(s,draft.VarName,11);setVariable(s,send.VarName,1);
advance(2.1002);c=commit();assert(c(27)==3&&c(33)==2&&c(24)==0);
%% 同Run返回、反向、同目标，以及allowed=0拒绝
waitReady();setVariable(s,draft.VarName,-2);setVariable(s,send.VarName,0);
advance(s.Time+.001);c=commit();assert(c(27)==2&&c(32)==3&&c(34)==3&&c(24)==-2);
waitReady();setVariable(s,send.VarName,1);advance(s.Time+.001);
c=commit();assert(c(27)==5&&c(32)==3&&c(33)==2&&c(34)==3);
setVariable(s,'Host_PWM_EN',0);setVariable(s,send.VarName,0);advance(s.Time+.001);
c=commit();assert(c(27)==6&&c(33)==3&&c(32)==3);
setVariable(s,'Host_PWM_EN',1);advance(s.Time+.001);
finish(s);out=s.SimulationOutput;
%% 每次变化都被采集；显示值直接来自同一份实际提交
events=axu5ev_send_trace(out);
assert(height(events)==6&&isequal(events.status',[3 2 3 2 5 6]));
assert(isequal(events.Ready_at_decision',[0 1 0 1 1 0]));
assert(isequal(events.allowed_at_decision',[1 1 1 1 1 0]));
assert(events.Ready_previous_frame(1)==1&&events.position_event(1)==1);
assert(events.Busy_at_decision(1)==0&&events.Busy_at_decision(3)==1);
c=axu5ev_matrix(out.r5_commit);u=axu5ev_matrix(out.r5_snapshot);
receipt=out.logsout.get('command_receipt').Values;
live=out.logsout.get('sampled_send_Ready_Busy').Values;
assert(isequal(receipt.Time,out.r5_commit.Time)&&isequal(live.Time,receipt.Time));
assert(max(abs(axu5ev_matrix(receipt)-c(:,[35 27 32 33 34 24])),[],'all')==0);
assert(max(abs(axu5ev_matrix(live)-[u(:,11) c(:,31) c(:,25)]),[],'all')==0);
folder=fullfile(root,'verification','issue8');
writetable(events,fullfile(folder,[mode '_send_events.csv']));
work=fullfile(root,'.runtime','issue8');if ~isfolder(work),mkdir(work);end
save(fullfile(work,[mode '_send.mat']),'out','events','-v7.3');
disp(events);

function p=block(sid)
    p=Simulink.ID.getFullName([m ':' num2str(sid)]);
end
function c=commit()
    if strcmp(mode,'model_fixed'),sid=2367;else,sid=2368;end
    r=get_param(block(sid),'RuntimeObject');c=reshape(r.OutputPort(1).Data,1,[]);
end
function advance(t)
    step(s,PauseTime=t);
end
function waitReady()
    while true
        c=commit();
        if c(31)>0&&mod(round(s.Time/1e-4),100)<95,return;end
        assert(s.Time<7.8,'AXU5EV:SEND_TIMEOUT','8 s内未到位。');
        advance(s.Time+.005);
    end
end
end
function finish(s)
if ~strcmp(s.Status,'inactive'),terminate(s);end
end
