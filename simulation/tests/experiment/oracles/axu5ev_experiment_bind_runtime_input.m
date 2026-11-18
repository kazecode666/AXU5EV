function u=axu5ev_experiment_bind_runtime_input(command,position_mm,speed_mm_s, ...
    control_fault,speed_valid)
%#codegen
% Bind measured fields to the copied Runtime's established 20-field contract.
u=command;
if ~all(isfinite(command))
    u=zeros(20,1);
end
u(15)=speed_mm_s;
u(19)=double(control_fault);
u(20)=position_mm;
u(9)=double(command(9)~=0 || control_fault || ~speed_valid);
u(10)=0;
u(12)=0;
u(13)=0;
u(14)=0;
if control_fault
    u(8)=0;
end
end
