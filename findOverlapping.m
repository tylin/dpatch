% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Find overlapping detections in detsByDetr.  Overlapping
% means both detections have the same imidx and the positions
% spatially overlap by a factor of .3.  At least 8 must
% be overlapping to result in a detector being considered
% as overlapping.  res contains the overlapping detectors
% by id, or the non-overlapping ones if findNonOverlap
% is specified.  Similarly conf.maxToFind will cause
% this function to return immediately when it has found
% maxToFind overlapping or non-overlapping detectors.
%
% Note that this function *could* be used to detect overlapping
% nearest-neighbor sets right after the nearest-neighbor step,
% but it is not.  It is only used to detect overlapping detectors
% at the end of everything.
function [res groups ovlmat]=findOverlapping(detsByDetr,conf)
try
  percentForOverlap=.3;
  maxOverlapping=5;
  numOtherDetrs=1;
  findNonOverlap=false;
  maxToFind=Inf;
  mustload=ischar(detsByDetr);
  currgroup=1;
  groups=zeros(size(detsByDetr));
  detrIdForPos=cellfun(@(x) x(1).detector,detsByDetr);
  if(nargout==3)
    ovlmat=sparse(numel(detsByDetr),numel(detsByDetr));
  end
  if(exist('conf','var'))
    if(isfield(conf,'maxToFind'))
      maxToFind=conf.maxToFind;
    end
    if(isfield(conf,'findNonOverlap'))
      findNonOverlap=conf.findNonOverlap;
    end
    if(isfield(conf,'range'))
      range=conf.range;
    else
      range=1:numel(detsByDetr);
    end
  end
  resPrevDets={};
  resPrevDetsAll={};
  res=[];
  %[~,imidxmap]=ismember(1:max(imidxmap),imidxmap);
  totaloverlapByDetr=[];
  for(k=1:numel(range))
    i=range(k);
    if(mustload)
      currDets=dsload([detsByDetr '{' num2str(i) '}'],'clear');
    else
      currDets=detsByDetr{i};
    end
    if(~isfield(currDets,'imidx'))
      %scr=num2cell(currDets.scores);
      %[currDets.meta.decision]=scr{:};
      currDets=simplifydets(currDets);
    end
    totaloverlapByDetr=sparse(1,i);
    totaloverlapByDetrAll=sparse(1,i);
    overlapFlag=1;
    for(j=1:numel(currDets))
      if(currDets(j).imidx>numel(resPrevDets))
        resPrevDets{currDets(j).imidx}=[];
        resPrevDetsAll{currDets(j).imidx}=[];
      end
      compDets=resPrevDets{currDets(j).imidx};
      if(isempty(compDets))
        continue;
      end
      boxesi = getBoxesForPedro(currDets(j).pos);
      boxesj = getBoxesForPedro([compDets.pos]);
      overl = computeOverlap(boxesj, boxesi, 'pascal');
      detinds=[compDets.detector];
      toup=unique(detinds(overl(:)>percentForOverlap));
      if(numel(totaloverlapByDetr)<max(toup))
        totaloverlapByDetr(max(toup))=0;
      end
      totaloverlapByDetr(toup)=totaloverlapByDetr(toup)+1;

      if(nargout==3)
        compDetsAll=resPrevDetsAll{currDets(j).imidx};
        boxesj = getBoxesForPedro([compDetsAll.pos]);
        overlAll = computeOverlap(boxesj, boxesi, 'pascal');
        detindsAll=[compDetsAll.detector];
        toupAll=unique(detindsAll(overlAll(:)>percentForOverlap));
        if(numel(totaloverlapByDetrAll)<max(toupAll))
          totaloverlapByDetrAll(max(toupAll))=0;
        end
        totaloverlapByDetrAll(toupAll)=totaloverlapByDetrAll(toupAll)+1;
      end

      if(sum(totaloverlapByDetr(toup)>maxOverlapping)>=numOtherDetrs)
        overlapFlag=0;
        if(nargout<3)
          break;
        end
      end
    end
    %max(totaloverlapByDetr)
    for(j=1:numel(currDets))
      resPrevDetsAll{currDets(j).imidx}=[resPrevDetsAll{currDets(j).imidx} currDets(j)];
    end
    if(overlapFlag)
      for(j=1:numel(currDets))
        resPrevDets{currDets(j).imidx}=[resPrevDets{currDets(j).imidx} currDets(j)];
      end
      if(findNonOverlap)
        res=[res i];
        disp(['found ' num2str(numel(res)) ' nonoverlap']);
        if(numel(res)>=maxToFind)
          nextClust=k+1;
          disp(['searched ' num2str(k) ' detectors, found ' num2str(numel(res)) ' nonoverlap']);
          return;
        end
      end
      groups(i)=currgroup;
      currgroup=currgroup+1;
      %disp(sum(cellfun(@(x) ~isempty(x),resPrevDets)));
    else
        if(~findNonOverlap)
          res=[res i];
          disp(['found ' num2str(numel(res)) ' overlap']);
        end
      tmp=find(totaloverlapByDetr>maxOverlapping);
      groups(i)=groups(find(tmp(1)==detrIdForPos));
    end
    if(nargout==3)
      ovlmat(i,1:(i-1))=totaloverlapByDetrAll(1:(i-1));
      ovlmat(1:(i-1),i)=totaloverlapByDetrAll(1:(i-1))';
    end
    if(mod(k,10)==0)
      disp(['findOverlapping: ' num2str(k) '/' num2str(numel(range))]);
    end
  end
  nextClust=[];
catch ex
  dsprinterr
end
end
