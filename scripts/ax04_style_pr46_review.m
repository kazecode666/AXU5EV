function result=ax04_style_pr46_review(route_lines)
% Manual PR46 layout for the ISR and its editable feedback subsystem.
% The caller reviews and saves. The user-arranged root geometry is preserved.
if nargin<1,route_lines=true;end
model='AXU5EV_Motor_Control_System';
root=fileparts(fileparts(mfilename('fullpath')));
expected=char(System.IO.Path.GetFullPath(fullfile(root, ...
    'simulation','experiment',[model '.slx'])));
assert(bdIsLoaded(model),'AX04:ReviewLayout','Open the experiment main model first.');
actual=char(System.IO.Path.GetFullPath(get_param(model,'FileName')));
assert(strcmpi(actual,expected),'AX04:ReviewLayout','The open model has another source.');
assert(strcmp(get_param(model,'SimulationStatus'),'stopped'), ...
    'AX04:ReviewLayout','Stop the experiment model before editing its layout.');
isr=find_child(model,'Motor_Control_ISR');
feedback=find_child(isr,'Feedback_Measurement');
assert(strcmp(get_param(feedback,'LinkStatus'),'none'), ...
    'AX04:ReviewLayout','The feedback implementation must be editable at its use site.');

root_before=block_positions(model);
before=algorithm_snapshot(model);
ports_before=port_appearance(model);
style_isr(isr);
style_feedback(feedback);
place_auxiliary_tags(isr);
if route_lines
    route_scope(isr);
    route_scope(feedback);
end
assert(isequal(root_before,block_positions(model)), ...
    'AX04:RootLayout','The user-arranged root block geometry changed.');
assert(isequaln(before,algorithm_snapshot(model)), ...
    'AX04:ReviewLayoutAlgorithm','Algorithm connections, parameters or scripts changed.');
assert(isequaln(ports_before,port_appearance(model)), ...
    'AX04:ReviewLayoutPorts','An ordinary Inport/Outport size or appearance changed.');
result=struct('status','PR46_LAYOUT_APPLIED','model',actual, ...
    'scopes',{{isr,feedback}},'root_geometry_preserved',true, ...
    'connections_parameters_and_scripts_preserved',true, ...
    'ordinary_ports_preserved',true,'saved',false,'dirty',get_param(model,'Dirty'));
disp(result);
end

function style_isr(scope)
area(scope,'isr_initialize','软件初始化与帧中断',[20 10 1650 150]);
area(scope,'isr_measurement','同帧测量与观测',[20 190 1130 950]);
area(scope,'isr_qualification','帧资格与故障锁存',[1160 190 1740 950]);
area(scope,'isr_runtime','对齐、外环与参考管理',[1790 190 2930 950]);
area(scope,'isr_driver','驱动许可、对齐许可与安全处理',[20 1020 2830 1980]);
area(scope,'isr_commit','PL参考封装与版本',[2980 190 4010 1280]);
area(scope,'isr_telemetry','PS最近观测与服务数据',[2870 1390 4010 1980]);

move_port(scope,'PL_Frame_IRQ_Entry',65,65);
move_block(scope,'Controller_Initialized',[390 45 650 95]);
measurements={'raw_count','sample_id','sample_tick','encoder_ready','illegal_count'};
for index=1:numel(measurements)
    move_port(scope,measurements{index},60,258+(index-1)*56);
end
move_block(scope,'Feedback_Measurement',[520 230 800 790]);
settings={'Mechanical_Zero_Count','Encoder_Forward','Encoder_Config_Version', ...
    'Encoder_Nanometres_Per_Count','Measurement_Reset'};
for index=1:numel(settings)
    y=523+(index-1)*56;
    move_block(scope,settings{index},[280 y 460 y+30]);
end
observations={'position_mm','speed_mm_s','position_valid','speed_valid', ...
    'history_count','feedback_status','continuous_count'};
for index=1:numel(observations)
    move_port(scope,observations{index},1000,270+(index-1)*80);
end
move_port(scope,'CommandFrame',1860,252);
move_port(scope,'current_valid',1180,405);
move_port(scope,'ERRI_n',1180,305);
move_port(scope,'ERRU_n',1180,355);
move_port(scope,'clear_fault',1180,655);
move_port(scope,'request_freset',650,1365);
move_port(scope,'request_relcon',650,1225);
move_port(scope,'request_encon',650,1295);
move_port(scope,'request_oe_disable',650,1435);

move_block(scope,'Frame_And_Fault_Qualification',[1270 230 1550 830]);
move_block(scope,'Hard_Travel_Max_mm',[1290 880 1450 910]);
move_block(scope,'Hard_Travel_Min_mm',[1510 880 1670 910]);
move_block(scope,'Bind_Real_Feedback',[2040 290 2320 590]);
move_block(scope,'Qualified_Runtime',[2440 290 2770 710]);
move_block(scope,'Runtime_Advance_Or_Safety',[2520 165 2600 215]);
move_port(scope,'runtime_frame',2860,395);

move_block(scope,'Controller_Driver_IO_Manager',[1100 1120 1400 1680]);
move_block(scope,'Control_Fault',[1620 1150 1700 1230]);
move_block(scope,'Drive_Output_Contract',[1630 1350 1650 1650]);
move_port(scope,'drive_outputs',1760,1500);
move_block(scope,'Alignment_Permit',[2130 1110 2440 1770]);

move_block(scope,'Reference_Commit',[3220 250 3540 1210]);
limits={'Alignment_Id_Limit_A','Debug_Iq_Limit_A','Electrical_Period_mm'};
for index=1:numel(limits)
    y=1030+(index-1)*64;
    move_block(scope,limits{index},[2980 y 3160 y+30]);
end
move_port(scope,'reference_commit',3790,410);
move_port(scope,'commit_sample_id',3790,730);
move_port(scope,'reference_version',3790,1050);
move_block(scope,'Capture_Latest_Observation',[3190 1490 3510 1890]);
move_block(scope,'Store_Latest_Telemetry',[3650 1650 3950 1710]);
end

function style_feedback(scope)
area(scope,'feedback_guard','同帧身份与连续计数',[10 10 670 830]);
area(scope,'feedback_position','机械位置与保持',[710 10 2010 430]);
area(scope,'feedback_speed','51位置、50间隔测速',[710 470 2010 1050]);
area(scope,'feedback_diagnostics','有效性与历史状态',[10 890 670 1290]);

inputs={'raw_count','sample_id','sample_tick','encoder_ready','illegal_count', ...
    'zero_count','reverse','config_version','nm_per_count','reset'};
for index=1:numel(inputs)
    move_port(scope,inputs{index},45,115+(index-1)*65);
end
move_block(scope,'Frame_And_Count_Guard',[285 80 595 730]);
move_block(scope,'Continuous_Position_Count',[770 95 830 155]);
move_block(scope,'Position_Count_To_Double',[900 105 1030 145]);
move_block(scope,'Position_Millimetres',[1120 95 1180 155]);
move_block(scope,'New_Frame_Position',[1280 90 1350 170]);
move_block(scope,'Reset_Position',[1550 90 1620 170]);
move_block(scope,'Position_Hold',[1460 275 1550 325]);
move_block(scope,'Zero',[1300 290 1370 320]);
move_port(scope,'position_mm',1860,130);

move_block(scope,'Delay_50_Intervals',[780 550 920 670]);
move_block(scope,'Count_Difference_50_Intervals',[1000 505 1060 565]);
move_block(scope,'Difference_To_Double',[1120 510 1250 550]);
move_block(scope,'Displacement_Millimetres',[1320 500 1380 560]);
move_block(scope,'Five_Millisecond_Speed',[1450 505 1640 565]);
move_block(scope,'Qualified_Speed',[1730 495 1800 575]);
move_port(scope,'speed_mm_s',1880,535);

move_block(scope,'Scale_To_Double',[780 805 920 845]);
move_block(scope,'Nanometres_To_Millimetres',[1000 800 1210 850]);
move_block(scope,'Mechanical_Direction',[1430 810 1520 910]);
move_block(scope,'Reverse_Direction',[1230 790 1310 820]);
move_block(scope,'Forward_Direction',[1230 910 1310 940]);
diagnostics={'position_valid','speed_valid','history_count','status','continuous_count'};
for index=1:numel(diagnostics)
    move_port(scope,diagnostics{index},590,965+(index-1)*65);
end
end

function block=find_child(scope,name)
blocks=find_system(scope,'SearchDepth',1,'LookUnderMasks','all', ...
    'FollowLinks','off','Type','block','Name',name);
blocks=blocks(~strcmp(blocks,scope));
assert(numel(blocks)==1,'AX04:ReviewLayoutBlock', ...
    'Expected one direct child named %s in %s.',name,scope);
block=blocks{1};
end

function move_block(scope,name,position)
block=find_child(scope,name);
assert(~any(strcmp(get_param(block,'BlockType'),{'Inport','Outport'})), ...
    'AX04:ReviewLayoutPort','Ordinary ports retain their original size.');
set_param(block,'Position',position);
end

function move_port(scope,name,left,center_y)
block=find_child(scope,name);
position=get_param(block,'Position');
port_size=position(3:4)-position(1:2);
top=round(center_y-port_size(2)/2);
set_param(block,'Position',[left top left+port_size(1) top+port_size(2)]);
end

function area(scope,key,title,position)
tag=['AX04_Manual_Layout_' key];
annotations=find_system(scope,'FindAll','on','SearchDepth',1,'Type','annotation');
matching=[];
for index=1:numel(annotations)
    item=get_param(annotations(index),'Object');
    if strcmp(item.Tag,tag),matching(end+1)=annotations(index);end %#ok<AGROW>
end
assert(numel(matching)<=1,'AX04:ReviewLayoutArea','Duplicate layout area tags.');
if isempty(matching)
    handle=add_block('built-in/Area',[scope '/' title], ...
        'Position',[-20000 -20000 -19000 -19000]);
    annotation=get_param(handle,'Object');
    annotation.Tag=tag;
else
    annotation=get_param(matching,'Object');
end
annotation.Name=title;
annotation.FontSize=14;
annotation.FontWeight='bold';
annotation.FixedWidth='on';
annotation.FixedHeight='on';
annotation.BackgroundColor='[0.901961,0.901961,1]';
annotation.Position=position;
end

function route_scope(scope)
% Rebuild geometry from the existing port pairs, discarding stale junctions.
blocks=find_system(scope,'SearchDepth',1,'Type','block');
edges=zeros(0,2);
names={};
for block_index=2:numel(blocks)
    ports=get_param(blocks{block_index},'PortHandles');
    kinds=intersect(fieldnames(ports),{'Inport','Enable','Trigger','Ifaction','Reset'});
    for kind_index=1:numel(kinds)
      inputs=ports.(kinds{kind_index});
      for input_index=1:numel(inputs)
        destination=inputs(input_index);
        line=get_param(destination,'Line');
        if line<0,continue;end
        source=get_param(line,'SrcPortHandle');
        while source<0
            line=get_param(line,'LineParent');
            source=get_param(line,'SrcPortHandle');
        end
        edges(end+1,:)=[source destination]; %#ok<AGROW>
        names{end+1}=get_param(line,'Name'); %#ok<AGROW>
      end
    end
end
lines=find_system(scope,'FindAll','on','SearchDepth',1,'Type','line');
parents=arrayfun(@(line)get_param(line,'LineParent'),lines);
lines=lines(parents<0);
for index=1:numel(lines)
    delete_line(lines(index));
end
for index=1:size(edges,1)
    line=add_line(scope,edges(index,1),edges(index,2),'autorouting','on');
    if ~isempty(names{index}),set_param(line,'Name',names{index});end
end
end

function place_auxiliary_tags(scope)
blocks=find_system(scope,'SearchDepth',1,'BlockType','Goto');
left_publishers={'ERRI_n','ERRU_n','current_valid','clear_fault'};
for index=1:numel(blocks)
    block=blocks{index};
    if ~startsWith(get_param(block,'GotoTag'),'isr_'),continue;end
    ports=get_param(block,'PortHandles');
    line=get_param(ports.Inport,'Line');
    source=get_param(line,'SrcPortHandle');
    while source<0
        line=get_param(line,'LineParent');
        source=get_param(line,'SrcPortHandle');
    end
    parent=get_param(source,'Parent');
    position=get_param(parent,'Position');
    parent_ports=get_param(parent,'PortHandles');
    center=round(position(2)+(get_param(source,'PortNumber')-0.5)* ...
        (position(4)-position(2))/numel(parent_ports.Outport));
    if any(strcmp(get_param(parent,'Name'),left_publishers))
        set_param(block,'Orientation','left','Position',[950 center-9 1130 center+9]);
    else
        set_param(block,'Orientation','right', ...
            'Position',[position(3)+20 center+15 position(3)+200 center+33]);
    end
end
end

function records=block_positions(scope)
blocks=find_system(scope,'SearchDepth',1,'Type','block');
blocks=sort(blocks(~strcmp(blocks,scope)));
records=cell(numel(blocks),2);
for index=1:numel(blocks)
    records(index,:)={blocks{index},get_param(blocks{index},'Position')};
end
end

function result=algorithm_snapshot(model)
blocks=sort(find_system(model,'LookUnderMasks','all','FollowLinks','off','Type','block'));
records=cell(numel(blocks),1);
connections=cell(0,1);
for index=1:numel(blocks)
    block=blocks{index};
    handles=get_param(block,'PortHandles');
    kinds=fieldnames(handles);
    parameters=get_param(block,'DialogParameters');
    values=struct;
    names={};
    if ~isempty(parameters),names=fieldnames(parameters);end
    for parameter_index=1:numel(names)
        name=names{parameter_index};
        values.(name)=get_param(block,name);
    end
    available=get_param(block,'ObjectParameters');
    semantics={'SampleTime','InitialCondition','InitialOutput','OutputWhenDisabled', ...
        'StatesWhenEnabling','TriggerType','GotoTag','TagVisibility','OutDataTypeStr'};
    for parameter_index=1:numel(semantics)
        name=semantics{parameter_index};
        if isfield(available,name),values.(name)=get_param(block,name);end
    end
    records{index}=struct('path',block,'type',get_param(block,'BlockType'), ...
        'parameters',values,'port_kinds',{kinds}, ...
        'port_counts',cellfun(@(kind)numel(handles.(kind)),kinds));
    destinations=intersect(kinds,{'Inport','Enable','Trigger','Ifaction','Reset'},'stable');
    for kind_index=1:numel(destinations)
        kind=destinations{kind_index};
        ports=handles.(kind);
        for port_index=1:numel(ports)
            line=get_param(ports(port_index),'Line');
            if line<0,continue;end
            source=get_param(line,'SrcPortHandle');
            while source<0 && get_param(line,'LineParent')>=0
                line=get_param(line,'LineParent');
                source=get_param(line,'SrcPortHandle');
            end
            assert(source>=0,'AX04:ReviewLayoutLine','A connected input has no source.');
            connections{end+1,1}=sprintf('%s|%d -> %s|%s|%d', ...
                get_param(source,'Parent'),get_param(source,'PortNumber'), ...
                block,kind,port_index); %#ok<AGROW>
        end
    end
end
charts=find(sfroot,'-isa','Stateflow.EMChart');
scripts=cell(0,2);
for index=1:numel(charts)
    if startsWith(charts(index).Path,[model '/'])
        scripts(end+1,:)={charts(index).Path,charts(index).Script}; %#ok<AGROW>
    end
end
if ~isempty(scripts),scripts=sortrows(scripts,1);end
charts=find(sfroot,'-isa','Stateflow.Chart');
stateflow=cell(0,1);
for chart_index=1:numel(charts)
    chart=charts(chart_index);
    if ~startsWith(chart.Path,[model '/']),continue;end
    states=find(chart,'-isa','Stateflow.State');
    for state_index=1:numel(states)
        state=states(state_index);
        stateflow{end+1,1}=sprintf('%s|state|%d|%s', ...
            chart.Path,state.Id,state.LabelString); %#ok<AGROW>
    end
    transitions=find(chart,'-isa','Stateflow.Transition');
    for transition_index=1:numel(transitions)
        transition=transitions(transition_index);
        stateflow{end+1,1}=sprintf('%s|transition|%d|%d|%s', ...
            chart.Path,transition.Id,transition.ExecutionOrder,transition.LabelString); %#ok<AGROW>
    end
end
result=struct('blocks',{records},'connections',{sort(connections)}, ...
    'scripts',{scripts},'stateflow',{sort(stateflow)});
end

function records=port_appearance(model)
blocks=sort(find_system(model,'LookUnderMasks','all','FollowLinks','off','Type','block'));
properties={'Orientation','ShowName','NamePlacement','ForegroundColor', ...
    'BackgroundColor','IconDisplay','FontName','FontSize','Port','PortDimensions','OutDataTypeStr'};
records=cell(0,1);
for index=1:numel(blocks)
    block=blocks{index};
    if ~any(strcmp(get_param(block,'BlockType'),{'Inport','Outport'})),continue;end
    position=get_param(block,'Position');
    record=struct('path',block,'size',position(3:4)-position(1:2));
    available=get_param(block,'ObjectParameters');
    for property_index=1:numel(properties)
        name=properties{property_index};
        if isfield(available,name),record.(name)=get_param(block,name);end
    end
    records{end+1,1}=record; %#ok<AGROW>
end
end
