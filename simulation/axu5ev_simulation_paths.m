function root=axu5ev_simulation_paths(root)
% Explicit pure-simulation paths. Archive and experiment are separate entries.
if nargin<1,root=axu5ev_project_root(mfilename('fullpath'));end
addpath(fullfile(root,'simulation'),fullfile(root,'simulation','closed_loop'), ...
    fullfile(root,'simulation','closed_loop','components'), ...
    fullfile(root,'simulation','closed_loop','parameters'), ...
    fullfile(root,'simulation','closed_loop','scripts'),fullfile(root,'verification'));
work=fullfile(root,'.runtime','ax01b');
if isfolder(work),addpath(work);end
end
