function model=axu5ev_prepare(mode,rebuild)
% 使用当前已加载参数；只准备后端和路径，不恢复默认目标。
%% 路径与后端
if nargin<1,mode=evalin('base','AXU5EV_Backend');end
if nargin<2,rebuild=false;end
assert(any(strcmp(mode,{'model_fixed','c_fixed','c_rtl'})));
root=axu5ev_project_root(mfilename('fullpath'));
work=axu5ev_closed_loop_work(root);
legacy=fullfile(root,'.runtime','ax01b');
axu5ev_simulation_paths(root);addpath(work);
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
vivado=evalin('base','AX01B_Vivado_Root');
Simulink.fileGenControl('set','CacheFolder',fullfile(work,'cache'), ...
    'CodeGenFolder',fullfile(work,'codegen'),'createDir',true);
%% 首次构建或显式重建；普通Run不触发
if ~strcmp(mode,'model_fixed')
    target=fullfile(work,['ax01b_r5_sfun.' mexext]);
    legacy_target=fullfile(legacy,['ax01b_r5_sfun.' mexext]);
    if rebuild||(~isfile(target)&&~isfile(legacy_target))
        assert(rebuild,'AXU5EV:BUILD_REQUIRED', ...
            'Host C backend is absent. Explicitly call axu5ev_prepare(mode,true) to build it.');
        clear ax01b_r5_sfun
        axu5ev_build_runtime(work);
    end
end
if strcmp(mode,'c_rtl')
    xsi_work=fullfile(work,'xsi');
    if evalin('base','exist(''AX01B_XSI_Work'',''var'')==1')
        previous=char(evalin('base','AX01B_XSI_Work'));
        if isfile(fullfile(previous,'xsim.dir','ax01b_p3','xsimk.dll'))
            xsi_work=previous;
        end
    end
    lib=fullfile(xsi_work,'xsim.dir','ax01b_p3','xsimk.dll');
    legacy_xsi=fullfile(legacy,'xsi');
    if ~rebuild && ~isfile(lib) && isfile(fullfile(legacy_xsi,'xsim.dir','ax01b_p3','xsimk.dll'))
        xsi_work=legacy_xsi;
        lib=fullfile(xsi_work,'xsim.dir','ax01b_p3','xsimk.dll');
    end
    if rebuild||~isfile(lib)
        assert(rebuild,'AXU5EV:BUILD_REQUIRED', ...
            'RTL simulation backend is absent. Explicitly call axu5ev_prepare(mode,true) to build it.');
        xsi_work=fullfile(work,['xsi_' char(datetime('now',Format='yyyyMMdd_HHmmss_SSS'))]);
        command=sprintf('pwsh -NoProfile -File "%s" -VivadoBin "%s" -WorkDir "%s"', ...
            fullfile(root,'scripts','ax01b_build_xsi.ps1'),fullfile(vivado,'bin'),xsi_work);
        [status,output]=system(command);fprintf('%s',output);assert(status==0,'AX01B:XSI','XSI build failed.');
    end
    assignin('base','AX01B_XSI_Work',xsi_work);
    dllpath=fullfile(vivado,'lib','win64.o');
    if ~contains(getenv('PATH'),dllpath),setenv('PATH',[dllpath ';' getenv('PATH')]);end
    target_wrapper=fullfile(work,['ax01b_foc_xsi_sfun.' mexext]);
    legacy_wrapper=fullfile(legacy,['ax01b_foc_xsi_sfun.' mexext]);
    if rebuild||(~isfile(target_wrapper)&&~isfile(legacy_wrapper))
        assert(rebuild,'AXU5EV:BUILD_REQUIRED', ...
            'XSI host wrapper is absent. Explicitly call axu5ev_prepare(mode,true) to build it.');
        clear ax01b_foc_xsi_sfun
        mex('-R2018a',['-I' fullfile(vivado,'data','xsim','include')], ...
            fullfile(root,'integration','r5_host','ax01b_foc_xsi_sfun.c'), ...
            '-outdir',work,'-output','ax01b_foc_xsi_sfun');
    end
end
%% 打开当前活动模型
open_system(fullfile(root,'simulation','closed_loop',[model '.slx']));
fprintf('AXU5EV_READY backend=%s；请点击Run。草稿确认后，Ready=1时翻转Send一次。\n',mode);
end
