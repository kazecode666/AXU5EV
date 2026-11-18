function result=task1_validate_encoder_model(output_dir,model)
% Compare the visible reused DSP block graph against its frozen reference.
if nargin<2,model='AXU5EV_Encoder_Feedback';end
if ~isfolder(output_dir),mkdir(output_dir);end
vectors=task1_encoder_vectors();
time=(0:vectors.frames-1)'*1e-4;
dataset=Simulink.SimulationData.Dataset;
ports=find_system(model,'SearchDepth',1,'BlockType','Inport');
assert(numel(ports)==10,'Expected the ten qualified-frame input fields.');
for port_index=1:numel(ports)
    port=str2double(get_param(ports{port_index},'Port'));
    dataset=dataset.addElement(timeseries(vectors.inputs{port},time), ...
        get_param(ports{port_index},'Name'));
end
input=Simulink.SimulationInput(model);
input=input.setExternalInput(dataset);
input=input.setModelParameter('StopTime',num2str(time(end),17));
output=sim(input);
actual=cell(1,7);
maximum_error=zeros(1,7);
for port=1:7
    signal=output.yout{port}.Values;
    actual{port}=squeeze(signal.Data);
    assert(numel(actual{port})==vectors.frames,'Output sample count differs.');
    assert(all(abs(signal.Time(:)-time)<1e-12),'Output sample time differs.');
    difference=abs(double(actual{port}(:))-double(vectors.expected{port}(:)));
    maximum_error(port)=max(difference);
    tolerance=0;
    if port<=2,tolerance=1e-9;end
    assert(all(difference<=tolerance),'Task1:EncoderModelDifference', ...
        'Output %d differs from qualified-frame reference by %.17g.',port,maximum_error(port));
end
assert(any(actual{4}),'50-interval speed history never became valid.');
assert(any(actual{2}>0) && any(actual{2}<0),'Both speed signs must be covered.');
rows=[vectors.case_ids,double(actual{1}),double(actual{2}),double(actual{3}), ...
    double(actual{4}),double(actual{5}),double(actual{6}),double(actual{7})];
writematrix(rows,fullfile(output_dir,'encoder_model_frames.csv'));
result=struct('status','PASS','model',model,'frames',vectors.frames, ...
    'scenarios',vectors.scenarios,'compared_output_fields',7, ...
    'maximum_error',maximum_error,'speed_intervals',50,'history_entries',51, ...
    'history_time_seconds',0.005,'board','NOT_RUN');
file=fopen(fullfile(output_dir,'encoder_model_result.json'),'w');
assert(file>=0,'Cannot create encoder result report.');
cleanup=onCleanup(@()fclose(file)); %#ok<NASGU>
fprintf(file,'%s\n',jsonencode(result,PrettyPrint=true));
disp(result);
end
