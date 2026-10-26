function metrics=axu5ev_closeout_export
% 导出这一组C/真实RTL闭环差异；不重跑历史工况，不平移曲线。
%% 两组实际结果与同一时间网格
root=fileparts(fileparts(mfilename('fullpath')));work=fullfile(root,'.runtime','ax01c');
folder=fullfile(root,'verification','ax01c');if ~isfolder(folder),mkdir(folder);end
a=load(fullfile(work,'c_fixed_continuous.mat'));
b=load(fullfile(work,'c_rtl_continuous.mat'));
t=a.out.r5_commit.Time;assert(isequal(t,b.out.r5_commit.Time));
c1=axu5ev_matrix(a.out.r5_commit);c2=axu5ev_matrix(b.out.r5_commit);
u1=axu5ev_matrix(a.out.r5_snapshot);u2=axu5ev_matrix(b.out.r5_snapshot);
assert(isequal(u1(:,[1:14 16:19]),u2(:,[1:14 16:19])),'两后端命令不同拍。');
assert(isequal(c1(:,24:36),c2(:,24:36)),'两后端命令接受/轨迹状态不一致。');
%% 物理量、参考与应用duty；最大值/RMS使用所有记录点
names={'x_mm','v_mmps','id','iq','duty_u_applied','duty_v_applied','duty_w_applied'};
units={'mm','mm/s','A','A','ratio','ratio','ratio'};
rows=cell(0,5);x1=cell(1,7);x2=cell(1,7);
for k=1:7
    s1=a.out.logsout.get(names{k}).Values;s2=b.out.logsout.get(names{k}).Values;
    assert(isequal(s1.Time,s2.Time));v1=double(s1.Data(:));v2=double(s2.Data(:));
    d=v2-v1;word=NaN;if k>=5,word=max(abs(d))*2^30;end
    rows(end+1,:)={names{k},units{k},max(abs(d)),sqrt(mean(d.^2)),word}; %#ok<AGROW>
    if k<=4
        % 物理日志按自己的时间取同拍值，不把R5行号当成对象日志行号。
        x1{k}=interp1(round(s1.Time/1e-6),v1,round(t/1e-6),'previous');
        x2{k}=interp1(round(s2.Time/1e-6),v2,round(t/1e-6),'previous');
        assert(all(isfinite(x1{k}))&&all(isfinite(x2{k})));
    else
        x1{k}=v1;x2{k}=v2;
    end
end
refs={'x_ref_mm','v_ref_mmps','id_ref_A','iq_ref_A'};cols=[13 3 1 2];
for k=1:4
    d=c2(:,cols(k))-c1(:,cols(k));
    rows(end+1,:)={refs{k},units{k},max(abs(d)),sqrt(mean(d.^2)),NaN}; %#ok<AGROW>
end
metrics=cell2table(rows,'VariableNames',{'signal','unit','max_abs','rms','max_duty_word_error'});
writetable(metrics,fullfile(folder,'differences.csv'));
writetable(struct2table([a.result;b.result]),fullfile(folder,'run_results.csv'));
writetable(a.events,fullfile(folder,'c_fixed_commands.csv'));
writetable(b.events,fullfile(folder,'c_rtl_commands.csv'));
%% 首次Ready按段记录；沿用原5次位置事件，不以停止时刻误差代替
ready=cell(0,6);
for mode=1:2
    if mode==1,c=c1;u=u1;label='c_fixed';else,c=c2;u=u2;label='c_rtl';end
    for seg=1:3
        ix=find(c(:,34)==seg&c(:,31)>0,1);assert(~isempty(ix));
        pos=find(mod(round(t/1e-4),100)==99&(1:numel(t))'<=ix);
        pos=pos(end-4:end);window=max(abs(u(pos,20)-c(pos,24)));
        assert(window<=.02+1e-9&&all(c(pos,30)>0));
        ready(end+1,:)={label,seg,c(ix,24),t(ix),u(ix,20)-c(ix,24),window}; %#ok<AGROW>
    end
end
writetable(cell2table(ready,'VariableNames',{'mode','segment','target_mm','first_ready_s','error_mm','five_event_max_error_mm'}), ...
    fullfile(folder,'ready_events.csv'));
%% 10 ms精简曲线，另保留命令采样点；完整MAT不提交
ix=unique([1:100:numel(t) numel(t) round(a.commands(:,1)'/1e-4)+1]);
curves=table(t(ix),c1(ix,13),x1{1}(ix),x2{1}(ix),c1(ix,3),x1{2}(ix),x2{2}(ix), ...
    c1(ix,1),x1{3}(ix),x2{3}(ix),c1(ix,2),x1{4}(ix),x2{4}(ix), ...
    c1(ix,24),c1(ix,25),c1(ix,31),c1(ix,27),'VariableNames', ...
    {'time_s','x_ref_mm','x_C_mm','x_RTL_mm','v_ref_mmps','v_C_mmps','v_RTL_mmps', ...
    'id_ref_A','id_C_A','id_RTL_A','iq_ref_A','iq_C_A','iq_RTL_A','target_mm','Busy','Ready','status'});
writetable(curves,fullfile(folder,'motion.csv'));
d1=axu5ev_matrix(a.out.duty_result);d2=axu5ev_matrix(b.out.duty_result);
assert(isequal(a.out.duty_result.Time,b.out.duty_result.Time));
fprintf('all-frame duty result max word error %.17g\n',max(abs(d2-d1),[],'all')*2^30);
td=a.out.logsout.get(names{5}).Values.Time;
iy=unique([1:100:numel(td) numel(td)]);
writetable(table(td(iy),x1{5}(iy),x2{5}(iy),x1{6}(iy),x2{6}(iy),x1{7}(iy),x2{7}(iy), ...
    'VariableNames',{'application_s','du_C','du_RTL','dv_C','dv_RTL','dw_C','dw_RTL'}), ...
    fullfile(folder,'applied_duty.csv'));
%% 直接叠加同拍曲线，纵轴自动包含全部数据
f=figure('Visible','off','Position',[100 100 1100 650]);tl=tiledlayout(f,2,1,'TileSpacing','compact');
for k=1:2
    ax=nexttile(tl);plot(ax,t,c1(:,cols(k)),':','LineWidth',1.3);hold(ax,'on');
    plot(ax,t,x1{k},'-','LineWidth',1.1);plot(ax,t,x2{k},'--','LineWidth',1);
    ylabel(ax,units{k});grid(ax,'on');legend(ax,refs{k},'C + fixed FOC','C + actual SV','Interpreter','none');
end
xlabel(ax,'simulation time (s)');title(tl,'10 -> 0 -> -2 mm: identical command times');
exportgraphics(f,fullfile(folder,'motion.png'),'Resolution',140);close(f);
f=figure('Visible','off','Position',[100 100 1100 800]);tl=tiledlayout(f,3,1,'TileSpacing','compact');
for k=3:4
    ax=nexttile(tl);plot(ax,t,c1(:,cols(k)),':','LineWidth',1.2);hold(ax,'on');
    plot(ax,t,x1{k},'-');plot(ax,t,x2{k},'--');ylabel(ax,[names{k} ' (A)']);grid(ax,'on');
    legend(ax,refs{k},'C + fixed FOC','C + actual SV','Interpreter','none');
end
ax=nexttile(tl);plot(ax,td,[x1{5} x1{6} x1{7}]);hold(ax,'on');
plot(ax,td,[x2{5} x2{6} x2{7}],'--');ylabel(ax,'applied duty');grid(ax,'on');
legend(ax,'u C','v C','w C','u RTL','v RTL','w RTL');xlabel(ax,'simulation time (s)');
exportgraphics(f,fullfile(folder,'foc_and_application.png'),'Resolution',140);close(f);
disp(metrics);disp(a.checks);disp(b.checks);
end
