function axu5ev_build_runtime(work)
% 从完整Runtime生成C并构建薄的100us在线调用块。
%% 当前模型与参数
root=axu5ev_project_root(mfilename('fullpath'));
if nargin<1,work=axu5ev_closed_loop_work(root);end
work=char(System.IO.Path.GetFullPath(work));
sessions=char(System.IO.Path.GetFullPath(fullfile(root,'.runtime','closed_loop')));
assert(~strcmpi(work,sessions) && ...
    startsWith([work filesep],[sessions filesep],'IgnoreCase',true), ...
    'AXU5EV:Session','Build output must use a new closed-loop session.');
axu5ev_simulation_paths(root);addpath(work);
Simulink.fileGenControl('set','CacheFolder',fullfile(work,'cache'), ...
    'CodeGenFolder',fullfile(work,'codegen'),'createDir',true);
open_system(fullfile(root,'simulation','closed_loop','components','AXU5EV_R5_Runtime.slx'));
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
