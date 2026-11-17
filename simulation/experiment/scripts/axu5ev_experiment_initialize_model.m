function axu5ev_experiment_initialize_model(model,parameters)
% Assign an explicit parameter snapshot to one independent experiment model.
% The caller chooses when its reviewed source model is saved.
assert(bdIsLoaded(model),'Open the experiment source model first.');
assert(startsWith(model,'AXU5EV_Experiment_') || ...
    strcmp(model,'AXU5EV_Motor_Control_System'),'Expected an experiment source model.');
assert(strcmp(get_param(model,'SimulationStatus'),'stopped'));
workspace=get_param(model,'ModelWorkspace');
workspace.DataSource='Model File';
names=fieldnames(parameters);
for index=1:numel(names)
    name=names{index};
    assignin(workspace,name,parameters.(name));
end
end
