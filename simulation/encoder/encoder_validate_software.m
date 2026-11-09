function result=encoder_validate_software(output_dir)
% Analytical synthetic frame cases plus MATLAB/generated-host-C comparison.
checks=0;rows=zeros(0,14);
for scenario=1:15
 encoder_position_speed(uint32(0),uint32(0),uint64(0),false,uint32(0),uint32(0),false,uint32(0),uint32(1000),true);
 encoder_position_speed_mex(uint32(0),uint32(0),uint64(0),false,uint32(0),uint32(0),false,uint32(0),uint32(1000),true);
 id=uint32(0);tick=uint64(0);raw=uint32(0);zero=uint32(0);rev=false;ver=uint32(1);bad=uint32(0);
 if scenario==3,raw=uint32(1000);end
 if scenario==5,raw=uint32(4294967286);id=uint32(4294966296);tick=intmax('uint64')-uint64(25000);end
 if scenario==6,raw=uint32(10);end
 previous_history=uint8(0);
 for k=0:85
  ready=true;step=uint32(500);dt=uint64(5000);
  if scenario==4,rev=true;end
  if (scenario==7||scenario==13) && k==30,step=uint32(0);dt=uint64(0);end
  if scenario==8 && k==30,step=uint32(1000);dt=uint64(10000);end
  if scenario==9 && k==30,zero=raw;ver=uint32(2);end
  if scenario==10 && k==30,ready=false;end
  if scenario==11 && k==30,bad=uint32(1);end
  if scenario==12 && k==30,raw=wrap32(raw,2147483648);end
  if scenario==15 && k==30,rev=true;ver=uint32(2);end
  if k>0
   id=wrap32(id,double(step));tick=wrap64(tick,dt);
   if scenario~=1 && ~(scenario==7 && k==30)
    increment=10;if scenario==3 || scenario==6 || (scenario==14 && k>=30),increment=-10;end
    if scenario~=12 || k~=30,raw=wrap32(raw,increment);end
   end
  end
  args={raw,id,tick,ready,bad,zero,rev,ver,uint32(1000),false};
  [a,b,c,d,e,f,g]=encoder_position_speed(args{:});
  [ma,mb,mc,md,me,mf,mg]=encoder_position_speed_mex(args{:});
  assert(abs(a-ma)<1e-12 && abs(b-mb)<1e-12 && isequal(c,mc) && isequal(d,md) && isequal(e,me) && isequal(f,mf) && isequal(g,mg));checks=checks+1;
  if scenario<=6
   assert(c);assert(d==(k>=50));
   if k>=50
    expected=100;if scenario==1,expected=0;elseif scenario==3||scenario==4||scenario==6,expected=-100;end
    assert(abs(b-expected)<1e-9);
   end
   if scenario==1,assert(a==0);end
   if scenario==2,assert(abs(a-k*.01)<1e-12);end
   if scenario==5,assert(abs(a-(-.01+k*.01))<1e-12);end
  elseif scenario==7 && k==30
   assert(e==previous_history && bitand(f,uint32(2))~=0 && ~d);
  elseif scenario==8 && k==30
   assert(bitand(f,uint32(4))~=0 && ~d && e==1);
  elseif scenario==9 && k==30
   assert(bitand(f,uint32(8))~=0 && ~d && abs(a-.01)<1e-12);
  elseif (scenario==10||scenario==11||scenario==12||scenario==13) && k==30
   assert(~c && ~d && e==0);
  end
  if (scenario==8||scenario==9||scenario==15) && k>=30
   assert(d==(k>=80)); % 51 new consecutive samples after gap/config.
  end
  if (scenario==10||scenario==11||scenario==12||scenario==13) && k>=31
   assert(c && d==(k>=81)); % Invalid frame is not part of the rebuilt history.
  end
  if scenario==14
   expected_position=.01*k;if k>=30,expected_position=.29-.01*(k-29);end
   assert(abs(a-expected_position)<1e-12 && d==(k>=50));
   if k>=50
    old_position=.01*(k-50);if k-50>=30,old_position=.29-.01*(k-79);end
    assert(abs(b-(expected_position-old_position)/.005)<1e-9);
   end
  end
  if scenario==15 && k>=30,assert(abs(a+.01*k)<1e-12);if d,assert(abs(b+100)<1e-9);end,end
  rows(end+1,:)=[scenario,k,double(raw),double(id),a,b,c,d,double(e),double(f),double(g),double(zero),double(rev),double(ver)]; %#ok<AGROW>
  previous_history=e;
 end
end
% Non-integral identity/tick restart is invalid for the current frame; the
% next qualified frame explicitly establishes a new coordinate epoch.
encoder_position_speed(uint32(0),uint32(0),uint64(0),false,uint32(0),uint32(0),false,uint32(0),uint32(1000),true);
encoder_position_speed_mex(uint32(0),uint32(0),uint64(0),false,uint32(0),uint32(0),false,uint32(0),uint32(1000),true);
encoder_position_speed(uint32(0),uint32(5000),uint64(50000),true,uint32(0),uint32(0),false,uint32(1),uint32(1000),false);
encoder_position_speed_mex(uint32(0),uint32(5000),uint64(50000),true,uint32(0),uint32(0),false,uint32(1),uint32(1000),false);
[~,~,pv,sv,n,s]=encoder_position_speed(uint32(1),uint32(0),uint64(0),true,uint32(0),uint32(0),false,uint32(1),uint32(1000),false);
[~,~,mpv,msv,mn,ms]=encoder_position_speed_mex(uint32(1),uint32(0),uint64(0),true,uint32(0),uint32(0),false,uint32(1),uint32(1000),false);
assert(isequal([pv,sv,double(n),double(s)],[mpv,msv,double(mn),double(ms)]));
assert(~pv && ~sv && n==0 && bitand(s,uint32(64))~=0);checks=checks+1;
writematrix(rows,fullfile(output_dir,'software_golden.csv'));
result=struct('status','PASS','matlab_generated_c_frame_comparisons',checks, ...
 'scenarios',16,'history_entries',51,'speed_intervals',50,'nominal_history_ms',5, ...
 'position_unit','mm','speed_unit','mm/s','tick_hz',50000000, ...
 'id_step',500,'tick_step',5000,'cases','stationary,forward,reverse,motion reversal,direction/config change,count/id/tick wrap,duplicate,gap,zero/config,unready,illegal,half-wrap,restart and full history reacquisition');
end
function r=wrap32(a,delta)
r=uint32(mod(double(a)+delta,4294967296));
end
function r=wrap64(a,delta)
if intmax('uint64')-a<delta,r=delta-(intmax('uint64')-a)-uint64(1);else,r=a+delta;end
end
