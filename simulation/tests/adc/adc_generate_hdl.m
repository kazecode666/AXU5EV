function result = adc_generate_hdl(output_dir,hdl_dir)
% Generate the shared ADC graph into an explicitly separate candidate folder.
root=axu5ev_project_root(mfilename('fullpath'));
if nargin<1
    output_dir=fullfile(root,'.runtime','tests', ...
        ['adc_hdl_' char(datetime('now',Format='yyyyMMdd_HHmmss_SSS'))]);
end
if nargin<2,hdl_dir=fullfile(output_dir,'hdl');end
if ~isfolder(output_dir),mkdir(output_dir);end
oldpath=path;gen=Simulink.fileGenControl('getConfig');
cleanup=onCleanup(@()restore(oldpath,gen)); %#ok<NASGU>
axu5ev_test_paths(root);
Simulink.fileGenControl('set','CacheFolder',fullfile(output_dir,'cache'), ...
 'CodeGenFolder',fullfile(output_dir,'code'),'createDir',true);
m='AXU5EV_ADC_HDL';
if ~bdIsLoaded(m),open_system(fullfile(root,'simulation','tests','adc',[m '.slx']));end
dut=Simulink.ID.getFullName([m ':1']);
assert(strcmp(get_param(dut,'ReferenceBlock'),'AXU5EV_PL_Algorithm_Library/Current_Preprocess'));
assert(strcmp(get_param(dut,'LinkStatus'),'resolved'));
original=getActiveConfigSet(m);original_name=original.Name;
original_dirty=get_param(m,'Dirty');
original_pipeline=hdlget_param(dut,'DistributedPipelining');
temporary=copy(original);temporary.Name='Task1_ADC_temporary';
attachConfigSet(m,temporary);
configuration_cleanup=onCleanup(@()restore_configuration( ...
    m,original_name,temporary.Name,dut,original_pipeline,oldpath,gen,original_dirty)); %#ok<NASGU>
setActiveConfigSet(m,temporary.Name);
hdlset_param(m,'TargetLanguage','SystemVerilog','ResetType','sync', ...
 'ResetAssertedLevel','active-high','ClockInputPort','clk', ...
 'ClockEnableInputPort','clk_enable','ResetInputPort','reset', ...
 'ClockEnableOutputPort','ce_out','GenerateModel','off', ...
 'GenerateValidationModel','off','Traceability','off','ResourceReport','off', ...
 'OptimizationReport','off','EnableComments','on','DateComment','off', ...
 'Oversampling',1,'ClockRatePipelining','off');
if ~strcmp(original_pipeline,'off')
    hdlset_param(dut,'DistributedPipelining','off');
end
makehdl(dut,'TargetDirectory',hdl_dir);
files=dir(fullfile(hdl_dir,m,'*.sv'));
assert(~isempty(files),'No SystemVerilog files were generated.');
assert(isfile(fullfile(hdl_dir,m,'Current_Processing.sv')), ...
 'The extracted current-processing graph was not generated.');
for k=1:numel(files)
    numeric=fileread(fullfile(files(k).folder,files(k).name));
    assert(~contains(numeric,"< -32'sd2147483648"), ...
     'Unsafe generated signed literal in %s.',files(k).name);
end
result=struct('status','PASS','model',m,'dut',dut, ...
 'component',get_param(dut,'ReferenceBlock'),'output_latency_cycles',1, ...
 'generated_directory',fullfile(hdl_dir,m),'model_saved',false,'board','NOT_RUN');
f=fopen(fullfile(output_dir,'hdl_result.json'),'w');
closer=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(result,PrettyPrint=true));
% The current model remains open with its existing unsaved edits.
disp(result);
end
function restore(oldpath,gen)
path(oldpath);Simulink.fileGenControl('setConfig','config',gen);
end

function restore_configuration(model,original_name,temporary_name,dut,original_pipeline,oldpath,gen,original_dirty)
setActiveConfigSet(model,original_name);
detachConfigSet(model,temporary_name);
if ~strcmp(hdlget_param(dut,'DistributedPipelining'),original_pipeline)
    hdlset_param(dut,'DistributedPipelining',original_pipeline);
end
restore(oldpath,gen);
set_param(model,'Dirty',original_dirty);
end
