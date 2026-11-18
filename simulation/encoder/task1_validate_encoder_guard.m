function result=task1_validate_encoder_guard()
% Check only the extracted frame/count guard against the frozen reference.
vectors=task1_encoder_vectors();
for frame=1:vectors.frames
    args=cellfun(@(column)column(frame),vectors.inputs,UniformOutput=false);
    [total,~,advance,restart,pv,sv,count,status]=task1_encoder_guard(args{:});
    assert(isequal(total,vectors.expected{7}(frame)));
    assert(isequal(pv,vectors.expected{3}(frame)));
    assert(isequal(sv,vectors.expected{4}(frame)));
    assert(isequal(count,vectors.expected{5}(frame)));
    assert(isequal(status,vectors.expected{6}(frame)));
    assert(~sv || advance);
    if args{10},assert(restart && ~advance);end
end
result=struct('status','PASS','frames',vectors.frames, ...
    'scenarios',vectors.scenarios,'guard_fields_compared',5);
disp(result);
end
