function result=adc_run_observer(generate_hdl,output_dir)
% Observer validation and optional generation through the one ADC entry.
if nargin<1,generate_hdl=false;end
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin<2
 output_dir=fullfile(root,'.runtime','adc_consolidation', ...
   ['matlab_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))]);
end
result.component=adc_validate_component(output_dir);
if generate_hdl,result.hdl=adc_generate_hdl(output_dir);
else,result.hdl=struct('status','NOT_RUN');end
end
