% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Read disk to determine what is available on disk to be loaded.
% Most often, this is used when a distributed worker creates a
% variable that isn't one of the 'reduce' variables, and so its
% creation is not communicated back to the main thread.  dsloadsavestate
% will let the main thread discover what changes have been made.
%
% matchstr is the variable that is to be loaded.  It can be
% an absolute or relative path, with *-wildcards and indexes
% in brackets.
%

function res=dsloadsavestate(matchstr,inpath)
  if(nargin<2)
    global ds;
    inpath=ds.sys.outdir;
  end
  if(nargin<1)
    matchstr='*';
  end
  %if(nargout==0)
  %  global ds;
  %else
  %  ds=struct();
  %end
  if(~exist('ds','var'))
    ds=struct();
  end
  %if(~isfield(ds,'savestate'))
  %  ds.savestate=struct();
  %end
  %if(isfield(ds,'distproc'))
  %  distproc=ds.distproc;
  %  ds=rmfield(ds,'distproc');
  %end
  %if(~isfield(ds,'savestate'))
  %  savestate=struct();
  %else
  %  savestate=ds.savestate;
  %  ds2=rmfield(ds,'savestate');
  %end
  %if(isfield(ds,'distproc'))
  %  distproc=ds.distproc;
  %  ds2=rmfield(ds,'distproc');
  %end
  if(~exist([inpath '/ds'] ,'dir'))
    disp(['warning: no ds found in ' inpath]);
    res=[];
    return;
  end

  %if(isfield(ds,'sys'))
  %  ds2=rmfield(ds,'sys');
  %  sys=ds.sys;
  %else
  %  sys=struct();
  %  ds2=ds;
  %end
  %if(~isfield(sys,'currpath'))
  %  sys.currpath='';
  %end
  %[realpath,~,~,savestate]=dsdiskpath(['ds' sys.currpath],1);
  [matchstr brakidx]=dssplitmatchstr(matchstr);
  matchstr=dsabspath(matchstr);
  matchstr=matchstr(5:end);
  if(isfield(ds,'sys'))
    ds2=ds.sys.root;%rmfield(ds,'sys');
    sys=ds.sys;
    eval(['ds2' sys.currpath '=rmfield(ds,''sys'');']);
  else
    sys=struct();
    sys.savestate=struct();
    ds2=ds;
  end
  if(~isfield(sys,'currpath'))
    sys.currpath='';
  end
  savestate=sys.savestate;

      %[matchstr brakidx]=dssplitmatchstr(matchstr);
      %if((numel(matchstr)>=3)&&strcmp(matchstr(1:3),'ds.'))
  %    if(strcmp(matchstr(1:3),'ds.'))
        %matchstr=matchstr(4:end)
      %end

    %[matchstr brakidx]=dssplitmatchstr(matchstr);
    %savestate=ds.savestate;
    %ds=rmfield(ds,'savestate');
    [savestate]=dsrecurse(ds2,[inpath '/ds'],[inpath '/ds'],savestate,matchstr,{'disk'},'loadsavestate',brakidx);
    sys.savestate=savestate;
    ds.sys=sys;
    if(nargout>0)
      res=savestate;
    end
  %end
  %if(exist('distproc','var'))
  %  ds.distproc=distproc;
  %end
end
