function ax01b_summarize_results
% 汇总正常闭环的实际数据；完整波形仍留.runtime。
root=fileparts(fileparts(mfilename('fullpath')));
work=fullfile(root,'.runtime','ax01b');
folder=fullfile(root,'verification','ax01b');
if ~isfolder(folder),mkdir(folder);end
scenes={'point','continuous','alignment','stop_reset'};
modes={'model_fixed','c_fixed','c_rtl'};
rows={};differences={};events={};
for k=1:numel(scenes)
 scene=scenes{k};
 for j=1:numel(modes)
  mode=modes{j};file=fullfile(work,[mode '_' scene '.mat']);
  if ~isfile(file),continue;end
  a=load(file,'out');o=a.out;c=matrix(o.r5_commit);
  x=o.logsout.get('x_mm').Values;
  changed=[1;find(any(diff(c(:,[24 27 32 33 34 5]))~=0,2))+1];
  for ix=changed'
   events(end+1,:)={mode,scene,o.r5_commit.Time(ix),c(ix,24),c(ix,25), ...
    c(ix,31),c(ix,27),c(ix,32),c(ix,33),c(ix,34),c(ix,5)}; %#ok<AGROW>
  end
  rows(end+1,:)={mode,scene,numel(o.r5_commit.Time),o.r5_commit.Time(end), ...
   double(x.Data(end)),c(end,24),c(end,32),c(end,33),c(end,31),c(end,4)}; %#ok<AGROW>
  if strcmp(mode,'c_fixed')||strcmp(mode,'c_rtl')
   refmode='model_fixed';if strcmp(mode,'c_rtl'),refmode='c_fixed';end
   b=load(fullfile(work,[refmode '_' scene '.mat']),'out');
   for name={'x_mm','v_mmps','id','iq','duty_u_applied','duty_v_applied','duty_w_applied'}
    s=o.logsout.get(name{1}).Values;r=b.out.logsout.get(name{1}).Values;
    common=s.Time<=r.Time(end);t=s.Time(common);
    delta=double(s.Data(common))-interp1(r.Time,double(r.Data),t,'previous');
    differences(end+1,:)={mode,refmode,scene,name{1},max(abs(delta)),sqrt(mean(delta.^2))}; %#ok<AGROW>
   end
  end
 end
end
writetable(cell2table(rows,'VariableNames',{'mode','scene','frames','last_frame_s', ...
 'final_x_mm','accepted_target_mm','accepted','rejected','final_ready','Init_Done'}), ...
 fullfile(folder,'scene_results.csv'));
writetable(cell2table(differences,'VariableNames',{'mode','reference','scene','signal','max_abs','rms'}), ...
 fullfile(folder,'closedloop_differences.csv'));
writetable(cell2table(events,'VariableNames',{'mode','scene','time_s','target_mm','Busy', ...
 'Ready','command_status','accepted','rejected','segment_id','Init_State'}), ...
 fullfile(folder,'command_events.csv'));
files=dir(fullfile(work,'*_comparison.mat'));comparisons=struct([]);
for k=1:numel(files)
 a=load(fullfile(files(k).folder,files(k).name),'summary');
 comparisons=[comparisons;a.summary]; %#ok<AGROW>
end
if ~isempty(comparisons),writetable(struct2table(comparisons),fullfile(folder,'same_input_comparisons.csv'));end
% 连续命令和物理对齐的直接观测曲线。
for scene={'continuous','alignment','stop_reset'}
 mode='c_fixed';if isfile(fullfile(work,['c_rtl_' scene{1} '.mat'])),mode='c_rtl';end
 a=load(fullfile(work,[mode '_' scene{1} '.mat']),'out','events');o=a.out;c=matrix(o.r5_commit);t=o.r5_commit.Time;
 f=figure('Visible','off','Position',[100 100 1100 820]);
 tiledlayout(4,1);
 nexttile;plot(t,c(:,13),'--');hold on;s=o.logsout.get('x_mm').Values;plot(s.Time,s.Data);ylabel('x (mm)');legend('reference','actual');grid on;
 nexttile;plot(t,c(:,3),'--');hold on;s=o.logsout.get('v_mmps').Values;plot(s.Time,s.Data);ylabel('v (mm/s)');legend('reference','actual');grid on;
 nexttile;plot(t,c(:,1:2),'--');hold on;for name={'id','iq'},s=o.logsout.get(name{1}).Values;plot(s.Time,s.Data);end;ylabel('current (A)');legend('id ref','iq ref','id','iq');grid on;
 nexttile;stairs(t,c(:,[24 31 5 27]));ylabel('status / mm');xlabel('simulation time (s)');legend('accepted target','Ready','Init state','command status');grid on;
 sgtitle([mode ' / ' scene{1}],'Interpreter','none');
 exportgraphics(f,fullfile(folder,[scene{1} '.png']),'Resolution',140);close(f);
 end
end
function d=matrix(ts)
d=double(ts.Data);if size(d,1)~=numel(ts.Time),d=reshape(d,[],numel(ts.Time))';end
end
