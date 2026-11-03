function status = RUN_ETH02(scenario, options)
%RUN_ETH02 Upload accepted files, explicitly start one replay, export and analyze.
% User invocation after Review only. Loading a model never calls this function.
% Example:
% RUN_ETH02("current_motion",Start=true,Conditions="first ETH02 launch; fixed cable; power stage disconnected")
arguments
    scenario (1,1) string {mustBeMember(scenario,["current_motion","current_alignment_reset"])}
    options.Start (1,1) logical = false
    options.Conditions (1,1) string = ""
    options.IP (1,1) string = "192.168.50.10"
    options.Output (1,1) string = ""
end
if ~options.Start
    error('ETH02:ExplicitStart','Pass Start=true to upload and explicitly start one experiment.');
end
if strlength(options.Conditions)==0
    error('ETH02:Conditions','Declare this run''s actual conditions using Conditions="...".');
end
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
if strlength(options.Output)==0
    options.Output = string(fullfile(root,'.runtime','ethernet','eth02','board',scenario+"_01"));
end
parts = ["python", quote(fullfile(root,'scripts','eth02_run.py')), ...
    "--ip",quote(options.IP),"--scenario",quote(scenario),"--start", ...
    "--conditions",quote(options.Conditions),"--out",quote(options.Output)];
status = system(strjoin(parts," "),'-echo');
if status~=0
    error('ETH02:ExperimentFailed','Experiment/export/analysis failed (exit %d); preserve this output directory.',status);
end
end

function text = quote(value)
% Windows cmd quoting for paths and plain declared conditions, no shell expansion.
value = string(value);
if any(contains(value,["""","%","!","&","|","<",">","^",newline,char(13)]))
    error('ETH02:Argument','Shell metacharacters are not accepted in experiment arguments.');
end
text = """" + value + """";
end
