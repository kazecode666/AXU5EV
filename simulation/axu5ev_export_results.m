function axu5ev_export_results
% 仅导出本轮必要结果；完整波形留.runtime，不改历史证据。
%% 汇总本轮指定工况
root=fileparts(fileparts(mfilename('fullpath')));
work=fullfile(root,'.runtime','issue8');folder=fullfile(root,'verification','issue8');
if ~isfolder(folder),mkdir(folder);end
files={'model_fixed_default','c_fixed_continuous','c_fixed_reset_release', ...
    'c_fixed_reset_moving','c_fixed_restart_short'};
rows=struct([]);checks=struct([]);
for k=1:numel(files)
    a=load(fullfile(work,[files{k} '.mat']),'out','result');
    rows=[rows;a.result]; %#ok<AGROW>
    b=axu5ev_verify_run(a.out);b.case_name=files{k};checks=[checks;b]; %#ok<AGROW>
end
writetable(struct2table(rows),fullfile(folder,'run_results.csv'));
writetable(struct2table(checks),fullfile(folder,'feedback_and_application.csv'));
%% 修复前10秒与修复后默认5秒分别完整显示
a=load(fullfile(work,'before_model_10mm.mat'),'ax_before_model');
positionPlot(a.ax_before_model,'修复前：10 mm，10 s原参数','before_10mm');
a=load(fullfile(work,'model_fixed_default.mat'),'out');
positionPlot(a.out,'修复后：默认10 mm / 5 s / V10 / A100','after_10mm');
a=load(fullfile(work,'c_fixed_continuous.mat'),'out');
positionPlot(a.out,'生成C：同Run 10 → 0 → −2 mm；Busy拒绝11 mm','continuous');
%% 运动中复位/释放：保留原中断与参考保持
a=load(fullfile(work,'c_fixed_reset_moving.mat'),'out');
positionPlot(a.out,'运动中PI_Reset：0.30 s置1，0.35 s释放','reset_moving');

function positionPlot(out,caption,name)
    c=axu5ev_matrix(out.r5_commit);t=out.r5_commit.Time;
    x=out.logsout.get('x_mm').Values;
    f=figure('Visible','off','Position',[100 100 1050 480]);ax=axes(f);
    plot(ax,t,c(:,13),'--','LineWidth',1.4,'DisplayName','x_ref_mm');hold(ax,'on');
    plot(ax,x.Time,double(x.Data),'LineWidth',1.2,'DisplayName','x_mm');
    plot(ax,t,c(:,24),':','LineWidth',1,'DisplayName','accepted_target_mm');
    title(ax,caption,'Interpreter','none');xlabel(ax,'仿真时间 (s)');ylabel(ax,'位置 (mm)');
    grid(ax,'on');legend(ax,'show','Location','best','Interpreter','none');ax.FontSize=12;
    if strcmp(name,'reset_moving')
        xline(ax,.3,':','PI_Reset=1','HandleVisibility','off');
        xline(ax,.35,':','PI_Reset=0','HandleVisibility','off');
    end
    exportgraphics(f,fullfile(folder,[name '.png']),'Resolution',150);close(f);
    % 10ms精简曲线；未裁切纵轴，也未改变仿真记录。
    ix=unique([1:100:numel(t) numel(t)]);
    x_same=interp1(round(x.Time/1e-6),double(x.Data(:)),round(t(ix)/1e-6),'previous');
    assert(all(isfinite(x_same)));
    tab=table(t(ix),c(ix,13),x_same, ...
        c(ix,24),c(ix,25),c(ix,31),c(ix,27),'VariableNames', ...
        {'time_s','x_ref_mm','x_mm','accepted_target_mm','Busy','Ready','command_status'});
    writetable(tab,fullfile(folder,[name '.csv']));
end
end
