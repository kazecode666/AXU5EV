function ax00_compare
root=fileparts(fileparts(mfilename('fullpath')));rows=struct([]);
for b=0:1
 a=load(fullfile(root,'.runtime','ax00',['frozen_' num2str(b)],'signals.mat'));
 c=load(fullfile(root,'.runtime','ax00',['active_' num2str(b)],'signals.mat'));
 names=fieldnames(a.signals);assert(isequal(sort(names),sort(fieldnames(c.signals))));
 for k=1:numel(names)
  x=a.signals.(names{k});y=c.signals.(names{k});sameTime=isequal(x.time,y.time);sameData=isequaln(x.data,y.data);
  row=struct('backend',b,'signal',names{k},'samples',numel(x.time),'time_exact',sameTime,'data_exact',sameData,'max_abs',max(abs(double(x.data(:))-double(y.data(:)))));
  if isempty(rows),rows=row;else,rows(end+1)=row;end
  assert(sameTime&&sameData,'AX00:MISMATCH','Difference in %s backend %d',names{k},b);
 end
end
writetable(struct2table(rows),fullfile(root,'coordination/reports/baseline_comparison.csv'));
disp('AX00_BASELINE_COMPARE_PASS');
end
