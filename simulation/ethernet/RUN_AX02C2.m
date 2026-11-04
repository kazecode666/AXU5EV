function status = RUN_AX02C2(scenario, options)
%RUN_AX02C2 Explicit recorded Runtime + real AXI/PL experiment and file export.
% RUN_AX02C2("current_motion",Start=true,Conditions="power stage disconnected; fixed cable")
arguments
    scenario (1,1) string {mustBeMember(scenario,"current_motion")} = "current_motion"
    options.Start (1,1) logical = false
    options.Conditions (1,1) string = ""
    options.IP (1,1) string = "192.168.50.10"
    options.Output (1,1) string = ""
end
if ~options.Start
    error('AX02C2:ExplicitStart','Pass Start=true to upload and start one C2 experiment.');
end
if strlength(options.Conditions)==0
    error('AX02C2:Conditions','Declare the actual experiment conditions.');
end
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
if strlength(options.Output)==0
    options.Output=string(fullfile(root,'.runtime','ax02c2','board',scenario+"_perf_r1_01"));
end
parts=["python",quote(fullfile(root,'scripts','ax02c2_run.py')), ...
    "--ip",quote(options.IP),"--scenario",quote(scenario),"--start", ...
    "--conditions",quote(options.Conditions),"--out",quote(options.Output)];
status=system(strjoin(parts," "),'-echo');
if status~=0
    error('AX02C2:ExperimentFailed','C2 experiment/export/analysis failed (exit %d); preserve this output directory.',status);
end
end

function text=quote(value)
value=string(value);
if any(contains(value,["""","%","!","&","|","<",">","^",newline,char(13)]))
    error('AX02C2:Argument','Shell metacharacters are not accepted in experiment arguments.');
end
text=""""+value+"""";
end
