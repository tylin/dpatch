% Author: Carl Doersch (cdoersch at cs dot cmu dot edu) [based on Saurabh's code]
% A distributed computation buried inside of getTopNDetsPerCluster2: extract
% feature vectors from images.
  myaddpath;
  pPat=ds.cffp.patches{dsidx};
  if(~isempty(pPat))
    imPath = pPat(1).im;
    pyra = constructFeaturePyramidForImg(im2double(imread(imPath)), ds.conf.params);
    feats = getPatchFeaturesFromPyramid(pPat, pyra, ds.conf.params);
    ds.cffp.allFeatures{dsidx} = feats;
  end
