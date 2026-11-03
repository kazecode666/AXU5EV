function result = START_ETH01(action)
% ETH01 offline model entry. No board access. Run from MATLAB through MCP.
% START_ETH01('sim') / ('codegen') / ('host') / ('build') / ('check')
if nargin==0, action='sim'; end
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
switch action
 case {'sim','codegen','all'}
  result=eth01_validate(action);
 case 'host'
  [status,text]=system(sprintf('python -m unittest discover -s "%s" -p "test_eth01_*.py" -v',fullfile(root,'tests')));
  disp(text);assert(status==0);result=status;
 case 'build'
  [status,text]=system(sprintf('"E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat" -s "%s"',fullfile(root,'scripts','eth01_build.py')));
  disp(text);
  if status~=0 || ~contains(text,'ETH01_BUILD_PASS')
   error('ETH01:BuildFailed','Python build did not complete successfully (Vitis launcher exit %d). See output above.',status);
  end
  result=START_ETH01('check');
 case 'check'
  [status,text]=system(sprintf('python "%s" --check-startup',fullfile(root,'scripts','eth01_build.py')));
  disp(text);assert(status==0);result=status;
 otherwise
  error('ETH01:Action','Use sim, codegen, all, host, build or check.');
end
end
