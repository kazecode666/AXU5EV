function model=ax01b_prepare_hybrid(mode,rebuild)
% 一次初始化并打开共享闭环；运行时目标/发送不需要重编译。
if nargin<1,mode='c_fixed';end
if nargin<2,rebuild=false;end
assert(any(strcmp(mode,{'model_fixed','c_fixed','c_rtl'})));
root=fileparts(fileparts(mfilename('fullpath')));
work=fullfile(root,'.runtime','ax01b');
addpath(root,fullfile(root,'scripts'),fullfile(root,'simulink模型'), ...
    fullfile(root,'firmware','r5'),fullfile(root,'integration'), ...
    fullfile(root,'verification'),work);
evalin('base','init_PMLSM_PI_FOC_Float_Baseline;');
assignin('base','AX01B_Use_C',double(~strcmp(mode,'model_fixed')));
assignin('base','AX01B_Use_RTL',double(strcmp(mode,'c_rtl')));
assignin('base','AX01B_XSI_Work',fullfile(work,'xsi'));
vivado='E:/AMDDesignTools/2026.1/Vivado';
assignin('base','AX01B_Vivado_Root',vivado);
Simulink.fileGenControl('set','CacheFolder',fullfile(work,'cache'), ...
    'CodeGenFolder',fullfile(work,'codegen'),'createDir',true);
if ~strcmp(mode,'model_fixed')
    target=fullfile(work,['ax01b_r5_sfun.' mexext]);
    if rebuild||~isfile(target)
        clear ax01b_r5_sfun
        ax01b_build_runtime;
    end
end
if strcmp(mode,'c_rtl')
    lib=fullfile(work,'xsi','xsim.dir','ax01b_p3','xsimk.dll');
    if rebuild||~isfile(lib)
        command=sprintf('pwsh -NoProfile -File "%s"',fullfile(root,'scripts','ax01b_build_xsi.ps1'));
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
model='AXU5EV_Hybrid_ClosedLoop';
open_system(fullfile(root,'integration',[model '.slx']));
fprintf('AX01B_READY mode=%s: edit target draft, toggle Send once; stop before changing backend.\n',mode);
end
