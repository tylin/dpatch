% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Make dswork forget about everything that's already been
% saved to disk.
function clearsavestate()
  global ds;
  %outdir=ds.sys.savestate.outdir;
  ds.sys.savestate=struct();
  %ds.sys.outdir=outdir;
end
