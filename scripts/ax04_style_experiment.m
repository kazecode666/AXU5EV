function result=ax04_style_experiment(selection,route_lines)
% Apply the AX-04 manual layout to the canonical experiment main model.
% The caller reviews and saves the resulting in-memory layout.
if nargin<1,selection='both';end
if nargin<2,route_lines=true;end
selection=validatestring(selection,{'root','isr','both','driver'});
root=fileparts(fileparts(mfilename('fullpath')));
if strcmp(selection,'driver')
    model='AXU5EV_Experiment_R5_Algorithms';
    expected=fullfile(root,'simulation','experiment','r5',[model '.slx']);
else
    model='AXU5EV_Motor_Control_System';
    expected=fullfile(root,'simulation','experiment',[model '.slx']);
end
expected=char(System.IO.Path.GetFullPath(expected));
assert(bdIsLoaded(model),'AX04:LayoutSource','Load the canonical experiment source first.');
actual=char(System.IO.Path.GetFullPath(get_param(model,'FileName')));
assert(strcmpi(actual,expected),'AX04:LayoutSource','The open model is outside simulation/experiment.');
assert(strcmp(get_param(model,'SimulationStatus'),'stopped'), ...
    'AX04:LayoutRunning','Stop the experiment main model before applying its layout.');
before=algorithm_snapshot(model);
ports_before=port_appearance(model);
scopes={};
if strcmp(selection,'driver')
    set_param(model,'Lock','off');
    driver=find_child(model,'Controller_Driver_IO_Manager');
    style_driver(driver);
    scopes{end+1}=driver;
end
if any(strcmp(selection,{'root','both'}))
    style_root(model);
    scopes{end+1}=model;
end
if any(strcmp(selection,{'isr','both'}))
    isr=find_child(model,'Motor_Control_ISR');
    style_isr(isr);
    scopes{end+1}=isr;
end
if route_lines
    for index=1:numel(scopes)
        lines=find_system(scopes{index},'FindAll','on','SearchDepth',1,'Type','line');
        if ~isempty(lines)
            parents=arrayfun(@(line)get_param(line,'LineParent'),lines);
            Simulink.BlockDiagram.routeLine(lines(parents<0));
        end
    end
    if any(strcmp(selection,{'root','both'})),route_function_calls(model);end
end
after=algorithm_snapshot(model);
assert(isequaln(before,after),'AX04:LayoutStructure', ...
    'The block interfaces, signal connections or MATLAB Function scripts changed.');
assert(isequaln(ports_before,port_appearance(model)),'AX04:LayoutPorts', ...
    'An Inport or Outport size or appearance changed.');
result=struct('status','LAYOUT_APPLIED','model',actual,'scopes',{scopes}, ...
    'routing_requested',logical(route_lines),'structure_preserved',true, ...
    'normal_port_appearance_preserved',true,'dirty',get_param(model,'Dirty'), ...
    'saved',false);
disp(result);
end

function style_driver(scope)
area(scope,'driver_inputs','输入与故障采集',[20 80 420 1130]);
area(scope,'driver_latch','故障锁存与禁止',[480 80 1480 1130]);
area(scope,'driver_outputs','驱动输出',[1540 80 2080 1130]);
disable_preview(scope,'External_Fault_Latch');
inputs={'ERRI_n',200;'ERRU_n',260;'clear_fault',350; ...
    'system_fault_latch',470;'request_relcon',610;'request_encon',730; ...
    'request_freset',840;'request_oe_disable',1000};
for index=1:size(inputs,1)
    move_port(scope,inputs{index,1},60,inputs{index,2});
end
positions={ ...
    'ERRI_Raw_Goto',[260 185 345 215]; ...
    'ERRU_Raw_Goto',[260 245 345 275]; ...
    'ERRI_Raw_From',[500 190 585 220]; ...
    'ERRU_Raw_From',[500 250 585 280]; ...
    'External_Fault_Latch',[700 180 940 360]; ...
    'System_Fault_Active',[620 450 720 500]; ...
    'Reset_Or_System_Inhibit',[840 450 900 510]; ...
    'System_Fault_Not',[1020 450 1080 510]; ...
    'Drive_Safe_Goto',[1190 465 1275 495]; ...
    'Outside_Driver_Reset',[650 810 710 870]; ...
    'Fault_OE_Inhibit_Outside_Reset',[1050 790 1110 850]; ...
    'Drive_Safe_RELCON',[1580 620 1665 644]; ...
    'Drive_Safe_ENCON',[1580 740 1665 764]; ...
    'RELCON_Safe_Enable',[1750 580 1810 650]; ...
    'ENCON_Safe_Enable',[1750 700 1810 770]; ...
    sprintf('Logical\nOperator'),[1750 980 1810 1040]};
for index=1:size(positions,1)
    move_block(scope,positions{index,1},positions{index,2});
end
outputs={'external_fault_latch',270;'RELCON',615;'ENCON',735; ...
    'F_Reset',890;'OE_Disable',1010};
for index=1:size(outputs,1)
    move_port(scope,outputs{index,1},1900,outputs{index,2});
end
notes=find_system(scope,'FindAll','on','SearchDepth',1,'Type','annotation');
for index=1:numel(notes)
    note=get_param(notes(index),'Object');
    if strcmp(note.AnnotationType,'area_annotation'),continue;end
    text=lower(strtrim(note.Name));
    if startsWith(text,'oe_disable')
        origin=[1590 1070];
    elseif startsWith(text,'f_reset')
        origin=[1590 930];
    elseif startsWith(text,'encon')
        origin=[1590 790];
    elseif startsWith(text,'relcon')
        origin=[1590 670];
    elseif startsWith(text,'erri_n')
        origin=[60 1060];
    elseif startsWith(text,'/oe')
        origin=[500 1090];
    else
        continue;
    end
    original=note.Position;
    note.Position=[origin origin+original(3:4)-original(1:2)];
end
end

function style_root(scope)
area(scope,'root_initialize','初始化与中断入口',[20 30 1120 280]);
area(scope,'root_inputs','采样、测量与命令输入',[20 310 560 1260]);
area(scope,'root_realtime','实时控制、对齐与驱动行程',[600 300 1130 1270]);
area(scope,'root_pl','PL接口与反馈观测',[1180 310 1610 1270]);
area(scope,'root_service','非实时服务入口',[20 1320 560 1660]);
area(scope,'root_telemetry','记录与通信',[600 1320 1610 1810]);
disable_preview(scope,'Initialize_Controller');
disable_preview(scope,'NonRealtime_Service');
move_block(scope,'Initialize_Controller',[280 80 510 180]);
move_block(scope,'Initialized',[650 100 850 150]);
move_block(scope,'LatestTelemetry',[650 1710 900 1760]);
move_block(scope,'Motor_Control_ISR',[650 330 1080 1230]);
move_block(scope,'NonRealtime_Service',[650 1440 1080 1620]);
move_port(scope,'PL_Frame_IRQ',500,245);
move_port(scope,'Service_Request',500,1365);
inputs={'CommandFrame','raw_count','sample_id','sample_tick','encoder_ready', ...
    'illegal_count','current_valid','ERRI_n','ERRU_n','clear_fault', ...
    'request_relcon','request_encon','request_freset','request_oe_disable'};
for index=1:numel(inputs)
    move_port(scope,inputs{index},70,380+(index-1)*60);
end
outputs={'runtime_frame','position_mm','speed_mm_s','position_valid','speed_valid', ...
    'history_count','feedback_status','continuous_count','reference_commit', ...
    'commit_sample_id','reference_version','drive_outputs'};
for index=1:numel(outputs)
    move_port(scope,outputs{index},1430,380+(index-1)*73);
end
move_port(scope,'telemetry',1430,1500);
move_port(scope,'service_count',1430,1570);
end

function style_isr(scope)
area(scope,'isr_initialize','初始化与中断',[20 20 1060 170]);
area(scope,'isr_measurement','采集测量',[20 210 1060 910]);
area(scope,'isr_runtime','对齐、外环与参考管理',[1120 300 2030 910]);
area(scope,'isr_driver','驱动与行程保护',[20 950 1700 1740]);
area(scope,'isr_commit','PL接口与同帧参考提交',[2070 300 3080 1390]);
area(scope,'isr_telemetry','记录与通信',[1770 1450 3080 1860]);
move_port(scope,'PL_Frame_IRQ_Entry',80,90);
move_block(scope,'Controller_Initialized',[350 70 600 115]);

measurement_inputs={'raw_count','sample_id','sample_tick','encoder_ready','illegal_count'};
for index=1:numel(measurement_inputs)
    move_port(scope,measurement_inputs{index},60,305+(index-1)*40);
end
move_block(scope,'Feedback_Measurement',[500 260 740 720]);
constants={'Mechanical_Zero_Count','Encoder_Forward','Encoder_Config_Version', ...
    'Encoder_Nanometres_Per_Count','Measurement_Reset'};
for index=1:numel(constants)
    y=490+(index-1)*50;
    move_block(scope,constants{index},[270 y 430 y+30]);
end
measurement_outputs={'position_mm','speed_mm_s','position_valid','speed_valid', ...
    'history_count','feedback_status','continuous_count'};
for index=1:numel(measurement_outputs)
    move_port(scope,measurement_outputs{index},940,280+(index-1)*80);
end
move_port(scope,'CommandFrame',60,855);
move_block(scope,'Bind_Real_Feedback',[1220 520 1480 720]);
move_block(scope,'Qualified_Runtime',[1610 520 1910 820]);
move_port(scope,'runtime_frame',1960,640);

driver_inputs={'current_valid','ERRI_n','ERRU_n','clear_fault', ...
    'request_relcon','request_encon','request_freset','request_oe_disable'};
for index=1:numel(driver_inputs)
    move_port(scope,driver_inputs{index},60,1000+(index-1)*60);
end
move_block(scope,'Frame_And_Fault_Qualification',[640 1040 920 1660]);
move_block(scope,'Hard_Travel_Max_mm',[350 1520 530 1550]);
move_block(scope,'Hard_Travel_Min_mm',[350 1580 530 1610]);
move_block(scope,'Controller_Driver_IO_Manager',[1110 1290 1350 1660]);
move_block(scope,'Control_Fault',[1450 1100 1520 1170]);
move_block(scope,'Drive_Output_Contract',[1470 1390 1490 1570]);
move_port(scope,'drive_outputs',1580,1480);

move_block(scope,'Reference_Commit',[2410 760 2710 1280]);
limits={'Alignment_Id_Limit_A','Debug_Iq_Limit_A','Electrical_Period_mm'};
for index=1:numel(limits)
    y=1130+(index-1)*55;
    move_block(scope,limits{index},[2130 y 2320 y+30]);
end
move_port(scope,'reference_commit',2870,850);
move_port(scope,'commit_sample_id',2870,1020);
move_port(scope,'reference_version',2870,1190);
move_block(scope,'Capture_Latest_Observation',[2300 1520 2590 1790]);
move_block(scope,'Store_Latest_Telemetry',[2780 1610 3040 1660]);
end

function disable_preview(scope,name)
block=find_child(scope,name);
available=get_param(block,'ObjectParameters');
if isfield(available,'ContentPreviewEnabled')
    set_param(block,'ContentPreviewEnabled','off');
end
end

function route_function_calls(scope)
names={'PL_Frame_IRQ','Motor_Control_ISR';'Service_Request','NonRealtime_Service'};
for index=1:size(names,1)
    source=find_child(scope,names{index,1});
    target=find_child(scope,names{index,2});
    source_ports=get_param(source,'PortHandles');
    target_ports=get_param(target,'PortHandles');
    assert(numel(source_ports.Outport)==1 && numel(target_ports.Trigger)==1, ...
        'AX04:LayoutCall','Expected one function-call source and trigger.');
    line=get_param(source_ports.Outport,'Line');
    assert(line>=0 && any(get_param(line,'DstPortHandle')==target_ports.Trigger), ...
        'AX04:LayoutCall','The existing function-call connection differs.');
    source_position=get_param(source,'Position');
    target_position=get_param(target,'Position');
    start=[source_position(3),round(mean(source_position([2 4])))];
    finish=[round(mean(target_position([1 3]))),target_position(2)];
    points=[start;finish(1) start(2);finish];
    points=points([true;any(diff(points,1,1)~=0,2)],:);
    set_param(line,'Points',points);
end
end

function path=find_child(scope,name)
paths=find_system(scope,'SearchDepth',1,'LookUnderMasks','all', ...
    'FollowLinks','off','Type','block','Name',name);
paths=paths(~strcmp(paths,scope));
assert(numel(paths)==1,'AX04:LayoutName', ...
    'Expected one direct child named %s in %s.',name,scope);
path=paths{1};
end

function move_block(scope,name,position)
block=find_child(scope,name);
assert(~any(strcmp(get_param(block,'BlockType'),{'Inport','Outport'})), ...
    'AX04:LayoutPort','Use size-preserving placement for ordinary ports.');
set_param(block,'Position',position);
end

function move_port(scope,name,left,center_y)
block=find_child(scope,name);
original=get_param(block,'Position');
width=original(3)-original(1);
height=original(4)-original(2);
top=round(center_y-height/2);
set_param(block,'Position',[left top left+width top+height]);
end

function area(scope,key,title,position)
tag=['AX04_Manual_Layout_' key];
handles=find_system(scope,'FindAll','on','SearchDepth',1,'Type','annotation');
matching=[];
for index=1:numel(handles)
    annotation=get_param(handles(index),'Object');
    if strcmp(annotation.Tag,tag),matching(end+1)=handles(index);end %#ok<AGROW>
end
assert(numel(matching)<=1,'AX04:LayoutArea','Duplicate AX-04 layout area tags.');
if isempty(matching)
    handle=add_block('built-in/Area',[scope '/' title], ...
        'Position',[-20000 -20000 -19000 -19000]);
    annotation=get_param(handle,'Object');
else
    annotation=get_param(matching,'Object');
end
assert(strcmp(annotation.AnnotationType,'area_annotation'), ...
    'AX04:LayoutArea','The tagged AX-04 annotation is not an area.');
annotation.Tag=tag;
annotation.Description=['AX-04 manual layout area ' key];
annotation.FontSize=14;
annotation.FontWeight='bold';
annotation.FixedWidth='on';
annotation.FixedHeight='on';
annotation.Position=position;
annotation.BackgroundColor='[0.901961,0.901961,1]';
end

function result=algorithm_snapshot(model)
blocks=find_system(model,'LookUnderMasks','all','FollowLinks','off','Type','block');
blocks=sort(blocks);
records=cell(numel(blocks),1);
connections=cell(0,1);
for index=1:numel(blocks)
    block=blocks{index};
    handles=get_param(block,'PortHandles');
    kinds=fieldnames(handles);
    widths=cellfun(@(kind)numel(handles.(kind)),kinds);
    records{index}=struct('path',block,'type',get_param(block,'BlockType'), ...
        'port_kinds',{kinds},'port_counts',widths);
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
            source_description='unconnected';
            if source>=0
                source_description=sprintf('%s|%d', ...
                    get_param(source,'Parent'),get_param(source,'PortNumber'));
            end
            connections{end+1,1}=sprintf('%s -> %s|%s|%d', ...
                source_description,block,kind,port_index); %#ok<AGROW>
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
result=struct('blocks',{records},'connections',{sort(connections)},'scripts',{scripts});
end

function result=port_appearance(model)
blocks=find_system(model,'LookUnderMasks','all','FollowLinks','off','Type','block');
blocks=sort(blocks);
result=cell(0,1);
properties={'Orientation','ShowName','NamePlacement','ForegroundColor', ...
    'BackgroundColor','IconDisplay','FontName','FontSize','Port','PortDimensions','OutDataTypeStr'};
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
    result{end+1,1}=record; %#ok<AGROW>
end
end
