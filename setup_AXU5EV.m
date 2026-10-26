function root=setup_AXU5EV
% 仅加入本工程活动算法和验证入口，不改参数或模型。
root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'simulation'),fullfile(root,'simulink模型'),fullfile(root,'scripts'));
end
