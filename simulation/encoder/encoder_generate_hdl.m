function result=encoder_generate_hdl(output_dir)
% Generate only the new encoder component; never save a user ADC/library model.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin<1,output_dir=fullfile(root,'.runtime','encoder_feedback','model_01');end
if ~isfolder(output_dir),mkdir(output_dir);end
oldpath=path;gen=Simulink.fileGenControl('getConfig');
cleanup=onCleanup(@()restore(oldpath,gen)); %#ok<NASGU>
addpath(fullfile(root,'simulation','encoder'));
scale=jsondecode(fileread(fullfile(root,'simulation','encoder','encoder_test_scale.json')));
assert(scale.counts_per_electrical_period==30000 && scale.nanometres_per_count==1000, ...
 'Angle specialization and test scale differ; regenerate numerical design for a new period.');
Simulink.fileGenControl('set','CacheFolder',fullfile(output_dir,'cache'), ...
 'CodeGenFolder',fullfile(output_dir,'code'),'createDir',true);
m='AXU5EV_Encoder_Angle_HDL';
if ~bdIsLoaded(m),open_system(fullfile(root,'simulation','encoder',[m '.slx']));end
assert(strcmp(get_param(m,'Dirty'),'off'),'Review unsaved encoder model edits before generating.');
dut=Simulink.ID.getFullName([m ':22']);
assert(strcmp(get_param(dut,'ReferenceBlock'),'AXU5EV_Encoder_Components/Encoder_Angle'));
assert(strcmp(get_param(dut,'LinkStatus'),'resolved'));
hdlset_param(m,'TargetLanguage','SystemVerilog','ResetType','sync', ...
 'ResetAssertedLevel','active-high','ClockInputPort','clk', ...
 'ClockEnableInputPort','clk_enable','ResetInputPort','reset', ...
 'ClockEnableOutputPort','ce_out','GenerateModel','off', ...
 'GenerateValidationModel','off','Traceability','off','ResourceReport','off', ...
 'OptimizationReport','off','EnableComments','on','DateComment','off', ...
 'Oversampling',1,'ClockRatePipelining','off');
hdlset_param(dut,'DistributedPipelining','off');
out=fullfile(root,'generated','encoder');
makehdl(dut,'TargetDirectory',out);
numeric=fileread(fullfile(out,m,'Electric_Angle_Core.sv'));
assert(~contains(numeric,"-32'sd2147483648"),'Unsafe HDL signed literal; regenerate from safe source.');
result=struct('status','PASS','model',m,'dut',dut,'generated_directory',fullfile(out,m), ...
 'format','signed40 radians Q32 stored in signed64','board','NOT_RUN');
f=fopen(fullfile(output_dir,'hdl_result.json'),'w');closer=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(result,PrettyPrint=true));
save_system(m);disp(result);
end
function restore(oldpath,gen)
path(oldpath);Simulink.fileGenControl('setConfig','config',gen);
end
