function result=axu5ev_closeout_run(mode)
% Issue13收尾：两后端使用原10→0→−2 mm场景的同一命令时刻。
%% 当前参数和后端；不覆盖用户初始化
assert(any(strcmp(mode,{'c_fixed','c_rtl'})));
assert(evalin('base','Host_Target_mm==10&&Host_Move_Request==0&&Host_AutoStart_EN==1'));
m=axu5ev_prepare(mode);root=fileparts(fileparts(mfilename('fullpath')));
work=fullfile(root,'.runtime','ax01c');if ~isfolder(work),mkdir(work);end
% 保留既有continuous顺序，统一到本轮C记录的实际采样时刻。
commands=[2.0915 0 1;2.1016 11 0;5.2999 -2 1];stop_s=6.4536;
in=Simulink.SimulationInput(m);in=in.setModelParameter('StopTime',num2str(stop_s,17));
s=simulation(in);initialize(s);cleanup=onCleanup(@()finish(s));wall=tic;
%% 同一次Run：自动10 mm、返回0、反向−2 mm
try
    for k=1:size(commands,1)
        advance(commands(k,1)-5e-6); % 留5个对象步，确保下一100 us采样拍采用命令
        setBlockParameter(s,block(1981),'Value',num2str(commands(k,2),17));
        setBlockParameter(s,block(2063),'Value',num2str(commands(k,3),17));
    end
    advance(stop_s);finish(s);out=s.SimulationOutput;
catch err
    finish(s);out=s.SimulationOutput;
    save(fullfile(work,[mode '_partial.mat']),'out','commands','err','-v7.3');
    rethrow(err);
end
%% 保留实际记录，再核对原到位规则、命令采样和50 us应用
result=axu5ev_run_summary(out);result.mode=mode;result.wall_s=toc(wall);
save(fullfile(work,[mode '_continuous.mat']),'out','commands','result','-v7.3');
assert(result.accepted==3&&result.rejected==1&&result.segment_id==3 ...
    &&result.accepted_target_mm==-2&&result.Busy==0);
% Ready在到位后仍可回落；每段必须确实出现原Ready，不能强制末拍为1。
c=axu5ev_matrix(out.r5_commit);
for seg=1:3,assert(any(c(:,34)==seg&c(:,31)>0));end
events=axu5ev_send_trace(out);
assert(height(events)==3&&max(abs(events.sample_s-commands(:,1)))<1e-12);
assert(isequal(events.status',[2 3 2]));
checks=axu5ev_verify_run(out,strcmp(mode,'c_rtl'));
save(fullfile(work,[mode '_continuous.mat']),'events','checks','-append');
disp(result);disp(events);

function p=block(sid)
    p=Simulink.ID.getFullName([m ':' num2str(sid)]);
end
function advance(t)
    while s.Time<t-1e-12
        step(s,PauseTime=min(t,s.Time+.25));
        r=get_param(block(2368),'RuntimeObject');c=reshape(r.OutputPort(1).Data,1,[]);
        message=sprintf('%s t=%.6f wall=%.1fs target=%g Ready=%g accepted=%g rejected=%g', ...
            mode,s.Time,toc(wall),c(24),c(31),c(32),c(33));
        fprintf('%s\n',message);
        writelines(message,fullfile(work,[mode '_progress.txt']));
    end
end
end
function finish(s)
if ~strcmp(s.Status,'inactive'),terminate(s);end
end
