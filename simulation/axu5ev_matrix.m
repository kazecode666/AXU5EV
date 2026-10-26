function d=axu5ev_matrix(ts)
% 统一模型向量与C行向量的timeseries存储方向。
d=double(ts.Data);
if size(d,1)~=numel(ts.Time),d=reshape(d,[],numel(ts.Time))';end
end
