% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Load a variable or set of variables from disk.  matchstr is
% a string specifying the variables, and can include *-wildcards
% and indexes.  However, if nargout==1, this must resolve to a
% single variable (either a struct, an ordinary variable, or
% a single cell of a cell array).  By default, variables will not
% be loaded if they already exist in memory and are nonempty. 
% In these cases, the resulting value is returned.  varargin allows 
% additional options.    
%
% 'inpath': the string in the argument immediately after the 'inpath'
%           argument is specified is interpreted as a path on disk
%           from which the data can be loaded.  The path should specify
%           a directory that contains the 'ds' directory used by another
%           instance of dswork.  matchstr will then be interpreted relative
%           to that root.  In this mode, the global ds structure will not
%           be changed and the variable will instead be returned; i.e. nargout
%           must be 1.
% 
% 'clear': clear from memory whatever was loaded.  Useless unless nargout>0
%
% 'recheck': call dsloadsavestate first, in case something was added on disk.
%
% 'force': load variables even if the target variables in memory are not empty
%
%

function res=dsload(matchstr,varargin)
%     keyboard
  %disp(['dsload(' matchstr ')']);
  j=1;
  force=0;
  clearfromds=0;
  externalds=0;
  while(j<=numel(varargin))
    if(strcmp(varargin{j},'inpath'))
      inpath=varargin{j+1};
      externalds=1;
      j=j+2;
    elseif(strcmp(varargin{j},'clear'))
      clearfromds=1;
      j=j+1;
    elseif(strcmp(varargin{j},'force'))
      force=1;
      j=j+1;
    elseif(strcmp(varargin{j},'recheck'))
      dsloadsavestate(matchstr);
      j=j+1;
    end
  end
  if(nargin<1)
    matchstr='*';
  end
  origmatchstr=matchstr;
  %tic
  if(~exist('inpath','var'))
    global ds;
    inpath=ds.sys.outdir;
  else
    ds=struct();
  end
%  else
    if(externalds)
      savestate=dsloadsavestate(matchstr,inpath);
      sys.savestate=savestate;
%    else
%      global ds;
%      clearfromds=inpath;
%      inpath=ds.sys.outdir;
    end
%  end
  %if(nargout==0)
  %  global ds;
  %else
  %  ds=struct();
  %end
  %if(isempty(ds))
  %  ds=struct();
  %end
  %if(~isfield(ds,'sys'))
  %  sys=struct();
  %  ds2=ds;
  %else
  %  sys=ds.sys;
  %  ds2=rmfield(ds,'sys');
  %end
  [matchstr brakidx]=dssplitmatchstr(matchstr);
  if(~externalds)
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
  else
    if(dshasprefix(matchstr,'ds.'))
      matchstr=matchstr(4:end);
    elseif(dshasprefix(matchstr,'.ds.'))
      matchstr=matchstr(5:end);
    end
    ds2=ds;
  end

%  if(isfield(ds,'distproc'))
%    distproc=ds.distproc;
%    ds2=rmfield(ds,'distproc');
%  end
  %try
    if(~exist([inpath '/ds'] ,'dir'))
      %ds=struct();
      %ds.savestate=struct();
      disp(['warning: no ds found in ' inpath]);
      res=[];
      return;
    else
      %[matchstr brakidx]=dssplitmatchstr(matchstr);
      %if((numel(matchstr)>=3)&&strcmp(matchstr(1:3),'ds.'))
  %    if(strcmp(matchstr(1:3),'ds.'))
      %  matchstr=matchstr(4:end);
      %end

      %savestate=ds.savestate;
      %ds=rmfield(ds,'savestate');
      %realpath=sys.currpath;
      %realpath(realpath=='.')='/';
      %if(~externalds)
      %  [realpath,~,~,savestate]=dsdiskpath(['ds' sys.currpath]);
      %end
      if(force)
        task='forceload';
      else
        task='load';
      end
      %if(~isempty(savestate))
        [savestate ds2]=dsrecurse(ds2,[inpath '/ds'],[inpath '/ds'],savestate,matchstr,{'savestate'},task,brakidx);
        if(~externalds)
          %eval(['sys.savestate' sys.currpath '=savestate;']);
          %ds.sys=sys;
          %sys.savestate=savestate;
          if(isempty(sys.currpath)||dsfield(ds2,sys.currpath(2:end)))
            eval(['ds=ds2' sys.currpath ';']);
          else
            sys.currpath='';
            eval(['ds=ds2' sys.currpath ';']);
            disp('warning: operation removed currpath, returning to root.');
          end
          eval(['ds2' sys.currpath '=struct();']);
          sys.root=ds2;
          ds.sys=sys;
        else
          ds=ds2;

        end
      %end
      %if(externalds)
      %  ds=ds2;
      %end
      if(nargout>0&&~any(origmatchstr=='*'))
        [matchstr brakidx]=dssplitmatchstr(origmatchstr);
        if(~externalds)
          matchstr=dsfindvar(matchstr);
        end
        [bkidxstr extrainds]=dsrefstring(eval(['size(' matchstr ')']),brakidx,0);
        %if(~isempty(brakidx{2}))
        %  ressz=eval(['size(' matchstr ')']);
        %  inval2=(brakidx{2}>ressz(2));
        %  bkidx2=brakidx{2};
        %  bkidx2(inval2)=[];
        %  extrainds2=sum(inval2);
        %  if(~isempty(brakidx(1)))
        %    inval1=(brakidx{1}>ressz(1));
        %    bkidx1=brakidx{1};
        %    bkidx1(inval1)=[];
        %    extrainds1=sum(inval1);
        %    bkidxstr=['(' num2str(bkidx1(:)') ',' num2str(bkidx2(:)') ')'];
        %  else
        %    bkidxstr=['(' num2str(bkidx2(:)') ')'];
        %  end
        %else
        %  bkidxstr='';
        %end
        %['res=' matchstr bkidxstr ';']
        eval(['res=' matchstr bkidxstr ';']);
        if(extrainds(1)>0)
          res=[res;cell(extrainds(1),size(res,2))];
        end
        if(extrainds(2)>0)
          res=[res cell(size(res,2),extrainds(2))];
        end
        if(iscell(res)&&(numel(res)==1)&&(~isempty(bkidxstr)))%((numel(brakidx{1})<=1)||(numel(brakidx{2})==1)))
          res=res{1};
        end
        if(clearfromds)
          %if(~isempty(bkidxstr))
          %  bkidxstr(1)='{';
          %  bkidxstr(end)='}';
          %  empty=[];
          %elseif(eval(['iscell(' matchstr ')']))
          %  empty={};
          %elseif(eval(['isstruct(' matchstr ')&&numel(' matchstr ')==1']))
          %  empty=struct();
          %end
          %eval([matchstr bkidxstr '=empty;']);
          dsclear(origmatchstr);
        end
      end
    end
  %finally
    %if(exist('distproc','var'))
    %  ds.distproc=distproc;
    %end
    %toc
  %end
end
