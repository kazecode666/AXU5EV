function [count,z_seen,illegal] = ax03b1_abz_reference(ab,z)
%#codegen
% Ideal already-synchronized logic reference, not the thin RTL synchronizer
% or glitch filter. No speed state, no Z counter reset.
persistent old oldz c zs bad
if isempty(old),old=uint8(0);oldz=false;c=int32(0);zs=false;bad=uint32(0);end
delta=int32(0);key=uint8(old*4+ab);
if key==1||key==7||key==14||key==8,delta=int32(1);
elseif key==2||key==11||key==13||key==4,delta=int32(-1);
elseif old~=ab,bad=bad+uint32(1);end
% Explicit modulo32 count; MATLAB int32 addition otherwise saturates.
if delta==1 && c==intmax('int32'),c=intmin('int32');
elseif delta==-1 && c==intmin('int32'),c=intmax('int32');
else,c=c+delta;end
if z && ~oldz,zs=true;end
old=ab;oldz=z;count=c;z_seen=zs;illegal=bad;
end
