function rows=m3_apply_candidate(cfg)
% HDL-only properties on an owned generation copy; no algorithm/state edits.
rows=struct('SID',{},'path',{},'property',{},'before',{},'requested',{},'after',{},'reason',{});
if ~isfield(cfg,'candidate'),return;end
settings=cfg.candidate.settings;
for k=1:numel(settings)
    s=settings(k);p=Simulink.ID.getFullName(sprintf('%s:%d',cfg.model,s.SID));
    assert(startsWith(p,[cfg.dut '/'])||strcmp(p,cfg.dut),'M3:CANDIDATE_SCOPE','Candidate property outside DUT.');
    before=hdlget_param(p,s.property);
    hdlset_param(p,s.property,s.value);after=hdlget_param(p,s.property);
    assert(strcmpi(string(after),string(s.value)),'M3:CANDIDATE_READBACK','HDL property readback failed.');
    rows(end+1)=struct('SID',s.SID,'path',p,'property',s.property, ...
        'before',before,'requested',s.value,'after',after,'reason',s.reason); %#ok<AGROW>
end
end
