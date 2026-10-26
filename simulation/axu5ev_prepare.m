function model=axu5ev_prepare(mode,rebuild)
% 使用当前已加载参数；只准备后端和路径，不恢复默认目标。
%% 路径与后端
if nargin<1,mode=evalin('base','AXU5EV_Backend');end
if nargin<2,rebuild=false;end
assert(any(strcmp(mode,{'model_fixed','c_fixed','c_rtl'})));
root=fileparts(fileparts(mfilename('fullpath')));
work=fullfile(root,'.runtime','ax01b');
addpath(fullfile(root,'simulation'),fullfile(root,'verification'),work);
assert(evalin('base','exist(''PMLSM_M1A_InitVersion'',''var'')==1'), ...
    'AXU5EV:INIT','请先运行simulation/START_HERE.m。');
model='AXU5EV_Hybrid_ClosedLoop';
if bdIsLoaded(model)
    assert(strcmp(get_param(model,'SimulationStatus'),'stopped'), ...
        'AXU5EV:STOP_FIRST','切换后端或重建前请停止仿真。');
end
assignin('base','AXU5EV_Backend',mode);
assignin('base','AX01B_Use_C',double(~strcmp(mode,'model_fixed')));
assignin('base','AX01B_Use_RTL',double(strcmp(mode,'c_rtl')));
assignin('base','AX01B_XSI_Work',fullfile(work,'xsi'));
vivado=evalin('base','AX01B_Vivado_Root');
Simulink.fileGenControl('set','CacheFolder',fullfile(work,'cache'), ...
    'CodeGenFolder',fullfile(work,'codegen'),'createDir',true);
%% 首次构建或显式重建；普通Run不触发
if ~strcmp(mode,'model_fixed')
    target=fullfile(work,['ax01b_r5_sfun.' mexext]);
    if rebuild||~isfile(target)
        clear ax01b_r5_sfun
        axu5ev_build_runtime;
    end
end
if strcmp(mode,'c_rtl')
    lib=fullfile(work,'xsi','xsim.dir','ax01b_p3','xsimk.dll');
    if rebuild||~isfile(lib)
        command=sprintf('pwsh -NoProfile -File "%s" -VivadoBin "%s"', ...
            fullfile(root,'scripts','ax01b_build_xsi.ps1'),fullfile(vivado,'bin'));
        [status,output]=system(command);fprintf('%s',output);assert(status==0,'AX01B:XSI','XSI build failed.');
    end
    dllpath=fullfile(vivado,'lib','win64.o');
    if ~contains(getenv('PATH'),dllpath),setenv('PATH',[dllpath ';' getenv('PATH')]);end
    if rebuild||~isfile(fullfile(work,['ax01b_foc_xsi_sfun.' mexext]))
        clear ax01b_foc_xsi_sfun
        mex('-R2018a',['-I' fullfile(vivado,'data','xsim','include')], ...
            fullfile(root,'integration','r5_host','ax01b_foc_xsi_sfun.c'), ...
            '-outdir',work,'-output','ax01b_foc_xsi_sfun');
    end
end
%% 打开当前活动模型
open_system(fullfile(root,'simulation',[model '.slx']));
fprintf('AXU5EV_READY backend=%s；请点击Run。草稿确认后，Ready=1时翻转Send一次。\n',mode);
end
