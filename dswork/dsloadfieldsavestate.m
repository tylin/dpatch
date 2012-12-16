%function [currds savestate]=dsloadfield(dfnam,currpath,currds,savestate)
%we want this to be a script instead of a function so we don't create duplicates of the ds variable.
%currpath references the parent directory, and currds/savestate reference the parents as well.
%  ds=struct();
%  savestate=struct();
%  nams=cleandir(currpath);
%  for(i=1:numel(nams))
%    dfnam=nams(i).name;
    if('.'==cfnam{1}(1))
      %warp seems to generate random nfs file handles
      return;
    end
for(dslf_idx=1:numel(cfnam))
    dfnam=cfnam{dslf_idx};
    fpath=[currpath '/' dfnam];
    if(exist(fpath,'dir'))
       %'got dir'
%      if(~all(dfnam(end-1:end)=='[]'))
        %struct case
%        [tmpds tmpsavestate]=dsload_rec(fpath);
%        savestate=setfield(savestate, dfnam, tmpsavestate);
%        ds=setfield(ds, dfnam, tmpds);
%      else
        %cell case
        if(dshassuffix(fnam,'img'))
          isimg=1;
        else
          isimg=0;
        end
        if(dshassuffix(fnam,'html'))
          ishtml=1;
        else
          ishtml=0;
        end
        if(dshassuffix(fnam,'txt'))
          istxt=1;
        else
          istxt=0;
        end
        if(dshassuffix(fnam,'fig'))
          return;
        end
        %files=cleandir(fpath);
        %nfiles=numel(files);
        %idxlist=zeros(nfiles,1);
        %for(i=1:nfiles)
        %  dotpos=find(files(i).name=='.');
        %  idxlist(i)=str2num(files(i).name(1:(dotpos(1)-1)));
        %end
        %cellsavest=getfield(savestate,sdfnam);
        %tmpcell=cell(size(cellsavest));
        %sdfnam=dfnam;%(1:(end-2));
        %if(isfield(currds,sdfnam))
        %  tmpcell2=getfield(currds,sdfnam);
        %  if(numel(tmpcell)>numel(tmpcell2))
        %    tmpcell(1:numel(tmpcell2))=tmpcell2;
        %  else
        %    tmpcell=tmpcell2;
        %  end
        %end
        %if(isfield(savestate,sdfnam)&&~isempty(getfield(savestate,sdfnam)))
        %  cellsavest2=getfield(savestate,sdfnam);
        %  cellsavest2=cellsavest2{2};
        %  cellsavest=zeros(max(max(idxlist),size(cellsavest2,1));
        %  if(numel(cellsavest)>numel(cellsavest))
        %    cellsavest(1:numel(cellsavest2))=cellsavest2;
        %  else
        %    cellsavest=cellsavest2;
        %  end
        %else
        %  cellsavest=zeros(max(idxlist),1);
        %end
        %if(~isempty(brakidx))
        %  mybrakidx=intersect(brakidx,idxlist);
        %  mybrakidx=mybrakidx(:)';
        %else
        %  mybrakidx=idxlist(:)';
        %end
        dslf_cols=cleandir(fpath);
        dslf_cols=cellfun(@(x) str2num(x(1:find(x=='.'))),{dslf_cols.name});
        if(~isempty(brakidx{2}))
          dslf_brakidx{2}=sort(intersect(dslf_cols,brakidx{2}),'descend')
        else
          dslf_brakidx{2}=sort(dslf_cols,'descend');
        end

%        for(dslf_k=1:2)
%          if(isempty(brakidx{dslf_k}))
%            brakidx{dssf_k}=1:size(cellsavest,dssf_k);
%          end
%        end

        %cellsavest=zeros(max(dslf_brakidx{1}),max(dslf_brakidx{2}));
        %tic
        if(isimg||ishtml||istxt)
          cellsavest(dslf_brakidx{2})=1;
        else
          cellsavest=[];
          for(dslf_i=dslf_brakidx{2}(:)')
            %dslf_i
            %fpath2=[fpath '/' num2str(dslf_i)];
            dslf_filnam=[fpath '/' num2str(dslf_i) '.mat'];
            %tic
            %dslf_cols=cleandir(fpath2);
            %toc
            contents=[];
            try
            tic
            load(dslf_filnam,'contents');
            toc
            catch
            end
            if(isempty(contents))
              %it turns out whos loads the whole archive, so this is really
              %slow.  it isn't used any more; here only for backwards
              %compatibility.
              %tic
              %dslf_vars=whos('-file',dslf_filnam);
              %toc
              %dslf_rows=cellfun(@(x) str2num(x(5:end)),{dslf_vars.name});
              dslf_rows=1;
            else
              dslf_rows=contents;
            end
            clear contents;
            if(~isempty(brakidx{1}))
              dslf_brakidx{1}=sort(intersect(dslf_rows,brakidx{2}),'descend')
            else
              dslf_brakidx{1}=sort(dslf_rows,'descend');
            end
            %tic
            %dslf_files=cleandir(fpath2);
            %toc
            %dslf_files={dslf_files.name};
            for(dslf_j=dslf_brakidx{1}(:)')
              cellsavest(dslf_j,dslf_i)=1;
              %if(strcmp(task,'load'))
                %if(isimg)
                %  cellsavest(dslf_i,dslf_j)=ismember(dslf_j,dslf_cols);%(exist([fpath2 '/' num2str(dslf_j) '.jpg'],'file')>0);
                %elseif(ishtml) 
                %  cellsavest(dslf_i,dslf_j)=ismember([ num2str(dslf_j) '.html'],dslf_files);%(exist([fpath2 '/' num2str(dslf_j) '.html'],'file')>0);
                %else
                  %[fpath2 '/' num2str(dslf_j) '.mat']
                %  cellsavest(dslf_i,dslf_j)=ismember([ num2str(dslf_j) '.mat'],dslf_files);%(exist([fpath2 '/' num2str(dslf_j) '.mat'],'file')>0);
                  %disp('got data')
                  %keyboard;
                  %tmpcell{dslf_i,dslf_j}=data;
                %end
              %end
              %cellsavest(i,j)=1;
            end
          end
        end
        %toc
%        if(strcmp(task,'load'))
        %currds=setfield(currds,dfnam,tmpcell);
 %       end
        savestate=setfield(savestate,fnam,{1,cellsavest});
%      end
    else
      %if(dshassuffix(dfnam,'html'))
        %if(strcmp(task,'load'))
        %  data=fileread([currpath '/' dfnam '.html']);
        %end
      %  vnam=dfnam;%(:,1:end-5);
      if(dshassuffix(dfnam,'img'))
        if(dshassuffix(dfnam(1:end-4),'fig'))
          return;
        end
        %if(strcmp(task,'load'))
        %  data=imread([currpath '/' dfnam '.jpg']);
        %end
        %vnam=dfnam;%(:,1:end-4);
        %ds=setfield(ds,vnam,data);
      %elseif(dshassuffix(dfnam,'fig'))
        %continue;
      %  return
      %else
        %if(strcmp(task,'load'))
      %    load([currpath '/' dfnam '.jpg');
        %end
      %  vnam=dfnam;%(:,1:end-4);
          %if(strcmp(vnam,'binneighs'))
          %keyboard;
          %end
          %ds=setfield(ds,vnam,data);
      %end
      %if(strcmp(task,'load'))
      %  currds=setfield(currds,vnam,data);
      end
      savestate=setfield(savestate,fnam,1);
    end
end
  %keyboard;
%end
