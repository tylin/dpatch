% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
% 
% Read the results of one round of negative mining and train
% a detector.  The id of the detector to retrain is specified in
% ds.batch.round.selectedClust(dsidx), the positive patches
% (which are assumed to be fixed throughout negative mining) are
% given by: 
% ds.batch.round.posFeatures(ds.batch.round.assignedClust==ds.batch.round.selectedClust(dsidx),:).
% ds.batch.round.detections{ds.batch.round.negmin.iminds,dsidx} are the newly 
% mined negatives, which will be combined with 
% ds.batch.round.negmin.prevfeats{dsidx} to provide the negatives for the
% current training round.  The resulting detector is written to
% ds.batch.round.negmin.traineddetectors{dsidx}, and sufficiently hard
% negatives are saved to ds.batch.round.negmin.prevfeats{dsidx} for
% later.
myaddpath;
clustId=ds.batch.round.selectedClust(dsidx);
%clustId=ds.batch.currbatch(dsidx);
%if(~dsfield(ds,'initPatchesNeg'))
  %dsload('ds.init*');
  %dsload('ds.batch.round.*');
%end
if(~dsfield(ds,'batch','round','negmin','iminds'))
  dsload('ds.batch.round.negmin.iminds');
end
if(~dsfield(ds,'batch','round','assignedClust'))
  dsload('ds.batch.round.assignedClust');
end
if(~dsfield(ds,'batch','round','posFeatures'))
  dsload('ds.batch.round.posFeatures');
end
posInds = ds.batch.round.assignedClust == clustId;
posFeatures = ds.batch.round.posFeatures(posInds, :);
%features = [posFeatures; ds.initFeatsNeg];
%patches = [ds.batch.round.posPatches(posinds);ds.initPatchesNeg];
%isvalid=ismember([patches.imidx],ds.batch.round.totrainon);
%features=features(isvalid);
iminds=ds.batch.round.negmin.iminds;
alldets=[];
%ds.batch.round.negmin.detections=cell(numel(iminds),dsidx);
for(k=1:numel(iminds))
%   dsload(['ds.batch.round.negmin.detections{' num2str(k) '}']);
%   tmpdets=simplifydets(ds.batch.round.negmin.detections{k},iminds(k));
%   ds.batch.round.negmin.detections{k}=[];
%   if(size(tmpdets)>0)
%     alldets=[alldets;tmpdets([tmpdets.detector]==clustId)];
%   end
%  diskidx=clustId+numel(ds.batch.round.selectedClust)*(k-1);
%  ['ds.batch.round.negmin.detections{' num2str(diskidx) '}']
  tic
  dsload(['ds.batch.round.negmin.detections{' num2str(dsidx) '}{' num2str(k) '}']);
  %size(ds.batch.round.negmin.detections)
  toc
  if(~dsfield(ds,'batch','round','negmin','detections')||size(ds.batch.round.negmin.detections,2)<k)
    %the further images contain nothing.
    continue;
  end
  mydets=ds.batch.round.negmin.detections{dsidx,k};
  %size(ds.batch.round.negmin.detections)
  if(~isempty(mydets))
    alldets=[alldets;mydets];
  end
  ds.batch.round.negmin.detections{dsidx,k}=[];
end
dsload(['ds.batch.round.negmin.prevfeats{' num2str(dsidx) '}']);
mymemory
if(dsfield(ds,'batch','round','negmin','prevfeats')&&...
  (numel(ds.batch.round.negmin.prevfeats)>=dsidx)&&...
  ~isempty(ds.batch.round.negmin.prevfeats{dsidx}))
%  dsload('ds.batch.round.negmin.detectors');
  prevfeats=ds.batch.round.negmin.prevfeats{dsidx};;
else
  if(~dsfield(ds,'initFeatsNeg'))
    dsload('ds.initFeatsNeg');
  end
  prevfeats=ds.initFeatsNeg;
end

if(size(alldets)>0)
  allnegs=[prevfeats;cell2mat({alldets.features}')];
else
  allnegs=prevfeats;
end
features=[posFeatures;allnegs];

labels = [ones(size(posFeatures, 1), 1); ...
ones(size(allnegs, 1), 1) * -1];

fprintf('Training SVM ...  ');
size(labels)
size(features)
model = mySvmTrain(labels, features, ds.conf.params.svmflags, false);

selectedNegs = cullNegatives(allnegs,model,-1.02);
mymemory
allnegs=allnegs(selectedNegs,:);
{'ds.batch.round.nextnegmin.prevfeats{dsidx}','allnegs'};dsup;
%keyboard;
dssave(['ds.batch.round.nextnegmin.prevfeats{' num2str(dsidx) '}']);
ds.batch.round.negmin.prevfeats={};
ds.batch.round.nextnegmin.prevfeats={};
ds.batch.round.negmin.detections={};
%culledfeats=cullNegatives(allfeats,model,cullingThreshold);

ds.batch.round.nextnegmin.traineddetectors{dsidx}=model;
%ds.batch.firstResult{dsidx} = struct('predictedLabels', predictedLabels, 'accuracy', ...
%        accuracy, 'decision', decision);
