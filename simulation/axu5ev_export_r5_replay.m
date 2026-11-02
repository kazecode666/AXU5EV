function reports=axu5ev_export_r5_replay(outputDir)
% Export real 100us records and current Runtime-only reference, never run RTL.
root=fileparts(fileparts(mfilename('fullpath')));
if nargin==0,outputDir=fullfile(root,'.runtime','ax02a','replay');end
assert(~isfolder(outputDir),'Use a new output directory.');mkdir(outputDir);
assert(evalin('base','exist(''PMLSM_M1A_InitVersion'',''var'')==1'));
addpath(fullfile(root,'simulation'));
source=fullfile(root,'.runtime','ax01c','c_fixed_continuous.mat');
assert(isfile(source),'Missing original MAT; do not reconstruct from decimated CSV.');
raw=load(source,'out');
u=axu5ev_matrix(raw.out.r5_snapshot);y=axu5ev_matrix(raw.out.r5_commit);
t=double(raw.out.r5_snapshot.Time(:));ty=double(raw.out.r5_commit.Time(:));
assert(size(u,2)==20&&size(y,2)==41&&numel(t)==64536);
assert(isequal(t,ty)&&abs(t(end)-6.4535)<1e-12);
assert(max(abs(diff(t)-1e-4))<1e-12);
assert(isequal(find(diff(u(:,11))~=0),[20915;21016;52999]));
model='AXU5EV_R5_Runtime';
if ~bdIsLoaded(model),load_system(fullfile(root,'simulation',[model '.slx']));end
assert(strcmp(get_param(model,'SimulationStatus'),'stopped'));
dirty=get_param(model,'Dirty');cfg=get_param(model,'ProdHWDeviceType');
reports(1)=export('pr14_original',u,y,t, ...
    'PR14 original C/feedback record; historical parameters, not current Runtime');
% The current saved Runtime and current loaded parameters form a new reference.
% Reuse the original feedback stimulus without interpolation; no plant/RTL rerun.
current=simulate(u,t);
reports(2)=export('current_motion',u,current,t, ...
    'Current Runtime model reference using unchanged PR14 100us input/feedback');
% Manual Start, full original counters; then independent reset and fault inputs.
n=43100;td=(0:n-1)'*1e-4;direct=zeros(n,20);
direct(:,1)=10;direct(:,[6 7 8])=1;direct(:,16)=1;direct(:,20)=3.25;
direct(11,17)=1; % k=10 manual Start, no automatic shortened alignment
direct(42151:42161,9)=1; % PI_Reset only
direct(42201:42211,8)=0; % PWM disable only
direct(42301,18)=1; % Init_Reset after complete five-state sequence
direct(42311,17)=1; % explicitly start a second alignment
direct(42401:42451,19)=1; % latched travel-fault input
direct(42501,18)=1; % Init_Reset and fault clear are separate inputs
direct(42511,17)=1;
yd=simulate(direct,td);
assert(all(ismember(0:4,unique(yd(:,5))')),'Five alignment states not covered.');
assert(any(yd(:,4)==1)&&any(yd(:,12)==1));
assert(any(abs(yd(:,8))>0),'Expected one-shot nonzero offset.');
reports(3)=export('current_alignment_reset',direct,yd,td, ...
    'Current Runtime deterministic manual alignment, original 10000/30000/2000, PI/PWM/Init/fault paths');
assert(strcmp(get_param(model,'Dirty'),dirty)&&strcmp(get_param(model,'ProdHWDeviceType'),cfg));
fprintf('REPLAY_EXPORT_PASS: %d scenarios, 20/41 fields, LE float64, full readback.\n',numel(reports));

    function result=simulate(inputs,time)
        signal=timeseries(inputs,time);signal=setinterpmethod(signal,'zoh');
        dataset=Simulink.SimulationData.Dataset;dataset=dataset.addElement(signal,'runtime_u');
        in=Simulink.SimulationInput(model);in=in.setExternalInput(dataset);
        in=in.setModelParameter('StopTime',num2str(time(end),17), ...
            'SaveOutput','on','SaveFormat','Dataset','ReturnWorkspaceOutputs','on');
        out=sim(in);logged=out.yout{1}.Values;
        assert(numel(logged.Time)==numel(time)&&max(abs(logged.Time(:)-time(:)))<1e-12);
        result=axu5ev_matrix(logged);assert(size(result,2)==41);
    end

    function report=export(name,inputs,outputs,time,description)
        directory=fullfile(outputDir,name);mkdir(directory);
        write_readback('input.bin',inputs);write_readback('reference.bin',outputs);
        report=struct('scenario',name,'frames',size(inputs,1),'Ts',1e-4, ...
            'input_fields',20,'output_fields',41,'format','little-endian float64, frame-major', ...
            'input_source',source,'input_source_commit','9a6877546581301638a2bde7203db47896b4f8aa', ...
            'reference_description',description,'model_version',get_param(model,'ModelVersion'), ...
            'parameter_source',fullfile(root,'simulation','init_AXU5EV.m'), ...
            'first_s',time(1),'last_s',time(end),'matlab',version);
        if ~strcmp(name,'pr14_original')
            report.reference_source='Current local Runtime and parameters; user edits are not PR14';
            names={'Host_Traj_Vmax','Host_Traj_Amax','Host_Traj_Jmax','Ts_ACR', ...
                'v_ref_set_rate_up','v_ref_set_rate_dn','Ramp_Ticks','Hold_Ticks','Id_Release_Ramp_Ticks'};
            for j=1:numel(names),report.parameters.(names{j})=evalin('base',names{j});end
        else
            report.reference_source='Original PR14 MAT';
            report.parameters=struct;
        end
        f=fopen(fullfile(directory,'metadata.json'),'w');assert(f>=0);
        c=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(report,PrettyPrint=true));clear c
        save(fullfile(directory,'reference.mat'),'inputs','outputs','time','report','-v7.3');
        function write_readback(filename,matrix)
            file=fullfile(directory,filename);f=fopen(file,'w','ieee-le');assert(f>=0);
            count=fwrite(f,matrix','double');fclose(f);assert(count==numel(matrix));
            f=fopen(file,'r','ieee-le');assert(f>=0);
            back=fread(f,[size(matrix,2),Inf],'double')';fclose(f);
            assert(isequal(back,matrix),'Serialized file differs from original.');
            bytes=dir(file);assert(bytes.bytes==8*numel(matrix));
        end
    end
end
