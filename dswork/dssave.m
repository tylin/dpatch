% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Save unsaved variables in dswork to disk.  matchstr specifies
% the variable or set of variables, and accepts *-wildcards, indexes
% in brackets, and absolute and relative paths.  dssave() is equivalent
% to dssave('*');
%
function dssave(matchstr)
  global ds;
  if(dsbool(ds,'conf','checksaves'));
    task='savechk';
  else
    task='save';
  end
%  if(nargin<2)
    outpath=ds.sys.outdir;
%  end
  if(nargin<1)
    matchstr='*';
  end
  mymkdir([outpath '/ds/']);
  %[matchstr brakidx]=dssplitmatchstr(matchstr);
  %if((numel(matchstr)>=3)&&strcmp(matchstr(1:3),'ds.'))
  %  matchstr=matchstr(4:end)
  %end
  %brakidx
  %if(isfield(ds,'distproc'))
  %  distproc=ds.distproc;
  %  ds=rmfield(ds,'distproc');
  %end
  %if(isfield(ds,'distproc'))
  %  distproc=ds.distproc;
  %  ds2=rmfield(ds,'distproc');
  %else
  %  ds2=ds;
  %end
  %if(isfield(ds,'savestate'))
  %  ds2=rmfield(ds2,'savestate');
  %  savestate=ds.savestate;
  %else
  %  savestate=struct();
  %end
  [matchstr brakidx]=dssplitmatchstr(matchstr)
  matchstr=dsabspath(matchstr)
  matchstr=matchstr(5:end)
  if(isfield(ds,'sys'))
    ds2=ds.sys.root;%rmfield(ds,'sys');
    sys=ds.sys;
    eval(['ds2' sys.currpath '=rmfield(ds,''sys'');'])
  else
    sys=struct();
    sys.savestate=struct();
    ds2=ds;
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
    %we start by completing ALL moves so we don't overwrite files 
    %that have been moved in memory but not on disk
%    savestate_tmp=dsrecurse(ds,[outpath '/ds'],[outpath '/ds'],struct(),'*',{'ds','savestate'},'move',[]);
%    ds.savestate=dsrecurse(ds,[outpath '/ds'],[outpath '/ds'],savestate_tmp,matchstr,{'ds'},'save',brakidx);
%  else
    %savestate=dsrecurse(ds2,[outpath '/ds'],[outpath '/ds'],savestate,'*',{'ds','savestate'},'move',[]);
    if(dsbool(ds,'sys','distproc','mapreducer'))
      task='savedistr';
    else
      task='save';
    end
    [savestate,~,respath]=dsrecurse(ds2,[outpath '/ds'],[outpath '/ds'],savestate,matchstr,{'ds'},task,brakidx);
    respath
    sys.savestate=savestate;
    if(strcmp(task,'savedistr'))
      for(i=1:size(respath,1))
        respath{i,1}=['.ds.' respath{i,1}];
      end
      if(isfield(sys,'saved'))
        sys.saved=[sys.saved;respath];
      else
        sys.saved=respath;
      end
    end
    ds.sys=sys;


%  end
%  if(exist('distproc','var'))
%    ds.distproc=distproc;
%  end
end
