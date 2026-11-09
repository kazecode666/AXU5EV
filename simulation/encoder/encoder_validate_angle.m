function result=encoder_validate_angle(output_dir)
% Compare MATLAB algorithm and linked Simulink component; export RTL vectors.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
if ~isfolder(output_dir),mkdir(output_dir);end
addpath(fullfile(root,'simulation','encoder'));
% [count, ready, zero, offset_count, reverse, version].
v=[0 1 0 0 0 1;7500 1 0 0 0 1;15000 1 0 0 0 1;22500 1 0 0 0 1; ...
 29999 1 0 0 0 1;30000 1 0 0 0 1;30001 1 0 0 0 1;0 1 0 0 0 1; ...
 4294967295 1 0 0 0 1;4294967294 1 0 0 0 1;0 1 0 0 0 1; ...
 2147483646 1 2147483646 0 0 2;2147483647 1 2147483646 0 0 2; ...
 2147483648 1 2147483646 0 0 2;2147483649 1 2147483646 0 0 2; ...
 4294967294 1 4294967294 0 0 3;4294967295 1 4294967294 0 0 3; ...
 0 1 4294967294 0 0 3;1 1 4294967294 0 0 3; ...
 1 1 1 0 0 4;0 1 1 0 0 4;4294967295 1 1 0 0 4;4294967294 1 1 0 0 4; ...
 7500 1 0 0 1 5;15000 1 0 0 1 5;22500 1 0 0 1 5;30000 1 0 0 1 5; ...
 7500 1 0 29999 0 6;7500 1 7500 29999 0 7;7501 1 7500 29999 0 7; ...
 7501 0 7500 0 0 7;7502 1 7500 0 0 7; ...
 2147483648 1 0 0 0 8;2 1 0 0 0 8;3 1 0 30000 0 9;4 1 0 0 0 9];
clear encoder_angle_step
n=size(v,1);spacing=48;cycles=n*spacing;data=zeros(cycles,7);expected=zeros(cycles,5);
golden=zeros(n,5);primed=false;phase=0;prev=0;old=zeros(1,4);max_error=0;
for k=1:n
 row=v(k,:);cfg=row([3 4 5 6]);changed=~primed||any(cfg~=old);
 origin=prev;base=phase;if changed,origin=row(3);base=0;end
 delta=mod(row(1)-origin+2^31,2^32)-2^31;
 good=logical(row(2))&&row(4)<30000&&delta~=-2^31;
 if row(5),delta=-delta;end
 p=mod(base+delta,30000);theta=0;pc=0;
 if good
  phase=p;pc=mod(p+row(4),30000);
  theta=double(bitshift(uint64(pc)*uint64(943231700270)+uint64(524288),-20));
  ideal=round(pc*2*pi*2^32/30000);max_error=max(max_error,abs(theta-ideal));
 end
 primed=good;prev=row(1);old=cfg;golden(k,:)=[theta pc good 1 row(6)];
 for j=1:spacing
  t=(k-1)*spacing+j;data(t,:)=[j==1 row];
  [a,b,c,d,e]=encoder_angle_step(logical(j==1),uint32(row(1)),logical(row(2)), ...
   uint32(row(3)),uint16(row(4)),logical(row(5)),uint32(row(6)));
  expected(t,:)=[double(a) double(b) c d double(e)];
  if d,assert(isequal(expected(t,:),golden(k,:)),'Angle reference mismatch frame %d',k);end
 end
end
assert(max_error<=1,'Angle quantization exceeds one Q32 LSB');
assert(nnz(expected(:,4))==n,'Missing result event');
% Linked model adds one UnitDelay to every output, including the event.
time=(0:cycles-1)'*2e-8;ds=Simulink.SimulationData.Dataset();
names={'sample_strobe','count','ready','zero_count','phase_offset_count','direction','config_version'};
for p=1:7
 switch p
  case {1,3,6},x=logical(data(:,p));
  case 5,x=uint16(data(:,p));
  otherwise,x=uint32(data(:,p));
 end
 ds=ds.addElement(timeseries(x,time),names{p});
end
m='AXU5EV_Encoder_Angle_HDL';if ~bdIsLoaded(m),open_system(fullfile(root,'simulation','encoder',[m '.slx']));end
in=Simulink.SimulationInput(m);in=in.setExternalInput(ds);
in=in.setModelParameter('SaveOutput','on','OutputSaveName','yout', ...
 'SaveFormat','Dataset','StopTime',sprintf('%.12g',time(end)));
out=sim(in);actual=zeros(cycles,5);
for p=1:5,actual(:,p)=double(out.yout.getElement(p).Values.Data);end
assert(isequal(actual,[zeros(1,5);expected(1:end-1,:)]),'Linked model vs function differs');
events=find(actual(:,4));latencies=events-(0:n-1)'*spacing-1;
assert(numel(unique(latencies))==1);
% Text contains all inputs and analytical expected result for standalone RTL.
f=fopen(fullfile(output_dir,'angle_vectors.txt'),'w');cl=onCleanup(@()fclose(f));
for k=1:n,fprintf(f,'%.0f %.0f %.0f %.0f %.0f %.0f %.0f %.0f %.0f\n',v(k,:),golden(k,1),golden(k,2),golden(k,3));end
% latency_cycles here is the Simulink pre-state-update output sample offset.
% Generated RTL is separately measured post-edge; see README for 33/34 convention.
result=struct('status','PASS','vectors',n,'model_clock_steps',cycles,'latency_cycles',latencies(1), ...
 'max_ideal_error_q32_lsb',max_error,'format','signed40 Q32 rad in int64','coefficient',943231700270, ...
 'source','AXU5EV_Encoder_Components/Encoder_Angle -> encoder_angle_step.m','board','NOT_RUN');
f2=fopen(fullfile(output_dir,'angle_model_result.json'),'w');cl2=onCleanup(@()fclose(f2));
fprintf(f2,'%s\n',jsonencode(result,PrettyPrint=true));disp(result);
end
