function result=adc_validate_component(output_dir)
% Reuse the accepted arithmetic vectors on the shared linked component.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldpath=path;gen=Simulink.fileGenControl('getConfig');
cleanup=onCleanup(@()restore(oldpath,gen)); %#ok<NASGU>
addpath(fullfile(root,'simulation'),fullfile(root,'simulation','real_io'));
if ~isfolder(output_dir),mkdir(output_dir);end
Simulink.fileGenControl('set','CacheFolder',fullfile(output_dir,'cache'), ...
 'CodeGenFolder',fullfile(output_dir,'code'),'createDir',true);
numeric=ax03b1_validate_current(output_dir);
v=readmatrix(fullfile(output_dir,'current_vectors.csv'));
m='AXU5EV_ADC_HDL';
if ~bdIsLoaded(m),open_system(fullfile(root,'simulation',[m '.slx']));end
ports=find_system(m,'SearchDepth',1,'BlockType','Inport');
ds=Simulink.SimulationData.Dataset;
t=(0:size(v,1))'*2e-8;
for k=1:numel(ports)
 n=str2double(get_param(ports{k},'Port'));
 typ=get_param(ports{k},'OutDataTypeStr');if strcmp(typ,'boolean'),typ='logical';end
 data=cast([v(:,n);v(end,n)],typ);
 ds=ds.addElement(timeseries(data,t),get_param(ports{k},'Name'));
end
si=Simulink.SimulationInput(m);si=si.setExternalInput(ds);
si=si.setModelParameter('StopTime',num2str(t(end),17));
so=sim(si);
for n=1:14
 actual=double(squeeze(so.yout{n}.Values.Data));
 assert(isequal(actual(2:end),v(:,18+n)), ...
   'ADC:LatencyOrValue','Output %d differs from vectors at one-clock delay.',n);
end
observer='AXU5EV_ADC_Observer';
if ~bdIsLoaded(observer),open_system(fullfile(root,'simulation',[observer '.slx']));end
so=sim(observer,'ReturnWorkspaceOutputs','on');
data=squeeze(so.yout{1}.Values.Data);if size(data,2)~=20,data=data.';end
frames=data(data(:,11)==1,:);[~,first]=unique(frames(:,1),'stable');frames=frames(first,:);
assert(size(frames,1)==4 && all(frames(:,8)==1));
assert(isequal(frames(1:3,1),int64([0;500;1000])));
assert(all(frames(:,5)+frames(:,6)+frames(:,7)==0));
writematrix(frames,fullfile(output_dir,'observer_frames.csv'));
result=struct('status','PASS','numeric_checks',numeric.checks, ...
 'vector_rows',size(v,1),'output_fields',14,'output_latency_cycles',1, ...
 'observer_frames',size(frames,1),'board','NOT_RUN');
f=fopen(fullfile(output_dir,'component_result.json'),'w');
closer=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(result,PrettyPrint=true));disp(result);
end
function restore(oldpath,gen)
path(oldpath);Simulink.fileGenControl('setConfig','config',gen);
end
