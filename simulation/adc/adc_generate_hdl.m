function result = adc_generate_hdl(output_dir)
% Single ADC HDL entry. Only the linked numeric component is generated.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin<1,output_dir=fullfile(root,'.runtime','adc_consolidation','matlab_01');end
if ~isfolder(output_dir),mkdir(output_dir);end
oldpath=path;gen=Simulink.fileGenControl('getConfig');
cleanup=onCleanup(@()restore(oldpath,gen)); %#ok<NASGU>
addpath(fullfile(root,'simulation'),fullfile(root,'simulation','real_io'));
Simulink.fileGenControl('set','CacheFolder',fullfile(output_dir,'cache'), ...
 'CodeGenFolder',fullfile(output_dir,'code'),'createDir',true);
m='AXU5EV_ADC_HDL';
if ~bdIsLoaded(m),open_system(fullfile(root,'simulation',[m '.slx']));end
assert(strcmp(get_param(m,'Dirty'),'off'),'Review unsaved ADC HDL model first.');
dut=Simulink.ID.getFullName([m ':1']);
assert(strcmp(get_param(dut,'ReferenceBlock'),'AXU5EV_PL_Algorithm_Library/Current_Preprocess'));
assert(strcmp(get_param(dut,'LinkStatus'),'resolved'));
hdlset_param(m,'TargetLanguage','SystemVerilog','ResetType','sync', ...
 'ResetAssertedLevel','active-high','ClockInputPort','clk', ...
 'ClockEnableInputPort','clk_enable','ResetInputPort','reset', ...
 'ClockEnableOutputPort','ce_out','GenerateModel','off', ...
 'GenerateValidationModel','off','Traceability','off','ResourceReport','off', ...
 'OptimizationReport','off','EnableComments','on','DateComment','off', ...
 'Oversampling',1,'ClockRatePipelining','off');
hdlset_param(dut,'DistributedPipelining','off');
out=fullfile(root,'generated','adc');
makehdl(dut,'TargetDirectory',out);
numeric=fileread(fullfile(out,m,'Numeric_Algorithm.sv'));
assert(~contains(numeric,"< -32'sd2147483648"),'Unsafe generated signed literal.');
result=struct('status','PASS','model',m,'dut',dut, ...
 'component',get_param(dut,'ReferenceBlock'),'output_latency_cycles',1, ...
 'generated_directory',fullfile(out,m),'board','NOT_RUN');
f=fopen(fullfile(output_dir,'hdl_result.json'),'w');
closer=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(result,PrettyPrint=true));
% Only this new shell, checked clean above, records generation settings.
% Never save the legacy observer or other user models.
save_system(m);
disp(result);
end
function restore(oldpath,gen)
path(oldpath);Simulink.fileGenControl('setConfig','config',gen);
end
