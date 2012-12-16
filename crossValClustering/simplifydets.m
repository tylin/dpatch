% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
%
% Convert Saurabh's detection structures into one unified
% format: a single struct array with a minimal number of
% fields. 
function [res]=simplifydets(detections,imidx,assignedClust)
  curridx=1;
  if(isfield(detections(1),'x1'))
    %this is just the metadata part of the detections struct
    detections(1).firstLevel.detections(1).metadata=detections;
  end
  if(isfield(detections,'imgIds'))
    %this is just the detections part
    detections.metadata=detections.meta;
    detections(1).firstLevel.detections=detections;
  end
  for(i=1:numel(detections(1).firstLevel.detections))
    for(j=1:numel(detections(1).firstLevel.detections(i).metadata))
      pos=struct(...
        'x1',detections(1).firstLevel.detections(i).metadata(j).x1,...
        'x2',detections(1).firstLevel.detections(i).metadata(j).x2,...
        'y1',detections(1).firstLevel.detections(i).metadata(j).y1,...
        'y2',detections(1).firstLevel.detections(i).metadata(j).y2);
      if(~exist('imidx','var'))
        curimidx=detections(1).firstLevel.detections(i).imgIds(curridx);
      else
        if(numel(imidx)==1)
          curimidx=imidx;
        else
          curimidx=imidx(curridx);
        end
      end
      if(isfield(detections(1).firstLevel.detections(i),'decision'))
        decision=detections(1).firstLevel.detections(i).decision(j);
      elseif(isfield(detections(1).firstLevel.detections(i).metadata(j),'detScore'))
        decision=detections(1).firstLevel.detections(i).metadata(j).detScore;
      elseif(isfield(detections(1).firstLevel.detections(i),'scores'))
        decision=detections(1).firstLevel.detections(i).scores(j);
      else
        decision=0;
      end
      if(isfield(detections(1).firstLevel.detections(i).metadata(j),'clust'))
        mydetector=detections(1).firstLevel.detections(i).metadata(j).clust;
      elseif(exist('assignedClust','var'))
        mydetector=assignedClust(curridx);
      else
        mydetector=i;
      end
      tmp=struct(...
        'decision',decision,...
        'pos',pos,...
        'imidx',curimidx,...
        'detector',mydetector);
      if(isfield(detections(1).firstLevel.detections(i),'features')&&...
         (~isempty(detections(1).firstLevel.detections(i).features)))
        tmp.features=detections(1).firstLevel.detections(i).features(j,:);
      end
      res(curridx,1)=tmp;

        
      curridx=curridx+1;
    end
  end
  if(~exist('res','var'))
    res=struct([]);
  end
end
