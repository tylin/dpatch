% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Test whether any detectors have converged.  This is a performance
% optimization that was not included in the paper; in general, any
% detector that converges will not change as the iterations continue (i.e.
% it just wastes cpu), and any detector that doesn't converge and gets
% thrown out could be thrown out by simply running it on a sufficeintly
% large dataset and seeing that it has low purity.  
function [convergedClusts, tooOldClusts,resthresh]=testDetectorConvergence(prevPosFeats,...
                                               prevAssignedClust,...
                                               detectors,...
                                               selectedClust,...
                                               selClustIts,minfeats,maxage,mindecision)
if(nargin<7)
  %old interface
  maxage=3;
  minfeats=5;
else
%  if(numel(prevPosFeats)<numel(minits))
%    convergedClusts=[];
%    tooOldClusts=[];
%    return;
%  end
  prevPosFeats=cell2mat(prevPosFeats);
  prevAssignedClust=cell2mat(prevAssignedClust);
end
if(nargin<8)
  mindecision=0;
end
convergedClusts=logical(zeros(size(selectedClust)));
weakestdecision=zeros(size(selectedClust));
for(i=1:numel(selectedClust))
  mydet=selectDetectors(detectors,i)
  features=prevPosFeats(find(prevAssignedClust==selectedClust(i)),:);
  if(size(features,1)<minfeats)
    weakestdecision(i)=-Inf;
    continue;
  end
  labels = ones(size(features, 1), size(mydet.firstLevModels.w, 1));
  [unused_labels, unused_acc, decision] = mySvmPredict(labels, ...
      features, mydet.firstLevModels);
  weakestdecision(i)=min(decision);
end
if(~isempty(mindecision))
  
%  if(all(decision>mindecision))
%    convergedClusts(i)=true;
%  end
  convergedClusts=weakestdecision>mindecision;
  resthresh=mindecision;
else
  if(any(~isinf(weakestdecision)))
    decs=sort(weakestdecision(~isinf(weakestdecision)),'descend');
    resthresh=decs(ceil(numel(decs)/4));
    convergedClusts=weakestdecision>resthresh;
  else
    resthresh=[];
  end
end


convergedClusts=selectedClust(convergedClusts);
tooOldClusts=selectedClust(selClustIts>=maxage);
