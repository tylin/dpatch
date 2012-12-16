% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% If a worker ever gets stuck at a command prompt (e.g. a
% keyboard statement), you can use this to send commands to it.
% cmdstr is the command to run on each worker; ids is a list of
% worker ids to send the command to.
function dscmd(cmdstr,ids)
  global ds;
  if(nargin<2)
    ids=ds.sys.distproc.allslaves;
  end
  for(i=ids(:)')
    unix(['ssh ' ds.sys.distproc.hostname{i}(1:end-1) ' "echo ''' cmdstr ''' > ' ds.sys.outdir 'ds/sys/distproc/mlpipe' num2str(i) '"']);
  end
end
