function model=ax01b_prepare_hybrid(mode,rebuild)
% 兼容旧调用；日常入口为simulation/START_HERE。
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'simulation'));
if evalin('base','exist(''PMLSM_M1A_InitVersion'',''var'')~=1')
    evalin('base','init_AXU5EV;');
end
if nargin<1,mode=evalin('base','AXU5EV_Backend');end
if nargin<2,rebuild=false;end
model=axu5ev_prepare(mode,rebuild);
end
