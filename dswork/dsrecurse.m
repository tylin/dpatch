% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
function [savestate,currds,respath]=dsrecurse(currds,basedir,currpath,savestate,matchstr,recurseon,task,brakidx)
%try
  %if(mystrcmp(basedir,currpath))
  %  disp(['dsrecurse:' matchstr]);
  %  currpath
  %end
  respath={};
  if(~isstruct(savestate))
    savestate=struct();
    %disp('setting empty savestate top')
  end
  if(~isstruct(currds))
    currds=struct();
  end
  nams={};
  if(ismember({'disk'},recurseon))
    fils=cleandir(currpath);
    disknams={fils.name};
    if(strcmp(basedir,currpath))
      %we are at the root--don't want to load the sys directory!
      disknams(ismember(disknams,{'sys'}))=[];
    end
    for(i=1:numel(disknams))
      nam=disknams{i};
      dotpos=find(nam=='.');
      if(numel(dotpos)>0)
        nam=nam(1:(dotpos-1));
      end
      brakpos=find(nam=='[');
      if(numel(brakpos)>0)
        nam=nam(1:(brakpos(1)-1))
      end
      nams{i,1}=nam;
    end
    matcheddisknams=nams;
  end
  if(ismember({'savestate'},recurseon))
    tmpnams=fieldnames(savestate);
    if(mystrcmp(basedir,currpath))
      %we are at the root--don't want to save the outdir!
      tmpnams(ismember(tmpnams,{'outdir'}))=[];
    end
    nams=[nams;tmpnams];
  end
  if(ismember({'ds'},recurseon))
    nams=[nams;fieldnames(currds)];
  end
  nams=unique(nams);
  correspdisknams=cell(numel(nams),1);
  for(i=1:numel(correspdisknams))
    correspdisknams{i}={};
  end
  if(exist('disknams','var'))
    for(i=1:numel(disknams))
      [~,idx]=ismember(matcheddisknams{i},nams);
      correspdisknams{idx}{end+1}=disknams{i};
    end
  end
  %if(strcmp(task,'delete'))
  %keyboard;
  %end
  %if(numel(recurseon)>1)
  %  idx(idx>numel(disknams))=numel(disknams)+1;
  %  disknams{end+1}=[];
  %  disknams=disknams(idx);
  %end
  dotpos=find(matchstr=='.');
  if(numel(dotpos)==0)
    currmatchstr=matchstr;
    nextmatchstr='*';
    matchisterminal=true;
  else
    currmatchstr=matchstr(1:(dotpos(1)-1));
    nextmatchstr=matchstr((dotpos(1)+1):end);
    matchisterminal=false;
  end
%  if(sum(currmatchstr=='{')>0)
%    brakpos=find(currmatchstr=='{');
%    idxstr=currmatchstr((brakpos(1)+1):(end-1));
%    currmatchstr=currmatchstr(1:(brakpos-1));
%  end
%  task
  for(i=1:numel(nams))
    %nams{i}

    if(~dsstringmatch(currmatchstr,nams{i}))
      %currmatchstr
      %'did not match'
      continue;
    end
      %currmatchstr
    %'matched'
    clear filenm;
    fnam=nams{i};
      %if(strcmp(fnam,'initFeats'))
      %  keyboard;
      %end
    fieldisstruct=false;
    if(ismember({'disk'},recurseon))
      fieldisstruct=exist([currpath '/' fnam],'dir')&&~mystrcmp(fnam((end-1):end),'[]');
      %if(fieldisstruct&&~isfield(savestate,fnam))
      %  savestate=setfield(savestate,fnam,struct());
      %end
    end
    if(ismember({'savestate'},recurseon)&&isfield(savestate,fnam))
      fieldisstruct=fieldisstruct||isstruct(getfield(savestate,fnam));
    end
    if(ismember({'ds'},recurseon)&&isfield(currds,fnam))
      try
      fieldisstruct=fieldisstruct||isstruct(getfield(currds,fnam))&&(numel(getfield(currds,fnam))==1);
      catch,keyboard;end
    end
    %if(strcmp(fnam,'batch'))
    %  keyboard;
    %end
    if(fieldisstruct)
      %fnam
      %'field is struct'
      if(strcmp(task(1:4),'save')&&(...
            ~isfield(savestate,fnam)||...
            ((isfield(getfield(savestate,fnam),'savestate')&&getfield(getfield(savestate,fnam),'savestate')==0))||...
            isempty(getfield(savestate,fnam))))
        %disp('setting empty savesatate')
        mymkdir([currpath '/' fnam]);
        if(~isfield(savestate,fnam))
          savestate=setfield(savestate,fnam,struct());
        end
        if(strcmp(task,'savedistr'))
          respath=[respath; {fnam, struct()}];
        end
      end
      if(strcmp(task,'loadsavestate')&&(~isfield(savestate,fnam)))
        savestate=setfield(savestate,fnam,struct());
      end
      if(~isfield(currds,fnam))
        %add it so that the operation can complete.  The only operation that
        %even reads the resulting currds is dsload, so it doesn't matter
        %if we mess it up in other cases.
        currds=setfield(currds,fnam,struct());
      end
      if(strcmp(task,'delete')&&matchisterminal)
        if(isfield(savestate,fnam))
          savestate=rmfield(savestate,fnam);
          disp(['remove:' fnam]);
          rmdir([currpath '/' fnam],'s');
        end
        if(isfield(currds,fnam))
          currds=rmfield(currds,fnam);
        end
      elseif(strcmp(task,'expandpath')&&matchisterminal)
        respath=[respath;{fnam}];
      else
        if(isfield(savestate,fnam))
          savesttopass=getfield(savestate,fnam);
          savestup=true;
        else
          %if we got here and the field hasn't been added to the savestate,
          %we must be doing a delete and shouldn't add it.
          savesttopass=struct();
          savestup=false;
        end
        [savestate2 currds2 respath2]=dsrecurse(getfield(currds,fnam),basedir,[currpath '/' fnam],savesttopass,nextmatchstr,recurseon,task,brakidx);
        if(savestup)
          savestate=setfield(savestate,fnam,savestate2);
        end
        currds=setfield(currds,fnam,currds2);
        if(strcmp(task,'savedistr'))
          for(i=1:size(respath2,1))
            respath2{i,1}=[fnam '.' respath2{i,1}];
          end
          respath=[respath;respath2];
        end
      end
      if(strcmp(task,'expandpath')&&exist('respath2','var'))
        for(i=1:numel(respath2))
          respath2{i}=[fnam '.' respath2{i}];
        end
        respath=[respath;respath2];
      end
    else
      %disp(['got:' fnam]);
      %fnam
      %'field is not struct'
      cfnam=correspdisknams{i};
      if(strcmp(task,'load')||strcmp(task,'forceload'))
        [currds,savestate]=dsloadfield(fnam,currpath,currds,savestate,task,brakidx);
      elseif(strcmp(task,'loadsavestate'))
        dsloadfieldsavestate;
      elseif(strcmp(task(1:4),'save'))
        %'saving'
        if(strcmp(task(end-2:end),'chk'))
          checksave=1;
        else
          checksave=0;
        end
        [savestate respath2]=dssavefield(getfield(currds,fnam),fnam,basedir,currpath,savestate,brakidx,task,checksave);
        %for(i=1:size(respath2,1))
        %  respath2{i,1}=[fnam '.' respath2{i,1}];
        %end
        respath=[respath;respath2];
      elseif(strcmp(task,'move'))
        %if(~isfield(savestate,fnam))
        %  'empty savestae'
        %  fnam
        %end
        if(isfield(savestate,fnam))
          f=getfield(savestate,fnam);
        else
          f=struct();
        end
        savestate=dsmovefield(f,fnam,basedir,currpath,savestate);
        %if(~isfield(savestate,fnam))
        %  'empty savestae after'
        %  fnam
        %end

      elseif(strcmp(task,'delete'))
        %savestate=dsdeletefield(getfield(currds,fnam),fnam,basedir,currpath,savestate,brakidx);
        for(i=1:numel(cfnam))
          if(isfield(savestate,fnam)&&iscell(getfield(savestate,fnam))&&(~(isempty(brakidx{2}))))
            if(~isempty(brakidx{1}))
              %TODO: handle 2d arrays
              disp('dsdelete does not yet support 2d array indexing...will delete memory/savestate, not disk');
            else
              typ=dsgettypeforvar([],fnam);
              for(k=1:numel(brakidx{2}))
                nms=dsgetdisknamtype(num2str(brakidx{2}(k)),typ,'');
                for(l=1:numel(nms))
                  delete([currpath '/' cfnam{i} '/' nms{l} ]);
                end
              end
            end
          else
            if(exist([currpath '/' cfnam{i}],'dir'))
              rmdir([currpath '/' cfnam{i}],'s');
            else
              delete([currpath '/' cfnam{i}]);
            end
          end
        end
        if(isfield(savestate,fnam))
          if(iscell(getfield(savestate,fnam))&&~(isempty(brakidx{2})&&isempty(brakidx{1})))
            csst=getfield(savestate,fnam);
            if(numel(csst)<2)
              csst{2}=[];
            end
            if(isempty(brakidx{1}))
              csst{2}(brakidx{2})=false;
            else
              csst{2}(brakidx{1},brakidx{2})=false;
            end
            savestate=setfield(savestate,fnam,csst);
          else
            savestate=rmfield(savestate,fnam);
          end
        end
        if(isfield(currds,fnam))
          if(iscell(getfield(currds,fnam))&&~(isempty(brakidx{2})&&isempty(brakidx{1})))
            csst=getfield(currds,fnam);
            if(isempty(brakidx{1}))
              csst{brakidx{2}}=[];
            else
              csst{brakidx{1},brakidx{2}}=[];
            end
            currds=setfield(currds,fnam,csst);
          else
            currds=rmfield(currds,fnam);
          end
        end
      elseif(strcmp(task,'expandpath'))
        respath=[respath;{fnam}];
      end
    end
  end
%catch ex
%dsprinterr
%end
end
