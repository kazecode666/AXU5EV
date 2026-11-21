function result=ax04_validate_feedforward(output_dir,observe_dq)
% Short dynamic feedforward trace for the independent B2 FOC and RTL.
if nargin<2,observe_dq=false;end
root=axu5ev_project_root(mfilename('fullpath'));
assert(~isfolder(output_dir) && ~isfile(output_dir),'Choose a new verification directory.');
mkdir(output_dir);
oldpath=path;folders=Simulink.fileGenControl('getConfig');
cleanup=onCleanup(@()restore(oldpath,folders)); %#ok<NASGU>
addpath(fullfile(root,'simulation','experiment','pl'), ...
    fullfile(root,'simulation','experiment','parameters'));
Simulink.fileGenControl('set','CacheFolder',fullfile(output_dir,'cache'), ...
    'CodeGenFolder',fullfile(output_dir,'code'),'createDir',true);
model='AXU5EV_Experiment_FOC';
file=fullfile(root,'simulation','experiment','pl',[model '.slx']);
if ~bdIsLoaded(model),load_system(file);end
assert(strcmp(get_param(model,'Dirty'),'off'));
workspace=get_param(model,'ModelWorkspace');
p=axu5ev_experiment_parameters();
assert(isequaln(getVariable(workspace,'FOC_Fixed_Config'),p.FOC_Fixed_Config));

angles=[0 pi/6 pi/2 -pi/3];
speeds=[30 -30];
frames=48;values=zeros(frames,9);
values(:,1:3)=repmat([.2 -.12 -.08],frames,1);
values(:,6:7)=repmat([-.1 .15],frames,1);
values(:,9)=48;
values([1:4 45:48],8)=1;
cases=zeros(8,4);
case_index=0;
for angle=angles
    for speed=speeds
        case_index=case_index+1;
        rows=5+(case_index-1)*5:9+(case_index-1)*5;
        values(rows,4)=angle;
        values(rows,5)=speed;
        cases(case_index,:)=[rows(1)-1 rows(end)-1 angle speed];
    end
end
time=(0:frames-1)'*p.Ts_ACR;
names={'ia','ib','ic','theta_e','omega_e','iq_ref','id_ref','PI_Reset_EN','Vdc_V'};
signs=[1 1 1 1 1 1 1 0 0];widths=[32 32 32 40 40 32 32 1 32];
fractions=[24 24 24 32 24 24 24 0 24];
dataset=Simulink.SimulationData.Dataset;
for index=1:9
    if index==8
        data=logical(values(:,index));
    else
        data=fi(values(:,index),signs(index),widths(index),fractions(index));
    end
    dataset=dataset.addElement(timeseries(data,time),names{index});
end
in=Simulink.SimulationInput(model);
in=in.setExternalInput(dataset);
ports=find_system(model,'SearchDepth',1,'BlockType','Inport');
for index=1:numel(ports)
    in=in.setBlockParameter(ports{index},'SampleTime',num2str(p.Ts_ACR,17));
    in=in.setBlockParameter(ports{index},'Interpolate','off');
end
in=in.setModelParameter('SaveOutput','on','OutputSaveName','yout', ...
    'SaveFormat','Dataset','StopTime',num2str(time(end),17), ...
    'SampleTimeConstraint','Unconstrained','SolverType','Fixed-step', ...
    'Solver','FixedStepDiscrete','FixedStep',num2str(p.Ts_ACR,17), ...
    'Decimation','1','OutputOption','SpecifiedOutputTimes','OutputTimes',mat2str(time.',17));
out=sim(in);actual=zeros(frames,3);
for index=1:3
    data=out.yout{index}.Values;
    assert(isequal(size(data.Time),size(time)) && all(abs(data.Time-time)<1e-14));
    actual(:,index)=double(squeeze(data.Data));
end
assert(all(isfinite(actual),'all') && all(actual>=0 & actual<=1,'all'));
assert(max(max(actual(5:44,:),[],2)-min(actual(5:44,:),[],2))>.05);
assert(isequal(actual(45:48,:),repmat(actual(4,:),4,1)), ...
    'Held PI reset differs from its initial zero-command duty.');
writematrix([time values actual],fullfile(output_dir,'foc_feedforward_model.csv'));
if observe_dq
    assert(numElements(out.yout)==7);
    hex_words=cell(1,4);
    for index=1:4
        tap=out.yout{index+3}.Values;
        assert(isequal(size(tap.Time),size(time)) && all(abs(tap.Time-time)<1e-14));
        values_fi=squeeze(tap.Data);
        value_type=numerictype(values_fi);
        assert(issigned(values_fi) && value_type.WordLength==64 && value_type.FractionLength==40);
        hex_words{index}=dec2hex(typecast(storedInteger(values_fi),'uint64'),16);
    end
    fid=fopen(fullfile(output_dir,'foc_dq_vectors.hex'),'w');
    assert(fid>=0);
    finish_dq=onCleanup(@()fclose(fid)); %#ok<NASGU>
    rows=[hex_words{:}];
    for index=1:frames
        fprintf(fid,'%s\n',rows(index,:));
    end
end
result=struct('status','PASS','frames',frames,'active_frames',40, ...
    'angle_velocity_cases',cases,'case_columns','first_frame,last_frame,theta_rad,omega_rad_s', ...
    'phase_currents_A',[.2 -.12 -.08],'id_ref_A',.15,'iq_ref_A',-.1, ...
    'start_reset_frames',4,'tail_reset_frames',4,'Ts_ACR',p.Ts_ACR, ...
    'expected_duty_words',3*frames,'expected_dq_words',4*frames*observe_dq, ...
    'input_quantization','Nearest fi constructor', ...
    'FOC_parameters',p.FOC_Fixed_Parameters,'hardware','HW_BINDING_PENDING','board','BOARD_NOT_RUN');
stream=fopen(fullfile(output_dir,'feedforward_model_result.json'),'w');assert(stream>=0);
closer=onCleanup(@()fclose(stream)); %#ok<NASGU>
fprintf(stream,'%s\n',jsonencode(result,PrettyPrint=true));
assert(strcmp(get_param(model,'Dirty'),'off'));
disp(result);
end

function restore(oldpath,folders)
path(oldpath);
Simulink.fileGenControl('setConfig','config',folders);
end
