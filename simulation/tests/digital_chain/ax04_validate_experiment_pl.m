function result=ax04_validate_experiment_pl(output_dir,stage)
% Focused source-copy and B2-parameter checks for AX-04's independent PL.
if nargin<2,stage='all';end
assert(ismember(stage,{'copy','foc','all'}),'Expected copy, foc or all validation stage.');
root=axu5ev_project_root(mfilename('fullpath'));
assert(~isfolder(output_dir),'Choose a new validation directory.');
mkdir(output_dir);
oldpath=path;
folders=Simulink.fileGenControl('getConfig');
cleanup=onCleanup(@()restore(oldpath,folders)); %#ok<NASGU>
addpath(fullfile(root,'simulation','tests','adc'), ...
    fullfile(root,'simulation','tests','encoder'), ...
    fullfile(root,'simulation','experiment','pl'), ...
    fullfile(root,'simulation','experiment','parameters'));
Simulink.fileGenControl('set','CacheFolder',fullfile(output_dir,'cache'), ...
    'CodeGenFolder',fullfile(output_dir,'code'),'createDir',true);
if strcmp(stage,'foc')
    current=struct('status','SOURCE_COPY_VERIFIED');
    angle=struct('status','SOURCE_COPY_VERIFIED');
else
    current=validate_current(root,fullfile(output_dir,'current'));
    angle=validate_angle(root,fullfile(output_dir,'angle'));
end
if ~strcmp(stage,'copy')
    foc=validate_foc(root,fullfile(output_dir,'foc'));
else
    foc=struct('status','DEFERRED_B2_PARAMETER_STAGE');
end
result=struct('status','PASS','current',current,'angle',angle,'foc',foc, ...
    'hardware','HW_BINDING_PENDING','board','BOARD_NOT_RUN', ...
    'scope','short model simulation and accepted numeric fixtures');
write_json(fullfile(output_dir,'experiment_pl_numeric.json'),result);
disp(result);
end

function result=validate_current(root,output_dir)
mkdir(output_dir);
oracle=ax03b1_validate_current(output_dir);
vectors=readmatrix(fullfile(output_dir,'current_vectors.csv'));
model=open_experiment(root,'AXU5EV_Experiment_Current_HDL');
ports=find_system(model,'SearchDepth',1,'BlockType','Inport');
assert(numel(ports)==18 && size(vectors,2)==32);
time=(0:size(vectors,1))'*2e-8;
dataset=Simulink.SimulationData.Dataset;
for index=1:numel(ports)
    port=ports{index};number=str2double(get_param(port,'Port'));
    type=get_param(port,'OutDataTypeStr');
    if strcmp(type,'boolean'),type='logical';end
    data=cast([vectors(:,number);vectors(end,number)],type);
    dataset=dataset.addElement(timeseries(data,time),get_param(port,'Name'));
end
input=Simulink.SimulationInput(model);
input=input.setExternalInput(dataset);
input=input.setModelParameter('SaveOutput','on','OutputSaveName','yout', ...
    'SaveFormat','Dataset','StopTime',num2str(time(end),17));
output=sim(input);
for index=1:14
    actual=double(squeeze(output.yout{index}.Values.Data));
    assert(isequal(actual(2:end),vectors(:,18+index)), ...
        'AX04:CurrentCopy','Independent current output %d differs.',index);
end
result=struct('status','PASS','vectors',size(vectors,1), ...
    'arithmetic_checks',oracle.checks,'outputs',14,'latency_cycles',1, ...
    'reference','accepted PR45 49-vector integer arithmetic and calibration oracle');
write_json(fullfile(output_dir,'experiment_current.json'),result);
end

function result=validate_angle(root,output_dir)
mkdir(output_dir);
% The existing fixture owns the 46 edge cases and independent ideal-Q32 test.
fixture=encoder_validate_angle(output_dir);
vectors=readmatrix(fullfile(output_dir,'angle_vectors.txt'));
spacing=48;cycles=size(vectors,1)*spacing;
data=zeros(cycles,7);expected=zeros(cycles,5);
clear encoder_angle_step
for index=1:size(vectors,1)
    row=vectors(index,1:6);
    for clock=1:spacing
        sample=(index-1)*spacing+clock;
        data(sample,:)=[clock==1 row];
        [angle,phase,valid,strobe,version]=encoder_angle_step(clock==1, ...
            uint32(row(1)),logical(row(2)),uint32(row(3)),uint16(row(4)), ...
            logical(row(5)),uint32(row(6)));
        expected(sample,:)=[double(angle) double(phase) valid strobe double(version)];
    end
end
time=(0:cycles-1)'*2e-8;
names={'sample_strobe','count','ready','zero_count','phase_offset_count','direction','config_version'};
dataset=Simulink.SimulationData.Dataset;
for index=1:7
    switch index
        case {1,3,6},values=logical(data(:,index));
        case 5,values=uint16(data(:,index));
        otherwise,values=uint32(data(:,index));
    end
    dataset=dataset.addElement(timeseries(values,time),names{index});
end
model=open_experiment(root,'AXU5EV_Experiment_Angle_HDL');
input=Simulink.SimulationInput(model);
input=input.setExternalInput(dataset);
input=input.setModelParameter('SaveOutput','on','OutputSaveName','yout', ...
    'SaveFormat','Dataset','StopTime',num2str(time(end),17));
output=sim(input);actual=zeros(cycles,5);
for index=1:5,actual(:,index)=double(output.yout{index}.Values.Data);end
assert(isequal(actual,[zeros(1,5);expected(1:end-1,:)]), ...
    'AX04:AngleCopy','Independent angle component differs from frozen oracle.');
result=struct('status','PASS','vectors',size(vectors,1),'clock_steps',cycles, ...
    'latency_cycles',fixture.latency_cycles, ...
    'max_ideal_error_q32_lsb',fixture.max_ideal_error_q32_lsb, ...
    'reference','accepted PR41 modulo32 serial angle and Q32 quantization oracle');
write_json(fullfile(output_dir,'experiment_angle.json'),result);
end

function result=validate_foc(root,output_dir)
mkdir(output_dir);
p=axu5ev_experiment_parameters();
model=open_experiment(root,'AXU5EV_Experiment_FOC');
workspace=get_param(model,'ModelWorkspace');
cfg=getVariable(workspace,'FOC_Fixed_Config');
assert(isequal(cfg.Parameters,p.FOC_Fixed_Parameters), ...
    'Save the reviewed independent B2 FOC workspace before validation.');
assert(abs(cfg.Coefficients.Kp.original-59)<1e-12 && ...
    abs(cfg.Coefficients.KiTs.original-.725)<1e-12);
assert(cfg.Parameters.Rs==1.45 && cfg.Parameters.Ld==.0118 && cfg.Parameters.Lq==.0118);
assert(abs(cfg.Parameters.psi-p.PMLSM_psi_f_Wb)<1e-14);
% All stimuli lie in the accepted fixed-point engineering verification range.
% They are offline vectors, unrelated to physical current permission.
reset=1:12;saturate=13:140;release=141:1164;tail=1165:1188;
values=zeros(tail(end),9);
values(:,9)=48;
values(reset,8)=1;values(tail,8)=1;
values(saturate,6)=1;
values(release,2)=sqrt(3)*.1;
values(release,3)=-sqrt(3)*.1;
time=(0:size(values,1)-1)'*p.Ts_ACR;
dataset=Simulink.SimulationData.Dataset;
names={'ia','ib','ic','theta_e','omega_e','iq_ref','id_ref','PI_Reset_EN','Vdc_V'};
signs=[1 1 1 1 1 1 1 0 0];widths=[32 32 32 40 40 32 32 1 32];
fractions=[24 24 24 32 24 24 24 0 24];
for index=1:9
    if index==8
        data=logical(values(:,index));
    else
        data=fi(values(:,index),signs(index),widths(index),fractions(index));
    end
    dataset=dataset.addElement(timeseries(data,time),names{index});
end
input=Simulink.SimulationInput(model);
input=input.setExternalInput(dataset);
ports=find_system(model,'SearchDepth',1,'BlockType','Inport');
for index=1:numel(ports)
    input=input.setBlockParameter(ports{index},'SampleTime',num2str(p.Ts_ACR,17));
    input=input.setBlockParameter(ports{index},'Interpolate','off');
end
input=input.setModelParameter('SaveOutput','on','OutputSaveName','yout', ...
    'SaveFormat','Dataset','StopTime',num2str(time(end),17), ...
    'SampleTimeConstraint','Unconstrained','SolverType','Fixed-step', ...
    'Solver','FixedStepDiscrete','FixedStep',num2str(p.Ts_ACR,17), ...
    'Decimation','1','OutputOption','SpecifiedOutputTimes','OutputTimes',mat2str(time.',17));
actual=foc_outputs(sim(input),time);
writematrix([time values actual],fullfile(output_dir,'foc_short_model.csv'));
assert(all(isfinite(actual),'all') && all(actual>=0 & actual<=1,'all'));
reset_duty=actual(reset(end),:);
assert(all(reset_duty==reset_duty(1)));
reset_error=max(abs(actual(tail(end)-9:tail(end),:)-reset_duty),[],'all');
assert(reset_error==0,'AX04:PIReset','Held PI_Reset differs from initial zero-command duty.');
span=max(actual,[],2)-min(actual,[],2);
assert(max(span(saturate))>.7,'Saturation stimulus did not reach voltage limiting.');
% A temporary model-workspace override isolates the existing AW contribution.
zero_aw=cfg;
zero_aw.Coefficients.Kaw_d.quantized=0;
zero_aw.Coefficients.Kaw_q.quantized=0;
control=input.setVariable('FOC_Fixed_Config',zero_aw,'Workspace',model);
without_aw=foc_outputs(sim(control),time);
difference_words=abs(actual-without_aw)*2^30;
assert(max(difference_words(release,:),[],'all')>100, ...
    'AX04:AntiWindup','AW coefficient did not affect recovery duty.');
writematrix([time values actual without_aw],fullfile(output_dir,'foc_short_vectors.csv'));
result=struct('status','PASS','frames',size(values,1),'current_pi',[59 7250], ...
    'phase_rl',[cfg.Parameters.Rs cfg.Parameters.Ld cfg.Parameters.Lq], ...
    'flux_Wb',cfg.Parameters.psi,'Ts_ACR',p.Ts_ACR, ...
    'peak_duty_span',max(span(saturate)), ...
    'max_aw_recovery_difference_uq30_words',max(difference_words(release,:),[],'all'), ...
    'zero_command_duty_uq30_words',reset_duty*2^30, ...
    'zero_command_nominal_center_offset_words',(reset_duty-.5)*2^30, ...
    'held_reset_return_error_uq30_words',reset_error*2^30, ...
    'checks','bounded duty, B2 workspace, voltage saturation, AW contribution, PI reset');
write_json(fullfile(output_dir,'experiment_foc.json'),result);
end

function values=foc_outputs(output,time)
values=zeros(numel(time),3);
for index=1:3
    data=output.yout{index}.Values;
    assert(isequal(size(data.Time),size(time)) && all(abs(data.Time-time)<1e-14));
    values(:,index)=double(squeeze(data.Data));
end
end

function model=open_experiment(root,model)
file=fullfile(root,'simulation','experiment','pl',[model '.slx']);
if ~bdIsLoaded(model),open_system(file);end
assert(strcmpi(strrep(get_param(model,'FileName'),'\','/'),strrep(file,'\','/')));
assert(strcmp(get_param(model,'SimulationStatus'),'stopped'));
assert(strcmp(get_param(model,'Dirty'),'off'),'Save reviewed independent sources first.');
end

function restore(oldpath,folders)
path(oldpath);
Simulink.fileGenControl('setConfig','config',folders);
end

function write_json(file,value)
stream=fopen(file,'w');assert(stream>=0);
cleanup=onCleanup(@()fclose(stream)); %#ok<NASGU>
fprintf(stream,'%s\n',jsonencode(value,PrettyPrint=true));
end
