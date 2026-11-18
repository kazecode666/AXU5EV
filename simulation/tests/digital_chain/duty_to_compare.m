function [compare_u,compare_v,compare_w,result_strobe] = duty_to_compare(sample_strobe,duty_u,duty_v,duty_w)
%#codegen
% The ONLY deployed Q30 duty -> 0..5000 numeric mapping.
% Unsigned values above 1.0 saturate, then round half upward.
compare_u=uint16(0);compare_v=uint16(0);compare_w=uint16(0);
result_strobe=sample_strobe;
if sample_strobe
 compare_u=map(duty_u);compare_v=map(duty_v);compare_w=map(duty_w);
end
end
function c=map(d)
if d>uint32(1073741824),d=uint32(1073741824);end
c=uint16(bitshift(uint64(d)*uint64(5000)+uint64(536870912),-30));
end
