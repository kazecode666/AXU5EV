function result=task1_dsp_reuse(action,output_dir)
% Open, verify or generate the shared Issue42 Task1 feedback components.
% This entry does not initialize motor/PI parameters or access a target board.
root=fileparts(fileparts(mfilename('fullpath')));
if nargin<1,action='open';end
if nargin<2,output_dir=fullfile(root,'.runtime','dsp_reuse', ...
        char(datetime('now',Format='yyyyMMdd_HHmmss')));end
oldpath=path;folders=Simulink.fileGenControl('getConfig');
if ~strcmp(action,'open')
    cleanup=onCleanup(@()restore(oldpath,folders));
end
addpath(fullfile(root,'simulation'),fullfile(root,'simulation','adc'), ...
    fullfile(root,'simulation','real_io'),fullfile(root,'simulation','encoder'), ...
    fullfile(root,'simulation','motor_control'));
switch action
    case 'open'
        open_system(fullfile(root,'simulation','AXU5EV_PL_Algorithm_Library.slx'));
        open_system(fullfile(root,'simulation','encoder','AXU5EV_Encoder_Components.slx'));
        open_system(fullfile(root,'simulation','encoder','AXU5EV_Encoder_Feedback.slx'));
        open_system(fullfile(root,'simulation','motor_control','AXU5EV_Motor_Control_System.slx'));
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
            open_system(fullfile(root,'simulation','encoder',[model '.slx']));
        end
        result.feedback=task1_validate_encoder_model(fullfile(output_dir,'feedback'));
    case 'generate'
        assert(~isfolder(output_dir),'Choose a new generation directory.');
        mkdir(output_dir);
        result.current=adc_generate_hdl(fullfile(output_dir,'current'), ...
            fullfile(root,'generated','dsp_reuse','adc'));
        result.angle=encoder_generate_hdl(fullfile(output_dir,'angle'), ...
            fullfile(root,'generated','dsp_reuse','angle'));
        result.feedback=encoder_generate_c(fullfile(output_dir,'feedback'));
    otherwise
        error('Task1:Action','Expected open, verify or generate.');
end
end

function restore(oldpath,folders)
path(oldpath);
Simulink.fileGenControl('setConfig','config',folders);
end
