% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Delete a variable both from memory and from disk.  matchstr
% is the name of the variable, can be either absolute or relative,
% and can include '*'-wildcards and indexes in brackets.
function dsdelete(matchstr)
  global ds;
  %if(nargin<2)
  %  outpath=ds.savestate.outdir;
  %end
  outpath=ds.sys.outdir;
  if(nargin<1)
    disp('must use * explicitly for dsdelete.  not doing anything.');
    return;
  end
  mymkdir([outpath '/ds/']);

  [matchstr brakidx]=dssplitmatchstr(matchstr);
  matchstr=dsabspath(matchstr);
  matchstr=matchstr(5:end)
  if(isfield(ds,'sys'))
    ds2=ds.sys.root;%rmfield(ds,'sys');
    sys=ds.sys;
    eval(['ds2' sys.currpath '=rmfield(ds,''sys'');']);
  else
    sys=struct();
    ds2=ds;
    sys.savestate=struct();
  end
  if(~isfield(sys,'currpath'))
    sys.currpath='';
  end
  savestate=sys.savestate;
  %[realpath,~,~,savestate]=dsdiskpath(['ds' sys.currpath],1);
  if(isempty(savestate))
    return;
  end

%  if(~isfield(ds,'savestate'))
%    savestate_tmp=dsrecurse(ds2,[outpath '/ds'],[outpath '/ds'],struct(),'*',{'ds'},'move',[]);
%    ds.savestate=dsrecurse(ds2,[outpath '/ds'],[outpath '/ds'],savestate_tmp,matchstr,{'ds','disk'},'delete',brakidx);
%  else
    %we start by completing ALL moves so we don't overwrite files 
    %that have been moved in memory but not on disk
    %savestate_tmp=dsrecurse(ds2,[outpath '/ds'],[outpath '/ds'],savestate,'*',{'ds'},'move',[]);
    [savestate ds2]=dsrecurse(ds2,[outpath '/ds'],[outpath '/ds'],sys.savestate,matchstr,{'savestate','ds','disk'},'delete',brakidx);
    
    %eval(['sys.savestate' sys.currpath '=savestate;']);
    sys.savestate=savestate;
    if(isempty(sys.currpath)||dsfield(ds2,sys.currpath(2:end)))
      eval(['ds=ds2' sys.currpath]);
    else
      sys.currpath='';
      eval(['ds=ds2' sys.currpath]);
      disp('warning: operation removed currpath, returning to root.');
    end
    eval(['ds2' sys.currpath '=struct();']);
    sys.root=ds2;
    ds.sys=sys;
%  end
  %if(exist('distproc','var'))
  %  ds.distproc=distproc;
  %end
end
