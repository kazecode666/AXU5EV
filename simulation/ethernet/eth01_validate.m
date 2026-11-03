function result = eth01_validate(mode)
% Offline entry: simulation then Cortex-R C generation; never downloads.
if nargin==0, mode='all'; end
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
out=fullfile(root,'.runtime','ethernet','eth01','model');
if ~isfolder(out), mkdir(out); end
model='ETH01_Model'; load_system(fullfile(root,'simulation','ethernet',[model '.slx']));
if any(strcmp(mode,{'all','sim'}))
 t=(0:9)'*0.001;
 bytes=repmat(uint8((0:255)'),1,10)';
 lens=uint16([0 1 255 256 257 1 1 1 1 1]');
 valid=logical([1 1 1 1 1 0 1 0 0 0]');
 ready=logical([1 1 1 1 1 1 0 0 1 1]');
 ds=Simulink.SimulationData.Dataset;
 vals={bytes,lens,valid,uint32((11:20)'),ready};
 names={'Bytes','Len','Valid','Seq','TxReady'};
 for k=1:5, ds=ds.addElement(timeseries(vals{k},t),names{k}); end
 si=Simulink.SimulationInput(model); si=si.setExternalInput(ds);
 si=si.setModelParameter('StopTime','0.009','SaveOutput','on','OutputSaveName','yout','SaveFormat','Dataset');
 so=sim(si); yo=so.yout;
 counts=yo{5}.Values.Data(:); statuses=yo{6}.Values.Data(:);
 assert(isequal(counts,uint32([1 2 3 4 4 4 5 5 5 5]')));
 assert(statuses(5)==3 && all(statuses(8:9)==2));
 data=yo{1}.Values.Data;
 assert(all(reshape(data(1:256,1,4),256,1)==bitxor(uint8((0:255)'),uint8(90))));
 result=struct('MODEL_SIM','PASS','counts',counts','statuses',statuses');
 fid=fopen(fullfile(out,'simulation.json'),'w');fprintf(fid,'%s\n',jsonencode(result));fclose(fid);
 load_system(fullfile(root,'simulation','ethernet','ETH01_Target.slx'));
 targetRun=sim('ETH01_Target','StopTime','0.003');
 assert(all(targetRun.yout{1}.Values.Data==0));
 load_system(fullfile(root,'simulation','ethernet','ETH01_SoC_IO_Probe.slx'));
 probeRun=sim('ETH01_SoC_IO_Probe');
 assert(isequal(probeRun.yout{1}.Values.Data(1,:),uint8(0:255)));
 assert(all(probeRun.yout{2}.Values.Data==256));
end
if any(strcmp(mode,{'all','codegen'}))
 old=Simulink.fileGenControl('getConfig'); cleanup=onCleanup(@()Simulink.fileGenControl('setConfig','config',old));
 Simulink.fileGenControl('set','CodeGenFolder',fullfile(out,'codegen'),'CacheFolder',fullfile(out,'cache'),'createDir',true);
 slbuild(model);
 load_system(fullfile(root,'simulation','ethernet','ETH01_Target.slx'));
 slbuild('ETH01_Target');
 result=struct('CODEGEN','PASS','release',version('-release'),'algorithm',fullfile(out,'codegen','ETH01_Model_ert_rtw'),'target',fullfile(out,'codegen','ETH01_Target_ert_rtw'));
 fid=fopen(fullfile(out,'codegen.json'),'w');fprintf(fid,'%s\n',jsonencode(result));fclose(fid);
end
end
