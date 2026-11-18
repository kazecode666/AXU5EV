function root=axu5ev_project_root(location)
% Resolve this checkout from a source file or folder, independently of pwd.
if nargin<1,location=mfilename('fullpath');end
if isfile(location),root=fileparts(location);else,root=location;end
while ~isfile(fullfile(root,'AGENTS.md')) || ~isfolder(fullfile(root,'simulation'))
    parent=fileparts(root);
    assert(~strcmp(parent,root) && ~isempty(parent),'AXU5EV:Root', ...
        'Cannot locate AXU5EV from %s.',location);
    root=parent;
end
end
