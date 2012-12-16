function [features, levels, indexes, gradsums] = unentanglePyramid(pyramid, ...
  patchCanonicalSize)
% Converts a pyramid of hog features for an image to a single matrix.
%
% Author: saurabh.me@gmail.com (Saurabh Singh).

  %prSize = round(patchCanonicalSize(1) / pyramid.sbins) - 2;
  %pcSize = round(patchCanonicalSize(2) / pyramid.sbins) - 2;
  global ds;
  [prSize, pcSize, pzSize, nExtra]=getCanonicalPatchHOGSize(ds.conf.params);
  selFeatures = cell(length(pyramid.features), 1);
  selGradsums = cell(length(pyramid.features), 1);
  selFeaturesInds = cell(length(pyramid.features), 1);

  selLevel = cell(length(pyramid.features), 1);
  totalProcessed = 0;
  %im=RGB2Lab(im);

  for i = 1 : length(pyramid.features)
    [feats, indexes, selGradsums{i,1}] = getFeaturesForLevel(pyramid.features{i}, ds.conf.params, prSize, ...
      pcSize,pzSize,nExtra,pyramid.gradimg{i});
    selFeatures{i} = feats;
    selFeaturesInds{i} = indexes;
    numFeats = size(feats, 1);
    selLevel{i} = ones(numFeats, 1) * i;
    totalProcessed = totalProcessed + numFeats;
  end
  gradsums=cell2mat(selGradsums);

  [features, levels, indexes] = appendAllTogether(totalProcessed, ...
    selFeatures, selLevel, selFeaturesInds);

end

function [newFeat, newLev, newInds] = appendAllTogether(totalProcessed, ...
  features, levels, indexes)
newFeat = zeros(totalProcessed, size(features{1}, 2));
newLev = zeros(totalProcessed, 1);
newInds = zeros(totalProcessed, 2);

featInd = 1;
for i = 1 : length(features)
  if isempty(features{i})
    continue;
  end
  startInd = featInd;
  endInd = startInd + size(features{i}, 1) - 1;
  newFeat(startInd:endInd, :) = features{i};
  features{i} = [];
  newLev(startInd:endInd) = levels{i};
  levels{i} = [];
  newInds(startInd:endInd, :) = indexes{i};
  indexes{i} = [];
  featInd = endInd + 1;
end
end
