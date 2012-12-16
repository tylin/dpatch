% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Read the variable ds.detsimple and summarize it, without
% loading the whole thing into memory (for some reason, matlab
% is really inefficient at loading ds.detsimple).
%
% It supports many modes of operation, but only one is actually
% used, so I will explain only that call, which appears in
% autoclust_main.m
%
% topn collects the top 100 detections for each detector, separately
% for the positive images (those marked as positive by .ds.ispos)
% and the negative images.  All
% of these top detections are concatenated together in topn in no
% particular order.  The conf.issingle flag tells readdetsimple to
% treat all cities listed in cat as a single positive class; not setting
% this flag causes the cities to be treated separately (and thus you will
% get 100 top detections for each.  Any detections with scores lower than
% ctthresh are ignored. The oneperim flag means only the highest-scoring
% detection for each detector for each image is considered.
% maxdetector is the number of unique detectors fired on the 
% images to produce ds.detsimple.

function [topn,posCount,negCount,posCtIds]=readdetsimple(maxdetector,ctthresh,conf)
  ispos=dsload('.ds.ispos');
  if(~exist('ctthresh','var'))
    ctthresh=0;
  end
%  if(~exist('issingle','var'))
    issingle=0
    oneperim=0
    nperdet=100
%  end
  if(exist('conf','var'))
    if(isfield(conf,'issingle'))
      issingle=conf.issingle;
    end
    if(isfield(conf,'oneperim'))
      oneperim=conf.oneperim;
    end
    if(isfield(conf,'nperdet'))
      nperdet=conf.nperdet;
    end
  end
  %if(~iscell(cat))
  %  cat={cat};
  %  uncell=1;
  %else
    uncell=0;
  %end
  nouts=2;%numel(cat)+1;
  uncell
  pause(1);
  if(issingle)
    nouts=2;
    %uncell=1;
  end
  global ds;
  %post=zeros(maxdetector,2);
  posCount=[];
  negCount=[];
  for(i=1:nouts)
    topn{i}=cell(maxdetector,1);
    posCount{i}=[];%zeros(maxdetector,1);
    posCtIds{i}=[];%zeros(maxdetector,1);
  end
  function res=maxkcombine(x, y)
    allxy=[x;cell2mat(y)];
    if(isempty(allxy))
      res=[];
      return;
    end
    for(i2=numel(allxy):-1:1)
      dec(i2)=allxy(i2).decision;
    end
    %[~,ord]=maxk(dec,20);
    [~,ord]=sort(dec,'descend');
    ord=ord(1:min(numel(ord),nperdet));
    res=allxy(ord);
  end
  %detsbydetector=cell(maxdetector,1);
  detsbydetector=repmat({repmat({{}},maxdetector,1)},nouts,1);
  locstouched=[];
  imgs=dsload(['.ds.imgs{' num2str(dsload('.ds.conf.currimset')) '}']);
  for(i=1:numel(ds.myiminds))
    a=tic;
    tic
    dsload(['ds.detsimple{' num2str(i) '}'])
    toc
    if(numel(ds.detsimple)>=i&&~isempty(ds.detsimple{i}))
      mydets=ds.detsimple{i};
      ds.detsimple{i}=[];
      %mypostidx=1+(strcmp(imgs(ds.myiminds(i)).city,cat));
        curCount=zeros(maxdetector,1);
        loc=double(ispos(ds.myiminds(i)));%ismember({imgs(ds.myiminds(i)).city},cat);
        if(issingle)
          loc=min(loc,1);
        end
        if(loc==0)
          loc=nouts;
        end
        locstouched(loc)=1;
        tic
        if(oneperim)
          [~,resortord]=sort([mydets.decision],'descend');
          mydets=mydets(resortord);
          [~,inds]=unique([mydets.detector],'first');
          mydets=mydets(inds);
        end
        for(j=1:numel(mydets))
          if(mydets(j).decision>ctthresh)
            curCount(mydets(j).detector)=curCount(mydets(j).detector)+1;
          end
          detsbydetector{loc}{mydets(j).detector}=[detsbydetector{loc}{mydets(j).detector};{mydets(j)}];
        end
        toc
        %disp(cat)
        %disp(imgs(ds.myiminds(i)).city)
      if(ispos(ds.myiminds(i)))%ismember({imgs(ds.myiminds(i)).city},cat))
        posCount{loc}=[posCount{loc} curCount];
        posCtIds{loc}=[posCtIds{loc} i];
      else
        negCount=[negCount curCount];
        posCount{loc}=[posCount{loc} curCount];
        posCtIds{loc}=[posCtIds{loc} i];
      end
    else
      mydets=[];
      curCount=zeros(maxdetector,1);
        %if(issingle)
        %  loc=1;
        %else
        %  [~,loc]=ismember({imgs(ds.myiminds(i)).city},cat);
        %end
        %if(loc==0)
        %  loc=nouts;
        %end
        loc=double(ispos(ds.myiminds(i)));%ismember({imgs(ds.myiminds(i)).city},cat);
        if(issingle)
          loc=min(loc,1);
        end
        if(loc==0)
          loc=nouts;
        end
      if(ispos(ds.myiminds(i)))%ismember({imgs(ds.myiminds(i)).city},cat))
        posCount{loc}=[posCount{loc} curCount];
        posCtIds{loc}=[posCtIds{loc} i];
      else
        negCount=[negCount curCount];
        posCount{loc}=[posCount{loc} curCount];
        posCtIds{loc}=[posCtIds{loc} i];
      end
    end
    if(mod(i,100)==0)
      disp('maxkcombine');
      tic
      %keyboard
      locstouched
      for(m=find(locstouched))
        topn{m}=cellfun(@maxkcombine,topn{m},detsbydetector{m},'UniformOutput',false);
      end
      %keyboard;
      %detsbydetector=cell(maxdetector,1);
      %detsbydetector=repmat({{}},maxdetector,1);
      detsbydetector=repmat({repmat({{}},maxdetector,1)},nouts,1);
      locstouched=[];
      toc
    end
    disp(num2str(i));
    toc(a)
  end
      for(m=find(locstouched))
        topn{m}=cellfun(@maxkcombine,topn{m},detsbydetector{m},'UniformOutput',false);
      end
      %      for(m=find(locstouched))
      %        topn{loc}=cellfun(@maxkcombine,topn{loc},detsbydetector,'UniformOutput',false);
      %      end
  %post=post(:,1)./(sum(post,2));
%  keyboard;
  %if(0)
  %for(i=1:numel(topn))
  %  if(iscell(topn{i}))
  %    topn{i}=structcell2mat(topn{i});
  %  end
  %end
  for(j=1:maxdetector)
    currdecs=[];
    for(i=1:numel(topn))
      if(~isempty(topn{i}{j}))
        tmpdecs=[topn{i}{j}.decision];
        currdecs=[currdecs tmpdecs(:)'];
      end
    end
    [~,ord]=sort(currdecs,'descend');
    if(numel(ord)>0)
      minthresh(j)=currdecs(ord(min(nperdet,numel(ord))));
    else
      minthresh(j)=-1;
    end
  end
  for(i=1:numel(topn))
    if(iscell(topn{i}))
      topn{i}=structcell2mat(topn{i});
    end
    %disp(['extra top detections ' num2str(i)]);
    %for(j=1:numel(topn{i}))
    %  det=topn{i}(j);
    %  idx=find(posCtIds{i}==det.imidx);
%        disp('added')
%        disp([num2str(minthresh(det.detector)) ' < ' num2str(topn{i}(j).decision) ' < ' num2str(ctthresh)]);
%try
    %  if(topn{i}(j).decision<ctthresh&&topn{i}(j).decision>=minthresh(det.detector))
    %    posCount{i}(det.detector,idx)=posCount{i}(det.detector,idx)+1;
    %  end
      %catch
      %keyboard
      %end
    %end
  end
  if(uncell)
    posCount=posCount{1};
    topn=topn{1};
  end
  %end
end
