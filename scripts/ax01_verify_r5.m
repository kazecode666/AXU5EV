function results = ax01_verify_r5(runSIL)
% 验证R5提取边界；在独立MATLAB进程运行，不修改原控制模型。
if nargin == 0, runSIL = false; end
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'simulation'), ...
    fullfile(root,'verification','r5'));
evalin('base','init_AXU5EV;');
runtime = fullfile(root,'.runtime','ax01');
if ~isfolder(runtime), mkdir(runtime); end
Simulink.fileGenControl('set','CacheFolder',fullfile(runtime,'cache'), ...
    'CodeGenFolder',fullfile(runtime,'codegen'),'createDir',true);
names = {'position_reset','speed_slew','current_test', ...
    'alignment_full','alignment_reset_fault'};
results = repmat(struct('case','','seconds',0,'samples',0, ...
    'normal_max_error',NaN,'sil_max_error',NaN,'status',''),1,numel(names));
for k = 1:numel(names)
    [data,stopTime] = inputs(names{k});
    ref = runCase('AXU5EV_R5_Reference',data,stopTime,'normal');
    actual = runCase('AXU5EV_R5_Control',data,stopTime,'normal');
    normalError = compare(ref,actual,0);
    replay = zeros(numel(actual.tout),27);
    replay(:,1) = actual.tout;
    for j = 1:14
        replay(:,j+1) = data.get(j).Data;
    end
    for j = 1:12
        replay(:,j+15) = double(actual.yout.get(j).Values.Data);
    end
    writematrix(replay,fullfile(runtime,[names{k} '.csv']));
    silError = NaN;
    if runSIL
        sil = runCase('AXU5EV_R5_Control',data,stopTime, ...
            'software-in-the-loop (sil)');
        silError = compare(actual,sil,1e-12);
    end
    if strcmp(names{k},'alignment_full')
        states = actual.yout.get(5).Values.Data;
        assert(isequal(unique(states(:))',(0:4)),'AX01:STATES', ...
            'Original five alignment states must all execute.');
        done = actual.yout.get(4).Values.Data;
        assert(done(end)==1,'AX01:ALIGNMENT','Full alignment did not finish.');
        offset = actual.yout.get(8).Values.Data;
        assert(abs(offset(end)-mod(-2*pi*3.25/60,2*pi))<1e-12, ...
            'AX01:OFFSET','Original one-time offset formula changed.');
        firstDone = actual.yout.get(4).Values.Time(find(done,1));
        assert(firstDone>=4.2,'AX01:COUNT','Alignment counts were shortened.');
    end
    results(k) = struct('case',names{k},'seconds',stopTime, ...
        'samples',numel(actual.tout),'normal_max_error',normalError, ...
        'sil_max_error',silError,'status','PASS');
    fprintf('AX01_PASS %s normal=%g SIL=%g samples=%d\n', ...
        names{k},normalError,silError,numel(actual.tout));
end
save(fullfile(runtime,'r5_equivalence.mat'),'results');
disp(struct2table(results));
end

function out = runCase(model,data,stopTime,mode)
in = Simulink.SimulationInput(model);
in = in.setModelParameter('StopTime',num2str(stopTime,17), ...
    'SimulationMode',mode);
in = in.setExternalInput(data);
out = sim(in);
end

function worst = compare(reference,actual,tolerance)
assert(reference.yout.numElements==actual.yout.numElements);
worst = 0;
for j = 1:reference.yout.numElements
    a = reference.yout.get(j).Values;
    b = actual.yout.get(j).Values;
    assert(isequal(a.Time,b.Time),'AX01:TIME','Output %d time mismatch.',j);
    assert(all(isfinite(a.Data(:))) && all(isfinite(b.Data(:))));
    err = max(abs(double(a.Data(:))-double(b.Data(:))));
    assert(err<=tolerance,'AX01:VALUE','Output %d error %.17g.',j,err);
    worst = max(worst,err);
end
end

function [ds,stopTime] = inputs(name)
stopTime = 0.1;
if strcmp(name,'alignment_full'), stopTime = 4.25; end
t = (0:round(stopTime/1e-4))'*1e-4;
u = zeros(numel(t),14);
u(:,4:5) = 1; % 位置/速度使能
switch name
    case 'position_reset'
        u(:,1) = (t>=0.01)-1.5*(t>=0.065);
        u(:,2) = 0.2*sin(2*pi*7*t);
        u(:,3) = 0.2*2*pi*7*cos(2*pi*7*t);
        u(:,10) = (t>=0.03 & t<0.033) | (t>=0.07 & t<0.071);
    case 'speed_slew'
        u(:,4) = 0;
        u(:,6) = 8*(t>=0.005)-16*(t>=0.055);
        u(:,3) = 2*sin(2*pi*13*t);
        u(:,10) = t>=0.025 & t<0.027;
    case 'current_test'
        u(:,4:5) = 0;
        u(:,7) = 0.1;
        u(:,8) = 1;
        u(:,9) = 0.2-0.35*(t>=0.04);
        u(:,10) = t<0.001;
    case {'alignment_full','alignment_reset_fault'}
        u(:,1) = 5;
        u(:,2) = 3.25;
        u(:,11) = 1;
        u(:,12) = t>=0.002 & t<0.003; % 保留手动Start
        u(:,13) = t<0.001;
        if strcmp(name,'alignment_reset_fault')
            u(:,13) = u(:,13) | (t>=0.03 & t<0.032);
            u(:,12) = u(:,12) | (t>=0.035 & t<0.036);
            u(:,14) = t>=0.06 & t<0.065;
            u(:,10) = t>=0.02 & t<0.023; % 与Init_Reset分开
        end
end
ds = Simulink.SimulationData.Dataset;
for j = 1:size(u,2)
    value = timeseries(u(:,j),t);
    value = setinterpmethod(value,'zoh');
    ds = ds.addElement(value);
end
end
