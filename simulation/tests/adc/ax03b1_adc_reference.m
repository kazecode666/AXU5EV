function [raw_a,raw_b,result,position,sample_id,z_seen,illegal] = ax03b1_adc_reference(in_a,in_b,sample,count,conversion_ce,in_z_seen,in_illegal)
%#codegen
% SIM_ASSUMPTION only: seven conversion-clock delay, independent parallel bus.
% Position and ABZ events enter AT sampling and travel with that sample.
% Never substitute return-time count, Z latch or illegal-event count.
persistent a b s p ids zs bad next_id
if isempty(next_id)
 a=zeros(1,7,'uint16');b=zeros(1,7,'uint16');s=false(1,7);
 p=zeros(1,7,'int32');ids=zeros(1,7,'uint32');next_id=uint32(0);
 zs=false(1,7);bad=zeros(1,7,'uint32');
end
raw_a=a(7);raw_b=b(7);result=conversion_ce && s(7);position=p(7);sample_id=ids(7);
z_seen=zs(7);illegal=bad(7);
if conversion_ce
for k=7:-1:2,a(k)=a(k-1);b(k)=b(k-1);s(k)=s(k-1);p(k)=p(k-1);ids(k)=ids(k-1);zs(k)=zs(k-1);bad(k)=bad(k-1);end
a(1)=in_a;b(1)=in_b;s(1)=sample;p(1)=count;ids(1)=next_id;
zs(1)=in_z_seen;bad(1)=in_illegal;
if next_id==uint32(4294967295),next_id=uint32(0);else,next_id=next_id+uint32(1);end
end
end
