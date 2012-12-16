% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% change the current working directory-struct that dswork is using.
% dspath can be an absolute or relative path.  For example, if the
% ds currently contains (where '-' means a field):
%
% ds - struct1
%    - struct2 - field1
%              - field2
%
% Then dscd('ds.struct2') will result in a ds that looks like:
%
% ds - field1
%    - field2
%
% and so a call to ds.field1 will succeed.  You can no longer access
% ds.struct1 directly; you must either use dscd('.ds'), or use functions
% that recognize absolute paths.

function dscd(dspath)
  global ds;
  targ=dsabspath(dspath);
  targ=targ(4:end);
  rootpath=['ds.sys.root' targ];
  varpath=dsfindvar(dspath);
  if(dsfield(varpath))
    if(~eval(['isstruct(' varpath ')']))
      throw MException('ds:cantcd','Cannot cd into fieldi ' dspath ' that is not a struct');
    end
  else
    eval([rootpath '=struct();']);
  end
  if(dsfield(ds,'conf'))
    newconf=ds.conf;
  end
    
  %try
    if(dsfield(ds,'sys'))
      sys=ds.sys;
      ds2=rmfield(ds,'sys');
    else
      sys=struct();
      ds2=ds;
    end
    if(~dsfield(sys,'currpath'))
      sys.currpath='';
    end
    eval(['sys.root' sys.currpath '=ds2;']);
    if(~dsfield(sys,['root' targ]))
      %if(dsfield(sys,['savestate' sys.currpath]))
      eval(['sys.root' targ '=struct();']);
      %else
      %  throw MException('ds:cantcd','Cannot cd into fieldi ' dspath ' that does not exist.');
      %end
    end
    eval(['ds2=sys.root' targ ';']);
    eval(['sys.root' targ '=struct();']);
    %if(~dsfield(['sys.savestate' targ])) %don't actually want to create a savestate, or we'll think we have it on disk
    %  eval(['sys.savestate' targ '=struct();']);
    %end
    sys.currpath=targ;
    ds2.sys=sys;
    ds=ds2;
  %catch someexception
  %  ex=MException('dswork:cantcd','cannot cd')
  %  ex=addCause(ex,someexception);
  %  throw(ex);
  %end
  if(~dsfield(ds,'conf')&&exist('newconf','var'))
    ds.conf=newconf;
  end
end
