function vectors=task1_encoder_vectors()
% Qualified-frame cases from the frozen encoder_position_speed reference.
% Inputs retain uint64 timestamps without conversion through double.
inputs=cell(1,10);expected=cell(1,7);case_ids=zeros(0,1);
for scenario=1:17
    append({uint32(0),uint32(0),uint64(0),false,uint32(0), ...
        uint32(0),false,uint32(0),uint32(1000),true},scenario);
    id=uint32(0);tick=uint64(0);raw=uint32(0);zero=uint32(0);
    reverse=false;version=uint32(1);illegal=uint32(0);scale=uint32(1000);
    if scenario==3,raw=uint32(1000);end
    if scenario==5
        raw=uint32(4294967286);id=uint32(4294966296);
        tick=intmax('uint64')-uint64(25000);
    end
    if scenario==6,raw=uint32(10);end
    for frame=0:85
        ready=true;id_step=uint32(500);tick_step=uint64(5000);
        if scenario==4,reverse=true;end
        if (scenario==7 || scenario==13 || scenario==17) && frame==30
            id_step=uint32(0);tick_step=uint64(0);
        end
        if scenario==8 && frame==30
            id_step=uint32(1000);tick_step=uint64(10000);
        end
        if scenario==9 && frame==30,zero=raw;version=uint32(2);end
        if scenario==10 && frame==30,ready=false;end
        if scenario==11 && frame==30,illegal=uint32(1);end
        if scenario==12 && frame==30,raw=wrap32(raw,2147483648);end
        if scenario==15 && frame==30,reverse=true;version=uint32(2);end
        if scenario==16 && frame==30,scale=uint32(250);end
        if scenario==17 && frame==30,version=uint32(2);end
        if frame>0
            id=wrap32(id,double(id_step));tick=wrap64(tick,tick_step);
            if scenario~=1 && ~((scenario==7 || scenario==17) && frame==30)
                increment=10;
                if scenario==3 || scenario==6 || (scenario==14 && frame>=30)
                    increment=-10;
                end
                if scenario~=12 || frame~=30,raw=wrap32(raw,increment);end
            end
        end
        append({raw,id,tick,ready,illegal,zero,reverse,version,scale,false},scenario);
    end
end
% Preserve origin through an accumulated full raw32 revolution, then change
% version, direction and finally the explicitly supplied mechanical zero.
append({uint32(0),uint32(0),uint64(0),false,uint32(0), ...
    uint32(0),false,uint32(0),uint32(1000),true},18);
raws=uint32([0 2147483647 4294967294 1 2 3 4 5 6 7]);
versions=uint32([1 1 1 1 2 3 4 5 6 7]);
reverses=logical([0 0 0 0 0 1 1 1 0 0]);
zeros_=uint32([0 0 0 0 0 0 4 4 4 4]);
for frame=1:numel(raws)
    append({raws(frame),uint32((frame-1)*500),uint64((frame-1)*5000), ...
        true,uint32(0),zeros_(frame),reverses(frame),versions(frame),uint32(1000),false},18);
end
% Nonintegral identity/timestamp restart rejects the current frame.
append({uint32(0),uint32(0),uint64(0),false,uint32(0), ...
    uint32(0),false,uint32(0),uint32(1000),true},19);
append({uint32(0),uint32(5000),uint64(50000),true,uint32(0), ...
    uint32(0),false,uint32(1),uint32(1000),false},19);
append({uint32(1),uint32(0),uint64(0),true,uint32(0), ...
    uint32(0),false,uint32(1),uint32(1000),false},19);
vectors=struct('inputs',{inputs},'expected',{expected},'case_ids',case_ids, ...
    'frames',numel(case_ids),'scenarios',19);

    function append(args,scenario)
        outputs=cell(1,7);
        [outputs{:}]=encoder_position_speed(args{:});
        for input_index=1:10
            if isempty(inputs{input_index})
                inputs{input_index}=repmat(args{input_index},0,1);
            end
            inputs{input_index}(end+1,1)=args{input_index};
        end
        for output_index=1:7
            if isempty(expected{output_index})
                expected{output_index}=repmat(outputs{output_index},0,1);
            end
            expected{output_index}(end+1,1)=outputs{output_index};
        end
        case_ids(end+1,1)=scenario;
    end
end

function value=wrap32(previous,increment)
value=uint32(mod(double(previous)+increment,4294967296));
end

function value=wrap64(previous,increment)
if intmax('uint64')-previous<increment
    value=increment-(intmax('uint64')-previous)-uint64(1);
else
    value=previous+increment;
end
end
