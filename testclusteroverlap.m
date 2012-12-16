% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
% Significant contributions from Saurabh Singh (saurabh.me@gmail.com)
%
% topN is the top n detections for all previous "accepted" clusters,
% and query is the top n detections for a new cluster. keep=false
% indicates that there is a detector in topN such that 10% of the 
% detections in query overlap with that detector's detections
% by a factor of 30%.

function [keep] = testclusteroverlap(topN,query)

coccurOverlap = zeros(length(topN), 10);
%coccurPats = cell(length(topN), length(topN), 10);
%pBar = createProgressBar();
keep=true;
for i = 1 : length(topN)
  %pBar(i, length(topN));
%  for j = i + 1 : length(topN)
    imgIds=[topN{i}.imidx];
    qimgIds=[query.imidx];
    inter = intersect(imgIds, qimgIds);
    for k = 1 : length(inter)
      [memi, unused] = ismember(imgIds, inter(k));
      [memj, unused] = ismember(qimgIds, inter(k));
      boxesi = getBoxesForPedro([topN{i}(memi).pos]);
      boxesj = getBoxesForPedro([query(memj).pos]);
      overl = computeOverlap(boxesj, boxesi, 'pascal');
      [overl, overlEl] = max(overl, [], 2);
%       coccurOverlap(i, j) = coccurOverlap(i, j) + ...
%         sum(overl >= coccOverlapHighThresh) + ...
%         0.5 * sum(overl < coccOverlapHighThresh & ...
%           overl >= coccOverlapLowThresh);
%       coccurOverlap(i, j) = coccurOverlap(i, j) + ...
%         sum(overl <= coccOverlapHighThresh && ...
%         overl >= 0.001);
      overlInd = ceil(overl .* 10);
      overlInd(overlInd == 0) = 1;
      h = hist(overlInd, 1 : 10);
      h = reshape(h, 1, []);
      coccurOverlap(i, :) = coccurOverlap(i, :) + h;
      if(sum(coccurOverlap(i,3:end))>(.1*numel(query)))
        keep=false;
        return;
      end
      %coccurOverlap(j, i, :) = coccurOverlap(j, i, :) + h;
      
      %iInd = find(memi);
      %jInd = find(memj);
      %for p = 1 : length(overlInd)
      %  coccurPats{i, j, overlInd(p)} = [coccurPats{i, j, overlInd(p)}; ...
      %    iInd(p) jInd(overlEl(p))];
      %  coccurPats{j, i, overlInd(p)} = [coccurPats{j, i, overlInd(p)}; ...
      %    jInd(overlEl(p)) iInd(p)];
      %end
    end
%  end
end
end
