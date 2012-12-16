%distributed processing settings
%run in parallel?
isparallel=0;
%if isparallel=1, number of parallel jobs
nprocs=150;
%if isparallel=1, whether to run on multiple machines or locally
isdistributed=1;

%output directory settings
global ds;
myaddpath;
ds.prevnm=mfilename;
dssetout(['/data/hays_lab/people/gen/discrim_patch_code/dsout/' ds.prevnm '_out']);
ds.dispoutpath=['/data/hays_lab/people/gen/discrim_patch_code/dsout/' ds.prevnm '_out/'];
%loadimset(7);
load('dataset15.mat');
setdataset(imgs,'/data/hays_lab/15_scene_dataset','');
if(isfield(ds.conf.gbz{ds.conf.currimset},'imgsurl'))
  ds.imgsurl=ds.conf.gbz{ds.conf.currimset}.imgsurl;
end

%general configuration

%define the number of training iterations used.  The paper uses 3; sometimes
%using as many as 5 can result in minor improvements.
num_train_its=5;

rand('seed',1234)

%parameters for Saurabh's code
ds.conf.params= struct( ...
  'imageCanonicalSize', 400,...% images are resized so that their smallest dimension is this size.
  'patchCanonicalSize', {[80 80]}, ...% patches are extracted at this size.  Should be a multiple of sBins.
  'scaleIntervals', 8, ...% number of levels per octave in the HOG pyramid 
  'sBins', 8, ...% HOG sBins parameter--i.e. the width in height (in pixels) of each cell
  'useColor', 1, ...% include a tiny image (the a,b components of the Lab representation) in the patch descriptor
  'patchOverlapThreshold', 0.6, ...%detections (and random samples during initialization) with an overlap higher than this are discarded.
  'svmflags', '-s 0 -t 0 -c 0.1');

ds.conf.detectionParams = struct( ...
  'selectTopN', false, ...
  'useDecisionThresh', true, ...
  'overlap', 0.4, ...% detections with overlap higher than this are discarded.
  'fixedDecisionThresh', -1.002);

%pick which images to use out of the dataset

imgs=ds.imgs{ds.conf.currimset};
ds.mycity={'bedroom'};%paris'};% for 15 scene test - bedroom
parimgs=find(ismember({imgs.city},ds.mycity));
toomanyprague=find(ismember({imgs.city},{'prague'})); %there's extra images from prague/london in the datset
toomanyprague=toomanyprague(randperm(numel(toomanyprague)));
toomanyprague=toomanyprague(1001:end);
toomanylon=find(ismember({imgs.city},{'london'}));
toomanylon=toomanylon(randperm(numel(toomanylon)));
toomanylon=toomanylon(1001:end);
parsub=find(ismember({imgs.city},{'paris_sub'}));
nycsub=find(ismember({imgs.city},{'nyc_sub'}));

ds.ispos=zeros(1,numel(imgs));
ds.ispos(parimgs)=1;
otherimgs=ones(size(imgs));
otherimgs(parimgs)=0;
otherimgs(toomanyprague)=0;
otherimgs(toomanylon)=0;
otherimgs(parsub)=0;
otherimgs(nycsub)=0;
otherimgs=find(otherimgs);
rp=randperm(numel(parimgs));

% keyboard
% GEN: this had to be changed bc we're useing 15 scene dataset...
% there are 216 bedroom images, using 150 for train...
parimgs=parimgs(rp(1:150));%2000));%usually 2000 positive images is enough; sometimes even 1000 works.
rp=randperm(numel(otherimgs));
otherimgs=otherimgs(rp(1:floor(length(otherimgs)/2)));%8000));%floor(length(otherimgs)/2)));%
ds.myiminds=[parimgs(:); otherimgs(:)];
ds.parimgs=parimgs;

'positive'
numel(parimgs)
'other'
numel(otherimgs)

%sample random positive "candidate" patches
step=2;
ds.isinit=makemarks(ds.myiminds(1:step:end),numel(imgs));
initInds=find(ds.ispos&ds.isinit);
if(isparallel&&(~dsmapredisopen()))
    dsmapredopen(nprocs, 1, ~isdistributed);
end
if(~dsfield(ds,'initFeats'))
  disp('sampling positive patches');
  ds.sample=struct();
  ds.sample.initInds=initInds;
  dsmapreduce('myaddpath;[ds.sample.patches{dsidx}, ds.sample.feats{dsidx}]=sampleRandomPatches(ds.sample.initInds(dsidx),25);',{'ds.sample.initInds'},{'ds.sample.patches','ds.sample.feats'});
  ds.initPatches=cell2mat(ds.sample.patches)';
  disp(['sampled ' num2str(numel(ds.initPatches)) ' patches']);
  ds.initFeats=cell2mat(ds.sample.feats');
  dsdelete('ds.sample')
  ds.initImgInds=initInds;
  dssave();
end

%Also sample some random negative patches as an initial negative set for SVM training/negative mining procedure
if(~dsfield(ds,'initFeatsNeg'))
  initInds=find((~ds.ispos)&ds.isinit);
  disp('sampling negative patches');
  ord=randperm(numel(initInds));
  myinds=ord(1:min(numel(ord),30));
  ds.sample.initInds=myinds;
  dsmapreduce('myaddpath;[ds.sample.patches{dsidx}, ds.sample.feats{dsidx}]=sampleRandomPatches(ds.sample.initInds(dsidx));',{'ds.sample.initInds'},{'ds.sample.patches','ds.sample.feats'});
  {'ds.initPatchesNeg','cell2mat(ds.sample.patches)'''};dsup;
  disp(['sampled ' num2str(numel(ds.initPatchesNeg)) ' patches']);
  {'ds.initFeatsNeg','cell2mat(ds.sample.feats'')'};dsup;
  {'ds.initImgIndsNeg','initInds'};dsup;
end
ds.centers=bsxfun(@rdivide,bsxfun(@minus,ds.initFeats,mean(ds.initFeats,2)),sqrt(var(ds.initFeats,1,2)).*size(ds.initFeats,2));
ds.selectedClust=1:size(ds.initFeats,1);
ds.assignedClust=ds.selectedClust;
dssave();

if(exist([ds.prevnm '_wait'],'file'))
  keyboard;
end

%comptue nearest neighbors for each candidate patch.
npatches=size(ds.centers,1);
ds.centers=[];
dsmapreduce('autoclust_assignnn2',{'ds.myiminds'},{'ds.assignednn','ds.assignedidx','ds.pyrscales','ds.pyrcanosz'});
ds.centers=[];


%Sort the candidate patches by the percentage of top 20 nearest neighbors that come from positive set.
%Create a display of the highest-ranked 1200.
for(i=1:numel(ds.assignednn))
  if(isempty(ds.assignednn{i}))
    ds.assignednn{i}=ones(npatches,1)*Inf;
  end
end
assignednn=cell2mat(ds.assignednn);
ds.assignednn={};
nneighbors=100;
for(j=npatches:-1:1)
  dists=[];
  [topndist(j,:),ord]=mink(assignednn(j,:),nneighbors);
  for(i=numel(ord):-1:1)
    topnlab(j,i)=ds.ispos(ds.myiminds(ord(i)));
    topnidx(j,i,:)=[reshape([ord(i) ds.assignedidx{ord(i)}(j,:)],1,1,[])];
  end
  if(mod(j,100)==0);disp(j);end
end
ds.assignedidx={};
clear assignednn;
perclustpost=sum(topnlab(:,1:20),2);
[~,postord]=sort(perclustpost,'descend');
ds.perclustpost=perclustpost(postord);
{'ds.selectedClust','ds.selectedClust(postord)'};dsup;
disppats=find(ismember(ds.assignedClust,ds.selectedClust(1:1200)));
correspimg=[ds.initPatches.imidx];
currdets=simplifydets(ds.initPatches(disppats),correspimg(disppats),ds.assignedClust(disppats));
if(dsfield(ds,'dispoutpath')),dssymlink(['ds.bestbin0'],ds.dispoutpath);end
prepbatchwisebestbin(currdets,0,1);
dispres_discpatch;
{['ds.bestbin0'],'ds.bestbin'};dsup;
ds.bestbin=struct();
%Greedily get rid of the patches that are redundant.
%Create a display that shows, for each non-redundant patch, a subset of its nearest 
%neighbors (specifically, the [1st:10th]- and [15th:7:100th]-nearest)
dssave;
curridx=1;
selClustIdx=1;
mainflag=1;
topndets={};
topndetshalf={};
topndetstrain={};
topnorig=[];
newselclust=[];
for(i=reshape(postord,1,[]))
  if(mainflag)
    curdet=[];
    for(j=1:nneighbors)
      imgidx=topnidx(i,j,1);
      pos=pyridx2pos(reshape(topnidx(i,j,3:4),1,[]),ds.pyrcanosz{imgidx},ds.pyrscales{imgidx}(topnidx(i,j,2)),...
           ds.conf.params.patchCanonicalSize(1)/ds.conf.params.sBins-2,ds.conf.params.patchCanonicalSize(2)/ds.conf.params.sBins-2,...
                 ds.conf.params.sBins,ds.imgs{ds.conf.currimset}(ds.myiminds(imgidx)).imsize);
      curdet=[curdet;struct('decision',-topndist(i,j),'pos',pos,...
               'imidx',ds.myiminds(imgidx),'detector',ds.selectedClust(selClustIdx))];
      curridx=curridx+1;
    end
    if(mainflag)
      [tmpmainflag]=testclusteroverlap(topndetshalf,curdet(1:50));
    end
    origpatind=find(ds.selectedClust(selClustIdx)==ds.assignedClust);
    origdet=ds.initPatches(origpatind);
    origdet=struct('decision',0,'pos',...
               struct('x1',origdet.x1,'x2',origdet.x2,'y1',origdet.y1,'y2',origdet.y2),...
               'imidx',origdet.imidx,'detector',ds.selectedClust(selClustIdx),'count',ds.perclustpost(selClustIdx));
    if(tmpmainflag)
      if(numel(topnorig)<1200)
        topndets=[topndets;{curdet([1:10 15:7:100])}];%for display
        topndetshalf=[topndetshalf;{curdet(1:50)}];%for duplicate detection
        topndetstrain=[topndetstrain;{curdet(1:5)}];%for initializing detectors
        topnorig=[topnorig;origdet];
      end
      disp(['now have ' num2str(numel(newselclust)) ' topnorig']);
      newselclust=[newselclust ds.selectedClust(selClustIdx)];
      if(numel(newselclust)>=1200)
        mainflag=0;
      end
      tmpmainflag=0;
    end
  end
  selClustIdx=selClustIdx+1;
  disp([num2str(selClustIdx) '/' num2str(numel(postord))]);
end
clear topndetshalf;
{'ds.selectedClust','newselclust'};dsup;
ds.topnidx=topnidx;
ds.topnlab=topnlab;
ds.topndist=topndist;
topndets=cell2mat(topndets);
if(dsfield(ds,'dispoutpath')),dssymlink(['ds.bestbin_topn'],ds.dispoutpath);end
prepbatchwisebestbin(topnorig,0,1,1);
ds.bestbin.counts=[[topnorig.count]' 20-[topnorig.count]'];
ds.bestbin.iscorrect=true(size(ds.bestbin.decision));
dispres_discpatch;
dsmv('ds.bestbin.bbhtml','ds.bestbin.allcandidateshtml');
prepbatchwisebestbin(topndets,1,100,[1:10 15:7:100]);
ds.bestbin.splitflag=1;
dispres_discpatch;
{['ds.bestbin_topn'],'ds.bestbin'};dsup;
dsdelete('ds.bestbin');
dssave;
ds.bestbin_topn.alldiscpatchimg=cell(size(ds.bestbin_topn.alldiscpatchimg));

%extract features for the top 5 for each cluster
topndetstrain=cell2mat(topndetstrain);
trpatches=extractpatches(topndetstrain,ds.imgs{ds.conf.currimset});
dsmv('ds.initFeats','ds.initFeatsOrig');
dsmv('ds.assignedClust','ds.assignedClustOrig');
ds.initFeats=zeros(numel(trpatches),size(ds.initFeatsOrig,2));
ds.initFeatsOrig=[];
extrparams=ds.conf.params;
extrparams.imageCanonicalSize=[min(ds.conf.params.patchCanonicalSize)];
for(i=1:numel(trpatches))
  tmp=constructFeaturePyramidForImg(im2double(trpatches{i}),extrparams,1);
  ds.initFeats(i,:)=tmp.features{1}(:)';
  if(mod(i,10)==0)
    disp(i);
  end
end
ds.assignedClust=[topndetstrain.detector];
ds.posPatches=topndetstrain;
clear trpatches;
clear topnidx;
clear topnlab;
clear topndist;
clear topnorig;
dssave;


%begin cluster refinement procedure.
ds.conf.processingBatchSize=600;
pbs=ds.conf.processingBatchSize;
batchidx=0;
starti=1;
if(dsfield(ds,'batch','curriter'))
  starti=1+(pbs*(ds.batch.curriter-1))
  batchidx=ds.batch.curriter-1;
end
maintic=tic;
if(isparallel&&(~dsmapredisopen()))
  dsmapredopen(nprocs,1,~isdistributed);
  pause(10);
end
j=1;
ds.batch.round.assignedClust=[];
ds.batch.round.posFeatures=[];
ds.batch.round.assignedClust=[];
ds.batch.round.selectedClust=[];
ds.batch.round.selClustIts=[];
ds.batch.nextClust=1;
ds.batch.finishedDets={};
ds.batch.nFinishedDets=0;

while((ds.batch.nextClust<=numel(ds.selectedClust)||size(ds.batch.round.posFeatures,1)>0))
    {'ds.batch.round.curriter','j'};dsup;
    stopfile=[ds.prevnm '_stop'];
    if(exist(stopfile,'file'))
      %lets you stop training and just output the results so far
      break;
    end
    pausefile=[ds.prevnm '_pause'];
    if(exist(pausefile,'file'))
      keyboard;
    end

    %choose which candidate clusters to start working on
    ntoadd=ds.conf.processingBatchSize-numel(ds.batch.round.selectedClust);
    rngend=min((ds.batch.nextClust+ntoadd-1),numel(ds.selectedClust));
    newselclust=ds.selectedClust(ds.batch.nextClust:rngend);
    newfeats=find(ismember(ds.assignedClust,newselclust));
    {'ds.batch.round.posFeatures','[ds.batch.round.posFeatures; ds.initFeats(newfeats,:)]'};dsup;
    {'ds.batch.round.assignedClust','[ds.batch.round.assignedClust ds.assignedClust(newfeats)]'};dsup;
    {'ds.batch.round.selectedClust','[ds.batch.round.selectedClust newselclust]'};dsup;
    {'ds.batch.round.selClustIts','[ds.batch.round.selClustIts zeros(size(newselclust))]'};dsup;
    {'ds.batch.nextClust','ds.batch.nextClust+ntoadd'};dsup;

    %choose the training/validation sets for the current round
    nsets=3;
    jidx=mod(j-1,nsets)+1;
    jidxp1=mod(j,nsets)+1;
    currtrainset=ds.myiminds([jidx:nsets:numel(ds.parimgs) (numel(ds.parimgs)+j):7:numel(ds.myiminds)]);
    currvalset=ds.myiminds([jidxp1:nsets:numel(ds.parimgs) (numel(ds.parimgs)+j+1):7:numel(ds.myiminds)]);
    {'ds.batch.round.totrainon','currtrainset'};dsup;
    {'ds.batch.round.tovalon','currvalset'};dsup;
    
    %initialize the SVMs using the random negative patches
    dsmapreduce('autoclust_initial',{'ds.batch.round.selectedClust'},{'ds.batch.round.firstDet','ds.batch.round.firstResult'});
    dets=VisualEntityDetectors(ds.batch.round.firstDet, ds.conf.params);
    {'ds.batch.round.detectors','dets'};dsup;

    %Use the hard negative mining technique to train on negatives from the current negative set
    istrain=zeros(numel(ds.imgs{ds.conf.currimset}),1);
    istrain(ds.batch.round.totrainon)=1;
    allnegs=find((~ds.ispos(:))&istrain(:));
    currentInd = 1;
    maxElements = length(allnegs);
    iter = 1;
    startImgsPerIter = 15;
    alpha = 0.71;
    if(~dsfield(ds,'batch','round','mineddetectors'))
      dsdelete('ds.batch.round.negmin');
      while(currentInd<=maxElements)
        imgsPerIter = floor(startImgsPerIter * 2^((iter - 1)*alpha));
        finInd = min(currentInd + imgsPerIter - 1, maxElements);
        {'ds.batch.round.negmin.iminds','allnegs(currentInd:finInd)'};dsup;
        conf.noloadresults=1;
        dsmapreduce('autoclust_mine_negs',{'ds.batch.round.negmin.iminds'},{'ds.batch.round.negmin.imageflags'},struct('noloadresults',1));
        dsmapreduce('autoclust_train_negs',{'ds.batch.round.selectedClust'},{'ds.batch.round.nextnegmin.traineddetectors'},struct('noloadresults',1));
        dsload('ds.batch.round.nextnegmin.traineddetectors');

        dets = VisualEntityDetectors(ds.batch.round.nextnegmin.traineddetectors, ds.conf.params);
        {'ds.batch.round.detectors','dets'};dsup;
        dssave();
        dsdelete('ds.batch.round.negmin');
        dsmv('ds.batch.round.nextnegmin','ds.batch.round.negmin');
        iter=iter+1;
        currentInd=currentInd+imgsPerIter;
      end
      dsdelete('ds.batch.round.negmin');
    end
    {'ds.batch.round.iminds','[ds.batch.round.totrainon; ds.batch.round.tovalon]'};dsup;
    {'ds.batch.round.mineddetectors','dets'};dsup;
    pausefile=[ds.prevnm '_pause'];
    if(exist(pausefile,'file'))
      keyboard;
    end

    %run detection on both the training and validation sets
    dsmapreduce('autoclust_detect',{'ds.batch.round.iminds'},{'ds.batch.round.detectorflags'},struct('noloadresults',1));

    %find the top detections for each detector
    conf2.allatonce=true;
    dsmapreduce('autoclust_topn',{'ds.batch.round.selectedClust'},{'ds.batch.round.traintopN','ds.batch.round.validtopN','ds.batch.round.alltopN'},conf2);
    validtopN=ds.batch.round.validtopN;
    traintopN=ds.batch.round.traintopN;


    %extract the top 5 from the validation set for the next round
    [posFeatures, positivePatches, ...
      posCorrespInds, posCorrespImgs, assignedClustVote, ...
      assignedClustTrain, selectedClusters] = ...
      prepareDetectedPatchClusters(validtopN, ...
        10, 5, ds.conf.params, ds.batch.round.tovalon(logical(ds.ispos(ds.batch.round.tovalon))), ds.batch.round.selectedClust);
      currdets=simplifydets(positivePatches,posCorrespImgs,assignedClustTrain);
    %extract the top 100 and display them
    [~, positivePatches2, ...
      ~, posCorrespImgs2,~,assignedClustTrain2] = ...
      prepareDetectedPatchClusters(ds.batch.round.alltopN, ...
        100, 100, ds.conf.params, ds.batch.round.tovalon, ds.batch.round.selectedClust);
    dispdets=simplifydets(positivePatches2,posCorrespImgs2,assignedClustTrain2);
    %end
    dispdetscell={};
    dispdetscellv2={};
    for(i=1:numel(ds.batch.round.selectedClust))
      mydispdets=dispdets([dispdets.detector]==ds.batch.round.selectedClust(i));
      [~,ord5]=sort([mydispdets.decision],'descend');
      dispdetscell{i}=mydispdets(ord5([1:10 15:7:min(numel(ord5),100)]));
      dispdetscell{i}=dispdetscell{i}(:)';
    end
    dispdets=cell2mat(dispdetscell)';

    %Up until this point in the while loop, if the program crashes (e.g. due
    %to disk write failures) you can just restart it at line 286 and the
    %right thing should happen. After this point, however,
    %the program starts performing updates that shouldn't happen twice.

    dsmv('ds.bestbin_topn','ds.bestbin');  
    prepbatchwisebestbin(dispdets,j+2,100,[1:10 15:7:100]);
    dispres_discpatch;
    dsmv('ds.bestbin','ds.bestbin_topn');
    dssave;
    ds.bestbin_topn.alldiscpatchimg=cell(size(ds.bestbin_topn.alldiscpatchimg));

    tooOldClusts=ds.batch.round.selectedClust(ds.batch.round.selClustIts>=num_train_its);
    ds.sys.savestate.thresh=[];
    finished=find(ismember(ds.batch.round.selectedClust,intersect(selectedClusters,tooOldClusts)));
    ds.findetectors{j}=selectDetectors(ds.batch.round.detectors,finished);
    ds.finSelectedClust{j}=ds.batch.round.selectedClust(finished(:)');

    %store stuff (finished detectors, top detections etc.) for next round 
    {'ds.batch.nFinishedDets','ds.batch.nFinishedDets+size(ds.findetectors{j}.firstLevModels.w,1)'};dsup;
    selectedClusters=setdiff(selectedClusters,tooOldClusts);
    markedAssiClust=ismember(ds.batch.round.assignedClust, selectedClusters);
    markedAssiClust=ismember(assignedClustTrain, selectedClusters);
    assignedClustTrain=assignedClustTrain(markedAssiClust);
    posFeatures=posFeatures(markedAssiClust,:);
    [~,indstokeep]=ismember(selectedClusters,ds.batch.round.selectedClust);
    indstokeep(indstokeep==0)=[];
    selClustIts=ds.batch.round.selClustIts(indstokeep)+1;
    dssave;
    dsdelete('ds.batch.round.topdetsmap');
    dsmv('ds.batch.round',['ds.batch.round' num2str(j)])%create a backup
    dssave();
    {'ds.batch.round.posFeatures','posFeatures'};dsup;
    {'ds.batch.round.assignedClust','assignedClustTrain'};dsup;
    {'ds.batch.round.selectedClust','selectedClusters(:)'''};dsup;
    {'ds.batch.round.selClustIts','selClustIts'};dsup;
    dssave();
    eval(['ds.batch.round' num2str(j) '=struct();']);%remove the backup from memory
    j=j+1;
end
toc(maintic);
dets=collateAllDetectors2(ds.findetectors);
{'ds.selectedClust','cell2mat(ds.finSelectedClust)'};dsup;
dssave;
{'ds.dets','dets'};dsup;

%run the detectors on the entire dataset to compute purity/overlap
citiestogen=ds.mycity;
ds.conf.origdetectionParams=ds.conf.detectionParams;
dps = struct( ...
          'selectTopN', false, ...
          'useDecisionThresh', true, ...
          'overlap', .5,...
          'fixedDecisionThresh', -.85,...
          'removeFeatures',1);
{'ds.conf.detectionParams','dps'};dsup;
dsmapreduce(['myaddpath;dsload(''ds.dets'');ds.detsimple{dsidx}=simplifydets(ds.dets.detectPresenceInImg(' ...
            'double(getimg(ds.myiminds(dsidx)))/256,ds.conf.detectionParams' ...
            '),ds.myiminds(dsidx));'],{'ds.myiminds'},{'ds.detsimple'},struct('noloadresults',1));
if(dsmapredisopen())
  dsmapredclose;
end

maxdet=size(ds.dets.firstLevModels.w,1);
imgs=ds.imgs{ds.conf.currimset};
dsdelete('ds.bestbin');


%'overallcounts' is the version of the display described in the paper: for each detector, 
%find the top 30 detections, and rank based on the proportion that's in paris.
%
%'posterior' finds all firings with a score > -.2 and computes the quantity 
%(#paris+1)/(#paris+#nonparis+2), where #paris is the number of firings in Paris,
%and #nonparis is the number of firings outside Paris.  Thus, it's a posterior
%estimate of the probability \theta that a firing will be in Paris, starting
%with a uniform prior on \theta.  In practice, detectors are more confident on
%elements that look very different from the negative set; hence this ranking
%tends to prefer elements that look very different from the negative set, whereas
%the 'overallcounts' tends to prefer elements that are more common.

disptype={'overallcounts','posterior'};
dsload('ds.myiminds','recheck');
[topn,posCounts,negCounts]=readdetsimple(maxdet,-.2,struct('oneperim',1,'issingle',1,'nperdet',250));
for(k=1:numel(disptype))
  alldetections=[topn{1}(:);topn{2}(:)]';
  detsimpletmp=[];
  tmpdetectors=[alldetections.detector];
  tmpdecisions=[alldetections.decision];
  for(i=unique([alldetections.detector]))
    myinds=find(tmpdetectors==i);
    [~,ord]=sort(tmpdecisions(myinds),'descend');
    tmpdetsfordetr=alldetections(myinds(ord(1:min(numel(ord),30))));
    if(strcmp('overallcounts',disptype{k}))
      topNall{i}=alldetections(myinds(ord(1:min(numel(ord),250)))); 
    else
      topNall{i}=alldetections(myinds(ord(1:min(numel(ord),50))));
    end
    detsimpletmp=[detsimpletmp tmpdetsfordetr];
    switch(disptype{k})
    case('overallcounts')
      counts(i,1)=sum(ds.ispos([tmpdetsfordetr.imidx]));%ismember({ds.imgs{ds.conf.currimset}([tmpdetsfordetr.imidx]).city},citiestogen));
      counts(i,2)=numel(tmpdetsfordetr)-counts(i,1);
    case('posterior')
      counts(i,1)=sum(posCounts{1}(i,:));
      counts(i,2)=sum(negCounts(i,:));
    end
    disp(i)
  end
  if(strcmp(disptype{k},'overallcounts'))
    [~,detord]=sort(counts(:,1),'descend');
  else
    post=(counts(:,1)+1)./(sum(counts,2)+2)
    [~,detord]=sort(post,'descend');
  end
  [overl groups affinities]=findOverlapping(topNall(detord),struct('findNonOverlap',1));
  %detord=detord(overl)
  dsload('ds.selectedClust','recheck');
  resSelectedClust=ds.selectedClust(detord);
  detsimple=topn{1};
  for(j=1:numel(detsimple))
    detsimple(j).detector=ds.selectedClust(detsimple(j).detector);
  end
  if(strcmp(disptype{k},'overallcounts'))
    {'ds.selectedClustDclust','resSelectedClust'};dsup;
  end
  [~,mapping]=ismember(ds.selectedClustDclust,ds.selectedClust);
  ds.detsDclust=selectDetectors(ds.dets,mapping);

  %generate a display of the final detectors
  ds.bestbin.imgs=imgs;
  nycdets2=[];
  mydetectors=[];
  mydecisions=[];
  nycdets=detsimple;
  for(j=numel(nycdets):-1:1)
    mydetectors(j)=nycdets(j).detector;
    mydecisions(j)=nycdets(j).decision;
  end
  curridx=1;
  for(j=unique(mydetectors))
    myinds=find(mydetectors==j);
    [~,best]=maxk(mydecisions(myinds),20)
    nycdets2{1,curridx}=nycdets(myinds(best));
    curridx=curridx+1;
  end
  nycdets2=cell2mat(nycdets2');
  disp(numel(nycdets2))
  ds.bestbin.alldisclabelcat=[[nycdets2.imidx]',[nycdets2.detector]'];
  ds.bestbin.alldiscpatchimg=extractpatches(nycdets2,ds.bestbin.imgs);
  ds.bestbin.decision=[nycdets2.decision];
  countsIdxOrd=detord(overl(1:min(numel(overl),500)));
  ds.bestbin.tosave=ds.selectedClust(countsIdxOrd);
  ds.bestbin.isgeneral=ones(1,numel(ds.bestbin.tosave));
  ds.bestbin.counts=[counts(countsIdxOrd,1),counts(countsIdxOrd,2)];
  if(exist('misclabel','var'))
    ds.bestbin.misclabel{1}=misclabel(countsIdxOrd);
  end
  dispres_discpatch;
  bbhtmlorig=ds.bestbin.bbhtml;
  ds.bestbin.tosave=[];
  ds.bestbin.counts=[];
  ds.bestbin.group=ones(size(ds.bestbin.decision))*2;
  for(i=1:max(groups))
    togroup=detord(find(groups==i));
    togroup=togroup(:)';
    ds.bestbin.tosave=[ds.bestbin.tosave; ds.selectedClust(togroup)'];
    ds.bestbin.counts=[ds.bestbin.counts;[counts(togroup,1),counts(togroup,2)]];
    for(j=togroup(2:end))
      ds.bestbin.alldisclabelcat(end+1,:)=[0 ds.selectedClust(j)];
      ds.bestbin.alldiscpatchimg{end+1}=reshape([1 1 1],1,1,[]);
      ds.bestbin.decision(end+1)=0;
      ds.bestbin.isgeneral(end+1)=1;
      ds.bestbin.group(end+1)=1;
    end
  end
  ds.bestbin.affinities=affinities;
  dispres_discpatch;
  ds.bestbin.bbgrouphtml=ds.bestbin.bbhtml;
  ds.bestbin.bbhtml=bbhtmlorig;
  dsmv('ds.bestbin',['ds.bestbin_' disptype{k}]);
  if(dsfield(ds,'dispoutpath')),dssymlink(['ds.bestbin_' disptype{k}],[ds.dispoutpath]);end
  dssave;
  dsclear(['ds.bestbin_' disptype{k}]);
end
