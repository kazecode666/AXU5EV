%% 加载唯一参数入口
AXU5EV_Simulation_Dir=fileparts(mfilename('fullpath'));
addpath(AXU5EV_Simulation_Dir);
if bdIsLoaded('AXU5EV_Hybrid_ClosedLoop')
    assert(strcmp(get_param('AXU5EV_Hybrid_ClosedLoop','SimulationStatus'),'stopped'), ...
        'AXU5EV:STOP_FIRST','请先停止仿真；暂停时不要重新初始化。');
end
init_AXU5EV;

%% 打开整体闭环；由用户点击 Run
axu5ev_prepare(AXU5EV_Backend);
