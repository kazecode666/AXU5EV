function [raw_a,raw_b,sample,ab,z,configure,conversion_ce] = ax03b1_stimulus()
%#codegen
% TEST FIXTURE ONLY: shadow the normal SIM source under a scoped test path.
% Initial AB=11/Z=high must not manufacture count/illegal/Z events. Real
% positive/reverse AB edges and a later Z low-to-high must remain observable.
persistent tick
if isempty(tick),tick=uint32(0);end
raw_a=uint16(2000+mod(tick,uint32(61)));
raw_b=uint16(2100+mod(tick,uint32(43)));
sample=mod(tick,uint32(5000))==0;
conversion_ce=mod(tick,uint32(10))==0;
ab=uint8(3);
if tick>=6000 && tick<12000,ab=uint8(2);end % 11->10 +1; 10->11 -1
z=tick<9000 || tick>=16000; % initial high is baseline; real rise at 16000
configure=tick==0;tick=tick+uint32(1);
end
