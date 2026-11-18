%% Pure simulation entry. Open the current saved source and preserve edits.
AXU5EV_Startup_Dir=fileparts(mfilename('fullpath'));
addpath(AXU5EV_Startup_Dir);
AXU5EV_Startup_Root=axu5ev_simulation_paths(axu5ev_project_root(AXU5EV_Startup_Dir));
AXU5EV_Startup_Model='AXU5EV_Hybrid_ClosedLoop';
if bdIsLoaded(AXU5EV_Startup_Model)
    assert(strcmp(get_param(AXU5EV_Startup_Model,'SimulationStatus'),'stopped'), ...
        'AXU5EV:STOP_FIRST','Stop simulation before changing the entry.');
    assert(strcmpi(get_param(AXU5EV_Startup_Model,'FileName'), ...
        fullfile(AXU5EV_Startup_Root,'simulation','closed_loop',[AXU5EV_Startup_Model '.slx'])), ...
        'AXU5EV:LoadedSource','An existing model with this name comes from another source.');
    if strcmp(get_param(AXU5EV_Startup_Model,'Dirty'),'on')
        open_system(AXU5EV_Startup_Model);
        disp('SIMULATION_OPEN — existing unsaved model and current parameters retained.');
        return;
    end
end
if ~evalin('base','exist(''PMLSM_M1A_InitVersion'',''var'')==1')
    evalin('base','init_AXU5EV;');
end
axu5ev_prepare(evalin('base','AXU5EV_Backend'));
