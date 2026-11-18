function result=task1_validate_encoder_c(output_dir)
% Compare the exact model-generated target C through its test-only MEX bridge.
vectors=task1_encoder_vectors();
maximum_error=zeros(1,7);
for frame=1:vectors.frames
    args=cellfun(@(column)column(frame),vectors.inputs,UniformOutput=false);
    actual=cell(1,7);
    [actual{:}]=task1_encoder_model_mex(args{:});
    for port=1:7
        difference=abs(double(actual{port})-double(vectors.expected{port}(frame)));
        maximum_error(port)=max(maximum_error(port),difference);
        tolerance=0;
        if port<=2,tolerance=1e-9;end
        assert(difference<=tolerance,'Task1:EncoderCDifference', ...
            'Frame %d output %d differs by %.17g.',frame,port,difference);
    end
end
result=struct('status','PASS','frames',vectors.frames,'scenarios',vectors.scenarios, ...
    'compared_output_fields',7,'maximum_error',maximum_error, ...
    'source','ARM-target model-generated C compiled through transport-only MEX', ...
    'board','NOT_RUN');
file=fopen(fullfile(output_dir,'encoder_c_result.json'),'w');
assert(file>=0,'Cannot create encoder C result report.');
cleanup=onCleanup(@()fclose(file)); %#ok<NASGU>
fprintf(file,'%s\n',jsonencode(result,PrettyPrint=true));
disp(result);
end
