function selectedNegs = cullNegatives(negFeatures, detectors, ...
  cullingThreshold, detInd)
if(isfield(detectors,'firstLevModels'))
  detectors=detectors.firstLevModels;
end
[unused, unused, decision] = mySvmPredict( ...
  ones(size(negFeatures, 1), size(detectors.w, 1)) * -1, ...
  negFeatures, detectors);
if(nargin>3)
  decision = decision(:, detInd);
end
numNegs = size(negFeatures, 1);
% maxSel1 = sum(decision >= cullingThreshold) * 2;
maxSel1 = sum(decision >= cullingThreshold);
maxSel2 = sum(decision >= -1) * 3;
% maxSel2 = sum(decision >= -1);
maxSel = min([maxSel1; maxSel2]);
maxSel(maxSel > numNegs) = numNegs;

[unused, sortedInds] = sort(decision, 'descend');
selectedNegs = false(size(negFeatures, 1), 1);
selectedNegs(sortedInds(1:maxSel)) = true;
end
