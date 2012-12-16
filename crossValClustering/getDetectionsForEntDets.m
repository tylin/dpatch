function [detections, decision, levels, indexes] = getDetectionsForEntDets(detectors, ...
  pyramid, patchCanonicalSize, detectionParams,im)
% Performs the detections in the given image.
%
% Author: saurabh.me@gmail.com (Saurabh Singh).

%data = data.annotation;
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

totalProcessed = size(features, 1);

labels = ones(size(features, 1), size(detectors.w, 1));
[unused_labels, unused_acc, decision] = mySvmPredict(labels, ...
    features, detectors);

selected = doSelectionForParams(detectionParams, decision);
detections = constructResultStruct(pyramid, prSize, ...
  pcSize, totalProcessed, features, ...
  decision, levels, indexes, selected, detectionParams,im);
end

function detections = constructResultStruct(pyramid, prSize, ...
  pcSize, totalProcessed, features, ...
  decision, levels, indexes, selected, detectionParams,im)
detections = struct('features', [], 'metadata', [], 'decision', [], ...
  'totalProcessed', totalProcessed, 'thresh', []);

numDets = size(decision, 2);
for i = 1 : numDets
  detections(i).totalProcessed = totalProcessed;
  selInds = find(selected(:, i));
  if length(selInds) < 1
    continue;
  end
  metadata = getMetadataForPositives(...
      selInds, levels, indexes, prSize, pcSize, ...
      pyramid,im);
  picks = doNmsForImg(metadata, decision(selInds, i), ...
    detectionParams.overlap);
  detections(i).features = features(selInds(picks), :);
  detections(i).metadata = metadata(picks);
  detections(i).decision = decision(selInds(picks), i);
end
end

function selected = doSelectionForParams(params, decision)
% Perform selection based on detection parameters.
if params.selectTopN
  selected = false(size(decision));
  [desc, inds] = sort(decision, 'descend');
  [rows, cols] = size(decision);
  begins = ((1:cols) - 1) * rows;
  indexes = inds + repmat(begins, rows, 1);
  numToSelect = min(size(desc, 1), params.numToSelect);
  selInds = indexes(1 : numToSelect, :);
  selected(selInds(:)) = true;
elseif params.useDecisionThresh
  if isfield(params, 'fixedDecisionThresh')
    thresh = params.fixedDecisionThresh;
  else
    error('Fixed decision thresh needs to be specified.');
  end
  selected = decision >= thresh;
else
  thresh = 0;
  selected = decision >= thresh;
end
end
