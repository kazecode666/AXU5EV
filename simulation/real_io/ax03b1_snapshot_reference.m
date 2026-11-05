function observation=ax03b1_snapshot_reference(raw_a,raw_b,sample_id,position,ia,ib,ic,valid,result_strobe,clip,error,offset_a,offset_b,count_a,count_b,done_a,done_b,cal_version,z_seen,illegal)
%#codegen
% Observation-only reference, registers one complete result including invalid.
persistent last
if isempty(last),last=zeros(1,20,'int64');end
if result_strobe
 last=[int64(sample_id),int64(raw_a),int64(raw_b),int64(position),int64(ia),int64(ib),int64(ic),int64(valid),int64(clip),int64(error),int64(1),int64(offset_a),int64(offset_b),int64(count_a),int64(count_b),int64(done_a),int64(done_b),int64(cal_version),int64(z_seen),int64(illegal)];
end
observation=last;
end
