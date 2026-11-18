function work=axu5ev_closed_loop_work(root)
% Select one explicit writable simulation session, separate from old results.
if nargin<1,root=axu5ev_project_root(mfilename('fullpath'));end
if evalin('base','exist(''AXU5EV_ClosedLoop_Work'',''var'')==1')
    work=char(evalin('base','AXU5EV_ClosedLoop_Work'));
else
    work=fullfile(root,'.runtime','closed_loop', ...
        ['session_' char(datetime('now',Format='yyyyMMdd_HHmmss_SSS'))]);
    assert(~isfolder(work),'AXU5EV:Session','Choose a new simulation session.');
    assignin('base','AXU5EV_ClosedLoop_Work',work);
end
work=char(System.IO.Path.GetFullPath(work));
parent=char(System.IO.Path.GetFullPath(fullfile(root,'.runtime','closed_loop')));
assert(~strcmpi(work,parent) && ...
    startsWith([work filesep],[parent filesep],'IgnoreCase',true), ...
    'AXU5EV:Session','AXU5EV_ClosedLoop_Work must use .runtime/closed_loop/<session>.');
if ~isfolder(work),mkdir(work);end
end
