function result=ax03b1_run_no_power(generate_hdl)
% Run ONLY the independently authored no-power observer and its numeric tests.
% Usage: addpath('D:/Project/AXU5EV/simulation/real_io'); ax03b1_run_no_power(true)
if nargin<1, generate_hdl=false; end
here=fileparts(mfilename('fullpath'));root=fileparts(fileparts(here));
oldpath=path;gen=Simulink.fileGenControl('getConfig');
cleanup=onCleanup(@()restore(oldpath,gen)); %#ok<NASGU>
addpath(here);cache=fullfile(root,'.runtime','ax03b1','matlab');
if ~isfolder(cache),mkdir(cache);end
Simulink.fileGenControl('set','CacheFolder',fullfile(cache,'cache'),'CodeGenFolder',fullfile(cache,'code'),'createDir',true);
result.numeric=ax03b1_validate_current(cache);
m='AXU5EV_RealIO_NoPower';model_file=fullfile(root,'simulation',[m '.slx']);
if ~bdIsLoaded(m),open_system(model_file);end
assert(strcmp(get_param(m,'Dirty'),'off'),'Save/review the NEW model before running.');
simulation=sim(m,'ReturnWorkspaceOutputs','on');
y=simulation.yout{1}.Values;data=squeeze(y.Data);
if size(data,2)~=20,data=data.';end
assert(size(data,2)==20 && any(data(:,11)==1),'No complete observer result.');
frames=data(data(:,11)==1,:);[~,first]=unique(frames(:,1),'stable');frames=frames(first,:);
assert(size(frames,1)>=3 && all(frames(:,8)==1),'Insufficient valid observation frames.');
% Metadata uses the sample-time count, not the newer count at ADC return.
assert(frames(1,4)==0 && frames(2,4)==1250,'Sample-time position association differs.');
assert(isequal(frames(1:3,1),int64([0;500;1000])),'Conversion event ID association differs.');
assert(frames(1,19)==0 && all(frames(2:end,19)==1),'Sample-time Z event association differs.');
assert(all(frames(:,20)==0),'Legal AB stimulation produced illegal transitions.');
assert(all(frames(:,5)+frames(:,6)+frames(:,7)==0),'Unclipped Q24 reconstruction mismatch.');
result.model=struct('status','SIM_PASS','unique_frames',size(frames,1),'observation_columns',20,'sampled_Z_first',double(frames(1,19)),'sampled_Z_subsequent',double(frames(2,19)),'illegal_legal_stimulus',double(max(frames(:,20))),'logic_clock_hz',50e6,'conversion_clock_hz',5e6,'pipeline_conversion_cycles',7,'observe_ticks',5000,'board','NOT_RUN','ABZ_reference','ideal already-synchronized; RTL filter verified separately');
writematrix(frames,fullfile(cache,'observer_frames.csv'));
if generate_hdl
 out=fullfile(root,'generated','ax03b1');if ~isfolder(out),mkdir(out);end
 hdlset_param(m,'TargetLanguage','SystemVerilog','ResetType','sync','ResetAssertedLevel','active-high','ClockInputPort','clk','ClockEnableInputPort','clk_enable','ResetInputPort','reset','ClockEnableOutputPort','ce_out','GenerateModel','off','GenerateValidationModel','off','Traceability','off','ResourceReport','off','OptimizationReport','off','EnableComments','on','DateComment','off','Oversampling',1,'ClockRatePipelining','off');
 hdlset_param([m '/Current_Preprocess'],'DistributedPipelining','off');
 makehdl([m '/Current_Preprocess'],'TargetDirectory',out);
 generated_numeric=fileread(fullfile(out,m,'Numeric_Algorithm.sv'));
 assert(~contains(generated_numeric,"< -32'sd2147483648"), ...
     'AX03B1:SignedLiteral','Generated lower-bound comparison has unsafe SV literal width.');
 save_system(m,model_file); % This NEW model only; never a user/source model.
 result.hdl=struct('status','HDL_GENERATION_PASS','module','Current_Preprocess','output_latency_cycles',1,'synthesis','NOT_RUN','board','NOT_RUN');
else,result.hdl=struct('status','NOT_RUN');end
f=fopen(fullfile(cache,'evidence.json'),'w');c=onCleanup(@()fclose(f));fprintf(f,'%s\n',jsonencode(result,PrettyPrint=true));disp(result);
end
function restore(oldpath,gen)
path(oldpath);Simulink.fileGenControl('setConfig','config',gen);
end
