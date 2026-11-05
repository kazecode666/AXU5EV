function [raw_a,raw_b,sample,ab,z,configure,conversion_ce] = ax03b1_stimulus()
%#codegen
% SIM_ASSUMPTION: two parallel offset-binary channels; no motor plant.
persistent tick
if isempty(tick),tick=uint32(0);end
raw_a=uint16(2000+mod(tick,uint32(61)));
raw_b=uint16(2100+mod(tick,uint32(43)));
% 50MHz behavioral clock / 5000 = original nominal 100us sample interval.
sample=mod(tick,uint32(5000))==0;
conversion_ce=mod(tick,uint32(10))==0; % 5MHz conversion within 50MHz logic
gray=uint8([0 1 3 2]);ab=gray(double(mod(idivide(tick,uint32(4)),uint32(4)))+1);
z=mod(tick,uint32(128))==64;configure=tick==0;tick=tick+uint32(1);
end
