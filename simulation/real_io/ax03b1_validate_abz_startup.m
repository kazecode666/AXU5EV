function evidence = ax03b1_validate_abz_startup(output_dir)
% Directed PR29 startup regression; never saves or edits the observer SLX.
% Use a fresh output directory so previous runs remain intact.
here=fileparts(mfilename('fullpath'));root=fileparts(fileparts(here));
if nargin<1,output_dir=tempname(fullfile(root,'.runtime','ax03b1'));end
assert(~isfolder(output_dir),'AX03B1:ExistingEvidence','Use a fresh evidence directory.');
mkdir(output_dir);
oldpath=path;gen=Simulink.fileGenControl('getConfig');
cleanup=onCleanup(@()restore(oldpath,gen));
addpath(here);
Simulink.fileGenControl('set','CacheFolder',fullfile(output_dir,'cache'), ...
    'CodeGenFolder',fullfile(output_dir,'code'),'createDir',true);
evidence.scope='PR29 ABZ ideal reference startup only; RTL unchanged';
evidence.reference=reference_matrix();
evidence.numeric=ax03b1_validate_current(output_dir);

m='AXU5EV_RealIO_NoPower';
assert(bdIsLoaded(m) && strcmp(get_param(m,'Dirty'),'off'), ...
    'Open the reviewed observer model without unsaved edits before running.');
% Nominal regression uses the real stimulus and the original SLX, unsaved.
assert(strcmp(which('ax03b1_stimulus'),fullfile(here,'ax03b1_stimulus.m')));
in=Simulink.SimulationInput(m);
in=in.setModelParameter('StopTime','0.00032','ReturnWorkspaceOutputs','on');
out=sim(in);nominal=frames(out);
assert(isequal(nominal(:,1),int64([0;500;1000;1500])));
assert(isequal(nominal(:,4),int64([0;1250;2500;3750])));
assert(isequal(nominal(:,19),int64([0;1;1;1])) && all(nominal(:,20)==0));
assert(all(nominal(:,8)==1) && all(sum(nominal(:,5:7),2)==0));
writematrix(nominal,fullfile(output_dir,'nominal_frames.csv'));
evidence.nominal=struct('status','SIM_PASS','unique_frames',size(nominal,1), ...
    'observation_columns',20,'sampled_count',double(nominal(:,4).'));

% Test-only path substitution changes the peripheral stimulus, not the model
% or any receive/numeric/snapshot code. The identical function signature is
% intentional. Assert resolution, compile normally, and restore path on exit.
fixture=fullfile(root,'verification','ax03b1','fixtures','abz_startup');
addpath(fixture,'-begin');clear ax03b1_stimulus
assert(strcmp(which('ax03b1_stimulus'),fullfile(fixture,'ax03b1_stimulus.m')));
expected=int64([0 0 0 0;500 0 0 0;1000 1 0 0;1500 0 0 0;2000 0 1 0]);
for repetition=1:2
    in=Simulink.SimulationInput(m);
    in=in.setModelParameter('StopTime','0.00042','ReturnWorkspaceOutputs','on');
    out=sim(in);observed=frames(out);
    assert(isequal(observed(:,[1 4 19 20]),expected), ...
        'AX03B1:StartupSnapshot','Startup/real edges were not preserved at sampling.');
    assert(all(observed(:,8)==1) && all(sum(observed(:,5:7),2)==0));
    writematrix(observed,fullfile(output_dir,sprintf('startup_frames_%d.csv',repetition)));
end
evidence.startup_model=struct('status','SIM_PASS','runs',2,'unique_frames_per_run',5, ...
    'observation_columns',20,'initial_ab',3,'initial_z',true, ...
    'sample_id',double(expected(:,1).'),'sampled_count',double(expected(:,2).'), ...
    'sampled_z_seen',double(expected(:,3).'),'sampled_illegal',double(expected(:,4).'), ...
    'stimulus_fixture','verification/ax03b1/fixtures/abz_startup/ax03b1_stimulus.m', ...
    'model_modified_or_saved',false,'synchronizer_filter_latency','NOT_MODELED');
evidence.status='PASS';evidence.hdl_generation='NOT_RUN';evidence.rtl='NOT_RUN';
evidence.board='NOT_RUN';evidence.output_dir=output_dir;
f=fopen(fullfile(output_dir,'abz_startup_results.json'),'w');
closer=onCleanup(@()fclose(f));
fprintf(f,'%s\n',jsonencode(evidence,PrettyPrint=true));
fprintf('AX03B1_ABZ_STARTUP_PASS cases=%d checks=%d model_runs=2 frames_per_run=5\n', ...
    evidence.reference.cases,evidence.reference.checks);
end

function result=reference_matrix()
% Expected transitions are specified by the Gray ring, independently of the
% reference's key table. Each direction starts after an independent reset.
gray=uint8([0 1 3 2]);checks=0;cases=0;
for repetition=1:2
    for initial=0:3
        for initial_z=[false true]
            for direction=[1 -1]
                clear ax03b1_abz_reference
                ab=uint8(initial);z=logical(initial_z);
                verify(ab,z,0,false,0); % first observation is a baseline
                for hold=1:20,verify(ab,z,0,false,0);end
                index=find(gray==ab);next=gray(mod(index-1+direction,4)+1);
                verify(next,z,direction,false,0);
                verify(next,z,direction,false,0); % holding is not another edge
                verify(ab,z,0,false,0); % reverse the real edge
                verify(ab,false,0,false,0); % initial high must first go low
                verify(ab,true,0,true,0); % only a real low-to-high sets Z
                verify(ab,false,0,true,0); % latch survives falling Z
                illegal_ab=bitxor(ab,uint8(3));
                verify(illegal_ab,false,0,true,1); % real double jump still detected
                cases=cases+1;
            end
        end
    end
end
clear ax03b1_abz_reference
result=struct('status','PASS','initial_ab_states',4,'initial_z_levels',2, ...
    'directions_per_start',2,'independent_repetitions',2,'cases',cases, ...
    'checks',checks,'static_hold_calls',20,'reset','clear persistent function');
    function verify(ab,z,want_count,want_z,want_bad)
        [count,z_seen,illegal]=ax03b1_abz_reference(ab,z);
        assert(count==int32(want_count) && z_seen==want_z && illegal==uint32(want_bad), ...
            'AX03B1:ABZStartup','AB=%d Z=%d got %d/%d/%d expected %d/%d/%d', ...
            ab,z,count,z_seen,illegal,want_count,want_z,want_bad);
        checks=checks+1;
    end
end

function data=frames(out)
data=squeeze(out.yout{1}.Values.Data);
if size(data,2)~=20,data=data.';end
assert(size(data,2)==20 && any(data(:,11)==1));
data=data(data(:,11)==1,:);[~,first]=unique(data(:,1),'stable');data=data(first,:);
end

function restore(oldpath,gen)
path(oldpath);clear ax03b1_stimulus ax03b1_abz_reference
Simulink.fileGenControl('setConfig','config',gen);
end
