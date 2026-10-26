function axu5ev_build_runtime
% 从完整Runtime生成C并构建薄的100us在线调用块。
%% 当前模型与参数
root=fileparts(fileparts(mfilename('fullpath')));
work=fullfile(root,'.runtime','ax01b');
addpath(fullfile(root,'simulation'),work);
Simulink.fileGenControl('set','CacheFolder',fullfile(work,'cache'), ...
    'CodeGenFolder',fullfile(work,'codegen'),'createDir',true);
open_system(fullfile(root,'simulation','AXU5EV_R5_Runtime.slx'));
%% 模型生成C；不手工维护算法副本
clear ax01b_r5_sfun
slbuild('AXU5EV_R5_Runtime');
folder=fullfile(work,'codegen','AXU5EV_R5_Runtime_ert_rtw');
files=dir(fullfile(folder,'*.c'));
sources=fullfile(folder,{files(~strcmp({files.name},'ert_main.c')).name});
%% 主机在线包装；不等于R5目标编译
mex('-R2018a',['-I' folder],['-I' fullfile(matlabroot,'simulink','include')], ...
    fullfile(root,'integration','r5_host','ax01b_r5_sfun.c'), ...
    fullfile(root,'integration','r5_host','ax01b_r5_bridge.c'),sources{:}, ...
    '-outdir',work,'-output','ax01b_r5_sfun');
end
