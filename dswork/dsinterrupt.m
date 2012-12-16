% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Interrupt the jobs running in parallel.  Usually only used
% after you have interrupted a dsmapreduce in the main thread.
function dsinterrupt()
  global ds;
  for(i=1:numel(ds.sys.distproc.commlinkinterrupt))
    cmd.name='interrupt';
    save(ds.sys.distproc.commlinkinterrupt{i},'cmd');
  end
end
