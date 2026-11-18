function [reference,commit_id,reference_version]=axu5ev_experiment_reference_commit( ...
    runtime,healthy,speed_valid,speed_mm_s,sample_id,new_frame,request_freset, ...
    relcon,encon,oe_disable,external_fault,travel_fault,id_limit,iq_limit,tau_mm)
%#codegen
% Atomic reference/permission adapter. The PL current loop remains external.
persistent version last_id
if isempty(version)
    version=uint32(0);
    last_id=uint32(0);
end
if new_frame
    if version==uint32(4294967295)
        version=uint32(0);
    else
        version=version+uint32(1);
    end
    last_id=sample_id;
end
runtime_finite=all(isfinite(runtime));
valid=new_frame && healthy && speed_valid && ~external_fault && ...
    travel_fault<=0.5 && runtime_finite;
pwm=valid && runtime(18)~=0 && relcon && encon && ~oe_disable && ~request_freset;
id_ref=min(id_limit,max(-id_limit,runtime(1)));
iq_ref=min(iq_limit,max(-iq_limit,runtime(2)));
if ~valid
    id_ref=0;
    iq_ref=0;
end
omega=speed_mm_s*(2*pi/tau_mm);
if ~speed_valid || ~isfinite(omega)
    omega=0;
end
pi_reset=runtime(23)~=0 || ~pwm || ~valid;
theta_offset=runtime(8);
angle_init=runtime(7);
if ~runtime_finite
    theta_offset=0;
    angle_init=0;
end
reference=[id_ref;iq_ref;omega;theta_offset;angle_init; ...
    double(pwm);double(pi_reset);double(valid)];
commit_id=last_id;
reference_version=version;
end
