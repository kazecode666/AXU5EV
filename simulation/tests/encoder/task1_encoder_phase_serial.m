function [phase_count,valid,result_strobe,version] = task1_encoder_phase_serial(sample_strobe,count,ready,zero_count,phase_offset_count,direction,config_version)
%#codegen
% Retained serial modulo state engine from PR41.
% Q32 angle scaling and rounding are visible blocks in Encoder_Angle.
% Test scale: 30000 effective decoded counts/electrical period, NOT x4 again.
% One bit/clock modulo reduction avoids a wide divider in the 50MHz domain.
persistent prev phase primed old_zero old_dir stage
persistent work remainder remaining negative base work_offset work_version work_valid
if isempty(stage)
 prev=uint32(0);phase=int32(0);primed=false;
 old_zero=uint32(0);old_dir=false;
 stage=uint8(0);work=uint32(0);remainder=uint16(0);remaining=uint8(0);
 negative=false;base=int32(0);work_offset=uint16(0);work_version=uint32(0);work_valid=false;
end
phase_count=uint16(0);valid=false;result_strobe=false;version=work_version;
if stage==uint8(0)
 if sample_strobe
  % Phase/epoch labels do not destroy accumulated modulo32 continuity.
  % Reverse changes the sign of the retained unoffset coordinate.
  changed=~primed || old_zero~=zero_count;
  origin=prev;base=phase;
  if old_dir~=direction
   base=-phase;if base<int32(0),base=base+int32(30000);end
  end
  if changed,origin=zero_count;base=int32(0);end
  delta=int64(count)-int64(origin);
  if delta>int64(2147483647),delta=delta-int64(4294967296);
  elseif bitshift(delta,-31)<int64(-1),delta=delta+int64(4294967296);end
  % The exact half range has no unique direction and must re-prime.
  work_valid=ready && phase_offset_count<uint16(30000) && delta>=int64(-2147483647);
  if direction,delta=-delta;end
  negative=delta<int64(0);if negative,delta=-delta;end
  work=uint32(delta);remainder=uint16(0);remaining=uint8(32);
  work_offset=phase_offset_count;work_version=config_version;
  old_zero=zero_count;old_dir=direction;
  prev=count;primed=work_valid;stage=uint8(1);
 end
elseif stage==uint8(1)
 shifted=bitshift(uint32(remainder),1)+bitshift(work,-31);
 if shifted>=uint32(30000),shifted=shifted-uint32(30000);end
 remainder=uint16(shifted);work=bitshift(work,1);remaining=remaining-uint8(1);
 if remaining==uint8(0),stage=uint8(2);end
else
 p=base;
 if negative,p=p-int32(remainder);else,p=p+int32(remainder);end
 if p<int32(0),p=p+int32(30000);elseif p>=int32(30000),p=p-int32(30000);end
 if work_valid
  phase=p;p=p+int32(work_offset);if p>=int32(30000),p=p-int32(30000);end
  phase_count=uint16(p);

 end
 valid=work_valid;result_strobe=true;version=work_version;stage=uint8(0);
end
end
