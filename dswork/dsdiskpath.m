function [dpath, fileexists, type,savestate]=dsdiskpath(dsvar, createdir, assumetype)
  global ds;
  dpath=[];
  fileexists=0;
  type=[];
  savestate=[];
  abspath=dsabspath(dsvar);
  savestp=['ds.sys.savestate' abspath(4:end)];
  fileexists=dsfield(savestp);
  %sptrexist=fileexists;
  if(fileexists)
    savestate=eval(savestp);
  end
  if(~fileexists)
    if(nargin>1&&createdir>0)
      fpath=ds.sys.outdir;
      ptr=ds.sys.root;
      sptr=ds.sys.savestate;
      builtnm='';
      flist=regexp(abspath(5:end),'\.','split')
      for(i=1:numel(flist))
        if(mystrcmp(builtnm,ds.sys.currpath))
          ptr=ds;
        end
        if(isfield(ptr,flist{i}))
          builtnm=[builtnm '.' flist{i}];
          if(~isfield(sptr,flist{i}))
            %sptrexist=0;
            if(i<numel(flist)||createdir>1)
              eval(['ds.sys.savestate' builtnm '=struct()']);
              fpath=[fpath '/' flist{i}];
              mymkdir(fpath);
            end
            sptr=struct();
          else
            sptr=getfield(sptr,flist{i});
          end
          ptr=getfield(ptr,flist{i});
        else
          clear ptr;
          break;
        end
      end
    end
  end
  dotpos=find(abspath=='.');
  varnm=abspath((dotpos(end)+1):end);
  locdirpath=abspath;
  locdirpath=locdirpath(1:(dotpos(end)));
  locdirpath(locdirpath=='.')='/';
  dirpath=[ds.sys.outdir locdirpath];
  if(exist('assumetype','var'))
    dpath=dsgetdisknamtype(varnm,assumetype,dirpath);
    type=assumetype;
  else
    if(exist('ptr','var'))
      type=dsgettypeforvar(ptr,varnm);
    elseif(fileexists)
      type=dsgettypeforvar(eval(savestp),varnm);
    else
      %else the file doesn't exist on disk and createdir couldn't/didn't infer it
      return;
    end
    dpath=dsgetdisknamtype(varnm,type,dirpath);
  end
  %varfromds=dsfindvar(abspath);
end
%function [type] =gettypeforvar(var,varnm)
%    if(iscell(var))
%      type='cell';
%    elseif(isstruct(var))
%      type='struct';
%    elseif(dshassuffix(varnm,'img'))
%      type='img';
%    elseif(dshassuffix(varnm,'fig'))
%      type='fig';
%    elseif(dshassuffix(varnm,'html'))
%      type='html';
%    elseif(dshassuffix(varnm,'txt'))
%      dotpos=find(varnm=='_');
%      type=varnm((dotpos(end)+1):end);
%    else
%      type='mat';
%    end  
%end
%function disknams=getdisknam(varnm,type,dirpath)
%    switch(type)
%      case('cell')
%        disknams={[dirpath varnm '[]']};
%      case('struct')
%        disknams={[dirpath varnm]};
%      case('img')
%        disknams={[dirpath varnm '.jpg']};
%      case('fig')
%        disknams={[dirpath varnm '.jpg'], [dirpath varnm '.pdf']};
%      case('html')
%        disknams={[dirpath varnm '.html']};
%      case('mat')
%        disknams={[dirpath varnm '.mat']};
%      otherwise
%        disknam={[dirpath varnm '.' type(1:end-3)]};
%    end
%end
