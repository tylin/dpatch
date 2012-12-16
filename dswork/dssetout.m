% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% specify the directory where everything should be saved.  Should be
% called exactly once at the beginning of the program.  Calling it again
% after dssave will only change the path, NOT what dswork believes is saved
% on disk (see dsclearsavestate), and will not reset the output directory
% used on worker nodes in a distribtued processing session.
function dssetout(outdir)
  global ds;
  if(~(outdir(end)=='/'))
    outdir=[outdir '/'];
  end
  ds.sys.outdir=outdir;
  if(~dsfield(ds,'sys','savestate'))
    ds.sys.savestate=struct();
  end
  if(~dsfield(ds,'sys','root'))
    ds.sys.root=struct();
  end
  if(~dsfield(ds,'sys','currpath'))
    ds.sys.currpath='';
  end
  mymkdir(outdir);
  mymkdir([outdir 'ds']);
  mymkdir([outdir 'ds/sys']);
  mymkdir([outdir 'ds/sys/distproc']);
end
