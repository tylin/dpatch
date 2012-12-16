% efficient nearest-neighbors in Euclidean distance.
% each row of toassign is assigned to the nearest row in targets.
% closest(i) is the row-index in targets of the closest element 
% for toassign(i,:).  outdist(i) is the distance to that point.
function [closest,outdist]=assigntoclosest(toassign,targets)
  targsq=sum(targets.^2,2);
  closest=zeros(size(toassign,1),1);
  outdist=zeros(size(toassign,1),1);
  for(i=1:800:size(toassign,1))
    inds=i:min(i+800-1,size(toassign,1));
    batch=toassign(inds,:);
    batchsq=sum(batch.^2,2);
    inprod=targets*(batch');
    dist=bsxfun(@plus,bsxfun(@minus,batchsq',2*inprod),targsq);
    [outdist(inds),closest(inds)]=min(dist,[],1);
  end
end
