function result=encoder_generate_c(output_dir)
% Generate the only active software numerical implementation. No model saves.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin<1,output_dir=fullfile(root,'.runtime','encoder_feedback','software_01');end
assert(~isfolder(output_dir),'Choose a new output directory.');mkdir(output_dir);
oldpath=path;cleanup=onCleanup(@()path(oldpath)); %#ok<NASGU>
addpath(fullfile(root,'simulation','encoder'));
args={uint32(0),uint32(0),uint64(0),false,uint32(0),uint32(0),false,uint32(0),uint32(1000),false};
cfg=coder.config('lib');cfg.TargetLang='C';cfg.GenCodeOnly=true;cfg.GenerateReport=false;
cfg.HardwareImplementation.ProdHWDeviceType='ARM Compatible->ARM Cortex-R';
cfg.HardwareImplementation.ProdLongLongMode=true;
cfg.EnableOpenMP=false;
active=fullfile(root,'generated','encoder','feedback_c');
target=fullfile(output_dir,'target_c');
codegen('-config',cfg,'encoder_position_speed','-args',args,'-d',target);
if ~isfolder(active),mkdir(active);end
files=[dir(fullfile(target,'*.c'));dir(fullfile(target,'*.h'))];
for k=1:numel(files),copyfile(fullfile(files(k).folder,files(k).name),fullfile(active,files(k).name));end
% Compile the exact ARM-target numeric C through a transport-only MEX gateway.
% No second host numerical generation or hand-edited generated source.
clear encoder_position_speed_mex;
sources=dir(fullfile(target,'*.c'));
paths=arrayfun(@(s)fullfile(s.folder,s.name),sources,UniformOutput=false);
mex('-R2018a',['-I' target],'-outdir',output_dir,'-output','encoder_position_speed_mex', ...
 fullfile(root,'verification','encoder_feedback','encoder_position_speed_gateway.c'),paths{:});
addpath(output_dir);
result=encoder_validate_software(output_dir);
result.active_c=active;result.generated_c_comparison='Exact ARM-target generated C compiled through transport-only host MEX';result.board='NOT_RUN';
f=fopen(fullfile(output_dir,'software_result.json'),'w');
closer=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(result,PrettyPrint=true));
disp(result);
end
