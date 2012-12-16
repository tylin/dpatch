% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
% Before negative mining, initialize each detector using 
% ds.batch.round.posFeatures
% as positive examples and ds.initFeatsNeg as negatives.
% ds.batch.round.assignedClust specifies which positive
% examples belong to which detector (detector ids in 
% ds.batch.round.selectedClust).  Resulting detectors
% are saved in ds.batch.round.firstDet.  ds.batch.round.firstResult
% contains additional metadata about the scores of positives, etc.

myaddpath();
clustId=ds.batch.round.selectedClust(dsidx);
%if(~dsfield(ds,'initPatchesNeg'))
  dsload('ds.init*');
  dsload('ds.batch.round.assignedClust');
  dsload('ds.batch.round.posFeatures');
  %dsload('ds.batch.round.posPatches');
%end
%ds
%ds.savestate
posInds = ds.batch.round.assignedClust == clustId;
%posFeatures = ds.batch.round.posFeatures(posInds, :);
%features = [posFeatures; ds.initFeatsNeg];
%patchpos=ds.batch.round.posPatches(posInds);
%if(isfield(patchpos,'clust'))
%  patchpos=rmfield(patchpos,'clust');
%end
%if(isfield(patchpos,'detScore'))
%  patchpos=rmfield(patchpos,'detScore');
%end
%if(isfield(patchpos,'imidx'))
%  isvalid=ismember([patchpos.imidx],ds.batch.round.totrainon);
%end
%negpats=ds.initPatchesNeg;
%if(isfield(negpats,'imidx'))
%  isvalid=ismember([negpats.imidx],ds.batch.round.totrainon);
%else
%  isvalid=true(size(negFeatures,1))
%end
%negFeatures=ds.initFeatsNeg;
%if(isfield(patchpos,'imidx'))
%  isvalid=ismember([patchpos.imidx],ds.batch.round.totrainon);
%else
%  isvalid=true(size(patchpos,1))
%end
%posFeatures=posFeatures(isvalid,:)
%patches = [patchpos(:);ds.initPatchesNeg];


labels = [ones(sum(posInds), 1); ...
ones(size(ds.initFeatsNeg, 1), 1) * -1];
features=[ds.batch.round.posFeatures(posInds, :);ds.initFeatsNeg];

fprintf('Training SVM ...  ');
size(labels)
size(features)
ds.conf.params.svmflags
model = mySvmTrain(labels, features, ds.conf.params.svmflags, false);
[predictedLabels, accuracy, decision] = mySvmPredict(labels, ...
                                       features, model);
%'firstDetsavestate'
%ds.savestate.batch.round.firstDet{2}
ds.batch.round.firstDet{dsidx}=model;
ds.batch.round.firstResult{dsidx} = struct('predictedLabels', predictedLabels, 'accuracy', ...
        accuracy, 'decision', decision);
