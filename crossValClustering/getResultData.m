function [scores, meta] = getResultData(result, clusti, overlap)
% Author: saurabh.me@gmail.com (Saurabh Singh).
  scores = [];
  meta = [];
  if(numel(result.firstLevel.detections)<clusti)
    return
  end
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

