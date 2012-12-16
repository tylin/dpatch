% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Get the top detections for each detector, based on the results of
% autoclust_detect.  The set of detectors to mine are given in 
% ds.batch.round.detectors(dsidx), where ds.batch.round.selectedClust(dsidx)
% is their ids.  Note that this is meant to run in the dsmapreduce allatonce
% mode, so dsidx may be a vector.  ds.batch.round.iminds gives the image ids 
% that autoclust_detect was run on, and ds.batch.round.tovalon/totrainon are
% the image ids for the validation and training sets.  ds.ispos indicates
% whether each image (by id) is from the positive set.  We find the top n for
% 3 sets: ds.batch.round.traintopN is the top 20 in the positive training set;
% ds.batch.round.validtopN is the top 20 in the positive validation set (used
% for the next round of training), and ds.batch.round.alltopN is the top 100
% in both the positive and negative validation sets (used for display).
% ds.batch.round.purity is the fraction of ds.batch.round.alltopN that is
% from the positive set.

myaddpath;
%if(0)
  imgs=dsload('.ds.imgs');
  ispos=dsload('ds.ispos');
  dsload('ds.batch.round.detectors');
  dsload('ds.batch.round.selectedClust');
  dsload('ds.batch.round.tovalon');
  dsload('ds.batch.round.totrainon');
  dsload('ds.batch.round.iminds');

    numTopN = 20;
    maxOverlap = 0.1;
%    alldets=[];
%    for(k=1:numel(ds.batch.round.detections{k}))
%      tmpdets=simplifydets(ds.batch.round.detections{k});
%      alldets=[alldets;tmpdets];
%    end
    detObj=PresenceDetectionResults2(dsidx,numel(ds.batch.round.selectedClust),ds.batch.round.iminds);

    traintopN=getTopNDetsPerCluster2(detObj,maxOverlap,ds.batch.round.totrainon(ispos(ds.batch.round.totrainon)==1),numTopN);
    valtopN=getTopNDetsPerCluster2(detObj,maxOverlap,ds.batch.round.tovalon(ispos(ds.batch.round.tovalon)==1),numTopN);
    for(i=1:numel(valtopN))
      if(numel(unique([valtopN{i}.imgIds]))~=numel(valtopN{i}.imgIds))
        throw(MException('ac:valtopn',['valtopn ' num2str(dsidx(i)) ' contains repeats']));
      end
    end
    alltopN=getTopNDetsPerCluster2(detObj,maxOverlap,ds.batch.round.tovalon,100);
    %mycity=dsload('.ds.mycity');
    %for(i=1:numel(dsidx))
    %  purity(i)=sum(ismember({imgs{ds.conf.currimset}(alltopN{i}.imgIds).city},mycity))./numel(alltopN{i});
    %end

    for(i=1:numel(dsidx))
      {'ds.batch.round.traintopN{dsidx(i)}','traintopN{i}'};dsup;
      {'ds.batch.round.validtopN{dsidx(i)}','valtopN{i}'};dsup;
      {'ds.batch.round.alltopN{dsidx(i)}','alltopN{i}'};dsup;
      % {'ds.batch.round.purity{dsidx(i)}','purity(i)'};dsup;
    end

