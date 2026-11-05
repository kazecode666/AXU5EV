function evidence=ax03b1_validate_current(output_dir)
% Small independent arithmetic/state oracle for the NEW current path only.
if nargin<1, output_dir=fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))),'.runtime','ax03b1','matlab'); end
if ~isfolder(output_dir), mkdir(output_dir); end
trace=zeros(0,32);
clear ax03b1_current_preprocess
v={false,uint16(0),uint16(0),true,true,false,false,false,false,true,uint32(17),int32(2000*65536+32768),int32(2100*65536+16384),true,true,int32(round(.013*2^24)),int32(round(-.027*2^24)),uint8(2)};
call(v); v{10}=false; v{1}=true;
checks=0; clipped=0;
% Deliberately unequal signed gains and fractional independent offsets.
for a=[0 1999 2000 2001 4095]
    for b=[0 2099 2100 2101 4095]
        v{2}=uint16(a);v{3}=uint16(b); o=call(v);
        wa=rne((a-double(v{12})/65536)*double(v{16}));
        wb=rne((b-double(v{13})/65536)*double(v{17}));
        expected=int32(max(-2147483648,min(2147483647,[wa wb -(wa+wb)])));
        assert(isequal([o{1} o{2} o{3}],expected));
        assert(o{14} && o{11});checks=checks+1;
    end
end
% Explicit half ties, both signs; q24 coefficients of 1 create exact halves.
v{10}=true;v{12}=int32(32768);v{13}=int32(32768);v{16}=int32(1);v{17}=int32(-3);call(v);v{10}=false;
for a=0:4
    v{2}=uint16(a);v{3}=uint16(a);o=call(v);
    wa=rne(a-.5);wb=rne(-3*(a-.5));
    assert(isequal([o{1} o{2} o{3}],int32([wa wb -(wa+wb)])));checks=checks+1;
end
% Extreme coefficients force individual clipping; c must use UNCLIPPED wide
% a/b. For equal positive currents c clips negative, rather than wrapping.
v{10}=true;v{12}=int32(0);v{13}=int32(0);v{16}=intmax('int32');v{17}=intmax('int32');call(v);v{10}=false;v{2}=uint16(4095);v{3}=uint16(4095);o=call(v);
assert(isequal([o{1} o{2} o{3}],[intmax('int32') intmax('int32') intmin('int32')]));
assert(o{12} && ~o{11} && bitand(o{13},uint16(128))~=0);checks=checks+1;clipped=clipped+1;
% Cancellation before clipping: unequal products cancel to a small true c.
v{10}=true;v{16}=intmax('int32');v{17}=int32(-2147483647);call(v);v{10}=false;o=call(v);
assert(o{3}==0 && o{12} && ~o{11});checks=checks+1;clipped=clipped+1;
% Independent calibration: 4 GOOD samples per channel, explicit SIM config.
v{10}=true;v{14}=false;v{15}=false;v{18}=uint8(2);v{16}=int32(100);v{17}=int32(-200);call(v);v{10}=false;v{8}=true;v{2}=uint16(2010);v{3}=uint16(2110);
o=call(v);assert(o{6}==1 && o{7}==1 && ~o{11});checks=checks+1;
v{8}=false;o=call(v);assert(o{6}==1 && o{7}==1);checks=checks+1;
v{8}=true;v{6}=true;o=call(v);assert(o{6}==1 && o{7}==2 && bitand(o{13},uint16(4))~=0);checks=checks+1;
v{6}=false;v{5}=false;o=call(v);assert(o{6}==2 && o{7}==2);checks=checks+1;
v{5}=true;call(v);o=call(v);assert(o{8}&&o{9}&&~o{11}&&o{4}==2010*65536&&o{5}==2110*65536&&o{10}==19);checks=checks+1;
o=call(v);assert(o{11}&&o{1}==0&&o{2}==0&&o{3}==0);checks=checks+1;
v{9}=true;o=call(v);assert(o{14}&&~o{11}&&bitand(o{13},uint16(256))~=0&&o{6}==0&&o{7}==0&&~o{8}&&~o{9}&&o{4}==2010*65536&&o{10}==20);checks=checks+1;
v{9}=false;v{2}=uint16(4096);o=call(v);assert(o{6}==0&&o{7}==1&&bitand(o{13},uint16(1))~=0);checks=checks+1;
v{10}=true;v{12}=int32(-1);o=call(v);assert(o{14}&&~o{11}&&bitand(o{13},uint16(320))==uint16(320));checks=checks+1;
v{12}=int32(0);v{11}=uint32(4294967295);call(v);v{10}=false;v{9}=true;o=call(v);assert(o{10}==0);checks=checks+1;
evidence=struct('status','PASS','checks',checks,'clip_cases',clipped,'calibration_N_sim',4,'calibration_N_nominal',1024,'arithmetic','int64 Q40 product; convergent Q24; wide Q24 c before int32 saturation','physical_calibration','NOT_RUN','board','NOT_RUN');
writematrix(trace,fullfile(output_dir,'current_vectors.csv'));
f=fopen(fullfile(output_dir,'current_numeric.json'),'w');c=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(evidence,PrettyPrint=true));disp(evidence);
    function o=call(v)
        o=cell(1,14);[o{:}]=ax03b1_current_preprocess(v{:});
        trace(end+1,:)=[cellfun(@double,v) cellfun(@double,o)];
    end
end
function y=rne(x)
% Independent double arithmetic oracle. Selected stimuli are exact binary
% fractions, including half ties and integer extreme cancellation.
q=floor(abs(x));r=abs(x)-q;y=q+(r>.5 || (r==.5 && mod(q,2)==1));
if x<0,y=-y;end
end
