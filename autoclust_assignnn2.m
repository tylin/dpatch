% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% For each element in ds.centers, find the nearest neighbor in
% the image specified by ds.myiminds(dsidx).  Just store the
% index for each element of centers to avoid communication. 
% The root node will aggregate across images and extract
% descriptors later.

myaddpath
%if(~dsfield(ds,'centers'))
  dsload('ds.centers');
  dsload('ds.myiminds');
%end
  i=ds.myiminds(dsidx);
    im=im2double(getimg(ds,i));
pyramid = constructFeaturePyramid(im, ds.conf.params);
[pcs(1),pcs(2),pcs(3),pcs(4)]=getCanonicalPatchHOGSize(ds.conf.params);
patchCanonicalSize=pcs;

prSize = round(patchCanonicalSize(1) / pyramid.sbins) - 2;
pcSize = round(patchCanonicalSize(2) / pyramid.sbins) - 2;

[features, levels, indexes,gradsums] = unentanglePyramid(pyramid, ...
  patchCanonicalSize);

invalid=(gradsums<9);
features(invalid,:)=[];
levels(invalid)=[];
indexes(invalid,:)=[];
gradsums(invalid)=[];
disp(['threw out ' num2str(sum(invalid)) ' patches']);
if(isempty(features))
  %ds.assignednn{dsidx}=[];
  %ds.assignedidx{dsidx}=[];
  %ds.pyrscales{dsidx} = [];
  %ds.pyrcanosz{dsidx} = [];
  return;
end
features=bsxfun(@rdivide,bsxfun(@minus,features,mean(features,2)),sqrt(var(features,1,2)).*size(features,2));
[assignedidx, dist]=assigntoclosest(single(ds.centers),single(features));
ds.assignednn{dsidx}=dist;
ds.assignedidx{dsidx}=[levels(assignedidx), indexes(assignedidx,:)];
ds.pyrscales{dsidx} = pyramid.scales;
ds.pyrcanosz{dsidx} = pyramid.canonicalScale;
