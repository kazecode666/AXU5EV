% 兼容旧外部初始化；参数只在simulation/init_AXU5EV定义。
AXU5EV_Legacy_Root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(AXU5EV_Legacy_Root,'simulation'));
init_AXU5EV;
