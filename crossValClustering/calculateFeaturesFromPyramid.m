function [features, collatedPatches, indexes] = ...
  calculateFeaturesFromPyramid(patches, params, imgIds)
% indexes: Index of the image corresponding to the patch.
%
% Author: saurabh.me@gmail.com (Saurabh Singh).
global ds;
allFeatures = cell(size(patches));
a=tic;
totalPatches = length(patches);
dsdelete('ds.cffp');
ds.cffp.patches=patches(:)';
dsmapreduce('autoclust_calcFeatsFromPyr',{'ds.cffp.patches'},{'ds.cffp.allFeatures'})
allFeatures=ds.cffp.allFeatures;
dsdelete('ds.cffp');
%parfor i = 1 : length(patches)
%  pPat = patches{i};
%  if ~isempty(pPat)
%    imPath = pPat(1).im;
%    pyra = constructFeaturePyramidForImg(im2double(imread(imPath)), params);
%    feats = getPatchFeaturesFromPyramid(pPat, pyra, params);
%    allFeatures{i} = feats;
%  end
%  fprintf('Patch %d/%d\n', i, totalPatches);
%end
toc(a);
posPatches = [];
allFeat = [];
indexes = {};
disp('Collecting all in one array.');
posPatches=structcell2mat(patches(:)');
allFeat=structcell2mat(allFeatures(:));
for i = 1 : length(allFeatures)
  if isempty(allFeatures{i})
    continue;
  end
  %posPatches = [posPatches patches{i}];
  %allFeat = [allFeat; allFeatures{i}];
  inds = ones(size(allFeatures{i}, 1), 1) * imgIds(i);
  if(~isempty(inds))
    indexes{end+1,1} = inds;
  end
  %allFeatures{i} = [];
  %patches{i} = [];
end
indexes=cell2mat(indexes);
disp('Done');
collatedPatches = posPatches;
features = allFeat;
end
