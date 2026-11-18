function result=task1_dsp_reuse(action,output_dir)
% Open, verify or generate the shared Issue42 Task1 feedback components.
% This entry does not initialize motor/PI parameters or access a target board.
root=axu5ev_project_root(mfilename('fullpath'));
if nargin<1,action='open';end
if nargin<2,output_dir=fullfile(root,'.runtime','dsp_reuse', ...
        char(datetime('now',Format='yyyyMMdd_HHmmss')));end
oldpath=path;folders=Simulink.fileGenControl('getConfig');
if ~strcmp(action,'open')
    cleanup=onCleanup(@()restore(oldpath,folders));
end
axu5ev_test_paths(root);
switch action
    case 'open'
        open_system(fullfile(root,'simulation','closed_loop','components','AXU5EV_PL_Algorithm_Library.slx'));
        open_system(fullfile(root,'simulation','tests','encoder','AXU5EV_Encoder_Components.slx'));
        open_system(fullfile(root,'simulation','tests','encoder','AXU5EV_Encoder_Feedback.slx'));
        open_system(fullfile(root,'simulation','tests','digital_chain','AXU5EV_DigitalChain_Test.slx'));
        result=struct('status','OPEN','board','NOT_RUN');
    case 'verify'
        assert(~isfolder(output_dir),'Choose a new evidence directory.');
        mkdir(output_dir);
        Simulink.fileGenControl('set','CacheFolder',fullfile(output_dir,'cache'), ...
            'CodeGenFolder',fullfile(output_dir,'code'),'createDir',true);
        result.current=adc_validate_component(fullfile(output_dir,'current'));
        result.angle=encoder_validate_angle(fullfile(output_dir,'angle'));
        model='AXU5EV_Encoder_Feedback';
        if ~bdIsLoaded(model)
            open_system(fullfile(root,'simulation','tests','encoder',[model '.slx']));
        end
        result.feedback=task1_validate_encoder_model(fullfile(output_dir,'feedback'));
    case 'generate'
        assert(~isfolder(output_dir),'Choose a new generation directory.');
        mkdir(output_dir);
        result.current=adc_generate_hdl(fullfile(output_dir,'current'), ...
            fullfile(output_dir,'current','hdl'));
        result.angle=encoder_generate_hdl(fullfile(output_dir,'angle'), ...
            fullfile(output_dir,'angle','hdl'));
        result.feedback=encoder_generate_c(fullfile(output_dir,'feedback'));
    otherwise
        error('Task1:Action','Expected open, verify or generate.');
end
end

function restore(oldpath,folders)
path(oldpath);
Simulink.fileGenControl('setConfig','config',folders);
end
