function feats = getPatchFeaturesFromPyramid(patches, pyramid, params)
% Cuts out the features for patches from the corresponding HOG feature pyramid.
%
% Author: saurabh.me@gmail.com (Saurabh Singh).
[nrows, ncols, nzee, nextra] = getCanonicalPatchHOGSize(params);
numElement = nrows * ncols * nzee + nextra;
feats = zeros(length(patches), numElement);
for i = 1 : length(patches)
  pyramidInfo = patches(i).pyramid;
  pyraLevel = pyramidInfo(1);
  r = pyramidInfo(2);
  c = pyramidInfo(3);
  patFeat = pyramid.features{pyraLevel}(r:r+nrows-1, c:c+ncols-1, :);
  if(dsfield(params,'useColorHists'))
    endhist=sum(sum(patFeat(:,:,32:end)));
    feats(i,:)=[reshape(patFeat(:,:,1:31),1,[]) endhist(:)'];
  else
    feats(i, :) = reshape(patFeat, 1, []);
  end
end
end
