function [ia_q24,ib_q24,ic_q24,offset_a_q16,offset_b_q16,cal_count_a,cal_count_b,cal_done_a,cal_done_b,cal_version,valid,clip,error,result_strobe] = ax03b1_current_preprocess(sample_strobe,raw_a,raw_b,capture_valid_a,capture_valid_b,otr_a,otr_b,cal_en,cal_restart,config_apply,config_version,offset_seed_a_q16,offset_seed_b_q16,manual_valid_a,manual_valid_b,gain_a_q24,gain_b_q24,cal_log2_N)
%#codegen
% New observation-only two-current path. Integer storage encodes Q16/Q24.
% config_apply atomically replaces both channels and starts a new epoch.
% Bad samples never advance calibration. External cal_en=0 pauses it.
% Result timing is combinational here; the generated DUT registers ALL outputs.
persistent oa ob ca cb sa sb da db ga gb lg ver configured
if isempty(configured)
    oa=int32(0); ob=int32(0); ca=uint16(0); cb=uint16(0);
    sa=uint32(0); sb=uint32(0); da=false; db=false;
    ga=int32(0); gb=int32(0); lg=uint8(10); ver=uint32(0);
    configured=false;
end
ia_q24=int32(0); ib_q24=int32(0); ic_q24=int32(0);
valid=false; clip=false; error=uint16(0); result_strobe=sample_strobe;
old_da=da; old_db=db;
if config_apply
    if sample_strobe,error=uint16(256);end
    % Restrict seeds to the ADC's representable Q16 interval. This bounds
    % each signed Q40 product below 2^60 and its pair sum below 2^61.
    seed_limit=int32(268369920); % 4095 * 65536
    good_cfg=(cal_log2_N<=uint8(10)) && ...
        (offset_seed_a_q16>=int32(0)) && (offset_seed_a_q16<=seed_limit) && ...
        (offset_seed_b_q16>=int32(0)) && (offset_seed_b_q16<=seed_limit);
    ca=uint16(0); cb=uint16(0); sa=uint32(0); sb=uint32(0);
    da=false; db=false; configured=good_cfg;
    if good_cfg
        oa=offset_seed_a_q16; ob=offset_seed_b_q16;
        ga=gain_a_q24; gb=gain_b_q24; lg=cal_log2_N;
        da=manual_valid_a; db=manual_valid_b; ver=config_version;
    else
        error=bitor(error,uint16(64));
    end
elseif cal_restart
    if sample_strobe,error=uint16(256);end
    ca=uint16(0); cb=uint16(0); sa=uint32(0); sb=uint32(0);
    da=false; db=false;
    ver=increment_version(ver);
elseif sample_strobe
    result_strobe=true;
    good_a=capture_valid_a && ~otr_a && (raw_a<=uint16(4095));
    good_b=capture_valid_b && ~otr_b && (raw_b<=uint16(4095));
    if ~capture_valid_a || raw_a>uint16(4095), error=bitor(error,uint16(1)); end
    if ~capture_valid_b || raw_b>uint16(4095), error=bitor(error,uint16(2)); end
    if otr_a, error=bitor(error,uint16(4)); end
    if otr_b, error=bitor(error,uint16(8)); end
    if ~old_da, error=bitor(error,uint16(16)); end
    if ~old_db, error=bitor(error,uint16(32)); end
    if ~configured, error=bitor(error,uint16(64)); end
    if configured && cal_en
        n=bitshift(uint16(1),int32(lg));
        if good_a && ~da
            sa=sa+uint32(raw_a); ca=ca+uint16(1);
            if ca==n
                oa=int32(bitshift(uint64(sa),int32(16)-int32(lg)));
                da=true;
                ver=increment_version(ver);
            end
        end
        if good_b && ~db
            sb=sb+uint32(raw_b); cb=cb+uint16(1);
            if cb==n
                ob=int32(bitshift(uint64(sb),int32(16)-int32(lg)));
                db=true;
                ver=increment_version(ver);
            end
        end
    end
    % The completing sample remains invalid. Next sample uses the new offsets.
    if configured && good_a && good_b && old_da && old_db
        pa=(bitshift(int64(raw_a),16)-int64(oa))*int64(ga);
        pb=(bitshift(int64(raw_b),16)-int64(ob))*int64(gb);
        wa=round_q40_to_q24(pa); wb=round_q40_to_q24(pb);
        % Reconstruct from un-clipped wide Q24 values: never from saturated
        % int32 outputs. The signed sum/negation has at least 34 bits.
        wc=-(wa+wb);
        [ia_q24,cl_a]=sat_q24(wa); [ib_q24,cl_b]=sat_q24(wb);
        [ic_q24,cl_c]=sat_q24(wc);
        clip=cl_a || cl_b || cl_c; valid=~clip;
        if clip, error=bitor(error,uint16(128)); end
    end
end
offset_a_q16=oa; offset_b_q16=ob;
cal_count_a=ca; cal_count_b=cb; cal_done_a=da; cal_done_b=db;
cal_version=ver;
end

function y=increment_version(x)
if x==uint32(4294967295),y=uint32(0);else,y=x+uint32(1);end
end

function y=round_q40_to_q24(x)
% Magnitude-based convergent rounding, symmetric for negative half ties.
negative=x<int64(0); a=x;
if negative, a=-x; end
q=bitshift(a,-16); r=bitand(a,int64(65535));
if r>int64(32768) || (r==int64(32768) && bitand(q,int64(1))~=int64(0))
    q=q+int64(1);
end
if negative, y=-q; else, y=q; end
end

function [y,clipped]=sat_q24(x)
hi=int64(2147483647);
% Arithmetic shift is an exact lower-bound test for every signed integer:
% x < -2^31 iff floor(x / 2^31) < -1. HDL Coder folds even explicitly
% constructed int64(-2^31) to a problematic 32-bit SV unary-min literal.
% This equivalent predicate avoids that literal in a 64-bit comparison.
below=bitshift(x,-31)<int64(-1);
clipped=x>hi || below;
if x>hi, y=int32(2147483647);
elseif below, y=int32(-2147483648);
else, y=int32(x);
end
end
