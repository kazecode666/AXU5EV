function summary=ax01b_compare_reference(mode,scene)
% 只用实际闭环记录作独立同输入对照；不驱动RTL反馈链。
root=fileparts(fileparts(mfilename('fullpath')));
file=fullfile(root,'.runtime','ax01b',[mode '_' scene '.mat']);
a=load(file,'out');out=a.out;
in=Simulink.SimulationInput('AXU5EV_Hybrid_Reference_Check');
in=in.setVariable('AX01B_software_input',out.r5_snapshot);
in=in.setVariable('AX01B_foc_input',out.foc_frame);
in=in.setVariable('AX01B_Reference_Stop',out.r5_commit.Time(end));
ref=sim(in);
software=matrix(ref.runtime_reference)-matrix(out.r5_commit);
duty=matrix(ref.duty_reference)-matrix(out.duty_result);
summary=struct('mode',mode,'scene',scene, ...
 'frames',numel(out.r5_commit.Time),'stop_s',out.r5_commit.Time(end), ...
 'software_max_abs',max(abs(software),[],'all'), ...
 'duty_max_word_error',max(abs(duty),[],'all')*2^30);
assert(summary.software_max_abs<=1e-12,'AX01B:SOFTWARE','Runtime/C same-input difference exceeds 1e-12.');
assert(summary.duty_max_word_error==0,'AX01B:WORDS','Fixed/actual duty word mismatch.');
if strcmp(mode,'c_rtl')
 e=matrix(out.rtl_frame_events);
 assert(all(e(:,1)==(1:size(e,1))')&&all(e(:,2)==315)&&all(e(:,3)==1)&&all(e(:,4)==0), ...
     'AX01B:FRAME','RTL frame/capture/hold events differ.');
end
save(fullfile(root,'.runtime','ax01b',[mode '_' scene '_comparison.mat']),'summary');
disp(summary);
end
function d=matrix(ts)
d=double(ts.Data);
if size(d,1)~=numel(ts.Time),d=reshape(d,[],numel(ts.Time))';end
end
