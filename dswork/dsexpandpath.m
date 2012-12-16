function res=dsexpandpath(matchstr)
  global ds;
  outpath=ds.sys.outdir;
  if(nargin<1)
    matchstr='*';
  end
  %mymkdir([outpath '/ds/']);
  [matchstr brakidx]=dssplitmatchstr(matchstr);
  %if(isfield(ds,'distproc'))
  %  distproc=ds.distproc;
  %  ds=rmfield(ds,'distproc');
  %end
  %if((numel(matchstr)>=3)&&strcmp(matchstr(1:3),'ds.'))
  %  matchstr=matchstr(4:end)
  %end
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
  %[realpath,~,~,savestate]=dsdiskpath(['ds' sys.currpath]);
  %if(isempty(savestate))
  %  savestate=struct();
  %end


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
  %[realpath,~,~,savestate]=dsdiskpath(['ds' sys.currpath],1);
  %if(isempty(savestate))
  %  return;
  %end
  %if(~isfield(ds,'savestate'))
    [~,~,res]=dsrecurse(ds2,[outpath '/ds'],[outpath '/ds'],savestate,matchstr,{'ds','savestate'},'expandpath',brakidx);
  for(i=1:numel(res))
    res{i}=['.ds.' res{i}];
  end
%  else
%    [~,~,res]=dsrecurse(rmfield(ds,'savestate'),[outpath '/ds'],[outpath '/ds'],ds.savestate,matchstr,{'ds','savestate'},'expandpath',brakidx);
%  end
%  if(exist('distproc','var'))
%    ds.distproc=distproc;
%  end
end
