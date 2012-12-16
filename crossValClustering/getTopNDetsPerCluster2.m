function topN = getTopNDetsPerCluster2(detectionResults, ...
  overlap, posIds, N)
% Generate the top N detections.
%
% Author: saurabh.me@gmail.com (Saurabh Singh).

numClusters = detectionResults.getNumClusters();
scores = cell(numClusters, 1);
imgIds = cell(numClusters, 1);
meta = cell(numClusters, 1);
maxCacheSize = max(N, 200);
maxToShow = N;

idsToUse = sort(posIds);
pBar = createProgressBar();
nresults=0;
total=0;
for j = 1 : length(idsToUse)
  pBar(j, length(idsToUse));
  id = idsToUse(j);
  %tic
  res = detectionResults.getPosResult(id);
  %toc
  if(isempty(res))
    continue;
  end
  for clusti = 1 : numClusters
    %[thisScores, imgMeta] = getResultData(res, ...
    %  clusti, overlap);
    if(clusti==1)
      total=total+numel(res(clusti).scores);
    end
    scores{clusti} = [scores{clusti}; res(clusti).scores'];
    imgIds{clusti} = [imgIds{clusti}; res(clusti).imgIds'];
    meta{clusti} = [meta{clusti}; res(clusti).meta'];
    %keyboard;
    %scores=[scores;res.scores'];
    %imgIds=[imgIds;res.imgIds'];
    %meta=[meta;res.meta'];
    %if length(scores) > maxCacheSize
    %  [meta, scores, imgIds] = pickTopN( ...
    %    scores, imgIds, meta, maxToShow, ...
    %    overlap);
    %end
    if length(scores{clusti}) > maxCacheSize
      [meta{clusti}, scores{clusti}, imgIds{clusti}] = pickTopN( ...
        scores{clusti}, imgIds{clusti}, meta{clusti}, maxToShow, ...
        overlap);
    end
  end
end
disp(['got ' num2str(total) ' results for first detector']);
%if(nresults==0)
%  throw(MException('a:b','
%end
% Collate the data.
topN = cell(1, numClusters);
%topN=struct();
%for i = 1 : numClusters
%  [topN.meta, topN.scores, topN.imgIds] = pickTopN(scores, ...
%    imgIds, meta, maxToShow, overlap);
%end
for i = 1 : numClusters
  [topN{i}.meta, topN{i}.scores, topN{i}.imgIds] = pickTopN(scores{i}, ...
    imgIds{i}, meta{i}, maxToShow, overlap);
end

end

function [meta, scores, imgIds] = pickTopN(scores, imgIds, meta, ...
  numToPick, maxOverlap)
  [unused, ordered] = cleanUpOverlapping(meta, scores, ...
    imgIds, maxOverlap);
  toSelect = min(length(ordered), numToPick);
  [~,uniqueim]=unique(imgIds(ordered),'first');
  ordered=ordered(sort(uniqueim,'ascend'));
  selected=ordered(1:min(numel(ordered),toSelect));
  %selected = ordered(1:toSelect);

  meta = meta(selected);
  scores = scores(selected);
  imgIds = imgIds(selected);
end

function [scores, meta] = getResultData(result, clusti, overlap)
  scores = [];
  meta = [];
  thisScores = result.firstLevel.detections(clusti).decision;
  if isempty(thisScores)
    return;
  end
  imgMeta = result.firstLevel.detections(clusti).metadata;
  % Do NMS for image.
  picks = doNmsForImg(imgMeta, thisScores, overlap);
  
  scores = thisScores(picks);
  meta = imgMeta(picks);
end
