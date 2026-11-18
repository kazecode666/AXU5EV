function [continuous_count,origin_count,advance,restart_history,position_valid,speed_valid,history_count,status] = axu5ev_experiment_encoder_guard(raw_count,sample_id,sample_tick,encoder_ready,illegal_count,zero_count,reverse,config_version,nm_per_count,reset)
%#codegen
% Frame qualification and modulo-count adaptation for the visible DSP graph.
% Position scaling, the 50-interval difference and speed scaling live in SLX.
% Retains the qualified-frame behavior of encoder_position_speed.
persistent initialized last_raw last_id last_tick last_bad total origin
persistent old_zero old_reverse old_version old_scale filled
if isempty(initialized)
    initialized=false;
    last_raw=uint32(0);last_id=uint32(0);last_tick=uint64(0);last_bad=uint32(0);
    total=int64(0);origin=int64(0);old_zero=uint32(0);old_reverse=false;
    old_version=uint32(0);old_scale=uint32(0);filled=uint8(0);
end
continuous_count=total;origin_count=origin;
advance=false;restart_history=false;position_valid=false;speed_valid=false;
history_count=filled;status=uint32(0);
if reset
    initialized=false;filled=uint8(0);total=int64(0);origin=int64(0);
    continuous_count=int64(0);origin_count=int64(0);history_count=uint8(0);
    restart_history=true;
    return;
end
if ~encoder_ready || nm_per_count==0
    initialized=false;filled=uint8(0);history_count=uint8(0);
    restart_history=true;status=uint32(16);
    return;
end
if initialized
    id_delta=mod32diff(sample_id,last_id);
    tick_delta=mod64diff(sample_tick,last_tick);
    if id_delta==0 && tick_delta==0
        status=uint32(2);position_valid=true;
        if raw_count~=last_raw || illegal_count~=last_bad
            initialized=false;filled=uint8(0);position_valid=false;
            restart_history=true;status=uint32(82);
        end
        history_count=filled;
        return;
    end
    if illegal_count~=last_bad
        initialized=false;filled=uint8(0);history_count=uint8(0);
        restart_history=true;status=uint32(16);
        return;
    end
    if id_delta~=500 || tick_delta~=5000
        if id_delta==0 || id_delta>2147483647 || ...
                mod(id_delta,uint64(500))~=0 || tick_delta~=id_delta*uint64(10)
            initialized=false;filled=uint8(0);history_count=uint8(0);
            restart_history=true;status=uint32(80);
            return;
        end
        filled=uint8(0);restart_history=true;status=uint32(4);
    end
    delta=count_delta(raw_count,last_raw);
    if delta==int64(-2147483648)
        initialized=false;filled=uint8(0);history_count=uint8(0);
        restart_history=true;status=uint32(48);
        return;
    end
    total=total+delta;
else
    total=count_delta(raw_count,uint32(0));
    status=uint32(1);filled=uint8(0);restart_history=true;
end
changed=~initialized || zero_count~=old_zero || reverse~=old_reverse || ...
    config_version~=old_version || nm_per_count~=old_scale;
if changed
    if ~initialized || zero_count~=old_zero
        relative=count_delta(raw_count,zero_count);
        if relative==int64(-2147483648)
            initialized=false;filled=uint8(0);history_count=uint8(0);
            restart_history=true;status=uint32(48);
            return;
        end
        origin=total-relative;
    end
    if initialized,status=bitor(status,uint32(8));end
    filled=uint8(0);restart_history=true;
end
initialized=true;last_raw=raw_count;last_id=sample_id;
last_tick=sample_tick;last_bad=illegal_count;
old_zero=zero_count;old_reverse=reverse;old_version=config_version;old_scale=nm_per_count;
if filled<51,filled=filled+uint8(1);end
continuous_count=total;origin_count=origin;advance=true;
position_valid=true;speed_valid=filled==51;history_count=filled;
end

function delta=count_delta(current,previous)
delta=int64(current)-int64(previous);
if delta>int64(2147483647)
    delta=delta-int64(4294967296);
elseif delta<int64(-2147483648)
    delta=delta+int64(4294967296);
end
end

function delta=mod32diff(current,previous)
if current>=previous
    delta=uint64(current)-uint64(previous);
else
    delta=uint64(4294967296)-uint64(previous)+uint64(current);
end
end

function delta=mod64diff(current,previous)
if current>=previous
    delta=current-previous;
else
    delta=(intmax('uint64')-previous)+current+uint64(1);
end
end
