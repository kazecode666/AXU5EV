function result=axu5ev_experiment_check_r5_source(model)
% Verify the editable R5 implementations used by the experiment main model.
assert(bdIsLoaded(model),'AX04:R5Source','Open the experiment main model first.');
components={'Feedback_Measurement','Controller_Driver_IO_Manager','Travel_Safety_Manager'};
instances=cell(1,numel(components));
for index=1:numel(components)
    blocks=find_system(model,'LookUnderMasks','all','FollowLinks','off', ...
        'Type','block','Name',components{index});
    assert(numel(blocks)==1,'AX04:R5Instance', ...
        'Expected one editable use-site implementation of %s.',components{index});
    instance=blocks{1};
    assert(strcmp(get_param(instance,'LinkStatus'),'none') && ...
        isempty(get_param(instance,'ReferenceBlock')),'AX04:R5Editable', ...
        'The active R5 component is still linked to a source library: %s',instance);
    instances{index}=instance;
end

blocks=find_system(model,'LookUnderMasks','all','FollowLinks','off','Type','block');
for index=1:numel(blocks)
    reference=get_param(blocks{index},'ReferenceBlock');
    assert(~any(startsWith(reference,{'AXU5EV_','PMLSM_'})), ...
        'AX04:R5LibrarySource','A project library remains in the active R5 algorithm: %s',reference);
end
references=find_system(model,'LookUnderMasks','all','FollowLinks','off','BlockType','ModelReference');
assert(isempty(references),'AX04:R5ModelSource', ...
    'The R5 generation model must contain its editable algorithm at the use site.');

charts=find(sfroot,'-isa','Stateflow.EMChart');
scripts=struct('path',{},'local_functions',{});
for index=1:numel(charts)
    chart=charts(index);
    if ~startsWith(chart.Path,[model '/']),continue;end
    script=chart.Script;
    declarations=regexp(script, ...
        '(?m)^\s*function\s+(?:\[[^\]]+\]\s*=\s*|[A-Za-z]\w*\s*=\s*)?([A-Za-z]\w*)\s*\(', ...
        'tokens');
    local_functions=cellfun(@(token)token{1},declarations,UniformOutput=false);
    statements=regexprep(script,'(?m)%[^\r\n]*','');
    calls=regexp(statements,'(?<!\w)(axu5ev_experiment_\w+)\s*\(','tokens');
    names=cellfun(@(token)token{1},calls,UniformOutput=false);
    external=setdiff(names,local_functions);
    assert(isempty(external),'AX04:R5FunctionSource', ...
        'The MATLAB Function still calls external per-sample code: %s / %s', ...
        chart.Path,strjoin(external,', '));
    scripts(end+1)=struct('path',chart.Path,'local_functions',{local_functions}); %#ok<AGROW>
end
assert(~isempty(scripts),'AX04:R5FunctionSource','The main model contains no MATLAB Function algorithms.');
[~,order]=sort({scripts.path});
scripts=scripts(order);
result=struct('status','MAIN_LOCAL_R5_SOURCE_PASS','editable_instances',{instances}, ...
    'project_library_links',0,'model_references',0,'matlab_function_blocks',scripts, ...
    'checked_function_namespace','axu5ev_experiment_*','external_per_sample_calls',0);
end
