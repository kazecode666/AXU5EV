function ax00_run_units(kind)
root=fileparts(fileparts(mfilename('fullpath')));restoredefaultpath;
addpath(fullfile(root,'scripts'),fullfile(root,'simulink模型'));
runtime=fullfile(root,'.runtime/ax00',kind);if ~isfolder(runtime),mkdir(runtime);end;cd(runtime);
Simulink.fileGenControl('set','CacheFolder',fullfile(runtime,'cache'),'CodeGenFolder',fullfile(runtime,'codegen'),'createDir',true);
if strcmp(kind,'live')
 result=m1b_verify_point_commands('live');
else
 result=m1b_verify_alignment_reuse('chart');
end
assert(~contains(lower(path),'fpga_xc7a200t'));
f=fopen(fullfile(root,'coordination/reports',['unit_' kind '.json']),'w');fprintf(f,'%s',jsonencode(result,PrettyPrint=true));fclose(f);
fprintf('AX00_UNIT_PASS %s\n',kind);
end
