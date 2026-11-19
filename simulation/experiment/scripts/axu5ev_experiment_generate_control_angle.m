function result=axu5ev_experiment_generate_control_angle(work_dir)
% Generate the AX04B angle/omega selection DUT from its editable model.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
name='AXU5EV_Experiment_Control_Angle_HDL';
source=fullfile(root,'simulation','experiment','pl',[name '.slx']);
assert(~isfolder(work_dir) && ~isfile(work_dir),'Choose a new HDL output directory.');
if ~bdIsLoaded(name),load_system(source);end
assert(strcmpi(get_param(name,'FileName'),char(System.IO.Path.GetFullPath(source))));
assert(strcmp(get_param(name,'Dirty'),'off'),'Save the reviewed angle boundary before generation.');
dut=[name '/Control_Angle'];
checks=checkhdl(dut);
assert(isempty(checks) || ~any(strcmpi({checks.level},'Error')), ...
    'HDL compatibility failed for Control_Angle.');
makehdl(dut,'TargetDirectory',work_dir);
file=fullfile(work_dir,name,'AX04B_Angle_Control_Angle.sv');
assert(isfile(file),'Generated angle selector is missing.');
result=struct('status','PASS','model',source,'dut',dut,'sv',file,'checkhdl',checks);
if nargout==0,disp(result);end
end
