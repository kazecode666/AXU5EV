function result=motor_control_generate_mapper(output_dir)
% Generate only the new numeric adapter, preserve unchanged p3/current/angle RTL.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
assert(~isfolder(output_dir),'Choose a new output directory.');mkdir(output_dir);
oldpath=path;g=Simulink.fileGenControl('getConfig');cl=onCleanup(@()restore(oldpath,g)); %#ok<NASGU>
addpath(fullfile(root,'simulation','motor_control'));
Simulink.fileGenControl('set','CacheFolder',fullfile(output_dir,'cache'), ...
 'CodeGenFolder',fullfile(output_dir,'code'),'createDir',true);
m='AXU5EV_Duty_Adapter_HDL';if ~bdIsLoaded(m),open_system(fullfile(root,'simulation','motor_control',[m '.slx']));end
assert(strcmp(get_param(m,'Dirty'),'off'),'Unsaved adapter edits must be reviewed.');
dut=Simulink.ID.getFullName([m ':1']);
hdlset_param(m,'TargetLanguage','SystemVerilog','ResetType','sync', ...
 'ResetAssertedLevel','active-high','ClockInputPort','clk','ClockEnableInputPort','clk_enable', ...
 'ResetInputPort','reset','ClockEnableOutputPort','ce_out','GenerateModel','off', ...
 'GenerateValidationModel','off','Traceability','off','ResourceReport','off','OptimizationReport','off', ...
 'EnableComments','on','DateComment','off','Oversampling',1,'ClockRatePipelining','off');
hdlset_param(dut,'DistributedPipelining','off');
makehdl(dut,'TargetDirectory',fullfile(root,'generated','motor_control'));
save_system(m);
v=uint32([0;1;107374;107374182;268435456;536870912;805306368;1073741823;1073741824;1073741825;4294967295]);
% Around selected integer decision boundaries, including exact half-step where representable.
v=[v;uint32(floor(((0:9)'+.5)*2^30/5000));uint32(ceil(((0:9)'+.5)*2^30/5000))];
n=numel(v);t=(0:n)'*2e-8;ds=Simulink.SimulationData.Dataset;
ds=ds.addElement(timeseries([true(n,1);false],t),'sample_strobe');
names={'duty_u','duty_v','duty_w'};input=[v circshift(v,1) circshift(v,2)];
expected=uint16(floor(min(double(input),2^30)*5000/2^30+.5));
for k=1:3,ds=ds.addElement(timeseries([input(:,k);input(end,k)],t),names{k});end
in=Simulink.SimulationInput(m);in=in.setExternalInput(ds);
in=in.setModelParameter('StopTime',sprintf('%.12g',t(end)));out=sim(in);
for k=1:3,assert(isequal(squeeze(out.yout{k}.Values.Data(2:end)),expected(:,k)));end
assert(all(out.yout{4}.Values.Data(2:end)));
f=fopen(fullfile(output_dir,'duty_vectors.txt'),'w');c=onCleanup(@()fclose(f));
for k=1:n,fprintf(f,'%u %u %u %u %u %u\n',input(k,:),expected(k,:));end
result=struct('status','PASS','vectors',n,'outputs',3,'registered_latency_clocks',1, ...
 'rounding','unsigned Q30 clamp then round half up to 0..5000', ...
 'source','duty_to_compare.m','board','NOT_RUN');
f2=fopen(fullfile(output_dir,'mapper_result.json'),'w');c2=onCleanup(@()fclose(f2));
fprintf(f2,'%s\n',jsonencode(result,PrettyPrint=true));disp(result);
end
function restore(p,g)
path(p);Simulink.fileGenControl('setConfig','config',g);
end
