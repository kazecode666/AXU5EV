function ax01_format_r5
% 仅整理新R5模型；端口恢复默认30x14，所有Goto保持局部。
m = 'AXU5EV_R5_Control';
pos(m,1044:1057,[60 80 90 94],42);
pos(m,1065:1076,[1520 100 1550 114],48);
pos(m,1017,[610 100 830 400]);
pos(m,509,[610 530 830 1090]);
pos(m,1077,[680 20 740 50]);
pos(m,1043,[680 450 740 480]);
pos(m,1058,[650 1170 690 1190]);
pos(m,1059,[1050 1150 1100 1190]);
pos(m,1061,[650 1250 700 1290]);
pos(m,1060,[650 1350 700 1390]);
pos(m,1062,[1050 1360 1090 1380]);
pos(m,1063,[950 1260 990 1280]);
pos(m,1064,[1420 1230 1470 1290]);
routeTags(m);
pos(m,1137,[750 1450 940 1470]);

motion = Simulink.ID.getFullName([m ':509']);
pos(m,[510 511 512 518 519 520 521 522 523 524 525 526 527 528], ...
    [40 70 70 84],45);
pos(m,818,[600 100 760 280]);
pos(m,921,[1250 100 1430 300]);
pos(m,899,[950 10 1100 80]);
pos(m,857,[600 470 820 870]);
pos(m,812,[1250 470 1290 550]);
pos(m,813,[1250 670 1290 750]);
pos(m,814,[1790 470 1830 550]);
pos(m,815,[1790 670 1830 750]);
pos(m,816,[1250 900 1290 980]);
pos(m,[1014 1015 1016],[2330 510 2360 524],200);
pos(m,530,[380 940 410 960]);
pos(m,809,[380 280 410 300]);
pos(m,[531 811 817],[40 910 220 940],70);
pos(m,[918 919 920],[600 1060 790 1090],70);
pos(m,529,[950 1300 970 1320]);
% 局部From→Goto转接放在独立底部行，避免压住控制路径。
pos(m,[831 852],[1250 1150 1440 1170],70);
pos(m,846,[1790 930 1980 950]);
routeTags(motion);
pos(m,898,[2040 1020 2230 1040]);
for sid = [810 894]
    b = Simulink.ID.getFullName([m ':' num2str(sid)]);
    p = get_param(b,'Position');
    set_param(b,'Position',[p(1:2) p(1)+130 p(4)]);
end
% 对照模型只整理新建的根层；内部原控制/FOC结构保留作比较。
r = 'AXU5EV_R5_Reference';
pos(r,1044:1057,[60 80 90 94],42);
pos(r,1065:1076,[1520 100 1550 114],48);
pos(r,1017,[610 100 830 400]);
pos(r,1078,[610 530 830 1290]);
pos(r,1077,[680 20 740 50]);
pos(r,1043,[680 450 740 480]);
pos(r,1058,[650 1420 690 1440]);
pos(r,1059,[1050 1400 1100 1440]);
pos(r,1061,[650 1500 700 1540]);
pos(r,1060,[650 1600 700 1640]);
pos(r,1062,[1050 1610 1090 1630]);
pos(r,1063,[950 1510 990 1530]);
pos(r,1064,[1420 1480 1470 1540]);
pos(r,1589,[60 750 90 770]);
pos(r,1590:1592,[1550 900 1570 920],70);
routeTags(r);
faultTag = find_system(r,'SearchDepth',1,'BlockType','Goto', ...
    'GotoTag','r5_Alignment_Fault_Active');
set_param(faultTag{1},'Position',[750 1700 940 1720]);
for model = {m,'AXU5EV_R5_Reference'}
    name = model{1};
    ports = find_system(name,'MatchFilter',@Simulink.match.allVariants, ...
        'Regexp','on','BlockType','^(Inport|Outport)$');
    for j = 1:numel(ports)
        p = get_param(ports{j},'Position');
        c = (p(2)+p(4))/2;
        set_param(ports{j},'Position',[p(1) c-7 p(1)+30 c+7]);
    end
    tags = find_system(name,'MatchFilter',@Simulink.match.allVariants,'BlockType','Goto');
    for j = 1:numel(tags)
        set_param(tags{j},'TagVisibility','local','IconDisplay','Tag','ShowName','off');
    end
    lines = find_system(name,'FindAll','on','MatchFilter',@Simulink.match.allVariants,'Type','line');
    Simulink.BlockDiagram.routeLine(lines);
    save_system(name);
end
end

function pos(model,sids,rectangle,dy)
if nargin<4, dy=0; end
for k = 1:numel(sids)
    b = Simulink.ID.getFullName([model ':' num2str(sids(k))]);
    set_param(b,'Position',rectangle+[0 dy*(k-1) 0 dy*(k-1)]);
end
end

function routeTags(scope)
% 根据邻接端口放置短线标签，不移动算法子系统内部。
tags = find_system(scope,'SearchDepth',1,'BlockType','Goto');
for j = 1:numel(tags)
    ph = get_param(tags{j},'PortHandles');
    lh = get_param(ph.Inport,'Line');
    if lh<0, continue; end
    source = get_param(lh,'SrcPortHandle');
    pt = get_param(source,'Position');
    set_param(tags{j},'Orientation','right', ...
        'Position',[pt(1)+45 pt(2)-10 pt(1)+235 pt(2)+10]);
end
tags = find_system(scope,'SearchDepth',1,'BlockType','From');
for j = 1:numel(tags)
    ph = get_param(tags{j},'PortHandles');
    lh = get_param(ph.Outport,'Line');
    if lh<0, continue; end
    destinations = get_param(lh,'DstPortHandle');
    if any(arrayfun(@(p)strcmp(get_param(get_param(p,'Parent'),'BlockType'),'Goto'),destinations))
        continue;
    end
    pt = get_param(destinations(1),'Position');
    set_param(tags{j},'Orientation','right','ShowName','off', ...
        'IconDisplay','Tag','Position',[pt(1)-235 pt(2)-10 pt(1)-45 pt(2)+10]);
end
end
