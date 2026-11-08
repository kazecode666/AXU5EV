function result=ax03b1_run_no_power(generate_hdl)
% Compatibility entry: the reviewed ADC shell now links the shared component.
if nargin<1,generate_hdl=false;end
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldpath=path;cleanup=onCleanup(@()path(oldpath)); %#ok<NASGU>
addpath(fullfile(root,'simulation','adc'));
result=adc_run_observer(generate_hdl);
end
