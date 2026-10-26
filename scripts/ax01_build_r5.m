function ax01_build_r5
% 主机ERT C生成；目标仍为Windows，不冒充R5交叉编译。
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'simulation'));
evalin('base','init_AXU5EV;');
runtime = fullfile(root,'.runtime','ax01');
Simulink.fileGenControl('set','CacheFolder',fullfile(runtime,'cache'), ...
    'CodeGenFolder',fullfile(runtime,'codegen'),'createDir',true);
open_system(fullfile(root,'simulation','AXU5EV_R5_Control.slx'));
slbuild('AXU5EV_R5_Control');
end
