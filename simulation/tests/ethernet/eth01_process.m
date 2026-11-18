function [reply,n,valid,seqOut,count,status] = process(bytes,len,newMsg,seq,txReady)
%#codegen
persistent saved savedLen savedSeq pending handled
if isempty(pending)
 saved=zeros(256,1,'uint8'); savedLen=uint16(0); savedSeq=uint32(0); pending=false; handled=uint32(0);
end
reply=saved; n=savedLen; seqOut=savedSeq; valid=false; status=uint8(0);
if pending
 valid=true; status=uint8(2);
 if txReady, pending=false; end
elseif newMsg
 if len>256
  status=uint8(3);
 else
  saved=bytes;
  for k=1:256
   if k<=len, saved(k)=bitxor(bytes(k),uint8(90)); end
  end
  savedLen=len; savedSeq=seq; handled=handled+uint32(1); pending=true;
  reply=saved; n=savedLen; seqOut=savedSeq; valid=true; status=uint8(1);
  if txReady, pending=false; end
 end
end
count=handled;
end
