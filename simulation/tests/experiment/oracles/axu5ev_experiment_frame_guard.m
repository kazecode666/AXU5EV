function [new_frame,healthy,fault_latched,clear_allowed]=axu5ev_experiment_frame_guard( ...
    initialized,erri_n,erru_n,current_valid,position_valid,feedback_status, ...
    position_mm,command,clear_fault,request_freset,max_hard,min_hard)
%#codegen
% Glue between qualified feedback and the copied control/driver algorithms.
% The measurement component owns count continuity and duplicate detection.
persistent fault
if isempty(fault)
    fault=false;
end
duplicate=bitand(feedback_status,uint32(2))~=uint32(0);
bad_feedback=~position_valid || ~current_valid || ...
    bitand(feedback_status,uint32(116))~=uint32(0);
raw_fault=~erri_n || ~erru_n;
hard_fault=position_valid && (position_mm>=max_hard || position_mm<=min_hard);
command_valid=all(isfinite(command));
clear_allowed=initialized && position_valid && ~duplicate && clear_fault && ...
    ~raw_fault && ~hard_fault && ...
    ~bad_feedback && command_valid && command(8)==0;
if clear_allowed
    fault=false;
elseif raw_fault || hard_fault || bad_feedback || ~command_valid
    fault=true;
end
new_frame=initialized && position_valid && ~duplicate;
healthy=new_frame && ~fault && ~raw_fault && ~hard_fault && ...
    current_valid && command_valid && ~request_freset;
fault_latched=fault;
end
