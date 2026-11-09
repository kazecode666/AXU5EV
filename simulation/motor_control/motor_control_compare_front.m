function result=motor_control_compare_front(trace_dir,output_dir)
% Exact event input/output table comparison to the existing authority functions.
assert(batchStartupOptionUsed,'Run through the isolated motor_control_run entry.');
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'simulation','real_io'),fullfile(root,'simulation','encoder'));
f=fopen(fullfile(trace_dir,'current_events.txt'));cl=onCleanup(@()fclose(f));current_checks=0;
types={'logical','uint16','uint16','logical','logical','logical','logical','logical','logical','logical', ...
 'uint32','int32','int32','logical','logical','int32','int32','uint8'};
clear ax03b1_current_preprocess
while true
 line=fgetl(f);if ~ischar(line),break;end
 if isempty(line)||startsWith(line,'#'),continue;end
 if strcmp(strtrim(line),'R'),clear ax03b1_current_preprocess;continue;end
 values=sscanf(line,'%f').';assert(numel(values)==32,'Current trace shape');
 args=cell(1,18);for k=1:18,args{k}=cast(values(k),types{k});end
 actual=cell(1,14);[actual{:}]=ax03b1_current_preprocess(args{:});
 a=cellfun(@double,actual);assert(isequal(a,values(19:32)),'Current event mismatch %d',current_checks+1);
 current_checks=current_checks+1;
end
f2=fopen(fullfile(trace_dir,'angle_events.txt'));cl2=onCleanup(@()fclose(f2));angle_checks=0;
clear encoder_angle_step
while true
 line=fgetl(f2);if ~ischar(line),break;end
 if isempty(line)||startsWith(line,'#'),continue;end
 if strcmp(strtrim(line),'R'),clear encoder_angle_step;continue;end
 v=sscanf(line,'%f').';assert(numel(v)==10,'Angle trace shape');
 seen=false;
 for c=1:35
  [theta,~,valid,event,version]=encoder_angle_step(c==1,uint32(v(2)),logical(v(3)),uint32(v(4)),uint16(v(5)),logical(v(6)),uint32(v(7)));
  if event
   assert(~seen && isequal([double(theta) double(valid) double(version)],v(8:10)),'Angle event mismatch %d',angle_checks+1);seen=true;
  end
 end
 assert(seen);angle_checks=angle_checks+1;
end
result=struct('status','PASS','current_events',current_checks,'current_output_words',14*current_checks, ...
 'angle_events',angle_checks,'same_input_table',trace_dir,'source_current','ax03b1_current_preprocess.m', ...
 'source_angle','encoder_angle_step.m','board','NOT_RUN');
fo=fopen(fullfile(output_dir,'front_model_result.json'),'w');cl3=onCleanup(@()fclose(fo));fprintf(fo,'%s\n',jsonencode(result,PrettyPrint=true));disp(result);
end
