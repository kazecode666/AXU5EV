function [position_mm,speed_mm_s,position_valid,speed_valid,history_count,status,continuous_count] = encoder_position_speed(raw_count,sample_id,sample_tick,encoder_ready,illegal_count,zero_count,reverse,config_version,nm_per_count,reset)
%#codegen
% ENCF software numeric source. No UART time, filter, PI or Runtime state.
% The physical scale is explicit: TEST 1000nm/count is 0.001mm/count once,
% with no extra quadrature multiplier. Tick=50MHz, selected IDs normally +500.
% Each received count displacement must be strictly within +/-2^31 counts.
% status bits: 0 startup, 1 duplicate, 2 gap, 3 config-history reset,
% 4 invalid encoder/illegal transition, 5 ambiguous half-wrap, 6 restart.
persistent initialized last_raw last_id last_tick last_bad total origin
persistent old_zero old_reverse old_version old_scale history ticks head filled cached_position
if isempty(initialized)
 initialized=false;last_raw=uint32(0);last_id=uint32(0);last_tick=uint64(0);last_bad=uint32(0);
 total=int64(0);origin=int64(0);old_zero=uint32(0);old_reverse=false;
 old_version=uint32(0);old_scale=uint32(0);history=zeros(51,1,'int64');
 ticks=zeros(51,1,'uint64');head=uint8(1);filled=uint8(0);cached_position=0.0;
end
position_mm=cached_position;speed_mm_s=0.0;position_valid=false;speed_valid=false;
status=uint32(0);history_count=filled;continuous_count=total;
if reset
 initialized=false;filled=uint8(0);head=uint8(1);cached_position=0.0;
 total=int64(0);origin=int64(0);position_mm=0.0;history_count=uint8(0);continuous_count=int64(0);
 return;
end
if ~encoder_ready || nm_per_count==0
 initialized=false;filled=uint8(0);head=uint8(1);history_count=uint8(0);status=uint32(16);
 return;
end
if initialized
 id_delta=mod32diff(sample_id,last_id);tick_delta=mod64diff(sample_tick,last_tick);
 if id_delta==0 && tick_delta==0
  status=uint32(2);position_valid=true;
  if raw_count~=last_raw || illegal_count~=last_bad
   initialized=false;filled=uint8(0);head=uint8(1);position_valid=false;status=uint32(82);
  end
  history_count=filled;return; % Re-reading a frozen frame never advances history.
 end
 if illegal_count~=last_bad
  initialized=false;filled=uint8(0);head=uint8(1);history_count=uint8(0);status=uint32(16);return;
 end
 % Missing integral frames can preserve count continuity under the delta bound,
 % but cannot preserve the 50-consecutive-interval speed history.
 if id_delta~=500 || tick_delta~=5000
  if id_delta==0 || id_delta>2147483647 || mod(id_delta,uint64(500))~=0 || tick_delta~=id_delta*uint64(10)
   initialized=false;filled=uint8(0);head=uint8(1);history_count=uint8(0);status=uint32(80);return;
  end
  filled=uint8(0);head=uint8(1);status=bitor(status,uint32(4));
 end
 delta=count_delta(raw_count,last_raw);
 if delta==int64(-2147483648)
  initialized=false;filled=uint8(0);head=uint8(1);history_count=uint8(0);status=uint32(48);return;
 end
 total=total+delta;
else
 total=count_delta(raw_count,uint32(0));
 status=bitor(status,uint32(1));filled=uint8(0);head=uint8(1);
end
changed=~initialized || zero_count~=old_zero || reverse~=old_reverse || config_version~=old_version || nm_per_count~=old_scale;
if changed
 if ~initialized || zero_count~=old_zero
  relative=count_delta(raw_count,zero_count);
  if relative==int64(-2147483648)
   initialized=false;filled=uint8(0);head=uint8(1);history_count=uint8(0);status=uint32(48);return;
  end
  % Only an explicit mechanical zero change remaps the nearest raw reference.
  % Electrical phase/version, direction and scale must preserve the continuous
  % origin even after one or more complete raw32 wraps.
  origin=total-relative;
 end
 % Any configuration change clears affected speed history; no offset impulse.
 if initialized,status=bitor(status,uint32(8));end
 filled=uint8(0);head=uint8(1);
end
initialized=true;last_raw=raw_count;last_id=sample_id;last_tick=sample_tick;last_bad=illegal_count;
old_zero=zero_count;old_reverse=reverse;old_version=config_version;old_scale=nm_per_count;
direction=1.0;if reverse,direction=-1.0;end
scale=double(nm_per_count)*1e-6; % nanometres -> millimetres
position_mm=double(total-origin)*scale*direction;cached_position=position_mm;position_valid=true;
history(head)=total;ticks(head)=sample_tick;
head=head+uint8(1);if head>51,head=uint8(1);end
if filled<51,filled=filled+uint8(1);end
if filled==51
 elapsed=mod64diff(sample_tick,ticks(head));
 % This is x[k]-x[k-50], not 50 samples and not a 1ms-speed-loop history.
 speed_mm_s=double(total-history(head))*scale*direction/(double(elapsed)/50000000.0);
 speed_valid=true;
end
history_count=filled;continuous_count=total;
end

function d=count_delta(a,b)
d=int64(a)-int64(b);
if d>int64(2147483647),d=d-int64(4294967296);
elseif d<int64(-2147483648),d=d+int64(4294967296);end
end
function d=mod32diff(a,b)
if a>=b,d=uint64(a)-uint64(b);
else,d=uint64(4294967296)-uint64(b)+uint64(a);end
end
function d=mod64diff(a,b)
if a>=b,d=a-b;else,d=(intmax('uint64')-b)+a+uint64(1);end
end
