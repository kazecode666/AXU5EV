function ax01b_build_runtime
% 兼容旧构建入口，使用当前已初始化参数。
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'simulation'));
axu5ev_build_runtime;
end
