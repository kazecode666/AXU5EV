function result=encoder_validate_pl_frames(frame_file,output_dir)
% Replay the actual receiver-before-stimulus RTL snapshot words through the
% MATLAB source and exact active C plus the SAME R5 field-map adapter.
f=fopen(frame_file,'r');assert(f>=0);c=onCleanup(@()fclose(f));tokens=textscan(f,'%s'); %#ok<NASGU>
assert(mod(numel(tokens{1}),41)==0);frames=reshape(uint32(hex2dec(tokens{1})),41,[]).';
encoder_position_speed(uint32(0),uint32(0),uint64(0),false,uint32(0),uint32(0),false,uint32(0),uint32(1000),true);
encoder_position_speed_mex(uint32(0),uint32(0),uint64(0),false,uint32(0),uint32(0),false,uint32(0),uint32(1000),true);
outputs=zeros(size(frames,1),9);initial_invalid=false;
for k=1:size(frames,1)
 p=frames(k,:);assert(p(1)==uint32(hex2dec('454e4346')) && p(2)==2);
 tick=bitor(uint64(p(5)),bitshift(uint64(p(6)),32));ready=bitand(p(3),uint32(512))~=0;
 [a,b,pv,sv,n,s,cc]=encoder_position_speed(p(17),p(4),tick,ready,p(21),p(36),p(38)~=0,p(35),p(41),false);
 [ca,cb,cpv,csv,cn,cs,ccc]=encoder_position_speed_mex(p);
 assert(abs(a-ca)<1e-12 && abs(b-cb)<1e-12 && isequal([pv,sv,double(n),double(s),double(cc)],[cpv,csv,double(cn),double(cs),double(ccc)]));
 assert(~sv); % This eight-frame record cannot fill a 51-entry speed history.
 if k==1,assert(~ready && ~pv && n==0);initial_invalid=true;end
 outputs(k,:)=[double(p(4)),double(p(17)),a,b,pv,sv,double(n),double(s),double(cc)];
end
writematrix(outputs,fullfile(output_dir,'pl_frame_software_outputs.csv'));
result=struct('status','PASS','frames',size(frames,1),'payload_words',41,'first_frame_unready_invalid',initial_invalid, ...
 'all_speed_invalid_history_short',true,'input',frame_file, ...
 'comparison','MATLAB source versus exact active C and identical R5 numeric_adapter.c field mapping','board','NOT_RUN');
fout=fopen(fullfile(output_dir,'pl_frame_result.json'),'w');closer=onCleanup(@()fclose(fout)); %#ok<NASGU>
fprintf(fout,'%s\n',jsonencode(result,PrettyPrint=true));disp(result);
end
