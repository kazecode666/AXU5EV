function result=motor_control_run(output_dir,trace_path,wait_for_completion)
% Unique safe executable entry: always isolate frozen dependencies from user models.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin<2,trace_path='';end
if nargin<3,wait_for_completion=true;end
assert(~isfolder(output_dir),'Select a new output directory.');mkdir(output_dir);
[~,attr]=fileattrib(output_dir);output_dir=attr.Name;
deps=fullfile(output_dir,'dependencies');
cmd=sprintf('python "%s" "%s"',fullfile(root,'scripts','motor_control_stage_sources.py'),deps);
[s,o]=system(cmd);assert(s==0,'%s',o);
if isempty(trace_path)
 expr=sprintf('addpath(''%s'');motor_control_system_batch(''%s'');',fullfile(root,'simulation','motor_control'),output_dir);
elseif isfolder(trace_path)
 expr=sprintf('addpath(''%s'');motor_control_compare_front(''%s'',''%s'');motor_control_compare_foc(''%s'',''%s'');', ...
  fullfile(root,'simulation','motor_control'),trace_path,output_dir,fullfile(trace_path,'foc_frames.txt'),output_dir);
else
 expr=sprintf('addpath(''%s'');motor_control_compare_foc(''%s'',''%s'');',fullfile(root,'simulation','motor_control'),trace_path,output_dir);
end
expr=strrep(expr,'\','/');
psi=System.Diagnostics.ProcessStartInfo;
psi.FileName=fullfile(matlabroot,'bin','matlab.exe');
psi.Arguments=sprintf('-batch "%s" -logfile "%s"',expr,fullfile(output_dir,'matlab.log'));
psi.UseShellExecute=false;psi.CreateNoWindow=true;
process=System.Diagnostics.Process.Start(psi);
if ~wait_for_completion
 result=struct('status','RUNNING','process_id',double(process.Id),'output_dir',output_dir);disp(result);return;
end
process.WaitForExit();assert(process.ExitCode==0,'Isolated model run failed; read %s',fullfile(output_dir,'matlab.log'));
if isempty(trace_path),name='system_result.json';else,name='foc_model_result.json';end
result=jsondecode(fileread(fullfile(output_dir,name)));disp(result);
end
