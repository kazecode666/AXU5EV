function result=ax04_validate_runtime_copy(source_model,copied_subsystem,output_dir)
% Compare the copied Runtime graph before its IRQ and B2 adaptations.
assert(~isfolder(output_dir) && ~isfile(output_dir), ...
    'AX04:Output','Choose a new copy-validation directory.');
source=describe_graph(source_model);
copied=describe_graph(copied_subsystem);
assert(isequaln(source,copied),'AX04:RuntimeCopy', ...
    'The initial Runtime copy differs from its source graph.');
mkdir(output_dir);
result=struct('status','PASS','source',source_model, ...
    'copy',copied_subsystem,'blocks',numel(source.blocks), ...
    'connections',size(source.connections,1), ...
    'stage','Before IRQ, driver/travel and AQM30-B2 adaptations');
stream=fopen(fullfile(output_dir,'runtime_copy.json'),'w');
assert(stream>=0,'AX04:Output','Cannot create copy-validation result.');
cleanup=onCleanup(@()fclose(stream)); %#ok<NASGU>
fprintf(stream,'%s\n',jsonencode(result,PrettyPrint=true));
disp(result);
end

function graph=describe_graph(scope)
paths=find_system(scope,'LookUnderMasks','all','FollowLinks','off','Type','block');
paths=paths(~strcmp(paths,scope));
relative=cellfun(@(name)name(numel(scope)+2:end),paths,UniformOutput=false);
[relative,order]=sort(relative);
paths=paths(order);
blocks=cell(size(paths));
connections=cell(0,4);
charts=find(sfroot,'-isa','Stateflow.EMChart');
state_charts=find(sfroot,'-isa','Stateflow.Chart');
for index=1:numel(paths)
    block=paths{index};
    record=struct('path',relative{index},'type',get_param(block,'BlockType'));
    dialog=get_param(block,'DialogParameters');
    record.parameters=struct;
    if ~isempty(dialog)
        names=sort(fieldnames(dialog));
        for parameter_index=1:numel(names)
            name=names{parameter_index};
            record.parameters.(name)=get_param(block,name);
        end
    end
    record.script='';
    matching=charts(strcmp({charts.Path},block));
    if ~isempty(matching),record.script=matching.Script;end
    record.stateflow=struct;
    matching=state_charts(strcmp({state_charts.Path},block));
    if ~isempty(matching),record.stateflow=describe_stateflow(matching);end
    blocks{index}=record;
    handles=get_param(block,'PortHandles');
    destination_kinds=intersect(fieldnames(handles), ...
        {'Inport','Enable','Trigger','Ifaction','Reset'},'stable');
    for kind_index=1:numel(destination_kinds)
        kind=destination_kinds{kind_index};
        ports=handles.(kind);
        for port_index=1:numel(ports)
            line=get_param(ports(port_index),'Line');
            if line<0,continue;end
            source_port=get_param(line,'SrcPortHandle');
            if source_port<0,continue;end
            source_block=get_param(source_port,'Parent');
            assert(startsWith(source_block,[scope '/']), ...
                'AX04:CopyBoundary','A Runtime connection leaves the compared scope.');
            connections(end+1,:)={ ...
                source_block(numel(scope)+2:end),get_param(source_port,'PortNumber'), ...
                relative{index},[kind num2str(port_index)]}; %#ok<AGROW>
        end
    end
end
graph=struct('blocks',{blocks},'connections',{connections});
end

function result=describe_stateflow(chart)
result=struct;
kinds={'State','Transition','Junction','Data','Event'};
properties={'Name','LabelString','Scope','Trigger','ExecutionOrder', ...
    'Decomposition','Position','IsSubchart','Type'};
for kind_index=1:numel(kinds)
    kind=kinds{kind_index};
    elements=chart.find('-isa',['Stateflow.' kind]);
    records=cell(1,numel(elements));
    for index=1:numel(elements)
        element=elements(index);
        record=struct;
        for property_index=1:numel(properties)
            name=properties{property_index};
            if isprop(element,name),record.(name)=element.(name);end
        end
        if strcmp(kind,'Transition')
            record.source=endpoint(element.Source);
            record.destination=endpoint(element.Destination);
        elseif strcmp(kind,'Data')
            record.size=element.Props.Array.Size;
            record.initial=element.Props.InitialValue;
            record.type_method=element.Props.Type.Method;
            record.primitive=element.Props.Type.Primitive;
            record.expression=element.Props.Type.Expression;
        end
        records{index}=jsonencode(record);
    end
    result.(kind)=sort(records);
end
end

function result=endpoint(element)
result=struct;
if isempty(element),return;end
result.class=class(element);
if isprop(element,'Name'),result.name=element.Name;end
if isprop(element,'Position'),result.position=element.Position;end
end
